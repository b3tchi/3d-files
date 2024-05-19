import sys
import FreeCAD as App
import Mesh

# sourceFile='/home/jan/repos/b3tchi/3d-files/main/models/assembly4-poc/assembly'
# sourceFile='/home/jan/repos/b3tchi/3d-files/main/models/assembly4-poc/part-base'
# exportFile='/home/jan/Documents/part-base.stl'

def main(sourceFile, exportFile):

    document=App.openDocument(sourceFile)

    #export via mesh
    objectToExport=document.getObject('Body')
    Mesh.export([objectToExport], exportFile)

    #export via shape file is much larger
    # objectToExport=document.getObject('Body').Shape.exportStl(exportFile)


    App.closeDocument(document.Name)

    exit()

    sys.exit(1)
    # App.exit()

# if __name__ == "__main__":
if len(sys.argv) != 5:
    print("Usage: freecad-linkstage3 --console <path_to_freecad_macro.py> <input_path> <output_stl_path>")
    sys.exit(1)
#     print("Usage: freecad_cmd <path_to_freecad_macro.py> <input_path> <output_stl_path>")

input_fcstd_path = sys.argv[3]
output_stl_path = sys.argv[4]
#
print(len(sys.argv))
print(input_fcstd_path)
print(output_stl_path)
    # main( sourceFile, exportFile)
main( input_fcstd_path, output_stl_path)

# sys.exit(1)
