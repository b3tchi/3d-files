"""Exporting freecad model as stl."""
import sys
import FreeCAD as App
# import Mesh
import Part


def main(source_file, export_file):
    """Execute acttion."""
    document = App.openDocument(source_file)

    # export via mesh
    object_to_export = document.getObject('Body')
    # Mesh.export([object_to_export], export_file)

    Part.export([object_to_export], export_file)
    #export via another method
    # export via shape file is much larger
    # objectToExport=document.getObject('Body').Shape.exportStl(exportFile)

    App.closeDocument(document.Name)

    exit()

    sys.exit(1)
    # App.exit()


if len(sys.argv) != 5:
    print("Usage: freecad-linkstage3 --console <path_to_freecad_macro.py>\
 <input_path> <output_stl_path>")
    sys.exit(1)

input_fcstd_path = sys.argv[3]
output_stl_path = sys.argv[4]
#
print(len(sys.argv))
print(input_fcstd_path)
print(output_stl_path)
# main( sourceFile, exportFile)
main(input_fcstd_path, output_stl_path)

# sys.exit(1)
