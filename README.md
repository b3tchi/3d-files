## scripts
- example moved to automation-poc

#### loading script module
```nu
use .\macros\prep-print.nu
```

#### define model and part to print
```nu
let model = 'dactyl-case-v3'
let part = 'driver-part'
let version = 'test'
```

#### testing building model
```nu
let macro = ( './macros' | path expand | path join 'export-to-stl.py' )
let input_file = ( './models' | path expand | path join $model $part )
let output_stl = ( $env.TEMP | path expand | path join $"($part)-($version).stl" )

freecad-linkstage3 --console $macro $input_file $output_stl
```
