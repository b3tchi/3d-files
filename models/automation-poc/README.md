## scripts
### poc in nushell

#### current prerequisites
under windows need to do aliases under nu shell
```nu
alias "freecad-linkstage3" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240123\bin\FreeCADLink.exe
alias "freecad-linkstage3 --console" = C:\Users\czjabeck\Dev\Applications\Freecad-Linkstage3\py3.11-20240123\bin\FreeCADCmd.exe
alias slicer-prusa = prusa-slicer-console.exe
```

#### create stl
```nu
#linux path
cd /home/jan/repos/b3tchi/3d-files/feat/xmas-tree-adapters/
#win path
cd C:/Users/czjabeck/Dev/Repositories/b3tchi/3d-files/feat/xmas-tree-adapters/

let macro = ( './macros/export-to-stl.py' | path expand )
let input_file = ( './models/automation-poc/part-base' | path expand)
let output_stl = ( $env.TEMP | path join 'part-base.stl' | path expand)

freecad-linkstage3 --console $macro $input $output 
```
#### generate gcode
```nu
let printer_config = ( './models/automation-poc/config.ini' | path expand)
let input_stl = ( $env.TEMP | path join 'part-base.stl' | path expand)
let output_gcode = ( $env.TEMP | path join 'part_base.gcode' | path expand)

slicer-prusa --load $printer_config --export-gcode --output $output_gcode $input_stl
```

#### send to mini via curl
- nu https post don't know form date yet
- this is working one is to listen PrusaLink when connected to printer
- specification could be found in the [github](https://github.com/prusa3d/Prusa-Link-Web/blob/master/spec/openapi.yaml)
- to browse the specs i can use [swager editor](https://editor.swagger.io/)
- longer names are shortened there should be first get call to find shortened path but api works with long paths
- TODO upload automatically trigger print dialog on the printer which block some of the operations
  - :idea: maybe try run print imidiatly and then cancel it 
  - seems more people have this issue

```nu
let api_key = (input -s 'enter api key: ')
let input_gcode = ( $env.TEMP | path join 'part_base.gcode' | path expand)
let printer_ip = '192.168.1.224'

#working !!!!
let printer_url = $"http://($printer_ip)/api/v1/files/usb/test_upload/level3/anotherrr.gcode"
curl -X PUT --header $"X-Api-Key: ($api_key)" -H 'Print-After-Upload: ?0' -H 'Overwrite: ?0' -F $"file=@($input_gcode)" -F 'path=' $printer_url

```

### Notes


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

