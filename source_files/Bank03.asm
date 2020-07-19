.org $C000

.include "Dragon_Warrior_Defines.asm"

;--------------------------------------[ Forward declarations ]--------------------------------------

.alias BankPointers             $8000
.alias UpdateSound              $8028
.alias NPCMobPtrTbl             $9734
.alias NPCStatPtrTbl            $974C
.alias MapEntryDirTbl           $9914
.alias ItemCostTbl              $9947
.alias KeyCostTbl               $9989
.alias InnCostTbl               $998C
.alias ShopItemsTbl             $9991
.alias WeaponsBonusTbl          $99CF
.alias ArmorBonusTbl            $99D7
.alias ShieldBonusTbl           $99DF
.alias BlackPalPtr              $9A18
.alias OverworldPalPtr          $9A1A
.alias TownPalPtr               $9A1C
.alias RedFlashPalPtr           $9A22
.alias RegSPPalPtr              $9A24
.alias SplFlshBGPalPtr          $9A26
.alias BadEndBGPalPtr           $9A28
.alias EnSPPalsPtr              $9A2A
.alias CombatBckgndGFX          $9C8F
.alias SpellCostTbl             $9D53
.alias ClearWinBufRAM2          $A788
.alias RemoveWindow             $A7A2
.alias GetBlockID               $AC17
.alias ModMapBlock              $AD66
.alias MapChngNoFadeOut         $B08D
.alias MapChngNoSound           $B091
.alias MapChngWithSound         $B097
.alias ResumeMusicTbl           $B1AE
.alias ChkSpecialLoc            $B219
.alias CheckMapExit             $B228
.alias DoJoyRight               $B252
.alias PostMoveUpdate           $B30E
.alias DoJoyLeft                $B34C
.alias DoJoyDown                $B3D8
.alias DoJoyUp                  $B504
.alias SprtFacingBaseAddr       $B6C2
.alias DoSprites                $B6DA
.alias DoIntroGFX               $BD5B

;-----------------------------------------[ Start of code ]------------------------------------------

LC000:  JSR $C5E0               ;Not used.
LC003:  JMP $C009               ;

;----------------------------------------------------------------------------------------------------

ModAttribBits:
LC006:  JSR CalcAttribAddr      ;($C5E4)Calculate attribute table address for given nametable byte.

LC009:  TYA                     ;Save the value of Y on the stack.
LC00A:  PHA                     ;

LC00B:  LDA NTYPos              ;
LC00D:  AND #$02                ;
LC00F:  ASL                     ;Load bit shift counter with proper index to bit pair to -->
LC010:  STA GenByte3D           ;change in the attribute table(0, 2, 4 or 6).
LC012:  LDA NTXPos              ;
LC014:  AND #$02                ;
LC016:  CLC                     ;
LC017:  ADC GenByte3D           ;
LC019:  TAY                     ;

LC01A:  LDA #$FC                ;Load bitmask for clearing selected nametable bits.
LC01C:  CPY #$00                ;Is bit counter 0?
LC01E:  BEQ SetAttribBits       ;If so, branch. No need to do any shifting.

AttribLoop:
LC020:  SEC                     ;
LC021:  ROL                     ;This loop shifts the attribute tabe bit pair into position -->
LC022:  ASL PPUDataByte         ;while decrementing the counter.
LC024:  DEY                     ;Do attribute table bits still need to be shifted?
LC025:  BNE AttribLoop          ;If so, branch to shift them 1 more bit.

SetAttribBits:
LC027:  AND (PPUBufPtr),Y       ;
LC029:  ORA PPUDataByte         ;Update the attribute table byte in both the PPU buffer and -->
LC02B:  STA (PPUBufPtr),Y       ;the PPU data byte.
LC02D:  STA PPUDataByte         ;

LC02F:  PLA                     ;
LC030:  TAY                     ;Restore the value of Y from the stack and exit.
LC031:  RTS                     ;

;----------------------------------------------------------------------------------------------------

NPCNewDir:
LC032:  CMP #DIR_UP             ;Is player facing up?
LC034:  BNE ChkPlayerRight      ;If not, branch to check if facing right.
LC036:  LDA #DIR_DOWN           ;Set NPC facing down.
LC038:  RTS                     ;

ChkPlayerRight:
LC039:  CMP #DIR_RIGHT          ;Is player facing right?
LC03B:  BNE ChkPlayerDown       ;If not, branch to check if facing down.
LC03D:  LDA #DIR_LEFT           ;Set NPC facing left.
LC03F:  RTS                     ;

ChkPlayerDown:
LC040:  CMP #DIR_DOWN           ;Is player facing down?
LC042:  BNE PlayerLeft          ;If not, branch. Player must be facing left.
LC044:  LDA #DIR_UP             ;Set NPC facing up.
LC046:  RTS                     ;

PlayerLeft:
LC047:  LDA #DIR_RIGHT          ;Player must be facing left.
LC049:  RTS                     ;Set NPC facing right.

;----------------------------------------------------------------------------------------------------

NPCFacePlayer:
LC04A:  STA NPCNumber           ;Save a copy of the NPC index.
LC04C:  TYA                     ;
LC04D:  PHA                     ;Save a copy of Y and X on the stack.
LC04E:  TXA                     ;
LC04F:  PHA                     ;

LC050:  LDX NPCNumber           ;Get index to NPC data.
LC052:  LDA CharDirection       ;Load player's direction.
LC055:  JSR NPCNewDir           ;($C032)Get direction NPC should face to talk to player.
LC058:  STA NPCNewFace          ;Save value of new NPC's direction.

LC05A:  LSR                     ;
LC05B:  ROR                     ;Move NPC facing bits into the proper location(Bits 5 and 6).
LC05C:  ROR                     ;
LC05D:  ROR                     ;
LC05E:  STA GenByte24           ;Save the bits temporarily.

LC060:  LDA NPCYPos,X           ;
LC062:  AND #$9F                ;Remove existing NPC direction bits.
LC064:  ORA GenByte24           ;OR in the new direction bits.
LC066:  STA NPCYPos,X           ;

LC068:  LDA #$00                ;Need to loop twice. Once for NPCs right next to player -->
LC06A:  STA NPCSpriteCntr       ;and once for NPCs behind counters.

LC06C:  LDY SpriteRAM           ;Get player's Y sprite position.
LC06F:  LDX SpriteRAM+3         ;Get player's X sprite position.

ChkPlyrDirection:
LC072:  LDA CharDirection       ;Is player facing up?
LC075:  BNE ChkPlyrRight        ;If not, branch to check other player directions.

LC077:  TYA                     ;
LC078:  SEC                     ;Player is facing up. Prepare to search for NPC data -->
LC079:  SBC #$10                ;that is above player.
LC07B:  TAY                     ;
LC07C:  JMP CheckNPCPosition    ;

ChkPlyrRight:
LC07F:  CMP #DIR_RIGHT          ;Is player facing right?
LC081:  BNE ChkPlyrDown         ;If not, branch to check other player directions.

LC083:  TXA                     ;
LC084:  CLC                     ;Player is facing right. Prepare to search for NPC data -->
LC085:  ADC #$10                ;that is right of player.
LC087:  TAX                     ;
LC088:  JMP CheckNPCPosition    ;

ChkPlyrDown:
LC08B:  CMP #DIR_DOWN           ;Is player facing down?
LC08D:  BNE PlyrLeft            ;If not, branch. Player must be facing left.

LC08F:  TYA                     ;
LC090:  CLC                     ;Player is facing down. Prepare to search for NPC data -->
LC091:  ADC #$10                ;that is below player.
LC093:  TAY                     ;
LC094:  JMP CheckNPCPosition    ;

PlyrLeft:
LC097:  TXA                     ;
LC098:  SEC                     ;Player is facing left. Prepare to search for NPC data -->
LC099:  SBC #$10                ;that is left of player.
LC09B:  TAX                     ;

CheckNPCPosition:
LC09C:  STX NPCXCheck           ;Save X and Y position data of NPC to change.
LC09E:  STY NPCYCheck           ;

LC0A0:  LDY #$10                ;Prepare to search the NPC sprites for location.

NPCSearchLoop:
LC0A2:  LDA SpriteRAM,Y         ;Has the sprite Y data for the desired NPC been found?
LC0A5:  CMP NPCYCheck           ;
LC0A7:  BNE +                   ;If not, branch to move the the next NPC sprite data.

LC0A9:  LDA SpriteRAM+3,Y       ;Has the sprite X data for the desired NPC been found?
LC0AC:  CMP NPCXCheck           ;
LC0AE:  BEQ NPCFound            ;If not, branch to move the the next NPC sprite data.

LC0B0:* TYA                     ;This is not the sprite data for the desired NPC. -->
LC0B1:  CLC                     ;Move to the next set of NPC sprite data. -->
LC0B2:  ADC #$10                ;4 bytes of data and 4 sprites per NPC = 16 bytes.

LC0B4:  TAY                     ;Has all the sprite data been searched?
LC0B5:  BNE NPCSearchLoop       ;If not, branch to check more sprite data.

LC0B7:  LDX NPCXCheck           ;Reload the NPC X and Y position data.
LC0B9:  LDY NPCYCheck           ;

LC0BB:  LDA NPCSpriteCntr       ;Is this the second time through the search loop?
LC0BD:  BNE NPCDirEnd           ;If so, branch to end. NPC not found.

LC0BF:  LDA #$01                ;Prepare to run the loop a second time.
LC0C1:  STA NPCSpriteCntr       ;
LC0C3:  JMP ChkPlyrDirection    ;($C072)Need to check for NPCs behind counters.

NPCFound:
LC0C6:  STY NPCSprtRAMInd       ;NPC sprites found. Save index to sprites.

LC0C8:  LDA #$04                ;Prepare to process 4 sprites for this NPC.
LC0CA:  STA NPCSpriteCntr       ;

LC0CC:  LDX NPCNumber
LC0CE:  JSR GetNPCSpriteIndex   ;($C0F4)Get index into sprite pattern table for NPC.

LC0D1:  TAY                     ;Load index to NPC ROM data.
LC0D2:  LDA NPCNewFace          ;Get new direction NPC will face.
LC0D4:  JSR SprtFacingBaseAddr  ;($B6C2)Calculate entry into char data table based on direction.
LC0D7:  LDX NPCSprtRAMInd       ;Load sprite RAM index for current NPC sprite.

NPCLoadNxtSprt:
LC0D9:  LDA (GenPtr22),Y        ;Load tile data for NPC sprite.
LC0DB:  STA SpriteRAM+1,X       ;

LC0DE:  INY                     ;
LC0DF:  LDA (GenPtr22),Y        ;Load attribute data for NPC sprite.
LC0E1:  DEY                     ;
LC0E2:  STA SpriteRAM+2,X       ;

LC0E5:  INX                     ;
LC0E6:  INX                     ;Increment to next sprite in sprite RAM.
LC0E7:  INX                     ;
LC0E8:  INX                     ;

LC0E9:  INY                     ;Have 4 sprites been processed for this NPC?
LC0EA:  INY                     ;
LC0EB:  DEC NPCSpriteCntr       ;
LC0ED:  BNE NPCLoadNxtSprt      ;If not, branch to load more sprite data.

NPCDirEnd:
LC0EF:  PLA                     ;
LC0F0:  TAX                     ;
LC0F1:  PLA                     ;Restore X and Y from the stack.
LC0F2:  TAY                     ;
LC0F3:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;3 NPCs types change depending on the map and game flag. Those types are listed below:
;%101 = Wizard or Dragonlord.
;%110 = Princess Gwaelin or Female villager.
;%111 = Stationary guard or Guard with trumpet.
;The following function looks at the map number and game flags to determine which NPC type to use.

GetNPCSpriteIndex:
LC0F4:  LDA NPCXPos,X           ;Get NPC type.
LC0F6:  AND #$E0                ;

LC0F8:  LSR                     ;/2 to get initial offset into sprite pattern table.
LC0F9:  STA GenByte24           ;

ChkFemaleNPC:
LC0FB:  CMP #$60                ;Is this the princess or a female villager?
LC0FD:  BNE ChkWizardNPC        ;If not, branch to check for dragonlord/wizard NPC.

LC0FF:  LDA MapNumber           ;Is the current map the ground floor of Tantagel castle?
LC101:  CMP #MAP_TANTCSTL_GF    ;
LC103:  BNE ChkThroneRoomNPC    ;If not, branch to check next map.

LC105:  LDA StoryFlags          ;Is the dragonlord dead?
LC107:  AND #F_DGNLRD_DEAD      ;
LC109:  BNE SetPrincessNPC      ;If so, branch to get princess NPC sprites.

ChkThroneRoomNPC:
LC10B:  LDA MapNumber           ;Is the current map the throne room?
LC10D:  CMP #MAP_THRONEROOM     ;
LC10F:  BNE NPCWalkAnim         ;If not, branch. Get female villager NPC sprites.

SetPrincessNPC:
LC111:  LDA #$D0                ;Load index to princess sprites.
LC113:  STA GenByte24           ;
LC115:  BNE NPCWalkAnim         ;Branch always.

ChkWizardNPC:
LC117:  LDA GenByte24           ;Is this the dragon lord or wizard NPC?
LC119:  CMP #$50                ;
LC11B:  BNE ChkGuardNPC         ;If not, branch to check for guard type NPC.

LC11D:  LDA MapNumber           ;Is the current map the ground floor of Tantagel castle?
LC11F:  CMP #MAP_TANTCSTL_GF    ;
LC121:  BNE ChkDrgnLordNPC      ;If not, branch to check for dragonlord NPC sprites.

LC123:  LDA StoryFlags;         ;Is the dragonlord dead?
LC125:  AND #F_DGNLRD_DEAD      ;
LC127:  BEQ ChkDrgnLordNPC      ;If not, branch to check for dragonlord NPC sprites.

SetWizardNPC:
LC129:  LDA #$F0                ;Load index to wizard sprites.
LC12B:  STA GenByte24           ;

GetGuardType:
LC12D:  LDA DisplayedLevel      ;
LC12F:  CMP #$FF                ;Has the end of the game just been reached?
LC131:  BNE EndNPCSpclType      ;If so, change guards to guards with trumpets.

LC133:  LDA GenByte24           ;
LC135:  ORA #$08                ;Get offset to guards with trumpets.
LC137:  STA GenByte24           ;
LC139:  BNE EndNPCSpclType      ;Branch always.

ChkDrgnLordNPC:
LC13B:  LDA MapNumber           ;Is the current map the basement of the dragonlord's castle?
LC13D:  CMP #MAP_DLCSTL_BF      ;
LC13F:  BNE NPCWalkAnim         ;If not, branch. Get wizard NPC sprites.

SetDgnLordNPC:
LC141:  LDA #$E0                ;Load index to dragonlord sprites.
LC143:  STA GenByte24           ;
LC145:  BNE NPCWalkAnim         ;Branch always.

ChkGuardNPC:
LC147:  CMP #$70                ;Is this a guard NPC?
LC149:  BEQ GetGuardType        ;If so, branch to see if its a trumpet guard.

NPCWalkAnim:
LC14B:  LDA CharLeftRight       ;
LC14D:  AND #$08                ;Add the offset for left or right walking version of NPC.
LC14F:  ORA GenByte24           ;
LC151:  STA GenByte24           ;

EndNPCSpclType:
LC153:  LDA GenByte24           ;Transfer final offset to A.
LC155:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetPlayerStatPtr:
LC156:  LDX #$3A                ;Start at level 30 and point to the end of LevelUpTbl.
LC158:  LDA #LVL_30             ;Work backwards to find the proper level.
LC15A:  STA DisplayedLevel      ;

PlayerStatLoop:
LC15C:  LDA ExpLB               ;
LC15E:  SEC                     ;Subtract entries in LevelUpTbl from player's current exp.
LC15F:  SBC LevelUpTbl,X        ;
LC162:  LDA ExpUB               ;
LC164:  SBC LevelUpTbl+1,X      ;Has the correct level for the player been found?
LC167:  BCS PlayerStatEnd       ;If so, branch to the exit.

LC169:  DEC DisplayedLevel      ;Move down to the next level and stats table entry.
LC16B:  DEX                     ;
LC16C:  DEX                     ;Are there more levels to descend through?
LC16D:  BNE PlayerStatLoop      ;If so, loop to check next level down.

PlayerStatEnd:
LC16F:  RTS                     ;End get player stats function.

;----------------------------------------------------------------------------------------------------

WaitMultiNMIs:
LC170:  STA GenByte24           ;Save number of frames to wait.
LC172:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC175:  DEC GenByte24           ;Have the defined number of frames passed?
LC177:  BPL -                   ;If not, branch to wait another frame.
LC179:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearPPU:
LC17A:  PHA                     ;
LC17B:  TXA                     ;
LC17C:  PHA                     ;Save A, X and Y.
LC17D:  TYA                     ;
LC17E:  PHA                     ;

LC17F:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC182:  LDA #%00001000          ;Turn off VBlank interrupt.
LC184:  STA PPUControl0         ;

LC187:  LDA #TL_BLANK_TILE1     ;Fill both nametables with blank tiles.
LC189:  STA PPUDataByte         ;

LC18B:  LDA PPUStatus           ;Reset address latch.

LC18E:  LDA #NT_NAMETBL0_UB     ;
LC190:  STA PPUAddress          ;Set address to start of nametable 0.
LC193:  LDA #NT_NAMETBL0_LB     ;
LC195:  STA PPUAddress          ;

LC198:  JSR ClearNameTable      ;($C1B9)Write #$5F to nametable 0.

LC19B:  LDA PPUStatus           ;Reset address latch.

LC19E:  LDA #NT_NAMETBL1_UB     ;
LC1A0:  STA PPUAddress          ;Set address to start of nametable 1.
LC1A3:  LDA #NT_NAMETBL1_LB     ;
LC1A5:  STA PPUAddress          ;

LC1A8:  JSR ClearNameTable      ;($C1B9)Write #$5F to nametable 1.

LC1AB:  LDA #%10001000          ;Turn on VBlank interrupt.
LC1AD:  STA PPUControl0         ;

LC1B0:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LC1B3:  PLA                     ;
LC1B4:  TAY                     ;
LC1B5:  PLA                     ;Restore A, X and Y.
LC1B6:  TAX                     ;
LC1B7:  PLA                     ;
LC1B8:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearNameTable:
LC1B9:  LDA PPUDataByte         ;
LC1BB:  LDX #$1E                ;
LC1BD:* LDY #$20                ;
LC1BF:* STA PPUIOReg            ;
LC1C2:  DEY                     ;Load a blank tile into every address of selected nametable.
LC1C3:  BNE -                   ;
LC1C5:  DEX                     ;
LC1C6:  BNE --                  ;
LC1C8:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WordMultiply:
LC1C9:  LDA #$00                ;
LC1CB:  STA MultRsltLB          ;Clear results variables.
LC1CD:  STA MultRsltUB          ;

MultiplyLoop:
LC1CF:  LDA MultNum1LB          ;
LC1D1:  ORA MultNum1UB          ;
LC1D3:  BEQ ++                  ;
LC1D5:  LSR MultNum1UB          ;
LC1D7:  ROR MultNum1LB          ;This function multiplies the two-->
LC1D9:  BCC +                   ;16-bit numbers stored in $3C,$3D-->
LC1DB:  LDA MultNum2LB          ;and $3E, $3F and stores the results-->
LC1DD:  CLC                     ;in $40,$41.
LC1DE:  ADC MultRsltLB          ;
LC1E0:  STA MultRsltLB          ;
LC1E2:  LDA MultNum2UB          ;
LC1E4:  ADC MultRsltUB          ;
LC1E6:  STA MultRsltUB          ;
LC1E8:* ASL MultNum2LB          ;
LC1EA:  ROL MultNum2UB          ;
LC1EC:  JMP MultiplyLoop        ;
LC1EF:* RTS

;----------------------------------------------------------------------------------------------------

ByteDivide:
LC1F0:  LDA #$00                ;Set upper byte of dividend to 0-->
LC1F2:  STA DivNmu1UB           ;When only doing 8-bit division.

WordDivide:
LC1F4:  LDY #$10                ;
LC1F6:  LDA #$00                ;
LC1F8:* ASL DivNum1LB           ;
LC1FA:  ROL DivNmu1UB           ;
LC1FC:  STA DivRemainder        ;
LC1FE:  ADC DivRemainder        ;
LC200:  INC DivQuotient         ;This function takes a 16-bit dividend-->
LC202:  SEC                     ;stored in $3C,$3D and divides it by-->
LC203:  SBC DivNum2             ;an 8-bit number stored in $3E.
LC205:  BCS +                   ;
LC207:  CLC                     ;The 8-bit quotient is stored in $3C and-->
LC208:  ADC DivNum2             ;the 8-bit remainder is stored in $40.
LC20A:  DEC DivQuotient         ;
LC20C:* DEY                     ;
LC20D:  BNE --                  ;
LC20F:  STA DivRemainder        ;
LC211:  RTS                     ;

;----------------------------------------------------------------------------------------------------

PalFadeOut:
LC212:  LDA #$00                ;Start at brightest palette.
LC214:  STA PalModByte          ;

FadeOutLoop:
LC216:  LDX #$04                ;Prepare to wait for 4 frames.
LC218:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC21B:  DEX                     ;
LC21C:  BNE -                   ;Has 4 frames elapsed? If not, branch to wait another frame.

LC21E:  LDA SprtPalPtrLB        ;
LC220:  STA PalPtrLB            ;Load sprite palette pointers.
LC222:  LDA SprtPalPtrUB        ;
LC224:  STA PalPtrUB            ;
LC226:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.

LC229:  LDA LoadBGPal           ;Is background palette supposed to change?
LC22B:  BEQ +                   ;If not, branch to skip.

LC22D:  LDA BGPalPtrLB          ;
LC22F:  STA PalPtrLB            ;Load background palette pointers.
LC231:  LDA BGPalPtrUB          ;
LC233:  STA PalPtrUB            ;
LC235:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer

LC238:* LDA PalModByte          ;
LC23A:  CLC                     ;Move to next palette.
LC23B:  ADC #$10                ;
LC23D:  STA PalModByte          ;

LC23F:  CMP #$50                ;Has the fade out effect completed?
LC241:  BNE FadeOutLoop         ;If not, branch to load the next palette in the sequence.
LC243:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearAttribByte:
LC244:  LDA NTBlockX            ;Get the offset for the current block in the nametable row.
LC246:  ASL                     ;*2. 2 tiles per block.
LC247:  CLC                     ;
LC248:  ADC XPosFromCenter      ;Pow position of tile(0-63).
LC24A:  AND #$3F                ;Max. 64 tiles in a row spanning the 2 nametables.
LC24C:  PHA                     ;Save row position on the stack.

LC24D:  LDA NTBlockY            ;Get the offset for the current block in the nametable column.
LC24F:  ASL                     ;*2. 2 tiles per block.
LC250:  CLC                     ;
LC251:  ADC YPosFromCenter      ;Column position(0-30).
LC253:  CLC                     ;
LC254:  ADC #$1E                ;Ensure dividend is positive since YPosFromCenter is signed.

LC256:  STA DivNum1LB           ;
LC258:  LDA #$1E                ;Divide by 30 to get proper nametable row to update.
LC25A:  STA DivNum2             ;
LC25C:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.

LC25F:  LDA DivRemainder        ;
LC261:  STA NTYPos              ;Store column position.
LC263:  PLA                     ;Restore A from stack.

LC264:  STA NTXPos              ;Store row position.
LC266:  JSR PrepClearAttrib     ;($C270)Calculate attribute table byte for blanking tiles.
LC269:  RTS

LC26A:  JSR $C5E0               ;Not used.
LC26D:  JMP ClearAttrib         ;($C273)Set black palette for given tiles.

PrepClearAttrib:
LC270:  JSR CalcAttribAddr      ;($C5E4)Calculate attribute table address for given nametable byte.

ClearAttrib:
LC273:  TYA                     ;Save Y to stack.
LC274:  PHA                     ;

LC275:  LDY #$00                ;
LC277:  LDA (PPUBufPtr),Y       ;Clear calculated attribute table byte.
LC279:  STA PPUDataByte         ;

LC27B:  PLA                     ;Restore Y from the stack.
LC27C:  TAY                     ;

LC27D:  LDA PPUAddrUB           ;
LC27F:  CLC                     ;Add in upper nibble of upper address byte.
LC280:  ADC #$20                ;
LC282:  STA PPUAddrUB           ;

LC284:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LC287:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;This section appears to be unused code from Dragon Quest.

LC288: .byte $20, $74, $FF, $20, $97, $C2, $E6, $99, $D0, $F9, $E6, $9A, $4C, $8B, $C2, $A5
LC298: .byte $D6, $F0, $0B, $C6, $D6, $A5, $99, $C6, $99, $A8, $D0, $02, $C6, $9A, $A0, $00
LC2A8: .byte $B1, $99, $C9, $F7, $D0, $13, $C8, $B1, $99, $85, $D6, $A5, $99, $18, $69, $03
LC2B8: .byte $85, $99, $90, $02, $E6, $9A, $4C, $97, $C2, $C9, $FF, $F0, $31, $C9, $FC, $D0
LC2C8: .byte $30, $A5, $0C, $18, $69, $40, $85, $0C, $85, $42, $A5, $0D, $69, $00, $85, $0D
LC2D8: .byte $85, $43, $A5, $9D, $85, $97, $E6, $98, $E6, $98, $A5, $98, $C9, $1E, $D0, $06
LC2E8: .byte $A9, $00, $85, $98, $F0, $08, $C9, $1F, $D0, $04, $A9, $01, $85, $98, $68, $68
LC2F8: .byte $60, $C9, $FE, $D0, $03, $20, $C9, $C2, $C9, $FB, $D0, $25, $A5, $E5, $0A, $0A
LC308: .byte $0A, $85, $3C, $0A, $65, $3C, $69, $03, $AA, $A9, $01, $85, $02, $A5, $02, $20
LC318: .byte $74, $FF, $D0, $F9, $20, $08, $C6, $A5, $47, $29, $08, $D0, $EC, $CA, $D0, $E9
LC328: .byte $60, $C9, $FD, $D0, $13, $A5, $99, $85, $9B, $A5, $9A, $85, $9C, $A9, $A3, $85
LC338: .byte $99, $A9, $00, $85, $9A, $4C, $74, $C4, $C9, $FA, $D0, $09, $A5, $9B, $85, $99
LC348: .byte $A5, $9C, $85, $9A, $60, $C9, $F0, $D0, $31, $C8, $B1, $99, $85, $3E, $C8, $B1
LC358: .byte $99, $85, $3F, $98, $48, $A0, $00, $84, $3D, $B1, $3E, $85, $3C, $68, $A8, $20
LC368: .byte $C9, $C6, $A5, $99, $18, $69, $02, $85, $9B, $A5, $9A, $69, $00, $85, $9C, $A9
LC378: .byte $00, $85, $9A, $A9, $B1, $85, $99, $4C, $74, $C4, $C9, $F1, $D0, $38, $20, $8C
LC388: .byte $C3, $4C, $74, $C4, $C8, $B1, $99, $85, $3E, $C8, $B1, $99, $85, $3F, $98, $48
LC398: .byte $A0, $00, $B1, $3E, $85, $3C, $C8, $B1, $3E, $85, $3D, $68, $A8, $20, $C9, $C6
LC3A8: .byte $A5, $99, $18, $69, $02, $85, $9B, $A5, $9A, $69, $00, $85, $9C, $A9, $00, $85
LC3B8: .byte $9A, $A9, $AF, $85, $99, $60, $C9, $F3, $D0, $13, $20, $8C, $C3, $A0, $00, $B1
LC3C8: .byte $99, $C9, $5F, $D0, $05, $E6, $99, $4C, $C7, $C3, $4C, $74, $C4, $C9, $F2, $D0
LC3D8: .byte $13, $A5, $99, $85, $9B, $A5, $9A, $85, $9C, $A9, $00, $85, $9A, $A9, $B5, $85
LC3E8: .byte $99, $4C, $74, $C4, $C9, $6D, $90, $3D, $E9, $6D, $AA, $E8, $AD, $50, $F1, $85
LC3F8: .byte $3C, $AD, $51, $F1, $85, $3D, $A0, $00, $B1, $3C, $C9, $FA, $F0, $04, $C8, $4C
LC408: .byte $00, $C4, $CA, $F0, $0D, $98, $38, $65, $3C, $85, $3C, $90, $02, $E6, $3D, $4C
LC418: .byte $FE, $C3, $A5, $99, $85, $9B, $A5, $9A, $85, $9C, $A5, $3C, $85, $99, $A5, $3D
LC428: .byte $85, $9A, $4C, $74, $C4, $C9, $57, $F0, $03, $4C, $74, $C4, $A5, $D4, $18, $69
LC438: .byte $09, $29, $3F, $85, $97, $A9, $00, $85, $4F, $20, $08, $C6, $A5, $47, $29, $03
LC448: .byte $F0, $04, $A9, $5F, $D0, $08, $A5, $4F, $29, $10, $D0, $F6, $A9, $57, $85, $08
LC458: .byte $20, $74, $FF, $20, $F5, $C4, $20, $90, $C6, $A5, $47, $29, $03, $F0, $DA, $A9
LC468: .byte $85, $00, $04, $17, $A5, $D4, $85, $97, $20, $EC, $C7, $60, $A0, $00, $B1, $99
LC478: .byte $85, $08, $A5, $09, $F0, $08, $C9, $01, $F0, $04, $A5, $08, $91, $42, $20, $F5
LC488: .byte $C4, $20, $90, $C6, $A0, $01, $B1, $99, $C9, $F8, $F0, $0A, $C9, $F9, $D0, $52
LC498: .byte $A9, $52, $85, $08, $D0, $04, $A9, $51, $85, $08, $E6, $99, $D0, $02, $E6, $9A
LC4A8: .byte $A5, $42, $18, $69, $E0, $85, $42, $B0, $02, $C6, $43, $A5, $09, $F0, $0A, $C9
LC4B8: .byte $01, $F0, $06, $A5, $08, $A0, $00, $91, $42, $A5, $42, $18, $69, $20, $85, $42
LC4C8: .byte $90, $02, $E6, $43, $C6, $98, $A5, $98, $C9, $FF, $D0, $04, $A9, $1D, $85, $98
LC4D8: .byte $20, $F5, $C4, $20, $90, $C6, $E6, $98, $A5, $98, $C9, $1E, $D0, $04, $A9, $00
LC4E8: .byte $85, $98, $E6, $42, $E6, $97, $A5, $97, $29, $3F, $85, $97, $60, $A5, $08, $48
LC4F8: .byte $A5, $09, $C9, $01, $F0, $1C, $A5, $98, $4A, $B0, $17, $A5, $97, $4A, $B0, $12
LC508: .byte $A5, $97, $85, $3C, $A5, $98, $85, $3E, $A9, $00, $85, $08, $20, $06, $C0, $20
LC518: .byte $73, $C2, $68, $85, $08, $A5, $97, $85, $3C, $A5, $98, $85, $3E, $20, $AA, $C5
LC528: .byte $60

;----------------------------------------------------------------------------------------------------

PalFadeIn:
LC529:  LDA #$30                ;Prepare to switch through 4 different palettes.
LC52B:  STA PalModByte          ;This will create a screen fade in effect.

FadeInLoop:
LC52D:  LDX #$04                ;Prepare to pause for 4 frames.
LC52F:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC532:  DEX                     ;Have 4 frames passed?
LC533:  BNE -                   ;If not, branch to wait another frame.

LC535:  LDA SprtPalPtrLB        ;
LC537:  STA PalPtrLB            ;Load base address of desired sprite palette data.
LC539:  LDA SprtPalPtrUB        ;
LC53B:  STA PalPtrUB            ;
LC53D:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.

LC540:  LDA LoadBGPal           ;Does background need to be faded in?
LC542:  BEQ +                   ;If not, branch to skip.

LC544:  LDA BGPalPtrLB          ;
LC546:  STA PalPtrLB            ;Load base address of desired background palette data.
LC548:  LDA BGPalPtrUB          ;
LC54A:  STA PalPtrUB            ;
LC54C:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer

LC54F:* LDA PalModByte          ;
LC551:  SEC                     ;Decrement palette fade in counter.
LC552:  SBC #$10                ;
LC554:  STA PalModByte          ;

LC556:  CMP #$F0                ;Is fade in complete?
LC558:  BNE FadeInLoop          ;If not, branch to continue fade in routine.
LC55A:  RTS                     ;

;----------------------------------------------------------------------------------------------------

UpdateRandNum:
LC55B:  LDA RandNumUB           ;
LC55D:  STA GenWord3CUB         ;
LC55F:  LDA RandNumLB           ;
LC561:  STA GenWord3CLB         ;
LC563:  ASL RandNumLB           ;
LC565:  ROL RandNumUB           ;
LC567:  CLC                     ;
LC568:  ADC RandNumLB           ;
LC56A:  STA RandNumLB           ;
LC56C:  LDA RandNumUB           ;
LC56E:  ADC GenWord3CUB         ;
LC570:  STA RandNumUB           ;Update the random number word.
LC572:  LDA RandNumLB           ;
LC574:  CLC                     ;
LC575:  ADC RandNumUB           ;
LC577:  STA RandNumUB           ;
LC579:  LDA RandNumLB           ;
LC57B:  CLC                     ;
LC57C:  ADC #$81                ;
LC57E:  STA RandNumLB           ;
LC580:  LDA RandNumUB           ;
LC582:  ADC #$00                ;
LC584:  STA RandNumUB           ;
LC586:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WaitForPPUBufSpace:
LC587:  STA GenByte24           ;Save max number bytes that can be used in PPU buffer.

WaitForPPUBufLoop:
LC589:  LDA PPUBufCount         ;Is the used space below the max used space?
LC58B:  CMP GenByte24           ;
LC58D:  BCC WaitForPPUBufEnd    ;If so, branch to end. Done waiting for space.
LC58F:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC592:  JMP WaitForPPUBufLoop   ;($C589)Loop until PPU buffer has enough empty space.

WaitForPPUBufEnd:
LC595:  RTS                     ;Buffer is free. Stop waiting.

;----------------------------------------------------------------------------------------------------

CalcPPUBufAddr:
LC596:  LDA #$40                ;Indicate data is being saved to PPU address buffer.
LC598:  ORA XPosFromLeft        ;
LC59A:  STA XPosFromLeft        ;Set bit 6 to determine target later.
LC59C:  BNE Block2TileConv      ;Branch always.

CalcRAMBufAddr:
LC59E:  LDA #$80                ;Indicate data is being saved to RAM buffer.
LC5A0:  ORA XPosFromLeft        ;
LC5A2:  STA XPosFromLeft        ;Set MSB to determine target later.
LC5A4:  BNE DoAddrCalc          ;Branch always.

Block2TileConv:
LC5A6:  ASL XPosFromLeft        ;*2. Blocks are 2 tiles wide. 
LC5A8:  ASL YPosFromTop         ;*2. Blocks are 2 tiles tall.

DoAddrCalc:
LC5AA:  LDA YPosFromTop         ;Put Y position in upper address byte.  This is 8 times the-->
LC5AC:  STA PPUBufPtrUB         ;address of the proper row needed so divide it down next.-->
LC5AE:  LDA #$00                ;This saves from having to do the multiplication routine-->
LC5B0:  STA PPUBufPtrLB         ;and is faster than shifting up into position.

LC5B2:  LSR PPUBufPtrUB         ;
LC5B4:  ROR PPUBufPtrLB         ;
LC5B6:  LSR PPUBufPtrUB         ;Divide address by 8.
LC5B8:  ROR PPUBufPtrLB         ;
LC5BA:  LSR PPUBufPtrUB         ;
LC5BC:  ROR PPUBufPtrLB         ;

LC5BE:  LDA XPosFromLeft        ;
LC5C0:  AND #$1F                ;Keep only lower 5 bits and add it to the addres-->
LC5C2:  CLC                     ;to get the proper offset in the current row.
LC5C3:  ADC PPUBufPtrLB         ;
LC5C5:  STA PPUBufPtrLB         ;

LC5C7:  PHP                     ;Save processor status on stack.

LC5C8:  LDA XPosFromLeft        ;Is data being saved to the RAM buffer?
LC5CA:  BPL +                   ;If not, branch.

LC5CC:  LDA #$04                ;Set upper byte or RAM buffer address.
LC5CE:  BNE EndPPUCalcAddr      ;Branch always.

LC5D0:* AND #$20                ;Is data being written to nametable 1?
LC5D2:  BNE +                   ;If so, branch.

LC5D4:  LDA #NT_NAMETBL0_UB     ;Load upper address byte of nametable 0.
LC5D6:  BNE EndPPUCalcAddr      ;Branch always.

LC5D8:* LDA #NT_NAMETBL1_UB     ;Load upper address byte of namteable 1.

EndPPUCalcAddr:
LC5DA:  PLP                     ;Restore processor status from stack.

LC5DB:  ADC PPUAddrUB           ;
LC5DD:  STA PPUAddrUB           ;Save proper PPU upper address byte and exit.
LC5DF:  RTS                     ;

;----------------------------------------------------------------------------------------------------

LC5E0:  ASL NTXPos              ;Not used.
LC5E2:  ASL NTYPos              ;

CalcAttribAddr:
LC5E4:  LDA NTYPos              ;Drop lower 2 bytes and multiply by 2. -->
LC5E6:  AND #$FC                ;Attribute table byte controls 4x4 tile square.
LC5E8:  ASL                     ;
LC5E9:  STA PPUAddrLB           ;

LC5EB:  LDA NTXPos              ;
LC5ED:  AND #$1F                ;Do not exceed 32 tiles in the row.
LC5EF:  LSR                     ;
LC5F0:  LSR                     ;/4. 1 byte of attrib. table controls 4x4 tile square.
LC5F1:  CLC                     ;
LC5F2:  ADC PPUAddrLB           ;Add X offset to calculation.
LC5F4:  CLC                     ;
LC5F5:  ADC #$C0                ;Offset to attribute table at $23C0 or $27C0. Lower byte now -->
LC5F7:  STA PPUAddrLB           ;contains proper address to corresponding attribute table address.

LC5F9:  LDA NTXPos              ;Are we currently on nametable 0?
LC5FB:  AND #$20                ;
LC5FD:  BNE +                   ;If not, branch to use address for nametable 1.

LC5FF:  LDA #$03                ;Lower nibble of upper byte(attribute table for nametable 0).
LC601:  BNE ExitAttribCalc      ;Branch always.

LC603:* LDA #$07                ;Lower nibble of upper byte(attribute table for nametable 1).

ExitAttribCalc:
LC605:  STA PPUAddrUB           ;Store calculated upper byte.
LC607:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetJoypadStatus:
LC608:  LDA GenByte3C           ;
LC60A:  PHA                     ;Prepare to update the random number by first saving registers -->
LC60B:  LDA GenByte3D           ;that are affected by the random number calculationa.
LC60D:  PHA                     ;

LC60E:  JSR UpdateRandNum       ;($C55B)Get random number.

LC611:  PLA                     ;
LC612:  STA GenByte3D           ;Restore the registers affected by random number calculations.
LC614:  PLA                     ;
LC615:  STA GenByte3C           ;

LC617:  LDA #$01                ;
LC619:  STA CPUJoyPad1          ;Reset controller port 1 in preparation for 8 reads.
LC61C:  LDA #$00                ;
LC61E:  STA CPUJoyPad1          ;

LC621:  LDY #$08                ;Prepare to read 8 bits from controller port 1.

JoypadReadLoop:
LC623:  LDA CPUJoyPad1          ;Read joypad bit from controller hardwars.
LC626:  STA JoypadBit           ;
LC628:  LSR                     ;
LC629:  ORA JoypadBit           ;Read the Famicom expansion bit(not used by NES).
LC62B:  LSR                     ;
LC62C:  ROR JoypadBtns          ;Rotate bit into the joypad status register.
LC62E:  DEY                     ;Have 8 bits been read from the controller?
LC62F:  BNE JoypadReadLoop      ;If not, branch to get another bit.

LC631:  RTS                     ;Done reading the controller bits.

;----------------------------------------------------------------------------------------------------

PrepSPPalLoad:
LC632:  LDA #$31                ;Max. 48 buffer spots can be used.
LC634:  JSR WaitForPPUBufSpace  ;($C587)Wait for space in PPU buffer.

LC637:  LDA #PAL_SPR_LB         ;Sprite palettes start at address $3F10.
LC639:  STA PPUAddrLB           ;
LC63B:  BNE LoadPalData         ;Branch always.

PrepBGPalLoad:
LC63D:  LDA #$61                ;Max. 96 buffer spots can be used.
LC63F:  JSR WaitForPPUBufSpace  ;($C587)Wait for space in PPU buffer.

LC642:  LDA #PAL_BKG_LB         ;Background palettes start at address $3F00.
LC644:  STA PPUAddrLB           ;

LoadPalData:
LC646:  LDA #PAL_UB             ;Upper byte of palette addresses are all $3F.
LC648:  STA PPUAddrUB           ;

LC64A:  LDY #$00                ;Prepare to add color data to 4 palettes.

PalDataLoop:
LC64C:  LDA #PAL_BLACK          ;First color of every palette is always black.
LC64E:  STA PPUDataByte         ;

LC650:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LC653:  JSR AddPalByte          ;($C661)Add a byte of palette data to the PPU buffer.
LC656:  JSR AddPalByte          ;($C661)Add a byte of palette data to the PPU buffer.
LC659:  JSR AddPalByte          ;($C661)Add a byte of palette data to the PPU buffer.
LC65C:  CPY #$0C                ;Have all the palettes been processed?
LC65E:  BNE PalDataLoop         ;If not, branch to add color data to another palette.
LC660:  RTS                     ;

AddPalByte:
LC661:  LDA PPUAddrLB           ;Is this the palette color used for text box borders?
LC663:  CMP #$01                ;
LC665:  BEQ ChkLowHPPal         ;If so, branch to see if HP is low for special color.

LC667:  CMP #$03                ;Is this the third palette color?
LC669:  BNE ChkPalFade          ;If not, branch to move on.

LC66B:  LDA EnNumber            ;Is player fighting the final boss?
LC66D:  CMP #EN_DRAGONLORD2     ;If not, branch to move on.
LC66F:  BNE ChkPalFade          ;Maybe this was used for a special palette no longer in the game?

ChkLowHPPal:
LC671:  LDA DisplayedMaxHP      ;
LC673:  LSR                     ;
LC674:  LSR                     ;Is player's health less than 1/8 of max HP?
LC675:  CLC                     ;If so, load red palette color instead of white.
LC676:  ADC #$01                ;
LC678:  CMP HitPoints           ;
LC67A:  BCC ChkPalFade          ;

LC67C:  LDA #$26                ;Load red palette color for low health.
LC67E:  BNE +                   ;

ChkPalFade:
LC680:  LDA (PalPtrLB),Y        ;Get current palette color.

LC682:* SEC                     ;If fade in/fade out is currently active, subtract the-->
LC683:  SBC PalModByte          ;current fade offset value from color to make it darker.
LC685:  BCS +                   ;

LC687:  LDA #PAL_BLACK          ;Fully faded out. Set all palette colors to black.

LC689:* STA PPUDataByte         ;Save final palette color.
LC68B:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LC68E:  INY                     ;Move to next palette byte.
LC68F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

AddPPUBufEntry:
LC690:  LDX PPUBufCount         ;
LC692:  CPX #$B0                ;Is the PPU buffer full?
LC694:  BCC PutPPUBufDat        ;If not, branch to add data to the PPU buffer.

LC696:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC699:  JMP AddPPUBufEntry      ;Loop until buffer has room.

PutPPUBufDat:
LC69C:  LDX PPUBufCount         ;Copy PPU buffer count to X
LC69E:  LDA PPUAddrUB           ;
LC6A0:  STA BlockRAM,X          ;Add upper byte of PPU target address to buffer.
LC6A3:  INX                     ;
LC6A4:  LDA PPUAddrLB           ;
LC6A6:  STA BlockRAM,X          ;Add lower byte of PPU target address to buffer.
LC6A9:  INX                     ;
LC6AA:  LDA PPUDataByte         ;
LC6AC:  STA BlockRAM,X          ;Add data byte to write to PPU to the buffer.
LC6AF:  INX                     ;

LC6B0:  INC PPUEntCount         ;Increase PPU buffer entries by 1(3 bytes per entry).
LC6B2:  STX PPUBufCount         ;Increase buffer count by 3 bytes.

LC6B4:  INC PPUAddrLB           ;
LC6B6:  BNE +                   ;Increment PPU target address.
LC6B8:  INC PPUAddrUB           ;
LC6BA:* RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearSpriteRAM:
LC6BB:  JSR WaitForNMI          ;($FF74)Wait for VBlank.
LC6BE:  LDX #$00                ;
LC6C0:  LDA #$F0                ;
LC6C2:* STA SpriteRAM,X         ;Clear 256 bytes of sprite RAM.
LC6C5:  INX                     ;
LC6C6:  BNE -                   ;
LC6C8:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;The following functions do not appear to be used. Functions from Dragon Quest.

DQFunc04:
LC6C9:  .byte $A2, $00, $A9, $5F, $95, $AF, $E8, $E0, $05, $D0, $F9, $A9, $FA, $95, $AF, $CA
LC6D9:  .byte $A9, $0A, $85, $3E, $A9, $00, $85, $3F, $20, $F4, $C1, $A5, $40, $95, $AF, $CA
LC6E9:  .byte $A5, $3C, $05, $3D, $D0, $EA, $60

;----------------------------------------------------------------------------------------------------

DoWindow:
LC6F0:  PLA                     ;
LC6F1:  CLC                     ;
LC6F2:  ADC #$01                ;
LC6F4:  STA GenPtr3ELB          ;
LC6F6:  PLA                     ;Get return address from stack and increment it.
LC6F7:  ADC #$00                ;The new return address skips the window data byte.
LC6F9:  STA GenPtr3EUB          ;
LC6FB:  PHA                     ;
LC6FC:  LDA GenPtr3ELB          ;
LC6FE:  PHA                     ;

LC6FF:  LDY #$00                ;Put window data byte in the accumulator.
LC701:  LDA (GenPtr3E),Y        ;

_DoWindow:
LC703:  BRK                     ;Display a window.
LC704:  .byte $10, $17          ;($A194)ShowWindow, bank 1.
LC706:  RTS                     ;

;----------------------------------------------------------------------------------------------------

AddBlocksToScreen:
LC707:  LDA BlockClear          ;Will always be 0.
LC709:  BNE BlankBlock          ;Branch never.

LC70B:  LDY #$00                ;
LC70D:  LDA (BlockAddr),Y       ;Is the block data blank?
LC70F:  CMP #$FF                ;
LC711:  BEQ BlankBlock          ;If so, branch.

LC713:  CMP #$FE                ;Is the block data blank?
LC715:  BEQ BlankBlock          ;If so, branch.

LC717:  JMP BattleBlock         ;Branch always.

;This portion of code should never run under normal circumstances.

BlankBlock:
LC71A:  LDA #$00                ;
LC71C:  STA BlkRemoveFlgs       ;Remove no tiles from the current block.
LC71E:  STA PPUHorzVert         ;PPU column write.

LC720:  JSR ModMapBlock         ;($AD66)Change block on map.

LC723:  LDY #$00                ;Prepare to clear the block data.
LC725:  LDA #$FF

LC727:  STA (BlockAddr),Y       ;
LC729:  INY                     ;Clear top row of block.
LC72A:  STA (BlockAddr),Y       ;

LC72C:  LDY #$20                ;Move to next row in block.

LC72E:  STA (BlockAddr),Y       ;
LC730:  INY                     ;Clear bottom row of block.
LC731:  STA (BlockAddr),Y       ;
LC733:  RTS                     ;

BattleBlock:
LC734:  LDA NTBlockY            ;
LC736:  ASL                     ;
LC737:  ADC YPosFromCenter      ;Get the target tile Y position and convert from a -->
LC739:  CLC                     ;signed value to an unsigned value and store the results.
LC73A:  ADC #$1E                ;
LC73C:  STA DivNum1LB           ;
LC73E:  LDA #$1E                ;
LC740:  STA DivNum2             ;
LC742:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LC745:  LDA DivRemainder        ;
LC747:  STA YPosFromTop         ;
LC749:  STA YFromTopTemp        ;

LC74B:  LDA NTBlockX            ;
LC74D:  ASL                     ;
LC74E:  CLC                     ;Get the target tile X position and convert from a -->
LC74F:  ADC XPosFromCenter      ;signed value to an unsigned value and store the results.
LC751:  AND #$3F                ;
LC753:  STA XPosFromLeft        ;
LC755:  STA XFromLeftTemp       ;
LC757:  JSR DoAddrCalc          ;($C5AA)Calculate destination address for GFX data.

LC75A:  LDY #$00                ;Zero out index.

LC75C:  LDA (BlockAddr),Y       ;Get upper left tile of block.
LC75E:  STA PPUDataByte         ;
LC760:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LC763:  INY                     ;Move to next tile.

LC764:  LDA (BlockAddr),Y       ;Get upper right tile of block.
LC766:  STA PPUDataByte         ;
LC768:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LC76B:  LDA PPUAddrLB           ;
LC76D:  CLC                     ;
LC76E:  ADC #$1E                ;Move to the next row of the block.
LC770:  STA PPUAddrLB           ;
LC772:  BCC +                   ;
LC774:  INC PPUAddrUB           ;

LC776:* LDY #$20                ;Move to next tile in next row down.

LC778:  LDA (BlockAddr),Y       ;Get lower left tile of block.
LC77A:  STA PPUDataByte         ;
LC77C:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LC77F:  INY                     ;Move to next tile.

LC780:  LDA (BlockAddr),Y       ;Get lower right tile of block.
LC782:  STA PPUDataByte         ;
LC784:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LC787:  LDA XFromLeftTemp       ;
LC789:  STA XPosFromLeft        ;Restore the X and Y position variables.
LC78B:  LDA YFromTopTemp        ;
LC78D:  STA YPosFromTop         ;

LC78F:  LDY #$00                ;Zero out index.

LC791:  LDA (BlockAddr),Y       ;Sets attribute table value for each block based on its -->
LC793:  CMP #$C1                ;position in the pattern table.
LC795:  BCS +                   ;Is this a sky tile in the battle scene? If not, branch.

LC797:  LDA #$00                ;Set attribute table value for battle scene sky tiles.
LC799:  BEQ SetAttribVals       ;

LC79B:* CMP #$CA                ;Is this a green covered mountain tile in the battle scene?
LC79D:  BCS +                   ;If not, branch.

LC79F:  LDA #$01                ;Set attribute table value for battle scene green covered -->
LC7A1:  BNE SetAttribVals       ;mountain tiles. Branch always.

LC7A3:* CMP #$DE                ;Is this a foreground tile in the battle scene?
LC7A5:  BCS +                   ;If not, branch.

LC7A7:  LDA #$02                ;Set attribute table value for battle scene foreground tiles.
LC7A9:  BNE SetAttribVals       ;Branch always.

LC7AB:* LDA #$03                ;Set attribute table values for battle scene horizon tiles. 

SetAttribVals:
LC7AD:  STA PPUDataByte         ;Store attribute table data.
LC7AF:  JSR ModAttribBits       ;($C006)Set the attribute table bits for a nametable block.

LC7B2:  LDA PPUAddrUB           ;
LC7B4:  CLC                     ;Move to the next position in the column.
LC7B5:  ADC #$20                ;
LC7B7:  STA PPUAddrUB           ;

LC7B9:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LC7BC:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoMidDialog:
LC7BD:  STA GenByte3C           ;Save dialog data byte.
LC7BF:  LDA #$00                ;Dialog is in lower text blocks.
LC7C1:  STA GenByte3D           ;
LC7C3:  BEQ SetDialogBytes      ;($C7E4)Prepare to display on-screen dialog.

;----------------------------------------------------------------------------------------------------
DoDialogHiBlock:
LC7C5:  LDA #$01                ;Prepare to get dialog from TextBlock17 or higher.
LC7C7:  STA GenByte3D           ;
LC7C9:  BNE +                   ;Branch always.

DoDialogLoBlock:
LC7CB:  LDA #$00                ;Prepare to get dialog from TextBlock1 to TextBlock16.
LC7CD:  STA GenByte3D           ;

LC7CF:* PLA                     ;Pull return address off the stack and increment-->
LC7D0:  CLC                     ;it.  Then place it back on the stack to skip-->
LC7D1:  ADC #$01                ;the data byte in the calling function.
LC7D3:  STA GenPtr3ELB          ;
LC7D5:  PLA                     ;
LC7D6:  ADC #$00                ;
LC7D8:  STA GenPtr3EUB          ;
LC7DA:  PHA                     ;Set a pointer to the data byte-->
LC7DB:  LDA GenPtr3ELB          ;in the calling function.
LC7DD:  PHA                     ;

LC7DE:  LDY #$00                ;
LC7E0:  LDA (GenPtr3E),Y        ;Store data byte.
LC7E2:  STA GenByte3C           ;

SetDialogBytes:
LC7E4:  LDA GenByte3C           ;Data byte after function call.
LC7E6:  LDX GenByte3D           ;High/low text block bit.

LC7E8:  BRK                     ;Display dialog on screen.
LC7E9:  .byte $12, $17          ;($B51D)DoDialog, bank 1.
LC7EB:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;This section appears to be unused code from Dragon Quest.

LC7EC: .byte $A5, $4B, $0A, $85, $3C, $A5, $98, $18, $69, $2C, $38, $E5, $3C, $85, $3C, $A9
LC7FC: .byte $1E, $85, $3E, $20, $F0, $C1, $A5, $40, $85, $3E, $48, $A5, $4A, $0A, $85, $3C
LC80C: .byte $A5, $D4, $18, $69, $10, $38, $E5, $3C, $85, $3C, $20, $9E, $C5, $A5, $0A, $85
LC81C: .byte $0C, $A5, $0B, $85, $0D, $68, $85, $3E, $A5, $4A, $0A, $85, $3C, $A5, $D2, $18
LC82C: .byte $69, $10, $38, $E5, $3C, $85, $3C, $20, $9E, $C5, $A5, $0A, $85, $42, $A5, $0B
LC83C: .byte $85, $43, $60, $A9, $5F, $85, $08, $20, $F5, $C4, $4C, $90, $C6, $A9, $56, $85
LC84C: .byte $08, $20, $F5, $C4, $4C, $90, $C6, $A9, $FF, $85, $4F, $20, $74, $FF, $20, $3F
LC85C: .byte $C8, $A5, $47, $48, $20, $08, $C6, $68, $F0, $0B, $A5, $4F, $29, $0F, $C9, $0C
LC86C: .byte $F0, $03, $4C, $A9, $C9, $A5, $47, $29, $01, $F0, $1C, $20, $49, $C8, $A5, $D8
LC87C: .byte $C9, $01, $F0, $04, $A9, $00, $85, $D7, $A5, $D9, $18, $65, $D7, $85, $D7, $A9
LC88C: .byte $85, $00, $04, $17, $A5, $D7, $60, $A5, $47, $29, $02, $F0, $0D, $20, $49, $C8
LC89C: .byte $A9, $85, $00, $04, $17, $A9, $FF, $85, $D7, $60, $A5, $47, $29, $10, $F0, $42
LC8AC: .byte $A5, $D8, $C9, $05, $F0, $1D, $A5, $D9, $D0, $03, $4C, $A9, $C9, $C6, $D9, $C6
LC8BC: .byte $98, $C6, $98, $A5, $98, $C9, $FE, $F0, $03, $4C, $A5, $C9, $A9, $1C, $85, $98
LC8CC: .byte $4C, $A5, $C9, $A5, $D9, $D0, $03, $4C, $A9, $C9, $A9, $00, $85, $D9, $A5, $9D
LC8DC: .byte $85, $97, $A5, $9E, $38, $E9, $02, $C9, $FE, $D0, $02, $A9, $1C, $85, $98, $4C
LC8EC: .byte $A5, $C9, $A5, $47, $29, $20, $F0, $46, $A5, $D8, $C9, $05, $F0, $21, $E6, $D9
LC8FC: .byte $A5, $D9, $C5, $D7, $D0, $05, $C6, $D9, $4C, $A9, $C9, $E6, $98, $E6, $98, $A5
LC90C: .byte $98, $C9, $1E, $F0, $03, $4C, $A5, $C9, $A9, $00, $85, $98, $4C, $A5, $C9, $A9
LC91C: .byte $02, $C5, $D9, $D0, $03, $4C, $A9, $C9, $85, $D9, $A5, $9D, $85, $97, $A5, $9E
LC92C: .byte $18, $69, $02, $C9, $1E, $D0, $02, $A9, $00, $85, $98, $4C, $A5, $C9, $A5, $47
LC93C: .byte $29, $40, $F0, $32, $A5, $D8, $C9, $05, $F0, $14, $A5, $D8, $C9, $01, $D0, $5D
LC94C: .byte $C6, $D8, $A5, $97, $38, $E9, $06, $29, $3F, $85, $97, $4C, $A5, $C9, $A9, $03
LC95C: .byte $C5, $D9, $F0, $49, $85, $D9, $A5, $9E, $85, $98, $A5, $9D, $38, $E9, $02, $29
LC96C: .byte $3F, $85, $97, $4C, $A5, $C9, $A5, $47, $29, $80, $F0, $31, $A5, $D8, $C9, $05
LC97C: .byte $F0, $12, $A5, $D8, $D0, $27, $E6, $D8, $A5, $97, $18, $69, $06, $29, $3F, $85
LC98C: .byte $97, $4C, $A5, $C9, $A9, $01, $C5, $D9, $F0, $13, $85, $D9, $A5, $9E, $85, $98
LC99C: .byte $A5, $9D, $18, $69, $02, $29, $3F, $85, $97, $A9, $00, $85, $4F, $A5, $4F, $29
LC9AC: .byte $10, $D0, $03, $20, $49, $C8, $4C, $57, $C8

;----------------------------------------------------------------------------------------------------

ContinueReset:
LC9B5:  LDA #$00                ;Switch to PRG bank 0.
LC9B7:  JSR SetPRGBankAndSwitch ;($FF91)Switch to new PRG bank.

LC9BA:  LDA #$00                ;
LC9BC:  TAX                     ;Clear more RAM.
LC9BD:  STA DrgnLrdPal          ;
LC9C0:  STA CharDirection       ;

LC9C3:* STA TrsrXPos,X          ;
LC9C6:  INX                     ;Clear RAM used for treasure-->
LC9C7:  CPX #$10                ;chest pickup history.
LC9C9:  BCC -                   ;

LC9CB:  BRK                     ;
LC9CC:  .byte $02, $17          ;($8178)ClearSoundRegs, bank 1.

LC9CE:  JSR Bank0ToNT0          ;($FCA3)Load data into nametable 0.
LC9D1:  JSR Bank3ToNT1          ;($FCB8)Load data into nametable 1.

LC9D4:  LDA #$FF                ;Invalidate HP.
LC9D6:  STA HitPoints           ;

LC9D8:  LDA #$08                ;
LC9DA:  STA NTBlockX            ;Set player's initial position on the nametable.
LC9DC:  LDA #$07                ;
LC9DE:  STA NTBlockY            ;
LC9E0:  JSR DoIntroGFX          ;($BD5B)Load intro graphics.

LC9E3:  LDA #$01                ;Wait for PPU buffer to be completely empty.
LC9E5:  JSR WaitForPPUBufSpace  ;($C587)Wait for space in PPU buffer.

LC9E8:  LDA #%00011000          ;Enable sprites and background.
LC9EA:  STA PPUControl1         ;

LC9ED:  LDA #$00                ;Reset sound engine status.
LC9EF:  STA SndEngineStat       ;

;----------------------------------------------------------------------------------------------------

;The game is completely reset at this point.  Start the intro routine stuff.

IntroRoutineStuff:
LC9F2:  BRK                     ;
LC9F3:  .byte $00, $27          ;($BCB0)DoIntroRoutine, bank 2.

LC9F5:  LDA #%00000000          ;Turn off sprites and background.
LC9F7:  STA PPUControl1         ;

LC9FA:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LC9FD:  JSR Bank1ToNT0          ;($FC98)Load CHR ROM bank 1 into nametable 0.
LCA00:  JSR Bank2ToNT1          ;($FCAD)Load CHR ROM bank 2 into nametable 1.

LCA03:  LDA #MSC_VILLAGE        ;Village music.
LCA05:  BRK                     ;
LCA06:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LCA08:  JSR LoadSaveMenus       ;($F678)Intro passed.  Show load/save windows.

;----------------------------------------------------------------------------------------------------

;The gameplay has started.

MainGameEngine:
LCA0B:  LDA #$FA                ;Indicate game has been started.
LCA0D:  STA GameStarted         ;

LCA0F:  LDA #$00                ;Prepare to clear door and treasure history.
LCA11:  TAX                     ;

LCA12:* STA DoorXPos,X          ;
LCA15:  INX                     ;Clear the door and treasure history.
LCA16:  CPX #$20                ;
LCA18:  BNE -                   ;

LCA1A:  JSR StartAtThroneRoom   ;($CB47)Start player at throne room.

LCA1D:  LDA PlayerFlags         ;Did the player just start the game?
LCA1F:  AND #F_LEFT_THROOM      ;
LCA21:  BEQ FirstKingDialog     ;If so, branch for the king's initial dialog.

LCA23:  JSR DoDialogHiBlock     ;($C7C5)I am glad thou hast returned...
LCA26:  .byte $17               ;TextBlock18, entry 7.

LCA27:  LDA DisplayedLevel      ;Is player level 30? If so, show a special message.
LCA29:  CMP #LVL_30             ;
LCA2B:  BNE KingExpCalc         ;If not, branch for the regular message.

LCA2D:  JSR DoDialogLoBlock     ;($C7CB)Though art strong enough...
LCA30:  .byte $02               ;TextBlock1, entry 2.

LCA31:  JMP EndKingDialog       ;Jump to last king dialog segment.

KingExpCalc:
LCA34:  JSR GetExpRemaining     ;($F134)Calculate experience needed for next level.

LCA37:  JSR DoDialogLoBlock     ;($C7CB)Before reaching thy next level...
LCA3A:  .byte $C1               ;TextBlock13, entry 1.

LCA3B:  JSR DoDialogHiBlock     ;($C7C5)See me again when thy level increases...
LCA3E:  .byte $18               ;TextBlock18, entry 8.

EndKingDialog:
LCA3F:  JSR DoDialogLoBlock     ;($C7CB)Goodbye now. Take care...
LCA42:  .byte $C4               ;TextBlock13, entry 4.

LCA43:  JMP PlayerInitControl   ;($CA4A)Give the player control for the first time.

FirstKingDialog:
LCA46:  JSR DoDialogHiBlock     ;($C7C5)Descendant of Erdrick, listen to my words...
LCA49:  .byte $02               ;TextBlock17, entry 2.

PlayerInitControl:
LCA4A:  JSR WaitForBtnRelease   ;($CFE4)Wait for player to release then press joypad buttons.

LCA4D:  LDA #WND_DIALOG         ;Remove the dialog window from the screen.
LCA4F:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LCA52:  LDA #NPC_MOVE           ;Allow the NPCs to move.
LCA54:  STA StopNPCMove         ;

;----------------------------------------------------------------------------------------------------

;This is the main loop where the rest of the game originates from.

GameEngineLoop:
LCA56:  LDA RadiantTimer        ;Is the radiant timer active?
LCA58:  BEQ CheckRepelTimer     ;If not, branch to check the repel timer.

LCA5A:  DEC RadiantTimer        ;Decrement the radiant timer.
LCA5C:  BNE CheckRepelTimer     ;Is radiant timer expired? If not, branch to check the repel timer.

LCA5E:  LDA LightDiameter       ;Radiant timer expired. Check light diameter.
LCA60:  CMP #$01                ;Is light diameter at minimum?
LCA62:  BEQ CheckRepelTimer     ;If so, branch to check the repel timer.

LCA64:  LDA #$3C                ;Reload radiant timer. 60 steps.
LCA66:  STA RadiantTimer        ;
LCA68:  DEC LightDiameter       ;Radius is reduced by two squares.
LCA6A:  DEC LightDiameter       ;

CheckRepelTimer:
LCA6C:  LDA RepelTimer          ;Is the repel timer active?
LCA6E:  BEQ JoypadCheckLoop     ;If not, branch to check joypad inputs.

LCA70:  DEC RepelTimer          ;Decrement the repel timer by 2 every step.
LCA72:  DEC RepelTimer          ;
LCA74:  BEQ EndRepelTimer       ;Did repel timer just end? If so, branch to show message.

LCA76:  LDA RepelTimer          ;Ir repel timer about to end?
LCA78:  CMP #$01                ;If not, jump to check user input.
LCA7A:  BNE JoypadCheckLoop     ;

EndRepelTimer:
LCA7C:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCA7F:  LDA #NPC_STOP           ;
LCA81:  STA StopNPCMove         ;Stop NPC movement.

LCA83:  JSR Dowindow            ;($C6F0)display on-screen window.
LCA86:  .byte WND_DIALOG        ;Dialog window.

LCA87:  LDA RepelTimer          ;If repel timer is odd, it is the repel spell. If it is -->
LCA89:  BNE RepelEndMsg         ;even, it is from fairy water. Branch accordingly.

LCA8B:  LDA #$37                ;TextBlock4, entry 7. The fairy water has lost its effect...
LCA8D:  BNE +                   ;Branch always.

RepelEndMsg:
LCA8F:  LDA #$34                ;TextBlock4, entry 4. Repel has lost its effect...
LCA91:* JSR DoMidDialog         ;($C7BD)Do any number of Dialogs.

LCA94:  JSR ResumeGamePlay      ;($CFD9)Give control back to player.
LCA97:  LDA #$00                ;
LCA99:  STA RepelTimer          ;Deactivate the repel timer.

JoypadCheckLoop:
LCA9B:  LDA #$00                ;Reset the frame counter.
LCA9D:  STA FrameCounter        ;

CheckInputs:
LCA9F:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LCAA2:  LDA JoypadBtns          ;
LCAA4:  AND #IN_START           ;Is game paused?
LCAA6:  BEQ CheckJoyA           ;If not, branch to check user inputs.

PausePrepLoop:
LCAA8:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCAAB:  LDA FrameCounter        ;
LCAAD:  AND #$0F                ;Sync the pause every 16th frame of the frame counter. -->
LCAAF:  CMP #$01                ;This lines up the NPCs and player on the background tiles.
LCAB1:  BEQ GamePaused          ;
LCAB3:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LCAB6:  JMP PausePrepLoop       ;($CAA8)Start pressed.  Wait until first frame and then pause game.

GamePaused:
LCAB9:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LCABC:  LDA JoypadBtns          ;
LCABE:  AND #IN_START           ;Stay in this loop until player releases pause button.
LCAC0:  BNE GamePaused          ;

LCAC2:* JSR GetJoypadStatus     ;($C608)Get input button presses.
LCAC5:  LDA JoypadBtns          ;
LCAC7:  AND #IN_START           ;Stay in this loop until user presses button to unpause game.
LCAC9:  BEQ -                   ;

LCACB:* JSR GetJoypadStatus     ;($C608)Get input button presses.
LCACE:  LDA JoypadBtns          ;
LCAD0:  AND #IN_START           ;Stay in this loop until user releases start button(unpause).
LCAD2:  BNE -                   ;
LCAD4:  JMP JoypadCheckLoop     ;($CA9B)Loop and check for controller input.

CheckJoyA:
LCAD7:  LDA JoypadBtns          ;Was A button pressed?
LCAD9:  LSR                     ;If not, branch to check other buttons.
LCADA:  BCC CheckJoyUp          ;

LCADC:  JSR DoNCCmdWindow       ;($CF49)Bring up non-combat command window.
LCADF:  JMP JoypadCheckLoop     ;Loop again to keep checking user inputs.

CheckJoyUp:
LCAE2:  LDA JoypadBtns          ;Get joypad buttons.
LCAE4:  AND #IN_UP              ;Is up being pressed?
LCAE6:  BEQ CheckJoyDown        ;If not, branch to check next button.

LCAE8:  LDA #DIR_UP             ;Point character up.
LCAEA:  STA CharDirection       ;
LCAED:  JSR DoJoyUp             ;($B504)Do button up pressed checks.
LCAF0:  JSR ChkSpecialLoc       ;($B219)Check for special locations on the maps.
LCAF3:  JMP GameEngineLoop      ;($CA56)Return to the start of the game engine loop.

CheckJoyDown:
LCAF6:  LDA JoypadBtns          ;Get joypad buttons.
LCAF8:  AND #IN_DOWN            ;Is down being pressed?
LCAFA:  BEQ CheckJoyLeft        ;If not, branch to check next button.

LCAFC:  LDA #DIR_DOWN           ;Point character down.
LCAFE:  STA CharDirection       ;
LCB01:  JSR DoJoyDown           ;($B3D8)Do button down pressed checks.
LCB04:  JSR ChkSpecialLoc       ;($B219)Check for special locations on the maps.
LCB07:  JMP GameEngineLoop      ;($CA56)Return to the start of the game engine loop.

CheckJoyLeft:
LCB0A:  LDA JoypadBtns          ;Get joypad buttons.
LCB0C:  AND #IN_LEFT            ;Is left being pressed?
LCB0E:  BEQ CheckJoyRight       ;If not, branch to check next button.

LCB10:  LDA #DIR_LEFT           ;Point character left.
LCB12:  STA CharDirection       ;
LCB15:  JSR DoJoyLeft           ;($B34C)Do button left pressed checks.
LCB18:  JSR ChkSpecialLoc       ;($B219)Check for special locations on the maps.
LCB1B:  JMP GameEngineLoop      ;($CA56)Return to the start of the game engine loop.

CheckJoyRight:
LCB1E:  LDA JoypadBtns          ;Get joypad buttons.
LCB20:  BPL IdleUpdate          ;Is right being pressed? If not, branch to update the idle status.

LCB22:  LDA #DIR_RIGHT          ;Point character right.
LCB24:  STA CharDirection       ;
LCB27:  JSR DoJoyRight          ;($B252)Do button right pressed checks.
LCB2A:  JSR ChkSpecialLoc       ;($B219)Check for special locations on the maps.
LCB2D:  JMP GameEngineLoop      ;($CA56)Return to the start of the game engine loop.

IdleUpdate:
LCB30:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCB33:  LDA FrameCounter        ;Has the input been idle for 50 frames?
LCB35:  CMP #$31                ;
LCB37:  BNE EngineLoopEnd       ;If not, branch to not bring up the pop-up window.

LCB39:  JSR Dowindow            ;($C6F0)display on-screen window.
LCB3C:  .byte WND_POPUP         ;Pop-up window.

LCB3D:  LDA #$32                ;Indicate pop-up window is active.
LCB3F:  STA FrameCounter        ;

EngineLoopEnd:
LCB41:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LCB44:  JMP CheckInputs         ;Loop until user presses a button.

;----------------------------------------------------------------------------------------------------

StartAtThroneRoom:
LCB47:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCB4A:  LDA BlackPalPtr         ;
LCB4D:  STA PalPtrLB            ;
LCB4F:  LDA BlackPalPtr+1       ;Point to the all black palette.
LCB52:  STA PalPtrUB            ;

LCB54:  LDA #$00                ;No sprite palette fade in.
LCB56:  STA PalModByte          ;

LCB58:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.
LCB5B:  LDA #$30                ;
LCB5D:  STA PalModByte          ;Prepare to fade in background tiles.

LCB5F:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer
LCB62:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCB65:  JSR LoadStats           ;($F050)Update player attributes.
LCB68:  JSR Bank1ToNT0          ;($FC98)Load CHR ROM bank 1 into nametable 0.

LCB6B:  LDA ModsnSpells         ;Is the player cursed?
LCB6D:  AND #IS_CURSED          ;
LCB6F:  BEQ +                   ;If not, branch to move on.

LCB71:  LDA #$01                ;
LCB73:  STA HitPoints           ;Player is cursed. Set starting hit points to 1.
LCB75:  JMP SetStartPos         ;

LCB78:* LDA ThisStrtStat        ;Should player's HP and MP be restored on start?
LCB7B:  CMP #STRT_FULL_HP       ;
LCB7D:  BNE SetStartPos         ;If not, branch to move on.

LCB7F:  TXA                     ;Save X on the stack.
LCB80:  PHA                     ;

LCB81:  LDA DisplayedMaxHP      ;
LCB83:  STA HitPoints           ;Max out HP and MP.
LCB85:  LDA DisplayedMaxMP      ;
LCB87:  STA MagicPoints         ;

LCB89:  LDX SaveNumber          ;
LCB8C:  LDA #STRT_NO_HP         ;Indicate in the save game that the HP and MP -->
LCB8E:  STA StartStatus1,X      ;should not be maxed out on the next start.
LCB91:  STA ThisStrtStat        ;

LCB94:  PLA                     ;Restore X from the stack.
LCB95:  TAX                     ;

SetStartPos:
LCB96:  LDA #$03                ;
LCB98:  STA CharXPos            ;Set player's X block position.
LCB9A:  STA _CharXPos           ;

LCB9C:  LDA #$04                ;
LCB9E:  STA CharYPos            ;Set player's Y block position.
LCBA0:  STA _CharYPos           ;

LCBA2:  LDA #$30                ;
LCBA4:  STA CharXPixelsLB       ;Set player's X and Y map pixel positions.
LCBA6:  LDA #$40                ;
LCBA8:  STA CharYPixelsLB       ;

LCBAA:  LDA #$00                ;
LCBAC:  STA RepeatCounter       ;Clear any active timers and the upper byte --> 
LCBAE:  STA RepelTimer          ;of the map pixel positions.
LCBB0:  STA CharXPixelsUB       ;
LCBB2:  STA CharYPixelsUB       ;

LCBB4:  LDA #$08                ;
LCBB6:  STA NTBlockX            ;Set nametable X and Y position of the player.
LCBB8:  LDA #$07                ;
LCBBA:  STA NTBlockY            ;

LCBBC:  LDA #MAP_THRONEROOM     ;Prepare to load the throne room map.
LCBBE:  STA MapNumber           ;

LCBC0:  JSR ClearWinBufRAM2     ;($A788)Clear RAM buffer used for drawing text windows.
LCBC3:  JSR MapChngNoSound      ;($B091)Change maps with no stairs sound.
LCBC6:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LCBC9:  LDA #$00                ;Reset the frame counter.
LCBCB:  STA FrameCounter        ;

FirstInputLoop:
LCBCD:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LCBD0:  LDA JoypadBtns          ;Has player pressed a button?
LCBD2:  BNE FrameSyncLoop       ;If not, loop until they do.

LCBD4:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCBD7:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LCBDA:  JMP FirstInputLoop      ;Wait for player to press a button.

FrameSyncLoop:
LCBDD:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LCBE0:  LDA FrameCounter        ;
LCBE2:  AND #$0F                ;Make sure the frame counter is synchronized. Actions will -->
LCBE4:  CMP #$01                ;not occur until frame counter is on frame 1.
LCBE6:  BEQ +                   ;

LCBE8:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LCBEB:  JMP FrameSyncLoop       ;($CBDD)Wait for frame 1 before loading dialog windows.

LCBEE:* LDA #NPC_STOP           ;Stop NPCs from moving on the screen.
LCBF0:  STA StopNPCMove         ;

LCBF2:  JSR Dowindow            ;($C6F0)display on-screen window.
LCBF5:  .byte WND_DIALOG        ;Dialog window.
LCBF6:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckForTriggers:
LCBF7:  LDA StoryFlags          ;Is the dragonlord dead?
LCBF9:  AND #F_DGNLRD_DEAD      ;
LCBFB:  BNE ChkCstlEnd          ;If so, branch to check end game trigger.

LCBFD:  JMP MovementUpdates     ;($CCF6)Do routine movement checks.

ChkCstlEnd:
LCC00:  LDA MapNumber           ;Is player on the ground floor of Tantagel castle?
LCC02:  CMP #MAP_TANTCSTL_GF    ;
LCC04:  BNE +                   ;If not, branch to check other things.

LCC06:  LDA CharYPos            ;Is player in the right Y coordinate to trigger the end game?
LCC08:  CMP #$08                ;
LCC0A:  BNE +                   ;If not, branch to check other things.

LCC0C:  LDA CharXPos            ;Is player at the first of 2 possible X coordinates to -->
LCC0E:  CMP #$0A                ;trigger the end game?
LCC10:  BEQ EndGameTriggered    ;If not, check second trigger.

LCC12:  CMP #$0B                ;Is player at the second of 2 possible X coordinates to -->
LCC14:  BEQ EndGameTriggered    ;trigger the end game? If so, branch to end game sequence.

LCC16:* JMP CheckBlockDmg       ;Check to see if current map tile will damage player.

EndGameTriggered:
LCC19:  LDA #MSC_NOSOUND        ;Silence music.
LCC1B:  BRK                     ;
LCC1C:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LCC1E:  LDA #NPC_STOP           ;Stop the NPCs from moving.
LCC20:  STA StopNPCMove         ;

LCC22:  JSR Dowindow            ;($C6F0)display on-screen window.
LCC25:  .byte WND_DIALOG        ;Dialog window.

LCC26:  JSR DoDialogHiBlock     ;($C7C5)The legends have proven true...
LCC29:  .byte $1B               ;TextBlock18, entry 11.

LCC2A:  LDA PlayerFlags         ;Has the player returned princess Gwaelin?
LCC2C:  AND #F_RTN_GWAELIN      ;
LCC2E:  BEQ ChkCarryGwaelin     ;If not, branch to see if the player is carrying Gwaelin.

LCC30:  LDA #$C7                ;Set princess Gwaelin at stairs, X position.
LCC32:  STA GwaelinXPos         ;
LCC34:  LDA #$27                ;Set princess Gwaelin at stairs, Y position, facing right.
LCC36:  STA GwaelinYPos         ;
LCC38:  LDA #$00                ;Align princess Gwaelin in stairs before movement.
LCC3A:  STA GwaelinOffset       ;

LCC3C:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCC3F:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LCC42:  JSR DoDialogHiBlock     ;($C7C5)Gwaelin said: please wait...
LCC45:  .byte $1C               ;TextBlock18, entry 12.

GwaelinMoveLoop:
LCC46:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCC49:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LCC4C:  LDA GwaelinOffset       ;
LCC4E:  CLC                     ;Move Gwaelin 1 pixel right.
LCC4F:  ADC #$10                ;
LCC51:  STA GwaelinOffset       ;Has Gwaelin moved 16 pixels?
LCC53:  BCC +                   ;If so, time to increment her X position.

LCC55:  INC GwaelinXPos         ;increment Gwaelin's xposition.

LCC57:* JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LCC5A:  LDA GwaelinXPos         ;Has Gwaelin moved next to the king?
LCC5C:  CMP #$CA                ;
LCC5E:  BNE GwaelinMoveLoop     ;If not, branch to move Gwaelin some more.

LCC60:  LDA #$47                ;Change Gwaelin NPC to down facing direction.
LCC62:  STA GwaelinYPos         ;
LCC64:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LCC67:  JMP GwaelinJoin         ;Jump to Gwaelin dialog.

ChkCarryGwaelin:
LCC6A:  LDA PlayerFlags         ;Is player carrying Gwaelin?
LCC6C:  LSR                     ;
LCC6D:  BCC TaleEnd             ;If not, branch to skip Gwaelin ending sequence.

LCC6F:  LDA PlayerFlags         ;
LCC71:  AND #$FE                ;Clear the flag indicating the player is holding Gwaelin.
LCC73:  STA PlayerFlags         ;

LCC75:  LDA #$CA                ;
LCC77:  STA GwaelinXPos         ;
LCC79:  LDA #$47                ;Place princess Gwaelin next to the king and facing down.
LCC7B:  STA GwaelinYPos         ;
LCC7D:  LDA #$00                ;
LCC7F:  STA GwaelinOffset       ;

LCC81:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCC84:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LCC87:  JSR DoDialogHiBlock     ;($C7C5)Gwaelin said: please wait...
LCC8A:  .byte $1C               ;TextBlock18, entry 12.

GwaelinJoin:
LCC8B:  JSR DoDialogHiBlock     ;($C7C5)I wish to go with thee...
LCC8E:  .byte $1D               ;TextBlock18, entry 13.

GwaelinDecline:
LCC8F:  JSR DoDialogHiBlock     ;($C7C5)May I travel as your companion...
LCC92:  .byte $1E               ;TextBlock18, entry 14.

LCC93:  JSR Dowindow            ;($C6F0)display on-screen window.
LCC94:  .byte WND_YES_NO1       ;Yes/No window.

LCC97:  BEQ GwaelinAccept       ;Branch if player says yes to Gwaelin.

LCC99:  JSR DoDialogLoBlock     ;($C7CB)But thou must...
LCC9C:  .byte $B6               ;TextBlock12, entry 6.

LCC9D:  JMP GwaelinDecline      ;Branch to loop until player accepts.

GwaelinAccept:
LCCA0:  JSR DoDialogLoBlock     ;($C7CB)I'm so happy...
LCCA3:  .byte $B8               ;TextBlock12, entry 8.

LCCA4:  LDA #$00                ;
LCCA6:  STA GwaelinXPos         ;Remove the princess Gwaelin NPC from the screen. -->
LCCA8:  STA GwaelinYPos         ;She will be drawn in the player's arms.
LCCAA:  STA GwaelinOffset       ;

LCCAC:  LDA PlayerFlags         ;
LCCAE:  ORA #F_GOT_GWAELIN      ;Set flag indicating player is carrying Gwaelin.
LCCB0:  STA PlayerFlags         ;

LCCB2:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCCB5:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

TaleEnd:
LCCB8:  JSR DoDialogHiBlock     ;($C7C5)And thus the tale comes to an end...
LCCBB:  .byte $22               ;TextBlock19, entry 2.

LCCBC:  LDX #$78                ;Wait 120 frames before continuing.
LCCBE:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCCC1:  DEX                     ;Has 120 frames passed?
LCCC2:  BNE -                   ;If not, branch to wait another frame.

LCCC4:  LDA #WND_DIALOG         ;Remove the dialog window.
LCCC6:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LCCC9:  LDA #$01                ;Show the player facing right.
LCCCB:  STA CharDirection       ;
LCCCE:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LCCD1:  LDA #$1E                ;Prepare to wait 30 frames(1/2 second).
LCCD3:  JSR WaitMultiNMIs       ;($C170)Wait for a defined number of frames.

LCCD6:  LDA #$02                ;Draw the player facing down.
LCCD8:  STA CharDirection       ;
LCCDB:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LCCDE:  LDX #$1E                ;Prepare to wait 30 frames(1/2 second).
LCCE0:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCCE3:  DEX                     ;Has 30 frames passed?
LCCE4:  BNE -                   ;If not, branch to wait another frame.

LCCE6:  LDA #$FF                ;Indicate the guards with trumpets should be shown.
LCCE8:  STA DisplayedLevel      ;
LCCEA:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LCCED:  BRK                     ;Show end credits.
LCCEE:  .byte $0E, $17          ;($939A)DoEndCredits, bank 1.

LCCF0:  JSR MMCShutdown         ;($FC88)Switch to PRG bank 3 and disable PRG RAM.

Spinlock1:
LCCF3:  JMP Spinlock1           ;($CCF3)Spinlock the game.  Reset required to do anything else.

;----------------------------------------------------------------------------------------------------

MovementUpdates:
LCCF6:  LDA EqippedItems        ;Is the player wearing Erdrick's armor?
LCCF8:  AND #AR_ARMOR           ;
LCCFA:  CMP #AR_ERDK_ARMR       ;
LCCFC:  BEQ MovmtIncHP          ;If so, branch.

LCCFE:  CMP #AR_MAGIC_ARMR      ;Is the player wearing magic armor?
LCD00:  BNE CheckTantCursed     ;If not, branch.

LCD02:  INC MjArmrHP            ;Player is wearing magic armor.
LCD04:  LDA MjArmrHP            ;
LCD06:  AND #$03                ;Is player on their 3rd step?
LCD08:  BNE CheckTantCursed     ;If not, branch to exit check.

MovmtIncHP:
LCD0A:  INC HitPoints           ;Player recovers 1 HP.

LCD0C:  LDA HitPoints           ;Has player exceeded their max HP?
LCD0E:  CMP DisplayedMaxHP      ;
LCD10:  BCC ChkLowHP            ;If not, branch.

LCD12:  LDA DisplayedMaxHP      ;Set player HP to max.
LCD14:  STA HitPoints           ;

ChkLowHP:
LCD16:  LDA DisplayedMaxHP      ;Does the player have less than 1/8th their max HP?
LCD18:  LSR                     ;
LCD19:  LSR                     ;
LCD1A:  CLC                     ;
LCD1B:  ADC #$01                ;
LCD1D:  CMP HitPoints           ;
LCD1F:  BCS CheckTantCursed     ;If so, branch.

LCD21:  LDA #$01                ;Player is not badly hurt.
LCD23:  STA PPUAddrLB           ;
LCD25:  LDA #$3F                ;
LCD27:  STA PPUAddrUB           ;Make sure low HP palette is not active.
LCD29:  LDA #$30                ;
LCD2B:  STA PPUDataByte         ;
LCD2D:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

;----------------------------------------------------------------------------------------------------

CheckTantCursed:
LCD30:  LDA MapNumber           ;Is the player in Tantagel castle, ground floor?
LCD32:  CMP #MAP_TANTCSTL_GF    ;
LCD34:  BNE CheckAxeKnight      ;If not, exit this check.

LCD36:  LDA ModsnSpells         ;Is the player cursed?
LCD38:  AND #$C0                ;
LCD3A:  BEQ CheckAxeKnight      ;If not, branch to exit this check.

LCD3C:  LDA CharYPos            ;Is the player's Y position 27?
LCD3E:  CMP #$1B                ;
LCD40:  BNE CheckAxeKnight      ;If not, exit this check.

LCD42:  LDA #NPC_STOP           ;Stop the NPCs from moving.
LCD44:  STA StopNPCMove         ;

LCD46:  JSR Dowindow            ;($C6F0)display on-screen window.
LCD49:  .byte WND_DIALOG        ;Dialog window.

LCD4A:  JSR DoDialogLoBlock     ;($C7CB)Cursed one, be gone...
LCD4D:  .byte $44               ;TextBlock5, entry 4.

LCD4E:  JMP CheckMapExit        ;($B228)Force player to exit the map.

;----------------------------------------------------------------------------------------------------

CheckAxeKnight:
LCD51:  LDA MapNumber           ;Is the player in Hauksness?
LCD53:  CMP #MAP_HAUKSNESS      ;
LCD55:  BNE CheckGrnDragon      ;If not, exit this check.

LCD57:  LDA CharXPos            ;Is the player at position 18, 12?
LCD59:  CMP #$12                ;
LCD5B:  BNE CheckGrnDragon      ;
LCD5D:  LDA CharYPos            ;
LCD5F:  CMP #$0C                ;
LCD61:  BNE CheckGrnDragon      ;If not, exit this check.

LCD63:  LDA #EN_AXEKNIGHT       ;Fight the axe knight!
LCD65:  JMP InitFight           ;($E4DF)Begin fight sequence.

;----------------------------------------------------------------------------------------------------

CheckGrnDragon:
LCD68:  LDA MapNumber           ;Is the player in the swamp cave?
LCD6A:  CMP #MAP_SWAMPCAVE      ;
LCD6C:  BNE CheckGolem          ;If not, exit this check.

LCD6E:  LDA CharXPos            ;Is the player at position 4,14?
LCD70:  CMP #$04                ;
LCD72:  BNE CheckGolem          ;
LCD74:  LDA CharYPos            ;
LCD76:  CMP #$0E                ;
LCD78:  BNE CheckGolem          ;If not, exit this check.

LCD7A:  LDA StoryFlags          ;Has the green dragon already been defeated?
LCD7C:  AND #F_GDRG_DEAD        ;
LCD7E:  BNE CheckGolem          ;If so, exit this check.

LCD80:  LDA #EN_GDRAGON         ;Fight the green dragon!
LCD82:  JMP InitFight           ;($E4DF)Begin fight sequence.

;----------------------------------------------------------------------------------------------------

CheckGolem:
LCD85:  LDA MapNumber           ;Is the player on the overworld map?
LCD87:  CMP #MAP_OVERWORLD      ;
LCD89:  BNE CheckBlockDmg       ;If not, exit this check.

LCD8B:  LDA CharXPos            ;Is the player at position 73, 100?
LCD8D:  CMP #$49                ;
LCD8F:  BNE CheckBlockDmg       ;
LCD91:  LDA CharYPos            ;
LCD93:  CMP #$64                ;
LCD95:  BNE CheckBlockDmg       ;If not, exit this check.

LCD97:  LDA StoryFlags          ;Has golem already been defeated?
LCD99:  AND #F_GOLEM_DEAD       ;
LCD9B:  BNE CheckBlockDmg       ;If so, exit this check.

LCD9D:  LDA #EN_GOLEM           ;Fight golem!
LCD9F:  JMP InitFight           ;($E4DF)Begin fight sequence.

;----------------------------------------------------------------------------------------------------

CheckBlockDmg:
LCDA2:  JSR UpdateRandNum       ;($C55B)Get random number.
LCDA5:  LDA CharXPos            ;
LCDA7:  STA XTarget             ;Get the player's X and Y position.
LCDA9:  LDA CharYPos            ;
LCDAB:  STA YTarget             ;

LCDAD:  JSR GetBlockID          ;($AC17)Get description of block.
LCDB0:  LDA TargetResults       ;
LCDB2:  STA ThisTile            ;Get the current tile type player is standing on.

LCDB4:  CMP #BLK_TOWN           ;Is the player on a map changing tile?
LCDB6:  BCC ChkOtherBlocks      ;Town, castle or cave.
LCDB8:  CMP #BLK_BRIDGE         ;
LCDBA:  BCS ChkOtherBlocks      ;If not, branch.

LCDBC:  JMP CalcNextMap         ;($D941)Calculate next map to load.

ChkOtherBlocks:
LCDBF:  LDA StoryFlags          ;Is the dragonlord dead?
LCDC1:  AND #F_DGNLRD_DEAD      ;If so, can't get hurt by map blocks.
LCDC3:  BEQ NextBlockCheck      ;If not, branch to make more block checks.
LCDC5:  RTS                     ;

NextBlockCheck:
LCDC6:  LDA ThisTile            ;Is player standing on a swampp block?
LCDC8:  CMP #BLK_SWAMP          ;
LCDCA:  BNE ChkBlkSand          ;If not, branch.

LCDCC:  LDA EqippedItems        ;Player is standing on a swamp block.
LCDCE:  AND #AR_ARMOR           ;Is the player wearing Erdrick's armor?
LCDD0:  CMP #AR_ERDK_ARMR       ;
LCDD2:  BEQ ChkFight            ;If so, branch. Take no damage.

LCDD4:  LDA #SFX_SWMP_DMG       ;Swamp damage SFX.
LCDD6:  BRK                     ;
LCDD7:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LCDD9:  JSR RedFlashScreen      ;($EE14)Flash the screen red.
LCDDC:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LCDDF:  LDA HitPoints           ;Player takes 2 points of damage.
LCDE1:  SEC                     ;
LCDE2:  SBC #$02                ;Did player's HP go negative?
LCDE4:  BCS DoSwampDamage       ;If not, branch to update HP.

LCDE6:  LDA #$00                ;Player is dead. set HP to 0.

DoSwampDamage:
LCDE8:  STA HitPoints           ;Update player HP.
LCDEA:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCDED:  JSR LoadRegBGPal        ;($EE28)Load the normal background palette.

LCDF0:  LDA HitPoints           ;Is player still alive?
LCDF2:  BNE ChkFight            ;If so, branch to check for random encounter.

LCDF4:  JSR Dowindow            ;($C6F0)display on-screen window.
LCDF7:  .byte WND_POPUP         ;Pop-up window.

LCDF8:  JMP InitDeathSequence   ;($EDA7)Player has died.

ChkFight:
LCDFB:  LDA #$0F                ;Get random number.

ChkFight2: 
LCDFD:  AND RandNumUB           ;Is lower nibble 0?
LCDFF:  BEQ DoRandomFight       ;If so, branch to start a random fight.
LCE01:  RTS                     ;

ChkBlkSand:
LCE02:  CMP #BLK_SAND           ;Is the player on a sand block?
LCE04:  BEQ ChkSandFight        ;If so, branch to check for a fight.

LCE06:  CMP #BLK_HILL           ;Is the player on a hill block?
LCE08:  BNE ChkBlkTrees         ;If not, branch to check for other block types.

LCE0A:  JSR WaitForNMI          ;($FF74)Three frame pause when walking on hill block.
LCE0D:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCE10:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

ChkSandFight:
LCE13:  LDA #$07                ;Twice as likely to get into a fight in the sandy areas!
LCE15:  BNE ChkFight2           ;Branch always to Recheck if a fight will happen.

ChkBlkTrees:
LCE17:  CMP #BLK_TREES          ;Is player on a tree block?     
LCE19:  BEQ ChkRandomFight      ;if so, branch to check for enemy encounter.

LCE1B:  CMP #BLK_BRICK          ;Is player on a brick block?
LCE1D:  BEQ ChkRandomFight      ;if so, branch to check for enemy encounter.

LCE1F:  CMP #BLK_FFIELD         ;Is player on a force field block?
LCE21:  BNE ChkFight6           ;If not, branch to check for a random fight.

LCE23:  LDA EqippedItems        ;Player is on a force field blck.
LCE25:  AND #AR_ARMOR           ;Is player wearing Erdrick's armor?
LCE27:  CMP #AR_ERDK_ARMR       ;If not, branch to do force field damage to player.
LCE29:  BEQ ChkRandomFight      ;($CE5F)Check for enemy encounter.

LCE2B:  LDA #SFX_FFDAMAGE       ;Force field damage SFX.
LCE2D:  BRK                     ;
LCE2E:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LCE30:  LDA #$03                ;Prepare to flash the screen red for 3 frames.
LCE32:  STA GenByte42           ;

LCE34:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCE37:  JSR RedFlashScreen      ;($EE14)Flash the screen red.
LCE3A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCE3D:  JSR LoadRegBGPal        ;($EE28)Load the normal background palette.
LCE40:  DEC GenByte42           ;Has 3 frames passed?
LCE42:  BNE -                   ;If not, branch to wait another frame.

LCE44:  LDA HitPoints           ;Player takes 15 points of force field damage.
LCE46:  SEC                     ;
LCE47:  SBC #$0F                ;Has the player HP gone negative?
LCE49:  BCS +                   ;If not, branch to move on.

LCE4B:  LDA #$00                ;Set player HP to 0.
LCE4D:  BEQ +                   ;Branch always.

LCE4F:* STA HitPoints           ;Is player's HP 0?
LCE51:  CMP #$00                ;If not, branch to check for a random fight.
LCE53:  BNE ChkRandomFight      ;($CE5F)Check for enemy encounter.
LCE55:  JSR LoadRegBGPal        ;($EE28)Load the normal background palette.

LCE58:  JSR Dowindow            ;($C6F0)display on-screen window.
LCE5B:  .byte WND_POPUP         ;Pop-up window.

LCE5C:  JMP InitDeathSequence   ;($EDA7)Player has died.

;----------------------------------------------------------------------------------------------------

ChkRandomFight:
LCE5F:  LDA #$0F                ;Prepare to check lower nibble of random number for a random fight.
LCE61:  BNE ChkFight2           ;Branch always.

ChkFight6:
LCE63:  LDA CharXPos            ;Is character on an odd X map position?
LCE65:  LSR                     ;
LCE66:  BCS ChkFight5           ;If not, branch to check for normal chance for a fight.

LCE68:  LDA CharYPos            ;Is character on an odd Y map position?
LCE6A:  LSR                     ;
LCE6B:  BCC HighFightChance     ;Even X and even Y map location is higher fight chance.
LCE6D:  BCS NormFightChance     ;Odd Y position. Check for normal fight chance.

ChkFight5:
LCE6F:  LDA CharYPos            ;Is character on an odd Y map position?
LCE71:  LSR                     ;If not, branch for normal fight chance.
LCE72:  BCC NormFightChance     ;Odd X and odd Y map location is higher fight chance.

HighFightChance:
LCE74:  LDA #$1F                ;Higher chance for fight. Check 5 bits instead of 4.
LCE76:* BNE ChkFight2           ;Branch always.

NormFightChance:
LCE78:  LDA #$0F                ;Prepare to check lower nibble of random number for a fight.
LCE7A:  BNE -                   ;Branch always.

;At this point, the player had initiated a fight. Need to check which map and where.

DoRandomFight:
LCE7C:  LDA MapNumber           ;Is player on the overworld map?
LCE7E:  CMP #MAP_OVERWORLD      ;
LCE80:  BNE ChkDungeonFights    ;If not, branch to check other maps.

;This section of code calculates the proper enemies for the player's world map position.

LCE82:  LDA CharYPos            ;Divide player's Y location on overworkd map by 15. -->
LCE84:  STA DivNum1LB           ;This gives a number ranging from 0 to 7. -->
LCE86:  LDA #$0F                ;The enemy zones on the overworld map are an 8X8 grid.
LCE88:  STA DivNum2             ;
LCE8A:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.

LCE8D:  LDA DivNum1LB           ;Save Y data for enemy zone calculation.
LCE8F:  STA GenByte42           ;

LCE91:  LDA CharXPos            ;Divide player's X location on overworkd map by 15. -->
LCE93:  STA DivNum1LB           ;This gives a number ranging from 0 to 7. -->
LCE95:  LDA #$0F                ;The enemy zones on the overworld map are an 8X8 grid.
LCE97:  STA DivNum2             ;
LCE99:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.

LCE9C:  LDA GenByte42           ;*4. 4 bytes per row in overworld enemy grid.
LCE9E:  ASL                     ;
LCE9F:  ASL                     ;The proper row in OvrWrldEnGrid is now known. -->
LCEA0:  STA EnemyOffset         ;Next, calculate the desired byte from the row.

LCEA2:  LDA DivNum1LB           ;Get the X position again for the overworld enemy grid.
LCEA4:  LSR                     ;/2 at the enemy data is stored in nibble wide data.
LCEA5:  CLC                     ;Add value to the Y position calculation.
LCEA6:  ADC EnemyOffset         ;
LCEA8:  TAX                     ;We now have the proper byte index into OvrWrldEnGrid.

LCEA9:  LDA OvrWrldEnGrid,X     ;Get the enemy zone data from OvrWrldEnGrid.
LCEAC:  STA EnemyOffset         ;

LCEAE:  LDA DivNum1LB           ;Since the enemy zone data is stored in nibbles, we need -->
LCEB0:  LSR                     ;to get the right nibble in the byte. Is this the right -->
LCEB1:  BCS +                   ;byte? If so, branch.

LCEB3:  LSR EnemyOffset         ;
LCEB5:  LSR EnemyOffset         ;Transfer upper nibble into the lower nibble.
LCEB7:  LSR EnemyOffset         ;
LCEB9:  LSR EnemyOffset         ;

LCEBB:* LDA EnemyOffset         ;Keep only the lower nibble. We now have the proper -->
LCEBD:  AND #$0F                ;data from OvrWrldEnGrid.
LCEBF:  BNE GetEnemyRow         ;

LCEC1:  JSR UpdateRandNum       ;($C55B)Get random number.

LCEC4:  LDA ThisTile            ;Is player in hilly terrain?
LCEC6:  CMP #BLK_HILL           ;If not, branch. Another check will be done to avoid a -->
LCEC8:  BNE NormFightModifier   ;fight. 50% chance the fight may not happen.

HighFightModifier:
LCECA:  LDA RandNumUB           ;Player is in hilly terrain. Increased chance of fight!
LCECC:  AND #$03                ;Do another check to avoid the fight. 25% chance the fight -->
LCECE:  BEQ GetEnemyRow         ;may not happen. Is fight going to happen?
LCED0:  RTS                     ;If so, branch to calculate which enemy.

NormFightModifier:
LCED1:  LDA RandNumUB           ;Player is not on hilly terrain.
LCED3:  AND #$01                ;Do another check to avoid the fight. 50% chance the fight -->
LCED5:  BEQ GetEnemyRow         ;may not happen. Is fight going to happen?
LCED7:  RTS                     ;If so, branch to calculate which enemy.

;This section of code calculates the proper enemies for the player's dungeon map position.

ChkDungeonFights:
LCED8:  CMP #MAP_DLCSTL_GF      ;Is player on ground floor of the dragonlord's castle?
LCEDA:  BNE ChkHauksnessFight   ;
LCEDC:  LDA #$10                ;If so, load proper offset to enemy data row in EnemyGroupsTbl.
LCEDE:  BNE GetEnemyRow         ;Branch always.

ChkHauksnessFight:
LCEE0:  CMP #MAP_HAUKSNESS      ;Is player in Hauksness?
LCEE2:  BNE ChkDLCastleFight    ;
LCEE4:  LDA #$0D                ;If so, load proper offset to enemy data row in EnemyGroupsTbl.
LCEE6:  BNE GetEnemyRow         ;Branch always.

ChkDLCastleFight:
LCEE8:  CMP #MAP_DLCSTL_BF      ;Is player on bottom floor of the dragonlord's castle?
LCEEA:  BNE ChkErdrickFight     ;
LCEEC:  LDA #$12                ;If so, load proper offset to enemy data row in EnemyGroupsTbl.
LCEEE:  BNE GetEnemyRow         ;Branch always.

ChkErdrickFight:
LCEF0:  CMP #MAP_ERDRCK_B1      ;Is player in Erdrick's cave?
LCEF2:  BCS NoEnemyMap          ;If so, branch to exit. No enemies here.

LCEF4:  LDA MapType             ;Is player in any one of the other dungeons?
LCEF6:  CMP #MAP_DUNGEON        ;If so, branch to calculate proper enemy row.
LCEF8:  BEQ DoDungeonEnemy      ;

NoEnemyMap:
LCEFA:  RTS                     ;No enemies on this map. Return without a fight.

DoDungeonEnemy:
LCEFB:  LDA MapNumber           ;
LCEFD:  SEC                     ;Convert map number into a value that can be used to find -->
LCEFE:  SBC #$0F                ;the index to the enemy data.
LCF00:  TAX                     ;
LCF01:  LDA CaveEnIndexTbl,X    ;Get enemy index data byte. points to a row in EnemyGroupsTbl.

GetEnemyRow:
LCF04:  STA EnemyOffset         ;This calculates the proper row of enemies to -->
LCF06:  ASL                     ;choose a fight from in EnemyGroupsTbl.
LCF07:  ASL                     ;
LCF08:  CLC                     ;
LCF09:  ADC EnemyOffset         ;EnemyOffset * 5. 5 enemy entries per row.
LCF0B:  STA EnemyOffset         ;

;All chances to evade the enemy has failed(except repel). Figure out which enemy to fight.
;At this point, we have the index to the row of enemies in EnemyGroupsTbl.

GetEnemyInRow:
LCF0D:  JSR UpdateRandNum       ;($C55B)Get random number.
LCF10:  LDA RandNumUB           ;
LCF12:  AND #$07                ;Keep only 3 LSBs. Is number between 0 and 4? If not, branch -->
LCF14:  CMP #$05                ;to get another random number as there are only 2 enemy slots -->
LCF16:  BCS GetEnemyInRow       ;per enemy zone.

LCF18:  ADC EnemyOffset         ;Add offset to the enemy row to get the specific enemy.
LCF1A:  TAX                     ;
LCF1B:  LDA EnemyGroupsTbl,X    ;
LCF1E:  STA _EnNumber           ;Store the enemy number and continue the fight preparations.

LCF20:  LDA MapNumber           ;Is player on the overworld map?
LCF22:  CMP #MAP_OVERWORLD      ;If so, there is a chance the fight can be repelled.
LCF24:  BNE ReadyFight          ;If not, branch to prepare the fight.

ChkFightRepel:
LCF26:  LDA RepelTimer          ;Is the repel spell active?
LCF28:  BEQ ReadyFight          ;If not, branch to start fight.

LCF2A:  LDA DisplayedDefns      ;
LCF2C:  LSR                     ;Get a copy of the player's defense / 2.
LCF2D:  STA GenByte3E           ;

LCF2F:  LDX _EnNumber           ;Get enemy's repel value from RepelTbl.
LCF31:  LDA RepelTbl,X          ;
LCF34:  SEC                     ;Is enemy's repel value less than DisplayedDefns/2?
LCF35:  SBC GenByte3E           ;
LCF37:  BCC RepelSucceeded      ;If so, branch.  Enemy was successfully repeled.

LCF39:  STA GenByte3E           ;Save difference between repel value and DisplayedDefns/2
LCF3B:  LDA RepelTbl,X          ;
LCF3E:  LSR                     ;
LCF3F:  CMP GenByte3E           ;Is repel value/2 < repel value - DisplayedDefns/2?
LCF41:  BCC ReadyFight          ;If not, branch to start fight. Repel unsuccessful.

RepelSucceeded:
LCF43:  RTS                     ;Repel scucceeded. Return without starting a fight.

ReadyFight:
LCF44:  LDA _EnNumber           ;Load random enemy to fight.
LCF46:  JMP InitFight           ;($E4DF)Begin fight sequence.

;----------------------------------------------------------------------------------------------------

DoNCCmdWindow:
LCF49:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCF4C:  LDA FrameCounter        ;
LCF4E:  AND #$0F                ;Sync window with frame counter.
LCF50:  CMP #$01                ;Is frame counter on the 16th frame?
LCF52:  BEQ ShowNCCmdWindow     ;If so, branch to show the non-combat command window.
LCF54:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LCF57:  JMP DoNCCmdWindow       ;($CF49)Loop until ready to show non-combat command window.

ShowNCCmdWindow:
LCF5A:  LDA #NPC_STOP           ;Stop NPCs from moving.
LCF5C:  STA StopNPCMove         ;

LCF5E:  JSR Dowindow            ;($C6F0)display on-screen window.
LCF61:  .byte WND_POPUP         ;Pop-up window.

LCF62:  JSR Dowindow            ;($C6F0)display on-screen window.
LCF65:  .byte WND_CMD_NONCMB    ;Command window, non-combat.

LCF66:  CMP #WND_ABORT          ;Did player abort the menu?
LCF68:  BNE NCCmdSelected       ;If not, branch.

ClrNCCmdWnd:
LCF6A:  LDA #WND_CMD_NONCMB     ;Remove command window from screen.
LCF6C:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LCF6F:  LDA #NPC_MOVE           ;
LCF71:  STA StopNPCMove         ;Allow NPCs to start moving around again.
LCF73:  RTS                     ;

NCCmdSelected:
LCF74:  LDA WndSelResults       ;Did player select STATUS?
LCF76:  CMP #NCC_STATUS         ;If not, branch to check other selections.
LCF78:  BNE CheckCmdWndResults  ;($CFAF)Check some command window selection results.

LCF7A:  JSR LoadStats           ;($F050)Update player attributes.
LCF7D:  JSR IncDescBuffer       ;($D92E)Write #$01-#$0A to the description buffer

LCF80:  LDA EqippedItems        ;
LCF82:  LSR                     ;
LCF83:  LSR                     ;
LCF84:  LSR                     ;Move equipped weapon to 3 LSBs.
LCF85:  LSR                     ;Value range is #$09-#$10.
LCF86:  LSR                     ;
LCF87:  CLC                     ;
LCF88:  ADC #$09                ;
LCF8A:  STA DescBuf+$8          ;

LCF8C:  LDA EqippedItems        ;
LCF8E:  LSR                     ;
LCF8F:  LSR                     ;Move equipped armor to 3 LSBs.
LCF90:  AND #$07                ;Value range is #$11-#$18.
LCF92:  CLC                     ;
LCF93:  ADC #$11                ;
LCF95:  STA DescBuf+$9          ;

LCF97:  LDA EqippedItems        ;
LCF99:  AND #$03                ;Move equipped shield to 2 LSBs.
LCF9B:  CLC                     ;Value range is #$19-#$1C.
LCF9C:  ADC #$19                ;
LCF9E:  STA DescBuf+$A          ;

LCFA0:  JSR Dowindow            ;($C6F0)display on-screen window.
LCFA3:  .byte WND_STATUS        ;Status window.

LCFA4:  JSR WaitForBtnRelease   ;($CFE4)Wait for player to release then press joypad buttons.

LCFA7:  LDA #WND_STATUS         ;Remove status window from screen.
LCFA9:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LCFAC:  JMP ClrNCCmdWnd         ;($CF6A)Remove non-combat command window from screen.

;----------------------------------------------------------------------------------------------------

CheckCmdWndResults:
LCFAF:  CMP #NCC_TALK           ;Did player select TALK from menu? If so, branch.
LCFB1:  BEQ CheckTalk           ;($CFF9)Talk selected from command menu.

LCFB3:  CMP #NCC_STAIRS         ;Did player select STAIRS from menu?
LCFB5:  BNE +                   ;If not, branch.
LCFB7:  JMP CheckStairs         ;($D9AF)Stairs selected from command window.

LCFBA:* CMP #NCC_DOOR           ;Did player select DOOR from menu?
LCFBC:  BNE +                   ;If not, branch.
LCFBE:  JMP CheckDoor           ;($DC42)Door selected from command menu.

LCFC1:* CMP #NCC_SPELL          ;Did player select SPELL from menu?
LCFC3:  BNE +                   ;If not, branch.
LCFC5:  JMP DoSpell             ;($DA11)Spell selected from command menu.

LCFC8:* CMP #NCC_ITEM           ;Did player select ITEM from menu?
LCFCA:  BNE +                   ;If not, branch.
LCFCC:  JMP CheckInventory      ;($DC1B)Item selected from command window.

LCFCF:* CMP #NCC_SEARCH         ;Did player select SEARCH from menu?
LCFD1:  BNE +                   ;If not, branch.
LCFD3:  JMP DoSearch            ;($E103)Search selected from command window.

LCFD6:* JMP DoTake              ;($E1E3)Take selected from command window.

ResumeGamePlay:
LCFD9:  JSR WaitForBtnRelease   ;($CFE4)Wait for player to release then press joypad buttons.
LCFDC:  LDA #WND_DIALOG         ;Remove dialog window from screen.
LCFDE:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LCFE1:  JMP ClrNCCmdWnd         ;($CF6A)Remove non-combat command window from screen.

;----------------------------------------------------------------------------------------------------

WaitForBtnRelease:
LCFE4:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCFE7:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LCFEA:  LDA JoypadBtns          ;
LCFEC:  BNE WaitForBtnRelease   ;Loop until no joypad buttons are pressed.

WaitForBtnPress:
LCFEE:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LCFF1:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LCFF4:  LDA JoypadBtns          ;
LCFF6:  BEQ WaitForBtnPress     ;Loop until any joypad button is pressed.
LCFF8:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckTalk:
LCFF9:  LDA CharDirection       ;Get current direction player is facing.
LCFFC:  PHA                     ;

LCFFD:  JSR Dowindow            ;($C6F0)display on-screen window.
LD000:  .byte WND_DIALOG        ;Dialog window.

LD001:  LDA CharXPos            ;
LD003:  STA XTarget             ;Make a copy of the player's X and Y coordinates.
LD005:  LDA CharYPos            ;
LD007:  STA YTarget             ;

CheckFacingUp:
LD009:  PLA                     ;Get player's direction.
LD00A:  BNE CheckFacingRight    ;Is player facing up? If not branch to check other directions.

LD00C:  DEC YTarget             ;Get position above player.
LD00E:  JSR GetBlockID          ;($AC17)Get description of block.
LD011:  LDA TargetResults       ;
LD013:  CMP #BLK_LRG_TILE       ;Is player facing a store counter?
LD015:  BNE DoTalkResults       ;If not, branch to check for an NPC.

LD017:  DEC _TargetY            ;Set talk target for block beyond shop counter.
LD019:  JMP DoTalkResults       ;

CheckFacingRight:
LD01C:  CMP #DIR_RIGHT          ;Is player facing right?
LD01E:  BNE CheckFacingDown     ;If not branch to check other directions.

LD020:  INC XTarget             ;Get position to right of player.
LD022:  JSR GetBlockID          ;($AC17)Get description of block.
LD025:  LDA TargetResults       ;
LD027:  CMP #BLK_LRG_TILE       ;Is player facing a store counter?
LD029:  BNE DoTalkResults       ;

LD02B:  INC _TargetX            ;Set talk target for block beyond shop counter.
LD02D:  JMP DoTalkResults       ;

CheckFacingDown:
LD030:  CMP #DIR_DOWN           ;Is player facing down?
LD032:  BNE DoFacingLeft        ;If not branch to check other directions.

LD034:  INC YTarget             ;Get position below player.
LD036:  JSR GetBlockID          ;($AC17)Get description of block.
LD039:  LDA TargetResults       ;
LD03B:  CMP #BLK_LRG_TILE       ;Is player facing a store counter?
LD03D:  BNE DoTalkResults       ;If not, branch to check for an NPC.

LD03F:  INC _TargetY            ;Set talk target for block beyond shop counter.
LD041:  JMP DoTalkResults       ;

DoFacingLeft:
LD044:  DEC XTarget             ;Player must be facing left.
LD046:  JSR GetBlockID          ;($AC17)Get description of block.
LD049:  LDA TargetResults       ;
LD04B:  CMP #BLK_LRG_TILE       ;Is player facing a store counter?
LD04D:  BNE DoTalkResults       ;If not, branch to check for an NPC.

LD04F:  DEC _TargetX            ;Set talk target for block beyond shop counter.

;----------------------------------------------------------------------------------------------------

DoTalkResults:
LD051:  LDA TargetResults       ;Is the player talking to the princess in the swamp cave?
LD053:  CMP #BLK_PRINCESS       ;
LD055:  BNE CheckNPCTalk        ;If not, branch to check the NPCs.

LD057:  LDA _TargetX            ;
LD059:  PHA                     ;Save the X and Y coordinates of princess Gwaelin.
LD05A:  LDA _TargetY            ;
LD05C:  PHA                     ;

DoGwaelinRescue:
LD05D:  JSR DoDialogLoBlock     ;($C7CB)Though art brave to rescue me, I'm Gwaelin...
LD060:  .byte $B5               ;TextBlock12, entry 5.

PrincessRescueLoop:
LD061:  JSR DoDialogLoBlock     ;($C7CB)Will thou take me to the castle...
LD064:  .byte $C5               ;TextBlock13, entry 5.

LD065:  JSR Dowindow            ;($C6F0)display on-screen window.
LD068:  .byte WND_YES_NO1       ;Yes/No selection window.

LD069:  BEQ +                   ;Branch if player agrees to take Gwaelin along.

LD06B:  JSR DoDialogLoBlock     ;($C7CB)But thou must...
LD06E:  .byte $B6               ;TextBlock12, entry 6.

JMP PrincessRescueLoop          ;($D061)Loop until the player agrees to take Gwaelin.

LD072:* LDA PlayerFlags         ;
LD074:  ORA #F_GOT_GWAELIN      ;Set flag indicating player is holding Gwaelin.
LD076:  STA PlayerFlags         ;
LD078:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LD07B:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LD07E:  PLA                     ;Restore Gwaelin's Y position.
LD07F:  SEC                     ;
LD080:  SBC CharYPos            ;Get the Y position difference from player.
LD082:  ASL                     ;Convert block position to tile position.
LD083:  STA YPosFromCenter      ;Y position of block to remove.

LD085:  PLA                     ;Restore Gwaelin's X position.
LD086:  SEC                     ;
LD087:  SBC CharXPos            ;Get the X position difference from player.
LD089:  ASL                     ;Convert block position to tile position.
LD08A:  STA XPosFromCenter      ;X position of block to remove.

LD08C:  LDA #$00                ;Remove all 4 princess blocks from screen.
LD08E:  STA BlkRemoveFlgs       ;
LD090:  JSR ModMapBlock         ;($AD66)Change block on map.

LD093:  JSR DoDialogLoBlock     ;($C7CB)Princess Gwaelin embraces thee.
LD096:  .byte $B7               ;TextBlock12, entry 7.

LD097:  LDA #MSC_PRNCS_LOVE     ;Gwaelin's love music.
LD099:  BRK                     ;
LD09A:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LD09C:  BRK                     ;Wait for the music clip to end.
LD09D:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LD09F:  LDA #MSC_DUNGEON1       ;Dungeon 1 music.
LD0A1:  BRK                     ;
LD0A2:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LD0A4:  LDA #$B8                ;TextBlock12, entry 8.
LD0A6:  JMP DoFinalDialog       ;($D242)I'm so happy...

;----------------------------------------------------------------------------------------------------

CheckNPCTalk:
LD0A9:  LDY #$00                ;Prepare to loop through all NPC slots.

NPCTalkLoop:
LD0AB:  LDA _NPCXPos,Y          ;Check NPCs Y position.
LD0AE:  AND #$1F                ;Widest map is only 32 blocks.
LD0B0:  CMP _TargetX            ;Is the X position valid?
LD0B2:  BNE CheckNextNPC        ;If not, branch to check the next NPC slot.

LD0B4:  LDA _NPCYPos,Y          ;Check NPCs X position.
LD0B7:  AND #$1F                ;Tallest map is only 32 blocks.
LD0B9:  CMP _TargetY            ;Is the Y position valid?
LD0BB:  BNE CheckNextNPC        ;If not, branch to check the next NPC slot.

LD0BD:  LDA _NPCXPos,Y          ;Make sure the NPC slot contains a valid NPC and-->
LD0C0:  BNE JmpValidateNPC      ;is not empty.  If all 3 bytes are 0, the slot is-->
LD0C2:  LDA _NPCYPos,Y          ;empty.
LD0C5:  BNE JmpValidateNPC      ;
LD0C7:  LDA _NPCMidPos,Y        ;
LD0CA:  BNE JmpValidateNPC      ;
LD0CC:  JMP NoTalk              ;($D1ED)No one to talk to in that direction.

JmpValidateNPC:
LD0CF:  JMP ValidateNPC         ;($D0DC)Do more checks to ensure valid NPC.

CheckNextNPC:
LD0D2:  INY                     ;
LD0D3:  INY                     ;Move to next NPC(3 bytes per NPC).
LD0D4:  INY                     ;

LD0D5:  CPY #$3C                ;Have all 20 NPC slots been checked?
LD0D7:  BNE NPCTalkLoop         ;If not, branch to check the next slot.

LD0D9:  JMP NoTalk              ;($D1ED)No one to talk to in that direction.

;----------------------------------------------------------------------------------------------------

ValidateNPC:
LD0DC:  STY NPCOffset           ;Get NPC offset.
LD0DE:  CPY #$1E                ;Lower NPC slots are for moving NPCs.
LD0E0:  BCC CheckMobNPC         ;If lower slot, branch to check for valid mobile NPC.

LD0E2:  TYA                     ;
LD0E3:  SEC                     ;This is a static NPC.  Move offset down in preparation-->
LD0E4:  SBC #$1C                ;to calculate the index into the NPCStatPtrTbl.
LD0E6:  TAY                     ;

LD0E7:  LDA MapNumber           ;Subtract 4 from the map number and make sure it is-->
LD0E9:  SEC                     ;less than or equal to 11.
LD0EA:  SBC #$04                ;This is because valid NPCs are only on map numbers-->
LD0EC:  CMP #$0B                ;4 through 14.
LD0EE:  BCC GetStatNPCPtr       ;Check for valid static NPC.

LD0F0:  JMP NoTalk              ;($D1ED)No one to talk to in that direction.

GetStatNPCPtr:
LD0F3:  ASL                     ;*2. Pointers into NPC tables are 2 bytes.
LD0F4:  TAX                     ;

LD0F5:  LDA NPCStatPtrTbl,X     ;
LD0F8:  STA GenPtr3CLB          ;Get pointer to static NPC for the current map.
LD0FA:  LDA NPCStatPtrTbl+1,X   ;
LD0FD:  STA GenPtr3CUB          ;
LD0FF:  JMP PrepTalk            ;($D11C)Do next phase of NPC dialog.

CheckMobNPC:
LD102:  INY                     ;+2. Need to check 3rd byte in table entry.
LD103:  INY                     ;

LD104:  LDA MapNumber           ;Subtract 4 from the map number and make sure it is-->
LD106:  SEC                     ;less than or equal to 11.
LD107:  SBC #$04                ;This is because valid NPCs are only on map numbers-->
LD109:  CMP #$0B                ;4 through 14.
LD10B:  BCC GetMobNPCPtr        ;Check for valid mobile NPC.

LD10D:  JMP NoTalk              ;($D1ED)No one to talk to in that direction.

GetMobNPCPtr:
LD110:  ASL                     ;*2. Pointers into NPC tables are 2 bytes.
LD111:  TAX                     ;

LD112:  LDA NPCMobPtrTbl,X      ;
LD115:  STA GenPtr3CLB          ;Get pointer to mobile NPC for the current map.
LD117:  LDA NPCMobPtrTbl+1,X    ;
LD11A:  STA GenPtr3CUB          ;

PrepTalk:
LD11C:  LDA NPCOffset           ;Get target NPC number.
LD11E:  JSR NPCFacePlayer       ;($C04A)Make the NPC face the player.

LD121:  TYA                     ;Save NPC index on stack.
LD122:  PHA                     ;

LD123:  LDA GenPtr3CLB          ;
LD125:  PHA                     ;Save NPC data pointer on stack.
LD126:  LDA GenPtr3CUB          ;
LD128:  PHA                     ;

LD129:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LD12C:  PLA                     ;
LD12D:  STA GenPtr3CUB          ;Restore NPC data pointer from stack.
LD12F:  PLA                     ;
LD130:  STA GenPtr3CLB          ;

LD132:  PLA                     ;Restore NPC index from stack.
LD133:  TAY                     ;

LD134:  LDA StoryFlags          ;Is the dragonlord dead?
LD136:  AND #F_DGNLRD_DEAD      ;
LD138:  BEQ RegularDialog       ;If not, branch for normal dialog.

LD13A:  LDA MapNumber           ;
LD13C:  CMP #MAP_TANTCSTL_GF    ;Is player in Tantgel castle after defeating the dragonlord?
LD13E:  BNE TantEndDialog       ;If not, branch to do other post dragonlord dialog.

LD140:  JSR DoDialogHiBlock     ;($C7C5)King Lorik awaits...
LD143:  .byte $21               ;TextBlock19, entry 1

LD144:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

TantEndDialog:
LD147:  LDA (GenPtr3C),Y        ;There is a NPC who was looking for Gwaelin and is almost-->
LD149:  CMP #$64                ;dead.  I guess he finally dies when the dragonlord is defeated.
LD14B:  BNE RandEndDialog       ;Branch if not talking to that one specific NPC.

LD14D:  JSR DoDialogHiBlock     ;($C7C5)"...."
LD150:  .byte $15               ;TextBlock18, entry 5.

LD151:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

RandEndDialog:
LD154:  JSR UpdateRandNum       ;($C55B)Get a random number.
LD157:  LDA RandNumUB           ;
LD159:  LSR                     ;Randomly choose text based on the LSB of-->
LD15A:  BCC AlternateDialog     ;the number if the dragonlord is dead.

LD15C:  JSR DoDialogHiBlock     ;($C7C5)Hurray! Hurray!...
LD15F:  .byte $1F               ;TextBlock18, entry 15. 

LD160:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

AlternateDialog:
LD163:  JSR DoDialogHiBlock     ;($C7C5)Thou has brought us peace...
LD166:  .byte $20               ;TextBlock19, entry 0.

LD167:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

RegularDialog:
LD16A:  LDA (GenPtr3C),Y        ;Is this weapon shop dialog?
LD16C:  CMP #$07                ;If so, jump to do weapon shop dialog.
LD16E:  BCS +                   ;
LD170:  JMP WeaponsDialog       ;($D553)Weapon shop dialog.

LD173:* CMP #$0C                ;Is this tool shop dialog?
LD175:  BCS +                   ;If so, jump to do tool shop dialog.
LD177:  JMP ToolsDialog         ;($D6A7)Tool shop dialog.

LD17A:* CMP #$0F                ;Is this key shop dialog?
LD17C:  BCS +                   ;If so, jump to do key shop dialog.
LD17E:  JMP KeysDialog          ;($D7ED)Key shop dialog.

LD181:* CMP #$11                ;Is this fairy water shop dialog?
LD183:  BCS +                   ;If so, jump to do fairy water shop dialog.
LD185:  JMP FairyDialog         ;($D843)Fairy water shop dialog.

LD188:* CMP #$16                ;Is this inn dialog?
LD18A:  BCS +                   ;If so, jump to do inn dialog.
LD18C:  JMP InnDialog           ;($D895)Inn dialog.

LD18F:* CMP #$5E                ;Is this other misc. dialog?
LD191:  BCS CheckYesNoDialog    ;($D1C5)If so, branch to break the dialog down further.

;----------------------------------------------------------------------------------------------------

;From here, dialog between #$16 and #$5D is processed. 

LD193:  PHA                     ;Save dialog control byte on stack.

LD194:  LDA PlayerFlags         ;Has the player left the throne room for the first time yet?
LD196:  AND #F_LEFT_THROOM      ;
LD198:  BNE DoVariousDialog1    ;If so, branch.

LD19A:  PLA                     ;Is this one of the throne room stationary guards?
LD19B:  CMP #$23                ;
LD19D:  BNE ThrnRmDialog2       ;If not, branch to check other guard.

LD19F:  JSR DoDialogHiBlock     ;($C7C5)East of this castle is a town...
LD1A2:  .byte $01               ;TextBlock17, entry 1.

LD1A3:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ThrnRmDialog2:
LD1A6:  CMP #$24                ;Is this the other throne room stationary guard?
LD1A8:  BNE DoVariousDialog2    ;If not, branch.

LD1AA:  JSR DoDialogHiBlock     ;($C7C5)In a treasure chest a key will be found...
LD1AD:  .byte $00               ;TextBlock17, entry 0.

LD1AE:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

DoVariousDialog1:
LD1B1:  PLA                     ;Save a copy of the dialog control byte on the stack.

DoVariousDialog2:
LD1B2:  PHA                     ;Restore dialog control byte.
LD1B3:  CLC                     ;
LD1B4:  ADC #$2F                ;Add offset to the byte to find proper text block entry.
LD1B6:  JSR DoMidDialog         ;($C7BD)Do any number of Dialogs.

LD1B9:  PLA                     ;Is this TextBlock5, entry 9 which talks about the legend-->
LD1BA:  CMP #$1A                ;of the rainbow bridge?
LD1BC:  BNE EndVariousDialog    ;If not, branch to exit dialog routine.

LD1BE:  JSR DoDialogLoBlock     ;($C7CB)It's a legend...
LD1C1:  .byte $B0               ;TextBlock12, entry 0.

EndVariousDialog:
LD1C2:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

CheckYesNoDialog:
LD1C5:  CMP #$62                ;Is this Dialog wih a yes/no window?
LD1C7:  BCS ChkPrncsDialog1     ;If not, branch to check for various princess dialog.

LD1C9:  CLC                     ;Calculate proper text block for yes/no dialog.
LD1CA:  ADC #$2F                ;Store a copy of the dialog control byte.
LD1CC:  STA DialogTemp          ;
LD1CE:  JSR DoMidDialog         ;($C7BD)TextBlock9, entry 13 - TextBlock10, entry 0.

LD1D1:  JSR Dowindow            ;($C6F0)display on-screen window.
LD1D4:  .byte WND_YES_NO1       ;Yes/no selection window.

LD1D5:  BNE NoRespDialog        ;Did player select yes? If so, branch.

YesRespDialog:
LD1D7:  LDA DialogTemp          ;Get "yes" dialog response.
LD1D9:  CLC                     ;
LD1DA:  ADC #$05                ;
LD1DC:  JSR DoMidDialog         ;($C7BD)TextBlock10, entries 1 - 4.

LD1DF:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

NoRespDialog:
LD1E2:  LDA DialogTemp          ;Get "no" dialog response.
LD1E4:  CLC                     ;
LD1E5:  ADC #$0A                ;
LD1E7:  JSR DoMidDialog         ;($C7BD)TextBlock10, entries 5 - 8.

LD1EA:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

NoTalk:
LD1ED:  JSR DoDialogLoBlock     ;($C7CB)There is no one there...
LD1F0:  .byte $0F               ;TextBlock1, entry 15.

LD1F1:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkPrncsDialog1:
LD1F4:  BNE ChkPrncsDialog2     ;Talkging to the guard looking for Gwaelin? if not, branch.

LD1F6:  LDA PlayerFlags         ;Has Gwaelin been returned or being carried?
LD1F8:  AND #F_DONE_GWAELIN     ;
LD1FA:  BNE PrincessSaved1      ;If so, branch.

PrincessNotSaved:
LD1FC:  LDA #$9B                ;TextBlock10, entry 11.
LD1FE:  BNE DoFinalDialog       ;($D242)Where oh where can I find princess Gwaelin...

PrincessSaved1:
LD200:  LDA #$9C                ;TextBlock10, entry 12.
LD202:  BNE DoFinalDialog       ;($D242)Thank you for saving the princess...

ChkPrncsDialog2:
LD204:  CMP #$63                ;Check for another princess dialog.
LD206:  BNE ChkPrncsDialog3     ;

LD208:  LDA PlayerFlags         ;Has the princess been saved?
LD20A:  AND #F_DONE_GWAELIN     ;
LD20C:  BEQ PrincessNotSaved    ;If not, branch.

LD20E:  LDA #$9D                ;TextBlock10, entry 13.
LD210:  BNE DoFinalDialog       ;($D242)My dearest Gwaelin! I hate thee...

ChkPrncsDialog3:
LD212:  CMP #$64                ;Check for another princess dialog.
LD214:  BNE ChkPrncsDialog4     ;

LD216:  LDA PlayerFlags         ;Has the princess been saved?
LD218:  AND #F_DONE_GWAELIN     ;
LD21A:  BNE PrincessSaved2      ;If so, branch.

LD21C:  LDA #$9E                ;TextBlock10, entry 14.
LD21E:  BNE DoFinalDialog       ;($D242)Tell the king the search for his daughter has failed...

PrincessSaved2:
LD220:  LDA #$9F                ;TextBlock10, entry 15.
LD222:  BNE DoFinalDialog       ;($D242)Who touches me? I cannot see or hear...

ChkPrncsDialog4:
LD224:  CMP #$65                ;Check for another princess dialog.
LD226:  BNE WzdGuardDialog      ;If not princess dialog, branch to next dialog type.

LD228:  LDA PlayerFlags         ;Has the princess been saved?
LD22A:  AND #F_DONE_GWAELIN     ;
LD22C:  BNE PrincessSaved3      ;If so, branch.

LD22E:  JSR DoDialogLoBlock     ;($C7CB)Dost thou know about princess Gwaelin...
LD231:  .byte $A0               ;TextBlock11, entry 0.

LD232:  JSR Dowindow            ;($C6F0)display on-screen window.
LD235:  .byte WND_YES_NO1       ;Yes/No selection window.

LD236:  BEQ SavePrincessDialog  ;Player has heard about the princess.  Branch to skip.

LD238:  JSR DoDialogLoBlock     ;($C7CB)Half a year has passed since the princess was kidnapped...
LD23B:  .byte $A1               ;TextBlock11, entry 1.

SavePrincessDialog:
LD23C:  LDA #$A2                ;TextBlock11, entry 2.
LD23E:  BNE DoFinalDialog       ;($D242)Please save the princess...

PrincessSaved3:
LD240:  LDA #$A3                ;TextBlock11, entry 3. Oh, brave player...

;----------------------------------------------------------------------------------------------------

DoFinalDialog:
LD242:  JSR DoMidDialog         ;($C7BD)Call dialog function.
LD245:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

WzdGuardDialog:
LD248:  CMP #$66                ;Is the player talking to a chest guarding wizard?
LD24A:  BNE ChkCursedDialog     ;If not, branch.

LD24C:  LDA #ITM_STNS_SNLGHT    ;Check if stones of sunlight are already in possesion.
LD24E:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD251:  CMP #ITM_NOT_FOUND      ;
LD253:  BNE HaveUniqueItem      ;If so, branch to display "go away" message.

LD255:  LDA #ITM_RNBW_DROP      ;Check if rainbow drop is already in possesion.
LD257:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD25A:  CMP #ITM_NOT_FOUND      ;
LD25C:  BNE HaveUniqueItem      ;If so, branch to display "go away" message.

LD25E:  JSR DoDialogLoBlock     ;($C7CB)I have been waiting long for someone such as thee...
LD261:  .byte $A4               ;TextBlock11, entry 4.

LD262:  LDA #$C6                ;TextBlock13, entry 6.
LD264:  BNE DoFinalDialog       ;($D242)Take the treasure chest...

HaveUniqueItem:
LD266:  LDA #$A5                ;TextBlock11, entry 5.
LD268:  BNE DoFinalDialog       ;($D242)Though hast no business here. Go away...

;----------------------------------------------------------------------------------------------------

ChkCursedDialog:
LD26A:  CMP #$67                ;Is the player taling to the curse remover?
LD26C:  BNE ChkWeaponDialog     ;If not, branch.

LD26E:  LDA ModsnSpells         ;Is the player cursed?
LD270:  AND #$C0                ;
LD272:  BNE CursedDialog        ;If so, branch to curse removal dialog.

LD274:  LDA #$A6                ;TextBlock11, entry 6.
LD276:  BNE DoFinalDialog       ;($D242)If thou art cursed, come again...

CursedDialog:
LD278:  JSR DoDialogLoBlock     ;($C7CB)I will free thee from thy curse...
LD27B:  .byte $A7               ;TextBlock11, entry 7.

LD27C:  LDA ModsnSpells         ;Is player cursed by the death necklace?
LD27E:  BPL RemoveCrsBelt       ;If not, branch.

LD280:  LDA #ITM_DTH_NEKLACE    ;Remove death necklace from inventory.
LD282:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

RemoveCrsBelt:
LD285:  BIT ModsnSpells         ;Is player cursed by the cursed belt?
LD287:  BVC ClearCurseFlags     ;If not, branch.

LD289:  LDA #ITM_CRSD_BELT      ;Remove cursed belt from inventory. 
LD28B:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

ClearCurseFlags:
LD28E:  LDA ModsnSpells         ;
LD290:  AND #$3F                ;Clear cursed status flags from player.
LD292:  STA ModsnSpells         ;

LD294:  LDA #$A8                ;TextBlock11, entry 8.
LD296:  BNE DoFinalDialog       ;($D242)Now, go...

;----------------------------------------------------------------------------------------------------

ChkWeaponDialog:
LD298:  CMP #$68                ;Is the player talking to the weapon identifying wizard?
LD29A:  BNE ChkRingDialog       ;If not, branch.

LD29C:  LDA EqippedItems        ;Does the player have Erdrick's sword?
LD29E:  AND #WP_WEAPONS         ;
LD2A0:  CMP #WP_ERDK_SWRD       ;
LD2A2:  BEQ GotSwordDialog      ;If so, branch.

LD2A4:  LDA #$A9                ;TextBlock11, entry 9.
LD2A6:  BNE DoFinalDialog       ;($D242)Thou cannot defeat the dragonlord with such weapons...

GotSwordDialog:
LD2A8:  LDA #$AA                ;TextBlock11, entry 10.
LD2AA:  BNE DoFinalDialog       ;($D242)Finally, thou hast obtained it, player...

;----------------------------------------------------------------------------------------------------

ChkRingDialog:
LD2AC:  CMP #$69                ;Is player talking to the ring identifying NPC?
LD2AE:  BNE ChkMagicDialog      ;If not, branch.

LD2B0:  LDA #ITM_FTR_RING       ;Does player have the fighter's ring in inventory?
LD2B2:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD2B5:  CMP #ITM_NOT_FOUND      ;
LD2B7:  BNE RingInInventory     ;If so, branch.

LD2B9:  LDA ModsnSpells         ;
LD2BB:  AND #$DF                ;Remove fighter's ring equipped status if it is not in inventory.
LD2BD:  STA ModsnSpells         ;

RingInInventory:
LD2BF:  LDA ModsnSpells         ;
LD2C1:  AND #F_FTR_RING         ;Branch if wearing the fighter's ring.
LD2C3:  BNE WearingRing         ;

LD2C5:  LDA #$AC                ;TextBlock11, entry 12. 
LD2C7:  JMP DoFinalDialog       ;($D242)All true warriors wear a ring...

WearingRing:
LD2CA:  LDA #$AB                ;TextBlock11, entry 11. 
LD2CC:  JMP DoFinalDialog       ;($D242)Is that a wedding ring...

;----------------------------------------------------------------------------------------------------

ChkMagicDialog:
LD2CF:  CMP #$6A                ;Is player talking to the MP restoring wizard?
LD2D1:  BNE ErdTknDialog        ;If not, branch.

LD2D3:  JSR DoDialogLoBlock     ;($C7CB)Player's coming was foretold by legend...
LD2D6:  .byte $AD               ;TextBlock11, entry 13.

LD2D7:  JSR BWScreenFlash       ;($DB37)Flash screen in black and white.
LD2DA:  LDA DisplayedMaxMP      ;
LD2DC:  STA MagicPoints         ;Max out player's MP.

LD2DE:  JSR Dowindow            ;($C6F0)display on-screen window.
LD2E1:  .byte WND_POPUP         ;Pop-up window.

LD2E2:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ErdTknDialog:
LD2E5:  CMP #$6B                ;Is the player talking to the Erdrick's token NPC?
LD2E7:  BNE RainStaffDialog     ;If not, branch.

LD2E9:  JSR DoDialogLoBlock     ;($C7CB)Let us wish the warrior well...
LD2EC:  .byte $4C               ;TextBlock5, entry 12.

LD3ED:  JSR DoDialogLoBlock     ;($C7CB)Thou may go and search...
LD2F0:  .byte $AE               ;TextBlock11, entry 14

LD2F1:  JSR DoDialogLoBlock     ;($C7CB)
LD2F4:  .byte $AF               ;TextBlock11, entry 15.

LD2F5:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

RainStaffDialog:
LD2F8:  CMP #$6C                ;Is the player talking to the staff of rain guardian?
LD2FA:  BNE RnbwDrpDialog       ;If not, branch.

LD2FC:  LDA #ITM_RNBW_DROP      ;Does the player already have the rainbow drop?
LD2FE:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD301:  CMP #ITM_NOT_FOUND      ;
LD303:  BNE HaveItemDialog      ;If so, branch.

LD305:  LDA #ITM_STFF_RAIN      ;Does the player already have the staff of rain?
LD307:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD30A:  CMP #ITM_NOT_FOUND      ;
LD30C:  BEQ ChkSlvrHarp         ;If so, branch.

HaveItemDialog:
LD30E:  LDA #$A5                ;TextBlock11, entry 5. Thou hast no business here...

NoItemGive:
LD310:  JSR DoMidDialog         ;($C7BD)Display dialog on screen.
LD313:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkSlvrHarp:
LD316:  LDA #ITM_SLVR_HARP      ;Does the player have the silver harp?
LD318:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD31B:  CMP #ITM_NOT_FOUND      ;
LD31D:  BEQ HarpNotFound        ;If not, branch.

LD31F:  JSR DoDialogLoBlock     ;($C7CB)It's a legend...
LD322:  .byte $B2               ;TextBlock12, entry 2.

LD323:  JSR DoDialogLoBlock     ;($C7CB)I have been waiting long for thee...
LD326:  .byte $A4               ;TextBlock11, entry 4.

LD327:  JSR DoDialogLoBlock     ;($C7CB)Take the treasure chest...
LD32A:  .byte $C6               ;TextBlock13, entry 6.

LD32B:  LDA #ITM_SLVR_HARP      ;Remove silver harp from inventory.
LD32D:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LD330:  LDA #$00                ;
LD332:  STA NPCXPos+$1E         ;Remove NPC from screen.
LD334:  STA NPCYPos+$1E         ;
LD336:  STA NPCMidPos+$1E       ;

LD338:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LD33B:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LD33E:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

HarpNotFound:
LD341:  LDA #$B1                ;TextBlock12, entry 1.
LD343:  BNE NoItemGive          ;Thy bravery must be proven, thus I propose a test...

;----------------------------------------------------------------------------------------------------

RnbwDrpDialog:
LD345:  CMP #$6D                ;Is the player talking to the rainbow drop guardian?
LD347:  BNE KingDialog          ;If not, branch.

LD349:  LDA #ITM_RNBW_DROP      ;Does player already have the rainbow drop?
LD34B:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD34E:  CMP #ITM_NOT_FOUND      ;
LD350:  BNE HaveItemDialog      ;If so, branch.

LD352:  LDA #ITM_ERDRICK_TKN    ;Does the player have Erdrick's token?
LD354:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD357:  CMP #ITM_NOT_FOUND      ;
LD359:  BNE HaveErdToken        ;If so, branch.

LD35B:  JSR DoDialogLoBlock     ;($C7CB)In thy task thou hast failed...
LD35E:  .byte $B3               ;TextBlock12, entry 3.

LD35F:  JSR BWScreenFlash       ;($DB37)Flash screen in black and white.
LD362:  JMP CheckMapExit        ;($B228)Force player to exit the map.

HaveErdToken:
LD365:  LDA #ITM_STNS_SNLGHT    ;Does the player have the stones of sunlight?
LD367:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD36A:  CMP #ITM_NOT_FOUND      ;
LD36C:  BEQ NoRnbwDrpDialog     ;If not, branch.

LD36E:  LDA #ITM_STFF_RAIN      ;Does the player have the staff of rain?
LD370:  JSR CheckForInvItem     ;($E055)Check inventory for item.
LD373:  CMP #ITM_NOT_FOUND      ;
LD375:  BEQ NoRnbwDrpDialog     ;If not, branch.

LD377:  JSR DoDialogLoBlock     ;($C7CB)Now the sun and rain shall meet...
LD37A:  .byte $B4               ;TextBlock12, entry 4.

LD37B:  LDA #ITM_STNS_SNLGHT    ;Remove the stones of sunlight from inventory.
LD37D:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LD380:  LDA #ITM_STFF_RAIN      ;Remove the staff of rain from inventory.
LD382:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LD385:  LDA #ITM_RNBW_DROP      ;Add rainbow drop to inventory.
LD387:  JSR AddInvItem          ;($E01B)Add item to inventory.

LD38A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LD38D:  LDA #%00011001          ;
LD38F:  STA PPUControl1         ;Set display to greyscale colors.

LD392:  LDX #$1E                ;make screen greyscale for 30 frames.
LD394:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LD397:  DEX                     ;Done with black and screen?
LD398:  BNE -                   ;If not, branch to do another frame.

LD39A:  LDA #%00011000          ;Set display to RGB colors.
LD39C:  STA PPUControl1         ;

LD39F:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

NoRnbwDrpDialog:
LD3A2:  JSR DoDialogLoBlock     ;($C7CB)When the sun and rain meet, a bridge will appear...
LD3A5:  .byte $49               ;TextBlock5, entry 9.

LD3A6:  LDA #$AE                ;TextBlock11, entry 14. I have been waiting long for thee...
LD3A8:  JMP NoItemGive          ;($D310)Player does not meet requirements to get rainbow drop.

;----------------------------------------------------------------------------------------------------

KingDialog:
LD3AB:  CMP #$6E                ;Is the player talking to the king?
LD3AD:  BEQ DoKingDialog        ;If so, branch.
LD3AF:  JMP PrincessDialog      ;Else check if player is talking to the princess.

DoKingDialog:
LD3B2:  LDA PlayerFlags         ;Is the player carrying Gwaelin?
LD3B4:  AND #F_GOT_GWAELIN      ;
LD3B6:  BEQ KingDialog2         ;If not, branch.

LD3B8:  JSR DoDialogLoBlock     ;($C7CB)I am grateful for my daughter's return...
LD3BB:  .byte $B9               ;TextBlock12, entry 9.

LD3BC:  LDA #ITM_GWAELIN_LVE    ;Try to give player Gwaelin's love.
LD3BE:  JSR AddInvItem          ;($E01B)Add item to inventory.

LD3C1:  CPX #INV_FULL           ;Was Gwaelin's love successfully given?
LD3C3:  BNE KingPrncsDialog     ;If so, branch.

LD3C5:  LDX #$00                ;Inventory full.  Prepare to take an item.

TakeItemLoop:
LD3C7:  LDA InvListTbl,X        ;Check for inventory item.
LD3CA:  JSR CheckForInvItem     ;($E055)Check inventory for item.

LD3CD:  CMP #ITM_NOT_FOUND      ;Is it in the player's inventory?
LD3CF:  BNE TakeItemFound       ;If so, branch to remove it.

LD3D1:  INX                     ;Has all 8 inventory slots been checked?
LD3D2:  CPX #$07                ;
LD3D4:  BNE TakeItemLoop        ;If not, branch to check the next one.

LD3D6:  BEQ KingPrncsDialog     ;No non-critical items found, branch.

TakeItemFound:
LD3D8:  LDA InvListTbl,X        ;Save a copy of item to take from player's inventory.
LD3DB:  PHA                     ;
LD3DC:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.
LD3DF:  PLA                     ;Restore a copy of item taken.

LD3E0:  CLC                     ;Get description of item taken.
LD3E1:  ADC #$31                ;
LD3E3:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LD3E6:  LDA #ITM_GWAELIN_LVE    ;Add Gwaelin's love to player's inventory.
LD3E8:  JSR AddInvItem          ;($E01B)Add item to inventory.

LD3EB:  JSR DoDialogLoBlock     ;($C7CB)And I would like to have something of thine...
LD3EE:  .byte $BA               ;TextBlock12, entry 10.

KingPrncsDialog:
LD3EF:  JSR DoDialogLoBlock     ;($C7CB)Even when we are parted by great distances...
LD3F2:  .byte $BB               ;TextBlock12, entry 11.

LD3F3:  JSR DoDialogLoBlock     ;($C7CB)Farewell, player...
LD3F6:  .byte $BC               ;TextBlock12, entry 12.

LD3F7:  LDA PlayerFlags         ;
LD3F9:  AND #$FC                ;Clear flag indicating player is carrying Gwaelin.
LD3FB:  ORA #F_RTN_GWAELIN      ;Set flag indicating Gwaelin has been returned.
LD3FD:  STA PlayerFlags         ;

LD3FF:  LDA #$C6                ;
LD401:  STA NPCXPos+$27         ;Place princess Gwaelin NPC on the screen.
LD403:  LDA #$43                ;
LD405:  STA NPCYPos+$27         ;

LD407:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LD40A:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LD40D:  JMP SaveDialog          ;($D433)Jump to save dialog.

KingDialog2:
LD410:  LDA PlayerFlags         ;Has the player left the throne room for the first time?
LD412:  AND #F_LEFT_THROOM      ;
LD414:  BNE LeftThRoom          ;If so, branch.

LD416:  LDA #$BF                ;TextBlock12, entry 15.
LD418:  JMP DoFinalDialog       ;($D242)When thou art finished preparing, please see me...

LeftThRoom:
LD41B:  JSR DoDialogLoBlock     ;($C7CB)I am greatly pleased that thou hast returned...
LD41E:  .byte $C0               ;TextBlock13, entry 0.

LD41F:  LDA DisplayedLevel      ;Is the player level 30?
LD421:  CMP #LVL_30             ;
LD423:  BNE CalculateExp        ;If not, branch.

LD425:  JSR DoDialogLoBlock     ;($C7CB)Thou art strong enough...
LD428:  .byte $02               ;TextBlock1, entry 2.

LD429:  JMP SaveDialog          ;($D433)Jump to save dialog.

CalculateExp:
LD42C:  JSR GetExpRemaining     ;($F134)Calculate experience needed for next level.

LD42F:  JSR DoDialogLoBlock     ;($C7CB)Before reaching thy next level of experience...
LD432:  .byte $C1               ;TextBlock13, entry 1.

SaveDialog:
LD433:  JSR DoDialogHiBlock     ;($C7C5)Will thou tell me now of thy deeds...
LD436:  .byte $23               ;TextBlock19, entry 3.

LD437:  JSR Dowindow            ;($C6F0)display on-screen window.
LD43A:  .byte WND_YES_NO1       ;Yes/no selection window.

LD43B:  CMP #WND_YES            ;Does the player wish to save their game?
LD43D:  BNE ContQuestDialog     ;If not, branch.

LD43F:  JSR PrepSaveGame        ;($F148)Prepare to save the current game.

LD442:  JSR DoDialogHiBlock     ;($C7C5)Thy deeds have been recorded...
LD445:  .byte $24               ;TextBlock19, entry 4.

ContQuestDialog:
LD446:  JSR DoDialogHiBlock     ;($C7C5)Dost thou wish to continue thy quest...
LD449:  .byte $25               ;TextBlock19, entry 5.

LD44A:  JSR Dowindow            ;($C6F0)display on-screen window.
LD44D:  .byte WND_YES_NO1       ;Yes/no selection window.

LD44E:  CMP #$00                ;Does pplayer want to continue playing?
LD450:  BEQ KingEndTalk         ;If so, branch.

LD452:  JSR DoDialogHiBlock     ;($C7C5)Rest then for a while...
LD455:  .byte $26               ;TextBlock19, entry 6.

LD456:  BRK                     ;Shut down game after player chooses not to continue.
LD457:  .byte $05, $17          ;($9362)ExitGame, bank 1.

LD459:  JSR MMCShutdown         ;($FC88)Switch to PRG bank 3 and disable PRG RAM.

Spinlock2:
LD45C:  JMP Spinlock2           ;($D45C)Spinlock the game.  Reset required to do anything else.

KingEndTalk:
LD45F:  LDA #$C4                ;TextBlock13, Entry4.
LD461:  JMP DoFinalDialog       ;($D242)Goodbye and tempt not the fates...

;----------------------------------------------------------------------------------------------------

PrincessDialog:
LD464:  CMP #$6F                ;Is the player talking to the princess?
LD466:  BNE DgrnLrdDialog       ;If not, branch.

LD468:  JSR UpdateRandNum       ;($C55B)Get random number.
LD46B:  LDA RandNumUB           ;
LD46D:  AND #$60                ;Choose a random number to vary what princess Gwaelin says-->
LD46F:  BNE PrncsRndDialog1     ;to the player when she is talked to.

LD471:  LDA #$BB                ;TextBlock12, entry 11.
LD473:  JMP DoFinalDialog       ;($D242)Even when we are parted by great distances...

PrncsRndDialog1:
LD476:  CMP #$60                ;Are the 2 random bits set?
LD478:  BNE PrncsRndDialog2     ;If so, show a little extra bit of dialog.

LD47A:  LDA #$BD                ;TextBlock12, entry 13.
LD47C:  JMP DoFinalDialog       ;($D242)I love thee, player...

PrncsRndDialog2:
LD47F:  JSR DoDialogLoBlock     ;($C7CB)Dost thou love me, player...
LD482:  .byte $BE               ;TextBlock12, entry 14.

LD483:  JSR Dowindow            ;($C6F0)display on-screen window.
LD486:  .byte WND_YES_NO1       ;Yes/no selection window.

LD487:  BEQ PrncsLoveDialog     ;Branch if player loves the princess.

LD489:  JSR DoDialogLoBlock     ;($C7CB)But thou must...
LD48C:  .byte $B6               ;TextBlock12, entry 6.

LD48D:  JMP PrncsRndDialog2     ;Loop until player says they love the princess.

PrncsLoveDialog:
LD490:  JSR DoDialogLoBlock     ;($C7CB)I'm so happy...
LD493:  .byte $B8               ;TextBlock12, entry 8.

LD494:  LDA #MSC_PRNCS_LOVE     ;Gwaelin's love music.
LD496:  BRK                     ;
LD497:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LD499:  BRK                     ;Wait for the music clip to end.
LD49A:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LD49C:  LDA #MSC_THRN_ROOM      ;Throne room castle music.
LD49E:  BRK                     ;
LD49F:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LD4A1:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

DgrnLrdDialog:
LD4A4:  CMP #$70                ;Is the player talking to the dragonlord?
LD4A6:  BEQ DoDrgnLrdDialog     ;If so, branch to do dragonlord dialog.
LD4A8:  JMP MiscDialog          ;($D533)Else jump to check some misc. dialog

DoDrgnLrdDialog:
LD4AB:  JSR DoDialogLoBlock     ;($C7CB)Welcome player, I am the dragonlord...
LD4AE:  .byte $C7               ;TextBlock13, entry 7.

LD4AF:  JSR DoDialogLoBlock     ;($C7CB)I have been waiting for one such as thee...
LD4B2:  .byte $A4               ;TextBlock11, entry 4.

LD4B3:  JSR DoDialogLoBlock     ;($C7CB)I give thee now a chance to share this world...
LD4B6:  .byte $C8               ;TextBlock13, entry 8.

LD4B7:  JSR Dowindow            ;($C6F0)display on-screen window.
LD4BA:  .byte WND_YES_NO1       ;Yes/no selection window.

LD4BB:  BNE RefuseDglrdDialog   ;Refuse to join the dragonlord. Branch to fight!

LD4BD:  JSR DoDialogHiBlock     ;($C7C5)Really?...
LD4C0:  .byte $16               ;TextBlock18, entry 6.

LD4C1:  JSR Dowindow            ;($C6F0)display on-screen window.
LD4C4:  .byte WND_YES_NO1       ;Yes/no selection window.

LD4C5:  BEQ ChooseDrgnLrd       ;Branch if player chooses to join the dragonlord.

RefuseDglrdDialog:
LD4C7:  JSR DoDialogLoBlock     ;($C7CB)Thou art a fool...
LD4CA:  .byte $C9               ;TextBlock13, entry 9.

LD4CB:  LDX #$28                ;Prepare to wait 40 frames before continuing.
LD4CD:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LD4D0:  DEX                     ;Has 40 frames passed?
LD4D1:  BNE -                   ;If not, branch to wait more.

LD4D3:  LDA #WND_DIALOG         ;Remove dialog window.
LD4D5:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LD4D8:  LDA #WND_CMD_NONCMB     ;Remove command window.
LD4DA:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LD4DD:  LDA #WND_POPUP          ;Remove pop-up window.
LD4DF:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LD4E2:  LDA #EN_DRAGONLORD1     ;Dragonlord, initial form.
LD4E4:  JMP InitFight           ;($E4DF)Fight the dragonlord.

ChooseDrgnLrd:
LD4E7:  JSR DoDialogLoBlock     ;($C7CB)Then half of this world is thine...
LD4EA:  .byte $CA               ;TextBlock13, entry 10.

LD4EB:  JSR DoDialogLoBlock     ;($C7CB)If thou dies I can bring thee back...
LD4EE:  .byte $C2               ;TextBlock13, entry 2.

ZeroStats:
LD4EF:  LDA #$00                ;
LD4F1:  STA ExpLB               ;
LD4F3:  STA ExpUB               ;
LD4F5:  STA GoldLB              ;
LD4F7:  STA GoldUB              ;
LD4F9:  STA InventorySlot12     ;
LD4FB:  STA InventorySlot34     ;Zero out stats. The player chose to join-->
LD4FD:  STA InventorySlot56     ;the dragonlord.  The game is over.
LD4FF:  STA InventorySlot78     ;
LD501:  STA InventoryKeys       ;
LD503:  STA InventoryHerbs      ;
LD505:  STA EqippedItems        ;
LD507:  STA ModsnSpells         ;
LD509:  STA PlayerFlags         ;
LD50B:  STA StoryFlags          ;

LD50D:  JSR DoDialogLoBlock     ;($C7CB)Empty dialog.
LD510:  .byte $C3               ;TextBlock13, entry 3.

LD511:  JSR DoDialogLoBlock     ;($C7CB)Thy journey is over. Take now a long rest...
LD514:  .byte $CB               ;TextBlock13, entry 11.

LD515:  LDA BadEndBGPalPtr      ;
LD518:  STA PalPtrLB            ;Get pointer to palette data.
LD51A:  LDA BadEndBGPalPtr+1    ;
LD51D:  STA PalPtrUB            ;

LD51F:  LDA #$00                ;Disable palette fade effect.
LD521:  STA PalModByte          ;

LD523:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer
LD526:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LD529:  JSR Dowindow            ;($C6F0)display on-screen window.
LD52C:  .byte WND_POPUP         ;Pop-up window.

LD52D:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

Spinlock3:
LD530:  JMP Spinlock3           ;($D530)Spinlock the game.  Reset required to do anything else.

;----------------------------------------------------------------------------------------------------

MiscDialog:
LD533:  CMP #$71                ;Tantagel ground floor guard dialog 1?
LD535:  BEQ GuardDialog1        ;If so, branch.

LD537:  CMP #$72                ;Tantagel ground floor guard dialog 2?
LD539:  BEQ GuardDialog2        ;If so, branch.

LD53B:  JMP NoTalk              ;($D1ED)No Valid NPC to talk to.

GuardDialog1:
LD53E:  JSR DoDialogLoBlock     ;($C7CB)If you are planning to take a rest, see king Lorik...
LD541:  .byte $03               ;TextBlock1, entry 3.

LD542:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

GuardDialog2:
LD545:  JSR DoDialogLoBlock     ;($C7CB)When entering the cave, take a torch...
LD548:  .byte $91               ;TextBlock10, entry 1.

LD549:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

InvListTbl:
LD54C:  .byte ITM_TORCH         ;
LD54D:  .byte ITM_DRG_SCALE     ;If Gwaelin is returned and the player's inventory-->
LD54E:  .byte ITM_FTR_RING      ;is full, one of the following items will be taken-->
LD54F:  .byte ITM_FRY_WATER     ;from the inventory and replaced with Gwaelin's love.-->
LD550:  .byte ITM_WINGS         ;If the inventory is full and none of these things-->
LD551:  .byte ITM_CRSD_BELT     ;are present, Gwaelin's love will not be added to inventory.
LD552:  .byte ITM_STFF_RAIN     ;

;----------------------------------------------------------------------------------------------------

WeaponsDialog:
LD553:  STA DialogTemp          ;Save dialog control byte.

LD555:  JSR DoDialogLoBlock     ;($C7CB)We deal in weapons and armor.
LD558:  .byte $28               ;TextBlock3, entry 8.

WpnDialogLoop:
LD559:  JSR Dowindow            ;($C6F0)display on-screen window.
LD55C:  .byte WND_YES_NO1       ;Yes/no selection window.

LD55D:  BEQ WeapYesDialog       ;Does the player want weapons? If so, branch.
LD55F:  JMP WeapNoDialog        ;($D66B)Finish weapons shop dialog.

WeapYesDialog:
LD562:  JSR DoDialogLoBlock     ;($C7CB)What dost thou wish to buy?
LD565:  .byte $2D               ;TextBlock3, entry 13.

LD566:  JSR GetShopItems        ;($D672)Get items for sale in this shop.

LD569:  LDA WndSelResults       ;Did the player abort the shop dialog?
LD56B:  CMP #WND_ABORT          ;
LD56D:  BNE CheckBuyWeapon      ;If not, branch to try to buy weapon.

LD56F:  JMP WeapNoDialog        ;($D66B)Finish weapons shop dialog.

CheckBuyWeapon:
LD572:  LDA ShopItemsTbl,X      ;Save the index to the item selected on the stack.
LD575:  PHA                     ;

LD576:  CLC                     ;Get the description for the weapon selected.
LD577:  ADC #$1B                ;
LD579:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LD57C:  JSR DoDialogLoBlock     ;($C7CB)The item?...
LD57F:  .byte $29               ;TextBlock 3, entry 9.

LD580:  LDA #$00                ;
LD582:  STA GenWrd00LB          ;Zero out price calculating variables.
LD584:  STA GenWrd00UB          ;

LD586:  PLA                     ;Restore selected item index.
LD587:  ASL                     ;*2. each entry in the table is 2 bytes.

LD588:  TAX                     ;
LD589:  LDA GoldLB              ;
LD58B:  SEC                     ;Subtract item price from player's gold to-->
LD58C:  SBC ItemCostTbl,X       ;see if player has enough money.
LD58F:  LDA GoldUB              ;
LD591:  SBC ItemCostTbl+1,X     ;

LD594:  BCS DoWeapPurchase      ;Does player have enough money? if so, branch.
LD596:  JMP NoMoneyDialog       ;($D660)Player does not have enough money.

DoWeapPurchase:
LD599:  TXA                     ;Save a copy of the item index into the ItemCostTbl.
LD59A:  PHA                     ;

LD59B:  CMP #$0E                ;Is the selected item anything but a weapon?
LD59D:  BCS ChkItem             ;If so, branch.

LD59F:  LDA EqippedItems        ;Get player's equipped weapons.
LD5A1:  LSR                     ;
LD5A2:  LSR                     ;
LD5A3:  LSR                     ;
LD5A4:  LSR                     ;
LD5A5:  LSR                     ;Does the player have a weapon?
LD5A6:  BEQ ConfSaleDialog      ;Does player have a weapon equipped?

LD5A8:  BNE GetBuybackPrice     ;If so, branch to offer money for existing weapon.

ChkItem:
LD5AA:  CMP #$1C                ;Is the selected item armor?
LD5AC:  BCS ChkShield           ;If not, branch.

ChkArmor:
LD5AE:  LDA EqippedItems        ;Get player's equipped armor.
LD5B0:  LSR                     ;
LD5B1:  LSR                     ;
LD5B2:  AND #$07                ;Is the player wearing armor?
LD5B4:  BEQ ConfSaleDialog      ;If not, branch to confirm purchase.

LD5B6:  CLC                     ;Set the index for armor prices.
LD5B7:  ADC #$07                ;
LD5B9:  BNE GetBuybackPrice     ;Branch to offer money for existing armor.

ChkShield:
LD5BB:  LDA EqippedItems        ;Is player carrying a shield?
LD5BD:  AND #SH_SHIELDS         ;
LD5BF:  BEQ ConfSaleDialog      ;If not, branch to confirm purchase.

LD5C1:  CLC                     ;Set index for shield prices.
LD5C2:  ADC #$0E                ;

GetBuybackPrice:
LD5C4:  ASL                     ;*2. each entry in the table is 2 bytes.
LD5C5:  TAY                     ;

LD5C6:  LDA ItemCostTbl-2,Y     ;Get item cost from ItemCostTbl
LD5C9:  STA GenWrd00LB          ;
LD5CB:  LDA ItemCostTbl-1,Y     ;
LD5CE:  STA GenWrd00UB          ;Save cost.

LD5D0:  LSR GenWrd00UB          ;Divide cost by 2.
LD5D2:  ROR GenWrd00LB          ;Sell item back for half of its cost.

LD5D4:  TYA                     ;Restore item index to original value.
LD5D5:  LSR                     ;

LD5D6:  CLC                     ;Get description index for selected item.
LD5D7:  ADC #$1A                ;
LD5D9:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LD5DC:  JSR DoDialogLoBlock     ;($C7CB)Then I will buy thy item...
LD5DF:  .byte $2A               ;TextBlock3, entry 10.

ConfSaleDialog:
LD5E0:  JSR DoDialogLoBlock     ;($C7CB)Is that ok...
LD5E3:  .byte $27               ;TextBlock3, entry 7.

LD5E4:  JSR Dowindow            ;($C6F0)display on-screen window.
LD5E7:  .byte WND_YES_NO1       ;Yes/no selection window.

LD5E8:  PLA                     ;Restore copy of the item index into the ItemCostTbl.
LD5E9:  TAX                     ;

LD5EA:  LDA WndSelResults       ;Did player choose to buy the item?
LD5EC:  BEQ ComitWeapPurchase   ;If so, branch to commit to purchase.

LD5EE:  JSR DoDialogLoBlock     ;($C7CB)Oh yes? That's too bad...
LD5F1:  .byte $26               ;TextBlock3, entry 6.

LD5F2:  JMP NextWeapDialog      ;($D664)Jump to see if player wants to buy something else.

ComitWeapPurchase:
LD5F5:  LDA GoldLB              ;
LD5F7:  SEC                     ;
LD5F8:  SBC ItemCostTbl,X       ;
LD5FB:  STA GoldLB              ;Subtract the cost of the item from the player's gold.
LD5FD:  LDA GoldUB              ;
LD5FF:  SBC ItemCostTbl+1,X     ;
LD602:  STA GoldUB              ;
LD604:  LDA GoldLB              ;

LD606:  CLC                     ;
LD607:  ADC GenWrd00LB          ;
LD609:  STA GoldLB              ;Add the buyback price of the old item to the player's gold.
LD60B:  LDA GoldUB              ;
LD60D:  ADC GenWrd00UB          ;
LD60F:  STA GoldUB              ;

LD611:  BCC ApplyPurchase       ;Has player maxed out gold? If not, branch.

LD613:  LDA #$FF                ;
LD615:  STA GoldLB              ;Set players gold to max value of 65535.
LD617:  STA GoldUB              ;

ApplyPurchase:
LD619:  TXA                     ;/2. Restore index to original value.
LD61A:  LSR                     ;

LD61B:  CMP #$07                ;Is the purchased item a weapon?
LD61D:  BCS $D63C               ;If not, branch.

LD61F:  CLC                     ;Add 1 to weapon to get proper EqippedItems value.
LD620:  ADC #$01                ;

LD622:  ASL                     ;
LD623:  ASL                     ;
LD624:  ASL                     ;Move weapon to proper bit location for EqippedItems.
LD625:  ASL                     ;
LD626:  ASL                     ;

LD627:  STA GenByte3C           ;Temp storage of new weapon.

LD629:  LDA EqippedItems        ;Remove old weapon.
LD62B:  AND #$1F                ;

LD62D:  ORA GenByte3C           ;Equip new weapon.
LD62F:  STA EqippedItems        ;

CompWeapPurchase:
LD631:  JSR DoDialogLoBlock     ;($C7CB)I thank thee...
LD634:  .byte $2E               ;TextBlock3, entry 14.

LD635:  JSR Dowindow            ;($C6F0)display on-screen window.
LD638:  .byte WND_POPUP         ;Pop-up window.
LD639:  JMP NextWeapDialog      ;($D664)Jump to see if player wants to buy something else.

ChkApplyArmor:
LD63C:  CMP #$0E                ;Is the purchased item armor?
LD63E:  BCS ApplyShield         ;If not branch to apply the new shield(the only one left).

LD640:  SEC                     ;
LD641:  SBC #$06                ;Subtract 6 and *4 to move armor to proper bit-->
LD643:  ASL                     ;location for EqippedItems.
LD644:  ASL                     ;

LD645:  STA GenByte3C           ;Temp storage of new armor.

LD647:  LDA EqippedItems        ;Remove old armor.
LD649:  AND #$E3                ;

LD64B:  ORA GenByte3C           ;Equip new armor.
LD64D:  STA EqippedItems        ;

LD64F:  BNE CompWeapPurchase    ;Branch always to complete process.

ApplyShield:
LD651:  SEC                     ;Subtract 13 to move shield to proper bit-->
LD652:  SBC #$0D                ;location for EqippedItems.

LD654:  STA GenByte3C           ;Temp storage of new shield.

LD656:  LDA EqippedItems        ;Remove old shield.
LD658:  AND #$FC                ;

LD65A:  ORA GenByte3C           ;Equip new shield.
LD65C:  STA EqippedItems        ;

LD65E:  BNE CompWeapPurchase    ;Branch always to complete process.

NoMoneyDialog:
LD660:  JSR DoDialogLoBlock     ;($C7CB)Sorry. Thou hast not enough money...
LD663:  .byte $2B               ;TextBlock3, entry 11.

NextWeapDialog:
LD664:  JSR DoDialogLoBlock     ;($C7CB)Dost thou wish to buy anything more...
LD667:  .byte $2C               ;TextBlock3, entry 12.

LD668:  JMP WpnDialogLoop       ;($D559)Branch to see if player wants to buy more.

WeapNoDialog:
LD66B:  JSR DoDialogLoBlock     ;($C7CB)Please come again...
LD66E:  .byte $2F               ;TextBlock3, entry 15.

LD66F:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

GetShopItems:
LD672:  LDX #$00                ;The dialog control byte is the entry-->
LD674:  LDA DialogTemp          ;into the ShopItemsTbl.
LD676:  STA ShopIndex           ;Store a copy of the table index.
LD678:  BEQ ShopEntryFound      ;Is the index 0? If so, no need to search the table.

ShopEntryLoop:
LD67A:  LDA ShopItemsTbl,X      ;
LD67D:  INX                     ;Increment through ShopItemsTbl to find end of-->
LD67E:  CMP #ITM_TBL_END        ;current shop index.
LD680:  BNE ShopEntryLoop       ;

LD682:  DEC ShopIndex           ;Have we found the proper index for this shop?
LD684:  BNE ShopEntryLoop       ;If not, branch to move to next index.

ShopEntryFound:
LD686:  TXA                     ;Use current offset as index into table for specific item.
LD687:  PHA                     ;Save base offset of this shop's table.

LD688:  LDY #$01                ;Load #$01 into the description buffer.
LD68A:  STY DescBuf             ;

ShopEntryLoad:
LD68C:  LDA ShopItemsTbl,X      ;Store description byte for item in the description buffer.-->
LD68F:  CLC                     ;The description byte will be converted to the proper-->
LD690:  ADC #$02                ;value in the window engine.
LD692:  STA _DescBuf,Y          ;

LD695:  CMP #ITM_TBL_END+2      ;Have all the description bytes been loaded?
LD697:  BEQ ShowShopInvWnd      ;If so, branch.

LD699:  INX                     ;Move to next byte in the ShopItemsTbl
LD69A:  INY                     ;move to next spot in the description buffer.
LD69B:  BNE ShopEntryLoad       ;Branch to get next item.

ShowShopInvWnd:
LD69D:  JSR Dowindow            ;($C6F0)display on-screen window.
LD6A0:  .byte WND_INVTRY2       ;Shop inventory window.

LD6A1:  PLA                     ;Restore base index into ShopItemsTbl.
LD6A2:  CLC                     ;
LD6A3:  ADC WndSelResults       ;Add selected item to value.
LD6A5:  TAX                     ;
LD6A6:  RTS                     ;The value in X is the index for the specific item in ShopItemsTbl.

;----------------------------------------------------------------------------------------------------

ToolsDialog:
LD6A7:  STA DialogTemp          ;Save a copy of the dialog byte.

LD6A9:  JSR DoDialogLoBlock     ;($C7CB)Welcome. We deal in tools...
LD6AC:  .byte $25               ;TextBlock3, entry 5.

LD6AD:  JSR Dowindow            ;($C6F0)display on-screen window.
LD6B0:  .byte WND_BUY_SELL      ;Buy/sell window.

LD6B1:  BEQ DoToolPurchase      ;Did player choose to buy something? if so, branch.

LD6B3:  CMP #WND_SELL           ;Did player choose to sell something?
LD6B5:  BNE ToolExitDialog      ;If not, branch to exit tool dialog.
LD6B7:  JMP DoToolSell          ;($D739)Sell tools routines.

ToolExitDialog:
LD6BA:  JSR DoDialogLoBlock     ;($C7CB)I will be waiting for thy next visit...
LD6BD:  .byte $1E               ;TextBlock2, entry 14.

LD6BE:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

DoToolPurchase:
LD6C1:  JSR DoDialogLoBlock     ;($C7CB)What dost thou want...
LD6C4:  .byte $24               ;TextBlock3, entry 4.

LD6C5:  JSR GetShopItems        ;($D672)Display items for sale in this shop.

LD6C8:  LDA WndSelResults       ;Did player cancel out of item window?
LD6CA:  CMP #WND_ABORT          ;If so, branch to exit tool dialog.
LD6CC:  BEQ ToolExitDialog      ;($D6BA)Exit tool buy/sell dialog.

LD6CE:  LDA ShopItemsTbl,X      ;Load selected item from shop item table.
LD6D1:  PHA                     ;Save a copy of the item on the stack.

LD6D2:  CLC                     ;Add 32 to get proper index for item description.
LD6D3:  ADC #$1F                ;
LD6D5:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LD6D8:  PLA                     ;Restore index to selected item.
LD6D9:  ASL                     ;*2. Cost of item is 2 byte in ItemCostTbl.

LD6DA:  TAX                     ;Subtract item price from player's current gold.
LD6DB:  LDA GoldLB              ;
LD6DD:  SEC                     ;
LD6DE:  SBC ItemCostTbl,X       ;
LD6E1:  STA GenWord3CLB         ;
LD6E3:  LDA GoldUB              ;
LD6E5:  SBC ItemCostTbl+1,X     ;Does player have enough gold to-->
LD6E8:  STA GenWord3CUB         ;purchase the selected item?
LD6EA:  BCS ChkToolPurchase     ;If so, branch.

LD6EC:  JSR DoDialogLoBlock     ;($C7CB)Thou hast not enough money...
LD6EF:  .byte $22               ;TextBlock3, entry 2.

LD6F0:  JMP NextToolDialog      ;($D716)Check if player wants to buy something else.

ChkToolPurchase:
LD6F3:  CPX #$22                ;Is player trying to buy herbs?
LD6F5:  BNE DoOthrToolPurchase  ;If not, branch.

LD6F7:  LDA InventoryHerbs      ;Does player already have the maximum herbs?
LD6F9:  CMP #$06                ;
LD6FB:  BNE PurchaseHerb        ;If not, branch to add herb to inventory.

LD6FD:  JSR DoDialogLoBlock     ;($C7CB)Thou cannot hold more herbs...
LD700:  .byte $20               ;TextBlock3, entry 0.

LD701:  JMP NextToolDialog      ;($D716)Check if player wants to buy something else.

PurchaseHerb:
LD704:  INC InventoryHerbs      ;Add 1 herb.

PurchaseTool:
LD706:  LDA GenWord3CLB         ;
LD708:  STA GoldLB              ;Save updated gold amount.
LD70A:  LDA GenWord3CUB         ;
LD70C:  STA GoldUB              ;

LD70E:  JSR DoDialogLoBlock     ;($C7CB)The item? Thank you very much...
LD711:  .byte $23               ;TextBlock3, entry 3.

LD712:  JSR Dowindow            ;($C6F0)display on-screen window.
LD715:  .byte WND_POPUP         ;Pop-up window.

NextToolDialog:
LD716:  JSR DoDialogLoBlock     ;($C7CB)Dost thou want anything else...
LD719:  .byte $1F               ;TextBlock2, entry 15.

LD71A:  JSR Dowindow            ;($C6F0)display on-screen window.
LD71D:  .byte WND_YES_NO1       ;Yes/no selection window.

LD71E:  BNE DoToolExit          ;Exit tool dialog.
LD720:  JMP DoToolPurchase      ;($D6C1)Loop do to another purchase.

DoToolExit:
LD723:  JMP ToolExitDialog      ;($D6BA)Exit tool buy/sell dialog.

DoOthrToolPurchase:
LD726:  TXA                     ;
LD727:  LSR                     ;Set proper index for corresponding item.
LD728:  SEC                     ;
LD729:  SBC #$12                ;

LD72B:  JSR AddInvItem          ;($E01B)Add item to inventory.
LD72E:  CPX #INV_FULL           ;Is player's inventory full?
LD730:  BNE PurchaseTool        ;If not, branch to purchase tool.

LD732:  JSR DoDialogLoBlock     ;($C7CB)Thou cannot carry anymore...
LD735:  .byte $21               ;TextBlock3, entry 1.

LD736:  JMP NextToolDialog      ;($D716)Check if player wants to buy something else.

DoToolSell:
LD739:  JSR CreateInvList       ;($DF77)Create inventory list in description buffer.
LD73C:  CPX #$01                ;Does player have any tools to sell?
LD73E:  BNE HaveToolsToSell     ;If so, branch.

LD740:  JSR DoDialogLoBlock     ;($C7CB)Thou hast no possesions...
LD743:  .byte $19               ;TextBlock2, entry 9.

LD744:  JMP ToolExitDialog      ;($D6BA)Exit tool buy/sell dialog.

HaveToolsToSell:
LD747:  JSR DoDialogLoBlock     ;($C7CB)What art thou selling...
LD74A:  .byte $1D               ;TextBlock2, entry 13.

LD74B:  JSR Dowindow            ;($C6F0)display on-screen window.
LD74E:  .byte WND_INVTRY1       ;Player inventory window.

LD74F:  CMP #WND_ABORT          ;Did player abort from inventory window?
LD751:  BNE GetSellDesc         ;
LD753:  JMP ToolExitDialog      ;($D6BA)Exit tool buy/sell dialog.

GetSellDesc:
LD756:  TAX                     ;
LD757:  LDA DescBuf+1,X         ;Get description byte from the description buffer.
LD759:  STA DescTemp            ;

LD75B:  CLC                     ;Convert it to the proper index in DescTbl.
LD75C:  ADC #$2E                ;

LD75E:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LD761:  LDA DescTemp            ;Get item description byte again.
LD763:  CLC                     ;
LD764:  ADC #$0F                ;Convert it into proper pointer for ItemCostTbl.
LD766:  ASL                     ;

LD767:  TAX                     ;
LD768:  LDA ItemCostTbl,X       ;
LD76B:  STA GenWrd00LB          ;Get item cost.
LD76D:  LDA ItemCostTbl+1,X     ;
LD770:  STA GenWrd00UB          ;

LD772:  ORA GenWrd00LB          ;Is tool value greater than 0?
LD774:  BNE SellableTool        ;If so, branch.  It is sellable.

LD776:  JSR DoDialogLoBlock     ;($C7CB)I cannot buy it...
LD779:  .byte $1B               ;TextBlock2, entry 11.

ItemSellLoop:
LD77A:  JSR DoDialogLoBlock     ;($C7CB)Will thou sell anything else...
LD77D:  .byte $1A               ;TextBlock2, entry 10.

LD77E:  JSR Dowindow            ;($C6F0)display on-screen window.
LD781:  .byte WND_YES_NO1       ;Yes/no selection window.

LD782:  BNE $D787
LD784:  JMP DoToolSell          ;($D739)Sell tools routines.
LD787:  JMP ToolExitDialog      ;($D6BA)Exit tool buy/sell dialog.

SellableTool:
LD78A:  LSR $01                 ;/2. Tool sell cost is only half its purchase cost.
LD78C:  ROR $00                 ;

LD78E:  JSR DoDialogLoBlock     ;($C7CB)Thou said the item. I will buy the item...
LD791:  .byte $1C               ;TextBlock2, entry 12.

LD792:  JSR Dowindow            ;($C6F0)display on-screen window.
LD795:  .byte WND_YES_NO1       ;Yes/no selection window.

LD796:  BNE ItemSellLoop        ;($D77A)No sale. Branch to see if player wants to sell more.

LD798:  LDA DescTemp            ;Is player selling a key?
LD79A:  CMP #$03                ;
LD79C:  BNE ChkSellHerb         ;If not, branch.

LD79E:  DEC InventoryKeys       ;Decrement Player's keys.

GetSellGold:
LD7A0:  LDA GoldLB              ;Add item's sell value to Player's gold.
LD7A2:  CLC                     ;
LD7A3:  ADC GenWrd00LB          ;
LD7A5:  STA GoldLB              ;
LD7A7:  LDA GoldUB              ;
LD7A9:  ADC GenWrd00UB          ;
LD7AB:  STA GoldUB              ;Did player's gold go beyond the max amount?
LD7AD:  BCC DoneSellingTool     ;If not, branch to conclude transaction.

LD7AF:  LDA #$FF                ;
LD7B1:  STA GoldLB              ;Set gold to max value(65535).
LD7B3:  STA GoldUB              ;

DoneSellingTool:
LD7B5:  JSR Dowindow            ;($C6F0)display on-screen window.
LD7B8:  .byte WND_POPUP         ;Pop-up window.

LD7B9:  JMP ItemSellLoop        ;($D77A)Branch to see if player wants to sell more.

ChkSellHerb:
LD7BC:  CMP #$02                ;Is player trying to sell an herb?
LD7BE:  BNE ChkSellBelt         ;If not, branch.

LD7C0:  DEC InventoryHerbs      ;Decrement herbs.
LD7C2:  JMP GetSellGold         ;($D7A0)Update gold after selling item.

ChkSellBelt:
LD7C5:  CMP #$0C                ;Is player trying to sell the cursed belt?
LD7C7:  BNE ChkSellNecklace     ;If not, branch.

LD7C9:  PHA                     ;Save a copy of item to sell.
LD7CA:  BIT ModsnSpells         ;Is player wearing the belt?
LD7CC:  BVC SellBelt            ;If not, branch to sell it.

CantSellCrsdItm:
LD7CE:  PLA                     ;Pull cursed item ID off stack.

LD7CF:  JSR DoDialogLoBlock     ;($C7CB)A curse is on thy body...
LD7D2:  .byte $18               ;TextBlock2, entry 8.

LD7D3:  JSR DoDialogLoBlock     ;($C7CB)I am sorry...
LD7D6:  .byte $17               ;TextBlock2, entry 7.

LD7D7:  JMP ItemSellLoop        ;($D77A)Branch to see if player wants to sell more.

ChkSellNecklace:
LD7DA:  CMP #$0E                ;Is player trying to sell the death necklace?
LD7DC:  BNE DoSellTool          ;If not, branch.

LD7DE:  PHA                     ;Is player wearing the death necklace?
LD7DF:  LDA ModsnSpells         ;
LD7E1:  BMI CantSellCrsdItm     ;If so, branch. Can't sell it.

SellBelt:
LD7E3:  PLA                     ;Pull cursed item ID off stack.

DoSellTool:
LD7E4:  SEC                     ;Convert item description byte to proper index value.
LD7E5:  SBC #$03                ;

LD7E7:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.
LD7EA:  JMP GetSellGold         ;($D7A0)Update gold after selling item.

;----------------------------------------------------------------------------------------------------

KeysDialog:
LD7ED:  SEC                     ;There are three key shops. The dialog control byte-->
LD7EE:  SBC #$0C                ;determines what the price of the key is.

LD7F0:  TAX                     ;Convert control byte to index for KeyCostTbl.
LD7F1:  LDA KeyCostTbl,X        ;

LD7F4:  STA GenWrd00LB          ;
LD7F6:  LDA #$00                ;Save key cost.  Upper byte is always 0.
LD7F8:  STA GenWrd00UB          ;

LD7FA:  JSR DoDialogLoBlock     ;($C7CB)Magic keys! They will unlock any door...
LD7FD:  .byte $16               ;TextBlock2, entry 6.

KeyDialogLoop:
LD7FE:  JSR Dowindow            ;($C6F0)display on-screen window.
LD801:  .byte WND_YES_NO1       ;Yes/no selection window.

LD802:  BEQ ChkBuyKey           ;Did player choose to buy a key? If so, branch.

EndKeyDialog:
LD804:  JSR DoDialogLoBlock     ;($C7CB)I will see thee later...
LD807:  .byte $12               ;TextBlock2, entry 2.
LD808:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkBuyKey:
LD80B:  LDA InventoryKeys       ;Does player already have the maximum 6 keys?
LD80D:  CMP #$06                ;
LD80F:  BNE ChkBuyKeyGold       ;If not, branch.

LD811:  JSR DoDialogLoBlock     ;($C7CB)I am sorry, but I cannot sell thee anymore...
LD814:  .byte $14               ;TextBlock2, entry 4.

LD815:  JMP EndKeyDialog        ;($D804)End key shop dialog.

ChkBuyKeyGold:
LD818:  LDA GoldLB              ;
LD81A:  SEC                     ;
LD81B:  SBC GenWrd00LB          ;
LD81D:  STA GenWord3CLB         ;Does player have enough gold to buy a key?
LD81F:  LDA GoldUB              ;If so, branch to commit key purchase.
LD821:  SBC GenWrd00UB          ;
LD823:  STA GenWord3CUB         ;
LD825:  BCS BuyKey              ;

LD827:  JSR DoDialogLoBlock     ;($C7CB)Thou hast not enough money.
LD82A:  .byte $13               ;TextBlock2, entry 3.

LD82B:  JMP EndKeyDialog        ;($D804)End key shop dialog.

BuyKey:
LD82E:  LDA GenWord3CLB         ;
LD830:  STA GoldLB              ;
LD832:  LDA GenWord3CUB         ;Subtract key cost from player's gold.
LD834:  STA GoldUB              ;
LD836:  INC InventoryKeys       ;

LD838:  JSR Dowindow            ;($C6F0)display on-screen window.
LD83B:  .byte WND_POPUP         ;Pop-up window.

LD83C:  JSR DoDialogLoBlock     ;($C7CB)Here, take this key...
LD83F:  .byte $15               ;TextBlock2, entry 5.

LD840:  JMP KeyDialogLoop       ;($D7FE)Loop to see if player wants another key.

;----------------------------------------------------------------------------------------------------

FairyDialog:
LD843:  LDA #$26                ;
LD845:  STA GenWrd00LB          ;Set fairy water price of 38 gold.
LD847:  LDA #$00                ;
LD849:  STA GenWrd00UB          ;

LD84B:  JSR DoDialogLoBlock     ;($C7CB)Will thou buy some fairy water...
LD84E:  .byte $11               ;TextBlock2, entry 1.

FairyDialogLoop:
LD84F:  JSR Dowindow            ;($C6F0)display on-screen window.
LD852:  .byte WND_YES_NO1       ;Yes/no selection window.

LD853:  BEQ ChkBuyFryWtr        ;Did player choose to buy some? If so, branch.

EndFairyDialog:
LD855:  JSR DoDialogLoBlock     ;($C7CB)All the best to thee...
LD858:  .byte $0C               ;TextBlock1, entry 12.

LD859:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkBuyFryWtr:
LD85C:  LDA GoldLB              ;
LD85E:  SEC                     ;
LD85F:  SBC GenWrd00LB          ;
LD861:  STA GenWord3CLB         ;Does player have enough money for fairy water?
LD863:  LDA GoldUB              ;If so, branch to see if it will fit in inventory.
LD865:  SBC GenWrd00UB          ;
LD867:  STA GenWord3CUB         ;
LD869:  BCS ChkFryWtrInv        ;

LD86B:  JSR DoDialogLoBlock     ;($C7CB)Thou hast not enough money.
LD86E:  .byte $22               ;TextBlock3, entry 2.

LD86F:  JMP EndFairyDialog      ;($D855)End fairy water dialog.

ChkFryWtrInv:
LD872:  LDA #ITM_FRY_WATER      ;Attempt to add a fairy water to the player's inventory.
LD874:  JSR AddInvItem          ;($E01B)Add item to inventory.
LD877:  CPX #INV_FULL           ;Is the players inventory full?
LD879:  BNE BuyFairyWater       ;If not, branch to commit to purchase.

LD87B:  JSR DoDialogLoBlock     ;($C7CB)Thou cannot carry anymore.
LD87E:  .byte $21               ;TextBlock3, entry 1.

LD87F:  JMP EndFairyDialog      ;($D855)End fairy water dialog.

BuyFairyWater:
LD882:  LDA GenWord3CLB         ;
LD884:  STA GoldLB              ;Subtract fairy water price from player's gold.
LD886:  LDA GenWord3CUB         ;
LD888:  STA GoldUB              ;

LD88A:  JSR Dowindow            ;($C6F0)display on-screen window.
LD88D:  .byte WND_POPUP         ;Pop-up window.

LD88E:  JSR DoDialogLoBlock     ;($C7CB)I thank thee. Won't thou buy another bottle...
LD891:  .byte $10               ;TextBlock2, entry 0.

LD892:  JMP FairyDialogLoop     ;($D84F)Loop to see if player wants to buy another.

;----------------------------------------------------------------------------------------------------

InnDialog:
LD895:  SEC                     ;Convert dialog control byte to-->
LD896:  SBC #$11                ;proper index in InnCostTbl.

LD898:  TAX                     ;Get inn cost from InnCostTbl.
LD899:  LDA InnCostTbl,X        ;

LD89C:  STA GenWrd00LB          ;
LD89E:  LDA #$00                ;Store inn cost. Upper byte is always 0.
LD8A0:  STA GenWrd00UB          ;

LD8A2:  JSR DoDialogLoBlock     ;($C7CB)Welcome to the traveler's inn...
LD8A5:  .byte $0B               ;TextBlock1, entry 11.

LD8A6:  JSR Dowindow            ;($C6F0)display on-screen window.
LD8A9:  .byte WND_YES_NO1       ;Yes/no selection window.

LD8AA:  BEQ ChkBuyInnStay       ;Did player choose to stay at the inn? if so, branch.

LD8AC:  JSR DoDialogLoBlock     ;($C7CB)Ok. Good-bye, traveler...

InnExitDialog2:
LD8AF:  .byte $0A               ;TextBlock1, entry 10.

LD8B0:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkBuyInnStay:
LD8B3:  LDA GoldLB              ;
LD8B5:  SEC                     ;
LD8B6:  SBC GenWrd00LB          ;
LD8B8:  STA GenWord3CLB         ;Does player have enough money to buy a night at the inn?
LD8BA:  LDA GoldUB              ;If so, branch to commit to purchase.
LD8BC:  SBC GenWrd00UB          ;
LD8BE:  STA GenWord3CUB         ;
LD8C0:  BCS BuyInnStay          ;

LD8C2:  JSR DoDialogLoBlock     ;($C7CB)Though hast not enough money...
LD8C5:  .byte $22               ;TextBlock3, entry 2.

LD8C6:  JMP InnExitDialog2      ;($D8AF)Exit inn dialog.

BuyInnStay:
LD8C9:  LDA GenWord3CLB         ;
LD8CB:  STA GoldLB              ;Subtract cost of inn stay from player's gold.
LD8CD:  LDA GenWord3CUB         ;
LD8CF:  STA GoldUB              ;

LD8D1:  JSR Dowindow            ;($C6F0)display on-screen window.
LD8D4:  .byte WND_POPUP         ;Pop-up window.

LD8D5:  JSR DoDialogLoBlock     ;($C7CB)Good night...
LD8D8:  .byte $09               ;TextBlock1, entry 9.

LD8D9:  JSR $D915
LD8DC:  JSR PalFadeOut          ;($C212)Fade out both background and sprite palettes.

LD8DF:  LDA #MSC_INN            ;Inn music.
LD8E1:  BRK                     ;
LD8E2:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LD8E4:  LDA DisplayedMaxHP      ;
LD8E6:  STA HitPoints           ;Stayed at an inn. Restore full HP and MP.
LD8E8:  LDA DisplayedMaxMP      ;
LD8EA:  STA MagicPoints         ;

LD8EC:  JSR Dowindow            ;($C6F0)display on-screen window.
LD8EF:  .byte WND_POPUP         ;Pop-up window.

LD8F0:  JSR GetRegPalPtrs       ;($D915)Get pointers to the standard palettes.

LD8F3:  BRK                     ;Wait for the music clip to end.
LD8F4:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LD8F6:  LDA #MSC_VILLAGE        ;Village music.
LD8F8:  BRK                     ;
LD8F9:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LD8FB:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.

LD8FE:  LDA PlayerFlags         ;Is player carrying Gwaelin?
LD900:  LSR                     ;
LD901:  BCC SpecialInnDialog    ;If not, branch for normal Inn dialog.

LD903:  JSR DoDialogLoBlock     ;($C7CB)Good morning. Thou has had a good night's sleep...
LD906:  .byte $06               ;TextBlock1, entry 6.

LD907:  JMP InnExitDialog       ;($D90E)Finish Inn dialog.

SpecialInnDialog:
LD90A:  JSR DoDialogLoBlock     ;($C7CB)Good morning. Thou seems to have had a good night...
LD90D:  .byte $08               ;TextBlock1, entry 8.

InnExitDialog:
LD90E:  JSR DoDialogLoBlock     ;($C7CB)I shall see thee again.
LD911:  .byte $07               ;TextBlock1, entry 7.

LD912:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

GetRegPalPtrs:
LD915:  LDA RegSPPalPtr         ;
LD918:  STA SprtPalPtrLB        ;Get a pointer to the standard sprite palettes.
LD91A:  LDA RegSPPalPtr+1       ;
LD91D:  STA SprtPalPtrUB        ;

LD91F:  LDA TownPalPtr          ;
LD922:  STA BGPalPtrLB          ;Get a pointer to the standard background palettes.
LD924:  LDA TownPalPtr+1        ;
LD927:  STA BGPalPtrUB          ;

LD929:  LDA #PAL_LOAD_BG        ;
LD92B:  STA LoadBGPal           ;Indicate background palette data should be loaded.
LD92D:  RTS                     ;

;----------------------------------------------------------------------------------------------------

IncDescBuffer:
LD92E:  LDX #$00                ;Prepare to write incrementing numbers-->
LD930:  LDA #$01                ;to the description buffer.

LD932:* STA DescBuf,X           ;
LD934:  INX                     ;Write the values #$01 to #$0A to the description buffer.
LD935:  CLC                     ;
LD936:  ADC #$01                ;
LD938:  CPX #$0B                ;Have all the bytes been written?
LD93A:  BNE -                   ;If not, branch to write another byte.
LD93C:  RTS                     ;

;----------------------------------------------------------------------------------------------------

StairDownFound:
LD93D:  LDA #$00                ;Indicate player came down stairs. Always faces right.
LD93F:  BEQ +                   ;Branch always.

CalcNextMap:
LD941:  LDA #$01                ;Indicate player new facing direction is table lookup.

LD943:* STA GenByte2C           ;Store player direction source flag.

LD945:  LDX #$00                ;Zero out indexes.
LD947:  LDY #$00                ;

MapCheckLoop1:
LD949:  LDA MapNumber           ;Has the right map been found in the table?
LD94B:  CMP MapEntryTbl,X       ;
LD94E:  BNE NextMapEntry1       ;If not, branch to check next table entry.

LD950:  LDA CharXPos            ;Does the X position in the table match the player's position?
LD952:  CMP MapEntryTbl+1,X     ;
LD955:  BNE NextMapEntry1       ;If not, branch to check next table entry.

LD957:  LDA CharYPos            ;Does the Y position in the table match the player's position?
LD959:  CMP MapEntryTbl+2,X     ;
LD95C:  BNE NextMapEntry1       ;If not, branch to check next table entry.

LD95E:  LDA MapTargetTbl,X      ;Set the player's new map.
LD961:  STA MapNumber           ;

LD963:  LDA MapTargetTbl+1,X    ;
LD966:  STA CharXPos            ;Set player's new X position.
LD968:  STA _CharXPos           ;
LD96A:  STA CharXPixelsLB       ;Pixel value will be processed more later.

LD96C:  LDA MapTargetTbl+2,X    ;
LD96F:  STA CharYPos            ;Set player's new Y position.
LD971:  STA _CharYPos           ;
LD973:  STA CharYPixelsLB       ;Pixel value will be processed more later.

LD975:  LDA GenByte2C           ;Did player just come down stairs?
LD977:  BEQ StairsFaceRight     ;If so, branch to make player face right.

LD979:  LDA MapEntryDirTbl,Y    ;Get player's new facing direction from table.
LD97C:  JMP SetPlyrPixelLoc     ;($D981)Set player's X and Y pixel location.

StairsFaceRight:
LD97F:  LDA #DIR_RIGHT          ;Came down stairs. Player always faces right.

SetPlyrPixelLoc:
LD981:  AND #$03                ;Save the bits representing the player's facing direction.
LD983:  STA CharDirection       ;

LD986:  LDA #$00                ;
LD988:  STA CharXPixelsUB       ;Clear out upper byte of player's pixel location.
LD98A:  STA CharYPixelsUB       ;

LD98C:  LDX #$04                ;Prepare to loop 4 times.

LD98E:* ASL CharXPixelsLB       ;
LD990:  ROL CharXPixelsUB       ;Multiply given pixel position by 16 as the block position -->
LD992:  ASL CharYPixelsLB       ;has been given. Each block is 16X16 pixels.
LD994:  ROL CharYPixelsUB       ;
LD996:  DEX                     ;Done multiplying?
LD997:  BNE -                   ;If not, branch to shift again.

LD999:  JMP MapChngWithSound    ;($B097)Change maps with stairs sound.

NextMapEntry1:
LD99C:  INX                     ;
LD99D:  INX                     ;Increment to next entry in MapEntryTbl.
LD99E:  INX                     ;

LD99F:  INY                     ;Increment to next entry in MapEntryDirTbl.

LD9A0:  CPX #$99                ;Have all the entries been checked?
LD9A2:  BNE MapCheckLoop1       ;If not, loop to check another entry.

LD9A4:  JSR Dowindow            ;($C6F0)display on-screen window.
LD9A7:  .byte WND_DIALOG        ;Dialog window.

LD9A8:  JSR DoDialogLoBlock     ;($C7CB)Thou cannot enter here...
LD9AB:  .byte $0E               ;TextBlock 1, entry 14.

LD9AC:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

CheckStairs:
LD9AF:  LDA CharXPos            ;
LD9B1:  STA XTarget             ;Get X and Y location of block player is standing on.
LD9B3:  LDA CharYPos            ;
LD9B5:  STA YTarget             ;
LD9B7:  JSR GetBlockID          ;($AC17)Get description of block.

LD9BA:  LDA TargetResults       ;Is player standing on a stair down block?
LD9BC:  CMP #BLK_STAIR_DN       ;
LD9BE:  BNE ChkStairsUp         ;If not, branch to check for a stair up block.

LD9C0:  JMP StairDownFound      ;Jump to go down stairs.

ChkStairsUp:
LD9C3:  CMP #BLK_STAIR_UP       ;Is player standing on stair up block?
LD9C5:  BNE NoStairsFound       ;If not, branch to tell player no stairs are here.

StairUpFound:
LD9C7:  LDX #$00                ;Zero out indexes.
LD9C9:  LDY #$00                ;

MapCheckLoop2:
LD9CB:  LDA MapNumber           ;Has the right map been found in the table?
LD9CD:  CMP MapTargetTbl,X      ;
LD9D0:  BNE NextMapEntry2       ;If not, branch to check next table entry.

LD9D2:  LDA CharXPos            ;Does the X position in the table match the player's position?
LD9D4:  CMP MapTargetTbl+1,X    ;
LD9D7:  BNE NextMapEntry2       ;If not, branch to check next table entry.

LD9D9:  LDA CharYPos            ;Does the Y position in the table match the player's position?
LD9DB:  CMP MapTargetTbl+2,X    ;
LD9DE:  BNE NextMapEntry2       ;If not, branch to check next table entry.

LD9E0:  LDA #DIR_LEFT           ;Came up stairs. Player always faces left.

ChangeMaps:
LD9E2:  PHA                     ;Save A on stack.

LD9E3:  LDA MapEntryTbl,X       ;Set the player's new map.
LD9E6:  STA MapNumber           ;

LD9E8:  LDA MapEntryTbl+1,X     ;
LD9EB:  STA CharXPos            ;Set player's new X position.
LD9ED:  STA _CharXPos           ;
LD9EF:  STA CharXPixelsLB       ;Pixel value will be processed more later.

LD9F1:  LDA MapEntryTbl+2,X     ;
LD9F4:  STA CharYPos            ;Set player's new Y position.
LD9F6:  STA _CharYPos           ;
LD9F8:  STA CharYPixelsLB       ;Pixel value will be processed more later.

LD9FA:  PLA                     ;Restore A from stack.
LD9FB:  JMP SetPlyrPixelLoc     ;($D981)Set player's X and Y pixel location.

NextMapEntry2:
LD9FE:  INX                     ;
LD9FF:  INX                     ;Increment to next entry in MapTargetTbl.
LDA00:  INX                     ;

LDA01:  INY                     ;Increment to next entry in MapEntryDirTbl.

LDA02:  CPX #$99                ;Have all the entries been checked?
LDA04:  BNE MapCheckLoop2       ;If not, loop to check another entry.

NoStairsFound:
LDA06:  JSR Dowindow            ;($C6F0)display on-screen window.
LDA09:  .byte WND_DIALOG        ;Dialog window.

LDA0A:  JSR DoDialogLoBlock     ;($C7CB)There are no stairs here...
LDA0D:  .byte $0D               ;TextBlock1, entry 13.

LDA0E:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

;These functions handle non-combat spell casting.

DoSpell:
LDA11:  LDA SpellFlags          ;
LDA13:  STA SpellFlagsLB        ;Get a copy of all the spells the player has.
LDA15:  LDA ModsnSpells         ;
LDA17:  AND #$03                ;
LDA19:  STA SpellFlagsUB        ;

LDA1B:  ORA SpellFlagsLB        ;Does the player have any spells at all?
LDA1D:  BNE +                   ;If so, branch to bring up spell window.

LDA1F:  JSR Dowindow            ;($C6F0)display on-screen window.
LDA22:  .byte WND_DIALOG        ;Dialog window.

LDA23:  JSR DoDialogLoBlock     ;($C7CB)Player cannot use the spell...
LDA26:  .byte $31               ;TextBlock4, entry 1.

LDA27:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

LDA2A:* JSR ShowSpells          ;($DB56)Bring up the spell window.

LDA2D:  CMP #WND_ABORT          ;Was the spell cancelled?
LDA2F:  BNE +                   ;If not, branch.

LDA31:  JMP ClrNCCmdWnd         ;($CF6A)Remove non-combat command window from screen.

LDA34:* PHA                     ;Save the spell cast on the stack for now.

LDA35:  JSR Dowindow            ;($C6F0)display on-screen window.
LDA38:  .byte WND_DIALOG        ;Dialog window.

LDA39:  PLA                     ;Load A with the spell cast.
LDA3A:  JSR CheckMP             ;($DB85)Check if MP is high enough to cast the spell.

LDA3D:  CMP #$32                ;TextBlock4, entry 2.
LDA3F:  BNE ChkHeal             ;($DA47)Check which spell was cast.
LDA41:  JSR DoMidDialog         ;($C7BD)Thy MP is too low...

LDA44:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkHeal:
LDA47:  CMP #SPL_HEAL           ;Was heal spell cast?
LDA49:  BNE ChkHurt             ;If not, branch to move on.

LDA4B:  JSR DoHeal              ;($DBB8)Add points to HP from heal spell.
LDA4E:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkHurt:
LDA51:  CMP #SPL_HURT           ;Was hurt spell cast?
LDA53:  BNE +                   ;If not, branch to move on.

SpellFizzle:
LDA55:  JSR DoDialogLoBlock     ;($C7CB)But nothing happened...
LDA58:  .byte $33               ;TextBlock4, entry 3.

LDA59:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

LDA5C:* CMP #SPL_SLEEP          ;Was sleep spell cast?
LDA5E:  BEQ SpellFizzle         ;If so, branch to indicate nothing happened.

LDA60:  CMP #SPL_RADIANT        ;Was radiant spell cast?
LDA62:  BNE ChkRepel            ;If not, branch to move on.

LDA64:  LDA MapType             ;Is the player in a dungeon?
LDA66:  CMP #MAP_DUNGEON        ;
LDA68:  BNE SpellFizzle         ;If not, branch to indicate nothing happened.

LDA6A:  LDA #$50                ;Set the radiant timer.
LDA6C:  STA RadiantTimer        ;

LDA6E:  LDA #WND_DIALOG         ;Remove the dialog window from the screen.
LDA70:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDA73:  LDA #WND_CMD_NONCMB     ;Remove the command window from the screen.
LDA75:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDA78:  LDA #WND_POPUP          ;Remove the pop-up window from the screen.
LDA7A:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LightIncreaseLoop:
LDA7D:  LDA LightDiameter       ;Radiant cast. Is the radiant diameter already maxed?
LDA7F:  CMP #$07                ;
LDA81:  BNE +                   ;If not, branch to increase the light diameter.
LDA83:  RTS                     ;Else exit.

LDA84:* CLC                     ;
LDA85:  ADC #$02                ;Increase the light diameter by 2 blocks.
LDA87:  STA LightDiameter       ;

LDA89:  LDA #SFX_RADIANT        ;Radiant spell SFX.
LDA8B:  BRK                     ;
LDA8C:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDA8E:  JSR PostMoveUpdate      ;($B30E)Update nametables after player moves.
LDA91:  JMP LightIncreaseLoop   ;Loop to keep increasing light diameter to maximum.

ChkRepel:
LDA94:  CMP #SPL_REPEL          ;Was repel cast?
LDA96:  BNE ChkOutside          ;If not, branch to move on.

LDA98:  LDA #$FF                ;Max out the repel timer.
LDA9A:  STA RepelTimer          ;
LDA9C:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkOutside:
LDA9F:  CMP #SPL_OUTSIDE        ;Was outside cast?
LDAA1:  BNE ChkHealmore         ;If not, branch to move on.

ChkErdricksCave:
LDAA3:  LDA MapNumber           ;
LDAA5:  CMP #MAP_ERDRCK_B1      ;Is player in Erdrick's cave?
LDAA7:  BCC ChkGarinhamCave     ;If not, branch.

LDAA9:  LDX #$27                ;Overworld at Erdrick's cave entrance.
LDAAB:  LDA #DIR_DOWN           ;Player will be facing down.
LDAAD:  JMP ChangeMaps          ;($D9E2)Load a new map.

ChkGarinhamCave:
LDAB0:* CMP #MAP_CVGAR_B1       ;Is player in Garinham cave?
LDAB2:  BCC ChkRockMtn          ;If not, branch.

LDAB4:  LDX #$39                ;Overworld at Garinham cave entrance.
LDAB6:  LDA #DIR_DOWN           ;Player will be facing down.
LDAB8:  JMP ChangeMaps          ;($D9E2)Load a new map.

ChkRockMtn:
LDABB:  CMP #MAP_RCKMTN_B1      ;Is player in the rock mountain cave?
LDABD:  BCC ChkSwampCave        ;If not, branch.

LDABF:  LDX #$18                ;Overworld at rock mountain cave entrance.
LDAC1:  LDA #DIR_DOWN           ;Player will be facing down.
LDAC3:  JMP ChangeMaps          ;($D9E2)Load a new map.

ChkSwampCave:
LDAC6:  CMP #MAP_SWAMPCAVE      ;Is player in the swamp cave?
LDAC8:  BNE ChkDLCastle         ;If not, branch.

LDACA:  LDX #$0F                ;Overworld at swamp cave entrance.
LDACC:  LDA #DIR_DOWN           ;Player will be facing down.
LDACE:  JMP ChangeMaps          ;($D9E2)Load a new map.

ChkDLCastle:
LDAD1:  CMP #MAP_DLCSTL_SL1     ;Is player in the Dragon Lord's castle?
LDAD3:  BCS OutsideDLCastle     ;If so, branch to exit castle.

LDAD5:  CMP #MAP_DLCSTL_BF      ;Is player in the basement of the Dragon Lord's castle?
LDAD7:  BEQ OutsideDLCastle     ;If so, branch to exit castle.

LDAD9:  JMP SpellFizzle         ;($DA55)Print text indicating spell did not work.

OutsideDLCastle:
LDADC:  LDX #$12                ;Overworld at dragon lord's castle.
LDADE:  LDA #$02                ;Player will be facing down.
LDAE0:  JMP ChangeMaps          ;($D9E2)Load a new map.

ChkHealmore:
LDAE3:  CMP #SPL_HEALMORE       ;Was healmore spell cast?
LDAE5:  BNE ChkReturn           ;If not, branch to move on.

LDAE7:  JSR DoHealmore          ;($DBD7)Increase health from healmore spell.
LDAEA:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkReturn:
LDAED:  CMP #SPL_RETURN         ;Was return spell cast?
LDAEF:  BNE UnknownSpell        ;If not, branch to exit. Unknown spell. Something went wrong.

LDAF1:  LDA MapType             ;Is the player in a dungeon?
LDAF3:  CMP #MAP_DUNGEON        ;
LDAF5:  BEQ ReturnFail          ;If so, branch. Spell fails.

LDAF7:  LDA MapNumber           ;Is the player in the bottom of the Dragon Lord's castle?
LDAF9:  CMP #MAP_DLCSTL_BF      ;
LDAFB:  BNE DoReturn            ;If so, branch. Spell fails.  

ReturnFail:
LDAFD:  JMP SpellFizzle         ;($DA55)Print text indicating spell did not work.

DoReturn:
LDB00:  LDA #MAP_OVERWORLD      ;Set player's current map as the overworld map.
LDB02:  STA MapNumber           ;

LDB04:  LDA #$2A                ;Set player's new X position right next to the castle.
LDB06:  STA CharXPos            ;
LDB08:  STA _CharXPos           ;
LDB0A:  STA CharXPixelsLB       ;Pixel value will be processed more later.

LDB0C:  LDA #$2B                ;Set player's new Y position right next to the castle.
LDB0E:  STA CharYPos            ;
LDB10:  STA _CharYPos           ;
LDB12:  STA CharYPixelsLB       ;Pixel value will be processed more later.

LDB14:  LDA #$00                ;
LDB16:  STA CharXPixelsUB       ;Clear out upper byte of player's pixel location.
LDB18:  STA CharYPixelsUB       ;

LDB1A:  LDX #$04                ;Prepare to loop 4 times.

LDB1C:* ASL CharXPixelsLB       ;
LDB1E:  ROL CharXPixelsUB       ;Multiply given pixel position by 16 as the block position -->
LDB20:  ASL CharYPixelsLB       ;has been given. Each block is 16X16 pixels.
LDB22:  ROL CharYPixelsUB       ;
LDB24:  DEX                     ;Done multiplying?
LDB25:  BNE -                   ;If not, branch to shift again.

LDB27:  LDA #SFX_WVRN_WNG       ;Wyvern wing SFX.
LDB29:  BRK                     ;
LDB2A:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDB2C:  LDA #DIR_DOWN           ;Set player facing direction to down.
LDB2E:  STA CharDirection       ;
LDB31:  JMP MapChngNoFadeOut    ;($B08D)Change map with no fade out or stairs sound.

UnknownSpell:
LDB34:  JMP SpellFizzle         ;($DA55)Print text indicating spell did not work.

;----------------------------------------------------------------------------------------------------

BWScreenFlash:
LDB37:  LDX #$08                ;Prepare to flash screen 8 times.
LDB39:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDB3C:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LDB3F:  LDA #%00011001          ;Change screen to greyscale colors.
LDB41:  STA PPUControl1         ;

LDB44:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDB47:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDB4A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LDB4D:  LDA #%00011000          ;Change screen to RGB colors.
LDB4F:  STA PPUControl1         ;

LDB52:  DEX                     ;Has the screen been flashed 8 times?
LDB53:  BNE -                   ;If not, branch to flash again.
LDB55:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ShowSpells:
LDB56:  JSR IncDescBuffer       ;($D92E)Write #$01-#$0A to the description buffer.
LDB59:  LDA #$02                ;Start description bytes for spells at #$02. 2 will be -->
LDB5B:  STA SpellDescByte       ;subtracted before the function returns.
LDB5D:  LDX #$01                ;Start at index 1 in the description buffer.

GetSpellsLoop:
LDB5F:  LSR SpellFlagsUB        ;Rotate spell flags through the carry bit to see if the -->
LDB61:  ROR SpellFlagsLB        ;player has a given spell. Does the player have the spell?
LDB63:  BCC nextSpell           ;If not, branch to check the next spell.

LDB65:  LDA SpellDescByte       ;
LDB67:  STA DescBuf,X           ;Player has the spell. Put it in the description buffer.
LDB69:  INX                     ;

nextSpell:
LDB6A:  INC SpellDescByte       ;Increment to next spell description byte.
LDB6C:  LDA SpellDescByte       ;
LDB6E:  CMP #$0C                ;Have all the spells been checked?
LDB70:  BNE GetSpellsLoop       ;If not, branch to check the next spell.

LDB72:  LDA #DSC_END            ;Mark the end of the description buffer.
LDB74:  STA DescBuf,X           ;

LDB76:  JSR Dowindow            ;($C6F0)display on-screen window.
LDB79:  .byte WND_SPELL2        ;Spell window.

LDB7A:  CMP #WND_ABORT          ;Did the player abort the spell selection?
LDB7C:  BEQ ShowSpellEnd        ;If so, branch to exit.

LDB7E:  TAX                     ;
LDB7F:  LDA DescBuf+1,X         ;The value from the description buffer needs to have 2 -->
LDB81:  SEC                     ;subtracted from it to get the proper value for the spell -->
LDB82:  SBC #$02                ;description text. Do that here.

ShowSpellEnd:
LDB84:  RTS                     ;Exit with the spell chosen in the accumulator.

;----------------------------------------------------------------------------------------------------

CheckMP:
LDB85:  STA SpellToCast         ;
LDB87:  LDX SpellToCast         ;Does player have enough MP to cast the spell?
LDB89:  LDA MagicPoints         ;
LDB8B:  CMP SpellCostTbl,X      ;
LDB8E:  BCS PlyrCastSpell       ;If so, branch.

LDB90:  LDA #$32                ;TextBlock4, entry 2.
LDB92:  RTS                     ;Player does not have enough MP. Return.

PlyrCastSpell:
LDB93:  SBC SpellCostTbl,X      ;Subtract the spell's required MP from player's MP.
LDB96:  STA MagicPoints         ;

LDB98:  LDA SpellToCast         ;
LDB9A:  CLC                     ;Add offset to find spell description.
LDB9B:  ADC #$10                ;
LDB9D:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LDBA0:  JSR DoDialogLoBlock     ;($C7CB)Player chanted the spell...
LDBA3:  .byte $30               ;TextBlock4, entry 0.

LDBA4:  LDA #SFX_SPELL          ;Spell cast SFX.
LDBA6:  BRK                     ;
LDBA7:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDBA9:  JSR BWScreenFlash       ;($DB37)Flash screen in black and white.

LDBAC:  BRK                     ;Wait for the music clip to end.
LDBAD:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LDBAF:  LDA SpellToCast         ;Save the cast spell number on the stack.
LDBB1:  PHA                     ;

LDBB2:  JSR Dowindow            ;($C6F0)display on-screen window.
LDBB5:  .byte WND_POPUP         ;Pop-up window.

LDBB6:  PLA                     ;Return with the cast spell number in the accumulator.
LDBB7:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoHeal:
LDBB8:  JSR UpdateRandNum       ;($C55B)Get random number.
LDBBB:  LDA RandNumUB           ;
LDBBD:  AND #$07                ;Keep lower 3 bits.
LDBBF:  CLC                     ;Add to 10.
LDBC0:  ADC #$0A                ;Heal adds 10 to 17 points to HP.

PlyrAddHP:
LDBC2:  CLC                     ;Did HP value roll over to 0?
LDBC3:  ADC HitPoints           ;
LDBC5:  BCS PlyrMaxHP           ;If so, branch to set maxHP.

LDBC7:  CMP DisplayedMaxHP      ;Did HP value exceed player's max HP?
LDBC9:  BCC +                   ;If not, branch to update HP.

PlyrMaxHP:
LDBCB:  LDA DisplayedMaxHP      ;Max out player's HP.

LDBCD:* STA HitPoints           ;Store player's new HP value.
LDBCF:  JSR LoadRegBGPal        ;($EE28)Load the normal background palette.

LDBD2:  JSR Dowindow            ;($C6F0)display on-screen window.
LDBD5:  .byte WND_POPUP         ;Pop-up window.
LDBD6:  RTS                     ;

DoHealmore:
LDBD7:  JSR UpdateRandNum       ;($C55B)Get random number.
LDBDA:  LDA RandNumUB           ;
LDBDC:  AND #$0F                ;Keep lower 4 bits.
LDBDE:  CLC                     ;
LDBDF:  ADC #$55                ;Add to 85
LDBE1:  JMP PlyrAddHP           ;Healmore adds 85 to 100 points to HP.

;----------------------------------------------------------------------------------------------------

CopyEnUpperBytes:
LDBE4:  LDA #$08                ;
LDBE6:  STA $3C                 ;Copy the unused enemy bytes into the description buffer.
LDBE8:  LDA #$01                ;
LDBEA:  STA $3D                 ;

LDBEC:  LDY #$00                ;Index is always 0.
LDBEE:  BEQ GetThisDescLoop     ;Branch always.

GetDescriptionByte:
LDBF0:  CLC                     ;
LDBF1:  ADC #$03                ;Add 4 to the item description entry number and save in X.
LDBF3:  TAX                     ;
LDBF4:  INX                     ;

LDBF5:  LDA DescTblPtr          ;
LDBF8:  STA GenPtr3CLB          ;Get the base address of the description table.
LDBFA:  LDA DescTblPtr+1        ;
LDBFD:  STA GenPtr3CUB          ;

LDBFF:  LDY #$00                ;Index is always 0. Increment pointer address instead.

DescriptionLoop:
LDC01:  LDA (GenPtr3C),Y        ;
LDC03:  INC GenPtr3CLB          ;Increment through the current description data looking -->
LDC05:  BNE +                   ;for the end marker.
LDC07:  INC GenPtr3CUB          ;

LDC09:* CMP #TXT_SUBEND         ;Has the end marker been found?
LDC0B:  BNE DescriptionLoop     ;If not, branch to get another byte of the description.

LDC0D:  DEX                     ;Found the end of the current description. Are we now aligned -->
LDC0E:  BNE DescriptionLoop     ;with the desired description? If not, branch.

;At this point, the pointer is pointed at the description byte.
;The byte now needs to be transferred into the description buffer.

GetThisDescLoop:
LDC10:  LDA (GenPtr3C),Y        ;
LDC12:  STA _DescBuf,Y          ;
LDC15:  INY                     ;Get a byte of the desired description.
LDC16:  CMP #TXT_SUBEND         ;
LDC18:  BNE GetThisDescLoop     ;Have we found the end marker for the description entry?
LDC1A:  RTS                     ;If not, branch to get next byte in the description.

;----------------------------------------------------------------------------------------------------

CheckInventory:
LDC1B:  JSR CreateInvList       ;($DF77)Create inventory list in description buffer.
LDC1E:  CPX #INV_NONE           ;Does player have any inventory?
LDC20:  BNE ShowInventory       ;If so, branch to show inventory.

LDC22:  JSR Dowindow            ;($C6F0)display on-screen window.
LDC25:  .byte WND_DIALOG        ;Dialog window.

LDC26:  JSR DoDialogLoBlock     ;($C7CB)Nothing of use has yet been given to thee...
LDC29:  .byte $3D               ;TextBlock4, entry 13.

LDC2A:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ShowInventory:
LDC2D:  JSR Dowindow            ;($C6F0)display on-screen window.
LDC30:  .byte WND_INVTRY1       ;Player inventory window.

LDC31:  CMP #WND_ABORT          ;Did player cancel out of inventory window?
LDC33:  BNE ChkItemUsed         ;If not, branch to check item they selected.

LDC35:  JMP ClrNCCmdWnd         ;($CF6A)Remove non-combat command window from screen.

ChkItemUsed:
LDC38:  TAX                     ;Load item description byte into A.
LDC39:  LDA DescBuf+1,X         ;

;----------------------------------------------------------------------------------------------------

ChkKey:
LDC3B:  CMP #INV_KEY            ;Did player select a key?
LDC3D:  BEQ CheckDoor           ;If so, branch to check if a door is near.
LDC3F:  JMP ChkHerb             ;($DCEA)Check if player used an herb.

CheckDoor:
LDC42:  LDA CharXPos            ;
LDC44:  STA XTarget             ;
LDC46:  LDA CharYPos            ;Check for a door above the player.
LDC48:  STA YTarget             ;
LDC4A:  DEC YTarget             ;
LDC4C:  JSR GetBlockID          ;($AC17)Get description of block.

LDC4F:  LDA TargetResults       ;Is there a door above the player?
LDC51:  CMP #BLK_DOOR           ;
LDC53:  BEQ DoorFound           ;If so, branch.

LDC55:  LDA CharXPos            ;
LDC57:  STA XTarget             ;
LDC59:  LDA CharYPos            ;Check for a door below the player.
LDC5B:  STA YTarget             ;
LDC5D:  INC YTarget             ;
LDC5F:  JSR GetBlockID          ;($AC17)Get description of block.

LDC62:  LDA TargetResults       ;Is there a door below the player?
LDC64:  CMP #BLK_DOOR           ;
LDC66:  BEQ DoorFound           ;If so, branch.

LDC68:  LDA CharXPos            ;
LDC6A:  STA XTarget             ;
LDC6C:  LDA CharYPos            ;Check for a door to the left of the player.
LDC6E:  STA YTarget             ;
LDC70:  DEC XTarget             ;
LDC72:  JSR GetBlockID          ;($AC17)Get description of block.

LDC75:  LDA TargetResults       ;Id there a door to the left of the player?
LDC77:  CMP #BLK_DOOR           ;
LDC79:  BEQ DoorFound           ;If so, branch.

LDC7B:  LDA CharXPos            ;
LDC7D:  STA XTarget             ;
LDC7F:  LDA CharYPos            ;Check for a door to the right of the player.
LDC81:  STA YTarget             ;
LDC83:  INC XTarget             ;
LDC85:  JSR GetBlockID          ;($AC17)Get description of block.

LDC88:  LDA TargetResults       ;Is there a door to the right of the player?
LDC8A:  CMP #BLK_DOOR           ;
LDC8C:  BEQ DoorFound           ;If so, branch.

LDC8E:  JSR Dowindow            ;($C6F0)display on-screen window.
LDC91:  .byte WND_DIALOG        ;Dialog window.

LDC92:  JSR DoDialogHiBlock     ;($C7C5)There is no door here...
LDC95:  .byte $0B               ;TextBlock17, entry 11.

LDC96:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

DoorFound:
LDC99:  LDA InventoryKeys       ;Does the player have a key to use?
LDC9B:  BNE UseKey              ;If so, branch.

LDC9D:  JSR Dowindow            ;($C6F0)display on-screen window.
LDCA0:  .byte WND_DIALOG        ;Dialog window.

LDCA1:  JSR DoDialogHiBlock     ;($C7C5)Thou has not a key to use...
LDCA4:  .byte $0C               ;TextBlock17, entry 12.

LDCA5:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

UseKey:
LDCA8:  DEC InventoryKeys       ;Remove a key from the player's inventory.

LDCAA:  LDX #$00                ;Zero out the index.

DoorCheckLoop:
LDCAC:  LDA DoorXPos,X          ;Is this an empty spot to record the opened door?
LDCAF:  BEQ DoorOpened          ;If so, branch.

LDCB1:  INX                     ;Move to next open door slot.
LDCB2:  INX                     ;
LDCB3:  CPX #$10                ;Have 5 slots been searched?
LDCB5:  BNE DoorCheckLoop       ;If not, branch to check next door slot.

LDCB7:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

DoorOpened:
LDCBA:  LDA _TargetX            ;
LDCBC:  STA DoorXPos,X          ;Save the position of the door to indicate it has been opened.
LDCBF:  LDA _TargetY            ;
LDCC1:  STA DoorYPos,X          ;

LDCC4:  LDA _TargetX            ;
LDCC6:  SEC                     ;
LDCC7:  SBC CharXPos            ;Calculate the block X position to remove the door. 
LDCC9:  ASL                     ;
LDCCA:  STA XPosFromCenter      ;

LDCCC:  LDA _TargetY            ;
LDCCE:  SEC                     ;
LDCCF:  SBC CharYPos            ;Calculate the block Y position to remove the door. 
LDCD1:  ASL                     ;
LDCD2:  STA YPosFromCenter      ;

LDCD4:  LDA #$00                ;Remove no tiles from the changed block.
LDCD6:  STA BlkRemoveFlgs       ;

LDCD8:  LDA #SFX_DOOR           ;Door SFX.
LDCDA:  BRK                     ;
LDCDB:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDCDD:  JSR ModMapBlock         ;($AD66)Change block on map.

LDCE0:* JSR GetJoypadStatus     ;($C608)Get input button presses.
LDCE3:  LDA JoypadBtns          ;Have any buttons been pressed?
LDCE5:  BNE -                   ;If not, loop until something is pressed.

LDCE7:  JMP ClrNCCmdWnd         ;($CF6A)Clear non-combat command window.

;----------------------------------------------------------------------------------------------------

ChkHerb:
LDCEA:  CMP #INV_HERB           ;Did player use an herb?
LDCEC:  BNE ChkTorch            ;If not, branch.

LDCEE:  JSR Dowindow            ;($C6F0)display on-screen window.
LDCF1:  .byte WND_DIALOG        ;Dialog window.

LDCF2:  JSR DoDialogLoBlock     ;($C7CB)Player used the herb.
LDCF5:  .byte $F7               ;TextBlock16, entry 7.

LDCF6:  DEC InventoryHerbs      ;Remove an herb from the player's inventory.

LDCF8:  JSR HerbHeal            ;($DCFE)Heal player from an herb.
LDCFB:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

HerbHeal:
LDCFE:  JSR UpdateRandNum       ;($C55B)Get random number.

LDD01:  LDA RandNumUB           ;Get lower 3 bits of a random number.
LDD03:  AND #$07                ;

LDD05:  CLC                     ;
LDD06:  ADC #$17                ;Herb will heal 23-30 HP.
LDD08:  ADC HitPoints           ;

LDD0A:  CMP DisplayedMaxHP      ;Did the player's HP exceed the maximum?
LDD0C:  BCC +                   ;If not, banch.

LDD0E:  LDA DisplayedMaxHP      ;Max out player's HP.

LDD10:* STA HitPoints           ;Update player's HP.
LDD12:  JSR LoadRegBGPal        ;($EE28)Load the normal background palette.

LDD15:  JSR Dowindow            ;($C6F0)display on-screen window.
LDD18:  .byte WND_POPUP         ;Pop-up window.
LDD19:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ChkTorch:
LDD1A:  CMP #INV_TORCH          ;Did player use a torch?
LDD1C:  BNE ChkFryWtr           ;If not, branch.

LDD1E:  LDA MapType             ;Is the player in a dungeon?
LDD20:  CMP #MAP_DUNGEON        ;
LDD22:  BEQ UseTorch            ;if so, branch.

LDD24:  JSR Dowindow            ;($C6F0)display on-screen window.
LDD27:  .byte WND_DIALOG        ;Dialog window.

LDD28:  JSR DoDialogLoBlock     ;($C7CB)A torch can only be used in dark places...
LDD2B:  .byte $35               ;TextBlock4, entry 5.

LDD2C:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

UseTorch:
LDD2F:  LDA #ITM_TORCH          ;Remove torch from inventory.
LDD31:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LDD34:  LDA #$00                ;Clear any remaining time in the radiant timer.
LDD36:  STA RadiantTimer        ;

LDD38:  LDA #WND_DIALOG         ;Remove the dialog window.
LDD3A:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDD3D:  LDA #WND_CMD_NONCMB     ;Remove command window.
LDD3F:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDD42:  LDA #WND_POPUP          ;Remove pop-up window.
LDD44:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LDD47:  LDA #$03                ;Set the light diameter to 3 blocks.
LDD49:  STA LightDiameter       ;

LDD4B:  LDA #SFX_RADIANT        ;Radiant spell SFX.
LDD4D:  BRK                     ;
LDD4E:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDD50:  JMP PostMoveUpdate      ;($B30E)Update nametables after player moves.

;----------------------------------------------------------------------------------------------------

ChkFryWtr:
LDD53:  CMP #INV_FAIRY          ;Did player use fairy water?
LDD55:  BNE ChkWings            ;If not, branch.

LDD57:  JSR Dowindow            ;($C6F0)display on-screen window.
LDD5A:  .byte WND_DIALOG        ;Dialog window.

LDD5B:  JSR DoDialogLoBlock     ;($C7CB)Player sprinkled the fairy water over his body...
LDD5E:  .byte $36               ;TextBlock4, entry 6.

LDD5F:  LDA #ITM_FRY_WATER      ;Remove the fairy water from the player's inventory.
LDD61:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LDD64:  LDA #$FE                ;Set the repel timer.
LDD66:  STA RepelTimer          ;
LDD68:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkWings:
LDD6B:  CMP #INV_WINGS          ;Did player use the wyvern wings?
LDD6D:  BNE ChkDrgnScl          ;If not, branch.

LDD6F:  JSR Dowindow            ;($C6F0)display on-screen window.
LDD72:  .byte WND_DIALOG        ;Dialog window.

LDD73:  LDA MapType             ;Is player in a dungeon?
LDD75:  CMP #MAP_DUNGEON        ;
LDD77:  BEQ WingsFail           ;If so, branch to not use the wing.

LDD79:  LDA MapNumber           ;Is player in basement of the dragon lord's castle?
LDD7B:  CMP #MAP_DLCSTL_BF      ;
LDD7D:  BNE UseWings            ;If not, branch to use the wing.

WingsFail:
LDD7F:  JSR DoDialogLoBlock     ;($C7CB)TextBlock4, entry 8.
LDD82:  .byte $38               ;The wings cannot be used here...

LDD83:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

UseWings:
LDD86:  LDA #ITM_WINGS          ;Remove wings from inventory.
LDD88:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LDD8B:  JSR DoDialogLoBlock     ;($C7CB)TextBlock4, entry 9.
LDD8E:  .byte $39               ;Player threw the wings into the air...

LDD8F:  JSR BWScreenFlash       ;($DB37)Flash screen in black and white.
LDD92:  JMP DoReturn            ;($DB00)Return player back to the castle.

;----------------------------------------------------------------------------------------------------

ChkDrgnScl:
LDD95:  CMP #INV_SCALE          ;Did player use the dragon's scale?
LDD97:  BNE ChkFryFlt           ;If not, branch.

LDD99:  JSR Dowindow            ;($C6F0)display on-screen window.
LDD9C:  .byte WND_DIALOG        ;Dialog window.

LDD9D:  JSR ChkDragonScale      ;($DFB9)Check if player is wearing the dragon's scale.
LDDA0:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkFryFlt:
LDDA3:  CMP #INV_FLUTE          ;Did player use the fairy's flute?
LDDA5:  BNE ChkFghtrRng         ;If not, branch.

LDDA7:  JSR Dowindow            ;($C6F0)display on-screen window.
LDDAA:  .byte WND_DIALOG        ;Dialog window.

LDDAB:  JSR DoDialogLoBlock     ;($C7CB)Player blew the faries' flute...
LDDAE:  .byte $3C               ;TextBlock4, entry 12.

LDDAF:  LDA #MSC_FRY_FLUTE      ;Fairy flute music.
LDDB1:  BRK                     ;
LDDB2:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDDB4:  BRK                     ;Wait for the music clip to end.
LDDB5:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LDDB7:  LDX MapNumber           ;Get current map number.
LDDB9:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LDDBC:  BRK                     ;
LDDBD:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDDBF:  JSR DoDialogLoBlock     ;($C7CB)But nothing happened...
LDDC2:  .byte $33               ;TextBlock4, entry 3.

LDDC3:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkFghtrRng:
LDDC6:  CMP #INV_RING           ;Did player use the fighter's ring?
LDDC8:  BNE ChkToken            ;If not, branch.

LDDCA:  JSR Dowindow            ;($C6F0)display on-screen window.
LDDCD:  .byte WND_DIALOG        ;Dialog window.

LDDCE:  JSR ChkRing             ;($DFD1)Check if player is wearing the ring.
LDDD1:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkToken:
LDDD4:  CMP #INV_TOKEN          ;Did the player use Erdrick's token?
LDDD6:  BNE ChkStones           ;If not, branch.

LDDD8:  JSR Dowindow            ;($C6F0)display on-screen window.
LDDDB:  .byte WND_DIALOG        ;Dialog window.

LDDDC:  LDA #$38                ;Index to Erdrick's token description.

DoItemDescription:
LDDDE:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LDDE1:  JSR DoDialogLoBlock     ;($C7CB)Player held the item tightly...
LDDE4:  .byte $40               ;TextBox5, entry 0.

LDDE5:  JSR DoDialogLoBlock     ;($C7CB)But nothing happened...
LDDE8:  .byte $33               ;TextBlock4, entry 3.

LDDE9:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkStones:
LDDEC:  CMP #INV_STONES         ;Did the player use the stones of sunlight?
LDDEE:  BNE ChkStaff            ;If not, branch.

LDDF0:  JSR Dowindow            ;($C6F0)display on-screen window.
LDDF3:  .byte WND_DIALOG        ;Dialog window.

LDDF4:  LDA #$3D                ;Index to stones of sunlight description.
LDDF6:  BNE DoItemDescription   ;Branch always.

;----------------------------------------------------------------------------------------------------

ChkStaff:
LDDF8:  CMP #INV_STAFF          ;Did the player use the staff of rain?
LDDFA:  BNE ChkHarp             ;If not, branch.

LDDFC:  JSR Dowindow            ;($C6F0)display on-screen window.
LDDFF:  .byte WND_DIALOG        ;Dialog window.

LDE00:  LDA #$3E                ;Index to staff of rain description.
LDE02:  BNE DoItemDescription   ;Branch always.

;----------------------------------------------------------------------------------------------------

ChkHarp:
LDE04:  CMP #INV_HARP           ;Did the player use the harp?
LDE06:  BNE ChkBelt             ;If not, branch.

LDE08:  JSR Dowindow            ;($C6F0)display on-screen window.
LDE0B:  .byte WND_DIALOG        ;Dialog window.

LDE0C:  JSR DoDialogLoBlock     ;($C7CB)Player played a sweet melody on the harp...
LDE0F:  .byte $41               ;TextBox5, entry 1.

LDE10:  LDA #MSC_SILV_HARP      ;Silver harp music.
LDE12:  BRK                     ;
LDE13:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDE15:  BRK                     ;Wait for the music clip to end.
LDE16:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LDE18:  LDA MapNumber           ;Is the player on the overworld map?
LDE1A:  CMP #MAP_OVERWORLD      ;
LDE1C:  BNE HarpFail            ;If not, branch. Harp only work in the overworld.

HarpRNGLoop:
LDE1E:  JSR UpdateRandNum       ;($C55B)Get random number.
LDE21:  LDA RandNumUB           ;
LDE23:  AND #$07                ;Choose a random number that is 0, 1, 2, 3, 4 or 6.
LDE25:  CMP #$05                ;
LDE27:  BEQ HarpRNGLoop         ;The harp will summon either a slime, red slime, drakee -->
LDE29:  CMP #$07                ;ghost, magician or scorpion.
LDE2B:  BEQ HarpRNGLoop         ;Work even after the dragon lord is dead.

LDE2D:  PHA                     ;Store the random enemy number on the stack.

LDE2E:  LDA #WND_DIALOG         ;Remove the dialog window.
LDE30:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDE33:  LDA #WND_CMD_NONCMB     ;Remove the command window.
LDE35:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDE38:  LDA #WND_POPUP          ;Remove the popup window.
LDE3A:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LDE3D:  PLA                     ;Restore the enemy number back to A.
LDE3E:  JMP InitFight           ;($E4DF)Begin fight sequence.

HarpFail:
LDE41:  LDX MapNumber           ;Get current map number.
LDE43:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LDE46:  BRK                     ;
LDE47:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDE49:  JSR DoDialogLoBlock     ;($C7CB)But nothing happened...
LDE4C:  .byte $33               ;TextBox4, entry 3.

LDE4D:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkBelt:
LDE50:  CMP #INV_BELT           ;Did the player use the cursed belt?
LDE52:  BNE ChkNecklace         ;If not, branch.

LDE54:  JSR Dowindow            ;($C6F0)display on-screen window.
LDE57:  .byte WND_DIALOG        ;Dialog window.

LDE58:  JSR WearCursedItem      ;($DFE7)Player puts on cursed item.

LDE5B:  LDX MapNumber           ;Get current map number.
LDE5D:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LDE60:  BRK                     ;
LDE61:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDE63:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkNecklace:
LDE66:  CMP #INV_NECKLACE       ;Did the player use the death necklace?
LDE68:  BNE ChkDrop             ;If not, branch.

LDE6A:  JSR Dowindow            ;($C6F0)display on-screen window.
LDE6D:  .byte WND_DIALOG        ;Dialog window.

LDE6E:  JSR ChkDeathNecklace    ;($E00A)Check if player is wearking the death necklace.

LDE71:  LDX MapNumber           ;Get current map number.
LDE73:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LDE76:  BRK                     ;
LDE77:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDE79:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

ChkDrop:
LDE7C:  CMP #INV_DROP           ;Did the player use the rainbow drop?
LDE7E:  BEQ +                   ;If so, branch.

LDE80:  JMP ChkLove             ;Jump to see if player used Gwaelin's love.

LDE83:* JSR Dowindow            ;($C6F0)display on-screen window.
LDE86:  .byte WND_DIALOG        ;Dialog window.

LDE87:  JSR DoDialogLoBlock     ;($C7CB)Player held the rainbow drop toward the sky...
LDE8A:  .byte $04               ;TextBox1, entry 4.

LDE8B:  LDA MapNumber           ;Is the player on the overworld map?
LDE8D:  CMP #MAP_OVERWORLD      ;
LDE8F:  BNE RainbowFail         ;If not, branch. The rainbow bridge creation failed.

LDE91:  LDA CharXPos            ;Is the player in the correct X position?
LDE93:  CMP #$41                ;
LDE95:  BNE RainbowFail         ;If not, branch. The rainbow bridge creation failed.

LDE97:  LDA CharYPos            ;Is the player in the correct Y position?
LDE99:  CMP #$31                ;
LDE9B:  BNE RainbowFail         ;If not, branch. The rainbow bridge creation failed.

LDE9D:  LDA ModsnSpells         ;Has the rainbow bridge already been built?
LDE9F:  AND #F_RNBW_BRDG        ;
LDEA1:  BNE RainbowFail         ;If not, branch. The rainbow bridge creation failed.

LDEA3:  LDA #WND_DIALOG         ;Remove the dialog window.
LDEA5:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDEA8:  LDA #WND_CMD_NONCMB     ;Remove the command window.
LDEAA:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LDEAD:  LDA #WND_POPUP          ;remove the pop-up window.
LDEAF:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LDEB2:  LDA #MSC_RNBW_BRDG      ;Rainbow bridge music.
LDEB4:  BRK                     ;
LDEB5:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDEB7:  LDA ModsnSpells         ;
LDEB9:  ORA #F_RNBW_BRDG        ;Indicate rainbow bridge has been made.
LDEBB:  STA ModsnSpells         ;

LDEBD:  LDA #$FE                ;
LDEBF:  STA XPosFromCenter      ;Prepare to create the rainbow bridge 2 -->
LDEC1:  LDA #$00                ;tiles to the left of the player.
LDEC3:  STA YPosFromCenter      ;

LDEC5:  LDA #$04                ;Prepare to cycle the rainbow flash colors 4 times.
LDEC7:  STA BridgeFlashCntr     ;

BuildBridgeLoop2:
LDEC9:  LDA #$21                ;Load the initial color for rainbow flash.
LDECB:  STA PPUDataByte         ;

BuildBridgeLoop1:
LDECD:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDED0:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDED3:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDED6:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LDED9:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LDEDC:  LDA #$03                ;Prepare to change a background palette color. -->
LDEDE:  STA PPUAddrLB           ;This is the palette location that creates the -->
LDEE0:  LDA #$3F                ;multicolor water effect when the rainbow bridge -->
LDEE2:  STA PPUAddrUB           ;animation is occurring.

LDEE4:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LDEE7:  INC PPUDataByte         ;Increment to next palette color.

LDEE9:  LDA PPUDataByte         ;Has the last palette color ben shown?
LDEEB:  CMP #$12                ;
LDEED:  BEQ BridgeAnimDone      ;If so, branch to end the animation.

LDEEF:  CMP #$2D                ;Has the last palette color in the flash cycle completed?
LDEF1:  BNE BuildBridgeLoop1    ;If not, branch to do the next color.

LDEF3:  DEC BridgeFlashCntr     ;Has 4 cycles of flashing colors finished?
LDEF5:  BNE BuildBridgeLoop2    ;If not, branch to do another cycle.

LDEF7:  LDA #$11                ;Move to the next colors in the palette.
LDEF9:  STA PPUDataByte         ;
LDEFB:  BNE BuildBridgeLoop1    ;Branch always.

BridgeAnimDone:
LDEFD:  BRK                     ;Wait for the music clip to end.
LDEFE:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LDF00:  LDA #MSC_OUTDOOR        ;Outdoor music.
LDF02:  BRK                     ;
LDF03:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDF05:  JMP ModMapBlock         ;($AD66)Change block on map.

RainbowFail:
LDF08:  LDA #$05                ;TextBlock1, entry 5.
LDF0A:  JMP DoFinalDialog       ;($D242)But no rainbow appeared here...

;----------------------------------------------------------------------------------------------------

ChkLove:
LDF0D:  CMP #INV_LOVE           ;Did player use Gwaelin's love?
LDF0F:  BNE EndItemChecks       ;If not, branch to end. No more items to check.

LDF11:  JSR Dowindow            ;($C6F0)display on-screen window.
LDF14:  .byte WND_DIALOG        ;Dialog window.

LDF15:  LDA DisplayedLevel      ;Is player at the max level?
LDF17:  CMP #LVL_30             ;
LDF19:  BNE DoLoveExp           ;If so, branch to skip showing experience for next level.

LDF1B:  JSR DoDialogHiBlock     ;($C7C5)Know thou hast reached the final level...
LDF1E:  .byte $05               ;TextBlock17, entry 5.

LDF1F:  JMP ChkLoveMap          ;Max level already reached. Skip experience dialog.

DoLoveExp:
LDF22:  JSR GetExpRemaining     ;($F134)Calculate experience needed for next level.

LDF25:  JSR DoDialogLoBlock     ;($C7CB)To reach the next level...
LDF28:  .byte $DB               ;TextBlock14, entry 11.

ChkLoveMap:
LDF29:  LDA MapNumber           ;Is player not on the overworld?
LDF2B:  CMP #MAP_OVERWORLD      ;
LDF2D:  BNE LastLoveDialog      ;If not, branch to skip showing distance to castle.

LDF2F:  JSR DoDialogLoBlock     ;($C7CB)From where thou art now, my castle lies...
LDF32:  .byte $DC               ;TextBlock14, entry 12.

LDF33:  JSR DoDialogLoBlock     ;($C7CB)Empty text.
LDF36:  .byte $DD               ;TextBlock14, entry 13.

LDF37:  LDA CharYPos            ;Calculate player's Y distance from castle.
LDF39:  SEC                     ;
LDF3A:  SBC #$2B                ;Is distance a positive value?
LDF3C:  BCS YDiffDialog         ;If so, branch to display value to player.

LDF3E:  EOR #$FF                ;
LDF40:  STA GenByte00           ;Do 2's compliment on number to turn it positive.
LDF42:  INC GenByte00           ;

LDF44:  LDA #$DF                ;TextBlock14, entry 15. To the south...
LDF46:  BNE DoNorthSouthDialog  ;Branch always.

YDiffDialog:
LDF48:  STA GenByte00           ;Store Y distance from the castle.

LDF4A:  LDA #$DE                ;TextBlock14, entry 14. To the north...

DoNorthSouthDialog:
LDF4C:  LDX #$00                ;Zero out register. Never used.
LDF4E:  STX GenByte01           ;
LDF50:  JSR DoMidDialog         ;($C7BD)Show north/south dialog.

LDF53:  LDA CharXPos            ;Calculate player's X distance from castle.
LDF55:  SEC                     ;
LDF56:  SBC #$2B                ;Is distance a positive value?
LDF58:  BCS XDiffDialog         ;If so, branch to display value to player.

LDF5A:  EOR #$FF                ;
LDF5C:  STA GenByte00           ;Do 2's compliment on number to turn it positive.
LDF5E:  INC GenByte00           ;

LDF60:  LDA #$E0                ;TextBlock15, entry 0. To the east...
LDF62:  BNE DoEastWestDialog    ;Branch always.

XDiffDialog:
LDF64:  STA GenByte00           ;Store X distance from the castle.

LDF66:  LDA #$E1                ;TextBlock15, entry 1. To the west...

DoEastWestDialog:
LDF68:  LDX #$00                ;Zero out register. Never used.
LDF6A:  STX GenByte01           ;
LDF6C:  JSR DoMidDialog         ;($C7BD)Show east/west dialog.

LastLoveDialog:
LDF6F:  LDA #$BD                ;TextBlock12, entry 13.
LDF71:  JMP DoFinalDialog       ;($D242)I love thee...

EndItemChecks:
LDF74:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

CreateInvList:
LDF77:  LDX #$00                ;
LDF79:  LDA #$01                ;Start the buffer with the value #$01.
LDF7B:  STA DescBuf,X           ;

LDF7D:  INX                     ;Does the player have herbs?
LDF7E:  LDA InventoryHerbs      ;
LDF80:  BEQ +                   ;If not branch to check for keys.

LDF82:  LDA #$02                ;
LDF84:  STA DescBuf,X           ;Add herbs description pointer to buffer.
LDF86:  INX                     ;

LDF87:* LDA InventoryKeys       ;Does the player have keys?
LDF89:  BEQ +                   ;If not, branch.

LDF8B:  LDA #$03                ;
LDF8D:  STA DescBuf,X           ;Add keys description pointer to buffer.
LDF8F:  INX                     ;

LDF90:* LDY #$00                ;Set pointer to first inventory byte.

InvListLoop:
LDF92:  LDA InventoryPtr,Y      ;Get inventory byte.
LDF95:  AND #$0F                ;Extract lower inventory item.
LDF97:  BEQ +                   ;Branch to upper item if empty.
LDF99:  CLC                     ;
LDF9A:  ADC #$03                ;
LDF9C:  STA DescBuf,X           ;Add 3 to pointer value and add to description buffer.
LDF9E:  INX                     ;

LDF9F:* LDA InventoryPtr,Y      ;Get inventory byte.
LDFA2:  AND #$F0                ;
LDFA4:  BEQ +                   ;Branch to check next byte if empty.
LDFA6:  LSR                     ;
LDFA7:  LSR                     ;Move upper nibble to lower nibble.
LDFA8:  LSR                     ;
LDFA9:  LSR                     ;
LDFAA:  ADC #$03                ;Add 3 to pointer value and add to description buffer.
LDFAC:  STA DescBuf,X           ;

LDFAE:  INX                     ;Move to next slot in description buffer.
LDFAF:* INY                     ;Move to next slot in inventory.
LDFB0:  CPY #$04                ;Have 4 inventory bytes been processed?
LDFB2:  BNE InvListLoop         ;If not, branch to process more.

LDFB4:  LDA #$FF                ;
LDFB6:  STA DescBuf,X           ;End description buffer with #$FF.
LDFB8:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ChkDragonScale:
LDFB9:  LDA ModsnSpells         ;Is player alreay wearing the dragon scale?
LDFBB:  AND #F_DRGSCALE         ;
LDFBD:  BNE DrgScaleDialog      ;If so, branch.

LDFBF:  LDA ModsnSpells         ;
LDFC1:  ORA #F_DRGSCALE         ;Set dragon's scale flag.
LDFC3:  STA ModsnSpells         ;

LDFC5:  JSR DoDialogLoBlock     ;($C7CB)Player donned the scale of the dragon...
LDFC8:  .byte $3A               ;TextBlock4, entry 10.

LDFC9:  JMP LoadStats           ;($F050)Update player attributes.

DrgScaleDialog:
LDFCC:  JSR DoDialogLoBlock     ;($C7CB)Thou art already wearing the scale...
LDFCF:  .byte $3B               ;TextBlock4, entry 11.
LDFD0:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ChkRing:
LDFD1:  LDA ModsnSpells         ;
LDFD3:  AND #F_FTR_RING         ;Check if already wearing the fighter's ring.
LDFD5:  BNE AlreadyWearingRing  ;If so, branch to adjustment message.
LDFD7:  LDA ModsnSpells         ;Else set flag and indicate ring is worn.
LDFD9:  ORA #F_FTR_RING         ;
LDFDB:  STA ModsnSpells         ;

LDFDD:  JSR DoDialogLoBlock     ;($C7CB)Player put on the fighter's ring...
LDFE0:  .byte $3E               ;TextBlock4, entry 14.
LDFE1:  RTS                     ;

AlreadyWearingRing:
LDFE2:  JSR DoDialogLoBlock     ;($C7CB)Player adjusted the position of the ring...
LDFE5:  .byte $3F               ;TextBlock4, entry 15.
LDFE6:  RTS                     ;

WearCursedItem:
LDFE7:  LDA #$3A                ;Description index for the cursed belt.
LDFE9:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.
LDFEC:  BIT ModsnSpells         ;Is the player already wearing a cursed belt?
LDFEE:  BVS DoCursedDialog      ;If so, branch.

LDFF0:  LDA ModsnSpells         ;
LDFF2:  ORA #F_CRSD_BELT        ;Indicate player is cursed.
LDFF4:  STA ModsnSpells         ;

PlayerCursed:
LDFF6:  JSR DoDialogLoBlock     ;($C7CB)Player put on the item and was cursed...
LDFF9:  .byte $42               ;TextBlock5, entry 2.

PlayCursedMusic:
LDFFA:  LDA #MSC_CURSED         ;Cursed music.
LDFFC:  BRK                     ;
LDFFD:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LDFFF:  BRK                     ;Wait for the music clip to end.
LE000:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.
LE002:  RTS                     ;

DoCursedDialog:
LE003:  JSR DoDialogLoBlock     ;($C7CB)The item is squeezing thy body...
LE006:  .byte $43               ;TextBlock5, entry 3.

LE007:  JMP PlayCursedMusic     ;($DFFA)Player equipped a cursed object.

ChkDeathNecklace:
LE00A:  LDA #$3C                ;Description index for the death necklace.
LE00C:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE00F:  LDA ModsnSpells         ;Is the player wearing the death necklace.
LE011:  BMI DoCursedDialog      ;If so, branch to tell player they are cursed.

LE013:  LDA ModsnSpells         ;Set the bit indicating the player is wearing the death necklace.
LE015:  ORA #F_DTH_NECKLACE     ;
LE017:  STA ModsnSpells         ;
LE019:  BNE PlayerCursed        ;Branch always to tell player they are cursed.

;----------------------------------------------------------------------------------------------------

AddInvItem:
LE01B:  STA GenByte3E           ;Store a copy of the inventory item and zero out index.
LE01D:  LDX #$00                ;

AddInvLoop:
LE01F:  LDA InventorySlot12,X   ;Is the lower nibble inventory slot already occupied?
LE021:  AND #$0F                ;
LE023:  BNE ChkUpperInvNibble   ;If so, branch to check the upper nibble.

LE025:  LDA InventorySlot12,X   ;
LE027:  AND #$F0                ;
LE029:  ORA GenByte3E           ;Add new inventory item to lower nibble slot.
LE02B:  STA InventorySlot12,X   ;
LE02D:  RTS                     ;

ChkUpperInvNibble:
LE02E:  LDA InventorySlot12,X   ;Is the upper nibble inventory slot already occupied?
LE030:  AND #$F0                ;
LE032:  BNE ChkNextInvSlot      ;If so, branch to check the next inventory byte.

LE034:  ASL GenByte3E           ;
LE036:  ASL GenByte3E           ;Slot is open. Move item to upper nibble.
LE038:  ASL GenByte3E           ;
LE03A:  ASL GenByte3E           ;

LE03C:  LDA InventorySlot12,X   ;
LE03E:  AND #$0F                ;
LE040:  ORA GenByte3E           ;Add new inventory item to upper nibble slot.
LE042:  STA InventorySlot12,X   ;
LE044:  RTS                     ;

ChkNextInvSlot:
LE045:  INX                     ;Have all 4 bytes of inventory been checked(8 items)?
LE046:  CPX #INV_FULL           ;
LE048:  BNE AddInvLoop          ;If not, branch to check another byte.

LE04A:  RTS                     ;Inventory is full. Return.

;----------------------------------------------------------------------------------------------------

RemoveInvItem:
LE04B:  JSR CheckForInvItem     ;($E055)Get pointer to item in inventory.
LE04E:  AND InventoryPtr,Y      ;
LE051:  STA InventoryPtr,Y      ;Clear item from inventory slot.
LE054:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckForInvItem:
LE055:  LDY #$00                ;Zero out inventory index.
LE057:  STA GenByte3C           ;Keep a copy of item to find.

InvCheckLoop:
LE059:  LDA InventoryPtr,Y      ;Check lower inventory item.
LE05C:  AND #NBL_LOWER          ;
LE05E:  CMP GenByte3C           ;Is this the desired item?
LE060:  BNE +                   ;If not branch to check next slot.

LE062:  LDA #ITM_FOUND_LO       ;Item found in the low nibble.
LE064:  RTS                     ;

LE065:* LDA InventoryPtr,Y      ;Reload inventory byte.
LE068:  LSR                     ;
LE069:  LSR                     ;Shift upper item down to lower nibble.
LE06A:  LSR                     ;
LE06B:  LSR                     ;
LE06C:  CMP GenByte3C           ;Is this the desired item?
LE06E:  BNE +                   ;If not, branch to check if at end of inventory.

LE070:  LDA #ITM_FOUND_HI       ;Item found in the high nibble.
LE072:  RTS                     ;

LE073:* INY                     ;Has all the inventory been checked?
LE074:  CPY #$04                ;
LE076:  BNE InvCheckLoop        ;If not, branch to check next two slots.

LE078:  LDA #ITM_NOT_FOUND      ;The item was not in the inventory.
LE07A:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DiscardItem:
LE07B:  STA DialogTemp          ;Store dialog control byte.

LE07D:  JSR DoDialogLoBlock     ;($C7CB)If thou will take the item, thou must discard something...
LE080:  .byte $CC               ;TextBlock13, entry 12.

LE081:  JSR Dowindow            ;($C6F0)display on-screen window.
LE084:  .byte WND_YES_NO1       ;Yes/No window.

LE085:  BEQ PlayerDiscards      ;Branch if player chooses to discard an item.

PlayerNoDiscard:
LE087:  LDA DialogTemp          ;Player will not discard an item.
LE089:  CLC                     ;
LE08A:  ADC #$31                ;
LE08C:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE08F:  LDA #$CD                ;TextBlock13, entry 13.
LE091:  JMP DoFinalDialog       ;($D242)Thou hast given up thy item...

PlayerDiscards:
LE094:  JSR DoDialogLoBlock     ;($C7CB)What shall thou drop..
LE097:  .byte $CE               ;TextBlock13, entry 14.

LE098:  JSR CreateInvList       ;($DF77)Create inventory list in description buffer.

LE09B:  JSR Dowindow            ;($C6F0)display on-screen window.
LE09E:  .byte WND_INVTRY1       ;Player inventory window.

LE09F:  CMP #WND_ABORT          ;Did player abort the discard process?
LE0A1:  BEQ PlayerNoDiscard     ;If so, branch.

LE0A3:  TAX                     ;Prepare a check to see if player is trying to discard -->
LE0A4:  LDA DescBuf+1,X         ;an important item that cannot be discarded.
LE0A6:  LDY #$00                ;

DiscardChkLoop:
LE0A8:  CMP NonDiscardTbl,Y     ;Does the item match a non-discarable item?
LE0AB:  BNE NextDiscardChk      ;If not, branch to check next non-discardable item.

LE0AD:  JSR DoDialogLoBlock     ;($C7CB)That is much to important to throw away...
LE0B0:  .byte $D1               ;TextBlock14, entry 1.

LE0B1:  JMP PlayerDiscards      ;Jump so player can choose another item to discard.

NextDiscardChk:
LE0B4:  INY                     ;Has the item been checked against all non-discardable items?
LE0B5:  CPY #$09                ;
LE0B7:  BNE DiscardChkLoop      ;If not, branch to check against another item.

LE0B9:  CMP #INV_BELT           ;Is player trying to discard the cursed belt?
LE0BB:  BNE ChkDiscardNecklace  ;If not, branch to check if its the death necklace.

LE0BD:  BIT ModsnSpells         ;Is the player wearing the cursed belt?
LE0BF:  BVC ChkDiscardNecklace  ;If so, branch to check if player is discarding death necklace.

BodyCursedDialog:
LE0C1:  JSR DoDialogLoBlock     ;($C7CB)A curse is upon thy body...
LE0C4:  .byte $18               ;TextBlock2, entry 8.

LE0C5:  JMP PlayerDiscards      ;Jump so player can choose another item to discard.

ChkDiscardNecklace:
LE0C8:  LDA DescBuf+1,X         ;Is player trying to discard the death necklace?
LE0CA:  CMP #INV_NECKLACE       ;
LE0CC:  BNE +                   ;If not, branch.

LE0CE:  LDA ModsnSpells         ;Is the player wearing the death necklace?
LE0D0:  BMI BodyCursedDialog    ;If so, branch to display cursed dialog.

LE0D2:* LDA DescBuf+1,X         ;Save a copy of the description of the item.
LE0D4:  PHA                     ;

LE0D5:  CLC                     ;Add offset to find proper description of discarded item.
LE0D6:  ADC #$2E                ;
LE0D8:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE0DB:  JSR DoDialogLoBlock     ;($C7CB)Thou hast dropped thy item...
LE0DE:  .byte $CF               ;TextBlock13, entry 15.

LE0DF:  LDA DialogTemp          ;Add offset to find proper description of gained item.
LE0E1:  CLC                     ;
LE0E2:  ADC #$31                ;
LE0E4:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE0E7:  JSR DoDialogLoBlock     ;($C7CB)And obtained the item...
LE0EA:  .byte $D0               ;TextBlock14, entry 0

LE0EB:  PLA                     ;Add offset to get proper item to remove from inventory.
LE0EC:  SEC                     ;
LE0ED:  SBC #$03                ;
LE0EF:  JSR RemoveInvItem       ;($E04B)Remove item from inventory.

LE0F2:  LDA DescTemp            ;Prepare to add new item to inventory.
LE0F4:  JSR AddInvItem          ;($E01B)Add item to inventory.

LE0F7:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;The following table contains items that cannot be discarded by the player.

NonDiscardTbl:
LE0FA:  .byte INV_HERB, INV_KEY,    INV_FLUTE, INV_TOKEN, INV_LOVE
LE0FF:  .byte INV_HARP, INV_STONES, INV_STAFF, INV_DROP

;----------------------------------------------------------------------------------------------------

DoSearch:
LE103:  JSR Dowindow            ;($C6F0)display on-screen window.
LE106:  .byte WND_DIALOG        ;Dialog window.

LE107:  JSR DoDialogLoBlock     ;($C7CB)Player searched the ground all about...
LE10A:  .byte $D2               ;TextBlock14, entry 2.

LE10B:  LDA MapNumber           ;Is player on the overworld map?
LE10D:  CMP #MAP_OVERWORLD      ;
LE10F:  BNE NextSearch          ;If not, branch to do other searches.

LE111:  LDA CharXPos            ;
LE113:  CMP #$53                ;Is player in the proper X any Y position to find Erdrick's token?
LE115:  BNE NextSearch          ;
LE117:  LDA CharYPos            ;If not, branch to do other searches. Erdrick's token is the -->
LE119:  CMP #$71                ;only item to find on the overworld map.
LE11B:  BNE NextSearch          ;

LE11D:  LDA #ITM_ERDRICK_TKN    ;Check to see if the player already has Erdrick's token.

FoundItem:
LE11F:  STA DescTemp            ;Prepare to check for existing inventory item.
LE121:  JSR CheckForInvItem     ;($E055)Check inventory for item.

LE124:  CMP #ITM_NOT_FOUND      ;Does player already have Erdrick's token?
LE126:  BEQ ErdrickTknFound     ;If not, branch to try to add it to player's inventory.

ItemAlreadyFound:
LE128:  LDA #$D3                ;TextBlock14, entry 3.
LE12A:  JMP DoFinalDialog       ;($D242)But there found nothing...

ErdrickTknFound:
LE12D:  LDA DescTemp            ;Get offset to description byte for Erdrick's token.
LE12F:  CLC                     ;
LE130:  ADC #$31                ;
LE132:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE135:  JSR DoDialogLoBlock     ;($C7CB)Player discovered the item...
LE138:  .byte $D5               ;TextBlock14, entry 5.

LE139:  LDA DescTemp            ;Prepare to try to add item to inventory.
LE13B:  JSR AddInvItem          ;($E01B)Add item to inventory.

LE13E:  CPX #INV_FULL           ;Is player's inventory full?
LE140:  BEQ +                   ;If so, branch.

LE142:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

LE145:* LDA DescTemp            ;Prepare to tell player inventory is full.
LE147:  JMP DiscardItem         ;($E07B)Inventory full. Ask player to discard an item.

;----------------------------------------------------------------------------------------------------

NextSearch:
LE14A:  LDA MapNumber           ;Is player in the town of Kol?
LE14C:  CMP #MAP_KOL            ;
LE14E:  BNE SrchEdrckArmor      ;If not, branch.

LE150:  LDA CharXPos            ;
LE152:  CMP #$09                ;Is player in the proper location to find the fairy flute?
LE154:  BNE SrchEdrckArmor      ;
LE156:  LDA CharYPos            ;
LE158:  CMP #$06                ;If not, branch to move on.
LE15A:  BNE SrchEdrckArmor      ;

LE15C:  LDA #ITM_FRY_FLUTE      ;Indicate playe may find the fairy flute.
LE15E:  BNE FoundItem           ;branch always.

SrchEdrckArmor:
LE160:  LDA MapNumber           ;Is the player in Huksness?
LE162:  CMP #MAP_HAUKSNESS      ;
LE164:  BNE SrchPassage         ;If not, branch.

LE166:  LDA CharXPos            ;
LE168:  CMP #$12                ;Is player in the proper location to find Erdrick's armor?
LE16A:  BNE SrchPassage         ;
LE16C:  LDA CharYPos            ;
LE16E:  CMP #$0C                ;If not, branch to move on.
LE170:  BNE SrchPassage         ;

LE172:  LDA EqippedItems        ;Does player already have Erdrick's armor?
LE174:  AND #AR_ARMOR           ;
LE176:  CMP #AR_ERDK_ARMR       ;
LE178:  BEQ ItemAlreadyFound    ;If so, branch.

LE17A:  LDA EqippedItems        ;
LE17C:  ORA #AR_ERDK_ARMR       ;Equip player with Erdrick's armor.
LE17E:  STA EqippedItems        ;

LE180:  LDA #$28                ;Erdrick's armor description byte.
LE182:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE185:  LDA #$D5                ;TextBlock14, entry 5.
LE187:  JMP DoFinalDialog       ;($D242)Player discovered the item...

SrchPassage:
LE18A:  LDA MapNumber           ;Is player on the ground floor of the dragonlord's castle?
LE18C:  CMP #MAP_DLCSTL_GF      ;
LE18E:  BNE ChkSearchTrsr       ;If not, branch.

LE190:  LDA CharXPos            ;
LE192:  CMP #$0A                ;Is the player standing in the dragonlord's throne?
LE194:  BNE ChkSearchTrsr       ;
LE196:  LDA CharYPos            ;If so, branch to tell player wind is comming -->
LE198:  CMP #$03                ;from behind the throne.
LE19A:  BNE +                   ;Else branch.

LE19C:  LDA #$D6                ;TextBlock14, entry 6.
LE19E:  JMP DoFinalDialog       ;($D242)Feel the wind behind the throne...

LE1A1:* CMP #$01                ;Is player standing behind dragonlord's throne?
LE1A3:  BNE ChkSearchTrsr       ;If not, branch.

LE1A5:  LDA ModsnSpells         ;Has player already found the secret passage?
LE1A7:  AND #F_PSG_FOUND        ;
LE1A9:  BNE ChkSearchTrsr       ;If so, branch to move on.

LE1AB:  LDA ModsnSpells         ;
LE1AD:  ORA #F_PSG_FOUND        ;Indicate the player discvered the secret passage.
LE1AF:  STA ModsnSpells         ;

LE1B1:  LDA #$0F                ;Description byte for the secret passage.
LE1B3:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE1B6:  JSR DoDialogLoBlock     ;($C7CB)TextBlock14, entry 5.
LE1B9:  .byte $D5               ;Player discovered the item...

LE1BA:  LDA #$00                ;
LE1BC:  STA YPosFromCenter      ;Change the block the player is standing on to stairs down.
LE1BE:  STA XPosFromCenter      ;
LE1C0:  STA BlkRemoveFlgs       ;Remove no tiles from the block.
LE1C2:  JSR ModMapBlock         ;($AD66)Change block on map.
LE1C5:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ChkSearchTrsr:
LE1C8:  LDA CharXPos            ;
LE1CA:  STA XTarget             ;Get the block description of the block the player is standing on.
LE1CC:  LDA CharYPos            ;
LE1CE:  STA YTarget             ;
LE1D0:  JSR GetBlockID          ;($AC17)Get description of block.

LE1D3:  LDA TargetResults       ;Is player standing on a treasure chest?
LE1D5:  CMP #BLK_CHEST          ;
LE1D7:  BNE +                   ;If not, branch.

LE1D9:  LDA #$D4                ;TextBlock14, entry 4.
LE1DB:  JMP DoFinalDialog       ;($D242)There is a treasure box...

LE1DE:* LDA #$D3                ;TextBlock14, entry 3.
LE1E0:  JMP DoFinalDialog       ;($D242)But there found nothing...

;----------------------------------------------------------------------------------------------------

DoTake:
LE1E3:  JSR Dowindow            ;($C6F0)display on-screen window.
LE1E6:  .byte WND_DIALOG        ;Dialog window.

LE1E7:  LDA CharXPos            ;
LE1E9:  STA XTarget             ;Get the block description of the block the player is standing on.
LE1EB:  LDA CharYPos            ;
LE1ED:  STA YTarget             ;
LE1EF:  JSR GetBlockID          ;($AC17)Get description of block.

LE1F2:  LDA TargetResults       ;Is player standing on a treasure chest?
LE1F4:  CMP #BLK_CHEST          ;
LE1F6:  BEQ FoundTreasure       ;If so, branch.

NoTrsrChest:
LE1F8:  LDA #$D7                ;TextBlock14, entry 7.
LE1FA:  JMP DoFinalDialog       ;($D242)There is nothing to take here...

FoundTreasure:       
LE1FD:  BRK                     ;Copy treasure table into RAM.
LE1FE:  .byte $08, $17          ;($994F)CopyTrsrTbl, bank 1.

LE200:  LDY #$00                ;Treasure table starts at address $0320.

ChkTrsrTblLoop:
LE202:  LDA MapNumber           ;Does player map match current treasure chest map?
LE204:  CMP TrsrArray,Y         ;
LE207:  BNE NextTrsrChest       ;If not, branch to increment to next treasure chest.

LE209:  LDA CharXPos            ;Does player X position match treasure chest X position?
LE20B:  CMP TrsrArray+1,Y       ;
LE20E:  BNE NextTrsrChest       ;If not, branch to increment to next treasure chest.

LE210:  LDA CharYPos            ;Does player Y position match treasure chest X position?
LE212:  CMP TrsrArray+2,Y       ;
LE215:  BEQ ChkTrsrKey          ;If so, branch. Treasure chest found!

NextTrsrChest:
LE217:  INY                     ;
LE218:  INY                     ;Increment to next entry in treasure chest data array.
LE219:  INY                     ;
LE21A:  INY                     ;

LE21B:  CPY #$7C                ;Has the whole treasure chest data array been checked?
LE21D:  BNE ChkTrsrTblLoop      ;If not, branch to check the next entry.

LE21F:  BEQ NoTrsrChest         ;No treasure chest found at this location by the player.

;----------------------------------------------------------------------------------------------------

ChkTrsrKey:
LE221:  LDA TrsrArray+3,Y       ;Did player just find a treasure chest containing a key?
LE224:  STA DialogTemp          ;
LE226:  CMP #TRSR_KEY           ;
LE228:  BNE ChkTrsrHerb         ;If not, branch to check the next treasure type.

LE22A:  LDA InventoryKeys       ;Does player have the max of 5 keys?
LE22C:  CMP #$06                ;
LE22E:  BNE TrsrGetKey          ;If not, branch to increment keys in inventory.

GetTreasureChest1:
LE230:  JSR GetTreasure         ;($E39A)Check for valid treasure and get it.

LE233:  LDA #$DA                ;TextBlock14, entry 10.
LE235:  JMP DoFinalDialog       ;($D242)Unfortunately, it is empty...

TrsrGetKey:
LE238:  INC InventoryKeys       ;Player got a key. Increment keys in inventory.

GetTreasureChest2:
LE23A:  JSR GetTreasure         ;($E39A)Check for valid treasure and get it.

LE23D:  LDA #$D9                ;TextBlock14, entry 9.
LE23F:  JMP DoFinalDialog       ;($D242)Fortune smiles upon thee...

;----------------------------------------------------------------------------------------------------

ChkTrsrHerb:
LE242:  CMP #TRSR_HERB          ;Did player just find a treasure chest containing an herb?
LE244:  BNE ChkTrsrNecklace     ;If not, branch to check the next treasure type.

LE246:  LDA InventoryHerbs      ;Does player have the max of 5 herbs?
LE248:  CMP #$06
LE24A:  BEQ GetTreasureChest1   ;If so, branch to get treasure and exit without incrementing herbs.

LE24C:  INC InventoryHerbs      ;Increment player's herb inventory.
LE24E:  BNE GetTreasureChest2   ;branch always.

;----------------------------------------------------------------------------------------------------

ChkTrsrNecklace:
LE250:  CMP #TRSR_NCK           ;Did player just find a treasure chest containing the death necklace?
LE252:  BNE ChkTrsrErdSword     ;If not, branch to check the next treasure type.

LE254:  LDA PlayerFlags         ;Did the player already find the death necklace?
LE256:  AND #F_DTH_NCK_FOUND    ;
LE258:  BNE GetDthNeckGold      ;If so, branch to get gold instead.

LE25A:  JSR UpdateRandNum       ;($C55B)Get random number.
LE25D:  LDA RandNumUB           ;If lower 5 bits are 0, player will receive the-->
LE25F:  AND #$1F                ;death necklace(1 in 32 chance).
LE261:  BNE GetDthNeckGold      ;($E288)Lower 5 zeros? if not, branch to get gold instead.

LE263:  LDA PlayerFlags         ;
LE265:  ORA #F_DTH_NCK_FOUND    ;Indicate player has found the death necklace.
LE267:  STA PlayerFlags         ;

;----------------------------------------------------------------------------------------------------

SetTrsrDescByte:
LE269:  JSR GetTreasure         ;($E39A)Check for valid treasure and get it.
LE26C:  LDA DescTemp            ;
LE26E:  SEC                     ;Set the proper index to the description byte for the item.
LE26F:  SBC #$03                ;
LE271:  STA DescTemp            ;

LE273:  JSR DoDialogLoBlock     ;($C7CB)Fortune smiles upon thee. Thou hast found the item...
LE276:  .byte $D9               ;TextBlock14, entry 9.

LE277:  LDA DescTemp            ;Add the item to the player's inventory.
LE279:  JSR AddInvItem          ;($E01B)Add item to inventory.

LE27C:  CPX #INV_FULL           ;Is the player's inventory full?
LE27E:  BEQ TrsrInvFull         ;If so, branch to give player the option to drop an item.

LE280:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

TrsrInvFull:
LE283:  LDA DescTemp            ;Get index to item player is trying to pick up.
LE285:  JMP DiscardItem         ;($E07B)Inventory full. Ask player to discard an item.

;----------------------------------------------------------------------------------------------------

GetDthNeckGold:
LE288:  LDA #$1F                ;Up to 31 extra gold randomly added.
LE28A:  STA RndGoldBits         ;

LE28C:  LDA #$64                ;
LE28E:  STA TrsrGoldLB          ;100 base gold for this treasure.
LE290:  LDA #$00                ;
LE292:  STA TrsrGoldUB          ;

LE294:  JMP GetTrsrGold         ;($E365)Calculate treasure gold received.

;----------------------------------------------------------------------------------------------------

ChkTrsrErdSword:
LE297:  CMP #TRSR_ERSD          ;Did player just find a treasure chest containing Erdrick's sword?
LE299:  BNE ChkTrsrHarp         ;If not, branch to check the next treasure type.

LE29B:  LDA EqippedItems        ;Does the player already have Erdrick's sword?
LE29D:  AND #WP_WEAPONS         ;
LE29F:  CMP #WP_ERDK_SWRD       ;
LE2A1:  BNE +                   ;If not, branch.

GetTreasureChest3:
LE2A3:  JMP GetTreasureChest1   ;The treasure chest is empty.

LE2A6:* LDA EqippedItems        ;Indicate the player is equipped with Erdrick's sword.
LE2A8:  ORA #WP_ERDK_SWRD       ;
LE2AA:  STA EqippedItems        ;
LE2AC:  JSR GetTreasure         ;($E39A)Check for valid treasure and get it.

LE2AF:  LDA #$21                ;Description byte for Erdrick's sword.
LE2B1:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LE2B4:  LDA #$D9                ;TextBlock14, entry 9.
LE2B6:  JMP DoFinalDialog       ;($D242)Fortune smiles upon thee...

;----------------------------------------------------------------------------------------------------

ChkTrsrHarp:
LE2B9:  CMP #TRSR_HARP          ;Did player just get chest with the harp, staff or rainbow drop?
LE2BB:  BNE ChkTrsrStones       ;If not, branch to check the next treasure type.

LE2BD:  LDA #ITM_SLVR_HARP      ;Check if player has the silver harp.
LE2BF:  JSR CheckForInvItem     ;($E055)Check if item is already in inventory.

LE2C2:  CMP #ITM_NOT_FOUND      ;Does player have the silver harp?
LE2C4:  BNE GetTreasureChest3   ;if so, branch got get empty treasure chest.

LE2C6:  LDA #ITM_STFF_RAIN      ;Check if the player has the staff of rain.
LE2C8:  JSR CheckForInvItem     ;($E055)Check if item is already in inventory.

LE2CB:  CMP #ITM_NOT_FOUND      ;Does the player have the staff of rain?
LE2CD:  BNE GetTreasureChest3   ;if so, branch got get empty treasure chest.

ChkRnbwDrop:
LE2CF:  LDA #ITM_RNBW_DROP      ;Check if the player has the rainbow drop.
LE2D1:  JSR CheckForInvItem     ;($E055)Check if item is already in inventory.

LE2D4:  CMP #ITM_NOT_FOUND      ;Does the player have the rainbow drop?
LE2D6:  BNE GetTreasureChest3   ;if so, branch got get empty treasure chest.

LE2D8:  JMP SetTrsrDescByte     ;Display a message to player about getting the silver harp.

;----------------------------------------------------------------------------------------------------

ChkTrsrStones:
LE2DB:  CMP #TRSR_SUN           ;Did player just get chest with the stones of sunlight?
LE2DD:  BNE ChkTrsrNonGold      ;If not, branch to check the next treasure type.

LE2DF:  LDA #ITM_STNS_SNLGHT    ;Check if player already has the stones of sunlight.
LE2E1:  JSR CheckForInvItem     ;($E055)Check if item is already in inventory.

LE2E4:  CMP #ITM_NOT_FOUND      ;Does the player have the stones of sunlight?
LE2E6:  BNE GetTreasureChest3   ;if so, branch got get empty treasure chest.

LE2E8:  BEQ ChkRnbwDrop         ;Branch always to check for the rainbow drop.

;----------------------------------------------------------------------------------------------------

ChkTrsrNonGold:
LE2EA:  CMP #TRSR_ERSD          ;Did player get a non-gold treasure not already checked for?
LE2EC:  BCS ChkTrsrGold1        ;If not, branch to check for a gold based treasure.

LE2EE:  JMP SetTrsrDescByte     ;Branch always to get the treasure and inform the player.

;----------------------------------------------------------------------------------------------------

ChkTrsrGold1:
LE2F1:  CMP #TRSR_GLD1          ;Did player just get a treasure chest with gold 1 treasure?
LE2F3:  BNE ChkTrsrGold2        ;If not, branch to check for gold 2 treasure.

LE2F5:  LDA #$0F                ;Max 15 gold randomly added to treasure.
LE2F7:  STA RndGoldBits         ;

LE2F9:  LDA #$05                ;
LE2FB:  STA TrsrGoldLB          ;Base gold amount of treasure is 5.
LE2FD:  LDA #$00                ;
LE2FF:  STA TrsrGoldUB          ;

LE301:  BEQ GetTrsrGold         ;($E365)Calculate treasure gold received.

;----------------------------------------------------------------------------------------------------

ChkTrsrGold2:
LE303:  CMP #TRSR_GLD2          ;Did player just get a treasure chest with gold 2 treasure?
LE305:  BNE ChkTrsrGold3        ;If not, branch to check for gold 3 treasure.

LE307:  LDA #$07                ;Max 7 gold randomly added to treasure.
LE309:  STA RndGoldBits         ;

LE30B:  LDA #$06                ;
LE30D:  STA TrsrGoldLB          ;Base gold amount of treasure is 6.
LE30F:  LDA #$00                ;
LE311:  STA TrsrGoldUB          ;

LE313:  BEQ GetTrsrGold         ;($E365)Calculate treasure gold received.

;----------------------------------------------------------------------------------------------------

ChkTrsrGold3:
LE315:  CMP #TRSR_GLD3          ;Did player just get a treasure chest with gold 3 treasure?
LE317:  BNE ChkTrsrGold4        ;If not, branch to check for gold 4 treasure.

LE319:  LDA #$07                ;Max 7 gold randomly added to treasure.
LE31B:  STA RndGoldBits         ;

LE31D:  LDA #$0A                ;
LE31F:  STA TrsrGoldLB          ;Base gold amount of treasure is 10.
LE321:  LDA #$00                ;
LE323:  STA TrsrGoldUB          ;

LE325:  BEQ GetTrsrGold         ;($E365)Calculate treasure gold received.

;----------------------------------------------------------------------------------------------------

ChkTrsrGold4:
LE327:  CMP #TRSR_GLD4          ;Did player just get a treasure chest with gold 4 treasure?
LE329:  BNE ChkTrsrGold5        ;If not, branch to check for gold 5 treasure.

LE32B:  LDA #$FF                ;Max 255 gold randomly added to treasure.
LE32D:  STA RndGoldBits         ;

LE32F:  LDA #$F4                ;
LE331:  STA TrsrGoldLB          ;Base gold amount of treasure is 500.
LE333:  LDA #$01                ;
LE335:  STA TrsrGoldUB          ;

LE337:  BNE GetTrsrGold         ;($E365)Calculate treasure gold received.

;----------------------------------------------------------------------------------------------------

ChkTrsrGold5:
LE339:  CMP #TRSR_GLD5          ;Did player just get a treasure chest with gold 5 treasure?
LE33B:  BNE ChkTrsrErdTablet    ;If not, branch to get Erdrick's tablet(only remianing treasure).

LE33D:  LDA #$00                ;No random amount added to treasure.
LE33F:  STA RndGoldBits         ;

LE341:  STA TrsrGoldUB          ;
LE343:  LDA #$78                ;Base gold amount of treasure is 120.
LE345:  STA TrsrGoldLB          ;

LE347:  BNE GetTrsrGold         ;($E365)Calculate treasure gold received.

;----------------------------------------------------------------------------------------------------

ChkTrsrErdTablet:
LE349:  JSR GetTreasure         ;($E39A)Check for valid treasure and get it.

LE34C:  LDX #$00                ;Only thing left is Erdrick's tablet.
LE34E:* LDA ErdrkTabletTbl,X    ;
LE351:  STA DescBuf,X           ;Get description bytes from table below.
LE353:  INX                     ;
LE354:  CPX #$02                ;Got second byte?
LE356:  BNE -                   ;If not, branch to get it.

LE358:  JSR DoDialogLoBlock     ;($C7CB)TextBlock14, entry 9.
LE35B:  .byte $D9               ;Fortune smiles upon thee. Thou hast found the item...

LE35C:  JSR DoDialogHiBlock     ;($C7C5)TextBlock17, entry 3.
LE35F:  .byte $03               ;The tablet reads as follows...

LE360:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

ErdrkTabletTbl:
LE363:  .byte $19, $FA          ;Description index for Erdrick's tablet.

;----------------------------------------------------------------------------------------------------

GetTrsrGold:
LE365:  JSR UpdateRandNum       ;($C55B)Get random number.
LE368:  LDA RandNumUB           ;
LE36A:  AND RndGoldBits         ;Get random anount of gold to add to treasure gold.

LE36C:  CLC                     ;
LE36D:  ADC TrsrGoldLB          ;
LE36F:  STA TrsrGoldLB          ;Add the random amount of gold to the treasure gold.
LE371:  LDA TrsrGoldUB          ;
LE373:  ADC #$00                ;
LE375:  STA TrsrGoldUB          ;
LE377:  JSR GetTreasure         ;($E39A)Check for valid treasure and get it.

LE37A:  LDA GoldLB              ;
LE37C:  CLC                     ;
LE37D:  ADC TrsrGoldLB          ;
LE37F:  STA GoldLB              ;Add treasure gold to player's gold.
LE381:  LDA GoldUB              ;
LE383:  ADC TrsrGoldUB          ;
LE385:  STA GoldUB              ;Did player's gold overflow?
LE387:  BCC GainGoldDialog      ;If not, branch to display message and exit.

LE389:  LDA #$FF                ;
LE38B:  STA GoldLB              ;Set player's gold to max(65535).
LE38D:  STA GoldUB              ;

GainGoldDialog:
LE38F:  JSR DoDialogLoBlock     ;($C7CB)Of gold thou hast gained...
LE392:  .byte $D8               ;TextBlock14, entry 8.

LE393:  JSR Dowindow            ;($C6F0)display on-screen window.
LE396:  .byte WND_POPUP         ;Pop-up window.

LE397:  JMP ResumeGamePlay      ;($CFD9)Give control back to player.

;----------------------------------------------------------------------------------------------------

GetTreasure:
LE39A:  LDX #$00                ;Start at beginning of treasure table.

ChkTrsrLoop:
LE39C:  LDA TrsrXPos,X          ;Is treasure slot empty?
LE39F:  ORA TrsrYPos,X          ;
LE3A2:  BEQ TakeTreasure        ;If so, branch to take treasure.

LE3A4:  INX                     ;Move to next spot in treasure table to see if its empty.
LE3A5:  INX                     ;
LE3A6:  CPX #$10                ;At the end of the table?
LE3A8:  BNE ChkTrsrLoop         ;If not, branch to check next entry.
LE3AA:  RTS                     ;Treasure table is full.  Can't get treasure.

TakeTreasure:
LE3AB:  LDA CharXPos            ;
LE3AD:  STA TrsrXPos,X          ;Store player's position in treasure table.
LE3B0:  LDA CharYPos            ;This is how the game keeps track of taken treasure.
LE3B2:  STA TrsrYPos,X          ;

LE3B5:  LDA #$00                ;
LE3B7:  STA XPosFromCenter      ;Remove treasure chest block directly under player.
LE3B9:  STA YPosFromCenter      ;
LE3BB:  STA BlkRemoveFlgs       ;Remove all 4 tiles of treasure chest.

LE3BD:  LDA #SFX_TRSR_CHEST     ;Treasure chest SFX.
LE3BF:  BRK                     ;
LE3C0:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE3C2:  JSR ModMapBlock         ;($AD66)Change block on map.

LE3C5:  LDA DescTemp            ;Load description byte.
LE3C7:  CLC                     ;Add offset to locate item descriptions.
LE3C8:  ADC #$2E                ;
LE3CA:  JMP GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

;----------------------------------------------------------------------------------------------------

LoadCombatBckgrnd:
LE3CD:  LDA EnNumber            ;
LE3CF:  CMP #EN_DRAGONLORD2     ;Is this the final boss?
LE3D1:  BNE +                   ;If so, skip drawing the background.
LE3D3:  RTS                     ;

LE3D4:* LDX #$00                ;
LE3D6:  STX BlockClear          ;Initialize variables.
LE3D8:  STX BlockCounter        ;

LE3DA:  LDA #$0A                ;
LE3DC:  STA GenPtr3CLB          ;Buffer combat background graphics in 
LE3DE:  LDA #$05                ;RAM starting at $050A.
LE3E0:  STA GenPtr3CUB          ;

BGGFXLoadLoop:
LE3E2:  LDY #$00                ;Keeps track of current location in row.

BGLoadRow:
LE3E4:  LDA MapNumber           ;Is the combat happening on the overworld?
LE3E6:  CMP #MAP_OVERWORLD      ;
LE3E8:  BEQ +                   ;If so, branch to load outside graphics.

LE3EA:  LDA #TL_BLANK_TILE1     ;Not on overworld, load black background.
LE3EC:  BNE ++                  ;

LE3EE:* LDA CombatBckgndGFX,X   ;Get background data and load it into RAM.
LE3F1:* STA (GenPtr3C),Y        ;

LE3F3:  INX                     ;Increment to next values in data table and RAM.
LE3F4:  INY                     ;

LE3F5:  CPY #$0E                ;Have 14 tiles been loaded?
LE3F7:  BNE BGLoadRow           ;If not, branch to keep loading row.

LE3F9:  LDA GenPtr3CLB          ;
LE3FB:  CLC                     ;
LE3FC:  ADC #$20                ;
LE3FE:  STA GenPtr3CLB          ;Move to beginning of the next row.
LE400:  LDA GenPtr3CUB          ;
LE402:  ADC #$00                ;
LE404:  STA GenPtr3CUB          ;

LE406:  CPX #$C4                ;Have 194 tiles been loaded (14*14)?
LE408:  BNE BGGFXLoadLoop       ;If not, branch to load more.

LE40A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE40D:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

BGGFXScreenLoop:
LE410:  LDX BlockCounter        ;Use the block counter as the index into the table.

LE412:  LDA CmbtBGPlcmntTbl,X   ;
LE415:  LSR                     ;Get byte from table and extract-->
LE416:  LSR                     ;x displacement (upper nibble).
LE417:  LSR                     ;
LE418:  LSR                     ;

LE419:  CLC                     ;Need to convert from combat background coords-->
LE41A:  ADC #$FA                ;to screen tile coords.  The formula is:
LE41C:  STA XPosFromCenter      ;x = combatBGX + #$0A.
LE41E:  CLC                     ;
LE41F:  ADC #$10                ;Here they are basing off the center so they actually use:
LE421:  STA XPosFromLeft        ;x = combatBGX + #$10 - #$6.

LE423:  LDA CmbtBGPlcmntTbl,X   ;Get same byte from table and extract-->
LE426:  AND #$0F                ;y displacement (lower nibble).

LE428:  CLC                     ;The y position needs to be converted as well.-->
LE429:  ADC #$FA                ;the formula is:
LE42B:  STA YPosFromCenter      ;y = combatBGY + #$09.
LE42D:  CLC                     ;
LE42E:  ADC #$0E                ;Here they are basing off the center so they actually use:
LE430:  STA YPosFromTop         ;y = combatBGY + #$0E - #$6.

LE432:  JSR CalcRAMBufAddr      ;($C59E)Calculate RAM buffer address for block placement.

LE435:  LDA PPUBufPtrLB         ;
LE437:  STA BlockAddrLB         ;Save a copy of the block address.
LE439:  LDA PPUBufPtrUB         ;
LE43B:  STA BlockAddrUB         ;

LE43D:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE440:  JSR AddBlocksToScreen   ;($C707)Calculate 4x4 tile addresses and move data to PPU.

LE443:  INC BlockCounter        ;Have 49 blocks been placed?
LE445:  LDA BlockCounter        ;If not, loop to load more.
LE447:  CMP #$31                ;
LE449:  BNE BGGFXScreenLoop     ;
LE44B:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE44E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

LoadEnemyGFX:
LE44F:  LDA EnNumber            ;Is this the final boss?
LE451:  CMP #EN_DRAGONLORD2     ;
LE453:  BNE +                   ;If not branch to load regular enemy graphics.

LE455:  LDA #$00                ;Clear enemy number.
LE457:  STA EnNumber            ;

LE459:  BRK                     ;Load the final boss!
LE45A:  .byte $02, $07          ;($BABD)DoEndFight, bank 0.
LE45C:  RTS                     ;

LE45D:* LDA #$00                ;
LE45F:  STA RAMTrgtPtrLB        ;
LE461:  STA CopyCounterUB       ;Copy enemy sprite data into $0300 to $03A0. -->
LE463:  LDA #$03                ;Always copy 160 bytes(53 sprites worth of data). -->
LE465:  STA RAMTrgtPtrUB        ;Not all the data copied may be used.
LE467:  LDA #$A0                ;
LE469:  STA CopyCounterLB       ;

LE46B:  BRK                     ;Copy ROM table into RAM.
LE46C:  .byte $0A, $17          ;($9981)CopyROMToRAM, bank 1.

LE46E:  LDX #$10                ;Index to store enemy sprites. Starts after player sprites.

LE470:  LDY #$00                ;
LE472:  STY EnSpritePtrLB       ;Copy enemy sprite data from base address $0300.
LE474:  LDA #$03                ;
LE476:  STA EnSpritePtrUB       ;

EnSpriteLoop:
LE478:  LDA (EnSpritePtr),Y     ;Null terminated sprite data. Has end been reached?
LE47A:  BEQ EnLoadPalData       ;If so, branch to stop loading sprite data.

LE47C:  STA SpriteRAM+1,X       ;Store tile pattern for sprite.

LE47F:  INY                     ;Move to next sprite byte.

LE480:  LDA (EnSpritePtr),Y     ;Get the 6 bits of Y position data for the enemy sprite.
LE482:  AND #$3F                ;

LE484:  CLC                     ;
LE485:  ADC #$44                ;Move the sprite down to the central region of the screen.
LE487:  STA SpriteRAM,X         ;

LE48A:  LDA (EnSpritePtr),Y     ;
LE48C:  AND #$C0                ;Get the horizontal and vertical mirrioring bits for the sprite.
LE48E:  STA EnSprtAttribDat     ;

LE490:  INY                     ;Move to next sprite byte.

LE491:  LDA (EnSpritePtr),Y     ;
LE493:  AND #$03                ;Get the palette data for the sprite.
LE495:  ORA EnSprtAttribDat     ;           
LE497:  STA EnSprtAttribDat     ;

LE499:  LDA (EnSpritePtr),Y     ;
LE49B:  LSR                     ;Get the X position data of the prite.
LE49C:  LSR                     ;

LE49D:  SEC                     ;Move sprite 28 pixels left. Not sure -->
LE49E:  SBC #$1C                ;why data was formatted this way.
LE4A0:  STA EnSprtXPos          ;

LE4A2:  LDA IsEnMirrored        ;Is the enemy mirrored?
LE4A4:  BEQ SetEnSprtAttrib     ;If not, branch to skip inverting the X position of the sprite.

LE4A6:  LDA EnSprtXPos          ;
LE4A8:  EOR #$FF                ;Enemy is mirrored. 2's compliment the X position of the sprite.
LE4AA:  STA EnSprtXPos          ;
LE4AC:  INC EnSprtXPos          ;

LE4AE:  LDA EnSprtAttribDat     ;Since the enemy is mirrored in the X direction, the -->
LE4B0:  EOR #$40                ;horizontal mirroring of the sprite needs to be inverted.
LE4B2:  STA EnSprtAttribDat     ;

SetEnSprtAttrib:
LE4B4:  LDA EnSprtAttribDat     ;Store the attribute data for the enemy sprite.
LE4B6:  STA SpriteRAM+2,X       ;

LE4B9:  LDA EnSprtXPos          ;
LE4BB:  CLC                     ;Move the sprite to the central region of the screen.
LE4BC:  ADC #$84                ;
LE4BE:  STA SpriteRAM+3,X       ;

LE4C1:  INX                     ;
LE4C2:  INX                     ;Move to next sprite in sprite RAM.
LE4C3:  INX                     ;Each sprite is 4 bytes.
LE4C4:  INX                     ;

LE4C5:  INY                     ;More sprite data to load?
LE4C6:  BNE EnSpriteLoop        ;If so, branch to do another enemy sprite.

EnLoadPalData:
LE4C8:  JSR LoadEnPalette       ;($EEFD)Load enemy palette data.
LE4CB:  JSR Bank3ToNT1          ;($FCB8)Load data into nametable 1.

LE4CE:  LDA #$00                ;
LE4D0:  STA EnSprtXPos          ;Clear out sprite working variables. -->
LE4D2:  LDA #$30                ;Doesn't appear to have an effect.
LE4D4:  STA EnSprtAttribDat     ;

LE4D6:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.
LE4D9:  JSR PalFadeIn           ;($C529)Fade in both background and sprite palettes.
LE4DC:  JMP PalFadeIn           ;($C529)Fade in both background and sprite palettes.

;----------------------------------------------------------------------------------------------------

InitFight:
LE4DF:  STA EnNumber            ;Prepare to point to enemy data table entry.
LE4E1:  STA EnDatPtr            ;

LE4E3:  CMP #EN_DRAGONLORD2     ;Is this the final boss?
LE4E5:  BNE +                   ;If not, branch to play enter fight music.

LE4E7:  LDA #MSC_END_BOSS       ;End boss music.
LE4E9:  BNE LoadFightMusic      ;Branch always.

LE4EB:* LDA #MSC_ENTR_FGHT      ;Enter fight music.

LoadFightMusic:
LE4ED:  BRK                     ;Start the fight music.
LE4EE:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE4F0:  LDA #$00                ;
LE4F2:  STA EnDatPtrUB          ;
LE4F4:  ASL EnDatPtrLB          ;
LE4F6:  ROL EnDatPtrUB          ;
LE4F8:  ASL EnDatPtrLB          ;Enemy data pointer * 16.
LE4FA:  ROL EnDatPtrUB          ;Each entry in the table is 16 bytes.
LE4FC:  ASL EnDatPtrLB          ;
LE4FE:  ROL EnDatPtrUB          ;
LE500:  ASL EnDatPtrLB          ;
LE502:  ROL EnDatPtrUB          ;

LE504:  LDA EnNumber            ;Save a copy of the enemy number.
LE506:  PHA                     ;

LE507:  LDA #$00                ;Zero out enemy number.
LE509:  STA EnNumber            ;

LE50B:  BRK                     ;
LE50C:  .byte $0C, $17          ;($9961)LoadEnemyStats, bank 1.

LE50E:  PLA                     ;
LE50F:  STA EnNumber            ;
LE511:  CMP #EN_RDRAGON         ;
LE513:  BNE +                   ;
LE515:  LDA #$46                ;Load additional description bytes for the red dragon.-->
LE517:  STA Stack               ;These bytes do not appear to be used for any enemy.
LE51A:  LDA #$FA                ;
LE51C:  STA Stack+1             ;
LE51F:  BNE ContInitFight       ;
LE521:* LDA #$FA                ;
LE523:  STA Stack               ;

ContInitFight:
LE526:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.

LE529:  LDA PlayerFlags         ;
LE52B:  AND #$0F                ;Clear combat status flags.
LE52D:  STA PlayerFlags         ;

LE52F:  LDA EnNumber            ;
LE531:  PHA                     ;Save the enemy number on the stack and-->
LE532:  LDA #$00                ;then clear the EnNumber variable.
LE534:  STA EnNumber            ;

LE536:  JSR LoadStats           ;($F050)Update player attributes.

LE539:  PLA                     ;Restore enemy number data.
LE53A:  STA EnNumber            ;

LE53C:  ASL                     ;*2 Pointer to enemy sprite data is 2 bytes.
LE53D:  TAY                     ;Use Y as index into EnSpritesPtrTbl.

LE53E:  LDX #$22                ;Save base address for EnSpritesPtrTbl in GenPtr22.

LE540:  BRK                     ;Table of pointers to enemy sprites.
LE541:  .byte $8B, $17          ;($99E4)EnSpritesPtrTbl, bank 1.

LE543:  LDA #PRG_BANK_1         ;Get lower byte of sprite data pointer-->
LE545:  JSR GetBankDataByte     ;($FD1C)from PRG bank 1 and store in A.

LE548:  CLC                     ;Add with carry does nothing.
LE549:  ADC #$00                ;
LE54B:  STA ROMSrcPtrLB         ;Store lower byte of enemy sprite data pointer.

LE54D:  PHP                     ;Carry should always be clear.

LE54E:  INY                     ;Increment to next byte in EnSpritesPtrTbl
LE54F:  LDA #PRG_BANK_1         ;Get upper byte of sprite data pointer-->
LE551:  JSR GetBankDataByte     ;($FD1C)from PRG bank 1 and store in A.

LE554:  TAY                     ;Save a copy of upper byte to check enemy mirroring later.

LE555:  AND #$7F                ;
LE557:  PLP                     ;Set MSB of upper byte if not already set.
LE558:  ADC #$80                ;Carry should always be clear.
LE55A:  STA ROMSrcPtrUB         ;

LE55C:  TYA                     ;Store enemy mirroring bit on stack.
LE55D:  PHA                     ;

LE55E:  LDA ROMSrcPtrLB         ;
LE560:  STA NotUsed26           ;Save a copy of the ROM location of eney sprite data, lower byte.
LE562:  PHA                     ;

LE563:  LDA ROMSrcPtrUB         ;
LE565:  STA NotUsed27           ;Save a copy of the ROM location of eney sprite data, upper byte.
LE567:  PHA                     ;

LE568:  JSR LoadCombatBckgrnd   ;($E3CD)Show combat scene background.

LE56B:  PLA                     ;Restore ROM location of eney sprite data, upper byte.
LE56C:  STA ROMSrcPtrUB         ;

LE56E:  PLA                     ;Restore ROM location of eney sprite data, lower byte.
LE56F:  STA ROMSrcPtrLB         ;

LE571:  PLA                     ;
LE572:  AND #$80                ;Get byte containing mirrored bit and keep only mirroring bit.
LE574:  STA IsEnMirrored        ;

LE576:  LDA NPCUpdateCntr       ;
LE578:  ORA #$80                ;This appears to have no effect and is cleared when fight ends.
LE57A:  STA NPCUpdateCntr       ;

LE57C:  JSR LoadEnemyGFX        ;($E44F)Display enemy sprites.

LE57F:  JSR Dowindow            ;($C6F0)display on-screen window.
LE582:  .byte WND_DIALOG        ;Dialog window.

LE583:  LDA EnNumber
LE585:  CMP #EN_DRAGONLORD2
LE587:  BNE $E592

LE589:  JSR DoDialogHiBlock     ;($C7C5)The dragonlord reveals his true self...
LE58C:  .byte $19               ;TextBlock18, entry 9.

LE58D:  LDA EnBaseHP
LE590:  BNE $E5BA

LE592:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE595:  JSR DoDialogLoBlock     ;($C7CB)An enemy draws near...
LE598:  .byte $E2               ;TextBlock15, entry 2.

ModEnHitPoints:
LE599:  LDA EnBaseHP
LE59C:  STA MultNum2LB
LE59E:  JSR UpdateRandNum       ;($C55B)Get random number.

LE5A1:  LDA RandNumUB
LE5A3:  STA MultNum1LB
LE5A5:  LDA #$00
LE5A7:  STA MultNum1UB
LE5A9:  STA MultNum2UB
LE5AB:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.

LE5AE:  LDA MultRsltUB
LE5B0:  LSR
LE5B1:  LSR
LE5B2:  STA MultRsltLB
LE5B4:  LDA EnBaseHP
LE5B7:  SEC
LE5B8:  SBC MultRsltLB

LE5BA:  STA EnCurntHP
LE5BC:  JSR CheckEnRun          ;($EFB7)Check if enemy is going to run away.
LE5BF:  JSR $EEC0

LE5C2:  BCS StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE5C4:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE5C7:  JSR DoDialogLoBlock     ;($C7CB)The enemy attacked before player ready...
LE5CA:  .byte $E4               ;TextBlock15, entry 4.

LE5CB:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

;----------------------------------------------------------------------------------------------------

StartPlayerTurn:
LE5CE:  JSR Dowindow            ;($C6F0)display on-screen window.
LE5D1:  .byte WND_POPUP         ;Pop-up window.

LE5D2:  LDA PlayerFlags
LE5D4:  BPL $E5EF
LE5D6:  JSR UpdateRandNum       ;($C55B)Get random number.
LE5D9:  LDA RandNumUB
LE5DB:  LSR
LE5DC:  BCS PlayerAwakes

PlayerAsleepDialog:
LE5DE:  JSR DoDialogHiBlock     ;($C7C5)Thou art still asleep...
LE5E1:  .byte $07               ;TextBlock17, entry 7.

LE5E2:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

PlayerAwakes:
LE5E5:  LDA PlayerFlags         ;
LE5E7:  AND #$7F                ;Clear player sleeping flag.
LE5E9:  STA PlayerFlags         ;

LE5EB:  JSR DoDialogHiBlock     ;($C7C5)Player awakes...
LE5EE:  .byte $08               ;TextBlock17, entry 8.

LE5EF:  JSR DoDialogLoBlock     ;($C7CB)Command?...
LE5F2:  .byte $E8               ;TextBlock15, entry 8.

LE5F3:  JSR Dowindow            ;($C6F0)display on-screen window.
LE5F6:  .byte WND_CMD_CMB       ;Combat command window.

LE5F7:  LDA SpellToCast
LE5F9:  BEQ $E5FE
LE5FB:  JMP $E6B6

LE5FE:  LDA #WND_CMD_CMB
LE600:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LE603:  LDA #SFX_ATTACK         ;Player attack SFX.
LE605:  BRK                     ;
LE606:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE608:  JSR DoDialogLoBlock     ;($C7CB)
LE60B:  .byte $E5 

LE60C:  LDA $CC
LE60E:  STA $42
LE610:  LDA EnBaseDef
LE613:  STA $43
LE615:  LDA EnNumber
LE617:  CMP #EN_DRAGONLORD1
LE619:  BEQ $E651
LE61B:  CMP #EN_DRAGONLORD2
LE61D:  BEQ $E651
LE61F:  JSR UpdateRandNum       ;($C55B)Get random number.
LE622:  LDA RandNumUB
LE624:  AND #$1F
LE626:  BNE $E651

LE628:  LDA #SFX_EXCLNT_MOVE    ;Excellent move SFX
LE62A:  BRK                     ;
LE62B:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE62D:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE630:  JSR DoDialogHiBlock     ;($C7C5)Excellent move...
LE633:  .byte $04               ;TextBlock17, entry 4.

LE634:  JSR UpdateRandNum       ;($C55B)Get random number.
LE637:  LDA RandNumUB
LE639:  STA MultNum1LB
LE63B:  LDA DisplayedAttck
LE63D:  LSR
LE63E:  STA MultNum2LB
LE640:  LDA #$00
LE642:  STA MultNum1UB
LE644:  STA MultNum2UB
LE646:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LE649:  LDA DisplayedAttck
LE64B:  SEC
LE64C:  SBC MultRsltUB
LE64E:  JMP $E664
LE651:  JSR $EFE5
LE654:  LDA MultNum1LB
LE656:  BNE $E664

LE658:  LDA #SFX_MISSED1        ;Player missed 1 SFX.
LE65A:  BRK                     ;
LE65B:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE65D:  JSR DoDialogLoBlock     ;($C7CB)The attack failed...
LE660:  .byte $E7               ;TextBlock15, entry 7.

LE661:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE664:  STA $00
LE666:  LDA #$00
LE668:  STA $01
LE66A:  BIT PlayerFlags
LE66C:  BVS $E69A
LE66E:  JSR UpdateRandNum       ;($C55B)Get random number.
LE671:  LDA RandNumUB
LE673:  AND #$3F
LE675:  STA RandNumUB
LE677:  LDA EnBaseMDef
LE67A:  AND #$0F
LE67C:  BEQ $E69A
LE67E:  SEC
LE67F:  SBC #$01
LE681:  CMP RandNumUB
LE683:  BCC $E69A

LE685:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE688:  LDA #SFX_MISSED1        ;Player missed 1 SFX.
LE68A:  BRK                     ;
LE68B:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE68D:  JSR DoDialogHiBlock     ;($C7C5)It is dodging!...
LE690:  .byte $0A               ;TextBlock17, entry 10.

LE691:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE694:  STA $00
LE696:  LDA #$00
LE698:  STA $01

LE69A:  LDA #SFX_ENMY_HIT       ;Enemy hit SFX.
LE69C:  BRK                     ;
LE69D:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE69F:  LDA RedFlashPalPtr
LE6A2:  STA $42
LE6A4:  LDA RedFlashPalPtr+1
LE6A7:  STA $43
LE6A9:  JSR PaletteFlash        ;($EF38)Palette flashing effect.
LE6AC:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE6AF:  JSR DoDialogLoBlock     ;($C7CB)
LE6B2:  .byte $E6

LE6B3:  JMP $E95D

LE6B6:  CMP #$02
LE6B8:  BEQ $E6BD
LE6BA:  JMP $E7A2
LE6BD:  LDA SpellFlags
LE6BF:  STA SpellFlagsLB
LE6C1:  LDA ModsnSpells
LE6C3:  AND #$03
LE6C5:  STA SpellFlagsUB
LE6C7:  ORA SpellFlagsLB
LE6C9:  BNE $E6D7
LE6CB:  LDA #WND_CMD_CMB
LE6CD:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LE6D0:  JSR DoDialogLoBlock     ;($C7CB)Player cannot yet use the spell.
LE6D3:  .byte $31               ;TextBlock4, entry 1.

LE6D4:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE6D7:  JSR ShowSpells          ;($DB56)Bring up the spell window.
LE6DA:  CMP #WND_ABORT
LE6DC:  BNE $E6E6

LE6DE:  LDA #WND_CMD_CMB
LE6E0:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LE6E3:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE6E6:  PHA
LE6E7:  LDA #WND_CMD_CMB
LE6E9:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LE6EC:  PLA
LE6ED:  CMP #$03
LE6EF:  BEQ $E6FD
LE6F1:  CMP #$07
LE6F3:  BEQ $E6FD
LE6F5:  CMP #$05
LE6F7:  BEQ $E6FD
LE6F9:  CMP #$06
LE6FB:  BNE $E704

LE6FD:  JSR DoDialogLoBlock     ;($C7CB)
LE700:  .byte $E9

LE701:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE704:  JSR CheckMP             ;($DB85)Check if MP is high enough to cast the spell.
LE707:  CMP #$32                ;TextBlock4, entry 2.
LE709:  BNE +
LE70B:  JSR DoMidDialog         ;($C7BD)Thy MP is too low...
LE70E:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE711:* STA SpellToCast
LE713:  LDA PlayerFlags
LE715:  AND #$10
LE717:  BEQ $E720

LE719:  JSR DoDialogLoBlock     ;($C7CB)
LE71C:  .byte $EA

LE71D:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE720:  LDA SpellToCast         ;Get cast spell.

LE722:  CMP #SPL_HEAL           ;Was the heal spell cast?
LE724:  BNE +                   ;If not, branch to move on.
LE726:  JSR DoHeal              ;($DBB8)Increase HP from heal spell.
LE729:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE72C:* CMP #SPL_HEALMORE       ;Was the healmore spell cast?
LE72E:  BNE +                   ;If not, branch to move on.
LE730:  JSR DoHealmore          ;($DBD7)Increase health from healmore spell.
LE733:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE736:* CMP #$01
LE738:  BNE $E751
LE73A:  LDA EnBaseMDef
LE73D:  LSR
LE73E:  LSR
LE73F:  LSR
LE740:  LSR
LE741:  JSR $E946
LE744:  JSR UpdateRandNum       ;($C55B)Get random number.
LE747:  LDA RandNumUB
LE749:  AND #$07
LE74B:  CLC
LE74C:  ADC #$05
LE74E:  JMP $E694
LE751:  CMP #$09
LE753:  BNE $E76C
LE755:  LDA EnBaseMDef
LE758:  LSR
LE759:  LSR
LE75A:  LSR
LE75B:  LSR
LE75C:  JSR $E946
LE75F:  JSR UpdateRandNum       ;($C55B)Get random number.
LE762:  LDA RandNumUB
LE764:  AND #$07
LE766:  CLC
LE767:  ADC #$3A
LE769:  JMP $E694
LE76C:  CMP #$02
LE76E:  BNE $E78A
LE770:  LDA EnBaseAgi
LE773:  LSR
LE774:  LSR
LE775:  LSR
LE776:  LSR
LE777:  JSR $E946
LE77A:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE77D:  JSR DoDialogLoBlock     ;($C7CB)
LE780:  .byte $EC

LE781:  LDA PlayerFlags
LE783:  ORA #$40
LE785:  STA PlayerFlags
LE787:  JMP $EB3E
LE78A:  LDA EnBaseAgi
LE78D:  AND #$0F
LE78F:  JSR $E946
LE792:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE795:  JSR DoDialogLoBlock     ;($C7CB)
LE798:  .byte $ED

LE799:  LDA PlayerFlags
LE79B:  ORA #$20
LE79D:  STA PlayerFlags
LE79F:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE7A2:  CMP #$03
LE7A4:  BEQ $E7A9
LE7A6:  JMP $E87F
LE7A9:  JSR CreateInvList       ;($DF77)Create inventory list in description buffer.
LE7AC:  CPX #$01
LE7AE:  BNE $E7BC
LE7B0:  LDA #WND_CMD_CMB
LE7B2:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LE7B5:  JSR DoDialogLoBlock     ;($C7CB)
LE7B8:  .byte $3D

LE7B9:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE7BC:  JSR Dowindow            ;($C6F0)display on-screen window.
LE7BF:  .byte WND_INVTRY1       ;Player inventory window.

LE7C0:  CMP #$FF
LE7C2:  BNE $E7CC
LE7C4:  LDA #WND_CMD_CMB
LE7C6:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LE7C9:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

LE7CC:  PHA
LE7CD:  LDA #WND_CMD_CMB
LE7CF:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LE7D2:  PLA
LE7D3:  TAX
LE7D4:  LDA DescBuf+1,X
LE7D6:  CMP #$02
LE7D8:  BNE $E7E6
LE7DA:  DEC InventoryHerbs

LE7DC:  JSR DoDialogLoBlock     ;($C7CB)Player used the herb...
LE7DF:  .byte $F7               ;TextBlock16, entry 7.

LE7E0:  JSR $DCFE
LE7E3:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE7E6:  CMP #$08
LE7E8:  BNE $E820

LE7EA:  JSR DoDialogLoBlock     ;($C7CB)
LE7ED:  .byte $3C

LE7EE:  LDA #MSC_FRY_FLUTE      ;Fairy flute music.
LE7F0:  BRK                     ;
LE7F1:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE7F3:  BRK                     ;Wait for the music clip to end.
LE7F4:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LE7F6:  LDA EnNumber
LE7F8:  CMP #EN_DRAGONLORD2
LE7FA:  BEQ $E801
LE7FC:  LDA #$18
LE7FE:  JMP $E803

LE801:  LDA #MSC_END_BOSS       ;End boss music.
LE803:  BRK                     ;
LE804:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE806:  LDA EnNumber
LE808:  CMP #EN_GOLEM
LE80A:  BNE $E819

LE80C:  JSR DoDialogLoBlock     ;($C7CB)
LE80F:  .byte $F3

LE810:  LDA PlayerFlags
LE812:  ORA #$40
LE814:  STA PlayerFlags
LE816:  JMP $EB3E

LE819:  JSR DoDialogLoBlock     ;($C7CB)
LE81C:  .byte $33

LE81D:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE820:  CMP #$0D
LE822:  BNE $E84A

LE824:  JSR DoDialogLoBlock     ;($C7CB)
LE827:  .byte $41

LE828:  LDA #MSC_SILV_HARP      ;Silver harp music.
LE829:  BRK                     ;
LE82B:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE82D:  BRK                     ;Wait for the music clip to end.
LE82E:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LE830:  LDA EnNumber
LE832:  CMP #EN_DRAGONLORD2
LE834:  BEQ $E83B
LE836:  LDA #MSC_REG_FGHT
LE838:  JMP $E83D

LE83B:  LDA #MSC_END_BOSS       ;End boss music.
LE83D:  BRK                     ;
LE83E:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE840:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE843:  JSR DoDialogLoBlock     ;($C7CB)Enemy looks happy...
LE846:  .byte $F4               ;TextBlock16, entry 4.

LE847:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE84A:  CMP #$07
LE84C:  BNE $E854
LE84E:  JSR ChkDragonScale      ;($DFB9)Check if player is wearing the dragon's scale.
LE851:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE854:  CMP #$09
LE856:  BNE $E85E
LE858:  JSR ChkRing             ;($DFD1)Check if player is wearing the ring.
LE85B:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE85E:  CMP #$0C
LE860:  BNE $E86D
LE862:  JSR WearCursedItem      ;($DFE7)Player puts on cursed item.

LE865:  LDA #MSC_REG_FGHT       ;Regular fight music.
LE867:  BRK                     ;
LE868:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE86A:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE86D:  CMP #$0E
LE86F:  BNE $E87C
LE871:  JSR ChkDeathNecklace    ;($E00A)Check if player is wearking the death necklace.

LE874:  LDA #MSC_REG_FGHT       ;Regular fight music.
LE876:  BRK                     ;
LE877:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE879:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE87C:  JMP $E6FD
LE87F:  CMP #$01
LE881:  BEQ $E886
LE883:  JMP $E5EF

LE886:  LDA #WND_CMD_CMB
LE888:  JSR RemoveWindow        ;($A7A2)Remove window from screen.

LE88B:  LDA #SFX_RUN            ;Run away SFX.
LE88D:  BRK                     ;
LE88E:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE890:  JSR DoDialogLoBlock     ;($C7CB)
LE893:  .byte $F5 

LE894:  BIT PlayerFlags
LE896:  BVS $E8A4
LE898:  JSR ModEnemyStats       ;($EE91)Randomly modify enemy stats.
LE89B:  BCS $E8A4

LE89D:  JSR DoDialogLoBlock     ;($C7CB)
LE8A0:  .byte $F6 

LE8A1:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE8A4:  LDX MapNumber           ;Get current map number.
LE8A6:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LE8A9:  BRK                     ;
LE8AA:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE8AC:  LDA EnNumber
LE8AE:  CMP #EN_DRAGONLORD2
LE8B0:  BNE $E8D4
LE8B2:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE8B5:  LDA $9A18
LE8B8:  STA PalPtrLB
LE8BA:  LDA $9A19
LE8BD:  STA PalPtrUB
LE8BF:  LDA #$00
LE8C1:  STA PalModByte
LE8C3:  STA EnNumber
LE8C5:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.
LE8C8:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer
LE8CB:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE8CE:  JSR ClearWinBufRAM2     ;($A788)Clear RAM buffer used for drawing text windows.
LE8D1:  JMP MapChngNoSound      ;($B091)Change maps with no stairs sound.

LE8D4:  LDA MapNumber
LE8D6:  CMP #MAP_HAUKSNESS
LE8D8:  BNE $E8FB
LE8DA:  LDA CharXPos
LE8DC:  CMP #$12
LE8DE:  BNE $E8FB
LE8E0:  LDA CharYPos
LE8E2:  CMP #$0C
LE8E4:  BNE $E8FB
LE8E6:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
LE8E9:  DEC CharXPos
LE8EB:  DEC _CharXPos
LE8ED:  LDA CharXPixelsLB
LE8EF:  SEC
LE8F0:  SBC #$10
LE8F2:  STA CharXPixelsLB
LE8F4:  BCS $E8F8
LE8F6:  DEC CharXPixelsUB
LE8F8:  JMP MapChngWithSound    ;($B097)Change maps with stairs sound.
LE8FB:  LDA MapNumber
LE8FD:  CMP #MAP_SWAMPCAVE
LE8FF:  BNE $E928
LE901:  LDA CharXPos
LE903:  CMP #$04
LE905:  BNE $E928
LE907:  LDA CharYPos
LE909:  CMP #$0E
LE90B:  BNE $E928
LE90D:  LDA StoryFlags
LE90F:  AND #F_GDRG_DEAD
LE911:  BNE $E928
LE913:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
LE916:  DEC CharYPos
LE918:  DEC _CharYPos
LE91A:  LDA CharYPixelsLB
LE91C:  SEC
LE91D:  SBC #$10
LE91F:  STA CharYPixelsLB
LE921:  BCS $E925
LE923:  DEC CharYPixelsUB
LE925:  JMP MapChngWithSound    ;($B097)Change maps with stairs sound.
LE928:  LDA MapNumber
LE92A:  CMP #MAP_OVERWORLD
LE92C:  BNE $E940
LE92E:  LDA CharXPos
LE930:  CMP #$49
LE932:  BNE $E940
LE934:  LDA CharYPos
LE936:  CMP #$64
LE938:  BNE $E940
LE93A:  LDA StoryFlags
LE93C:  AND #F_GOLEM_DEAD
LE93E:  BEQ $E913
LE940:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
LE943:  JMP $EE5A
LE946:  STA $3E
LE948:  JSR UpdateRandNum       ;($C55B)Get random number.
LE94B:  LDA RandNumUB
LE94D:  AND #$0F
LE94F:  CMP $3E
LE951:  BCC $E954
LE953:  RTS

LE954:  PLA
LE955:  PLA

LE956:  JSR DoDialogLoBlock     ;($C7CB)
LE959:  .byte $EB

LE95A:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

LE95D:  LDA EnCurntHP
LE95F:  SEC
LE960:  SBC $00
LE962:  STA EnCurntHP
LE964:  BCC EnemyDefeated       ;($E96B)Enemy overkill! Branch to end fight.
LE966:  BEQ EnemyDefeated       ;($E96B)Enemy dead! Branch to end fight.
LE968:  JMP StartEnemyTurn      ;($EB1B)It's the enemy's turn to attack.

;----------------------------------------------------------------------------------------------------

EnemyDefeated:
LE96B:  LDA EnNumber            ;Check what enemy was just killed.
LE96D:  CMP #EN_GDRAGON         ;Was it a green dragon?
LE96F:  BNE ChkGolemKilled      ;If not, move on.

LE971:  LDA MapNumber           ;Green dragon just killed.
LE973:  CMP #MAP_SWAMPCAVE      ;Was it in the swamp cave?
LE975:  BNE ChkGolemKilled      ;If not, move on.

LE977:  LDA StoryFlags          ;Green dragon in the swamp cave-->
LE979:  ORA #F_GDRG_DEAD        ;was defeated.  Set story flag.
LE97B:  STA StoryFlags          ;
LE97D:  BNE ContEnDefeated      ;Branch always.

ChkGolemKilled:
LE97F:  CMP #EN_GOLEM           ;Was it a golem?
LE981:  BNE ContEnDefeated      ;If not, move on.

LE983:  LDA MapNumber           ;Golem just killed.
LE985:  CMP #MAP_OVERWORLD      ;Was it on the overworld map?
LE987:  BNE ContEnDefeated      ;If not, move on.

LE989:  LDA StoryFlags          ;Golem on the overworld was-->
LE98B:  ORA #F_GOLEM_DEAD       ;defeated.  Set story flag.
LE98D:  STA StoryFlags          ;

ContEnDefeated:
LE98F:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LE992:  JSR DoDialogLoBlock     ;($C7CB)Thy experience increased by amount...
LE995:  .byte $EE               ;TextBlock15, entry 14.

LE996:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.

LE999:  LDA #MSC_VICTORY        ;Victory music.
LE99B:  BRK                     ;
LE99C:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LE99E:  LDA EnNumber            ;Was it the first dragonlord that was defeated?
LE9A0:  CMP #EN_DRAGONLORD1     ;
LE9A2:  BNE NotDL1Defeated      ;If not, branch to move on.

LE9A4:  LDX #$50                ;Wait for 80 frames.
LE9A6:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE9A9:  DEX                     ;
LE9AA:  BNE -                   ;80 frames elapsed? If not, branch to wait more.

LE9AC:  LDA #EN_DRAGONLORD2     ;Fight the final boss!
LE9AE:  JMP InitFight           ;($E4DF)Load the final fight.

NotDL1Defeated:
LE9B1:  CMP #EN_DRAGONLORD2
LE9B3:  BNE $EA0A
LE9B5:  STA DrgnLrdPal
LE9B8:  LDA #$02
LE9BA:  STA CharDirection
LE9BD:  LDA #$2C
LE9BF:  STA PPUAddrLB
LE9C1:  LDA #$21
LE9C3:  STA PPUAddrUB
LE9C5:  LDA #TL_BLANK_TILE1
LE9C7:  STA PPUDataByte
LE9C9:  LDA #$06
LE9CB:  STA $3C
LE9CD:  LDY #$07
LE9CF:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
LE9D2:  DEY
LE9D3:  BNE $E9CF
LE9D5:  LDA PPUAddrLB
LE9D7:  CLC
LE9D8:  ADC #$19
LE9DA:  STA PPUAddrLB
LE9DC:  BCC $E9E0
LE9DE:  INC PPUAddrUB
LE9E0:  DEC $3C
LE9E2:  BNE $E9CD
LE9E4:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LE9E7:  JSR WaitForNMI          ;($FF74)

LE9EA:  LDA #$00                ;Clear enemy number.
LE9EC:  STA EnNumber            ;

LE9EE:  JSR DoDialogHiBlock     ;($C7C5)Thou hast found the ball of light...
LE9F1:  .byte $1A               ;TextBlock18, entry 10.

LE9F2:  LDA StoryFlags          ;
LE9F4:  ORA #F_DGNLRD_DEAD      ;Set flag indicating the dragonlord has been defeated.
LE9F6:  STA StoryFlags          ;

LE9F8:  JSR WaitForBtnRelease   ;($CFE4)Wait for player to release then press joypad buttons.
LE9FB:  LDA DisplayedMaxHP
LE9FD:  STA HitPoints
LE9FF:  LDA DisplayedMaxMP
LEA01:  STA MagicPoints
LEA03:  LDX #$12
LEA05:  LDA #$02
LEA07:  JMP ChangeMaps          ;($D9E2)Load a new map.
LEA0A:  LDA EnBaseExp
LEA0D:  STA $00
LEA0F:  LDA #$00
LEA11:  STA $01

LEA13:  JSR DoDialogLoBlock     ;($C7CB)
LEA16:  .byte $EF

LEA17:  LDA $00
LEA19:  CLC
LEA1A:  ADC ExpLB
LEA1C:  STA ExpLB
LEA1E:  BCC $EA2A
LEA20:  INC ExpUB
LEA22:  BNE $EA2A
LEA24:  LDA #$FF
LEA26:  STA ExpLB
LEA28:  STA ExpUB
LEA2A:  LDA EnBaseGld
LEA2D:  STA MultNum2LB
LEA2F:  JSR UpdateRandNum       ;($C55B)Get random number.
LEA32:  LDA RandNumUB
LEA34:  AND #$3F
LEA36:  CLC
LEA37:  ADC #$C0
LEA39:  STA MultNum1LB
LEA3B:  LDA #$00
LEA3D:  STA MultNum1UB
LEA3F:  STA MultNum2UB
LEA41:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LEA44:  LDA MultRsltUB
LEA46:  STA $00
LEA48:  LDA #$00
LEA4A:  STA $01

LEA4C:  JSR DoDialogLoBlock     ;($C7CB)
LEA4F:  .byte $F0 

LEA50:  LDA $00
LEA52:  CLC
LEA53:  ADC GoldLB
LEA55:  STA GoldLB
LEA57:  BCC $EA63
LEA59:  INC GoldUB
LEA5B:  BNE $EA63
LEA5D:  LDA #$FF
LEA5F:  STA GoldLB
LEA61:  STA GoldUB

LEA63:  JSR Dowindow            ;($C6F0)display on-screen window.
LEA66:  .byte WND_POPUP         ;Pop-up window.

LEA67:  LDA DisplayedMaxMP
LEA69:  PHA
LEA6A:  LDA DisplayedMaxHP
LEA6C:  PHA
LEA6D:  LDA DisplayedAgi
LEA6F:  PHA
LEA70:  LDA DisplayedStr
LEA72:  PHA
LEA73:  LDA DisplayedLevel
LEA75:  PHA
LEA76:  JSR LoadStats           ;($F050)Update player attributes.

LEA79:  PLA
LEA7A:  CMP DisplayedLevel
LEA7C:  BNE $EA90

LEA7E:  BRK                     ;Wait for the music clip to end.
LEA7F:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LEA81:  LDX MapNumber           ;Get current map number.
LEA83:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LEA86:  BRK                     ;
LEA87:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEA89:  PLA
LEA8A:  PLA
LEA8B:  PLA
LEA8C:  PLA
LEA8D:  JMP ExitFight           ;($EE54)Return to map after fight.

LEA90:  LDA #MSC_LEVEL_UP       ;Level up music.
LEA92:  BRK                     ;
LEA93:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEA95:  BRK                     ;Wait for the music clip to end.
LEA96:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LEA98:  LDX MapNumber           ;Get current map number.
LEA9A:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LEA9D:  BRK                     ;
LEA9E:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEAA0:  JSR DoDialogLoBlock     ;($C7CB)Thou hast been promoted to the next level...
LEAA3:  .byte $F1               ;TextBlock16, entry 1.

LEAA4:  LDA #$00
LEAA6:  STA $01
LEAA8:  PLA
LEAA9:  STA $3C
LEAAB:  LDA DisplayedStr
LEAAD:  SEC
LEAAE:  SBC $3C
LEAB0:  BEQ $EAB8
LEAB2:  STA $00

LEAB4:  JSR DoDialogHiBlock     ;($C7C5)
LEAB7:  .byte $0E 

LEAB8:  PLA
LEAB9:  STA $3C
LEABB:  LDA DisplayedAgi
LEABD:  SEC
LEABE:  SBC $3C
LEAC0:  BEQ $EAC8
LEAC2:  STA $00

LEAC4:  JSR DoDialogHiBlock     ;($C7C5)
LEAC7:  .byte $0F

LEAC8:  PLA
LEAC9:  STA $3C
LEACB:  LDA DisplayedMaxHP
LEACD:  SEC
LEACE:  SBC $3C
LEAD0:  STA $00

LEAD2:  JSR DoDialogHiBlock     ;($C7C5)
LEAD5:  .byte $10

LEAD6:  PLA
LEAD7:  STA $3C
LEAD9:  LDA DisplayedMaxMP
LEADB:  SEC
LEADC:  SBC $3C
LEADE:  BEQ $EAE6
LEAE0:  STA $00

LEAE2:  JSR DoDialogHiBlock     ;($C7C5)Thy maximum magic points increased...
LEAE5:  .byte $11               ;TextBlock18, entry 1.

LEAE6:  LDA DisplayedLevel      ;
LEAE8:  CMP #LVL_03             ;
LEAEA:  BEQ NewSpellDialog      ;
LEAEC:  CMP #LVL_04             ;
LEAEE:  BEQ NewSpellDialog      ;
LEAF0:  CMP #LVL_07             ;
LEAF2:  BEQ NewSpellDialog      ;
LEAF4:  CMP #LVL_09             ;
LEAF6:  BEQ NewSpellDialog      ;A new spell has been learned.  New spells are-->
LEAF8:  CMP #LVL_10             ;learned on levels 3, 4, 7, 9, 10, 12, 13, 15,-->
LEAFA:  BEQ NewSpellDialog      ;17 and 19.
LEAFC:  CMP #LVL_12             ;
LEAFE:  BEQ NewSpellDialog      ;
LEB00:  CMP #LVL_13             ;
LEB02:  BEQ NewSpellDialog      ;
LEB04:  CMP #LVL_15             ;
LEB06:  BEQ NewSpellDialog      ;
LEB08:  CMP #LVL_17             ;
LEB0A:  BEQ NewSpellDialog      ;
LEB0C:  CMP #LVL_19             ;

LEB0E:  BNE +                   ;No new spell learned. Branch to skip new spell dialog.

NewSpellDialog:
LEB10:  JSR DoDialogLoBlock     ;($C7CB)Thou hast learned a new spell...
LEB13:  .byte $F2               ;TextBlock16, entry 2.

LEB14:* JSR Dowindow            ;($C6F0)display on-screen window.
LEB17:  .byte WND_POPUP         ;Pop-up window.

LEB18:  JMP ExitFight           ;($EE54)Return to map after fight.

;----------------------------------------------------------------------------------------------------

StartEnemyTurn:
LEB1B:  LDA PlayerFlags         ;Check if enemy is asleep.
LEB1D:  AND #F_EN_ASLEEP        ;
LEB1F:  BEQ DoEnemyAttack       ;($EB48)Enemy is not asleep.  Branch to continue.

LEB21:* JSR UpdateRandNum       ;($C55B)Get random number.
LEB24:  LDA RandNumUB           ;
LEB26:  AND #$03                ;Get random number until at least one of the 2 LSBs is set.
LEB28:  BEQ -                   ;

LEB2A:  CMP #$01                ;1 in 4 chance enemy will wake up.
LEB2C:  BNE EnStillAsleep       ;Is enemy still asleep if so, branch.

LEB2E:  LDA PlayerFlags         ;
LEB30:  AND #$BF                ;Clear enemy asleep flag.
LEB32:  STA PlayerFlags         ;
LEB34:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LEB37:  JSR DoDialogLoBlock     ;($C7CB)Enemy hath woken up...
LEB3A:  .byte $00               ;TextBlock 1, entry 0.

LEB3B:  JMP DoEnemyAttack       ;($EB48)Enemy woke up.  Jump to continue.

EnStillAsleep:
LEB3E:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LEB41:  JSR DoDialogLoBlock     ;($C7CB)The enemy is asleep...
LEB44:  .byte $F8               ;TextBlock16, entry 8.

LEB45:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

;----------------------------------------------------------------------------------------------------

DoEnemyAttack:
LEB48:  JSR CheckEnRun          ;($EFB7)Check if enemy is going to run away.
LEB4B:  JSR UpdateRandNum       ;($C55B)Get random number.
LEB4E:  LDA EnSpell             ;
LEB51:  AND #$30                ;Get upper spells control bits.
LEB53:  STA GenByte3C           ;
LEB55:  LDA RandNumUB           ;Make random check to see if an upper spell will be cast.
LEB57:  AND #$30                ;
LEB59:  CMP GenByte3C           ;Will upper spell be cast?
LEB5B:  BCS EnCheckHurtFire     ;If not, branch to check if lower spell will be cast.

LEB5D:  LDA EnSpell             ;Get upper spell bits.
LEB60:  AND #$C0                ;Some spell other than sleep?
LEB62:  BNE +                   ;If so, branch to check which spell.

LEB64:  LDA PlayerFlags         ;Is the player asleep?
LEB66:  BMI EnCheckHurtFire     ;If so, branch to check if lower spell will be cast.
LEB68:  JMP EnCastSleep         ;($EC92)Enemy casts sleep.

LEB6B:* CMP #$40                ;Does enemy have stopspell?
LEB6D:  BNE +                   ;If not, branch to check for heal.

LEB6F:  LDA PlayerFlags         ;Is the player stopspelled?
LEB71:  AND #F_PLR_STOPSPEL     ;
LEB73:  BNE EnCheckHurtFire     ;If so, branch to check if lower spell will be cast.
LEB75:  JMP EnCastStopspell     ;($EC69)Enemy casts stopspell.

LEB78:* CMP #$80                ;Does enemy have heal?
LEB7A:  BNE +                   ;If not, branch to check for healmore.

LEB7C:  LDA EnBaseHP            ;Is enemies current hit points less than 1/4-->
LEB7F:  LSR                     ;of base hit points?
LEB80:  LSR                     ;If not, branch to check if lower spell will be cast.
LEB81:  CMP EnCurntHP           ;
LEB83:  BCC EnCheckHurtFire     ;
LEB85:  JMP EnCastHeal          ;($ECA6)Enemy casts heal.

LEB88:* LDA EnBaseHP            ;Is enemies current hit points less than 1/4-->
LEB8B:  LSR                     ;of base hit points?
LEB8C:  LSR                     ;If not, branch to check if lower spell will be cast.
LEB8D:  CMP EnCurntHP           ;
LEB8F:  BCC EnCheckHurtFire     ;
LEB91:  JMP EnCastHealmore      ;($ECCE)Enemy casts healmore.

EnCheckHurtFire:
LEB94:  JSR UpdateRandNum       ;($C55B)Get random number.
LEB97:  LDA EnSpell             ;
LEB9A:  AND #$03                ;Get lower spells control bits.
LEB9C:  STA GenByte3C           ;
LEB9E:  LDA RandNumUB           ;
LEBA0:  AND #$03                ;Make random check to see if a lower spell will be cast.
LEBA2:  CMP GenByte3C           ;Will lower spell be cast?
LEBA4:  BCS EnPhysAttack        ;If not, branch. Enemy going to do a physical attack.

LEBA6:  LDA EnSpell             ;Get upper spell bits.
LEBA9:  AND #$0C                ;Some spell other than hurt?
LEBAB:  BNE +                   ;If so, branch to check which spell.
LEBAD:  JMP EnCastHurt          ;($EC23)Enemy casts hurt.

LEBB0:* CMP #$04                ;Does enemy have hurtmore spell?
LEBB2:  BNE +                   ;If not, branch.
LEBB4:  JMP EnCastHurtmore      ;($EC55)Enemy casts hurtmore.

LEBB7:* CMP #$08                ;Does enemy have fire1?
LEBB9:  BNE +                   ;If not, branch to do fire2.
LEBBB:  JMP EnCastFire1         ;($ECED)Enemy casts fire1.

LEBBE:* JMP EnCastFire2         ;($ECE1)Enemy casts fire2(end boss only).

EnPhysAttack:
LEBC1:  LDA #SFX_ATCK_PREP      ;Prepare to attack SFX.
LEBC3:  BRK                     ;
LEBC4:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEBC6:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LEBC9:  JSR DoDialogLoBlock     ;($C7CB)The enemy attacks...
LEBCC:  .byte $F9               ;TextBlock16, entry 9.

LEBCD:  LDA EnBaseAtt           ;Make a copy of enemy's attack stat.
LEBD0:  STA GenByte42           ;
LEBD2:  LDA DisplayedDefns      ;Make a copy of player's defense stat.
LEBD4:  STA GenByte43           ;
LEBD6:  JSR EnCalcHitDmg        ;($EFF4)Calculate enemy hit damage on player.

LEBD9:  LDA GenByte3C           ;Did enemy do damage to the player?
LEBDB:  BNE EnHitsPlayer        ;If so, branch to subtract damage from player's HP.

LEBDD:  LDA #SFX_MISSED2        ;Attack missed 2 SFX.
LEBDF:  BRK                     ;
LEBE0:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEBE2:  JSR DoDialogLoBlock     ;($C7CB)A miss! no damage hath been scored...
LEBE5:  .byte $FB               ;TextBlock16, entry 11.

LEBE6:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

EnHitsPlayer:
LEBE9:  STA GenByte00           ;Store damage to subtract from player's hit points.
LEBEB:  JMP PlayerHit           ;($ED20)Player takes damage.

EnCastSpell:
LEBEE:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LEBF1:  JSR DoDialogLoBlock     ;($C7CB)enemy...
LEBF4:  .byte $FC               ;TextBlock16, entry 12.

LEBF5:  LDA SpellToCast         ;Get description byte for spell to cast.
LEBF7:  JSR GetDescriptionByte  ;($DBF0)Load byte for item dialog description.

LEBFA:  JSR DoDialogLoBlock     ;($C7CB)Chants the spell of spell...
LEBFD:  .byte $FD               ;TextBlock16, entry 13.

LEBFE:  LDA #SFX_SPELL          ;Spell cast SFX.
LEC00:  BRK                     ;
LEC01:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEC03:  LDA SplFlshBGPalPtr     ;Get pointer to background flashing palettes.
LEC06:  STA GenPtr42LB          ;
LEC08:  LDA SplFlshBGPalPtr+1   ;
LEC0B:  STA GenPtr42UB          ;
LEC0D:  JSR PaletteFlash        ;($EF38)Palette flashing effect.

LEC10:  BRK                     ;Wait for the music clip to end.
LEC11:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LEC13:  LDA PlayerFlags         ;
LEC15:  AND #F_EN_STOPSPEL      ;Has the enemy been stopspelled?
LEC17:  BNE EnStopSplDialog     ;If so, branch to display blocked dialog.
LEC19:  RTS                     ;

EnStopSplDialog:
LEC1A:  JSR DoDialogLoBlock     ;($C7CB)But the spell has been blocked...
LEC1D:  .byte $EA               ;TextBlock15, entry 10.

LEC1E:  PLA                     ;Remove return address from last function.
LEC1F:  PLA                     ;
LEC20:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

EnCastHurt:
LEC23:  LDA #DSC_HURT-4         ;Prepare to cast hurt spell.
LEC25:  STA SpellToCast         ;
LEC27:  JSR EnCastSpell         ;($EBEE)Enemy casts a spell.

LEC2A:  JSR UpdateRandNum       ;($C55B)Get random number.
LEC2D:  LDA RandNumUB
LEC2F:  AND #$07
LEC31:  CLC
LEC32:  ADC #$03

EnCalcSpllDmg:
LEC34:  STA GenByte00
LEC36:  LDA EqippedItems
LEC38:  AND #AR_ARMOR
LEC3A:  CMP #AR_ERDK_ARMR
LEC3C:  BEQ $EC42

LEC3E:  CMP #AR_MAGIC_ARMR
LEC40:  BNE $EC52

LEC42:  LDA GenByte00
LEC44:  STA DivNum1LB
LEC46:  LDA #$03
LEC48:  STA DivNum2
LEC4A:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LEC4D:  LDA DivQuotient
LEC4F:  ASL
LEC50:  STA GenByte00
LEC52:  JMP PlayerHit           ;($ED20)Player takes damage.

EnCastHurtmore:
LEC55:  LDA #DSC_HURTMORE-4     ;Prepare to cast hurtmore spell.
LEC57:  STA SpellToCast         ;
LEC59:  JSR EnCastSpell         ;($EBEE)Enemy casts a spell.

LEC5C:  JSR UpdateRandNum       ;($C55B)Get random number.
LEC5F:  LDA RandNumUB           ;Get random number and keep lower 4 bits.
LEC61:  AND #$0F                ;
LEC63:  CLC                     ;Add 30.
LEC64:  ADC #$1E                ;Enemy damages for 30HP min and 45HP max(base damage).
LEC66:  JMP EnCalcSpllDmg       ;($EC34)Calculate player damage.

EnCastStopspell:
LEC69:  LDA #DSC_STOPSPELL-4    ;Prepare to cast stopspell.
LEC6B:  STA SpellToCast         ;
LEC6D:  JSR EnCastSpell         ;($EBEE)Enemy casts a spell.

LEC70:  LDA EqippedItems        ;If player is wearing Erdrick's armor,
LEC72:  AND #AR_ARMOR           ;stopspell will not work.
LEC74:  CMP #AR_ERDK_ARMR       ;
LEC76:  BEQ BlockStopSpell      ;Branch to block.

LEC78:  JSR UpdateRandNum       ;($C55B)Get random number.
LEC7B:  LDA RandNumUB           ;50% chance it will stopspell the player.
LEC7D:  LSR                     ;
LEC7E:  BCC BlockStopSpell      ;Branch if stopspell was blocked.

LEC80:  LDA PlayerFlags         ;
LEC82:  ORA #F_PLR_STOPSPEL     ;Stopspell on player was successful.
LEC84:  STA PlayerFlags         ;

LEC86:  LDA #$FE                ;TextBlock16, entry 14. Spell is blocked...
LEC88:* JSR DoMidDialog         ;($C7BD)

LEC8B:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

BlockStopSpell:
LEC8E:  LDA #$EB                ;TextBlock15, Entry 11. The spell will not work...
LEC90:  BNE -                   ;Branch always.

EnCastSleep:
LEC92:  LDA #DSC_SLEEP-4        ;Prepare to cast sleep spell.
LEC94:  STA SpellToCast         ;
LEC96:  JSR EnCastSpell         ;($EBEE)Enemy casts a spell.

LEC99:  LDA PlayerFlags         ;
LEC9B:  ORA #F_PLR_ASLEEP       ;Set player flag for sleep.
LEC9D:  STA PlayerFlags         ;

LEC9F:  JSR DoDialogHiBlock     ;($C7C5)Thou art asleep...
LECA2:  .byte $06               ;TextBlock17, entry 6.

LECA3:  JMP PlayerAsleepDialog  ;($E5DE)Show dialog that player is still asleep.

EnCastHeal:
LECA6:  LDA #DSC_HEAL-4         ;Prepare to cast heal spell.
LECA8:  STA SpellToCast         ;
LECAA:  JSR EnCastSpell         ;($EBEE)Enemy casts a spell.

LECAD:  JSR UpdateRandNum       ;($C55B)Get random number.
LECB0:  LDA RandNumUB           ;Get random number and keep lower 3 bits.
LECB2:  AND #$07                ;
LECB4:  CLC                     ;Add 20.
LECB5:  ADC #$14                ;Enemy recovers 20HP min and 27HP max.

EnemyAddHP:
LECB7:  CLC                     ;
LECB8:  ADC EnCurntHP           ;Add recovered amount to enemy hit points.
LECBA:  CMP EnBaseHP            ;
LECBD:  BCC +                   ;Is new amount higher than max amount? If not, branch.

LECBF:  LDA EnBaseHP            ;Enemy hit points fully recovered.

LECC2:* STA EnCurntHP           ;Update enemy hit points.
LECC4:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LECC7:  JSR DoDialogHiBlock     ;($C7C5)The enemy hath recovered...
LECCA:  .byte $09               ;TextBlock17, entry 9.

LECCB:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

EnCastHealmore:
LECCE:  LDA #DSC_HEALMORE-4     ;Prepare to cast healmore spell.
LECD0:  STA SpellToCast         ;
LECD2:  JSR EnCastSpell         ;($EBEE)Enemy casts a spell.

LECD5:  JSR UpdateRandNum       ;($C55B)Get random number.
LECD8:  LDA RandNumUB           ;Get random number and keep lower 4 bits.
LECDA:  AND #$0F                ;
LECDC:  CLC                     ;Add 85.
LECDD:  ADC #$55                ;Enemy recovers 85HP min and 100HP max.
LECDF:  BNE EnemyAddHP          ;Branch always.

EnCastFire2:
LECE1:  JSR UpdateRandNum       ;($C55B)Get random number.
LECE4:  LDA RandNumUB
LECE6:  AND #$07
LECE8:  CLC
LECE9:  ADC #$41
LECEB:  BNE $ECF6

EnCastFire1:
LECED:  JSR UpdateRandNum       ;($C55B)Get random number.
LECF0:  LDA RandNumUB
LECF2:  AND #$07
LECF4:  ORA #$10

LECF6:  STA $00
LECF8:  LDA #$00
LECFA:  STA $01
LECFC:  LDA EqippedItems
LECFE:  AND #AR_ARMOR
LED00:  CMP #AR_ERDK_ARMR
LED02:  BNE DoFireSFX

LED04:  LDA $00
LED06:  STA DivNum1LB
LED08:  LDA #$03
LED0A:  STA DivNum2
LED0C:  JSR ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LED0F:  LDA DivQuotient
LED11:  ASL
LED12:  STA $00

DoFireSFX:
LED14:  LDA #SFX_FIRE           ;Fire SFX.
LED16:  BRK                     ;
LED17:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LED19:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LED1C:  JSR DoDialogLoBlock     ;($C7CB)The enemy is breathing fire...
LED1F:  .byte $FF               ;TextBlock16, entry 15.

;----------------------------------------------------------------------------------------------------

PlayerHit:
LED20:  LDA #SFX_PLYR_HIT1      ;Player hit 1 SFX.
LED22:  BRK                     ;
LED23:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LED25:  LDA #$00
LED27:  STA $01
LED29:  LDA HitPoints
LED2B:  SEC
LED2C:  SBC $00
LED2E:  BCS $ED32
LED30:  LDA #$00
LED32:  STA HitPoints
LED34:  LDA #$08
LED36:  STA $42
LED38:  LDA ScrollX
LED3A:  STA $0F
LED3C:  LDA ScrollY
LED3E:  STA $10
LED40:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LED43:  LDA HitPoints
LED45:  BEQ $ED4D
LED47:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LED4A:  JMP $ED56
LED4D:  LDA EnNumber
LED4F:  CMP #EN_DRAGONLORD2
LED51:  BEQ $ED56
LED53:  JSR RedFlashScreen      ;($EE14)Flash the screen red.
LED56:  LDA $42
LED58:  AND #$01
LED5A:  BNE $ED66
LED5C:  LDA $0F
LED5E:  CLC
LED5F:  ADC #$02
LED61:  STA ScrollX
LED63:  JMP $ED6D
LED66:  LDA $10
LED68:  CLC
LED69:  ADC #$02
LED6B:  STA ScrollY
LED6D:  LDA EnNumber
LED6F:  CMP #EN_DRAGONLORD2
LED71:  BNE $ED7B
LED73:  LDA $0F
LED75:  STA ScrollX
LED77:  LDA $10
LED79:  STA ScrollY
LED7B:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LED7E:  JSR LoadRegBGPal        ;($EE28)Load the normal background palette.
LED81:  LDA $0F
LED83:  STA ScrollX
LED85:  LDA $10
LED87:  STA ScrollY
LED89:  DEC $42
LED8B:  BNE $ED40

LED8D:  JSR DoDialogLoBlock     ;($C7CB)
LED90:  .byte $FA

LED91:  JSR Dowindow            ;($C6F0)display on-screen window.
LED94:  .byte WND_POPUP

LED95:  LDA HitPoints           ;Has player died?
LED97:  BEQ PlayerHasDied       ;
LED99:  JMP StartPlayerTurn     ;($E5CE)It's the player's turn to attack.

PlayerHasDied:
LED9C:  LDA #MSC_DEATH          ;Death music.
LED9E:  BRK                     ;
LED9F:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEDA1:  BRK                     ;Wait for the music clip to end.
LEDA2:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LEDA4:  JMP $EDB4

InitDeathSequence:
LEDA7:  LDA #MSC_DEATH          ;Death music.
LEDA9:  BRK                     ;
LEDAA:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEDAC:  BRK                     ;Wait for the music clip to end.
LEDAD:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

LEDAF:  LDA #WND_DIALOG         ;Dialog window.
LEDB1:  JSR _DoWindow           ;($C703)Show dialog window.

LEDB4:  JSR DoDialogLoBlock     ;($C7CB)Thou art dead...
LEDB7:  .byte $01               ;TextBlock1, entry 1.

LEDB8:  LDA #STRT_FULL_HP       ;Player's HP and MP should be maxed out on next start.
LEDBA:  STA ThisStrtStat        ;

LEDBD:  LDA #$00                ;Character will be facing up on next restart.
LEDBF:  STA CharDirection       ;

LEDC2:* JSR GetJoypadStatus     ;($C608)Get input button presses.
LEDC5:  LDA JoypadBtns
LEDC7:  AND #$09
LEDC9:  BEQ -

LEDCB:  LSR GoldUB
LEDCD:  ROR GoldLB
LEDCF:  LDA PlayerFlags
LEDD1:  AND #$FE
LEDD3:  STA PlayerFlags
LEDD5:  LDA EnNumber
LEDD7:  STA DrgnLrdPal

LEDDA:  LDA #$00
LEDDC:  STA EnNumber

LEDDE:  JSR StartAtThroneRoom   ;($CB47)Start player at throne room.

LEDE1:  LDA ModsnSpells
LEDE3:  AND #$C0
LEDE5:  BEQ $EDF2

LEDE7:  JSR DoDialogHiBlock     ;($C7C5)Thou hast failed and thou art cursed...
LEDEA:  .byte $14               ;TextBlock18, entry 4.

LEDEB:  LDX #$0C
LEDED:  LDA #$02
LEDEF:  JMP ChangeMaps          ;($D9E2)Load a new map.

LEDF2:  JSR DoDialogHiBlock     ;($C7C5)
LEDF5:  .byte $0D 

LEDF6:  LDA $C7
LEDF8:  CMP #$1E
LEDFA:  BEQ $EE03
LEDFC:  JSR GetExpRemaining     ;($F134)Calculate experience needed for next level.

LEDFF:  JSR DoDialogHiBlock     ;($C7C5)
LEE02:  .byte $12

LEE03:  JSR DoDialogHiBlock     ;($C7C5)
LEE06:  .byte $13

LEE07:  JSR WaitForBtnRelease   ;($CFE4)Wait for player to release then press joypad buttons.
LEE0A:  LDA #WND_DIALOG
LEE0C:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LEE0F:  LDA #NPC_MOVE
LEE11:  STA StopNPCMove
LEE13:  RTS

RedFlashScreen:
LEE14:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LEE17:  LDA RedFlashPalPtr
LEE1A:  STA PalPtrLB
LEE1C:  LDA RedFlashPalPtr+1
LEE1F:  STA PalPtrUB
LEE21:  LDA #$00
LEE23:  STA PalModByte
LEE25:  JMP PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer

;----------------------------------------------------------------------------------------------------

LoadRegBGPal:
LEE28:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LEE2B:  LDA EnNumber
LEE2D:  CMP #EN_DRAGONLORD2
LEE2F:  BNE $EE3E
LEE31:  LDA FnlBsBGPalPtr
LEE34:  STA PalPtrLB
LEE36:  LDA FnlBsBGPalPtr+1
LEE39:  STA PalPtrUB
LEE3B:  JMP $EE4D

LEE3E:  LDA OverworldPalPtr
LEE41:  CLC
LEE42:  ADC MapType
LEE44:  STA PalPtrLB
LEE46:  LDA OverworldPalPtr+1
LEE49:  ADC #$00
LEE4B:  STA PalPtrUB

LEE4D:  LDA #$00                ;No palette modification.
LEE4F:  STA PalModByte          ;
LEE51:  JMP PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer

;----------------------------------------------------------------------------------------------------

ExitFight:
LEE54:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
LEE57:  JSR WaitForBtnRelease   ;($CFE4)Wait for player to release then press joypad buttons.
LEE5A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LEE5D:  LDA RegSPPalPtr         ;
LEE60:  STA PalPtrLB            ;Load standard palette while on map.
LEE62:  LDA RegSPPalPtr+1       ;
LEE65:  STA PalPtrUB            ;

LEE67:  LDA #$00
LEE69:  STA $3C
LEE6B:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.

LEE6E:  LDA NPCUpdateCntr
LEE70:  AND #$70
LEE72:  BEQ $EE76

LEE74:  LDA #$FF
LEE76:  STA NPCUpdateCntr

LEE78:  LDA #WND_DIALOG
LEE7A:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LEE7D:  LDA #WND_ALPHBT
LEE7F:  JSR RemoveWindow        ;($A7A2)Remove window from screen.
LEE82:  LDA #$02
LEE84:  STA CharDirection

LEE87:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LEE8A:  JSR Bank2ToNT1          ;($FCAD)Load CHR ROM bank 2 into nametable 1.
LEE8D:  JSR DoSprites           ;($B6DA)Update player and NPC sprites.
LEE90:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ModEnemyStats:
LEE91:  JSR UpdateRandNum       ;($C55B)Get random number.
LEE94:  LDA EnNumber
LEE96:  CMP #EN_STONEMAN
LEE98:  BCC $EE9F
LEE9A:  LDA RandNumUB
LEE9C:  JMP $EEC7

LEE9F:  CMP #EN_GDRAGON
LEEA1:  BCC $EEAA
LEEA3:  LDA RandNumUB
LEEA5:  AND #$7F
LEEA7:  JMP $EEC7

LEEAA:  CMP #EN_DROLLMAGI
LEEAC:  BCC $EEC0
LEEAE:  LDA RandNumUB
LEEB0:  AND #$3F
LEEB2:  STA $3E
LEEB4:  JSR UpdateRandNum       ;($C55B)Get random number.
LEEB7:  LDA RandNumUB
LEEB9:  AND #$1F
LEEBB:  ADC $3E
LEEBD:  JMP $EEC7

;----------------------------------------------------------------------------------------------------

LEEC0:  JSR UpdateRandNum       ;($C55B)Get random number.
LEEC3:  LDA RandNumUB
LEEC5:  AND #$3F

LEEC7:  STA MultNum1LB
LEEC9:  LDA EnBaseDef
LEECC:  STA MultNum2LB
LEECE:  LDA #$00
LEED0:  STA MultNum1UB
LEED2:  STA MultNum2UB
LEED4:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LEED7:  LDA MultRsltLB
LEED9:  STA $42
LEEDB:  LDA MultRsltUB
LEEDD:  STA $43
LEEDF:  JSR UpdateRandNum       ;($C55B)Get random number.
LEEE2:  LDA RandNumUB
LEEE4:  STA MultNum1LB
LEEE6:  LDA DisplayedAgi
LEEE8:  STA MultNum2LB
LEEEA:  LDA #$00
LEEEC:  STA MultNum1UB
LEEEE:  STA MultNum2UB
LEEF0:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LEEF3:  LDA MultRsltLB
LEEF5:  SEC
LEEF6:  SBC $42
LEEF8:  LDA MultRsltUB
LEEFA:  SBC $43
LEEFC:  RTS

;----------------------------------------------------------------------------------------------------

LoadEnPalette:
LEEFD:  LDA EnNumber
LEEFF:  STA MultNum1LB
LEF01:  LDA #$0C
LEF03:  STA MultNum2LB
LEF05:  LDA #$00
LEF07:  STA MultNum1UB
LEF09:  STA MultNum2UB
LEF0B:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LEF0E:  LDA MultRsltLB
LEF10:  CLC
LEF11:  ADC EnSPPalsPtr
LEF14:  STA $3C
LEF16:  LDA MultRsltUB
LEF18:  ADC EnSPPalsPtr+1
LEF1B:  STA $3D
LEF1D:  TYA
LEF1E:  PHA
LEF1F:  LDY #$0B

LEF21:  LDA ($3C),Y
LEF23:  STA $03A0,Y
LEF26:  DEY
LEF27:  BPL $EF21

LEF29:  PLA
LEF2A:  TAY
LEF2B:  LDA #$03
LEF2D:  STA $3F
LEF2F:  STA PalPtrUB
LEF31:  LDA #$A0
LEF33:  STA $3E
LEF35:  STA PalPtrLB
LEF37:  RTS

;----------------------------------------------------------------------------------------------------

PaletteFlash:
LEF38:  LDA #$05
LEF3A:  STA $DE
LEF3C:  LDA $42
LEF3E:  STA PalPtrLB
LEF40:  LDA $43
LEF42:  STA PalPtrUB
LEF44:  JSR WaitForNMI          ;($FF74)
LEF47:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LEF4A:  JSR WaitForNMI          ;($FF74)
LEF4D:  LDA #$00
LEF4F:  STA PalModByte
LEF51:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.
LEF54:  LDA EnNumber
LEF56:  CMP #EN_DRAGONLORD2
LEF58:  BNE $EF67
LEF5A:  LDA $EF9B
LEF5D:  STA PalPtrLB
LEF5F:  LDA $EF9C
LEF62:  STA PalPtrUB
LEF64:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer
LEF67:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LEF6A:  JSR WaitForNMI          ;($FF74)
LEF6D:  LDA $42
LEF6F:  PHA
LEF70:  LDA $43
LEF72:  PHA
LEF73:  JSR LoadEnPalette       ;($EEFD)Load enemy palette data.
LEF76:  PLA
LEF77:  STA $43
LEF79:  PLA
LEF7A:  STA $42
LEF7C:  LDA #$00
LEF7E:  STA PalModByte
LEF80:  JSR PrepSPPalLoad       ;($C632)Load sprite palette data into PPU buffer.
LEF83:  LDA EnNumber
LEF85:  CMP #EN_DRAGONLORD2
LEF87:  BNE $EF96
LEF89:  LDA $EF9D
LEF8C:  STA PalPtrLB
LEF8E:  LDA $EF9E
LEF91:  STA PalPtrUB
LEF93:  JSR PrepBGPalLoad       ;($C63D)Load background palette data into PPU buffer
LEF96:  DEC $DE
LEF98:  BNE $EF3C
LEF9A:  RTS

EnemyBGPalPtr:
LEF9B:  .word EnemyBGPal        ;Pointer to BG palette for regular enemies.

FnlBsBGPalPtr:
LEF9D:  .word FinalBossBGPal    ;Pointer to BG plaette for end boss.

EnemyBGPal:
LEF9F:  .byte $30, $0E, $30, $16, $16, $16, $16, $16, $16, $16, $16, $16

FinalBossBGPal:
LEFAB:  .byte $30, $0E, $30, $17, $15, $30, $21, $22, $27, $0F, $27, $27

;----------------------------------------------------------------------------------------------------

CheckEnRun:
LEFB7:  LDA DisplayedStr
LEFB9:  LSR
LEFBA:  CMP EnBaseAtt
LEFBD:  BCC $EFE4

LEFBF:  JSR UpdateRandNum       ;($C55B)Get random number.
LEFC2:  LDA RandNumUB
LEFC4:  AND #$03
LEFC6:  BNE $EFE4

LEFC8:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.

LEFCB:  LDA #SFX_RUN            ;Run away SFX.
LEFCD:  BRK                     ;
LEFCE:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEFD0:  JSR CopyEnUpperBytes    ;($DBE4)Copy enemy upper bytes to description RAM.

LEFD3:  JSR DoDialogLoBlock     ;($C7CB)The enemy is running away.
LEFD6:  .byte $E3               ;TextBlock15, entry 3.

LEFD7:  LDX MapNumber           ;Get current map number.
LEFD9:  LDA ResumeMusicTbl,X    ;Use current map number to resume music.
LEFDC:  BRK                     ;
LEFDD:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LEFDF:  PLA
LEFE0:  PLA
LEFE1:  JMP ExitFight           ;($EE54)Return to map after fight.
LEFE4:  RTS

;----------------------------------------------------------------------------------------------------

LEFE5:  LSR $43
LEFE7:  LDA $42
LEFE9:  SEC
LEFEA:  SBC $43
LEFEC:  BCC $F026
LEFEE:  CMP #$02
LEFF0:  BCS $F030
LEFF2:  BCC $F026

EnCalcHitDmg:
LEFF4:  LSR $43
LEFF6:  LDA $42
LEFF8:  LSR
LEFF9:  STA MultNum2LB
LEFFB:  INC MultNum2LB
LEFFD:  LDA $42
LEFFF:  SEC
LF000:  SBC $43
LF002:  BCC $F008

LF004:  CMP MultNum2LB
LF006:  BCS $F030

LF008:  JSR UpdateRandNum       ;($C55B)Get random number.
LF00B:  LDA RandNumUB
LF00D:  STA MultNum1LB
LF00F:  LDA #$00
LF011:  STA MultNum1UB
LF013:  STA MultNum2UB
LF015:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LF018:  LDA MultRsltUB
LF01A:  CLC
LF01B:  ADC #$02
LF01D:  STA DivNum1LB
LF01F:  LDA #$03
LF021:  STA DivNum2
LF023:  JMP ByteDivide          ;($C1F0)Divide a 16-bit number by an 8-bit number.
LF026:  JSR UpdateRandNum       ;($C55B)Get random number.
LF029:  LDA RandNumUB
LF02B:  AND #$01
LF02D:  STA DivQuotient
LF02F:  RTS

LF030:  STA $42
LF032:  STA MultNum2LB
LF034:  INC MultNum2LB
LF036:  JSR UpdateRandNum       ;($C55B)Get random number.
LF039:  LDA RandNumUB
LF03B:  STA MultNum1LB
LF03D:  LDA #$00
LF03F:  STA MultNum1UB
LF041:  STA MultNum2UB
LF043:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.
LF046:  LDA MultRsltUB
LF048:  CLC
LF049:  ADC $42
LF04B:  ROR
LF04C:  LSR
LF04D:  STA $3C
LF04F:  RTS

;----------------------------------------------------------------------------------------------------

LoadStats:
LF050:  LDX #LVL_TBL_LAST       ;Point to level 30 in LevelUpTbl.
LF052:  LDA #LVL_30             ;
LF054:  STA DisplayedLevel      ;Set displayed level to 30.

GetLevelLoop:
LF056:  LDA ExpLB               ;
LF058:  SEC                     ;
LF059:  SBC LevelUpTbl,X        ;
LF05C:  LDA ExpUB               ;Get current experience and subtract the values in LevelUpTbl -->
LF05E:  SBC LevelUpTbl+1,X      ;If the value goes negative, then the player's current level -->
LF061:  BCS LevelFound          ;has been found.  Keep looping until the player's current -->
LF063:  DEC DisplayedLevel      ;level is determined.
LF065:  DEX                     ;
LF066:  DEX                     ;
LF067:  BNE GetLevelLoop        ;

LevelFound:
LF069:  LDA DisplayedLevel      ;
LF06B:  SEC                     ;Subtract 1 from level as index into table starts at 0.
LF06C:  SBC #$01                ;

LF06E:  ASL                     ;Index*2.
LF06F:  STA LevelDatPtr         ;
LF071:  ASL                     ;Index*4.
LF072:  CLC                     ;
LF073:  ADC LevelDatPtr         ;Final table pointer = 2*(level-1)+4*(level-1).
LF075:  STA LevelDatPtr         ;6 bytes per table entry.

LF077:  LDA #$FF                ;Indicate not in VBlank.
LF079:  STA NMIStatus           ;

LF07B:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LF07E:  LDA NMIStatus           ;
LF080:  BNE -                   ;Wait for VBlank to end before continuing.

LF082:  BRK                     ;Get player's base stats for their level.
LF083:  .byte $0D, $17          ;($99B4)SetBaseStats, bank 1.

LF085:  LDX #$04                ;Prepare to get lower 4 characers of name.
LF087:  LDA #$00                ;Prepare to add their numerical values together.

NameAddLoop:
LF089:  CLC                     ;Add the 4 values of the name characters together.
LF08A:  .byte $7D, $B4, $00     ;ADC $00B4,X. Assembling as ADC $B4,X. Replaced with binary.
LF08D:  DEX                     ;Have all 4 characters been added together?
LF08E:  BNE NameAddLoop         ;If not, loop to add another one.

LF090:  STA StatBonus           ;Save off total value for later.
LF092:  AND #$03                ;
LF094:  STA StatPenalty         ;Get 2 LSBs for stat penalty calculations.

LF096:  LDA StatBonus           ;
LF098:  LSR                     ;Get bits 2 and 3 for stat bonus calculations and -->
LF099:  LSR                     ;move them to bits 0 and 1.
LF09A:  AND #$03                ;
LF09C:  STA StatBonus           ;

LF09E:  LDA StatPenalty         ;If LSB is set, penalize max MP.
LF0A0:  LSR                     ;
LF0A1:  BCS MaxMPPenalty        ;Penalize max MP? If so, branch.

LF0A3:  LDA DisplayedStr        ;Penalize strength by 10%.
LF0A5:  JSR ReduceStat          ;($F10C)Multiply stat by 9/10.
LF0A8:  STA DisplayedStr        ;

LF0AA:  JMP ChkAgiPenalty       ;Check agility, max HP penalties.

MaxMPPenalty:
LF0AD:  LDA DisplayedMaxMP      ;Only penalize MP if player has any MP to penalize.
LF0AF:  BEQ ChkAgiPenalty       ;

LF0B1:  JSR ReduceStat          ;($F10C)Multiply stat by 9/10.
LF0B4:  STA DisplayedMaxMP      ;Penalize max MP.

ChkAgiPenalty:
LF0B6:  LDA StatPenalty         ;if bit 1 is set, penalize agility.
LF0B8:  AND #$02                ;
LF0BA:  BNE MaxHPPenalty        ;Penalize max HP? If so, branch.

LF0BC:  LDA DisplayedAgi        ;Penalize agility by 10%.
LF0BE:  JSR ReduceStat          ;($F10C)Multiply stat by 9/10.
LF0C1:  STA DisplayedAgi        ;

LF0C3:  JMP AddItemBonuses      ;($F0CD)Add bonuses for player's equipped items.

MaxHPPenalty:
LF0C6:  LDA DisplayedMaxHP      ;Penalize max HP.
LF0C8:  JSR ReduceStat          ;($F10C)Multiply stat by 9/10.
LF0CB:  STA DisplayedMaxHP      ;

AddItemBonuses:
LF0CD:  LDA EqippedItems        ;Get equipped items.
LF0CF:  LSR                     ;
LF0D0:  LSR                     ;
LF0D1:  LSR                     ;Shift weapons down to lower 3 bits.
LF0D2:  LSR                     ;
LF0D3:  LSR                     ;

LF0D4:  TAX                     ;Use the 3 bits above as index into the WeaponsBonusTbl.
LF0D5:  LDA WeaponsBonusTbl,X   ;

LF0D8:  CLC                     ;
LF0D9:  ADC DisplayedStr        ;Add bonus from weapons table to strength attribute.
LF0DB:  STA DisplayedAttck      ;

LF0DD:  LDA DisplayedAgi        ;
LF0DF:  LSR                     ;Divide agility by 2 and add to defense attribute.
LF0E0:  STA DisplayedDefns      ;

LF0E2:  LDA EqippedItems        ;Get equipped armor and move to lower 3 bits.
LF0E4:  LSR                     ;
LF0E5:  LSR                     ;
LF0E6:  AND #AR_ARMOR/4         ;Remove weapon bits.

LF0E8:  TAX                     ;Use the 3 bits above as index into the ArmorBonusTbl.
LF0E9:  LDA ArmorBonusTbl,X     ;

LF0EC:  CLC                     ;
LF0ED:  ADC DisplayedDefns      ;Add bonus from armor table to defense attribute.
LF0EF:  STA DisplayedDefns      ;

LF0F1:  LDA EqippedItems        ;Mask off shield bits.
LF0F3:  AND #SH_SHIELDS         ;

LF0F5:  TAX                     ;Use the 2 bits above as index into the ShieldBonusTbl.
LF0F6:  LDA ShieldBonusTbl,X    ;

LF0F9:  CLC                     ;
LF0FA:  ADC DisplayedDefns      ;Add bonus from shield table to defense attribute.
LF0FC:  STA DisplayedDefns      ;

LF0FE:  LDA ModsnSpells         ;Is dragon's scale equipped?
LF100:  AND #F_DRGSCALE         ;
LF102:  BEQ +                   ;If not, branch to exit.

LF104:  LDA DisplayedDefns      ;
LF106:  CLC                     ;
LF107:  ADC #$02                ;Dragon's scale equipped. Add 2 to defense.
LF109:  STA DisplayedDefns      ;
LF10B:* RTS                     ;

;----------------------------------------------------------------------------------------------------

;The name of the character is critical in determining how the stats are penalized.  There are two
;pairs of stats that will always be penalized.  If a character has normal strength growth, then their
;max MP will be penalized by 10%.  The opposite is true: if a character has normal MP growth, then
;their strength will be penalized by 10%.  The other pair of stats is agility and max HP.  If agility
;has normal growth, the max HP will be penalized by 10% and vice versa.  The important thing to take
;away is that two stats will always be penalized while the other two are not.  A bonus of 0 to 3
;points will be added to the 2 penalized stats.  This gives the effect of having the penalized stat
;slightly stronger at the beginning of the game but becomes weaker as the player progresses levels.
;
;Only the first 4 letters in the name are used for the stat penalties and bonus calculations. Here
;is how it works:
;
;The numeric value of the first four letters of the name are added together.  the following
;is a list of the numeric values of the characters:
;A=$24, B=$25, C=$26, D=$27, E=$28, F=$29, G=$2A, H=$2B, I=$2C, J=$2D,
;K=$2E, L=$2F, M=$30, N=$31, O=$32, P=$33, Q=$34, R=$35, S=$36, T=$37,
;U=$38, V=$39, W=$3A, X=$3B, Y=$3C, Z=$3D, -=$49, '=$40, !=$4C, ?=$4B,
;(=$4F, )=$4E, a=0A$, b=$0B, c=$0C, d=$0D, e=$0E, f=$0F, g=$10, h=$11,
;i=$12, j=$13, k=$14, l=$15, m=$16, n=$17, o=$18, p=$19, q=$1A, r=$1B,
;s=$1C, t=$1D, u=$1E, v=$1F, w=$20, x=$21, y=$22, z=$23, ,=$48, .=$47,
;space=$60
;
;Bits 0 and 1 are used to determine the stat penalties. Bits 2 and 3 are the stats bonus.
;
;If bit 0 is clear, strength is penalized by 10%. If bit 0 is set, max MP is penalized by 10%.
;if bit 1 is clear, agility is penalized by 10%. If bit 1 is set, max HP is penalized by 10%.
;
;Bits 2 and 3 are shifted down to bits 0 and 1 and added to the penalized stats.
;
;Some examples:
;JAKE = $2D+$24+$2E+$28 = $A7. Max MP penalized, max HP penalized, +1 added to max MP, HP.
;Deez = $27+$0E+$0E+$23 = $66. Strength penalized, max HP penalized, +1 added to strength, max HP.
;
;The best combination would be to have the lowest 4 bits be 1111. This would reduce max HP and MP
;but give a bonus of 3 points to each. Strength and agility would have normal growth.

ReduceStat:
LF10C:  STA MultNum1LB          ;
LF10E:  LDA #$09                ;
LF110:  STA MultNum2LB          ;
LF112:  LDA #$00                ;Multiply stat by 9.
LF114:  STA MultNum1UB          ;
LF116:  STA MultNum2UB          ;
LF118:  JSR WordMultiply        ;($C1C9)Multiply 2 16-bit words.

LF11B:  LDA MultRsltLB          ;
LF11D:  STA DivNum1LB           ;Save results of multiplication.
LF11F:  LDA MultRsltUB          ;
LF121:  STA DivNmu1UB           ;

LF123:  LDA #$0A                ;prepare to Divide stat by 10.
LF125:  STA DivNum2             ;
LF127:  LDA #$00                ;
LF129:  STA DivNum2NU           ;
LF12B:  JSR WordDivide          ;($C1F4)Divide a 16-bit word by an 8-bit byte.
LF12E:  LDA DivQuotient         ;Net result is stat*9/10.

LF130:  CLC                     ;Add in any stat bonus that may have been calculated.
LF131:  ADC StatBonus           ;Stat bonus may be in the range of 0-3.
LF133:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetExpRemaining:
LF134:  LDA DisplayedLevel      ;Get player's current level.
LF136:  ASL                     ;*2
LF137:  TAX                     ;
LF138:  LDA LevelUpTbl,X        ;
LF13B:  SEC                     ;
LF13C:  SBC ExpLB               ;Subtract current experience from value in table-->
LF13E:  STA GenWrd00LB          ;to get remaining experience until level up.
LF140:  LDA LevelUpTbl+1,X      ;
LF143:  SBC ExpUB               ;
LF145:  STA GenWrd00UB          ;
LF147:  RTS                     ;

;----------------------------------------------------------------------------------------------------

PrepSaveGame:
LF148:  LDA #$01                ;Wait for PPU buffer to be completely empty.
LF14A:  JSR WaitForPPUBufSpace  ;($C587)Wait for space in PPU buffer.
LF14D:  JMP SaveCurrentGame     ;($F9DF)Save current game.

;----------------------------------------------------------------------------------------------------

UnusedTblPtr1:
LF150:  .word DescTbl+1         ;($F155)Unused pointer into table below.

DescTblPtr:
LF152:  .word DescTbl           ;($F154)Pointer into table below.

DescTbl:

;Unused data.
LF154:  .byte $FA
LF155:  .byte $55, $62, $FA
LF158:  .byte $41, $4E, $40, $62, $FA
LF15D:  .byte $FA
LF15E:  .byte $40, $47, $F8, $6B, $4E, $4D, $FA
LF165:  .byte $0C, $35, $14, $1C, $F8, $23, $FA
LF16C:  .byte $2F, $0C, $13, $18, $FA
LF171:  .byte $0A, $38, $19, $FA
LF175:  .byte $4C, $F8, $40, $4A, $22, $23, $0F, $FA
LF17D:  .byte $1B, $19, $0D, $1C, $11, $33, $FA
LF184:  .byte $42, $4D, $42, $4E, $40, $FA
LF18A:  .byte $31, $4D, $43, $47, $F8, $4E, $43, $FA
LF192:  .byte $28, $16, $4F, $FA
LF196:  .byte $15, $F8, $39, $4F, $FA
LF19B:  .byte $1C, $F8, $16, $0F, $60, $FA
LF1A1:  .byte $28, $16, $0F, $60, $FA
LF1A6:  .byte $13, $F8, $14, $F8, $0B, $28, $16, $4F, $FA
LF1AF:  .byte $00, $FA
LF1B1:  .byte $00, $FA

LF1B3:  .byte DSC_SCRT_PSG,      TXT_SUBEND     ;Secret passage text.
LF1B5:  .byte DSC_HEAL-$13,      TXT_SUBEND     ;Heal spell text.
LF1B7:  .byte DSC_HURT-$13,      TXT_SUBEND     ;Hurt spell text.
LF1B9:  .byte DSC_SLEEP-$13,     TXT_SUBEND     ;Sleep spell text.
LF1BB:  .byte DSC_RADIANT-$13,   TXT_SUBEND     ;Radiant spell text.
LF1BD:  .byte DSC_STOPSPELL-$13, TXT_SUBEND     ;Stopspell spell text.
LF1BF:  .byte DSC_OUTSIDE-$13,   TXT_SUBEND     ;Outside spell text.
LF1C1:  .byte DSC_RETURN-$13,    TXT_SUBEND     ;Return spell text.
LF1C3:  .byte DSC_REPEL-$13,     TXT_SUBEND     ;Repel spell text.
LF1C5:  .byte DSC_HEALMORE-$13,  TXT_SUBEND     ;Healmore spell text.
LF1C7:  .byte DSC_HURTMORE-$13,  TXT_SUBEND     ;Hurtmore spell text.

;Unused data.
LF1C9:  .byte $44, $26, $F8, $43, $FA

LF1CE:  .byte DSC_BMB_POLE,      TXT_SUBEND     ;Bamboo pole text.
LF1D0:  .byte DSC_CLUB,          TXT_SUBEND     ;Club text.
LF1D2:  .byte DSC_CPR_SWD,       TXT_SUBEND     ;Copper sword text.
LF1D4:  .byte DSC_HND_AXE,       TXT_SUBEND     ;Hand axe text.
LF1D6:  .byte DSC_BROAD_SWD,     TXT_SUBEND     ;Broad sword text.
LF1D8:  .byte DSC_FLAME_SWD,     TXT_SUBEND     ;Flame sword text.
LF1DA:  .byte DSC_ERD_SWD,       TXT_SUBEND     ;Erdrick's sword text.
LF1DC:  .byte DSC_CLOTHES,       TXT_SUBEND     ;Clothes text.
LF1DE:  .byte DSC_LTHR_ARMR,     TXT_SUBEND     ;Leather armor text.
LF1E0:  .byte DSC_CHAIN_ML,      TXT_SUBEND     ;Chain mail text.
LF1E2:  .byte DSC_HALF_PLT,      TXT_SUBEND     ;Half plate text.
LF1E4:  .byte DSC_FULL_PLT,      TXT_SUBEND     ;Full plate text.
LF1E6:  .byte DSC_MAG_ARMR,      TXT_SUBEND     ;Magic armor text.
LF1E8:  .byte DSC_ERD_ARMR,      TXT_SUBEND     ;Erdrick's armor text.
LF1EA:  .byte DSC_SM_SHLD,       TXT_SUBEND     ;Small shield text.
LF1EC:  .byte DSC_LG_SHLD,       TXT_SUBEND     ;Large shield text.
LF1EE:  .byte DSC_SLVR_SHLD,     TXT_SUBEND     ;Silver shield text.

;Unused data.
LF1F0:  .byte $3C, $5F, $5F, $25, $F8, $10, $58, $FA
LF1F8:  .byte $3C, $5F, $2F, $34, $0B, $58, $FA
LF1FF:  .byte $28, $13, $1D, $22, $5F, $FA
LF205:  .byte $41, $6B, $22, $5F, $1A, $36, $24, $11, $FA

LF20E:  .byte DSC_HERB,          TXT_SUBEND     ;Herb text.
LF210:  .byte DSC_KEY,           TXT_SUBEND     ;Magic key text.
LF212:  .byte DSC_TORCH,         TXT_SUBEND     ;Torch text.
LF214:  .byte DSC_FRY_WATER,     TXT_SUBEND     ;Fairy water text.
LF216:  .byte DSC_WINGS,         TXT_SUBEND     ;Wings text.
LF218:  .byte DSC_DRGN_SCL,      TXT_SUBEND     ;Dragon's scale text.
LF21A:  .byte DSC_FRY_FLUTE,     TXT_SUBEND     ;Fairy flute text.
LF21C:  .byte DSC_FGHTR_RNG,     TXT_SUBEND     ;Fighter's ring text.
LF21E:  .byte DSC_ERD_TKN,       TXT_SUBEND     ;Erdrick's token text.
LF220:  .byte DSC_GWLN_LOVE,     TXT_SUBEND     ;Gwaelin's love text.
LF222:  .byte DSC_CRSD_BLT,      TXT_SUBEND     ;Cursed belt text.
LF224:  .byte DSC_SLVR_HARP,     TXT_SUBEND     ;Silver harp text.
LF226:  .byte DSC_DTH_NCK,       TXT_SUBEND     ;Death necklace text.
LF228:  .byte DSC_STN_SUN,       TXT_SUBEND     ;Stones of sunlight text.
LF22A:  .byte DSC_RN_STAFF,      TXT_SUBEND     ;Staff of rain text.
LF22C:  .byte DSC_RNBW_DRP,      TXT_SUBEND     ;Rainbow drop text.

;Unused data.
LF22E:  .byte $15, $0F, $15, $FA
LF232:  .byte $15, $F8, $3A, $2C, $37, $FA
LF238:  .byte $0A, $1E, $19, $FA
LF23C:  .byte $28, $19, $F8, $FA
LF240:  .byte $18, $33, $0B, $15, $F8, $3B, $0C, $FA
LF248:  .byte $2C, $1C, $28, $17, $37, $0F, $F8, $6C, $FA
LF251:  .byte $0E, $0F, $21, $0F, $F8, $5F, $19, $31, $28, $17, $37, $0F, $F8, $6C, $FA
LF260:  .byte $1E, $1F, $0F, $FA
LF264:  .byte $1D, $F8, $33, $36, $FA
LF269:  .byte $1E, $1F, $36, $FA
LF26D:  .byte $1C, $1F, $0B, $33, $19, $FA
LF273:  .byte $29, $1B, $12, $19, $FA
LF278:  .byte $35, $19, $15, $FA
LF27C:  .byte $41, $4E, $40, $FA
LF280:  .byte $24, $2B, $FA
LF283:  .byte $1C, $F8, $16, $4F, $FA
LF288:  .byte $0A, $2B, $1D, $5F, $19, $0B, $2F, $0C, $0F, $F8, $5F, $0A, $35, $14, $32, $FA
LF298:  .byte $19, $16, $12, $19, $F8, $15, $1C, $FA
LF2A0:  .byte $13, $F8, $14, $F8, $0B, $28, $16, $FA
LF2A8:  .byte $11, $19, $F8, $14, $0B, $FA
LF2AE:  .byte $14, $28, $FA
LF2B1:  .byte $0E, $0C, $14, $28, $FA
LF2B6:  .byte $13, $13, $23, $FA
LF2BA:  .byte $18, $1E, $19, $FA
LF2BE:  .byte $0A, $30, $35, $33, $FA
LF2C3:  .byte $0F, $F8, $2F, $0B, $52, $FA
LF2C9:  .byte $1D, $F8, $0C, $0F, $FA
LF2CE:  .byte $2E, $0C, $15, $39, $FA
LF2D3:  .byte $23, $16, $F8, $FA
LF2D7:  .byte $14, $0F, $F8, $16, $FA
LF2DC:  .byte $0A, $32, $30, $15, $0B, $FA
LF2E2:  .byte $1D, $F8, $13, $0F, $1F, $FA
LF2E8:  .byte $24, $1B, $2F, $0C, $FA
LF2ED:  .byte $0E, $28, $0D, $FA
LF2F1:  .byte $0E, $15, $34, $FA
LF2F5:  .byte $25, $32, $0B, $5F, $0B, $0B, $1B, $19, $0D, $FA
LF2FF:  .byte $28, $1A, $FA
LF302:  .byte $28, $2C, $22, $19, $1A, $FA
LF308:  .byte $0A, $31, $0F, $F8, $1D, $0C, $FA
LF30F:  .byte $0F, $F8, $FA
LF312:  .byte $10, $F8, $FA
LF315:  .byte $11, $F8, $FA
LF318:  .byte $12, $F8, $FA
LF31B:  .byte $13, $F8, $FA
LF31E:  .byte $14, $F8, $FA
LF321:  .byte $15, $F8, $FA
LF324:  .byte $16, $F8, $FA
LF327:  .byte $17, $F8, $FA
LF32A:  .byte $18, $F8, $FA
LF32D:  .byte $19, $F8, $FA
LF330:  .byte $1A, $F8, $FA
LF333:  .byte $1B, $F8, $FA
LF336:  .byte $1C, $F8, $FA
LF339:  .byte $1D, $F8, $FA
LF33C:  .byte $23, $F8, $FA
LF33F:  .byte $24, $F8, $FA
LF342:  .byte $25, $F8, $FA
LF345:  .byte $26, $F8, $FA
LF348:  .byte $27, $F8, $FA
LF34B:  .byte $23, $F9, $FA
LF34E:  .byte $24, $F9, $FA
LF351:  .byte $25, $F9, $FA
LF354:  .byte $26, $F9, $FA
LF357:  .byte $27, $F9, $FA
LF35A:  .byte $FA

;----------------------------------------------------------------------------------------------------

LevelUpTbl:
LF35B:  .word $0000             ;Level 1  - 0     exp.
LF35D:  .word $0007             ;Level 2  - 7     exp.
LF35F:  .word $0017             ;Level 3  - 23    exp.
LF361:  .word $002F             ;Level 4  - 47    exp.
LF363:  .word $006E             ;Level 5  - 110   exp.
LF365:  .word $00DC             ;Level 6  - 220   exp.
LF367:  .word $01C2             ;Level 7  - 450   exp.
LF369:  .word $0320             ;Level 8  - 800   exp.
LF36B:  .word $0514             ;Level 9  - 1300  exp.
LF36D:  .word $07D0             ;Level 10 - 2000  exp.
LF36F:  .word $0B54             ;Level 11 - 2900  exp.
LF371:  .word $0FA0             ;Level 12 - 4000  exp.
LF373:  .word $157C             ;Level 13 - 5500  exp.
LF375:  .word $1D4C             ;Level 14 - 7500  exp.
LF377:  .word $2710             ;Level 15 - 10000 exp.
LF379:  .word $32C8             ;Level 16 - 13000 exp.
LF37B:  .word $3E80             ;Level 17 - 16000 exp.
LF37D:  .word $4A38             ;Level 18 - 19000 exp.
LF37F:  .word $55F0             ;Level 19 - 22000 exp.
LF381:  .word $6590             ;Level 20 - 26000 exp.
LF383:  .word $7530             ;Level 21 - 30000 exp.
LF385:  .word $84D0             ;Level 22 - 34000 exp.
LF387:  .word $9470             ;Level 23 - 38000 exp.
LF389:  .word $A410             ;Level 24 - 42000 exp.
LF38B:  .word $B3B0             ;Level 25 - 46000 exp.
LF38D:  .word $C350             ;Level 26 - 50000 exp.
LF38F:  .word $D2F0             ;Level 27 - 54000 exp.
LF391:  .word $E290             ;Level 28 - 58000 exp.
LF393:  .word $F230             ;Level 29 - 62000 exp.
LF395:  .word $FFFF             ;Level 30 - 65535 exp.

;----------------------------------------------------------------------------------------------------

;This table is used to place the combat background on the screen when a fight starts.  It lays
;the graphic blocks out in a spiral fashion.  The upper left corner of the background is considered
;coordinates 0,0.  The combat background is 14 by 14 tiles.  Each graphic block is 2x2 tiles. The
;upper nibble in the byte is the x position in the grid while the lower nibble is the y position.
;Since the first byte in the table is $66, this means the first block appears when the background
;at position 6,6 (the center of the background).  The next block appears at coordinates 6,8 (just
;below the first block).  Since each block is 2x2 tiles, they appear at even coordinates only.

CmbtBGPlcmntTbl:
LF397:  .byte $66, $68, $48, $46, $44, $64, $84, $86, $88, $8A, $6A, $4A, $2A, $28, $26, $24
LF3A7:  .byte $22, $42, $62, $82, $A2, $A4, $A6, $A8, $AA, $AC, $8C, $6C, $4C, $2C, $0C, $0A
LF3B7:  .byte $08, $06, $04, $02, $00, $20, $40, $60, $80, $A0, $C0, $C2, $C4, $C6, $C8, $CA
LF3C7:  .byte $CC 

;----------------------------------------------------------------------------------------------------

;This table contains data that links one map to another. The first byte is the current map number.
;The next two bytes are the x and y positions respectively on the current map that connect to the
;target map.  The coordinates are based on the upper left corner of the map and start at 0,0.

MapEntryTbl:
LF3C8:  .byte MAP_OVERWORLD,   $02, $02 ;Overworld(2,2)          -> Garinham(0,14).
LF3CB:  .byte MAP_OVERWORLD,   $51, $01 ;Overworld(81,1)         -> Staff of rain cave(4,9).
LF3CD:  .byte MAP_OVERWORLD,   $68, $0A ;Overworld(104,10)       -> Koll(19,23).
LF3D1:  .byte MAP_OVERWORLD,   $30, $29 ;Overworld(48,41)        -> Brecconary(0,15).
LF3D4:  .byte MAP_OVERWORLD,   $2B, $2B ;Overworld(43,43)        -> Tant castle GF(11,29).
LF3D7:  .byte MAP_OVERWORLD,   $68, $2C ;Overworld(104,44)       -> Swamp cave(0,0).
LF3DA:  .byte MAP_OVERWORLD,   $30, $30 ;Overworld(48,48)        -> DL castle GF(10,19).
LF3DD:  .byte MAP_OVERWORLD,   $68, $31 ;Overworld(104,49)       -> Swamp cave(0,29).
LF3E0:  .byte MAP_OVERWORLD,   $1D, $39 ;Overworld(29,57)        -> Rock mtn B1(0,7).
LF3E3:  .byte MAP_OVERWORLD,   $66, $48 ;Overworld(102,72)       -> Rimuldar(29,14).
LF3E6:  .byte MAP_OVERWORLD,   $19, $59 ;Overworld(25,89)        -> Hauksness(0,10).
LF3E9:  .byte MAP_OVERWORLD,   $49, $66 ;Overworld(73,102)       -> Cantlin(15,0).
LF3EC:  .byte MAP_OVERWORLD,   $6C, $6D ;Overworld(108,109)      -> Rnbw drp cave(0,4).
LF3EF:  .byte MAP_OVERWORLD,   $1C, $0C ;Overworld(28,12)        -> Erdrick cave B1(0,0).
LF3F2:  .byte MAP_DLCSTL_GF,   $0A, $01 ;DL castle GF(10,1)      -> DL castle SL1(9,0).
LF3F5:  .byte MAP_DLCSTL_GF,   $04, $0E ;DL castle GF(4,14)      -> DL castle SL1(8,13).
LF3F8:  .byte MAP_DLCSTL_GF,   $0F, $0E ;DL castle GF(15,14)     -> DL castle SL1(17,15).
LF3FB:  .byte MAP_TANTCSTL_GF, $1D, $1D ;Tant castle GF(29,29)   -> Tant castle SL(0,4).
LF3FE:  .byte MAP_THRONEROOM,  $08, $08 ;Throneroom(8,8)         -> Tant castle GF(7,7).
LF401:  .byte MAP_GARINHAM,    $13, $00 ;Garinham(19,0)          -> Garinham cave B1(6,11).
LF404:  .byte MAP_DLCSTL_SL1,  $0F, $01 ;DL castle SL1(15,1)     -> DL castle SL2(8,0).
LF407:  .byte MAP_DLCSTL_SL1,  $0D, $07 ;DL castle SL1(13,7)     -> DL castle SL2(4,4).
LF40A:  .byte MAP_DLCSTL_SL1,  $13, $07 ;DL castle SL1(19,7)     -> DL castle SL2(9,8).
LF40D:  .byte MAP_DLCSTL_SL1,  $0E, $09 ;DL castle SL1(14,9)     -> DL castle SL2(8,9).
LF410:  .byte MAP_DLCSTL_SL1,  $02, $0E ;DL castle SL1(2,14)     -> DL castle SL2(0,1).
LF413:  .byte MAP_DLCSTL_SL1,  $02, $04 ;DL castle SL1(2,4)      -> DL castle SL2(0,0).
LF416:  .byte MAP_DLCSTL_SL1,  $08, $13 ;DL castle SL1(8,19)     -> DL castle SL2(5,0).
LF419:  .byte MAP_DLCSTL_SL2,  $03, $00 ;DL castle SL2(3,0)      -> DL castle SL3(7,0).
LF41C:  .byte MAP_DLCSTL_SL2,  $09, $01 ;DL castle SL2(9,1)      -> DL castle SL3(2,2).
LF41F:  .byte MAP_DLCSTL_SL2,  $00, $08 ;DL castle SL2(0,8)      -> DL castle SL3(5,4).
LF422:  .byte MAP_DLCSTL_SL2,  $01, $09 ;DL castle SL2(1,9)      -> DL castle SL3(0,9).
LF425:  .byte MAP_DLCSTL_SL3,  $01, $06 ;DL castle SL3(1,6)      -> DL castle SL4(0,9).
LF428:  .byte MAP_DLCSTL_SL3,  $07, $07 ;DL castle SL3(7,7)      -> DL castle SL4(7,7).
LF42B:  .byte MAP_DLCSTL_SL4,  $02, $02 ;DL castle SL4(2,2)      -> DL castle SL5(9,0).
LF42E:  .byte MAP_DLCSTL_SL4,  $08, $01 ;DL castle SL4(8,1)      -> DL castle SL5(4,0).
LF431:  .byte MAP_DLCSTL_SL5,  $05, $05 ;DL castle SL5(5,5)      -> DL castle SL6(0,0).
LF434:  .byte MAP_DLCSTL_SL5,  $00, $00 ;DL castle SL5(0,0)      -> DL castle SL6(0,6).
LF437:  .byte MAP_DLCSTL_SL6,  $09, $00 ;DL castle SL6(9,0)      -> DL castle SL6(0,0).
LF43A:  .byte MAP_DLCSTL_SL6,  $09, $06 ;DL castle SL6(9,6)      -> DL castle BF(10,29).
LF43D:  .byte MAP_RCKMTN_B1,   $00, $00 ;Rock mtn B1(0,0)        -> Rock mtn B2(0,0).
LF440:  .byte MAP_RCKMTN_B1,   $06, $05 ;Rock mtn B1(6,5)        -> Rock mtn B2(6,5).
LF443:  .byte MAP_RCKMTN_B1,   $0C, $0C ;Rock mtn B1(12,12)      -> Rock mtn B2(12,12).
LF446:  .byte MAP_CVGAR_B1,    $01, $12 ;Garinham cave B1(1,18)  -> Garinham cave B2(11,2).
LF449:  .byte MAP_CVGAR_B2,    $01, $01 ;Garinham cave B2(1,1)   -> Garinham cave B3(14,1).
LF44C:  .byte MAP_CVGAR_B2,    $0C, $01 ;Garinham cave B2(12,1)  -> Garinham cave B3(18,1).
LF44F:  .byte MAP_CVGAR_B2,    $05, $06 ;Garinham cave B2(5,6)   -> Garinham cave B3(6,11).
LF452:  .byte MAP_CVGAR_B2,    $01, $0A ;Garinham cave B2(1,10)  -> Garinham cave B3(2,17).
LF455:  .byte MAP_CVGAR_B2,    $0C, $0A ;Garinham cave B2(12,10) -> Garinham cave B3(18,13).
LF458:  .byte MAP_CVGAR_B3,    $09, $05 ;Garinham cave B3(9,5)   -> Garinham cave B4(0,4).
LF45B:  .byte MAP_CVGAR_B3,    $0A, $09 ;Garinham cave B3(10,9)  -> Garinham cave B4(5,4).
LF45D:  .byte MAP_ERDRCK_B1,   $09, $09 ;Erdrick cave B1(9,9)    -> Erdrick cave B2(8,9).

;This table is the same size as the table above and each entry is the destination from the exits
;above. Entry 1 in the table above corresponds to entry 1 in the table below. Stairs up use this
;table for the current map and use the table above for the destination.

MapTargetTbl:
LF461:  .byte MAP_GARINHAM,    $00, $0E ;Garinham(0,14)          <- Overworld(2,2)
LF465:  .byte MAP_RAIN,        $04, $09 ;Staff of rain cave(4,9) <- Overworld(81,1).
LF467:  .byte MAP_KOL,         $13, $17 ;Koll(19,23)             <- Overworld(104,10).
LF46A:  .byte MAP_BRECCONARY,  $00, $0F ;Brecconary(0,15)        <- Overworld(48,41).
LF46D:  .byte MAP_TANTCSTL_GF, $0B, $1D ;Tant castle GF(11,29)   <- Overworld(43,43).
LF471:  .byte MAP_SWAMPCAVE,   $00, $00 ;Swamp cave(0,0)         <- Overworld(104,44).
LF473:  .byte MAP_DLCSTL_GF,   $0A, $13 ;DL castle GF(10,19)     <- Overworld(48,48).
LF476:  .byte MAP_SWAMPCAVE,   $00, $1D ;Swamp cave(0,29)        <- Overworld(104,49).
LF479:  .byte MAP_RCKMTN_B1,   $00, $07 ;Rock mtn B1(0,7)        <- Overworld(29,57).
LF47C:  .byte MAP_RIMULDAR,    $1D, $0E ;Rimuldar(29,14)         <- Overworld(102,72).
LF47E:  .byte MAP_HAUKSNESS,   $00, $0A ;Hauksness(0,10)         <- Overworld(25,89).
LF482:  .byte MAP_CANTLIN,     $0F, $00 ;Cantlin(15,0)           <- Overworld(73,102).
LF485:  .byte MAP_RAINBOW,     $00, $04 ;Rnbw drp cave(0,4)      <- Overworld(108,109).
LF488:  .byte MAP_ERDRCK_B1,   $00, $00 ;Erdrick cave B1(0,0)    <- Overworld(28,12).
LF48B:  .byte MAP_DLCSTL_SL1,  $09, $00 ;DL castle SL1(9,0)      -> DL castle GF(10,1).
LF48E:  .byte MAP_DLCSTL_SL1,  $08, $0D ;DL castle SL1(8,13)     -> DL castle GF(4,14).
LF491:  .byte MAP_DLCSTL_SL1,  $11, $0F ;DL castle SL1(17,15)    -> DL castle GF(15,14).
LF494:  .byte MAP_TANTCSTL_SL, $00, $04 ;Tant castle SL(0,4)     -> Tant castle GF(29,29).
LF497:  .byte MAP_TANTCSTL_GF, $07, $07 ;Tant castle GF(7,7)     -> Throneroom(8,8).
LF49A:  .byte MAP_CVGAR_B1,    $06, $0B ;Garinham cave B1(6,11)  -> Garinham(19,0).
LF49D:  .byte MAP_DLCSTL_SL2,  $08, $00 ;DL castle SL2(8,0)      -> DL castle SL1(15,1).
LF4A0:  .byte MAP_DLCSTL_SL2,  $04, $04 ;DL castle SL2(4,4)      -> DL castle SL1(13,7).
LF4A3:  .byte MAP_DLCSTL_SL2,  $09, $08 ;DL castle SL2(9,8)      -> DL castle SL1(19,7).
LF4A6:  .byte MAP_DLCSTL_SL2,  $08, $09 ;DL castle SL2(8,9)      -> DL castle SL1(14,9).
LF4A9:  .byte MAP_DLCSTL_SL2,  $00, $01 ;DL castle SL2(0,1)      -> DL castle SL1(2,14).
LF4AC:  .byte MAP_DLCSTL_SL2,  $00, $00 ;DL castle SL2(0,0)      -> DL castle SL1(2,4).
LF4AF:  .byte MAP_DLCSTL_SL2,  $05, $00 ;DL castle SL2(5,0)      -> DL castle SL1(8,19).
LF4B2:  .byte MAP_DLCSTL_SL3,  $07, $00 ;DL castle SL3(7,0)      -> DL castle SL2(3,0).
LF4B5:  .byte MAP_DLCSTL_SL3,  $02, $02 ;DL castle SL3(2,2)      -> DL castle SL2(9,1).
LF4B8:  .byte MAP_DLCSTL_SL3,  $05, $04 ;DL castle SL3(5,4)      -> DL castle SL2(0,8).
LF4BB:  .byte MAP_DLCSTL_SL3,  $00, $09 ;DL castle SL3(0,9)      -> DL castle SL2(1,9).
LF4BE:  .byte MAP_DLCSTL_SL4,  $00, $09 ;DL castle SL4(0,9)      -> DL castle SL3(1,6).
LF4C1:  .byte MAP_DLCSTL_SL4,  $07, $07 ;DL castle SL4(7,7)      -> DL castle SL3(7,7).
LF4C4:  .byte MAP_DLCSTL_SL5,  $09, $00 ;DL castle SL5(9,0)      -> DL castle SL4(2,2).
LF4C7:  .byte MAP_DLCSTL_SL5,  $04, $00 ;DL castle SL5(4,0)      -> DL castle SL4(8,1).
LF4CA:  .byte MAP_DLCSTL_SL6,  $00, $00 ;DL castle SL6(0,0)      -> DL castle SL5(5,5).
LF4CD:  .byte MAP_DLCSTL_SL6,  $00, $06 ;DL castle SL6(0,6)      -> DL castle SL5(0,0).
LF4D0:  .byte MAP_DLCSTL_SL6,  $00, $00 ;DL castle SL6(0,0)      -> DL castle SL6(9,0).
LF4D3:  .byte MAP_DLCSTL_BF,   $0A, $1D ;DL castle BF(10,29)     -> DL castle SL6(9,6).
LF4F6:  .byte MAP_RCKMTN_B2,   $00, $00 ;Rock mtn B2(0,0)        -> Rock mtn B1(0,0).
LF4D9:  .byte MAP_RCKMTN_B2,   $06, $05 ;Rock mtn B2(6,5)        -> Rock mtn B1(6,5).
LF4DC:  .byte MAP_RCKMTN_B2,   $0C, $0C ;Rock mtn B2(12,12)      -> Rock mtn B1(12,12).
LF4DF:  .byte MAP_CVGAR_B2,    $0B, $02 ;Garinham cave B2(11,2)  -> Garinham cave B1(1,18).
LF4E2:  .byte MAP_CVGAR_B3,    $0E, $01 ;Garinham cave B3(14,1)  -> Garinham cave B2(1,1).
LF4E5:  .byte MAP_CVGAR_B3,    $12, $01 ;Garinham cave B3(18,1)  -> Garinham cave B2(12,1).
LF4E8:  .byte MAP_CVGAR_B3,    $06, $0B ;Garinham cave B3(6,11)  -> Garinham cave B2(5,6).
LF4EB:  .byte MAP_CVGAR_B3,    $02, $11 ;Garinham cave B3(2,17)  -> Garinham cave B2(1,10).
LF4EE:  .byte MAP_CVGAR_B3,    $12, $0D ;Garinham cave B3(18,13) -> Garinham cave B2(12,10).
LF4F1:  .byte MAP_CVGAR_B4,    $00, $04 ;Garinham cave B4(0,4)   -> Garinham cave B3(9,5).
LF4F4:  .byte MAP_CVGAR_B4,    $05, $04 ;Garinham cave B4(5,4)   -> Garinham cave B3(10,9).
LF4F7:  .byte MAP_ERDRCK_B2,   $08, $09 ;Erdrick cave B2(8,9)    -> Erdrick cave B1(9,9).

;----------------------------------------------------------------------------------------------------

;The following table is used during the random fight generation to determine if the player is
;strong enought to repel an enemy when the repel spell is active.  each entry in the table
;corresponds to an enemy and the index is the same as the enemy number. We can call each entry
;in the table the enemy's RepelVal.  The formula for figuring out if repel will work is as
;follows: IF [RepelVal - DisplayedDefns/2 < 0] OR [RepelVal/2 < (RepelVal - DisplayedDefns/2)]
;Then repel will be successful.

RepelTbl:
LF4FA:  .byte $05, $07, $09, $0B, $0B, $0E, $12, $14, $12, $18, $16, $1C, $1C, $24, $28, $2C
LF50A:  .byte $0A, $28, $32, $2F, $34, $38, $3C, $44, $78, $30, $4C, $4E, $4F, $56, $58, $56
LF51A:  .byte $50, $5E, $62, $64, $69, $78, $5A, $8C

;The following table dictates which random encounters occur in which part of the overworld map.
;The map is divided into an 8X8 grid.  Each nibble from the table below corresponds to a grid.
;The nibble corresponds to a row in the EnemyGroupsTbl below.

OvrWrldEnGrid:
LF522:  .byte $33, $22, $35, $45
LF526:  .byte $32, $12, $33, $45
LF52A:  .byte $41, $00, $23, $45
LF52E:  .byte $51, $1C, $66, $66
LF532:  .byte $55, $4C, $97, $77
LF536:  .byte $A9, $8C, $CC, $87
LF53A:  .byte $AA, $BC, $DD, $98
LF53E:  .byte $BB, $CD, $DC, $99

;The following table dictates what random encounters will happen in the dungeons. The indexes
;into the table correspond to the order of the caves starting with map number #$0F and ending
;with map number #$1B. Each byte corresponds to a row in the EnemyGroupsTbl below.

CaveEnIndexTbl:
LF542:  .byte $10, $11, $11, $11, $12, $12, $13, $13, $0E, $0E, $07, $0F, $0F

;The following table controls the random enemy encounters.  Each dungeon or zone on the overworld
;map can have up to 5 different enemies to encounter.  Each row in the table represents those
;enemies.  The first 14 rows are the overworld enemies and correspond to nibbles in the
;OvrWrldEnGrid table.  The remaining entries are for the various dungeons as described above.

EnemyGroupsTbl:
LF54F:  .byte EN_SLIME,       EN_RSLIME,      EN_SLIME,       EN_RSLIME,      EN_SLIME
LF554:  .byte EN_RSLIME,      EN_SLIME,       EN_RSLIME,      EN_DRAKEE,      EN_RSLIME
LF559:  .byte EN_SLIME,       EN_GHOST,       EN_DRAKEE,      EN_GHOST,       EN_RSLIME
LF55E:  .byte EN_RSLIME,      EN_RSLIME,      EN_DRAKEE,      EN_GHOST,       EN_MAGICIAN
LF563:  .byte EN_GHOST,       EN_MAGICIAN,    EN_MAGIDRAKE,   EN_MAGIDRAKE,   EN_SCORPION
LF568:  .byte EN_GHOST,       EN_MAGICIAN,    EN_MAGIDRAKE,   EN_SCORPION,    EN_SKELETON
LF56D:  .byte EN_MAGIDRAKE,   EN_SCORPION,    EN_SKELETON,    EN_WARLOCK,     EN_WOLF
LF572:  .byte EN_SKELETON,    EN_WARLOCK,     EN_MSCORPION,   EN_WOLF,        EN_WOLF
LF577:  .byte EN_MSCORPION,   EN_WRAITH,      EN_WOLFLORD,    EN_WOLFLORD,    EN_GOLDMAN
LF57C:  .byte EN_WRAITH,      EN_WYVERN,      EN_WOLFLORD,    EN_WYVERN,      EN_GOLDMAN
LF581:  .byte EN_WYVERN,      EN_RSCORPION,   EN_WKNIGHT,     EN_KNIGHT,      EN_DKNIGHT
LF586:  .byte EN_WKNIGHT,     EN_KNIGHT,      EN_MAGIWYVERN,  EN_DKNIGHT,     EN_MSLIME
LF58B:  .byte EN_KNIGHT,      EN_MAGIWYVERN,  EN_DKNIGHT,     EN_WEREWOLF,    EN_STARWYVERN
LF590:  .byte EN_WEREWOLF,    EN_GDRAGON,     EN_STARWYVERN,  EN_STARWYVERN,  EN_WIZARD

;These are dungeon enemy zones.
LF595:  .byte EN_POLTERGEIST, EN_DROLL,       EN_DRAKEEMA,    EN_SKELETON,    EN_WARLOCK
LF59A:  .byte EN_SPECTER,     EN_WOLFLORD,    EN_DRUINLORD,   EN_DROLLMAGI,   EN_WKNIGHT
LF59F:  .byte EN_WEREWOLF,    EN_GDRAGON,     EN_STARWYVERN,  EN_WIZARD,      EN_AXEKNIGHT
LF5A4:  .byte EN_WIZARD,      EN_AXEKNIGHT,   EN_BDRAGON,     EN_BDRAGON,     EN_STONEMAN
LF5A9:  .byte EN_WIZARD,      EN_STONEMAN,    EN_ARMORKNIGHT, EN_ARMORKNIGHT, EN_RDRAGON
LF5AE:  .byte EN_GHOST,       EN_MAGICIAN,    EN_SCORPION,    EN_DRUIN,       EN_DRUIN

;----------------------------------------------------------------------------------------------------

GFXTilesPtr:
LF5B3:  .word GFXTilesTbl               ;Pointer to table below.

GFXTilesTbl:
LF5B5:  .byte $A0, $A0, $A0, $A0, $02   ;Grass.                                     Block $00
LF5BA:  .byte $A1, $A1, $A1, $A1, $03   ;Sand.                                      Block $01
LF5BF:  .byte $A2, $A3, $A4, $A5, $03   ;Hill.                                      Block $02
LF5C4:  .byte $73, $74, $75, $76, $01   ;Stairs up.                                 Block $03
LF5C9:  .byte $77, $77, $77, $77, $01   ;Bricks.                                    Block $04
LF5CE:  .byte $7B, $7C, $7D, $7E, $01   ;Stairs down.                               Block $05
LF5D3:  .byte $81, $81, $81, $81, $02   ;Swamp.                                     Block $06
LF5D8:  .byte $82, $83, $84, $85, $00   ;Town                                       Block $07
LF5DD:  .byte $86, $87, $88, $89, $01   ;Cave.                                      Block $08
LF5E2:  .byte $8A, $8B, $8C, $8D, $00   ;Castle.                                    Block $09
LF5E7:  .byte $9B, $9C, $9D, $9E, $00   ;Bridge.                                    Block $0A
LF5EC:  .byte $7F, $7F, $80, $80, $02   ;Trees.                                     Block $0B
LF5F1:  .byte $F8, $FA, $F9, $FB, $01   ;Treasure chest.                            Block $0C
LF5F6:  .byte $8E, $8E, $8E, $8E, $03   ;Force field.                               Block $0D
LF5FB:  .byte $F7, $F3, $6D, $6E, $02   ;Large tile.                                Block $0E
LF600:  .byte $F6, $A8, $A8, $F6, $00   ;Water - no shore.                          Block $0F
LF605:  .byte $6F, $70, $71, $72, $01   ;Stone block.                               Block $10
LF60A:  .byte $8F, $90, $91, $92, $01   ;Door.                                      Block $11
LF60F:  .byte $A6, $A7, $F4, $F5, $01   ;Mountain.                                  Block $12
LF614:  .byte $93, $94, $95, $96, $01   ;Weapon shop sign.                          Block $13
LF619:  .byte $97, $98, $99, $9A, $01   ;Inn sign.                                  Block $14
LF61E:  .byte $9F, $9F, $9F, $9F, $01   ;Small tiles.                               Block $15
LF623:  .byte $5F, $5F, $5F, $5F, $01   ;Black square.                              Block $16
LF628:  .byte $A9, $AB, $AA, $AC, $01   ;Princess Gwaelin.                          Block $17
LF62D:  .byte $46, $4A, $A8, $F6, $00   ;Water - shore at top.                      Block $18
LF632:  .byte $5A, $A8, $5B, $F6, $00   ;Water - shore at left.                     Block $19
LF637:  .byte $5E, $4A, $5B, $F6, $00   ;Water - shore at top, left.                Block $1A
LF63C:  .byte $F6, $5C, $A8, $5D, $00   ;Water - shore at right.                    Block $1B
LF641:  .byte $46, $6A, $A8, $5D, $00   ;Water - shore at top, right.               Block $1C
LF646:  .byte $5A, $5C, $5B, $5D, $00   ;Water - shore at left, right.              Block $1D
LF64B:  .byte $5E, $6A, $5B, $5D, $00   ;Water - shore at top, left, right.         Block $1E
LF650:  .byte $F6, $A8, $58, $59, $00   ;Water - shore at bottom.                   Block $1F
LF655:  .byte $46, $4A, $58, $59, $00   ;Water - shore at top, bottom.              Block $20
LF65A:  .byte $5A, $A8, $6B, $59, $00   ;Water - shore at left, bottom.             Block $21
LF65F:  .byte $5E, $4A, $6B, $59, $00   ;Water - shore at top, left, bottom.        Block $22
LF664:  .byte $F6, $5C, $58, $6C, $00   ;Water - shore at right, bottom.            Block $23
LF669:  .byte $46, $6A, $58, $6C, $00   ;Water - shore at top, right, bottom.       Block $24
LF66E:  .byte $5A, $5C, $6B, $6C, $00   ;Water - shore at left, right and bottom.   Block $25
LF673:  .byte $5E, $6A, $6B, $6C, $00   ;Water - shore at all sides.                Block $26

;----------------------------------------------------------------------------------------------------

LoadSaveMenus:
LF678:  JSR ShowStartGame       ;($F842)Show initial windows for managing saved games.
LF67B:  LDX SaveNumber          ;
LF67E:  LDA StartStatus1,X      ;Get start status for selected game.
LF681:  STA ThisStrtStat        ;
LF684:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndLoadGameDat:
LF685:  LDA SaveSelected        ;Get selected saved game.
LF688:  JSR Copy100Times        ;($FAC1)Make up to 100 copies of saved game to validate.
LF68B:  JSR GetPlayerStatPtr    ;($C156)Get pointer to player's level base stats.
LF68E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

SGZeroStats:
LF68F:  LDA #$00                ;
LF691:  STA ExpLB               ;
LF693:  STA ExpUB               ;
LF695:  STA GoldLB              ;
LF697:  STA GoldUB              ;
LF699:  STA InventorySlot12     ;
LF69B:  STA InventorySlot34     ;
LF69D:  STA InventorySlot56     ;
LF69F:  STA InventorySlot78     ;
LF6A1:  STA InventoryKeys       ;
LF6A3:  STA InventoryHerbs      ;Zero out all the character's data as a new game is starting.
LF6A5:  STA EqippedItems        ;
LF6A7:  STA ModsnSpells         ;
LF6A9:  STA PlayerFlags         ;
LF6AB:  STA StoryFlags          ;
LF6AD:  STA HitPoints           ;
LF6AF:  STA MagicPoints         ;
LF6B1:  LDX SaveNumber          ;
LF6B4:  LDA #STRT_FULL_HP       ;
LF6B6:  STA StartStatus1,X      ;
LF6B9:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CopyGame:
LF6BA:  LDA OpnSltSelected      ;Prepare to get address of target game slot.
LF6BD:  JSR GetSaveGameBase     ;($FC00)Get base address of target game slot data.

LF6C0:  LDA GameDatPtrLB        ;
LF6C2:  STA RAMTrgtPtrLB        ;Set target pointer to target game slot.
LF6C4:  LDA GameDatPtrUB        ;
LF6C6:  STA RAMTrgtPtrUB        ;

LF6C8:  LDA SaveNumber          ;Prepare to get address of source game slot.
LF6CB:  JSR GetSaveGameBase     ;($FC00)Get base address of source game slot data.

LF6CE:  LDY #$00                ;Need to copy a total of 320 bytes(32*10).
LF6D0:* LDA (GameDatPtr),Y      ;Copy data byte from source to target.
LF6D2:  STA (RAMTrgtPtr),Y      ;
LF6D4:  DEY                     ;Have the first 256 bytes been copied?
LF6D5:  BNE -                   ;If not, branch to copy another byte.

LF6D7:  LDX GameDatPtrUB        ;
LF6D9:  INX                     ;
LF6DA:  STX GameDatPtrUB        ;Increment upper byte of source and target addresses.
LF6DC:  LDX RAMTrgtPtrUB        ;
LF6DE:  INX                     ;
LF6DF:  STX RAMTrgtPtrUB        ;

LF6E1:* LDA (GameDatPtr),Y      ;Copy final 64 bytes of save game data.
LF6E3:  STA (RAMTrgtPtr),Y      ;Copy data byte from source to target.
LF6E5:  INY                     ;
LF6E6:  CPY #$40                ;Have 64 bytes been copied?
LF6E8:  BNE -                   ;If not, branch to copy another byte.

LF6EA:  LDA OpnSltSelected      ;Set the newly created game slot as a valid save game slot.
LF6ED:  STA SaveNumber          ;
LF6F0:  JSR CreateNewSave       ;($F7DA)Prep save game slot.
LF6F3:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetValidSaves:
LF6F4:  LDX #$09                ;Prepare to check for Ken Masuta's name in battery backed RAM.
LF6F6:* LDA KenMasuta1,X        ;
LF6F9:  CMP KenMasutaTbl,X      ;Check if Ken's name is intact in the battery backed RAM.
LF6FC:  BNE InitSaves           ;Is the name correct? If not, branch to invalidae all saved games.
LF6FE:  DEX                     ;Have all 9 characters of ken's name been checked in RAM?
LF6FF:  BPL -                   ;If not, branch to verify another character.

LF701:  JMP WriteKenStrings     ;($F753)Write "Ken Masuta" to RAM to validate memory.

InitSaves:
LF704:  LDX #$09                ;Prepare to check for Ken Masuta's name in battery backed RAM.
LF706:* LDA KenMasuta2,X        ;

LF709:  CMP KenMasutaTbl,X      ;Does the character in RAM match the ROM table?
LF70C:  BNE ClearSaveGameRAM    ;If not, RAM values are corrupt. Branch to rease saved games.

LF70E:  DEX                     ;Done comparing entire Ken Masuta string?
LF70F:  BPL -                   ;If not, branch to check next byte in string.

LF711:  BMI WriteKenStrings     ;Battery backed RAM integrity checks out. Rewrite Ken string.

ClearSaveGameRAM:
LF713:  INC Unused6435          ;
LF716:  LDA #$00                ;Initialize variables used for clearing game data.
LF718:  LDX #$00                ;

LF71A:* STA SavedGame1,X        ;Clear first 256 bytes of save game data for all slots.
LF71D:  STA SavedGame2,X        ;
LF720:  STA SavedGame3,X        ;
LF723:  DEX                     ;Are 256 bytes cleared?
LF724:  BNE -                   ;If not, branch to clear more bytes.

LF726:  LDX #$00                ;Clear remaining 64 bytes of save game data for all slots.
LF728:* STA SavedGame1+$100,X   ;
LF72B:  STA SavedGame2+$100,X   ;
LF72E:  STA SavedGame3+$100,X   ;
LF731:  INX                     ;
LF732:  CPX #$40                ;Are 64 bytes cleared?
LF734:  BCC -                   ;If not, branch to clear more bytes.

LF736:  LDA #$00                ;
LF738:  STA ValidSave1          ;
LF73B:  STA ValidSave2          ;
LF73E:  STA ValidSave3          ;
LF741:  STA StartStatus1        ;Clear various save game variables.
LF744:  STA StartStatus2        ;
LF747:  STA StartStatus3        ;
LF74A:  STA CRCFail1            ;
LF74D:  STA CRCFail2            ;
LF750:  STA CRCFail3            ;

WriteKenStrings:
LF753:  LDX #$09                ;Write Ken Masuta's name to 2 different RAM locations.
LF755:* LDA KenMasutaTbl,X      ;
LF758:  STA KenMasuta1,X        ;
LF75B:  STA KenMasuta2,X        ;
LF75E:  DEX                     ;Have all bytes of his name been written?
LF75F:  BPL -                   ;If not, branch to write the next byte.

LF761:  LDA #$00                ;Clear saved game bit mask and manually revalidate.
LF763:  STA SaveBitMask         ;
LF766:  JSR VerifyValidSaves    ;($F7B5)Update saved game bit mask to match ValidSave variables.

LF769:  LDA SaveBitMask         ;Make a copy of valid saved games bitmask.
LF76C:  STA OpnSltSelected      ;

LF76F:  LDA #$02                ;Prepare to check all 3 saved games.
LF771:  STA SaveGameCntr        ;

LF774:  LDA #$00                ;Start at saved game 1.
LF776:  STA SaveNumber          ;

CheckValidSlot:
LF779:  LSR OpnSltSelected      ;Does the current saved game slot contain a saved game?
LF77C:  BCC DoneValidateSave    ;If not, branch to check the next slot.

LF77E:  LDA SaveNumber          ;Prepare to test the RAM for the selected save slot.
LF781:  JSR Copy100Times        ;($FAC1)Make up to 100 copies of saved game to validate.
LF784:  CMP #$00                ;Is RAM for saved game valid?
LF786:  BEQ DoneValidateSave    ;If so, branch to check next saved game.

LF788:  LDA SaveNumber          ;Saved game RAM was corrupted. Erase game.
LF78B:  JSR ClearValidSaves     ;($F80F)Clear ValidSave variable for selected game.

LF78E:  JSR Dowindow            ;($C6F0)display on-screen window.
LF791:  .byte WND_DIALOG        ;Dialog window.

LF792:  LDA SaveNumber          ;
LF795:  CLC                     ;
LF796:  ADC #$01                ;Save number of failed saved game slots found.
LF798:  STA GenWrd00LB          ;Seems to have no effect.
LF79A:  LDA #$00                ;
LF79C:  STA GenWrd00UB          ;

LF79E:  JSR DoDialogHiBlock     ;($C7C5)Unfortunately no deeds were recorded...
LF7A1:  .byte $29               ;TextBlock19, entry 9.

LF7A2:  LDA #$1E                ;Prepare to wait 30 frames(1/2 second).
LF7A4:  JSR WaitMultiNMIs       ;($C170)Wait a dfined number of frames.

LF7A7:  LDA #$02                ;Prepare to remove the dialog window.

LF7A9:  BRK                     ;Remove window from screen.
LF7AA:  .byte $05, $07          ;($A7A2)RemoveWindow, bank 0.

DoneValidateSave:
LF7AC:  INC SaveNumber          ;Move to next saved game.
LF7AF:  DEC SaveGameCntr        ;Have all 3 game slots been checked?
LF7B2:  BPL CheckValidSlot      ;If not, branch to check the next one.
LF7B4:  RTS                     ;

;----------------------------------------------------------------------------------------------------

VerifyValidSaves:
LF7B5:  TXA                     ;Save X on stack.
LF7B6:  PHA                     ;

LF7B7:  LDA #$00                ;Assume no valid save games.
LF7B9:  LDX ValidSave1          ;
LF7BC:  CPX #$C8                ;Is valid byte value correct for saved game 1?
LF7BE:  BNE ChkBitMask2         ;If not, branch to check saved game 2.

LF7C0:  ORA #$01                ;Set game 1 as a valid save game.

ChkBitMask2:
LF7C2:  LDX ValidSave2          ;Is valid byte value correct for saved game 2?
LF7C5:  CPX #$C8                ;
LF7C7:  BNE ChkBitMask3         ;If not, branch to check saved game 3.

LF7C9:  ORA #$02                ;Set game 2 as a valid save game.

ChkBitMask3:
LF7CB:  LDX ValidSave3          ;Is valid byte value correct for saved game 3?
LF7CE:  CPX #$C8                ;
LF7D0:  BNE UpdtSaveBitMask     ;If not, branch to save saved games bit masks.

LF7D2:  ORA #$04                ;Set game 3 as a valid save game.

UpdtSaveBitMask:
LF7D4:  STA SaveBitMask         ;Save bit mask for valid saved games.

LF7D7:  PLA                     ;
LF7D8:  TAX                     ;Restore X from stack and return.
LF7D9:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CreateNewSave:
LF7DA:  PHA                     ;
LF7DB:  TXA                     ;Save A and X on the stack.
LF7DC:  PHA                     ;

LF7DD:  LDA SaveBitMask         ;Get save bit mask and save number.
LF7E0:  LDX SaveNumber          ;
LF7E3:  BEQ SaveAtSlot1         ;Save slot 1? If so, branch to create.

LF7E5:  CPX #$01                ;
LF7E7:  BEQ SaveAtSlot2         ;Save slot 2? If so, branch to create.

LF7E9:  CPX #$02                ;Does nothing. Has to be save slot 3.
LF7EB:  ORA #$04                ;Set valid bit in bit mask.
LF7ED:  LDX #$C8                ;
LF7EF:  STX ValidSave3          ;Indicate save slot 3 is valid.
LF7F2:  JMP UpdateSaveBitMask   ;($F806)Keep only lower 3 bits and exit.

SaveAtSlot2:
LF7F5:  ORA #$02                ;Set valid bit in bit mask.
LF7F7:  LDX #$C8                ;
LF7F9:  STX ValidSave2          ;Indicate save slot 2 is valid.
LF7FC:  JMP UpdateSaveBitMask   ;($F806)Keep only lower 3 bits and exit.

SaveAtSlot1:
LF7FF:  ORA #$01                ;Set valid bit in bit mask.
LF801:  LDX #$C8                ;
LF803:  STX ValidSave1          ;Indicate save slot 1 is valid.

UpdateSaveBitMask:
LF806:  AND #$07                ;Keep only lower 3 bits in bit mask.
LF808:  STA SaveBitMask         ;

LF80B:  PLA                     ;
LF80C:  TAX                     ;Restore A and X.
LF80D:  PLA                     ;
LF80E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearValidSaves:
LF80F:  PHA                     ;
LF810:  TXA                     ;Save A and X on the stack.
LF811:  PHA                     ;

LF812:  LDA SaveBitMask         ;Is the first save game selected?
LF815:  LDX SaveNumber          ;
LF818:  BEQ ClearValidSave1     ;If so, branch to clear first save game valid bits.

LF81A:  CPX #$01                ;Is the second save game selected?
LF81C:  BEQ ClearValidSave2     ;If so, branch to clear second save game valid bits.

LF81E:  CPX #$02                ;Compare has no function here.
LF820:  AND #$03                ;Clear bit 2 of saved game bit mask.
LF822:  LDX #$00                ;Clear ValidSave3.
LF824:  STX ValidSave3          ;
LF827:  JMP ClearValisSaveDone  ;($F83B)Update save game bit mask.

ClearValidSave2:
LF82A:  AND #$05                ;Clear bit 1 of saved game bit mask.
LF82C:  LDX #$00                ;Clear ValidSave2.
LF82E:  STX ValidSave2          ;
LF831:  JMP ClearValisSaveDone  ;($F83B)Update save game bit mask.

ClearValidSave1:
LF834:  AND #$06                ;Clear LSB of saved game bit mask.
LF836:  LDX #$00                ;Clear ValidSave1.
LF838:  STX ValidSave1          ;

ClearValisSaveDone:
LF83B:  STA SaveBitMask         ;Update valid save game bit mask.

LF83E:  PLA                     ;
LF83F:  TAX                     ;Restore A and X from the stack.
LF840:  PLA                     ;
LF841:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ShowStartGame:
LF842:  JSR ClearWinBufRAM      ;($FC4D)Clear RAM $0400-$07BF;
LF845:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
LF848:  JSR ClearPPU            ;($C17A)Clear the PPU.
LF84B:  LDA #%00011000          ;Turn on background and sprites.
LF84D:  STA PPUControl1         ;
LF850:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LF853:  BRK                     ;Load BG and sprite palettes for selecting saved game.
LF854:  .byte $01, $07          ;($AA7E)LoadStartPals, bank 0.

LF856:  JSR GetValidSaves       ;($F6F4)Get valid save game slots.
LF859:  LDA SaveBitMask         ;Get save games bitmask.
LF85C:  AND #$07                ;Are there any saved games?
LF85E:  BEQ PreNoSaves          ;If not, branch.

LF860:  CMP #$07                ;Is there at least 1 empty save slot?
LF862:  BNE PreUnusedSaves      ;If so, branch.

;----------------------------------------------------------------------------------------------------

PreSavesUsed:
LF864:  JSR Dowindow            ;($C6F0)display on-screen window.
LF867:  .byte WND_CNT_CH_ER     ;Continue, change, erase window.

LF868:  CMP #$00                ;Was continue saved game selected?
LF86A:  BNE ChkChngMsgSpeed     ;If not, branch to check next selection.
LF86C:  JMP DoContinueGame      ;($F8AF)Select existing game to continue.

ChkChngMsgSpeed:
LF86F:  CMP #$01                ;Was change message speed selected?
LF871:  BNE ChkEraseGame        ;If not, branch to check next selection.
LF873:  JMP DoChngMsgSpeed      ;($F8EC)Select game to change message speed.

ChkEraseGame:
LF876:  CMP #$02                ;Was erase game selected?
LF878:  BNE PreSavesUsed        ;If not, branch to stay on current menu.
LF87A:  JMP DoEraseGame         ;($F911)Select game to erase.

;----------------------------------------------------------------------------------------------------

PreUnusedSaves:
LF87D:  JSR Dowindow            ;($C6F0)display on-screen window.
LF880:  .byte WND_FULL_MNU      ;Full menu window.

LF881:  CMP #$00                ;Was continue saved game selected?
LF883:  BNE ChkChngMsgSpeed2    ;If not, branch to check next selection.
LF885:  JMP DoContinueGame      ;($F8AF)Select existing game to continue.

ChkChngMsgSpeed2:
LF888:  CMP #$01                ;Was change message speed selected?
LF88A:  BNE ChkNewQuest         ;If not, branch to check next selection.
LF88C:  JMP DoChngMsgSpeed      ;($F8EC)Select game to change message speed.

ChkNewQuest:
LF88F:  CMP #$02                ;Was start a new game selected?
LF891:  BNE ChkCopyQuest        ;If not, branch to check next selection.
LF893:  JMP DoNewQuest          ;($F8C2)Start a new game.

ChkCopyQuest:
LF896:  CMP #$03                ;Was copy a game selected?
LF898:  BNE ChkEraseGame2       ;If not, branch to check next selection.
LF89A:  JMP DoCopyGame          ;($F93B)Copy a saved game.

ChkEraseGame2:
LF89D:  CMP #$04                ;Was erase game selected?
LF89F:  BNE PreUnusedSaves      ;If not, branch to stay on current menu.
LF8A1:  JMP DoEraseGame         ;($F911)Select game to erase.

;----------------------------------------------------------------------------------------------------

PreNoSaves:
LF8A4:  JSR Dowindow            ;($C6F0)display on-screen window.
LF8A7:  .byte WND_NEW_QST       ;Begin new quest window.

LF8A8:  CMP #$00                ;Was continue saved game selected?
LF8AA:  BNE PreNoSaves          ;If not, branch to stay on current menu.
LF8AC:  JMP DoNewQuest          ;($F8C2)Start a new game.

;----------------------------------------------------------------------------------------------------

DoContinueGame:
LF8AF:  LDA #$00                ;Prepare to get valid saved games.
LF8B1:  JSR ShowUsedLogs        ;($F99F)Show occupied adventure logs.
LF8B4:  CMP #WND_ABORT          ;Was B button pressed?
LF8B6:  BNE PrepContinueGame    ;If not, branch to continue saved game.
LF8B8:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

PrepContinueGame:
LF8BB:  STA SaveNumber          ;Get a copy of the selected saved game number.
LF8BE:  JSR Copy100Times        ;($FAC1)Make up to 100 copies of saved game to validate.
LF8C1:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoNewQuest:
LF8C2:  LDA #$FF                ;Prepare to show available adventure log spots.
LF8C4:  JSR ShowOpenLogs        ;($F983)Show open adventure log spots.
LF8C7:  CMP #WND_ABORT          ;Was B button pressed?
LF8C9:  BNE NewQuest            ;If not, branch to input character name of new game.

LF8CB:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

NewQuest:
LF8CE:  STA SaveNumber          ;Save the game slot for the new game.

LF8D1:  BRK                     ;Do name entering functions.
LF8D2:  .byte $11, $17          ;($AE02)WndEnterName, bank 1.

LF8D4:  LDA #MSG_NORMAL         ;Set normal message speed.
LF8D6:  STA MessageSpeed        ;

LF8D8:  JSR Dowindow            ;($C6F0)display on-screen window.
LF8DB:  .byte WND_MSG_SPEED     ;Message speed window.

LF8DC:  CMP #WND_ABORT          ;Was B button pressed?
LF8DE:  BNE InitNewGame         ;If not, branch to initialize the new game.

LF8E0:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

;----------------------------------------------------------------------------------------------------

InitNewGame:
LF8E3:  STA MessageSpeed        ;Save the selected message speed.
LF8E5:  JSR SGZeroStats         ;($F68F)Zero out all save game stats.
LF8E8:  JSR SaveCurrentGame     ;($F9DF)Save game data in the selected slot.
LF8EB:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoChngMsgSpeed:
LF8EC:  LDA #$00                ;Prepare to show occupied adventure log spots.
LF8EE:  JSR ShowUsedLogs        ;($F99F)Show occupied adventure logs.
LF8F1:  CMP #WND_ABORT          ;Was B button pressed?
LF8F3:  BNE ShowChngMsgSpeed    ;If not, branch to show change message speed window.

LF8F5:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

ShowChngMsgSpeed:
LF8F8:  STA SaveNumber          ;Store desired game number.
LF8FB:  JSR Copy100Times        ;($FAC1)Make up to 100 copies of saved game to validate.

LF8FE:  JSR Dowindow            ;($C6F0)display on-screen window.
LF901:  .byte WND_MSG_SPEED     ;Message speed window.

LF902:  CMP #WND_ABORT          ;Was B button pressed?
LF904:  BNE ChngMsgSpeed        ;If not, branch to change message speed.

LF906:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

ChngMsgSpeed:
LF909:  STA MessageSpeed        ;Update message speed.
LF90B:  JSR SaveCurrentGame     ;($F9DF)Save game data in the selected slot.
LF90E:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

;----------------------------------------------------------------------------------------------------

DoEraseGame:
LF911:  LDA #$00                ;Prepare to get used save game slots.
LF913:  JSR ShowUsedLogs        ;($F99F)Show occupied adventure logs.
LF916:  CMP #WND_ABORT          ;Was B button pressed?
LF918:  BNE VerifyErase         ;If not, branch to show verify window.
LF91A:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

VerifyErase:
LF91D:  STA SaveNumber          ;Make copies of save slot selected(0 to 2).
LF920:  STA SaveSelected        ;

LF923:  JSR Dowindow            ;($C6F0)display on-screen window.
LF926:  .byte WND_ERASE         ;Erase log window.

LF927:  JSR Dowindow            ;($C6F0)display on-screen window.
LF92A:  .byte WND_YES_NO2       ;Yes/No selection window.

LF92B:  CMP #WND_YES            ;Was chosen from selection window?
LF92D:  BEQ EraseGame           ;If so, branch to erase selected game.
LF92F:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

EraseGame:
LF932:  LDA SaveNumber          ;Get save slot to erase.
LF935:  JSR ClearValidSaves     ;($F80F)Clear ValidSave variable for selected game.
LF938:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

;----------------------------------------------------------------------------------------------------

DoCopyGame:
LF93B:  LDA #$00                ;Prepare to get used save game slots.
LF93D:  JSR ShowUsedLogs        ;($F99F)Show occupied adventure logs.
LF940:  CMP #WND_ABORT          ;Was B button pressed?
LF942:  BNE ShowOpenSlots       ;If not, branch to show open save game slots.

LF944:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

ShowOpenSlots:
LF947:  STA SaveNumber          ;Save a copy of the selected slot.
LF94A:  LDA #$FF                ;Prepare to get open save game slots.
LF94C:  JSR ShowOpenLogs        ;($F983)Show open adventure log spots.
LF94F:  CMP #WND_ABORT          ;Was B button pressed?
LF951:  BNE ConfirmCopy         ;If not, branch to confirm save game copy.

LF953:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

ConfirmCopy:
LF956:  STA OpnSltSelected      ;Save target slot to copy game into.

LF959:  JSR Dowindow            ;($C6F0)display on-screen window.
LF95C:  .byte WND_YES_NO2       ;Yes/No selection window.

LF95D:  CMP #$00                ;was game copy finalized?
LF95F:  BEQ DoCopyGameDat       ;If so, branch to copy game data.

LF961:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

DoCopyGameDat:
LF964:  JSR CopyGame            ;($F6BA)Copy game data from save slot to another.
LF967:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

WndBackToMain:
LF96A:  LDA #$FF                ;Prepare to remove window from screen.

LF96C:  BRK                     ;Remove window from screen.
LF96D:  .byte $05, $07          ;($A7A2)RemoveWindow, bank 0.

LF96F:  LDA SaveBitMask         ;Is there still a spot open after copy?
LF972:  AND #$07                ;
LF974:  BEQ JmpNoSaves          ;If not, branch to show appropriate main menu.

LF976:  CMP #$07                ;Is there still a spot open after copy?
LF978:  BNE JmpSomeSaves        ;If so, branch to show appropriate main menu. Should always branch.

LF97A:  JMP PreSavesUsed        ;($F864)Show main menu with no open game slots.

JmpSomeSaves:
LF97D:  JMP PreUnusedSaves      ;($F87D)Show main menu with used and unused game slots.

JmpNoSaves:
LF980:  JMP PreNoSaves          ;($F8A4)Show main menu with no occupied game slots.

;----------------------------------------------------------------------------------------------------

ShowOpenLogs:
LF983:  EOR SaveBitMask         ;Get 1's compliment of valid game bit masks.
LF986:  AND #$07                ;Keep only lower 3 bits. Only 3 save slots.
LF988:  BEQ NoOpenGames         ;Are any open slots present? If not, branch to exit.

LF98A:  STA _SaveBitMask        ;
LF98D:  CLC                     ;Use bitmasks to find proper log list window to show.
LF98E:  ADC #$11                ;

LF990:  BRK                     ;Display empty adventure logs window (windows #$12 to #$18).
LF991:  .byte $10, $17          ;($A194)ShowWindow, bank 1.

LF993:  CMP #WND_ABORT          ;Was B button pressed?
LF995:  BNE ShowOpenLogsExit    ;If not, exit with selected log results.

NoOpenGames:
LF997:  PLA                     ;Pull last return address.
LF998:  PLA                     ;
LF999:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

ShowOpenLogsExit:
LF99C:  JMP CalcSelectedSlot    ;($F9BB)Calculate save slot selected.

;----------------------------------------------------------------------------------------------------

ShowUsedLogs:
LF99F:  EOR SaveBitMask         ;Get saved games bitmask.
LF9A2:  AND #$07                ;Keep only lower 3 bits. Only 3 save slots.
LF9A4:  BEQ NoSavedGames        ;Are any saved games present? If not, branch to exit.

LF9A6:  STA _SaveBitMask        ;
LF9A9:  CLC                     ;Use bitmasks to find proper log list window to show.
LF9AA:  ADC #$18                ;

LF9AC:  BRK                     ;Display used adventure logs window (windows #$19 to #$1F).
LF9AD:  .byte $10, $17          ;($A194)ShowWindow, bank 1.

LF9AF:  CMP #WND_ABORT          ;Was B button pressed?
LF9B1:  BNE ShowUsedLogsExit    ;If not, exit with selected log results.

NoSavedGames:
LF9B3:  PLA                     ;Pull last return address.
LF9B4:  PLA                     ;
LF9B5:  JMP WndBackToMain       ;($F96A)Go back to main pre-game window.

ShowUsedLogsExit:
LF9B8:  JMP CalcSelectedSlot    ;($F9BB)Calculate save slot selected.

;----------------------------------------------------------------------------------------------------

CalcSelectedSlot:
LF9BB:  LDX _SaveBitMask        ;Get bit mask for saved game slots.

ChkUsedSlot2:
LF9BE:  CPX #$02                ;Was used game slot 2 selected?
LF9C0:  BNE ChkUsedSlot3        ;If not branch to check next.

LF9C2:  LDA #$01                ;Return 2nd game slot (count starts at 0).
LF9C4:  RTS                     ;

ChkUsedSlot3:
LF9C5:  CPX #$04                ;Was used game slot 3 selected?
LF9C7:  BNE ChkOpenSlot2        ;If not branch to check next.

LF9C9:  LDA #$02                ;Return 3rd game slot (count starts at 0).
LF9CB:  RTS                     ;

ChkOpenSlot2:
LF9CC:  CPX #$05                ;Are slots 3 and 1 open?
LF9CE:  BNE ChkOpenSlot1        ;If not, branch to check next.

LF9D0:  CMP #$01                ;Was second selection in window chosen(slot 3)?
LF9D2:  BNE CalcSlotExit        ;If not, branch to exit.  Must have been slot 1.

LF9D4:  LDA #$02                ;Return 3rd game slot (count starts at 0).
LF9D6:  RTS                     ;

ChkOpenSlot1:
LF9D7:  CPX #$06                ;Are slots 3 and 2 open?
LF9D9:  BNE CalcSlotExit        ;Must be slot 1 selected. Return 1st slot(0).

LF9DB:  CLC                     ;Return 2nd game slot (count starts at 0).
LF9DC:  ADC #$01                ;

CalcSlotExit:
LF9DE:  RTS                     ;Return value of 0, 1 or 2 for selected game slot. 

;----------------------------------------------------------------------------------------------------

SaveCurrentGame:
LF9DF:  PHA                     ;
LF9E0:  TXA                     ;
LF9E1:  PHA                     ;Preserve A, X, and Y on the stack.
LF9E2:  TYA                     ;
LF9E3:  PHA                     ;

LF9E4:  LDA SaveNumber          ;
LF9E7:  AND #$07                ;Only keep lower 3 bits of save game number.
LF9E9:  STA SaveNumber          ;

LF9EC:  JSR CreateNewSave       ;($F7DA)Prep save game slot.
LF9EF:  LDA CrntGamePtr         ;
LF9F2:  STA GameDatPtrLB        ;Setup game data pointer.
LF9F4:  LDA CrntGamePtr+1       ;
LF9F7:  STA GameDatPtrUB        ;

LF9F9:  JSR SaveData            ;($FA18)Save player's data to battery backed RAM.
LF9FC:  JSR GetCRC              ;($FBE0)Get CRC for selected game data.

LF9FF:  LDA CrntGamePtr         ;
LFA02:  STA ROMSrcPtrLB         ;Setup game data pointer to save game 10 times.
LFA04:  LDA CrntGamePtr+1       ;
LFA07:  STA ROMSrcPtrUB         ;

LFA09:  LDA SaveNumber          ;Get saved game index.
LFA0C:  JSR GetSaveGameBase     ;($FC00)Get base address of selected save game data.
LFA0F:  JSR Save10Times         ;($FAA3)Save game data 10 times accross different addresses.

LFA12:  PLA                     ;
LFA13:  TAY                     ;
LFA14:  PLA                     ;Restore A, X and Y from the stack.
LFA15:  TAX                     ;
LFA16:  PLA                     ;
LFA17:  RTS                     ;

;----------------------------------------------------------------------------------------------------

SaveData:
LFA18:  LDY #$00                ;Zero out index.

LFA1A:  LDA ExpLB               ;
LFA1C:  STA (GameDatPtr),Y      ;
LFA1E:  INY                     ;Save player's experience points.
LFA1F:  LDA ExpUB               ;
LFA21:  STA (GameDatPtr),Y      ;

LFA23:  INY                     ;
LFA24:  LDA GoldLB              ;
LFA26:  STA (GameDatPtr),Y      ;Save player's gold.
LFA28:  INY                     ;
LFA29:  LDA GoldUB              ;
LFA2B:  STA (GameDatPtr),Y      ;

LFA2D:  INY                     ;
LFA2E:  LDA InventorySlot12     ;
LFA30:  STA (GameDatPtr),Y      ;
LFA32:  INY                     ;
LFA33:  LDA InventorySlot34     ;
LFA35:  STA (GameDatPtr),Y      ;Save player's inventory items.
LFA37:  INY                     ;
LFA38:  LDA InventorySlot56     ;
LFA3A:  STA (GameDatPtr),Y      ;
LFA3C:  INY                     ;
LFA3D:  LDA InventorySlot78     ;
LFA3F:  STA (GameDatPtr),Y      ;

LFA41:  INY                     ;
LFA42:  LDA InventoryKeys       ;Get player's keys.
LFA44:  AND #$0F                ;   
LFA46:  CMP #$07                ;Does player have more than 6 keys?
LFA48:  BCC +                   ;If not, branch to move on.

LFA4A:  LDA #$06                ;6 keys max.
LFA4C:* STA (GameDatPtr),Y      ;Save player's magic keys.

LFA4E:  INY                     ;
LFA4F:  LDA InventoryHerbs      ;Save player's herbs.
LFA51:  STA (GameDatPtr),Y      ;

LFA53:  INY                     ;
LFA54:  LDA EqippedItems        ;Save player's armor, shield and weapon.
LFA56:  STA (GameDatPtr),Y      ;

LFA58:  INY                     ;
LFA59:  LDA ModsnSpells         ;save player's upper 2 spells and other flags.
LFA5B:  STA (GameDatPtr),Y      ;

LFA5D:  INY                     ;
LFA5E:  LDA PlayerFlags         ;save other player flags.
LFA60:  STA (GameDatPtr),Y      ;

LFA62:  INY                     ;
LFA63:  LDA StoryFlags          ;Save player's story flags.
LFA65:  STA (GameDatPtr),Y      ;

LFA67:  INY                     ;Prepare to save 4 lower name characters.
LFA68:  LDX #$03                ;

LFA6A:* LDA DispName0,X         ;Save lower name character.
LFA6C:  STA (GameDatPtr),Y      ;
LFA6E:  INY                     ;
LFA6F:  DEX                     ;More characters to save?
LFA70:  BPL -                   ;If so, branch to get next character.

LFA72:  LDX #$03                ;Prepare to save 4 upper name characters.

LFA74:* LDA DispName4,X         ;Save upper name character.
LFA77:  STA (GameDatPtr),Y      ;
LFA79:  INY                     ;
LFA7A:  DEX                     ;More characters to save?
LFA7B:  BPL -                   ;If so, branch to get next character.

LFA7D:  LDA MessageSpeed        ;Save player's message speed.
LFA7F:  STA (GameDatPtr),Y      ;

LFA81:  INY                     ;
LFA82:  LDA HitPoints           ;Save player's hit points.
LFA84:  STA (GameDatPtr),Y      ;

LFA86:  INY                     ;
LFA87:  LDA MagicPoints         ;Save player's magic points.
LFA89:  STA (GameDatPtr),Y      ;

LFA8B:  LDX SaveNumber          ;
LFA8E:  LDA StartStatus1,X      ;Save player's restart status.
LFA91:  INY                     ;
LFA92:  STA (GameDatPtr),Y      ;

LFA94:  LDA #$C8                ;
LFA96:  INY                     ;
LFA97:  STA (GameDatPtr),Y      ;
LFA99:  INY                     ;
LFA9A:  STA (GameDatPtr),Y      ;Fill spare bytes.
LFA9C:  INY                     ;
LFA9D:  STA (GameDatPtr),Y      ;
LFA9F:  INY                     ;
LFAA0:  STA (GameDatPtr),Y      ;
LFAA2:  RTS                     ;

;----------------------------------------------------------------------------------------------------

Save10Times:
LFAA3:  LDX #$09                ;Prepare to save games 10 times.

Save10Loop:
LFAA5:  JSR StoreGamedData      ;($FAB7)Write game data to save game slot RAM.

LFAA8:  LDA GameDatPtrLB        ;
LFAAA:  CLC                     ;
LFAAB:  ADC #$20                ;Move to next save spot. Each spot is 32 bytes.
LFAAD:  STA GameDatPtrLB        ;
LFAAF:  BCC +                   ;
LFAB1:  INC GameDatPtrUB        ;

LFAB3:* DEX                     ;Has the save game been written to 10 different addresses?
LFAB4:  BPL Save10Loop          ;
LFAB6:  RTS                     ;If not, branch to write another copy of the save game data.

StoreGamedData:
LFAB7:  LDY #$1F                ;Prepare to write 32 bytes.  Each save game is 32 bytes.
LFAB9:* LDA (ROMSrcPtr),Y       ;
LFABB:  STA (GameDatPtr),Y      ;
LFABD:  DEY                     ;
LFABE:  BPL -                   ;Has 32 bytes been written?
LFAC0:  RTS                     ;If not, branch to write another save game data byte.

;----------------------------------------------------------------------------------------------------
Copy100Times:
LFAC1:  STA GenByte3E           ;Save index to desired save game.

LFAC3:  TXA                     ;
LFAC4:  PHA                     ;Preserve values of X and Y on the stack.
LFAC5:  TYA                     ;
LFAC6:  PHA                     ;

LFAC7:  LDA GenByte3E           ;
LFAC9:  AND #$07                ;Keep only lower 3 bits of save game index.
LFACB:  STA GenByte3E           ;

LFACD:  JSR GetSaveGameBase     ;($FC00)Get base address of selected save game data.

LFAD0:  LDX #$0A                ;Prepare to copy game data to 10 different locations.

GameCopyLoop:
LFAD2:  TXA                     ;Save number of copies left to make on stack.
LFAD3:  PHA                     ;

LFAD4:  JSR CheckValidCRC       ;($FB4A)Check if the CRC for the selected save game is valid.
LFAD7:  BCS CRCCheckFail        ;Is data valid? If not, branch.

LFAD9:  JSR LoadSavedData       ;($FB6B)Load save game data into game engine registers.

LFADC:  LDA CrntGamePtr         ;Set a pointer to copy save game data. Makes-->
LFADF:  STA GenPtr3CLB          ;a working copy of saved game data but does not-->
LFAE1:  LDA CrntGamePtr+1       ;put the data into the game engine registers.
LFAE4:  STA GenPtr3CUB          ;

LFAE6:  JSR MakeWorkingCopy     ;($FB40)Make a working copy of selected saved game.
LFAE9:  JSR Copy10Times         ;($FB15)Copy of saved game data 10 times to same addresses.

LFAEC:  PLA                     ;Indicate saved game data successfully copied.
LFAED:  LDA #$00                ;
LFAEF:  JMP FinishGameCopy      ;($FB0C)Done making copies of the saved game.

CRCCheckFail:
LFAF2:  TXA                     ;
LFAF3:  LDX SaveNumber          ;Increment CRC fail counter.
LFAF6:  INC CRCFail1,X          ;
LFAF9:  TAX                     ;

LFAFA:  LDA GameDatPtrLB        ;
LFAFC:  CLC                     ;
LFAFD:  ADC #$20                ;Move to next address slots to copy saved game into.
LFAFF:  STA GameDatPtrLB        ;
LFB01:  BCC NextCopy            ;
LFB03:  INC GameDatPtrUB        ;

NextCopy:
LFB05:  PLA                     ;Get number of copies left to make.
LFB06:  TAX                     ;
LFB07:  DEX                     ;Have 10 copies been made?
LFB08:  BNE GameCopyLoop        ;If not, branch to make another copy.

LFB0A:  LDA #$FF                ;Indicate saved game data cannot be successfully copied.

FinishGameCopy:
LFB0C:  STA GenByte3E           ;Store valid status of saved game(#$00-good, #$FF-bad).

LFB0E:  PLA                     ;
LFB0F:  TAY                     ;Restore values of X and Y from the stack.
LFB10:  PLA                     ;
LFB11:  TAX                     ;

LFB12:  LDA GenByte3E           ;A indicates whether selected game is valid or not.
LFB14:  RTS                     ;

;----------------------------------------------------------------------------------------------------

Copy10Times:
LFB15:  LDA GenByte3E           ;Load save game number to work on.
LFB17:  JSR GetSaveGameBase     ;($FC00)Get base address of selected save game data.

LFB1A:  LDA GameDatPtrLB        ;
LFB1C:  STA GenPtr3CLB          ;Copy destination is saved game slot.
LFB1E:  LDA GameDatPtrUB        ;
LFB20:  STA GenPtr3CUB          ;

LFB22:  LDA CrntGamePtr         ;
LFB25:  STA GameDatPtrLB        ;Copy source is working copy of saved game.
LFB27:  LDA CrntGamePtr+1       ;
LFB2A:  STA GameDatPtrUB        ;

LFB2C:  LDX #$0A                ;Prepare to make 10 copies of the saved game data.

Copy10Loop:
LFB2E:  JSR MakeWorkingCopy     ;($FB40)Make a working copy of a selected saved game.

LFB31:  LDA GenByte3C           ;
LFB33:  CLC                     ;
LFB34:  ADC #$20                ;Keep track of how many bytes total have been copied.
LFB36:  STA GenByte3C           ;
LFB38:  BCC Check10Copies       ;
LFB3A:  INC GenByte3D           ;

Check10Copies:
LFB3C:  DEX                     ;Have 10 copies been made?
LFB3D:  BNE Copy10Loop          ;
LFB3F:  RTS                     ;If not, branch to make a new copy.

;----------------------------------------------------------------------------------------------------

MakeWorkingCopy:
LFB40:  LDY #$1F                ;Copy 32 bytes of data.
LFB42:* LDA (GameDatPtr),Y      ;Copy byte of saved game data.
LFB44:  STA (GenPtr3C),Y        ;
LFB46:  DEY                     ;Have all 32 bytes of data been copied?
LFB47:  BPL -                   ;If not, branch to copy next byte.
LFB49:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckValidCRC:
LFB4A:  LDY #$1E                ;
LFB4C:  LDA (GameDatPtr),Y      ;
LFB4E:  STA CRCCopyLB           ;Save a copy of the existing CRC in the save game.
LFB50:  INY                     ;
LFB51:  LDA (GameDatPtr),Y      ;
LFB53:  STA CRCCopyUB           ;

LFB55:  JSR GetCRC              ;($FBE0)Recalculate CRC for selected game data.

LFB58:  LDY #$1E                ;Compare lower bytes of the old and new CRC.    
LFB5A:  LDA CRCCopyLB           ;
LFB5C:  CMP (GameDatPtr),Y      ;Are they the same?
LFB5E:  BNE InvalidCRC          ;If not, branch.  Save game data is not valid.

LFB60:  INY                     ;Compare lower bytes of the old and new CRC.    
LFB61:  LDA CRCCopyUB           ;
LFB63:  CMP (GameDatPtr),Y      ;Are they the same?
LFB65:  BEQ ValidCRC            ;If so, branch.  Save game data is valid.

InvalidCRC:
LFB67:  SEC                     ;Set the carry and return.
LFB68:  RTS                     ;The CRC is invalid.

ValidCRC:
LFB69:  CLC                     ;Clear the carry and return.
LFB6A:  RTS                     ;The CRC is valid.

;----------------------------------------------------------------------------------------------------

LoadSavedData:
LFB6B:  LDY #$00                ;Start at beginning of save game data.

LFB6D:  LDA (GameDatPtr),Y      ;
LFB6F:  STA ExpLB               ;
LFB71:  INY                     ;Load player's experience.
LFB72:  LDA (GameDatPtr),Y      ;
LFB74:  STA ExpUB               ;

LFB76:  INY                     ;
LFB77:  LDA (GameDatPtr),Y      ;
LFB79:  STA GoldLB              ;Load player's gold.
LFB7B:  INY                     ;
LFB7C:  LDA (GameDatPtr),Y      ;
LFB7E:  STA GoldUB              ;

LFB80:  INY                     ;
LFB81:  LDA (GameDatPtr),Y      ;
LFB83:  STA InventorySlot12     ;
LFB85:  INY                     ;
LFB86:  LDA (GameDatPtr),Y      ;
LFB88:  STA InventorySlot34     ;Load player's inventory items.
LFB8A:  INY                     ;
LFB8B:  LDA (GameDatPtr),Y      ;
LFB8D:  STA InventorySlot56     ;
LFB8F:  INY                     ;
LFB90:  LDA (GameDatPtr),Y      ;
LFB92:  STA InventorySlot78     ;

LFB94:  INY                     ;
LFB95:  LDA (GameDatPtr),Y      ;Load player's keys.
LFB97:  STA InventoryKeys       ;

LFB99:  INY                     ;
LFB9A:  LDA (GameDatPtr),Y      ;Load player's herbs.
LFB9C:  STA InventoryHerbs      ;

LFB9E:  INY                     ;
LFB9F:  LDA (GameDatPtr),Y      ;Load player's weapons and armor.
LFBA1:  STA EqippedItems        ;

LFBA3:  INY                     ;
LFBA4:  LDA (GameDatPtr),Y      ;Load player's upper spells and misc. flags.
LFBA6:  STA ModsnSpells         ;

LFBA8:  INY                     ;
LFBA9:  LDA (GameDatPtr),Y      ;
LFBAB:  STA PlayerFlags         ;Load all other story and player flags.
LFBAD:  INY                     ;
LFBAE:  LDA (GameDatPtr),Y      ;
LFBB0:  STA StoryFlags          ;

LFBB2:  INY                     ;Load player's lower 4 characters of their name.
LFBB3:  LDX #$03                ;
LFBB5:* LDA (GameDatPtr),Y      ;
LFBB7:  STA DispName0,X         ;
LFBB9:  INY                     ;
LFBBA:  DEX                     ;Have 4 characters been loaded?
LFBBB:  BPL -                   ;If not, branch to load another character.

LFBBD:  LDX #$03                ;Load player's upper 4 characters of their name.
LFBBF:* LDA (GameDatPtr),Y      ;
LFBC1:  STA DispName4,X         ;
LFBC4:  INY                     ;
LFBC5:  DEX                     ;Have 4 characters been loaded?
LFBC6:  BPL -                   ;If not, branch to load another character.

LFBC8:  LDA (GameDatPtr),Y      ;Load message speed.
LFBCA:  STA MessageSpeed        ;

LFBCC:  INY                     ;
LFBCD:  LDA (GameDatPtr),Y      ;Load player's current HP.
LFBCF:  STA HitPoints           ;

LFBD1:  INY                     ;
LFBD2:  LDA (GameDatPtr),Y      ;Load player's current MP.
LFBD4:  STA MagicPoints         ;

LFBD6:  INY                     ;
LFBD7:  LDA (GameDatPtr),Y      ;Load player's start status-->
LFBD9:  LDX SaveNumber          ;(should HP and MP be restored).
LFBDC:  STA StartStatus1,X      ;
LFBDF:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetCRC:
LFBE0:  JSR DoCRC               ;($FBEF)Calculate CRC on saved game.
LFBE3:  LDY #$1E                ;CRC is stored in bytes 31 and 32 of saved game data.

LFBE5:  LDA CRCLB               ;
LFBE7:  STA (GameDatPtr),Y      ;
LFBE9:  INY                     ;Save CRC in saved game data slot.
LFBEA:  LDA CRCUB               ;
LFBEC:  STA (GameDatPtr),Y      ;
LFBEE:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoCRC:
LFBEF:  LDY #$1D                ;30 bytes of saved game data.

LFBF1:  STY CRCLB               ;Seed the LFSR.
LFBF3:  STY CRCUB               ;

LFBF5:* LDA (GameDatPtr),Y      ;Loop until all saved data bytes are processed.
LFBF7:  STA GenByte3C           ;
LFBF9:  JSR DoLFSR              ;($FC2A)Put data through an LFSR.
LFBFC:  DEY                     ;
LFBFD:  BPL -                   ;More bytes to process? If so, branch to continue.
LFBFF:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetSaveGameBase:
LFC00:  STA GenByte22           ;Save value of A
LFC02:  TXA                     ;Preserve value of X on the stack.
LFC03:  PHA                     ;
LFC04:  LDA GenByte22           ;Restore value of A.

LFC06:  LDX SvdGamePtr          ;
LFC09:  STX GameDatPtrLB        ;Get base address for save game 1 data.
LFC0B:  LDX SvdGamePtr+1        ;
LFC0E:  STX GameDatPtrUB        ;

LFC10:  TAX                     ;Is the base address for game 1 desired?
LFC11:  BEQ FoundSaveGameBase   ;If so, nothing mre to do.  Branch to exit.

LFC13:* JSR GetNxtSvGameBase    ;($FC1C)Get the base address for the next save game data.
LFC16:  DEX                     ;Is this the base address for the save game desired?
LFC17:  BNE -                   ;If not, branch to go to next save game.

FoundSaveGameBase:
LFC19:  PLA                     ;
LFC1A:  TAX                     ;Restore value of X from the stack.
LFC1B:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetNxtSvGameBase:
LFC1C:  LDA GameDatPtrLB        ;
LFC1E:  CLC                     ;
LFC1F:  ADC #$40                ;
LFC21:  STA GameDatPtrLB        ;Add #$140 to current save game base addres-->
LFC23:  LDA GameDatPtrUB        ;to find the base of the next saved game.
LFC25:  ADC #$01                ;
LFC27:  STA GameDatPtrUB        ;
LFC29:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoLFSR:
LFC2A:  TYA                     ;Save Y.
LFC2B:  PHA                     ;

LFC2C:  LDY #$08                ;
LFC2E:* LDA CRCUB               ;
LFC30:  EOR GenByte3C           ;
LFC32:  ASL CRCLB               ;
LFC34:  ROL CRCUB               ;
LFC36:  ASL GenByte3C           ;
LFC38:  ASL                     ;Some kind of linear feedback shift register I think.-->
LFC39:  BCC +                   ;The saved data is run though this function and a 16-bit-->
LFC3B:  LDA CRCLB               ;CRC appears to be generated. 
LFC3D:  EOR #$21                ;
LFC3F:  STA CRCLB               ;
LFC41:  LDA CRCUB               ;
LFC43:  EOR #$10                ;
LFC45:  STA CRCUB               ;
LFC47:* DEY                     ;
LFC48:  BNE --                  ;

LFC4A:  PLA                     ;
LFC4B:  TAY                     ;Restore Y.
LFC4C:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearWinBufRAM:
LFC4D:  LDA #TL_BLANK_TILE1     ;Fill buffer with Blank tiles.

LFC4F:  LDX #$00                ;
LFC51:* STA WinBufRAM,X         ;Clear RAM $0400-$04FF
LFC54:  DEX                     ;
LFC55:  BNE -                   ;

LFC57:  LDX #$00                ;
LFC59:* STA WinBufRAM+$100,X    ;Clear RAM $0500-$05FF
LFC5C:  DEX                     ;
LFC5D:  BNE -                   ;

LFC5F:  LDX #$00                ;
LFC61:* STA WinBufRAM+$200,X    ;Clear RAM $0600-$06FF
LFC64:  DEX                     ;
LFC65:  BNE -                   ;

LFC67:  LDX #$00                ;
LFC69:* STA WinBufRAM+$300,X    ;
LFC6C:  INX                     ;Clear RAM $0700-$07BF
LFC6D:  CPX #$C0                ;
LFC6F:  BCC -                   ;
LFC71:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CrntGamePtr:
LFC72:  .word CurrentGameDat    ;($6048)Data collection point for current game.

SvdGamePtr:
LFC74:  .word SavedGame1        ;($6068)Base address for the 3 save game slots.

KenMasutaTbl:
;              K    E    N    _    M    A    S    U    T    A
LFC76:  .byte $4B, $45, $4E, $20, $4D, $41, $53, $55, $54, $41 

;----------------------------------------------------------------------------------------------------

LoadMMCPRGBank3:
LFC80:  PHA                     ;Save A.
LFC81:  LDA #PRG_BANK_3         ;Prepare to load PRG bank 3.
LFC83:  JSR MMC1LoadPRG         ;($FF96)Load PRG bank 3.
LFC86:  PLA                     ;Restore A.
LFC87:  RTS                     ;

;----------------------------------------------------------------------------------------------------

MMCShutdown:
LFC88:  PHA                     ;Save A.

LFC89:  LDA #PRG_B3_NO_RAM      ;Prepare to load PRG bank 3 and disable the PRG RAM.
LFC8B:  STA ActiveBank          ;
LFC8E:  JSR MMC1LoadPRG         ;($FF96)Load bank 3.

LFC91:  LDA #%00001000          ;Disable NMI.
LFC93:  STA PPUControl0         ;

LFC96:  PLA                     ;Restore A.
LFC97:  RTS                     ;

;----------------------------------------------------------------------------------------------------

Bank1ToNT0:
LFC98:  PHA                     ;Save A on stack.
LFC99:  LDA #CHR_BANK_1         ;Indicate CHR ROM bank 1 to be loaded.

SetActiveNT0:
LFC9B:  STA ActiveNT0           ;
LFC9E:  JSR MMC1LoadNT0         ;($FFAC)load nametable 0 with CHR ROM bank 1.
LFCA1:  PLA                     ;
LFCA2:  RTS                     ;Restore A before returning.

Bank0ToNT0:
LFCA3:  PHA                     ;Save A on stack.
LFCA4:  LDA #CHR_BANK_0         ;Indicate CHR ROM bank 0 to be loaded.
LFCA6:  BEQ SetActiveNT0        ;Load it into nametable 0.

Bank0ToNT1:
LFCA8:  PHA                     ;Indicate CHR ROM bank 0 to be loaded.
LFCA9:  LDA #CHR_BANK_0         ;
LFCAB:  BEQ SetActiveNT1        ;Load it into nametable 1.

Bank2ToNT1:
LFCAD:  PHA                     ;Indicate CHR ROM bank 2 to be loaded.
LFCAE:  LDA #CHR_BANK_2         ;

SetActiveNT1:
LFCB0:  STA ActiveNT1           ;
LFCB3:  JSR MMC1LoadNT1         ;($FFC2)load nametable 1.
LFCB6:  PLA                     ;Restore A and return.
LFCB7:  RTS                     ;

Bank3ToNT1:
LFCB8:  PHA                     ;
LFCB9:  LDA #CHR_BANK_3         ;Indicate CHR ROM bank 3 to be loaded.
LFCBB:  BNE SetActiveNT1        ;

;----------------------------------------------------------------------------------------------------

RunBankFunction:
LFCBD:  STA IRQStoreA           ;
LFCBF:  STX IRQStoreX           ;
LFCC1:  LDA ActiveBank          ;Save register values and active PRG bank on stack.
LFCC4:  PHA                     ;
LFCC5:  PHP                     ;

LFCC6:  LDA ActiveBank          ;Unused variable.
LFCC9:  STA WndUnused6006       ;

LFCCC:  JSR GetDataPtr          ;($FCEC)Get pointer to desired data.
LFCCF:  LDA #$4C                ;Prepare to jump. #$4C is the opcode for JUMP.
LFCD1:  STA _JMPFuncPtr         ;

LFCD3:  LDX IRQStoreX           ;
LFCD5:  LDA IRQStoreA           ;Restore registers and processor status.
LFCD7:  PLP                     ;

LFCD8:  JSR JMPFuncPtr          ;Call bank function.

LFCDB:  PHP                     ;Save A and processor status.
LFCDC:  STA IRQStoreA           ;

LFCDE:  PLA                     ;Load bank number to return to.
LFCDF:  STA NewPRGBank          ;

LFCE1:  PLA                     ;Prepare to load original PRG bank back into memory.
LFCE2:  JSR SetPRGBankAndSwitch ;($FF91)Restore original PRG bank.

LFCE5:  LDA NewPRGBank          ;Load active PRG bank number.
LFCE7:  PHA                     ;
LFCE8:  LDA IRQStoreA           ;
LFCEA:  PLP                     ;Restore variables before returning.
LFCEB:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetDataPtr:
LFCEC:  LDA NewPRGBank          ;Load bank number to switch to.
LFCEE:  JSR SetPRGBankAndSwitch ;($FF91)Switch to new PRG bank.
LFCF1:  LDA BankPtrIndex        ;Load index into BankPointer table.
LFCF3:  ASL                     ;*2.

LFCF4:  TAX                     ;
LFCF5:  LDA BankPointers,X      ;
LFCF8:  STA BankPntrLB          ;Get base address of desired data.
LFCFA:  LDA BankPointers+1,X    ;
LFCFD:  STA BankPntrUB          ;
LFCFF:  RTS                     ;

GetAndStrDatPtr:
LFD00:  STA IRQStoreA           ;Save current values of A and X.
LFD02:  STX IRQStoreX           ;

LFD04:  LDA ActiveBank          ;Store current active PRG bank.
LFD07:  PHA                     ;
LFD08:  JSR GetDataPtr          ;($FCEC)Get pointer to desired data.

LFD0B:  PLA                     ;Switch back to original PRG bank.
LFD0C:  JSR SetPRGBankAndSwitch ;($FF91)Switch to new PRG bank.

LFD0F:  LDX IRQStoreX           ;Restore X.
LFD11:  LDA BankPntrLB          ;
LFD13:  STA GenPtr00LB,X        ;Transfer retreived pointer to a-->
LFD15:  LDA BankPntrUB          ;general purpose pointer address.
LFD17:  STA GenPtr00UB,X        ;
LFD19:  LDA IRQStoreA           ;Restore A.
LFD1B:  RTS                     ;

GetBankDataByte:
LFD1C:  STA IRQStoreA           ;Save current value of A.
LFD1E:  LDA ActiveBank          ;Store current active PRG bank.
LFD21:  PHA                     ;
LFD22:  LDA IRQStoreA           ;Restore A. It contains the bank to switch to.
LFD24:  JSR SetPRGBankAndSwitch ;($FF91)Switch to new PRG bank.

LFD27:  LDA GenPtr00LB,X        ;
LFD29:  STA BankDatPtrLB        ;
LFD2B:  LDA GenPtr00UB,X        ;Get data byte from desired bank and store in A.
LFD2D:  STA BankDatPtrUB        ;
LFD2F:  LDA (BankDatPtr),Y      ;

LFD31:  STA IRQStoreA           ;Save current value of A.

LFD33:  PLA                     ;Switch back to original PRG bank.
LFD34:  JSR SetPRGBankAndSwitch ;($FF91)Switch to PRG bank function is on.

LFD37:  LDA IRQStoreA           ;Place data byte retreived in A.
LFD39:  RTS                     ;

;----------------------------------------------------------------------------------------------------

IRQ:
LFD3A:  SEI                     ;Disable IRQs.
LFD3B:  PHP                     ;Push processor status. Not necessary. Done by interrupt.
LFD3C:  BIT APUCommonCntrl0     ;Appears to have no effect.

LFD3F:  STA IRQStoreA           ;
LFD41:  STX IRQStoreX           ;Save A, X, and Y.
LFD43:  STY IRQStoreY           ;

LFD45:  TSX                     ;Get stack pointer.
LFD46:  LDA BankFuncDatLB,X     ;
LFD49:  SEC                     ;Get return address from the stack-->
LFD4A:  SBC #$01                ;and subtract 1.  This points to the-->
LFD4C:  STA _BankFuncDatLB      ;first data byte after the BRK-->
LFD4E:  LDA BankFuncDatUB,X     ;instruction.
LFD51:  SBC #$00                ;
LFD53:  STA _BankFuncDatUB      ;Save pointer to this byte in $33 and $34.

LFD55:  LDY #$01                ;
LFD57:  LDA (_BankFuncDatPtr),Y ;Get Second byte after BRK and save on stack.
LFD59:  PHA                     ;

LFD5A:  AND #$08                ;If bit 3 is set, set the carry bit.
LFD5C:  CMP #$08                ;If carry bit set, get data only, do not run function.

LFD5E:  PLA                     ;Restore data byte.
LFD5F:  ROR                     ;
LFD60:  LSR                     ;
LFD61:  LSR                     ;Get upper nibble. It contains PRG bank to switch to.
LFD62:  LSR                     ;
LFD63:  STA NewPRGBank          ;

LFD65:  DEY                     ;Get first byte after the BRK instruction.
LFD66:  LDA (_BankFuncDatPtr),Y ;
LFD68:  BMI GetBankData         ;Branch if MSB set. Only get data byte.

LFD6A:  STA BankPtrIndex        ;Save index into BankPointers table.

LFD6C:  LDY IRQStoreY           ;Restore Y.
LFD6E:  LDX IRQStoreX           ;Restore X.
LFD70:  PLP                     ;Restore processor status.
LFD71:  PLA                     ;Discard extra processor status byte.
LFD72:  LDA IRQStoreA           ;Restore A
LFD74:  JMP RunBankFunction     ;($FCBD)Run the desired bank function.

GetBankData:
LFD77:* AND #$3F                ;Remove upper bit.
LFD79:  STA BankPtrIndex        ;Save index into BankPointers table.

LFD7B:  LDY IRQStoreY           ;Restore Y.
LFD7D:  LDX IRQStoreX           ;Restore X.
LFD7F:  PLP                     ;Restore processor status.
LFD80:  PLA                     ;Discard extra processor status byte.
LFD81:  LDA IRQStoreA           ;Restore A
LFD83:  JMP GetAndStrDatPtr     ;($FD00)Get data pointer.

;----------------------------------------------------------------------------------------------------

DoReset:
LFD86:  CLD                     ;Put processor in binary mode.
LFD87:  LDA #%00010000          ;Turn off VBlank interrupt, BG pattern table 1.
LFD89:  STA PPUControl0         ;

LFD8C:* LDA PPUStatus           ;
LFD8F:  BMI -                   ;Loop until not in VBlank. Clears the address latch.
LFD91:* LDA PPUStatus           ;
LFD94:  BPL -                   ;Wait until VBlank starts.
LFD96:* LDA PPUStatus           ;
LFD99:  BMI -                   ;In VBlank.  Bit should be clear on second read.

LFD9B:  LDA #%00000000          ;Turn off the display.
LFD9D:  STA PPUControl1         ;

LFDA0:  LDX #$FF                ;Manually reset stack pointer.
LFDA2:  TXS                     ;

LFDA3:  TAX                     ;
LFDA4:  STA UpdateBGTiles       ;Clear update background tiles byte.
LFDA7:* STA $00,X               ;
LFDA9:  STA BlockRAM,X          ;
LFDAC:  STA WinBufRAM,X         ;Clear internal NES RAM.
LFDAF:  STA WinBufRAM+$0100,X   ;
LFDB2:  STA WinBufRAM+$0200,X   ;
LFDB5:  STA WinBufRAM+$0300,X   ;
LFDB8:  INX                     ;
LFDB9:  BNE -                   ;

LFDBB:  JSR LoadMMCPRGBank3     ;($FC80)Make sure PRG bank 3 is loaded.
LFDBE:  STA ActiveBank          ;Should always store PRG bank 0 as active bank.

LFDC1:  LDA #%00011110          ;16KB PRG banks, 4KB CHR banks, vertical mirroring.
LFDC3:  STA MMC1Config          ;

LFDC6:  LDA #$00                ;
LFDC8:  STA ActiveNT0           ;Prepare to load the nametables.
LFDCB:  STA ActiveNT1           ;
LFDCE:  JSR DoMMC1              ;($FDF4)Program the MMC1 chip.

LFDD1:  LDA PPUStatus           ;Clear PPU address latch.
LFDD4:  LDA #$10                ;
LFDD6:  STA PPUAddress          ;
LFDD9:  LDA #$00                ;Set PPU address to start of pattern table 1.
LFDDB:  STA PPUAddress          ;

LFDDE:  LDX #$10                ;
LFDE0:* STA PPUIOReg            ;Clear lower 16 bytes of pattern table 1.
LFDE3:  DEX                     ;
LFDE4:  BNE -                   ;

LFDE6:  LDA #%10001000          ;Turn on VBlank interrupts, set sprites-->
LFDE8:  STA PPUControl0         ;to pattern table 1.
LFDEB:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
LFDEE:  JSR WaitForNMI          ;($FF74)Wait for VBlank.
LFDF1:  JMP ContinueReset       ;($C9B5)Continue the reset process.

;----------------------------------------------------------------------------------------------------

DoMMC1:
LFDF4:  INC $FFDF               ;Reset MMC1 chip.
LFDF7:  LDA MMC1Config          ;Configure MMC1 chip.
LFDFA:  JSR MMC1LoadConfig      ;($FE09)Load the configuration for the MMC1 controller.
LFDFD:  LDA ActiveNT0           ;Get CHR ROM bank to load into nametable 0.
LFE00:  JSR MMC1LoadNT0         ;($FFAC)load nametable 0.
LFE03:  LDA ActiveNT1           ;Get CHR ROM bank to load into nametable 1.
LFE06:  JMP MMC1LoadNT1         ;($FFC2)load nametable 1.

MMC1LoadConfig:
LFE09:  STA MMC1Config          ;
LFE0C:  STA MMCCfg              ;
LFE0F:  LSR                     ;
LFE10:  STA MMCCfg              ;
LFE13:  LSR                     ;
LFE14:  STA MMCCfg              ;Load the configuration for the MMC1 controller.
LFE17:  LSR                     ;
LFE18:  STA MMCCfg              ;
LFE1B:  LSR                     ;
LFE1C:  STA MMCCfg              ;
LFE1F:  RTS                     ;

UpdateBG:
LFE20:  LDY #$01                ;MSB set indicates PPU control byte.
LFE22:  LDA BlockRAM,X          ;Is this a PPU control byte?
LFE25:  BPL LoadBGDat           ;If not, branch to load as PPU data byte.

LFE27:  TAY                     ;This PPU data byte has PPU control info in it.
LFE28:  LSR                     ;
LFE29:  LSR                     ;Move upper nibble to lower nibble.
LFE2A:  LSR                     ;
LFE2B:  LSR                     ;
LFE2C:  AND #$04                ;
LFE2E:  ORA #$88                ;Isolate bit used to control address increment-->
LFE30:  STA PPUControl0         ;and apply it to the current PPU settings.

LFE33:  TYA                     ;
LFE34:  INX                     ;Reload the data byte because it also contains address info.
LFE35:  LDY BlockRAM,X          ;

LoadBGDat:
LFE38:  INX                     ;Move to next index in buffer.
LFE39:  AND #$3F                ;Remove any PPU control bits from byte.

LFE3B:  STA PPUAddress          ;
LFE3E:  LDA BlockRAM,X          ;Set PPU address for data load.
LFE41:  INX                     ;
LFE42:  STA PPUAddress          ;

LFE45:* LDA BlockRAM,X          ;Get next data byte for PPU load.
LFE48:  INX                     ;
LFE49:  STA PPUIOReg            ;Store byte in PPU.
LFE4C:  DEY                     ;More data to load for this entry?
LFE4D:  BNE -                   ;If so, branch to get next byte.

LFE4F:  DEC PPUEntCount         ;Is there another PPU entry to load?
LFE51:  BNE UpdateBG            ;If so, branch to get the next entry.

LFE53:  BEQ ProcessVBlank2      ;Done with Background updates. Move on.

;----------------------------------------------------------------------------------------------------

NotVBlankReady:
LFE55:  JSR SetPPUValues        ;($FF2D)Set scroll values, background color and active nametable.
LFE58:  LDA #$02                ;Set sprite RAM to address $0200.
LFE5A:  STA SPRDMAReg           ;
LFE5D:  JMP DoFrameUpdates      ;($FEE0)Do mandatory frame checks and updates.

;----------------------------------------------------------------------------------------------------

SetSprtRAM:
LFE60:  LDA #$02                ;Set sprite RAM to address $0200.
LFE62:  STA SPRDMAReg           ;
LFE65:  BNE ProcessVBlank2      ;Jump to do more VBlank stuff.

;----------------------------------------------------------------------------------------------------

NMI:
LFE67:  PHA                     ;
LFE68:  TXA                     ;
LFE69:  PHA                     ;Store register values on the stack.
LFE6A:  TYA                     ;
LFE6B:  PHA                     ;
LFE6C:  TSX                     ;

LFE6D:  LDA Stack-10,X          ;
LFE70:  CMP #>WaitForNMI        ;
LFE72:  BNE NotVBlankReady      ;Get return address from the stack and check-->
LFE74:  LDA Stack-11,X          ;If program was not idle waiting for VBlank.
LFE77:  CMP #<WaitForNMI+3      ;
LFE79:  BCC NotVBlankReady      ;
LFE7B:  CMP #<WaitForNMI+9      ;Do less processing if not VBlank ready.
LFE7D:  BCS NotVBlankReady      ;

ProcessVBlank:
LFE7F:  LDA PPUStatus           ;No effect.
LFE82:  INC FrameCounter        ;Increment frame counter.

LFE84:  LDA PPUEntCount         ;Are there PPU entries waiting to be loaded into the PPU?
LFE86:  BEQ SetSprtRAM          ;If not, branch to do sprite stuff.

LFE88:  CMP #$08                ;Are there more than 8 PPU entries to load?
LFE8A:  BCS ChkBGUpdates        ;If so, branch.

LFE8C:  LDA #$02                ;Set sprite RAM to address $0200.
LFE8E:  STA SPRDMAReg           ;

ChkBGUpdates:
LFE91:  LDX #$00                ;Set index to beginning of buffer.
LFE93:  LDA UpdateBGTiles       ;Do background tiles need to be updated?
LFE96:  BMI UpdateBG            ;If so, branch.

LFE98:* LDA BlockRAM,X          ;
LFE9B:  STA PPUAddress          ;
LFE9E:  LDA BlockRAM+1,X        ;
LFEA1:  STA PPUAddress          ;
LFEA4:  LDA BlockRAM+2,X        ;
LFEA7:  STA PPUIOReg            ;Load PPU buffer contents into PPU.
LFEAA:  INX                     ;
LFEAB:  INX                     ;
LFEAC:  INX                     ;
LFEAD:  CPX PPUBufCount         ;
LFEAF:  BNE -                   ;

ProcessVBlank2:
LFEB1:  LDA #$3F                ;Prepare to write to the PPU palettes.
LFEB3:  STA PPUAddress          ;

LFEB6:  LDA #$00                ;
LFEB8:  STA NMIStatus           ;
LFEBA:  STA PPUEntCount         ;Clear status variables.
LFEBC:  STA PPUBufCount         ;
LFEBE:  STA UpdateBGTiles       ;

LFEC1:  STA PPUAddress          ;
LFEC4:  LDA #$0F                ;Set universal background color to black.
LFEC6:  STA PPUIOReg            ;

LFEC9:  LDA ActiveNmTbl         ;
LFECB:  BNE +                   ;
LFECD:  LDA #%10001000          ;Set active name table.
LFECF:  BNE ++                  ;
LFED1:* LDA #%10001001          ;
LFED3:* STA PPUControl0         ;

LFED6:  LDA ScrollX             ;
LFED8:  STA PPUScroll           ;Set scroll registers.
LFEDB:  LDA ScrollY             ;
LFEDD:  STA PPUScroll           ;

DoFrameUpdates:
LFEE0:  JSR DoMMC1              ;($FDF4)Program the MMC1 chip.
LFEE3:  LDA SndEngineStat       ;Is sound engine busy?
LFEE6:  BNE DoFrameUpdates2     ;If so, branch to skip updating sounds.

LFEE8:  LDA #PRG_BANK_1         ;Prepare to access sound engine.
LFEEA:  JSR MMC1LoadPRG         ;($FF96)Load PRG bank 1.
LFEED:  JSR UpdateSound         ;($8028)Update music or SFX.

DoFrameUpdates2:
LFEF0:  LDA ActiveBank          ;Get active PRG bank.
LFEF3:  JSR SetPRGBankAndSwitch ;($FF91)Switch to new PRG bank.

LFEF6:  TSX                     ;
LFEF7:  LDA Stack-$A,X          ;Get upper byte of interrupt return address.
LFEFA:  STA NMIPtrUB            ;

LFEFC:  CMP #>MMC1LoadPRG       ;Is upper byte of return address within the range of the-->
LFEFE:  BNE ChkValidInst        ;MMC PRG functions? If not, branch to move on.

LFF00:  LDA Stack-$B,X          ;Get lower byte of interrupt return address.

LFF03:  CMP #<MMC1LoadPRG       ;Is lower byte of return address within the range of the-->
LFF05:  BCC ChkValidInst        ;MMC PRG functions? If not, branch to move on.

LFF07:  CMP #<MMC1LoadNT1+$14   ;Is lower byte of return address within the range of the-->
LFF09:  BCS ChkValidInst        ;MMC PRG functions? If not, branch to move on.

LFF0B:  LDA #<MMC1LoadNT1+$14   ;MMC was being accessed when interrupt happened.
LFF0D:  STA Stack-$B,X          ;Set return address to end of MMC functions.

ChkValidInst:
LFF10:  LDA Stack-$B,X          ;Get lower byte of interrupt return address.
LFF13:  STA NMIPtrLB            ;

LFF15:  LDY #$00                ;Does data at return address have 7 as the lower nibble?
LFF17:  LDA (NMIPtr),Y          ;
LFF19:  AND #$0F                ;
LFF1B:  CMP #$07                ;If so, do not do IRQ routines.  No valid instruction-->
LFF1D:  BEQ PrepForIRQFuncs     ;has 7 as the lower nibble.  Could be a data byte.

LFF1F:  PLA                     ;
LFF20:  TAY                     ;
LFF21:  PLA                     ;Restore register values and return.
LFF22:  TAX                     ;
LFF23:  PLA                     ;
LFF24:  RTI                     ;

PrepForIRQFuncs:
LFF25:  PLA                     ;
LFF26:  TAY                     ;
LFF27:  PLA                     ;Restore values before running IRQ routines.
LFF28:  TAX                     ;
LFF29:  PLA                     ;
LFF2A:  JMP IRQ                 ;($FD3A)IRQ vector.

;----------------------------------------------------------------------------------------------------

SetPPUValues:
LFF2D:  LDA #$3F                ;
LFF2F:  STA PPUAddress          ;
LFF32:  LDA #$00                ;Set universal background color to black.
LFF34:  STA PPUAddress          ;
LFF37:  LDA #$0F                ;
LFF39:  STA PPUIOReg            ;

LFF3C:  LDA ActiveNmTbl         ;Get which nametable is supposed to be active.
LFF3E:  BNE SetNT1              ;Is it nametable 1? If so, branch to set.

SetNT0:
LFF40:  LDA #%10001000          ;Set nametable 0 as active nametable.
LFF42:  BNE SetScrollRegs       ;Branch always.

SetNT1:
LFF44:  LDA #%10001001          ;Set nametable 1 as active nametable.

SetScrollRegs:
LFF46:  STA PPUControl0         ;
LFF49:  LDA ScrollX             ;
LFF4B:  STA PPUScroll           ;Set scroll registers.
LFF4E:  LDA ScrollY             ;
LFF50:  STA PPUScroll           ;
LFF53:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;Unused.
LFF54:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFF64:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

;----------------------------------------------------------------------------------------------------

WaitForNMI:
LFF74:  LDA #$01                ;
LFF76:  STA NMIStatus           ;
LFF78:* LDA NMIStatus           ;Loop until NMI has completed.
LFF7A:  BNE -                   ;
LFF7C:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;Unused.
LFF7D:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LFF8D:  .byte $FF

;----------------------------------------------------------------------------------------------------

_DoReset:
LFF8E:  JMP DoReset             ;($FD86)Reset game.

;----------------------------------------------------------------------------------------------------

SetPRGBankAndSwitch:
LFF91:  STA ActiveBank          ;
LFF94:  NOP                     ;Store active PRG bank number-->
LFF95:  NOP                     ;and drop into the routine below.

MMC1LoadPRG:
LFF96:  STA MMCPRG              ;
LFF99:  LSR                     ;
LFF9A:  STA MMCPRG              ;
LFF9D:  LSR                     ;
LFF9E:  STA MMCPRG              ;
LFFA1:  LSR                     ;Change the program ROM bank.
LFFA2:  STA MMCPRG              ;
LFFA5:  LSR                     ;
LFFA6:  STA MMCPRG              ;
LFFA9:  NOP                     ;
LFFAA:  NOP                     ;
LFFAB:  RTS                     ;

MMC1LoadNT0:
LFFAC:  STA MMCCHR0             ;
LFFAF:  LSR                     ;
LFFB0:  STA MMCCHR0             ;
LFFB3:  LSR                     ;
LFFB4:  STA MMCCHR0             ;
LFFB7:  LSR                     ;Change nametable 0.
LFFB8:  STA MMCCHR0             ;
LFFBB:  LSR                     ;
LFFBC:  STA MMCCHR0             ;
LFFBF:  NOP                     ;
LFFC0:  NOP                     ;
LFFC1:  RTS                     ;

MMC1LoadNT1:
LFFC2:  STA MMCCHR1             ;
LFFC5:  LSR                     ;
LFFC6:  STA MMCCHR1             ;
LFFC9:  LSR                     ;
LFFCA:  STA MMCCHR1             ;
LFFCD:  LSR                     ;Change nametable 1.
LFFCE:  STA MMCCHR1             ;
LFFD1:  LSR                     ;
LFFD2:  STA MMCCHR1             ;
LFFD5:  NOP                     ;
LFFD6:  NOP                     ;
LFFD7:  RTS                     ;

;----------------------------------------------------------------------------------------------------

RESET:
LFFD8:  SEI                     ;Disable interrupts.
LFFD9:  INC MMCReset2           ;Reset MMC1 chip.
LFFDC:  JMP DoReset             ;($FD86)Continue with the reset process.

;----------------------------------------------------------------------------------------------------

;                   D    R    A    G    O    N    _    W    A    R    R    I    O    R
LFFDF:  .byte $80, $44, $52, $41, $47, $4F, $4E, $20, $57, $41, $52, $52, $49, $4F, $52, $20
LFFEF:  .byte $20, $56, $DE, $30, $70, $01, $04, $01, $0F, $07, $44

LFFFA:  .word NMI               ;($FE67)NMI vector.
LFFFC:  .word RESET             ;($FFD8)Reset vector.
LFFFE:  .word IRQ               ;($FD3A)IRQ vector.
