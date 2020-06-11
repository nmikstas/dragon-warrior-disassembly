.org $8000

.include "Dragon_Warrior_Defines.asm"

;--------------------------------------[ Forward declarations ]--------------------------------------

.alias GetSpclNPCType           $C0F4
.alias WordMultiply             $C1C9
.alias ByteDivide               $C1F0
.alias PalFadeOut               $C212
.alias PalFadeIn                $C529
.alias UpdateRandNum            $C55B
.alias CalcPPUBufAddr           $C596
.alias PrepSPPalLoad            $C632
.alias PrepBGPalLoad            $C63D
.alias AddPPUBufEntry           $C690
.alias ClearSpriteRAM           $C6BB
.alias IdleUpdate               $CB30
.alias CheckForEnding           $CBF7
.alias MapTargetTbl             $F461
.alias Bank1ToCHR0              $FC98
.alias Bank0ToCHR0              $FCA3
.alias Bank0ToCHR1              $FCA8
.alias Bank2ToCHR1              $FCAD
.alias WaitForNMI               $FF74
.alias _DoReset                 $FF8E

;-----------------------------------------[ Start of code ]------------------------------------------

;The following table contains functions called from bank 3 through the IRQ interrupt.

BankPointers:
L8000:  .word $0000             ;Unused.
L8002:  .word LoadStartPals     ;($AA7E)Load BG and sprite palettes for selecting saved game.
L8004:  .word LoadEndBossGFX    ;($BABD)Load final battle graphics.
L8006:  .word ItemCostTbl       ;($9947)Table of costs for shop items.
L8008:  .word DoSprites         ;($B6DA)Update player and NPC sprites.
L800A:  .word RemoveWindow      ;($A7A2)Remove window from screen.
L800C:  .word LoadCreditsPals   ;($AA62)Load palettes for end credits.
L800E:  .word DoPalFadeIn       ;($AA3D)Fade in palettes.
L8010:  .word DoPalFadeOut      ;($AA43)Fade out palettes.

BrecCvrdDatPtr:
L8012:  .word TantSLDat         ;($8D24)Pointer to Brecconary covered areas data.

GarinCvrdDatPtr:
L8014:  .word DgnLrdSL4Dat      ;($8EE6)Pointer to Garinham covered areas data.

CantCvrdDatPtr:
L8016:  .word SwampCaveDat+$32  ;($8FAE)Pointer to Cantlin covered areas data.

RimCvrdDatPtr:
L8018:  .word GarinCaveB3Dat+$E ;($9170)Pointer to Rimuldar covered areas data.

;----------------------------------------------------------------------------------------------------

MapDatTbl:                      ;Data for game maps.

;Unused. Map #$00.
L801A:  .word NULL              ;Map data pointer.
L801C:  .byte $00               ;Columns.
L801D:  .byte $00               ;Rows.
L801E:  .byte $00               ;Boundary block.

;Overworld. Map #$01.
L801F:  .word WrldMapPtrTbl     ;($A653)Pointer to row pointers.
L8021:  .byte $77               ;120 colums.
L8022:  .byte $77               ;120 rows.
L8023:  .byte $0F               ;Water.

;Dragonlord's castle - ground floor. Map #$02.
L8024:  .word DLCstlGFDat       ;($80B0)Pointer to map data.
L8026:  .byte $13               ;20 columns.
L8027:  .byte $13               ;20 rows.
L8028:  .byte $06               ;Swamp.

;Hauksness. Map #$03.
L8029:  .word HauksnessDat      ;($8178)Pointer to map data.
L802B:  .byte $13               ;20 columns.
L802C:  .byte $13               ;20 rows.
L802D:  .byte $01               ;Sand.

;Tantagel castle ground floor. Map #$04.
L802E:  .word TantGFDat         ;($8240)Pointer to map data.
L8030:  .byte $1D               ;30 columns.
L8031:  .byte $1D               ;30 rows.
L8032:  .byte $00               ;Grass.

;Throne room. Map #$05.
L8033:  .word ThrnRoomDat       ;($8402)Pointer to map data.
L8035:  .byte $09               ;10 columns.
L8036:  .byte $09               ;10 rows.
L8037:  .byte $15               ;Small tiles.

;Dragonlord's castle - bottom level. Map #$06.
L8038:  .word DgnLrdBLDat       ;($8434)Pointer to map data.
L803A:  .byte $1D               ;30 columns.
L803B:  .byte $1D               ;30 rows.
L803C:  .byte $0F               ;Water.

;Kol. Map #$07.
L803D:  .word KolDat            ;($85F6)Pointer to map data.
L803F:  .byte $17               ;24 columns.
L8040:  .byte $17               ;24 rows.
L8041:  .byte $0B               ;Trees.

;Brecconary. Map #$08.
L8042:  .word BrecconaryDat     ;($8716)Pointer to map data.
L8044:  .byte $1D               ;30 columns.
L8045:  .byte $1D               ;30 rows.
L8046:  .byte $00               ;Grass.

;Garinham. Map #$09.
L8047:  .word GarinhamDat       ;($8A9A)ointer to map data.
L8049:  .byte $13               ;20 columns.
L804A:  .byte $13               ;20 rows.
L804B:  .byte $00               ;Grass.

;Cantlin. Map #$0A.
L804C:  .word CantlinDat        ;($88D8)Pointer to map data.
L804E:  .byte $1D               ;30 columns.
L804F:  .byte $1D               ;30 rows.
L8050:  .byte $04               ;Brick.

;Rimuldar. Map #$0B.
L8051:  .word RimuldarDat       ;($8B62)Pointer to map data.
L8053:  .byte $1D               ;30 columns.
L8054:  .byte $1D               ;30 rows.
L8055:  .byte $00               ;Grass.

;Tantagel castle - sublevel. Map #$0C.
L8056:  .word TantSLDat         ;($8D24)Pointer to map data.
L8058:  .byte $09               ;10 columns.
L8059:  .byte $09               ;10 rows.
L805A:  .byte $10               ;Stone.

;Staff of rain cave. Map #$0D.
L805B:  .word RainCaveDat       ;($8D56)Pointer to map data.
L805D:  .byte $09               ;10 columns.
L805E:  .byte $09               ;10 rows.
L805F:  .byte $10               ;Stone.

;Rainbow drop cave. Map #$0E.
L8060:  .word DropCaveDat       ;($8D88)Pointer to map data.
L8062:  .byte $09               ;10 columns.
L8063:  .byte $09               ;10 rows.
L8064:  .byte $10               ;Stone.

;Dragonlord's castle - sublevel 1. Map #$0F.
L8065:  .word DgnLrdSL1Dat      ;($8DBA)Pointer to map data.
L8067:  .byte $13               ;20 columns.
L8068:  .byte $13               ;20 rows.
L8069:  .byte $10               ;Stone.

;Dragonlord's castle - sublevel 2. Map #$10.
L806A:  .word DgnLrdSL2Dat      ;($8E82)Pointer to map data.
L806C:  .byte $09               ;10 columns.
L806D:  .byte $09               ;10 rows.
L806E:  .byte $10               ;Stone.

;Dragonlord's castle - sublevel 3. Map #$11.
L806F:  .word DgnLrdSL3Dat      ;($8EB4)Pointer to map data.
L8071:  .byte $09               ;10 columns.
L8072:  .byte $09               ;10 rows.
L8073:  .byte $10               ;Stone.

;Dragonlord's castle - sublevel 4. Map #$12.
L8074:  .word DgnLrdSL4Dat      ;($8EE6)Pointer to map data.
L8076:  .byte $09               ;10 columns.
L8077:  .byte $09               ;10 rows.
L8078:  .byte $10               ;Stone.

;Dragonlord's castle - sublevel 5. Map #$13.
L8079:  .word DgnLrdSL5Dat      ;($8F18)Pointer to map data.
L807B:  .byte $09               ;10 columns.
L807C:  .byte $09               ;10 rows.
L807D:  .byte $10               ;Stone.

;Dragonlord's castle - sublevel 6. Map #$14.
L807E:  .word DgnLrdSL6Dat      ;($8F4A)Pointer to map data.
L8080:  .byte $09               ;10 columns.
L8081:  .byte $09               ;10 rows.
L8082:  .byte $10               ;Stone.

;Swamp cave. Map #$15.
L8083:  .word SwampCaveDat      ;($8F7C)Pointer to map data.
L8085:  .byte $05               ;6 columns.
L8086:  .byte $1D               ;30 rows.
L8087:  .byte $10               ;Stone.

;Rock mountain cave - B1. Map #$16.
L8088:  .word RckMtnB1Dat       ;($8FD6)Pointer to map data.
L808A:  .byte $0D               ;14 columns.
L808B:  .byte $0D               ;14 rows.
L808C:  .byte $10               ;Stone.

;Rock mountain cave - B2. Map #$17.
L808D:  .word RckMtnB2Dat       ;($9038)Pointer to map data.
L808F:  .byte $0D               ;14 columns.
L8090:  .byte $0D               ;14 rows.
L8091:  .byte $10               ;Stone.

;Cave of garinham - B1. Map #$18.
L8092:  .word GarinCaveB1Dat    ;($909A)Pointer to map data.
L8094:  .byte $13               ;20 columns.
L8095:  .byte $13               ;20 rows.
L8096:  .byte $10               ;Stone.

;Cave of garinham - B2. Map #$19.
L8097:  .word GarinCaveB2Dat    ;($925C)Pointer to map data.
L8099:  .byte $0D               ;14 columns.
L809A:  .byte $0B               ;12 rows.
L809B:  .byte $10               ;Stone.

;Cave of garinham - B3. Map #$1A.
L809C:  .word GarinCaveB3Dat    ;($9162)Pointer to map data.
L809E:  .byte $13               ;20 columns.
L809F:  .byte $13               ;20 rows.
L80A0:  .byte $10               ;Stone.

;Cave of garinham - B4. Map #$1B.
L80A1:  .word GarinCaveB4Dat    ;($922A)Pointer to map data.
L80A3:  .byte $09               ;10 columns.
L80A4:  .byte $09               ;10 rows.
L80A5:  .byte $10               ;Stone.

;Erdrick's cave - B1. Map #$1C.
L80A6:  .word ErdCaveB1Dat      ;($92B0)Pointer to map data.
L80A8:  .byte $09               ;10 columns.
L80A9:  .byte $09               ;10 rows.
L80AA:  .byte $10               ;Stone.

;Erdrick's cave - B2. Map #$1D.
L80AB:  .word ErdCaveB2Dat      ;($92E2)Pointer to map data.
L80AD:  .byte $09               ;10 columns.
L80AE:  .byte $09               ;10 rows.
L80AF:  .byte $10               ;Stone.

;----------------------------------------------------------------------------------------------------
;Each byte represents 2 tiles of information (upper nibble and lower nibble).  a total of 16
;different tile types are possible per map.  The tile mapping is different for different
;maps so the tile mapping is present above each map entry.

;Dragonlord's castle - ground floor. Map #$02.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
DLCstlGFDat:
L80B0:  .byte $99, $44, $49, $94, $44, $44, $44, $44, $44, $99 
L80BA:  .byte $94, $46, $44, $94, $AA, $7A, $A4, $66, $64, $49
L80C4:  .byte $44, $66, $64, $44, $AF, $FF, $A4, $64, $66, $44
L80CE:  .byte $46, $64, $66, $64, $AF, $6F, $A4, $66, $66, $64
L80D8:  .byte $46, $44, $44, $64, $AA, $AA, $A4, $46, $44, $64
L80E2:  .byte $46, $46, $66, $64, $AA, $AA, $A4, $66, $64, $64
L80EC:  .byte $46, $44, $64, $64, $46, $66, $44, $64, $66, $64
L80F6:  .byte $46, $46, $66, $66, $44, $A4, $46, $66, $64, $64
L8100:  .byte $46, $44, $B4, $46, $46, $66, $44, $4B, $44, $64
L810A:  .byte $46, $4A, $AA, $46, $44, $A4, $44, $AA, $A4, $64
L8114:  .byte $46, $4A, $4A, $46, $46, $66, $44, $A4, $A4, $64
L811E:  .byte $46, $4A, $AA, $46, $44, $A4, $44, $AA, $A4, $64
L8128:  .byte $46, $4A, $4A, $46, $66, $66, $44, $A4, $A4, $64
L8132:  .byte $46, $4A, $AA, $44, $44, $44, $44, $AA, $A4, $64
L813C:  .byte $46, $44, $74, $46, $66, $66, $64, $47, $44, $64
L8146:  .byte $46, $64, $44, $66, $46, $64, $66, $44, $46, $64
L8150:  .byte $44, $66, $66, $66, $66, $66, $66, $66, $66, $44
L815A:  .byte $94, $46, $66, $44, $46, $64, $44, $66, $64, $49
L8164:  .byte $99, $44, $44, $49, $46, $64, $94, $44, $44, $99
L816E:  .byte $99, $99, $99, $99, $46, $64, $99, $99, $99, $99

;Hauksness. Map #$03.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
HauksnessDat:
L8178:  .byte $44, $11, $04, $41, $44, $44, $44, $46, $64, $94
L8182:  .byte $41, $10, $84, $16, $6F, $64, $80, $01, $69, $94
L818C:  .byte $11, $18, $04, $46, $64, $64, $00, $06, $99, $14
L8196:  .byte $10, $00, $99, $44, $64, $44, $09, $06, $69, $11
L81A0:  .byte $11, $00, $09, $90, $60, $00, $80, $06, $60, $14
L81AA:  .byte $40, $66, $61, $91, $66, $61, $16, $61, $60, $04
L81B4:  .byte $40, $66, $66, $16, $61, $11, $66, $66, $60, $80
L81BE:  .byte $00, $66, $01, $11, $08, $00, $00, $00, $60, $08
L81C8:  .byte $40, $66, $01, $44, $44, $14, $66, $64, $64, $40
L81D2:  .byte $66, $16, $04, $66, $61, $14, $90, $46, $F9, $41
L81DC:  .byte $61, $66, $04, $44, $F4, $44, $09, $46, $99, $49
L81E6:  .byte $88, $66, $84, $11, $66, $64, $80, $44, $94, $49
L81F0:  .byte $80, $16, $84, $14, $64, $14, $88, $11, $99, $84
L81FA:  .byte $40, $61, $84, $66, $61, $11, $81, $04, $44, $41
L8204:  .byte $40, $66, $04, $46, $64, $44, $10, $04, $11, $14
L820E:  .byte $49, $16, $01, $18, $61, $66, $66, $16, $6F, $14
L8218:  .byte $99, $66, $00, $10, $68, $00, $00, $04, $64, $11
L8222:  .byte $19, $61, $66, $66, $10, $00, $90, $04, $44, $44
L822C:  .byte $49, $99, $00, $00, $00, $09, $99, $01, $11, $11
L8236:  .byte $11, $94, $44, $40, $49, $99, $94, $44, $14, $44

;Tantegel castle ground floor. Map #$04.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
TantGFDat:
L8240:  .byte $44, $44, $44, $40, $00, $00, $00, $04, $44, $44, $44, $04, $44, $08, $00
L824F:  .byte $46, $66, $66, $40, $80, $88, $08, $04, $66, $66, $64, $04, $64, $00, $00
L825E:  .byte $46, $66, $66, $40, $00, $00, $00, $04, $66, $66, $64, $04, $F4, $00, $00
L826D:  .byte $46, $64, $66, $44, $44, $66, $44, $44, $66, $46, $64, $00, $08, $80, $00
L827C:  .byte $46, $66, $66, $66, $66, $66, $66, $66, $66, $66, $64, $08, $88, $00, $00
L828B:  .byte $46, $66, $66, $44, $44, $44, $44, $44, $66, $66, $64, $00, $00, $00, $00
L829A:  .byte $44, $44, $46, $46, $66, $66, $66, $64, $44, $B4, $44, $44, $64, $44, $00
L82A9:  .byte $46, $66, $46, $45, $66, $66, $64, $64, $66, $66, $66, $66, $66, $64, $00
L82B8:  .byte $46, $66, $66, $46, $66, $66, $66, $64, $66, $66, $66, $66, $66, $64, $00
L82C7:  .byte $46, $66, $46, $44, $46, $66, $64, $44, $44, $44, $44, $44, $46, $64, $00
L82D6:  .byte $44, $44, $46, $48, $86, $66, $68, $84, $66, $46, $64, $66, $46, $64, $00
L82E5:  .byte $46, $66, $46, $48, $86, $66, $68, $84, $66, $46, $64, $66, $46, $64, $00
L82F4:  .byte $46, $66, $46, $48, $06, $66, $60, $84, $66, $66, $66, $66, $66, $64, $00
L8303:  .byte $43, $66, $B6, $40, $06, $66, $60, $04, $66, $66, $66, $66, $66, $64, $00
L8312:  .byte $46, $36, $46, $40, $06, $66, $60, $04, $66, $46, $64, $66, $46, $64, $00
L8321:  .byte $43, $63, $46, $40, $66, $66, $66, $04, $66, $46, $64, $66, $46, $64, $00
L8330:  .byte $44, $44, $46, $40, $62, $22, $26, $04, $44, $44, $44, $44, $46, $44, $00
L833F:  .byte $46, $66, $66, $66, $62, $AA, $26, $66, $66, $66, $64, $66, $66, $64, $00
L834E:  .byte $46, $66, $66, $66, $62, $AA, $26, $66, $66, $66, $64, $AA, $AA, $A4, $00
L835D:  .byte $44, $46, $64, $44, $62, $22, $26, $44, $66, $66, $64, $AA, $AA, $A4, $00
L836C:  .byte $46, $66, $66, $64, $66, $66, $66, $46, $66, $66, $64, $66, $66, $64, $00
L837B:  .byte $46, $66, $66, $64, $46, $66, $64, $44, $44, $46, $64, $66, $66, $64, $20
L838A:  .byte $46, $64, $66, $66, $46, $66, $64, $66, $66, $66, $64, $44, $44, $44, $20
L8399:  .byte $46, $66, $66, $66, $46, $66, $64, $66, $66, $66, $64, $22, $22, $22, $20
L83A8:  .byte $46, $22, $66, $46, $46, $66, $64, $66, $44, $44, $44, $22, $22, $22, $20
L83B7:  .byte $42, $22, $26, $66, $46, $66, $64, $66, $46, $64, $64, $22, $22, $22, $20
L83C6:  .byte $42, $22, $26, $66, $44, $66, $44, $66, $66, $6F, $64, $22, $22, $22, $20
L83D5:  .byte $42, $22, $22, $66, $46, $66, $64, $66, $46, $64, $64, $22, $22, $22, $20
L83E4:  .byte $44, $44, $44, $44, $44, $66, $44, $44, $44, $44, $44, $22, $22, $22, $20
L83F3:  .byte $22, $00, $00, $00, $00, $66, $00, $00, $00, $00, $22, $22, $22, $22, $27

;Throne room. Map #$05.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
ThrnRoomDat:
L8402:  .byte $44, $44, $44, $44, $44
L8407:  .byte $46, $66, $66, $36, $64
L840C:  .byte $46, $FF, $FF, $FF, $64
L8411:  .byte $46, $F6, $FF, $6F, $64
L8416:  .byte $46, $66, $33, $66, $64
L841B:  .byte $46, $66, $66, $66, $64
L8420:  .byte $46, $66, $66, $66, $64
L8425:  .byte $44, $44, $B4, $44, $44
L842A:  .byte $46, $66, $66, $66, $74
L842F:  .byte $44, $44, $44, $44, $44

;Dragonlord's castle - bottom level. Map #$06.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
DgnLrdBLDat:
L8434:  .byte $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22
L8443:  .byte $22, $24, $44, $42, $22, $22, $22, $44, $44, $44, $44, $42, $44, $42, $22
L8452:  .byte $22, $44, $66, $44, $44, $44, $44, $46, $66, $46, $66, $44, $46, $44, $22
L8461:  .byte $24, $46, $66, $64, $46, $66, $64, $66, $66, $66, $66, $64, $66, $64, $42
L8470:  .byte $24, $66, $66, $66, $44, $66, $44, $66, $66, $46, $66, $64, $64, $66, $42
L847F:  .byte $24, $66, $46, $66, $46, $66, $66, $66, $64, $44, $66, $66, $66, $66, $42
L848E:  .byte $24, $66, $66, $66, $46, $66, $64, $44, $44, $64, $44, $44, $64, $66, $42
L849D:  .byte $24, $46, $66, $64, $46, $66, $64, $66, $64, $44, $66, $64, $66, $64, $42
L84AC:  .byte $22, $44, $66, $44, $66, $66, $64, $46, $66, $66, $66, $44, $46, $44, $12
L84BB:  .byte $22, $24, $64, $46, $64, $44, $44, $44, $66, $46, $64, $41, $46, $41, $12
L84CA:  .byte $22, $24, $66, $66, $64, $66, $66, $64, $46, $66, $44, $11, $11, $11, $22
L84D9:  .byte $22, $24, $64, $44, $44, $63, $66, $64, $44, $64, $41, $12, $11, $12, $22
L84E8:  .byte $22, $24, $64, $66, $64, $63, $36, $66, $6B, $64, $11, $22, $22, $1E, $12
L84F7:  .byte $22, $24, $64, $64, $64, $63, $33, $64, $44, $64, $41, $22, $22, $22, $02
L8506:  .byte $22, $24, $64, $66, $64, $66, $66, $64, $46, $66, $42, $22, $12, $29, $02
L8515:  .byte $22, $24, $64, $64, $64, $44, $44, $44, $66, $64, $42, $12, $91, $E1, $22
L8524:  .byte $22, $24, $64, $66, $64, $46, $66, $66, $66, $44, $22, $22, $00, $22, $22
L8533:  .byte $22, $24, $64, $64, $64, $66, $64, $44, $64, $42, $22, $12, $29, $12, $22
L8542:  .byte $22, $24, $64, $66, $64, $66, $44, $24, $44, $22, $21, $12, $19, $02, $12
L8551:  .byte $22, $24, $64, $64, $64, $64, $42, $22, $22, $22, $11, $22, $11, $01, $12
L8560:  .byte $22, $24, $64, $66, $64, $64, $22, $24, $44, $22, $22, $21, $19, $91, $22
L856F:  .byte $22, $44, $64, $46, $44, $64, $42, $44, $64, $42, $22, $11, $00, $91, $12
L857E:  .byte $24, $46, $66, $46, $46, $66, $44, $46, $66, $44, $22, $14, $46, $44, $12
L858D:  .byte $24, $66, $66, $66, $66, $66, $44, $6F, $F6, $64, $44, $44, $66, $64, $12
L859C:  .byte $24, $66, $46, $64, $46, $66, $46, $6F, $66, $66, $66, $66, $66, $64, $02
L85AB:  .byte $24, $66, $66, $64, $44, $64, $44, $6F, $F6, $64, $44, $44, $66, $64, $02
L85BA:  .byte $24, $46, $66, $44, $24, $64, $24, $46, $66, $44, $22, $94, $44, $44, $12
L85C9:  .byte $22, $44, $64, $42, $24, $64, $22, $44, $64, $42, $22, $11, $99, $91, $12
L85D8:  .byte $22, $24, $44, $22, $94, $64, $92, $24, $44, $22, $22, $21, $11, $11, $22
L85E7:  .byte $22, $22, $22, $29, $94, $54, $99, $22, $22, $22, $22, $22, $22, $22, $22

;Kol. Map #$07.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
KolDat:
L85F6:  .byte $44, $40, $88, $84, $44, $44, $88, $88, $88, $88, $44, $44
L8602:  .byte $46, $40, $08, $84, $66, $64, $88, $88, $88, $4D, $46, $64
L860E:  .byte $4F, $49, $08, $86, $62, $66, $11, $11, $11, $66, $66, $64
L861A:  .byte $96, $99, $08, $84, $66, $64, $81, $88, $88, $4F, $44, $44
L8626:  .byte $99, $90, $04, $44, $46, $44, $81, $88, $88, $46, $48, $88
L8632:  .byte $09, $00, $04, $88, $88, $88, $81, $88, $88, $44, $48, $88
L863E:  .byte $00, $00, $84, $88, $88, $88, $81, $88, $88, $88, $88, $08
L864A:  .byte $80, $08, $84, $88, $88, $88, $81, $88, $88, $80, $00, $08
L8656:  .byte $88, $44, $44, $44, $88, $88, $11, $18, $88, $00, $08, $00
L8662:  .byte $88, $88, $88, $84, $88, $81, $11, $11, $88, $80, $80, $08
L866E:  .byte $44, $44, $48, $84, $88, $11, $11, $11, $18, $44, $44, $44
L867A:  .byte $46, $66, $48, $84, $81, $11, $11, $11, $11, $46, $64, $64
L8686:  .byte $46, $66, $48, $1B, $11, $11, $11, $11, $11, $66, $6F, $64
L8692:  .byte $46, $66, $48, $14, $81, $11, $11, $11, $11, $46, $64, $64
L869E:  .byte $4B, $44, $46, $14, $88, $11, $11, $11, $18, $44, $44, $44
L86AA:  .byte $46, $46, $66, $64, $88, $81, $11, $11, $88, $88, $88, $88
L86B6:  .byte $46, $46, $44, $44, $44, $48, $11, $18, $88, $88, $88, $88
L86C2:  .byte $46, $66, $46, $66, $66, $48, $81, $88, $88, $44, $44, $88
L86CE:  .byte $46, $46, $46, $06, $06, $48, $81, $11, $11, $11, $14, $88
L86DA:  .byte $46, $46, $66, $66, $66, $48, $44, $44, $48, $11, $14, $88
L86E6:  .byte $46, $66, $46, $66, $66, $44, $46, $63, $48, $11, $14, $88
L86F2:  .byte $44, $64, $46, $06, $06, $66, $6F, $63, $48, $81, $88, $88
L86FE:  .byte $80, $00, $46, $66, $66, $44, $46, $63, $48, $81, $88, $88
L870A:  .byte $88, $00, $44, $44, $44, $48, $44, $44, $48, $81, $88, $88

;Brecconary. Map #$08.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
BrecconaryDat:
L8716:  .byte $44, $44, $44, $44, $44, $44, $41, $66, $14, $44, $44, $44, $44, $44, $44
L8725:  .byte $48, $88, $00, $00, $88, $88, $11, $66, $11, $88, $88, $88, $88, $88, $84
L8734:  .byte $48, $80, $00, $00, $08, $08, $01, $66, $10, $08, $44, $44, $44, $44, $84
L8743:  .byte $48, $04, $44, $44, $00, $00, $00, $66, $00, $08, $46, $64, $62, $24, $84
L8752:  .byte $48, $04, $66, $64, $00, $00, $00, $66, $10, $00, $46, $6F, $62, $24, $84
L8761:  .byte $48, $04, $6F, $64, $00, $00, $00, $66, $10, $80, $46, $64, $62, $24, $84
L8770:  .byte $48, $04, $46, $44, $00, $11, $00, $66, $11, $80, $4B, $44, $44, $44, $04
L877F:  .byte $48, $00, $06, $C0, $01, $11, $10, $66, $10, $80, $00, $08, $00, $80, $04
L878E:  .byte $48, $80, $06, $00, $11, $81, $10, $66, $10, $00, $00, $88, $88, $88, $04
L879D:  .byte $48, $00, $06, $00, $18, $88, $11, $66, $00, $44, $44, $44, $44, $48, $04
L87AC:  .byte $48, $00, $06, $01, $11, $88, $81, $66, $00, $46, $66, $46, $66, $40, $04
L87BB:  .byte $40, $00, $06, $01, $18, $88, $10, $66, $00, $46, $66, $46, $66, $40, $04
L87CA:  .byte $48, $80, $06, $00, $11, $11, $10, $66, $00, $44, $64, $44, $64, $40, $84
L87D9:  .byte $88, $00, $06, $00, $00, $11, $00, $66, $00, $00, $60, $00, $60, $00, $88
L87E8:  .byte $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66
L87F7:  .byte $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66
L8806:  .byte $88, $00, $00, $00, $60, $00, $08, $06, $00, $08, $00, $00, $02, $22, $88
L8815:  .byte $48, $80, $00, $00, $60, $00, $88, $06, $08, $88, $80, $22, $22, $22, $28
L8824:  .byte $48, $00, $00, $00, $60, $08, $80, $06, $88, $80, $02, $22, $22, $22, $22
L8833:  .byte $40, $00, $00, $4D, $64, $00, $00, $06, $08, $00, $22, $22, $22, $22, $22
L8842:  .byte $40, $44, $44, $44, $64, $44, $00, $06, $80, $02, $22, $20, $02, $22, $22
L8851:  .byte $40, $46, $64, $66, $6F, $64, $00, $06, $00, $22, $00, $00, $00, $02, $22
L8860:  .byte $40, $46, $64, $64, $44, $44, $08, $06, $66, $E0, $00, $00, $00, $00, $02
L886F:  .byte $40, $46, $6B, $66, $66, $64, $08, $00, $00, $20, $04, $64, $44, $48, $02
L887E:  .byte $40, $46, $44, $64, $46, $64, $08, $80, $02, $20, $04, $66, $46, $48, $02
L888D:  .byte $40, $46, $64, $66, $46, $64, $88, $88, $02, $22, $04, $66, $F6, $40, $22
L889C:  .byte $40, $46, $64, $66, $46, $64, $08, $80, $02, $20, $04, $66, $46, $40, $82
L88AB:  .byte $40, $44, $44, $44, $44, $44, $08, $00, $22, $22, $04, $44, $44, $48, $82
L88BA:  .byte $40, $00, $00, $00, $00, $00, $00, $02, $22, $22, $00, $00, $02, $28, $22
L88C9:  .byte $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $22, $22, $22, $22, $22

;Cantlin. Map #$0A.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
CantlinDat:
L88D8:  .byte $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66
L88E7:  .byte $64, $44, $66, $44, $44, $44, $44, $66, $C1, $11, $11, $11, $16, $44, $46
L88F6:  .byte $64, $66, $66, $46, $64, $66, $64, $66, $11, $44, $44, $44, $16, $46, $46
L8905:  .byte $64, $44, $66, $46, $64, $66, $64, $66, $88, $46, $64, $64, $16, $46, $46
L8914:  .byte $66, $66, $66, $44, $F4, $64, $44, $66, $66, $66, $6F, $64, $16, $66, $66
L8923:  .byte $66, $66, $66, $46, $66, $66, $64, $66, $66, $66, $6F, $64, $16, $44, $46
L8932:  .byte $64, $44, $66, $44, $64, $46, $64, $66, $88, $46, $64, $64, $16, $46, $46
L8941:  .byte $64, $6F, $66, $1D, $11, $46, $64, $66, $11, $44, $44, $44, $16, $4F, $46
L8950:  .byte $64, $44, $66, $11, $11, $44, $44, $66, $11, $11, $11, $11, $16, $46, $46
L895F:  .byte $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $B6, $46
L896E:  .byte $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $64, $46, $46
L897D:  .byte $64, $44, $66, $44, $46, $60, $22, $20, $00, $06, $64, $44, $44, $66, $46
L898C:  .byte $64, $6F, $66, $F6, $46, $62, $22, $22, $00, $06, $64, $64, $6F, $66, $46
L899B:  .byte $64, $44, $66, $44, $46, $62, $28, $22, $20, $06, $6F, $64, $64, $66, $46
L89AA:  .byte $64, $6F, $66, $66, $66, $60, $22, $20, $22, $06, $64, $44, $44, $44, $46
L89B9:  .byte $64, $44, $64, $44, $46, $60, $00, $00, $0E, $06, $66, $66, $66, $66, $66
L89C8:  .byte $64, $66, $64, $66, $46, $60, $00, $00, $02, $06, $66, $66, $66, $66, $66
L89D7:  .byte $64, $66, $66, $66, $46, $60, $00, $00, $22, $06, $64, $44, $66, $44, $46
L89E6:  .byte $64, $44, $44, $44, $46, $60, $00, $22, $22, $26, $6F, $64, $66, $66, $46
L89F5:  .byte $66, $66, $66, $66, $66, $60, $02, $22, $82, $26, $64, $44, $66, $46, $46
L8A04:  .byte $66, $66, $66, $66, $66, $60, $22, $28, $82, $26, $66, $66, $66, $44, $46
L8A13:  .byte $64, $44, $B4, $44, $46, $60, $22, $88, $22, $06, $64, $44, $66, $66, $66
L8A22:  .byte $64, $11, $11, $11, $46, $60, $02, $22, $20, $06, $64, $64, $44, $46, $46
L8A31:  .byte $64, $11, $11, $11, $46, $60, $00, $22, $00, $06, $64, $F4, $66, $66, $46
L8A40:  .byte $64, $44, $44, $11, $46, $66, $46, $66, $64, $66, $64, $64, $46, $44, $46
L8A4F:  .byte $64, $66, $64, $11, $B6, $44, $44, $BB, $44, $44, $66, $64, $66, $43, $46
L8A5E:  .byte $64, $66, $6F, $11, $46, $4A, $AA, $AA, $AA, $A4, $64, $66, $66, $F6, $46
L8A6D:  .byte $64, $36, $64, $11, $46, $4A, $44, $44, $44, $A4, $64, $64, $66, $43, $46
L8A7C:  .byte $64, $44, $44, $44, $46, $4A, $AA, $66, $AA, $A4, $64, $44, $44, $44, $46
L8A8B:  .byte $66, $66, $66, $66, $66, $44, $44, $44, $44, $44, $66, $66, $66, $66, $66

;Garinham. Map #$09.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
GarinhamDat:
L8A9A:  .byte $22, $46, $66, $66, $66, $66, $66, $66, $22, $47
L8AA4:  .byte $22, $46, $11, $11, $11, $11, $11, $16, $6E, $66
L8AAE:  .byte $44, $46, $44, $44, $44, $44, $44, $44, $42, $44
L8AB8:  .byte $46, $66, $66, $66, $66, $66, $64, $44, $42, $22
L8AC2:  .byte $46, $44, $44, $46, $66, $66, $62, $22, $42, $44
L8ACC:  .byte $46, $46, $66, $46, $33, $66, $64, $22, $22, $24
L8AD6:  .byte $46, $44, $B4, $46, $36, $66, $64, $24, $24, $24
L8AE0:  .byte $46, $66, $66, $66, $66, $66, $66, $66, $66, $64
L8AEA:  .byte $46, $66, $66, $66, $66, $66, $66, $66, $66, $64
L8AF4:  .byte $44, $44, $44, $44, $44, $44, $44, $44, $66, $64
L8AFE:  .byte $24, $66, $46, $48, $88, $88, $88, $84, $4B, $44
L8B08:  .byte $24, $66, $F6, $48, $80, $66, $60, $88, $86, $88
L8B12:  .byte $44, $64, $44, $48, $00, $68, $66, $66, $66, $66
L8B1C:  .byte $00, $60, $00, $00, $66, $66, $60, $06, $00, $00
L8B26:  .byte $66, $66, $66, $66, $60, $60, $00, $D6, $44, $48
L8B30:  .byte $88, $80, $60, $80, $00, $6C, $00, $46, $F6, $44
L8B3A:  .byte $44, $44, $64, $81, $44, $64, $40, $46, $44, $44
L8B44:  .byte $24, $66, $64, $41, $46, $F6, $40, $46, $46, $64
L8B4E:  .byte $24, $44, $44, $24, $46, $66, $40, $46, $66, $64
L8B58:  .byte $22, $22, $22, $22, $44, $44, $40, $44, $44, $44

;Rimuldar. Map #$0B.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Trees, $9-Poison, $A-Force Field,
;$B-Door, $C-Weapon Shop Sign, $D-Inn Sign, $E-Bridge, $F-Large Tile.
RimuldarDat:
L8B62:  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
L8B71:  .byte $00, $02, $22, $22, $22, $22, $22, $22, $22, $00, $00, $00, $00, $00, $00
L8B80:  .byte $02, $22, $44, $48, $80, $00, $00, $00, $02, $22, $20, $00, $00, $00, $00
L8B8F:  .byte $0E, $00, $66, $48, $00, $00, $08, $88, $00, $08, $22, $22, $00, $00, $00
L8B9E:  .byte $22, $00, $66, $40, $00, $06, $66, $66, $66, $68, $80, $02, $22, $20, $00
L8BAD:  .byte $28, $46, $66, $40, $80, $06, $08, $06, $11, $60, $00, $00, $88, $20, $00
L8BBC:  .byte $28, $44, $F4, $40, $04, $46, $44, $46, $44, $60, $04, $44, $44, $20, $00
L8BCB:  .byte $20, $46, $66, $40, $04, $66, $64, $66, $64, $60, $04, $66, $64, $22, $00
L8BDA:  .byte $20, $44, $44, $40, $04, $66, $64, $66, $64, $68, $04, $4F, $44, $12, $00
L8BE9:  .byte $20, $00, $00, $00, $04, $44, $44, $44, $44, $66, $66, $66, $64, $12, $00
L8BF8:  .byte $20, $00, $00, $02, $28, $00, $00, $08, $00, $60, $C4, $66, $64, $12, $00
L8C07:  .byte $20, $80, $22, $22, $22, $00, $06, $66, $66, $66, $04, $66, $64, $12, $20
L8C16:  .byte $21, $02, $28, $88, $22, $08, $66, $66, $66, $66, $04, $44, $44, $80, $20
L8C25:  .byte $21, $22, $80, $08, $20, $06, $66, $00, $00, $66, $00, $00, $88, $88, $20
L8C34:  .byte $21, $11, $80, $82, $20, $66, $60, $08, $00, $66, $66, $66, $66, $66, $E6
L8C43:  .byte $21, $22, $88, $22, $00, $66, $00, $88, $00, $66, $66, $66, $66, $66, $E6
L8C52:  .byte $21, $02, $22, $20, $00, $66, $08, $80, $4D, $60, $08, $80, $08, $88, $20
L8C61:  .byte $20, $80, $00, $08, $00, $66, $00, $84, $44, $64, $44, $44, $44, $80, $20
L8C70:  .byte $20, $00, $00, $88, $80, $66, $08, $84, $6F, $64, $66, $46, $64, $02, $20
L8C7F:  .byte $20, $44, $44, $44, $44, $66, $40, $84, $44, $66, $66, $66, $64, $02, $00
L8C8E:  .byte $20, $46, $66, $66, $66, $66, $40, $04, $66, $66, $66, $46, $64, $82, $00
L8C9D:  .byte $20, $46, $66, $64, $66, $66, $40, $84, $46, $44, $4B, $44, $44, $82, $00
L8CAC:  .byte $20, $44, $46, $64, $66, $66, $40, $14, $66, $64, $66, $46, $64, $22, $00
L8CBB:  .byte $28, $46, $F6, $66, $64, $46, $40, $14, $66, $64, $66, $B6, $34, $20, $00
L8CCA:  .byte $28, $44, $46, $64, $66, $66, $40, $14, $44, $44, $44, $44, $44, $20, $00
L8CD9:  .byte $22, $46, $66, $64, $66, $66, $48, $11, $11, $80, $08, $82, $22, $20, $00
L8CE8:  .byte $02, $46, $66, $66, $66, $66, $48, $80, $08, $00, $22, $22, $00, $00, $00
L8CF7:  .byte $02, $44, $44, $44, $44, $44, $48, $88, $82, $22, $20, $00, $00, $00, $00
L8D06:  .byte $00, $02, $22, $22, $22, $22, $22, $22, $22, $00, $00, $00, $00, $00, $00
L8D15:  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

;Tantagel castle - sublevel. Map #$0C.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Grass, $9-Sand, $A-Water,
;$B-Treasure Chest, $C-Stone, $D-Stairs Up, $E-Brick, $F-Stairs Down.
TantSLDat:
L8D24:  .byte $46, $66, $66, $66, $64
L8D29:  .byte $64, $66, $66, $66, $46
L8D2E:  .byte $66, $66, $66, $66, $66
L8D33:  .byte $66, $64, $44, $46, $66
L8D38:  .byte $56, $64, $66, $46, $66
L8D3D:  .byte $66, $64, $36, $46, $66
L8D42:  .byte $66, $64, $66, $46, $66
L8D47:  .byte $66, $66, $66, $66, $66
L8D4C:  .byte $EC, $EE, $EE, $EE, $46
L8D51:  .byte $46, $66, $66, $66, $64

;Staff of rain cave. Map #$0D.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Grass, $9-Sand, $A-Water,
;$B-Treasure Chest, $C-Stone, $D-Stairs Up, $E-Brick, $F-Stairs Down.
RainCaveDat:
L8D56:  .byte $46, $66, $66, $66, $64
L8D5B:  .byte $EE, $EE, $EE, $EE, $66
L8D60:  .byte $66, $44, $44, $44, $66
L8D65:  .byte $66, $46, $64, $64, $66
L8D6A:  .byte $EE, $CB, $EE, $EE, $66
L8D6F:  .byte $66, $46, $64, $64, $66
L8D74:  .byte $66, $44, $44, $44, $66
L8D79:  .byte $EE, $EE, $EE, $EE, $66
L8D7E:  .byte $46, $66, $66, $66, $64
L8D83:  .byte $44, $44, $56, $44, $44

;Rainbow drop cave. Map #$0E.
;Tile mapping: $0-Grass, $1-Sand, $2-Water, $3-Treasure Chest, $4-Stone,
;$5-Stairs Up, $6-Brick, $7-Stairs Down, $8-Grass, $9-Sand, $A-Water,
;$B-Treasure Chest, $C-Stone, $D-Stairs Up, $E-Brick, $F-Stairs Down.
DropCaveDat:
L8D88:  .byte $C6, $EE, $EE, $EE, $66
L8D8D:  .byte $46, $64, $64, $64, $66
L8D92:  .byte $46, $44, $66, $64, $46
L8D97:  .byte $46, $66, $44, $46, $66
L8D9C:  .byte $56, $46, $46, $46, $46
L8DA1:  .byte $66, $46, $63, $46, $46
L8DA6:  .byte $46, $66, $44, $46, $66
L8DAB:  .byte $46, $44, $66, $64, $46
L8DB0:  .byte $46, $64, $64, $64, $66
L8DB5:  .byte $46, $66, $66, $66, $66

;Dragonlord's castle - sublevel 1. Map #$0F.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
DgnLrdSL1Dat:
L8DBA:  .byte $22, $22, $22, $22, $01, $02, $22, $02, $22, $22
L8DC4:  .byte $20, $00, $00, $22, $02, $22, $02, $03, $00, $02
L8DCE:  .byte $20, $22, $20, $02, $00, $00, $02, $00, $02, $22
L8DD8:  .byte $20, $22, $22, $02, $22, $22, $22, $00, $22, $02
L8DE2:  .byte $20, $32, $02, $00, $22, $22, $20, $02, $20, $00
L8DEC:  .byte $20, $00, $02, $20, $00, $00, $00, $22, $00, $22
L8DF6:  .byte $22, $22, $00, $20, $22, $22, $02, $20, $02, $22
L8E00:  .byte $00, $22, $02, $20, $02, $20, $03, $20, $22, $03
L8E0A:  .byte $20, $02, $02, $00, $22, $22, $00, $00, $22, $00
L8E14:  .byte $22, $22, $02, $02, $20, $02, $20, $30, $02, $02
L8E1E:  .byte $20, $00, $02, $02, $20, $02, $20, $22, $02, $02
L8E28:  .byte $20, $22, $22, $00, $22, $22, $00, $22, $02, $02
L8E32:  .byte $20, $20, $22, $20, $02, $20, $02, $20, $02, $02
L8E3C:  .byte $20, $20, $00, $20, $12, $22, $02, $22, $22, $02
L8E46:  .byte $20, $30, $22, $20, $00, $00, $00, $02, $00, $02
L8E50:  .byte $20, $00, $20, $00, $22, $22, $22, $22, $01, $22
L8E5A:  .byte $20, $22, $22, $22, $20, $00, $02, $00, $02, $22
L8E64:  .byte $20, $22, $00, $00, $22, $20, $22, $22, $02, $22
L8E6E:  .byte $20, $00, $02, $20, $00, $20, $00, $02, $22, $02
L8E78:  .byte $22, $22, $22, $22, $30, $22, $22, $22, $02, $22

;Dragonlord's castle - sublevel 2. Map #$10.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
DgnLrdSL2Dat:
L8E82:  .byte $12, $03, $01, $20, $12
L8E87:  .byte $18, $0A, $88, $A0, $03
L8E8C:  .byte $00, $22, $20, $22, $00
L8E91:  .byte $22, $20, $00, $02, $22
L8E96:  .byte $28, $88, $9A, $82, $02
L8E9B:  .byte $20, $20, $24, $00, $02
L8EA0:  .byte $22, $20, $00, $02, $22
L8EA5:  .byte $08, $AA, $8A, $A2, $00
L8EAA:  .byte $30, $02, $00, $20, $01
L8EAF:  .byte $23, $02, $22, $20, $12

;Dragonlord's castle - sublevel 3. Map #$11.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
DgnLrdSL3Dat:
L8EB4:  .byte $2A, $AA, $AA, $81, $22
L8EB9:  .byte $20, $00, $22, $00, $02
L8EBE:  .byte $20, $10, $22, $22, $22
L8EC3:  .byte $28, $A8, $88, $A0, $02
L8EC8:  .byte $20, $22, $01, $22, $02
L8ECD:  .byte $20, $02, $00, $02, $02
L8ED2:  .byte $23, $02, $22, $00, $02
L8ED7:  .byte $00, $00, $02, $23, $02
L8EDC:  .byte $22, $22, $00, $00, $02
L8EE1:  .byte $12, $02, $22, $22, $22

;Dragonlord's castle - sublevel 4. Map #$12.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
DgnLrdSL4Dat:
L8EE6:  .byte $22, $22, $22, $22, $22
L8EEB:  .byte $20, $00, $00, $02, $32
L8EF0:  .byte $20, $32, $22, $22, $22
L8EF5:  .byte $20, $00, $02, $22, $02
L8EFA:  .byte $22, $22, $02, $22, $02
L8EFF:  .byte $20, $02, $00, $02, $02
L8F04:  .byte $88, $AA, $AA, $8A, $8A
L8F09:  .byte $8A, $AA, $8A, $89, $8A
L8F0E:  .byte $AA, $A8, $8A, $88, $8A
L8F13:  .byte $9A, $88, $AA, $AA, $AA

;Dragonlord's castle - sublevel 5. Map #$13.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
DgnLrdSL5Dat:
L8F18:  .byte $B8, $A8, $9A, $AA, $89
L8F1D:  .byte $A8, $A8, $88, $8A, $8A
L8F22:  .byte $A8, $AA, $AA, $8A, $8A
L8F27:  .byte $A8, $A8, $8A, $8A, $8A
L8F2C:  .byte $A8, $A8, $AA, $8A, $8A
L8F31:  .byte $A8, $A8, $AB, $8A, $8A
L8F36:  .byte $A8, $A8, $88, $8A, $8A
L8F3B:  .byte $A8, $AA, $AA, $AA, $8A
L8F40:  .byte $A8, $88, $88, $88, $8A
L8F45:  .byte $AA, $AA, $AA, $AA, $AA

;Dragonlord's castle - sublevel 6. Map #$14.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
DgnLrdSL6Dat:
L8F4A:  .byte $12, $22, $22, $22, $23
L8F4F:  .byte $00, $00, $08, $80, $88
L8F54:  .byte $00, $00, $00, $00, $00
L8F59:  .byte $00, $00, $00, $00, $00
L8F5E:  .byte $02, $22, $22, $22, $20
L8F63:  .byte $02, $22, $22, $22, $20
L8F68:  .byte $12, $22, $22, $22, $23
L8F6D:  .byte $02, $22, $22, $22, $20
L8F72:  .byte $02, $22, $22, $22, $20
L8F77:  .byte $00, $00, $00, $00, $00

;Swamp cave. Map #$15.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
SwampCaveDat:
L8F7C:  .byte $12, $22, $22
L8F7F:  .byte $20, $02, $00
L8F82:  .byte $20, $22, $02
L8F85:  .byte $20, $02, $22
L8F88:  .byte $22, $22, $02
L8F8B:  .byte $20, $20, $02
L8F8E:  .byte $22, $00, $22
L8F91:  .byte $20, $02, $22
L8F94:  .byte $22, $22, $02
L8F97:  .byte $20, $20, $02
L8F9A:  .byte $20, $22, $22
L8F9D:  .byte $20, $22, $02
L8FA0:  .byte $20, $20, $02
L8FA3:  .byte $20, $22, $22
L8FA6:  .byte $20, $00, $20
L8FA9:  .byte $20, $22, $22
L8FAC:  .byte $20, $20, $00
L8FAF:  .byte $20, $20, $22
L8FB2:  .byte $20, $20, $26
L8FB5:  .byte $20, $20, $22
L8FB8:  .byte $20, $20, $05
L8FBB:  .byte $20, $22, $2A
L8FBE:  .byte $A8, $00, $00
L8FC1:  .byte $22, $22, $02
L8FC4:  .byte $20, $02, $02
L8FC7:  .byte $22, $02, $22
L8FCA:  .byte $8A, $A2, $08
L8FCD:  .byte $80, $02, $22
L8FD0:  .byte $22, $02, $02
L8FD3:  .byte $12, $22, $02

;Rock mountain cave - B1. Map #$16.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
RckMtnB1Dat:
L8FD6:  .byte $32, $22, $00, $88, $A2, $2A, $AA
L8FDD:  .byte $20, $02, $22, $22, $20, $20, $02
L8FE4:  .byte $20, $20, $00, $00, $80, $A0, $22
L8FEB:  .byte $22, $22, $22, $22, $20, $20, $22
L8FF2:  .byte $00, $00, $20, $00, $00, $20, $22
L8FF9:  .byte $22, $22, $20, $32, $22, $20, $24
L9000:  .byte $00, $20, $02, $00, $00, $00, $00
L9007:  .byte $12, $22, $22, $22, $20, $22, $20
L900E:  .byte $00, $20, $00, $00, $22, $20, $20
L9015:  .byte $22, $22, $20, $22, $20, $22, $22
L901C:  .byte $20, $00, $20, $20, $20, $00, $20
L9023:  .byte $22, $22, $22, $20, $22, $22, $22
L902A:  .byte $20, $20, $20, $00, $20, $22, $32
L9031:  .byte $22, $22, $22, $22, $20, $22, $22

;Rock mountain cave - B2. Map #$17.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
RckMtnB2Dat:
L9038:  .byte $12, $02, $22, $22, $22, $22, $22
L903F:  .byte $22, $02, $02, $02, $00, $20, $02
L9046:  .byte $00, $44, $02, $02, $02, $22, $02
L904D:  .byte $20, $00, $22, $00, $02, $22, $22
L9054:  .byte $22, $22, $20, $22, $08, $A8, $88
L905B:  .byte $88, $80, $20, $12, $22, $22, $22
L9062:  .byte $24, $20, $20, $22, $00, $28, $8A
L9069:  .byte $AA, $A8, $A0, $00, $02, $20, $22
L9070:  .byte $02, $00, $22, $22, $02, $20, $2A
L9077:  .byte $AA, $A8, $88, $A2, $22, $40, $02
L907E:  .byte $20, $00, $22, $20, $00, $02, $00
L9085:  .byte $28, $AA, $A8, $AA, $A0, $22, $22
L908C:  .byte $20, $00, $00, $00, $20, $20, $12
L9093:  .byte $22, $2A, $AA, $AA, $A8, $A2, $22

;Cave of garinham - B1. Map #$18.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
GarinCaveB1Dat:
L909A:  .byte $22, $22, $22, $22, $02, $04, $44, $02, $22, $28
L90A4:  .byte $A8, $88, $88, $82, $22, $02, $22, $22, $00, $22
L90AE:  .byte $20, $22, $22, $02, $0A, $8A, $AA, $8A, $A2, $02
L90B8:  .byte $20, $20, $02, $22, $02, $02, $00, $00, $02, $0A
L90C2:  .byte $A8, $AA, $AA, $80, $02, $00, $02, $02, $02, $22
L90CC:  .byte $20, $00, $02, $22, $0A, $AA, $8A, $8A, $82, $02
L90D6:  .byte $22, $22, $00, $00, $02, $02, $02, $02, $02, $0A
L90E0:  .byte $A8, $AA, $8A, $A2, $22, $22, $22, $22, $22, $22
L90EA:  .byte $20, $20, $02, $00, $0A, $88, $88, $8A, $80, $02
L90F4:  .byte $20, $20, $22, $22, $22, $02, $22, $22, $02, $2A
L90FE:  .byte $A8, $A8, $A8, $A0, $02, $00, $00, $02, $22, $22
L9108:  .byte $20, $22, $20, $12, $2A, $8A, $AA, $8A, $80, $22
L9112:  .byte $20, $20, $20, $22, $22, $02, $02, $22, $00, $20
L911C:  .byte $20, $20, $00, $00, $02, $00, $00, $02, $20, $22
L9126:  .byte $20, $22, $20, $22, $22, $22, $22, $00, $00, $02
L9130:  .byte $00, $00, $20, $00, $00, $02, $02, $02, $02, $02
L913A:  .byte $22, $20, $00, $22, $22, $22, $22, $02, $22, $22
L9144:  .byte $22, $02, $02, $20, $20, $00, $00, $00, $05, $00
L914E:  .byte $23, $22, $00, $00, $00, $20, $22, $20, $22, $22
L9158:  .byte $22, $22, $22, $22, $22, $22, $20, $22, $20, $22

;Cave of garinham - B3. Map #$1A.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
GarinCaveB3Dat:
L9162:  .byte $22, $20, $22, $20, $22, $22, $22, $22, $02, $22
L916C:  .byte $24, $20, $22, $22, $20, $20, $20, $12, $02, $12
L9176:  .byte $22, $20, $20, $00, $00, $22, $22, $22, $02, $22
L9180:  .byte $20, $00, $20, $20, $20, $00, $00, $00, $00, $00
L918A:  .byte $20, $22, $20, $22, $22, $00, $AA, $A0, $02, $22
L9194:  .byte $20, $20, $00, $20, $23, $02, $22, $22, $00, $02
L919E:  .byte $22, $28, $A2, $20, $00, $02, $24, $22, $02, $02
L91A8:  .byte $20, $00, $20, $20, $20, $02, $AA, $A2, $02, $02
L91B2:  .byte $20, $20, $20, $20, $20, $22, $22, $20, $02, $22
L91BC:  .byte $A8, $A8, $A2, $20, $20, $32, $00, $00, $02, $02
L91C6:  .byte $20, $20, $20, $00, $20, $88, $8A, $82, $22, $02
L91D0:  .byte $20, $20, $20, $12, $22, $22, $22, $02, $20, $02
L91DA:  .byte $A8, $A8, $A0, $00, $00, $00, $00, $00, $20, $22
L91E4:  .byte $20, $20, $20, $22, $22, $8A, $AA, $A2, $20, $12
L91EE:  .byte $20, $22, $20, $22, $02, $02, $00, $02, $00, $02
L91F8:  .byte $20, $02, $20, $22, $02, $02, $22, $22, $02, $22
L9202:  .byte $20, $22, $00, $00, $02, $00, $00, $02, $02, $02
L920C:  .byte $20, $12, $22, $22, $22, $02, $22, $22, $02, $02
L9216:  .byte $20, $00, $00, $00, $00, $00, $00, $02, $00, $02
L9220:  .byte $22, $22, $22, $22, $22, $22, $22, $22, $22, $22

;Cave of garinham - B4. Map #$1B.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
GarinCaveB4Dat:
L922A:  .byte $00, $00, $02, $00, $00
L922F:  .byte $00, $00, $22, $20, $00
L9234:  .byte $00, $02, $20, $22, $00
L9239:  .byte $00, $22, $00, $02, $20
L923E:  .byte $12, $20, $01, $22, $22
L9243:  .byte $00, $22, $00, $02, $20
L9248:  .byte $00, $02, $20, $22, $00
L924D:  .byte $00, $00, $22, $20, $00
L9252:  .byte $00, $00, $02, $00, $00
L9257:  .byte $00, $00, $00, $00, $00

;Cave of garinham - B2. Map #$19.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
GarinCaveB2Dat:
L925C:  .byte $22, $22, $22, $22, $22, $22, $22
L9263:  .byte $23, $02, $00, $00, $00, $02, $32
L926A:  .byte $20, $02, $22, $22, $22, $01, $22
L9271:  .byte $22, $00, $00, $00, $02, $00, $02
L9278:  .byte $22, $02, $22, $22, $22, $22, $02
L927F:  .byte $22, $02, $02, $02, $02, $02, $02
L9286:  .byte $22, $02, $23, $22, $02, $02, $02
L928D:  .byte $22, $8A, $8A, $8A, $88, $00, $82
L9294:  .byte $22, $02, $22, $22, $02, $22, $22
L929B:  .byte $20, $00, $88, $88, $88, $88, $8A
L92A2:  .byte $A3, $02, $22, $22, $22, $20, $32
L92A9:  .byte $22, $22, $22, $AA, $AA, $AA, $AA

;Erdrick's cave - B1. Map #$1C.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
ErdCaveB1Dat:
L92B0:  .byte $9A, $82, $22, $20, $02
L92B5:  .byte $02, $02, $00, $22, $22
L92BA:  .byte $22, $AA, $AA, $A8, $8A
L92BF:  .byte $8A, $80, $02, $00, $22
L92C4:  .byte $22, $02, $22, $02, $20
L92C9:  .byte $20, $88, $8A, $AA, $88
L92CE:  .byte $AA, $A2, $22, $02, $02
L92D3:  .byte $00, $20, $20, $02, $22
L92D8:  .byte $02, $AA, $AA, $8A, $8A
L92DD:  .byte $8A, $82, $02, $22, $03

;Erdrick's cave - B2. Map #$1D.
;Tile mapping: $0-Stone, $1-Stairs Up, $2-Brick, $3-Stairs Down, 
;$4-Treasure Chest, $5-Door, $6-Gwaelin, $7-Blank, $8-Stone, $9-Stairs Up, 
;$A-Brick, $B-Stairs Down, $C-Treasure Chest, $D-Door, $E-Gwaelin, $F-Blank.
ErdCaveB2Dat:
L92E2:  .byte $22, $22, $22, $22, $22
L92E7:  .byte $20, $88, $88, $A8, $88
L92EC:  .byte $AA, $A2, $20, $20, $22
L92F1:  .byte $00, $02, $00, $22, $24 
L92F6:  .byte $22, $AA, $8A, $88, $AA
L92FB:  .byte $A8, $A0, $02, $02, $00
L9300:  .byte $20, $02, $02, $22, $22
L9305:  .byte $22, $AA, $88, $A8, $8A
L930A:  .byte $8A, $82, $20, $20, $22
L930F:  .byte $22, $20, $22, $20, $12

;----------------------------------------------------------------------------------------------------

;Unused.
L9314:  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
L9324:  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

;----------------------------------------------------------------------------------------------------

;The following table contains all the sprites that compose the characters in the game.
;There are two bytes assiciated with each sprite.  The first byte is the tile pattern number 
;and the second byte is the sprite attribute byte and controls the palette, mirroring and
;background/foreground attributes.

CharSpriteTblPtr:
L9332:  .word CharSpriteTbl     ;Pointer to the table below.

CharSpriteTbl:
;Male villager, facing back, right side extended.
L9334:  .byte $00, $00
L9336:  .byte $00, $40
L9338:  .byte $02, $00
L933A:  .byte $03, $00

;Male villager, facing back, left side extended.
L933C:  .byte $00, $00
L933E:  .byte $00, $40
L9340:  .byte $03, $40
L9342:  .byte $02, $40

;Fighter, facing back, right side extended.
L9344:  .byte $D8, $03
L9346:  .byte $D9, $03
L9348:  .byte $DA, $03
L934A:  .byte $DB, $03

;Fighter, facing back, left side extended.
L934C:  .byte $D8, $03
L934E:  .byte $DC, $03
L9350:  .byte $DD, $03 
L9352:  .byte $DE, $03

;Guard, facing back, right side extended.
L9354:  .byte $58, $02
L9356:  .byte $59, $02
L9358:  .byte $5A, $02
L935A:  .byte $5B, $02

;Guard, facing back, left side extended.
L935C:  .byte $58, $02
L935E:  .byte $5D, $02
L9360:  .byte $5E, $02
L9362:  .byte $5F, $02

;Shopkeeper, facing back, right side extended.
L9364:  .byte $22, $01
L9366:  .byte $22, $41
L9368:  .byte $2A, $01
L936A:  .byte $2B, $01

;Shopkeeper, facing back, left side extended.
L936C:  .byte $22, $01
L936E:  .byte $22, $41
L9370:  .byte $2B, $41
L9372:  .byte $2A, $41

;King Lorik, facing front, right side extended.
L9374:  .byte $70, $03
L9376:  .byte $72, $03
L9378:  .byte $74, $03
L937A:  .byte $76, $03

;King Lorik, facing front, left side extended.
L937C:  .byte $88, $03
L937E:  .byte $89, $03
L9380:  .byte $8A, $03
L9382:  .byte $8B, $03

;Wizard, facing back, right side extended.
L9384:  .byte $F0, $02
L9386:  .byte $F1, $02
L9388:  .byte $F2, $02
L938A:  .byte $F3, $02

;Wizard, facing back, left side extended.
L938C:  .byte $F0, $02
L938E:  .byte $F4, $02
L9390:  .byte $F5, $02
L9392:  .byte $F6, $02

;Female villager, facing back, right side extended.
L9394:  .byte $0C, $00
L9396:  .byte $0C, $40
L9398:  .byte $0F, $40
L939A:  .byte $0E, $40

;Female villager, facing back, left side extended.
L939C:  .byte $0C, $00
L939E:  .byte $0C, $40
L93A0:  .byte $0E, $00
L93A2:  .byte $0F, $00

;Guard, facing right, front foot up.
L93A4:  .byte $68, $02
L93A6:  .byte $69, $02
L93A8:  .byte $6A, $02
L93AA:  .byte $6B, $02

;Guard, facing right, holding trumpet.
L93AC:  .byte $8D, $42
L93AE:  .byte $8C, $41
L93B0:  .byte $8F, $42
L93B2:  .byte $8E, $41

;Player, facing up, right side extended, no shield, no weapon.
L93B4:  .byte $20, $00
L93B6:  .byte $21, $00
L93B8:  .byte $24, $00
L93BA:  .byte $25, $00

;Player, facing up, left side extended, no shield, no weapon.
L93BC:  .byte $21, $40
L93BE:  .byte $20, $40
L93C0:  .byte $25, $40
L93C2:  .byte $24, $40

;Player, facing up, right side extended, no shield, weapon.
L93C4:  .byte $40, $00
L93C6:  .byte $41, $00
L93C8:  .byte $42, $00
L93CA:  .byte $43, $00

;Player, facing up, left side extended, no shield, weapon.
L93CC:  .byte $44, $00
L93CE:  .byte $45, $00
L93D0:  .byte $46, $00
L93D2:  .byte $47, $00

;Player, facing up, right side extended, shield, no weapon.
L93D4:  .byte $60, $00
L93D6:  .byte $21, $00
L93D8:  .byte $62, $00
L93DA:  .byte $25, $00

;Player, facing up, left side extended, shield, no weapon.
L93DC:  .byte $64, $00
L93DE:  .byte $20, $40
L93E0:  .byte $66, $00
L93E2:  .byte $24, $40

;Player, facing up, right side extended, shield, weapon.
L93E4:  .byte $80, $00
L93E6:  .byte $41, $00
L93E8:  .byte $82, $00
L93EA:  .byte $43, $00

;Player, facing up, left side extended, shield, weapon.
L93EC:  .byte $84, $00
L93EE:  .byte $45, $00
L93F0:  .byte $86, $00
L93F2:  .byte $47, $00

;Player, facing up, right side extended, carrying Gwaelin.
L93F4:  .byte $A4, $00
L93F6:  .byte $A5, $00
L93F8:  .byte $A2, $00
L93FA:  .byte $A3, $00

;Player, facing up, left side extended, carrying Gwaelin.
L93FC:  .byte $A4, $00
L93FE:  .byte $A5, $00
L9400:  .byte $A6, $00
L9402:  .byte $A7, $00

;Gwaelin, facing up, right side extended.
L9404:  .byte $18, $03
L9406:  .byte $18, $43
L9408:  .byte $1A, $03
L940A:  .byte $1B, $03

;Gwaelin, facing up, left side extended.
L940C:  .byte $18, $03
L940E:  .byte $18, $43
L9410:  .byte $1B, $43
L9412:  .byte $1A, $43

;Dragonlord, facing up, right side extended.
L9414:  .byte $C4, $00
L9416:  .byte $C5, $00
L9418:  .byte $C6, $00
L941A:  .byte $C7, $00

;Dragonlord, facing up, left side extended.
L941C:  .byte $C4, $00
L941E:  .byte $C8, $00
L9420:  .byte $C9, $00
L9422:  .byte $CA, $00

;Guard, facing left, front leg up.
L9424:  .byte $69, $42
L9426:  .byte $68, $42
L9428:  .byte $6B, $42
L942A:  .byte $6A, $42

;Guard, facing left, holding trumpet.
L942C:  .byte $8C, $01
L942E:  .byte $8D, $02
L9430:  .byte $8E, $01
L9432:  .byte $8F, $02

;Male villager, facing right, front foot up.
L9434:  .byte $04, $00
L9436:  .byte $05, $00
L9438:  .byte $06, $00
L943A:  .byte $07, $00

;Male villager, facing right, front foot down.
L943C:  .byte $04, $00
L943E:  .byte $05, $00
L9440:  .byte $08, $00
L9442:  .byte $09, $00

;Fighter, facing right, front foot up.
L9444:  .byte $DF, $03
L9446:  .byte $E0, $03
L9448:  .byte $E1, $03
L944A:  .byte $E2, $03

;Fighter, facing right, front foot down.
L944C:  .byte $DF, $03
L944E:  .byte $E3, $03
L9450:  .byte $E4, $03
L9452:  .byte $E5, $03

;Guard, facing right, front foot up.
L9454:  .byte $68, $02
L9456:  .byte $69, $02
L9458:  .byte $6A, $02
L945A:  .byte $6B, $02

;Guard, facing right, front foot down.
L945C:  .byte $68, $02
L945E:  .byte $5C, $02
L9460:  .byte $6C, $02
L9462:  .byte $6D, $02

;Shopkeeper, facing right, front foot up.
L9464:  .byte $2C, $01
L9466:  .byte $2D, $01
L9468:  .byte $2E, $01
L946A:  .byte $2F, $01

;Shopkeeper, facing right, front foot down.
L946C:  .byte $2C, $01
L946E:  .byte $2D, $01
L9470:  .byte $23, $01
L9472:  .byte $1C, $01

;King Lorik, facing front, right side extended.
L9474:  .byte $70, $03
L9476:  .byte $72, $03
L9478:  .byte $74, $03
L947A:  .byte $76, $03

;King Lorik, facing front, left side extended.
L947C:  .byte $88, $03
L947E:  .byte $89, $03
L9480:  .byte $8A, $03
L9482:  .byte $8B, $03

;Wizard, facing right, front foot up.
L9484:  .byte $F7, $02
L9486:  .byte $F8, $02
L9488:  .byte $F9, $02
L948A:  .byte $FA, $02

;Wizard, facing right, front foot down.
L948C:  .byte $F7, $02
L948E:  .byte $FB, $02
L9490:  .byte $FC, $02
L9492:  .byte $FD, $02

;Female villager, facing right, front foot up.
L9494:  .byte $10, $00
L9496:  .byte $11, $00
L9498:  .byte $14, $00
L949A:  .byte $15, $00

;Female villager, facing right, front foot down.
L949C:  .byte $10, $00
L949E:  .byte $11, $00
L94A0:  .byte $12, $00
L94A2:  .byte $13, $00

;Guard, facing right, front foot up.
L94A4:  .byte $68, $02
L94A6:  .byte $69, $02
L94A8:  .byte $6A, $02
L94AA:  .byte $6B, $02

;Guard, facing right, holding trumpet.
L94AC:  .byte $8D, $42
L94AE:  .byte $8C, $41
L94B0:  .byte $8F, $42
L94B2:  .byte $8E, $41

;Player, facing right, front foot up, no shield, no weapon.
L94B4:  .byte $26, $00
L94B6:  .byte $27, $00
L94B8:  .byte $28, $00
L94BA:  .byte $29, $00

;Player, facing right, front foot down, no shield, no weapon.
L94BC:  .byte $30, $00
L94BE:  .byte $31, $00
L94C0:  .byte $32, $00
L94C2:  .byte $33, $00

;Player, facing right, front foot up, no shield, weapon.
L94C4:  .byte $48, $00
L94C6:  .byte $49, $00
L94C8:  .byte $4A, $00
L94CA:  .byte $4B, $00

;Player, facing right, front foot down, no shield, weapon.
L94CC:  .byte $4C, $00
L94CE:  .byte $4D, $00
L94D0:  .byte $4E, $00
L94D2:  .byte $4F, $00

;Player, facing right, front foot up, shield, no weapon.
L94D4:  .byte $26, $00
L94D6:  .byte $27, $00
L94D8:  .byte $28, $00
L94DA:  .byte $29, $00

;Player, facing right, front foot down, shield, no weapon.
L94DC:  .byte $30, $00
L94DE:  .byte $31, $00
L94E0:  .byte $32, $00
L94E2:  .byte $33, $00

;Player, facing right, front foot up, shield, weapon.
L94E4:  .byte $48, $00
L94E6:  .byte $49, $00
L94E8:  .byte $4A, $00
L94EA:  .byte $4B, $00

;Player, facing right, front foot down, shield, weapon.
L94EC:  .byte $4C, $00
L94EE:  .byte $4D, $00
L94F0:  .byte $4E, $00
L94F2:  .byte $4F, $00

;Player, facing right, front foot up, carrying Gwaelin.
L94F4:  .byte $A8, $00
L94F6:  .byte $A9, $03
L94F8:  .byte $AA, $00
L94FA:  .byte $AB, $03

;Player, facing right, front foot down, carrying Gwaelin.
L94FC:  .byte $AC, $00
L94FE:  .byte $AD, $03
L9500:  .byte $AE, $00
L9502:  .byte $AF, $03

;Gwaelin, facing right, front foot up.
L9504:  .byte $38, $03
L9506:  .byte $19, $43
L9508:  .byte $3C, $03
L950A:  .byte $3D, $03

;Gwaelin, facing right, front foot down.
L950C:  .byte $38, $03
L950E:  .byte $19, $43
L9510:  .byte $3A, $03
L9512:  .byte $3B, $03

;Dragonlord, facing right, front foot up.
L9514:  .byte $CE, $00
L9516:  .byte $CB, $00
L9518:  .byte $CC, $00
L951A:  .byte $CD, $00

;Dragonlord, facing right, front foot down.
L951C:  .byte $CE, $00
L951E:  .byte $CF, $00
L9520:  .byte $D0, $00
L9522:  .byte $D1, $00

;Guard, facing left, front foot up.
L9524:  .byte $69, $42
L9526:  .byte $68, $42
L9528:  .byte $6B, $42
L952A:  .byte $6A, $42

;Guard, facing left, holding trumpet.
L952C:  .byte $8C, $01
L952E:  .byte $8D, $02
L9530:  .byte $8E, $01
L9532:  .byte $8F, $02

;Male villager, facing down, right side extended.
L9534:  .byte $01, $00
L9536:  .byte $01, $40
L9538:  .byte $0A, $00
L953A:  .byte $0B, $00

;Male villager, facing down, left side extended.
L953C:  .byte $01, $00
L953E:  .byte $01, $40
L9540:  .byte $0B, $40
L9542:  .byte $0A, $40

;Fighter, facing down, right side extended.
L9544:  .byte $E6, $03
L9546:  .byte $B0, $03
L9548:  .byte $B1, $03
L954A:  .byte $E7, $03

;Fighter, facing down, left side extended.
L954C:  .byte $E8, $03
L954E:  .byte $B0, $03
L9550:  .byte $E9, $03
L9552:  .byte $EA, $03

;Guard, facing down, right side extended.
L9554:  .byte $78, $02
L9556:  .byte $79, $02
L9558:  .byte $7A, $02
L955A:  .byte $7B, $02

;Guard, facing down, left side extended.
L955C:  .byte $7C, $02
L955E:  .byte $79, $02
L9560:  .byte $7E, $02
L9562:  .byte $7F, $02

;Shopkeeper, facing front, right side extended.
L9564:  .byte $1D, $01
L9566:  .byte $1D, $41
L9568:  .byte $1E, $01
L956A:  .byte $1F, $01

;Shopkeeper, facing front, left side extended.
L956C:  .byte $1D, $01
L956E:  .byte $1D, $41
L9570:  .byte $1F, $41
L9572:  .byte $1E, $41

;King Lorik, facing front, right side extended.
L9574:  .byte $70, $03
L9576:  .byte $72, $03
L9578:  .byte $74, $03
L957A:  .byte $76, $03

;King Lorik, facing front, left side extended.
L957C:  .byte $88, $03
L957E:  .byte $89, $03
L9580:  .byte $8A, $03
L9582:  .byte $8B, $03

;Wizard, facing front, right side extended.
L9584:  .byte $FE, $02
L9586:  .byte $FF, $02
L9588:  .byte $C2, $02
L958A:  .byte $C3, $02

;Wizard, facing front, left side extended.
L958C:  .byte $A0, $02
L958E:  .byte $FF, $02
L9590:  .byte $A1, $02
L9592:  .byte $85, $02

;Female villager, facing front, right side extended.
L9594:  .byte $0D, $00
L9596:  .byte $0D, $40
L9598:  .byte $16, $00
L959A:  .byte $17, $00

;Female villager, facing front, left side extended.
L959C:  .byte $0D, $00
L959E:  .byte $0D, $40
L95A0:  .byte $17, $40
L95A2:  .byte $16, $40

;Guard, facing right, front foot up.
L95A4:  .byte $68, $02
L95A6:  .byte $69, $02
L95A8:  .byte $6A, $02
L95AA:  .byte $6B, $02

;Guard, facing right, holding trumpet.
L95AC:  .byte $8D, $42
L95AE:  .byte $8C, $41
L95B0:  .byte $8F, $42
L95B2:  .byte $8E, $41

;Player, facing down, right side extended, no shield, no weapon.
L95B4:  .byte $34, $00
L95B6:  .byte $35, $00
L95B8:  .byte $36, $00
L95BA:  .byte $37, $00

;Player, facing down, left side extended, no shield, no weapon.
L95BC:  .byte $35, $40
L95BE:  .byte $34, $40
L95C0:  .byte $37, $40
L95C2:  .byte $36, $40

;Player, facing down, right side extended, no shield, weapon.
L95C4:  .byte $50, $00
L95C6:  .byte $51, $00
L95C8:  .byte $52, $00
L95CA:  .byte $53, $00

;Player, facing down, left side extended, no shield, weapon.
L95CC:  .byte $54, $00
L95CE:  .byte $55, $00
L95D0:  .byte $56, $00
L95D2:  .byte $57, $00

;Player, facing down, right side extended, shield, no weapon.
L95D4:  .byte $34, $00
L95D6:  .byte $71, $00
L95D8:  .byte $36, $00
L95DA:  .byte $73, $00

;Player, facing down, left side extended, shield, no weapon.
L95DC:  .byte $35, $40
L95DE:  .byte $75, $00
L95E0:  .byte $37, $40
L95E2:  .byte $77, $00

;Player, facing down, right side extended, shield, weapon.
L95E4:  .byte $50, $00
L95E6:  .byte $91, $00
L95E8:  .byte $52, $00
L95EA:  .byte $93, $00

;Player, facing down, left side extended, shield, weapon.
L95EC:  .byte $54, $00
L95EE:  .byte $95, $00
L95F0:  .byte $56, $00
L95F2:  .byte $97, $00

;Player, facing down, right side extended, carrying Gwaelin.
L95F4:  .byte $B4, $03
L95F6:  .byte $B5, $00
L95F8:  .byte $B2, $03
L95FA:  .byte $B3, $03

;Player, facing down, left side extended, carrying Gwaelin.
L95FC:  .byte $B4, $03
L95FE:  .byte $B5, $00
L9600:  .byte $B6, $03
L9602:  .byte $B7, $03

;Gwaelin, facing down, right side extended.
L9604:  .byte $3E, $03
L9606:  .byte $3F, $03
L9608:  .byte $C0, $03
L960A:  .byte $C1, $03

;Gwaelin, facing down, left side extended.
L960C:  .byte $3E, $03
L960E:  .byte $3F, $03
L9610:  .byte $C1, $43
L9612:  .byte $C0, $43

;Dragonlord, facing down, right side extended.
L9614:  .byte $D2, $00
L9616:  .byte $D3, $00
L9618:  .byte $D4, $00
L961A:  .byte $D5, $00

;Dragonlord, facing down, left side extended.
L961C:  .byte $D6, $00
L961E:  .byte $D3, $00
L9620:  .byte $D7, $00
L9622:  .byte $92, $00

;Guard, facing left, front foot up.
L9624:  .byte $69, $42
L9626:  .byte $68, $42
L9628:  .byte $6B, $42
L962A:  .byte $6A, $42

;Guard, facing left, holding trumpet.
L962C:  .byte $8C, $01
L962E:  .byte $8D, $02
L9630:  .byte $8E, $01
L9632:  .byte $8F, $02

;Male villager, facing left, front foot up.
L9634:  .byte $05, $40
L9636:  .byte $04, $40
L9638:  .byte $07, $40
L963A:  .byte $06, $40

;Male villager, facing left, front foot down.
L963C:  .byte $05, $40
L963E:  .byte $04, $40
L9640:  .byte $09, $40
L9642:  .byte $08, $40

;Fighter, facing left, front foot up.
L9644:  .byte $EB, $03
L9646:  .byte $DF, $43
L9648:  .byte $EC, $03
L964A:  .byte $ED, $03

;Fighter, facing left, front foot down.
L964C:  .byte $EB, $03
L964E:  .byte $DF, $43
L9650:  .byte $EE, $03
L9652:  .byte $EF, $03

;Guard, facing left, front foot down.
L9654:  .byte $7D, $02
L9656:  .byte $68, $42
L9658:  .byte $81, $02
L965A:  .byte $83, $02

;Guard, facing left, front foot up.
L965C:  .byte $7D, $02
L965E:  .byte $68, $42
L9660:  .byte $6E, $02
L9662:  .byte $6F, $02

;Shopkeeper, facing left, front foot down.
L9664:  .byte $2D, $41
L9666:  .byte $2C, $41
L9668:  .byte $1C, $41
L966A:  .byte $23, $41

;Shopkeeper, facing left, front foot up.
L966C:  .byte $2D, $41
L966E:  .byte $2C, $41
L9670:  .byte $2F, $41
L9672:  .byte $2E, $41

;King Lorik, facing front, right side extended.
L9674:  .byte $70, $03
L9676:  .byte $72, $03
L9678:  .byte $74, $03
L967A:  .byte $76, $03

;King Lorik, facing front, left side extended.
L967C:  .byte $88, $03
L967E:  .byte $89, $03
L9680:  .byte $8A, $03
L9682:  .byte $8B, $03

;Wizard, facing left, front foot up.
L9684:  .byte $87, $02
L9686:  .byte $F7, $42
L9688:  .byte $65, $02
L968A:  .byte $67, $02

;Wizard, facing left, front foot down.
L968C:  .byte $87, $02
L968E:  .byte $F7, $42
L9690:  .byte $61, $02
L9692:  .byte $63, $02

;Female villager, facing left, front foot up.
L9694:  .byte $11, $40
L9696:  .byte $10, $40
L9698:  .byte $15, $40
L969A:  .byte $14, $40

;Female villager, facing left, front foot down.
L969C:  .byte $11, $40
L969E:  .byte $10, $40
L96A0:  .byte $13, $40
L96A2:  .byte $12, $40

;Guard, facing right, front foot up.
L96A4:  .byte $68, $02
L96A6:  .byte $69, $02
L96A8:  .byte $6A, $02
L96AA:  .byte $6B, $02

;Guard, facing right, holding trumpet.
L96AC:  .byte $8D, $42
L96AE:  .byte $8C, $41
L96B0:  .byte $8F, $42
L96B2:  .byte $8E, $41

;Player, facing left, front foot up, no shield, no weapon.
L96B4:  .byte $27, $40
L96B6:  .byte $26, $40
L96B8:  .byte $29, $40
L96BA:  .byte $28, $40

;Player, facing left, front foot down, no shield, no weapon.
L96BC:  .byte $31, $40
L96BE:  .byte $30, $40
L96C0:  .byte $33, $40
L96C2:  .byte $32, $40

;Player, facing left, front foot up, no shield, weapon.
L96C4:  .byte $27, $40
L96C6:  .byte $26, $40
L96C8:  .byte $29, $40
L96CA:  .byte $28, $40

;Player, facing left, front foot down, no shield, weapon.
L96CC:  .byte $31, $40
L96CE:  .byte $30, $40
L96D0:  .byte $33, $40
L96D2:  .byte $32, $40

;Player, facing left, front foot up, shield, no weapon.
L96D4:  .byte $98, $00
L96D6:  .byte $99, $00
L96D8:  .byte $9A, $00
L96DA:  .byte $9B, $00

;Player, facing left, front foot down, shield, no weapon.
L96DC:  .byte $9C, $00
L96DE:  .byte $9D, $00
L96E0:  .byte $9E, $00
L96E2:  .byte $9F, $00

;Player, facing left, front foot up, shield, weapon.
L96E4:  .byte $98, $00
L96E6:  .byte $99, $00
L96E8:  .byte $9A, $00
L96EA:  .byte $9B, $00

;Player, facing left, front foot down, shield, weapon.
L96EC:  .byte $9C, $00
L96EE:  .byte $9D, $00
L96F0:  .byte $9E, $00
L96F2:  .byte $9F, $00

;Player, facing left, front foot up, carrying Gwaelin.
L96F4:  .byte $B8, $03
L96F6:  .byte $B9, $00
L96F8:  .byte $BA, $03
L96FA:  .byte $BB, $03

;Player, facing left, front foot down, carrying Gwaelin.
L96FC:  .byte $BC, $03
L96FE:  .byte $BD, $00
L9700:  .byte $BE, $03
L9702:  .byte $BF, $03

;Gwaelin, facing left, front foot up.
L9704:  .byte $38, $03
L9706:  .byte $39, $03
L9708:  .byte $3A, $03
L970A:  .byte $3B, $03

;Gwaelin, facing left, front foot down.
L970C:  .byte $39, $43
L970E:  .byte $38, $43
L9710:  .byte $3C, $03
L9712:  .byte $3D, $03

;Dragonlord, facing left, front foot up.
L9714:  .byte $D0, $00
L9716:  .byte $D1, $00
L9718:  .byte $D2, $00
L971A:  .byte $D3, $00

;Dragonlord, facing left, front foot down.
L971C:  .byte $D4, $00
L971E:  .byte $D5, $00
L9720:  .byte $D6, $00
L9722:  .byte $D7, $00

;Guard, facing left, front foot up.
L9724:  .byte $69, $42
L9726:  .byte $68, $42
L9728:  .byte $6B, $42
L972A:  .byte $6A, $42

;Guard, facing left, holding trumpet.
L972C:  .byte $8C, $01
L972E:  .byte $8D, $02
L9730:  .byte $8E, $01
L9732:  .byte $8F, $02

;----------------------------------------------------------------------------------------------------

;The following 2 tables are used to find NPC data for the various maps.  The first table
;points to NPC data for modile NPCs.  The second table points to NPC data for static NPCs.

NPCMobPtrTbl:
L9734:  .word TantMobTbl        ;($9764)Tantagel castle, ground floor mobile NPCs.
L9736:  .word ThRmMobTbl        ;($97A2)Throne room mobile NPCs.
L9738:  .word DLBFMobTbl        ;($97EA)Dragonlord's castle, bottom floor mobile NPCs.
L973A:  .word KolMobTbl         ;($98B3)Kol mobile NPCs.
L973C:  .word BrecMobTbl        ;($9875)Brecconary mobile NPCs.
L973E:  .word GarMobTbl         ;($98E5)Garinham mobile NPCs.
L9740:  .word CantMobTbl        ;($97F9)Cantlin mobile NPCs.
L9742:  .word RimMobTbl         ;($9837)Rimuldar mobile NPCs.
L9744:  .word TaSLMobTbl        ;($97B3)Tantagel castle, sublevel mobile NPCs.
L9746:  .word RainMobTbl        ;($97EF)Staff of rain cave mobile NPCs.
L9748:  .word RnbwMobTbl        ;($97F4)Rainbow drop cave mobile NPCs.
L974A:  .word TaDLMobTbl        ;($97B8)Tantagel castle, after dragonlord defeat mobile NPCs.

NPCStatPtrTbl:
L974C:  .word TantStatTbl       ;($9783)Tantagel castle, ground floor static NPCs.
L974E:  .word ThRmStatTbl       ;($97A6)Throne room, static NPCs.
L9750:  .word DLBFStatTbl       ;($97EB)Dragonlord's castle, bottom floor static NPCs.
L9752:  .word KolStatTbl        ;($98CF)Kol, static NPCs.
L9754:  .word BrecStatTbl       ;($9894)Brecconary, static NPCs.
L9756:  .word GarStatTbl        ;($98FB)Garinham, static NPCs.
L9758:  .word CantStatTbl       ;($9818)Cantlin, static NPCs.
L975A:  .word RimStatTbl        ;($9856)Rimuldar, static NPCs.
L975C:  .word TaSLStatTbl       ;($97B4)Tantagel castle, sublevel static NPCs.
L975E:  .word RainStatTbl       ;($97F0)Staff of rain cave static NPCs.
L9760:  .word RnbwStatTbl       ;($97F5)Rainbow drop cave static NPCs.
L9762:  .word TaDLStatTbl       ;($97CE)Tantagel castle, after dragonlord defeat static NPCs.

;----------------------------------------------------------------------------------------------------

;The tables below control the characteristics of the NPCs. There are 3 bytes per entry and are
;formatted as follows:

;NNNXXXXX _DDYYYYY CCCCCCCC
;
;NNN      - NPC graphic: 0=Male villager, 1=Fighter, 2=Guard, 3=Shopkeeper, 4=King Lorik,
;             5=Wizard/Dragonlord, 6=Princess Gwaelin/Female villager
;             7=Stationary guard/Guard with trumpet.
;XXXXX    - NPC X position.
;_        - Unused.
;DD       - NPC direction: 0=Facing up, 1=Facing right, 2=Facing down, 3=Facing left.
;CCCCCCCC - Dialog control byte.

;----------------------------------------------------------------------------------------------------

TantMobTbl:
L9764:  .byte $C8, $4D, $62     ;Female villager at  8,13.
L9767:  .byte $53, $42, $17     ;Guard at           19, 2.
L976A:  .byte $0B, $4B, $1C     ;Male villager at   11,11.
L976D:  .byte $B1, $4B, $1D     ;Wizard at          17,11.
L9770:  .byte $64, $55, $1F     ;Shopkeeper at       4,21.
L9773:  .byte $39, $4B, $16     ;Fighter at         25,11.
L9776:  .byte $52, $52, $72     ;Guard at           18,18.
L9779:  .byte $42, $4C, $1B     ;Guard at            2,12.
L977C:  .byte $66, $59, $20     ;Shopkeeper at       6,25.
L977F:  .byte $38, $55, $22     ;Fighter at         24,21.
L9782:  .byte $FF               ;

TantStatTbl:
L9783:  .byte $78, $41, $0E     ;Shopkeeper at      24, 1.
L9786:  .byte $DB, $45, $1A     ;Female villager at 27, 5.
L9789:  .byte $48, $46, $19     ;Guard at            8, 6.
L978C:  .byte $02, $48, $18     ;Male villager at    2, 8.
L978F:  .byte $48, $08, $71     ;Guard at            8, 8.
L9792:  .byte $5A, $0F, $1E     ;Guard at           26,15.
L9795:  .byte $4F, $34, $63     ;Guard at           15,20.
L9798:  .byte $B4, $7A, $6A     ;Wizard at          20,26.
L979B:  .byte $49, $3B, $21     ;Guard at            9,27.
L979E:  .byte $4C, $7B, $21     ;Guard at           12,27.
L97A1:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

ThRmMobTbl:
L97A2:  .byte $47, $45, $65     ;Guard at            7, 5.
L97A5:  .byte $FF               ;

ThRmStatTbl:
L97A6:  .byte $83, $43, $6E     ;King Lorik at       3, 3.
L97A9:  .byte $43, $26, $23     ;Guard at            3, 6.
L97AC:  .byte $45, $66, $24     ;Guard at            5, 6.
L97AF:  .byte $C6, $43, $6F     ;Princess Gwaelin at 6, 3.
L97B2:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

TaSLMobTbl:
L97B3:  .byte $FF               ;No mobile NPCs.

TaSLStatTbl:
L97B4:  .byte $A4, $46, $66     ;Wizard at           4, 6.
L97B7:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

TaDLMobTbl:
L97B8:  .byte $53, $42, $17     ;Guard at           19, 2.
L97BB:  .byte $0E, $57, $1C     ;Male villager at   14,23.
L97BE:  .byte $39, $4B, $16     ;Fighter at         25,11.
L97C1:  .byte $52, $52, $72     ;Guard at           18,18.
L97C4:  .byte $42, $4C, $1B     ;Guard at            2,12.
L97C7:  .byte $66, $59, $20     ;Shopkeeper at       6,25.
L97CA:  .byte $38, $55, $22     ;Fighter at         24,21.
L97CD:  .byte $FF               ;

TaDLStatTbl:
L97CE:  .byte $8B, $47, $FE     ;King Lorik at      11, 7.
L97D1:  .byte $E9, $49, $FD     ;Trumpet guard at    9, 9.
L97D4:  .byte $E9, $4B, $FD     ;Trumpet guard at    9,11.
L97D7:  .byte $E9, $4D, $FD     ;Trumpet guard at    9,13.
L97DA:  .byte $AC, $49, $FD     ;Trumpet guard at   12, 9.
L97DD:  .byte $AC, $4B, $FD     ;Trumpet guard at   12,11.
L97E0:  .byte $AC, $4D, $FD     ;Trumpet guard at   12,13.
L97E3:  .byte $49, $3B, $FD     ;Guard at            9,11.
L97E6:  .byte $4C, $7B, $FD     ;Guard at           12,11.
L97E9:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

DLBFMobTbl:
L97EA:  .byte $FF               ;No mobile NPCs.

DLBFStatTbl:
L97EB:  .byte $B0, $58, $70     ;Dragonlord at      16,24.
L97EE:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

RainMobTbl:
L97EF:  .byte $FF               ;No mobile NPCs.

RainStatTbl:
L97F0:  .byte $A4, $24, $6C     ;Wizard at           4, 4.
L97F3:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

RnbwMobTbl:
L97F4:  .byte $FF               ;No mobile NPCs.

RnbwStatTbl:
L97F5:  .byte $A4, $65, $6D     ;Wizard at           4, 5.
L97F8:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

CantMobTbl:
L97F9:  .byte $14, $4F, $4B     ;Male villager at   20,15.
L97FC:  .byte $45, $46, $60     ;Guard at            5, 6.
L97FF:  .byte $79, $51, $4C     ;Shopkeeper at      25,17.
L9802:  .byte $C4, $4E, $49     ;Female villager at  4,14.
L9805:  .byte $76, $45, $03     ;Shopkeeper at      22, 5.
L9808:  .byte $C9, $50, $4A     ;Female villager at  9,16.
L980B:  .byte $AE, $5C, $6B     ;Wizard at          14,28.
L980E:  .byte $4F, $46, $48     ;Guard at           15, 6.
L9811:  .byte $63, $5A, $4E     ;Shopkeeper at       3,26.
L9814:  .byte $56, $49, $4D     ;Guard at           22, 9.
L9817:  .byte $FF               ;

CantStatTbl:
L9818:  .byte $68, $43, $14     ;Shopkeeper at       8, 3.
L981B:  .byte $BB, $46, $0C     ;Wizard at          27, 6.
L981E:  .byte $02, $27, $0A     ;Male villager at    2, 7.
L9821:  .byte $62, $2C, $45     ;Shopkeeper at       2,12.
L9824:  .byte $67, $6C, $0B     ;Shopkeeper at       7,12.
L9827:  .byte $58, $2C, $05     ;Guard at           24,12.
L982A:  .byte $D6, $6D, $10     ;Female villager at 22,13.
L982D:  .byte $AF, $50, $46     ;Wizard at          15,16.
L9830:  .byte $B6, $56, $47     ;Wizard at          22,22.
L9833:  .byte $7B, $7A, $04     ;Shopkeeper at      27,26.
L9836:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

RimMobTbl:
L9837:  .byte $C6, $55, $59     ;Female villager at  6,21.
L983A:  .byte $0B, $48, $30     ;Male villager at   11, 8.
L983D:  .byte $06, $57, $5A     ;Male villager at    6,23.
L9840:  .byte $D6, $4E, $56     ;Female villager at 22,14.
L9843:  .byte $25, $59, $5B     ;Fighter at          5,25.
L9846:  .byte $37, $4B, $52     ;Fighter at         23,11.
L9849:  .byte $0E, $4B, $55     ;Male villager at   14,11.
L984C:  .byte $30, $5A, $69     ;Fighter at         16,26.
L984F:  .byte $48, $50, $54     ;Guard at            8,16.
L9852:  .byte $38, $53, $57     ;Fighter at         24,19.
L9855:  .byte $FF               ;

RimStatTbl:
L9856:  .byte $1B, $40, $51     ;Male villager at   27, 0.
L9859:  .byte $62, $04, $4F     ;Shopkeeper at       2, 4.
L985C:  .byte $A4, $07, $0D     ;Wizard at           4, 7.
L985F:  .byte $77, $47, $06     ;Shopkeeper at      23, 7.
L9862:  .byte $CF, $08, $50     ;Female villager at 15, 8.
L9865:  .byte $A6, $6D, $53     ;Wizard at           6,13.
L9868:  .byte $70, $32, $15     ;Shopkeeper at      16,18.
L986B:  .byte $A3, $37, $61     ;Wizard at           3,23.
L986E:  .byte $B4, $57, $58     ;Wizard at          20,23.
L9871:  .byte $C0, $5A, $5C     ;Female villager at  0,26
L9874:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

BrecMobTbl:
L9875:  .byte $A9, $44, $2B     ;Wizard at           9, 4.
L9878:  .byte $2C, $53, $5D     ;Fighter at         12,19.
L987B:  .byte $6F, $49, $2E     ;Shopkeeper at      15, 9.
L987E:  .byte $19, $56, $31     ;Male villager at   25,22.
L9881:  .byte $0A, $4E, $2C     ;Male villager at   10,14.
L9884:  .byte $D8, $44, $0F     ;Female villager at 24, 4.
L9887:  .byte $5A, $4F, $2F     ;Guard at           26,15.
L988A:  .byte $CF, $58, $2D     ;Female villager at 15,24.
L988D:  .byte $33, $52, $30     ;Fighter at         19,18.
L9890:  .byte $23, $5A, $27     ;Fighter at          3,26.
L9893:  .byte $FF               ;

BrecStatTbl:
L9894:  .byte $65, $44, $01     ;Shopkeeper at       5, 4.
L9897:  .byte $3C, $41, $25     ;Fighter at         28, 1.
L989A:  .byte $C4, $47, $29     ;Female villager     4, 7.
L989D:  .byte $14, $4A, $26     ;Male villager at   20,10.
L98A0:  .byte $B8, $4A, $67     ;Wizard at          24,10.
L98A3:  .byte $01, $4D, $2A     ;Male villager at    1,13.
L98A6:  .byte $6A, $75, $12     ;Shopkeeper at      10,21.
L98A9:  .byte $14, $17, $28     ;Male villager at   20,23.
L98AC:  .byte $79, $79, $08     ;Shopkeeper at      25,25.
L98AF:  .byte $4A, $1A, $64     ;Guard at           10,26.
L98B2:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

KolMobTbl:
L98B3:  .byte $0E, $4D, $36     ;Male villager at   14,13.
L98B6:  .byte $05, $4C, $30     ;Male villager at    5,12.
L98B9:  .byte $4C, $4A, $37     ;Guard at           12,10.
L98BC:  .byte $A2, $4C, $5E     ;Wizard at           2,12.
L98BF:  .byte $B4, $53, $38     ;Wizard at          20,19.
L98C2:  .byte $26, $47, $35     ;Fighter at          6, 7.
L98C5:  .byte $CB, $4E, $2E     ;Female villager    11,14.
L98C8:  .byte $67, $53, $5F     ;Shopkeeper at       7,19.
L98CB:  .byte $B4, $48, $39     ;Wizard at          20, 8.
L98CE:  .byte $FF               ;

KolStatTbl:
L98CF:  .byte $A1, $41, $68     ;Wizard at           1, 1.
L98D2:  .byte $CC, $41, $32     ;Female villager    12, 1.
L98D5:  .byte $73, $04, $11     ;Shopkeeper at      19, 4.
L98D8:  .byte $76, $6C, $00     ;Shopkeeper at      22,12.
L98DB:  .byte $34, $4D, $33     ;Fighter at         20,13.
L98DE:  .byte $6E, $75, $07     ;Shopkeeper at      14,21.
L98E1:  .byte $41, $57, $34     ;Guard at            1,23.
L98E4:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

GarMobTbl:
L98E5:  .byte $CC, $44, $3E     ;Female villager at 12, 4.
L98E8:  .byte $CC, $4C, $43     ;Female villager at 12,12.
L98EB:  .byte $AC, $48, $3F     ;Wizard at          12, 8.
L98EE:  .byte $A2, $4A, $42     ;Wizard at           2,10.
L98F1:  .byte $0B, $47, $3D     ;Male villager at   11, 7.
L98F4:  .byte $12, $4C, $44     ;Male villager at   18,12.
L98F7:  .byte $27, $51, $41     ;Fighter at          7,17.
L98FA:  .byte $FF               ;

GarStatTbl:
L98FB:  .byte $AE, $41, $3A     ;Wizard at          14, 1.
L98FE:  .byte $43, $25, $3B     ;Guard at            3, 5.
L9901:  .byte $45, $65, $3B     ;Guard at            5, 5.
L9904:  .byte $69, $46, $3C     ;Shopkeeper at       9, 6.
L9907:  .byte $65, $6B, $09     ;Shopkeeper at       5,11.
L990A:  .byte $71, $6F, $13     ;Shopkeeper at      17,15.
L990D:  .byte $A2, $31, $40     ;Wizard at           2,17.
L9910:  .byte $6A, $12, $02     ;Shopkeeper at      10,18.
L9913:  .byte $FF               ;

;----------------------------------------------------------------------------------------------------

;This table indicates which direction player is facing when changing maps.
;Each entry in this table corresponds to an entry in MapTargetTbl.
;Player's facing direction: 0-up, 1-right, 2-down, 3-left.

MapEntryDirTbl: 
L9914:  .byte DIR_RIGHT, DIR_DOWN, DIR_UP,    DIR_RIGHT, DIR_UP,   DIR_RIGHT, DIR_UP,   DIR_RIGHT
L991C:  .byte DIR_RIGHT, DIR_LEFT, DIR_RIGHT, DIR_DOWN,  DIR_DOWN, DIR_RIGHT, DIR_DOWN, DIR_DOWN
L9924:  .byte DIR_DOWN,  DIR_DOWN, DIR_RIGHT, DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN, DIR_DOWN
L992C:  .byte DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN, DIR_DOWN
L9934:  .byte DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN, DIR_DOWN
L993C:  .byte DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN,  DIR_DOWN, DIR_DOWN,  DIR_DOWN, DIR_DOWN
L9944:  .byte DIR_DOWN,  DIR_DOWN, DIR_DOWN

;----------------------------------------------------------------------------------------------------

;There is another cost table in bank 1. It is used for displaying the costs in the shop
;inventory window.  This table is used to calculate the cost when items are bought and
;sold. The order of the items is slightly different between tables.

ItemCostTbl:
L9947:  .word $000A             ;Bamboo pole        - 10    gold.
L9949:  .word $003C             ;Club               - 60    gold.
L994B:  .word $00B4             ;Copper sword       - 180   gold.
L994D:  .word $0230             ;Hand axe           - 560   gold.
L994F:  .word $05DC             ;Broad sword        - 1500  gold.
L9951:  .word $2648             ;Flame sword        - 9800  gold.
L9953:  .word $0002             ;Erdrick's sword    - 2     gold.
L9955:  .word $0014             ;Clothes            - 20    gold.
L9957:  .word $0046             ;Leather armor      - 70    gold.
L9959:  .word $012C             ;Chain mail         - 300   gold.
L995B:  .word $03E8             ;Half plate         - 1000  gold.
L995D:  .word $0BB8             ;Full plate         - 3000  gold.
L995F:  .word $1E14             ;Magic armor        - 7700  gold.
L9961:  .word $0002             ;Erdrick's armor    - 2     gold.
L9963:  .word $005A             ;Small shield       - 90    gold.
L9965:  .word $0320             ;Large shield       - 800   gold.
L9967:  .word $39D0             ;Silver shield      - 14800 gold.
L9969:  .word $0018             ;Herb               - 24    gold.
L996B:  .word $0035             ;Magic key          - 53    gold.
L996D:  .word $0008             ;Torch              - 8     gold.
L996F:  .word $0026             ;Fairy water        - 38    gold.
L9971:  .word $0046             ;Wings              - 70    gold.
L9973:  .word $0014             ;Dragon's scale     - 20    gold.
L9975:  .word $0000             ;Fairy flute        - 0     gold.
L9977:  .word $001E             ;Fighter's ring     - 30    gold.
L9979:  .word $0000             ;Erdrick's token    - 0     gold.
L997B:  .word $0000             ;Gwaelin's love     - 0     gold.
L997D:  .word $0168             ;Cursed belt        - 360   gold.
L997F:  .word $0000             ;Silver harp        - 0     gold.
L9981:  .word $0960             ;Death necklace     - 2400  gold.
L9983:  .word $0000             ;Stones of sunlight - 0     gold.
L9985:  .word $0000             ;Staff of rain      - 0     gold.
L9987:  .word $0000             ;Rainbow drop       - 0     gold.

;----------------------------------------------------------------------------------------------------

KeyCostTbl:
L9989:  .byte $62               ;Cantlin            - 98    gold.
L998A:  .byte $35               ;Rimuldar           - 53    gold.
L998B:  .byte $55               ;Tantagel castle    - 85    gold.

;----------------------------------------------------------------------------------------------------

InnCostTbl:
L998C:  .byte $14               ;Kol                - 20    gold.
L998D:  .byte $06               ;Brecconary         - 6     gold.
L998E:  .byte $19               ;Garinham           - 25    gold.
L998F:  .byte $64               ;Cantlin            - 100   gold.
L9990:  .byte $37               ;Rimuldar           - 55    gold.

;----------------------------------------------------------------------------------------------------

;The following table contains the item availablle in the shops.  The first 7 rows are the items
;in the weapons and armor shops while the remaining rows are for the tool shops.  The values in
;the table correspond to the item indexes in the ItemCostTbl above.

ShopItemsTbl:

;Koll weapons and armor shop.
L9991:  .byte $02, $03, $0A, $0B, $0E, $FD

;Brecconary weapons and armor shop.
L9997:  .byte $00, $01, $02, $07, $08, $0E, $FD

;Garinham weapons and armor shop.
L999E:  .byte $01, $02, $03, $08, $09, $0A, $0F, $FD

;Cantlin weapons and armor shop 1.
L99A6:  .byte $00, $01, $02, $08, $09, $0F, $FD

;Cantlin weapons and armor shop 2.
L99AD:  .byte $03, $04, $0B, $0C, $FD

;Cantlin weapons and armor shop 3.
L99B2:  .byte $05, $10, $FD

;Rimuldar weapons and armor shop.
L99B5:  .byte $02, $03, $04, $0A, $0B, $0C, $FD

;Koll item shop.
L99BC:  .byte $11, $13, $16, $15, $FD

;Brecconary item shop.
L99C1:  .byte $11, $13, $16, $FD

;Garinham item shop.
L99C5:  .byte $11, $13, $16, $FD

;Cantlin item shop 1.
L99C9:  .byte $11, $13, $FD

;Cantlin item shop 2.
L99CC:  .byte $16, $15, $FD 

;----------------------------------------------------------------------------------------------------
;This table contains weapon bonuses added to the
;strength score to produce the attack power stat.

WeaponsBonusTbl:
L99CF:  .byte $00   ;None            +0.
L99D0:  .byte $02   ;Bamboo pole     +2.
L99D1:  .byte $04   ;Club            +4.
L99D2:  .byte $0A   ;Copper sword    +10.
L99D3:  .byte $0F   ;Hand axe        +15.
L99D4:  .byte $14   ;Broad sword     +20.
L99D5:  .byte $1C   ;Flame sword     +28
L99D6:  .byte $28   ;Erdrick's sword +40.

;This table contains armor bonuses added to the
;agility score to produce the defense power stat.

ArmorBonusTbl:
L99D7:  .byte $00   ;None            +0.
L99D8:  .byte $02   ;Clothes         +2.
L99D9:  .byte $04   ;Leather armor   +4.
L99DA:  .byte $0A   ;Chain mail      +10.
L99DB:  .byte $10   ;Half plate      +16.
L99DC:  .byte $18   ;Full plate      +24.
L99DD:  .byte $18   ;Magic armor     +24.
L99DE:  .byte $1C   ;Erdrick's armor +28.

;This table contains shield bonuses added to the
;agility score to produce the defense power stat.

ShieldBonusTbl:
L99DF:  .byte $00   ;None            +0.
L99E0:  .byte $04   ;Small shield    +4.
L99E1:  .byte $0A   ;Large shield    +10.
L99E2:  .byte $14   ;Silver shield   +20.

;----------------------------------------------------------------------------------------------------

;The following table converts the overworld map block types to standard block IDs. The
;index in the table represents the map block type while the value in the table is the
;standard block ID.

WrldBlkConvTbl:
L99E3:  .byte BLK_GRASS         ;Index $00 - G = Grass.
L99E4:  .byte BLK_SAND          ;Index $01 - D = Desert.
L99E5:  .byte BLK_HILL          ;Index $02 - H = Hills.
L99E6:  .byte BLK_MOUNTAIN      ;Index $03 - M = Mountain.
L99E7:  .byte BLK_WATER         ;Index $04 - W = Water.
L99E8:  .byte BLK_STONE         ;Index $05 - R = Rock Wall.
L99E9:  .byte BLK_TREES         ;Index $06 - F = Forest
L99EA:  .byte BLK_SWAMP         ;Index $07 - P = Poison.
L99EB:  .byte BLK_TOWN          ;Index $08 - T = Town.
L99EC:  .byte BLK_CAVE          ;Index $09 - U = Underground Tunnel.
L99ED:  .byte BLK_CASTLE        ;Index $0A - C = Castle.
L99EE:  .byte BLK_BRIDGE        ;Index $0B - B = Bridge.
L99EF:  .byte BLK_STAIR_DN      ;Index $0C - S = Stairs.

;----------------------------------------------------------------------------------------------------

;The following table converts blocks from the various maps into standard block IDs. The table
;has 3 parts.  The first part converts the overworld water blocks into the various blocks with
;a shore pattern. The second part does town block conversions while the third part does dungeon
;block conversions. As in the table above, the index into the table is the map block type while
;the vale in the table is the standard block ID.

GenBlkConvTbl:

;Overworld water block conversions.
L99F0:  .byte BLK_WATER         ;Water - no shore.
L99F1:  .byte BLK_WTR_T         ;Water - shore at top.
L99F2:  .byte BLK_WTR_L         ;Water - shore at left.
L99F3:  .byte BLK_WTR_TL        ;Water - shore at top, left.
L99F4:  .byte BLK_WTR_R         ;Water - shore at right.
L99F5:  .byte BLK_WTR_TR        ;Water - shore at top, right.
L99F6:  .byte BLK_WTR_LR        ;Water - shore at left, right.
L99F7:  .byte BLK_WTR_TLR       ;Water - shore at top, left, right.
L99F8:  .byte BLK_WTR_B         ;Water - shore at bottom.
L99F9:  .byte BLK_WTR_TB        ;Water - shore at top, bottom.
L99FA:  .byte BLK_WTR_LB        ;Water - shore at left, bottom.
L99FB:  .byte BLK_WTR_TLB       ;Water - shore at top, left, bottom.
L99FC:  .byte BLK_WTR_RB        ;Water - shore at right, bottom.
L99FD:  .byte BLK_WTR_TRB       ;Water - shore at top, right, bottom.
L99FE:  .byte BLK_WTR_LRB       ;Water - shore at left, right and bottom.
L99FF:  .byte BLK_WTR_TLRB      ;Water - shore at all sides.

;Town block conversions.
L9A00:  .byte BLK_GRASS         ;Index $00 - Grass.
L9A01:  .byte BLK_SAND          ;Index $01 - Sand.
L9A02:  .byte BLK_WATER         ;Index $02 - Water.
L9A03:  .byte BLK_CHEST         ;Index $03 - Treasure chest.
L9A04:  .byte BLK_STONE         ;Index $04 - Stone.
L9A05:  .byte BLK_STAIR_UP      ;Index $05 - Stairs up.
L9A06:  .byte BLK_BRICK         ;Index $06 - Brick.
L9A07:  .byte BLK_STAIR_DN      ;Index $07 - Stairs down.
L9A08:  .byte BLK_TREES         ;Index $08 - Trees.
L9A09:  .byte BLK_SWAMP         ;Index $09 - Poison.
L9A0A:  .byte BLK_FFIELD        ;Index $0A - Force field.
L9A0B:  .byte BLK_DOOR          ;Index $0B - Door.
L9A0C:  .byte BLK_SHOP          ;Index $0C - Weapon shop sign.
L9A0D:  .byte BLK_INN           ;Index $0D - Inn sign.
L9A0E:  .byte BLK_BRIDGE        ;Index $0E - Bridge.
L9A0F:  .byte BLK_LRG_TILE      ;Index $0F - Large tile.

;Dungeon block conversions.
L9A10:  .byte BLK_STONE         ;Index $00 - Stone.
L9A11:  .byte BLK_STAIR_UP      ;Index $01 - Stairs Up.
L9A12:  .byte BLK_BRICK         ;Index $02 - Brick.
L9A13:  .byte BLK_STAIR_DN      ;Index $03 - Stairs Down.
L9A14:  .byte BLK_CHEST         ;Index $04 - Treasure Chest.
L9A15:  .byte BLK_DOOR          ;Index $05 - Door.
L9A16:  .byte BLK_PRINCESS      ;Index $0E - Gwaelin.
L9A17:  .byte BLK_BLANK         ;Index $0F - Blank.

;----------------------------------------------------------------------------------------------------

;Palette data pointers.

BlackPalPtr:
L9A18:  .word BlackPal          ;($9A3A)Palette where all colors are black.

OverworldPalPtr:
L9A1A:  .word OverworldPal      ;($9A46)Background palette used on the overworld map.

TownPalPtr:
L9A1C:  .word TownPal           ;($9A56)Background palette used in towns.

DungeonPalPtr:
L9A1E:  .word DungeonPal        ;($9A66)Background palette used in dungeons.

PreGamePalPtr:
L9A20:  .word PreGamePal        ;($9A73)Background palette for pre-game windows.

RedFlashPalPtr:
L9A22:  .word RedFlashPal       ;(9A7F)Palette used to flash red when damage occurs.

RegSPPalPtr:
L9A24:  .word RegSPPal          ;(9A8B)Normal sprite palette used while walking on map.

SplFlshBGPalPtr:
L9A26:  .word SplFlshBGPal      ;(9A7F)Palette used when enemy is casting a spell.

BadEndBGPalPtr:
L9A28:  .word BadEndBGPal       ;($9AA3)Palette when choosing to join the dragonlord.

EnSPPalsPtr:
L9A2A:  .word EnSPPals          ;($9AAF)Enemy sprite palettes.

FadePalPtr:
L9A2C:  .word FadePal           ;($9A2E)Palette used for fade in/fade out.

;----------------------------------------------------------------------------------------------------

;Palette data.

FadePal:
L9A2E:  .byte $0E, $30, $30, $0E, $24, $24, $0E, $27, $27, $0E, $2A, $2A

BlackPal:
L9A3A:  .byte $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

OverworldPal:
L9A46:  .byte $30, $10, $11, $10, $00, $29, $29, $1A, $27, $29, $37, $11

L9A52:  .byte $0E, $0E, $0E, $0E    ;Unused palette data.

TownPal:
L9A56:  .byte $30, $10, $11, $10, $00, $16, $29, $1A, $27, $29, $37, $11

L9A62:  .byte $0E, $0E, $0E, $0E    ;Unused palette data.

DungeonPal:
L9A66:  .byte $30, $0E, $0E, $10, $00, $16, $0E, $0E, $0E, $0E, $0E, $0E

L9A72:  .byte $0E                   ;Unused palette data.

PreGamePal:
L9A73:  .byte $30, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

RedFlashPal:
L9A7F:  .byte $16, $16, $16, $16, $16, $16, $16, $16, $16, $16, $16, $16

RegSPPal:
L9A8B:  .byte $35, $30, $12, $35, $27, $1A, $35, $30, $00, $35, $30, $07

SplFlshBGPal:
L9A97:  .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10

BadEndBGPal:
L9AA3:  .byte $16, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

;----------------------------------------------------------------------------------------------------

EnSPPals:                       ;Enemy sprite palettes.
BSlimePal:
L9AAF:  .byte $1C, $15, $30, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

RSlimePal:
L9ABB:  .byte $16, $0D, $30, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

DrakeePal:
L9AC7:  .byte $01, $15, $30, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

GhostPal:
L9AD3:  .byte $13, $15, $0C, $26, $0C, $0E, $26, $30, $0E, $26, $15, $0E

MagicianPal:
L9AE0:  .byte $00, $36, $0F, $00, $30, $0F, $26, $14, $29, $0E, $0E, $00

MDrakeePal:
L9AEB:  .byte $15, $0E, $30, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

ScorpionPal:
L9AF7:  .byte $26, $13, $1E, $0E, $0E, $30, $0E, $0E, $0E, $0E, $0E, $0E

DruinPal:
L9B03:  .byte $26, $03, $30, $15, $27, $07, $03, $15, $0E, $0E, $0E, $0E

PltrGstPal:
L9B0F:  .byte $2B, $15, $1B, $23, $1B, $0E, $23, $30, $0E, $23, $15, $0E

DrollPal:
L9B1B:  .byte $34, $15, $30, $34, $15, $13, $34, $07, $13, $07, $15, $13

DrakeemaPal:
L9B27:  .byte $36, $0E, $25, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

SkeletonPal:
L9B33:  .byte $30, $00, $0D, $27, $0C, $07, $30, $1C, $0D, $30, $0C, $1C

WarlockPal:
L9B3F:  .byte $06, $0C, $0F, $06, $30, $0F, $17, $15, $21, $0E, $0E, $06

MScorpionPal:
L9B4B:  .byte $10, $15, $1E, $0E, $0E, $30, $0E, $0E, $0E, $0E, $0E, $0E

WolfPal:
L9B57:  .byte $2C, $06, $0E, $2C, $30, $0E, $26, $06, $30, $2C, $06, $0C

WraithPal:
L9B63:  .byte $30, $00, $0D, $0E, $17, $1B, $30, $18, $0D, $30, $17, $1C

MSlimePal:
L9B6F:  .byte $00, $0D, $30, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

SpecterPal:
L9B7B:  .byte $27, $15, $07, $1C, $07, $0E, $1C, $30, $0E, $1C, $15, $0E

WolfLordPal:
L9B87:  .byte $06, $10, $0E, $06, $30, $0E, $26, $15, $30, $06, $10, $15

DruinLordPal:
L9B93:  .byte $13, $05, $30, $1A, $2C, $0C, $05, $1A, $0E, $0E, $0E, $0E

DrollMagiPal:
L9B9F:  .byte $10, $05, $30, $10, $05, $00, $10, $10, $00, $10, $05, $00

WyvernPal:
L9BAB:  .byte $0C, $10, $30, $0C, $15, $26, $10, $26, $0E, $30, $26, $0E

RScorpionPal:
L9BB7:  .byte $1C, $06, $1E, $0E, $0E, $35, $0E, $0E, $0E, $0E, $0E, $0E

WKnightPal:
L9BC3:  .byte $30, $00, $0D, $27, $06, $03, $30, $25, $0D, $30, $06, $1C

GolemPal:
L9BCF:  .byte $26, $16, $0E, $0E, $0E, $30, $0E, $0E, $0E, $0E, $0E, $0E

GoldManPal:
L9BDB:  .byte $37, $27, $0E, $0E, $0E, $25, $0E, $0E, $0E, $0E, $0E, $0E

KnightPal:
L9BE7:  .byte $21, $1C, $0E, $15, $1C, $0E, $17, $0C, $21, $21, $15, $0E

MagiWyvernPal:
L9BF3:  .byte $06, $37, $30, $06, $15, $26, $37, $26, $0E, $30, $26, $0E

DKnightPal:
L9BFF:  .byte $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E

WerewolfPal:
L9C0B:  .byte $27, $02, $0E, $27, $30, $0E, $30, $06, $30, $27, $02, $06

GDragonPal:
L9C17:  .byte $1A, $27, $0E, $10, $27, $1A, $30, $26, $0C, $1A, $10, $0E

StarWyvernPal:
L9C23:  .byte $15, $34, $31, $15, $30, $27, $34, $27, $0E, $30, $26, $0E

WizardPal:
L9C2F:  .byte $37, $10, $0F, $37, $30, $0F, $00, $26, $1C, $0E, $0E, $37

AxeKnightPal:
L9C3B:  .byte $10, $00, $0E, $22, $00, $0E, $15, $0C, $30, $10, $22, $0E

BDragonPal:
L9C47:  .byte $1C, $25, $0E, $17, $25, $1C, $30, $16, $07, $1C, $17, $0E

StoneManPal:
L9C53:  .byte $10, $00, $0E, $0E, $0E, $25, $0E, $0E, $0E, $0E, $0E, $0E

ArmorKnightPal:
L9C5F:  .byte $25, $16, $0E, $27, $16, $0E, $10, $37, $27, $25, $27, $0E

RDragonPal:
L9C6B:  .byte $17, $10, $0E, $22, $10, $17, $30, $16, $0C, $17, $22, $0E

DrgnLrd1Pal:
L9C77:  .byte $03, $21, $0F, $26, $21, $0C, $30, $15, $0C, $30, $15, $26

DrgnLrd2Pal:
L9C83:  .byte $21, $22, $27, $17, $0C, $30, $07, $15, $30, $21, $27, $15

;----------------------------------------------------------------------------------------------------

;The following data block is the nametable pointers for the overworld combat
;background graphics.  The graphical area is 14 rows by 14 columns.  The data
;below starts at the upper left corner of the background and progresses left
;to right, top to bottom.

CombatBckgndGFX:
L9C8F:  .byte $BA, $BC, $BC, $BC, $BC, $BC, $BC, $BC, $BC, $BC, $BC, $BC, $BC, $BD
L9C9D:  .byte $BB, $B2, $AF, $AD, $AE, $B2, $B2, $B2, $B2, $B2, $B2, $AD, $B1, $BE
L9CAB:  .byte $BB, $B2, $EE, $E1, $B2, $B2, $B2, $AF, $B0, $B1, $B2, $B2, $B2, $BE
L9CB9:  .byte $BB, $B2, $DE, $E2, $B2, $B2, $B2, $B2, $B2, $B2, $B2, $B5, $B2, $BE
L9CC7:  .byte $EB, $EA, $CA, $CE, $E5, $E3, $E3, $E3, $DF, $E4, $B3, $B6, $B8, $BE
L9CD5:  .byte $EC, $ED, $CC, $D0, $E6, $E9, $E9, $E7, $E0, $E8, $B4, $B7, $B9, $BF
L9CE3:  .byte $DC, $D1, $D2, $D7, $DB, $CD, $CD, $CD, $CD, $D3, $CB, $CF, $CF, $D4
L9CF1:  .byte $DD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $D3, $D4
L9CFF:  .byte $C9, $C2, $C4, $C6, $CD, $CD, $CD, $CD, $CD, $CD, $C6, $C6, $CD, $D5
L9D0D:  .byte $C1, $C3, $C5, $C6, $CD, $CD, $CD, $CD, $CD, $CD, $C6, $C8, $CD, $D5
L9D1B:  .byte $D9, $CD, $C7, $C6, $CD, $CD, $CD, $CD, $C6, $C6, $CD, $CD, $CD, $D5
L9D29:  .byte $D9, $CD, $C6, $C8, $CD, $CD, $CD, $CD, $C6, $C6, $CD, $CD, $CD, $D5
L9D37:  .byte $D9, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $CD, $D5
L9D45:  .byte $D8, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $DA, $D6 

;----------------------------------------------------------------------------------------------------

;This table contains the number of points it takes to cast each spell.

SpellCostTbl:
L9D53:  .byte $04               ;Heal      4MP.
L9D54:  .byte $02               ;Hurt      2MP.
L9D55:  .byte $02               ;Sleep     2MP.
L9D56:  .byte $03               ;Radiant   3MP.
L9D57:  .byte $02               ;Stopspell 2MP.
L9D58:  .byte $06               ;Outside   6MP.
L9D59:  .byte $08               ;Return    8MP.
L9D5A:  .byte $02               ;Repel     2MP.
L9D5B:  .byte $0A               ;Healmore  10MP.
L9D5C:  .byte $05               ;Hurtmore  5MP.

;----------------------------------------------------------------------------------------------------

;Start of world map data.

;The world map uses run length encoding because it would be too big for the memory otherwise.
;Each byte is broken down into the upper and lower nibble.  The upper nibble is the type of tile
;and can be decided from the table below.  The second nibble+1 is the number of times the tile is
;repeated.  Some rows have less than 120 tiles in them and use data from the next row until 120
;tiles have been calculated for the row.

;0 - G = Grass.
;1 - D = Desert.
;2 - H = Hills.
;3 - M = Mountain.
;4 - W = Water.
;5 - R = Rock Wall.
;6 - F = Forest
;7 - P = Poison.
;8 - T = Town.
;9 - U = Underground Tunnel.
;A - C = Castle.
;B - B = Bridge.
;C - S = Stairs.
;D - N/A.
;E - N/A.
;F - N/A.

Row000:      ;W02  G06  W12  G07  W15  G08  W16  W09  F05  G03  W14  G10  W13  
L9D5D:  .byte $41, $05, $4B, $06, $4E, $07, $4F, $48, $64, $02, $4D, $09, $4C

Row001:      ;W01  G03  F04  G02  W08  G11  W11  G06  H08  W16  W02  F08  G01  S01  G01  W09  
L9D6A:  .byte $40, $02, $63, $01, $47, $0A, $4A, $05, $27, $4F, $41, $67, $00, $C0, $00, $48
;             M07  H05  G07  W09  
L9D7A:  .byte $36, $24, $06, $48

Row002:      ;G02  T01  F06  G02  W05  G06  F05  G03  W09  G06  F05  H06  W14  F09  G03  W09  
L9D7E:  .byte $01, $80, $65, $01, $44, $05, $64, $02, $48, $05, $64, $25, $4D, $68, $02, $48
;             M04  H10  G07  W08  
L9D8E:  .byte $33, $29, $06, $47

Row003:      ;G01  F09  G11  F08  G02  W08  G05  F09  H04  W12  F10  M02  W09  M03  H13  G09  
L9D92:  .byte $00, $68, $0A, $67, $01, $47, $04, $68, $23, $4B, $69, $31, $48, $32, $2C, $08
;             W05  
L9DA2:  .byte $44

Row004:      ;F06  H05  M03  G06  F10  G02  W06  G05  F10  H05  W11  F09  M03  W07  M03  H09  
L9DA3:  .byte $65, $24, $32, $05, $69, $01, $45, $04, $69, $24, $4A, $68, $32, $46, $32, $28
;             F08  G08  W04  
L9DB3:  .byte $67, $07, $43

Row005:      ;F05  H05  M05  G05  F10  G04  W02  G05  F05  W03  F05  H04  W10  F09  M03  W07  
L9DB6:  .byte $64, $24, $34, $04, $69, $03, $41, $04, $64, $42, $64, $23, $49, $68, $32, $46
;             M03  H08  F12  G07  W03  
L9DC6:  .byte $32, $27, $6B, $06, $42

Row006:      ;F03  H05  M08  G03  F13  G09  F04  W05  F03  H04  W09  M03  F07  M03  W07  H11  
L9DCB:  .byte $62, $24, $37, $02, $6C, $08, $63, $44, $62, $23, $48, $32, $66, $32, $46, $2A
;             F14  G06  W03  
L9DDB:  .byte $6D, $05, $42

Row007:      ;H06  M05  F04  M04  F12  G09  F06  W03  H07  W09  M03  F09  M03  W07  H09  F06  
L9DDE:  .byte $25, $34, $63, $33, $6B, $08, $65, $42, $26, $48, $32, $68, $32, $46, $28, $65
;             M05  F06  G05  W02  
L9DEE:  .byte $34, $65, $04, $41

Row008:      ;H04  M04  F09  M03  F13  G06  F06  W03  H08  W10  M03  F09  M03  W05  H08  F06  
L9DF2:  .byte $23, $33, $68, $32, $6C, $05, $65, $42, $27, $49, $32, $68, $32, $44, $27, $65
;             M03  F03  M03  F06  G03  W02  
L9E02:  .byte $32, $62, $32, $65, $02, $41

Row009:      ;H04  M02  F12  M02  F06  D04  F05  G05  F07  H08  W09  F03  M03  F10  M02  W04  
L9E08:  .byte $23, $31, $6B, $31, $65, $13, $64, $04, $66, $27, $48, $62, $32, $69, $31, $43
;             H08  F05  M02  F06  M02  F07  G03  W01  
L9E18:  .byte $27, $64, $31, $65, $31, $66, $02, $40

Row010:      ;H02  G03  F12  M03  F05  D06  F06  G05  F06  H06  W09  F03  M04  F11  M02  W04  
L9E20:  .byte $21, $02, $6B, $32, $64, $15, $65, $04, $65, $25, $48, $62, $33, $6A, $31, $43
;             H07  F10  T01  F03  M02  F08  
L9E30:  .byte $26, $69, $80, $62, $31, $67

Row011:      ;W02  G04  F12  M03  F03  D08  F06  G05  F07  H03  W10  F04  M04  F10  M02  W05  
L9E36:  .byte $41, $03, $6B, $32, $62, $17, $65, $04, $66, $22, $49, $63, $33, $69, $31, $44
;             H07  F16  F08  
L9E46:  .byte $26, $6F, $67

Row012:      ;W03  G05  F10  M04  F02  D04  U01  D03  F05  G06  F07  H05  W07  F05  M04  F11  
L9E49:  .byte $42, $04, $69, $33, $61, $13, $90, $12, $64, $05, $66, $24, $46, $64, $33, $6A
;             M01  W05  H08  F16  F08  
L9E59:  .byte $30, $44, $27, $6F, $67

Row013:      ;W04  G08  F07  M04  F02  D07  F06  G06  F07  H05  W05  F07  M06  F08  M02  W04  
L9E5E:  .byte $43, $07, $66, $33, $61, $16, $65, $05, $66, $24, $44, $66, $35, $67, $31, $43
;             H10  F16  F06  
L9E6E:  .byte $29, $6F, $65

Row014:      ;W05  F04  G05  F06  M04  F03  D04  F08  G04  F08  H04  G02  W03  F09  M06  F07  
L9E71:  .byte $44, $63, $04, $65, $33, $62, $13, $67, $03, $67, $23, $01, $42, $68, $35, $66
;             M03  W04  H07  G04  F16  F04  
L9E81:  .byte $32, $43, $26, $03, $6F, $63

Row015:      ;W04  F05  G06  F07  M03  F13  G06  F08  H02  G03  W02  F07  G07  M03  F07  M03  
L9E87:  .byte $43, $64, $05, $66, $32, $6C, $05, $67, $21, $02, $41, $66, $06, $32, $66, $32
;             W04  H05  G06  F16  
L9E97:  .byte $43, $24, $05, $6F

Row016:      ;W06  F02  G07  F06  G04  F13  G05  F10  G04  W02  F04  G12  M04  F05  M03  W05  
L9E9B:  .byte $45, $61, $06, $65, $03, $6C, $04, $69, $03, $41, $63, $0B, $33, $64, $32, $44
;             F02  G07  F12  W07  
L9EAB:  .byte $61, $06, $6B, $46

Row017:      ;W03  F06  G07  F04  G05  F12  G05  F10  G06  W02  G16  G01  M03  F05  M03  W02  
L9EAF:  .byte $42, $65, $06, $63, $04, $6B, $04, $69, $05, $41, $0F, $00, $32, $64, $32, $41
;             F03  G07  F08  M04  W08  
L9EBF:  .byte $62, $06, $67, $33, $47

Row018:      ;W02  F09  G13  F13  G06  F08  G08  W02  G16  G01  M04  F04  W03  F04  G07  F04  
L9EC4:  .byte $41, $68, $0C, $6C, $05, $67, $07, $41, $0F, $00, $33, $63, $42, $63, $06, $63
;             M06  F04  W06  
L9ED4:  .byte $35, $63, $45

Row019:      ;W02  F09  G13  F14  G06  F06  G10  B01  G06  F06  G06  M04  F09  G07  F02  M07  
L9ED7:  .byte $41, $68, $0C, $6D, $05, $65, $09, $B0, $05, $65, $05, $33, $68, $06, $61, $36
;             F03  D04  W05  
L9EE7:  .byte $62, $13, $44

Row020:      ;W01  F11  G14  F12  G07  F03  G12  W02  G04  F08  G06  M10  F02  W01  G05  F02  
L9EEA:  .byte $40, $6A, $0D, $6B, $06, $62, $0B, $41, $03, $67, $05, $39, $61, $40, $04, $61
;             M05  F05  D07  W03  
L9EFA:  .byte $34, $64, $16, $42

Row021:      ;F12  G15  F10  G16  G08  W01  G03  F10  G05  F02  M09  W02  G05  F01  M06  D13  
L9EFE:  .byte $6B, $0E, $69, $0F, $07, $40, $02, $69, $04, $61, $38, $41, $04, $60, $35, $1C
;             W02  
L9F0E:  .byte $41

Row022:      ;F13  G12  H04  F07  G16  G09  W01  G02  F05  H04  F03  G03  F07  H03  W05  G05  
L9F0F:  .byte $6C, $0B, $23, $66, $0F, $08, $40, $01, $64, $23, $62, $02, $66, $22, $44, $04
;             M05  D16  
L9F1F:  .byte $34, $1F

Row023:      ;F14  G07  W03  H07  F04  G15  F04  G07  W02  F04  H06  F04  G03  F05  H05  W04  
L9F21:  .byte $6D, $06, $42, $26, $63, $0E, $63, $06, $41, $63, $25, $63, $02, $64, $24, $43
;             G06  M03  D10  F02  D05  
L9F31:  .byte $05, $32, $19, $61, $14

Row024:      ;F15  G04  W07  H06  F04  G10  F09  G07  W02  F03  H07  F04  G04  F02  H07  W04  
L9F36:  .byte $6E, $03, $46, $25, $63, $09, $68, $06, $41, $62, $26, $63, $03, $61, $26, $43
;             G08  D09  F04  D04  
L9F46:  .byte $07, $18, $63, $13

Row025:      ;F16  G02  W09  H05  F04  G08  F10  H03  G06  W02  F03  H07  F04  G06  H07  W04  
L9F4A:  .byte $6F, $01, $48, $24, $63, $07, $69, $22, $05, $41, $62, $26, $63, $05, $26, $43
;             G07  D09  F04  D04  
L9F5A:  .byte $06, $18, $63, $13

Row026:      ;F16  F01  W10  H04  F04  G08  F10  H06  G05  W02  F03  H05  F05  G07  F07  W03  
L9F5E:  .byte $6F, $60, $49, $23, $63, $07, $69, $25, $04, $41, $62, $24, $64, $06, $66, $42
;             G07  D10  F02  D05  
L9F6E:  .byte $06, $19, $61, $14

Row027:      ;W02  F15  W09  M03  F06  G07  F10  H08  G05  W05  F10  G05  F07  W05  G07  D15  
L9F72:  .byte $41, $6E, $48, $32, $65, $06, $69, $27, $04, $44, $69, $04, $66, $44, $06, $1E

Row028:      ;W03  F13  W09  M07  F02  G06  F12  H09  G07  W05  F08  G05  F05  W05  G09  D13  
L9F82:  .byte $42, $6C, $48, $36, $61, $05, $6B, $28, $06, $44, $67, $04, $64, $44, $08, $1C

Row029:      ;W08  F07  W06  M12  G07  F13  H08  G04  M04  W05  F07  G06  F03  W05  G11  D11  
L9F92:  .byte $47, $66, $45, $3B, $06, $6C, $27, $03, $33, $44, $66, $05, $62, $44, $0A, $1A

Row030:      ;W04  H03  W03  F04  W05  M15  G05  F09  M06  H06  G03  M05  W07  F07  G06  W06  
L9FA2:  .byte $43, $22, $42, $63, $44, $3E, $04, $68, $35, $25, $02, $34, $46, $66, $05, $45
;             G14  D07  W05  
L9FB2:  .byte $0D, $16, $44

Row031:      ;W03  H06  B01  F02  W03  M16  M01  G06  F07  M10  H06  M06  W09  F06  G07  W06  
L9FB5:  .byte $42, $25, $B0, $61, $42, $3F, $30, $05, $66, $39, $25, $35, $48, $65, $06, $45
;             G13  H06  W06  
L9FC5:  .byte $0C, $25, $45

Row032:      ;W02  H07  W05  H04  M12  G09  F03  M14  H05  M07  W07  F06  G08  W07  G10  H10  
L9FC8:  .byte $41, $26, $44, $23, $3B, $08, $62, $3D, $24, $36, $46, $65, $07, $46, $09, $29
;             W04  
L9FD8:  .byte $43

Row033:      ;W02  H16  H03  M07  G12  M07  H04  M06  F03  M09  W05  F08  G08  W05  G10  H08  
L9FD9:  .byte $41, $2F, $22, $36, $0B, $36, $23, $35, $62, $38, $44, $67, $07, $44, $09, $27
;             F04  W03  
L9FE9:  .byte $63, $42

Row034:      ;W02  H16  H05  M04  G12  M04  H11  M02  F10  M04  W03  F10  G08  W03  G10  H07  
L9FEB:  .byte $41, $2F, $24, $33, $0B, $33, $2A, $31, $69, $33, $42, $69, $07, $42, $09, $26
;             F07  
L9FFB:  .byte $66

Row035:      ;W03  H10  G04  H07  M02  G14  H15  M02  F05  D05  M07  F08  G09  W02  G10  H07  
L9FFC:  .byte $42, $29, $03, $26, $31, $0D, $2E, $31, $64, $14, $36, $67, $08, $41, $09, $26
;             F09  
LA00C:  .byte $68

Row036:      ;W04  H03  F04  G08  H05  W02  G13  F07  H08  M04  F02  D09  M06  F06  G09  W02  
LA00D:  .byte $43, $22, $63, $07, $24, $41, $0C, $66, $27, $33, $61, $18, $35, $65, $08, $41
;             G05  M04  H08  F11  
LA01D:  .byte $04, $33, $27, $6A

Row037:      ;W02  F08  G10  H03  W04  G11  F11  H06  M04  D09  P03  F09  G10  B01  G03  F02  
LA021:  .byte $41, $67, $09, $22, $43, $0A, $6A, $25, $33, $18, $72, $68, $09, $B0, $02, $61
;             M06  H06  F11  
LA031:  .byte $35, $25, $6A

Row038:      ;W01  F07  G11  H04  W05  G08  F14  H08  W04  D05  P05  F09  G06  W04  F05  M07  
LA034:  .byte $40, $66, $0A, $23, $44, $07, $6D, $27, $43, $14, $74, $68, $05, $43, $64, $36
;             H04  F12  W01  
LA044:  .byte $23, $6B, $40

Row039:      ;F07  G10  F05  W05  G08  F14  G04  H04  W08  P08  F07  G04  W07  F08  M05  H02  
LA047:  .byte $66, $09, $64, $44, $07, $6D, $03, $23, $47, $77, $66, $03, $46, $67, $34, $21
;             F12  W02  
LA057:  .byte $6B, $41

Row040:      ;F05  G09  F07  W06  G07  F11  G10  W09  P08  F07  W13  F04  P04  M04  F13  W03  
LA059:  .byte $64, $08, $66, $45, $06, $6A, $09, $48, $77, $66, $4C, $63, $73, $33, $6C, $42

Row041:      ;F04  G07  F08  W09  G07  F07  G06  T01  G05  W12  P05  F06  W16  W01  P08  M05  
LA069:  .byte $63, $06, $67, $48, $06, $66, $05, $80, $04, $4B, $74, $65, $4F, $40, $77, $34
;             F06  W07  
LA079:  .byte $65, $46

Row042:      ;F05  G05  F05  W10  G11  F04  G09  W16  W04  F05  W16  W07  P06  M07  W10  
LA07B:  .byte $64, $04, $64, $49, $0A, $63, $08, $4F, $43, $64, $4F, $46, $75, $36, $49

Row043:      ;W01  F05  G03  F04  W11  G16  G03  C01  G03  W16  W16  W16  W04  P07  M03  W11  
LA08A:  .byte $40, $64, $02, $63, $4A, $0F, $02, $A0, $02, $4F, $4F, $4F, $43, $76, $32, $4A

Row044:      ;W02  F10  W09  G16  G08  W16  W16  W16  W10  P01  U01  P01  M02  W12  
LA09A:  .byte $41, $69, $48, $0F, $07, $4F, $4F, $4F, $49, $70, $90, $70, $31, $4B

Row045:      ;W02  F09  W09  F06  G16  G01  W08  M03  W16  W15  F06  W16  W13  
LA0A8:  .byte $41, $68, $48, $65, $0F, $00, $47, $32, $4F, $4E, $65, $4F, $4C

Row046:      ;W04  F09  W06  F08  G14  W08  M06  W16  W08  F11  G05  W16  W04  H04  
LA0B5:  .byte $43, $68, $45, $67, $0D, $47, $35, $4F, $47, $6A, $04, $4F, $43, $23

Row047:      ;W03  F11  W08  F07  G11  W07  P03  M07  W16  W01  F15  G09  W16  H06  
LA0C3:  .byte $42, $6A, $47, $66, $0A, $46, $72, $36, $4F, $40, $6E, $08, $4F, $25

Row048:      ;W02  F13  W08  F08  G08  W07  M01  P01  C01  P01  M08  W13  D04  F14  G12  W12  
LA0D1:  .byte $41, $6C, $47, $67, $07, $46, $30, $70, $A0, $70, $37, $4C, $13, $6D, $0B, $4B
;             H07  
LA0E1:  .byte $26

Row049:      ;W03  F11  W10  F08  G08  W05  M02  P03  D02  M07  W02  D03  W01  D03  W02  D07  
LA0E2:  .byte $42, $6A, $49, $67, $07, $44, $31, $72, $11, $36, $41, $12, $40, $12, $41, $16
;             F13  G13  P01  U01  P01  W06  H08  
LA0F2:  .byte $6C, $0C, $70, $90, $70, $45, $27

Row050:      ;W03  F10  M04  W05  F11  G07  W04  M07  D02  M04  D06  W04  D11  F14  G11  P03  
LA0F9:  .byte $42, $69, $33, $44, $6A, $06, $43, $36, $11, $33, $15, $43, $1A, $6D, $0A, $72
;             W05  F04  H05  
LA109:  .byte $44, $63, $24

Row051:      ;W05  F06  M13  F08  G08  W05  M04  D04  M03  D05  M02  W04  M02  D10  F16  F01  
LA10C:  .byte $44, $65, $3C, $67, $07, $44, $33, $13, $32, $14, $31, $43, $31, $19, $6F, $60
;             G06  H06  W02  F10  
LA11C:  .byte $05, $25, $41, $69

Row052:      ;W04  G02  F02  M16  M01  F08  G06  W05  M04  D04  M05  D03  M02  W06  M03  D10  
LA120:  .byte $43, $01, $61, $3F, $30, $67, $05, $44, $33, $13, $34, $12, $31, $45, $32, $19
;             F15  M03  H10  F11  
LA130:  .byte $6E, $32, $29, $6A

Row053:      ;W02  G04  M16  M04  F08  G04  W07  M02  D06  M05  D01  M02  W08  M04  D09  F07  
LA134:  .byte $41, $03, $3F, $33, $67, $03, $46, $31, $15, $34, $10, $31, $47, $33, $18, $66
;             W04  M06  H09  F12  
LA144:  .byte $43, $35, $28, $6B

Row054:      ;W01  G04  M04  F07  M13  F05  H03  W08  M03  D06  M04  H02  M02  W09  M03  D08  
LA148:  .byte $40, $03, $33, $66, $3C, $64, $22, $47, $32, $15, $33, $21, $31, $48, $32, $17
;             F05  W07  M07  H08  F11  
LA158:  .byte $64, $46, $36, $27, $6A

Row055:      ;G04  M03  F10  M14  F04  H03  W08  M02  D06  M03  H02  M03  W10  M04  D05  F04  
LA15D:  .byte $03, $32, $69, $3D, $63, $22, $47, $31, $15, $32, $21, $32, $49, $33, $14, $63
;             W08  M13  H03  F11  
LA16D:  .byte $47, $3C, $22, $6A

Row056:      ;G04  F07  P04  F04  M13  F04  H03  W07  M02  D05  M03  H03  M02  W13  M03  H05  
LA171:  .byte $03, $66, $73, $63, $3C, $63, $22, $46, $31, $14, $32, $22, $31, $4C, $32, $24
;             F04  W04  M04  F05  M08  F12  W01  
LA181:  .byte $63, $43, $33, $64, $37, $6B, $40

Row057:      ;G03  F06  P07  F05  M04  G04  U01  M02  F03  H04  W07  M03  D03  M03  H04  M02  
LA188:  .byte $02, $65, $76, $64, $33, $03, $90, $31, $62, $23, $46, $32, $12, $32, $23, $31
;             W13  M02  H08  F16  M10  F07  W03  
LA198:  .byte $4C, $31, $27, $6F, $39, $66, $42

Row058:      ;G04  F04  P08  F06  G06  M03  H08  W08  M02  D02  M03  H06  M02  W11  M03  H08  
LA19F:  .byte $03, $63, $77, $65, $05, $32, $27, $47, $31, $11, $32, $25, $31, $4A, $32, $27
;             F16  M09  D03  F04  W04  
LA1AF:  .byte $6F, $38, $12, $63, $43

Row059:      ;G03  F06  P06  F07  G05  M03  H08  W09  M02  P01  M06  H01  M05  W12  M02  H06  
LA1B4:  .byte $02, $65, $75, $66, $04, $32, $27, $48, $31, $70, $35, $20, $34, $4B, $31, $25
;             G09  F08  M08  D06  F02  W05  
LA1C4:  .byte $08, $67, $37, $15, $61, $44

Row060:      ;G03  F07  P04  F07  G06  M04  H06  W09  M02  P02  M05  G03  M03  W14  M02  H04  
LA1CA:  .byte $02, $66, $73, $66, $05, $33, $25, $48, $31, $71, $34, $02, $32, $4D, $31, $23
;             G14  F11  D08  F02  W04  
LA1DA:  .byte $0D, $6A, $17, $61, $43

Row061:      ;G03  F16  F01  M15  W12  M02  P02  M03  G03  M03  W14  M03  H03  G16  F09  D08  
LA1DF:  .byte $02, $6F, $60, $3E, $4B, $31, $71, $32, $02, $32, $4D, $32, $22, $0F, $68, $17
;             F04  W03  
LA1EF:  .byte $63, $42

Row062:      ;G04  F14  M11  F04  W15  M02  P02  M03  G03  M03  W14  M03  H03  G15  F10  D06  
LA1F1:  .byte $03, $6D, $3A, $63, $4E, $31, $71, $32, $02, $32, $4D, $32, $22, $0E, $69, $15
;             F05  W03  
LA201:  .byte $64, $42

Row063:      ;W01  G04  F09  H03  M06  F09  G02  W14  M02  P04  M02  G03  M02  W15  M03  H08  
LA203:  .byte $40, $03, $68, $22, $35, $68, $01, $4D, $31, $73, $31, $02, $31, $4E, $32, $27
;             F03  G05  F12  D04  F07  
LA213:  .byte $62, $04, $6B, $13, $66

Row064:      ;W02  G04  F07  H06  M03  F09  G05  W13  M02  P06  M03  W16  W01  M02  H07  F05  
LA218:  .byte $41, $03, $66, $25, $32, $68, $04, $4C, $31, $75, $32, $4F, $40, $31, $26, $64
;             G03  F04  M08  F13  
LA228:  .byte $02, $63, $37, $6C

Row065:      ;W04  G04  F08  H05  F09  G07  W13  M03  P02  M03  W16  W06  H05  F11  M03  G05  
LA22C:  .byte $43, $03, $67, $24, $68, $06, $4C, $32, $71, $32, $4F, $45, $24, $6A, $32, $04
;             M06  F10  
LA23C:  .byte $35, $69

Row066:      ;W06  G04  F07  H06  F05  G08  W16  M04  W16  W10  F13  M03  G09  M04  F09  
LA23E:  .byte $45, $03, $66, $25, $64, $07, $4F, $33, $4F, $49, $6C, $32, $08, $33, $68

Row067:      ;W07  G05  F06  H03  F06  G08  W16  W16  W16  W01  F11  M02  G03  F05  G03  M05  
LA24D:  .byte $46, $04, $65, $22, $65, $07, $4F, $4F, $4F, $40, $6A, $31, $02, $64, $02, $34
;             F07  
LA25D:  .byte $66

Row068:      ;W08  G06  F12  G07  W05  F07  W16  W16  W09  F08  G05  F07  G04  M03  F07  
LA25E:  .byte $47, $05, $6B, $06, $44, $66, $4F, $4F, $48, $67, $04, $66, $03, $32, $66

Row069:      ;W09  G06  F10  G05  W06  F07  W16  W16  W09  F09  G05  F02  W05  F02  G04  M03  
LA26D:  .byte $48, $05, $69, $04, $45, $66, $4F, $4F, $48, $68, $04, $61, $44, $61, $03, $32
;             F06  
LA27D:  .byte $65

Row070:      ;W11  G06  F08  G06  W04  G02  F05  W16  W16  W08  F10  G05  F02  W07  F02  G03  
LA27E:  .byte $4A, $05, $67, $05, $43, $01, $64, $4F, $4F, $47, $69, $04, $61, $46, $61, $02
;             M02  F07  
LA28E:  .byte $31, $66

Row071:      ;W12  G07  F08  G11  F03  W16  W16  W10  F10  G03  F02  W03  G03  W03  F02  G02  
LA290:  .byte $4B, $06, $67, $0A, $62, $4F, $4F, $49, $69, $02, $61, $42, $02, $42, $61, $01
;             M03  F06  
LA2A0:  .byte $32, $65

Row072:      ;W14  G06  F09  G10  W16  W16  W15  F08  G02  F02  W03  G01  T01  G01  D03  F02  
LA2A2:  .byte $4D, $05, $68, $09, $4F, $4F, $4E, $67, $01, $61, $42, $00, $80, $00, $12, $61
;             G02  M02  F07  
LA2B2:  .byte $01, $31, $66

Row073:      ;W06  M06  W09  F12  G04  W16  W16  W16  F13  W03  G03  W03  F02  G02  M02  F07  
LA2B5:  .byte $45, $35, $48, $6B, $03, $4F, $4F, $4F, $6C, $42, $02, $42, $61, $01, $31, $66

Row074:      ;W05  M03  F06  W09  F11  G04  W16  W16  W16  F13  W07  F02  G02  M02  F07  
LA2C5:  .byte $44, $32, $65, $48, $6A, $03, $4F, $4F, $4F, $6C, $46, $61, $01, $31, $66

Row075:      ;W04  M03  F10  W05  F11  G06  W16  W15  M08  W09  F13  W05  F03  M04  F06  
LA2D4:  .byte $43, $32, $69, $44, $6A, $05, $4F, $4E, $37, $48, $6C, $44, $62, $33, $65

Row076:      ;W03  M03  F08  G04  W06  F08  G10  W16  W10  M05  D07  W09  F09  M05  F15  
LA2E3:  .byte $42, $32, $67, $03, $45, $67, $09, $4F, $49, $34, $16, $48, $68, $34, $6E

Row077:      ;W02  M03  F06  G10  W04  F07  G11  W16  W08  D08  M04  D02  W07  F11  M05  F13  
LA2F2:  .byte $41, $32, $65, $09, $43, $66, $0A, $4F, $47, $17, $33, $11, $46, $6A, $34, $6C
;             W03  
LA302:  .byte $42

Row078:      ;W01  M03  F06  G13  W01  F07  G06  F02  G05  W16  W06  M14  D02  W07  F12  M04  
LA303:  .byte $40, $32, $65, $0C, $40, $66, $05, $61, $04, $4F, $45, $3D, $11, $46, $6B, $33
;             H03  F08  G02  W02  
LA313:  .byte $22, $67, $01, $41

Row079:      ;M03  F04  G09  F04  G03  B01  F07  G05  F04  G05  W14  M10  D06  M06  D01  W09  
LA317:  .byte $32, $63, $08, $63, $02, $B0, $66, $04, $63, $04, $4D, $39, $15, $35, $10, $48
;             F11  M03  H04  F06  G05  
LA327:  .byte $6A, $32, $23, $65, $04

Row080:      ;M03  F03  G08  F09  W02  F05  G05  F06  G04  W11  M08  D14  M03  D01  M02  W06  
LA32C:  .byte $32, $62, $07, $68, $41, $64, $04, $65, $03, $4A, $37, $1D, $32, $10, $31, $45
;             F14  M02  H03  F05  G06  
LA33C:  .byte $6D, $31, $22, $64, $05

Row081:      ;M02  F05  G05  F12  W02  F04  G04  F08  G04  W08  M09  D02  M12  D02  M02  D01  
LA341:  .byte $31, $64, $04, $6B, $41, $63, $03, $67, $03, $47, $38, $11, $3B, $11, $31, $10
;             M02  W07  F14  M02  H03  F05  G05  
LA351:  .byte $31, $46, $6D, $31, $22, $64, $04

Row082:      ;F05  G06  H02  F11  M04  F03  G04  F06  G05  W07  M09  D02  M04  D08  M02  D01  
LA358:  .byte $64, $05, $21, $6A, $33, $62, $03, $65, $04, $46, $38, $11, $33, $17, $31, $10
;             M02  D01  M03  W08  F13  M02  H02  F05  G05  
LA368:  .byte $31, $10, $32, $47, $6C, $31, $21, $64, $04

Row083:      ;F04  G06  H04  F09  M08  G05  F04  G06  W08  M08  D01  M09  D03  M03  D02  M01  
LA371:  .byte $63, $05, $23, $68, $37, $04, $63, $05, $47, $37, $10, $38, $12, $32, $11, $30
;             D01  M04  W07  F13  M03  H02  F05  G04  
LA381:  .byte $10, $33, $46, $6C, $32, $21, $64, $03

Row084:      ;F05  G04  H04  F09  M11  G12  W11  H02  D05  M10  D01  M05  D04  M03  W08  F13  
LA389:  .byte $64, $03, $23, $68, $3A, $0B, $4A, $21, $14, $39, $10, $34, $13, $32, $47, $6C
;             M02  H03  F05  G02  W01  
LA399:  .byte $31, $22, $64, $01, $40

Row085:      ;F05  G02  H05  F09  M14  G08  W11  H05  M03  D02  M09  D01  M08  F01  M04  W08  
LA39E:  .byte $64, $01, $24, $68, $3D, $07, $4A, $24, $32, $11, $38, $10, $37, $60, $33, $47
;             F13  M02  F08  
LA3AE:  .byte $6C, $31, $67

Row086:      ;W02  F05  H06  F05  M05  D07  M07  G04  W09  F03  H07  M03  D05  M05  D01  M07  
LA3B1:  .byte $41, $64, $25, $64, $34, $16, $36, $03, $48, $62, $26, $32, $14, $34, $10, $36
;             F03  M03  W11  F08  H04  F08  
LA3C1:  .byte $62, $32, $4A, $67, $23, $67

Row087:      ;W03  F05  H06  F02  M03  D12  M05  W13  F05  H05  M14  D07  F05  M03  W12  F05  
LA3C7:  .byte $42, $64, $25, $61, $32, $1B, $34, $4C, $64, $24, $3D, $16, $64, $32, $4B, $64
;             H05  F08  
LA3D7:  .byte $24, $67

Row088:      ;W02  F06  H09  D15  M03  W12  F06  H06  M07  G03  M10  F07  M02  W13  F06  H04  
LA3D9:  .byte $41, $65, $28, $1E, $32, $4B, $65, $25, $36, $02, $39, $66, $31, $4C, $65, $23
;             F06  W03  
LA3E9:  .byte $65, $42

Row089:      ;F09  H07  D09  T01  D05  M02  W12  F06  H08  M02  F03  G04  W04  M08  F05  M02  
LA3EB:  .byte $68, $26, $18, $80, $14, $31, $4B, $65, $27, $31, $62, $03, $43, $37, $64, $31
;             W15  F06  H04  F03  W05  
LA3FB:  .byte $4E, $65, $23, $62, $44

Row090:      ;F11  H05  D14  W06  F13  H09  M02  F05  G05  W03  P05  M04  F02  M02  W14  F07  
LA400:  .byte $6A, $24, $1D, $45, $6C, $28, $31, $64, $04, $42, $74, $33, $61, $31, $4D, $66
;             H06  F03  W04  
LA410:  .byte $25, $62, $43

Row091:      ;W01  F12  H02  D12  W07  F07  W07  H07  M04  F06  G05  B01  P05  G04  M03  F01  
LA413:  .byte $40, $6B, $21, $1B, $46, $66, $46, $26, $33, $65, $04, $B0, $74, $03, $32, $60
;             W16  W01  F07  H04  F05  
LA423:  .byte $4F, $40, $66, $23, $64

Row092:      ;W05  F09  D11  W07  F04  W04  F06  H07  M03  F10  G03  W02  P04  G06  M02  G02  
LA428:  .byte $44, $68, $1A, $46, $63, $43, $65, $26, $32, $69, $02, $41, $73, $05, $31, $01
;             W16  F07  H03  F05  
LA438:  .byte $4F, $66, $22, $64

Row093:      ;W11  F02  D13  W05  F08  W08  H05  M02  F11  W04  P05  G06  M04  G02  W16  F04  
LA43C:  .byte $4A, $61, $1C, $44, $67, $47, $24, $31, $6A, $43, $74, $05, $33, $01, $4F, $63
;             H04  F05  
LA44C:  .byte $23, $64

Row094:      ;W08  D15  W10  F15  H03  M02  F08  W07  P05  G06  M05  G01  W14  F02  W02  F04  
LA44E:  .byte $47, $1E, $49, $6E, $22, $31, $67, $46, $74, $05, $34, $00, $4D, $61, $41, $63
;             H04  F05  
LA45E:  .byte $23, $64

Row095:      ;W04  D16  D05  W05  F08  W04  F07  M03  F05  W12  P03  G07  F02  M02  G03  W12  
LA460:  .byte $43, $1F, $14, $44, $67, $43, $66, $32, $64, $4B, $72, $06, $61, $31, $02, $4B
;             F04  W01  F05  H02  F05  W05  
LA470:  .byte $63, $40, $64, $21, $64, $44

Row096:      ;W02  D06  H06  D11  F05  W13  F04  M03  F05  W13  G11  F03  M02  G03  W10  F05  
LA476:  .byte $41, $15, $25, $1A, $64, $4C, $63, $32, $64, $4C, $0A, $62, $31, $02, $49, $64
;             W02  F10  W06  
LA486:  .byte $41, $69, $45

Row097:      ;W03  D03  H04  F05  D09  F15  W03  F03  M02  F07  W11  F04  G09  F05  M03  G02  
LA489:  .byte $42, $12, $23, $64, $18, $6E, $42, $62, $31, $66, $4A, $63, $08, $64, $32, $01
;             W11  F04  W02  F09  W06  
LA499:  .byte $4A, $63, $41, $68, $45

Row098:      ;W02  H06  F10  D05  F16  F01  B01  F02  M03  F07  W07  F10  G07  F08  M02  G02  
LA49E:  .byte $41, $25, $69, $14, $6F, $60, $B0, $61, $32, $66, $46, $69, $06, $67, $31, $01
;             W09  F06  W02  F07  W07  
LA4AE:  .byte $48, $65, $41, $66, $46

Row099:      ;W01  H05  F14  D04  F14  W04  M02  F04  G04  W10  F09  G06  F07  M02  G03  W09  
LA4B3:  .byte $40, $24, $6D, $13, $6D, $43, $31, $63, $03, $49, $68, $05, $66, $31, $02, $48
;             F02  P01  F04  B01  F06  W08  
LA4C3:  .byte $61, $70, $63, $B0, $65, $47

Row100:      ;H07  F14  D04  F11  W09  G06  W10  F10  R02  G01  R02  F07  M04  G03  W07  F02  
LA4C9:  .byte $26, $6D, $13, $6A, $48, $05, $49, $69, $51, $00, $51, $66, $33, $02, $46, $61
;             P03  F03  W02  F04  W09  
LA4D9:  .byte $72, $62, $41, $63, $48

Row101:      ;H05  M04  F12  D05  F07  W11  G06  W12  F09  R01  G03  R01  F07  M05  G03  W06  
LA4DE:  .byte $24, $33, $6B, $14, $66, $4A, $05, $4B, $68, $50, $02, $50, $66, $34, $02, $45
;             F03  P03  F02  W02  F03  W10  
LA4EE:  .byte $62, $72, $61, $41, $62, $49

Row102:      ;H06  M05  F09  D07  F06  M02  W04  M05  G06  W14  F07  R01  G01  T01  G01  R01  
LA4F4:  .byte $25, $34, $68, $16, $65, $31, $43, $34, $05, $4D, $66, $50, $00, $80, $00, $50
;             F08  M05  H03  W06  F03  P02  F03  W14  
LA504:  .byte $67, $34, $22, $45, $62, $71, $62, $4D

Row103:      ;H08  M05  F07  D08  F05  M03  W02  M04  F02  G05  W02  G04  W11  F05  R01  G03  
LA50C:  .byte $27, $34, $66, $17, $64, $32, $41, $33, $61, $04, $41, $03, $4A, $64, $50, $02
;             R01  F10  M02  H05  W05  F02  G04  F03  W13  
LA51C:  .byte $50, $69, $31, $24, $44, $61, $03, $62, $4C

Row104:      ;H07  M09  F04  D08  H02  F04  M07  F04  G04  B01  G05  F05  W07  F04  R05  F09  
LA525:  .byte $26, $38, $63, $17, $21, $63, $36, $63, $03, $B0, $04, $64, $46, $63, $54, $68
;             M03  H06  W05  F02  G03  H04  G03  W09  
LA535:  .byte $32, $25, $44, $61, $02, $23, $02, $48

Row105:      ;H07  M02  F05  M07  D05  H06  F03  M05  F05  G03  W02  G04  F10  M04  F16  M03  
LA53D:  .byte $26, $31, $64, $36, $14, $25, $62, $34, $64, $02, $41, $03, $69, $33, $6F, $32
;             H06  W08  G02  H07  G06  W04  
LA54D:  .byte $25, $47, $01, $26, $05, $43

Row106:      ;W01  H05  M02  F08  M07  D02  H08  M06  F07  W03  F03  G05  F08  M06  F10  M06  
LA553:  .byte $40, $24, $31, $67, $36, $11, $27, $35, $66, $42, $62, $04, $67, $35, $69, $35
;             H05  W10  H03  M05  H03  G05  
LA563:  .byte $24, $49, $22, $34, $22, $04

Row107:      ;W03  H03  M02  F05  G05  M04  H12  M06  F05  W03  F05  G06  F08  M08  F04  M07  
LA569:  .byte $42, $22, $31, $64, $04, $33, $2B, $35, $64, $42, $64, $05, $67, $37, $63, $36
;             H07  W08  H03  M03  F02  M03  H02  G04  
LA579:  .byte $26, $47, $22, $32, $61, $32, $21, $03

Row108:      ;W05  H02  M02  F03  G07  H13  M07  F05  W03  F07  G06  F08  M16  M01  H09  W06  
LA581:  .byte $44, $21, $31, $62, $06, $2C, $36, $64, $42, $66, $05, $67, $3F, $30, $28, $45
;             H03  M03  F04  M02  H03  G01  
LA591:  .byte $22, $32, $63, $31, $22, $00

Row109:      ;W04  H04  M03  G07  H13  M07  F05  W04  F06  G09  F05  P03  M11  P05  H06  W07  
LA597:  .byte $43, $23, $32, $06, $2C, $36, $64, $43, $65, $08, $64, $72, $3A, $74, $25, $46
;             H03  M03  F03  S01  F02  M02  G02  W05  
LA5A7:  .byte $22, $32, $62, $C0, $61, $31, $01, $44

Row110:      ;W03  H05  M02  G09  H10  M06  F08  W05  F04  G10  F03  P08  M07  P07  H06  W07  
LA5AF:  .byte $42, $24, $31, $08, $29, $35, $67, $44, $63, $09, $62, $77, $36, $76, $25, $46
;             H03  M02  F05  M04  G04  
LA5BF:  .byte $22, $31, $64, $33, $03

Row111:      ;W04  H04  M02  G10  H08  M06  F09  W04  F05  G10  F03  P09  M05  P09  H04  W09  
LA5C4:  .byte $43, $23, $31, $09, $27, $35, $68, $43, $64, $09, $62, $78, $34, $78, $23, $48
;             H03  M02  F04  M02  H03  G03  
LA5D4:  .byte $22, $31, $63, $31, $22, $02

Row112:      ;W05  H05  G10  H09  M04  F09  W06  F05  G08  F03  P11  M03  P11  H02  W10  H03  
LA5DA:  .byte $44, $24, $09, $28, $33, $68, $45, $64, $07, $62, $7A, $32, $7A, $21, $49, $22
;             M03  F01  M03  H03  G03  
LA5EA:  .byte $32, $60, $32, $22, $02

Row113:      ;W07  H04  G08  H08  M05  F09  W07  F07  G06  F04  P16  P09  W12  H03  M02  F01  
LA5EF:  .byte $46, $23, $07, $27, $34, $68, $46, $66, $05, $63, $7F, $78, $4B, $22, $31, $60
;             M02  H03  G03  
LA5FF:  .byte $31, $22, $02

Row114:      ;W06  H06  G06  H04  W03  M08  F07  W09  F08  G03  F05  P11  W02  P11  W13  H09  
LA602:  .byte $45, $25, $05, $23, $42, $37, $66, $48, $67, $02, $64, $7A, $41, $7A, $4C, $28
;             G04  
LA612:  .byte $03

Row115:      ;W07  H06  G04  H04  W05  F13  W12  F13  P11  W04  P09  W14  H06  P03  W09  
LA613:  .byte $46, $25, $03, $23, $44, $6C, $4B, $6C, $7A, $43, $78, $4D, $25, $72, $48

Row116:      ;W08  H14  W03  F12  W16  F10  P11  W08  P04  W16  W01  H04  P02  W11  
LA622:  .byte $47, $2D, $42, $6B, $4F, $69, $7A, $47, $73, $4F, $40, $23, $71, $4A

Row117:      ;W09  H13  B01  H06  F05  W16  W05  F05  P13  W16  W15  H02  P02  W12  
LA630:  .byte $48, $2C, $B0, $25, $64, $4F, $44, $64, $7C, $4F, $4E, $21, $71, $4B

Row118:      ;W11  H10  W03  H07  W16  W12  P13  W16  W16  P04  
LA63E:  .byte $4A, $29, $42, $26, $4F, $4B, $7C, $4F, $4F, $73

Row119:      ;W12  H07  W16  W16  W09  P10  W16  W16  W02  P03  W13  
LA648:  .byte $4B, $26, $4F, $4F, $48, $79, $4F, $4F, $41, $72, $4C

;Pointers to world map rows.
WrldMapPtrTbl:
LA653:  .word Row000, Row001, Row002, Row003, Row004, Row005, Row006, Row007
LA663:  .word Row008, Row009, Row010, Row011, Row012, Row013, Row014, Row015
LA673:  .word Row016, Row017, Row018, Row019, Row020, Row021, Row022, Row023
LA683:  .word Row024, Row025, Row026, Row027, Row028, Row029, Row030, Row031
LA693:  .word Row032, Row033, Row034, Row035, Row036, Row037, Row038, Row039
LA6A3:  .word Row040, Row041, Row042, Row043, Row044, Row045, Row046, Row047
LA6B3:  .word Row048, Row049, Row050, Row051, Row052, Row053, Row054, Row055
LA6C3:  .word Row056, Row057, Row058, Row059, Row060, Row061, Row062, Row063
LA6D3:  .word Row064, Row065, Row066, Row067, Row068, Row069, Row070, Row071
LA6E3:  .word Row072, Row073, Row074, Row075, Row076, Row077, Row078, Row079
LA6F3:  .word Row080, Row081, Row082, Row083, Row084, Row085, Row086, Row087
LA703:  .word Row088, Row089, Row090, Row091, Row092, Row093, Row094, Row095
LA713:  .word Row096, Row097, Row098, Row099, Row100, Row101, Row102, Row103
LA723:  .word Row104, Row105, Row106, Row107, Row108, Row109, Row110, Row111
LA733:  .word Row112, Row113, Row114, Row115, Row116, Row117, Row118, Row119

;----------------------------------------------------------------------------------------------------

ScreenFadeOut:
LA743:  LDA DrgnLrdPal
LA746:  CMP #EN_DRAGONLORD2
LA748:  BEQ $A76D
LA74A:  LDA #$FF
LA74C:  STA $3D
LA74E:  LDA RegSPPalPtr
LA751:  STA $3E
LA753:  LDA RegSPPalPtr+1
LA756:  STA $3F
LA758:  LDA OverworldPalPtr
LA75B:  CLC
LA75C:  ADC MapType
LA75E:  STA $40
LA760:  LDA OverworldPalPtr+1
LA763:  ADC #$00
LA765:  STA $41
LA767:  JSR PalFadeOut          ;($C212)Fade out both background and sprite palettes.
LA76A:  JMP $A788

LA76D:  LDA #$FF
LA76F:  STA $3D
LA771:  LDA EndBossPal1Ptr
LA774:  STA $40
LA776:  LDA EndBossPal1Ptr+1
LA779:  STA $41
LA77B:  LDA EndBossPal2Ptr
LA77E:  STA $3E
LA780:  LDA EndBossPal2Ptr+1
LA783:  STA $3F
LA785:  JSR PalFadeOut          ;($C212)Fade out both background and sprite palettes.

LA788:  LDA #$00
LA78A:  STA $3C
LA78C:  LDA #$04
LA78E:  STA $3D
LA790:  LDY #$00
LA792:  LDA #$FF
LA794:  STA ($3C),Y
LA796:  INY
LA797:  BNE $A794
LA799:  INC $3D
LA79B:  LDA $3D
LA79D:  CMP #$08
LA79F:  BNE $A790
LA7A1:  RTS

;----------------------------------------------------------------------------------------------------

RemoveWindow:
LA7A2:  STA WndTypeCopy

LA7A4:  BRK                     ;Get parameters for removing windows from the screen.
LA7A5:  .byte $00, $17          ;($AF24)WndEraseParams, bank 1.

LA7A7:  LDA WndEraseWdth
LA7AA:  LSR
LA7AB:  ORA #$10
LA7AD:  STA $64A6
LA7B0:  LDA WndEraseHght
LA7B3:  SEC
LA7B4:  SBC #$01
LA7B6:  ASL
LA7B7:  ASL
LA7B8:  ASL
LA7B9:  ASL
LA7BA:  ADC WndErasePos
LA7BD:  STA $64A7
LA7C0:  LDA WndErasePos
LA7C3:  AND #$0F
LA7C5:  STA $3C
LA7C7:  SEC
LA7C8:  SBC #$08
LA7CA:  ASL
LA7CB:  STA $9D
LA7CD:  LDA WndEraseHght
LA7D0:  STA $98
LA7D2:  SEC
LA7D3:  SBC #$01
LA7D5:  PHA
LA7D6:  LDA WndErasePos
LA7D9:  LSR
LA7DA:  LSR
LA7DB:  LSR
LA7DC:  LSR
LA7DD:  STA $22
LA7DF:  PLA
LA7E0:  CLC
LA7E1:  ADC $22
LA7E3:  STA $22
LA7E5:  SEC
LA7E6:  SBC #$07
LA7E8:  ASL
LA7E9:  STA $10
LA7EB:  LDA WndEraseWdth
LA7EE:  LSR
LA7EF:  STA $9E
LA7F1:  LDA $22
LA7F3:  STA $3E
LA7F5:  JSR CalcPPUBufAddr      ;($C596)Calculate PPU address.
LA7F8:  LDA PPUAddrLB
LA7FA:  STA $99
LA7FC:  LDA PPUAddrUB
LA7FE:  STA $9A

LA800:  LDA WndTypeCopy
LA802:  BEQ $A818

LA804:  CMP #$02
LA806:  BEQ $A818

LA808:  CMP #$03
LA80A:  BEQ $A818

LA80C:  CMP #$04
LA80E:  BEQ $A818

LA810:  CMP #$0B
LA812:  BEQ $A818

LA814:  LDA #$00
LA816:  BEQ $A81A

LA818:  LDA #$FF
LA81A:  STA $4D
LA81C:  LDA #$00
LA81E:  STA $23
LA820:  STA $22
LA822:  LDA $9D
LA824:  STA $0F
LA826:  LDA $9E
LA828:  STA $97
LA82A:  JSR $A880
LA82D:  LDA $99
LA82F:  CLC
LA830:  ADC #$02
LA832:  STA $99
LA834:  BCC $A838
LA836:  INC $9A
LA838:  INC $22
LA83A:  INC $22
LA83C:  INC $23
LA83E:  INC $0F
LA840:  INC $0F
LA842:  DEC $97
LA844:  BNE $A82A

LA846:  BRK                     ;Show/hide window on the screen.
LA847:  .byte $01, $17          ;($ABC4)WndShowHide.

LA849:  LDA $99
LA84B:  CLC
LA84C:  ADC #$C0
LA84E:  STA $99
LA850:  BCS $A854
LA852:  DEC $9A
LA854:  LDA $9E
LA856:  ASL
LA857:  STA $3C
LA859:  LDA $99
LA85B:  SEC
LA85C:  SBC $3C
LA85E:  STA $99
LA860:  BCS $A864
LA862:  DEC $9A
LA864:  LDA $64A7
LA867:  SEC
LA868:  SBC #$10
LA86A:  STA $64A7
LA86D:  DEC $10
LA86F:  DEC $10
LA871:  DEC $98
LA873:  BNE $A81C
LA875:  LDA StopNPCMove
LA877:  BEQ $A87F

LA879:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LA87C:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LA87F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

LA880:  LDA $4D
LA882:  BNE $A893
LA884:  LDY #$00
LA886:  LDA ($99),Y
LA888:  CMP #$FF
LA88A:  BEQ $A893
LA88C:  CMP #$FE
LA88E:  BEQ $A893
LA890:  JMP $A8AD
LA893:  LDA #$00
LA895:  STA BlkRemoveFlgs
LA897:  STA $D1
LA899:  JSR $A921
LA89C:  LDY #$00
LA89E:  LDA #$FF
LA8A0:  STA ($99),Y
LA8A2:  INY
LA8A3:  STA ($99),Y
LA8A5:  LDY #$20
LA8A7:  STA ($99),Y
LA8A9:  INY
LA8AA:  STA ($99),Y
LA8AC:  RTS

LA8AD:  LDA NTBlockY
LA8AF:  ASL
LA8B0:  ADC $10
LA8B2:  CLC
LA8B3:  ADC #$1E
LA8B5:  STA $3C
LA8B7:  LDA #$1E
LA8B9:  STA $3E
LA8BB:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LA8BE:  LDA $40
LA8C0:  STA $3E
LA8C2:  STA $49
LA8C4:  LDA NTBlockX
LA8C6:  ASL
LA8C7:  CLC
LA8C8:  ADC $0F
LA8CA:  AND #$3F
LA8CC:  STA $3C
LA8CE:  STA $48
LA8D0:  JSR $C5AA
LA8D3:  LDX $22
LA8D5:  LDY #$00
LA8D7:  LDA ($99),Y
LA8D9:  STA $6436,X
LA8DC:  INY
LA8DD:  LDA ($99),Y
LA8DF:  STA $6437,X
LA8E2:  TXA
LA8E3:  CLC
LA8E4:  ADC WndEraseWdth
LA8E7:  TAX
LA8E8:  LDY #$20
LA8EA:  LDA ($99),Y
LA8EC:  STA $6436,X
LA8EF:  INY
LA8F0:  LDA ($99),Y
LA8F2:  STA $6437,X
LA8F5:  LDA $48
LA8F7:  STA $3C
LA8F9:  LDA $49
LA8FB:  STA $3E
LA8FD:  LDY #$00
LA8FF:  LDA ($99),Y
LA901:  CMP #$C1
LA903:  BCS $A909
LA905:  LDA #$00
LA907:  BEQ $A91B
LA909:  CMP #$CA
LA90B:  BCS $A911
LA90D:  LDA #$01
LA90F:  BNE $A91B
LA911:  CMP #$DE
LA913:  BCS $A919
LA915:  LDA #$02
LA917:  BNE $A91B
LA919:  LDA #$03
LA91B:  LDX $23
LA91D:  STA AttribTblBuf,X
LA920:  RTS

LA921:  LDA NTBlockY
LA923:  ASL
LA924:  CLC
LA925:  ADC $10
LA927:  CLC
LA928:  ADC #$1E
LA92A:  STA $3C
LA92C:  LDA #$1E
LA92E:  STA $3E
LA930:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LA933:  LDA $40
LA935:  STA $3E
LA937:  STA $49
LA939:  LDA NTBlockX
LA93B:  ASL
LA93C:  CLC
LA93D:  ADC $0F
LA93F:  AND #$3F
LA941:  STA $3C
LA943:  STA $48
LA945:  JSR $C5AA
LA948:  LDA $0F
LA94A:  ASL
LA94B:  LDA $0F
LA94D:  ROR
LA94E:  CLC
LA94F:  ADC CharXPos
LA951:  STA $3C
LA953:  LDA $10
LA955:  ASL
LA956:  LDA $10
LA958:  ROR
LA959:  CLC
LA95A:  ADC CharYPos
LA95C:  STA $3E
LA95E:  JSR GetBlockID          ;($AC17)Get description of block.
LA961:  LDA MapType
LA963:  CMP #MAP_DUNGEON
LA965:  BNE $A9CD
LA967:  LDA $0F
LA969:  BPL $A975
LA96B:  EOR #$FF
LA96D:  CLC
LA96E:  ADC #$01
LA970:  STA $3E
LA972:  JMP $A979
LA975:* LDA $0F
LA977:  STA $3E
LA979:  LDA LightDiameter
LA97B:  CMP $3E
LA97D:  BCS $A989
LA97F:  LDA #$16
LA981:  STA $3C
LA983:  LDA #$00
LA985:  STA BlkRemoveFlgs
LA987:  BEQ $A9E6
LA989:* BNE $A999
LA98B:  LDA $0F
LA98D:  BPL $A995
LA98F:  LDA #$05
LA991:  STA BlkRemoveFlgs
LA993:  BNE $A999
LA995:* LDA #$0A
LA997:  STA BlkRemoveFlgs
LA999:* LDA $10
LA99B:  BPL $A9A7
LA99D:  EOR #$FF
LA99F:  CLC
LA9A0:  ADC #$01
LA9A2:  STA $3E
LA9A4:  JMP $A9AB
LA9A7:* LDA $10
LA9A9:  STA $3E
LA9AB:  LDA LightDiameter
LA9AD:  CMP $3E
LA9AF:  BCS +
LA9B1:  LDA #$16
LA9B3:  STA $3C
LA9B5:  LDA #$00
LA9B7:  STA BlkRemoveFlgs
LA9B9:  BEQ +++++
LA9BB:* BNE ++++
LA9BD:  LDA $10
LA9BF:  BPL +
LA9C1:  LDA #$03
LA9C3:  STA BlkRemoveFlgs
LA9C5:  BNE ++++
LA9C7:* LDA #$0C
LA9C9:  STA BlkRemoveFlgs
LA9CB:  BNE +++
LA9CD:* JSR $AAE1
LA9D0:  LDA $19
LA9D2:  EOR $3D
LA9D4:  AND #$08
LA9D6:  BEQ ++
LA9D8:  LDA $19
LA9DA:  BNE +
LA9DC:  LDA #$15
LA9DE:  STA $3C
LA9E0:  BNE ++                  ;Branch always.
LA9E2:* LDA #$16
LA9E4:  STA $3C
LA9E6:* LDA $3C
LA9E8:  ASL
LA9E9:  ASL
LA9EA:  ADC $3C
LA9EC:  ADC $F5B3
LA9EF:  STA $40
LA9F1:  LDA $F5B4
LA9F4:  ADC #$00
LA9F6:  STA $41
LA9F8:  LDX $22                 ;Load store offset.
LA9FA:  LDY #$00
LA9FC:  LDA ($40),Y             ;Load tile number.
LA9FE:  STA $6436,X             
LAA01:  INY
LAA02:  LDA ($40),Y
LAA04:  STA $6437,X
LAA07:  TXA
LAA08:  CLC
LAA09:  ADC WndEraseWdth
LAA0C:  TAX
LAA0D:  LDA PPUAddrLB
LAA0F:  CLC
LAA10:  ADC #$1E
LAA12:  STA PPUAddrLB
LAA14:  BCC $AA18
LAA16:  INC PPUAddrUB
LAA18:* INY
LAA19:  LDA ($40),Y
LAA1B:  STA $6436,X
LAA1E:  INY
LAA1F:  LDA ($40),Y
LAA21:  STA $6437,X
LAA24:  INY
LAA25:  LDA $48
LAA27:  STA $3C
LAA29:  LDA $49
LAA2B:  STA $3E
LAA2D:  LDA ($40),Y
LAA2F:  STA PPUDataByte
LAA31:  LDA $D1
LAA33:  BNE $AA3C
LAA35:  LDX $23
LAA37:  LDA PPUDataByte
LAA39:  STA AttribTblBuf,X
LAA3C:* RTS

;----------------------------------------------------------------------------------------------------

DoPalFadeIn:
LAA3D:  JSR $AA49
LAA40:  JMP PalFadeIn           ;($C529)Fade in both background and sprite palettes.

DoPalFadeOut:
LAA43:  JSR $AA49
LAA46:  JMP PalFadeOut          ;($C212)Fade out both background and sprite palettes.

LAA49:  LDA BlackPalPtr
LAA4C:  STA $3E
LAA4E:  LDA BlackPalPtr+1
LAA51:  STA $3F
LAA53:  LDA $9A2C
LAA56:  STA $40
LAA58:  LDA $9A2D
LAA5B:  STA $41
LAA5D:  LDA #$FF
LAA5F:  STA $3D
LAA61:  RTS

;----------------------------------------------------------------------------------------------------

LoadCreditsPals:
LAA62:  LDA #$FF
LAA64:  STA $3D
LAA66:  LDA RegSPPalPtr
LAA69:  STA $3E
LAA6B:  LDA RegSPPalPtr+1
LAA6E:  STA $3F
LAA70:  LDA TownPalPtr
LAA73:  STA $40
LAA75:  LDA TownPalPtr+1
LAA78:  STA $41
LAA7A:  JSR PalFadeOut          ;($C212)Fade out both background and sprite palettes.
LAA7D:  RTS

LoadStartPals:
LAA7E:  LDA RegSPPalPtr
LAA81:  STA $3E
LAA83:  LDA RegSPPalPtr+1
LAA86:  STA $3F
LAA88:  LDA PreGamePalPtr
LAA8B:  STA $40
LAA8D:  LDA PreGamePalPtr+1
LAA90:  STA $41
LAA92:  LDA #$FF
LAA94:  STA $3D
LAA96:  JMP PalFadeIn           ;($C529)Fade in both background and sprite palettes.

LoadIntroPals:
LAA99:  LDA BlackPalPtr
LAA9C:  STA PalPtrLB
LAA9E:  LDA BlackPalPtr+1
LAAA1:  STA PalPtrUB
LAAA3:  LDA #$00
LAAA5:  STA $3C
LAAA7:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer
LAAAA:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LAAAD:  LDA BlackPalPtr
LAAB0:  STA PalPtrLB
LAAB2:  LDA BlackPalPtr+1
LAAB5:  STA PalPtrUB

LAAB7:  LDA #$00
LAAB9:  STA PalModByte
LAABB:  JMP PrepSPPalLoad       ;($C632)Wait for PPU buffer to be open.

;----------------------------------------------------------------------------------------------------

LAABE:  LDA MapWidth
LAAC0:  CLC
LAAC1:  ADC #$01
LAAC3:  LSR
LAAC4:  STA $3C
LAAC6:  LDA #$00
LAAC8:  STA $3D
LAACA:  STA $3F
LAACC:  LDA $43
LAACE:  STA $3E
LAAD0:  JSR WordMultiply        ;($C1C9)
LAAD3:  LDA $42
LAAD5:  LSR
LAAD6:  CLC
LAAD7:  ADC $40
LAAD9:  STA $3E
LAADB:  LDA $41
LAADD:  ADC #$00
LAADF:  STA $3F
LAAE1:  LDA $17
LAAE3:  ORA $18
LAAE5:  BNE $AAEC
LAAE7:  LDA #$00
LAAE9:  STA $3D
LAAEB:  RTS

LAAEC:  LDA MapWidth
LAAEE:  CMP $42
LAAF0:  BCC $AAE7
LAAF2:  LDA MapHeight
LAAF4:  CMP $43
LAAF6:  BCC $AAE7

LAAF8:  LDA $3E
LAAFA:  CLC
LAAFB:  ADC $17
LAAFD:  STA $3E

LAAFF:  LDA $3F
LAB01:  ADC $18
LAB03:  STA $3F

LAB05:  TYA
LAB06:  PHA
LAB07:  LDY #$00
LAB09:  LDA ($3E),Y
LAB0B:  STA $3D
LAB0D:  PLA
LAB0E:  TAY
LAB0F:  LDA $42
LAB11:  AND #$01
LAB13:  BNE $AB1D
LAB15:  LSR $3D
LAB17:  LSR $3D
LAB19:  LSR $3D
LAB1B:  LSR $3D

LAB1D:  LDA $3D
LAB1F:  AND #$08
LAB21:  STA $3D
LAB23:  RTS

;----------------------------------------------------------------------------------------------------

DoWtrConv:
LAB24:  TAX                     ;Save A on stack(water block ID, not used).
LAB25:  PHA                     ;

LAB26:  LDX #$00                ;Zero out index into conversion table.

LAB28:  LDY XTarget             ;Make a copy of the X target coord.
LAB2A:  STY GenByte2C           ;

LAB2C:  CPY #$77                ;Is target the last block in the row?
LAB2E:  BEQ ChkWtrBlkRght       ;If so, branch. Block to right is always another water block.

LAB30:  INY                     ;Get block ID of block to the right of target block.
LAB31:  STY XTarget             ;
LAB33:  JSR FindRowBlock        ;($ABF4)Find block ID of target block in world map row.

ChkWtrBlkRght:
LAB36:  BEQ WaterBlockRight     ;Is block to right of target block water? If so, branch.

LAB38:  TXA                     ;Block to right of target is not a water block.
LAB39:  CLC                     ;Set bit 2 in index byte. Shore will be on the right-->
LAB3A:  ADC #$04                ;of the current water block.
LAB3C:  TAX                     ;

WaterBlockRight:
LAB3D:  LDY GenByte2C           ;Restore the original block X coord. Is target first block row? 
LAB3F:  BEQ ChkWtrBlkLft        ;If so, branch. Block to left is always another water block.

LAB41:  DEY                     ;Get block ID of block to the left of target block.
LAB42:  STY XTarget             ;
LAB44:  JSR FindRowBlock        ;($ABF4)Find block ID of target block in world map row.

ChkWtrBlkLft:
LAB47:  BEQ WaterBlockLeft      ;Is block to left of target block water? If so, branch.

LAB49:  INX                     ;Block to left of target is not a water block.
LAB4A:  INX                     ;set bit 1 in index byte. Shore to left.

WaterBlockLeft:
LAB4B:  LDA GenByte2C           ;Restore the original block X coord.
LAB4D:  STA XTarget
LAB4F:  LDY YTarget
LAB51:  BEQ $AB58

LAB53:  DEY
LAB54:  TYA
LAB55:  JSR ChkWtrOrBrdg        ;($ABE8)If target block is water or bridge, set zero flag.

LAB58:  BEQ $AB5B

LAB5A:  INX

LAB5B:  LDY YTarget
LAB5D:  CPY #$77
LAB5F:  BEQ $AB66

LAB61:  INY
LAB62:  TYA
LAB63:  JSR ChkWtrOrBrdg        ;($ABE8)If target block is water or bridge, set zero flag.
LAB66:  BEQ $AB6D

LAB68:  TXA
LAB69:  CLC
LAB6A:  ADC #$08
LAB6C:  TAX

LAB6D:  LDA GenBlkConvTbl,X     ;Get final block ID from conversion table.
LAB70:  STA TargetResults       ;

LAB72:  PLA                     ;
LAB73:  TAX                     ;
LAB74:  PLA                     ;Restore X and Y from stack.
LAB75:  TAY                     ;
LAB76:  RTS                     ;

;----------------------------------------------------------------------------------------------------

TrgtOutOfBounds:
LAB77:  TYA                     ;
LAB78:  PHA                     ;Save Y and X on stack.
LAB79:  TXA                     ;
LAB7A:  PHA                     ;

LAB7B:  LDX #$00
LAB7D:  LDA MapNumber
LAB7F:  CMP #MAP_OVERWORLD
LAB81:  BNE $ABDF

LAB83:  LDA YTarget
LAB85:  BMI $ABB1

LAB87:  CMP #$78
LAB89:  BCS $ABB1

LAB8B:  LDA XTarget
LAB8D:  CMP #$FF
LAB8F:  BEQ $ABA3

LAB91:  CMP #$78
LAB93:  BNE $ABB1

LAB95:  DEC XTarget
LAB97:  LDA YTarget
LAB99:  JSR ChkWtrOrBrdg        ;($ABE8)If target block is water or bridge, set zero flag.
LAB9C:  BEQ $ABA0

LAB9E:  LDX #$02
LABA0:  JMP $AB6D

LABA3:  INC XTarget
LABA5:  LDA YTarget
LABA7:  JSR ChkWtrOrBrdg        ;($ABE8)If target block is water or bridge, set zero flag.
LABAA:  BEQ $ABAE

LABAC:  LDX #$04
LABAE:  JMP $AB6D

LABB1:  LDA XTarget
LABB3:  BMI $ABDF

LABB5:  CMP #$78
LABB7:  BCS $ABDF

LABB9:  LDA YTarget
LABBB:  CMP #$FF
LABBD:  BEQ $ABD1

LABBF:  CMP #$78
LABC1:  BNE $ABDF

LABC3:  DEC YTarget
LABC5:  LDA YTarget
LABC7:  JSR ChkWtrOrBrdg        ;($ABE8)If target block is water or bridge, set zero flag.
LABCA:  BEQ $ABCE

LABCC:  LDX #$01
LABCE:  JMP $AB6D

LABD1:  INC YTarget
LABD3:  LDA YTarget
LABD5:  JSR ChkWtrOrBrdg        ;($ABE8)If target block is water or bridge, set zero flag.
LABD8:  BEQ $ABDC

LABDA:  LDX #$08
LABDC:  JMP $AB6D

LABDF:  LDA BoundryBlock        ;Target is beyond map boundry.
LABE1:  STA TargetResults       ;Load results with boundry block value.

LABE3:  PLA                     ;
LABE4:  TAX                     ;
LABE5:  PLA                     ;Restore X and Y from stack and return.
LABE6:  TAY                     ;
LABE7:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ChkWtrOrBrdg:
LABE8:  ASL                     ;*2. Each row entry in WrldMapPtrTbl is 2 bytes.

LABE9:  TAY                     ;
LABEA:  LDA WrldMapPtrTbl,Y     ;
LABED:  STA WrldMapPtrLB        ;Get a pointer to beginning of desired world map row data.
LABEF:  LDA WrldMapPtrTbl+1,Y   ;
LABF2:  STA WrldMapPtrUB        ;

FindRowBlock:
LABF4:  LDY #$00                ;Start at beginning of row.
LABF6:  STY WrldMapXPos         ;

FindMapBlkLoop2:
LABF8:  LDA (WrldMapPtr),Y      ;Get number of times map block repeats.
LABFA:  AND #$0F                ;

LABFC:  SEC                     ;
LABFD:  ADC WrldMapXPos         ;Add repeat number to world map X position calculation.
LABFF:  STA WrldMapXPos         ;

LAC01:  LDA XTarget             ;Has target block been found?
LAC03:  CMP WrldMapXPos         ;
LAC05:  BCC MapBlkFound2        ;If so, branch.

LAC07:  INY                     ;Increment to next entry in world map row table.
LAC08:  JMP FindMapBlkLoop2     ;($ABF8)Loop until target block is found.

MapBlkFound2:
LAC0B:  LDA (WrldMapPtr),Y      ;Get target block type.
LAC0D:  AND #$F0                ;

LAC0F:  CMP #$40                ;Is target block a water block?
LAC11:  BNE ChkBrdgBlk          ;If not, branch to check for a bridge block.
LAC13:  RTS                     ;Water block. Zero flag set.

ChkBrdgBlk:
LAC14:  CMP #$B0                ;Set zero flag if block is a bridge block.
LAC16:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetBlockID:
LAC17:  LDA XTarget             ;
LAC19:  STA GenByte42           ;Store a copy of the target coordinates.
LAC1B:  LDA YTarget             ;
LAC1D:  STA GenByte43           ;

LAC1F:  LDA MapWidth            ;Is the target X coordinate within the map bounds?
LAC21:  CMP XTarget             ;
LAC23:  BCS BlkIDCheckEn        ;If so, branch to keep processing.

JmpOutOfBounds:
LAC25:  JMP TrgtOutOfBounds     ;($AB77)Target out of bounds. Jump for boundary block.

BlkIDCheckEn:
LAC28:  LDA EnNumber            ;Is player fighting the end boss?
LAC2A:  CMP #EN_DRAGONLORD2     ;
LAC2C:  BNE BlkIDChkYCoord      ;If not, branch to keep processing.

LAC2E:  LDA #BLK_BLANK          ;
LAC30:  STA TargetResults       ;Fighting end boss. Return blank tile.
LAC32:  RTS                     ;

BlkIDChkYCoord:
LAC33:  LDA MapHeight           ;Is the target Y coordinate within the map bounds?
LAC35:  CMP YTarget             ;
LAC37:  BCC JmpOutOfBounds      ;If not, branch to get boundary block.

ChkOvrWrld:
LAC39:  TYA                     ;Save Y on the stack.
LAC3A:  PHA                     ;

LAC3B:  LDA MapNumber           ;Is the player on the overworld map?
LAC3D:  CMP #MAP_OVERWORLD      ;
LAC3F:  BNE ChkOthrMaps         ;If not, branch to check other maps.

ChkRnbwBrdg:
LAC41:  LDA XTarget             ;Is the X position 64?
LAC43:  CMP #$40                ;
LAC45:  BNE GetOvrWldTarget     ;If not, branch.

LAC47:  LDA YTarget             ;Is the Y position 49?
LAC49:  CMP #$31                ;
LAC4B:  BNE GetOvrWldTarget     ;If not, branch.

LAC4D:  LDA ModsnSpells         ;Has the rainbow bridge been created?
LAC4F:  AND #F_RNBW_BRDG        ;
LAC51:  BEQ GetOvrWldTarget     ;If not, branch.

LAC53:  LDA #BLK_BRIDGE         ;The target is the rainbow bridge.
LAC55:  STA TargetResults       ;

LAC57:  PLA                     ;
LAC58:  TAY                     ;Restore Y from stack.
LAC59:  RTS                     ;

GetOvrWldTarget:
LAC5A:  LDA YTarget             ;*2. Each row entry in WrldMapPtrTbl is 2 bytes.
LAC5C:  ASL                     ;

LAC5D:  TAY                     ;
LAC5E:  LDA WrldMapPtrTbl,Y     ;
LAC61:  STA WrldMapPtrLB        ;Get a pointer to beginning of desired world map row data.
LAC63:  LDA WrldMapPtrTbl+1,Y   ;
LAC66:  STA WrldMapPtrUB        ;

LAC68:  LDY #$00                ;Start at beginning of row.
LAC6A:  STY WrldMapXPos         ;

FindMapBlkLoop:
LAC6C:  LDA (WrldMapPtr),Y      ;Get number of times map block repeats.
LAC6E:  AND #$0F                ;

LAC70:  SEC                     ;
LAC71:  ADC WrldMapXPos         ;Add repeat number to world map X position calculation.
LAC73:  STA WrldMapXPos         ;

LAC75:  LDA XTarget             ;Has target block been found?
LAC77:  CMP WrldMapXPos         ;
LAC79:  BCC MapBlkFound         ;If so, branch.

LAC7B:  INY                     ;Increment to next entry in world map row table.
LAC7C:  JMP FindMapBlkLoop      ;($AC6C)Loop until target block is found.

MapBlkFound:
LAC7F:  LDA (WrldMapPtr),Y      ;
LAC81:  LSR                     ;
LAC82:  LSR                     ;Get map block type and move to lower nibble.
LAC83:  LSR                     ;
LAC84:  LSR                     ;

LAC85:  CLC                     ;Is target an overworld water block?
LAC86:  ADC MapType             ;
LAC88:  CMP #$04                ;
LAC8A:  BNE ConvBlkID           ;If not, branch to get other block ID types.

LAC8C:  JMP DoWtrConv           ;($AB24)Get specific outdoor water block ID.

ConvBlkID:
LAC8F:  TAY                     ;Use block type as index into table.
LAC90:  LDA WrldBlkConvTbl,Y    ;Convert world map block to standard block ID.
LAC93:  STA TargetResults       ;Store table value in results register.

LAC95:  PLA                     ;
LAC96:  TAY                     ;Restore Y from stack. Done.
LAC97:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ChkOthrMaps:
LAC98:  LDA #$00                ;Set upper bytes to 0 for multiplication prep.
LAC9A:  STA MultNum1UB          ;
LAC9C:  STA MultNum2UB          ;The lower byte of MultNum2 is TargetY.

LAC9E:  LDA MapWidth            ;Divide by 2 as 1 byte represents 2 blocks.
LACA0:  LSR                     ;

LACA1:  ADC #$00                ;Prep multiplication.  The result is the start of the-->
LACA3:  STA MultNum1LB          ;row that the target block is on.
LACA5:  JSR WordMultiply        ;($C1C9)Multiply 2 words.

LACA8:  LDA _TargetX            ;Divide by 2 as 1 byte represents 2 blocks.
LACAA:  LSR                     ;

LACAB:  CLC                     ;Add X offset for final address value.
LACAC:  ADC MultRsltLB          ;

LACAE:  STA MapBytePtrLB        ;
LACB0:  STA GenPtr3ELB          ;
LACB2:  LDA MultRsltUB          ;Store address value results in map byte pointer-->
LACB4:  ADC #$00                ;and save a copy in a general use pointer.
LACB6:  STA MapBytePtrUB        ;
LACB8:  STA GenPtr3EUB          ;

LACBA:  LDA MapBytePtrLB        ;
LACBC:  CLC                     ;
LACBD:  ADC MapDatPtrLB         ;Add value just calculated to the-->
LACBF:  STA MapBytePtrLB        ;current map data base address.
LACC1:  LDA MapBytePtrUB        ;
LACC3:  ADC MapDatPtrUB         ;
LACC5:  STA MapBytePtrUB        ;

LACC7:  LDY #$00                ;
LACC9:  LDA (MapBytePtr),Y      ;Use new index to retreive desired data byte from memory.
LACCB:  STA TargetResults       ;

LACCD:  LDA _TargetX            ;Is target block have an oeven numbered X position?
LACCF:  LSR                     ;If so, the upper nibble needs to-->
LACD0:  BCS ChkRemovedBlks      ; be shifted the the lower nibble.

LACD2:  LSR TargetResults       ;
LACD4:  LSR TargetResults       ;Shift upper nibble to the lower nibble.
LACD6:  LSR TargetResults       ;
LACD8:  LSR TargetResults       ;

ChkRemovedBlks:
LACDA:  LDA MapNumber
LACDC:  CMP #MAP_TANTCSTL_SL
LACDE:  BCC $ACE4

LACE0:  LDA #$07
LACE2:  BNE $ACE6

LACE4:  LDA #$0F

LACE6:  AND XTarget
LACE8:  CLC
LACE9:  ADC MapType
LACEB:  TAY
LACEC:  LDA GenBlkConvTbl,Y
LACEF:  STA TargetResults

LACF1:  CMP #BLK_PRINCESS
LACF3:  BNE $AD01

LACF5:  LDA PlayerFlags
LACF7:  AND #F_DONE_GWAELIN
LACF9:  BEQ $AD3C

LACFB:  LDA #BLK_BRICK
LACFD:  STA TargetResults
LACFF:  BNE $AD3C

LAD01:  CMP #BLK_STAIR_DN
LAD03:  BNE $AD23

LAD05:  LDA MapNumber
LAD07:  CMP #MAP_DLCSTL_GF
LAD09:  BNE $AD3C
LAD0B:  LDA $42
LAD0D:  CMP #$0A
LAD0F:  BNE $AD3C
LAD11:  LDA $43
LAD13:  CMP #$01
LAD15:  BNE $AD3C
LAD17:  LDA ModsnSpells
LAD19:  AND #F_PSG_FOUND
LAD1B:  BNE $AD3C

LAD1D:  LDA #BLK_FFIELD
LAD1F:  STA TargetResults
LAD21:  BNE $AD3C

LAD23:  CMP #BLK_CHEST
LAD25:  BNE $AD45

LAD27:  LDY #$00
LAD29:  LDA $42
LAD2B:  CMP TrsrXPos,Y
LAD2E:  BNE $AD3F

LAD30:  INY
LAD31:  LDA $43
LAD33:  CMP TrsrXPos,Y
LAD36:  BNE $AD40

LAD38:  LDA #BLK_BRICK
LAD3A:  STA TargetResults

LAD3C:  PLA
LAD3D:  TAY
LAD3E:  RTS

LAD3F:  INY

LAD40:  INY
LAD41:  CPY #BLK_STONE
LAD43:  BNE $AD29

LAD45:  LDA $3C
LAD47:  CMP #BLK_DOOR
LAD49:  BNE $AD3C

LAD4B:  LDY #$00
LAD4D:  LDA $42
LAD4F:  CMP DoorXPos,Y
LAD52:  BNE $AD5E
LAD54:  INY
LAD55:  LDA $43
LAD57:  CMP DoorXPos,Y
LAD5A:  BNE $AD5F
LAD5C:  BEQ $AD38
LAD5E:  INY
LAD5F:  INY
LAD60:  CPY #$10
LAD62:  BNE $AD4D
LAD64:  BEQ $AD3C

;----------------------------------------------------------------------------------------------------

ModMapBlock:
LAD66:  LDA NTBlockY
LAD68:  ASL

LAD69:  CLC

LAD6A:  ADC YPosFromCenter
LAD6C:  CLC
LAD6D:  ADC #$1E
LAD6F:  STA DivNum1LB

LAD71:  LDA #$1E
LAD73:  STA DivNum2
LAD75:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LAD78:  LDA $40
LAD7A:  STA $3E
LAD7C:  STA $49
LAD7E:  LDA NTBlockX
LAD80:  ASL
LAD81:  CLC
LAD82:  ADC XPosFromCenter
LAD84:  AND #$3F
LAD86:  STA $3C
LAD88:  STA $48
LAD8A:  JSR $C5AA
LAD8D:  LDA $0F
LAD8F:  ASL
LAD90:  LDA $0F
LAD92:  ROR
LAD93:  CLC
LAD94:  ADC CharXPos
LAD96:  STA $3C
LAD98:  LDA $10
LAD9A:  ASL
LAD9B:  LDA $10
LAD9D:  ROR
LAD9E:  CLC
LAD9F:  ADC CharYPos
LADA1:  STA $3E
LADA3:  JSR GetBlockID          ;($AC17)Get description of block.
LADA6:  LDA MapType
LADA8:  CMP #MAP_DUNGEON
LADAA:  BNE $AE12
LADAC:  LDA $0F
LADAE:  BPL $ADBA
LADB0:  EOR #$FF
LADB2:  CLC
LADB3:  ADC #$01
LADB5:  STA $3E
LADB7:  JMP $ADBE
LADBA:  LDA $0F
LADBC:  STA $3E
LADBE:  LDA LightDiameter
LADC0:  CMP $3E
LADC2:  BCS $ADCE
LADC4:  LDA #$16
LADC6:  STA $3C
LADC8:  LDA #$00
LADCA:  STA BlkRemoveFlgs
LADCC:  BEQ $AE2B
LADCE:  BNE $ADDE
LADD0:  LDA $0F
LADD2:  BPL $ADDA
LADD4:  LDA #$05
LADD6:  STA BlkRemoveFlgs
LADD8:  BNE $ADDE
LADDA:  LDA #$0A
LADDC:  STA BlkRemoveFlgs
LADDE:  LDA $10
LADE0:  BPL $ADEC
LADE2:  EOR #$FF
LADE4:  CLC
LADE5:  ADC #$01
LADE7:  STA $3E
LADE9:  JMP $ADF0
LADEC:  LDA $10
LADEE:  STA $3E
LADF0:  LDA LightDiameter
LADF2:  CMP $3E
LADF4:  BCS $AE00
LADF6:  LDA #$16
LADF8:  STA $3C
LADFA:  LDA #$00
LADFC:  STA BlkRemoveFlgs
LADFE:  BEQ $AE2B
LAE00:  BNE $AE2B
LAE02:  LDA $10
LAE04:  BPL $AE0C
LAE06:  LDA #$03
LAE08:  STA BlkRemoveFlgs
LAE0A:  BNE $AE2B
LAE0C:  LDA #$0C
LAE0E:  STA BlkRemoveFlgs
LAE10:  BNE $AE2B
LAE12:  JSR $AAE1
LAE15:  LDA $19
LAE17:  EOR $3D
LAE19:  AND #$08
LAE1B:  BEQ $AE2B
LAE1D:  LDA $19
LAE1F:  BNE $AE27
LAE21:  LDA #$15
LAE23:  STA $3C
LAE25:  BNE $AE2B
LAE27:  LDA #$16
LAE29:  STA $3C
LAE2B:  LDA $3C
LAE2D:  ASL
LAE2E:  ASL
LAE2F:  ADC $3C
LAE31:  ADC $F5B3
LAE34:  STA $40
LAE36:  LDA $F5B4
LAE39:  ADC #$00
LAE3B:  STA $41
LAE3D:  LDY #$00
LAE3F:  LDA ($40),Y
LAE41:  STA PPUDataByte
LAE43:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LAE46:  LDA BlkRemoveFlgs
LAE48:  LSR
LAE49:  BCC $AE63
LAE4B:  LDA MapType
LAE4D:  CMP #$20
LAE4F:  BNE $AE5B
LAE51:  LDX PPUBufCount
LAE53:  DEX
LAE54:  LDA #TL_BLANK_TILE1
LAE56:  STA BlockRAM,X
LAE59:  BNE $AE63
LAE5B:  DEC PPUBufCount
LAE5D:  DEC PPUBufCount
LAE5F:  DEC PPUBufCount
LAE61:  DEC PPUEntCount
LAE63:  INY
LAE64:  LDA ($40),Y
LAE66:  STA PPUDataByte
LAE68:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LAE6B:  LDA BlkRemoveFlgs
LAE6D:  AND #$02
LAE6F:  BEQ $AE89
LAE71:  LDA MapType
LAE73:  CMP #$20
LAE75:  BNE $AE81
LAE77:  LDX PPUBufCount
LAE79:  DEX
LAE7A:  LDA #TL_BLANK_TILE1
LAE7C:  STA BlockRAM,X
LAE7F:  BNE $AE89
LAE81:  DEC PPUBufCount
LAE83:  DEC PPUBufCount
LAE85:  DEC PPUBufCount
LAE87:  DEC PPUEntCount
LAE89:  INY
LAE8A:  LDA PPUAddrLB
LAE8C:  CLC
LAE8D:  ADC #$1E
LAE8F:  STA PPUAddrLB
LAE91:  BCC $AE95
LAE93:  INC PPUAddrUB
LAE95:  LDA ($40),Y
LAE97:  STA PPUDataByte
LAE99:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LAE9C:  LDA BlkRemoveFlgs
LAE9E:  AND #$04
LAEA0:  BEQ $AEBA
LAEA2:  LDA MapType
LAEA4:  CMP #$20
LAEA6:  BNE $AEB2
LAEA8:  LDX PPUBufCount
LAEAA:  DEX
LAEAB:  LDA #TL_BLANK_TILE1
LAEAD:  STA BlockRAM,X
LAEB0:  BNE $AEBA
LAEB2:  DEC PPUBufCount
LAEB4:  DEC PPUBufCount
LAEB6:  DEC PPUBufCount
LAEB8:  DEC PPUEntCount
LAEBA:  INY
LAEBB:  LDA ($40),Y
LAEBD:  STA PPUDataByte
LAEBF:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LAEC2:  LDA BlkRemoveFlgs
LAEC4:  AND #$08
LAEC6:  BEQ $AEE0
LAEC8:  LDA MapType
LAECA:  CMP #MAP_DUNGEON
LAECC:  BNE $AED8
LAECE:  LDX PPUBufCount
LAED0:  DEX
LAED1:  LDA #TL_BLANK_TILE1
LAED3:  STA BlockRAM,X
LAED6:  BNE $AEE0
LAED8:  DEC PPUBufCount
LAEDA:  DEC PPUBufCount
LAEDC:  DEC PPUBufCount
LAEDE:  DEC PPUEntCount
LAEE0:  INY
LAEE1:  LDA $48
LAEE3:  STA $3C
LAEE5:  LDA $49
LAEE7:  STA $3E
LAEE9:  LDA ($40),Y
LAEEB:  STA PPUDataByte
LAEED:  JSR $C006
LAEF0:  LDA $D1
LAEF2:  BNE $AEFE
LAEF4:  LDA PPUAddrUB
LAEF6:  CLC
LAEF7:  ADC #$20
LAEF9:  STA PPUAddrUB
LAEFB:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LAEFE:  RTS

LAEFF:  LDA CharXPos
LAF01:  STA $3C
LAF03:  LDA CharYPos
LAF05:  STA $3E
LAF07:  JSR GetBlockID          ;($AC17)Get description of block.
LAF0A:  JSR $AAE1
LAF0D:  LDA $3D
LAF0F:  STA $19
LAF11:  RTS

LAF12:  LDA MapNumber
LAF14:  CMP #MAP_DLCSTL_SL1
LAF16:  BCS $AF1F
LAF18:  LDA #$01
LAF1A:  STA LightDiameter
LAF1C:  LSR
LAF1D:  STA RadiantTimer

LAF1F:  LDA MapNumber
LAF21:  CMP #MAP_THRONEROOM
LAF23:  BEQ $AF2B

LAF25:  LDA PlayerFlags
LAF27:  ORA #F_LEFT_THROOM
LAF29:  STA PlayerFlags

LAF2B:  LDA MapNumber
LAF2D:  CMP #MAP_OVERWORLD
LAF2F:  BNE $AF3C

LAF31:  LDX #$00
LAF33:  TXA
LAF34:  STA DoorXPos,X
LAF37:  INX
LAF38:  CPX #$20
LAF3A:  BNE $AF34
LAF3C:  LDA PlayerFlags
LAF3E:  AND #$08
LAF40:  BEQ $AF6A

LAF42:  LDA MapNumber
LAF44:  CMP #MAP_THRONEROOM
LAF46:  BNE $AF6A

LAF48:  LDA #$04
LAF4A:  STA $602A
LAF4D:  STA $602B
LAF50:  STA $6029
LAF53:  STA $601A

LAF56:  LDA #$05
LAF58:  STA $6028

LAF5B:  LDA #$06
LAF5D:  STA $6026

LAF60:  LDA #$01
LAF62:  STA $6027

LAF65:  LDA #$07
LAF67:  STA $601B

LAF6A:  LDA #$08
LAF6C:  STA NTBlockX
LAF6E:  LDA #$07
LAF70:  STA NTBlockY
LAF72:  LDA #$00
LAF74:  STA ScrollX
LAF76:  STA ScrollY
LAF78:  STA ActiveNmTbl

LAF7A:  LDA MapNumber
LAF7C:  ASL
LAF7D:  ASL
LAF7E:  ADC MapNumber
LAF80:  TAY
LAF81:  LDA MapDatTbl,Y
LAF84:  STA $11
LAF86:  INY
LAF87:  LDA MapDatTbl,Y
LAF8A:  STA $12
LAF8C:  INY
LAF8D:  LDA MapDatTbl,Y
LAF90:  STA MapWidth
LAF92:  INY
LAF93:  LDA MapDatTbl,Y
LAF96:  STA MapHeight
LAF98:  INY
LAF99:  LDA MapDatTbl,Y
LAF9C:  STA $15
LAF9E:  LDA #$FF
LAFA0:  STA NPCUpdateCntr
LAFA2:  LDA StoryFlags
LAFA4:  AND #F_DGNLRD_DEAD
LAFA6:  BEQ $AFB2

LAFA8:  LDA MapNumber
LAFAA:  CMP #MAP_TANTCSTL_GF
LAFAC:  BNE $AFB2
LAFAE:  LDA #$0B
LAFB0:  BNE $AFBB

LAFB2:  LDA MapNumber
LAFB4:  SEC
LAFB5:  SBC #$04
LAFB7:  CMP #$0B
LAFB9:  BCS $B01A
LAFBB:  ASL
LAFBC:  TAY
LAFBD:  LDA #$00
LAFBF:  STA NPCUpdateCntr
LAFC1:  LDA NPCMobPtrTbl,Y
LAFC4:  STA $3C
LAFC6:  LDA NPCMobPtrTbl+1,Y
LAFC9:  STA $3D
LAFCB:  LDA #$00
LAFCD:  TAX
LAFCE:  STA NPCXPos,X
LAFD0:  INX
LAFD1:  CPX #$3C
LAFD3:  BNE $AFCE

LAFD5:  LDA MapNumber
LAFD7:  CMP #MAP_DLCSTL_BF
LAFD9:  BNE $AFE1
LAFDB:  LDA StoryFlags
LAFDD:  AND #F_DGNLRD_DEAD
LAFDF:  BNE $B01A
LAFE1:  LDY #$00
LAFE3:  LDX #$00
LAFE5:  LDA ($3C),Y
LAFE7:  CMP #$FF
LAFE9:  BEQ $AFFE
LAFEB:  STA NPCXPos,X
LAFED:  INX
LAFEE:  INY
LAFEF:  LDA ($3C),Y
LAFF1:  STA NPCXPos,X
LAFF3:  INX
LAFF4:  INY
LAFF5:  LDA #$00
LAFF7:  STA NPCXPos,X
LAFF9:  INX
LAFFA:  INY
LAFFB:  JMP $AFE5
LAFFE:  INY
LAFFF:  LDX #$1E
LB001:  LDA ($3C),Y
LB003:  CMP #$FF
LB005:  BEQ $B01A
LB007:  STA NPCXPos,X
LB009:  INX
LB00A:  INY
LB00B:  LDA ($3C),Y
LB00D:  STA NPCXPos,X
LB00F:  INX
LB010:  INY
LB011:  LDA #$00
LB013:  STA NPCXPos,X
LB015:  INX
LB016:  INY
LB017:  JMP $B001

LB01A:  LDA MapNumber
LB01C:  CMP #MAP_THRONEROOM
LB01E:  BNE $B02E
LB020:  LDA PlayerFlags
LB022:  AND #F_RTN_GWAELIN
LB024:  BNE $B02E
LB026:  LDA #$00
LB028:  STA $78
LB02A:  STA $79
LB02C:  STA $7A

LB02E:  LDA MapNumber
LB030:  CMP #MAP_DLCSTL_SL1
LB032:  BCC $B03F
LB034:  LDA #MAP_DUNGEON
LB036:  STA MapType

LB038:  LDA #$00
LB03A:  STA $17
LB03C:  STA $18
LB03E:  RTS

LB03F:  LDA MapNumber
LB041:  CMP #MAP_OVERWORLD
LB043:  BNE $B04B

LB045:  LDA #MAP_OVRWLD
LB047:  STA MapType
LB049:  BEQ $B038

LB04B:  LDA #MAP_TOWN
LB04D:  STA MapType

LB04F:  LDA MapNumber
LB051:  CMP #MAP_BRECCONARY
LB053:  BNE $B060

LB055:  LDA BrecCvrdDatPtr
LB058:  STA $17
LB05A:  LDA BrecCvrdDatPtr+1
LB05D:  STA $18
LB05F:  RTS

LB060:  CMP #MAP_GARINHAM
LB062:  BNE $B06F

LB064:  LDA GarinCvrdDatPtr
LB067:  STA $17
LB069:  LDA GarinCvrdDatPtr+1
LB06C:  STA $18
LB06E:  RTS

LB06F:  CMP #MAP_CANTLIN
LB071:  BNE $B07E

LB073:  LDA CantCvrdDatPtr
LB076:  STA $17
LB078:  LDA CantCvrdDatPtr+1
LB07B:  STA $18
LB07D:  RTS

LB07E:  CMP #MAP_RIMULDAR
LB080:  BNE $B038

LB082:  LDA RimCvrdDatPtr
LB085:  STA $17
LB087:  LDA RimCvrdDatPtr+1
LB08A:  STA $18
LB08C:  RTS

;----------------------------------------------------------------------------------------------------

MapChngNoFadeOut:
LB08D:  LDA #$00
LB08F:  BEQ $B099

MapChngNoSound:
LB091:  LDA #$00
LB093:  STA $25
LB095:  BEQ $B09E

MapChngWithSound:
LB097:  LDA #$01
LB099:  STA $25
LB09B:  JSR ScreenFadeOut       ;($A743)Fade out screen.
LB09E:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.

LB0A1:  LDA #$00
LB0A3:  STA PPUControl1
LB0A6:  STA DrgnLrdPal          ;Clear dragonlord palette register.
LB0A9:  JSR Bank1ToCHR0         ;($FC98)Load CHR bank 1 into CHR0 memory.
LB0AC:  JSR Bank2ToCHR1         ;($FCAD)Load CHR bank 2 into CHR1 memory.
LB0AF:  LDA $25
LB0B1:  BEQ $B0B8

LB0B3:  LDA #SFX_STAIRS         ;Stairs SFX.
LB0B5:  BRK                     ;
LB0B6:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LB0B8:  LDA #$18
LB0BA:  STA PPUControl1
LB0BD:  JSR $AF12
LB0C0:  JSR $AEFF
LB0C3:  LDA #$F2
LB0C5:  STA $10
LB0C7:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB0CA:  LDA #$EE
LB0CC:  STA $0F

LB0CE:  LDA #$00
LB0D0:  STA BlkRemoveFlgs
LB0D2:  STA $D1
LB0D4:  JSR ModMapBlock         ;($AD66)Change block on map.
LB0D7:  INC $0F
LB0D9:  INC $0F
LB0DB:  BNE $B0CE
LB0DD:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LB0E0:  LDA #$00
LB0E2:  STA BlkRemoveFlgs
LB0E4:  STA $D1
LB0E6:  JSR ModMapBlock         ;($AD66)Change block on map.
LB0E9:  INC $0F
LB0EB:  INC $0F
LB0ED:  LDA $0F
LB0EF:  CMP #$12
LB0F1:  BNE $B0E0
LB0F3:  INC $10
LB0F5:  INC $10
LB0F7:  LDA $10
LB0F9:  CMP #$10
LB0FB:  BNE $B0C7
LB0FD:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB100:  LDA #NPC_STOP
LB102:  STA StopNPCMove
LB104:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB107:  LDA #NPC_MOVE
LB109:  STA StopNPCMove
LB10B:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LB10E:  LDX MapNumber           ;Get current map number.
LB110:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.

LB113:  BRK                     ;
LB114:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LB116:  LDA RegSPPalPtr
LB119:  STA $3E
LB11B:  LDA RegSPPalPtr+1
LB11E:  STA $3F
LB120:  LDA #$FF
LB122:  STA $3D
LB124:  LDA OverworldPalPtr
LB127:  CLC
LB128:  ADC MapType
LB12A:  STA $40
LB12C:  LDA OverworldPalPtr+1
LB12F:  ADC #$00
LB131:  STA $41
LB133:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.
LB136:  LDA #$02
LB138:  STA PPUAddrLB
LB13A:  LDA #$24
LB13C:  STA PPUAddrUB
LB13E:  LDA #TL_BLANK_TILE1
LB140:  STA PPUDataByte
LB142:  LDA #$0F
LB144:  STA $4D

LB146:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB149:  LDY PPUBufCount
LB14B:  LDA #$80
LB14D:  STA UpdateBGTiles
LB150:  LDA PPUAddrUB
LB152:  ORA #$80
LB154:  STA BlockRAM,Y
LB157:  LDA #$1C
LB159:  TAX
LB15A:  STA BlockRAM+1,Y
LB15D:  LDA PPUAddrLB
LB15F:  STA BlockRAM+2,Y
LB162:  LDA PPUDataByte
LB164:  STA BlockRAM+3,Y
LB167:  INY
LB168:  DEX
LB169:  BNE $B164
LB16B:  INC PPUEntCount
LB16D:  LDA PPUAddrLB
LB16F:  CLC
LB170:  ADC #$20
LB172:  STA PPUAddrLB
LB174:  BCC $B178
LB176:  INC PPUAddrUB
LB178:  LDA PPUAddrUB
LB17A:  ORA #$80
LB17C:  STA BlockRAM+3,Y
LB17F:  LDA #$1C
LB181:  TAX
LB182:  STA BlockRAM+4,Y
LB185:  LDA PPUAddrLB
LB187:  STA BlockRAM+5,Y
LB18A:  LDA PPUDataByte
LB18C:  STA BlockRAM+6,Y
LB18F:  INY
LB190:  DEX
LB191:  BNE $B18C
LB193:  INC PPUEntCount
LB195:  TYA
LB196:  CLC
LB197:  ADC #$06
LB199:  STA PPUBufCount
LB19B:  LDA PPUAddrLB
LB19D:  CLC
LB19E:  ADC #$20
LB1A0:  STA PPUAddrLB
LB1A2:  BCC $B1A6
LB1A4:  INC PPUAddrUB
LB1A6:  DEC $4D
LB1A8:  BNE $B146
LB1AA:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB1AD:  RTS

;----------------------------------------------------------------------------------------------------

;The following table is used to pick what music to resume after an event occurs.  The index in
;the table represents the map number and the value in the table is the music number to resume.

ResumeMusicTbl:
LB1AE:  .byte MSC_NOSOUND       ;Unused.                              Silence music.
LB1AF:  .byte MSC_OUTDOOR       ;overworld.                           Resume overworld music.
LB1B0:  .byte MSC_DUNGEON1      ;dragonlord castle, ground floor map. Resume dungeon 1 music.
LB1B1:  .byte MSC_DUNGEON4      ;Hauksness.                           Resume dungeon 4 music.
LB1B2:  .byte MSC_TANTAGEL2     ;Tantagel castle, ground floor.       Resume tantagel 2 music.
LB1B3:  .byte MSC_THRN_ROOM     ;Tantagel castle, throne room.        Resume tantagel 1 music.
LB1B4:  .byte MSC_DUNGEON8      ;Dragonlord castle, bottom floor.     Resume dungeon 8 music.
LB1B5:  .byte MSC_VILLAGE       ;Kol.                                 Resume village music.
LB1B6:  .byte MSC_VILLAGE       ;Brecconary.                          Resume village music.
LB1B7:  .byte MSC_VILLAGE       ;Garinham.                            Resume village music.
LB1B8:  .byte MSC_VILLAGE       ;Cantlin.                             Resume village music.
LB1B9:  .byte MSC_VILLAGE       ;Rimuldar.                            Resume village music.
LB1BA:  .byte MSC_TANTAGEL2     ;Tantagel castle, sublevel.           Resume tantagel 2 music.
LB1BB:  .byte MSC_TANTAGEL2     ;Staff of rain cave.                  Resume tantagel 2 music.
LB1BC:  .byte MSC_TANTAGEL2     ;Rainbow drop cave.                   Resume tantagel 2 music.
LB1BD:  .byte MSC_DUNGEON2      ;Dragonlord castle, sublevel 1.       Resume dungeon 2 music.
LB1BE:  .byte MSC_DUNGEON3      ;Dragonlord castle, sublevel 2.       Resume dungeon 3 music.
LB1BF:  .byte MSC_DUNGEON4      ;Dragonlord castle, sublevel 3.       Resume dungeon 4 music.
LB1C0:  .byte MSC_DUNGEON5      ;Dragonlord castle, sublevel 4.       Resume dungeon 5 music.
LB1C1:  .byte MSC_DUNGEON6      ;Dragonlord castle, sublevel 5.       Resume dungeon 6 music.
LB1C2:  .byte MSC_DUNGEON7      ;Dragonlord castle, sublevel 6.       Resume dungeon 7 music.
LB1C3:  .byte MSC_DUNGEON1      ;Swamp cave.                          Resume dungeon 1 music.
LB1C4:  .byte MSC_DUNGEON1      ;Rock mountain cave, B1.              Resume dungeon 1 music.
LB1C5:  .byte MSC_DUNGEON2      ;Rock mountain cave, B2.              Resume dungeon 2 music.
LB1C6:  .byte MSC_DUNGEON1      ;Cave of Garinham, B1.                Resume dungeon 1 music.
LB1C7:  .byte MSC_DUNGEON2      ;Cave of Garinham, B2.                Resume dungeon 2 music.
LB1C8:  .byte MSC_DUNGEON3      ;Cave of Garinham, B3.                Resume dungeon 3 music.
LB1C9:  .byte MSC_DUNGEON4      ;Cave of Garinham, B4.                Resume dungeon 4 music.
LB1CA:  .byte MSC_DUNGEON1      ;Erdrick's cave B1.                   Resume dungeon 1 music.
LB1CB:  .byte MSC_DUNGEON2      ;Erdrick's cave B2.                   Resume dungeon 2 music.

;----------------------------------------------------------------------------------------------------

LB1CC:  LDA _CharXPos
LB1CE:  STA XTarget
LB1D0:  LDA _CharYPos
LB1D2:  STA YTarget
LB1D4:  JSR GetBlockID          ;($AC17)Get description of block.
LB1D7:  LDA TargetResults
LB1D9:  CMP #BLK_LRG_TILE
LB1DB:  BCC $B1F5
LB1DD:  LDA CharXPos
LB1DF:  STA _CharXPos
LB1E1:  LDA CharYPos
LB1E3:  STA _CharYPos

LB1E5:  PLA
LB1E6:  PLA
LB1E7:  PLA
LB1E8:  PLA

LB1E9:  LDA #SFX_WALL_BUMP      ;Wall bump SFX
LB1EB:  BRK                     ;
LB1EC:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LB1EE:  LDA #$00                ;Reset frame counter.
LB1F0:  STA FrameCounter        ;
LB1F2:  JMP IdleUpdate          ;($CB30)Update NPC movement and pop-up window.

LB1F5:  LDA NPCUpdateCntr
LB1F7:  CMP #$FF
LB1F9:  BNE $B1FC
LB1FB:  RTS

LB1FC:  LDX #$00
LB1FE:  LDA NPCXPos,X
LB200:  AND #$1F
LB202:  CMP _CharXPos
LB204:  BNE $B211
LB206:  LDA NPCYPos,X
LB208:  AND #$1F
LB20A:  CMP _CharYPos
LB20C:  BNE $B211
LB20E:  JMP $B1DD
LB211:  INX
LB212:  INX
LB213:  INX
LB214:  CPX #$3C
LB216:  BNE $B1FE
LB218:  RTS

;----------------------------------------------------------------------------------------------------

LB219:  LDA MapWidth
LB21B:  CMP CharXPos
LB21D:  BCC $B228
LB21F:  LDA MapHeight
LB221:  CMP CharYPos
LB223:  BCC $B228
LB225:  JMP CheckForEnding      ;($CBF7)Check movement updates.

CheckMapExit:
LB228:  LDX #$00
LB22A:  LDA MapNumber
LB22C:  CMP MapTargetTbl,X
LB22F:  BEQ $B239
LB231:  INX
LB232:  INX
LB233:  INX
LB234:  CPX #$93
LB236:  BNE $B22C
LB238:  RTS

LB239:  LDA #$02
LB23B:  JMP $D9E2

;----------------------------------------------------------------------------------------------------

ChkRemovePopUp:
LB23E:  LDA BGBufRAM+$84        ;
LB241:  CMP #$FF                ;This tile will be blank unless the pop-up window is active.
LB243:  BNE DoRemovePopUp       ;If it is active, branch to remove it from the screen.
LB245:  RTS                     ;

DoRemovePopUp:
LB246:  LDA FrameCounter        ;Save the frame counter on the stack.
LB248:  PHA                     ;

LB249:  LDA #WND_POPUP          ;Remove the pop-up window.
LB24B:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LB24E:  PLA                     ;
LB24F:  STA FrameCounter        ;Restore the frame counter on the stack.
LB251:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoJoyRight:
LB252:  JSR ChkRemovePopUp      ;($B23E)Check if pop-up window needs to be removed.
LB255:  LDA FrameCounter
LB257:  AND #$0F
LB259:  BEQ $B260
LB25B:  PLA
LB25C:  PLA
LB25D:  JMP IdleUpdate          ;($CB30)Update NPC movement and pop-up window.

LB260:  INC _CharXPos
LB262:  JSR $B1CC
LB265:  LDA MapType
LB267:  CMP #MAP_DUNGEON
LB269:  BNE $B28C
LB26B:  INC CharXPos
LB26D:  JSR $B2D4
LB270:  LDA CharXPixelsLB
LB272:  CLC
LB273:  ADC #$08
LB275:  STA CharXPixelsLB
LB277:  BCC $B27B
LB279:  INC CharXPixelsUB
LB27B:  JSR $B30E
LB27E:  LDA CharXPixelsLB
LB280:  CLC
LB281:  ADC #$08
LB283:  STA CharXPixelsLB
LB285:  BCC $B289
LB287:  INC CharXPixelsUB
LB289:  JMP DoSprites           ;($B6DA)Update player and NPC sprites.
LB28C:  LDA #$12
LB28E:  STA $0F
LB290:  LDA #$F2
LB292:  STA $10
LB294:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB297:  LDA #$00
LB299:  STA BlkRemoveFlgs
LB29B:  STA $D1
LB29D:  JSR ModMapBlock         ;($AD66)Change block on map.
LB2A0:  INC $10
LB2A2:  INC $10
LB2A4:  INC ScrollX
LB2A6:  INC CharXPixelsLB
LB2A8:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB2AB:  LDA $10
LB2AD:  CMP #$10
LB2AF:  BNE $B294
LB2B1:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB2B4:  INC ScrollX
LB2B6:  BNE $B2BE
LB2B8:  LDA ActiveNmTbl
LB2BA:  EOR #$01
LB2BC:  STA ActiveNmTbl
LB2BE:  INC NTBlockX
LB2C0:  LDA #$1F
LB2C2:  AND NTBlockX
LB2C4:  STA NTBlockX
LB2C6:  INC CharXPos
LB2C8:  INC CharXPixelsLB
LB2CA:  BNE $B2CE
LB2CC:  INC CharXPixelsUB
LB2CE:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB2D1:  JMP $B5FA
LB2D4:  LDA NTBlockX
LB2D6:  EOR #$10
LB2D8:  AND #$1F
LB2DA:  STA NTBlockX
LB2DC:  LDA #$FA
LB2DE:  STA $10
LB2E0:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB2E3:  LDA #$F9
LB2E5:  STA $0F
LB2E7:  LDA #$00
LB2E9:  STA BlkRemoveFlgs
LB2EB:  STA $D1
LB2ED:  JSR ModMapBlock         ;($AD66)Change block on map.
LB2F0:  INC $0F
LB2F2:  INC $0F
LB2F4:  LDA $0F
LB2F6:  CMP #$09
LB2F8:  BNE $B2E7
LB2FA:  INC $10
LB2FC:  INC $10
LB2FE:  LDA $10
LB300:  CMP #$08
LB302:  BNE $B2E0
LB304:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB307:  LDA ActiveNmTbl
LB309:  EOR #$01
LB30B:  STA ActiveNmTbl
LB30D:  RTS
LB30E:  LDA NTBlockX
LB310:  CLC
LB311:  ADC #$10
LB313:  AND #$1F
LB315:  STA NTBlockX
LB317:  LDA #$FA
LB319:  STA $10
LB31B:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB31E:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB321:  LDA #$FA
LB323:  STA $0F
LB325:  LDA #$00
LB327:  STA BlkRemoveFlgs
LB329:  STA $D1
LB32B:  JSR ModMapBlock         ;($AD66)Change block on map.
LB32E:  INC $0F
LB330:  INC $0F
LB332:  LDA $0F
LB334:  CMP #$08
LB336:  BNE $B325
LB338:  INC $10
LB33A:  INC $10
LB33C:  LDA $10
LB33E:  CMP #$08
LB340:  BNE $B31E
LB342:  LDA ActiveNmTbl
LB344:  EOR #$01
LB346:  STA ActiveNmTbl
LB348:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB34B:  RTS

;----------------------------------------------------------------------------------------------------

LB34C:  JSR ChkRemovePopUp      ;($B23E)Check if pop-up window needs to be removed.
LB34F:  LDA FrameCounter
LB351:  AND #$0F
LB353:  BEQ $B35A
LB355:  PLA
LB356:  PLA
LB357:  JMP IdleUpdate          ;($CB30)Update NPC movement and pop-up window.

LB35A:  DEC _CharXPos
LB35C:  JSR $B1CC
LB35F:  LDA MapType
LB361:  CMP #MAP_DUNGEON
LB363:  BNE $B386
LB365:  JSR $B2D4
LB368:  DEC CharXPos
LB36A:  LDA CharXPixelsLB
LB36C:  SEC
LB36D:  SBC #$08
LB36F:  STA CharXPixelsLB
LB371:  BCS $B375
LB373:  DEC CharXPixelsUB
LB375:  JSR $B30E
LB378:  LDA CharXPixelsLB
LB37A:  SEC
LB37B:  SBC #$08
LB37D:  STA CharXPixelsLB
LB37F:  BCS $B383
LB381:  DEC CharXPixelsUB
LB383:  JMP DoSprites           ;($B6DA)Update player and NPC sprites.
LB386:  LDA #$EC
LB388:  STA $0F
LB38A:  LDA #$F2
LB38C:  STA $10
LB38E:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB391:  LDA #$00
LB393:  STA BlkRemoveFlgs
LB395:  STA $D1
LB397:  JSR ModMapBlock         ;($AD66)Change block on map.
LB39A:  INC $10
LB39C:  INC $10
LB39E:  LDA ScrollX
LB3A0:  SEC
LB3A1:  SBC #$01
LB3A3:  STA ScrollX
LB3A5:  BCS $B3AD
LB3A7:  LDA ActiveNmTbl
LB3A9:  EOR #$01
LB3AB:  STA ActiveNmTbl
LB3AD:  LDA CharXPixelsLB
LB3AF:  SEC
LB3B0:  SBC #$01
LB3B2:  STA CharXPixelsLB
LB3B4:  BCS $B3B8
LB3B6:  DEC CharXPixelsUB
LB3B8:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB3BB:  LDA $10
LB3BD:  CMP #$10
LB3BF:  BNE $B38E
LB3C1:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB3C4:  DEC ScrollX
LB3C6:  DEC NTBlockX
LB3C8:  LDA #$1F
LB3CA:  AND NTBlockX
LB3CC:  STA NTBlockX
LB3CE:  DEC CharXPos
LB3D0:  DEC CharXPixelsLB
LB3D2:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB3D5:  JMP $B5FA

;----------------------------------------------------------------------------------------------------

LB3D8:  JSR ChkRemovePopUp      ;($B23E)Check if pop-up window needs to be removed.
LB3DB:  LDA FrameCounter
LB3DD:  AND #$0F
LB3DF:  BEQ $B3E6
LB3E1:  PLA
LB3E2:  PLA
LB3E3:  JMP IdleUpdate          ;($CB30)Update NPC movement and pop-up window.

LB3E6:  INC _CharYPos
LB3E8:  JSR $B1CC
LB3EB:  LDA MapType
LB3ED:  CMP #MAP_DUNGEON
LB3EF:  BNE $B412
LB3F1:  INC CharYPos
LB3F3:  JSR $B4C9
LB3F6:  LDA CharYPixelsLB
LB3F8:  CLC
LB3F9:  ADC #$08
LB3FB:  STA CharYPixelsLB
LB3FD:  BCC $B401
LB3FF:  INC CharYPixelsUB
LB401:  JSR $B30E
LB404:  LDA CharYPixelsLB
LB406:  CLC
LB407:  ADC #$08
LB409:  STA CharYPixelsLB
LB40B:  BCC $B40F
LB40D:  INC CharYPixelsUB
LB40F:  JMP DoSprites           ;($B6DA)Update player and NPC sprites.
LB412:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB415:  INC ScrollY
LB417:  INC CharYPixelsLB
LB419:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB41C:  LDA #$10
LB41E:  STA $10
LB420:  LDA #$EE
LB422:  STA $0F
LB424:  LDA #$03
LB426:  STA $4D
LB428:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB42B:  LDA #$0C
LB42D:  STA BlkRemoveFlgs
LB42F:  STA $D1
LB431:  JSR ModMapBlock         ;($AD66)Change block on map.
LB434:  INC $0F
LB436:  INC $0F
LB438:  DEC $4D
LB43A:  BNE $B42B
LB43C:  INC ScrollY
LB43E:  INC CharYPixelsLB
LB440:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB443:  LDA $0F
LB445:  CMP #$12
LB447:  BNE $B424
LB449:  LDA #$10
LB44B:  STA $10
LB44D:  LDA #$EC
LB44F:  STA $0F
LB451:  LDA #$05
LB453:  STA $4D
LB455:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB458:  JSR $C244
LB45B:  LDA $0F
LB45D:  CLC
LB45E:  ADC #$04
LB460:  STA $0F
LB462:  DEC $4D
LB464:  BNE $B458
LB466:  INC ScrollY
LB468:  INC CharYPixelsLB
LB46A:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB46D:  LDA $0F
LB46F:  CMP #$14
LB471:  BNE $B451
LB473:  LDA #$10
LB475:  STA $10
LB477:  LDA #$EE
LB479:  STA $0F
LB47B:  LDA #$03
LB47D:  STA $4D
LB47F:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB482:  LDA #$03
LB484:  STA BlkRemoveFlgs
LB486:  STA $D1
LB488:  JSR ModMapBlock         ;($AD66)Change block on map.
LB48B:  INC $0F
LB48D:  INC $0F
LB48F:  DEC $4D
LB491:  BNE $B482
LB493:  INC ScrollY
LB495:  INC CharYPixelsLB
LB497:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB49A:  LDA $0F
LB49C:  CMP #$12
LB49E:  BNE $B47B
LB4A0:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB4A3:  INC ScrollY
LB4A5:  LDA ScrollY
LB4A7:  CMP #$F0
LB4A9:  BNE $B4AF
LB4AB:  LDA #$00
LB4AD:  STA ScrollY
LB4AF:  INC NTBlockY
LB4B1:  LDA NTBlockY
LB4B3:  CMP #$0F
LB4B5:  BNE $B4BB
LB4B7:  LDA #$00
LB4B9:  STA NTBlockY
LB4BB:  INC CharYPos
LB4BD:  INC CharYPixelsLB
LB4BF:  BNE $B4C3
LB4C1:  INC CharYPixelsUB
LB4C3:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB4C6:  JMP $B5FA
LB4C9:  LDA NTBlockX
LB4CB:  CLC
LB4CC:  ADC #$10
LB4CE:  AND #$1F
LB4D0:  STA NTBlockX
LB4D2:  LDA #$FA
LB4D4:  STA $0F
LB4D6:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB4D9:  LDA #$F9
LB4DB:  STA $10
LB4DD:  LDA #$00
LB4DF:  STA BlkRemoveFlgs
LB4E1:  STA $D1
LB4E3:  JSR ModMapBlock         ;($AD66)Change block on map.
LB4E6:  INC $10
LB4E8:  INC $10
LB4EA:  LDA $10
LB4EC:  CMP #$09
LB4EE:  BNE $B4DD
LB4F0:  INC $0F
LB4F2:  INC $0F
LB4F4:  LDA $0F
LB4F6:  CMP #$08
LB4F8:  BNE $B4D6
LB4FA:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB4FD:  LDA ActiveNmTbl
LB4FF:  EOR #$01
LB501:  STA ActiveNmTbl
LB503:  RTS

;----------------------------------------------------------------------------------------------------

DoJoyUp:
LB504:  JSR ChkRemovePopUp      ;($B23E)Check if pop-up window needs to be removed.
LB507:  LDA FrameCounter
LB509:  AND #$0F
LB50B:  BEQ $B512
LB50D:  PLA
LB50E:  PLA
LB50F:  JMP IdleUpdate          ;($CB30)Update NPC movement and pop-up window.

LB512:  DEC _CharYPos
LB514:  JSR $B1CC
LB517:  LDA MapType
LB519:  CMP #MAP_DUNGEON
LB51B:  BNE $B53E
LB51D:  JSR $B4C9
LB520:  DEC CharYPos
LB522:  LDA CharYPixelsLB
LB524:  SEC
LB525:  SBC #$08
LB527:  STA CharYPixelsLB
LB529:  BCS $B52D
LB52B:  DEC CharYPixelsUB
LB52D:  JSR $B30E
LB530:  LDA CharYPixelsLB
LB532:  SEC
LB533:  SBC #$08
LB535:  STA CharYPixelsLB
LB537:  BCS $B53B
LB539:  DEC CharYPixelsUB
LB53B:  JMP DoSprites           ;($B6DA)Update player and NPC sprites.
LB53E:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB541:  DEC ScrollY
LB543:  LDA ScrollY
LB545:  CMP #$FF
LB547:  BNE $B54D
LB549:  LDA #$EF
LB54B:  STA ScrollY
LB54D:  LDA CharYPixelsLB
LB54F:  SEC
LB550:  SBC #$01
LB552:  STA CharYPixelsLB
LB554:  BCS $B558
LB556:  DEC CharYPixelsUB
LB558:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB55B:  LDA #$F0
LB55D:  STA $10
LB55F:  LDA #$EE
LB561:  STA $0F
LB563:  LDA #$03
LB565:  STA $4D
LB567:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB56A:  LDA #$03
LB56C:  STA BlkRemoveFlgs
LB56E:  STA $D1
LB570:  JSR ModMapBlock         ;($AD66)Change block on map.
LB573:  INC $0F
LB575:  INC $0F
LB577:  DEC $4D
LB579:  BNE $B56A
LB57B:  DEC ScrollY
LB57D:  DEC CharYPixelsLB
LB57F:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB582:  LDA $0F
LB584:  CMP #$12
LB586:  BNE $B563
LB588:  LDA #$F0
LB58A:  STA $10
LB58C:  LDA #$EC
LB58E:  STA $0F
LB590:  LDA #$05
LB592:  STA $4D
LB594:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB597:  JSR $C244
LB59A:  LDA $0F
LB59C:  CLC
LB59D:  ADC #$04
LB59F:  STA $0F
LB5A1:  DEC $4D
LB5A3:  BNE $B597
LB5A5:  DEC ScrollY
LB5A7:  DEC CharYPixelsLB
LB5A9:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB5AC:  LDA $0F
LB5AE:  CMP #$14
LB5B0:  BNE $B590
LB5B2:  LDA #$F0
LB5B4:  STA $10
LB5B6:  LDA #$EE
LB5B8:  STA $0F
LB5BA:  LDA #$03
LB5BC:  STA $4D
LB5BE:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB5C1:  LDA #$0C
LB5C3:  STA BlkRemoveFlgs
LB5C5:  STA $D1
LB5C7:  JSR ModMapBlock         ;($AD66)Change block on map.
LB5CA:  INC $0F
LB5CC:  INC $0F
LB5CE:  DEC $4D
LB5D0:  BNE $B5C1
LB5D2:  DEC ScrollY
LB5D4:  DEC CharYPixelsLB
LB5D6:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB5D9:  LDA $0F
LB5DB:  CMP #$12
LB5DD:  BNE $B5BA
LB5DF:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB5E2:  DEC ScrollY
LB5E4:  DEC NTBlockY
LB5E6:  LDA NTBlockY
LB5E8:  CMP #$FF
LB5EA:  BNE $B5F0
LB5EC:  LDA #$0E
LB5EE:  STA NTBlockY
LB5F0:  DEC CharYPos
LB5F2:  DEC CharYPixelsLB
LB5F4:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB5F7:  JMP $B5FA

LB5FA:  LDA CharXPos
LB5FC:  STA _TargetX
LB5FE:  LDA CharYPos
LB600:  STA _TargetY
LB602:  JSR $AABE
LB605:  LDA $3D
LB607:  CMP $19
LB609:  BNE $B60C
LB60B:  RTS

LB60C:  STA $19
LB60E:  LDA $19
LB610:  BEQ $B623
LB612:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB615:  LDA #$F0
LB617:  STA $0200
LB61A:  STA $0204
LB61D:  STA $0208
LB620:  STA $020C
LB623:  LDA NTBlockX
LB625:  CLC
LB626:  ADC #$10
LB628:  AND #$1F
LB62A:  STA NTBlockX
LB62C:  LDA #$F2
LB62E:  STA $10
LB630:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB633:  LDA #$F0
LB635:  STA $0F
LB637:  LDA #$00
LB639:  STA BlkRemoveFlgs
LB63B:  STA $D1
LB63D:  JSR ModMapBlock         ;($AD66)Change block on map.
LB640:  INC $0F
LB642:  INC $0F
LB644:  LDA $0F
LB646:  CMP #$00
LB648:  BNE $B637
LB64A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB64D:  LDA #$00
LB64F:  STA BlkRemoveFlgs
LB651:  STA $D1
LB653:  JSR ModMapBlock         ;($AD66)Change block on map.
LB656:  INC $0F
LB658:  INC $0F
LB65A:  LDA $0F
LB65C:  CMP #$10
LB65E:  BNE $B64D
LB660:  INC $10
LB662:  INC $10
LB664:  LDA $10
LB666:  CMP #$10
LB668:  BNE $B630
LB66A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB66D:  LDA #$01
LB66F:  STA FrameCounter
LB671:  LDA #NPC_STOP
LB673:  STA StopNPCMove
LB675:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LB678:  LDA #NPC_MOVE
LB67A:  STA StopNPCMove
LB67C:  LDA ActiveNmTbl
LB67E:  EOR #$01
LB680:  STA ActiveNmTbl
LB682:  LDA #$EE
LB684:  STA $0F
LB686:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB689:  LDA #$F2
LB68B:  STA $10
LB68D:  LDA #$00
LB68F:  STA BlkRemoveFlgs
LB691:  STA $D1
LB693:  JSR ModMapBlock         ;($AD66)Change block on map.
LB696:  INC $10
LB698:  INC $10
LB69A:  LDA $10
LB69C:  CMP #$02
LB69E:  BNE $B68D
LB6A0:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB6A3:  LDA #$00
LB6A5:  STA BlkRemoveFlgs
LB6A7:  STA $D1
LB6A9:  JSR ModMapBlock         ;($AD66)Change block on map.
LB6AC:  INC $10
LB6AE:  INC $10
LB6B0:  LDA $10
LB6B2:  CMP #$10
LB6B4:  BNE $B6A3
LB6B6:  LDA $0F
LB6B8:  CLC
LB6B9:  ADC #$22
LB6BB:  STA $0F
LB6BD:  CMP #$32
LB6BF:  BNE $B686
LB6C1:  RTS

;----------------------------------------------------------------------------------------------------

SprtFacingBaseAddr:
LB6C2:  STA NPCCounter          ;Save a copy of character direction.

LB6C4:  LDA CharSpriteTblPtr    ;
LB6C7:  STA GenPtr22LB          ;Get base address of character sprite table.
LB6C9:  LDA CharSpriteTblPtr+1  ;
LB6CC:  STA GenPtr22UB          ;

LB6CE:* LDA NPCCounter          ;Increment upper byte of pointer while decrementing the-->
LB6D0:  BEQ SprtFacingEnd       ;NPC counter to find the base address of the character-->
LB6D2:  INC GenPtr22UB          ;sprites for the proper facing direction.  The table-->
LB6D4:  DEC NPCCounter          ;is organized by the direction the character is facing.
LB6D6:  JMP -                   ;Has proper direction been found? If not, branch to decrement.

SprtFacingEnd:
LB6D9:  RTS                     ;End sprite direction calculations.

;----------------------------------------------------------------------------------------------------

DoSprites:
LB6DA:  LDA EnNumber            ;Is this the final fight?
LB6DC:  CMP #EN_DRAGONLORD2     ;If so, exit, else branch-->
LB6DE:  BNE SprtChkFrameCntr    ;to continue processing.
LB6E0:  RTS                     ;

SprtChkFrameCntr:
LB6E1:  LDA FrameCounter        ;Is this the 16th frame?
LB6E3:  AND #$0F                ;
LB6E5:  BNE ChkGotGwaelin       ;If not, branch.

LB6E7:  LDA CharLeftRight       ;Every 16th frame, alternate character animations. This-->
LB6E9:  CLC                     ;creates the walking effect for characters. bit 3 is-->
LB6EA:  ADC #$08                ;the only bit considered.
LB6EC:  STA CharLeftRight       ;

ChkGotGwaelin:
LB6EE:  LDA PlayerFlags         ;Is the player carrying Gwaelin?
LB6F0:  AND #F_GOT_GWAELIN      ;if not, branch.
LB6F2:  BEQ ChkPlayerWeapons    ;

LB6F4:  LDA #$C0
LB6F6:  STA $3C
LB6F8:  BNE GetPlayerAnim

ChkPlayerWeapons:
LB6FA:  LDA #$80
LB6FC:  STA $3C
LB6FE:  LDA EqippedItems
LB700:  AND #WP_WEAPONS
LB702:  BEQ ChkPlayerShields

LB704:  LDA #$90
LB706:  STA $3C

ChkPlayerShields:
LB708:  LDA EqippedItems
LB70A:  AND #SH_SHIELDS
LB70C:  BEQ GetPlayerAnim

LB70E:  LDA #$20
LB710:  ORA $3C
LB712:  STA $3C

GetPlayerAnim:
LB714:  LDA CharLeftRight
LB716:  AND #$08
LB718:  ORA $3C
LB71A:  TAY
LB71B:  LDX #$00

LB71D:  LDA #$6F                ;First sprite tile of player is 111 pixels from top of screen.
LB71F:  STA CharYScrPos         ;

LB721:  LDA CharDirection       ;Use character facing direction for char table index calc.
LB724:  JSR SprtFacingBaseAddr  ;($B6C2)Calculate entry into char data table based on direction.

GetPlayerTileLoop1:
LB727:  LDA #$80
LB729:  STA CharXScrPos

GetPlayerTileLoop2:
LB72B:  LDA $05D0
LB72E:  CMP #$FF
LB730:  BEQ $B736

LB732:  LDA #$F0
LB734:  BNE PlyrSetXCord

LB736:  LDA CharYScrPos

PlyrSetXCord:
LB738:  STA SpriteRAM,X

LB73B:  INX                     ;
LB73C:  LDA (GenPtr22),Y        ;Store player sprite tile pattern byte.
LB73E:  STA SpriteRAM,X         ;

LB741:  INX                     ;
LB742:  INY                     ;Store player sprite attribute byte.
LB743:  LDA (GenPtr22),Y        ;
LB745:  STA SpriteRAM,X         ;

LB748:  INX                     ;
LB749:  INY                     ;Store player sprite X screen position.
LB74A:  LDA CharXScrPos         ;
LB74C:  STA SpriteRAM,X         ;

LB74F:  INX
LB750:  LDA CharXScrPos
LB752:  CLC
LB753:  ADC #$08
LB755:  STA CharXScrPos
LB757:  CMP #$90
LB759:  BNE GetPlayerTileLoop2

LB75B:  LDA CharYScrPos         ;
LB75D:  CLC                     ;Move down 1 row for next player sprite tiles(8 pixels).
LB75E:  ADC #$08                ;
LB760:  STA CharYScrPos         ;

LB762:  CMP #$7F                ;Have all 4 sprite tiles for the player been placed?
LB764:  BNE GetPlayerTileLoop1  ;If not, branch to place another tile.

LB766:  LDA NPCUpdateCntr
LB768:  AND #$F0
LB76A:  BEQ $B76F
LB76C:  JMP $B9FB

LB76F:  LDA NPCUpdateCntr
LB771:  ASL
LB772:  STA $3C
LB774:  ASL
LB775:  ADC $3C
LB777:  TAX
LB778:  LDA #$02
LB77A:  STA $4E
LB77C:  LDA NPCXPos,X
LB77E:  AND #$1F
LB780:  BNE $B78B
LB782:  LDA NPCYPos,X
LB784:  AND #$1F
LB786:  BNE $B78B
LB788:  JMP $B8EA
LB78B:  LDA FrameCounter
LB78D:  AND #$0F
LB78F:  CMP #$01
LB791:  BEQ $B796
LB793:  JMP $B861
LB796:  LDA StopNPCMove
LB798:  BEQ $B7A1
LB79A:  ASL NPCYPos,X
LB79C:  LSR NPCYPos,X
LB79E:  JMP $B8EA
LB7A1:  JSR UpdateRandNum       ;($C55B)Get random number.
LB7A4:  LDA NPCYPos,X
LB7A6:  AND #$9F
LB7A8:  STA NPCYPos,X
LB7AA:  LDA $95
LB7AC:  AND #$60
LB7AE:  ORA NPCYPos,X
LB7B0:  STA NPCYPos,X
LB7B2:  JSR GetNPCPosCopy       ;($BA15)Get a copy of the NPCs X and Y block position.
LB7B5:  JSR $BA22
LB7B8:  LDA $41
LB7BA:  BEQ $B7C2
LB7BC:  LDA $40
LB7BE:  CMP #$FF
LB7C0:  BNE $B79A
LB7C2:  JSR $AABE
LB7C5:  LDA NPCYPos,X
LB7C7:  AND #$60
LB7C9:  BNE $B7D0
LB7CB:  DEC $43
LB7CD:  JMP $B7E4
LB7D0:  CMP #$20
LB7D2:  BNE $B7D9
LB7D4:  INC $42
LB7D6:  JMP $B7E4
LB7D9:  CMP #$40
LB7DB:  BNE $B7E2
LB7DD:  INC $43
LB7DF:  JMP $B7E4
LB7E2:  DEC $42
LB7E4:  LDA MapHeight
LB7E6:  CMP $43
LB7E8:  BCS $B7ED
LB7EA:  JMP $B79A

LB7ED:  LDA MapWidth
LB7EF:  CMP $42
LB7F1:  BCC $B79A
LB7F3:  JSR $BA22
LB7F6:  LDA $41
LB7F8:  BEQ $B800
LB7FA:  LDA $40
LB7FC:  CMP #$FF
LB7FE:  BNE $B79A
LB800:  LDA $42
LB802:  CMP CharXPos
LB804:  BNE $B80C
LB806:  LDA $43
LB808:  CMP CharYPos
LB80A:  BEQ $B79A
LB80C:  LDA $42
LB80E:  CMP _CharXPos
LB810:  BNE $B81B
LB812:  LDA $43
LB814:  CMP _CharYPos
LB816:  BNE $B81B
LB818:  JMP $B79A
LB81B:  LDY #$00
LB81D:  LDA _NPCXPos,Y
LB820:  AND #$1F
LB822:  CMP $42
LB824:  BNE $B832
LB826:  LDA _NPCYPos,Y
LB829:  AND #$1F
LB82B:  CMP $43
LB82D:  BNE $B832
LB82F:  JMP $B79A
LB832:  INY
LB833:  INY
LB834:  INY
LB835:  CPY #$3C
LB837:  BNE $B81D
LB839:  LDA $3D
LB83B:  PHA
LB83C:  LDA $42
LB83E:  STA $3C
LB840:  LDA $43
LB842:  STA $3E
LB844:  JSR GetBlockID          ;($AC17)Get description of block.
LB847:  JSR $AAE1
LB84A:  PLA
LB84B:  CMP $3D
LB84D:  BEQ $B852
LB84F:  JMP $B79A
LB852:  LDA $3C
LB854:  CMP #$0D
LB856:  BCC $B85B
LB858:  JMP $B79A
LB85B:  LDA NPCYPos,X
LB85D:  ORA #$80
LB85F:  STA NPCYPos,X
LB861:  LDA NPCYPos,X
LB863:  BMI $B868
LB865:  JMP $B8EA

LB868:  LDA StopNPCMove
LB86A:  BEQ $B86F
LB86C:  JMP $B8EA

LB86F:  LDA NPCYPos,X
LB871:  AND #$60
LB873:  BNE $B893
LB875:  LDA NPCMidPos,X
LB877:  AND #$0F
LB879:  SEC
LB87A:  SBC #$01
LB87C:  AND #$0F
LB87E:  STA $3C
LB880:  LDA NPCMidPos,X
LB882:  AND #$F0
LB884:  ORA $3C
LB886:  STA NPCMidPos,X
LB888:  LDA $3C
LB88A:  CMP #$0F
LB88C:  BNE $B8EA
LB88E:  DEC NPCYPos,X
LB890:  JMP $B8EA
LB893:  CMP #$20
LB895:  BNE $B8B1
LB897:  LDA NPCMidPos,X
LB899:  AND #$F0
LB89B:  CLC
LB89C:  ADC #$10
LB89E:  STA $3C
LB8A0:  LDA NPCMidPos,X
LB8A2:  AND #$0F
LB8A4:  ORA $3C
LB8A6:  STA NPCMidPos,X
LB8A8:  LDA $3C
LB8AA:  BNE $B8EA
LB8AC:  INC NPCXPos,X
LB8AE:  JMP $B8EA
LB8B1:  CMP #$40
LB8B3:  BNE $B8D1
LB8B5:  LDA NPCMidPos,X
LB8B7:  AND #$0F
LB8B9:  CLC
LB8BA:  ADC #$01
LB8BC:  AND #$0F
LB8BE:  STA $3C
LB8C0:  LDA NPCMidPos,X
LB8C2:  AND #$F0
LB8C4:  ORA $3C
LB8C6:  STA NPCMidPos,X
LB8C8:  LDA $3C
LB8CA:  BNE $B8EA
LB8CC:  INC NPCYPos,X
LB8CE:  JMP $B8EA
LB8D1:  LDA NPCMidPos,X
LB8D3:  AND #$F0
LB8D5:  SEC
LB8D6:  SBC #$10
LB8D8:  STA $3C
LB8DA:  LDA NPCMidPos,X
LB8DC:  AND #$0F
LB8DE:  ORA $3C
LB8E0:  STA NPCMidPos,X
LB8E2:  LDA $3C
LB8E4:  CMP #$F0
LB8E6:  BNE $B8EA
LB8E8:  DEC NPCXPos,X
LB8EA:  INX
LB8EB:  INX
LB8EC:  INX
LB8ED:  DEC $4E
LB8EF:  BEQ $B8F4
LB8F1:  JMP $B77C
LB8F4:  LDX #$00
LB8F6:  LDA #$10
LB8F8:  STA $4E
LB8FA:  LDA NPCXPos,X
LB8FC:  AND #$1F
LB8FE:  BNE $B909
LB900:  LDA NPCYPos,X
LB902:  AND #$1F
LB904:  BNE $B909
LB906:  JMP $B9DF
LB909:  JSR NPCXScrnCord        ;($BA52)Get NPC pixel X coord on the screen.
LB90C:  LDA $3E
LB90E:  CLC
LB90F:  ADC #$07
LB911:  STA $3E
LB913:  LDA $3F
LB915:  ADC #$00
LB917:  BEQ $B929
LB919:  CMP #$01
LB91B:  BEQ $B920
LB91D:  JMP $B9DF

LB920:  LDA $3E
LB922:  CMP #$07
LB924:  BCC $B929
LB926:  JMP $B9DF

LB929:  JSR NPCYScrnCord        ;($BA84)Get NPC pixel Y coord on the screen.
LB92C:  LDA $40
LB92E:  CLC
LB92F:  ADC #$11
LB931:  STA $40
LB933:  LDA $41
LB935:  ADC #$00
LB937:  BEQ $B93C
LB939:  JMP $B9DF
LB93C:  JSR GetNPCPosCopy       ;($BA15)Get a copy of the NPCs X and Y block position.
LB93F:  JSR $BA22
LB942:  LDA $41
LB944:  BEQ $B94F
LB946:  LDA $40
LB948:  CMP #$FF
LB94A:  BEQ $B94F
LB94C:  JMP $B9DF
LB94F:  LDA $42
LB951:  STA $3C
LB953:  LDA $43
LB955:  STA $3E
LB957:  JSR $AABE
LB95A:  LDA $3D
LB95C:  CMP $19
LB95E:  BEQ $B963
LB960:  JMP $B9DF

LB963:  JSR GetSpclNPCType      ;($C0F4)Check for special NPC type.
LB966:  STA $3C
LB968:  JSR NPCXScrnCord        ;($BA52)Get NPC pixel X coord on the screen.
LB96B:  JSR NPCYScrnCord        ;($BA84)Get NPC pixel Y coord on the screen.
LB96E:  LDY $4E
LB970:  STX $4E
LB972:  LDX $3C
LB974:  LDA #$00
LB976:  STA $3C
LB978:  LDA #$00
LB97A:  STA $3D
LB97C:  LDA $3E
LB97E:  CLC
LB97F:  ADC $3D
LB981:  STA $42
LB983:  LDA $3F
LB985:  ADC #$00
LB987:  BNE $B9C0
LB989:  TYA
LB98A:  STX $25
LB98C:  TAX
LB98D:  LDY $4E
LB98F:  LDA _NPCYPos,Y
LB992:  AND #$60
LB994:  ASL
LB995:  ROL
LB996:  ROL
LB997:  ROL
LB998:  JSR SprtFacingBaseAddr  ;($B6C2)Calculate entry into char data table based on direction.
LB99B:  LDY $25
LB99D:  LDA ThisNPCXPos
LB99F:  STA $0203,X
LB9A2:  LDA $40
LB9A4:  CLC
LB9A5:  ADC $3C
LB9A7:  STA $0200,X
LB9AA:  LDA ($22),Y
LB9AC:  STA $0201,X
LB9AF:  INY
LB9B0:  LDA ($22),Y
LB9B2:  DEY
LB9B3:  STA $0202,X
LB9B6:  TYA
LB9B7:  STX $22
LB9B9:  TAX
LB9BA:  LDY $22
LB9BC:  INY
LB9BD:  INY
LB9BE:  INY
LB9BF:  INY
LB9C0:  INX
LB9C1:  INX
LB9C2:  TYA
LB9C3:  BEQ $B9E9
LB9C5:  LDA $3D
LB9C7:  CLC
LB9C8:  ADC #$08
LB9CA:  STA $3D
LB9CC:  CMP #$10
LB9CE:  BNE $B97C
LB9D0:  LDA $3C
LB9D2:  CLC
LB9D3:  ADC #$08
LB9D5:  STA $3C
LB9D7:  CMP #$10
LB9D9:  BNE $B978
LB9DB:  LDX $4E
LB9DD:  STY $4E

LB9DF:  INX
LB9E0:  INX
LB9E1:  INX
LB9E2:  CPX #$3C
LB9E4:  BEQ $B9E9
LB9E6:  JMP $B8FA
LB9E9:  LDY $4E
LB9EB:  LDA #$F0
LB9ED:  CPY #$00
LB9EF:  BEQ $B9FB
LB9F1:  STA $0200,Y
LB9F4:  INY
LB9F5:  INY
LB9F6:  INY
LB9F7:  INY
LB9F8:  JMP $B9ED

LB9FB:  LDA FrameCounter
LB9FD:  AND #$0F
LB9FF:  BEQ $BA02
LBA01:  RTS

LBA02:  LDA NPCUpdateCntr
LBA04:  CMP #$FF
LBA06:  BEQ $BA14

LBA08:  INC NPCUpdateCntr
LBA0A:  LDA NPCUpdateCntr
LBA0C:  CMP #$05
LBA0E:  BNE $BA14

LBA10:  LDA #$00
LBA12:  STA NPCUpdateCntr

LBA14:  RTS

;----------------------------------------------------------------------------------------------------

GetNPCPosCopy:
LBA15:  LDA NPCXPos,X           ;
LBA17:  AND #$1F                ;Save a copy of the current NPC's X block position.
LBA19:  STA ThisNPCXPos         ;

LBA1B:  LDA NPCYPos,X           ;
LBA1D:  AND #$1F                ;Save a copy of the current NPC's Y block position.
LBA1F:  STA ThisNPCYPos         ;
LBA21:  RTS                     ;

;----------------------------------------------------------------------------------------------------

LBA22:  LDA #$00
LBA24:  STA $41
LBA26:  LDA $42
LBA28:  SEC
LBA29:  SBC CharXPos
LBA2B:  CLC
LBA2C:  ADC #$08
LBA2E:  STA $3C
LBA30:  CMP #$10
LBA32:  BCC $BA35
LBA34:  RTS

LBA35:  LDA $43
LBA37:  SEC
LBA38:  SBC CharYPos
LBA3A:  CLC
LBA3B:  ADC #$07
LBA3D:  STA $3E
LBA3F:  CMP #$0F
LBA41:  BCC $BA44
LBA43:  RTS

LBA44:  JSR CalcPPUBufAddr      ;($C596)Calculate PPU address.
LBA47:  LDY #$00
LBA49:  LDA (PPUBufPtr),Y
LBA4B:  STA $40
LBA4D:  LDA #$FF
LBA4F:  STA $41
LBA51:  RTS

;----------------------------------------------------------------------------------------------------

NPCXScrnCord:
LBA52:  LDA NPCXPos,X
LBA54:  AND #$1F
LBA56:  STA $3F
LBA58:  LDA NPCMidPos,X
LBA5A:  STA $3E

LBA5C:  LSR $3F
LBA5E:  ROR $3E
LBA60:  LSR $3F
LBA62:  ROR $3E
LBA64:  LSR $3F
LBA66:  ROR $3E
LBA68:  LSR $3F
LBA6A:  ROR $3E

LBA6C:  LDA $3E
LBA6E:  SEC
LBA6F:  SBC CharXPixelsLB
LBA71:  STA $3E
LBA73:  LDA $3F
LBA75:  SBC CharXPixelsUB
LBA77:  STA $3F

LBA79:  LDA $3E
LBA7B:  EOR #$80
LBA7D:  STA $3E
LBA7F:  BMI $BA83
LBA81:  INC $3F
LBA83:  RTS

;----------------------------------------------------------------------------------------------------

NPCYScrnCord:
LBA84:  LDA NPCYPos,X
LBA86:  AND #$1F
LBA88:  STA $41
LBA8A:  LDA #$00
LBA8C:  STA $40

LBA8E:  LSR $41
LBA90:  ROR $40
LBA92:  LSR $41
LBA94:  ROR $40
LBA96:  LSR $41
LBA98:  ROR $40
LBA9A:  LSR $41
LBA9C:  ROR $40

LBA9E:  LDA NPCMidPos,X
LBAA0:  AND #$0F
LBAA2:  ORA $40
LBAA4:  STA $40

LBAA6:  SEC
LBAA7:  SBC CharYPixelsLB
LBAA9:  STA $40

LBAAB:  LDA $41
LBAAD:  SBC CharYPixelsUB
LBAAF:  STA $41

LBAB1:  LDA $40
LBAB3:  CLC
LBAB4:  ADC #$6F
LBAB6:  STA $40
LBAB8:  BCC $BABC
LBABA:  INC $41
LBABC:  RTS

;----------------------------------------------------------------------------------------------------

LoadEndBossGFX:
LBABD:  LDA #PAL_LOAD_BG        ;Prepare to load both sprite and background palettes.
LBABF:  STA LoadBGPal           ;
LBAC1:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LBAC4:  LDA TownPalPtr          ;
LBAC7:  STA BGPalPtrLB          ;Get background palette pointer.
LBAC9:  LDA TownPalPtr+1        ;
LBACC:  STA BGPalPtrUB          ;

LBACE:  LDA BlackPalPtr         ;
LBAD1:  STA SprtPalPtrLB        ;Get sprite palette pointer.
LBAD3:  LDA BlackPalPtr+1       ;
LBAD6:  STA SprtPalPtrUB        ;

LBAD8:  JSR PalFadeOut          ;($C212)Fade out both background and sprite palettes.

LBADB:  LDA #NT_NAMETBL0_LB     ;
LBADD:  STA PPUAddrLB           ;Load base address of nametable 0.
LBADF:  LDA #NT_NAMETBL0_UB     ;
LBAE1:  STA PPUAddrUB           ;

LBAE3:  LDA #$1E                ;Prepare to load 30 nametable buffer rows.
LBAE5:  STA BufByteCntr         ;
LBAE7:  LDA #TL_BLANK_TILE1     ;Prepare to load blank tiles into the buffer.
LBAE9:  STA PPUDataByte         ;

LBAEB:  JSR LoadBufferRows      ;($BBAE)Load a string of the same byte into nametable buffer rows.

LBAEE:  LDA #$00                ;Prepare to clear out the attribute table.
LBAF0:  STA PPUDataByte         ;

LBAF2:  LDA #$02                ;Load 2 rows of zeros into the attribute table.
LBAF4:  STA BufByteCntr         ;

LBAF6:  JSR LoadBufferRows      ;($BBAE)Load a string of the same byte into nametable buffer rows.
LBAF9:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LBAFC:  LDA #$FF                ;Prepare to clear NES RAM.
LBAFE:  LDY #$00                ;256 bytes.

LBB00:* STA BGBufRAM,Y          ;
LBB03:  STA BGBufRAM+$100,Y     ;
LBB06:  STA BGBufRAM+$200,Y     ;Clear NES RAM.
LBB09:  STA BGBufRAM+$300,Y     ;
LBB0C:  DEY                     ;
LBB0D:  BNE -                   ;

LBB0F:  LDA #%00000000          ;Turn off sprites and background.
LBB11:  STA PPUControl1         ;

LBB14:  JSR Bank0ToCHR0         ;($FCA3)Load CHR bank 0 to CHR ROM 0.
LBB17:  JSR Bank0ToCHR1         ;($FCA8)Load CHR bank 0 to CHR ROM 1.

LBB1A:  LDY #$00                ;Start at beginning of table.

EBTileLoadLoop:
LBB1C:  LDA EndBossBGTiles,Y    ;Get tile number from table
LBB1F:  STA PPUDataByte         ;

LBB21:  INY                     ;
LBB22:  LDA EndBossBGTiles,Y    ;Get lower address byte from table.
LBB25:  STA PPUAddrLB           ;

LBB27:  INY                     ;
LBB28:  LDA EndBossBGTiles,Y    ;Get upper address byte from table.
LBB2B:  STA PPUAddrUB           ;

LBB2D:  INY                     ;Last 4 entries are attribute table entries.
LBB2E:  CPY #$3C                ;Is this one of the last 4 entries?
LBB30:  BCS EBTileBufLoad       ;If not, branch.

LBB32:  LDA PPUAddrLB           ;
LBB34:  SEC                     ;
LBB35:  SBC #$02                ;Attribute table entry. Subtract 2 from address.
LBB37:  STA PPUAddrLB           ;
LBB39:  BCS EBTileBufLoad       ;
LBB3B:  DEC PPUAddrUB           ;

EBTileBufLoad:
LBB3D:  JSR LoadBufferByte      ;($BBDF)Load a single byte into the nametable buffer.
LBB40:  CPY #$45
LBB42:  BNE EBTileLoadLoop

LBB44:  LDX #$00                ;Zero out index for sprite data table.

EBSpriteLoadLoop:
LBB46:  LDA EndBossSPTiles,X    ;   
LBB49:  CMP #$FF                ;Look for end #$FF to see if at end of sprites.
LBB4B:  BNE EBSpriteSave        ;#$FF found? If not, branch to get next byte.

LBB4D:  LDA EndBossSPTiles+1,X  ;Get next byte. Overwrites last byte. a bug.
LBB50:  CMP #$FF                ;
LBB52:  BEQ EBSpriteLoadDone    ;Second #$FF found? If not, branch to get next byte.

EBSpriteSave:
LBB54:  STA SpriteRAM,X         ;Save sprite data byte.
LBB57:  INX                     ;Have all the sprite bytes been loaded?
LBB58:  BNE EBSpriteLoadLoop    ;If not, branch to get more.

EBSpriteLoadDone:
LBB5A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LBB5D:  LDA #%00011000          ;
LBB5F:  STA PPUControl1         ;Turn on sprites and background.

LBB62:  LDA EndBossPal2Ptr      ;
LBB65:  STA SprtPalPtrLB        ;Get sprite palette pointer for end boss.
LBB67:  LDA EndBossPal2Ptr+1    ;
LBB6A:  STA SprtPalPtrUB        ;

LBB6C:  LDA EndBossPal1Ptr      ;
LBB6F:  STA BGPalPtrLB          ;Get background palette pointer for end boss.
LBB71:  LDA EndBossPal1Ptr+1    ;
LBB74:  STA BGPalPtrUB          ;

LBB76:  LDA #$00                ;
LBB78:  STA ScrollX             ;Zero out the scroll registers.
LBB7A:  STA ScrollY             ;
LBB7C:  STA ActiveNmTbl         ;Use nametable 0.

LBB7E:  LDA #$08                ;
LBB80:  STA NTBlockX            ;Set block position to the center of the screen.
LBB82:  LDA #$07                ;
LBB84:  STA NTBlockY            ;

LBB86:  LDA #SFX_FIRE           ;Fire SFX.
LBB88:  BRK                     ;
LBB89:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LBB8B:  LDA #EN_DRAGONLORD2     ;Indicate fighting the end boss.
LBB8D:  STA EnNumber            ;
LBB8F:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LBB92:  LDA #PAL_LOAD_BG        ;Indicate both sprite and background palettes will be written.
LBB94:  STA LoadBGPal           ;

LBB96:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.
LBB99:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.
LBB9C:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.
LBB9F:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.

LBBA2:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LBBA5:  LDX #$28                ;Wait 40 frames before continuing.
LBBA7:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LBBAA:  DEX                     ;
LBBAB:  BNE -                   ;Have 40 frames passed?
LBBAD:  RTS                     ;If not, branch to wait another frame.

;----------------------------------------------------------------------------------------------------

LoadBufferRows:
LBBAE:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LBBB1:  LDY #$20                ;1 row is 32 tiles.

LBBB3:* JSR LoadBufferByte      ;($BBDF)Load a single byte into the nametable buffer.
LBBB6:  DEY                     ;
LBBB7:  BNE -                   ;Has the whole row been loaded? If not, branch to do another byte.

LBBB9:  DEC BufByteCntr         ;Move to next row.
LBBBB:  BNE LoadBufferRows      ;Is there another row to load?
LBBBD:  RTS                     ;If so, branch to to another row.

;----------------------------------------------------------------------------------------------------

UnusedFunc1:
LBBBE:  LDA NTBlockY            ;
LBBC0:  ASL                     ;
LBBC1:  CLC                     ;
LBBC2:  ADC YPosFromCenter      ;
LBBC4:  CLC                     ;
LBBC5:  ADC #$1E                ;
LBBC7:  STA DivNum1LB           ;
LBBC9:  LDA #$1E                ;
LBBCB:  STA DivNum2             ;Unused function.
LBBCD:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LBBD0:  LDA $40                 ;
LBBD2:  STA $3E                 ;
LBBD4:  LDA NTBlockX            ;
LBBD6:  ASL                     ;
LBBD7:  CLC                     ;
LBBD8:  ADC $0F                 ;
LBBDA:  AND #$3F                ;
LBBDC:  STA $3C                 ;
LBBDE:  RTS                     ;

;----------------------------------------------------------------------------------------------------

LoadBufferByte:
LBBDF:  TYA                     ;Save Y on the stack.
LBBE0:  PHA                     ;

LBBE1:  LDA PPUAddrLB           ;
LBBE3:  STA GenPtr22LB          ;
LBBE5:  LDA PPUAddrUB           ;Get PPU address and minus #$1C to find the corresponding-->
LBBE7:  SEC                     ;point in the nametable buffer.
LBBE8:  SBC #$1C                ;
LBBEA:  STA GenPtr22UB          ;

LBBEC:  LDY #$00                ;Zero out the offset.
LBBEE:  LDA PPUDataByte         ;Store byte in the buffer.
LBBF0:  STA (GenPtr22),Y        ;
LBBF2:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LBBF5:  PLA                     ;
LBBF6:  TAY                     ;Restore Y from the stack.
LBBF7:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;The following table contains the background tiles used to make the end boss.
;There are three bytes per tile.  The first byte is the tile pattern.  The 
;next two bytes are the PPU address for the tile pattern.

EndBossBGTiles:
LBBF8:  .byte $58, $2F, $21     ;PPUAddress $212F.
LBBFB:  .byte $59, $4F, $21     ;PPUAddress $214F.
LBBFE:  .byte $5A, $70, $21     ;PPUAddress $2170.
LBC01:  .byte $5B, $71, $21     ;PPUAddress $2171.
LBC04:  .byte $5C, $8E, $21     ;PPUAddress $218E.
LBC07:  .byte $5D, $8F, $21     ;PPUAddress $218F.
LBC0A:  .byte $5E, $90, $21     ;PPUAddress $2190.
LBC0D:  .byte $6A, $91, $21     ;PPUAddress $2191.
LBC10:  .byte $6B, $92, $21     ;PPUAddress $2192.
LBC13:  .byte $6C, $AE, $21     ;PPUAddress $21AE.
LBC16:  .byte $6D, $AF, $21     ;PPUAddress $21AF.
LBC19:  .byte $6E, $B0, $21     ;PPUAddress $21B0.
LBC1C:  .byte $6F, $B1, $21     ;PPUAddress $21B1.
LBC1F:  .byte $70, $B2, $21     ;PPUAddress $21B2.
LBC22:  .byte $71, $B3, $21     ;PPUAddress $21B3.
LBC25:  .byte $72, $CE, $21     ;PPUAddress $21CE.
LBC28:  .byte $73, $CF, $21     ;PPUAddress $21CF.
LBC2B:  .byte $0A, $D0, $21     ;PPUAddress $21D0.
LBC2E:  .byte $0B, $D1, $21     ;PPUAddress $21D1.
LBC31:  .byte $91, $D3, $23     ;PPUAddress $23D3.
LBC34:  .byte $C0, $DA, $23     ;PPUAddress $23DA.
LBC37:  .byte $EA, $DB, $23     ;PPUAddress $23DB.
LBC3A:  .byte $02, $DC, $23     ;PPUAddress $23DC.

;----------------------------------------------------------------------------------------------------

;The end boss uses all 64 sprites. 256 bytes total.  The sprites
;are loaded directly into sprite RAM without any processing.

EndBossSPTiles:
LBC3D:  .byte $6F, $C0, $00, $80
LBC41:  .byte $77, $C1, $00, $60
LBC45:  .byte $77, $C2, $00, $68
LBC49:  .byte $77, $C3, $00, $70
LBC4D:  .byte $77, $C4, $00, $78
LBC51:  .byte $77, $C5, $00, $80
LBC55:  .byte $7F, $C6, $00, $60
LBC59:  .byte $7F, $C7, $00, $68
LBC5D:  .byte $7F, $C8, $00, $70
LBC61:  .byte $7F, $C9, $00, $78
LBC65:  .byte $7F, $CA, $00, $80
LBC69:  .byte $87, $CB, $00, $65
LBC6D:  .byte $87, $CC, $00, $6D
LBC71:  .byte $87, $CD, $00, $78
LBC75:  .byte $87, $CE, $00, $80
LBC79:  .byte $8A, $CF, $01, $61
LBC7D:  .byte $8E, $D0, $01, $74
LBC81:  .byte $8F, $D1, $00, $64
LBC85:  .byte $8F, $D2, $00, $6D
LBC89:  .byte $8F, $D3, $00, $7B
LBC8D:  .byte $8F, $D4, $00, $83
LBC91:  .byte $92, $D5, $00, $8B
LBC95:  .byte $94, $D6, $01, $8A
LBC99:  .byte $97, $D7, $00, $83
LBC9D:  .byte $64, $D8, $01, $4E
LBCA1:  .byte $60, $D9, $01, $56
LBCA5:  .byte $68, $DA, $01, $56
LBCA9:  .byte $5B, $DB, $01, $5E
LBCAD:  .byte $63, $DC, $01, $5E
LBCB1:  .byte $6B, $DD, $01, $5E
LBCB5:  .byte $5B, $DE, $01, $66
LBCB9:  .byte $63, $DF, $01, $66
LBCBD:  .byte $6B, $E0, $01, $66
LBCC1:  .byte $6F, $E1, $00, $58
LBCC5:  .byte $59, $E2, $01, $80
LBCC9:  .byte $61, $E3, $01, $80
LBCCD:  .byte $6B, $E4, $01, $80
LBCD1:  .byte $59, $E5, $01, $88
LBCD5:  .byte $61, $E6, $01, $88
LBCD9:  .byte $69, $E7, $01, $88
LBCDD:  .byte $5F, $E8, $01, $90
LBCE1:  .byte $67, $E9, $01, $90
LBCE5:  .byte $67, $EA, $01, $98
LBCE9:  .byte $6F, $EB, $01, $8F
LBCED:  .byte $3E, $EC, $02, $51
LBCF1:  .byte $3E, $ED, $02, $59
LBCF5:  .byte $46, $EE, $02, $4E
LBCF9:  .byte $46, $EF, $02, $56
LBCFD:  .byte $46, $F0, $02, $5E
LBD01:  .byte $40, $F1, $00, $68
LBD05:  .byte $48, $F2, $00, $68
LBD09:  .byte $50, $F3, $00, $68
LBD0D:  .byte $47, $F4, $00, $70
LBD11:  .byte $4E, $F5, $02, $70
LBD15:  .byte $4F, $F6, $00, $70
LBD19:  .byte $47, $F7, $00, $78
LBD1D:  .byte $4F, $F8, $00, $78
LBD21:  .byte $4A, $F9, $02, $7B
LBD25:  .byte $52, $FA, $02, $7B
LBD29:  .byte $4C, $FB, $02, $83
LBD2D:  .byte $4F, $FC, $02, $8B
LBD31:  .byte $56, $FD, $03, $54
LBD35:  .byte $56, $FE, $03, $5C
LBD39:  .byte $5E, $FF, $03, $5C    ;A bug. Actually displays part of a 3. Where tail meets wing.
LBD3D:  .byte $FF, $FF              ;Look at code under EBSpriteLoadLoop for reason why.

;----------------------------------------------------------------------------------------------------

EndBossPal1Ptr:
LBD3F:  .word EndBossPal1       ;($BD41)Pointer to palette data below.
EndBossPal1:
LBD41:  .byte $30, $0E, $30, $17, $15, $30, $21, $22, $27, $0F, $27, $27

EndBossPal2Ptr:
LBD4D:  .word EndBossPal2       ;($BD4F)Pointer to palette data below.
EndBossPal2:
LBD4F:  .byte $21, $22, $27, $17, $0C, $30, $07, $15, $30, $21, $27, $15 

;----------------------------------------------------------------------------------------------------

DoIntroGFX:
LBD5B:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LBD5E:  JSR LoadIntroPals       ;($AA99)Load palettes for end fight.
LBD61:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.

LBD64:  LDA #%00001000          ;Set sprite pattern table 1 and nametable 0.
LBD66:  STA PPUControl0         ;

LBD69:  LDA IntroGFXTblPtr+1    ;
LBD6C:  STA DatPntrlUB          ;Point to beginning of data table.
LBD6E:  LDA IntroGFXTblPtr      ;
LBD71:  STA DatPntr1LB          ;

LBD73:  LDA #NT_NAMETBL0_UB     ;
LBD75:  STA PPUAddrUB           ;
LBD77:  STA PPUAddress          ;Set PPU address to nametable 0.
LBD7A:  LDA #NT_NAMETBL0_LB     ;
LBD7C:  STA PPUAddrLB           ;
LBD7E:  STA PPUAddress          ;

IntroGFXLoop:
LBD81:  JSR IntroGFXPtrInc      ;($BDBF)Get nametable data.
LBD84:  CMP #END_TXT_END        ;Check for end of data block indicator.
LBD86:  BEQ ChkNTEnd            ;If found, branch to check if done.
    
LBD88:  CMP #END_RPT            ;Check for repeated data indicator.
LBD8A:  BNE IncToNextByte       ;Branch to skip if not repeating data.

LBD8C:  JSR IntroGFXPtrInc      ;($BDBF)Get number of times to repeat byte.
LBD8F:  STA RepeatCounter       ;Load number of times to repeat data byte.
LBD91:  JSR IntroGFXPtrInc      ;($BDBF)Get nametable data.
LBD94:  STA PPUDataByte         ;Store data byte to display.

LBD96:* JSR LoadGFXAndInc       ;($BDB3)Load byte on to nametable.
LBD99:  DEC RepeatCounter       ;Decrement repeat counter.
LBD9B:  BNE -                   ;Branch if more to repeat.
LBD9D:  BEQ IntroGFXLoop        ;Done repeating. Branch always.

IncToNextByte:
LBD9F:  STA PPUDataByte         ;Load byte into nametable.
LBDA1:  JSR LoadGFXAndInc       ;($BDB3)Load byte and increment pointer.
LBDA4:  JMP IntroGFXLoop        ;Loop to get more data.

ChkNTEnd:
LBDA7:  LDA PPUAddrUB           ;
LBDA9:  CMP #NT_NAMETBL1_UB     ;Check to see if at the end of the nametable.
LBDAB:  BNE IntroGFXLoop        ;If not, branch to load more graphics.

LBDAD:  LDA #%10001000          ;
LBDAF:  STA PPUControl0         ;Turn VBlank interrupt back on and return.
LBDB2:  RTS                     ;

LoadGFXAndInc:
LBDB3:  LDA PPUDataByte         ;Load nametable data into the PPU.
LBDB5:  STA PPUIOReg            ;
LBDB8:  INC PPUAddrLB           ;
LBDBA:  BNE +                   ;Increment to next address.
LBDBC:  INC PPUAddrUB           ;
LBDBE:* RTS                     ;

IntroGFXPtrInc:
LBDBF:  LDY #$00                ;Load nametable data from PRG ROM.
LBDC1:  LDA (DatPntr1),Y        ;
LBDC3:  INC DatPntr1LB          ;
LBDC5:  BNE +                   ;Increment pointer to next data byte.
LBDC7:  INC DatPntrlUB          ;
LBDC9:* RTS                     ;

;----------------------------------------------------------------------------------------------------

IntroGFXTblPtr:
LBDCA:  .word IntroGFXTbl       ;($BDCC)Pointer to beginning of table below.

IntroGFXTbl:
LBDCC:  .byte $F7, $80, $5F, $FC    ;4 rows of blank tiles.
LBDD0:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBDD4:  .byte $F7, $20, $AD, $FC    ;Dragon Warrior graphic starts here.

LBDD8:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBDE8:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBDF8:  .byte $FC

LBDF9:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBE09:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBE19:  .byte $FC

LBE1A:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBE2A:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBE3A:  .byte $FC

LBE3B:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBE4B:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBE5B:  .byte $FC

LBE5C:  .byte $A9, $AA, $A9, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E, $7F, $80
LBE6C:  .byte $81, $82, $83, $84, $85, $86, $85, $86, $87, $88, $89, $8A, $8B, $8C, $A9, $AA
LBE7C:  .byte $FC

LBE7D:  .byte $AB, $AC, $AB, $8D, $8E, $8F, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99
LBE8D:  .byte $9A, $9B, $9C, $9D, $9E, $9F, $9E, $9F, $A0, $A1, $A2, $A3, $AB, $AC, $AB, $AC
LBE9D:  .byte $FC

LBE9E:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A4, $A5, $A9, $A6, $A7, $AA, $A9, $AA, $A9, $AA
LBEAE:  .byte $A9, $A8, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBEBE:  .byte $FC

LBEBF:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBECF:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBEDF:  .byte $FC

LBEE0:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBEF0:  .byte $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA, $A9, $AA
LBF00:  .byte $FC

LBF01:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBF11:  .byte $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC, $AB, $AC
LBF21:  .byte $FC

LBF22:  .byte $F7, $20, $AE, $FC    ;Dragon Warrior graphic ends here.

;----------------------------------------------------------------------------------------------------

LBF26:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.
LBF2A:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBF2E:  .byte $F7, $0A, $5F         ;10 blank tiles.
;              -    P    U    S    H    _    S    T    A    R    T    -
LBF31:  .byte $63, $33, $38, $36, $2B, $5F, $36, $37, $24, $35, $37, $63
LBF3D:  .byte $F7, $0A, $5F, $FC    ;10 blank tiles.

;----------------------------------------------------------------------------------------------------

LBF41:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBF45:  .byte $F7, $0B, $5F         ;11 blank tiles.
;             COPY  1    9    8    6    _    E    N    I    X 
LBF48:  .byte $62, $01, $09, $08, $06, $5F, $28, $31, $2C, $3B
LBF52:  .byte $F7, $0B, $5F, $FC    ;11 blank tiles.

;----------------------------------------------------------------------------------------------------
 
LBF56:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBF5A:  .byte $F7, $0B, $5F         ;11 blank tiles.
;             COPY  1    9    8    9    _    E    N    I    X
LBF5D:  .byte $62, $01, $09, $08, $09, $5F, $28, $31, $2C, $3B
LBF67:  .byte $F7, $0B, $5F, $FC    ;11 blank tiles.

;----------------------------------------------------------------------------------------------------

LBF6B:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBF6F:  .byte $F7, $06, $5F         ;6 blank tiles.
;              L    I    C    E    N    S    E    D    _    T    O    _    N    I    N    T
LBF72:  .byte $2F, $2C, $26, $28, $31, $36, $28, $27, $5F, $37, $32, $5F, $31, $2C, $31, $37
;              E    N    D    O 
LBF82:  .byte $28, $31, $27, $32
LBF86:  .byte $F7, $06, $5F, $FC    ;6 blank tiles.

;----------------------------------------------------------------------------------------------------

LBF8A:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBF8E:  .byte $F7, $04, $5F         ;4 blank tiles.
;              T    M    _    T    R    A    D    E    M    A    R    K    _    T    O    _
LBF91:  .byte $37, $30, $5F, $37, $35, $24, $27, $28, $30, $24, $35, $2E, $5F, $37, $32, $5F
;              N    I    N    T    E    N    D    O
LBFA1:  .byte $31, $2C, $31, $37, $28, $31, $27, $32
LBFA9:  .byte $F7, $04, $5F, $FC    ;4 blank tiles.

;----------------------------------------------------------------------------------------------------

LBFAD:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.
LBFB1:  .byte $F7, $20, $5F, $FC    ;1 row of blank tiles.

;----------------------------------------------------------------------------------------------------

LBFB5:  .byte $F7, $08, $FF, $F7, $08, $05, $F7, $10, $00, $FC      ;1 row of attribute table data.
LBFBF:  .byte $F7, $08, $A5, $F7, $08, $FF, $FC, $F7, $10, $FF, $FC ;1 row of attribute table data.

;----------------------------------------------------------------------------------------------------

;Unused.
LBFCA:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

;----------------------------------------------------------------------------------------------------

NMI:
RESET:
IRQ:
LBFD8:  SEI                     ;Disable interrupts.
LBFD9:  INC MMCReset1           ;Reset MMC1 chip.
LBFDC:  JMP _DoReset            ;($FF8E)Continue with the reset process.

;                   D    R    A    G    O    N    _    W    A    R    R    I    O    R    _
LBFDF:  .byte $80, $44, $52, $41, $47, $4F, $4E, $20, $57, $41, $52, $52, $49, $4F, $52, $20
LBFEF:  .byte $20, $56, $DE, $30, $70, $01, $04, $01, $0F, $07, $00 

LBFFA:  .word NMI               ;($BFD8)NMI vector.
LBFFC:  .word RESET             ;($BFD8)Reset vector.
LBFFE:  .word IRQ               ;($BFD8)IRQ vector.
