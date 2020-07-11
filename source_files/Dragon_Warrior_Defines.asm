;-------------------------------------[General Purpose Variables]------------------------------------

.alias GenByte00        $00     ;General use byte.
.alias GenByte01        $01     ;General use byte.

.alias GenPtr00         $00     ;General use pointer.
.alias GenPtr00LB       $00     ;General use pointer, lower byte.
.alias GenPtr00UB       $01     ;General use pointer, upper byte.

.alias GenWrd00         $00     ;General use word.
.alias GenWrd00LB       $00     ;General use word, lower byte.
.alias GenWrd00UB       $01     ;General use word, upper byte.

.alias GenByte22        $22     ;General use byte.

.alias GenPtr22         $22     ;General use pointer.
.alias GenPtr22LB       $22     ;General use pointer, lower byte.
.alias GenPtr22UB       $23     ;General use pointer, upper byte.

.alias GenByte24        $24     ;General use byte.

.alias GenByte2C        $2C     ;General use byte.

.alias GenByte3C        $3C     ;General use byte.
.alias GenByte3D        $3D     ;General use byte.

.alias GenPtr3C         $3C     ;General use pointer.
.alias GenPtr3CLB       $3C     ;General use pointer, lower byte.
.alias GenPtr3CUB       $3D     ;General use pointer, upper byte.

.alias GenWord3C        $3C     ;General use word.
.alias GenWord3CLB      $3C     ;General use word, lower byte.
.alias GenWord3CUB      $3D     ;General use word, upper byte.

.alias GenByte3E        $3E     ;General use byte.
.alias GenByte3F        $3F     ;General use byte.

.alias GenPtr3E         $3E     ;General use pointer.
.alias GenPtr3ELB       $3E     ;General use pointer, lower byte.
.alias GenPtr3EUB       $3F     ;General use pointer, upper byte.

.alias GenWord3E        $3E     ;General use word.
.alias GenWord3ELB      $3E     ;General use word, lower byte.
.alias GenWord3EUB      $3F     ;General use word, upper byte.

.alias GenByte42        $42     ;General use byte.
.alias GenByte43        $43     ;General use byte.

.alias GenPtr42         $42     ;General use pointer.
.alias GenPtr42LB       $42     ;General use pointer, lower byte.
.alias GenPtr42UB       $43     ;General use pointer, upper byte.

.alias GenWord42        $42     ;General use word.
.alias GenWord42LB      $42     ;General use word, lower byte.
.alias GenWord42UB      $43     ;General use word, upper byte.

;-----------------------------------------[Variable Defines]-----------------------------------------

.alias NMIStatus        $02     ;#$00 = in NMI(VBlank).
.alias PPUEntCount      $03     ;Number of entries load from PPU buffer to PPU.
.alias PPUBufCount      $04     ;Number of bytes to load from PPU buffer to PPU.
.alias ScrollX          $05     ;PPU scroll x position.
.alias ActiveNmTbl      $06     ;Active name table $#00= nametable0, #$01=nametable1.
.alias ScrollY          $07     ;PPU scroll y position.
.alias PPUDataByte      $08     ;Data byte to be stored in PPU.

.alias PPUBufPtr        $0A     ;Pointer to RAM buffer for PPU image.
.alias PPUBufPtrLB      $0A     ;Pointer to RAM buffer for PPU image, lower byte.
.alias PPUBufPtrUB      $0B     ;Pointer to RAM buffer for PPU image, upper byte.
.alias PPUAddrLB        $0A     ;Target address for PPU write, lower byte.
.alias PPUAddrUB        $0B     ;Target address for PPU write, upper byte.
.alias PalPtrLB         $0C     ;Pointer to PPU palette data, lower byte.
.alias PalPtrUB         $0D     ;Pointer to PPU palette data, upper byte.

.alias XPosFromCenter   $0F     ;Tile X position with respect to center of display. Signed.
.alias YPosFromCenter   $10     ;Tile Y position with respect to center of display. Signed.

.alias MapDatPtr        $11     ;Pointer to base address of map data.
.alias MapDatPtrLB      $11     ;Pointer to base address of map data, lower byte.
.alias MapDatPtrUB      $12     ;Pointer to base address of map data, upper byte.
.alias MapWidth         $13     ;Width of current map in blocks.
.alias MapHeight        $14     ;Height of current map in blocks. 
.alias BoundryBlock     $15     ;Block ID of for blocks beyond the map boundaries.
.alias MapType          $16     ;#$00-over world, #$10-town/castle, #$20-cave.

.alias CoverDatPtr      $17     ;Pointer to map covered area data.
.alias CoverDatLB       $17     ;Pointer to map covered area data, lower byte.
.alias CoverDatUB       $18     ;Pointer to map covered area data, upper byte.
.alias CoverStatus      $19     ;#$00=Not covered, #$08=Under cover.

.alias ThisTempIndex    $1A     ;Working index into temp buffer.
.alias DescEntry        $1A     ;Entry number for item description.

.alias TextEntry        $1A     ;Entry number within text block(0-15).
.alias TextBlock        $1B     ;Text block number(0-18).

.alias RowsRemaining    $1A     ;When displaying dialog, remaining rows in window.
.alias _ColsRemaining   $1B     ;When doing window calculations, cols remaining in current row.
.alias ColsRemaining    $1C     ;When displaying dialog, remaining chars in row.

.alias TxtRowNum        $1A     ;Target row in dialog window.
.alias TxtRowStart      $1B     ;Offset into target row(column).

.alias PPURowBytesLB    $1B     ;Stores lower number of bytes un a PPU row(32).
.alias PPURowBytesUB    $1C     ;Stores upper number of bytes un a PPU row(0).

.alias BCDByte0         $1A     ;
.alias BCDByte1         $1B     ;Used to convert binary word to BCD.
.alias BCDByte2         $1C     ;
.alias BCDResult        $1D     ;Hold 1 byte result of conversion.

.alias WndColLB         $1E     ;Number of columns in window used in mult, lower byte.
.alias WndColUB         $1F     ;Number of columns in window used in mult, upper byte(0).

.alias _WndCol          $20     ;Working Copy of current window column selected.
.alias _WndRow          $21     ;Working Copy of current window row selected.

.alias GameDatPtr       $22     ;Pointer for loading/saving game data.
.alias GameDatPtrLB     $22     ;Pointer for loading/saving game data, lower byte.
.alias GameDatPtrUB     $23     ;Pointer for loading/saving game data, upper byte.

.alias PlayerDatPtr     $22     ;Pointer for loading/saving player stats.
.alias PlayerDatPtrLB   $22     ;Pointer for loading/saving player stats, lower byte.
.alias PlayerDatPtrUB   $23     ;Pointer for loading/saving player stats, upper byte.

.alias WndLineBufIdx    $22     ;Index into window line buffer.
.alias AttribBufIndex   $23     ;Index into attribute table buffer

.alias WndTypeCopy      $23     ;Temporary copy of current window type.

.alias NPCXCheck        $22     ;X position to check for NPC.
.alias NPCYCheck        $23     ;Y position to check for NPC.
.alias NPCCounter       $24     ;Counter for finding direction of character sprites.
.alias NPCOffset        $25     ;Offset to NPC position data.
.alias NPCNewFace       $25     ;New direction NPC should face to talk to player.
.alias NPCNumber        $26     ;NPC being worked on.
.alias NPCSpriteCntr    $27     ;Counter used for loading NPC sprite data.
.alias NPCSprtRAMInd    $28     ;Index into sprite RAM for current NPC sprite.

.alias JMPFuncPtr       $0030   ;JUMP command for IRQ function pointer.
.alias _JMPFuncPtr      $30     ;JUMP command for IRQ function pointer.

.alias NewPRGBank       $30     ;Stores PRG bank to switch to.
.alias BankDatPtr       $30     ;Bank data pointer.
.alias BankDatPtrLB     $30     ;Bank data pointer, lower byte.
.alias BankDatPtrUB     $31     ;Bank data pointer, upper byte.
.alias BankPtrIndex     $31     ;Stores index into BankPointers table.
.alias BankPntr         $31     ;Bank function pointer.
.alias BankPntrLB       $31     ;Bank function pointer, lower byte.
.alias BankPntrUB       $32     ;Bank function pointer, upper byte.

.alias _BankFuncDatPtr  $33     ;Bank function data pointer.
.alias _BankFuncDatLB   $33     ;Bank function data pointer, lower byte.
.alias _BankFuncDatUB   $34     ;Bank function data pointer, upper byte.

.alias NMIPtr           $35     ;Used to check If MMC is being accessed during NMI.
.alias NMIPtrLB         $35     ;Special NMI check pointer, lower byte.
.alias NMIPtrUB         $36     ;Special NMI check pointer, upper byte.

.alias IRQStoreA        $37     ;Temp storage for A in IRQ routine.
.alias IRQStoreX        $38     ;Temp storage for X in IRQ routine.
.alias IRQStoreY        $39     ;Temp storage for Y in IRQ routine.

.alias CharXPos         $3A     ;Player's X position on current map in blocks.
.alias CharYPos         $3B     ;Player's Y position on current map in blocks.

.alias BufByteCntr      $3C     ;Buffer byte load counter.
.alias _EnNumber        $3C     ;Working copy of enemy number.

.alias CharYScrPos      $3C     ;Character sprite Y position on the screen.
.alias CharXScrPos      $3D     ;Character sprite X position on the screen.

.alias ShopIndex        $3C     ;Index into ShopItemsTbl for current shop items list.
.alias WrldMapXPos      $3D     ;World map X position calculation.

.alias LevelDatPtr      $3C     ;Pointer into BaseStatsTbl.
.alias PalModByte       $3C     ;Added to palette data to change it in some cases.
.alias LoadBGPal        $3D     ;#$00-skip loading BG palette, #$FF-Load BG palette.

.alias CoveredStsNext   $3D     ;Indicates the covered status after player movement.

.alias XPosFromLeft     $3C     ;Tile X position with respect to top left of display. 
.alias YPosFromTop      $3E     ;Tile Y position with respect to top left of display. 

.alias TargetResults    $3C     ;Stores results byte for target check.
.alias XTarget          $3C     ;X position to check for item, door, etc.
.alias YTarget          $3E     ;Y position to check for item, door, etc.

.alias NTXPos           $3C     ;Nametable X position to modify (#$00-#$3F, spans 2 nametables).
.alias NTYPos           $3E     ;Nametable Y position to modify (#$00-#$1E).

.alias ROMSrcPtr        $3C     ;ROM copy source pointer.
.alias ROMSrcPtrLB      $3C     ;ROM copy source pointer, lower byte.
.alias ROMSrcPtrUB      $3D     ;ROM copy source pointer, upper byte.

.alias RAMTrgtPtr       $3E     ;RAM copy target pointer.
.alias RAMTrgtPtrLB     $3E     ;RAM copy target pointer, lower byte.
.alias RAMTrgtPtrUB     $3F     ;RAM copy target pointer, upper byte.

.alias MultNum1LB       $3C     ;Multiply number 1, lower byte.
.alias MultNum1UB       $3D     ;Multiply number 1, upper byte.
.alias MultNum2LB       $3E     ;Multiply number 2, lower byte.
.alias MultNum2UB       $3F     ;Multiply number 2, upper byte.
.alias MultRsltLB       $40     ;Multiply results, lower byte.
.alias MultRsltUB       $41     ;Multiply results, upper byte.

.alias DivNum1LB        $3C     ;Divide number 1, lower byte.
.alias DivNmu1UB        $3D     ;Divide number 1, upper byte.
.alias DivNum2          $3E     ;Divide number 2.
.alias DivNum2NU        $3F     ;Divide number 2 (not used).
.alias DivQuotient      $3C     ;Divide results, quotient.
.alias DivRemainder     $40     ;Divide results, remainder.

.alias EnemyOffset      $3E     ;Offset used to get enemy from EnemyGroupsTbl.

.alias SpellFlagsLB     $3E     ;Stores bit flags for first 8 spells.
.alias SpellFlagsUB     $3F     ;Stores bit flags for last 2 spells in the LSBs.

.alias SprtPalPtr       $3E     ;Pointer to sprite palette data.
.alias SprtPalPtrLB     $3E     ;Pointer to sprite palette data, lower byte.
.alias SprtPalPtrUB     $3F     ;Pointer to sprite palette data, upper byte.

.alias NPCXPixelsLB     $3E     ;NPC X pixel coordinates, lower byte.
.alias NPCXPixelsUB     $3F     ;NPC X pixel coordinates, upper byte.
.alias NPCYPixelsLB     $40     ;NPC Y pixel coordinates, lower byte.
.alias NPCYPixelsUB     $41     ;NPC Y pixel coordinates, upper byte.

.alias SpellDescByte    $40     ;#$00-#$0A represents each one of the spells in ascending order.

.alias BGPalPtr         $40     ;Pointer to background palette data.
.alias BGPalPtrLB       $40     ;Pointer to background palette data, lower byte.
.alias BGPalPtrUB       $41     ;Pointer to background palette data, upper byte.

.alias CopyCounter      $40     ;Word used to count bytes copied from ROM to RAM.
.alias CopyCounterLB    $40     ;Copy counter, lower byte.
.alias CopyCounterUB    $41     ;Copy counter, upper byte.

.alias EnDatPtr         $40     ;Enemy data pointer.
.alias EnDatPtrLB       $40     ;Enemy data pointer, lower byte.
.alias EnDatPtrUB       $41     ;Enemy data pointer, upper byte.

.alias BlockDataPtr     $40     ;Pointer to block graphics data.
.alias BlockDataPtrLB   $40     ;Pointer to block graphics data, lower byte.
.alias BlockDataPtrUB   $41     ;Pointer to block graphics data, upper byte.

.alias CRCCopyLB        $40     ;Copy of saved game CRC, lower byte for verification purposes.
.alias CRCCopyUB        $41     ;Copy of saved game CRC, upper byte for verification purposes.

.alias MapBytePtr       $40     ;Pointer to map data byte.
.alias MapBytePtrLB     $40     ;Pointer to map data byte, lower byte.
.alias MapBytePtrUB     $41     ;Pointer to map data byte, upper byte.

.alias WrldMapPtr       $40     ;Pointer to overworld map row data.
.alias WrldMapPtrLB     $40     ;Pointer to overworld map row data, lower byte.
.alias WrldMapPtrUB     $41     ;Pointer to overworld map row data, upper byte.

.alias WindowBlock      $40     ;#$FF-No window data at selected block.
.alias NPCWndwSts       $41     ;#$FF-NPC on screen, #$00-NPC not on screen.

.alias _TargetX         $42     ;Target block, X position.
.alias _TargetY         $43     ;Target block, Y position.

.alias ThisNPCXPos      $42     ;Copy of current NPCs X block position on map.
.alias ThisNPCYPos      $43     ;Copy of current NPCs y block position on map.

.alias StatBonus        $42     ;When stat penalties are applied, any value here will 
                                ;be added in as a bonus. Potential bonus of 0-3 points.
.alias StatPenalty      $43     ;Lower 2 bits only. stat penalties work as follows:
                                ;If bit 0 is clear -> strength is reduced by 10%.
                                ;If bit 0 is set   -> max MP is reduced by 10%.
                                ;If bit 1 is clear -> agility is reduced by 10%.
                                ;If bit 1 is set   -> max HP is reduced by 10%.

.alias MapNumber        $45     ;Current map player is on.
.alias JoypadBit        $46     ;LSB Contains current bit read from joypad 1.
.alias JoypadBtns       $47     ;Captured button presses on controller 1.

.alias XFromLeftTemp    $48     ;Temporary storage for XPosFromLeft.
.alias YFromTopTemp     $49     ;Temporary storage for YPosFromTop.

.alias NTBlockX         $4A     ;Nametable X block position, #$00-#$1F(1/2 X tile position).
.alias NTBlockY         $4B     ;Nametable Y block position, #$00-#$0E(1/2 y tile position).
.alias BlkRemoveFlgs    $4C     ;Lower nibble is flags for tiles to keep when changing a map block.
                                ;1-upper left, 2-upper right, 4-lower left, 8-lower right.
.alias BridgeFlashCntr  $4C     ;Used to count palette flash cycles when rainbow bridge is created.
.alias TileCounter      $4D     ;Used to count tiles when modifying blocks.
.alias BlockClear       $4D     ;Is always 0. Maybe had some other function in Dragon's Quest.
.alias WndForeBack      $4D     ;#$FF=Background window, #$00=Foreground window(over another window).
.alias NPCLoopCounter   $4E     ;Counter for controlling NPC update loops.
.alias FrameCounter     $4F     ;Normally increments every frame. used for timing.

.alias CharLeftRight    $50     ;Controls character animations. bit 3 atlernates animations.

.alias _NPCXPos         $0051   ;NPC X block position on current map.
.alias _NPCYPos         $0052   ;NPC Y block position on current map.
.alias _NPCMidPos       $0053   ;NPC offset from current tile.

.alias NPCXPos          $51     ;Through $8A. NPC X block position on current map. Also NPC type.
.alias NPCYPos          $52     ;Through $8B. NPC Y block position on current map. Also NPC direction.
.alias NPCMidPos        $53     ;Through $8C. NPC offset from current tile. Used only when moving.

.alias GwaelinXPos      $8A     ;Princess Gwaelin's X position at the end of the game.
.alias GwaelinYPos      $8B     ;Princess Gwaelin's Y position at the end of the game.
.alias GwaelinOffset    $8C     ;Princess Gwaelin's moving offset at the end of the game.

.alias NPCUpdateCntr    $8D     ;Counts 0 to 4. Used to update NPCs.
.alias _CharXPos        $8E     ;Copy of player's X position.
.alias _CharYPos        $8F     ;Copy of player's Y position.
.alias CharXPixelsLB    $90     ;Player's X position in pixels, lower byte (CharXPos*16).
.alias CharXPixelsUB    $91     ;Player's X position in pixels, upper byte.
.alias IntroCounter     $91     ;Counter for intro routine.
.alias CharYPixelsLB    $92     ;Player's Y position in pixels, lower byte (CharYPos*16).
.alias CharYPixelsUB    $93     ;Player's Y position in pixels, upper byte.
.alias IntroPointer     $93     ;Data pointer for intro routines.
.alias CRCLB            $94     ;Saved game CRC value, lower byte.
.alias CRCUB            $95     ;Saved game CRC value, upper byte.
.alias RandNumLB        $94     ;Random number, lower byte.
.alias RandNumUB        $95     ;Random number, upper byte.
.alias StopNPCMove      $96     ;#$FF-Stop NPCs from moving, #$00-Allow NPCs to move.
.alias WndColPos        $97     ;Window column position, in tiles.
.alias WndRowPos        $98     ;Window row position, in tiles.
.alias BlockCounter     $98     ;Counts blocks placed when putting combat background on screen.

.alias BlockAddr        $99     ;Current block address in buffer.
.alias BlockAddrLB      $99     ;Current block address in buffer, lower byte.
.alias BlockAddrUB      $9A     ;Current block address in buffer, upper byte.

.alias DatPntr1         $99     ;
.alias DatPntr1LB       $99     ;Stores a pointer to the start of data tables.
.alias DatPntrlUB       $9A     ;

.alias StartSignedXPos  $9D     ;Starting X position in tiles of window row. signed from center.
.alias WndBlockWidth    $9E     ;Block width of window being removed.

.alias DialogPtr        $9F     ;Pointer to dialog text.
.alias DialogPtrLB      $9F     ;Pointer to dialog text, lower byte.
.alias DialogPtrUB      $A0     ;Pointer to dialog text, upper byte.

.alias WndDatPtr        $9F     ;Pointer to window data.
.alias WndDatPtrLB      $9F     ;Pointer to window data, lower byte.
.alias WndDatPtrUB      $A0     ;Pointer to window data, upper byte.

.alias WndFcnPtr        $00A1   ;Window function pointer.
.alias WndFcnLB         $A1     ;Window function pointer, lower byte.
.alias WndFcnUB         $A2     ;Window function pointer, upper byte.

.alias DescPtr          $A1     ;Pointer used for item and window descriptions.
.alias DescPtrLB        $A1     ;Description pointer, lower byte.
.alias DescPtrUB        $A2     ;Description pointer, upper byte.

.alias AttribPtr        $A1     ;Pointer used for attribute table data.
.alias AttribPtrLB      $A1     ;attribute table pointer, lower byte.
.alias AttribPtrUB      $A2     ;attribute table pointer, upper byte.

.alias _DescBuf         $00A3   ;Description buffer.
.alias DescBuf          $A3     ;Through $B4. Indexes used for item descriptions.

.alias DispName0        $B5     ;
.alias DispName1        $B6     ;First four bytes of name displayed in status window.
.alias DispName2        $B7     ;
.alias DispName3        $B8     ;
.alias GameStarted      $B9     ;Loaded with #$FA after game started and never used again.
.alias EndCreditCount   $BA     ;Counts the number of end credit screens that have been displayed.
.alias ExpLB            $BA     ;Current experience points, lower byte.
.alias ExpUB            $BB     ;Current experience points, upper byte.
.alias GoldLB           $BC     ;Current gold, lower byte.
.alias GoldUB           $BD     ;Current gold, upper bytee.
.alias EqippedItems     $BE     ;Current equipped items %WWWAAASS W-weapon, A-armor, S-shield
                                ;Value  Weapon           Armor            Shield
                                ;--------------------------------------------------------------------
                                ; 000   None             None             None
                                ; 001   Bamboo Pole      Clothes          Small Shield
                                ; 010   Club             Leather Armor    Large Shield
                                ; 011   Copper Sword     Chain Mail       Silver Shield
                                ; 100   Hand Axe         Half Plate       N/A
                                ; 101   Broad Sword      Full Plate       N/A
                                ; 110   Flame Sword      Magic Armor      N/A
                                ; 111   Erdrick's Sword  Erdrick's Armor  N/A
                                
                                ;Inventory
                                ;$00=None, $01=Torch, $02=Fairy Water, $03=Wings
                                ;$04=Dragon's Scale, $05=Fairy Flute, $06=Fighter's Ring
                                ;$07=Erdrick's Token, $08=Gwaelin's Love, $09=Cursed Belt
                                ;$0A=Slver Harp, $0B=Death Necklace, $0C=Stones of Sunlight                          
                                ;$0D=Staff of Rain, $0E=Rainbow Drop, $0F=Herb(can't be used).
                                ;--------------------------------------------------------------------
.alias InventoryKeys    $BF     ;Magic key count. Not part of regular inventory.
.alias InventoryHerbs   $C0     ;Herb count. Not part of regular inventory.
.alias InventoryPtr     $00C1   ;Inventory pointer.
.alias InventorySlot12  $C1     ;First two inventory slots.
.alias InventorySlot34  $C2     ;Second two inventory slots.
.alias InventorySlot56  $C3     ;Third two inventory slots.
.alias InventorySlot78  $C4     ;Fourth two inventory slots.
.alias HitPoints        $C5     ;Current hit points.
.alias MagicPoints      $C6     ;Current magic points.
.alias DisplayedLevel   $C7     ;Current level, for display only.
.alias DisplayedStr     $C8     ;Strength, for display only.
.alias DisplayedAgi     $C9     ;Agility, for display only.
.alias DisplayedMaxHP   $CA     ;Max hit points, for display only.
.alias DisplayedMaxMP   $CB     ;Max magic points, for display only.
.alias DisplayedAttck   $CC     ;Attack power, for display only.
.alias DisplayedDefns   $CD     ;Defense power, for display only.
.alias SpellFlags       $CE     ;Flags that keep track of the player's spells.
                                ;%00000001-Heal
                                ;%00000010-Hurt
                                ;%00000100-Sleep
                                ;%00001000-Radiant
                                ;%00010000-Stopspell
                                ;%00100000-Outside
                                ;%01000000-Return
                                ;%10000000-Repel
.alias ModsnSpells      $CF     ;Two more spell flags and stat enhancing items.
                                ;%00000001-Healmore Spell.
                                ;%00000010-Hurtmore Spell.
                                ;%00000100-Dragonlord castle secret passage found.
                                ;%00001000-Rainbow bridge created.
                                ;%00010000-Wearing Dragon's scale.
                                ;%00100000-Wearing Fighter's ring.
                                ;%01000000-Wearing Cursed belt.
                                ;%10000000-Wearing Death necklace.

.alias LightDiameter    $D0     ;Diameter in blocks of light around player in dungeons.                             
.alias PPUHorzVert      $D1     ;#$00=Write PPU data in vertical column(add #$20 every write).
                                ;non-zero=Write PPU data horizontally. 
.alias AddAttribData    $D1     ;#$00=Move attrib data to buffer. Non-zero=skip attrib table data.
                               
.alias WndTxtXCoord     $D2     ;X coordinant of current text byte relative to the window.  
.alias WndTxtYCoord     $D3     ;Y coordinant of current text byte relative to the window.                      

.alias RepeatCounter    $D6     ;Counts repeated PPU entry bytes.                           
.alias SpellToCast      $D7     ;Spell player or enemy is attempting to cast.
.alias WndSelResults    $D7     ;Stores selection results from a window.

.alias WndCol           $D8     ;Window colum currently selected.
.alias WndRow           $D9     ;Window row currently selected.

.alias RadiantTimer     $DA     ;Remaining time for radiant spell.
.alias RepelTimer       $DB     ;Remining repel spell time.

.alias DialogTemp       $DE     ;Dialog byte used for finding correct dialog.
.alias DescTemp         $DE     ;Temporary storage of item description byte.
.alias PlayerFlags      $DF     ;Additional player flags.
                                ;%00000001-Carrying Gwaelin.
                                ;%00000010-Gwaelin returned.
                                ;%00000100-Player received a death necklace.
                                ;%00001000-Player has been beyond the throne room.
                                ;%00010000-Player stopspelled.
                                ;%00100000-Enemy stopspelled.
                                ;%01000000-Enemy asleep.
                                ;%10000000-Player asleep.

.alias EnNumber         $E0     ;Enemy number. $00 through $27.
.alias ThisTile         $E0     ;Current block type player is standing on.
                                
.alias EnCurntHP        $E2     ;Enemy's current hit points.
.alias MjArmrHP         $E3     ;Increments every movement and increments HP every
                                ;3 steps if wearing magic armor.            
.alias StoryFlags       $E4     ;Flags that keep track of major game events.
                                ;%00000001-
                                ;%00000010-Golem defeated.
                                ;%00000100-Dragonlord defeated.
                                ;%00001000-Left throne room.
                                ;%00010000-
                                ;%00100000-
                                ;%01000000-Green dragon defeated.
                                ;%10000000-
.alias MessageSpeed     $E5     ;#$00-fast, #$01-normal, #$02-slow.

;--------------------------------------[Sound Engine Variables]--------------------------------------

.alias SQ1IndexLB       $E6     ;Current address to SQ1 music data.
.alias SQ1IndexUB       $E7     ;
.alias SQ2IndexLB       $E8     ;Current address to SQ2 music data.
.alias SQ2IndexUB       $E9     ;
.alias TriIndexLB       $EA     ;Current address to triangle music data.
.alias TriIndexUB       $EB     ;
.alias NoisIndexLB      $EC     ;Current address to noise SFX data.
.alias NoisIndexUB      $ED     ;

.alias SQ1ReturnLB      $EE     ;Return address for SQ1 music loop.
.alias SQ1ReturnUB      $EF     ;
.alias SQ2ReturnLB      $F0     ;Return address for SQ2 music loop.
.alias SQ2ReturnUB      $F1     ;
.alias TriReturnLB      $F2     ;Return address for triangle music loop.
.alias TriReturnUB      $F3     ;

.alias ChannelLength    $F4     ;#$00 it is not in use. Anything else is the remaining note time.
.alias ChannelQuiet     $F5     ;#Amount of quiet time between notes.

.alias SQ1Length        $F4     ;SQ1 channel in use, time left for current note.
.alias SQ1Quiet         $F5     ;SQ1 Quiet time between notes.
.alias SQ2Length        $F6     ;SQ2 channel in use, time left for current note.
.alias SQ2Quiet         $F7     ;SQ2 Quiet time between notes.
.alias TRILength        $F8     ;Triangle channel in use, time left for current note.
.alias TRIQuiet         $F9     ;TRI Quiet time between notes.
.alias SFXActive        $FA     ;Number of frames remaining in current SFX.
.alias Tempo            $FB     ;Controls overall speed of music.
.alias TempoCntr        $FC     ;Increments by Tempo every frame.
.alias NoteOffset       $FD     ;Index offset for note to play. Makes dungeon music lower.
.alias MusicTemp        $FE     ;Used as temp variable when doing sound calcs.
.alias SQ2Config        $FF     ;Hold config byte for SQ2 control register $4004.

;----------------------------------------------------------------------------------------------------
                                
.alias EnBaseAtt        $0100   ;Enemy base attack attibute.
.alias EnBaseDef        $0101   ;Enemy base defense attribute.
.alias EnBaseHP         $0102   ;Enemy base hit points.

.alias EnSpell          $0103   ;Enemy spells.
                                ;The enemy spells are broken into the upper and lower nibbles.
                                ;The upper nibble controls the sleep, stopspell, heal and
                                ;healmore spells.  Bits 4 and 5 control the percent the spell
                                ;will be cast:
                                ;00=0%, 01=25%, 10=50%, 11 = 75%.
                                ;Bits 6 and 7 control which spell:
                                ;00=sleep, 01=stopspell, 10=heal, 11=healmore.
                                ;The lower nibble controls the hurt, hurtmore, fire1 and fire2
                                ;spells.  Fire2 is only used by the final boss. Bits 0 and 1
                                ;control the percent the spell will be cast:
                                ;00=0%, 01=25%, 10=50%, 11 = 75%.
                                ;Bits 2 and 3 control which spell:
                                ;00=hurt, 01=hurtmore, 10=fire1, 11=fire2.

.alias BankFuncDatLB    $0103   ;Pointer to bank function data after BRK command, lower byte.
.alias BankFuncDatUB    $0104   ;Pointer to bank function data after BRK command, upper byte.                               
                                
.alias EnBaseAgi        $0104   ;Enemy base agility.
.alias EnBaseMDef       $0105   ;Enemy base magic defense.
.alias EnBaseExp        $0106   ;Enemy base experience.
.alias EnBaseGld        $0107   ;Enemy base gold.
                                
.alias Stack            $0110   ;Through $01FF. CPU stack.
.alias SpriteRAM        $0200   ;Through $02FF. Sprite DMA RAM.
.alias BlockRAM         $0300   ;Through $03FF. Multipurpose RAM for buffering.
.alias WinBufRAM        $0400   ;Through $07BF. Window data buffer. 32 by 30 bytes.  

;--------------------------------------[Hardware defines]--------------------------------------------

.alias PPUControl0      $2000   ;
.alias PPUControl1      $2001   ;
.alias PPUStatus        $2002   ;
.alias SPRAddress       $2003   ;PPU hardware control registers.
.alias SPRIOReg         $2004   ;
.alias PPUScroll        $2005   ;
.alias PPUAddress       $2006   ;
.alias PPUIOReg         $2007   ;

.alias SQ1Cntrl0        $4000   ;
.alias SQ1Cntrl1        $4001   ;SQ1 hardware control registers.
.alias SQ1Cntrl2        $4002   ;
.alias SQ1Cntrl3        $4003   ;

.alias SQ2Cntrl0        $4004   ;
.alias SQ2Cntrl1        $4005   ;SQ2 hardware control registers.
.alias SQ2Cntrl2        $4006   ;
.alias SQ2Cntrl3        $4007   ;

.alias TriangleCntrl0   $4008   ;
.alias TriangleCntrl1   $4009   ;Triangle hardware control registers.
.alias TriangleCntrl2   $400A   ;
.alias TriangleCntrl3   $400B   ;

.alias NoiseCntrl0      $400C   ;
.alias NoiseCntrl1      $400D   ;Noise hardware control registers.
.alias NoiseCntrl2      $400E   ;
.alias NoiseCntrl3      $400F   ;

.alias DMCCntrl0        $4010   ;
.alias DMCCntrl1        $4011   ;DMC hardware control registers.
.alias DMCCntrl2        $4012   ;
.alias DMCCntrl3        $4013   ;

.alias SPRDMAReg        $4014   ;Sprite RAM DMA register.
.alias APUCommonCntrl0  $4015   ;APU common control 1 register.
.alias CPUJoyPad1       $4016   ;Joypad1 register.
.alias APUCommonCntrl1  $4017   ;Joypad2/APU common control 2 register.

;------------------------------------------[Cartridge RAM]-------------------------------------------

.alias MMC1Config       $6001   ;Stores configuration for MMC1.
.alias ActiveNT0        $6002   ;Stores number of CHR ROM bank active in nametable 0.
.alias ActiveNT1        $6003   ;Stores number of CHR ROM bank active in nametable 1.
.alias ActiveBank       $6004   ;Stores number of lower PRG bank that is active.
.alias SndEngineStat    $6005   ;If not 0, sound engine is processing.

.alias DrgnLrdPal       $600A   ;Read only once and loads a special palette when
                                ;the dradonlord is defeated. The palette does not
                                ;seemed to be used for anything.

.alias DoorXPos         $600C   ;Through $601A. X and y positions of doors-->
.alias DoorYPos         $600D   ;Through $601B. opened on the current map.
.alias TrsrXPos         $601C   ;Through $602A. X and y positions of treasure-->
.alias TrsrYPos         $601D   ;Through $602B. chests picked up on the current map.
                                
.alias UpdateBGTiles    $602C   ;MSB set = update on-screen background tiles.

.alias MusicTrigger     $602E   ;Certain music spots trigger events. Only used in intro routine.
.alias CharDirection    $602F   ;Player's facing direction, 0-up, 1-right, 2-down, 3-left.
.alias SaveSelected     $6030   ;Save slot selected(0-2).
.alias OpnSltSelected   $6031   ;Open game slot selected for copying a saved game into.
.alias SaveGameCntr     $6032   

.alias _SaveBitMask     $6034   ;Working copy of saved games bitmasks.
.alias ValidSave1       $6035   ;#$C8=valid saved data, slot 1, #$00=not valid.
.alias ValidSave2       $6036   ;#$C8=valid saved data, slot 2, #$00=not valid.
.alias ValidSave3       $6037   ;#$C8=valid saved data, slot 3, #$00=not valid.
.alias SaveBitMask      $6038   ;Bit mask of valid save slots. uses 3 LSBs.
.alias SaveNumber       $6039   ;Save file number(0-2).
.alias ThisStrtStat     $603A   ;Determines if HP and MP are restored on start for current game.
.alias KenMasuta2       $603B   ;Through $6044. Stores Ken Masuta's name.
.alias StartStatus1     $6045   ;#$78=Full HP and MP on start, #$AB=Do not restore, Save game 1.
.alias StartStatus2     $6046   ;#$78=Full HP and MP on start, #$AB=Do not restore, Save game 2.
.alias StartStatus3     $6047   ;#$78=Full HP and MP on start, #$AB=Do not restore, Save game 3.
.alias CurrentGameDat   $6048   ;Through $6067. Game data for current game being played.
.alias SavedGame1       $6068   ;Through $61A7. Save game slot 1. Data repeated 10 times.
.alias SavedGame2       $61A8   ;Through $62E7. Save game slot 2. Data repeated 10 times.
.alias SavedGame3       $62E8   ;Through $6427. Save game slot 3. Data repeated 10 times.
.alias KenMasuta1       $6428   ;Through $6431. Stores Ken Masuta's name.
.alias CRCFail1         $6432   ;CRC failures for save game 1.
.alias CRCFail2         $6433   ;CRC failures for save game 2.
.alias CRCFail3         $6434   ;CRC failures for save game 3.
.alias Unused6435       $6435   ;Unused variable.

;------------------------------------[Text and window Variables]-------------------------------------

.alias WndUnused6006    $6006   ;Unused window variable.
.alias WndEraseHght     $6007   ;Window erase height in blocks.
.alias WndEraseWdth     $6008   ;Window erase width in tiles.
.alias WndErasePos      $6009   ;Window erase position in blocks, Y=upper nibble, X=lower nibble.

.alias WndLineBuf       $6436   ;Through $6471. 60 bytes. buffers 2 window tile rows.

.alias AttribTblBuf     $6496   ;Through $64A5. Attribute table buffer for 1 on-screen block row.

.alias WndWidthTemp     $64A6   ;Temp copy of WndWidth.
.alias _WndPosition     $64A7   ;Working copy of WndPosition.

.alias WndBlkTileRow    $64A9   ;Either #$02 or #$01. Which row of block is being processed.
.alias _WndWidth        $64AA   ;Working copy of WndWidth.
.alias WndUnused64AB    $64AB   ;Written to but never used.
.alias WndLineBufIndex  $64AC   ;Current index into window line buffer.
.alias WndAtrbBufIndex  $64AD   ;Current index into attribute table buffer.
.alias WndUnused64AE    $64AE   ;Written to but never used.

.alias DescLength       $64AF   ;Length in bytes of description string.
.alias IndMultByte      $64AF   ;Indexed multiplication multiplicand byte.
.alias DialogScrlY      $64AF   ;Screen coords Y offset while scrolling dialog text.

.alias DialogScrlInd    $64B0   ;Index into dialog buffer to write to PPU while scrolling.

.alias IndMultNum1      $64B0   ;Indexed multiplication, 1st multiplication byte.
.alias IndMultNum2      $64B1   ;Indexed multiplication, 2nd multiplication byte.

.alias WordBufIndex     $64B4   ;Search index into word buffer.

.alias WndNTRowOffset   $64B6   ;Tile offset in nametable row for start of window row.
.alias WndAtribDat      $64B6   ;Attribute table data byte.

.alias ScrnTxtXCoord    $64B6   ;X coordinant of current text byte relative to the screen.
.alias ScrnTxtYCoord    $64B7   ;Y coordinant of current text byte relative to the screen.
.alias WndBtnPresses    $64B8   ;Button presses captured while selection window is active.

.alias WndThisNTRow     $64B8   ;Number of tiles for window row on this nametable.
.alias WndNextNTRow     $64B9   ;Number of tiles for window row on next nametable.

.alias WndPPUAddrLB     $64BA   ;Lower byte PPU address for current window tile.
.alias WndPPUAddrUB     $64BB   ;Upper byte PPU address for current window tile.

.alias AtribBitsOfst    $64BE   ;Offset for attrib table bits in attrib table byte(0,2,4,6).
.alias AttribByte       $64BF   ;Attribute table data byte.

.alias WndAttribVal     $64C1   ;Attribute table value(#$00-#$03).
.alias _WndPPUAddrLB    $64C2   ;Working copy of nametable address, lower byte.
.alias _WndPPUAddrUB    $64C3   ;Working copy of nametable address, upper byte.
.alias WndAtribAdrLB    $64C4   ;Attribute table address, lower byte.
.alias WndAtribAdrUB    $64C5   ;Attribute table address, upper byte.
.alias DispName4        $64C6   ;
.alias DispName5        $64C7   ;Last four bytes of name.
.alias DispName6        $64C8   ;
.alias DispName7        $64C9   ;

.alias TempBuffer       $64CA   ;Through $64D5. 13 bytes. For BCD conversion and other small stuff.

.alias WindowType       $64DC   ;Window type byte.
.alias WorkTile         $64DD   ;Current tile pattern used for building windows.
.alias WndCcontrol      $64DE   ;Retreived control byte from window data table.
.alias WndParam         $64DF   ;Parameters for window, such as number of times to repeat, etc.

.alias WndXPosAW        $64E0   ;Current X position after current word is taken into account.

.alias WndXPos          $64E0   ;Current X position in window.
.alias WndYPos          $64E1   ;Current Y position in window(current tile row being built).
.alias WndCounter       $64E2   ;Counter used when building window rows.

.alias SubBufLength     $64E2   ;Sub string buffer length.

.alias WndWidth         $64E3   ;Window width in tiles.
.alias WndHeightblks    $64E4   ;Window height in blocks (block is 2X2 tiles).
.alias WndHeight        $64E5   ;Window height in tiles.
.alias WndPosition      $64E6   ;Window screen coordinates in blocks. Y in upper nibble, X in lower.
.alias WndColumns       $64E7   ;Window columnns. Indicates how many tiles between columns.
.alias WndDatIndex      $64E8   ;Index into window data table.
.alias WndRepeatIndex   $64E9   ;Index in window data to return to for variable height windows.
.alias WndBuildRow      $64EA   ;When building window on screen, keeps track of current block height.
.alias WndCursorHome    $64EB   ;Home position of cursor. X in upper nibble, Y in lower.
.alias WndOptions       $64EC   ;Various window options.
.alias WndDescHalf      $64ED   ;#$00=on first part of description, #$01=on second part.
.alias WndThisDesc      $64EE   ;In variable height windows, index to current item description.
.alias WndDescIndex     $64EF   ;Index into description tables.
.alias WndUnused1       $64F0   ;Unused window variable.

.alias WndCursorXPos    $64F2   ;Cursor X position in tiles in current selection window.
.alias WndCursorYPos    $64F3   ;Cursor Y position in tiles in current selection window.
.alias WndUnused64F4    $64F4   ;Written to but never used.
.alias WndCursorYHome   $64F5   ;Home Y coord for cursor.
.alias WndBuildPhase    $64F6   ;Window build phase. MSB set-phase 1, bit 6 set-phase 2.

.alias WndUnused64FB    $64FB   ;Written to but never used.

.alias WndNameIndex     $6504   ;Index into name string when creating player's name.
.alias WndUnused6505    $6505   ;Written to but never used.
.alias WndSelNumCols    $6506   ;Number of columns for command windows and alphabet window.
.alias WndBtnRetrig     $6507   ;Controls retrigger time for button presses in windows.

.alias TxtLineSpace     $6509   ;Always #$08. single spaced lines.
.alias TxtIndent        $650A   ;Number if spaces to indent text line.
.alias WrkBufBytsDone   $650B   ;Keeps track of how many work buffer bytes have been processed.
.alias Dialog00         $650C   ;Set to 0 on dialog init and never changed.
.alias WordBufLen       $650D   ;Length of word buffer.
.alias DialogEnd        $650E   ;#$FF=dialog end.

.alias Unused6510       $6510   ;Written to but never read.
.alias Unused6511       $6511   ;Written to but never read.
.alias Unused6512       $6512   ;Written to but never read.
.alias Unused6513       $6513   ;Written to but never read.
.alias WordBuffer       $6514   ;Through $652B. 24 bytes. Buffers a single word.
.alias WorkBuffer       $652C   ;Through $6553. 40 bytes. Sub string work buffer.
.alias NameBuffer       $6554   ;Through $655C. 9  bytes. Buffer for storing player's name.

.alias DialogOutBuf     $657C   ;Through $662B. 176 bytes. Final dialog output buffer.

;------------------------------------------[MMC Registers]-------------------------------------------

.alias MMCCfg           $9FFF   ;MMC1 configuration.
.alias MMCPRG           $FFFF   ;MMC1 PRG RAM.
.alias MMCCHR0          $BFFF   ;MMC1 CHR0 RAM.
.alias MMCCHR1          $DFFF   ;MMC1 CHR1 RAM.
.alias MMCReset1        $BFDF   ;Resets MMC1 configuration.
.alias MMCReset2        $FFDF   ;Resets MMC1 configuration.

;--------------------------------------------[Constants]---------------------------------------------

;Player flags.
.alias F_GOT_GWAELIN    $01     ;Carrying Gwaelin.
.alias F_RTN_GWAELIN    $02     ;Gwaelin returned.
.alias F_GOLEM_DEAD     $02     ;Golem defeated.
.alias F_DONE_GWAELIN   $03     ;Gwaelin being carried or saved.
.alias F_DGNLRD_DEAD    $04     ;Dragonlord defeated.
.alias F_PSG_FOUND      $04     ;Passage behind dragonlord throne found.
.alias F_DTH_NCK_FOUND  $04     ;Player found the death necklace.
.alias F_RNBW_BRDG      $08     ;Rainbow bridge created.
.alias F_LEFT_THROOM    $08     ;Left throne room and started quest.
.alias F_DRGSCALE       $10     ;Wearing dragon scale.
.alias F_PLR_STOPSPEL   $10     ;Player stopspelled.
.alias F_EN_STOPSPEL    $20     ;Enemy stopspelled.
.alias F_FTR_RING       $20     ;Wearing the fighter's ring.
.alias F_GDRG_DEAD      $40     ;Green dragon defeated.
.alias F_CRSD_BELT      $40     ;Wearing cursed belt.
.alias F_EN_ASLEEP      $40     ;Enemy is asleep.
.alias F_PLR_ASLEEP     $80     ;Player is asleep.
.alias F_DTH_NECKLACE   $80     ;Wearing death necklace.

;Player's weapon, armor and shield.
.alias WP_NONE          $00     ;No weapon.
.alias WP_BAMBOO        $20     ;Bamboo pole.
.alias WP_CLUB          $40     ;Club.
.alias WP_CPR_SWRD      $60     ;Copper sword.
.alias WP_HAND_AX       $80     ;Hand axe.
.alias WP_BRD_SWRD      $A0     ;Broad sword.
.alias WP_FLM_SWRD      $C0     ;Flame sword.
.alias WP_ERDK_SWRD     $E0     ;Erdrick's sword.
.alias AR_NONE          $00     ;No armor.
.alias AR_CLOTHES       $04     ;Clothes.
.alias AR_LTHR_ARMR     $08     ;Leather armor.
.alias AR_CHAIN_MAIL    $0C     ;Chain mail.
.alias AR_HALF_PLATE    $10     ;Half plate.
.alias AR_FULL_PLATE    $14     ;Full plate.
.alias AR_MAGIC_ARMR    $18     ;Magic armor.
.alias AR_ERDK_ARMR     $1C     ;Erdrick's armor.
.alias SH_NONE          $00     ;No shield.
.alias SH_SMLL_SHLD     $01     ;Small shield.
.alias SH_LRG_SHLD      $02     ;Large shield.
.alias SH_SLVR_SHLD     $03     ;Silver shield.
.alias WP_WEAPONS       $E0     ;Bitmask for weapons.
.alias AR_ARMOR         $1C     ;Bitmask for armor.
.alias SH_SHIELDS       $03     ;Bitmask for shields.

;Player direction
.alias DIR_UP           $00     ;Player facing up.
.alias DIR_RIGHT        $01     ;Player facing right.
.alias DIR_DOWN         $02     ;Player facing down.
.alias DIR_LEFT         $03     ;Player facing left.

;NPC direction
.alias NPC_UP           $00     ;NPC facing up.
.alias NPC_RIGHT        $20     ;NPC facing right.
.alias NPC_DOWN         $40     ;NPC facing down.
.alias NPC_LEFT         $60     ;NPC facing left.

;Player levels.
.alias LVL_01           $01     ;Experience level 01.
.alias LVL_02           $02     ;Experience level 02.
.alias LVL_03           $03     ;Experience level 03.
.alias LVL_04           $04     ;Experience level 04.
.alias LVL_05           $05     ;Experience level 05.
.alias LVL_06           $06     ;Experience level 06.
.alias LVL_07           $07     ;Experience level 07.
.alias LVL_08           $08     ;Experience level 08.
.alias LVL_09           $09     ;Experience level 09.
.alias LVL_10           $0A     ;Experience level 10.
.alias LVL_11           $0B     ;Experience level 11.
.alias LVL_12           $0C     ;Experience level 12.
.alias LVL_13           $0D     ;Experience level 13.
.alias LVL_14           $0E     ;Experience level 14.
.alias LVL_15           $0F     ;Experience level 15.
.alias LVL_16           $10     ;Experience level 16.
.alias LVL_17           $11     ;Experience level 17.
.alias LVL_18           $12     ;Experience level 18.
.alias LVL_19           $13     ;Experience level 19.
.alias LVL_20           $14     ;Experience level 20.
.alias LVL_21           $15     ;Experience level 21.
.alias LVL_22           $16     ;Experience level 22.
.alias LVL_23           $17     ;Experience level 23.
.alias LVL_24           $18     ;Experience level 24.
.alias LVL_25           $19     ;Experience level 25.
.alias LVL_26           $1A     ;Experience level 26.
.alias LVL_27           $1B     ;Experience level 27.
.alias LVL_28           $1C     ;Experience level 28.
.alias LVL_29           $1D     ;Experience level 29.
.alias LVL_30           $1E     ;Experience level 30.

;Index to level 30 in the level up table.
.alias LVL_TBL_LAST     $3A     ;2 bytes per level up table entry.

;Inventory items.
.alias ITM_NONE         $00     ;No item.
.alias ITM_TORCH        $01     ;Torch.
.alias ITM_FRY_WATER    $02     ;Fairy water.
.alias ITM_WINGS        $03     ;Wyvern wings.
.alias ITM_DRG_SCALE    $04     ;Dragon scale.
.alias ITM_FRY_FLUTE    $05     ;Fairy flute.
.alias ITM_FTR_RING     $06     ;Fighter's ring.
.alias ITM_ERDRICK_TKN  $07     ;Erdrick's token.
.alias ITM_GWAELIN_LVE  $08     ;Gwaelin's love.
.alias ITM_CRSD_BELT    $09     ;Cursed belt.
.alias ITM_SLVR_HARP    $0A     ;Silver harp.
.alias ITM_DTH_NEKLACE  $0B     ;Death necklace.
.alias ITM_STNS_SNLGHT  $0C     ;Stones of sunlight.
.alias ITM_STFF_RAIN    $0D     ;Staff of rain.
.alias ITM_RNBW_DROP    $0E     ;Rainbow drop.
.alias ITM_FOUND_HI     $0F     ;Item is in inventory, high nibble.
.alias ITM_FOUND_LO     $F0     ;Item is in inventory, low nibble.
.alias ITM_NOT_FOUND    $FF     ;Item is not in inventory.
.alias ITM_END          $FF     ;End of item list.

;Used inventory items.
.alias INV_NONE         $01     ;Player has no inventory.
.alias INV_HERB         $02     ;Herb.
.alias INV_KEY          $03     ;key.
.alias INV_TORCH        $04     ;Torch.
.alias INV_FAIRY        $05     ;Fairy water.
.alias INV_WINGS        $06     ;Wyvern wings.
.alias INV_SCALE        $07     ;Dragon's scale.
.alias INV_FLUTE        $08     ;Fairy flute.
.alias INV_RING         $09     ;Fighter's ring.
.alias INV_TOKEN        $0A     ;Erdrick's token.
.alias INV_LOVE         $0B     ;Gwaelin's love.
.alias INV_BELT         $0C     ;Cursed belt.
.alias INV_HARP         $0D     ;Silver harp.
.alias INV_NECKLACE     $0E     ;Death necklace.
.alias INV_STONES       $0F     ;Stones of sunlight.
.alias INV_STAFF        $10     ;Staff of rain.
.alias INV_DROP         $11     ;Rainbow drop.

;Controller bits.
.alias IN_A             $01     ;A button.
.alias IN_B             $02     ;B button.
.alias IN_A_OR_B        $03     ;A or B button.
.alias IN_SELECT        $04     ;Select button.
.alias IN_START         $08     ;Start button.
.alias IN_UP            $10     ;Up button.
.alias IN_DOWN          $20     ;Down button.
.alias IN_LEFT          $40     ;Left button.
.alias IN_RIGHT         $80     ;Right button.
.alias IN_SEL_STRT      $0C     ;Select and start buttons.

;Enemies.
.alias EN_SLIME         $00     ;Slime.
.alias EN_RSLIME        $01     ;Red slime.
.alias EN_DRAKEE        $02     ;Drakee.
.alias EN_GHOST         $03     ;Ghost.
.alias EN_MAGICIAN      $04     ;Magician.
.alias EN_MAGIDRAKE     $05     ;Magidrakee.
.alias EN_SCORPION      $06     ;Scorpion.
.alias EN_DRUIN         $07     ;Druin.
.alias EN_POLTERGEIST   $08     ;Poltergeist.
.alias EN_DROLL         $09     ;Droll.
.alias EN_DRAKEEMA      $0A     ;Drakeema.
.alias EN_SKELETON      $0B     ;Skeleton.
.alias EN_WARLOCK       $0C     ;Warlock.
.alias EN_MSCORPION     $0D     ;Metal scorpion.
.alias EN_WOLF          $0E     ;Wolf.
.alias EN_WRAITH        $0F     ;Wraith.
.alias EN_MSLIME        $10     ;Metal slime.
.alias EN_SPECTER       $11     ;Specter.
.alias EN_WOLFLORD      $12     ;Wolflord.
.alias EN_DRUINLORD     $13     ;Druinlord.
.alias EN_DROLLMAGI     $14     ;Drollmagi.
.alias EN_WYVERN        $15     ;Wyvern.
.alias EN_RSCORPION     $16     ;Rouge scorpion.
.alias EN_WKNIGHT       $17     ;Wraith knight.
.alias EN_GOLEM         $18     ;Golem.
.alias EN_GOLDMAN       $19     ;Goldman.
.alias EN_KNIGHT        $1A     ;Knight.
.alias EN_MAGIWYVERN    $1B     ;Magiwyvern.
.alias EN_DKNIGHT       $1C     ;Demon knight.
.alias EN_WEREWOLF      $1D     ;Werewolf.
.alias EN_GDRAGON       $1E     ;Green dragon.
.alias EN_STARWYVERN    $1F     ;Starwyvern.
.alias EN_WIZARD        $20     ;Wizard.
.alias EN_AXEKNIGHT     $21     ;Axe knight.
.alias EN_BDRAGON       $22     ;Blue dragon.
.alias EN_STONEMAN      $23     ;Stoneman.
.alias EN_ARMORKNIGHT   $24     ;Armored knight.
.alias EN_RDRAGON       $25     ;Red dragon.
.alias EN_DRAGONLORD1   $26     ;Dragonlord, initial form.
.alias EN_DRAGONLORD2   $27     ;Dragonlord, final form.

;Maps.
.alias MAP_OVERWORLD    $01     ;Overworld map.
.alias MAP_DLCSTL_GF    $02     ;Dragonlord castle, ground floor.
.alias MAP_HAUKSNESS    $03     ;Hauksness.
.alias MAP_TANTCSTL_GF  $04     ;Tantagel castle, ground floor.
.alias MAP_THRONEROOM   $05     ;Tantagel castle, throne room.
.alias MAP_DLCSTL_BF    $06     ;Dragonlord castle, bottom floor.
.alias MAP_KOL          $07     ;Kol.
.alias MAP_BRECCONARY   $08     ;Brecconary.
.alias MAP_GARINHAM     $09     ;Garinham.
.alias MAP_CANTLIN      $0A     ;Cantlin.
.alias MAP_RIMULDAR     $0B     ;Rimuldar.
.alias MAP_TANTCSTL_SL  $0C     ;Tantagel castle, sublevel.
.alias MAP_RAIN         $0D     ;Staff of rain cave.
.alias MAP_RAINBOW      $0E     ;Rainbow drop cave.
.alias MAP_DLCSTL_SL1   $0F     ;Dragonlord castle, sublevel 1.
.alias MAP_DLCSTL_SL2   $10     ;Dragonlord castle, sublevel 2.
.alias MAP_DLCSTL_SL3   $11     ;Dragonlord castle, sublevel 3.
.alias MAP_DLCSTL_SL4   $12     ;Dragonlord castle, sublevel 4.
.alias MAP_DLCSTL_SL5   $13     ;Dragonlord castle, sublevel 5.
.alias MAP_DLCSTL_SL6   $14     ;Dragonlord castle, sublevel 6.
.alias MAP_SWAMPCAVE    $15     ;Swamp cave.
.alias MAP_RCKMTN_B1    $16     ;Rock mountain cave, B1.
.alias MAP_RCKMTN_B2    $17     ;Rock mountain cave, B2.
.alias MAP_CVGAR_B1     $18     ;Cave of Garinham, B1.
.alias MAP_CVGAR_B2     $19     ;Cave of Garinham, B2.
.alias MAP_CVGAR_B3     $1A     ;Cave of Garinham, B3.
.alias MAP_CVGAR_B4     $1B     ;Cave of Garinham, B4.
.alias MAP_ERDRCK_B1    $1C     ;Erdrick's cave B1.
.alias MAP_ERDRCK_B2    $1D     ;Erdrick's cave B2.

;Music/Sounds.
.alias MSC_NOSOUND      $00     ;No sound.
.alias MSC_INTRO        $01     ;Intro music.
.alias MSC_THRN_ROOM    $02     ;Throne room castle music.
.alias MSC_TANTAGEL2    $03     ;Tantagel 2 castle music.
.alias MSC_VILLAGE      $04     ;Village/pre-game music.
.alias MSC_OUTDOOR      $05     ;Outdoor music.
.alias MSC_DUNGEON1     $06     ;Dungeon 1 music.
.alias MSC_DUNGEON2     $07     ;Dungeon 2 music.
.alias MSC_DUNGEON3     $08     ;Dungeon 3 music.
.alias MSC_DUNGEON4     $09     ;Dungeon 4 music.
.alias MSC_DUNGEON5     $0A     ;Dungeon 5 music.
.alias MSC_DUNGEON6     $0B     ;Dungeon 6 music.
.alias MSC_DUNGEON7     $0C     ;Dungeon 7 music.
.alias MSC_DUNGEON8     $0D     ;Dungeon 8 music.
.alias MSC_ENTR_FGHT    $0E     ;Enter fight music.
.alias MSC_END_BOSS     $0F     ;End boss music.
.alias MSC_END          $10     ;End music.
.alias MSC_SILV_HARP    $11     ;Silver harp music.
.alias MSC_FRY_FLUTE    $12     ;Fairy flute music.
.alias MSC_RNBW_BRDG    $13     ;Rainbow bridge music.
.alias MSC_DEATH        $14     ;Player death music.
.alias MSC_INN          $15     ;Inn music.
.alias MSC_PRNCS_LOVE   $16     ;Princess Gwaelin's love music.
.alias MSC_CURSED       $17     ;Cursed Music.
.alias MSC_REG_FGHT     $18     ;Regular fight music.
.alias MSC_VICTORY      $19     ;Victory music.
.alias MSC_LEVEL_UP     $1A     ;Level up music.
.alias SFX_FFDAMAGE     $80     ;Force field damage SFX.
.alias SFX_WVRN_WNG     $81     ;Wyvern wing SFX.
.alias SFX_STAIRS       $82     ;Stairs SFX.
.alias SFX_RUN          $83     ;Run away SFX.
.alias SFX_SWMP_DMG     $84     ;Swamp damage SFX.
.alias SFX_MENU_BTN     $85     ;Menu button SFX.
.alias SFX_CONFIRM      $86     ;Confirmation SFX.
.alias SFX_ENMY_HIT     $87     ;Enemy hit SFX.
.alias SFX_EXCLNT_MOVE  $88     ;Excellent move SFX.
.alias SFX_ATTACK       $89     ;Attack SFX.
.alias SFX_PLYR_HIT1    $8A     ;Player hit 1 SFX.
.alias SFX_PLYR_HIT2    $8B     ;Player hit 2 SFX.
.alias SFX_ATCK_PREP    $8C     ;Attack prep SFX.
.alias SFX_MISSED1      $8D     ;Missed 1 SFX.
.alias SFX_MISSED2      $8E     ;Missed 2 SFX.
.alias SFX_WALL_BUMP    $8F     ;Wall bump SFX.
.alias SFX_TEXT         $90     ;Text SFX.
.alias SFX_SPELL        $91     ;Spell cast SFX.
.alias SFX_RADIANT      $92     ;Radiant spell SFX.
.alias SFX_TRSR_CHEST   $93     ;Open chest SFX.
.alias SFX_DOOR         $94     ;Open door SFX.
.alias SFX_FIRE         $95     ;Breath fire SFX.

;Sound control bytes.
.alias MCTL_SQ1_SW      $00     ;Index to SQ1 channel software regs.
.alias MCTL_SQ2_SW      $02     ;Index to SQ2 channel software regs.
.alias MCTL_TRI_SW      $04     ;Index to TRI channel software regs.
.alias MCTL_NOIS_SW     $06     ;Index to noise channel software regs.
.alias MCTL_SQ1_HW      $00     ;Index to SQ1 channel hardware regs.
.alias MCTL_SQ2_HW      $04     ;Index to SQ2 channel hardware regs.
.alias MCTL_TRI_HW      $08     ;Index to TRI channel hardware regs.
.alias MCTL_DMC_HW      $10     ;Index to DMC channel hardware regs (not used).
.alias MCTL_NOTE        $80     ;*2 is index into note table to load musical note.
.alias MCTL_NOISE_CFG   $E0     ;Noise channel period config byte.
.alias MCTL_END_SPACE   $F6     ;Stop adding quiet time between notes.
.alias MCTL_ADD_SPACE   $F7     ;Add quiet time between notes.
.alias MCTL_NOISE_VOL   $F8     ;Noise volume control byte.
.alias MCTL_NOTE_OFST   $F9     ;Note offset control byte.
.alias MCTL_CNTRL1      $FA     ;Channel control 1 byte.
.alias MCTL_CNTRL0      $FB     ;Channel control 0 byte.
.alias MCTL_NO_OP       $FC     ;Skip byte and move to the next byte.
.alias MCTL_RETURN      $FD     ;Return to old music data address.
.alias MCTL_JUMP        $FE     ;Jump to new music data address.
.alias MCTL_TEMPO       $FF     ;Change music tempo.

;Nibble bit masks.
.alias NBL_LOWER        $0F     ;Lower nibble.
.alias NBL_UPPER        $F0     ;Upper nibble.

;Message speed.
.alias MSG_FAST         $00     ;Fast message speed.
.alias MSG_NORMAL       $01     ;Normal message speed.
.alias MSG_SLOW         $02     ;Slow message speed.

;PRG banks.
.alias PRG_BANK_0       $00     ;PRG bank 0
.alias PRG_BANK_1       $01     ;PRG bank 1
.alias PRG_BANK_2       $02     ;PRG bank 2
.alias PRG_BANK_3       $03     ;PRG bank 3
.alias PRG_B3_NO_RAM    $13     ;PRG bank 3, disable PRG RAM.

;CHR banks.
.alias CHR_BANK_0       $00     ;CHR bank 0
.alias CHR_BANK_1       $01     ;CHR bank 1
.alias CHR_BANK_2       $02     ;CHR bank 2
.alias CHR_BANK_3       $03     ;CHR bank 3

;Spells
.alias SPL_HEAL         $00     ;Heal.
.alias SPL_HURT         $01     ;Hurt
.alias SPL_SLEEP        $02     ;Sleep.
.alias SPL_RADIANT      $03     ;Radiant.
.alias SPL_STOPSPELL    $04     ;Stopspell.
.alias SPL_OUTSIDE      $05     ;Outside.
.alias SPL_RETURN       $06     ;Return.
.alias SPL_REPEL        $07     ;Repel.
.alias SPL_HEALMORE     $08     ;Healmore.
.alias SPL_HURTMORE     $09     ;Hurtmore.

;Text control characters and other misc. characters.
.alias TXT_LWR_N        $17     ;Lowercase n.
.alias TXT_LWR_S        $1C     ;Lowercase s.
.alias TXT_UPR_A        $24     ;Uppercase A.
.alias TXT_UPR_E        $28     ;Uppercase E.
.alias TXT_UPR_I        $2C     ;Uppercase I.
.alias TXT_UPR_O        $32     ;Uppercase O.
.alias TXT_UPR_U        $38     ;Uppercase U.
.alias TXT_APOS         $40     ;Apostrophe.
.alias TXT_PERIOD       $47     ;Period.
.alias TXT_COMMA        $48     ;Comma.
.alias TXT_DASH         $49     ;Dash.
.alias TXT_QUESTION     $4B     ;Question mark.
.alias TXT_EXCLAIM      $4C     ;Exclaimation point.
.alias TXT_CLS_PAREN    $4E     ;Closed parenthesis.
.alias TXT_OPN_PAREN    $4F     ;Open parenthesis.
.alias TXT_OPN_QUOTE    $50     ;Open quote.
.alias TXT_PRD_QUOTE    $52     ;Period followed by and end quote.
.alias TXT_INDENT       $57     ;Indent character. Causes subsequent lines to be indented.
.alias TXT_BLANK1       $60     ;Blank space.
.alias TXT_PLRL         $EF     ;Prints the letter " s" or " " (space).
.alias TXT_PNTS         $F0     ;Prints the word " Point" or " Points".
.alias TXT_ENM2         $F1     ;An enemy's name preceeded by 'a' or 'an'.
.alias TXT_DESC         $F2     ;Object description preceeded by 'a' or 'an'.
.alias TXT_AMTP         $F3     ;Displays a numeric value followed by "Point" or "Points".
.alias TXT_ENMY         $F4     ;An enemy's name.
.alias TXT_AMNT         $F5     ;Displays a numeric value.
.alias TXT_SPEL         $F6     ;A spell's name.
.alias TXT_ITEM         $F7     ;An item's name.
.alias TXT_NAME         $F8     ;The player's name.
.alias TXT_COPY         $F9     ;Copy description buffer to work buffer.
.alias TXT_SUBEND       $FA     ;End of substring contents.
.alias TXT_WAIT         $FB     ;Wait for the user to press a button.
.alias TXT_END1         $FC     ;End of text entry marker.
.alias TXT_NEWL         $FD     ;New line.
.alias TXT_NOP          $FE     ;Byte skipped while processing.
.alias TXT_END2         $FF     ;End of text entry marker.

;Intro/end control bytes.
.alias END_RPT          $F7     ;Loop control byte.
.alias END_TXT_END      $FC     ;End marker for text data.
.alias END_RPT_END      $FD     ;End marker for repeated data.

;Window types.
.alias WND_POPUP        $00     ;Pop-up window with name, level, HP, MP gold and experience.
.alias WND_STATUS       $01     ;Status window.
.alias WND_DIALOG       $02     ;Dialog window.
.alias WND_CMD_NONCMB   $03     ;Command window, non-combat.
.alias WND_CMD_CMB      $04     ;Command window, combat.
.alias WND_SPELL1       $05     ;Spell window, not used.
.alias WND_SPELL2       $06     ;Spell window, points to same window data as above.
.alias WND_INVTRY1      $07     ;Inventory window, player inventory.
.alias WND_INVTRY2      $08     ;Inventory window, Shop inventory.
.alias WND_YES_NO1      $09     ;Yes/no selection window, variant 1.
.alias WND_BUY_SELL     $0A     ;Buy/sell window.
.alias WND_ALPHBT       $0B     ;Alphabet window.
.alias WND_MSG_SPEED    $0C     ;Message speed window.
.alias WND_INPT_NAME    $0D     ;Input name window.
.alias WND_NM_ENTRY     $0E     ;Name entry window.
.alias WND_CNT_CH_ER    $0F     ;Continue, change, erase window.
.alias WND_FULL_MNU     $10     ;Full menu window.
.alias WND_NEW_QST      $11     ;Begin new quest window.
.alias WND_LOG_1_1      $12     ;Log list window, only entry 1, variant 1.
.alias WND_ERASE        $20     ;Erase log window.
.alias WND_YES_NO2      $21     ;Yes/no selection window, variant 2.

;Description entries.
.alias DSC_NONE         $00     ;No text.
.alias DSC_BMB_POLE     $01     ;Bamboo pole text.
.alias DSC_CLUB         $02     ;Club text.
.alias DSC_CPR_SWD      $03     ;Copper sword text.
.alias DSC_HND_AXE      $04     ;Hand Axe text.
.alias DSC_BROAD_SWD    $05     ;Broad sword text.
.alias DSC_FLAME_SWD    $06     ;Flame Sword text.
.alias DSC_ERD_SWD      $07     ;Erdrick's sword text.
.alias DSC_CLOTHES      $08     ;Clothes text.
.alias DSC_LTHR_ARMR    $09     ;Leather armor text.
.alias DSC_CHAIN_ML     $0A     ;Chain mail text.
.alias DSC_HALF_PLT     $0B     ;Half plate text.
.alias DSC_FULL_PLT     $0C     ;Full plate text.
.alias DSC_MAG_ARMR     $0D     ;Magic armor text.
.alias DSC_ERD_ARMR     $0E     ;Erdrick's armor text.
.alias DSC_SM_SHLD      $0F     ;Small shield text.
.alias DSC_LG_SHLD      $10     ;Large shield text.
.alias DSC_SLVR_SHLD    $11     ;Silver shield text.
.alias DSC_HERB         $12     ;Herb text.
.alias DSC_TORCH        $13     ;Torch text.
.alias DSC_DRGN_SCL     $14     ;Dragon's scale text.
.alias DSC_WINGS        $15     ;Wyvern wings text.
.alias DSC_KEY          $16     ;Magic key text.
.alias DSC_FRY_WATER    $17     ;Fairy water text.
.alias DSC_BL_LIGHT     $18     ;Ball of light text.
.alias DSC_ERD_TBLT     $19     ;Erdrick's tablet text.
.alias DSC_FRY_FLUTE    $1A     ;Fairy flute text.
.alias DSC_SLVR_HARP    $1B     ;Silver harp text.
.alias DSC_RN_STAFF     $1C     ;Staff of rain text.
.alias DSC_STN_SUN      $1D     ;Stones of sunlight text.
.alias DSC_GWLN_LOVE    $1E     ;Gwaelin's love text.
.alias DSC_RNBW_DRP     $1F     ;Rainbow drop text.
.alias DSC_CRSD_BLT     $20     ;Cursed belt text.
.alias DSC_DTH_NCK      $21     ;Death necklace text.
.alias DSC_FGHTR_RNG    $22     ;Fighter's ring text.
.alias DSC_ERD_TKN      $23     ;Erdrick's token text.
.alias DSC_SCRT_PSG     $24     ;Secret passage text.
.alias DSC_HEAL         $14     ;Heal spell text.
.alias DSC_HURT         $15     ;Hurt spell text.
.alias DSC_SLEEP        $16     ;Sleep spell text.
.alias DSC_RADIANT      $17     ;Radiant spell text.
.alias DSC_STOPSPELL    $18     ;Stopspell spell text.
.alias DSC_OUTSIDE      $19     ;Outside spell text.
.alias DSC_RETURN       $1A     ;Return spell text.
.alias DSC_REPEL        $1B     ;Repel spell text.
.alias DSC_HEALMORE     $1C     ;Healmore spell text.
.alias DSC_HURTMORE     $1D     ;Hurtmore spell text.
.alias DSC_END          $FF     ;Marks the end of the description buffer.

;Window border constants.
.alias NULL             $0000   ;Null pointer.
.alias TL_RIGHT_ARROW   $42     ;Right pointing arrow.
.alias TL_BLANK_TILE1   $5F     ;Blank tile 1 tile pattern number.
.alias TL_BLANK_TILE2   $60     ;Blank tile 2 tile pattern number.
.alias TL_LEFT          $61     ;Left window border.
.alias TL_TOP1          $62     ;Upper window border.
.alias TL_TOP2          $63     ;Upper window border.
.alias TL_UPPER_LEFT    $64     ;Upper left window border.
.alias TL_BOT_LEFT      $65     ;Lower left window border.
.alias TL_RIGHT         $66     ;Right window border.
.alias TL_UPPER_RIGHT   $67     ;Upper right window border.
.alias TL_BOTTOM        $68     ;Bottom window border.
.alias TL_BOT_RIGHT     $69     ;Lower right window border.

;Graphic block constants.
.alias BLK_GRASS        $00     ;Grass block.
.alias BLK_SAND         $01     ;Sand block.
.alias BLK_HILL         $02     ;Hill block.
.alias BLK_STAIR_UP     $03     ;Stairs up block.
.alias BLK_BRICK        $04     ;Bricks block.
.alias BLK_STAIR_DN     $05     ;Stairs down block.
.alias BLK_SWAMP        $06     ;Swamp block.
.alias BLK_TOWN         $07     ;Town block.
.alias BLK_CAVE         $08     ;Cave block.
.alias BLK_CASTLE       $09     ;Castle block.
.alias BLK_BRIDGE       $0A     ;Bridge block.
.alias BLK_TREES        $0B     ;Trees block.
.alias BLK_CHEST        $0C     ;Treasure chest block.
.alias BLK_FFIELD       $0D     ;Force field block.
.alias BLK_LRG_TILE     $0E     ;Large tile/shop counter block.
.alias BLK_WATER        $0F     ;Water block.
.alias BLK_STONE        $10     ;Stone block.
.alias BLK_DOOR         $11     ;Door block.
.alias BLK_MOUNTAIN     $12     ;Mountain block.
.alias BLK_SHOP         $13     ;Shop sign block.
.alias BLK_INN          $14     ;Inn sign block.
.alias BLK_SML_TILES    $15     ;Small tiles block.
.alias BLK_BLANK        $16     ;Black square block.
.alias BLK_PRINCESS     $17     ;Princess Gwaelin block.
.alias BLK_WTR_T        $18     ;Water - shore at top.
.alias BLK_WTR_L        $19     ;Water - shore at left.
.alias BLK_WTR_TL       $1A     ;Water - shore at top, left.
.alias BLK_WTR_R        $1B     ;Water - shore at right.
.alias BLK_WTR_TR       $1C     ;Water - shore at top, right.
.alias BLK_WTR_LR       $1D     ;Water - shore at left, right.
.alias BLK_WTR_TLR      $1E     ;Water - shore at top, left, right.
.alias BLK_WTR_B        $1F     ;Water - shore at bottom.
.alias BLK_WTR_TB       $20     ;Water - shore at top, bottom.
.alias BLK_WTR_LB       $21     ;Water - shore at left, bottom.
.alias BLK_WTR_TLB      $22     ;Water - shore at top, left, bottom.
.alias BLK_WTR_RB       $23     ;Water - shore at right, bottom.
.alias BLK_WTR_TRB      $24     ;Water - shore at top, right, bottom.
.alias BLK_WTR_LRB      $25     ;Water - shore at left, right and bottom.
.alias BLK_WTR_TLRB     $26     ;Water - shore at all sides.

;Treasure chest constants.
.alias TRSR_HERB        $02     ;Herb.
.alias TRSR_KEY         $03     ;Magic key.
.alias TRSR_TORCH       $04     ;Torch.
.alias TRSR_WINGS       $06     ;Wyvern wings.
.alias TRSR_RING        $09     ;Fighter's ring.
.alias TRSR_BELT        $0C     ;Cursed belt.
.alias TRSR_HARP        $0D     ;Silver harp.
.alias TRSR_NCK         $0E     ;Death necklace or 100-131 gold.
.alias TRSR_SUN         $0F     ;Stones of sunlight
.alias TRSR_RAIN        $10     ;Staff of rain.
.alias TRSR_ERSD        $11     ;Erdrick's sword.
.alias TRSR_GLD1        $12     ;5-20 gold.
.alias TRSR_GLD2        $13     ;6-13  gold.
.alias TRSR_GLD3        $14     ;10-17 gold.
.alias TRSR_GLD4        $15     ;500-755 gold.
.alias TRSR_GLD5        $16     ;120 gold.
.alias TRSR_TBLT        $17     ;Erdrick's tablet.

;Non-combat command window commands.
.alias NCC_TALK         $00     ;Talk.
.alias NCC_STATUS       $01     ;Status.
.alias NCC_STAIRS       $02     ;Stairs.
.alias NCC_SEARCH       $03     ;Search.
.alias NCC_SPELL        $04     ;Spell.
.alias NCC_ITEM         $05     ;Item.
.alias NCC_DOOR         $06     ;Door.
.alias NCC_TAKE         $07     ;Take.

;Map types.
.alias MAP_OVRWLD       $00     ;Overworld map.
.alias MAP_TOWN         $10     ;Town/castle map.
.alias MAP_DUNGEON      $20     ;Dungeon map.

;Palette addresses.
.alias PAL_BKG_LB       $00     ;Lower byte starting address of background palettes.
.alias PAL_SPR_LB       $10     ;Lower byte starting address of sprite palettes.
.alias PAL_UB           $3F     ;Upper byte address of all palettes.

;Misc. constants.
.alias NT_NAMETBL0_LB   $00     ;Nametable 0 base address lower byte.
.alias NT_NAMETBL0_UB   $20     ;Nametable 0 base address upper byte.
.alias NT_NAMETBL1_LB   $00     ;Nametable 1 base address lower byte.
.alias NT_NAMETBL1_UB   $24     ;Nametable 1 base address upper byte.
.alias AT_ATRBTBL0_UB   $23     ;Attribute table 0 base address upper byte.
.alias AT_ATRBTBL1_UB   $27     ;Attribute table 1 base address upper byte.
.alias NPC_MOVE         $00     ;Allow NPCs to move.
.alias NPC_STOP         $FF     ;Stop NPCs from moving.
.alias WND_ABORT        $FF     ;Window cancelled.
.alias STRT_FULL_HP     $78     ;Restore HP and MP on restart.
.alias STRT_NO_HP       $AB     ;Do not restore HP and MP on restart.
.alias IS_CURSED        $C0     ;Bitmask for checking if player is cursed.
.alias WND_YES          $00     ;Yes selected from Yes/no window.
.alias WND_NO           $01     ;No selected from Yes/no window.
.alias WND_BUY          $00     ;Buy selected from Buy/sell window.
.alias WND_SELL         $01     ;Sell selected from Buy/sell window.
.alias ITM_TBL_END      $FD     ;End of shop items list.
.alias PAL_LOAD_BG      $FF     ;Load background palette data.
.alias PAL_SKIP_BG      $00     ;Skip loading background palette.
.alias PAL_BLACK        $0F     ;Black background palette value.
.alias WND_FOREGROUND   $00     ;Window overlaps another window.
.alias WND_BACKGROUND   $FF     ;Window is a background window.
