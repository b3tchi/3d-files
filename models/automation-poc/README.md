## scripts
### preparation
#### current prerequisites in windows
under windows need to do aliases under nu shell
```nu
alias "freecad-linkstage3" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240407\bin\FreeCADLink.exe
alias "freecad-linkstage3 --console" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240407\bin\FreeCADCmd.exe
alias slicer-prusa = prusa-slicer-console.exe
```

#### ensure current workdir is root of repository
```nu
#linux path
cd /home/jan/repos/b3tchi/3d-files/feat/xmas-tree-adapters/
#win path
cd C:/Users/czjabeck/Dev/Repositories/b3tchi/3d-files/feat/xmas-tree-adapters/
```


### poc automated script
#### loading script module
```nu
source .\macros\prep-print.nu; use prep-print
```


### poc in nushell manual process


#### define model and part to print
```nu
let model = 'automation-poc'
let part = 'part-base'
```

#### get file version from git tag
```nu
let branch = (git rev-parse --abbrev-ref HEAD)
let tag_git = (git describe --tags --match $"($model)/($part)/*" --abbrev=0 HEAD)

let tag_build = (if $tag_git  == '' { '0.1.0' } else { $tag_git })

let time_stamp = (date now | format date %Y%m%d%H%M%S)
let version = (if $branch == 'main' { $tag_build } else { [ $tag_build, '-next+', $time_stamp ] | str join })
```

#### create stl
```nu
let macro = ( './macros' | path expand | path join 'export-to-stl.py' )
let input_file = ( './models' | path expand | path join $model $part )
let output_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )

freecad-linkstage3 --console $macro $input_file $output_stl
```
#### generate gcode
```nu
let printer_config = ( './configs' | path expand | path join $model prototype.ini )
let input_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )
let output_gcode = ( $env.TEMP | path expand | path join $"($part)-($version).gcode" )

slicer-prusa --load $printer_config --export-gcode --output $output_gcode $input_stl
```

#### preview in slicer-prusa
```nu
slicer-prusa $output_gcode
```

#### send to mini via curl
- nu https post don't know form date yet
- this is working one is to listen PrusaLink when connected to printer
- specification could be found in the [github](https://github.com/prusa3d/Prusa-Link-Web/blob/master/spec/openapi.yaml)
- to browse the specs i can use [swagger editor](https://editor.swagger.io/)
- longer names are shortened there should be first get call to find shortened path but api works with long paths
- TODO upload automatically trigger print dialog on the printer which block some of the operations
  - :idea: maybe try run print immediatly and then cancel it 
  - seems more people have this issue

```nu
let api_key = (input -s 'enter api key: ')
let input_gcode = ( $env.TEMP | path expand | path join $"($part)-($version).gcode" )
let printer_ip = '192.168.1.224'

#working !!!!
let printer_url = $"http://($printer_ip)/api/v1/files/usb/($model)/($part)-($version).gcode"
curl -X PUT --header $"X-Api-Key: ($api_key)" -H 'Print-After-Upload: ?0' -H 'Overwrite: ?0' -F $"file=@($input_gcode)" -F 'path=' $printer_url
```



### Work Notes


#### old api 
- old api not using v1 which is bit confusing
```nu
let printer_url = $"http://($printer_ip)/api/files/local/test_upload"
curl -X POST -H $"X-Api-Key: ($api_key)" -H 'Print-After-Upload: ?0' -H 'Overwrite: ?0' -F $"file=@($input_gcode)" -F 'path=' -F 'select=false' $printer_url
```
#### alternative using bash
```bash
freecad-linkstage3 --console $PWD/macros/export-to-stl.py
slicer-prusa --load /home/jan/Documents/config.ini --export-gcode --output /home/jan/Documents/test.gcode /home/jan/Documents/part-base.stl
```

