# dragon-warrior-disassembly
NES Dragon Warrior software disassembly

# NOTE
This project is part of my project portfolio: https://nmikstas.github.io/portfolio/

# Folder Structure
This project includes Ophis to assemble the source code.  
The original_files folder contains the binary images if the memory banks from the original game.  
The source_files folder is where the actual disassembled game is located.  
The output_files folder is where the assembled binaries are located after the build script is run.  They should be identical to the original binary files.  
The completion_map folder contains a bitmap showing a visual representation of the completion of the disassembly.  

# Build Script
The build_script file can be run from Git bash to assemble the source files and do checksums on the output files and original files.  This file can be modified to produce a working ROM.  Also, if one were inclined to find the original dragon warrior NES ROM, they could include it in the root directory and run a checksum on the assembled ROM file...  