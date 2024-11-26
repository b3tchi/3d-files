#!/usr/bin/nu

# tHREE dIMENSION pRINTEr alias  = tdpr scripts to manage print file handling with ease
use ./fx.nu
export-env {

    $env.NU_LOG_LEVEL = 'DEBUG'
    $env.TEMP = '/tmp/3d-files'
    mkdir $env.TEMP

}

def configs [] {
    ls -s ($env.PWD | path join configs) | get name
}

def models [] {
    ls -s ($env.PWD | path join models) | where type == dir | get name
}

def parts [context: string] {
    let model = $context | split row ' ' | last 2 | first
    ls -s ($env.PWD | path join models $model ) | where type == dir |get name
}

def parts-v2 [context: string] {
    logd context $context
    let arguments = $context | split row ' ' | skip 2
    mut model_position = 0

    $model_position += (if ('--config' in $arguments) { 2 } else {0})
    $model_position += (if ('--validate' in $arguments) { 1 } else {0})

    let model = $arguments | get $model_position

    ls -s ($env.PWD | path join models $model ) | where type == dir |get name
}

export def --env setup [
    url: string # printer local url
    password?: string # carefull here! avoid enter key directly it will be kept in history!!!
    ] {

    $env.3D_PRINTER_IP = $url
    $env.3D_PRINTER_KEY = if $password == null {
        input -s 'enter api key: '
    } else {$password}
}

export def check [] {
    print $"url:($env.3D_PRINTER_IP)"
    print $"api-key:($env.3D_PRINTER_KEY)"
    let resp = http get --headers [X-Api-Key $env.3D_PRINTER_KEY] $"http://($env.3D_PRINTER_IP)/api/v1/status"
    return $resp.printer.state
}

export def --env send [
    --config: string@configs #print settings
    --arrange #validate layout is properly set
    --validate #validate layout is properly set
    model: string@models #select what model is used
    ...parts: string@parts-v2 #select which parts to print
    ] {

    #header items
    let timestamp = (date now | format date %Y%m%d%H%M%S)
    let branch_name = git rev-parse --abbrev-ref HEAD #I/O
    let $config_name = if ($config == null) { 'prototype.ini' } else { $config }

    let temp_path = '/tmp/3d-files'
    let macro_path = ( './macros' | path expand | path join 'export-to-stl.py' )
    let model_root = ( './models' | path expand )
    let config_path = ( './configs' | path expand | path join $config_name )

    #pepare parts list
    let parts_base = (fx build-base $model $branch_name $timestamp $parts)
        | insert last_tag {|row|
            try {git ...(fx last-tag-args $model $row.part) e> (std null-device)} catch {''}} #I/O
        | insert version {|row|
            fx build-version $row.last_tag}
        | insert stem {|row|
            fx part-version $row.branch $row.part $row.version $row.timestamp}
        | insert short {|row|
            fx build-short $row.branch $row.part $row.version $row.count}
        | insert stl_path {|row|
            fx build-stl-path $temp_path $model $row.stem $timestamp}
        | insert fcad_dir {|row|
            fx build-part-dir $model_root $model $row.part}

    let final_stem = fx build-final-name $parts_base $timestamp
    let final_stl = fx build-final-file $temp_path $timestamp $model $final_stem 'stl'
    let final_3mf = fx build-final-file $temp_path $timestamp $model $final_stem '3mf'
    let final_gcode = fx build-final-file $temp_path $timestamp $model $final_stem 'gcode'

    mkdir ($final_gcode | path dirname) #I/O

    $parts_base | each {|part|
        let freecad_args = fx create-stl $macro_path $part.fcad_dir $part.stl_path
        try { freecad-linkstage3 ...$freecad_args } catch { 'export command issue' } #I/O
    }

    let merge_args = fx merge-stl $config_path $final_3mf ($parts_base | select stl_path count)
    try { prusa-slicer ...$merge_args } catch { 'merge command issue' } #I/O

    # validate source input
    if $arrange {
        prusa-slicer $final_3mf #I/O
    }

    #create final stl
    # TBD let thumb_path = generate-thumb $final_stl

    # create gcode
    let slicer_args = fx create-gcode $config_path $final_3mf $final_gcode
    try { prusa-slicer ...$slicer_args } catch { 'gcode command issue' } #I/O


    # validate source input
    if $validate {
        prusa-slicer $final_gcode #I/O

        if ([yes no] | input list 'Please confirm, that gcode is ok, ready to be send to printer?') == 'no' {
            print 'Print script is cancelled'
            return
        }
    }

    # print gcode
    # TBD fx embed-thumbnail $thumb_path $gcode_path
    let curl_args = fx print-gcode $model $final_gcode $env.3D_PRINTER_KEY $env.3D_PRINTER_IP
    try { curl ...$slicer_args } catch { 'print command issue' } #I/O
    print $curl_args

    return $final_gcode
}
