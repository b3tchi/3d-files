import sys
import FreeCAD as App
import Mesh

# sourceFile='/home/jan/repos/b3tchi/3d-files/main/models/assembly4-poc/assembly'
sourceFile='/home/jan/repos/b3tchi/3d-files/main/models/assembly4-poc/part-base'
exportFile='/home/jan/Documents/part-base.stl'

def main(sourceFile, exportFile):

    document=App.openDocument(sourceFile)

    # objectToExport=document.getObject('base')
    objectToExport=document.getObject('Body')

    Mesh.export([objectToExport], exportFile)

    App.closeDocument(document.Name)

    exit()
    # App.exit()

# if __name__ == "__main__":
#     # Expect two command line arguments:
#     # 1. Path to the input FCStd file
#     # 2. Path to the output STL file
#     if len(sys.argv) != 3:
#         print("Usage: freecad_cmd <path_to_freecad_macro.py> <input_path> <output_stl_path>")
#         sys.exit(1)
#
#     input_fcstd_path = sys.argv[1]
#     output_stl_path = sys.argv[2]
#
#     print(input_fcstd_path)
#     print(output_stl_path)
    # main( sourceFile, exportFile)
main( sourceFile, exportFile)
