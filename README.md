# dragon-warrior-disassembly

NES Dragon Warrior software disassembly. This project is now done! The entire game has been reverse engineered and commented. There are over 33,00 lines of code.

## NOTE

This project is part of my project [portfolio](https://nmikstas.github.io/portfolio/)

## Folder Structure

This project includes Ophis to assemble the source code.  
The source_files folder is where the actual disassembled game is located.  
The output_files folder is where the assembled binaries are located after the build script is run.  They should be identical to the original binary files.  
The completion_map folder contains an image file showing a visual representation of the completion of the disassembly.  

## Build Script

The build_script file can be run from Git bash to assemble the source files and do checksums on the output files and original files.  This file can be modified to produce a working ROM.  Also, if one were inclined to find the original dragon warrior NES ROM, they could include it in the root directory and run a checksum on the assembled ROM file...  
