# three dimension printer alias  = tdpr scripts to manager printing
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
	let model_position = if ('--config' in $arguments) { 2 } else { 0 }
	let model = $arguments | get $model_position

	ls -s ($env.PWD | path join models $model ) | where type == dir |get name
}

export def --env printer-setup [
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

export def printer-check [] {
    print $"url:($env.3D_PRINTER_IP)"
    print $"api-key:($env.3D_PRINTER_KEY)"
 	let resp = http get --headers [X-Api-Key $env.3D_PRINTER_KEY] $"http://($env.3D_PRINTER_IP)/api/v1/status"
	return $resp.printer.state
}

export def send [
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
    let $file_gcode = create-gcode $model $part $version $config
    print $file_gcode
	#printing code
	print-gcode $model $part $version

	return $file_gcode

}


export def part-version [
    model: string@models
    part: string@parts
	next_timestamp?: string
    ] {

    let branch = (git rev-parse --abbrev-ref HEAD)
    let tag_git = (git describe --tags --match $"($model)/($part)/*" --abbrev=0 HEAD)

    let tag_build = (if $tag_git  == '' { '0.1.0' } else { $tag_git })

	mut tag_parts = [$tag_build]

	print $branch

	if ($branch != 'main') {

		if ($next_timestamp == null) {
			$tag_parts = ( $tag_parts | append '-next' )
		} else {
			$tag_parts = ( $tag_parts | append '-next+' )
			$tag_parts = ( $tag_parts | append $next_timestamp )
		}

	} else {
		print 'wtf'
	}

	print ($tag_parts)
    let version = ( $tag_parts | str join )

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

export def send-v2 [
    --config: string@configs
    model: string@models
    ...parts: string@parts-v2
    ] {

	log debug test
	log error test

	mut stls = []
	mut part_names = []

	let next_timestamp = (date now | format date %Y%m%d%H%M%S)

	let $config_name = if ($config == null) { 'prototype.ini' } else { $config }

	for $part in $parts {
		let file_version = part-version $model $part $next_timestamp 
		let name_version = part-version $model $part

		logd version $file_version

		$part_names = $part_names | append $"($part)-(if ( $parts | length ) > 1 { $name_version } else { $file_version})"
		let file_stl = create-stl $model $part $file_version

		logd stl_name $file_stl
		$stls = ( $stls | append $file_stl )
	}

	logd stls ($stls | to text)

	let part_names = $part_names | str join '-'
	let gcode_name = if (( $parts | length ) > 1) { 'multi-' + $next_timestamp + '-' + $part_names } else { $part_names }

	logd part_names ($part_names | to text)
	logd gcode_name $gcode_name

    let file_gcode = create-gcode-v2 $config_name $gcode_name $stls

	print $file_gcode
	#printing code
	#print-gcode $model $part $version

	return $file_gcode

}
def create-gcode-v2 [
    config: string
    gcode_name: string
    stls: list
    ] {


    let printer_config = ( './configs' | path expand | path join $config )
    # let input_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )
    let output_gcode = ( $env.TEMP | path expand | path join $"($gcode_name).gcode" )

	prusa-slicer --load $printer_config --export-gcode --output $output_gcode ...$stls

    return $output_gcode
}

def create-gcode [
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

def print-gcode [
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
