#!/usr/bin/nu

export def xtest [] {
    return 'tex1'
}

export def print-gcode [
    model: string
    gcode_path: string
    api_key: string
    printer_ip: string
    ] {

    let gcode_name = ( $gcode_path | path basename )

    # logd gcode_name $gcode_name

    #working !!!!
    let printer_url = $"http://($printer_ip)/api/v1/files/usb/($model)/($gcode_name)"
    let args = [
        -X PUT
        --header $"X-Api-Key: ($api_key)"
        -H 'Print-After-Upload: ?0'
        -H 'Overwrite: ?0'
        -F $"file=@($gcode_path)"
        -F 'path=' $printer_url
    ]
    # curl -X PUT --header $"X-Api-Key: ($api_key)" -H 'Print-After-Upload: ?0' -H 'Overwrite: ?0' -F $"file=@($gcode_path)" -F 'path=' $printer_url
    return $args
    # logd printer_url $printer_url

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

    # logd encoded ( $fixed_width | to text )

    mut gcode_content = open $gcode_path | lines

    $gcode_content
    | save --force ($gcode_path | path parse | upsert extension { 'gcode.bckp'} | path join)

    # Open the G-code file and embed the thumbnail
    $gcode_content = ( $gcode_content | insert 2 $img_encoded | flatten | flatten )
    $gcode_content | save --force ( $gcode_path )
}

export def create-gcode [
    config_name: string
    stl_path: string
    ] {

    let printer_config = ( './configs' | path expand | path join $config_name )
    let output_gcode = ($stl_path | path parse --extension 'stl' | upsert extension { 'gcode'} | path join)
    let args = [
        --load $printer_config
        --export-gcode
        --ensure-on-bed
        --output $output_gcode
        $stl_path
    ]

    # logd slicer-args ($args | to text)

    # try { prusa-slicer ...$args } catch { log error 'slicer command issue' }

    return $args
}
export def last-tag-args [
    model: string
    part: string
    ] {

    let args = [
        describe
        --tags
        --match $"($model)/($part)/*"
        --abbrev=0
        HEAD
    ]

    return $args
}

export def create-stl [
    model: string
    part: string
    version: string
    tmp_path: string
    ] {

    let macro = ( './macros' | path expand | path join 'export-to-stl.py' )
    let input_file = ( './models' | path expand | path join $model $part )
    let output_stl = ( $tmp_path | path expand | path join $"($part)-($version).stl" )

    let args = [
        --console $macro
        $input_file
        $output_stl
    ]

    return $args
}

export def build-version [
    last_tag: string
    ] {

    let resp = if ($last_tag == '') {
            "0.1.0"
        } else {
            $last_tag | split row '/' | last
        }

    return $resp
}

export def build-base [
    model: string
    branch: string
    timestamp: string
    parts: list
    ] {

    let resp = $parts | uniq --count | rename part count
        | insert model $model
        | insert branch $branch
        | insert timestamp $timestamp

    return $resp
}

export def part-version [
    branch: string
    part: string
    version: string
    next_timestamp?: string
    ] {

    mut tag_parts = [$part '-' $version]
    if ($branch != 'main') {
        if ($next_timestamp == null) {
            $tag_parts = ( $tag_parts | append '-next' )
        } else {
            $tag_parts = ( $tag_parts | append '-next+' )
            $tag_parts = ( $tag_parts | append $next_timestamp )
        }
    }

    let version = ( $tag_parts | str join )

    return $version
}

export def build-short [
    branch: string
    part: string
    version: string
    count: int
    ] {

    let resp = $count
        | append $part | split row '-'
            | each {|word| $word | str substring 0..1}
        | append '@'
        | append $version
        | append (if ($branch != 'main') {'n'})
        | str join ''

    return $resp
}
# export def part-version-old [
#     model: string
#     part: string
#     tag_git: string
#     next_timestamp?: string
#     ] {

#     # let branch = (git rev-parse --abbrev-ref HEAD)
#     # logd branch $branch

#     # let tag_git = (git describe --tags --match $"($model)/($part)/*" --abbrev=0 HEAD)
#     let tag_build = (if $tag_git  == '' { '0.1.0' } else { $tag_git })

#     mut tag_parts = [$tag_build]
#     if ($branch != 'main') {
#         if ($next_timestamp == null) {
#             $tag_parts = ( $tag_parts | append '-next' )
#         } else {
#             $tag_parts = ( $tag_parts | append '-next+' )
#             $tag_parts = ( $tag_parts | append $next_timestamp )
#         }
#     }

#     let version = ( $tag_parts | str join )
#     # logd version ($version)

#     return $version
# }
