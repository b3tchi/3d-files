export-env {
    $env.3D_PRINTER_IP = ''
    $env.3D_PRINTER_KEY = ''
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
export def --env printer-setup [
    url: string
    ] {
    $env.3D_PRINTER_IP = $url
    $env.3D_PRINTER_KEY = (input -s 'enter api key: ')

	alias "freecad-linkstage3" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240407\bin\FreeCADLink.exe
	alias "freecad-linkstage3 --console" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240407\bin\FreeCADCmd.exe
	alias slicer-prusa = prusa-slicer-console.exe
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

    let $version = part-version $model $part
    print $version
    let $file_stl = if $stl == null { create-stl $model $part $version } else { move-stl $model $part $version $stl }
    print $file_stl
    let $file_gcode = create-gcode $model $part $version $config
    print $file_gcode
	#printing code
	print-gcode $model $part $version

	return $file_gcode

}

def part-version [
    model: string@models
    part: string@parts
    ] {

    let branch = (git rev-parse --abbrev-ref HEAD)
    let tag_git = (git describe --tags --match $"($model)/($part)/*" --abbrev=0 HEAD)

    let tag_build = (if $tag_git  == '' { '0.1.0' } else { $tag_git })

    let time_stamp = (date now | format date %Y%m%d%H%M%S)
    let version = (if $branch == 'main' { $tag_build } else { [ $tag_build, '-next+', $time_stamp ] | str join })

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

def create-stl [
    model: string@models
    part: string@parts
    version: string
    ] {

    let macro = ( './macros' | path expand | path join 'export-to-stl.py' )
    let input_file = ( './models' | path expand | path join $model $part )
    let output_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )

    freecad-linkstage3 --console $macro $input_file $output_stl

    return $output_stl
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

    slicer-prusa --load $printer_config --export-gcode --output $output_gcode $input_stl

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
