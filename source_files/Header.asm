;Dragon Warrior NES Emulator Header File.
.org $0000

;----------------------------------------------------------------------------------------------------

;Bytes 0-3.
;      N    E    S   EOF
.byte $4E, $45, $53, $1A        ;ASCII NES followed by MS-DOS end-of-file.

;----------------------------------------------------------------------------------------------------

;Byte 4.
.byte $04                       ;PRG ROM size: 4 banks * 16KB = 64KB.

;----------------------------------------------------------------------------------------------------

;Byte 5.
.byte $02                       ;CHR ROM size: 2 banks * 8KB = 16KB.

;----------------------------------------------------------------------------------------------------

;76543210
;||||||||
;|||||||+- Mirroring: 0: horizontal (vertical arrangement) (CIRAM A10 = PPU A11)
;|||||||              1: vertical (horizontal arrangement) (CIRAM A10 = PPU A10)
;||||||+-- 1: Cartridge contains battery-backed PRG RAM ($6000-7FFF) or other persistent memory
;|||||+--- 1: 512-byte trainer at $7000-$71FF (stored before PRG data)
;||||+---- 1: Ignore mirroring control or above mirroring bit; instead provide four-screen VRAM
;++++----- Lower nybble of mapper number
;
;Byte 6.
.byte $12                       ;Battery backed up RAM, MMC1 mapper, horizontal mirroring.

;----------------------------------------------------------------------------------------------------

;76543210
;||||||||
;|||||||+- VS Unisystem
;||||||+-- PlayChoice-10 (8 KB of Hint Screen data stored after CHR data)
;||||++--- If equal to 2, flags 8-15 are in NES 2.0 format
;++++----- Upper nybble of mapper number
;
;Byte 7.
.byte $00                       ;NES 1.0 header format, MMC1 mapper.

;----------------------------------------------------------------------------------------------------

;76543210
;||||||||
;++++++++- PRG RAM size
;
;Byte 8.
.byte $00                       ;No PRG RAM.

;----------------------------------------------------------------------------------------------------

;76543210
;||||||||
;|||||||+- TV system (0: NTSC; 1: PAL)
;+++++++-- Reserved, set to zero
;
;Byte 9.
.byte $00                       ;NTSC.

;----------------------------------------------------------------------------------------------------

;76543210
;  ||  ||
;  ||  ++- TV system (0: NTSC; 2: PAL; 1/3: dual compatible)
;  |+----- PRG RAM ($6000-$7FFF) (0: present; 1: not present)
;  +------ 0: Board has no bus conflicts; 1: Board has bus conflicts
;  
;Byte 10.
.byte $00                       ;NTSC, no PRG RAM, no bus conflicts.

;----------------------------------------------------------------------------------------------------

;Bytes 11-15.
.byte $00, $00, $00, $00, $00   ;Unused.
