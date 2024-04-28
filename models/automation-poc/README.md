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
cd /home/jan/repos/b3tchi/3d-files/feat/xmas-tree-adapters/

let macro = ( './macros/export-to-stl.py' | path expand )
let input_file = ( './models/automation-poc/part-base' | path expand)
let output_stl = ( $env.TMP | path join 'part-base.stl' | path expand)

freecad-linkstage3 --console $macro $input $output 
```
#### generate gcode
```nu
let printer_config = ( './models/automation-poc/config.ini' | path expand)
let input_stl = ( $env.TMP | path join 'part-base.stl' | path expand)
let output_gcode = ( $env.TMP | path join 'part_base.gcode' | path expand)

slicer-prusa --load $printer_config --export-gcode --output $output_gcode $input_stl
```

#### send to mini
```nu

```


### alternative using bash
```bash
freecad-linkstage3 --console $PWD/macros/export-to-stl.py

slicer-prusa --load /home/jan/Documents/config.ini --export-gcode --output /home/jan/Documents/test.gcode /home/jan/Documents/part-base.stl
```

