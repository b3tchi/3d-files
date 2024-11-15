#!/usr/bin/nu

# tHREE dIMENSION pRINTEr alias  = tdpr scripts to manager printing
use std log
export-env {
    # $env.3D_PRINTER_IP# = ''
    # $env.3D_PRINTER_KEY# = ''

    # if $nu.os-info.name == 'linux' {
    $env.NU_LOG_LEVEL = 'DEBUG'
    # $env.NU_LOG_LEVEL = ''
    $env.TEMP = '/tmp/3d-files'
    mkdir $env.TEMP
    # export alias slicer-prusa =
    # 	print (scope aliases)
    # }

    # if $nu.os-info.name == 'windows' {
    # 	export alias "freecad-linkstage3" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240407\bin\FreeCADLink.exe
    # 	export alias "freecad-linkstage3 --console" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240407\bin\FreeCADCmd.exe
    # 	export alias slicer-prusa = prusa-slicer-console.exe
    # }
}

# def slicer-command [...args: string] {
# 	if $nu.os-info.name == 'linux' {
# 		prusa-slicer ...$args
# 	}
# }

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
    url: string
    ] {

    $env.3D_PRINTER_IP = $url
    $env.3D_PRINTER_KEY = (input -s 'enter api key: ')
}

def logd [
	description:string
	msg:string
	] {

	log debug $"(ansi yellow)($description): ($msg)(ansi reset)"
}

export def check [] {
    print $"url:($env.3D_PRINTER_IP)"
    print $"api-key:($env.3D_PRINTER_KEY)"
 	let resp = http get --headers [X-Api-Key $env.3D_PRINTER_KEY] $"http://($env.3D_PRINTER_IP)/api/v1/status"
	return $resp.printer.state
}

export def send-v1 [
    model: string@models
    part: string@parts
    config: string@configs
    stl?: string
    ] {

    let next_timestamp = (date now | format date %Y%m%d%H%M%S)

    let $version = part-version $model $part $next_timestamp
    print $version
    let $file_stl = if $stl == null { create-stl $model $part $version } else { move-stl $model $part $version $stl }
    print $file_stl
    let $file_gcode = create-gcode-v1 $model $part $version $config
    print $file_gcode
    #printing code
    print-gcode-v1 $model $part $version

    return $file_gcode
}

export def part-version [
    model: string@models
    part: string@parts
	next_timestamp?: string
    ] {

    let branch = (git rev-parse --abbrev-ref HEAD)
	logd branch $branch

    let tag_git = (git describe --tags --match $"($model)/($part)/*" --abbrev=0 HEAD)
    let tag_build = (if $tag_git  == '' { '0.1.0' } else { $tag_git })

	mut tag_parts = [$tag_build]
	if ($branch != 'main') {
		if ($next_timestamp == null) {
			$tag_parts = ( $tag_parts | append '-next' )
		} else {
			$tag_parts = ( $tag_parts | append '-next+' )
			$tag_parts = ( $tag_parts | append $next_timestamp )
		}
	}

    let version = ( $tag_parts | str join )
	logd version ($version)

    return $version
}

def move-stl [
    model: string@models
    part: string@parts
    version: string
	stl: string
	] {

    let output_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )

	cp -v $stl $output_stl

    return $output_stl
}

export def create-stl [
    model: string@models
    part: string@parts
    version: string
    ] {

    let macro = ( './macros' | path expand | path join 'export-to-stl.py' )
    let input_file = ( './models' | path expand | path join $model $part )
    let output_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )

	logd output1 $output_stl

    try { freecad-linkstage3 --console $macro $input_file $output_stl } catch { 'freecad linking '}

	logd output2 $output_stl

    return $output_stl
}

export def send [
    --config: string@configs #prit settings
	--validate #validate layout is properly set
    model: string@models #select what model is used
    ...parts: string@parts-v2 #select which parts to print
    ] {

	let next_timestamp = (date now | format date %Y%m%d%H%M%S)

	let $config_name = if ($config == null) { 'prototype.ini' } else { $config }
	
	mut final_stl = ''

	if ( $parts | length ) > 1 {

		mut stls = []
		mut part_names = []
		mut multi_part_names = []

		for $part in $parts {

			let name_version = ( (part-version $model $part) | str replace '-next' 'n' )
			$part_names = $part_names | append $"($part | split row '-' | each {|row| $row |str substring 0..1}| str join '' )@($name_version)"

			let file_version = part-version $model $part $next_timestamp 
			let file_stl = create-stl $model $part $file_version

			logd version $file_version
			logd stl_name $file_stl

			$stls = ( $stls | append $file_stl )
		}

		logd stls ($stls | to text)
		logd part_names ($part_names | to text)

		let part_names = $part_names | uniq --count | each {|row| $"($row.count)($row.value)"}| str join '-'

		let final_name =  ['x' $part_names $next_timestamp] | str join '-' 

		logd final_name ($final_name | to text)

		$final_stl = merge-stl $validate $final_name $config_name $stls 

	} else {

		let $part = ( $parts | get 0 )

		let file_version = part-version $model $part $next_timestamp

		$final_stl = create-stl $model $part $file_version
	}
	

	let thumb_path = generate-thumb $final_stl
    let gcode_path = create-gcode $config_name $final_stl

	embed-thumbnail $thumb_path $gcode_path 

	print-gcode $model $gcode_path
	print $gcode_path

	return $gcode_path
}

def generate-thumb-v0 [ 
    stl_name: string
    png_name: string
	] {

#	using latest version of stl-thumb stl-thumb-git standard version not working for me
#	installed via yay -S stl-thumb-git
	
	stl-thumb -s 220 $stl_name $png_name
}

export def generate-thumb [ 
    stl_path: string
	] {
	let scad_path = ( $stl_path | path parse --extension stl | upsert extension { 'scad'} | path join )
	'import("' + $stl_path + '");' | save --force $scad_path

	let output_png = ($stl_path | path parse --extension 'stl' | upsert extension { 'png'} | path join)

	let args = [
		-o $output_png
		'--imgsize=220,124'
		--viewall
		'--colorscheme=Tomorrow Night'
		$scad_path

	]
	logd args ( $args | to text) 

	try { openscad ...$args } catch { log error 'thumb gen error' }

    return $output_png
}

def merge-stl [
    validate: bool
    output_name: string
    config_name:string
    stls: list
    ] {

    let output_stl = ( $env.TEMP | path expand | path join $"($output_name).stl" )
    let config_path = ( './configs' | path expand | path join $config_name )

    let args = [--load $config_path --export-stl --merge --split --ensure-on-bed --output $output_stl] | append $stls

    try { prusa-slicer ...$args } catch { log error 'slicer command issue' }

    logd slicer-args ($args | to text)

    if $validate {
        cd $env.TEMP
        prusa-slicer $output_stl --output $output_stl
        cd -
    }

    return $output_stl
}

export def embed-thumbnail [
	png_path: string
	gcode_path: string
	] {
	let width = 220
	let height = 124

	# Convert image to base64 and save to a temporary variable
	let image_base64 = (open $png_path | encode base64)

	# Calculate the size of the base64 data
	let size = ($image_base64 | str length)

	let fixed_width = ( $image_base64 | str replace --all -r '(.{78})' "; $1\n" | str replace -r "(.{1,78})$" "; $1" )

	let img_encoded = [
		';'
		$"; thumbnail begin ($width)x($height) ($size)" 
		$"($fixed_width)"
		'; thumbnail end'
		';'
	]

	logd encoded ( $fixed_width | to text )

	mut gcode_content = open $gcode_path | lines

	$gcode_content
	| save --force ($gcode_path | path parse | upsert extension { 'gcode.bckp'} | path join)

	# Open the G-code file and embed the thumbnail
	$gcode_content = ( $gcode_content | insert 2 $img_encoded | flatten | flatten )
	$gcode_content | save --force ( $gcode_path )
}

export def create-gcode [
    config: string
    stl_path: string
    ] {


    let printer_config = ( './configs' | path expand | path join $config )

	let output_gcode = ($stl_path | path parse --extension 'stl' | upsert extension { 'gcode'} | path join)

	let args = [--load $printer_config --export-gcode --ensure-on-bed --output $output_gcode $stl_path]

	logd slicer-args ($args | to text)
	
	try { prusa-slicer ...$args } catch { log error 'slicer command issue' }

    return $output_gcode
}

def create-gcode-v1 [
    model: string@models
    part: string@parts
    version: string
    config: string
    ] {

    let printer_config = ( './configs' | path expand | path join $config )
    let input_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )
    let output_gcode = ( $env.TEMP | path expand | path join $"($part)-($version).gcode" )

	prusa-slicer --load $printer_config --export-gcode --output $output_gcode $input_stl

    return $output_gcode
}

def print-gcode-v1 [
    model: string@models
    part: string@parts
    version: string
	] {

	let input_gcode = ( $env.TEMP | path expand | path join $"($part)-($version).gcode" )
	let api_key = $env.3D_PRINTER_KEY
	let printer_ip = $env.3D_PRINTER_IP

 	#working !!!!
	let printer_url = $"http://($printer_ip)/api/v1/files/usb/($model)/($part)-($version).gcode"
	curl -X PUT --header $"X-Api-Key: ($api_key)" -H 'Print-After-Upload: ?0' -H 'Overwrite: ?0' -F $"file=@($input_gcode)" -F 'path=' $printer_url

}

def print-gcode [
    model: string@models
	gcode_path: string
	] {

	let gcode_name = ( $gcode_path | path basename )
	let api_key = $env.3D_PRINTER_KEY
	let printer_ip = $env.3D_PRINTER_IP

	logd gcode_name $gcode_name

 	#working !!!!
	let printer_url = $"http://($printer_ip)/api/v1/files/usb/($model)/($gcode_name)"
	curl -X PUT --header $"X-Api-Key: ($api_key)" -H 'Print-After-Upload: ?0' -H 'Overwrite: ?0' -F $"file=@($gcode_path)" -F 'path=' $printer_url

	logd printer_url $printer_url
}
