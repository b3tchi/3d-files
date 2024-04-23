## scripts
```bash
freecad-linkstage3 --console $PWD/macros/export-to-stl.py

slicer-prusa --load /home/jan/Documents/config.ini --export-gcode --output /home/jan/Documents/test.gcode /home/jan/Documents/part-base.stl
```

```nu
cd /home/jan/repos/b3tchi/3d-files/feat/xmas-tree-adapters/

let macro = ( './macros/export-to-stl.py' | path expand )
let input = ( './models/automation-poc/part-base' | path expand)
let output = ( /tmp/part-base.stl' | path expand)

freecad-linkstage3 --console $macro $input $output 

```
