.org $8000

.include "Dragon_Warrior_Defines.asm"

;--------------------------------------[ Forward declarations ]--------------------------------------

.alias ClearPPU                 $C17A
.alias CalcPPUBufAddr           $C596
.alias GetJoypadStatus          $C608
.alias AddPPUBufEntry           $C690
.alias ClearSpriteRAM           $C6BB
.alias DoWindow                 $C6F0
.alias DoDialogHiBlock          $C7C5
.alias WndLoadGameDat           $F685
.alias Bank0ToCHR0              $FCA3
.alias GetAndStrDatPtr          $FD00
.alias GetBankDataByte          $FD1C
.alias WaitForNMI               $FF74
.alias _DoReset                 $FF8E

;-----------------------------------------[ Start of code ]------------------------------------------

;The following table contains functions called from bank 3 through the IRQ interrupt.

BankPointers:
L8000:  .word WndEraseParams    ;($AF24)Get parameters for removing windows from the screen.
L8002:  .word WndShowHide       ;($ABC4)Show/hide window on the screen.
L8004:  .word ClearSoundRegs    ;($8178)Silence all sound.
L8006:  .word WaitForMusicEnd   ;($815E)Wait for the music clip to end.
L8008:  .word InitMusicSFX      ;($81A0)Initialize new music/SFX.
L800A:  .word ExitGame          ;($9362)Shut down game after player chooses not to continue.
L800C:  .word NULL              ;Unused.
L800E:  .word NULL              ;Unused.
L8010:  .word CopyTrsrTbl       ;($994F)Copy treasure table into RAM.
L8012:  .word NULL              ;Unused.
L8014:  .word CopyROMToRAM      ;($9981)Copy a ROM table into RAM.
L8016:  .word EnSpritesPtrTbl   ;($99E4)Table of pointers to enemy sprites.
L8018:  .word LoadEnemyStats    ;($9961)Load enemy stats when initiaizing a battle.
L801A:  .word SetBaseStats      ;($99B4)Get player's base stats for their level.
L801C:  .word DoEndCredits      ;($939A)Show end credits.
L801E:  .word NULL              ;Unused.
L8020:  .word ShowWindow        ;($A194)Display a window.
L8022:  .word WndEnterName      ;($AE02)Do name entering functions.
L8024:  .word DoDialog          ;($B51D)Display in-game dialog.
L8026:  .word NULL              ;Unused.

;-------------------------------------------[Sound Engine]-------------------------------------------

UpdateSound:
L8028:  PHA                     ;
L8029:  TXA                     ;
L802A:  PHA                     ;Store X, Y and A.
L802B:  TYA                     ;
L802C:  PHA                     ;

L802D:  LDX #MCTL_NOIS_SW       ;Noise channel software regs index.
L802F:  LDY #MCTL_SQ2_HW        ;SQ2 channel hardware regs index.
L8031:  LDA SFXActive           ;Is an SFX active?
L8033:  BEQ +                   ;If not, branch to skip SFX processing.

L8035:  LDA NoteOffset          ;
L8037:  PHA                     ;Save a copy of note offset and then clear
L8038:  LDA #$00                ;it as it is not used in SFX processing.
L803A:  STA NoteOffset          ;

L803C:  JSR GetNextNote         ;($80CB)Check to see if time to get next channel note.
L803F:  TAX                     ;

L8040:  PLA                     ;Restore note offset value.
L8041:  STA NoteOffset          ;

L8043:  TXA                     ;Is SFX still processing?
L8044:  BNE +                   ;If so, branch to continue or else reset noise and SQ2.

L8046:  LDA #%00000101          ;Silence SQ2 and noise channels.
L8048:  STA APUCommonCntrl0     ;
L804B:  LDA #%00001111          ;Enable SQ1, SQ2, TRI and noise channels.
L804D:  STA APUCommonCntrl0     ;

L8050:  LDA SQ2Config           ;Update SQ2 control byte 0.
L8052:  STA SQ2Cntrl0           ;

L8055:  LDA #%00001000          ;Disable sweep generator on SQ2.
L8057:  STA SQ2Cntrl1           ;

L805A:  LDA #%00110000          ;Turn off volume for noise channel.
L805C:  STA NoiseCntrl0         ;

L805F:* LDA TempoCntr           ;Tempo counter has the effect of slowing down the length
L8061:  CLC                     ;The music plays.  If the tempo is less than 150, the
L8062:  ADC Tempo               ;amount it slows down is linear.  For example, if tempo is
L8064:  STA TempoCntr           ;125, the music will slow down by 150/125 = 1.2 times.
L8066:  BCC SoundUpdateEnd      ;The values varies if tempo is greater than 150.

L8068:  SBC #$96                ;Subtract 150 from tempo counter.
L806A:  STA TempoCntr           ;

L806C:  LDX #MCTL_TRI_SW        ;TRI channel software regs index.
L806E:  LDY #MCTL_TRI_HW        ;TRI channel hardware regs index.
L8070:  JSR GetNextNote         ;($80CB)Check to see if time to get next channel note.

L8073:  LDX #MCTL_SQ2_SW        ;SQ2 channel software regs index.
L8075:  LDY #MCTL_SQ2_HW        ;SQ2 channel hardware regs index.
L8077:  LDA SFXActive           ;Is an SFX currenty active?
L8079:  BEQ +                   ;If not, branch.

L807B:  LDY #MCTL_DMC_HW        ;Set hardware register index to DMC regs (not used).
L807D:* JSR GetNextNote         ;($80CB)Check to see if time to get next channel note.

L8080:  LDX #MCTL_SQ1_SW        ;SQ1 channel software regs index.
L8082:  LDY #MCTL_SQ1_HW        ;SQ1 channel hardware regs index.
L8084:  JSR GetNextNote         ;($80CB)Check to see if time to get next channel note.

SoundUpdateEnd:
L8087:  LDY #$00                ;
L8089:  LDA (SQ1IndexLB),Y      ;Update music trigger value.
L808B:  STA MusicTrigger        ;

L808E:  PLA                     ;
L808F:  TAY                     ;
L8090:  PLA                     ;Restore X, Y and A.
L8091:  TAX                     ;
L8092:  PLA                     ;
L8093:  RTS                     ;

;----------------------------------------------------------------------------------------------------

MusicReturn:
L8094:  LDA SQ1ReturnLB,X       ;
L8096:  STA SQ1IndexLB,X        ;Load return address into sound channel
L8098:  LDA SQ1ReturnUB,X       ;data address.  Process byte if not $00.
L809A:  STA SQ1IndexUB,X        ;
L809C:  BNE ProcessAudioByte    ;

;----------------------------------------------------------------------------------------------------

LoadMusicNote:
L809E:  CLC                     ;Add any existing offset into note table.
L809F:  ADC NoteOffset          ;Used to change the sound of various dungeon levels.

L80A1:  ASL                     ;*2.  Each table value is 2 bytes.
L80A2:  STX MusicTemp           ;Save X.
L80A4:  TAX                     ;Use calculated value as index into note table.

L80A5:  LDA MusicalNotesTbl,X   ;
L80A8:  STA SQ1Cntrl2,Y         ;Store note data bytes into its
L80AB:  LDA MusicalNotesTbl+1,X ;corresponding hardware registers.
L80AE:  STA SQ1Cntrl3,Y         ;

L80B1:  LDX MusicTemp           ;Restore X.
L80B3:  CPX #MCTL_NOIS_SW       ;Is noise channel being processed?
L80B5:  BEQ ProcessAudioByte    ;If so, branch to get next audio data byte.

L80B7:  LDA ChannelQuiet,X      ;Is any quiet time between notes expired?
L80B9:  BEQ ProcessAudioByte    ;If so, branch to get next audio byte.

L80BB:  BNE UpdateChnlUsage     ;Wait for quiet time between notes to end. Branch always.

;----------------------------------------------------------------------------------------------------

ChnlQuietTime:
L80BD:  JSR GetAudioData        ;($8155)Get next music data byte.
L80C0:  STA ChannelQuiet,X      ;Store quiet time byte.
L80C2:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

EndChnlQuietTime:
L80C5:  LDA #$00                ;Clear quiet time byte.
L80C7:  STA ChannelQuiet,X      ;
L80C9:  BEQ ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

GetNextNote:
L80CB:  LDA ChannelLength,X     ;Is channel enabled?
L80CD:  BEQ UpdateReturn        ;If not, branch to exit.

L80CF:  DEC ChannelLength,X     ;Decrement length remaining.
L80D1:  BNE UpdateReturn        ;Time to get new data? if not, branch to exit.

;----------------------------------------------------------------------------------------------------

ProcessAudioByte:
L80D3:  JSR GetAudioData        ;($8155)Get next music data byte.
L80D6:  CMP #MCTL_JUMP          ;
L80D8:  BEQ MusicJump           ;Check if need to jump to new music data address.

L80DA:  BCS ChangeTempo         ;Check if tempo needs to be changed.

L80DC:  CMP #MCTL_NO_OP         ;Check if no-op byte.
L80DE:  BEQ ProcessAudioByte    ;If so, branch to get next byte.

L80E0:  BCS MusicReturn         ;Check if need to jump back to previous music data adddress.

L80E2:  CMP #MCTL_CNTRL1        ;Check if channel control 1 byte.
L80E4:  BEQ ChnlCntrl1          ;If so, branch to load config byte.

L80E6:  BCS ChnlCntrl0          ;Check if channel control 0 byte.

L80E8:  CMP #MCTL_NOISE_VOL     ;Check if noise channel volume control byte.
L80EA:  BEQ NoiseVolume         ;If so, branch to load noise volume.

L80EC:  BCS GetNoteOffset       ;Is this a note offset byte? If so, branch.

L80EE:  CMP #MCTL_END_SPACE     ;Check if end quiet time between notes byte.
L80F0:  BEQ EndChnlQuietTime    ;If so, branch to end quiet time.

L80F2:  BCS ChnlQuietTime       ;Add quiet time between notes? if so branch to get quiet time.

L80F4:  CMP #MCTL_NOISE_CFG     ;Is byte a noise channel config byte?
L80F6:  BCS LoadNoise           ;If so, branch to configure noise channel.

L80F8:  CMP #MCTL_NOTE          ;Is byte a musical note? 
L80FA:  BCS LoadMusicNote       ;If so, branch to load note.

;If no control bytes match the cases above, byte Is note length counter.

UpdateChnlUsage:
L80FC:  STA ChannelLength,X     ;Update channel note counter.

UpdateReturn:
L80FE:  RTS                     ;Finished with current processing.

;----------------------------------------------------------------------------------------------------

ChangeTempo:
L80FF:  JSR GetAudioData        ;($8155)Get next music data byte.
L8102:  STA Tempo               ;Update music speed.
L8104:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

MusicJump:
L8107:  JSR GetAudioData        ;($8155)Get next music data byte.
L810A:  PHA                     ;
L810B:  JSR GetAudioData        ;($8155)Get next music data byte.
L810E:  PHA                     ;Get jump address from music data.
L810F:  LDA SQ1IndexLB,X        ;
L8111:  STA SQ1ReturnLB,X       ;
L8113:  LDA SQ1IndexUB,X        ;Save current address in return address variables.
L8115:  STA SQ1ReturnUB,X       ;
L8117:  PLA                     ;
L8118:  STA SQ1IndexUB,X        ;Jump to new music data address and get data byte.
L811A:  PLA                     ;
L811B:  STA SQ1IndexLB,X        ;
L811D:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

ChnlCntrl0:
L8120:  JSR GetAudioData        ;($8155)Get next music data byte.
L8123:  CPX #$02                ;Is SQ2 currently being handled?
L8125:  BNE +                   ;If not, branch to load into corresponding SQ register.

L8127:  STA SQ2Config           ;Else store a copy of the data byte in SQ2 config register.

L8129:* STA SQ1Cntrl0,Y         ;Load control byte into corresponding control register.
L812C:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

NoiseVolume:
L812F:  JSR GetAudioData        ;($8155)Get next music data byte.
L8132:  STA NoiseCntrl0         ;Set noise volume byte.
L8135:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

LoadNoise:
L8138:  AND #$0F                ;Set noise period.
L813A:  STA NoiseCntrl2         ;
L813D:  LDA #%00001000          ;Set length counter to 1.
L813F:  STA NoiseCntrl3         ;
L8142:  BNE ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

GetNoteOffset:
L8144:  JSR GetAudioData        ;($8155)Get next music data byte.
L8147:  STA NoteOffset          ;Get note offset byte.
L8149:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

ChnlCntrl1:
L814C:  JSR GetAudioData        ;($8155)Get next music data byte.
L814F:  STA SQ1Cntrl1,Y         ;Store byte in square wave config register.
L8152:  JMP ProcessAudioByte    ;($80D3)Determine what to do with music data byte.

;----------------------------------------------------------------------------------------------------

GetAudioData:
L8155:  LDA (SQ1IndexLB,X)      ;Get data byte from ROM.

IncAudioPtr:
L8157:  INC SQ1IndexLB,X        ;
L8159:  BNE +                   ;Increment data pointer.
L815B:  INC SQ1IndexUB,X        ;
L815D:* RTS                     ;

;----------------------------------------------------------------------------------------------------

WaitForMusicEnd:
L815E:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
L8161:  LDA #MCTL_NO_OP         ;Load no-op character. Its also used for end of music segment.
L8163:  LDX #MCTL_SQ1_SW        ;
L8165:  CMP (SQ1IndexLB,X)      ;Is no-op found in SQ1 data? if so, end found.  Branch to end.
L8167:  BEQ +                   ;

L8169:  LDX #MCTL_NOIS_SW       ;
L816B:  CMP (SQ1IndexLB,X)      ;Is no-op found in noise data? if so, end found.  Branch to end.
L816D:  BEQ +                   ;

L816F:  LDX #MCTL_TRI_SW        ;
L8171:  CMP (SQ1IndexLB,X)      ;Is no-op found in triangel data? if so, end found.  Branch to end.
L8173:  BNE WaitForMusicEnd     ;
L8175:* JMP IncAudioPtr         ;($8157)Increment audio data pointer.

;----------------------------------------------------------------------------------------------------

ClearSoundRegs:
L8178:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

L817B:  LDA #$00                ;
L817D:  STA DMCCntrl0           ;Clear hardware control registers.
L8180:  STA APUCommonCntrl1     ;
L8183:  STA APUCommonCntrl0     ;

L8186:  STA SQ1Length           ;
L8188:  STA SQ2Length           ;Indicate the channels are not in use.
L818A:  STA TRILength           ;

L818C:  STA SFXActive           ;No SFX active.

L818E:  LDA #%00001111          ;
L8190:  STA APUCommonCntrl0     ;Enable sound channels.

L8193:  LDA #$FF                ;Initialize tempo.
L8195:  STA Tempo               ;

L8197:  LDA #$08                ;
L8199:  STA SQ1Cntrl1           ;Disable SQ1 and SQ2 sweep units.
L819C:  STA SQ2Cntrl1           ;
L819F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

InitMusicSFX:
L81A0:  LDX #$FF                ;Indicate the sound engine is active.
L81A2:  STX SndEngineStat       ;
L81A5:  TAX                     ;
L81A6:  BMI DoSFX               ;If MSB set, branch to process SFX.

DoMusic:
L81A8:  ASL                     ;Index into table is 4*n + 4. Points to last word in table entry.
L81A9:  STA MusicTemp           ;
L81AB:  ASL                     ;There are 3 words for each music entry in the table.
L81AC:  ADC MusicTemp           ;The entries are for SQ1, SQ2 and TRI from left to right.
L81AE:  ADC #$04                ;
L81B0:  TAY                     ;Use Y as index into table.

L81B1:  LDX #$04                ;Prepare to loop 3 times.

ChnlInitLoop:
L81B3:  LDA MscStrtIndxTbl+1,Y  ;Get upper byte of pointer from table.
L81B6:  BNE +                   ;Is there a valid pointer? If so branch to save pointer.

L81B8:  LDA MscStrtIndxTbl+1,X  ;
L81BB:  STA SQ1IndexUB,X        ;No music data for this chnnel in the table.  Load
L81BD:  LDA MscStrtIndxTbl,X    ;the "no sound" data instead.
L81C0:  JMP ++                  ;

L81C3:* STA SQ1IndexUB,X        ;
L81C5:  LDA MscStrtIndxTbl,Y    ;Store pointer to audio data.
L81C8:* STA SQ1IndexLB,X        ;

L81CA:  LDA #$01                ;Indicate the channel has valid sound data.
L81CC:  STA ChannelLength,X     ;

L81CE:  DEY                     ;Move to the next pointer in the pointer table and in the RAM.
L81CF:  DEY                     ;
L81D0:  DEX                     ;
L81D1:  DEX                     ;Have three pointers been picked up?
L81D2:  BPL ChnlInitLoop        ;If not, branch to get the next pointer.

L81D4:  LDA #$00                ;
L81D6:  STA NoteOffset          ;
L81D8:  STA SQ1Quiet            ;
L81DA:  STA SQ2Quiet            ;Clear various status variables.
L81DC:  STA TRIQuiet            ;
L81DE:  STA SndEngineStat       ;
L81E1:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoSFX:
L81E2:  ASL                     ;*2. Pointers in table are 2 bytes.
L81E3:  TAX                     ;

L81E4:  LDA #$01                ;Indicate a SFX is active.
L81E6:  STA SFXActive           ;

L81E8:  LDA SFXStrtIndxTbl,X    ;
L81EB:  STA NoisIndexLB         ;Get pointer to SFX data from table.
L81ED:  LDA SFXStrtIndxTbl+1,X  ;
L81F0:  STA NoisIndexUB         ;

L81F2:  LDA #$08                ;Disable SQ2 sweep unit.
L81F4:  STA SQ2Cntrl1           ;

L81F7:  LDA #$30                ;Disable length counter and set constant
L81F9:  STA SQ2Cntrl0           ;volume for SQ2 and noise channels.
L81FC:  STA NoiseCntrl0         ;

L81FF:  LDA #$00                ;
L8201:  STA SndEngineStat       ;Indicate sound engine finished.
L8204:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;The LSB of the length counter is always written when loading the frequency data into the 
;counter registers.  This plays the note for the longest possible time if the halt flag is
;cleared.  The first byte contains the low bits of the timer while the second byte contains
;the upper 3 bits.  The formula for figuring out the frequency is as follows: 
;1790000/16/(hhhllllllll + 1).

MusicalNotesTbl:
L8205:  .byte $AD, $0E          ;65.4Hz  (C2),  Entry #$80.
L8207:  .byte $4D, $0E          ;69.3Hz  (C#2), Entry #$81.
L8209:  .byte $F3, $0D          ;73.4Hz  (D2),  Entry #$82.
L820B:  .byte $9D, $0D          ;77.8Hz  (D#2), Entry #$83.
L820D:  .byte $4C, $0D          ;82.4Hz  (E2),  Entry #$84.
L820F:  .byte $00, $0D          ;87.3Hz  (F2),  Entry #$85.
L8211:  .byte $B8, $0C          ;92.5Hz  (F#2), Entry #$86.
L8213:  .byte $74, $0C          ;98.0Hz  (G2),  Entry #$87.
L8215:  .byte $34, $0C          ;103.9Hz (Ab2), Entry #$88.
L8217:  .byte $F8, $0B          ;110.0Hz (A2),  Entry #$89.
L8219:  .byte $BF, $0B          ;116.5Hz (A#2), Entry #$8A.
L821B:  .byte $89, $0B          ;123.5Hz (B2),  Entry #$8B.
L821D:  .byte $56, $0B          ;130.8Hz (C3),  Entry #$8C.
L821F:  .byte $26, $0B          ;138.6Hz (C#3), Entry #$8D.
L8221:  .byte $F9, $0A          ;146.8Hz (D3),  Entry #$8E.
L8223:  .byte $CE, $0A          ;155.6Hz (D#3), Entry #$8F.
L8225:  .byte $A6, $0A          ;164.8Hz (E3),  Entry #$90.
L8227:  .byte $80, $0A          ;174.5Hz (F3),  Entry #$91.
L8229:  .byte $5C, $0A          ;184.9Hz (F#3), Entry #$92.
L822B:  .byte $3A, $0A          ;196.0Hz (G3),  Entry #$93.
L822D:  .byte $1A, $0A          ;207.6Hz (Ab3), Entry #$94.
L822F:  .byte $FB, $09          ;220.2Hz (A3),  Entry #$95.
L8231:  .byte $DF, $09          ;233.1Hz (A#3), Entry #$96.
L8233:  .byte $C4, $09          ;247.0Hz (B3),  Entry #$97.
L8235:  .byte $AB, $09          ;261.4Hz (C4),  Entry #$98.
L8237:  .byte $93, $09          ;276.9Hz (C#4), Entry #$99.
L8239:  .byte $7C, $09          ;293.6Hz (D4),  Entry #$9A.
L823B:  .byte $67, $09          ;310.8Hz (D#4), Entry #$9B.
L823D:  .byte $52, $09          ;330.0Hz (E4),  Entry #$9C.
L823F:  .byte $3F, $09          ;349.6Hz (F4),  Entry #$9D.
L8241:  .byte $2D, $09          ;370.4Hz (F#4), Entry #$9E.
L8243:  .byte $1C, $09          ;392.5Hz (G4),  Entry #$9F.
L8245:  .byte $0C, $09          ;414.4Hz (Ab4), Entry #$A0.
L8247:  .byte $FD, $08          ;440.4Hz (A4),  Entry #$A1.
L8249:  .byte $EF, $08          ;466.1Hz (A#4), Entry #$A2.
L824B:  .byte $E1, $08          ;495.0Hz (B4),  Entry #$A3.
L824D:  .byte $D5, $08          ;522.8Hz (C5),  Entry #$A4.
L824F:  .byte $C9, $08          ;553.8Hz (C#5), Entry #$A5.
L8251:  .byte $BD, $08          ;588.8Hz (D5),  Entry #$A6.
L8253:  .byte $B3, $08          ;621.5Hz (D#5), Entry #$A7.
L8255:  .byte $A9, $08          ;658.1Hz (E5),  Entry #$A8.
L8257:  .byte $9F, $08          ;699.2Hz (F5),  Entry #$A9.
L8259:  .byte $96, $08          ;740.9Hz (F#5), Entry #$AA.
L825B:  .byte $8E, $08          ;782.3Hz (G5),  Entry #$AB.
L825D:  .byte $86, $08          ;828.7Hz (Ab5), Entry #$AC.
L825F:  .byte $7E, $08          ;880.9HZ (A5),  Entry #$AD.
L8261:  .byte $77, $08          ;932.3Hz (A#5), Entry #$AE.
L8263:  .byte $70, $08          ;990.0Hz (B5),  Entry #$AF.
L8265:  .byte $6A, $08          ;1046Hz  (C6),  Entry #$B0.
L8267:  .byte $64, $08          ;1108Hz  (C#6), Entry #$B1.
L8269:  .byte $5E, $08          ;1178Hz  (D6),  Entry #$B2.
L826B:  .byte $59, $08          ;1243Hz  (D#6), Entry #$B3.
L826D:  .byte $54, $08          ;1316Hz  (E6),  Entry #$B4.
L826F:  .byte $4F, $08          ;1398Hz  (F6),  Entry #$B5.
L8271:  .byte $4B, $08          ;1472Hz  (F#6), Entry #$B6.
L8273:  .byte $46, $08          ;1576Hz  (G6),  Entry #$B7.
L8275:  .byte $42, $08          ;1670Hz  (Ab6), Entry #$B8.
L8277:  .byte $3F, $08          ;1748Hz  (A6),  Entry #$B9.
L8279:  .byte $3B, $08          ;1865Hz  (A#6), Entry #$BA.
L827B:  .byte $38, $08          ;1963Hz  (B6),  Entry #$BB.
L827D:  .byte $34, $08          ;2111Hz  (C7),  Entry #$BC.
L827F:  .byte $31, $08          ;2238Hz  (C#7), Entry #$BD.
L8281:  .byte $2F, $08          ;2331Hz  (D7),  Entry #$BE.
L8283:  .byte $2C, $08          ;2486Hz  (D#7), Entry #$BF.
L8285:  .byte $29, $08          ;2664Hz  (E7),  Entry #$C0.
L8287:  .byte $27, $08          ;2796Hz  (F7),  Entry #$C1.
L8289:  .byte $25, $08          ;2944Hz  (F#7), Entry #$C2.
L828B:  .byte $23, $08          ;3107Hz  (G7),  Entry #$C3.
L828D:  .byte $21, $08          ;3290Hz  (G#7), Entry #$C4.
L828F:  .byte $1F, $08          ;3496Hz  (A7),  Entry #$C5.
L8291:  .byte $1D, $08          ;3729Hz  (A#7), Entry #$C6.
L8293:  .byte $1B, $08          ;3996Hz  (B7),  Entry #$C7.
L8295:  .byte $1A, $08          ;4144Hz  (C8),  Entry #$C8.

;----------------------------------------------------------------------------------------------------

MscStrtIndxTbl:
L8297:  .word SQNoSnd,     SQNoSnd,     TRINoSnd    ;($84CB, $84CB, $84CE)No sound.
L829D:  .word SQ1Intro,    SQ2Intro,    TriIntro    ;($8D6D, $8E3D, $8F06)Intro.
L82A3:  .word SQ1ThrnRm,   NULL,        TRIThrnRm   ;($84D3, $0000, $853E)Throne room.
L82A9:  .word SQ1Tantagel, NULL,        TRITantagel ;($85AA, $0000, $85B4)Tantagel castle.
L82AF:  .word SQ1Village,  NULL,        TRIVillage  ;($872F, $0000, $87A2)Village/pre-game.
L82B5:  .word SQ1Outdoor,  NULL,        TRIOutdoor  ;($8844, $0000, $8817)Outdoors.
L82BB:  .word SQ1Dngn,     NULL,        TRIDngn1    ;($888B, $0000, $891D)Dungeon 1.
L82C1:  .word SQ1Dngn,     NULL,        TRIDngn2    ;($888B, $0000, $8924)Dungeon 2.
L82C7:  .word SQ1Dngn,     NULL,        TRIDngn3    ;($888B, $0000, $892B)Dungeon 3.
L82CD:  .word SQ1Dngn,     NULL,        TRIDngn4    ;($888B, $0000, $8932)Dungeon 4.
L82D3:  .word SQ1Dngn,     NULL,        TRIDngn5    ;($888B, $0000, $8937)Dungeon 5.
L82D9:  .word SQ1Dngn,     NULL,        TRIDngn6    ;($888B, $0000, $893E)Dungeon 6.
L82DF:  .word SQ1Dngn,     NULL,        TRIDngn7    ;($888B, $0000, $8945)Dungeon 7.
L82E5:  .word SQ1Dngn,     NULL,        TRIDngn8    ;($888B, $0000, $894C)Dungeon 8.
L82EB:  .word SQ1EntFight, NULL,        TRIEntFight ;($89A9, $0000, $8ACF)Enter fight.
L82F1:  .word SQ1EndBoss,  SQ2EndBoss,  TRIEndBoss  ;($8B62, $8BE6, $8C1A)End boss.
L82F7:  .word SQ1EndGame,  SQ2EndGame,  TRIEndGame  ;($8F62, $90B2, $922E)End game.
L82FD:  .word SQ1SlvrHrp,  SQ2SlvrHrp,  NULL        ;($8C3F, $8C3E, $0000)Silver harp.
L8303:  .word NULL,        NULL,        TRIFryFlute ;($0000, $0000, $8C9A)Fairy flute.
L8309:  .word SQ1RnbwBrdg, SQ2RnbwBrdg, NULL        ;($8CE2, $8CE1, $0000)Rainbow bridge.
L830F:  .word SQ1Death,    SQ2Death,    NULL        ;($8D24, $8D23, $0000)Player death.
L8315:  .word SQ1Inn,      SQ2Inn,      NULL        ;($86CC, $86EB, $0000)Inn.
L831B:  .word SQ1Princess, SQ2Princess, TRIPrincess ;($8653, $867B, $86AC)Princess Gwaelin.
L8321:  .word SQ1Cursed,   SQ2Cursed,   NULL        ;($8D4B, $8D4A, $0000)Cursed.
L8327:  .word SQ1Fight,    NULL,        TRIFight    ;($89BF, $0000, $8AE1)Regular fight.
L832D:  .word SQ1Victory,  SQ2Victory,  NULL        ;($870E, $8707, $0000)Victory.
L8333:  .word SQ1LevelUp,  SQ2LevelUp,  NULL        ;($862A, $8640, $0000)Level up.

;----------------------------------------------------------------------------------------------------

SFXStrtIndxTbl:
L8339:  .word FFDamageSFX                           ;($836E)Force field damage.
L833B:  .word WyvernWngSFX                          ;($8377)Wyvern wing.
L833D:  .word StairsSFX                             ;($839E)Stairs.
L833F:  .word RunSFX                                ;($83C2)Run away.
L8341:  .word SwmpDmgSFX                            ;($83F8)Swamp damage.
L8343:  .word MenuSFX                               ;($8401)Menu button.
L8345:  .word ConfirmSFX                            ;($8406)Confirmation.
L8347:  .word EnHitSFX                              ;($8411)Enemy hit.
L8349:  .word ExclntMvSFX                           ;($8420)Excellent move.
L834B:  .word AttackSFX                             ;($843B)Attack.
L834D:  .word HitSFX                                ;($844A)Player hit 1.
L834F:  .word HitSFX                                ;($844A)Player hit 2.
L8351:  .word AtckPrepSFX                           ;($8459)Attack prep.
L8353:  .word Missed1SFX                            ;($8468)Missed 1.
L8355:  .word Missed2SFX                            ;($8471)Missed 2.
L8357:  .word WallSFX                               ;($847A)Wall bump.
L8359:  .word TextSFX                               ;($8486)Text.
L835B:  .word SpellSFX                              ;($848E)Spell cast.
L835D:  .word RadiantSFX                            ;($84A0)Radiant.
L835F:  .word OpnChestSFX                           ;($84AB)Open chest.
L8361:  .word OpnDoorSFX                            ;($84B6)Open door.
L8363:  .word FireSFX                               ;($8365)Breath fire.

;----------------------------------------------------------------------------------------------------

FireSFX:
L8365:  .byte MCTL_CNTRL0,     $B3  ;50% duty, len counter no, env no, vol=3.
L8367:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L8369:  .byte $ED, $0C              ;Noise timer period = 1016, 12 counts.
L836B:  .byte $EE, $30              ;Noise timer period = 2034, 48 counts.
L836D:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

FFDamageSFX:
L836E:  .byte MCTL_NOISE_VOL,  $0F  ;len counter yes, env yes, vol=15.
L8370:  .byte $E7, $04              ;Noise timer period = 160, 4 counts.
L8372:  .byte $E8, $04              ;Noise timer period = 202, 4 counts.
L8374:  .byte $E9, $04              ;Noise timer period = 254, 4 counts.
L8376:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

WyvernWngSFX:
L8377:  .byte MCTL_NOISE_VOL,  $01  ;len counter yes, env yes, vol=1.
L8379:  .byte MCTL_CNTRL0,     $7F  ;25% duty, len counter no, env no, vol=15.
L837B:  .byte MCTL_CNTRL1,     $9B  ;Setup sweep generator.
L837D:  .byte $8C                   ;C3.
L837E:  .byte $EF, $06              ;Noise timer period = 4068, 6 counts.
L8380:  .byte $EE, $06              ;Noise timer period = 2034, 6 counts.
L8382:  .byte $0C                   ;12 counts.
L8383:  .byte MCTL_CNTRL1,     $94  ;Setup sweep generator.
L8385:  .byte $06                   ;6 counts.
L8386:  .byte MCTL_CNTRL1,     $9B  ;Setup sweep generator.
L8388:  .byte MCTL_NOISE_VOL,  $01  ;len counter yes, env yes, vol=1.
L838A:  .byte $8C                   ;C3.
L838B:  .byte $EF, $06              ;Noise timer period = 4068, 6 counts.
L838D:  .byte $EE, $06              ;Noise timer period = 2034, 6 counts.
L838F:  .byte $0C                   ;12 counts.
L8390:  .byte MCTL_CNTRL1,     $94  ;Setup sweep generator.
L8392:  .byte $06                   ;6 counts.
L8393:  .byte MCTL_CNTRL1,     $9B  ;Setup sweep generator.
L8395:  .byte MCTL_NOISE_VOL,  $01  ;len counter yes, env yes, vol=1.
L8397:  .byte $8C                   ;C3.
L8398:  .byte $EF, $06              ;Noise timer period = 4068, 6 counts.
L839A:  .byte $EE, $06              ;Noise timer period = 2034, 6 counts.
L839C:  .byte $0C                   ;12 counts.
L839D:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

StairsSFX:
L839E:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83A0:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L83A1:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83A4:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83A6:  .byte $0C                   ;12 counts.
L83A7:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83A9:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83AB:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L83AD:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83AF:  .byte $0C                   ;12 counts.
L83B0:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83B2:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L83B4:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83B6:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83B8:  .byte $0C                   ;12 counts.
L83B9:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83BB:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83BD:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L83BF:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83C1:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

RunSFX:
L83C2:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83C4:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L83C6:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83C8:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83CA:  .byte $03                   ;3 counts.
L83CB:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83CD:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83CF:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L83D1:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83D3:  .byte $03                   ;3 counts.
L83D4:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83D6:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L83D8:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83DA:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83DC:  .byte $03                   ;3 counts.
L83DD:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83DF:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83E1:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L83E3:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83E5:  .byte $03                   ;3 counts.
L83E6:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83E8:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L83EA:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83EC:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83EE:  .byte $03                   ;3 counts.
L83EF:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L83F1:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L83F3:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L83F5:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L83F7:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

SwmpDmgSFX:
L83F8:  .byte MCTL_NOISE_VOL,  $01  ;len counter yes, env yes, vol=1.
L83FA:  .byte $EF, $06              ;Noise timer period = 4068, 6 counts.
L83FC:  .byte $ED, $06              ;Noise timer period = 1016, 6 counts.
L83FE:  .byte MCTL_NOISE_VOL,  $30  ;len counter no, env no, vol=0.
L8400:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

MenuSFX:
L8401:  .byte MCTL_CNTRL0,     $89  ;50% duty, len counter yes, env yes, vol=9.
L8403:  .byte $C5, $06              ;A7,  6 counts.
L8405:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

ConfirmSFX:
L8406:  .byte MCTL_CNTRL0,     $89  ;50% duty, len counter yes, env yes, vol=9.
L8408:  .byte $BC, $04              ;C7,  4 counts.
L840A:  .byte $C2, $04              ;F#7, 4 counts.
L840C:  .byte $BC, $04              ;C7,  4 counts.
L840E:  .byte $C2, $04              ;F#7, 4 counts.
L8410:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

EnHitSFX:
L8411:  .byte MCTL_NOISE_VOL,  $0F  ;len counter yes, env yes, vol=15.
L8413:  .byte $EA, $02              ;Noise timer period = 380,  2 counts.
L8415:  .byte $EB, $02              ;Noise timer period = 508,  2 counts.
L8417:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L8419:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L841B:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L841D:  .byte $EF, $02              ;Noise timer period = 4068, 2 counts.
L841F:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

ExclntMvSFX:
L8420:  .byte MCTL_NOISE_VOL,  $0F  ;len counter yes, env yes, vol=15.
L8422:  .byte $E8, $02              ;Noise timer period = 202,  2 counts.
L8424:  .byte $E9, $02              ;Noise timer period = 254,  2 counts.
L8426:  .byte $EA, $02              ;Noise timer period = 380,  2 counts.
L8428:  .byte $EB, $02              ;Noise timer period = 508,  2 counts.
L842A:  .byte $E8, $02              ;Noise timer period = 202,  2 counts.
L842C:  .byte $E9, $02              ;Noise timer period = 254,  2 counts.
L842E:  .byte $EA, $02              ;Noise timer period = 380,  2 counts.
L8430:  .byte $EB, $02              ;Noise timer period = 508,  2 counts.
L8432:  .byte $EA, $02              ;Noise timer period = 380,  2 counts.
L8434:  .byte $E9, $02              ;Noise timer period = 254,  2 counts.
L8436:  .byte $E8, $02              ;Noise timer period = 202,  2 counts.
L8438:  .byte $E7, $02              ;Noise timer period = 160,  2 counts.
L843A:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

AttackSFX:
L843B:  .byte MCTL_CNTRL0,     $43  ;25% duty, len counter yes, env yes, vol=3.
L843D:  .byte $B7, $02              ;G6,  2 counts.
L843F:  .byte $B8, $02              ;Ab6, 2 counts.
L8441:  .byte $B6, $02              ;F#6, 2 counts.
L8443:  .byte $B7, $02              ;G6,  2 counts.
L8445:  .byte $B8, $02              ;Ab6, 2 counts.
L8447:  .byte $B6, $02              ;F#6, 2 counts.
L8449:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

HitSFX:
L844A:  .byte MCTL_NOISE_VOL,  $0F  ;len counter yes, env yes, vol=15.
L844C:  .byte $EF, $02              ;Noise timer period = 4068, 2 counts.
L844E:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L8450:  .byte $ED, $02              ;Noise timer period = 1016, 2 counts.
L8452:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L8454:  .byte $EB, $02              ;Noise timer period = 508,  2 counts.
L8456:  .byte $EA, $02              ;Noise timer period = 380,  2 counts.
L8458:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

AtckPrepSFX:
L8459:  .byte MCTL_CNTRL0,     $43  ;25% duty, len counter yes, env yes, vol=3.
L845B:  .byte $A6, $02              ;D5,  2 counts.
L845D:  .byte $A3, $02              ;B4,  2 counts.
L845F:  .byte $A7, $02              ;D#5, 2 counts.
L8461:  .byte $A6, $02              ;D5,  2 counts.
L8463:  .byte $A3, $02              ;B4,  2 counts.
L8465:  .byte $A7, $02              ;D#5, 2 counts.
L8467:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

Missed1SFX:
L8468:  .byte MCTL_CNTRL0,     $0F  ;12.5% duty, len counter yes, env yes, vol=15.
L846A:  .byte $AD, $04              ;A5,  4 counts.
L846C:  .byte $AB, $04              ;G5,  4 counts.
L846E:  .byte $A7, $04              ;D#5, 4 counts.
L8470:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

Missed2SFX:
L8471:  .byte MCTL_CNTRL0,     $0F  ;12.5% duty, len counter yes, env yes, vol=15.
L8473:  .byte $AF, $04              ;B5,  4 counts.
L8475:  .byte $AD, $04              ;A5,  4 counts.
L8477:  .byte $A9, $04              ;F5,  4 counts.
L8479:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

WallSFX:
L847A:  .byte MCTL_CNTRL0,     $8F  ;50% duty, len counter yes, env yes, vol=15.
L847C:  .byte MCTL_NOISE_VOL,  $00  ;len counter yes, env yes, vol=0.
L847E:  .byte $EE                   ;Noise timer period = 2034.
L847F:  .byte $8F, $03              ;D#3, 3 counts.
L8481:  .byte $8E, $03              ;D3,  3 counts.
L8483:  .byte $8C, $03              ;C3,  3 counts.
L8485:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

TextSFX:
L8486:  .byte MCTL_NOISE_VOL,  $32  ;len counter no, env no, vol=2.
L8488:  .byte MCTL_CNTRL0,     $00  ;12.5% duty, len counter yes, env yes, vol=0.
L848A:  .byte $AD                   ;A5.
L848B:  .byte $EE, $08              ;Noise timer period = 2034, 8 counts.
L848D:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

SpellSFX:
L848E:  .byte MCTL_CNTRL0,     $4F  ;25% duty, len counter yes, env yes, vol=15.
L8490:  .byte $98, $06              ;C4,  6 counts.
L8492:  .byte $9A, $06              ;D4,  6 counts.
L8494:  .byte $99, $06              ;C#4, 6 counts.
L8496:  .byte $9C, $06              ;E4,  6 counts.
L8498:  .byte $9B, $06              ;D#4, 6 counts.
L849A:  .byte $9D, $06              ;F4,  6 counts.
L849C:  .byte $9E, $06              ;F#4, 6 counts.
L849E:  .byte $00                   ;End SFX.
L849F:  .byte MCTL_NO_OP            ;Continue previous music.

;----------------------------------------------------------------------------------------------------

RadiantSFX:
L84A0:  .byte MCTL_NOISE_VOL,  $3F  ;len counter no, env no, vol=15.
L84A2:  .byte $EF, $03              ;Noise timer period = 4068, 3 counts.
L84A4:  .byte $EE, $02              ;Noise timer period = 2034, 2 counts.
L84A6:  .byte $ED, $01              ;Noise timer period = 1016, 1 count.
L84A8:  .byte $EC, $02              ;Noise timer period = 762,  2 counts.
L84AA:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

OpnChestSFX:
L84AB:  .byte MCTL_CNTRL0,     $8F  ;50% duty, len counter yes, env yes, vol=15.
L84AD:  .byte $92, $03              ;F#3, 3 counts.
L84AF:  .byte $98, $03              ;C4,  3 counts.
L84B1:  .byte $93, $03              ;G3,  3 counts.
L84B3:  .byte $99, $03              ;C#4, 3 counts.
L84B5:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

OpnDoorSFX:
L84B6:  .byte MCTL_CNTRL0,     $00  ;12.5% duty, len counter yes, env yes, vol=0.
L84B8:  .byte $B0, $02              ;C6,  2 counts.
L84BA:  .byte $A5, $02              ;C#5, 2 counts.
L84BC:  .byte $B2, $02              ;D6,  2 counts.
L84BE:  .byte $A7, $02              ;D#5, 2 counts.
L84C0:  .byte $B4, $06              ;E6,  6 counts.
L84C2:  .byte $A6, $02              ;D5,  2 counts.
L84C4:  .byte $B3, $02              ;D#6, 2 counts.
L84C6:  .byte $A8, $02              ;E5,  2 counts.
L84C8:  .byte $B5, $06              ;F6,  6 counts.
L84CA:  .byte $00                   ;End SFX.

;----------------------------------------------------------------------------------------------------

SQNoSnd:
L84CB:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L84CD:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

TRINoSnd:
L84CE:  .byte MCTL_NOTE_OFST, $00   ;Note offset of 0 notes.
L84D0:  .byte MCTL_CNTRL0,    $00   ;Silence the trianlge channel.
L84D2:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

SQ1ThrnRm:
L84D3:  .byte MCTL_TEMPO,     $7E   ;60/1.19=50 counts per second.

SQ1ThrnRmLoop:
L84D5:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L84D7:  .byte MCTL_JUMP             ;Jump to new music address.
L84D8:  .word SQ1Tantagel2          ;($85BA).
L84DA:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L84DC:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L84DE:  .byte $95                   ;A3.
L84DF:  .byte MCTL_JUMP             ;Jump to new music address.
L84E0:  .word SQ1ThrnRm2            ;($851E).
L84E2:  .byte $93                   ;G3.
L84E3:  .byte MCTL_JUMP             ;Jump to new music address.
L84E4:  .word SQ1ThrnRm2            ;($851E).
L84E6:  .byte MCTL_CNTRL0,    $87   ;50% duty, len counter yes, env yes, vol=7.
L84E8:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L84EA:  .byte $A3, $9F, $A4, $9F    ;B4,  G4,  C5,  G4.
L84EE:  .byte $A9, $A1, $A4, $A1    ;F5,  A4,  C5,  A4.
L84F2:  .byte $A8, $9C, $A0, $A3    ;E5,  E4,  Ab4, B4.
L84F6:  .byte $A8, $9F, $A5, $A8    ;E5,  G4,  C#5, E5.
L84FA:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L84FC:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L84FE:  .byte $8E                   ;D3.
L84FF:  .byte MCTL_JUMP             ;Jump to new music address.
L8500:  .word SQ1ThrnRm3            ;($852E).
L8502:  .byte $8C                   ;C3.
L8503:  .byte MCTL_JUMP             ;Jump to new music address.
L8504:  .word SQ1ThrnRm3            ;($852E).
L8506:  .byte MCTL_CNTRL0,    $87   ;50% duty, len counter yes, env yes, vol=7.
L8508:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L850A:  .byte $A3, $9F, $A4, $9F    ;B4,  G4,  C5,  G4.
L850E:  .byte $A9, $A1, $A4, $A9    ;F5,  A4,  C5,  F5.
L8512:  .byte $A8, $A1, $A0, $9D    ;E5,  A4,  Ab4, F4.
L8516:  .byte $9C, $9A, $98, $97    ;E4,  D4,  C4,  B3.
L851A:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L851B:  .byte MCTL_JUMP             ;Jump to new music address.
L851C:  .word SQ1ThrnRmLoop         ;($84D5).

SQ1ThrnRm2:
L851E:  .byte $06                   ;6 counts.
L851F:  .byte $AD, $AC              ;A5, 172 counts.
L8521:  .byte $AD, $06              ;A5,   6 counts.
L8523:  .byte $A8, $A7              ;E5, 167 counts.
L8525:  .byte $A8, $06              ;E5,   6 counts.
L8527:  .byte $A4, $A3              ;C5, 163 counts.
L8529:  .byte $A4, $06              ;C5,   6 counts.
L852B:  .byte $A1, $06              ;A4,   6 counts.
L852D:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1ThrnRm3:
L852E:  .byte $06                   ;6 counts.
L852F:  .byte $AD, $AC              ;A5, 172 counts.
L8531:  .byte $AD, $06              ;A5,   6 counts.
L8533:  .byte $A9, $A8              ;F5, 168 counts.
L8535:  .byte $A9, $06              ;F5,   6 counts.
L8537:  .byte $A6, $A5              ;D5, 165 counts.
L8539:  .byte $A6, $06              ;D5,   6 counts.
L853B:  .byte $A1, $06              ;A4,   6 counts.
L853D:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIThrnRm:
L853E:  .byte MCTL_JUMP             ;Jump to new music address.
L853F:  .word TRITantagel2          ;($85EB).
L8541:  .byte MCTL_CNTRL0,    $18   ;12.5% duty, len counter yes, env no, vol=8.
L8543:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L8545:  .byte $95                   ;A3.
L8546:  .byte $06                   ;6 counts.
L8547:  .byte $A4, $A3, $A4         ;C5,  B4,  C5.
L854A:  .byte $06                   ;6 counts.
L854B:  .byte $A4, $A3, $A4         ;C5,  B4,  C5.
L854E:  .byte $06                   ;6 counts.
L854F:  .byte $A8, $A7, $A8         ;E5,  D#5, E5.
L8552:  .byte $06                   ;6 counts.
L8553:  .byte $A4                   ;C5.
L8554:  .byte $06                   ;6 counts.
L8555:  .byte $93                   ;G3.
L8556:  .byte $06                   ;6 counts.
L8557:  .byte $A4, $A3, $A4         ;C5,  B4,  C5.
L855A:  .byte $06                   ;6 counts.
L855B:  .byte $A4, $A3, $9E         ;C5,  B4,  F#4.
L855E:  .byte $06                   ;6 counts.
L855F:  .byte $A8, $A7, $A8         ;E5,  D#5, E5.
L8562:  .byte $06                   ;6 counts.
L8563:  .byte $A4                   ;C5.
L8564:  .byte $06                   ;6 counts.
L8565:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L8567:  .byte $9D                   ;F4.
L8568:  .byte $12                   ;18 counts.
L8569:  .byte $9C                   ;E4.
L856A:  .byte $12                   ;18 counts.
L856B:  .byte $9A                   ;D4.
L856C:  .byte $12                   ;18 counts.
L856D:  .byte $9B                   ;D#4.
L856E:  .byte $12                   ;18 counts.
L856F:  .byte $9C                   ;E4.
L8570:  .byte $2A                   ;42 counts.
L8571:  .byte $A1                   ;A4.
L8572:  .byte $2A                   ;42 counts.
L8573:  .byte MCTL_CNTRL0,    $18   ;12.5% duty, len counter yes, env no, vol=8.
L8575:  .byte $9A                   ;D4.
L8576:  .byte $06                   ;6 counts.
L8577:  .byte $A9, $A8, $A9         ;F5,  E5,  F5.
L857A:  .byte $06                   ;6 counts.
L857B:  .byte $A6, $A5, $A6         ;D5,  C#5, D5.
L857E:  .byte $06                   ;6 counts.
L857F:  .byte $A9, $A8, $A9         ;F5,  E5,  F5.
L8582:  .byte $06                   ;6 counts.
L8583:  .byte $A6                   ;D5.
L8584:  .byte $06                   ;6 counts.
L8585:  .byte $98                   ;C4.
L8586:  .byte $06                   ;6 counts.
L8587:  .byte $A9, $A8, $A9         ;F5,  E5,  F5.
L858A:  .byte $06                   ;6 counts.
L858B:  .byte $A6, $A5, $97         ;D5,  C#5, B3.
L858E:  .byte $06                   ;6 counts.
L858F:  .byte $A9, $A8, $A9         ;F5,  E5,  F5.
L8592:  .byte $06                   ;6 counts.
L8593:  .byte $A6                   ;D5.
L8594:  .byte $06                   ;6 counts.
L8595:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L8597:  .byte $9D                   ;F4.
L8598:  .byte $12                   ;18 counts.
L8599:  .byte $9C                   ;E4.
L859A:  .byte $12                   ;18 counts.
L859B:  .byte $9A                   ;D4.
L859C:  .byte $2A                   ;42 counts.
L859D:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L859F:  .byte $9C, $A9, $A8, $A6    ;E4,  F5,  E5,  D5.
L85A3:  .byte $A4, $A3, $A1, $A0    ;C5,  B4,  A4,  Ab4.
L85A7:  .byte MCTL_JUMP             ;Jump to new music address.
L85A8:  .word TRIThrnRm             ;($853E).

;----------------------------------------------------------------------------------------------------

SQ1Tantagel:
L85AA:  .byte MCTL_TEMPO,     $7D   ;60/1.2=50 counts per second.
L85AC:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L85AE:  .byte MCTL_JUMP             ;Jump to new music address.
L85AF:  .word SQ1Tantagel2          ;($85BA).
L85B1:  .byte MCTL_JUMP             ;Jump to new music address.
L85B2:  .word SQ1Tantagel           ;($85AA).

;----------------------------------------------------------------------------------------------------

TRITantagel:
L85B4:  .byte MCTL_JUMP             ;Jump to new music address.
L85B5:  .word TRITantagel2          ;($85EB).
L85B7:  .byte MCTL_JUMP             ;Jump to new music address.
L85B8:  .word TRITantagel           ;($85B4).

;----------------------------------------------------------------------------------------------------

SQ1Tantagel2:
L85BA:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L85BC:  .byte $95, $A8, $A6, $A8    ;A3,  E5,  D5,  E5.
L85C0:  .byte $A4, $A8, $A3, $A8    ;C5,  E5,  B4,  E5.
L85C4:  .byte $A1                   ;A4.
L85C5:  .byte $54                   ;84 counts.
L85C6:  .byte $8E, $A9, $A8, $A9    ;D3,  F5,  E5,  F5.
L85CA:  .byte $A6, $A9, $A4, $A9    ;D5,  F5,  C5,  F5.
L85CE:  .byte $A3                   ;B4.
L85CF:  .byte $54                   ;84 counts.
L85D0:  .byte $95, $AB, $A9, $AB    ;A3,  G5,  F5,  G5.
L85D4:  .byte $A8, $AB, $A5, $AB    ;E5,  G5,  C#5, G5.
L85D8:  .byte $A9                   ;F5.
L85D9:  .byte $0C                   ;12 counts.
L85DA:  .byte $AB                   ;G5.
L85DB:  .byte $0C                   ;12 counts.
L85DC:  .byte $AD                   ;A5.
L85DD:  .byte $0C                   ;12 counts.
L85DE:  .byte $AB, $A9, $A8         ;G5,  F5,  E5.
L85E1:  .byte $0C                   ;12 counts.
L85E2:  .byte $A4, $A8, $A6         ;C5,  E5,  D5.
L85E5:  .byte $0C                   ;12 counts.
L85E6:  .byte $A7                   ;D#5.
L85E7:  .byte $0C                   ;12 counts.
L85E8:  .byte $A8                   ;E5.
L85E9:  .byte $54                   ;84 counts.
L85EA:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRITantagel2:
L85EB:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L85ED:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L85EF:  .byte $95                   ;A3.
L85F0:  .byte $54                   ;84 counts.
L85F1:  .byte $A1, $95, $98, $9C    ;A4  A3  C4  E4.
L85F5:  .byte $A1, $9F, $9D, $9C    ;A4  G4  F4  E4.
L85F9:  .byte $9A, $A6, $A4, $A6    ;D4  D5  C5  D5.
L85FD:  .byte $A3, $A6, $A1, $A6    ;B4  D5  A4  D5.
L8601:  .byte $A0, $9C, $A0, $A3    ;Ab4 E4  Ab4 B4.
L8605:  .byte $A8, $9C, $9E, $A0    ;E5  E4  F#4 Ab4.
L8609:  .byte $A1, $A8, $A6, $A8    ;A4  E5  D5  E5.
L860D:  .byte $A5, $A8, $A1, $A8    ;C#5 E5  A4  E5.
L8611:  .byte $A6, $A1, $A8, $A1    ;D5  A4  E5  A4.
L8615:  .byte $A9, $A1, $A8, $A6    ;F5  A4  E5  D5.
L8619:  .byte $A4, $9F, $A8, $9F    ;C5  G4  E5  G4.
L861D:  .byte $A3, $A9, $A1, $AA    ;B4  F5  A4  F#.
L8621:  .byte $AC, $9C, $A0, $A3    ;Ab5 E4  Ab4 B4.
L8625:  .byte $A8, $A6, $A4, $A3    ;E5  D5  C5  B4.
L8629:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ1LevelUp:
L862A:  .byte MCTL_TEMPO,     $50   ;60/1.88=32 counts per second.
L862C:  .byte MCTL_CNTRL0,    $42   ;25% duty, len counter yes, env yes, vol=2.
L862E:  .byte $A9, $04              ;F5,   4 counts.
L8630:  .byte $A9, $04              ;F5,   4 counts.
L8632:  .byte $A9, $04              ;F5,   4 counts.
L8634:  .byte $A9, $08              ;F5,   8 counts.
L8636:  .byte $A7, $08              ;D#5,  8 counts.
L8638:  .byte $AB, $08              ;G5,   8 counts.
L863A:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L863C:  .byte $A9, $18              ;F5,  24 counts.
L863E:  .byte $00                   ;End music.
L863F:  .byte MCTL_NO_OP            ;Continue last music.

;----------------------------------------------------------------------------------------------------

SQ2LevelUp:
L8640:  .byte MCTL_CNTRL0, $42      ;25% duty, len counter yes, env yes, vol=2.
L8642:  .byte $A4, $04              ;C5,   4 counts.
L8644:  .byte $A3, $04              ;B4,   4 counts.
L8646:  .byte $A2, $04              ;A#4,  4 counts.
L8648:  .byte $A1, $08              ;A4,   8 counts.
L864A:  .byte $9F, $08              ;G4,   8 counts.
L864C:  .byte $A2, $08              ;A#4,  8 counts.
L864E:  .byte MCTL_CNTRL0, $4F      ;25% duty, len counter yes, env yes, vol=15.
L8650:  .byte $A1, $18              ;A4,  24 counts.
L8652:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

SQ1Princess:
L8653:  .byte MCTL_TEMPO,     $6E   ;60/1.36=44 counts per second.
L8655:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8657:  .byte $06                   ;6 counts.
L8658:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L865A:  .byte $B0, $12              ;C6,  18 counts.
L865C:  .byte $AD, $06              ;A5,   6 counts.
L865E:  .byte $AB, $06              ;G5,   6 counts.
L8660:  .byte $A9, $06              ;F5,   6 counts.
L8662:  .byte $A8, $0C              ;E5,  12 counts.
L8664:  .byte $A6, $18              ;D5,  24 counts.
L8666:  .byte $AE, $12              ;A#5, 18 counts.
L8668:  .byte $AB, $06              ;G5,   6 counts.
L866A:  .byte $A8, $06              ;E5,   6 counts.
L866C:  .byte $A6, $06              ;D5,   6 counts.
L866E:  .byte $A5, $18              ;C#5, 24 counts.
L8670:  .byte $AD, $0C              ;A5,  12 counts.
L8672:  .byte MCTL_CNTRL0,    $BF   ;50% duty, len counter no, env no, vol=15.
L8674:  .byte $B0, $30              ;C6,  48 counts.
L8676:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8678:  .byte $3C                   ;60 counts.
L8679:  .byte $00                   ;End music.
L867A:  .byte MCTL_NO_OP            ;Continue last music.

;----------------------------------------------------------------------------------------------------

SQ2Princess:
L867B:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L867D:  .byte $12                   ;18 counts.
L867E:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8680:  .byte $A4, $0C              ;C5,  12 counts.
L8682:  .byte $A1, $0C              ;A4,  12 counts.
L8684:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8686:  .byte $0C                   ;12 counts.
L8687:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8689:  .byte $A0, $0C              ;Ab4, 12 counts.
L868B:  .byte $9D, $0C              ;F4,  12 counts.
L868D:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L868F:  .byte $0C                   ;12 counts.
L8690:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8692:  .byte $A6, $0C              ;D5,  12 counts.
L8694:  .byte $A2, $0C              ;A#4, 12 counts.
L8696:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8698:  .byte $0C                   ;12 counts.
L8699:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L869B:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L869D:  .byte $9C, $9F, $A2, $9C    ;E4,  G4,  A#4, E4.
L86A1:  .byte $A1, $A4, $A8, $A4    ;A4,  C5,  E5,  C5.
L86A5:  .byte $A1, $A4, $A1         ;A4,  C5,  A4.
L86A8:  .byte $06                   ;6 counts.
L86A9:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L86AB:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

TRIPrincess:
L86AC:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L86AE:  .byte $06                   ;6 counts.
L86AF:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L86B1:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L86B3:  .byte $9D, $A1, $A4, $A0    ;F4,  A4,  C5,  Ab4.
L86B7:  .byte $A3, $A0, $9F, $A2    ;B4,  Ab4, G4,  A#4.
L86BB:  .byte $9F, $98, $A4, $98    ;G4,  C4,  C5,  C4.
L86BF:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L86C1:  .byte $9D, $A1, $A4, $A1    ;F4,  A4,  C5,  A4.
L86C5:  .byte $9D, $98, $91         ;F4,  C4,  F3.
L86C8:  .byte $12                   ;18 counts.
L86C9:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L86CB:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

SQ1Inn:
L86CC:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.
L86CE:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L86D0:  .byte $18                   ;24 counts.
L86D1:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L86D3:  .byte $A4, $06              ;C5,   6 counts.
L86D5:  .byte $A6, $06              ;D5,   6 counts.
L86D7:  .byte $A4, $06              ;C5,   6 counts.
L86D9:  .byte $A6, $06              ;D5,   6 counts.
L86DB:  .byte $A8, $0C              ;E5,  12 counts.
L86DD:  .byte $AB, $0C              ;G5,  12 counts.
L86DF:  .byte $A4, $02              ;C5,   2 counts.
L86E1:  .byte $A8, $02              ;E5,   2 counts.
L86E3:  .byte $AB, $02              ;G5,   2 counts.
L86E5:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L86E7:  .byte $B0, $42              ;C6,  66 counts.
L86E9:  .byte $00                   ;End music.
L86EA:  .byte MCTL_NO_OP            ;Continue last music.

;----------------------------------------------------------------------------------------------------

SQ2Inn:
L86EB:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L86ED:  .byte $18                   ;24 counts.
L86EE:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L86F0:  .byte $9C, $06              ;E4m   6 counts.
L86F2:  .byte $9D, $06              ;F4m   6 counts.
L86F4:  .byte $9C, $06              ;E4m   6 counts.
L86F6:  .byte $9D, $06              ;F4,   6 counts.
L86F8:  .byte $9F, $0C              ;G4m  12 counts.
L86FA:  .byte $A2, $0C              ;A#4m 12 counts.
L86FC:  .byte $9C, $02              ;E4m   2 counts.
L86FE:  .byte $9F, $02              ;G4,   2 counts.
L8700:  .byte $A2, $02              ;A#4,  2 counts.
L8702:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8704:  .byte $A8, $42              ;E5,  66 counts.
L8706:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

SQ2Victory:
L8707:  .byte $06                   ;6 counts.
L8708:  .byte MCTL_JUMP             ;Jump to new music address.
L8709:  .word SQVictory             ;($8717).
L870B:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L870D:  .byte $00                   ;End music.

;----------------------------------------------------------------------------------------------------

SQ1Victory:
L870E:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.
L8710:  .byte MCTL_JUMP             ;Jump to new music address.
L8711:  .word SQVictory             ;($8717).
L8713:  .byte $B0, $2F              ;C6,  47 counts.
L8715:  .byte $00                   ;End music.
L8716:  .byte MCTL_NO_OP            ;Continue last music.

SQVictory:
L8717:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8719:  .byte $8C, $07              ;C3,   7 counts.
L871B:  .byte $93, $06              ;G3,   6 counts.
L871D:  .byte $98, $06              ;C4,   6 counts.
L871F:  .byte MCTL_ADD_SPACE, $01   ;1 counts between notes.
L8721:  .byte $9A, $9C, $9D, $9F    ;D4,  E4,  F4,  G4.
L8725:  .byte $A1, $A2, $A4, $A6    ;A4,  A#4, C5,  D5.
L8729:  .byte $A8, $A9, $AB, $AD    ;E5,  F5,  G5,  A5.
L872D:  .byte $AE                   ;A#5
L872E:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ1Village:
L872F:  .byte MCTL_TEMPO,     $73   ;60/1.3=46 counts per second.

SQ1VillageLoop:
L8731:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8733:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8735:  .byte $A1, $A2, $A4, $A9    ;A4,  A#4, C5,  F5.
L8739:  .byte $A8, $A6, $A4         ;E5,  D5,  C5.
L873C:  .byte $0C                   ;12 counts.
L873D:  .byte $A6, $A1, $A2         ;D5,  A4,  A#4.
L8740:  .byte $3C                   ;60 counts.
L8741:  .byte $9F, $A1, $A2, $A8    ;G4,  A4,  A#4, E5.
L8745:  .byte $A6, $A4, $A4, $A2    ;D5,  C5,  C5,  A#4.
L8749:  .byte $9F, $A2, $A1         ;G4,  A#4, A4.
L874C:  .byte $0C                   ;12 counts.
L874D:  .byte $A2                   ;A#4.
L874E:  .byte $0C                   ;12 counts.
L874F:  .byte MCTL_JUMP             ;Jump to new music address.
L8750:  .word SQ1Village2           ;($8772).
L8752:  .byte $0C                   ;12 counts.
L8753:  .byte $9D, $A1, $9F         ;F4,  A4,  G4.
L8756:  .byte $0C                   ;12 counts.
L8757:  .byte $A9                   ;F5.
L8758:  .byte $0C                   ;12 counts.
L8759:  .byte $A8, $A9, $A6, $A8    ;E5,  F5,  D5,  E5.
L875D:  .byte MCTL_JUMP             ;Jump to new music address.
L875E:  .word SQ1Village2           ;($8772).
L8760:  .byte $A2, $A3, $A6, $A4    ;A#4, B4,  D5,  C5.
L8764:  .byte $A2, $A1, $9F         ;A#4, A4,  G4.
L8767:  .byte MCTL_CNTRL0,    $85   ;50% duty, len counter yes, env yes, vol=5.
L8769:  .byte $A1                   ;A4.
L876A:  .byte $0C                   ;12 counts.
L876B:  .byte $9F                   ;G4.
L876C:  .byte $0C                   ;12 counts.
L876D:  .byte $9D                   ;F4.
L876E:  .byte $0C                   ;12 counts.
L876F:  .byte MCTL_JUMP             ;Jump to new music address.
L8770:  .word SQ1VillageLoop        ;($8731).

SQ1Village2:
L8772:  .byte $A4                   ;C5.
L8773:  .byte $0C                   ;12 counts.
L8774:  .byte $A6, $A8              ;D5,  E5.
L8776:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L8778:  .byte $A9                   ;F5.
L8779:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L877A:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L877C:  .byte $A2, $06              ;A#4,  6 counts.
L877E:  .byte $A2, $06              ;A#4,  6 counts.
L8780:  .byte $A2, $0C              ;A#4, 12 counts.
L8782:  .byte $A6, $0C              ;D5,  12 counts.
L8784:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8786:  .byte $A9, $18              ;F5,  24 counts.
L8788:  .byte $A8, $0C              ;E5,  12 counts.
L878A:  .byte $A6, $0C              ;D5,  12 counts.
L878C:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L878E:  .byte $A4, $0C              ;C5,  12 counts.
L8790:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L8792:  .byte $A1, $06              ;A4,   6 counts.
L8794:  .byte $A1, $06              ;A4,   6 counts.
L8796:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8798:  .byte $A1, $A4              ;A4,  C5.
L879A:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L879C:  .byte $A9                   ;F5.
L879D:  .byte $0C                   ;12 counts.
L879E:  .byte $A4, $A2, $A1         ;C5,  A#4, A4.
L87A1:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIVillage:
L87A2:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L87A4:  .byte $18                   ;24 counts.
L87A5:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L87A7:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L87A9:  .byte $9D, $A1, $A4, $A9    ;F4,  A4,  C5,  F5.
L87AD:  .byte $9E, $A1, $A4, $A6    ;F#4, A4,  C5,  D5.
L87B1:  .byte $9F, $A2, $A6, $AB    ;G4,  A#4, D5,  G5.
L87B5:  .byte $9E, $A6, $9D, $A6    ;F#4, D5,  F4,  D5.
L87B9:  .byte $9C, $A4, $A2, $A4    ;E4,  C5,  A#4, C5.
L87BD:  .byte $98, $9F, $9C, $9F    ;C4,  G4,  E4,  G4.
L87C1:  .byte $9D, $A4, $9F, $A4    ;F4,  C5,  G4,  C5.
L87C5:  .byte $A1, $A7              ;A4,  D#5.
L87C7:  .byte MCTL_JUMP             ;Jump to new music address.
L87C8:  .word TRIVillage2           ;($87EE).
L87CA:  .byte $A3                   ;B4.
L87CB:  .byte $0C                   ;12 counts.
L87CC:  .byte $A6                   ;D5.
L87CD:  .byte $0C                   ;12 counts.
L87CE:  .byte $A3                   ;B4.
L87CF:  .byte $0C                   ;12 counts.
L87D0:  .byte $A4, $A6, $A4         ;C5,  D5,  C5.
L87D3:  .byte $0C                   ;12 counts.
L87D4:  .byte $A6                   ;D5.
L87D5:  .byte $0C                   ;12 counts.
L87D6:  .byte $A8                   ;E5.
L87D7:  .byte $0C                   ;12 counts.
L87D8:  .byte MCTL_JUMP             ;Jump to new music address.
L87D9:  .word TRIVillage2           ;($87EE).
L87DB:  .byte $9D, $9F, $A0, $A3    ;F4,  G4,  Ab4, B4.
L87DF:  .byte $A4, $A5, $A6, $A8    ;C5,  C#5, D5,  E5.
L87E3:  .byte MCTL_CNTRL0,    $18   ;12.5% duty, len counter yes, env no, vol=8.
L87E5:  .byte $A9                   ;F5.
L87E6:  .byte $0C                   ;12 counts.
L87E7:  .byte $A4                   ;C5.
L87E8:  .byte $0C                   ;12 counts.
L87E9:  .byte $A1                   ;A4.
L87EA:  .byte $0C                   ;12 counts.
L87EB:  .byte MCTL_JUMP             ;Jump to new music address.
L87EC:  .word TRIVillage            ;($87A2).

TRIVillage2:
L87EE:  .byte $AE, $B0              ;A#5, C6.
L87F0:  .byte MCTL_CNTRL0,    $18   ;12.5% duty, len counter yes, env no, vol=8.
L87F2:  .byte $B2                   ;D6.
L87F3:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L87F4:  .byte $9D, $06              ;F4,   6 counts.
L87F6:  .byte $9D, $06              ;F4,   6 counts.
L87F8:  .byte $9D, $0C              ;F4,  12 counts.
L87FA:  .byte $A2, $0C              ;A#4, 12 counts.
L87FC:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L87FE:  .byte $A6, $18              ;D5,  24 counts.
L8800:  .byte $B0, $0C              ;C6,  12 counts.
L8802:  .byte $AE, $0C              ;A#5, 12 counts.
L8804:  .byte MCTL_CNTRL0,    $18   ;12.5% duty, len counter yes, env no, vol=8.
L8806:  .byte $98, $0C              ;C4,  12 counts.
L8808:  .byte $9D, $06              ;F4,   6 counts.
L880A:  .byte $9D, $06              ;F4,   6 counts.
L880C:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L880E:  .byte $9D, $A1              ;F4,  A4.
L8810:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L8812:  .byte $A4                   ;C5.
L8813:  .byte $24                   ;36 counts.
L8814:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L8816:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIOutdoor:
L8817:  .byte MCTL_TEMPO,     $96   ;60/1=60 counts per second.
L8819:  .byte MCTL_ADD_SPACE, $10   ;16 counts between notes.

TRIOutdoorLoop:
L881B:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L881D:  .byte $B2                   ;D6.
L881E:  .byte $10                   ;16 counts.
L881F:  .byte $B9                   ;A6.
L8820:  .byte $10                   ;16 counts.
L8821:  .byte $B7                   ;G6.
L8822:  .byte $50                   ;80 counts.
L8823:  .byte $B5, $B4, $B2         ;F6  E6  D6.
L8826:  .byte $10                   ;16 counts.
L8827:  .byte $B0, $AE, $B0, $AD    ;C6  A#5, C6,  A5.
L882B:  .byte $B4                   ;E6.
L882C:  .byte $10                   ;16 counts.
L882D:  .byte $B2                   ;D6.
L882E:  .byte $30                   ;48 counts.
L882F:  .byte $40                   ;64 counts.
L8830:  .byte $40                   ;64 counts.
L8831:  .byte $B9                   ;A6.
L8832:  .byte $10                   ;16 counts.
L8833:  .byte $BC                   ;C7.
L8834:  .byte $10                   ;16 counts.
L8835:  .byte $BB                   ;B6.
L8836:  .byte $50                   ;80 counts.
L8837:  .byte $B7, $B5, $B4         ;G6,  F6,  E6.
L883A:  .byte $10                   ;16 counts.
L883B:  .byte $B5, $B7, $B9         ;F6,  G6,  A6.
L883E:  .byte $70                   ;112 counts.
L883F:  .byte $40                   ;64 counts.
L8840:  .byte $40                   ;64 counts.
L8841:  .byte MCTL_JUMP             ;Jump to new music address.
L8842:  .word TRIOutdoorLoop        ;($881B).

;----------------------------------------------------------------------------------------------------

SQ1Outdoor:
L8844:  .byte MCTL_ADD_SPACE, $10   ;16 counts between notes.
L8846:  .byte MCTL_CNTRL0,    $81   ;50% duty, len counter yes, env yes, vol=1.

SQ1OutdoorLoop:
L8848:  .byte $9A, $A1, $9D, $A1    ;D4,  A4,  F4,  A4.
L884C:  .byte $9A, $A3, $9F, $A3    ;D4,  B4,  G4,  B4.
L8850:  .byte $9A, $A4, $A1, $A4    ;D4,  C5,  A4,  C5.
L8854:  .byte $9A, $A2, $9D, $A2    ;D4,  A#4, F4,  A#4.
L8858:  .byte $9C, $A4, $A1, $A4    ;E4,  C5,  A4,  C5.
L885C:  .byte $9A, $A1, $9E, $A1    ;D4,  A4,  F#4, A4.
L8860:  .byte $9A, $A1, $9E, $A1    ;D4,  A4,  F#4, A4.
L8864:  .byte $9F, $A2, $A1, $A4    ;G4,  A#4, A4,  C5.
L8868:  .byte $9A, $A4, $A1, $A4    ;D4,  C5,  A4,  C5.
L886C:  .byte $9A, $A3, $9F, $A3    ;D4,  B4,  G4,  B4.
L8870:  .byte $9A, $A3, $9F, $A3    ;D4,  B4,  G4,  B4.
L8874:  .byte $9A, $A2, $A0, $A2    ;D4,  A#4, Ab4, A#4.
L8878:  .byte $99, $A1, $9C, $A1    ;C#4, A4,  E4,  A4.
L887C:  .byte $9A, $A1, $9C, $A1    ;D4,  A4,  E4,  A4.
L8880:  .byte $99, $A1, $9C, $A1    ;C#4, A4,  E4,  A4.
L8884:  .byte $97, $A1, $99, $A1    ;B3,  A4,  C#4, A4.
L8888:  .byte MCTL_JUMP             ;Jump to new music address.
L8889:  .word SQ1OutdoorLoop        ;($8848).

;----------------------------------------------------------------------------------------------------

SQ1Dngn:
L888B:  .byte MCTL_JUMP             ;Jump to new music address.
L888C:  .word SQ1Dngn2              ;($88CA).
L888E:  .byte MCTL_JUMP             ;Jump to new music address.
L888F:  .word SQ1Dngn2              ;($88CA).
L8891:  .byte MCTL_JUMP             ;Jump to new music address.
L8892:  .word SQ1Dngn2              ;($88CA).
L8894:  .byte MCTL_JUMP             ;Jump to new music address.
L8895:  .word SQ1Dngn2              ;($88CA).
L8897:  .byte MCTL_JUMP             ;Jump to new music address.
L8898:  .word SQ1Dngn3              ;($88E1).
L889A:  .byte MCTL_JUMP             ;Jump to new music address.
L889B:  .word SQ1Dngn3              ;($88E1).
L889D:  .byte MCTL_JUMP             ;Jump to new music address.
L889E:  .word SQ1Dngn4              ;($88ED).
L88A0:  .byte MCTL_JUMP             ;Jump to new music address.
L88A1:  .word SQ1Dngn4              ;($88ED).
L88A3:  .byte MCTL_JUMP             ;Jump to new music address.
L88A4:  .word SQ1Dngn5              ;($88F9).
L88A6:  .byte MCTL_JUMP             ;Jump to new music address.
L88A7:  .word SQ1Dngn5              ;($88F9).
L88A9:  .byte MCTL_JUMP             ;Jump to new music address.
L88AA:  .word SQ1Dngn5              ;($88F9).
L88AC:  .byte MCTL_JUMP             ;Jump to new music address.
L88AD:  .word SQ1Dngn5              ;($88F9).
L88AF:  .byte MCTL_JUMP             ;Jump to new music address.
L88B0:  .word SQ1Dngn6              ;($8905).
L88B2:  .byte MCTL_JUMP             ;Jump to new music address.
L88B3:  .word SQ1Dngn6              ;($8905).
L88B5:  .byte $96, $0C              ;A#3, 12 counts.
L88B7:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88B9:  .byte $24                   ;36 counts.
L88BA:  .byte MCTL_CNTRL0,    $B6   ;50% duty, len counter no, env no, vol=6.
L88BC:  .byte MCTL_JUMP             ;Jump to new music address.
L88BD:  .word SQ1Dngn7              ;($8911).
L88BF:  .byte MCTL_JUMP             ;Jump to new music address.
L88C0:  .word SQ1Dngn7              ;($8911).
L88C2:  .byte $95, $0C              ;A3,  12 counts.
L88C4:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88C6:  .byte $24                   ;36 counts.
L88C7:  .byte MCTL_JUMP             ;Jump to new music address.
L88C8:  .word SQ1Dngn               ;($888B).

SQ1Dngn2:
L88CA:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88CC:  .byte $05                   ;5 counts.
L88CD:  .byte MCTL_CNTRL0,    $B6   ;50% duty, len counter no, env no, vol=6.
L88CF:  .byte $97, $07              ;B3,   7 counts.
L88D1:  .byte $9A, $06              ;D4,   6 counts.
L88D3:  .byte $9F, $06              ;G4,   6 counts.
L88D5:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88D7:  .byte $05                   ;5 counts.
L88D8:  .byte MCTL_CNTRL0,    $B6   ;50% duty, len counter no, env no, vol=6.
L88DA:  .byte $97, $07              ;B3,   7 counts.
L88DC:  .byte $9A, $06              ;D4,   6 counts.
L88DE:  .byte $9F, $06              ;G4,   6 counts.
L88E0:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1Dngn3:
L88E1:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88E3:  .byte $05                   ;5 counts.
L88E4:  .byte MCTL_CNTRL0,    $B6   ;50% duty, len counter no, env no, vol=6.
L88E6:  .byte $96, $07              ;A#3,  7 counts.
L88E8:  .byte $99, $06              ;C#4,  6 counts.
L88EA:  .byte $9C, $06              ;E4,   6 counts.
L88EC:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1Dngn4:
L88ED:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88EF:  .byte $05                   ;5 counts.
L88F0:  .byte MCTL_CNTRL0,    $B6   ;50% duty, len counter no, env no, vol=6.
L88F2:  .byte $97, $07              ;B3,   7 counts.
L88F4:  .byte $9A, $06              ;D4,   6 counts.
L88F6:  .byte $9D, $06              ;F4,   6 counts.
L88F8:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1Dngn5:
L88F9:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L88FB:  .byte $05                   ;5 counts.
L88FC:  .byte MCTL_CNTRL0,    $B6   ;50% duty, len counter no, env no, vol=6.
L88FE:  .byte $91, $07              ;F3,   7 counts.
L8900:  .byte $94, $06              ;Ab3,  6 counts.
L8902:  .byte $98, $06              ;C4,   6 counts.
L8904:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1Dngn6:
L8905:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8907:  .byte $96, $98, $96, $98    ;A#3, C4,  A#3, C4.
L890B:  .byte $96, $98, $96, $98    ;A#3, C4,  A#3, C4.
L890F:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8910:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1Dngn7:
L8911:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8913:  .byte $95, $97, $95, $97    ;A3,  B3,  A3,  B3.
L8917:  .byte $95, $97, $95, $97    ;A3,  B3,  A3,  B3.
L891B:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L891C:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIDngn1:
L891D:  .byte MCTL_NOTE_OFST, $09   ;Note offset of 9 notes.
L891F:  .byte MCTL_TEMPO,     $69   ;60/1.43=42 counts per second.
L8921:  .byte MCTL_JUMP             ;Jump to new music address.
L8922:  .word TRIDngn               ;($8950).

TRIDngn2:
L8924:  .byte MCTL_NOTE_OFST, $06   ;Note offset of 6 notes.
L8926:  .byte MCTL_TEMPO,     $64   ;60/1.5=40 counts per second.
L8928:  .byte MCTL_JUMP             ;Jump to new music address.
L8929:  .word TRIDngn               ;($8950).

TRIDngn3:
L892B:  .byte MCTL_NOTE_OFST, $03   ;Note offset of 3 notes.
L892D:  .byte MCTL_TEMPO,     $5F   ;60/1.58=38 counts per second.
L892F:  .byte MCTL_JUMP             ;Jump to new music address.
L8930:  .word TRIDngn               ;($8950).

TRIDngn4:
L8932:  .byte MCTL_TEMPO,     $5A   ;60/1.67=36 counts per second.
L8934:  .byte MCTL_JUMP             ;Jump to new music address.
L8935:  .word TRIDngn               ;($8950).

TRIDngn5:
L8937:  .byte MCTL_NOTE_OFST, $FD   ;Note offset of 253 notes.
L8939:  .byte MCTL_TEMPO,     $55   ;60/1.76=34 counts per second.
L893B:  .byte MCTL_JUMP             ;Jump to new music address.
L893C:  .word TRIDngn               ;($8950).

TRIDngn6:
L893E:  .byte MCTL_NOTE_OFST, $FA   ;Note offset of 250 notes.
L8940:  .byte MCTL_TEMPO,     $50   ;60/1.88=32 counts per second.
L8942:  .byte MCTL_JUMP             ;Jump to new music address.
L8943:  .word TRIDngn               ;($8950).

TRIDngn7:
L8945:  .byte MCTL_NOTE_OFST, $F7   ;Note offset of 247 notes.
L8947:  .byte MCTL_TEMPO,     $4B   ;60/2.0=30 counts per second.
L8949:  .byte MCTL_JUMP             ;Jump to new music address.
L894A:  .word TRIDngn               ;($8950).

TRIDngn8:
L894C:  .byte MCTL_NOTE_OFST, $F4   ;Note offset of 244 notes.
L894E:  .byte MCTL_TEMPO,     $46   ;60/2.14=28 counts per second.

TRIDngn:
L8950:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L8952:  .byte $AC, $18              ;Ab5, 24 counts.
L8954:  .byte $AE, $18              ;A#5, 24 counts.
L8956:  .byte $AC, $18              ;Ab5, 24 counts.
L8958:  .byte $AE, $18              ;A#5, 24 counts.
L895A:  .byte $B1, $18              ;C#6, 24 counts.
L895C:  .byte $AE, $18              ;A#5, 24 counts.
L895E:  .byte $AC, $18              ;Ab5, 24 counts.
L8960:  .byte $AE, $0C              ;A#5, 12 counts.
L8962:  .byte $AC, $0C              ;Ab5, 12 counts.
L8964:  .byte $AB, $18              ;G5,  24 counts.
L8966:  .byte $A9, $0C              ;F5,  12 counts.
L8968:  .byte $AB, $0C              ;G5,  12 counts.
L896A:  .byte $AE, $0C              ;A#5, 12 counts.
L896C:  .byte $AC, $0C              ;Ab5, 12 counts.
L896E:  .byte $AB, $0C              ;G5,  12 counts.
L8970:  .byte $A9, $0C              ;F5,  12 counts.
L8972:  .byte $A8, $18              ;E5,  24 counts.
L8974:  .byte $A6, $0C              ;D5,  12 counts.
L8976:  .byte $A8, $0C              ;E5,  12 counts.
L8978:  .byte $AB, $18              ;G5,  24 counts.
L897A:  .byte $A4, $18              ;C5,  24 counts.
L897C:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L897E:  .byte MCTL_JUMP             ;Jump to new music address.
L897F:  .word TRIDngn9              ;($8991).
L8981:  .byte MCTL_JUMP             ;Jump to new music address.
L8982:  .word TRIDngn9              ;($8991).
L8984:  .byte $AA, $30              ;F#5, 48 counts.
L8986:  .byte MCTL_JUMP             ;Jump to new music address.
L8987:  .word TRIDngn10             ;($899D).
L8989:  .byte MCTL_JUMP             ;Jump to new music address.
L898A:  .word TRIDngn10             ;($899D).
L898C:  .byte $A9, $30              ;F5,  48 counts.
L898E:  .byte MCTL_JUMP             ;Jump to new music address.
L898F:  .word TRIDngn               ;($8950).

TRIDngn9:
L8991:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8993:  .byte $AA, $A8, $AA, $A8    ;F#5, E5,  F#5, E5.
L8997:  .byte $AA, $A8, $AA, $A8    ;F#5, E5,  F#5, E5.
L899B:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L899C:  .byte MCTL_RETURN           ;Return to previous music block.

TRIDngn10:
L899D:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L899F:  .byte $A9, $A7, $A9, $A7    ;F5,  D#5, F5,  D#5.
L89A3:  .byte $A9, $A7, $A9, $A7    ;F5,  D#5, F5,  D#5.
L89A7:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L89A8:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ1EntFight:
L89A9:  .byte MCTL_TEMPO,     $50   ;60/1.88=32 counts per second.
L89AB:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L89AD:  .byte MCTL_JUMP             ;Jump to new music address.
L89AE:  .word EntFight              ;($8AAB).
L89B0:  .byte MCTL_JUMP             ;Jump to new music address.
L89B1:  .word EntFight              ;($8AAB).
L89B3:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.
L89B5:  .byte $98, $24              ;C4,  36 counts.
L89B7:  .byte $98, $06              ;C4,   6 counts.
L89B9:  .byte $99, $06              ;C#4,  6 counts.
L89BB:  .byte $9A, $06              ;D4,   6 counts.
L89BD:  .byte $9C, $06              ;E4,   6 counts.

;----------------------------------------------------------------------------------------------------

SQ1Fight:
L89BF:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.

SQ1FightLoop:
L89C1:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L89C3:  .byte $9D, $18              ;F4, 24 counts.
L89C5:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L89C7:  .byte $10                   ;16 counts.
L89C8:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L89CA:  .byte $9F, $02              ;G4,   2 counts.
L89CC:  .byte $A0, $02              ;Ab4,  2 counts.
L89CE:  .byte $A1, $02              ;A4,   2 counts.
L89D0:  .byte $A2, $02              ;A#4,  2 counts.
L89D2:  .byte $A3, $18              ;B4,  24 counts.
L89D4:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L89D6:  .byte $10                   ;16 counts.
L89D7:  .byte MCTL_JUMP             ;Jump to new music address.
L89D8:  .word SQ1Fight2             ;($8ABF).
L89DA:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L89DC:  .byte $9D, $02              ;F4,   2 counts.
L89DE:  .byte $9E, $02              ;F#4,  2 counts.
L89E0:  .byte $9F, $02              ;G4,   2 counts.
L89E2:  .byte $A0, $02              ;Ab4,  2 counts.
L89E4:  .byte $A1, $18              ;A4,  24 counts.
L89E6:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L89E8:  .byte $10                   ;16 counts.
L89E9:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L89EB:  .byte $A0, $02              ;Ab4,  2 counts.
L89ED:  .byte $A1, $02              ;A4,   2 counts.
L89EF:  .byte $A2, $02              ;A#4,  2 counts.
L89F1:  .byte $A3, $02              ;B4,   2 counts.
L89F3:  .byte $A4, $18              ;C5,  24 counts.
L89F5:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L89F7:  .byte $10                   ;16 counts.
L89F8:  .byte MCTL_JUMP             ;Jump to new music address.
L89F9:  .word SQ1Fight2             ;($8ABF).
L89FB:  .byte MCTL_JUMP             ;Jump to new music address.
L89FC:  .word SQ1Fight2             ;($8ABF).
L89FE:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A00:  .byte $9D, $02              ;F4,   2 counts.
L8A02:  .byte $9E, $02              ;F#4,  2 counts.
L8A04:  .byte $9F, $02              ;G4,   2 counts.
L8A06:  .byte $A0, $02              ;Ab4,  2 counts.
L8A08:  .byte $A1, $18              ;A4,  24 counts.
L8A0A:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A0C:  .byte $10                   ;16 counts.
L8A0D:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A0F:  .byte $9B, $02              ;D#4,  2 counts.
L8A11:  .byte $9C, $02              ;E4,   2 counts.
L8A13:  .byte $9D, $02              ;F4,   2 counts.
L8A15:  .byte $9E, $02              ;F#4,  2 counts.
L8A17:  .byte $9F, $18              ;G4,  24 counts.
L8A19:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A1B:  .byte $10                   ;16 counts.
L8A1C:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A1E:  .byte $A5, $02              ;C#5,  2 counts.
L8A20:  .byte $A6, $02              ;D5,   2 counts.
L8A22:  .byte $A7, $02              ;D#5,  2 counts.
L8A24:  .byte $A8, $02              ;E5,   2 counts.
L8A26:  .byte $A9, $18              ;F5,  24 counts.
L8A28:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A2A:  .byte $10                   ;16 counts.
L8A2B:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A2D:  .byte $A4, $02              ;C5,   2 counts.
L8A2F:  .byte $A5, $02              ;C#5,  2 counts.
L8A31:  .byte $A6, $02              ;D5,   2 counts.
L8A33:  .byte $A7, $02              ;D#5,  2 counts.
L8A35:  .byte $A8, $18              ;E5,  24 counts.
L8A37:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A39:  .byte $10                   ;16 counts.
L8A3A:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A3C:  .byte $A3, $02              ;B4,   2 counts.
L8A3E:  .byte $A4, $02              ;C5,   2 counts.
L8A40:  .byte $A5, $02              ;C#5,  2 counts.
L8A42:  .byte $A6, $02              ;D5,   2 counts.
L8A44:  .byte $A7, $18              ;D#5, 24 counts.
L8A46:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A48:  .byte $10                   ;16 counts.
L8A49:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A4B:  .byte $A3, $02              ;B4,   2 counts.
L8A4D:  .byte $A4, $02              ;C5,   2 counts.
L8A4F:  .byte $A5, $02              ;C#5,  2 counts.
L8A51:  .byte $A6, $02              ;D5,   2 counts.
L8A53:  .byte $A7, $18              ;D#5, 24 counts.
L8A55:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A57:  .byte $10                   ;16 counts.
L8A58:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A5A:  .byte $A2, $02              ;A#4,  2 counts.
L8A5C:  .byte $A3, $02              ;B4,   2 counts.
L8A5E:  .byte $A4, $02              ;C5,   2 counts.
L8A60:  .byte $A5, $02              ;C#5,  2 counts.
L8A62:  .byte $A6, $18              ;D5,  24 counts.
L8A64:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A66:  .byte $10                   ;16 counts.
L8A67:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A69:  .byte $A1, $02              ;A4,   2 counts.
L8A6B:  .byte $A2, $02              ;A#4,  2 counts.
L8A6D:  .byte $A3, $02              ;B4,   2 counts.
L8A6F:  .byte $A4, $02              ;C5,   2 counts.
L8A71:  .byte $A5, $18              ;C#5, 24 counts.
L8A73:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A75:  .byte $10                   ;16 counts.
L8A76:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8A78:  .byte $A2, $02              ;A#4,  2 counts.
L8A7A:  .byte $A3, $02              ;B4,   2 counts.
L8A7C:  .byte $A4, $02              ;C5,   2 counts.
L8A7E:  .byte $A5, $02              ;C#5,  2 counts.
L8A80:  .byte $A6, $18              ;D5,  24 counts.
L8A82:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8A84:  .byte $10                   ;16 counts.
L8A85:  .byte $A7, $02              ;D#5,  2 counts.
L8A87:  .byte $A8, $02              ;E5,   2 counts.
L8A89:  .byte $A9, $02              ;F5,   2 counts.
L8A8B:  .byte $AA, $02              ;F#5,  2 counts.
L8A8D:  .byte MCTL_ADD_SPACE, $08   ;8 counts between notes.
L8A8F:  .byte $AB, $A6, $AB, $AA    ;G5,  D5,  G5,  F#5.
L8A93:  .byte $A7, $AA, $A9, $A6    ;D#5, F#5, F5,  D5.
L8A97:  .byte $A9, $A8, $A5, $A8    ;F5,  E5,  C#5, E5.
L8A9B:  .byte $A7, $A4, $A1, $9E    ;D#5, C5,  A4,  F#4.
L8A9F:  .byte $9B, $98, $99, $90    ;D#4, C4,  C#4, E3.
L8AA3:  .byte $93, $96, $99, $9C    ;G3,  A#3, C#4, E4.
L8AA7:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8AA8:  .byte MCTL_JUMP             ;Jump to new music address.
L8AA9:  .word SQ1FightLoop          ;($89C1).

;----------------------------------------------------------------------------------------------------

EntFight:
L8AAB:  .byte MCTL_ADD_SPACE, $01   ;1 counts between notes.
L8AAD:  .byte $98, $9C, $9F, $A2    ;C4,  E4,  G4,  A#4.
L8AB1:  .byte $A5, $A8, $AB, $AE    ;C#5, E5,  G5,  A#5.
L8AB5:  .byte $B1, $AE, $AB, $A8    ;C#6, A#5, G5,  E5.
L8AB9:  .byte $A4, $A2, $9F, $9C    ;C5,  A#4, G4,  E4.
L8ABD:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8ABE:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ1Fight2:
L8ABF:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8AC1:  .byte $9E, $02              ;F#4,  2 counts.
L8AC3:  .byte $9F, $02              ;G4,   2 counts.
L8AC5:  .byte $A0, $02              ;Ab4,  2 counts.
L8AC7:  .byte $A1, $02              ;A4,   2 counts.
L8AC9:  .byte $A2, $18              ;A#4, 24 counts.
L8ACB:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8ACD:  .byte $10                   ;16 counts.
L8ACE:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIEntFight:
L8ACF:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8AD1:  .byte MCTL_JUMP             ;Jump to new music address.
L8AD2:  .word EntFight              ;($8AAB).
L8AD4:  .byte MCTL_JUMP             ;Jump to new music address.
L8AD5:  .word EntFight              ;($8AAB).
L8AD7:  .byte $98, $24              ;C4,  36 counts.
L8AD9:  .byte $98, $06              ;C4,   6 counts.
L8ADB:  .byte $99, $06              ;C#4,  6 counts.
L8ADD:  .byte $9A, $06              ;D4,   6 counts.
L8ADF:  .byte $9C, $06              ;E4,   6 counts.

;----------------------------------------------------------------------------------------------------

TRIFight:
L8AE1:  .byte MCTL_CNTRL0,    $10   ;12.5% duty, len counter yes, env no, vol=0.
L8AE3:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L8AE5:  .byte $9D, $A0, $A4         ;F4,  Ab4, C5.
L8AE8:  .byte $12                   ;18 counts.
L8AE9:  .byte $A6                   ;D5.
L8AEA:  .byte $06                   ;6 counts.
L8AEB:  .byte $9D, $A0, $A3         ;F4,  Ab4, B4.
L8AEE:  .byte $12                   ;18 counts.
L8AEF:  .byte $A6                   ;D5.
L8AF0:  .byte $06                   ;6 counts.
L8AF1:  .byte $9F, $A2, $A5         ;G4,  A#4, C#5.
L8AF4:  .byte $12                   ;18 counts.
L8AF5:  .byte $A8                   ;E5.
L8AF6:  .byte $06                   ;6 counts.
L8AF7:  .byte $9B, $9E, $A1         ;D#4, F#4, A4.
L8AFA:  .byte $12                   ;18 counts.
L8AFB:  .byte $A4                   ;C5.
L8AFC:  .byte $06                   ;6 counts.
L8AFD:  .byte $A1, $A4, $A7         ;A4,  C5,  D#5.
L8B00:  .byte $12                   ;18 counts.
L8B01:  .byte $AB                   ;G5.
L8B02:  .byte $06                   ;6 counts.
L8B03:  .byte $9B, $9F, $A5         ;D#4, G4,  C#5.
L8B06:  .byte $12                   ;18 counts.
L8B07:  .byte $A8                   ;E5.
L8B08:  .byte $06                   ;6 counts.
L8B09:  .byte $9E, $A2, $A6         ;F#4, A#4, D5.
L8B0C:  .byte $12                   ;18 counts.
L8B0D:  .byte $AA                   ;F#5.
L8B0E:  .byte $06                   ;6 counts.
L8B0F:  .byte $9A, $9E, $A1         ;D4,  F#4, A4.
L8B12:  .byte $12                   ;18 counts.
L8B13:  .byte $A6                   ;D5.
L8B14:  .byte $06                   ;6 counts.
L8B15:  .byte $9F, $A2, $A6         ;G4,  A#4, D5.
L8B18:  .byte $12                   ;18 counts.
L8B19:  .byte $A8                   ;E5.
L8B1A:  .byte $06                   ;6 counts.
L8B1B:  .byte $9F, $A3, $A6         ;G4,  B4,  D5.
L8B1E:  .byte $12                   ;18 counts.
L8B1F:  .byte $A9                   ;F5.
L8B20:  .byte $06                   ;6 counts.
L8B21:  .byte $98, $9F, $A2         ;C4,  G4,  A#4.
L8B24:  .byte $12                   ;18 counts.
L8B25:  .byte $A5                   ;C#5.
L8B26:  .byte $06                   ;6 counts.
L8B27:  .byte $9D, $9E, $A1         ;F4,  F#4, A4.
L8B2A:  .byte $12                   ;18 counts.
L8B2B:  .byte $A4                   ;C5.
L8B2C:  .byte $06                   ;6 counts.
L8B2D:  .byte $96, $9D, $A0         ;A#3, F4,  Ab4.
L8B30:  .byte $12                   ;18 counts.
L8B31:  .byte $A7                   ;D#5.
L8B32:  .byte $06                   ;6 counts.
L8B33:  .byte $96, $9D, $A0         ;A#3, F4,  Ab4.
L8B36:  .byte $12                   ;18 counts.
L8B37:  .byte $A6                   ;D5.
L8B38:  .byte $06                   ;6 counts.
L8B39:  .byte $95, $9C, $9F         ;A3,  E4,  G4.
L8B3C:  .byte $12                   ;18 counts.
L8B3D:  .byte $A2                   ;A#4.
L8B3E:  .byte $06                   ;6 counts.
L8B3F:  .byte $9A, $9E, $A1         ;D4,  F#4, A4.
L8B42:  .byte $12                   ;18 counts.
L8B43:  .byte $A6                   ;D5.
L8B44:  .byte $06                   ;6 counts.
L8B45:  .byte MCTL_ADD_SPACE, $08   ;8 counts between notes.
L8B47:  .byte $AE, $AB, $AE, $AD    ;A#5, G5,  A#5, A5.
L8B4B:  .byte $AA, $AD, $AC, $A9    ;F#5, A5,  Ab5, F5.
L8B4F:  .byte $AC, $AB, $A8, $AB    ;Ab5, G5,  E5,  G5.
L8B53:  .byte $AA, $AD, $AA, $A7    ;F#5, A5,  F#5, D#5.
L8B57:  .byte $A4, $A1, $A2, $99    ;C5,  A4,  A#4, C#4.
L8B5B:  .byte $9C, $9F, $A2, $A5    ;E4,  G4,  A#4, C#5.
L8B5F:  .byte MCTL_JUMP             ;Jump to new music address.
L8B60:  .word $8AE3                 ;

;----------------------------------------------------------------------------------------------------

SQ1EndBoss:
L8B62:  .byte MCTL_TEMPO,     $50   ;60/1.88=32 counts per second.

SQ1EndBoss2:
L8B64:  .byte MCTL_JUMP             ;Jump to new music address.
L8B65:  .word SQ1EndBoss3           ;($8BA1).
L8B67:  .byte MCTL_JUMP             ;Jump to new music address.
L8B68:  .word SQEndBoss             ;($8BB4).
L8B6A:  .byte MCTL_JUMP             ;Jump to new music address.
L8B6B:  .word SQ1EndBoss3           ;($8BA1).
L8B6D:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L8B6F:  .byte MCTL_CNTRL0,    $0F   ;12.5% duty, len counter yes, env yes, vol=15.
L8B71:  .byte $99, $9B, $9C, $9E    ;C#4, D#4, E4,  F#4.
L8B75:  .byte $9F                   ;G4.
L8B76:  .byte $1E                   ;30 counts.
L8B77:  .byte $A2, $9F, $A5         ;A#4, G4,  C#5.
L8B7A:  .byte $06                   ;6 counts.
L8B7B:  .byte $A4, $A2, $A1         ;C5,  A#4, A4.
L8B7E:  .byte $06                   ;6 counts.
L8B7F:  .byte $9F                   ;G4.
L8B80:  .byte $06                   ;6 counts.
L8B81:  .byte $A1                   ;A4.
L8B82:  .byte $06                   ;6 counts.
L8B83:  .byte $A2                   ;A#4.
L8B84:  .byte $12                   ;18 counts.
L8B85:  .byte $A4, $A2, $A1         ;C5,  A#4, A4.
L8B88:  .byte $06                   ;6 counts.
L8B89:  .byte $9F                   ;G4.
L8B8A:  .byte $06                   ;6 counts.
L8B8B:  .byte $A1, $A2, $A1, $9F    ;A4,  A#4, A4,  G4.
L8B8F:  .byte $9E                   ;F#4.
L8B90:  .byte $06                   ;6 counts.
L8B91:  .byte $9C                   ;E4.
L8B92:  .byte $06                   ;6 counts.
L8B93:  .byte $A1, $9F, $9E, $9C    ;A4,  G4,  F#4, E4.
L8B97:  .byte MCTL_CNTRL0,    $3F   ;12.5% duty, len counter no, env no, vol=15.
L8B99:  .byte $9B                   ;D#4.
L8B9A:  .byte $2A                   ;42 counts.
L8B9B:  .byte MCTL_CNTRL0,    $0F   ;12.5% duty, len counter yes, env yes, vol=15.
L8B9D:  .byte $18                   ;24 counts.
L8B9E:  .byte MCTL_JUMP             ;Jump to new music address.
L8B9F:  .word SQ1EndBoss2           ;($8B64).

SQ1EndBoss3:
L8BA1:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8BA3:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L8BA5:  .byte $95, $97              ;A3,  B3.
L8BA7:  .byte MCTL_CNTRL0,    $02   ;12.5% duty, len counter yes, env yes, vol=2.
L8BA9:  .byte $95, $97              ;A3,  B3.
L8BAB:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L8BAD:  .byte $95, $97              ;A3,  B3.
L8BAF:  .byte MCTL_CNTRL0,    $02   ;12.5% duty, len counter yes, env yes, vol=2.
L8BB1:  .byte $95, $97              ;A3,  B3.
L8BB3:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQEndBoss:
L8BB4:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L8BB6:  .byte MCTL_CNTRL0,    $0F   ;12.5% duty, len counter yes, env yes, vol=15.
L8BB8:  .byte $95, $97, $98, $9A    ;A3,  B3,  C4,  D4.
L8BBC:  .byte $9B                   ;D#4.
L8BBD:  .byte $1E                   ;30 counts.
L8BBE:  .byte $9E, $9B, $A1         ;F#4, D#4, A4.
L8BC1:  .byte $06                   ;6 counts.
L8BC2:  .byte $A0, $9E, $9D         ;Ab4, F#4, F4.
L8BC5:  .byte $06                   ;6 counts.
L8BC6:  .byte $9B                   ;D#4.
L8BC7:  .byte $06                   ;6 counts.
L8BC8:  .byte $9D                   ;F4.
L8BC9:  .byte $06                   ;6 counts.
L8BCA:  .byte $9E                   ;F#4.
L8BCB:  .byte $12                   ;18 counts.
L8BCC:  .byte $A0, $9E, $9D         ;Ab4, F#4, F4.
L8BCF:  .byte $06                   ;6 counts.
L8BD0:  .byte $9B                   ;D#4.
L8BD1:  .byte $06                   ;6 counts.
L8BD2:  .byte $9D, $9E, $9D, $9B    ;F4,  F#4, F4,  D#4.
L8BD6:  .byte $9A                   ;D4.
L8BD7:  .byte $06                   ;6 counts.
L8BD8:  .byte $98                   ;C4.
L8BD9:  .byte $06                   ;6 counts.
L8BDA:  .byte $9D, $9B, $9A, $98    ;F4,  D#4, D4,  C4.
L8BDE:  .byte MCTL_CNTRL0,    $3F   ;12.5% duty, len counter no, env no, vol=15.
L8BE0:  .byte $97                   ;B3.
L8BE1:  .byte $2A                   ;42 counts.
L8BE2:  .byte MCTL_CNTRL0,    $0F   ;12.5% duty, len counter yes, env yes, vol=15.
L8BE4:  .byte $18                   ;24 counts.
L8BE5:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ2EndBoss:
L8BE6:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8BE8:  .byte MCTL_JUMP             ;Jump to new music address.
L8BE9:  .word SQ2EndBoss2           ;($8C00).
L8BEB:  .byte MCTL_JUMP             ;Jump to new music address.
L8BEC:  .word SQ2EndBoss3           ;($8C11).
L8BEE:  .byte MCTL_JUMP             ;Jump to new music address.
L8BEF:  .word SQ2EndBoss3           ;($8C11).
L8BF1:  .byte MCTL_JUMP             ;Jump to new music address.
L8BF2:  .word SQ2EndBoss3           ;($8C11).
L8BF4:  .byte MCTL_JUMP             ;Jump to new music address.
L8BF5:  .word SQ2EndBoss4           ;($8C15).
L8BF7:  .byte MCTL_JUMP             ;Jump to new music address.
L8BF8:  .word SQ2EndBoss2           ;($8C00).
L8BFA:  .byte MCTL_JUMP             ;Jump to new music address.
L8BFB:  .word SQEndBoss             ;($8BB4).
L8BFD:  .byte MCTL_JUMP             ;Jump to new music address.
L8BFE:  .word SQ2EndBoss            ;($8BE6).

SQ2EndBoss2:
L8C00:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L8C02:  .byte $90, $8E              ;E3,  D3.
L8C04:  .byte MCTL_CNTRL0,    $02   ;12.5% duty, len counter yes, env yes, vol=2.
L8C06:  .byte $89, $8E              ;A2,  D3.
L8C08:  .byte MCTL_CNTRL0,    $82   ;50% duty, len counter yes, env yes, vol=2.
L8C0A:  .byte $90, $8E              ;E3,  D3.
L8C0C:  .byte MCTL_CNTRL0,    $02   ;12.5% duty, len counter yes, env yes, vol=2.
L8C0E:  .byte $89, $8E              ;A2,  D3.
L8C10:  .byte MCTL_RETURN           ;Return to previous music block.

SQ2EndBoss3:
L8C11:  .byte $92, $8F, $92, $8F    ;F#3, D#3, F#3, D#3.

SQ2EndBoss4:
L8C15:  .byte $92, $8F, $92, $8F    ;F#3, D#3, F#3, D#3.
L8C19:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIEndBoss:
L8C1A:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8C1C:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.

TRIEndBossLoop:
L8C1E:  .byte $9A, $98, $9A, $98    ;D4,  C4,  D4,  C4.
L8C22:  .byte $9A, $98, $9A, $98    ;D4,  C4,  D4,  C4.
L8C26:  .byte MCTL_JUMP             ;Jump to new music address.
L8C27:  .word TRIEndBoss2           ;($8C35).
L8C29:  .byte MCTL_JUMP             ;Jump to new music address.
L8C2A:  .word TRIEndBoss2           ;($8C35).
L8C2C:  .byte MCTL_JUMP             ;Jump to new music address.
L8C2D:  .word TRIEndBoss2           ;($8C35).
L8C2F:  .byte MCTL_JUMP             ;Jump to new music address.
L8C30:  .word TRIEndBoss3           ;($8C39).
L8C32:  .byte MCTL_JUMP             ;Jump to new music address.
L8C33:  .word TRIEndBossLoop        ;($8C1E).

TRIEndBoss2:
L8C35:  .byte $9E, $9B, $9E, $9B    ;F#4, D#4, F#4, D#4.

TRIEndBoss3:
L8C39:  .byte $9E, $9B, $9E, $9B    ;F#4, D#4, F#4, D#4.
L8C3D:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ2SlvrHrp:
L8C3E:  .byte $03                   ;3 counts.

SQ1SlvrHrp:
L8C3F:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8C41:  .byte $06                   ;6 counts.
L8C42:  .byte MCTL_CNTRL0,    $89   ;50% duty, len counter yes, env yes, vol=9.
L8C44:  .byte MCTL_TEMPO,     $3C   ;60/2.5=24 counts per second.
L8C46:  .byte $B9, $06              ;A6, 6 counts.
L8C48:  .byte $B5, $05              ;F6, 5 counts.
L8C4A:  .byte $B2, $04              ;D6, 4 counts.
L8C4C:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8C4D:  .byte $AF                   ;B5.
L8C4F:  .byte MCTL_TEMPO,     $46   ;60/2.14=28 counts per second.
L8C51:  .byte $B5, $B2, $AF, $AD    ;F6,  D6,  B5,  A5.
L8C55:  .byte MCTL_TEMPO,     $50   ;60/1.88=32 counts per second.
L8C57:  .byte $B2, $AF, $AD, $A9    ;D6,  B5,  A5,  F5.
L8C5B:  .byte MCTL_TEMPO,     $5A   ;60/1.67=36 counts per second.
L8C5D:  .byte $AD, $A9, $A6, $A3    ;A5,  F5,  D5,  B4.
L8C61:  .byte MCTL_TEMPO,     $64   ;60/1.5=40 counts per second.
L8C63:  .byte $A9, $A6, $A3, $A1    ;F5,  D5,  B4,  A4.
L8C67:  .byte MCTL_TEMPO,     $6D   ;60/1.38=43 counts per second.
L8C69:  .byte $A6, $A3, $A1, $9D    ;D5,  B4,  A4,  F4.
L8C6D:  .byte MCTL_TEMPO,     $76   ;60/1.27=47 counts per second.
L8C6F:  .byte $A1, $9D, $9A, $97    ;A4,  F4,  D4,  B3.
L8C73:  .byte MCTL_TEMPO,     $7F   ;60/1.18=51 counts per second.
L8C75:  .byte $9D, $9A, $97, $95    ;F4,  D4,  B3,  A3.
L8C79:  .byte MCTL_TEMPO,     $88   ;60/1.1=55 counts per second.
L8C7B:  .byte $9A, $97, $95, $91    ;D4,  B3,  A3,  F3.
L8C7F:  .byte MCTL_TEMPO,     $90   ;60/1.04=58 counts per second.
L8C81:  .byte $87, $8E, $91, $95    ;G2,  D3,  F3,  A3.
L8C85:  .byte $97, $9A, $97, $9A    ;B3,  D4,  B3,  D4.
L8C89:  .byte $9D, $A1, $A3, $A6    ;F4,  A4,  B4,  D5.
L8C8D:  .byte $A3, $A6, $A9, $AD    ;B4,  D5,  F5,  A5.
L8C91:  .byte $AF, $B2              ;B5,  D6.
L8C93:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8C94:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8C96:  .byte $B7, $30              ;G6, 48 counts.
L8C98:  .byte $00                   ;End music.
L8C99:  .byte MCTL_NO_OP            ;Continue previous music.

;----------------------------------------------------------------------------------------------------

TRIFryFlute:
L8C9A:  .byte MCTL_NOTE_OFST, $0C   ;Note offset of 12 notes.
L8C9C:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.
L8C9E:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L8CA0:  .byte $9F, $18              ;G4, 24 counts.
L8CA2:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8CA4:  .byte $A1, $A3, $A4, $A6    ;A4,  B4,  C5,  D5.
L8CA8:  .byte $A8, $A9, $AB, $AD    ;E5,  F5,  G5,  A5.
L8CAC:  .byte $AF, $B0, $B2, $B4    ;B5,  C6,  D6,  E6.
L8CB0:  .byte $B5                   ;F6.
L8CB1:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8CB2:  .byte MCTL_CNTRL0,    $20   ;12.5% duty, len counter no, env yes, vol=0.
L8CB4:  .byte $B7, $11              ;G6, 17 counts.
L8CB6:  .byte $B7, $10              ;G6, 16 counts.
L8CB8:  .byte $B7, $10              ;G6, 16 counts.
L8CBA:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L8CBC:  .byte MCTL_ADD_SPACE, $02   ;2 counts between notes.
L8CBE:  .byte $B7, $B9, $B7, $B9    ;G6,  A6,  G6,  A6.
L8CC2:  .byte $B7, $B9, $B7, $B9    ;G6,  A6,  G6,  A6.
L8CC6:  .byte $B7, $B9, $B7, $B9    ;G6,  A6,  G6,  A6.
L8CCA:  .byte $B7, $B9, $B7, $B9    ;G6,  A6,  G6,  A6.
L8CCE:  .byte $B7, $B9              ;G6,  A6.
L8CD0:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8CD1:  .byte $B7, $0D              ;G6, 13 counts.
L8CD3:  .byte $B5, $0D              ;F6, 13 counts.
L8CD5:  .byte $B2, $08              ;D6,  8 counts.
L8CD7:  .byte $AF, $08              ;B5,  8 counts.
L8CD9:  .byte $AD, $08              ;A5,  8 counts.
L8CDB:  .byte $AB, $30              ;G5, 48 counts.
L8CDD:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L8CDF:  .byte $00                   ;End music.
L8CE0:  .byte MCTL_NO_OP            ;Continue previous music.

;----------------------------------------------------------------------------------------------------

SQ2RnbwBrdg:
L8CE1:  .byte $03                   ;3 counts.

SQ1RnbwBrdg:
L8CE2:  .byte MCTL_TEMPO,     $50   ;60/1.88=32 counts per second.
L8CE4:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L8CE6:  .byte $8C, $09              ;C3, 9 counts.
L8CE8:  .byte $93, $08              ;G3, 8 counts.
L8CEA:  .byte $97, $07              ;B3, 7 counts.
L8CEC:  .byte $9C, $06              ;E4, 6 counts.
L8CEE:  .byte $8E, $05              ;D3, 5 counts.
L8CF0:  .byte $95, $04              ;A3, 4 counts.
L8CF2:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8CF4:  .byte $98, $9D              ;C4,  F4.
L8CF6:  .byte MCTL_TEMPO,     $58   ;60/1.7=35 counts per second.
L8CF8:  .byte $90, $97, $9A, $9F    ;E3,  B3,  D4,  G4.
L8CFC:  .byte MCTL_TEMPO,     $60   ;60/1.56=38 counts per second.
L8CFE:  .byte $91, $98, $9C, $A1    ;F3,  C4,  E4,  A4.
L8D02:  .byte MCTL_TEMPO,     $68   ;60/1.44=42 counts per second.
L8D04:  .byte $87, $8E, $93, $98    ;G2,  D3,  G3,  C4.
L8D08:  .byte MCTL_TEMPO,     $70   ;60/1.34=45 counts per second.
L8D0A:  .byte $9C, $A1, $A4, $A9    ;E4,  A4,  C5,  F5.
L8D0E:  .byte $AD, $B0, $B5, $B4    ;A5,  C6,  F6,  E6.
L8D12:  .byte MCTL_TEMPO,     $64   ;60/1.5=40 counts per second.
L8D14:  .byte $AF, $AB, $A8, $A3    ;B5,  G5,  E5,  B4.
L8D18:  .byte MCTL_TEMPO,     $5A   ;60/1.67=36 counts per second.
L8D1A:  .byte $9F, $9C, $97, $93    ;G4,  E4,  B3,  G3.
L8D1E:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8D1F:  .byte $8C, $30              ;C3, 48 counts.
L8D21:  .byte $00                   ;End music.
L8D22:  .byte MCTL_NO_OP            ;Continue previous music.

;----------------------------------------------------------------------------------------------------

SQ2Death:
L8D23:  .byte $02                   ;2 counts.

SQ1Death:
L8D24:  .byte MCTL_TEMPO,     $96   ;60/1 = 60 counts per second.
L8D26:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8D28:  .byte $18                   ;24 counts.
L8D29:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8D2B:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8D2D:  .byte $A9, $9A, $A1, $A9    ;F5,  D4,  A4,  F5.
L8D31:  .byte $A8, $99, $A1, $A8    ;E5,  C#4, A4,  E5.
L8D35:  .byte $A6, $96, $9F, $A6    ;D5,  A#3, G4,  D5.
L8D39:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8D3A:  .byte $A5, $0D              ;C#5, 13 counts.
L8D3C:  .byte $A2, $0E              ;A#4, 14 counts.
L8D3E:  .byte $A1, $0F              ;A4,  15 counts.
L8D40:  .byte $A0, $0F              ;Ab4, 15 counts.
L8D42:  .byte $A1, $04              ;A4,   4 counts.
L8D44:  .byte $A0, $04              ;Ab4,  4 counts.
L8D46:  .byte $A1, $30              ;A4,  48 counts.
L8D48:  .byte $00                   ;End music.
L8D49:  .byte MCTL_NO_OP            ;Continue previous music.

;----------------------------------------------------------------------------------------------------

SQ2Cursed:
L8D4A:  .byte $01                   ;1 count.

SQ1Cursed:
L8D4B:  .byte MCTL_TEMPO,     $96   ;60/1 = 60 counts per second.
L8D4D:  .byte MCTL_CNTRL0,    $45   ;25% duty, len counter yes, env yes, vol=5.
L8D4F:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L8D51:  .byte MCTL_JUMP             ;Jump to new music address.
L8D52:  .word SQCursed2             ;($8D68).
L8D54:  .byte MCTL_JUMP             ;Jump to new music address.
L8D55:  .word SQCursed2             ;($8D68).
L8D57:  .byte MCTL_JUMP             ;Jump to new music address.
L8D58:  .word SQCursed2             ;($8D68).
L8D5A:  .byte MCTL_JUMP             ;Jump to new music address.
L8D5B:  .word SQCursed2             ;($8D68).
L8D5D:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8D5E:  .byte $90, $14              ;E3,  20 counts.
L8D60:  .byte $91, $02              ;F3,   2 counts.
L8D62:  .byte $92, $02              ;F#3,  2 counts.
L8D64:  .byte $8A, $30              ;A#2, 48 counts.
L8D66:  .byte $00                   ;End music.
L8D67:  .byte MCTL_NO_OP            ;Continue previous music.

SQCursed2:
L8D68:  .byte $8C, $97              ;C3, 151 counts.
L8D6A:  .byte $8B, $96              ;B2, 150 counts.
L8D6C:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ1Intro:

L8D6D:  .byte MCTL_TEMPO,     $7D   ;60/1.2=50 counts per second.
L8D6F:  .byte MCTL_CNTRL0,    $06   ;12.5% duty, len counter yes, env yes, vol=6.
L8D71:  .byte $A1, $13              ;B4, 19 counts.
L8D73:  .byte $A1, $05              ;A4,  5 counts.
L8D75:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8D77:  .byte $A1, $9F, $9F, $9F    ;A4,  G4,  G4,  G4.
L8D7B:  .byte $9D, $9F, $A1, $A2    ;F4,  G4,  A4,  A#4.
L8D7F:  .byte $A1, $9F, $A1, $A2    ;A4,  G4,  A4,  A#4.
L8D83:  .byte $A4, $A6, $A9, $A6    ;C5,  D5,  F5,  D5.
L8D87:  .byte $A4, $A2, $A1         ;C5,  A#4, A4.
L8D8A:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8D8B:  .byte $9F, $13              ;G4, 19 counts.
L8D8D:  .byte $9F, $05              ;G4,  5 counts.
L8D8F:  .byte $9F, $0C              ;G4, 12 counts.
L8D91:  .byte $A1, $13              ;B4, 19 counts.
L8D93:  .byte $A1, $05              ;B4,  5 counts.
L8D95:  .byte $A1, $0C              ;B4, 12 counts.
L8D97:  .byte $A1, $0C              ;B4, 12 counts.
L8D99:  .byte $9D, $0C              ;F4, 12 counts.
L8D9B:  .byte $A1, $0C              ;B4, 12 counts.
L8D9D:  .byte MCTL_CNTRL0,    $3F   ;12.5% duty, len counter no, env no, vol=15.
L8D9F:  .byte $9F, $60              ;G4, 96 counts.
L8DA1:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8DA3:  .byte $18                   ;24 counts.
L8DA4:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.

SQ1IntroLoop:
L8DA6:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8DA8:  .byte $A4, $13              ;C5, 19 counts.
L8DAA:  .byte $A4, $05              ;C5,  5 counts.
L8DAC:  .byte $A9, $18              ;F5, 24 counts.
L8DAE:  .byte MCTL_NO_OP            ;Skip byte.
L8DAF:  .byte $AB, $18              ;G5,  24 counts.
L8DB1:  .byte $AD, $18              ;A5,  24 counts.
L8DB3:  .byte $AE, $18              ;A#5, 24 counts.
L8DB5:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8DB7:  .byte $B0, $18              ;C6,  24 counts.
L8DB9:  .byte $B5, $30              ;F6,  48 counts.
L8DBB:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8DBD:  .byte $B4, $13              ;E6,  19 counts.
L8DBF:  .byte $B2, $05              ;D6,   5 counts.
L8DC1:  .byte $B2, $24              ;D6,  36 counts.
L8DC3:  .byte $B0, $0C              ;C6,  12 counts.
L8DC5:  .byte MCTL_CNTRL0,    $40   ;25% duty, len counter yes, env yes, vol=0.
L8DC7:  .byte $0C                   ;12 counts.
L8DC8:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8DCA:  .byte $AF, $0C              ;B5,  12 counts.
L8DCC:  .byte $AF, $0C              ;B5,  12 counts.
L8DCE:  .byte $B2, $0C              ;D6,  12 counts.
L8DD0:  .byte $B0, $18              ;C6,  24 counts.
L8DD2:  .byte $AD, $30              ;A5,  48 counts.
L8DD4:  .byte $A1, $13              ;A4,  19 counts.
L8DD6:  .byte $A1, $05              ;A4,   5 counts.
L8DD8:  .byte $A1, $18              ;A4,  24 counts.
L8DDA:  .byte $A1, $18              ;A4,  24 counts.
L8DDC:  .byte $A3, $18              ;B5,  24 counts.
L8DDE:  .byte $A5, $18              ;C#5, 24 counts.
L8DE0:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8DE2:  .byte $A6, $30              ;D5,  48 counts.
L8DE4:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8DE6:  .byte $0C                   ;12 counts.
L8DE7:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8DE9:  .byte $A6, $A8, $A9         ;D5,  E5,  F5.
L8DEC:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8DEE:  .byte $AB, $24              ;G5,  36 counts.
L8DF0:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8DF2:  .byte $0C                   ;12 counts.
L8DF3:  .byte $A6, $A6, $A9, $A9    ;D5,  D5,  F5,  F5.
L8DF6:  .byte $0C                   ;12 counts.
L8DF7:  .byte $A8                   ;E5.
L8DF8:  .byte $0C                   ;12 counts.
L8DF9:  .byte $A6                   ;D5.
L8DFA:  .byte $0C                   ;12 counts.
L8DFB:  .byte $A4                   ;C5.
L8DFC:  .byte $0C                   ;12 counts.
L8DFE:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E00:  .byte $AD                   ;A5.
L8E01:  .byte $30                   ;48 counts.
L8E02:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E04:  .byte $AE, $AD, $AB         ;A#5, A5, G5.
L8E07:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E09:  .byte $A9                   ;F5.
L8E0A:  .byte $24                   ;36 counts.
L8E0B:  .byte $A6                   ;D5.
L8E0C:  .byte $0C                   ;12 counts.
L8E0D:  .byte $A9                   ;F5.
L8E0E:  .byte $0C                   ;12 counts.
L8E0F:  .byte $AB                   ;G5.
L8E10:  .byte $30                   ;48 counts.
L8E11:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E13:  .byte $AD, $AB, $A9         ;A5,  G5,  F5.
L8E16:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E18:  .byte $A9                   ;F5.
L8E19:  .byte $24                   ;36 counts.
L8E1A:  .byte $A8                   ;E5.
L8E1B:  .byte $0C                   ;12 counts.
L8E1C:  .byte $A4                   ;C5.
L8E1D:  .byte $0C                   ;12 counts.
L8E1E:  .byte $B0                   ;C6.
L8E1F:  .byte $30                   ;48 counts.
L8E20:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E22:  .byte $AD, $AE, $B0         ;A5,  A#5, C6.
L8E25:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E27:  .byte $B2                   ;D6.
L8E28:  .byte $30                   ;48 counts.
L8E29:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E2B:  .byte $A6, $A8, $A9         ;D5,  E5,  F5.
L8E2E:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8E2F:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E31:  .byte $AE, $30              ;A#5, 48 counts.
L8E33:  .byte $AD, $30              ;A5,  48 counts.
L8E35:  .byte $A9, $3C              ;F5,  60 counts.
L8E37:  .byte MCTL_CNTRL0,    $45   ;25% duty, len counter yes, env yes, vol=5.
L8E39:  .byte $0C                   ;12 counts.
L8E3A:  .byte MCTL_JUMP             ;Jump to new music address.
L8E3B:  .word SQ1IntroLoop          ;($8DA6).

;----------------------------------------------------------------------------------------------------

SQ2Intro:
L8E3D:  .byte MCTL_CNTRL0,    $06   ;12.5% duty, len counter yes, env yes, vol=6.
L8E3F:  .byte $98, $13              ;C4, 19 counts.
L8E41:  .byte $9D, $05              ;F4,  5 counts.
L8E43:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8E45:  .byte $9D, $98, $98, $98    ;F4,  C4,  C4,  C4.
L8E49:  .byte $95, $98, $9D, $9F    ;A3,  C4,  F4,  G4. 
L8E4D:  .byte $9D, $98, $9D, $9F    ;F4,  C4,  F4,  G4. 
L8E51:  .byte $A1, $A2, $A6, $A2    ;A4,  A#4, D5,  A#4. 
L8E55:  .byte $A1, $9F, $9D         ;A4,  G4,  F4.
L8E58:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8E59:  .byte $98, $13              ;C4, 19 counts.
L8E5B:  .byte $98, $05              ;C4,  5 counts.
L8E5D:  .byte $98, $0C              ;C4, 12 counts.
L8E5F:  .byte $9D, $13              ;F4, 19 counts.
L8E61:  .byte $9D, $05              ;F4,  5 counts.
L8E63:  .byte $9D, $0C              ;F4, 12 counts.
L8E65:  .byte $9D, $0C              ;F4, 12 counts.
L8E67:  .byte $95, $0C              ;A3, 12 counts.
L8E69:  .byte $9D, $0C              ;F4, 12 counts.
L8E6B:  .byte MCTL_CNTRL0,    $3F   ;12.5% duty, len counter no, env no, vol=15.
L8E6D:  .byte $98, $60              ;C4, 96 counts.
L8E6F:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8E71:  .byte $18                   ;24 counts.

SQ2IntroLoop:
L8E72:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E74:  .byte $A2, $13              ;A#4, 19 counts.
L8E76:  .byte $A2, $05              ;A#4,  5 counts.
L8E78:  .byte $A1, $18              ;A4,  24 counts.
L8E7A:  .byte $A4, $18              ;C5,  24 counts.
L8E7C:  .byte $A9, $18              ;F5,  24 counts.
L8E7E:  .byte $A9, $18              ;F5,  24 counts.
L8E80:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E82:  .byte $A9, $30              ;F5,  48 counts.
L8E84:  .byte $A9, $30              ;F5,  48 counts.
L8E86:  .byte $AE, $24              ;A#5, 36 counts.
L8E88:  .byte $AD, $0C              ;A5,  12 counts.
L8E8A:  .byte MCTL_CNTRL0,    $40   ;25% duty, len counter yes, env yes, vol=0.
L8E8C:  .byte $0C                   ;12 counts.
L8E8D:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E8F:  .byte $AC, $0C              ;Ab5, 12 counts.
L8E91:  .byte $AC, $0C              ;Ab5, 12 counts.
L8E93:  .byte $AF, $0C              ;B5,  12 counts.
L8E95:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8E97:  .byte $AD, $18              ;A5,  24 counts.
L8E99:  .byte $A9, $30              ;F5,  48 counts.
L8E9B:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8E9D:  .byte $95, $13              ;A3,  19 counts.
L8E9F:  .byte $95, $05              ;A3,   5 counts.
L8EA1:  .byte $99, $18              ;C#4, 24 counts.
L8EA3:  .byte $99, $18              ;C#4, 24 counts.
L8EA5:  .byte $9A, $18              ;D4,  24 counts.
L8EA7:  .byte $9C, $18              ;E4,  24 counts.
L8EA9:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8EAB:  .byte $9D, $30              ;F4,  48 counts.
L8EAD:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8EAF:  .byte $0C                   ;12 counts.
L8EB0:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8EB2:  .byte $9D, $9F, $A1         ;F4, G4, A4.
L8EB5:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8EB7:  .byte $A6                   ;D5.
L8EB8:  .byte $24                   ;36 counts.
L8EB9:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8EBB:  .byte $0C                   ;12 counts.
L8EBC:  .byte $A3, $A3, $A6, $A6    ;B4, B4, D5, D5.
L8EC0:  .byte $0C                   ;12 counts.
L8EC1:  .byte $A4                   ;C5.
L8EC2:  .byte $0C                   ;12 counts.
L8EC3:  .byte $A2                   ;A#4.
L8EC4:  .byte $0C                   ;12 counts.
L8EC5:  .byte $A2                   ;A#4.
L8EC6:  .byte $0C                   ;12 counts.
L8EC7:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8EC9:  .byte $A5                   ;C#5.
L8ECA:  .byte $30                   ;48 counts.
L8ECB:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8ECD:  .byte $A5, $A5, $A5         ;C#5, C#5, C#5.
L8ED0:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8ED2:  .byte $A6                   ;D5.
L8ED3:  .byte $24                   ;36 counts.
L8ED4:  .byte $A1                   ;A4. 
L8ED5:  .byte $0C                   ;12 counts.
L8ED6:  .byte $A1                   ;A4. 
L8ED7:  .byte $0C                   ;12 counts.
L8ED8:  .byte $A6                   ;D5. 
L8ED9:  .byte $30                   ;48 counts.
L8EDA:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8EDC:  .byte $A3, $A3, $A3         ;B4,  B4, B4. 
L8EDF:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8EE1:  .byte $A2                   ;A#4.
L8EE2:  .byte $24                   ;36 counts.
L8EE3:  .byte $A2                   ;A#4.
L8EE4:  .byte $0C                   ;12 counts.
L8EE5:  .byte $A2                   ;A#4.
L8EE6:  .byte $0C                   ;12 counts.
L8EE7:  .byte $AA                   ;F#5.
L8EE8:  .byte $30                   ;48 counts.
L8EE9:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8EEB:  .byte $AA, $AB, $AD         ;F#5, G5,  A5.  
L8EEE:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8EF0:  .byte $AE                   ;A#5.
L8EF1:  .byte $30                   ;48 counts.
L8EF2:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L8EF4:  .byte $A2, $A4, $A6         ;A#4, C5,  D5.  
L8EF7:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8EF8:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8EFA:  .byte $A6, $30              ;D5, 48 counts.
L8EFC:  .byte $A8, $30              ;E5, 48 counts.
L8EFE:  .byte $A1, $3C              ;A4, 60 counts.
L8F00:  .byte MCTL_CNTRL0,    $45   ;25% duty, len counter yes, env yes, vol=5.
L8F02:  .byte $0C                   ;12 counts.
L8F03:  .byte MCTL_JUMP             ;Jump to new music address.
L8F04:  .word SQ2IntroLoop          ;($8E72).

;----------------------------------------------------------------------------------------------------

TriIntro:
L8F06:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L8F08:  .byte $9D, $60              ;F4, 96 counts.
L8F0A:  .byte $60                   ;96 counts.
L8F0B:  .byte $60                   ;96 counts.
L8F0C:  .byte $60                   ;96 counts.
L8F0D:  .byte $60                   ;96 counts.
L8F0E:  .byte $18                   ;24 counts.
L8F0F:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L8F11:  .byte MCTL_ADD_SPACE, $18   ;24 counts between notes.

TRIIntroLoop:
L8F13:  .byte $9D, $9C, $9B, $9A    ;F4,  E4,  D#4, D4.  
L8F17:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8F19:  .byte $95                   ;A3.
L8F1A:  .byte $18                   ;24 counts.
L8F1B:  .byte $96                   ;A#3.
L8F1C:  .byte $18                   ;24 counts.
L8F1D:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L8F1F:  .byte $9D, $98, $91, $9D    ;F4,  C4,  F3,  F4.
L8F23:  .byte $9D, $95, $98, $9D    ;F4,  A3,  C4,  F4.
L8F27:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8F29:  .byte $95                   ;A3.
L8F2A:  .byte $18                   ;24 counts.
L8F2B:  .byte $95                   ;A3.
L8F2C:  .byte $18                   ;24 counts.
L8F2D:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L8F2F:  .byte $9A, $95, $9D, $9A    ;D4,  A3,  F4,  D4.
L8F33:  .byte $97, $9A, $9F, $93    ;B3,  D4,  G4,  G3.
L8F37:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8F39:  .byte $98                   ;C4.
L8F3A:  .byte $18                   ;24 counts.
L8F3B:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L8F3D:  .byte $98, $9C, $95, $99    ;C4,  E4,  A3,  C#4.
L8F41:  .byte $9C, $95, $9A, $9C    ;E4,  A3,  D4,  E4.
L8F45:  .byte $9D, $9A, $97, $9A    ;F4,  D4,  B3,  D4.
L8F49:  .byte $9F, $93, $98, $98    ;G4,  G3,  C4,  C4.
L8F4D:  .byte $9F, $A2, $A1, $9E    ;G4,  A#4, A4,  F#4.
L8F51:  .byte $9A, $95, $93, $95    ;D4,  A3,  G3,  A3.
L8F55:  .byte $96, $93, $9F, $98    ;A#3, G3,  G4,  C4.
L8F59:  .byte $A2, $98, $9D, $98    ;A#4, C4,  F4,  C4.
L8F5D:  .byte $9D                   ;F4.
L8F5E:  .byte $18                   ;24 counts.
L8F5F:  .byte MCTL_JUMP             ;Jump to new music address.
L8F60:  .word TRIIntroLoop          ;($8F13).

;----------------------------------------------------------------------------------------------------

SQ1EndGame:
L8F62:  .byte MCTL_TEMPO,     $82   ;60/1.15=52 counts per second.
L8F64:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8F66:  .byte $30                   ;48 counts.
L8F67:  .byte MCTL_CNTRL0,    $46   ;25% duty, len counter yes, env yes, vol=6.
L8F69:  .byte $AB, $13              ;G5, 19 counts.
L8F6B:  .byte $AB, $05              ;G5,  5 counts.
L8F6D:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L8F6F:  .byte $AB, $AB, $AB, $AB    ;G5,  G5,  G5,  G5.
L8F73:  .byte $AB, $AB, $AB, $AB    ;G5,  G5,  G5,  G5.
L8F77:  .byte $AB, $AB, $A9, $AB    ;G5,  G5,  F5,  G5.
L8F7B:  .byte $AD, $AB, $A9, $A8    ;A5,  G5,  F5,  E5.
L8F7F:  .byte $A9, $AB, $AD, $AB    ;F5,  G5,  A5,  G5.
L8F83:  .byte $A9, $A8              ;F5,  E5.
L8F85:  .byte MCTL_TEMPO,     $7D   ;60/1.2=50 counts per second.
L8F87:  .byte $A9, $A9, $A9         ;F5,  F5,  F5.
L8F8A:  .byte MCTL_TEMPO,     $7A   ;60/1.23=49 counts per second.
L8F8C:  .byte $AC, $AC, $AC         ;Ab5 Ab5 Ab5.
L8F8F:  .byte MCTL_TEMPO,     $76   ;60/1.27=47 counts per second.
L8F91:  .byte $AF, $AF, $AF         ;B5,  B5,  B5.
L8F94:  .byte MCTL_TEMPO,     $71   ;60/1.33=45 counts per second.
L8F96:  .byte $B2, $B2, $B2         ;D6,  D6,  D6.
L8F99:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L8F9B:  .byte $B7                   ;G6.
L8F9C:  .byte $54                   ;84 counts.
L8F9D:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L8F9F:  .byte $10                   ;16 counts.
L8FA0:  .byte MCTL_TEMPO,     $6E   ;60/1.36=44 counts per second.
L8FA2:  .byte MCTL_JUMP             ;Jump to new music address.
L8FA3:  .word SQ1EndGame2           ;($902F).
L8FA5:  .byte MCTL_JUMP             ;Jump to new music address.
L8FA6:  .word SQ1EndGame3           ;($9072).
L8FA8:  .byte MCTL_JUMP             ;Jump to new music address.
L8FA9:  .word SQ1EndGame2           ;($902F).
L8FAB:  .byte MCTL_JUMP             ;Jump to new music address.
L8FAC:  .word SQ1EndGame3           ;($9072).
L8FAE:  .byte MCTL_JUMP             ;Jump to new music address.
L8FAF:  .word SQ1EndGame2           ;($902F).
L8FB1:  .byte $A8, $A9, $AB         ;E5,  F5,  G5.
L8FB4:  .byte $24                   ;36 counts.
L8FB5:  .byte $A8, $A5, $A6, $A8    ;E5,  C#5, D5,  E5.
L8FB9:  .byte $A9                   ;F5.
L8FBA:  .byte $0C                   ;12 counts.
L8FBB:  .byte $AB                   ;G5.
L8FBC:  .byte $0C                   ;12 counts.
L8FBD:  .byte $AD                   ;A5.
L8FBE:  .byte $0C                   ;12 counts.
L8FBF:  .byte $AB, $A9              ;G5,  F5.
L8FC1:  .byte MCTL_CNTRL0,    $49   ;25% duty, len counter yes, env yes, vol=9.
L8FC3:  .byte $A8, $9C              ;E5,  E4.
L8FC5:  .byte MCTL_TEMPO,     $71   ;60/1.33=45 counts per second.
L8FC7:  .byte $9C, $A1              ;E4,  A4.
L8FC9:  .byte MCTL_TEMPO,     $74   ;60/1.29=47 counts per second.
L8FCB:  .byte $A1, $A4              ;A4,  C5.
L8FCD:  .byte MCTL_TEMPO,     $77   ;60/1.26=48 counts per second.
L8FCF:  .byte $A8, $AD              ;E5,  A5.
L8FD1:  .byte MCTL_TEMPO,     $79   ;60/1.24=48 counts per second.
L8FD3:  .byte $A6, $9D              ;D5,  F4.
L8FD5:  .byte MCTL_TEMPO,     $7C   ;60/1.21=50 counts per second.
L8FD7:  .byte $9D, $9F              ;F4,  G4.
L8FD9:  .byte MCTL_TEMPO,     $7F   ;60/1.18=51 counts per second.
L8FDB:  .byte $9F, $A3              ;G4,  B4.
L8FDD:  .byte MCTL_TEMPO,     $82   ;60/1.15=52 counts per second.
L8FDF:  .byte $A6, $AB              ;D5,  G5.
L8FE1:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L8FE2:  .byte MCTL_TEMPO,     $78   ;60/1.25=48 counts per second.
L8FE4:  .byte $B0, $18              ;C6, 24 counts.
L8FE6:  .byte $A4, $08              ;C5,  8 counts.
L8FE8:  .byte $A4, $08              ;C5,  8 counts.
L8FEA:  .byte $A4, $08              ;C5,  8 counts.
L8FEC:  .byte $A4, $18              ;C5, 24 counts.
L8FEE:  .byte $A6, $18              ;D5, 24 counts.
L8FF0:  .byte MCTL_TEMPO,     $64   ;60/1.5=40 counts per second.
L8FF2:  .byte MCTL_CNTRL0,    $7E   ;25% duty, len counter no, env no, vol=14.
L8FF4:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L8FF6:  .byte MCTL_JUMP             ;Jump to new music address.
L8FF7:  .word SQ1EndGame4           ;($901D).
L8FF9:  .byte MCTL_JUMP             ;Jump to new music address.
L8FFA:  .word SQ1EndGame4           ;($901D).
L8FFC:  .byte MCTL_JUMP             ;Jump to new music address.
L8FFD:  .word SQ1EndGame4           ;($901D).
L8FFF:  .byte MCTL_JUMP             ;Jump to new music address.
L9000:  .word SQ1EndGame4           ;($901D).
L9002:  .byte MCTL_TEMPO,     $69   ;60/1.43=42 counts per second.
L9004:  .byte MCTL_JUMP             ;Jump to new music address.
L9005:  .word SQ1EndGame5           ;($9026).
L9007:  .byte MCTL_JUMP             ;Jump to new music address.
L9008:  .word SQ1EndGame5           ;($9026).
L900A:  .byte MCTL_JUMP             ;Jump to new music address.
L900B:  .word SQ1EndGame5           ;($9026).
L900D:  .byte MCTL_JUMP             ;Jump to new music address.
L900E:  .word SQ1EndGame5           ;($9026).
L9010:  .byte MCTL_TEMPO,     $66   ;60/1.47=41 counts per second.
L9012:  .byte MCTL_CNTRL0,    $49   ;25% duty, len counter yes, env yes, vol=9.
L9014:  .byte MCTL_ADD_SPACE, $08   ;8 counts between notes.
L9016:  .byte $A8                   ;E5.
L9017:  .byte $10                   ;16 counts.
L9018:  .byte $98, $98, $98, $98    ;C4,  C4,  C4,  C4.
L901C:  .byte $00                   ;End music.

SQ1EndGame4:
L901D:  .byte $A4, $A0, $A4, $A0    ;C5,  Ab4, C5,  Ab4.
L9021:  .byte $A4, $A0, $A4, $A0    ;C5,  Ab4, C5,  Ab4.
L9025:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1EndGame5:
L9026:  .byte $A8, $A4, $A8, $A4    ;E5,  C5,  E5,  C5.
L902A:  .byte $A8, $A4, $A8, $A4    ;E5,  C5,  E5,  C5.
L902E:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1EndGame2:
L902F:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L9030:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L9032:  .byte $9F, $18              ;G4,  24 counts.
L9034:  .byte $A8, $14              ;E5,  20 counts.
L9036:  .byte $A8, $02              ;E5,   2 counts.
L9038:  .byte $A7, $02              ;D#5,  2 counts.
L903A:  .byte $A8, $0C              ;E5,  12 counts.
L903C:  .byte $AB, $0C              ;G5,  12 counts.
L903E:  .byte $A6, $14              ;D5,  20 counts.
L9040:  .byte $A6, $02              ;D5,   2 counts.
L9042:  .byte $A5, $02              ;C#5,  2 counts.
L9044:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L9046:  .byte $A6, $AB, $A4         ;D5,  G5,  C5.
L9049:  .byte $30                   ;48 counts.
L904A:  .byte $A4, $A6, $A8, $A9    ;C5,  D5,  E5,  F5.
L904E:  .byte $0C                   ;12 counts.
L904F:  .byte $AB, $A9, $A8         ;G5,  F5,  E5.
L9052:  .byte $0C                   ;12 counts.
L9053:  .byte $A9, $A8, $A6         ;F5,  E5,  D5.
L9056:  .byte $30                   ;48 counts.
L9057:  .byte $A6, $A8, $A9, $AB    ;D5,  E5,  F5,  G5.
L905B:  .byte $24                   ;36 counts.
L905C:  .byte $A8, $A5, $A6, $A8    ;E5,  C#5, D5,  E5.
L9060:  .byte $A9                   ;F5.
L9061:  .byte $0C                   ;12 counts.
L9062:  .byte $AB                   ;G5.
L9063:  .byte $0C                   ;12 counts.
L9064:  .byte $AD                   ;A5.
L9065:  .byte $0C                   ;12 counts.
L9066:  .byte $AB, $A9, $A8         ;G5,  F5,  E5.
L9069:  .byte $18                   ;24 counts.
L906A:  .byte $A8, $A4              ;E5,  C5.
L906C:  .byte $0C                   ;12 counts.
L906D:  .byte $A1                   ;A4.
L906E:  .byte $0C                   ;12 counts.
L906F:  .byte $A6                   ;D5.
L9070:  .byte $3C                   ;60 counts.
L9071:  .byte MCTL_RETURN           ;Return to previous music block.

SQ1EndGame3:
L9072:  .byte MCTL_CNTRL0,    $BF   ;50% duty, len counter no, env no, vol=15.
L9074:  .byte $AB                   ;G5.
L9075:  .byte $0C                   ;12 counts.
L9076:  .byte $AC                   ;Ab5.
L9077:  .byte $30                   ;48 counts.
L9078:  .byte $A6, $A7, $A9, $AE    ;D5,  D#5, F5,  A#5.
L907C:  .byte $24                   ;36 counts.
L907D:  .byte $AB                   ;G5.
L907E:  .byte $0C                   ;12 counts.
L907F:  .byte $A7                   ;D#5.
L9080:  .byte $0C                   ;12 counts.
L9081:  .byte $A9                   ;F5.
L9082:  .byte $30                   ;48 counts.
L9083:  .byte $AC, $AB, $A9         ;Ab5, G5,  F5.
L9086:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L9088:  .byte $A7                   ;D#5.
L9089:  .byte $0C                   ;12 counts.
L908A:  .byte $A9                   ;F5.
L908B:  .byte $0C                   ;12 counts.
L908C:  .byte $AB                   ;G5.
L908D:  .byte $0C                   ;12 counts.
L908E:  .byte MCTL_CNTRL0,    $BF   ;50% duty, len counter no, env no, vol=15.
L9090:  .byte $AC, $AE, $B0         ;Ab5, A#5, C6.
L9093:  .byte $30                   ;48 counts.
L9094:  .byte $B3, $B2, $B0         ;D#6, D6,  C6.
L9097:  .byte MCTL_CNTRL0,    $8E   ;50% duty, len counter yes, env yes, vol=14.
L9099:  .byte MCTL_ADD_SPACE, $10   ;16 counts between notes.
L909B:  .byte $AE, $AC, $AB, $AB    ;A#5, Ab5, G5,  G5.
L909F:  .byte $A9, $A7              ;F5,  D#5.
L90A1:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L90A3:  .byte MCTL_CNTRL0,    $BF   ;50% duty, len counter no, env no, vol=15.
L90A5:  .byte $A9                   ;F5.
L90A6:  .byte $30                   ;48 counts.
L90A7:  .byte $A4, $A6, $A7, $A7    ;C5,  D5,  D#5, D#5.
L90AB:  .byte $54                   ;84 counts.
L90AC:  .byte $A6                   ;D5.
L90AD:  .byte $30                   ;48 counts.
L90AE:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L90B0:  .byte $0C                   ;12 counts.
L90B1:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

SQ2EndGame:
L90B2:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L90B4:  .byte $30                   ;48 counts.
L90B5:  .byte MCTL_CNTRL0,    $46   ;25% duty, len counter yes, env yes, vol=6.
L90B7:  .byte $A3, $13              ;B4, 19 counts.
L90B9:  .byte $A3, $05              ;B4,  5 counts.
L90BB:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L90BD:  .byte $A3, $A9, $A9, $A9    ;B4,  F5,  F5,  F5.
L90C1:  .byte $A8, $A8, $A8, $A6    ;E5,  E5,  E5,  D5.
L90C5:  .byte $A4, $A3, $A1, $A3    ;C5,  B4,  A4,  B4.
L90C9:  .byte $A4, $A3, $A1, $9F    ;C5,  B4,  A4,  G4.
L90CD:  .byte $A1, $A3, $A4, $A3    ;A4,  B4,  C5,  B4.
L90D1:  .byte $A1, $9F, $A4, $A4    ;A4,  G4,  C5,  C5.
L90D5:  .byte $A4, $A7, $A7, $A7    ;C5,  D#5, D#5, D#5.
L90D9:  .byte $AA, $AA, $AA, $AD    ;F#5, F#5, F#5, A5.
L90DD:  .byte $AD, $AD              ;A5,  A5.
L90DF:  .byte MCTL_CNTRL0,    $7F   ;25% duty, len counter no, env no, vol=15.
L90E1:  .byte $B0                   ;C6.
L90E2:  .byte $3C                   ;60 counts.
L90E3:  .byte $AF                   ;B5.
L90E4:  .byte $0C                   ;12 counts.
L90E5:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L90E7:  .byte $28                   ;40 counts.
L90E8:  .byte MCTL_JUMP             ;Jump to new music address.
L90E9:  .word SQ2EndGame2           ;($9159).
L90EB:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L90ED:  .byte MCTL_JUMP             ;Jump to new music address.
L90EE:  .word SQ2EndGame3           ;($91A0).
L90F0:  .byte MCTL_JUMP             ;Jump to new music address.
L90F1:  .word SQ2EndGame2           ;($9159).
L90F3:  .byte MCTL_CNTRL0,    $4F   ;25% duty, len counter yes, env yes, vol=15.
L90F5:  .byte MCTL_JUMP             ;Jump to new music address.
L90F6:  .word SQ2EndGame3           ;($91A0).
L90F8:  .byte MCTL_JUMP             ;Jump to new music address.
L90F9:  .word SQ2EndGame2           ;($9159).
L90FB:  .byte $A4                   ;C5.
L90FC:  .byte $24                   ;36 counts.
L90FD:  .byte $9F                   ;G4.
L90FE:  .byte $24                   ;36 counts.
L90FF:  .byte $A1                   ;A4.
L9100:  .byte $54                   ;84 counts.
L9101:  .byte MCTL_CNTRL0,    $49   ;25% duty, len counter yes, env yes, vol=9.
L9103:  .byte $A1, $95, $95, $9C    ;A4,  A3,  A3,  E4.
L9107:  .byte $9C, $A1, $A1, $A8    ;E4,  A4,  A4,  E5.
L910B:  .byte $9D, $97, $97, $9A    ;F4,  B3,  B3,  D4.
L910F:  .byte $9A, $9D, $A3, $A6    ;D4,  F4,  B4,  D5.
L9113:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L9114:  .byte $A8, $18              ;E5,  24 counts.
L9116:  .byte $9B, $08              ;D#4,  8 counts.
L9118:  .byte $9B, $08              ;D#4,  8 counts.
L911A:  .byte $9B, $08              ;D#4,  8 counts.
L911C:  .byte $9B, $18              ;D#4, 24 counts.
L911E:  .byte $9D, $18              ;F4,  24 counts.
L9120:  .byte MCTL_CNTRL0,    $7E   ;25% duty, len counter no, env no, vol=14.
L9122:  .byte MCTL_ADD_SPACE, $03   ;3 counts between notes.
L9124:  .byte MCTL_JUMP             ;Jump to new music address.
L9125:  .word SQ2EndGame4           ;($9147).
L9127:  .byte MCTL_JUMP             ;Jump to new music address.
L9128:  .word SQ2EndGame4           ;($9147).
L912A:  .byte MCTL_JUMP             ;Jump to new music address.
L912B:  .word SQ2EndGame4           ;($9147).
L912D:  .byte MCTL_JUMP             ;Jump to new music address.
L912E:  .word SQ2EndGame4           ;($9147).
L9130:  .byte MCTL_JUMP             ;Jump to new music address.
L9131:  .word SQ2EndGame5           ;($9150).
L9133:  .byte MCTL_JUMP             ;Jump to new music address.
L9134:  .word SQ2EndGame5           ;($9150).
L9136:  .byte MCTL_JUMP             ;Jump to new music address.
L9137:  .word SQ2EndGame5           ;($9150).
L9139:  .byte MCTL_JUMP             ;Jump to new music address.
L913A:  .word SQ2EndGame5           ;($9150).
L913C:  .byte MCTL_CNTRL0,    $49   ;25% duty, len counter yes, env yes, vol=9.
L913E:  .byte MCTL_ADD_SPACE, $08   ;8 counts between notes.
L9140:  .byte $9F                   ;G4.
L9141:  .byte $10                   ;16 counts.
L9142:  .byte $8C, $8C, $8C, $8C    ;C3,  C3,  C3,  C3.
L9146:  .byte $00                   ;End music.

SQ2EndGame4:
L9147:  .byte $9B, $98, $9B, $98    ;D#4, C4,  D#4, C4.
L914B:  .byte $9B, $98, $9B, $98    ;D#4, C4,  D#4, C4.
L914F:  .byte MCTL_RETURN           ;Return to previous music block.

SQ2EndGame5:
L9150:  .byte $9F, $9C, $9F, $9C    ;G4,  E4,  G4,  E4.
L9154:  .byte $9F, $9C, $9F, $9C    ;G4,  E4,  G4,  E4.
L9158:  .byte MCTL_RETURN           ;Return to previous music block.

SQ2EndGame2:
L9159:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L915A:  .byte MCTL_CNTRL0,    $8F   ;50% duty, len counter yes, env yes, vol=15.
L915C:  .byte $9F, $14              ;G4,  20 counts.
L915E:  .byte $9F, $02              ;G4,   2 counts.
L9160:  .byte $9E, $02              ;F#4,  2 counts.
L9162:  .byte $9F, $06              ;G4,   6 counts.
L9164:  .byte $9F, $06              ;G4,   6 counts.
L9166:  .byte $9C, $06              ;E4,   6 counts.
L9168:  .byte $9F, $06              ;G4,   6 counts.
L916A:  .byte $9F, $1E              ;G4,  30 counts.
L916C:  .byte $9F, $06              ;G4,   6 counts.
L916E:  .byte $9D, $06              ;F4,   6 counts.
L9170:  .byte $9F, $06              ;G4,   6 counts.
L9172:  .byte $9C, $14              ;E4,  20 counts.
L9174:  .byte $9C, $02              ;E4,   2 counts.
L9176:  .byte $9B, $02              ;D#4,  2 counts.
L9178:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L917A:  .byte $9C, $9F, $9D         ;E4,  G4,  F4.
L917D:  .byte $24                   ;36 counts.
L917E:  .byte $A4                   ;C5.
L917F:  .byte $24                   ;36 counts.
L9180:  .byte $A4                   ;C5.
L9181:  .byte $0C                   ;12 counts.
L9182:  .byte $A5                   ;C#5.
L9183:  .byte $18                   ;24 counts.
L9184:  .byte $A4, $A3, $A1, $A3    ;C5,  B4,  A4,  B4.
L9188:  .byte $24                   ;36 counts.
L9189:  .byte $A4                   ;C5.
L918A:  .byte $24                   ;36 counts.
L918B:  .byte $9F                   ;G4.
L918C:  .byte $24                   ;36 counts.
L918D:  .byte $A1                   ;A4.
L918E:  .byte $54                   ;84 counts.
L918F:  .byte $A1, $9C, $98, $9C    ;A4,  E4,  C4,  E4.
L9193:  .byte $A1, $9C, $98, $9C    ;A4,  E4,  C4,  E4.
L9197:  .byte $0C                   ;12 counts.
L9198:  .byte $A4, $A1, $A4, $A3    ;C5,  A4,  C5,  B4.
L919C:  .byte MCTL_CNTRL0,    $89   ;50% duty, len counter yes, env yes, vol=9.
L919E:  .byte $24                   ;36 counts.
L919F:  .byte MCTL_RETURN           ;Return to previous music block.

SQ2EndGame3:
L91A0:  .byte MCTL_ADD_SPACE, $06   ;6 counts between notes.
L91A2:  .byte $9B, $98, $9B, $98    ;D#4, C4,  D#4, C4.
L91A6:  .byte $9B, $98, $9B, $98    ;D#4, C4,  D#4, C4.
L91AA:  .byte $A0, $9D, $A0, $9D    ;Ab4, F4,  Ab4, F4.
L91AE:  .byte $A0, $9D, $9A, $9D    ;Ab4, F4,  D4,  F4.
L91B2:  .byte $9F, $9A, $9F, $9A    ;G4,  D4,  G4,  D4.
L91B6:  .byte $9F, $9A, $9F, $9A    ;G4,  D4,  G4,  D4.
L91BA:  .byte $9B, $98, $9B, $98    ;D#4, C4,  D#4, C4.
L91BE:  .byte $9B, $98, $9B, $98    ;D#4, C4,  D#4, C4.
L91C2:  .byte $A4, $A1, $A4, $A1    ;C5,  A4,  C5,  A4.
L91C6:  .byte $A4, $A1, $A4, $A1    ;C5,  A4,  C5,  A4.
L91CA:  .byte $A6, $A3, $A6, $A3    ;D5,  B4,  D5,  B4.
L91CE:  .byte $A6, $A3, $A6, $A3    ;D5,  B4,  D5,  B4.
L91D2:  .byte $A2, $9F, $A2, $9F    ;A#4, G4,  A#4, G4.
L91D6:  .byte $A2, $9D, $A2, $9D    ;A#4, F4,  A#4, F4.
L91DA:  .byte $A2, $9F, $A2, $9F    ;A#4, G4,  A#4, G4.
L91DE:  .byte $A4, $A2, $A4, $A2    ;C5,  A#4, C5,  A#4.
L91E2:  .byte $9B, $A0, $A4, $A0    ;D#4, Ab4, C5,  Ab4.
L91E6:  .byte $9B, $A0, $A4, $A0    ;D#4, Ab4, C5,  Ab4.
L91EA:  .byte $9B, $A0, $A4, $A0    ;D#4, Ab4, C5,  Ab4.
L91EE:  .byte $9D, $A2, $9B, $A0    ;F4,  A#4, D#4, Ab4.
L91F2:  .byte $9F, $9A, $96, $9A    ;G4,  D4,  A#3, D4.
L91F6:  .byte $9F, $9A, $96, $9A    ;G4,  D4,  A#3, D4.
L91FA:  .byte $9F, $9B, $98, $9B    ;G4,  D#4, C4,  D#4.
L91FE:  .byte $9F, $9B, $98, $9B    ;G4,  D#4, C4,  D#4.
L9202:  .byte $98, $95, $98, $9D    ;C4,  A3,  C4,  F4.
L9206:  .byte $98, $95, $98, $9D    ;C4,  A3,  C4,  F4.
L920A:  .byte $98, $95, $98, $9D    ;C4,  A3,  C4,  F4.
L920E:  .byte $98, $95, $98, $9B    ;C4,  A3,  C4,  D#4.
L9212:  .byte $A3, $9F, $9D, $9F    ;B4,  G4,  F4,  G4.
L9216:  .byte $A3, $9F, $9D, $9F    ;B4,  G4,  F4,  G4.
L921A:  .byte $A3, $9F, $9D, $9F    ;B4,  G4,  F4,  G4.
L921E:  .byte $A3, $9F, $9D, $9F    ;B4,  G4,  F4,  G4.
L9222:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L9224:  .byte $A4                   ;C5.
L9225:  .byte $0C                   ;12 counts.
L9226:  .byte $A3, $A1, $A3         ;B4,  A4,  B4.
L9229:  .byte $0C                   ;12 counts.
L922A:  .byte MCTL_CNTRL0,    $89   ;50% duty, len counter yes, env yes, vol=9.
L922C:  .byte $18                   ;24 counts.
L922D:  .byte MCTL_RETURN           ;Return to previous music block.

;----------------------------------------------------------------------------------------------------

TRIEndGame:
L922E:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L9230:  .byte $30                   ;48 counts.
L9231:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L9233:  .byte $93, $6C              ;G3, 108 counts.
L9235:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L9237:  .byte $93, $9A, $9F, $A4    ;G3,  D4,  G4,  C5.
L923B:  .byte $A6, $A9, $A6, $A4    ;D5,  F5,  D5,  C5.
L923F:  .byte $A3, $A4, $A6, $A9    ;B4,  C5,  D5,  F5.
L9243:  .byte $A6, $A4, $A3, $A1    ;D5,  C5,  B4,  A4.
L9247:  .byte $A1, $A1, $A4, $A4    ;A4,  A4,  C5,  C5.
L924B:  .byte $A4, $A7, $A7, $A7    ;C5,  D#5, D#5, D#5.
L924F:  .byte $AA, $AA, $AA, $93    ;F#5, F#5, F#5, G3.
L9253:  .byte $98, $9A, $9F, $A4    ;C4,  D4,  G4,  C5.
L9257:  .byte $A6                   ;D5.
L9258:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L925A:  .byte $AB                   ;G5.
L925B:  .byte $34                   ;52 counts.
L925C:  .byte MCTL_NO_OP            ;Skip byte.
L925D:  .byte MCTL_JUMP             ;Jump to new music address.
L925E:  .word TRIEndGame2           ;($92BF).
L9260:  .byte MCTL_JUMP             ;Jump to new music address.
L9261:  .word TRIEndGame3           ;($92F2).
L9263:  .byte MCTL_JUMP             ;Jump to new music address.
L9264:  .word TRIEndGame2           ;($92BF).
L9266:  .byte MCTL_JUMP             ;Jump to new music address.
L9267:  .word TRIEndGame3           ;($92F2).
L9269:  .byte MCTL_JUMP             ;Jump to new music address.
L926A:  .word TRIEndGame2           ;($92BF).
L926C:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L926E:  .byte $A8, $9C, $A1         ;E5,  E4,  A4.
L9271:  .byte MCTL_NO_OP            ;Skip byte.
L9272:  .byte $95, $9A, $9C, $9D    ;A3,  D4,  E4,  F4.
L9276:  .byte MCTL_NO_OP            ;Skip byte.
L9277:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L9279:  .byte $18                   ;24 counts.
L927A:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L927C:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L927E:  .byte $92, $9E, $9E, $A4    ;F#3, F#4, F#4, C5.
L9282:  .byte $A4                   ;C5.
L9283:  .byte MCTL_NO_OP            ;Skip byte.
L9284:  .byte $A8, $9E, $B0, $93    ;E5,  F#4, C6,  G3.
L9288:  .byte $9F, $9F, $A3, $A3    ;G4,  G4,  B4,  B4.
L928C:  .byte MCTL_NO_OP            ;Skip byte.
L928D:  .byte $A6, $A9, $AF         ;D5,  F5,  B5.
L9290:  .byte MCTL_END_SPACE        ;Disable counts between notes.
L9291:  .byte $98, $18              ;C4,  24 counts.
L9293:  .byte $A0, $08              ;Ab4,  8 counts.
L9295:  .byte $A0, $08              ;Ab4,  8 counts.
L9297:  .byte $A0, $08              ;Ab4,  8 counts.
L9299:  .byte $A0, $18              ;Ab4, 24 counts.
L929B:  .byte MCTL_NO_OP            ;Skip byte.
L929C:  .byte $A2, $18              ;A#4, 24 counts.
L929E:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L92A0:  .byte $A0, $94, $A0, $94    ;Ab4, Ab3, Ab4, Ab3.
L92A4:  .byte MCTL_NOTE_OFST, $02   ;Note offset of 2 notes.
L92A6:  .byte $A0                   ;Ab4.
L92A7:  .byte MCTL_NO_OP            ;Skip byte.
L92A8:  .byte $94, $A0, $94         ;Ab3, Ab4, Ab3.
L92AB:  .byte MCTL_NOTE_OFST, $00   ;Note offset of 0 notes.
L92AD:  .byte $98, $93, $98, $93    ;C4,  G3,  C4,  G3.
L92B1:  .byte $98, $93, $98         ;C4,  G3,  C4.
L92B4:  .byte MCTL_NO_OP            ;Skip byte.
L92B5:  .byte $93                   ;G3.
L92B6:  .byte MCTL_ADD_SPACE, $08   ;8 counts between notes.
L92B8:  .byte $98                   ;C4.
L92B9:  .byte $10                   ;16 counts.
L92BA:  .byte $98, $98, $98, $98    ;C4,  C4,  C4,  C4.
L92BE:  .byte $00                   ;End music.

TRIEndGame2:
L92BF:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L92C1:  .byte MCTL_ADD_SPACE, $18   ;24 counts between notes.
L92C3:  .byte $98, $A4, $A3         ;C4,  C5,  B4.
L92C6:  .byte MCTL_NO_OP            ;Skip byte.
L92C7:  .byte $97, $96, $A2, $A1    ;B3,  A#3, A#4, A4.
L92CB:  .byte MCTL_NO_OP            ;Skip byte.
L92CC:  .byte $95, $94, $A0, $9F    ;A3,  Ab3, Ab4, G4.
L92D0:  .byte MCTL_NO_OP            ;Skip byte.
L92D1:  .byte $93, $92, $9E, $9D    ;G3,  F#3, F#4, F4.
L92D5:  .byte MCTL_NO_OP            ;Skip byte.
L92D6:  .byte $A9, $A8, $9C, $A1    ;F5,  E5,  E4,  A4.
L92DA:  .byte MCTL_NO_OP            ;Skip byte.
L92DB:  .byte $95, $9A, $9C, $9D    ;A3,  D4,  E4,  F4.
L92DF:  .byte MCTL_NO_OP            ;Skip byte.
L92E0:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L92E2:  .byte $18                   ;24 counts.
L92E3:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L92E5:  .byte $9E, $92, $9E         ;F#4 F#3 F#4.
L92E8:  .byte MCTL_NO_OP            ;Skip byte.
L92E9:  .byte $18                   ;24 counts.
L92EA:  .byte $9F, $9A, $93         ;G4,  D4,  G3.
L92ED:  .byte MCTL_NO_OP            ;Skip byte.
L92EE:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L92F0:  .byte $18                   ;24 counts.
L92F1:  .byte MCTL_RETURN           ;Return to previous music block.

TRIEndGame3:
L92F2:  .byte MCTL_ADD_SPACE, $0C   ;12 counts between notes.
L92F4:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L92F6:  .byte $9D                   ;F4.
L92F7:  .byte $18                   ;24 counts.
L92F8:  .byte $9D                   ;F4.
L92F9:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L92FB:  .byte $96                   ;A#3.
L92FC:  .byte MCTL_NO_OP            ;Skip byte.
L92FD:  .byte $96                   ;A#3.
L92FE:  .byte $0C                   ;12 counts.
L92FF:  .byte $96                   ;A#3.
L9300:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L9302:  .byte $9B                   ;D#4.
L9303:  .byte $18                   ;24 counts.
L9304:  .byte $9B                   ;D#4.
L9305:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L9307:  .byte $A0                   ;Ab4.
L9308:  .byte MCTL_NO_OP            ;Skip byte.
L9309:  .byte $A0                   ;Ab4.
L930A:  .byte $0C                   ;12 counts.
L930B:  .byte $94                   ;Ab3.
L930C:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L930E:  .byte $9A                   ;D4.
L930F:  .byte $18                   ;24 counts.
L9310:  .byte $9A                   ;D4.
L9311:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L9313:  .byte $9F                   ;G4.
L9314:  .byte MCTL_NO_OP            ;Skip byte.
L9315:  .byte $9F                   ;G4.
L9316:  .byte $0C                   ;12 counts.
L9317:  .byte $93, $98, $A4, $9A    ;G3,  C4,  C5,  D4.
L931B:  .byte $A6, $9B              ;D5,  D#4.
L931D:  .byte MCTL_NO_OP            ;Skip byte.
L931E:  .byte $A7, $9C, $A8         ;D#5, E4,  E5.
L9321:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L9323:  .byte $9D                   ;F4.
L9324:  .byte $18                   ;24 counts.
L9325:  .byte $9D                   ;F4.
L9326:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L9328:  .byte $A2                   ;A#4.
L9329:  .byte MCTL_NO_OP            ;Skip byte.
L932A:  .byte $A2                   ;A#4.
L932B:  .byte $0C                   ;12 counts.
L932C:  .byte $96                   ;A#3.
L932D:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L932F:  .byte $9B                   ;D#4.
L9330:  .byte $18                   ;24 counts.
L9331:  .byte $9B                   ;D#4.
L9332:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L9334:  .byte $A0                   ;Ab4.
L9335:  .byte MCTL_NO_OP            ;Skip byte.
L9336:  .byte $A0                   ;Ab4.
L9337:  .byte $0C                   ;12 counts.
L9338:  .byte $94                   ;Ab3.
L9339:  .byte MCTL_CNTRL0,    $60   ;25% duty, len counter no, env yes, vol=0.
L933B:  .byte $9A                   ;D4.
L933C:  .byte $18                   ;24 counts.
L933D:  .byte MCTL_CNTRL0,    $30   ;12.5% duty, len counter no, env no, vol=0.
L933F:  .byte $9A                   ;D4.
L9340:  .byte MCTL_ADD_SPACE, $18   ;24 counts between notes.
L9342:  .byte MCTL_CNTRL0,    $FF   ;75% duty, len counter no, env no, vol=15.
L9344:  .byte $9A                   ;D4.
L9345:  .byte MCTL_NO_OP            ;Skip byte.
L9346:  .byte $9E, $9F              ;F#4, G4.
L9348:  .byte $18                   ;24 counts.
L9349:  .byte $9A                   ;D4.
L934A:  .byte MCTL_NO_OP            ;Skip byte.
L934B:  .byte $9F, $9F, $9A, $93    ;G4,  G4,  D4,  G3.
L934F:  .byte MCTL_NO_OP            ;Skip byte.
L9350:  .byte MCTL_CNTRL0,    $00   ;12.5% duty, len counter yes, env yes, vol=0.
L9352:  .byte $18                   ;24 counts.
L9353:  .byte MCTL_RETURN           ;Return to previous music block.

;-------------------------------------------[End Credits]--------------------------------------------

EndGameClearPPU:
L9354:  LDA #%00000000          ;Turn off sprites and background.
L9356:  STA PPUControl1         ;

L9359:  JSR ClearPPU            ;($C17A)Clear the PPU.

L935C:  LDA #%00011000          ;
L935E:  STA PPUControl1         ;Turn on sprites and background.
L9361:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ExitGame:
L9362:  LDA #MSC_NOSOUND        ;Silence music.
L9364:  BRK                     ;
L9365:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

L9367:  BRK                     ;Load palettes for end credits.
L9368:  .byte $06, $07          ;($AA62)LoadCreditsPals, bank 0.

L936A:  LDA #$00                ;
L936C:  STA ExpLB               ;
L936E:  STA ScrollX             ;Clear various RAM values.
L9370:  STA ScrollY             ;
L9372:  STA ActiveNmTbl         ;
L9374:  STA NPCUpdateCntr       ;

L9376:  LDX #$3B                ;Prepare to clear NPC position RAM.

L9378:* STA NPCXPos,X           ;
L937A:  DEX                     ;Clear NPC map position RAM (60 bytes).
L937B:  BPL -                   ;

L937D:  LDA #EN_DRAGONLORD2     ;Set enemy number.
L937F:  STA EnNumber            ;

L9381:  JSR ClearSpriteRAM      ;($C6BB)Clear sprite RAM.
L9384:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
L9387:  JSR EndGameClearPPU     ;($9354)Clear the display contents of the PPU.

L938A:  LDA #$FF                ;Set hit points.
L938C:  STA HitPoints           ;

L938E:  BRK                     ;Load BG and sprite palettes for selecting saved game.
L938F:  .byte $01, $07          ;($AA7E)LoadStartPals, bank 0.

L9391:  JSR Dowindow            ;($C6F0)display on-screen window.
L9394:  .byte WND_DIALOG        ;Dialog window.

L9395:  JSR DoDialogHiBlock     ;($C7C5)Please press reset, hold it in...
L9398:  .byte $28               ;TextBlock19, entry 8.
L9399:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoEndCredits:
L939A:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

L939D:  LDA #MSC_END            ;End music.
L939F:  BRK                     ;
L93A0:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

L93A2:  BRK                     ;Wait for the music clip to end.
L93A3:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

L93A5:  BRK                     ;Load palettes for end credits.
L93A6:  .byte $06, $07          ;($AA62)LoadCreditsPals, bank 0.

L93A8:  JSR ClearSpriteRAM      ;($C6BB)Clear sprites.

L93AB:  LDA #%00000000          ;Turn off sprites and background.
L93AD:  STA PPUControl1         ;

L93B0:  JSR Bank0ToCHR0         ;($FCA3)Load data into CHR0.

L93B3:  LDA #$00                ;
L93B5:  STA ExpLB               ;
L93B7:  STA ScrollX             ;
L93B9:  STA ScrollY             ;Clear various RAM values.
L93BB:  STA ActiveNmTbl         ;
L93BD:  LDA #EN_DRAGONLORD2     ;
L93BF:  STA EnNumber            ;

L93C1:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
L93C4:  JSR EndGameClearPPU     ;($9354)Clear the display contents of the PPU.

L93C7:  LDA #$23                ;
L93C9:  STA PPUAddrUB           ;
L93CB:  LDA #$C8                ;Set attribute table bytes for nametable 0.
L93CD:  STA PPUAddrLB           ;
L93CF:  LDA #$55                ;
L93D1:  STA PPUDataByte         ;

L93D3:  LDY #$08                ;Load 8 bytes of attribute table data.
L93D5:* JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
L93D8:  DEY                     ;Done loading attribute table bytes? 
L93D9:  BNE -                   ;If not, branch to load more.

L93DB:  LDA #$AA                ;Load different attribute table data.
L93DD:  STA PPUDataByte         ;

L93DF:  LDY #$20                ;Fill the remainder of the attribute table with the data.
L93E1:* JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
L93E4:  DEY                     ;Done loading attribute table bytes? 
L93E5:  BNE -                   ;If not, branch to load more.

L93E7:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

L93EA:  LDA EndCreditDatPtr     ;
L93ED:  STA DatPntr1LB          ;Get pointer to end credits data.
L93EF:  LDA EndCreditDatPtr+1   ;
L93F2:  STA DatPntrlUB          ;

L93F4:  JMP RollCredits         ;($93FA)Display credits on the screen.

DoClearPPU:
L93F7:  JSR EndGameClearPPU     ;($9354)Clear the display contents of the PPU.

RollCredits:
L93FA:  LDY #$00                ;
L93FC:  LDA (DatPntr1),Y        ;First 2 bytes of data block are the PPU address.
L93FE:  STA PPUAddrLB           ;Load those bytes into the PPU data buffer as the
L9400:  INY                     ;target address for the data write.
L9401:  LDA (DatPntr1),Y        ;
L9403:  STA PPUAddrUB           ;

L9405:  LDY #$02                ;Move to data after PPU address.

GetNextEndByte:
L9407:  LDA (DatPntr1),Y        ;
L9409:  STA PPUDataByte         ;Is the byte a repeat control byte?
L940B:  CMP #END_RPT            ;
L940D:  BNE DoNonRepeatedValue  ;If not, branch to check for other byte types.

DoRepeatedValue:
L940F:  INY                     ;
L9410:  LDA (DatPntr1),Y        ;Get next byte. It is the number of times to repeat.
L9412:  STA GenByte3C           ;
L9414:  INY                     ;
L9415:  LDA (DatPntr1),Y        ;Get next byte. It is the byte to repeatedly load.
L9417:  STA PPUDataByte         ;Store byte in PPU buffer.

L9419:* JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.
L941C:  DEC GenByte3C           ;More data to load?
L941E:  BNE -                   ;If so, branch to load next byte.

L9420:  INY                     ;Increment data index.
L9421:  BNE GetNextEndByte      ;Get next data byte.

DoNonRepeatedValue:
L9423:  CMP #END_TXT_END        ;
L9425:  BEQ FinishEndDataBlock  ;Has an end of data block byte been found?
L9427:  CMP #END_RPT_END        ;If so, display credits and move to next data block.
L9429:  BEQ FinishEndDataBlock  ;

L942B:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

L942E:  INY                     ;Increment data index.
L942F:  BNE GetNextEndByte      ;Get next data byte.

FinishEndDataBlock:
L9431:  INY                     ;Increment data index and prepare to add
L9432:  TYA                     ;it to the data pointer.

L9433:  CLC                     ;
L9434:  ADC DatPntr1LB          ;Move pointer to start of next block of credits.
L9436:  STA DatPntr1LB          ;
L9438:  BCC +                   ;Does upper byte of pointer need to be incremented?
L943A:  INC DatPntrlUB          ;If not, branch to skip.

L943C:* LDA PPUDataByte         ;Has the end of this segment been found?
L943E:  CMP #END_TXT_END        ;If so, branch to get next segment.
L9440:  BEQ RollCredits         ;($93FA)Loop to keep rolling credits.

L9442:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

L9445:  BRK                     ;Fade in credits.
L9446:  .byte $07, $07          ;($AA3D)DoPalFadeIn, bank 0.

L9448:  LDA EndCreditCount      ;Get the number of credit screens that have been shown.
L944A:  BNE CheckCredits1       ;Is this the first one? If not, branch.

L944C:  LDY #$08                ;First credit screen.  Wait for 8 music timing events.
L944E:  BNE WaitForMusTmng      ;Branch always.

CheckCredits1:
L9450:  CMP #$01                ;Is this the second credit screen?
L9452:  BNE CheckCredits2       ;If not, branch.

L9454:  LDY #$02                ;Second credit screen.  Wait for 2 music timing events.
L9456:  BNE WaitForMusTmng      ;Branch always.

CheckCredits2:
L9458:  CMP #$02                ;Is this the third credit screen?
L945A:  BEQ CheckCreditEnd      ;if so, branch to wait for 3 music timing events.

L945C:  CMP #$03                ;Is this the fourth credit screen?
L945E:  BEQ CheckCreditEnd      ;if so, branch to wait for 3 music timing events.

L9460:  CMP #$04                ;Is this the fifth credit screen?
L9462:  BEQ CheckCreditEnd      ;if so, branch to wait for 3 music timing events.

L9464:  CMP #$0D                ;Is this the 14th or less credit screen?
L9466:  BEQ MusicTiming2        ;
L9468:  BCC MusicTiming2        ;if so, branch to wait for 2 music timing events.

CheckCreditEnd:
L946A:  CMP #$12                ;Have all 18 screens of credits been shown?
L946C:  BCC MusicTiming3        ;If not, branch to do more.

FinishCredits:
L946E:  LDY #$A0                ;Wait 160 frames.
L9470:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
L9473:  DEY                     ;Done waiting 160 frames?
L9474:  BNE -                   ;If not, branch to wait more.
L9476:  RTS                     ;

MusicTiming3:
L9477:  LDY #$03                ;Wait for 3 music timing events.
L9479:  BNE WaitForMusTmng      ;Branch always.

MusicTiming2:
L947B:  LDY #$02                ;Wait for 2 music timing events.

WaitForMusTmng:
L947D:* BRK                     ;Wait for timing queue in music.
L947E:  .byte $03, $17          ;($815E)WaitForMusicEnd, bank 1.

L9480:  DEY                     ;Is it time to move to the next set of credits?
L9481:  BNE -                   ;If not, branch to wait more.
L9483:  INC EndCreditCount      ;Increment credit screen counter.

L9485:  BRK                     ;Fade out credits.
L9486:  .byte $08, $07          ;($AA43)DoPalFadeOut, bank 0.

L9488:  JMP DoClearPPU          ;($93F7)Prepare to load next screen of credits.

;----------------------------------------------------------------------------------------------------

EndCreditDatPtr:
L948B:  .word EndCreditDat      ;($948D)Start of data below.

;----------------------------------------------------------------------------------------------------

EndCreditDat:
L948D:  .word $20E8             ;PPU address.
;              C    O    N    G    R    A    T    U    L    A    T    I    O    N    S    _   
L948F:  .byte $26, $32, $31, $2A, $35, $24, $37, $38, $2F, $24, $37, $2C, $32, $31, $36, $60
;             END  
L949F:  .byte $FC

;----------------------------------------------------------------------------------------------------

L94A0:  .word $2147             ;PPU address.
;              T    H    O    U    _    H    A    S    T    _    R    E    S    T    O    R
L94A2:  .byte $37, $2B, $32, $38, $5F, $2B, $24, $36, $37, $5F, $35, $28, $36, $37, $32, $35
;              E    D   END  
L94B2:  .byte $28, $27, $FC

;----------------------------------------------------------------------------------------------------
    
L94B5:  .word $2186             ;PPU address.
;              P    E    A    C    E    _    U    N    T    O    _    T    H    E    _    W
L94B7:  .byte $33, $28, $24, $26, $28, $5F, $38, $31, $37, $32, $5F, $37, $2B, $28, $5F, $3A
;              O    R    L    D    _   END  
L94C7:  .byte $32, $35, $2F, $27, $60, $FC

;----------------------------------------------------------------------------------------------------

L94CD:  .word $21E4             ;PPU address.
;              B    U    T    _    T    H    E    R    E    _    A    R    E    _    M    A
L94CF:  .byte $25, $38, $37, $5F, $37, $2B, $28, $35, $28, $5F, $24, $35, $28, $5F, $30, $24
;              N    Y    _    R    O    A    D    S   END  
L94DF:  .byte $31, $3C, $5F, $35, $32, $24, $27, $36, $FC

;----------------------------------------------------------------------------------------------------
  
L94E8:  .word $2229             ;PPU address.
;              Y    E    T    _    T    O    _    T    R    A    V    E    L    .   END
L94EA:  .byte $3C, $28, $37, $5F, $37, $32, $5F, $37, $35, $24, $39, $28, $2F, $61, $FC

;----------------------------------------------------------------------------------------------------
     
L94F9:  .word $2289             ;PPU address.
;              M    A    Y    _    T    H    E    _    L    I    G    H    T   END 
L94FB:  .byte $30, $24, $3C, $5F, $37, $2B, $28, $5F, $2F, $2C, $2A, $2B, $37, $FC

;----------------------------------------------------------------------------------------------------
 
L9509:  .word $22C8             ;PPU address.
;              S    H    I    N    E    _    U    P    O    N    _    T    H    E    E    .
L950B:  .byte $36, $2B, $2C, $31, $28, $5F, $38, $33, $32, $31, $5F, $37, $2B, $28, $28, $61
;             END
L951B:  .byte $FD

;----------------------------------------------------------------------------------------------------
   
L951C:  .word $2188             ;PPU address.
;              D    R    A    G    O    N    _    W    A    R    R    I    O    R   END  
L951E:  .byte $27, $35, $24, $2A, $32, $31, $5F, $3A, $24, $35, $35, $2C, $32, $35, $FC

;----------------------------------------------------------------------------------------------------
   
L952D:  .word $21ED             ;PPU address.
;              S    T    A    F    F   END  
L952F:  .byte $36, $37, $24, $29, $29, $FC

;----------------------------------------------------------------------------------------------------

L9535:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L9537:  .byte $F7, $20, $FF, $FD

;----------------------------------------------------------------------------------------------------

L953B:  .word $2186             ;PPU address.
;              S    C    E    N    A    R    I    O    _    W    R    I    T    T    E    N
L953D:  .byte $36, $26, $28, $31, $24, $35, $2C, $32, $5F, $3A, $35, $2C, $37, $37, $28, $31
;              _    B    Y   END  
L954D:  .byte $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
  
L9551:  .word $21EB             ;PPU address.
;              Y    U    J    I    _    H    O    R    I    I   END  
L9553:  .byte $3C, $38, $2D, $2C, $5F, $2B, $32, $35, $2C, $2C, $FC

;----------------------------------------------------------------------------------------------------
  
L955E:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L9560:  .byte $F7, $20, $05, $FD

;----------------------------------------------------------------------------------------------------

L9564:  .word $2185             ;PPU address.
;              C    H    A    R    A    C    T    E     R   _    D    E    S    I    G    N
L9566:  .byte $26, $2B, $24, $35, $24, $26, $37, $28, $35, $5F, $27, $28, $36, $2C, $2A, $31
;              E    D    _    B    Y   END  
L9576:  .byte $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
   
L957C:  .word $21E9             ;PPU address.
;              A    K    I    R    A    _    T    O    R    I    Y    A    M    A   END
L957E:  .byte $24, $2E, $2C, $35, $24, $5F, $37, $32, $35, $2C, $3C, $24, $30, $24, $FC

;----------------------------------------------------------------------------------------------------
     
L958D:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L958F:  .byte $F7, $20, $0A, $FD

;----------------------------------------------------------------------------------------------------

L9593:  .word $2187             ;PPU address.
;              M    U    S    I    C    _    C    O    M    P    O    S    E    D    _    B
L9595:  .byte $30, $38, $36, $2C, $26, $5F, $26, $32, $30, $33, $32, $36, $28, $27, $5F, $25
;              Y   END  
L95A5:  .byte $3C, $FC

;----------------------------------------------------------------------------------------------------

L95A7:  .word $21E8             ;PPU address
;              K    O    I    C    H    I    _    S    U    G    I    Y    A    M    A   END  
L95A9:  .byte $2E, $32, $2C, $26, $2B, $2C, $5F, $36, $38, $2A, $2C, $3C, $24, $30, $24, $FC

;----------------------------------------------------------------------------------------------------

L95B9:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L95BB:  .byte $F7, $20, $0F, $FD

;----------------------------------------------------------------------------------------------------

L95BF:  .word $212A             ;PPU address.
;              P    R    O    G    R    A    M    E    D    _    B    Y   END  
L95C1:  .byte $33, $35, $32, $2A, $35, $24, $30, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------

L95CE:  .word $21A8             ;PPU address.
;              K    O    I    C    H    I    _    N    A    K    A    M    U    R    A   END  
L95D0:  .byte $2E, $32, $2C, $26, $2B, $2C, $5F, $31, $24, $2E, $24, $30, $38, $35, $24, $FC

;----------------------------------------------------------------------------------------------------

L95E0:  .word $220A             ;PPU address.
;              K    O    J    I    _    Y    O    S    H    I    D    A   END 
L95E2:  .byte $2E, $32, $2D, $2C, $5F, $3C, $32, $36, $2B, $2C, $27, $24, $FC

;----------------------------------------------------------------------------------------------------

L95EF:  .word $2267             ;PPU address.
;              T    A    K    E    N    O    R    I    _    Y    A    M    A    M    O    R    
L95F1:  .byte $37, $24, $2E, $28, $31, $32, $35, $2C, $5F, $3C, $24, $30, $24, $30, $32, $35
;              I   END  
L9601:  .byte $2C, $FC

;----------------------------------------------------------------------------------------------------

L9603:  .word $23D0             ;PPU address.
;Attribute table data.
L9605:  .byte $F7, $08, $05, $F7, $10, $00, $FD

;----------------------------------------------------------------------------------------------------

L960C:  .word $2189             ;PPU address.
;              C    G    _    D    E    S    I    G    N    E    D    _    B    Y   END  
L960E:  .byte $26, $2A, $5F, $27, $28, $36, $2C, $2A, $31, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
   
L961D:  .word $21E9             ;PPU address.
;              T    A    K    A    S    H    I    _    Y    A    S    U    N    O   END
L961F:  .byte $37, $24, $2E, $24, $36, $2B, $2C, $5F, $3C, $24, $36, $38, $31, $32, $FC

;----------------------------------------------------------------------------------------------------

L962E:  .word $23D8             ;PPU address.
;Attribute table data.
L9630:  .byte $F7, $08, $0A, $FD

;----------------------------------------------------------------------------------------------------

L9634:  .word $2186             ;PPU address.
;              S    C    E    N    A    R    I    O    _    A    S    S    I    S    T    E
L9636:  .byte $36, $26, $28, $31, $24, $35, $2C, $32, $5F, $24, $36, $36, $2C, $36, $37, $28
;              D    _    B    Y   END  
L963E:  .byte $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------

L964B:  .word $21E8             ;PPU address.
;              H    I    R    O    S    H    I    _    M    I    Y    A    O    K    A   END  
L964D:  .byte $2B, $2C, $35, $32, $36, $2B, $2C, $5F, $30, $2C, $3C, $24, $32, $2E, $24, $FC

;----------------------------------------------------------------------------------------------------

L965D:  .word $23C0             ;PPU address.
;Attribute table data.
L965F:  .byte $F7, $20, $0F, $FD

;----------------------------------------------------------------------------------------------------

L9663:  .word $214A             ;PPU address.
;              A    S    S    I    S    T    E    D    _    B    Y   END
L9665:  .byte $24, $36, $36, $2C, $36, $37, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------

L9671:  .word $21CA             ;PPU address.
;              R    I    K    A    _    S    U    Z    U    K    I   END  
L9673:  .byte $35, $2C, $2E, $24, $5F, $36, $38, $3D, $38, $2E, $2C, $FC

;----------------------------------------------------------------------------------------------------

L967F:  .word $2228             ;PPU address.
;              T    A    D    A    S    H    I    _    F    U    K    U    Z    A    W    A
L9681:  .byte $37, $24, $27, $24, $36, $2B, $2C, $5F, $29, $38, $2E, $38, $3D, $24, $3A, $24
;             END  
L9691:  .byte $FC

;----------------------------------------------------------------------------------------------------

L9692:  .word $23D0             ;PPU address.
;Attribute table data.
L9694:  .byte $F7, $08, $50, $F7, $10, $00, $FD

;----------------------------------------------------------------------------------------------------

L969B:  .word $2187             ;PPU address.
;              S    P    E    C    I    A    L    _    T    H    A    N    K    S    _    T
L969D:  .byte $36, $33, $28, $26, $2C, $24, $2F, $5F, $37, $2B, $24, $31, $2E, $36, $5F, $37
;              O   END  
L96AD:  .byte $32, $FC

;----------------------------------------------------------------------------------------------------

L96AF:  .word $21E7             ;PPU address.
;              K    A    Z    U    H    I    K    O    _    T    O    R    I    S    H    I
L96B1:  .byte $2E, $24, $3D, $38, $2B, $2C, $2E, $32, $5F, $37, $32, $35, $2C, $36, $2B, $2C
;              M    A   END  
L96C1:  .byte $30, $24, $FC

;----------------------------------------------------------------------------------------------------
  
L96C4:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L96C6:  .byte $F7, $20, $05, $FD

;----------------------------------------------------------------------------------------------------

L96CA:  .word $218A             ;PPU address.
;              T    R    A    N    S    L    A    T    I    O    N   END  
L96CC:  .byte $37, $35, $24, $31, $36, $2F, $24, $37, $2C, $32, $31, $FC

;----------------------------------------------------------------------------------------------------

L96D8:  .word $21ED             ;PPU address.
;              S    T    A    F    F   END  
L96DA:  .byte $36, $37, $24, $29, $29, $FC

;----------------------------------------------------------------------------------------------------

L96E0:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L96E2:  .byte $F7, $20, $FF, $FD

;----------------------------------------------------------------------------------------------------

L96E6:  .word $20C6             ;PPU address.
;T    R    A    N    S    L    A    T    E    D    _    B    Y   END
L96E8:  .byte $37, $35, $24, $31, $36, $2F, $24, $37, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
  
L96F6:  .word $2108             ;PPU address.
;              T    O    S    H    I    K    O    _    W    A    T    S    O    N   END  
L96F8:  .byte $37, $32, $36, $2B, $2C, $2E, $32, $5F, $3A, $24, $37, $36, $32, $31, $FC

;----------------------------------------------------------------------------------------------------
   
L9707:  .word $2186             ;PPU address.
;              R    E    V    I    S    E    D    _    T    E    X    T    _    B    Y   END  
L9709:  .byte $35, $28, $39, $2C, $36, $28, $27, $5F, $37, $28, $3B, $37, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------

L9719:  .word $21C8             ;PPU address.
;              S    C    O    T    T    _    P    E    L    L    A    N    D   END  
L971B:  .byte $36, $26, $32, $37, $37, $5F, $33, $28, $2F, $2F, $24, $31, $27, $FC

;----------------------------------------------------------------------------------------------------

L9729:  .word $2246             ;PPU address.
;              T    E    C    H    N    I    C    A    L    _    S    U    P    P    O    R
L972B:  .byte $37, $28, $26, $2B, $31, $2C, $26, $24, $2F, $5F, $36, $38, $33, $33, $32, $35
;              T    _    B    Y   END  
L973B:  .byte $37, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------

L9740:  .word $2288             ;PPU address.
;              D    O    U    G    _    B    A    K    E    R   END  
L9742:  .byte $27, $32, $38, $2A, $5F, $25, $24, $2E, $28, $35, $FC

;----------------------------------------------------------------------------------------------------

L974D:  .word $23C0             ;PPU address.
;Attribute table data.
L974F:  .byte $F7, $10, $FF, $F7, $08, $00, $F7, $08, $0F, $F7, $10, $F0, $FD

;----------------------------------------------------------------------------------------------------

L975C:  .word $2148             ;PPU address.
;              P    R    O    G    R    A    M    E    D    _    B    Y   END  
L975E:  .byte $33, $35, $32, $2A, $35, $24, $30, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
  
L976B:  .word $21CA             ;PPU address.
;              K    E    N    I    C    H    I    _    M    A    S    U    T    A   END  
L976D:  .byte $2E, $28, $31, $2C, $26, $2B, $2C, $5F, $30, $24, $36, $38, $37, $24, $FC

;----------------------------------------------------------------------------------------------------
   
L977C:  .word $222A             ;PPU address.
;              M    A    N    A    B    U    _    Y    A    M    A    N    A   END  
L977E:  .byte $30, $24, $31, $24, $25, $38, $5F, $3C, $24, $30, $24, $31, $24, $FC

;----------------------------------------------------------------------------------------------------

L978C:  .word $23D0             ;PPU address.
;Attribute table data.
L978E:  .byte $F7, $08, $50, $F7, $10, $00, $FD

;----------------------------------------------------------------------------------------------------

L9795:  .word $2125             ;PPU address.
;              C    G    _    D    E    S    I    G    N    E    D    _    B    Y   END
L9797:  .byte $26, $2A, $5F, $27, $28, $36, $2C, $2A, $31, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
  
L97A6:  .word $218A             ;PPU address.
;              S    A    T    O    S    H    I    _    F    U    D    A    B    A   END
L97A8:  .byte $36, $24, $37, $32, $36, $2B, $2C, $5F, $29, $38, $27, $24, $25, $24, $FC

;----------------------------------------------------------------------------------------------------

L97B7:  .word $2205             ;PPU address.
;              S    P    E    C    I    A    L    _    T    H    A    N    K    S    _    T
L97B9:  .byte $36, $33, $28, $26, $2C, $24, $2F, $5F, $37, $2B, $24, $31, $2E, $36, $5F, $37
;              O   END  
L97C9:  .byte $32, $FC
;----------------------------------------------------------------------------------------------------
 
L97CB:  .word $226A             ;PPU address.
;              H    O    W    A    R    D    _    P    H    I    L    L    I    P    S   END
L97CD:  .byte $2B, $32, $3A, $24, $35, $27, $5F, $33, $2B, $2C, $2F, $2F, $2C, $33, $36, $FC

;----------------------------------------------------------------------------------------------------
  
L97DD:  .word $23D0             ;PPU address.
;Attribute table data.
L97DF:  .byte $F7, $08, $0A, $F7, $08, $00, $F7, $08, $0F, $FD

;----------------------------------------------------------------------------------------------------

L97E9:  .word $218A             ;PPU address.
;              D    I    R    E    C    T    E    D    _    B    Y   END  
L97EB:  .byte $27, $2C, $35, $28, $26, $37, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------
  
L97F7:  .word $21E8             ;PPU address.
;              K    O    I    C    H    I    _    N    A    K    A    M    U    R    A   END  
L97F9:  .byte $2E, $32, $2C, $26, $2B, $2C, $5F, $31, $24, $2E, $24, $30, $38, $35, $24, $FC

;----------------------------------------------------------------------------------------------------

L9809:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L980B:  .byte $F7, $20, $0A, $FD

;----------------------------------------------------------------------------------------------------

L980F:  .word $218A             ;PPU address.
;              P    R    O    D    U    C    E    D    _    B    Y   END  
L9811:  .byte $33, $35, $32, $27, $38, $26, $28, $27, $5F, $25, $3C, $FC

;----------------------------------------------------------------------------------------------------

L981D:  .word $21E9             ;PPU address.
;              Y    U    K    I    N    O    B    U    _    C    H    I    D    A   END
L981F:  .byte $3C, $38, $2E, $2C, $31, $32, $25, $38, $5F, $26, $2B, $2C, $27, $24, $FC
;----------------------------------------------------------------------------------------------------

L982E:  .word $23C0             ;PPU address.
;1 row of attribute table data.
L9830:  .byte $F7, $20, $0F, $FD

;----------------------------------------------------------------------------------------------------

L9834:  .word $2085             ;PPU address.
;              B    A    S    E    D    _    O    N    _    D    R    A    G    O    N    _
L9836:  .byte $25, $24, $36, $28, $27, $5F, $32, $31, $5F, $27, $35, $24, $2A, $32, $31, $5F
;              Q    U    E    S    T   END  
L9846:  .byte $34, $38, $28, $36, $37, $FC

;----------------------------------------------------------------------------------------------------
  
L984C:  .word $210B             ;PPU address.
;              C    O    P    Y    R    I    G    H    T   END  
L984E:  .byte $26, $32, $33, $3C, $35, $2C, $2A, $2B, $37, $FC

;----------------------------------------------------------------------------------------------------
 
L9858:  .word $2163             ;PPU address.
;              A    R    M    O    R    _    P    R    O    J    E    C    T   END  
L985A:  .byte $24, $35, $30, $32, $35, $5F, $33, $35, $32, $2D, $28, $26, $37, $FC

;----------------------------------------------------------------------------------------------------
  
L9868:  .word $2174             ;PPU address.
;              1    9    8    6    _    1    9    8    9   END  
L986A:  .byte $01, $09, $08, $06, $5F, $01, $09, $08, $09, $FC

;----------------------------------------------------------------------------------------------------
  
L9874:  .word $21C3             ;PPU address.
;              B    I    R    D    _    S    T    U    D    I    O   END  
L9876:  .byte $25, $2C, $35, $27, $5F, $36, $37, $38, $27, $2C, $32, $FC

;----------------------------------------------------------------------------------------------------
 
L9882:  .word $21D4             ;PPU address.
;              1    9    8    6    _    1    9    8    9   END  
L9884:  .byte $01, $09, $08, $06, $5F, $01, $09, $08, $09, $FC

;----------------------------------------------------------------------------------------------------

L988E:  .word $2223             ;PPU address.
;              K    O    I    C    H    I    _    S    U    G    I    Y    A    M    A   END
L9890:  .byte $2E, $32, $2C, $26, $2B, $2C, $5F, $36, $38, $2A, $2C, $3C, $24, $30, $24, $FC

;----------------------------------------------------------------------------------------------------
   
L98A0:  .word $2234             ;PPU address.
;              1    9    8    6    _    1    9    8    9   END  
L98A2:  .byte $01, $09, $08, $06, $5F, $01, $09, $08, $09, $FC

;----------------------------------------------------------------------------------------------------

L98AC:  .word $2283             ;PPU address.
;                            CHUN  _    S    O    F    T   END  
L98AE:  .byte $0C, $0D, $0E, $0F, $5F, $36, $32, $29, $37, $FC

;----------------------------------------------------------------------------------------------------
  
L98B8:  .word $2294             ;PPU address.
;              1    9    8    6    _    1    9    8    9   END  
L98BA:  .byte $01, $09, $08, $06, $5F, $01, $09, $08, $09, $FC

;----------------------------------------------------------------------------------------------------
  
L98C4:  .word $2309             ;PPU address.
;              E    N    I    X   END  
L98C6:  .byte $28, $31, $2C, $3B, $FC

;----------------------------------------------------------------------------------------------------

L98CB:  .word $2310             ;PPU address.
;              1    9    8    6    _    1    9    8    9   END  
L98CD:  .byte $01, $09, $08, $06, $5F, $01, $09, $08, $09, $FC

;----------------------------------------------------------------------------------------------------

L98D7:  .word $23C8             ;PPU address.
;Attribute table data.
L98D9:  .byte $F7, $03, $FF, $07, $F7, $06, $05, $F7, $03, $0F, $F7, $03, $AA, $F7, $05, $00
L98E9:  .byte $F7, $05, $AA, $FC

;----------------------------------------------------------------------------------------------------

L98ED:  .word $23E0             ;PPU address.
;Attribute table data.
L98EF:  .byte $F7, $05, $00, $F7, $03, $AA, $04, $F7, $04, $00, $F7, $03, $AA, $F7, $04, $00
L98FF:  .byte $F7, $03, $AA, $FD

;----------------------------------------------------------------------------------------------------

L9903:  .word $218F             ;PPU address.
;Enix "e" Top row.
L9905:  .byte $10, $11, $12, $FC

;----------------------------------------------------------------------------------------------------

L9909:  .word $21AE             ;PPU address.
;Enix "e" second row.
L990B:  .byte $13, $14, $15, $16, $FC

;----------------------------------------------------------------------------------------------------

L9910:  .word $21CE             ;PPU address.
;Enix "e" third row.
L9912:  .byte $17, $18, $19, $1A, $FC

;----------------------------------------------------------------------------------------------------

L9917:  .word $21EE             ;PPU address.
;Enix "e" bottom row.
L9919:  .byte $1B, $1C, $1D, $1E, $FC

;----------------------------------------------------------------------------------------------------

L991E:  .word $220E             ;PPU address.
;"ENIX" text.
L9920:  .byte $1F, $20, $21, $22, $FC

;----------------------------------------------------------------------------------------------------

L9925:  .word $23D8             ;PPU address.
;Half a row of blank tiles.
L9927:  .byte $F7, $10, $FF, $FD

;----------------------------------------------------------------------------------------------------

L992B:  .word $21AA             ;PPU address.
;"THE END" top row.
L992D:  .byte $3E, $3F, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $FC

;----------------------------------------------------------------------------------------------------

L993A:  .word $21CA             ;PPU address.
;"THE END" bottom row.
L993C:  .byte $4A, $4B, $4C, $4D, $4E, $4F, $50, $51, $52, $53, $54, $55, $FC

;----------------------------------------------------------------------------------------------------

L9949:  .word $23D0             ;PPU address.
;1 row of blank tiles.
L994B:  .byte $F7, $20, $00, $FD

;----------------------------------------------------------------------------------------------------

CopyTrsrTbl:
L994F:  PHA                     ;
L9950:  TXA                     ;Save A and X.
L9951:  PHA                     ;

L9952:  LDX #$7B                ;Prepare to copy 124 bytes.

L9954:* LDA TreasureTbl,X       ;Copy treasure table into RAM starting at $0320.
L9957:  STA BlockRAM+$20,X      ;
L995A:  DEX                     ;Have 124 bytes been copied?
L995B:  BPL -                   ;If not, branch to copy more.

L995D:  PLA                     ;
L995E:  TAX                     ;Restore X and A.
L995F:  PLA                     ;
L9960:  RTS                     ;

;----------------------------------------------------------------------------------------------------

LoadEnemyStats:
L9961:  PHA                     ;
L9962:  TYA                     ;Store A and Y.
L9963:  PHA                     ;

L9964:  LDY #$0F                ;16 bytes per enemy in EnStatTbl.
L9966:  LDA EnDatPtrLB          ;
L9968:  CLC                     ;
L9969:  ADC EnStatTblPtr        ;Add enemy data offset to the table pointer.
L996C:  STA GenPtr3CLB          ;
L996E:  LDA EnDatPtrUB          ;
L9970:  ADC EnStatTblPtr+1      ;Save a copy of the pointer in a general use pointer.
L9973:  STA GenPtr3CUB          ;

L9975:* LDA (GenPtr3C),Y        ;Use the general pointer to load the enemy data.
L9977:  STA EnBaseAtt,Y         ;
L997A:  DEY                     ;
L997B:  BPL -                   ;More data to load? If so, branch to load more.

L997D:  PLA                     ;
L997E:  TAY                     ;Restore A and Y and return.
L997F:  PLA                     ;
L9980:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CopyROMToRAM:
L9981:  PHA                     ;
L9982:  TYA                     ;Save A and Y.
L9983:  PHA                     ;

L9984:  LDY #$00                ;
L9986:  LDA CopyCounterLB       ;Is copy counter = 0?
L9988:  ORA CopyCounterUB       ;If so, branch.  Nothing to copy.
L998A:  BEQ CopyROMDone         ;

CopyROMLoop:
L998C:  LDA (ROMSrcPtr),Y       ;Get byte from ROM and put it into RAM.
L998E:  STA (RAMTrgtPtr),Y      ;

L9990:  LDA CopyCounterLB       ;
L9992:  SEC                     ;
L9993:  SBC #$01                ;
L9995:  STA CopyCounterLB       ;Decrement copy counter.
L9997:  LDA CopyCounterUB       ;
L9999:  SBC #$00                ;
L999B:  STA CopyCounterUB       ;

L999D:  ORA CopyCounterLB       ;Is copy counter = 0?
L999F:  BEQ CopyROMDone         ;If so, branch.  Done copying.

L99A1:  INC ROMSrcPtrLB         ;
L99A3:  BNE +                   ;Increment ROM source pointer.
L99A5:  INC ROMSrcPtrUB         ;

L99A7:* INC RAMTrgtPtrLB        ;
L99A9:  BNE +                   ;Increment RAM target pointer.
L99AB:  INC RAMTrgtPtrUB        ;

L99AD:* JMP CopyROMLoop         ;($998C)Loop to copy more data.

CopyROMDone:
L99B0:  PLA                     ;
L99B1:  TAY                     ;Restore Y and A and return.
L99B2:  PLA                     ;
L99B3:  RTS                     ;

;----------------------------------------------------------------------------------------------------

SetBaseStats:
L99B4:  TYA                     ;Save Y on the stack.
L99B5:  PHA                     ;

L99B6:  LDA BaseStatsTbl-2      ;
L99B9:  STA PlayerDatPtrLB      ;Load base address for the BaseStatsTbl.
L99BB:  LDA BaseStatsTbl-1      ;
L99BE:  STA PlayerDatPtrUB      ;
L99C0:  LDY LevelDatPtr         ;Load offset for player's level in the table.

L99C2:  LDA (PlayerDatPtr),Y    ;
L99C4:  STA DisplayedStr        ;Load player's base strength.
L99C6:  INY                     ;

L99C7:  LDA (PlayerDatPtr),Y    ;
L99C9:  STA DisplayedAgi        ;Load player's base agility.
L99CB:  INY                     ;

L99CC:  LDA (PlayerDatPtr),Y    ;
L99CE:  STA DisplayedMaxHP      ;Load player's base max HP.
L99D0:  INY                     ;

L99D1:  LDA (PlayerDatPtr),Y    ;
L99D3:  STA DisplayedMaxMP      ;Load player's base MP.
L99D5:  INY                     ;

L99D6:  LDA (PlayerDatPtr),Y    ;
L99D8:  ORA ModsnSpells         ;Load player's healmore/hurtmore spells.
L99DA:  STA ModsnSpells         ;
L99DC:  INY                     ;

L99DD:  LDA (PlayerDatPtr),Y    ;Load player's other spells.
L99DF:  STA SpellFlags          ;

L99E1:  PLA                     ;
L99E2:  TAY                     ;Restore Y and return.
L99E3:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;The following table contains the pointers to the enemy sprites.  The MSB for the pointer is not
;set for some entries.  The enemies that have the MSB set in the table below are mirrored from left
;to right on the display.  For example, the knight and armored knight have the same foot forward
;while the axe knight has the opposite foot forward.  This is because the axe knight is mirrored
;while the other two are not. The code that accesses the table sets the MSB when it accesses it.

EnSpritesPtrTbl:
L99E4:  .word SlimeSprts -$8000 ;($1B0E)Slime.
L99E6:  .word SlimeSprts -$8000 ;($1B0E)Red slime.
L99E8:  .word DrakeeSprts-$8000 ;($1AC4)Drakee.
L99EA:  .word GhstSprts  -$8000 ;($1BAA)Ghost.
L99EC:  .word MagSprts   -$8000 ;($1B30)Magician.
L99EE:  .word DrakeeSprts-$8000 ;($1AC4)Magidrakee.
L99F0:  .word ScorpSprts -$8000 ;($1CD1)Scorpion.
L99F2:  .word DruinSprts -$8000 ;($1AE0)Druin.
L99F4:  .word GhstSprts  -$8000 ;($1BAA)Poltergeist.
L99F6:  .word DrollSprts -$8000 ;($1A87)Droll.
L99F8:  .word DrakeeSprts-$8000 ;($1AC4)Drakeema.
L99FA:  .word SkelSprts         ;($9A3E)Skeleton.
L99FC:  .word WizSprts   -$8000 ;($1B24)Warlock.
L99FE:  .word ScorpSprts        ;($9CD1)Metal scorpion.
L9A00:  .word WolfSprts  -$8000 ;($1C15)Wolf.
L9A02:  .word SkelSprts  -$8000 ;($1A3E)Wraith.
L9A04:  .word SlimeSprts -$8000 ;($1B0E)Metal slime.
L9A06:  .word GhstSprts         ;($9BAA)Specter.
L9A08:  .word WolfSprts         ;($9C15)Wolflord.
L9A0A:  .word DruinSprts        ;($9AE0)Druinlord.
L9A0C:  .word DrollSprts -$8000 ;($1A87)Drollmagi.
L9A0E:  .word WyvrnSprts -$8000 ;($1BD5)Wyvern.
L9A10:  .word ScorpSprts -$8000 ;($1CD1)Rouge scorpion.
L9A12:  .word DKnightSprts      ;($9A32)Wraith knight.
L9A14:  .word GolemSprts        ;($9C70)Golem.
L9A16:  .word GolemSprts -$8000 ;($1C70)Goldman.
L9A18:  .word KntSprts   -$8000 ;($1D20)Knight.
L9A1A:  .word WyvrnSprts        ;($9BD5)Magiwyvern.
L9A1C:  .word DKnightSprts      ;($9A32)Demon knight.
L9A1E:  .word WolfSprts  -$8000 ;($1C15)Werewolf.
L9A20:  .word DgnSprts   -$8000 ;($1D81)Green dragon.
L9A22:  .word WyvrnSprts -$8000 ;($1BD5)Starwyvern.
L9A24:  .word WizSprts          ;($9B24)Wizard.
L9A26:  .word AxKntSprts        ;($9D0E)Axe knight.
L9A28:  .word RBDgnSprts -$8000 ;($1D7B)Blue dragon.
L9A2A:  .word GolemSprts -$8000 ;($1C70)Stoneman.
L9A2C:  .word ArKntSprts -$8000 ;($1D02)Armored knight.
L9A2E:  .word RBDgnSprts -$8000 ;($1D7B)Red dragon.
L9A30:  .word DgLdSprts  -$8000 ;($1B67)Dragonlord, initial form.

;----------------------------------------------------------------------------------------------------

;The following tables contain the sprite information for the enemies in the game(except the end
;boss). Each sprite is represented by 3 bytes.  The format for the bytes is as follows:

;TTTTTTTT VHYYYYYY XXXXXXPP

;TTTTTTTT-Tile pattern number for sprite.
;YYYYYY-Y position of sprite.
;XXXXXX-X position of sprite. 
;V-Vertical mirroring bit.
;H-Horizontal mirroring bit.
;PP-Palette number.

DKnightSprts:
L9A32:  .byte $30, $2A, $9F     ;
L9A35:  .byte $2F, $27, $7F     ;Wraith knight and demon knight sword sprites.
L9A38:  .byte $2F, $23, $5F     ;
L9A3B:  .byte $2E, $1F, $3F     ;

SkelSprts:
L9A3E:  .byte $20, $17, $70
L9A41:  .byte $21, $1F, $70
L9A44:  .byte $23, $1E, $3B
L9A47:  .byte $26, $26, $3A
L9A4A:  .byte $22, $1E, $59
L9A4D:  .byte $27, $26, $61
L9A50:  .byte $28, $2E, $61
L9A53:  .byte $29, $33, $55
L9A56:  .byte $2A, $37, $56
L9A59:  .byte $22, $5E, $89
L9A5C:  .byte $23, $5E, $AB
L9A5F:  .byte $27, $66, $81
L9A62:  .byte $28, $6E, $81
L9A65:  .byte $24, $26, $A6
L9A68:  .byte $25, $2D, $A6
L9A6B:  .byte $2B, $33, $9D
L9A6E:  .byte $2C, $3B, $8E
L9A71:  .byte $2D, $3B, $AE
L9A74:  .byte $FE, $3B, $4A
L9A77:  .byte $FF, $3B, $6A
L9A7A:  .byte $FE, $7B, $8A
L9A7D:  .byte $FE, $7D, $AA
L9A80:  .byte $FE, $3F, $86
L9A83:  .byte $FE, $7F, $A6
L9A86:  .byte $00

DrollSprts:
L9A87:  .byte $31, $59, $62
L9A8A:  .byte $32, $61, $63
L9A8D:  .byte $33, $69, $62
L9A90:  .byte $34, $71, $61
L9A93:  .byte $35, $77, $60
L9A96:  .byte $31, $19, $82
L9A99:  .byte $32, $21, $83
L9A9C:  .byte $33, $29, $82
L9A9F:  .byte $34, $31, $81
L9AA2:  .byte $35, $37, $80
L9AA5:  .byte $36, $5E, $40
L9AA8:  .byte $38, $66, $42
L9AAB:  .byte $39, $6E, $43
L9AAE:  .byte $3A, $76, $40
L9AB1:  .byte $36, $1E, $A0
L9AB4:  .byte $38, $26, $A2
L9AB7:  .byte $39, $2E, $A3
L9ABA:  .byte $3A, $36, $A0
L9ABD:  .byte $E6, $22, $5A
L9AC0:  .byte $E6, $62, $8A
L9AC3:  .byte $00

DrakeeSprts:
L9AC4:  .byte $3B, $1F, $50
L9AC7:  .byte $3C, $27, $50
L9ACA:  .byte $3D, $1F, $70
L9ACD:  .byte $3E, $27, $70
L9AD0:  .byte $3B, $5F, $90
L9AD3:  .byte $3C, $67, $90
L9AD6:  .byte $3F, $2C, $7C
L9AD9:  .byte $FE, $39, $62
L9ADC:  .byte $FE, $79, $82
L9ADF:  .byte $00

DruinSprts:
L9AE0:  .byte $42, $1C, $40
L9AE3:  .byte $45, $24, $40
L9AE6:  .byte $4A, $29, $41
L9AE9:  .byte $4D, $31, $41
L9AEC:  .byte $43, $1C, $60
L9AEF:  .byte $46, $24, $60
L9AF2:  .byte $4B, $29, $61
L9AF5:  .byte $4E, $31, $61
L9AF8:  .byte $40, $18, $6C
L9AFB:  .byte $41, $18, $8C
L9AFE:  .byte $44, $1C, $80
L9B01:  .byte $47, $24, $82
L9B04:  .byte $4C, $2A, $81
L9B07:  .byte $48, $24, $A1
L9B0A:  .byte $49, $28, $C1
L9B0D:  .byte $00

SlimeSprts:
L9B0E:  .byte $55, $32, $64
L9B11:  .byte $53, $2B, $60
L9B14:  .byte $54, $33, $60
L9B17:  .byte $53, $6B, $7C
L9B1A:  .byte $54, $73, $7C
L9B1D:  .byte $FF, $35, $72
L9B20:  .byte $FE, $F6, $92
L9B23:  .byte $00

WizSprts:
L9B24:  .byte $5C, $19, $96     ;
L9B27:  .byte $5D, $20, $96     ;Wizard and warlock staff sprites.
L9B2A:  .byte $5D, $2E, $9A     ;
L9B2D:  .byte $5D, $35, $9E     ;

MagSprts:
L9B30:  .byte $5A, $1B, $61
L9B33:  .byte $5B, $23, $61
L9B36:  .byte $5A, $5B, $81
L9B39:  .byte $5B, $63, $81
L9B3C:  .byte $56, $24, $30
L9B3F:  .byte $57, $23, $50
L9B42:  .byte $58, $2B, $50
L9B45:  .byte $59, $33, $50
L9B48:  .byte $5F, $23, $90
L9B4B:  .byte $60, $2B, $90
L9B4E:  .byte $61, $33, $90
L9B51:  .byte $5E, $33, $70
L9B54:  .byte $5E, $2C, $70
L9B57:  .byte $FF, $A7, $73
L9B5A:  .byte $FE, $37, $48
L9B5D:  .byte $FF, $37, $68
L9B60:  .byte $FF, $77, $88
L9B63:  .byte $FE, $77, $A8
L9B66:  .byte $00

DgLdSprts:
L9B67:  .byte $62, $1E, $9F
L9B6A:  .byte $63, $26, $9F
L9B6D:  .byte $63, $74, $9B
L9B70:  .byte $5D, $3B, $95
L9B73:  .byte $67, $1C, $62
L9B76:  .byte $68, $23, $61
L9B79:  .byte $69, $23, $5A
L9B7C:  .byte $6A, $2B, $63
L9B7F:  .byte $67, $5C, $82
L9B82:  .byte $68, $63, $81
L9B85:  .byte $69, $63, $8A
L9B88:  .byte $6A, $6B, $83
L9B8B:  .byte $64, $29, $50
L9B8E:  .byte $65, $31, $50
L9B91:  .byte $66, $39, $50
L9B94:  .byte $5F, $29, $90
L9B97:  .byte $60, $31, $90
L9B9A:  .byte $61, $39, $90
L9B9D:  .byte $5E, $39, $70
L9BA0:  .byte $5E, $32, $70
L9BA3:  .byte $5E, $2B, $80
L9BA6:  .byte $5E, $2B, $70
L9BA9:  .byte $00

GhstSprts:
L9BAA:  .byte $70, $27, $52
L9BAD:  .byte $73, $2F, $52
L9BB0:  .byte $71, $27, $72
L9BB3:  .byte $74, $2F, $73
L9BB6:  .byte $72, $27, $91
L9BB9:  .byte $75, $2F, $92
L9BBC:  .byte $6D, $21, $50
L9BBF:  .byte $6E, $21, $70
L9BC2:  .byte $6F, $21, $90
L9BC5:  .byte $6B, $19, $70
L9BC8:  .byte $6C, $19, $90
L9BCB:  .byte $FE, $3C, $55
L9BCE:  .byte $FF, $3C, $6D
L9BD1:  .byte $FE, $7C, $8D
L9BD4:  .byte $00

WyvrnSprts:
L9BD5:  .byte $83, $1A, $4F
L9BD8:  .byte $81, $15, $60
L9BDB:  .byte $82, $1D, $60
L9BDE:  .byte $7F, $18, $42
L9BE1:  .byte $80, $20, $41
L9BE4:  .byte $7C, $12, $9C
L9BE7:  .byte $7A, $1A, $80
L9BEA:  .byte $7B, $22, $80
L9BED:  .byte $7D, $1A, $A0
L9BF0:  .byte $7E, $22, $A0
L9BF3:  .byte $76, $2D, $2C
L9BF6:  .byte $77, $2D, $4C
L9BF9:  .byte $78, $2D, $6C
L9BFC:  .byte $79, $25, $60
L9BFF:  .byte $6B, $25, $70
L9C02:  .byte $55, $1F, $39
L9C05:  .byte $55, $21, $61
L9C08:  .byte $63, $A1, $45
L9C0B:  .byte $FE, $3D, $3E
L9C0E:  .byte $FF, $3D, $5E
L9C11:  .byte $FE, $7D, $7E
L9C14:  .byte $00

WolfSprts:
L9C15:  .byte $2A, $37, $56
L9C18:  .byte $8D, $21, $98
L9C1B:  .byte $8E, $29, $90
L9C1E:  .byte $84, $1A, $81
L9C21:  .byte $85, $22, $81
L9C24:  .byte $86, $2A, $80
L9C27:  .byte $87, $31, $83
L9C2A:  .byte $88, $21, $A0
L9C2D:  .byte $8F, $29, $A0
L9C30:  .byte $8A, $31, $A3
L9C33:  .byte $8B, $22, $C0
L9C36:  .byte $8C, $2A, $C0
L9C39:  .byte $2C, $39, $8E
L9C3C:  .byte $2D, $39, $AE
L9C3F:  .byte $84, $5A, $61
L9C42:  .byte $85, $62, $61
L9C45:  .byte $86, $6A, $60
L9C48:  .byte $87, $71, $63
L9C4B:  .byte $88, $61, $40
L9C4E:  .byte $89, $69, $40
L9C51:  .byte $90, $71, $43
L9C54:  .byte $8B, $62, $20
L9C57:  .byte $8C, $6A, $20
L9C5A:  .byte $FF, $2A, $72
L9C5D:  .byte $91, $1D, $A8
L9C60:  .byte $FE, $39, $40
L9C63:  .byte $FF, $39, $60
L9C66:  .byte $FF, $7A, $80
L9C69:  .byte $FE, $3D, $88
L9C6C:  .byte $FE, $7D, $A8
L9C6F:  .byte $00

GolemSprts:
L9C70:  .byte $0E, $1C, $24
L9C73:  .byte $B6, $24, $24
L9C76:  .byte $BD, $3C, $24
L9C79:  .byte $BB, $34, $38
L9C7C:  .byte $B7, $14, $44
L9C7F:  .byte $B8, $1C, $44
L9C82:  .byte $B9, $24, $44
L9C85:  .byte $BA, $2C, $44
L9C88:  .byte $BE, $3C, $44
L9C8B:  .byte $BC, $34, $58
L9C8E:  .byte $C1, $1C, $64
L9C91:  .byte $C2, $24, $64
L9C94:  .byte $C3, $2C, $64
L9C97:  .byte $BF, $3C, $64
L9C9A:  .byte $C0, $14, $6C
L9C9D:  .byte $C4, $18, $84
L9CA0:  .byte $C5, $20, $84
L9CA3:  .byte $C6, $28, $84
L9CA6:  .byte $C7, $30, $84
L9CA9:  .byte $CF, $38, $88
L9CAC:  .byte $C8, $18, $A4
L9CAF:  .byte $C9, $20, $A4
L9CB2:  .byte $CA, $28, $A4
L9CB5:  .byte $CB, $30, $A4
L9CB8:  .byte $D0, $38, $A8
L9CBB:  .byte $CC, $20, $C4
L9CBE:  .byte $CD, $28, $C4
L9CC1:  .byte $CE, $30, $C4
L9CC4:  .byte $58, $96, $64
L9CC7:  .byte $FF, $B8, $78
L9CCA:  .byte $FE, $3C, $94
L9CCD:  .byte $FE, $7C, $B4
L9CD0:  .byte $00

ScorpSprts:
L9CD1:  .byte $D4, $38, $38
L9CD4:  .byte $D5, $32, $50
L9CD7:  .byte $D6, $2F, $70
L9CDA:  .byte $D7, $37, $70
L9CDD:  .byte $D8, $3F, $8C
L9CE0:  .byte $D9, $2F, $90
L9CE3:  .byte $DA, $37, $90
L9CE6:  .byte $DB, $2F, $B0
L9CE9:  .byte $DC, $37, $B0
L9CEC:  .byte $D3, $27, $A8
L9CEF:  .byte $D2, $23, $9C
L9CF2:  .byte $D1, $23, $7C
L9CF5:  .byte $3F, $63, $74
L9CF8:  .byte $FF, $32, $71
L9CFB:  .byte $FE, $37, $54
L9CFE:  .byte $FE, $73, $C0
L9D01:  .byte $00

ArKntSprts:
L9D02:  .byte $F6, $19, $C6     ;
L9D05:  .byte $F7, $21, $C6     ;Armored knight shield sprites.
L9D08:  .byte $F8, $29, $C6     ;
L9D0B:  .byte $F9, $31, $C6     ;

AxKntSprts:
L9D0E:  .byte $FA, $11, $1E     ;
L9D11:  .byte $FB, $19, $1E     ;
L9D14:  .byte $FC, $15, $3E     ;Axe knight and armored knight sprites.
L9D17:  .byte $FD, $20, $2E     ;
L9D1A:  .byte $5D, $18, $32     ;
L9D1D:  .byte $B5, $2E, $26     ;

KntSprts:
L9D20:  .byte $B3, $31, $6E
L9D23:  .byte $B4, $31, $8E
L9D26:  .byte $37, $17, $6B
L9D29:  .byte $9C, $19, $8B
L9D2C:  .byte $9F, $1F, $54
L9D2F:  .byte $9D, $1F, $74
L9D32:  .byte $9E, $1F, $94
L9D35:  .byte $A0, $1F, $B4
L9D38:  .byte $A1, $27, $29
L9D3B:  .byte $A2, $27, $48
L9D3E:  .byte $A3, $27, $68
L9D41:  .byte $A4, $27, $88
L9D44:  .byte $A5, $27, $A8
L9D47:  .byte $A7, $29, $B5
L9D4A:  .byte $A8, $2F, $5C
L9D4D:  .byte $A9, $2F, $7C
L9D50:  .byte $AA, $2F, $9C
L9D53:  .byte $AB, $33, $3C
L9D56:  .byte $AD, $37, $5C
L9D59:  .byte $AE, $37, $7C
L9D5C:  .byte $AF, $37, $9C
L9D5F:  .byte $B1, $37, $BC
L9D62:  .byte $AC, $3B, $41
L9D65:  .byte $B0, $3F, $9C
L9D68:  .byte $B2, $3F, $BD
L9D6B:  .byte $B2, $3A, $4D
L9D6E:  .byte $A6, $27, $C8
L9D71:  .byte $FE, $7F, $CC
L9D74:  .byte $FE, $3D, $5C
L9D77:  .byte $FF, $3D, $7C
L9D7A:  .byte $00

RBDgnSprts:
L9D7B:  .byte $F3, $3F, $B6     ;Red dragon and blue dragon fireball sprites.
L9D7E:  .byte $F4, $3F, $D6     ;

DgnSprts:
L9D81:  .byte $E6, $34, $00
L9D84:  .byte $EC, $3C, $0C
L9D87:  .byte $E2, $2C, $20
L9D8A:  .byte $E7, $34, $20
L9D8D:  .byte $ED, $3C, $2C
L9D90:  .byte $DD, $1C, $39
L9D93:  .byte $DE, $24, $39
L9D96:  .byte $E3, $2C, $43
L9D99:  .byte $E8, $34, $40
L9D9C:  .byte $DF, $24, $5B
L9D9F:  .byte $F0, $36, $5D
L9DA2:  .byte $E4, $2C, $63
L9DA5:  .byte $E9, $34, $60
L9DA8:  .byte $EE, $3C, $6C
L9DAB:  .byte $E0, $24, $79
L9DAE:  .byte $E5, $2C, $80
L9DB1:  .byte $EA, $34, $80
L9DB4:  .byte $F1, $30, $8E
L9DB7:  .byte $EF, $3C, $8C
L9DBA:  .byte $F2, $3A, $92
L9DBD:  .byte $E1, $23, $99
L9DC0:  .byte $EB, $34, $A0
L9DC3:  .byte $F5, $24, $29
L9DC6:  .byte $F5, $BC, $4C
L9DC9:  .byte $FE, $EB, $94
L9DCC:  .byte $00

;----------------------------------------------------------------------------------------------------

;The following table contains all the treasure chest contents in the game. Each entry is
;4 bytes.  The first byte is the map number.  The second and third bytes are the X and Y
;positions on the map of the treasure, respectively.  The fourth byte is the treasure type.

TreasureTbl:
L9DCD:  .byte MAP_TANTCSTL_GF, $01, $0D, TRSR_GLD2  ;Tant castle, GF at 1,13: 6-13g.
L9DD1:  .byte MAP_TANTCSTL_GF, $01, $0F, TRSR_GLD2  ;Tant castle, GF at 1,15: 6-13g.
L9DD5:  .byte MAP_TANTCSTL_GF, $02, $0E, TRSR_GLD2  ;Tant castle, GF at 2,14: 6-13g.
L9DD9:  .byte MAP_TANTCSTL_GF, $03, $0F, TRSR_GLD2  ;Tant castle, GF at 3,15: 6-13g.
L9DDD:  .byte MAP_THRONEROOM,  $04, $04, TRSR_GLD5  ;Throne room at 4,4: 120g.
L9DE1:  .byte MAP_THRONEROOM,  $05, $04, TRSR_TORCH ;Throne room at 5,4: Torch.
L9DE5:  .byte MAP_THRONEROOM,  $06, $01, TRSR_KEY   ;Throne room at 6,1: Magic key.
L9DE9:  .byte MAP_RIMULDAR,    $18, $17, TRSR_WINGS ;Rumuldar at 24,23: wings.
L9DED:  .byte MAP_GARINHAM,    $08, $05, TRSR_GLD3  ;Garingham at 8,5: 10-17g.
L9DF1:  .byte MAP_GARINHAM,    $08, $06, TRSR_HERB  ;Garingham at 8,6: Herb.
L9DF5:  .byte MAP_GARINHAM,    $09, $05, TRSR_TORCH ;Garingham at 9,5: Torch.
L9DF9:  .byte MAP_DLCSTL_BF,   $0B, $0B, TRSR_HERB  ;Drgnlrd castle BF at 11,11: Herb.
L9DFD:  .byte MAP_DLCSTL_BF,   $0B, $0C, TRSR_GLD4  ;Drgnlrd castle BF at 11,12: 500-755g.
L9E01:  .byte MAP_DLCSTL_BF,   $0B, $0D, TRSR_WINGS ;Drgnlrd castle BF at 11,13: wings.
L9E04:  .byte MAP_DLCSTL_BF,   $0C, $0C, TRSR_KEY   ;Drgnlrd castle BF at 12,12: Key.
L9E09:  .byte MAP_DLCSTL_BF,   $0C, $0D, TRSR_BELT  ;Drgnlrd castle BF at 12,13: Cursed belt.
L9E0D:  .byte MAP_DLCSTL_BF,   $0D, $0D, TRSR_HERB  ;Drgnlrd castle BF at 13,13: Herb.
L9E11:  .byte MAP_TANTCSTL_SL, $04, $05, TRSR_SUN   ;Tant castle, SL at 4,5: Stones of sunlight.
L9E15:  .byte MAP_RAIN,        $03, $04, TRSR_RAIN  ;Staff of rain cave at 3,4: Staff of rain.
L9E19:  .byte MAP_CVGAR_B1,    $0B, $00, TRSR_HERB  ;Gar cave B1 at 11,0: Herb.
L9E1D:  .byte MAP_CVGAR_B1,    $0C, $00, TRSR_GLD1  ;Gar cave B1 at 12,0: 5-20g.
L9E21:  .byte MAP_CVGAR_B1,    $0D, $00, TRSR_GLD2  ;Gar cave B1 at 13,0: 6-13g.
L9E25:  .byte MAP_CVGAR_B3,    $01, $01, TRSR_BELT  ;Gar cave B3 at 1,1: Cursed belt.
L9E29:  .byte MAP_CVGAR_B3,    $0D, $06, TRSR_HARP  ;Gar cave B3 at 13,6: Silver harp.
L9E2D:  .byte MAP_DLCSTL_SL2,  $05, $05, TRSR_ERSD  ;Drgnlrd castle SL2 at 5,5: Erdrick's sword.
L9E31:  .byte MAP_RCKMTN_B2,   $01, $06, TRSR_NCK   ;Rock mtn B2 at 1,6: Death nck or 100-131g.
L9E35:  .byte MAP_RCKMTN_B2,   $03, $02, TRSR_TORCH ;Rock mtn B2 at 3,2: Torch.
L9E39:  .byte MAP_RCKMTN_B2,   $02, $02, TRSR_RING  ;Rock mtn B2 at 2,2: Fighter's ring.
L9E3D:  .byte MAP_RCKMTN_B2,   $0A, $09, TRSR_GLD3  ;Rock mtn B2 at 10,9: 10-17g.
L9E41:  .byte MAP_RCKMTN_B1,   $0D, $05, TRSR_HERB  ;Rock mtn B1 at 13,5: Herb.
L9E45:  .byte MAP_ERDRCK_B2,   $09, $03, TRSR_TBLT  ;Erd cave B2 at 9,3: Erdrick's tablet.

;----------------------------------------------------------------------------------------------------

;The following table contains the stats for the enemies.  There are 16 bytes per enemy.  The
;upper 8 bytes do not appear to be used.  The lower 8 bytes are the following:
;Att  - Enemy's attack power.
;Def  - Enemy's defense power.
;HP   - Enemy's base hit points.
;Spel - Enemy's spells.
;Agi  - Enemy's agility.
;Mdef - Enemy's magical defense.
;Exp  - Experience received from defeating enemy.
;Gld  - Gold received from defeating enemy.

EnStatTblPtr:                   ;Pointer to the table below.
L9E49:  .word EnStatTbl

EnStatTbl:
;Enemy $00-Slime.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9E4B:  .byte $05, $03, $03, $00, $0F, $01, $01, $02, $69, $40, $4A, $4D, $FA, $FA, $FA, $FA

;Enemy $01-Red Slime.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9E5B:  .byte $07, $03, $04, $00, $0F, $01, $01, $03, $69, $40, $4A, $4D, $26, $F8, $69, $FA

;Enemy $02-Drakee.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9E6B:  .byte $09, $06, $06, $00, $0F, $01, $02, $03, $42, $40, $6A, $4E, $FA, $FA, $FA, $FA

;Enemy $03-Ghost.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9E7B:  .byte $0B, $08, $07, $00, $0F, $04, $03, $05, $45, $F8, $4E, $69, $6B, $FA, $FA, $FA

;Enemy $04-Magician.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9E8B:  .byte $0B, $0C, $0D, $02, $00, $01, $04, $0C, $28, $27, $0C, $1B, $0F, $0B, $FA, $FA

;Enemy $05-Magidrakee.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9E9B:  .byte $0E, $0E, $0F, $02, $00, $01, $05, $0C, $3F, $4A, $48, $F8, $42, $40, $6A, $4E

;Enemy $06-Scorpion
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9EAB:  .byte $12, $10, $14, $00, $0F, $01, $06, $10, $0E, $0E, $14, $18, $31, $FA, $FA, $FA

;Enemy $07-Druin.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9EBB:  .byte $14, $12, $16, $00, $0F, $02, $07, $10, $3F, $4E, $47, $F8, $FA, $FA, $FA, $FA

;Enemy $08-Poltergeist
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9ECB:  .byte $12, $14, $17, $03, $00, $06, $08, $12, $3F, $6B, $41, $45, $F8, $4E, $69, $6B

;Enemy $09-Droll.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9EDB:  .byte $18, $18, $19, $00, $0E, $02, $0A, $19, $42, $41, $43, $FA, $FA, $FA, $FA, $FA

;Enemy $0A-Drakeema.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9EEB:  .byte $16, $1A, $14, $92, $20, $06, $0B, $14, $42, $40, $6A, $4E, $4B, $FA, $FA, $FA

;Enemy $0B-Skeleton.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9EFB:  .byte $1C, $16, $1E, $00, $0F, $04, $0B, $1E, $0F, $F8, $0B, $13, $1B, $FA, $FA, $FA

;Enemy $0C-Warlock.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F0B:  .byte $1C, $16, $1E, $12, $31, $02, $0D, $23, $28, $1D, $F8, $0C, $15, $FA, $FA, $FA

;Enemy $0D-Metal Scorpion.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F1B:  .byte $24, $2A, $16, $00, $0F, $02, $0E, $28, $1C, $1B, $22, $14, $18, $31, $FA, $FA

;Enemy $0E-Wolf.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F2B:  .byte $28, $1E, $22, $00, $1F, $02, $10, $32, $31, $4C, $46, $6B, $FA, $FA, $FA, $FA

;Enemy $0F-Wraith.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F3B:  .byte $2C, $22, $24, $90, $70, $04, $11, $3C, $15, $31, $3B, $0C, $FA, $FA, $FA, $FA

;Enemy $10-Metal slime.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F4B:  .byte $0A, $FF, $04, $03, $FF, $F1, $73, $06, $3F, $47, $43, $69, $40, $4A, $4D, $FA

;Enemy $11-Specter.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F5B:  .byte $28, $26, $24, $13, $31, $04, $12, $46, $26, $43, $45, $F8, $4E, $69, $6B, $FA

;Enemy $12-Wolflord.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F6B:  .byte $32, $24, $26, $60, $47, $02, $14, $50, $31, $4C, $46, $6B, $4B, $4D, $43, $FA

;Enemy $13-Druinlord.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F7B:  .byte $2F, $28, $23, $B1, $F0, $04, $14, $55, $3F, $4E, $47, $F8, $41, $4E, $42, $FA

;Enemy $14-Drollmagi.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F8B:  .byte $34, $32, $26, $60, $22, $01, $16, $5A, $42, $41, $43, $3F, $4A, $48, $F8, $FA

;Enemy $15-Wyvern.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9F9B:  .byte $38, $30, $2A, $00, $4F, $02, $18, $64, $6A, $3F, $40, $FA, $FA, $FA, $FA, $FA

;Enemy $16-Rouge Scorpion.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9FAB:  .byte $3C, $5A, $23, $00, $7F, $02, $1A, $6E, $15, $22, $14, $18, $31, $FA, $FA, $FA

;Enemy $17-Wraith Knight.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9FBB:  .byte $44, $38, $2E, $B0, $50, $34, $1C, $78, $15, $31, $3B, $0C, $22, $10, $15, $FA

;Enemy $18-Golem.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9FCB:  .byte $78, $3C, $46, $00, $FF, $F0, $05, $0A, $45, $F8, $4E, $44, $4D, $FA, $FA, $FA

;Enemy $19-Goldman.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9FDB:  .byte $30, $28, $32, $00, $DF, $01, $06, $C8, $45, $F8, $4E, $43, $42, $4B, $46, $FA

;Enemy $1A-Knight.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9FEB:  .byte $4C, $4E, $37, $60, $67, $01, $21, $82, $2F, $34, $0B, $22, $10, $15, $FA, $FA

;Enemy $1B-Magiwyvern.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
L9FFB:  .byte $4E, $44, $3A, $20, $20, $02, $22, $8C, $3F, $4A, $48, $F8, $6A, $3F, $40, $FA

;Enemy $1C-Demon Knight.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA00B:  .byte $4F, $40, $32, $00, $FF, $FF, $25, $96, $0F, $12, $F8, $22, $10, $15, $FA, $FA

;Enemy $1D-Werewolf.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA01B:  .byte $56, $46, $3C, $00, $7F, $07, $28, $9B, $6A, $40, $4E, $31, $4C, $46, $6B, $FA

;Enemy $1E-Green Dragon.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA02B:  .byte $58, $4A, $41, $09, $7F, $22, $2D, $A0, $42, $40, $45, $F8, $46, $FA, $FA, $FA

;Enemy $1F-Starwyvern.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA03B:  .byte $56, $50, $41, $F9, $80, $12, $2B, $A0, $69, $47, $4E, $6A, $3F, $40, $FA, $FA

;Enemy $20-Wizard.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA04B:  .byte $50, $46, $41, $06, $F7, $F2, $32, $A5, $19, $F8, $0B, $28, $1D, $F8, $0C, $FA

;Enemy $21-Axe Knight.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA05B:  .byte $5E, $52, $46, $10, $F3, $11, $36, $A5, $0A, $11, $28, $22, $10, $15, $FA, $FA

;Enemy $22-Blue Dragon.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA06B:  .byte $62, $54, $46, $09, $FF, $72, $3C, $96, $6A, $4E, $69, $42, $40, $45, $F8, $46

;Enemy $23-Stoneman.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA07B:  .byte $64, $28, $A0, $00, $2F, $71, $41, $8C, $69, $6B, $4E, $46, $4B, $46, $FA, $FA

;Enemy $24-Armored Knight.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA08B:  .byte $69, $56, $5A, $F5, $F7, $12, $46, $8C, $15, $1F, $0F, $F8, $29, $22, $10, $15

;Enemy $25-Red Dragon.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA09B:  .byte $78, $5A, $64, $19, $F7, $F2, $64, $8C, $47, $F8, $4E, $69, $42, $40, $45, $F8

;Enemy $26-Dragonlord.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA0AB:  .byte $5A, $4B, $64, $57, $FF, $F0, $00, $00, $31, $3A, $0C, $0E, $0C, $FA, $FA, $FA

;Enemy $27-Dragonlord True Self.
;             Att  Def   HP  Spel Agi  Mdef Exp  Gld   |--------------Unused--------------|
LA0BB:  .byte $8C, $C8, $82, $0E, $FF, $F0, $00, $00, $31, $3A, $0C, $0E, $0C, $FA, $FA, $FA

;----------------------------------------------------------------------------------------------------

;The table below provides the base stats per level.  The bytes represent the following stats:
;Byte 1-Strength, byte 2-Agility, byte 3-Max HP, byte 4-Max MP, byte 5-Healmore and Hurtmore
;spell flags, byte 6-All other spell flags.

LA0CB:  .word BaseStatsTbl

BaseStatsTbl:
LA0CD:  .byte $04, $04, $0F, $00, $00, $00  ;Level 1.
LA0D3:  .byte $05, $04, $16, $00, $00, $00  ;Level 2.
LA0D9:  .byte $07, $06, $18, $05, $00, $01  ;Level 3.
LA0DF:  .byte $07, $08, $1F, $10, $00, $03  ;Level 4.
LA0E5:  .byte $0C, $0A, $23, $14, $00, $03  ;Level 5.
LA0EB:  .byte $10, $0A, $26, $18, $00, $03  ;Level 6.
LA0F1:  .byte $12, $11, $28, $1A, $00, $07  ;Level 7.
LA0F7:  .byte $16, $14, $2E, $1D, $00, $07  ;Level 8.
LA0FD:  .byte $1E, $16, $32, $24, $00, $0F  ;Level 9.
LA103:  .byte $23, $1F, $36, $28, $00, $1F  ;Level 10.
LA109:  .byte $28, $23, $3E, $32, $00, $1F  ;Level 11.
LA10F:  .byte $30, $28, $3F, $3A, $00, $3F  ;Level 12.
LA115:  .byte $34, $30, $46, $40, $00, $7F  ;Level 13.
LA11B:  .byte $3C, $37, $4E, $46, $00, $7F  ;Level 14.
LA121:  .byte $44, $40, $56, $48, $00, $FF  ;Level 15.
LA127:  .byte $48, $46, $5C, $5F, $00, $FF  ;Level 16.
LA12D:  .byte $48, $4E, $64, $64, $01, $FF  ;Level 17.
LA133:  .byte $55, $54, $73, $6C, $01, $FF  ;Level 18.
LA139:  .byte $57, $56, $82, $73, $03, $FF  ;Level 19.
LA13F:  .byte $5C, $58, $8A, $80, $03, $FF  ;Level 20.
LA145:  .byte $5F, $5A, $95, $87, $03, $FF  ;Level 21.
LA14B:  .byte $61, $5A, $9E, $92, $03, $FF  ;Level 22.
LA151:  .byte $63, $5E, $A5, $99, $03, $FF  ;Level 23.
LA157:  .byte $67, $62, $AA, $A1, $03, $FF  ;Level 24.
LA15D:  .byte $71, $64, $AE, $A1, $03, $FF  ;Level 25.
LA163:  .byte $75, $69, $B4, $A8, $03, $FF  ;Level 26.
LA169:  .byte $7D, $6B, $BD, $AF, $03, $FF  ;Level 27.
LA16F:  .byte $82, $73, $C3, $B4, $03, $FF  ;Level 28.
LA175:  .byte $87, $78, $C8, $BE, $03, $FF  ;Level 29.
LA17B:  .byte $8C, $82, $D2, $C8, $03, $FF  ;Level 30.

;----------------------------------------------------------------------------------------------------

;This function appears to not be used.  It is not directly called through any other function
;or the IRQ interrupt.

WndUnusedFunc1:
LA181:  PLA                     ;Pull the value off the stack.

LA182:  CLC                     ;
LA183:  ADC #$01                ;
LA185:  STA GenPtr3ELB          ;Add the value to the pointer.
LA187:  PLA                     ;
LA188:  ADC #$00                ;
LA18A:  STA GenPtr3EUB          ;

LA18C:  PHA                     ;
LA18D:  LDA GenPtr3ELB          ;Push the new pointer value on the stack.
LA18F:  PHA                     ;

LA190:  LDY #$00                ;Use the pointer to retreive a byte from memory.
LA192:  LDA (GenPtr3E),Y        ;

;----------------------------------------------------------------------------------------------------

ShowWindow:
LA194:  JSR DoWindowPrep        ;($AEE1)Do some initial prep before window is displayed.
LA197:  JSR WindowSequence      ;($A19B)run the window building sequence.
LA19A:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WindowSequence:
LA19B:  STA WindowType          ;Save the window type.

LA19E:  LDA WndBuildPhase       ;Indicate first phase of window build is ocurring.
LA1A1:  ORA #$80                ;
LA1A3:  STA WndBuildPhase       ;

LA1A6:  JSR WndConstruct        ;($A1B1)Do the first phase of window construction.
LA1A9:  JSR WndCalcBufAddr      ;($A879)Calculate screen buffer address for data.

LA1AC:  LDA #$40                ;Indicate second phase of window build is ocurring.
LA1AE:  STA WndBuildPhase       ;

WndConstruct:
LA1B1:  JSR GetWndDatPtr        ;($A1D0)Get pointer to window data.
LA1B4:  JSR GetWndConfig        ;($A1E4)Get window configuration data.
LA1B7:  JSR WindowEngine        ;($A230)The guts of the window engine.

LA1BA:  BIT WndBuildPhase       ;Finishing up the first phase?
LA1BD:  BMI WndConstructDone    ;If so, branch to 

LA1BF:  LDA WindowType          ;
LA1C2:  CMP #WND_SPELL1         ;Special case. Don't destroy these windows when done.
LA1C4:  BCC WndConstructDone    ;The spell 1 window is never used and the alphabet
LA1C6:  CMP #WND_ALPHBT         ;window does not disappear when an item is selected.
LA1C8:  BCS WndConstructDone    ;

LA1CA:  BRK                     ;Remove window from screen.
LA1CB:  .byte $05, $07          ;($A7A2)RemoveWindow, bank 0.

WndConstructDone:
LA1CD:  LDA WndSelResults       ;Return window selection results, if any.
LA1CF:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetWndDatPtr:
LA1D0:  LDA #$00                ;First entry in description table is for windows.
LA1D2:  JSR GetDescPtr          ;($A823)Get pointer into description table.

LA1D5:  LDA WindowType          ;*2. Pointer is 2 bytes.
LA1D8:  ASL                     ;

LA1D9:  TAY                     ;
LA1DA:  LDA (DescPtr),Y         ;
LA1DC:  STA WndDatPtrLB         ;Get pointer to desired window data table.
LA1DE:  INY                     ;
LA1DF:  LDA (DescPtr),Y         ;
LA1E1:  STA WndDatPtrUB         ;
LA1E3:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetWndConfig:
LA1E4:  LDY #$00                ;Set pointer at base of data table.
LA1E6:  LDA (WndDatPtr),Y       ;
LA1E8:  STA WndOptions          ;Get window options byte from table.

LA1EB:  INY                     ;
LA1EC:  LDA (WndDatPtr),Y       ;
LA1EE:  STA WndHeightblks       ;Get window height in block from table.
LA1F1:  ASL                     ;
LA1F2:  STA WndHeight           ;Convert window height to tiles,

LA1F5:  INY                     ;
LA1F6:  LDA (WndDatPtr),Y       ;Get window width from table.
LA1F8:  STA WndWidth            ;

LA1FB:  INY                     ;
LA1FC:  LDA (WndDatPtr),Y       ;Get window position from table.
LA1FE:  STA WndPosition         ;
LA201:  PHA                     ;

LA202:  AND #$0F                ;
LA204:  ASL                     ;Extract and save column position nibble.
LA205:  STA WndColPos           ;

LA207:  PLA                     ;
LA208:  AND #$F0                ;
LA20A:  LSR                     ;Extract and save row position nibble.
LA20B:  LSR                     ;
LA20C:  LSR                     ;
LA20D:  STA WndRowPos           ;

LA20F:  INY                     ;MSB set in window options byte indicates its
LA210:  LDA WndOptions          ;a selection window. Is this a selection window?
LA213:  BPL +                   ;If not, branch to skip selection window bytes.

LA215:  LDA (WndDatPtr),Y       ;A selection window.  Get byte containing
LA217:  STA WndColumns          ;column width in tiles.

LA21A:  INY                     ;A selection window. Get byte with cursor
LA21B:  LDA (WndDatPtr),Y       ;home position. X in upper nibble, Y in lower.
LA21D:  STA WndCursorHome       ;

LA220:  INY                     ;
LA221:* BIT WndOptions          ;
LA224:  BVC +                   ;This bit is never set. Branch always.
LA226:  LDA (WndDatPtr),Y       ;
LA228:  STA WndUnused1          ;

LA22B:  INY                     ;
LA22C:* STY WndDatIndex         ;Save index into current window data table.
LA22F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WindowEngine:
LA230:  JSR InitWindowEngine    ;($A248)Initialize variables used by the window engine.

BuildWindowLoop:
LA233:  JSR WndUpdateWrkTile    ;($A26A)Update the working tile pattern.
LA236:  JSR GetNxtWndByte       ;($A2B7)Process next window data byte.
LA239:  JSR JumpToWndFunc       ;($A30A)Use data byte for indirect function jump.
LA23C:  JSR WndShowLine         ;($A5CE)Show window line on the screen.
LA23F:  JSR WndChkFullHeight    ;($A5F9)Check if window build is done.
LA242:  BCC BuildWindowLoop     ;Is window build done? If not, branch to do another row.

LA244:  JSR DoBlinkingCursor    ;($A63D)Show blinking cursor on selection windows.
LA247:  RTS                     ;

;----------------------------------------------------------------------------------------------------

InitWindowEngine:
LA248:  JSR ClearWndLineBuf     ;($A646)Clear window line buffer.
LA24B:  LDA #$FF                ;
LA24D:  STA WndUnused64FB       ;Written to but never accessed.

LA250:  LDA #$00                ;
LA252:  STA WndXPos             ;
LA255:  STA WndYPos             ;Zero out window variables.
LA258:  STA WndThisDesc         ;
LA25B:  STA WndDescHalf         ;
LA25E:  STA WndBuildRow         ;

LA261:  LDX #$0F                ;
LA263:* STA AttribTblBuf,X      ;
LA266:  DEX                     ;Zero out attribute table buffer.
LA267:  BPL -                   ;
LA269:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndUpdateWrkTile:
LA26A:  LDA #TL_BLANK_TILE1     ;Assume working tile will be a blank tile.
LA26C:  STA WorkTile            ;

LA26F:  LDX WndXPos             ;Is position in left most column?
LA272:  BEQ CheckWndRow         ;If so, branch to check row.

LA274:  INX                     ;Is position not at right most column?
LA275:  CPX WndWidth            ;
LA278:  BNE CheckWndBottom      ;If not, branch to check if in bottom rom.

LA27A:  LDX WndYPos             ;In left most column.  In top row?
LA27D:  BEQ WndUpRightCrnr      ;If so, branch to load upper right corner tile.

LA27F:  INX                     ;
LA280:  CPX WndHeight           ;In left most column. in bottom row?
LA283:  BEQ WndBotRightCrnr     ;If so, branch to load lower right corner tile.

LA285:  LDA #TL_RIGHT           ;Border pattern - right border.
LA287:  BNE UpdateWndWrkTile    ;Done. Branch to update working tile and exit.

WndUpRightCrnr:
LA289:  LDA #TL_UPPER_RIGHT     ;Border pattern - upper right corner.
LA28B:  BNE UpdateWndWrkTile    ;Done. Branch to update working tile and exit.

WndBotRightCrnr:
LA28D:  LDA #TL_BOT_RIGHT       ;Border pattern - lower right corner.
LA28F:  BNE UpdateWndWrkTile    ;Done. Branch to update working tile and exit.

CheckWndRow:
LA291:  LDX WndYPos             ;In top row. In left most ccolumn?
LA294:  BEQ WndUpLeftCrnr       ;If so, branch to load upper left corner tile.

LA296:  INX                     ;
LA297:  CPX WndHeight           ;In top row.  In left most column?
LA29A:  BEQ WndBotLeftCrnr      ;If so, branch to load lower left corner tile.
LA29C:  LDA #TL_LEFT            ;Border pattern - left border.
LA29E:  BNE UpdateWndWrkTile    ;Done. Branch to update working tile and exit.

WndUpLeftCrnr:
LA2A0:  LDA #TL_UPPER_LEFT      ;Border pattern - Upper left corner.
LA2A2:  BNE UpdateWndWrkTile    ;Done. Branch to update working tile and exit.

WndBotLeftCrnr:
LA2A4:  LDA #TL_BOT_LEFT        ;Border pattern - Lower left corner.
LA2A6:  BNE UpdateWndWrkTile    ;Done. Branch to update working tile and exit.

CheckWndBottom:
LA2A8:  LDX WndYPos             ;Not in left most or right most columns.
LA2AB:  INX                     ;
LA2AC:  CPX WndHeight           ;In bottom column?
LA2AF:  BNE +                   ;If not, branch to keep blank tile as working tile.
LA2B1:  LDA #TL_BOTTOM          ;Border pattern - bottom border.

UpdateWndWrkTile:
LA2B3:  STA WorkTile            ;Update working tile and exit.
LA2B6:* RTS                     ;

;----------------------------------------------------------------------------------------------------

GetNxtWndByte:
LA2B7:  LDA WorkTile            ;
LA2BA:  CMP #TL_BLANK_TILE1     ;Is current working byte not a blank tile? 
LA2BC:  BNE WorkTileNotBlank    ;if so, branch, nothing to do right now.

LA2BE:  LDA WndOptions          ;Is this a single spaced window?
LA2C1:  AND #$20                ;
LA2C3:  BNE GetNextWndByte      ;If so, branch to get next byte from window data table.

LA2C5:  LDA WndYPos             ;This is a double spaced window.
LA2C8:  LSR                     ;Are we at an even row?
LA2C9:  BCC GetNextWndByte      ;If so, branch to get next data byte, else nothing to do.

LA2CB:  LDA WndBuildRow         ;Is the window being built and on the first block row?
LA2CE:  CMP #$01                ;
LA2D0:  BNE ClearWndCntrlByte   ;If not branch.

LA2D2:  LDA #$00                ;Window just started being built.
LA2D4:  STA WndXPos             ;
LA2D7:  LDX WndYPos             ;Clear x and y position variables.
LA2DA:  INX                     ;
LA2DB:  STX WndHeight           ;Set window height to 1.

LA2DE:  PLA                     ;Remove last return address.
LA2DF:  PLA                     ;
LA2E0:  JMP BuildWindowLoop     ;($A233)continue building the window.

ClearWndCntrlByte:
LA2E3:  LDA #$00                ;Prepare to load a row of empty tiles.
LA2E5:  BEQ SeparateCntrlByte   ;

GetNextWndByte:
LA2E7:  LDY WndDatIndex         ;
LA2EA:  INC WndDatIndex         ;Get next byte from window data table and increment index.
LA2ED:  LDA (WndDatPtr),Y       ;
LA2EF:  BPL GotCharDat          ;Is retreived byte a control byte? if not branch.

SeparateCntrlByte:
LA2F1:  AND #$7F                ;Control byte found.  Discard bit indicating its a control byte.
LA2F3:  PHA                     ;

LA2F4:  AND #$07                ;Extract and save repeat counter bits.
LA2F6:  STA WndParam            ;

LA2F9:  PLA                     ;
LA2FA:  LSR                     ;
LA2FB:  LSR                     ;Shift control bits to lower end of byte and save.
LA2FC:  LSR                     ;
LA2FD:  STA WndCcontrol         ;
LA300:  RTS                     ;

GotCharDat:
LA301:  STA WorkTile            ;Store current byte in working tile variable.

WorkTileNotBlank:
LA304:  LDA #$10                ;
LA306:  STA WndCcontrol         ;Indicate character byte being processed.
LA309:  RTS                     ;

;----------------------------------------------------------------------------------------------------

JumpToWndFunc:
LA30A:  LDA WndCcontrol         ;Use window control byte as pointer
LA30D:  ASL                     ;into window control function table.

LA30E:  TAX                     ;
LA30F:  LDA WndCntrlPtrTbl,X    ;
LA312:  STA WndFcnLB            ;Get function address from table and jump.
LA314:  LDA WndCntrlPtrTbl+1,X  ;
LA317:  STA WndFcnUB            ;
LA319:  JMP (WndFcnPtr)         ;

;----------------------------------------------------------------------------------------------------

WndBlankTiles:
LA31C:  LDA #TL_BLANK_TILE1     ;Prepare to place blank tiles.
LA31E:  STA WorkTile            ;

LA321:  JSR SetCountLength      ;($A600)Calculate the required length of the counter.
LA324:* BIT WndBuildPhase       ;In the second phase of window building?
LA327:  BVS +                   ;If so, branch to skip building buffer.

LA329:  JSR BuildWndLine        ;($A546)Transfer data into window line buffer.
LA32C:  JMP NextBlankTile       ;($A332)Move to next blank tile.

LA32F:* JSR WndNextXPos         ;($A573)Increment x position in current window row.

NextBlankTile:
LA332:  DEC WndCounter          ;More tiles to process?
LA335:  BNE --                  ;If so, branch to do another.
LA337:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndHorzTiles:
LA338:  BIT WndOptions          ;Branch always.  This bit is never set for any of the windows.
LA33B:  BVC DoHorzTiles         ;

LA33D:  LDA #TL_BLANK_TILE1     ;Blank tile.
LA33F:  STA WorkTile            ;
LA342:  JSR BuildWndLine        ;($A546)Transfer data into window line buffer.
LA345:  LDA #TL_TOP2            ;Border pattern - upper border.
LA347:  STA WorkTile            ;
LA34A:  JSR BuildWndLine        ;($A546)Transfer data into window line buffer.

DoHorzTiles:
LA34D:  LDA #TL_TOP1            ;Border pattern - upper border.
LA34F:  STA WorkTile            ;
LA352:  JSR SetCountLength      ;($A600)Calculate the required length of the counter.

HorzTilesLoop:
LA355:  JSR BuildWndLine        ;($A546)Transfer data into window line buffer.
LA358:  DEC WndCounter          ;More tiles to process?
LA35B:  BNE HorzTilesLoop       ;If so, branch to do another.
LA35D:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndHitMgcPoints:
LA35E:  LDA #$03                ;Max number is 3 digits.
LA360:  STA SubBufLength        ;Set buffer length to 3.

LA363:  LDX #HitPoints          ;Prepare to convert hitpoints to BCD.
LA365:  LDA WndParam            ;
LA368:  AND #$04                ;Is bit 2 of parameter byte set?
LA36A:  BEQ +                   ;If so, branch to convert hit points.

LA36C:  LDX #MagicPoints        ;Convert magic points to BCD.

LA36E:* LDY #$01                ;1 byte to convert.
LA370:  JMP WndBinToBCD         ;($A61C)Convert binary word to BCD.

;----------------------------------------------------------------------------------------------------

WndGold:
LA373:  LDA #$05                ;Max number is 5 digits.
LA375:  STA SubBufLength        ;Set buffer length to 5.
LA378:  JSR GoldToBCD           ;($A8BA)Convert player's gold to BCD.
LA37B:  JMP WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.

;----------------------------------------------------------------------------------------------------

WndShowLevel:
LA37E:  LDA WndParam            ;Is parameter not 0? If so, get level from a saved game.
LA381:  BNE WndGetSavedGame     ;Branch to get saved game level.

WndCovertLvl:
LA383:  LDA #$02                ;Set buffer length to 2.
LA385:  STA SubBufLength        ;
LA388:  LDX #DisplayedLevel     ;Load player's level.

LA38A:  LDY #$01                ;1 byte to convert.
LA38C:  JMP WndBinToBCD         ;($A61C)Convert binary word to BCD.

WndGetSavedGame:
LA38F:  JSR WndLoadGameDat      ;($F685)Load selected game into memory.
LA392:  JMP WndCovertLvl        ;($A383)Convert player level to BCD.

;----------------------------------------------------------------------------------------------------

WndShowExp:
LA395:  LDA #$05                ;Set buffer length to 5.
LA397:  STA SubBufLength        ;

LA39A:  LDX #ExpLB              ;Load index for player's experience.

LA39C:  LDY #$02                ;2 bytes to convert.
LA39E:  JMP WndBinToBCD         ;($A61C)Convert binary word to BCD.

;----------------------------------------------------------------------------------------------------

WndShowName:
LA3A1:  LDA WndParam            ;
LA3A4:  CMP #$01                ;Get the full name of the current player.
LA3A6:  BEQ WndGetfullName      ;

LA3A8:  CMP #$04                ;Get the full name of a saved character.
LA3AA:  BEQ WndFullSaved        ;The SaveSelected variable is set before this function is called.

LA3AC:  CMP #$05                ;Get the lower 4 letters of a saved character.
LA3AE:  BCS WndLwr4Saved        ;The SaveSelected variable is set with the WndParam variable.

WndPrepGetLwr:
LA3B0:  LDA #$04                ;Set buffer length to 4.
LA3B2:  STA SubBufLength        ;

LA3B5:  LDX #$00                ;Start at beginning of name registers.
LA3B7:  LDY SubBufLength        ;

WndGetLwrName:
LA3BA:  LDA DispName0,X         ;Load name character and save it in the buffer.
LA3BC:  STA TempBuffer-1,Y      ;
LA3BF:  INX                     ;
LA3C0:  DEY                     ;Have 4 characters been loaded?
LA3C1:  BNE WndGetLwrName       ;If not, branch to get next character.

LA3C3:  JMP WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.

WndGetfullName:
LA3C6:  JSR WndPrepGetLwr       ;($A3B0)Get lower 4 characters of name.

LA3C9:  LDA #$04                ;Set buffer length to 4.
LA3CB:  STA SubBufLength        ;

LA3CE:  LDX #$00                ;Start at beginning of name registers.
LA3D0:  LDY SubBufLength        ;

WndGetUprName:
LA3D3:  LDA DispName4,X         ;Load name character and save it in the buffer.
LA3D6:  STA TempBuffer-1,Y      ;
LA3D9:  INX                     ;
LA3DA:  DEY                     ;Have 4 characters been loaded?
LA3DB:  BNE WndGetUprName       ;If not, branch to get next character.

LA3DD:  JMP WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.

WndLwr4Saved:
LA3E0:  LDA #$04                ;Set buffer length to 4.
LA3E2:  STA SubBufLength        ;

LA3E5:  LDA WndParam            ;
LA3E8:  SEC                     ;Select the desired save game by subtracting 5
LA3E9:  SBC #$05                ;from the WndParam variable.
LA3EB:  STA SaveSelected        ;

LA3EE:  JSR WndLoadGameDat      ;($F685)Load selected game into memory.
LA3F1:  JMP WndPrepGetLwr       ;($A3B0)Get lower 4 letters of saved character's name.

WndFullSaved:
LA3F4:  LDA #$08                ;Set buffer length to 8.
LA3F6:  STA SubBufLength        ;
LA3F9:  JSR WndLoadGameDat      ;($F685)Load selected game into memory.
LA3FC:  JMP WndGetfullName      ;($A3C6)Get full name of saved character.

;----------------------------------------------------------------------------------------------------

WndItemDesc:
LA3FF:  LDA #$09                ;Max buffer length is 9 characters.
LA401:  STA SubBufLength        ;

LA404:  LDA WndParam            ;Is this description for player or shop inventory?
LA407:  CMP #$03                ;
LA409:  BCS WndDoInvItem        ;If so, branch.

LA40B:  LDA WndParam            ;
LA40E:  ADC #$08                ;Add 8 to the description buffer
LA410:  TAX                     ;index and get description byte.
LA411:  LDA DescBuf,X           ;

LA413:  JSR WpnArmrConv         ;($A685)Convert index to proper weapon/armor description byte.
LA416:  JSR LookupDescriptions  ;($A790)Get description from tables.
LA419:  JSR WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.
LA41C:  JMP SecondDescHalf      ;($A7D7)Change to second description half.

WndDoInvItem:
LA41F:  JSR WndGetDescByte      ;($A651)Get byte from description buffer, store in A.
LA422:  JSR DoInvConv           ;($A657)Get inventory description byte.
LA425:  PHA                     ;Push description byte on stack.

LA426:  LDA WndParam            ;Is the player's inventory the target?
LA429:  CMP #$03                ;
LA42B:  BNE WndDescNum          ;If not, branch.

LA42D:  PLA                     ;Place a copy of the description byte in A.
LA42E:  PHA                     ;

LA42F:  CMP #DSC_HERB           ;Is the description byte for herbs?
LA431:  BEQ WndDecDescLength    ;If so, branch.

LA433:  CMP #DSC_KEY            ;Is the description byte for keys?
LA435:  BNE WndDescNum          ;If not, branch.

WndDecDescLength:
LA437:  DEC SubBufLength        ;Decrement length of description buffer.

WndDescNum:
LA43A:  PLA                     ;Put description byte in A.
LA43B:  JSR LookupDescriptions  ;($A790)Get description from tables.
LA43E:  JSR WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.
LA441:  LDA WndDescHalf         ;Is the first description half being worked on?
LA444:  BNE WndDesc2ndHalf      ;If so, branch to work on second description half.

LA446:  LDA WndParam            ;Is this the player's inventory?
LA449:  CMP #$03                ;
LA44B:  BNE WndDesc2ndHalf      ;If not, branch to work on second description half.

LA44D:  LDA WndDescIndex        ;Is the current description byte for herbs?
LA450:  CMP #DSC_HERB           ;
LA452:  BEQ WndNumHerbs         ;If so, branch to get number of herbs in player's inventory.

LA454:  CMP #DSC_KEY            ;Is the current description byte for keys?
LA456:  BEQ WndNumKeys          ;If so, branch.

WndDesc2ndHalf:
LA458:  JMP SecondDescHalf      ;($A7D7)Change to second description half.

WndNumHerbs:
LA45B:  LDA InventoryHerbs      ;Get nuber of herbs player has in inventory.
LA45D:  BNE WndPrepBCD          ;More than 0? If so, branch to convert and display amount.

WndNumKeys:
LA45F:  LDA InventoryKeys       ;Get number of keys player has in inventory.

WndPrepBCD:
LA461:  STA BCDByte0            ;Load value into first BCD conversion byte.
LA463:  LDA #$00                ;
LA465:  STA BCDByte1            ;The other 2 BCD conversion bytes are not used.
LA467:  STA BCDByte2            ;
LA469:  JSR ClearTempBuffer     ;($A776)Write blank tiles to buffer.

LA46C:  LDA #$01                ;Set buffer length to 1.
LA46E:  STA SubBufLength        ;

LA471:  JSR BinWordToBCD_       ;($A625)Convert word to BCD.
LA474:  JSR WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.
LA477:  JMP SecondDescHalf      ;($A7D7)Change to second description half.

;----------------------------------------------------------------------------------------------------

WndOneSpellDesc:
LA47A:  LDA #$09                ;Set max buffer length for description to 9 bytes.
LA47C:  STA SubBufLength        ;
LA47F:  JSR WndGetDescByte      ;($A651)Get byte from description buffer and store in A.

LA482:  SEC                     ;Subtract 1 from description byte to get correct offset.
LA483:  SBC #$01                ;

LA485:  JSR WndGetSpellDesc     ;($A7EB)Get spell description.
LA488:  JSR WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.
LA48B:  INC WndThisDesc         ;Increment pointer to next position in description buffer.
LA48E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndItemCost:
LA48F:  JSR ClearTempBuffer     ;($A776)Write blank tiles to buffer.
LA492:  LDA #$05                ;
LA494:  STA SubBufLength        ;Buffer is max. 5 characters long.

LA497:  LDA #$06                ;WndCostTbl is the table to use for item costs.
LA499:  JSR GetDescPtr          ;($A823)Get pointer into description table.

LA49C:  LDA WndDescIndex        ;Is the description index 0?
LA49F:  BEQ WndCstToLineBuf     ;If so, branch to skip getting item cost.

LA4A1:  ASL                     ;*2. Item costs are 2 bytes.
LA4A2:  TAY                     ;

LA4A3:  LDA (DescPtr),Y         ;Get lower byte of item cost.
LA4A5:  STA BCDByte0            ;

LA4A7:  INY                     ;
LA4A8:  LDA (DescPtr),Y         ;Get middle byte of item cost.
LA4AA:  STA BCDByte1            ;

LA4AC:  LDA #$00                ;Third byte is not used.
LA4AE:  STA BCDByte2            ;

LA4B0:  JSR BinWordToBCD_       ;($A625)Convert word to BCD.

WndCstToLineBuf:
LA4B3:  JMP WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.

;----------------------------------------------------------------------------------------------------

WndVariableHeight:
LA4B6:  LDA #$00                ;Zero out description index.
LA4B8:  STA WndThisDesc         ;
LA4BB:  LDA #$00                ;Start at first half of description.
LA4BD:  STA WndDescHalf         ;

LA4C0:  JSR CalcNumItems        ;($A4CD)Get number of items to display in window.
LA4C3:  STA WndBuildRow         ;Save the number of items.

LA4C6:  LDA WndDatIndex         ;
LA4C9:  STA WndRepeatIndex      ;Set this data index as loop point until all rows are built.
LA4CC:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;When a spell is cast, the description buffer is loaded with pointers for the descriptions
;of spells that the player has.  The buffer is terminated with #$FF.  For example, if the 
;player has the first three spells, the buffer will contain: #$01, #$02, #$03, #$FF.
;If the item list is for an inventory window, The window will start with #$01 and end with #$FF.

CalcNumItems:
LA4CD:  LDX #$01                ;Point to second byte in the item description buffer.
LA4CF:* LDA DescBuf,X           ;
LA4D1:  CMP #ITM_END            ;Has the end been found? If so, branch to move on.
LA4D3:  BEQ NumItemsEnd         ;
LA4D5:  INX                     ;Go to the next index. Has the max been reached?
LA4D6:  BNE -                   ;If not, branch to look at the next byte.

NumItemsEnd:
LA4D8:  DEX                     ;
LA4D9:  LDA DescBuf             ;If buffer starts with 1, return item count unmodified.
LA4DB:  CMP #$01                ;
LA4DD:  BEQ ReturnNumItems      ;

LA4DF:  INX                     ;
LA4E0:  CMP #$02                ;If buffer starts with 2, increment item count.
LA4E2:  BEQ ReturnNumItems      ;

LA4E4:  INX                     ;Increment item count again if anything other than 1 or 2.

ReturnNumItems:
LA4E5:  TXA                     ;Transfer item count to A.
LA4E6:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndBuildVariable:
LA4E7:  LDA WndParam            ;A parameter value of 2 will end the window
LA4EA:  CMP #$02                ;without handling the last line.
LA4EC:  BEQ WndBuildVarDone     ;

LA4EE:  AND #$03                ;Is the parameter anything but 0 or 2?
LA4F0:  BNE WndBuildEnd         ;If so, branch to finish window.

LA4F2:  LDA WndBuildRow         ;Is this the last row?
LA4F5:  BEQ WndBuildVarDone     ;If so, branch to exit. No more repeating.

LA4F7:  DEC WndBuildRow         ;Is this the second to last row?
LA4FA:  BEQ WndBuildVarDone     ;If so, branch to exit. No more repeating.

LA4FC:  LDA WndRepeatIndex      ;Repeat this data index until all rows are built.
LA4FF:  STA WndDatIndex         ;

WndBuildVarDone:
LA502:  RTS                     ;Done building row of variable height window.

;----------------------------------------------------------------------------------------------------

WndBuildEnd:
LA503:  LDA #$00                ;Start at beginning of window row.
LA505:  STA WndXPos             ;
LA508:  STA WndParam            ;Prepare to place blank tiles to end of row.

LA50B:  LDA WndYPos             ;If Y position of window line is even, add 2 to the position
LA50E:  AND #$01                ;and make it the window height.
LA510:  EOR #$01                ;
LA512:  CLC                     ;If Y position of window line is odd, add 1 to the position 
LA513:  ADC #$01                ;and make it the window height.
LA515:  ADC WndYPos             ;
LA518:  STA WndHeight           ;Required to properly form inventory windows.

LA51B:  LSR                     ;
LA51C:  STA WndHeightblks       ;/2. Block height is half the tile height.
LA51F:  LDA WndYPos             ;

LA522:  AND #$01                ;Does the last item only use a single row?
LA524:  BNE WndEndBuild         ;If not, branch to skip a blank line on bottom of window.

WndBlankLine:
LA526:  LDA #TL_LEFT            ;Border pattern - left border.
LA528:  STA WorkTile            ;
LA52B:  JSR BuildWndLine        ;($A546)Transfer data into window line buffer.
LA52E:  JMP WndBlankTiles       ;($A31C)Place blank tiles to end of row.

WndEndBuild:
LA531:  RTS                     ;End building last row.

;----------------------------------------------------------------------------------------------------

WndShowStat:
LA532:  LDX WndParam            ;
LA535:  LDA AttribVarTbl,X      ;Load desired player attribute from table.
LA538:  TAX                     ;

LA539:  LDA #$03                ;Set buffer length to 3.
LA53B:  STA SubBufLength        ;

LA53E:  LDY #$01                ;1 byte to convert.
LA540:  JMP WndBinToBCD         ;($A61C)Convert binary word to BCD.

;----------------------------------------------------------------------------------------------------

WndAddToBuf:
LA543:  JMP BuildWndLine        ;($A546)Transfer data into window line buffer.

;----------------------------------------------------------------------------------------------------

BuildWndLine:
LA546:  LDA WndYPos             ;Is this an even numbered window tile row?
LA549:  AND #$01                ;
LA54B:  BEQ BldLoadWrkTile      ;If so, branch.

LA54D:  LDA WndWidth            ;Odd row.  Prepare to save tile at end of window row.

BldLoadWrkTile:
LA550:  CLC                     ;
LA551:  ADC WndXPos             ;Move to next index in the window line buffer.
LA554:  TAX                     ;

LA555:  LDA WorkTile            ;Store working tile in the window line buffer.
LA558:  STA WndLineBuf,X        ;
LA55B:  JSR WndStorePPUDat      ;($A58B)Store window data byte in PPU buffer.

LA55E:  CMP #TL_LEFT            ;Is this tile a left border or a space?
LA560:  BCS WndNextXPos         ;If so, branch to move to next column.

LA562:  LDA WndLineBuf-1,X      ;Was the last tile a top border tile?
LA565:  CMP #TL_TOP1            ;
LA567:  BNE WndNextXPos         ;If not, branch to move to next column.

LA569:  LDA WndXPos             ;Is this the first column of this row?
LA56C:  BEQ WndNextXPos         ;If so, branch to move to next column.

LA56E:  LDA #TL_TOP2            ;Replace last tile with a top border tile.
LA570:  STA WndLineBuf-1,X      ;

WndNextXPos:
LA573:  INC WndXPos             ;Increment position in window row.
LA576:  LDA WndXPos             ;Still more space in current row?
LA579:  CMP WndWidth            ;If so, branch to exit.
LA57C:  BCC +                   ;

LA57E:  LDX #$01                ;At the end of the row.  Ensure the counter agrees.
LA580:  STX WndCounter          ;

LA583:  DEX                     ;
LA584:  STX WndXPos             ;Move to the beginning of the next row.
LA587:  INC WndYPos             ;
LA58A:* RTS                     ;

;----------------------------------------------------------------------------------------------------

WndStorePPUDat:
LA58B:  PHA                     ;
LA58C:  TXA                     ;
LA58D:  PHA                     ;Save a current copy of X,Y and A on the stack.
LA58E:  TYA                     ;
LA58F:  PHA                     ;

LA590:  BIT WndBuildPhase       ;Is this the second window building phase?
LA593:  BVS WndStorePPUDatEnd   ;If so, skip. Only save data on first phase.

LA595:  JSR PrepPPUAdrCalc      ;($A8AD)Address offset for start of current window row.
LA598:  LDA #$20                ;
LA59A:  STA PPURowBytesLB       ;32 bytes per screen row.
LA59C:  LDA #$00                ;
LA59E:  STA PPURowBytesUB       ;

LA5A0:  LDA WndYPos             ;Multiply 32 by current window row number.
LA5A3:  LDX #PPURowBytesLB      ;
LA5A5:  JSR IndexedMult         ;($A6EB)Calculate winidow row address offset.

LA5A8:  LDA PPURowBytesLB       ;
LA5AA:  CLC                     ;
LA5AB:  ADC WndXPos             ;Add X position of window to calculated value.
LA5AE:  STA PPURowBytesLB       ;Increment upper byte on a carry.
LA5B0:  BCC WndAddOffsetToAddr  ;
LA5B2:  INC PPURowBytesUB       ;

WndAddOffsetToAddr:
LA5B4:  CLC                     ;
LA5B5:  LDA PPURowBytesLB       ;Calculate lower byte of final PPU address.
LA5B7:  ADC PPUAddrLB           ;
LA5B9:  STA PPUAddrLB           ;

LA5BB:  LDA PPURowBytesUB       ;
LA5BD:  ADC PPUAddrUB           ;Calculate upper byte of final PPU address.
LA5BF:  STA PPUAddrUB           ;

LA5C1:  LDY #$00                ;
LA5C3:  LDA WorkTile            ;Store window tile byte in the PPU buffer.
LA5C6:  STA (PPUBufPtr),Y       ;

WndStorePPUDatEnd:
LA5C8:  PLA                     ;
LA5C9:  TAY                     ;
LA5CA:  PLA                     ;Restore X,Y and A from the stack.
LA5CB:  TAX                     ;
LA5CC:  PLA                     ;
LA5CD:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndShowLine:
LA5CE:  LDA WndYPos             ;Is this the beginning of an even numbered line?
LA5D1:  AND #$01                ;
LA5D3:  ORA WndXPos             ;
LA5D6:  BNE WndExitShowLine     ;If not, branch to exit. This row already rendered.

LA5D8:  LDA WndBuildPhase       ;Is this the second phase of window building?
LA5DB:  BMI WndExitShowLine     ;If so, branch to exit. Nothing to do here.

LA5DD:  LDA WndWidth            ;
LA5E0:  LSR                     ;Make a copy of window width and divide by 2.
LA5E1:  ORA #$10                ;Set bit 4. translated to 2(two tile rows ber block row).
LA5E3:  STA WndWidthTemp        ;

LA5E6:  LDA WndPosition         ;Create working copy of current window position.
LA5E9:  STA _WndPosition        ;Window position is represented in blocks.

LA5EC:  CLC                     ;Update window position of next row.
LA5ED:  ADC #$10                ;
LA5EF:  STA WndPosition         ;16 blocks per row.

LA5F2:  JSR WndShowHide         ;($ABC4)Show/hide window on the screen.
LA5F5:  JSR ClearWndLineBuf     ;($A646)Clear window line buffer.

WndExitShowLine:
LA5F8:  RTS                     ;Done showing window line.

;----------------------------------------------------------------------------------------------------

WndChkFullHeight:
LA5F9:  LDA WndYPos             ;Get current window height.
LA5FC:  CMP WndHeight           ;Compare with final window height.
LA5FF:  RTS                     ;

;----------------------------------------------------------------------------------------------------

SetCountLength:
LA600:  LDA WndParam            ;Get parameter data for current window control byte.
LA603:  BNE +                   ;Is it zero?
LA605:  LDA #$FF                ;If so, set counter length to maximum.

LA607:* STA SubBufLength        ;Set counter length.

LA60A:  CLC                     ;
LA60B:  LDA WndWidth            ;Is the current x position beyond the window width?
LA60E:  SBC WndXPos             ;If so, branch to exit.
LA611:  BCC +                   ;

LA613:  CMP SubBufLength        ;Is window row remainder greater than counter length?
LA616:  BCS +                   ;If so, branch to exit.

LA618:  STA SubBufLength        ;Limit counter to remainder of current window row.
LA61B:* RTS                     ;

;----------------------------------------------------------------------------------------------------

WndBinToBCD:
LA61C:  JSR _BinWordToBCD       ;($A622)To binary to BCD conversion.
LA61F:  JMP WndTempToLineBuf    ;($A62B)Transfer value from temp buf to window line buffer.

_BinWordToBCD:
LA622:  JSR GetBinBytesBCD      ;($A741)Load binary word to convert to BCD.

BinWordToBCD_:
LA625:  JSR ConvertToBCD        ;($A753)Convert binary word to BCD.
LA628:  JMP ClearBCDLeadZeros   ;($A764)Remove leading zeros from BCD value.

;----------------------------------------------------------------------------------------------------

WndTempToLineBuf:
LA62B:* LDX SubBufLength        ;Get last unprocessed entry in temp buffer.
LA62E:  LDA TempBuffer-1,X      ;
LA631:  STA WorkTile            ;Load value into work tile byte.

LA634:  JSR BuildWndLine        ;($A546)Transfer data into window line buffer.
LA637:  DEC SubBufLength        ;
LA63A:  BNE -                   ;More bytes to process? If so, branch to process another byte.
LA63C:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoBlinkingCursor:
LA63D:  LDA WndOptions          ;Is the current window a selection window?
LA640:  BPL +                   ;If not, branch to exit.
LA642:  JSR WndDoSelect         ;($A8D1)Do selection window routines.
LA645:* RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearWndLineBuf:
LA646:  LDA #TL_BLANK_TILE1     ;Blank tile index in pattern table.
LA648:  LDX #$3B                ;60 bytes in buffer.

LA64A:* STA WndLineBuf,X        ;Clear window line buffer.
LA64D:  DEX                     ;Has 60 bytes been written?
LA64E:  BPL -                   ;If not, branch to clear more bytes.
LA650:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndGetDescByte:
LA651:  LDX WndThisDesc         ;
LA654:  LDA DescBuf+1,X         ;Get description byte from buffer.
LA656:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoInvConv:
LA657:  PHA                     ;Is player's inventory the target?
LA658:  LDA WndParam            ;
LA65B:  CMP #$03                ;
LA65D:  BEQ PlyrInvConv         ;If so, branch.

LA65F:  CMP #$04                ;Is item shop inventory the target?
LA661:  BEQ ShopInvConv         ;If so, branch.

LA663:  PLA                     ;No other matches. Return description
LA664:  RTS                     ;buffer byte as description byte.

PlyrInvConv:
LA665:  PLA                     ;
LA666:  TAX                     ;Get proper description byte for player's inventory.
LA667:  LDA PlyrInvConvTbl-2,X  ;
LA66A:  RTS                     ;

ShopInvConv:
LA66B:  PLA                     ;Is tool shop inventory the description?
LA66C:  CMP #$13                ;
LA66E:  BCS ToolInvConv         ;If so, branch.

LA670:  TAX                     ;
LA671:  LDA WpnShopConvTbl-2,X  ;Get proper description byte for weapon shop inventory.
LA674:  RTS                     ;

ToolInvConv:
LA675:  SEC                     ;
LA676:  SBC #$13                ;Is this the description byte for the dragon's scale?
LA678:  CMP #$05                ;If so, branch to return dragon's scale description byte.
LA67A:  BEQ DgnSclConv          ;

LA67C:  LSR                     ;
LA67D:  TAX                     ;Get proper description byte for tool shop inventory.
LA67E:  LDA ItmShopConvTbl,X    ;
LA681:  RTS                     ;

DgnSclConv:
LA682:  LDA #DSC_DRGN_SCL       ;Return dragon's scale description byte.
LA684:  RTS                     ;

WpnArmrConv:
LA685:  TAX                     ;
LA686:  LDA WpnArmrConvTbL-9,X  ;Get proper description byte for weapon, armor and shield.
LA689:  RTS                     ;

PlyrInvConvTbl:
LA68A:  .byte DSC_HERB,      DSC_KEY,       DSC_TORCH,     DSC_FRY_WATER
LA68E:  .byte DSC_WINGS,     DSC_DRGN_SCL,  DSC_FRY_FLUTE, DSC_FGHTR_RNG
LA692:  .byte DSC_ERD_TKN,   DSC_GWLN_LOVE, DSC_CRSD_BLT,  DSC_SLVR_HARP
LA696:  .byte DSC_DTH_NCK,   DSC_STN_SUN,   DSC_RN_STAFF,  DSC_RNBW_DRP

ItmShopConvTbl:
LA69A:  .byte DSC_HERB,      DSC_TORCH,     DSC_WINGS,     DSC_DRGN_SCL

WpnShopConvTbl:
LA69E:  .byte DSC_BMB_POLE,  DSC_CLUB,      DSC_CPR_SWD,   DSC_HND_AXE
LA6A2:  .byte DSC_BROAD_SWD, DSC_FLAME_SWD, DSC_ERD_SWD,   DSC_CLOTHES
LA6A6:  .byte DSC_LTHR_ARMR, DSC_CHAIN_ML,  DSC_HALF_PLT,  DSC_FULL_PLT
LA6AA:  .byte DSC_MAG_ARMR,  DSC_ERD_ARMR,  DSC_SM_SHLD,   DSC_LG_SHLD
LA6AE:  .byte DSC_SLVR_SHLD

WpnArmrConvTbL:
LA6AF:  .byte DSC_NONE,      DSC_BMB_POLE,  DSC_CLUB,      DSC_CPR_SWD
LA6B3:  .byte DSC_HND_AXE,   DSC_BROAD_SWD, DSC_FLAME_SWD, DSC_ERD_SWD
LA6B7:  .byte DSC_NONE,      DSC_CLOTHES,   DSC_LTHR_ARMR, DSC_CHAIN_ML
LA6BB:  .byte DSC_HALF_PLT,  DSC_FULL_PLT,  DSC_MAG_ARMR,  DSC_ERD_ARMR
LA6BF:  .byte DSC_NONE,      DSC_SM_SHLD,   DSC_LG_SHLD,   DSC_SLVR_SHLD

;----------------------------------------------------------------------------------------------------

;This table runs the functions associated with the window control bytes.  The control bytes have the
;following format: 1CCCCPPP.  The MSB is always set to indicate it is a control byte.  The next 4
;bits are the index into the table below and dictate which function to run.  The 3 MSBs are the
;parameter bits and do various things for various functions.  Below is a list of the control bits
;and their functions.
;
; Byte range | Function                             | Parameter bits
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;  $80-$87   | Place blank spaces in window.        | Number of blank spaces to place.            |
;            |                                      | 0 = blanks to end of row.                   |
;  $88-$8F   | Place horizontal border in window.   | Number of border tiles to place.            |
;            |                                      | 0 = border tiles to end of row.             |
;  $90-$97   | Show hit points or magic points.     | MSB set-show MP, MSB clear-show HP.         |
;  $98-$9F   | Show player's gold.                  | None.                                       |
;  $A0-$A7   | Show active/saved player's level.    | 0 = current game, 1 = saved game.           |
;  $A8-$AF   | Show player's experience.            | None.                                       |
;  $B0-$B7   | Show active/saved player's name.     | 0 = current player, lower 4 letters.        |
;            |                                      | 1 = current player, full name.              |
;            |                                      | 4 = Saved player, full name.                |
;            |                                      | 5-7 = saved player, lower 4 letters.        |
;  $B8-$BF   | Show item/weapon/armor description.  | 0 = weapon, 1 = armor, 2 = shield,          |
;            |                                      | 3 = player's inventory, 4 = shop inventory. |                                      
;  $C0-$C7   | Show description for selected spell. | None.                                       |
;  $C8-$CF   | Show item cost.                      | None.                                       |
;  $D0-$D7   | Calculate variable window height.    | None.                                       |
;  $D8-$DF   | Show player stat.                    | 0 = strength, 1 = agility, 2 = attack,      |
;            |                                      | 3 = defense,  4 = max HP,  5 = Max MP       |
;  $E0-$E7   | N/A                                  | N/A                                         |
;  $E8-$EF   | Display items in variable window.    | 0 = show items in window, 2 = end window,   |
;            |                                      | 1,3,5,6,7 = Properly end window.            |
;  $F0-$F7   | N/A                                  | N/A                                         |
;  $F8-$FF   | N/A                                  | N/A                                         |
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

WndCntrlPtrTbl:
LA6C3:  .word WndBlankTiles     ;($A31C)Place blank tiles.
LA6C5:  .word WndHorzTiles      ;($A338)Place horizontal border tiles.
LA6C7:  .word WndHitMgcPoints   ;($A35E)Show hit points, magic points.
LA6C9:  .word WndGold           ;($A373)Show gold.
LA6CB:  .word WndShowLevel      ;($A37E)Show current/save game character level.
LA6CD:  .word WndShowExp        ;($A395)Show experience.
LA6CF:  .word WndShowName       ;($A3A1)Show name, 4 or 8 characters.
LA6D1:  .word WndItemDesc       ;($A3FF)Show weapon, armor, shield and item descriptions.
LA6D3:  .word WndOneSpellDesc   ;($A47A)Get spell description for current window row.
LA6D5:  .word WndItemCost       ;($A48F)Get item cost for store inventory windows.
LA6D7:  .word WndVariableHeight ;($A4B6)Calculate spell/inventory window height.
LA6D9:  .word WndShowStat       ;($A532)Show strength, agility max HP, max MP, attack pwr, defense pwr
LA6DB:  .word WndAddToBuf       ;($A543)Non-control character processing.
LA6DD:  .word WndBuildVariable  ;($A4E7)Do all entries in variable height windows.
LA6DF:  .word WndAddToBuf       ;($A543)Non-control character processing.
LA6E1:  .word WndAddToBuf       ;($A543)Non-control character processing.
LA6E3:  .word WndAddToBuf       ;($A543)Non-control character processing.

;----------------------------------------------------------------------------------------------------

AttribVarTbl:
LA6E5:  .byte DisplayedStr,   DisplayedAgi,   DisplayedAttck
LA6E8:  .byte DisplayedDefns, DisplayedMaxHP, DisplayedMaxMP

;----------------------------------------------------------------------------------------------------

IndexedMult:
LA6EB:  STA IndMultByte         ;
LA6EE:  LDA #$00                ;
LA6F0:  STA IndMultNum1         ;
LA6F3:  STA IndMultNum2         ;
LA6F6:* LSR IndMultByte         ;
LA6F9:  BCC +                   ;The indexed register contains the multiplication word.
LA6FB:  LDA GenPtr00LB,X        ;The accumulator contains the multiplication byte.
LA6FD:  CLC                     ;
LA6FE:  ADC IndMultNum1         ;
LA701:  STA IndMultNum1         ;
LA704:  LDA GenPtr00UB,X        ;This function takes 2 bytes and multiplies them together.
LA706:  ADC IndMultNum2         ;The 16-bit result is stored in the registers indexed by X.
LA709:  STA IndMultNum2         ;
LA70C:* ASL GenPtr00LB,X        ;
LA70E:  ROL GenPtr00UB,X        ;
LA710:  LDA IndMultByte         ;
LA713:  BNE --                  ;
LA715:  LDA IndMultNum1         ;
LA718:  STA GenPtr00LB,X        ;
LA71A:  LDA IndMultNum2         ;
LA71D:  STA GenPtr00UB,X        ;
LA71F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetBCDByte:
LA720:  TXA                     ;Save X
LA721:  PHA                     ;

LA722:  LDA #$00                ;
LA724:  STA BCDResult           ;
LA726:  LDX #$18                ;
LA728:* ASL BCDByte0            ;
LA72A:  ROL BCDByte1            ;
LA72C:  ROL BCDByte2            ;
LA72E:  ROL BCDResult           ;
LA730:  SEC                     ;Convert binary number in BCDByte0 to BCDByte2 to BCD.
LA731:  LDA BCDResult           ;
LA733:  SBC #$0A                ;
LA735:  BCC +                   ;
LA737:  STA BCDResult           ;
LA739:  INC BCDByte0            ;
LA73B:* DEX                     ;
LA73C:  BNE --                  ;

LA73E:  PLA                     ;
LA73F:  TAX                     ;Restore X and return.
LA740:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetBinBytesBCD:
LA741:  LDA #$00                ;
LA743:  STA BCDByte2            ;
LA745:  STA BCDByte1            ;Assume only one byte to convert to BCD.
LA747:  LDA GenWrd00LB,X        ;
LA749:  STA BCDByte0            ;Store byte.
LA74B:  DEY                     ;Y counts how many binary bytes to convert.
LA74C:  BEQ +                   ;
LA74E:  LDA GenWrd00UB,X        ;Load second byte to convert if it is present.
LA750:  STA BCDByte1            ;
LA752:* RTS                     ;

;----------------------------------------------------------------------------------------------------

ConvertToBCD:
LA753:  LDY #$00                ;No bytes converted yet.
LA755:* JSR GetBCDByte          ;($A720)Get BCD byte.

LA758:  LDA BCDResult           ;Store result byte in BCD buffer.
LA75A:  STA TempBuffer,Y        ;

LA75D:  INY                     ;Is conversion done?
LA75E:  CPY SubBufLength        ;
LA761:  BNE -                   ;If not, branch to convert another byte.
LA763:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearBCDLeadZeros:
LA764:  LDX SubBufLength        ;Point to end of BCD buffer.
LA767:  DEX                     ;

LA768:* LDA TempBuffer,X        ;Decrement through buffer replacing all
LA76B:  BNE +                   ;leading zeros with blank tiles.
LA76D:  LDA #TL_BLANK_TILE1     ;
LA76F:  STA TempBuffer,X        ;
LA772:  DEX                     ;
LA773:  BNE -                   ;At start of buffer? if not, branch to keep looking.
LA775:* RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearTempBuffer:
LA776:  PHA                     ;
LA777:  TXA                     ;Save A and X.
LA778:  PHA                     ;

LA779:  LDX #$0C                ;
LA77B:  LDA #TL_BLANK_TILE1     ;
LA77D:* STA TempBuffer,X        ;Load the entire 13 bytes of the buffer with blank tiles.
LA780:  DEX                     ;
LA781:  BPL -                   ;

LA783:  PLA                     ;
LA784:  TAX                     ;Restore X and A.
LA785:  PLA                     ;
LA786:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearAndLookup:
LA787:  JSR ClearAndSetBufLen   ;($A7AE)Initialize buffer.

LA78A:  CPX #$FF                ;End of description?
LA78C:  BEQ ++                  ;If so, branch to exit.

LA78E:  LDA DescBuf,X           ;Load description index.

;----------------------------------------------------------------------------------------------------

LookupDescriptions:
LA790:  STA WndDescIndex        ;Save a copy of description table index.
LA793:  JSR ClearAndSetBufLen   ;($A7AE)Initialize buffer.

LA796:  LDA WndDescHalf         ;If on first half of description, load Y with 0.
LA799:  AND #$01                ;
LA79B:  BEQ +                   ;If on second half of description, load Y with 1.
LA79D:  LDA #$01                ;
LA79F:* TAY                     ;

LA7A0:  LDA WndDescIndex        ;
LA7A3:  AND #$3F                ;Remove upper 2 bits of index.
LA7A5:  STA WndDescIndex        ;

LA7A8:  BEQ +                   ;Is index 0? If so exit, no description to display.
LA7AA:  JSR PrepIndexes         ;($A7BD)Prep description index and DescPtrTbl index.
LA7AD:* RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearAndSetBufLen:
LA7AE:  JSR ClearTempBuffer     ;($A776)Write blank tiles to buffer.
LA7B1:  LDA WndDescHalf         ;

LA7B4:  LSR                     ;On first half of description? If so, buffer length
LA7B5:  BCC +                   ;is fine.  Branch to return.

LA7B7:  LDA #$08                ;
LA7B9:  STA SubBufLength        ;If on second half of description, buffer can be 1 byte smaller.
LA7BC:* RTS                     ;

;----------------------------------------------------------------------------------------------------

PrepIndexes:
LA7BD:  PHA                     ;Is item description on second table?
LA7BE:  CMP #$20                ;
LA7C0:  BCC +                   ;If not, branch to use indexes as is.

LA7C2:  PLA                     ;Need to recompute index for ItemNames21TbL.
LA7C3:  SBC #$1F                ;Subtract 31(first table has 31 entries).
LA7C5:  PHA                     ;

LA7C6:  TYA                     ;Need to recompute index into DescPtrTbl.
LA7C7:  CLC                     ;
LA7C8:  ADC #$02                ;Add 2 to index to point to table 2.
LA7CA:  TAY                     ;

LA7CB:* INY                     ;Add 2 to pointer for DescPtrTbl. Index is now ready for use.
LA7CC:  INY                     ;

LA7CD:  TYA                     ;A is used as the index.
LA7CE:  JSR GetDescPtr          ;($A823)Get pointer into description table.

LA7D1:  PLA                     ;Restore index into description table.
LA7D2:  BEQ --                  ;Is index 0? If so, branch to exit. No description.
LA7D4:  JMP WndBuildTempBuf     ;($A842)Place description in temp buffer.

;----------------------------------------------------------------------------------------------------

SecondDescHalf:
LA7D7:  LDA WndDescHalf         ;Get which description half we are currently on.
LA7DA:  EOR #$01                ;
LA7DC:  BNE +                   ;Branch if value is set to 1.

LA7DE:  INC WndThisDesc         ;Set value to 1.

LA7E1:* STA WndDescHalf         ;Store the value of 1 for second half of description.
LA7E4:  RTS                     ;

;----------------------------------------------------------------------------------------------------

SetWorkTile:
LA7E5:  STA WorkTile            ;Set the value in the working tile.
LA7E8:  JMP BuildWndLine        ;($A546)Transfer data into window line buffer.

;----------------------------------------------------------------------------------------------------

WndGetSpellDesc:
LA7EB:  PHA                     ;
LA7EC:  JSR ClearTempBuffer     ;($A776)Write blank tiles to buffer.
LA7EF:  PLA                     ;

LA7F0:  STA DescEntry           ;Store a copy of the description entry byte.
LA7F2:  CMP #$FF                ;Has the end of the buffer been reached?
LA7F4:  BEQ +                   ;If so, branch to exit.

LA7F6:  LDA #$01                ;Spell description table.
LA7F8:  JSR GetDescPtr          ;($A823)Get pointer into description table.
LA7FB:  LDA DescEntry           ;Get index into description table.
LA7FD:  JMP WndBuildTempBuf     ;($A842)Place description in temp buffer.
LA800:* RTS                     ;

;----------------------------------------------------------------------------------------------------

GetEnDescHalf:
LA801:  STA DescEntry           ;Save index into enemy descriptions.

LA803:  LDY #$07                ;Start at index to first half of enemy names.
LA805:  LDA WndDescHalf         ;Get indicator to which name half to retreive.

LA808:  LSR                     ;Do we want the first half of the name?
LA809:  BCC +                   ;If so branch.

LA80B:  INY                     ;We want second half of the enemy name. Increment index.

LA80C:* LDA DescEntry           ;
LA80E:  PHA                     ;
LA80F:  CMP #$33                ;This part of the code should never be executed because
LA811:  BCC +                   ;it is incrementing to another table entry for enemy
LA813:  PLA                     ;numbers greater than 51 but there are only 40 different
LA814:  SBC #$32                ;enemies in the entire game.
LA816:  PHA                     ;
LA817:  INY                     ;

LA818:* TYA                     ;A now contains entry number into DescPtrTbl.
LA819:  JSR GetDescPtr          ;($A823)Get pointer into description table.
LA81C:  JSR ClearTempBuffer     ;($A776)Write blank tiles to buffer.
LA81F:  PLA
LA820:  JMP WndBuildTempBuf     ;($A842)Place description in temp buffer.

;----------------------------------------------------------------------------------------------------

GetDescPtr:
LA823:  ASL                     ;*2. words in table are two bytes.
LA824:  TAX                     ;

LA825:  LDA DescPtrTbl,X        ;
LA828:  STA DescPtrLB           ;Get desired address from table below.
LA82A:  LDA DescPtrTbl+1,X      ;Save in description pointer.
LA82D:  STA DescPtrUB           ;
LA82F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DescPtrTbl:
LA830:  .word WndwDataPtrTbl    ;($AF6C)Pointers to window type data bytes. 
LA832:  .word SpellNameTbl      ;($BE56)Spell names.
LA834:  .word ItemNames11TbL    ;($BAB7)Item descriptions, first table, first half.
LA836:  .word ItemNames12TbL    ;($BBB7)Item descriptions, first table, second half.
LA838:  .word ItemNames21TbL    ;($BB8F)Item descriptions, second table, first half.
LA83A:  .word ItemNames22TbL    ;($BC4F)Item descriptions, second table, second half.
LA83C:  .word WndCostTblPtr     ;($BE0E)Item costs, used in shop inventory windows.
LA83E:  .word EnNames1Tbl       ;($BC70)Enemy names, first half.
LA840:  .word EnNames2Tbl       ;($BDA2)Enemy names, second half.

;----------------------------------------------------------------------------------------------------

WndBuildTempBuf:
LA842:  TAX                     ;Transfer description table index to X.
LA843:  LDY #$00                ;

DescSrchOuterLoop:
LA845:  DEX                     ;Subtract 1 as 0 was used to for no description.
LA846:  BEQ BaseDescFound       ;At proper index? If so, no more searching required.

DescSrchInnerLoop:
LA848:  LDA (DescPtr),Y         ;Get next byte in ROM.
LA84A:  CMP #$FF                ;Is it an end of description marker?
LA84C:  BEQ NextDescription     ;If so, branch to update pointers.

ThisDescription:
LA84E:  INY                     ;Increment index.
LA84F:  BNE DescSrchInnerLoop   ;Is it 0?
LA851:  INC DescPtrUB           ;If so, increment upper byte.
LA853:  BNE DescSrchInnerLoop   ;Should always branch.

NextDescription:
LA855:  INY                     ;Increment index.
LA856:  BNE DescSrchOuterLoop   ;Is it 0?
LA858:  INC DescPtrUB           ;If so, increment upper byte.
LA85A:  BNE DescSrchOuterLoop   ;Should always branch.

BaseDescFound:
LA85C:* TYA                     ;
LA85D:  CLC                     ;
LA85E:  ADC DescPtrLB           ;Set description pointer to base of the description.
LA860:  STA DescPtrLB           ;
LA862:  BCC +                   ;
LA864:  INC DescPtrUB           ;

LA866:* LDY #$00                ;Zero out current index into description.
LA868:  LDX SubBufLength        ;Load buffer length.

LoadDescLoop:
LA86B:  LDA (DescPtr),Y         ;Get next byte in description.
LA86D:  CMP #$FF                ;Is it the end of description marker?
LA86F:  BEQ +                   ;If so, branch to end.

LA871:  STA TempBuffer-1,X      ;Store byte in the temp buffer.
LA874:  INY                     ;Increment ROM pointer.
LA875:  DEX                     ;Decrement RAM pointer.
LA876:  BNE LoadDescLoop        ;Is temp buffer full? If not, branch to get more.
LA878:* RTS                     ;

;----------------------------------------------------------------------------------------------------

WndCalcBufAddr:
LA879:  JSR PrepPPUAdrCalc      ;($A8AD)Prepare and calculate PPU address.

LA87C:  LDA WndHeight           ;Get window height in tiles.  Need to replace any end of text
LA87F:  STA RowsRemaining       ;control characters with no-ops so window can be processed properly.

CntrlCharSwapRow:
LA881:  LDY #$00                ;Start at beginning of window tile row.

LA883:  LDA WndWidth            ;Set remaining columns to window width.
LA886:  STA _ColsRemaining      ;

CntrlCharSwapCol:
LA888:  LDA (PPUBufPtr),Y       ;Was the end text control character found?
LA88A:  CMP #TXT_END2           ;
LA88C:  BNE CntrlNextCol        ;If not, branch to check next window character.

LA88E:  LDA #TXT_NOP            ;Replace text control character with a no-op.
LA890:  STA (PPUBufPtr),Y       ;

CntrlNextCol:
LA892:  INY                     ;Move to next columns.
LA893:  DEC _ColsRemaining      ;was that the last column?
LA895:  BNE CntrlCharSwapCol    ;If not, branch to move to next column.

LA897:  CLC                     ;
LA898:  LDA PPUAddrLB           ;
LA89A:  ADC #$20                ;Move buffer address to next row.
LA89C:  STA PPUAddrLB           ;Handle carry, if necessary.
LA89E:  BCC CntrlNextRow        ;
LA8A0:  INC PPUAddrUB           ;

CntrlNextRow:
LA8A2:  DEC RowsRemaining       ;Are there more rows to check?
LA8A4:  BNE CntrlCharSwapRow    ;If so, branch.

LA8A6:  BRK                     ;Update sprites.
LA8A7:  .byte $04, $07          ;($B6DA)DoSprites, bank 0.

LA8A9:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LA8AC:  RTS                     ;

PrepPPUAdrCalc:
LA8AD:  LDA WndColPos           ;Convert column tile position into block position.
LA8AF:  LSR                     ;
LA8B0:  STA XPosFromLeft        ;

LA8B2:  LDA WndRowPos           ;Convert row tile position into block position.
LA8B4:  LSR                     ;
LA8B5:  STA YPosFromTop         ;
LA8B7:  JMP CalcPPUBufAddr      ;($C596)Calculate PPU address.

;----------------------------------------------------------------------------------------------------

GoldToBCD:
LA8BA:  LDA #$05                ;Set results buffer length to 5.
LA8BC:  STA SubBufLength        ;

LA8BF:  LDA GoldLB              ;
LA8C1:  STA BCDByte0            ;
LA8C3:  LDA GoldUB              ;Transfer gold value to conversion variables.
LA8C5:  STA BCDByte1            ;
LA8C7:  LDA #$00                ;
LA8C9:  STA BCDByte2            ;

LA8CB:  JSR ConvertToBCD        ;($A753)Convert gold to BCD value.
LA8CE:  JMP ClearBCDLeadZeros   ;($A764)Remove leading zeros from BCD value.

;----------------------------------------------------------------------------------------------------

WndDoSelect:
LA8D1:  LDA WndBuildPhase       ;Is the window in the first build phase?
LA8D4:  BMI WndDoSelectExit     ;If so, branch to exit.

LA8D6:  JSR WndInitSelect       ;($A918)Initialize window selection variables.

LA8D9:  LDA #IN_RIGHT           ;Disable right button retrigger.
LA8DB:  STA WndBtnRetrig        ;
LA8DE:  STA JoypadBtns          ;Initialize joypad presses to a known value.

_WndDoSelectLoop:
LA8E0:  JSR WndDoSelectLoop     ;($A8E4)Loop while selection window is active.

WndDoSelectExit:
LA8E3:  RTS                     ;Exit window selection and return results.

WndDoSelectLoop:
LA8E4:  JSR WndGetButtons       ;($A8ED)Keep track of player button presses.
LA8E7:  JSR WndProcessInput     ;($A992)Update window based on user input.
LA8EA:  JMP WndDoSelectLoop     ;($A8E4)Loop while selection window is active.

WndGetButtons:
LA8ED:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LA8F0:  JSR UpdateCursorGFX     ;($A96C)Update cursor graphic in selection window.

LA8F3:  LDA JoypadBtns          ;Are any buttons being pressed?
LA8F5:  BEQ SetRetrigger        ;If not, branch to reset the retrigger.

LA8F7:  LDA FrameCounter        ;Reset the retrigger every 15 frames.
LA8F9:  AND #$0F                ;Is it time to reset the retrigger?
LA8FB:  BNE NoRetrigger         ;If not, branch.

SetRetrigger:
LA8FD:  STA WndBtnRetrig        ;Clear all bits. Retrigger.

NoRetrigger:
LA900:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LA903:  LDA WndBtnRetrig        ;Is there a retrigger event waiting to timeout?
LA906:  BNE WndGetButtons       ;($A8ED)If so, branch to get any button presses.

LA908:  LDA WndBtnRetrig        ;
LA90B:  AND JoypadBtns          ;Remove any button status bits that have chanegd.
LA90D:  STA WndBtnRetrig        ;

LA910:  EOR JoypadBtns          ;Have any buttons changed?
LA912:  STA WndBtnPresses       ;
LA915:  BEQ WndGetButtons       ;($A8ED)If so, branch to get button presses.
LA917:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndInitSelect:
LA918:  LDA #$00                ;
LA91A:  STA WndCol              ;
LA91C:  STA WndRow              ;
LA91E:  STA WndSelResults       ;Clear various window selection control registers.
LA920:  STA WndCursorXPos       ;
LA923:  STA WndCursorYPos       ;
LA926:  STA WndBtnRetrig        ;

LA929:  LDA WndColumns          ;
LA92C:  LSR                     ;Use WndColumns to determine how many columns there
LA92D:  LSR                     ;should be in multi column windows.  The only windows
LA92E:  LSR                     ;with multiple columns are the command windows and
LA92F:  LSR                     ;the alphabet window.  The command windows have 2
LA930:  TAX                     ;columns while the alphabet window has 11.
LA931:  LDA NumColTbl,X         ;
LA934:  STA WndSelNumCols       ;

LA937:  LDA WindowType          ;Is this a message speed window?
LA93A:  CMP #WND_MSG_SPEED      ;
LA93C:  BNE WndSetCrsrHome      ;If not, branch to skip setting message speed.

LA93E:  LDX MessageSpeed        ;Use current message speed to set the cursor in the window.
LA940:  STX WndRow              ;Set the window row the same as the message speed(0,1 or 2).
LA942:  TXA                     ;
LA943:  ASL                     ;Multiply by 2 and set the Y cursor position.
LA944:  STA WndCursorYPos       ;

WndSetCrsrHome:
LA947:  LDA WndCursorHome       ;Save a copy of the cursor X,Y home position.
LA94A:  PHA                     ;

LA94B:  AND #$0F                ;Save a copy of the home X coord but it is never used.
LA94D:  STA WndUnused64F4       ;

LA950:  CLC                     ;
LA951:  ADC WndCursorXPos       ;Convert home X coord from window coord to screen coord.
LA954:  STA WndCursorXPos       ;

LA957:  PLA                     ;Restore cursor X,Y home position.
LA958:  AND #$F0                ;
LA95A:  LSR                     ;
LA95B:  LSR                     ;Keep only Y coord and shift to lower nibble.
LA95C:  LSR                     ;
LA95D:  LSR                     ;
LA95E:  STA WndCursorYHome      ;This is the Y coord home position for the cursor.

LA961:  ADC WndCursorYPos       ;Convert home Y coord from window coord to screen coord.
LA964:  STA WndCursorYPos       ;

LA967:  LDA #$05                ;
LA969:  STA FrameCounter        ;Set framee counter to ensure cursor is initially visible.
LA96B:  RTS                     ;

;----------------------------------------------------------------------------------------------------

UpdateCursorGFX:
LA96C:  LDX #TL_BLANK_TILE1     ;Set cursor tile as blank tile.

LA96E:  LDA FrameCounter        ;Get lower 5 bits of the frame counter.
LA970:  AND #$1F                ;

LA972:  CMP #$10                ;Is count halfway through?
LA974:  BCS SetCursorTile       ;If not, load cursor tile as right pointing arrow.

ArrowCursorGFX:
LA976:  LDX #TL_RIGHT_ARROW     ;Set cursor tile as right pointing arrow.

SetCursorTile:
LA978:  STX PPUDataByte         ;Store cursor tile.

LA97A:  LDA WndColPos           ;
LA97C:  CLC                     ;Calculate cursor X position on screen, in tiles.
LA97D:  ADC WndCursorXPos       ;
LA980:  STA ScrnTxtXCoord       ;

LA983:  LDA WndRowPos           ;
LA985:  CLC                     ;Calculate cursor Y position on screen, in tiles.
LA986:  ADC WndCursorYPos       ;
LA989:  STA ScrnTxtYCoord       ;

LA98C:  JSR WndCalcPPUAddr      ;($ADC0)Calculate PPU address for window/text byte.
LA98F:  JMP AddPPUBufEntry      ;($C690)Add data to PPU buffer.

;----------------------------------------------------------------------------------------------------

WndProcessInput:
LA992:  LDA WndBtnPresses       ;Get any buttons that have been pressed by the player.

LA995:  LSR                     ;Has the A button been pressed?
LA996:  BCS WndAPressed         ;If so, branch.

LA998:  LSR                     ;Has the B button been pressed?
LA999:  BCS WndBPressed         ;If so, branch.

LA99B:  LSR                     ;Skip select and start while in selection window.
LA99C:  LSR                     ;

LA99D:  LSR                     ;Has the up button been pressed?
LA99E:  BCS WndUpPressed        ;If so, branch.

LA9A0:  LSR                     ;Has the down button been pressed?
LA9A1:  BCS WndDownPressed      ;If so, branch.

LA9A3:  LSR                     ;Has the left button been pressed?
LA9A4:  BCS WndLeftPressed      ;If so, branch.

LA9A6:  LSR                     ;Has no button been pressed?
LA9A7:  BCC WndEndUpPressed     ;If so, branch to exit.

LA9A9:  JMP WndRightPressed     ;($AAC8)Process right button press.

WndLeftPressed:
LA9AC:  JMP WndDoLeftPressed    ;($AA67)Process left button press.

;----------------------------------------------------------------------------------------------------

WndAPressed:
LA9AF:  LDA #IN_A               ;Disable A button retrigger.
LA9B1:  STA WndBtnRetrig        ;
LA9B4:  JSR WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

LA9B7:  LDA #SFX_MENU_BTN       ;Menu button SFX.
LA9B9:  BRK                     ;
LA9BA:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LA9BC:  LDA WndCol              ;
LA9BE:  STA _WndCol             ;Make a working copy of the cursor column and row.
LA9C0:  LDA WndRow              ;
LA9C2:  STA _WndRow             ;

LA9C4:  JSR WndCalcSelResult    ;($AB64)Calculate selection result based on col and row.

LA9C7:  PLA                     ;Pull last return address off of stack.
LA9C8:  PLA                     ;

LA9C9:  LDA WndSelResults       ;Load the selection results into A.
LA9CB:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndBPressed:
LA9CC:  LDA #IN_B               ;Disable B button retrigger.
LA9CE:  STA WndBtnRetrig        ;
LA9D1:  JSR WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

LA9D4:  PLA                     ;Pull last return address off of stack.
LA9D5:  PLA                     ;

LA9D6:  LDA #WND_ABORT          ;Load abort indicator into A
LA9D8:  STA WndSelResults       ;Store abort indicator in the selection results.
LA9DA:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndUpPressed:
LA9DB:  LDA #IN_UP              ;Disable up button retrigger.
LA9DD:  STA WndBtnRetrig        ;

LA9E0:  LDA WndRow              ;Is cursor already on the top row?
LA9E2:  BEQ WndEndUpPressed     ;If so, branch to exit.  Nothing to do.

LA9E4:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.

LA9E7:  LDA WindowType          ;Is this the SPELL1 window?
LA9EA:  CMP #WND_SPELL1         ;Not used in the game.
LA9EC:  BEQ WndSpell1Up         ;If so, branch for special cursor update.

LA9EE:  JSR WndMoveCursorUp     ;($ABB2)Move cursor position up 1 row.
LA9F1:  JSR WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

WndEndUpPressed:
LA9F4:  RTS                     ;Up button press processed. Return.

WndSpell1Up:
LA9F5:  LDA #$03                ;
LA9F7:  STA WndCursorXPos       ;Move cursor tile position to 3,2.
LA9FA:  LDA #$02                ;
LA9FC:  STA WndCursorYPos       ;

LA9FF:  LDA #$00                ;Set cursor row position to 0.
LAA01:  STA WndRow              ;
LAA03:  JMP WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

;----------------------------------------------------------------------------------------------------

WndDownPressed:
LAA06:  LDA #IN_DOWN            ;Disable down button retrigger.
LAA08:  STA WndBtnRetrig        ;

LAA0B:  LDA WindowType          ;Is this the SPELL1 window?
LAA0E:  CMP #WND_SPELL1         ;Not used in the game.
LAA10:  BEQ WndSpell1Down       ;If so, branch for special cursor update.

LAA12:  CMP #WND_MSG_SPEED      ;Is this the message speed window?
LAA14:  BNE WndDownCont1        ;If not, branch to continue processing.

LAA16:  LDA WndRow              ;Is thos the last row of the message speed window?
LAA18:  CMP #$02                ;
LAA1A:  BEQ WndDownDone         ;If so, branch to exit. Cannot go down anymore.

WndDownCont1:
LAA1C:  SEC                     ;Get window height.
LAA1D:  LDA WndHeight           ;Subtract 3 to get bottom most row the cursor can be on.
LAA20:  SBC #$03                ;
LAA22:  LSR                     ;/2. Cursor moves 2 tile rows when going up or down.

LAA23:  CMP WndRow              ;Is the cursor on the bottom row?
LAA25:  BEQ WndDownDone         ;If so, branch to exit. Cannot go down anymore.

LAA27:  JSR WndClearCursor      ;($AB30)Blank out cursor tile as it has moved.

LAA2A:  LDA WindowType          ;Is this the alphabet window?
LAA2D:  CMP #WND_ALPHBT         ;
LAA2F:  BNE WndDownCont2        ;If not, branch to continue processing.

LAA31:  JSR WndSpclMoveCrsr     ;($AB3F)Move cursor to next position if next row is bottom.

WndDownCont2:
LAA34:  LDA WndCursorYPos       ;Is the cursor Y cord at the top?
LAA37:  BNE WndDownCont3        ;If not, branch to continue processing.

LAA39:  LDA WndCursorYHome      ;Set cursor Y coord to the Y home position.
LAA3C:  STA WndCursorYPos       ;Is cursor Y position at 0?
LAA3F:  BNE WndDownUpdate       ;If not, branch.

WndDownCont3:
LAA41:  CLC                     ;
LAA42:  ADC #$02                ;Update cursor Y position and cursor row.
LAA44:  STA WndCursorYPos       ;
LAA47:  INC WndRow              ;

WndDownUpdate:
LAA49:  JSR WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

WndDownDone:
LAA4C:  RTS                     ;Down button press processed. Return.

WndSpell1Down:
LAA4D:  LDA WndRow              ;Is this the last row(not used)?
LAA4F:  CMP #$02                ;
LAA51:  BEQ WndDownDone         ;If so, branch to exit.

LAA53:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.
LAA56:  LDA #$02                ;
LAA58:  STA WndRow              ;Update window row.

LAA5A:  LDA #$03                ;Update cursor X pos.
LAA5C:  STA WndCursorXPos       ;

LAA5F:  LDA #$06                ;Update cursor Y pos.
LAA61:  STA WndCursorYPos       ;
LAA64:  JMP WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

;----------------------------------------------------------------------------------------------------

WndDoLeftPressed:
LAA67:  LDA #IN_LEFT            ;Disable left button retrigger.
LAA69:  STA WndBtnRetrig        ;

LAA6C:  LDA WindowType          ;Is this the SPELL1 window?
LAA6F:  CMP #WND_SPELL1         ;Not used in the game.
LAA71:  BEQ WndSpell1Left       ;If so, branch for special cursor update.

LAA73:  LDA WndCol              ;Is cursor already at the far left?
LAA75:  BEQ WndLeftDone         ;If so, branch to exit. Cannot go left anymore.

LAA77:  LDA WindowType          ;Is this the alphabet window?
LAA7A:  CMP #WND_ALPHBT         ;
LAA7C:  BNE WndLeftUpdate       ;If not, branch to continue processing.

LAA7E:  LDA WndRow              ;Is this the bottom row of the alphabet window?
LAA80:  CMP #$05                ;
LAA82:  BNE WndLeftUpdate       ;If not, branch to continue processing.

LAA84:  LDA WndCol              ;Is the cursor pointing to END?
LAA86:  CMP #$09                ;
LAA88:  BNE WndLeftUpdate       ;If not, branch to continue processing.

LAA8A:  LDA #$06                ;Move cursor to point to BACK.
LAA8C:  STA WndCol              ;
LAA8E:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.

LAA91:  LDA #$0D                ;Prepare new cursor X position.
LAA93:  BNE WndLeftUpdtFinish   ;

WndLeftUpdate:
LAA95:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.
LAA98:  DEC WndCol              ;Decrement cursor column position.

LAA9A:  LDA WndColumns          ;
LAA9D:  AND #$0F                ;Get number of tiles per column.
LAA9F:  STA WndColLB            ;

LAAA1:  LDA WndCursorXPos       ;
LAAA4:  SEC                     ;Subtract tiles to get final cursor X position.
LAAA5:  SBC WndColLB            ;

WndLeftUpdtFinish:
LAAA7:  STA WndCursorXPos       ;Update cursor X position.
LAAAA:  JSR WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

WndLeftDone:
LAAAD:  RTS                     ;Left button press processed. Return.

WndSpell1Left:
LAAAE:  LDA WndRow              ;Is this the 4th row in the SPELL1 window?
LAAB0:  CMP #$03                ;Not used in game.
LAAB2:  BEQ WndLeftDone         ;If so, branch to exit.

LAAB4:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.
LAAB7:  LDA #$03                ;
LAAB9:  STA WndRow              ;Update cursor row.

LAABB:  LDA #$01                ;Update cursor X position.          
LAABD:  STA WndCursorXPos       ;

LAAC0:  LDA #$04                ;Update cursor Y position.
LAAC2:  STA WndCursorYPos       ;
LAAC5:  JMP WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

;----------------------------------------------------------------------------------------------------

WndRightPressed:
LAAC8:  LDA #IN_RIGHT           ;Disable right button retrigger.
LAACA:  STA WndBtnRetrig        ;

LAACD:  LDA WindowType          ;Is this the SPELL1 window?
LAAD0:  CMP #WND_SPELL1         ;Not used in the game.
LAAD2:  BEQ WndSpell1Right      ;If so, branch for special cursor update.

LAAD4:  LDA WndColumns          ;Is there only a single column in this window?
LAAD7:  BEQ WndEndRghtPressed   ;If so, branch to exit. Nothing to process.

LAAD9:  LDA WindowType          ;Is this the alphabet window?
LAADC:  CMP #WND_ALPHBT         ;
LAADE:  BNE WndRightCont1       ;If not, branch to continue processing.

LAAE0:  LDA WndRow              ;Is this the bottom row of the alphabet window?
LAAE2:  CMP #$05                ;
LAAE4:  BNE WndRightCont1       ;If not, branch to continue processing.

LAAE6:  LDA WndCol              ;Is the cursor pointing to BACK or END?
LAAE8:  CMP #$06                ;
LAAEA:  BCC WndRightCont1       ;If not, branch to continue processing.

LAAEC:  BNE WndEndRghtPressed   ;Is the cursor pointing to BACK? If not, must be END. Done.

LAAEE:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.
LAAF1:  LDA #$09                ;
LAAF3:  STA WndCol              ;Move cursor to point to END.

LAAF5:  LDA #$13                ;Prepare new cursor X position.
LAAF7:  BNE WndRightUpdtFinish  ;

WndRightCont1:
LAAF9:  LDX WndSelNumCols       ;Is cursor in right most column?
LAAFC:  DEX                     ;
LAAFD:  CPX WndCol              ;
LAAFF:  BEQ WndEndRghtPressed   ;If so, branch to exit. Nothing to process.

LAB01:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.
LAB04:  INC WndCol              ;Increment cursor column position.

LAB06:  LDA WndColumns          ;Get number of tiles per column for this window.
LAB09:  AND #$0F                ;

LAB0B:  CLC                     ;Use tiles per column from above to update cursor X pos.
LAB0C:  ADC WndCursorXPos       ;

WndRightUpdtFinish:
LAB0F:  STA WndCursorXPos       ;Update cursor X position.
LAB12:  JSR WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

WndEndRghtPressed:
LAB15:  RTS                     ;Right button press processed. Return.

WndSpell1Right:
LAB16:  LDA WndRow              ;Is this the 2nd row in the SPELL1 window?
LAB18:  CMP #$01                ;Not used in game.
LAB1A:  BEQ WndEndRghtPressed   ;If so, branch to exit.

LAB1C:  JSR WndClearCursor      ;($AB30)Blank out cursor tile.
LAB1F:  LDA #$01                ;
LAB21:  STA WndRow              ;Update cursor row.

LAB23:  LDA #$07                ;Update cursor X position.
LAB25:  STA WndCursorXPos       ;

LAB28:  LDA #$04                ;Update cursor Y position.
LAB2A:  STA WndCursorYPos       ;
LAB2D:  JMP WndUpdateCrsrPos    ;($AB35)Update cursor position on screen.

;----------------------------------------------------------------------------------------------------

WndClearCursor:
LAB30:  LDX #TL_BLANK_TILE1     ;Replace cursor with a blank tile.
LAB32:  JMP SetCursorTile       ;($A978)Set cursor tile to blank tile.

;----------------------------------------------------------------------------------------------------

WndUpdateCrsrPos:
LAB35:  LDA #$05                ;Set cursor to arrow tile for 10 frames.
LAB37:  STA FrameCounter        ;
LAB39:  JSR ArrowCursorGFX      ;($A976)Set cursor graphic to the arrow.
LAB3C:  JMP WaitForNMI          ;($FF74)Wait for VBlank interrupt.

;----------------------------------------------------------------------------------------------------

WndSpclMoveCrsr:
LAB3F:  LDA WndRow              ;Is this the second to bottom row?
LAB41:  CMP #$04                ;
LAB43:  BNE WndEndUpdateCrsr    ;If not, branch to exit.

LAB45:  LDA WndCol              ;Is this the 8th column?
LAB47:  CMP #$07                ;
LAB49:  BEQ WndSetCrsrBack      ;If so, branch to set cursor to BACK selection.

LAB4B:  CMP #$08                ;is this the 9th, 10th or 11th column?
LAB4D:  BCC WndEndUpdateCrsr    ;If so, branch to set cursor to END selection.

WndSetCrsrEnd:
LAB4F:  LDA #$09                ;Set cursor to END selection in alphabet window.
LAB51:  STA WndCol              ;
LAB53:  LDA #$13                ;
LAB55:  STA WndCursorXPos       ;
LAB58:  BNE WndEndUpdateCrsr    ;Branch always.

WndSetCrsrBack:
LAB5A:  LDA #$06                ;
LAB5C:  STA WndCol              ;Set cursor to BACK selection in alphabet window.
LAB5E:  LDA #$0D                ;
LAB60:  STA WndCursorXPos       ;

WndEndUpdateCrsr:
LAB63:  RTS                     ;Cursor update complete. Return.

;----------------------------------------------------------------------------------------------------

WndCalcSelResult:
LAB64:  LDA WindowType          ;Is this the alphabet window for entering name?
LAB67:  CMP #WND_ALPHBT         ;
LAB69:  BEQ WndCalcAlphaResult  ;If so, branch for special results processing.

LAB6B:  LDA _WndCol             ;
LAB6D:  STA WndColLB            ;Store number of columns as first multiplicand.
LAB6F:  LDA #$00                ;
LAB71:  STA WndColUB            ;

LAB73:  SEC                     ;
LAB74:  LDA WndHeight           ;
LAB77:  SBC #$03                ;Value of first multiplicand is:
LAB79:  LSR                     ;(window height in tiles-3)/2 + 1.
LAB7A:  TAX                     ;
LAB7B:  INX                     ;
LAB7C:  TXA                     ;

LAB7D:  LDX #WndColLB           ;Multiply values for selection result.
LAB7F:  JSR IndexedMult         ;($A6EB)Get first part of selection result.

LAB82:  LDA WndColLB            ;
LAB84:  CLC                     ;
LAB85:  ADC _WndRow             ;Add the window row to get final value of selection result.
LAB87:  STA WndSelResults       ;
LAB89:  RTS                     ;

WndCalcAlphaResult:
LAB8A:  LDA _WndRow             ;Get current window row selected.

LAB8C:  LDX WndColumns          ;Branch never.
LAB8F:  BEQ WndSetAlphaResult   ;

LAB91:  AND #$0F                ;
LAB93:  STA WndColLB            ;Save only lower 4 bits of window row.
LAB95:  LDA #$00                ;
LAB97:  STA WndColUB            ;

LAB99:  LDX #WndColLB           ;Multiply the current selected row       
LAB9B:  LDA WndSelNumCols       ;with the total window columns.
LAB9E:  JSR IndexedMult         ;($A6EB)Get multiplied value.

LABA1:  LDA WndColLB            ;
LABA3:  CLC                     ;Add current selected column to result for final answer.
LABA4:  ADC _WndCol             ;

WndSetAlphaResult:
LABA6:  STA WndSelResults       ;Return alphabet window selection result.
LABA8:  RTS                     ;

LABA9:  LDA WndCol              ;
LABAB:  STA _WndCol             ;
LABAD:  LDA WndRow              ;Reset working copies of the window column and row variables.
LABAF:  STA _WndRow             ;
LABB1:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndMoveCursorUp:
LABB2:  LDA WndCursorYPos       ;
LABB5:  SEC                     ;Decrease Cursor tile position in the Y direction by 2.
LABB6:  SBC #$02                ;
LABB8:  STA WndCursorYPos       ;

LABBB:  DEC WndRow              ;Decrease Cursor row position by 1.
LABBD:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;This table contains the number of columns for selection windows with more than a single column.

NumColTbl:
LABBE:  .byte $02               ;Command windows columns.
LABBF:  .byte $0B               ;Alphabet window columns.

;----------------------------------------------------------------------------------------------------

WndUnusedFunc2:
LABC0:  LDA #$00                ;Unused window function.
LABC2:  BNE WndShowHide+2       ;

;----------------------------------------------------------------------------------------------------

WndShowHide:
LABC4:  LDA #$00                ;Zero out A.
LABC6:  JSR WndDoRow            ;($ABCC)Fill PPU buffer with window row contents.
LABC9:  JMP WndUpdateTiles      ;($ADFA)Update background tiles next NMI.

WndDoRow:
LABCC:  PHA                     ;Save A. Always 0.
LABCD:  .byte $AD, $03, $00     ;LDA $0003(PPUEntCount)Is PPU buffer empty?
LABD0:  BEQ WndDoRowReady       ;If so, branch to fill it with window row data.

LABD2:  JSR WndUpdateTiles      ;($ADFA)Wait until next NMI for buffer to be empty.

WndDoRowReady:
LABD5:  LDA #$00                ;Zero out unused variable.
LABD7:  STA WndUnused64AB       ;

LABDA:  PLA                     ;Restore A. Always 0.
LABDB:  JSR WndStartRow         ;($AD10)Set nametable and X,Y start position of window line.

LABDE:  LDA #$00                ;
LABE0:  STA WndLineBufIndex     ;Zero buffer indexes.
LABE3:  STA WndAtrbBufIndex     ;

LABE6:  LDA WndWidthTemp        ;
LABE9:  PHA                     ;
LABEA:  AND #$F0                ;Will always set WndBlkTileRow to 2.
LABEC:  LSR                     ;Two rows of tiles in a window row.
LABED:  LSR                     ;
LABEE:  LSR                     ;
LABEF:  STA WndBlkTileRow       ;

LABF2:  PLA                     ;
LABF3:  AND #$0F                ;Make a copy of window width.
LABF5:  ASL                     ;
LABF6:  STA _WndWidth           ;

LABF9:  STA WndUnused64AE       ;Not used.
LABFC:  .byte $AE, $04, $00     ;LDX $0004(PPUBufCount)Get index for next buffer entry.

WndRowLoop:
LABFF:  LDA PPUAddrUB           ;
LAC01:  STA WndPPUAddrUB        ;Get a copy of the address to start of window row(block).
LAC04:  LDA PPUAddrLB           ;
LAC06:  STA WndPPUAddrLB        ;

LAC09:  AND #$1F                ;Get row offset on nametable for start of window
LAC0B:  STA WndNTRowOffset      ;(row is 32 tiles long, 0-31).

LAC0E:  LDA #$20                ;Each row is 32 tiles.
LAC10:  SEC                     ;
LAC11:  SBC WndNTRowOffset      ;Calculate the difference between start of window
LAC14:  STA WndThisNTRow        ;row and end of nametable row.

LAC17:  LDA _WndWidth           ;Subtract window width from difference above
LAC1A:  SEC                     ;If the value is negative, the window spans
LAC1B:  SBC WndThisNTRow        ;both nametables.
LAC1E:  STA WndNextNTRow        ;
LAC21:  BEQ WndNoCrossNT        ;Does window run to end of this NT? if so, branch.

LAC23:  BCS WndCrossNT          ;Does window span both nametables? if so, branch.

WndNoCrossNT:
LAC25:  LDA _WndWidth           ;Entire window row is on this nametable.
LAC28:  STA WndThisNTRow        ;Store number of tiles to process on this nametable.
LAC2B:  JMP WndSingleNT         ;($AC51)Window is contained on a single nametable.

WndCrossNT:
LAC2E:  JSR WndLoadRowBuf       ;($AC83)Load buffer with window row(up to overrun).

LAC31:  LDA WndPPUAddrUB        ;
LAC34:  EOR #$04                ;Change upper address byte to other nametable.
LAC36:  STA WndPPUAddrUB        ;

LAC39:  LDA WndPPUAddrLB        ;
LAC3C:  AND #$1F                ;Save lower 5 bits of lower PPU address.
LAC3E:  STA WndNTRowOffset      ;

LAC41:  LDA WndPPUAddrLB        ;
LAC44:  SEC                     ;Subtract the saved value above to set the nametable->
LAC45:  SBC WndNTRowOffset      ;address to the beginning of the nametable row.
LAC48:  STA WndPPUAddrLB        ;

LAC4B:  LDA WndNextNTRow        ;Completed window row portion on first nametable.
LAC4E:  STA WndThisNTRow        ;Tansfer remainder for next nametable calcs.

WndSingleNT:
LAC51:  JSR WndLoadRowBuf       ;($AC83)Load buffer with window row data.

LAC54:  LDA PPUAddrUB           ;
LAC56:  AND #$FB                ;Is there at least 2 full rows before bottom of nametable?
LAC58:  CMP #$23                ;If so, branch to increment row. Won't hit attribute table.
LAC5A:  BCC WndIncPPURow        ;

LAC5C:  LDA PPUAddrLB           ;Is there 1 row before bottom of nametable?
LAC5E:  CMP #$A0                ;If so, branch to increment row. Won't hit attribute table.
LAC60:  BCC WndIncPPURow        ;

LAC62:  AND #$1F                ;Save row offset for next row.
LAC64:  STA PPUAddrLB           ;

LAC66:  LDA PPUAddrUB           ;Address is off bottom of nametable. discard lower bits
LAC68:  AND #$FC                ;to wrap window around to the top of the nametable.
LAC6A:  JMP UpdateNTAddr        ;Update nametable address.

WndIncPPURow:
LAC6D:  LDA PPUAddrLB           ;
LAC6F:  CLC                     ;
LAC70:  ADC #$20                ;Add 32 to PPU address to move to next row.
LAC72:  STA PPUAddrLB           ;32 blocks per row.
LAC74:  LDA PPUAddrUB           ;
LAC76:  ADC #$00                ;

UpdateNTAddr:
LAC78:  STA PPUAddrUB           ;Update PPU upper PPU address byte.

LAC7A:  DEC WndBlkTileRow       ;Does the second row of tiles still need to be done?
LAC7D:  BNE WndRowLoop          ;If so, branch to do second half of window row.

LAC7F:  .byte $8E, $04, $00     ;STX $0004(PPUBufCount)Update buffer index.
LAC82:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndLoadRowBuf:
LAC83:  LDA WndPPUAddrUB        ;Get upper ddress byte.
LAC86:  ORA #$80                ;MSB set = PPU control byte(counter next byte).
LAC88:  STA BlockRAM,X          ;Store in buffer.

LAC8B:  LDA WndThisNTRow        ;Load counter value for remainder of this NT row.
LAC8E:  STA BlockRAM+1,X        ;

LAC91:  LDA WndPPUAddrLB        ;Load lower PPU address byte into buffer.
LAC94:  STA BlockRAM+2,X        ;

LAC97:  INX                     ;
LAC98:  INX                     ;Move to data portion of buffer.
LAC99:  INX                     ;

LAC9A:  LDA WndThisNTRow        ;Save a copy of the count of tiles on this NT.
LAC9D:  PHA                     ;

LAC9E:  LDY WndLineBufIndex     ;Load index into line buffer.

WndBufLoadLoop:
LACA1:  LDA WndLineBuf,Y        ;
LACA4:  STA BlockRAM,X          ;Load line buffer into PPU buffer.
LACA7:  INX                     ;
LACA8:  INY                     ;
LACA9:  DEC WndThisNTRow        ;Is there more buffer data for this nametable?
LACAC:  BNE WndBufLoadLoop      ;If so, branch to get the next byte.

LACAE:  STY WndLineBufIndex     ;Update line buffer index.

LACB1:  PLA                     ;/2. Use this now to load attribute table bytes.
LACB2:  LSR                     ;1 attribute table byte per 2X2 block.
LACB3:  STA WndThisNTRow        ;

LACB6:  LDA WndBlkTileRow       ;Is this the second tile row that just finished?
LACB9:  AND #$01                ;If so, load attribute table data.
LACBB:  BEQ WndLoadRowBufEnd    ;Else branch to skip attribute table data for now.

LACBD:  LDY WndAtrbBufIndex     ;
LACC0:  LDA WndPPUAddrUB        ;Prepare to calculate attribute table addresses
LACC3:  STA _WndPPUAddrUB       ;by first starting with the nametable addresses.
LACC6:  LDA WndPPUAddrLB        ;
LACC9:  STA _WndPPUAddrLB       ;

WndLoadAttribLoop:
LACCC:  TXA                     ;
LACCD:  PHA                     ;Save BlockRAM index and AttribTblBuf index on stack.
LACCE:  TYA                     ;
LACCF:  PHA                     ;

LACD0:  LDA WndPPUAddrUB        ;Save upper byte of PPU address on stack.
LACD3:  PHA                     ;

LACD4:  LDA AttribTblBuf,Y      ;Get attibute table bits from buffer.
LACD7:  JSR WndCalcAttribAddr   ;($AD36)Update attribute table values.
LACDA:  STA WndAtribDat         ;Save a copy of the completed attribute table data byte.

LACDD:  PLA                     ;Restore upper byte of PPU address from stack.
LACDE:  STA WndPPUAddrUB        ;

LACE1:  PLA                     ;
LACE2:  TAY                     ;Restore BlockRAM index and AttribTblBuf index from stack.
LACE3:  PLA                     ;
LACE4:  TAX                     ;

LACE5:  LDA WndAtribAdrUB       ;
LACE8:  STA BlockRAM,X          ;
LACEB:  INX                     ;Save attribute table data address in buffer.
LACEC:  LDA WndAtribAdrLB       ;
LACEF:  STA BlockRAM,X          ;

LACF2:  INX                     ;
LACF3:  LDA WndAtribDat         ;Save attribute table data byte in buffer.
LACF6:  STA BlockRAM,X          ;

LACF9:  INX                     ;Increment BlockRAM index and AttribTblBuf index.
LACFA:  INY                     ;

LACFB:  INC _WndPPUAddrLB       ;Increment to next window block.
LACFE:  INC _WndPPUAddrLB       ;

LAD01:  .byte $EE, $03, $00     ;INC $0003(PPUEntCount)Update buffer entry count.

LAD04:  DEC WndThisNTRow        ;Is there still more attribute table data to load?
LAD07:  BNE WndLoadAttribLoop   ;If so, branch to do more.

LAD09:  STY WndAtrbBufIndex     ;Update attribute table buffer index.

WndLoadRowBufEnd:
LAD0C:  .byte $EE, $03, $00     ;INC $0003(PPUEntCount)Update buffer entry count.
LAD0F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndStartRow:
LAD10:  PHA                     ;Save A. Always 0.
LAD11:  JSR WndGetRowStartPos   ;($AD1F)Load X and Y start position of window row.
LAD14:  PLA                     ;Restore A. Always 0.
LAD15:  BNE WndNTSwap           ;Branch never.
LAD17:  RTS                     ;

WndNTSwap:
LAD18:  LDA PPUAddrUB           ;
LAD1A:  EOR #$04                ;Never used. Swaps between #$20 and #$24.
LAD1C:  STA PPUAddrUB           ;
LAD1E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndGetRowStartPos:
LAD1F:  LDA _WndPosition        ;
LAD22:  ASL                     ;Get start X position in tiles
LAD23:  AND #$1E                ;relative to screen for window row.
LAD25:  STA ScrnTxtXCoord       ;

LAD28:  LDA _WndPosition        ;
LAD2B:  LSR                     ;
LAD2C:  LSR                     ;Get start Y position in tiles
LAD2D:  LSR                     ;relative to screen for window row.
LAD2E:  AND #$1E                ;
LAD30:  STA ScrnTxtYCoord       ;
LAD33:  JMP WndCalcPPUAddr      ;($ADC0)Calculate PPU address for window/text byte.

;----------------------------------------------------------------------------------------------------

WndCalcAttribAddr:
LAD36:  STA WndAttribVal        ;Save a copy of the attibute table value.

LAD39:  LDA #$1F                ;Get tile offset in row and divide by 4. This gives
LAD3B:  AND _WndPPUAddrLB       ;a value of 0-7. There are 8 bytes of attribute
LAD3E:  LSR                     ;table data per nametable row. WndPPUAddrUB now has
LAD3F:  LSR                     ;the byte number in the attribute table for this
LAD40:  STA WndPPUAddrUB        ;row offset.

LAD43:  LDA #$80                ;
LAD45:  AND _WndPPUAddrLB       ;
LAD48:  LSR                     ;Get MSB of lower address byte and shift it to the
LAD49:  LSR                     ;lower nibble.  This cuts the rows of the attribute
LAD4A:  LSR                     ;table in half.  There are now 4 possible addreses
LAD4B:  LSR                     ;in the attribute table that correspond to the target
LAD4C:  ORA WndPPUAddrUB        ;in the nametable.
LAD4F:  STA WndPPUAddrUB        ;

LAD52:  LDA #$03                ;
LAD54:  AND _WndPPUAddrUB       ;Getting the 2 LSB of the upper address selects the
LAD57:  ASL                     ;proper byte from the 4 remaining from above. Move
LAD58:  ASL                     ;The 2 bits to the upper nibble and or them with the
LAD59:  ASL                     ;lower byte of the base address of the attribute
LAD5A:  ASL                     ;table.  Finally, or the result with the other
LAD5B:  ORA #$C0                ;result to get the final result of the lower address
LAD5D:  ORA WndPPUAddrUB        ;byte of the attribute table byte.
LAD60:  STA WndAtribAdrLB       ;

LAD63:  LDX #AT_ATRBTBL0_UB     ;Assume we are working on nametable 0.
LAD65:  LDA _WndPPUAddrUB       ;
LAD68:  CMP #NT_NAMETBL1_UB     ;Are we actually working on nametable 1?
LAD6A:  BCC WndSetAtribUB       ;If not, branch to save upper address byte.

LAD6C:  LDX #AT_ATRBTBL1_UB     ;Set attribute table upper address for nametable 1.

WndSetAtribUB:
LAD6E:  STX WndAtribAdrUB       ;Save upper address byte for the attribute table.

LAD71:  LDA _WndPPUAddrLB       ;
LAD74:  AND #$40                ;
LAD76:  LSR                     ;Get bit 6 of address and move to lower nibble.
LAD77:  LSR                     ;This sets the upper bit for offset shifting.
LAD78:  LSR                     ;
LAD79:  LSR                     ;
LAD7A:  STA AtribBitsOfst       ;

LAD7D:  LDA _WndPPUAddrLB       ;
LAD80:  AND #$02                ;Get bit 1 of lower address bit.
LAD82:  ORA AtribBitsOfst       ;This sets the lower bit for offset shifting.
LAD85:  STA AtribBitsOfst       ;

LAD88:  LDA WndAtribAdrLB       ;Set attrib table pointer to lower byte of attrib table address.
LAD8B:  STA AttribPtrLB         ;

LAD8D:  LDA WndAtribAdrUB       ;Set upper byte for attribute table buffer. The atrib
LAD90:  AND #$07                ; table buffer starts at either $0300 or $0700, depending
LAD92:  STA AttribPtrUB         ;on the active nametable.

LAD94:  LDA EnNumber            ;Is player fighting the end boss?
LAD96:  CMP #EN_DRAGONLORD2     ;If so, force atribute table buffer to base address $0700.
LAD98:  BNE ModAtribByte        ;If not, branch to get attribute table byte.

LAD9A:  LDA #$07                ;Force atribute table buffer to base address $0700.
LAD9C:  STA AttribPtrUB         ;

ModAtribByte:
LAD9E:  LDY #$00                ;
LADA0:  LDA (AttribPtr),Y       ;Get attribute byte to modify from buffer.
LADA2:  STA AttribByte          ;

LADA5:  LDA #$03                ;Initialize bitmask.
LADA7:  LDY AtribBitsOfst       ;Set shift amount.
LADAA:  BEQ AddNewAtribVal      ;Is there no shifting needed? If none, branch. done.

AtribValShiftLoop:
LADAC:  ASL                     ;Shift bitmask into proper position.
LADAD:  ASL WndAttribVal        ;Shift new attribute bits into proper position.
LADB0:  DEY                     ;Is shifting done?
LADB1:  BNE AtribValShiftLoop   ;If not branch to shift by another bit.

AddNewAtribVal:
LADB3:  EOR #$FF                ;Clear the two bits to be modified.
LADB5:  AND AttribByte          ;

LADB8:  ORA WndAttribVal        ;Insert the 2 new bits.
LADBB:  LDY #$00                ;

LADBD:  STA (AttribPtr),Y       ;Save attribute table data byte back into the buffer.
LADBF:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndCalcPPUAddr:
LADC0:  LDA ActiveNmTbl         ;
LADC2:  ASL                     ;
LADC3:  ASL                     ;Calculate base upper address byte of current
LADC4:  AND #$04                ;name table. It will be either #$20 or #$24.
LADC6:  ORA #$20                ;
LADC8:  STA PPUAddrUB           ;

LADCA:  LDA ScrnTxtXCoord       ;
LADCD:  ASL                     ;*8. Convert X tile coord to X pixel coord.
LADCE:  ASL                     ;
LADCF:  ASL                     ;

LADD0:  CLC                     ;Add scroll offset.  It is a pixel offset.
LADD1:  ADC ScrollX             ;

LADD3:  STA PPUAddrLB           ;The X coordinate in pixels is now calculated.
LADD5:  BCC WndAddY             ;Did X position go past nametable boundary? If not, branch.

WndXOverRun:
LADD7:  LDA PPUAddrUB           ;Window tile ran beyond end of nametable.
LADD9:  EOR #$04                ;Move to next nametable to continue window line.
LADDB:  STA PPUAddrUB           ;

WndAddY:
LADDD:  LDA ScrollY             ;
LADDF:  LSR                     ;/8. Convert Y scroll pixel coord to tile coord.
LADE0:  LSR                     ;
LADE1:  LSR                     ;

LADE2:  CLC                     ;Add Tile Y coord of window. A now
LADE3:  ADC ScrnTxtYCoord       ;contains Y coordinate in tiles.

LADE6:  CMP #$1E                ;Did Y position go below nametable boundary?
LADE8:  BCC WndAddrCombine      ;If not, branch.

WndYOverRun:
LADEA:  SBC #$1E                ;Window tile went below end of nametable. Loop back to top.

WndAddrCombine:
LADEC:  LSR                     ;A is upper byte of result and PPUAddrLB is lower byte.
LADED:  ROR PPUAddrLB           ;
LADEF:  LSR                     ;Need to divide by 8 because X coord is still in pixel
LADF0:  ROR PPUAddrLB           ;coords.
LADF2:  LSR                     ;
LADF3:  ROR PPUAddrLB           ;Result is now calculated with respect to screen.

LADF5:  ORA PPUAddrUB           ;Combine A with PPUAddrUB to convert from
LADF7:  STA PPUAddrUB           ;screen coord to nametable coords.
LADF9:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndUpdateTiles:
LADFA:  LDA #$80                ;Indicate background tiles need to be updated.
LADFC:  STA UpdateBGTiles       ;
LADFF:  JMP WaitForNMI          ;($FF74)Wait for VBlank interrupt.

;----------------------------------------------------------------------------------------------------

WndEnterName:
LAE02:  JSR InitNameWindow      ;($AE2C)Initialize window used while entering name.
LAE05:  JSR WndShowUnderscore   ;($AEB8)Show underscore below selected letter in name window.
LAE08:  JSR WndDoSelect         ;($A8D1)Do selection window routines.

ProcessNameLoop:
LAE0B:  JSR WndProcessChar      ;($AE53)Process name character selected by the player.
LAE0E:  JSR WndMaxNameLength    ;($AEB2)Set carry if max length name has been reached.
LAE11:  BCS WndStorePlyrName    ;Has player finished entering name? If so, branch to exit loop.
LAE13:  JSR _WndDoSelectLoop    ;($A8E0)Wait for player to select the next character.
LAE16:  JMP ProcessNameLoop     ;($AE0B)Loop to get name selected by player.

WndStorePlyrName:
LAE19:  LDX #$00                ;Set index to 0 for storing the player's name.

StoreNameLoop:
LAE1B:  LDA TempBuffer,X        ;Save the 8 characters of the player's name to the name registers.
LAE1E:  STA DispName0,X         ;
LAE20:  LDA TempBuffer+4,X      ;
LAE23:  STA DispName4,X         ;
LAE26:  INX                     ;
LAE27:  CPX #$04                ;Have all 8 characters been saved?
LAE29:  BNE StoreNameLoop       ;If not, branch to save the next 2.
LAE2B:  RTS                     ;

;----------------------------------------------------------------------------------------------------

InitNameWindow:
LAE2C:  LDA #$00                ;
LAE2E:  STA WndNameIndex        ;Zero out name variables.
LAE31:  STA WndUnused6505       ;

LAE34:  LDA #WND_NM_ENTRY       ;Show name entry window.
LAE36:  JSR ShowWindow          ;($A194)Display window.

LAE39:  LDA #WND_ALPHBT         ;Show alphabet window.
LAE3B:  JSR ShowWindow          ;($A194)Display window.

LAE3E:  LDA #$12                ;Set window columns to 18. Special value for the alphabet window.
LAE40:  STA WndColumns          ;

LAE43:  LDA #$21                ;Set starting cursor position to 2,1.
LAE45:  STA WndCursorHome       ;

LAE48:  LDA #TL_BLANK_TILE2     ;Prepare to clear temp buffer.
LAE4A:  LDX #$0C                ;

ClearNameBufLoop:
LAE4C:  STA TempBuffer,X        ;Place blank tile value in temp buffer.
LAE4F:  DEX                     ;
LAE50:  BPL ClearNameBufLoop    ;Have 12 values been written to the buffer?
LAE52:  RTS                     ;If not, branch to write another.

;----------------------------------------------------------------------------------------------------

WndProcessChar:
LAE53:  CMP #WND_ABORT          ;Did player press the B button?
LAE55:  BEQ WndDoBackspace      ;If so, back up 1 character.

LAE57:  CMP #$1A                ;Did player select character A-Z?
LAE59:  BCC WndUprCaseConvert   ;If so, branch to covert to nametables values.

LAE5B:  CMP #$21                ;Did player select symbol -'!?() or _?
LAE5D:  BCC WndSymbConvert1     ;If so, branch to covert to nametables values.

LAE5F:  CMP #$3B                ;Did player select character a-z?
LAE61:  BCC WndLwrCaseConvert   ;If so, branch to covert to nametables values.

LAE63:  CMP #$3D                ;Did player select symbol , or .?
LAE65:  BCC WndSymbConvert2     ;If so, branch to covert to nametables values.

LAE67:  CMP #$3D                ;Did player select BACK?
LAE69:  BEQ WndDoBackspace      ;If so, back up 1 character.

LAE6B:  LDA #$08                ;Player must have selected END.
LAE6D:  STA WndNameIndex        ;Set name index to max value to indicate the end.
LAE70:  RTS                     ;

WndUprCaseConvert:
LAE71:  CLC                     ;
LAE72:  ADC #TXT_UPR_A          ;Add value to convert to nametable character.
LAE74:  BNE WndUpdateName       ;

WndLwrCaseConvert:
LAE76:  SEC                     ;
LAE77:  SBC #$17                ;Subtract value to convert to nametable character.
LAE79:  BNE WndUpdateName       ;

WndSymbConvert1:
LAE7B:  TAX                     ;
LAE7C:  LDA SymbolConvTbl-$1A,X ;Use table to convert to nametable character.
LAE7F:  BNE WndUpdateName       ;

WndSymbConvert2:
LAE81:  TAX                     ;
LAE82:  LDA SymbolConvTbl-$34,X ;Use table to convert to nametable character.
LAE85:  BNE WndUpdateName       ;

WndDoBackspace:
LAE87:  LDA WndNameIndex        ;Is the name index already 0?
LAE8A:  BEQ WndProcessCharEnd1  ;If so, branch to exit, can't go back any further.

LAE8C:  JSR WndHideUnderscore   ;($AEBC)Remove underscore character from screen.
LAE8F:  DEC WndNameIndex        ;Move underscore back 1 character.
LAE92:  JSR WndShowUnderscore   ;($AEB8)Show underscore below selected letter in name window.

WndProcessCharEnd1:
LAE95:  RTS                     ;End character processing.

WndUpdateName:
LAE96:  PHA                     ;Save name character on stack.
LAE97:  JSR WndHideUnderscore   ;($AEBC)Remove underscore character from screen.

LAE9A:  PLA                     ;Restore name character and add it to the buffer.
LAE9B:  LDX WndNameIndex        ;
LAE9E:  STA TempBuffer,X        ;
LAEA1:  JSR WndNameCharYPos     ;($AEC2)Place selected name character on screen.

LAEA4:  INC WndNameIndex        ;Increment index for player's name.
LAEA7:  LDA WndNameIndex        ;
LAEAA:  CMP #$08                ;Have 8 character been entered for player's name?
LAEAC:  BCS WndProcessCharEnd2  ;If so, branch to end.

LAEAE:  JSR WndShowUnderscore   ;($AEB8)Show underscore below selected letter in name window.

WndProcessCharEnd2:
LAEB1:  RTS                     ;End character processing.

;----------------------------------------------------------------------------------------------------

WndMaxNameLength:
LAEB2:  LDA WndNameIndex        ;Have 8 name characters been inputted?
LAEB5:  CMP #$08                ;
LAEB7:  RTS                     ;If so, set carry.

;----------------------------------------------------------------------------------------------------

WndShowUnderscore:
LAEB8:  LDA #TL_TOP1            ;Border pattern - upper border(Underscore below selected entry).
LAEBA:  BNE WndUndrscrYPos      ;Branch always.

WndHideUnderscore:
LAEBC:  LDA #TL_BLANK_TILE1     ;Prepare to erase underscore character.

WndUndrscrYPos:
LAEBE:  LDX #$09                ;Set Y position for underscore character.
LAEC0:  BNE WndShowNameChar     ;Branch always.

WndNameCharYPos:
LAEC2:  LDX #$08                ;Set Y position for name character.

WndShowNameChar:
LAEC4:  STX ScrnTxtYCoord       ;Calculate X position for character to add to name window.
LAEC7:  STA PPUDataByte         ;

LAEC9:  LDA WndNameIndex        ;
LAECC:  CLC                     ;Calculate Y position for character to add to name window.
LAECD:  ADC #$0C                ;
LAECF:  STA ScrnTxtXCoord       ;

LAED2:  JSR WndCalcPPUAddr      ;($ADC0)Calculate PPU address for window/text byte.
LAED5:  JMP AddPPUBufEntry      ;($C690)Add data to PPU buffer.

;----------------------------------------------------------------------------------------------------

;The following table converts to the symbols in the alphabet
;window to the corresponding symbols in the nametable.

SymbolConvTbl:
LAED8:  .byte TXT_DASH,      TXT_APOS,      TXT_EXCLAIM,   TXT_QUESTION
LAEDC:  .byte TXT_OPN_PAREN, TXT_CLS_PAREN, TXT_BLANK1,    TXT_COMMA
LAEE0:  .byte TXT_PERIOD

;----------------------------------------------------------------------------------------------------

DoWindowPrep:
LAEE1:  PHA                     ;Save window type byte on the stack.

LAEE2:  LDX #$40                ;Initialize WndBuildPhase variable.
LAEE4:  STX WndBuildPhase       ;

LAEE7:  LDX #$03                ;Prepare to look through table below for window type.
LAEE9:* CMP WindowType1Tbl,X    ;
LAEEC:  BEQ +                   ;
LAEEE:  DEX                     ;If working on one of the 4 windows from the table below,
LAEEF:  BPL -                   ;Set the WndBuildPhase variable to 0.  This seems to have
LAEF1:  BMI ++                  ;no effect as the MSB is set after this function is run.
LAEF3:* LDA #$00                ;
LAEF5:  STA WndBuildPhase       ;

LAEF8:* PLA                     ;Get window type byte again.
LAEF9:  PHA                     ;

LAEFA:  CMP #WND_CMD_NONCMB     ;Is this the command, non-combat window?
LAEFC:  BEQ DoBeepSFX           ;If so, branch to make menu button SFX.

LAEFE:  CMP #WND_CMD_CMB        ;Is this the command, combat window?
LAF00:  BEQ DoBeepSFX           ;If so, branch to make menu button SFX.

LAF02:  CMP #WND_YES_NO1        ;Is this the yes/no selection window?
LAF04:  BEQ DoConfirmSFX        ;If so, branch to make confirm SFX.

LAF06:  CMP #WND_DIALOG         ;Is this a dialog window?
LAF08:  BNE +                   ;If not, branch to exit.

LAF0A:  LDA #$00                ;Dialog window being created. Set cursor to top left.
LAF0C:  STA WndTxtXCoord        ;
LAF0E:  STA WndTxtYCoord        ;
LAF10:  JSR ClearDialogOutBuf   ;($B850)Clear dialog window buffer.

LAF13:* PLA                     ;Restore window type byte in A and return.
LAF14:  RTS                     ;

DoBeepSFX:
LAF15:  LDA #SFX_MENU_BTN       ;Menu button SFX.
LAF17:  BNE +                   ;Branch always.

DoConfirmSFX:
LAF19:  LDA #SFX_CONFIRM        ;Confirmation SFX.
LAF1B:* BRK                     ;
LAF1C:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

LAF1E:  PLA                     ;Restore window type byte in A and return.
LAF1F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WindowType1Tbl:
LAF20:  .byte WND_CMD_NONCMB    ;Command window, non-combat.
LAF21:  .byte WND_CMD_CMB       ;Combat window, combat.
LAF22:  .byte WND_DIALOG        ;Dialog window.
LAF23:  .byte WND_POPUP         ;Pop-up window.

;----------------------------------------------------------------------------------------------------

WndEraseParams:
LAF24:  CMP #WND_ALPHBT         ;Special case. Erase alphabet window.
LAF26:  BEQ WndErsAlphabet      ;

LAF28:  CMP #$FF                ;Special case. Erase unspecified window.
LAF2A:  BEQ WndErsOther         ;

LAF2C:  ASL                     ;*2. Widow data pointer is 2 bytes.
LAF2D:  TAY                     ;

LAF2E:  LDA WndwDataPtrTbl,Y    ;
LAF31:  STA GenPtr3ELB          ;Get pointer base of window data.
LAF33:  LDA WndwDataPtrTbl+1,Y  ;
LAF36:  STA GenPtr3EUB          ;

LAF38:  LDY #$01                ;
LAF3A:  LDA (GenPtr3E),Y        ;Get window height in blocks.
LAF3C:  STA WndEraseHght        ;

LAF3F:  INY                     ;
LAF40:  LDA (GenPtr3E),Y        ;Get window width in tiles.
LAF42:  STA WndEraseWdth        ;

LAF45:  INY                     ;
LAF46:  LDA (GenPtr3E),Y        ;Get window X,Y position in blocks.
LAF48:  STA WndErasePos         ;
LAF4B:  RTS                     ;

WndErsAlphabet:
LAF4C:  LDA #$07                ;Window height = 7 blocks.
LAF4E:  STA WndEraseHght        ;

LAF51:  LDA #$16                ;Window width = 22 tiles.
LAF53:  STA WndEraseWdth        ;

LAF56:  LDA #$21                ;
LAF58:  STA WndErasePos         ;Window position = 2,1.
LAF5B:  RTS                     ;

WndErsOther:
LAF5C:  LDA #$0C                ;Window height = 12 blocks.
LAF5E:  STA WndEraseHght        ;

LAF61:  LDA #$1A                ;Window width =  26 tiles.
LAF63:  STA WndEraseWdth        ;

LAF66:  LDA #$22                ;
LAF68:  STA WndErasePos         ;Window position = 2,2.
LAF6B:  RTS                     ;

;----------------------------------------------------------------------------------------------------

WndwDataPtrTbl:
LAF6C:  .word PopupDat          ;($AFB0)Pop-up window.
LAF6E:  .word StatusDat         ;($AFC7)Status window.
LAF70:  .word DialogDat         ;($B04B)Dialog window.
LAF72:  .word CmdNonCmbtDat     ;($B054)Command window, non-combat.
LAF74:  .word CmdCmbtDat        ;($B095)Command window, combat.
LAF76:  .word SpellDat          ;($B0BA)Spell window.
LAF78:  .word SpellDat          ;($B0BA)Spell window.
LAF7A:  .word PlayerInvDat      ;($B0CC)Player inventory window.
LAF7C:  .word ShopInvDat        ;($B0DA)Shop inventory window.
LAF7E:  .word YesNo1Dat         ;($B0EB)Yes/no selection window, variant 1.
LAF80:  .word BuySellDat        ;($B0FB)Buy/sell selection window.
LAF82:  .word AlphabetDat       ;($B10D)Alphabet window.
LAF84:  .word MsgSpeedDat       ;($B194)Message speed window.
LAF86:  .word InputNameDat      ;($B1E0)Input name window.
LAF88:  .word NameEntryDat      ;($B1F7)Name entry window.
LAF8A:  .word ContChngErsDat    ;($B20B)Continue, change, erase window.
LAF8C:  .word FullMenuDat       ;($B249)Full pre-game menu window.
LAF8E:  .word NewQuestDat       ;($B2A8)Begin new quest window.
LAF90:  .word LogList1Dat1      ;($B2C2)Log list, entry 1 window 1.
LAF92:  .word LogList2Dat1      ;($B2DA)Log list, entry 2 window 1.
LAF94:  .word LogList12Dat1     ;($B2F2)Log list, entry 1,2 window 1.
LAF96:  .word LogList3Dat1      ;($B31B)Log list, entry 3 window 1.
LAF98:  .word LogList13Dat1     ;($B333)Log list, entry 1,3 window 1.
LAF9A:  .word LogList23Dat1     ;($B35C)Log list, entry 2,3 window 1.
LAF9C:  .word LogList123Dat1    ;($B385)Log list, entry 1,2,3 window 1.
LAF9E:  .word LogList1Dat2      ;($B3BF)Log list, entry 1 window 2.
LAFA0:  .word LogList2Dat2      ;($B3D9)Log list, entry 2 window 2.
LAFA2:  .word LogList12Dat2     ;($B3F3)Log list, entry 1,2 window 2.
LAFA4:  .word LogList3Dat2      ;($B420)Log list, entry 3 window 2.
LAFA6:  .word LogList13Dat2     ;($B43A)Log list, entry 1,3 window 2.
LAFA8:  .word LogList23Dat2     ;($B467)Log list, entry 2,3 window 2.
LAFAA:  .word LogList123Dat2    ;($B494)Log list, entry 1,2,3 window 2.
LAFAC:  .word EraseLogDat       ;($B4D4)Erase log window.
LAFAE:  .word YesNo2Dat         ;($B50D)Yes/no selection window, variant 2.

;----------------------------------------------------------------------------------------------------

PopupDat:
LAFB0:  .byte $01               ;Window options.  Display window.
LAFB1:  .byte $06               ;Window height.   6 blocks.
LAFB2:  .byte $08               ;Window Width.    8 tiles.
LAFB3:  .byte $21               ;Window Position. Y = 2 blocks, X = 1 block.
LAFB4:  .byte $89               ;Horizontal border, 1 space.
LAFB5:  .byte $B0               ;Show name, 4 characters.
LAFB6:  .byte $88               ;Horizontal border, remainder of row.
;              L    V
LAFB7:  .byte $2F, $39 
LAFB9:  .byte $82               ;Blank tiles, 2 spaces.
LAFBA:  .byte $A0               ;Show level.
;              H    P
LAFBB:  .byte $2B, $33
LAFBD:  .byte $81               ;Blank tile, 1 space.
LAFBE:  .byte $90               ;Show hit points.
;              M    P
LAFBF:  .byte $30, $33
LAFC1:  .byte $81               ;Blank tile, 1 space.
LAFC2:  .byte $94               ;Show magic points.
;              G
LAFC3:  .byte $2A
LAFC4:  .byte $98               ;Show gold.
;              E
LAFC5:  .byte $28
LAFC6:  .byte $A8               ;Show experience.

;----------------------------------------------------------------------------------------------------

StatusDat:
LAFC7:  .byte $21               ;Display window, single spaced.
LAFC8:  .byte $0B               ;Window height.   11 blocks.
LAFC9:  .byte $14               ;Window Width.    20 tiles.
LAFCA:  .byte $35               ;Window Position. Y = 3 blocks, X = 5 blocks.
LAFCB:  .byte $88               ;Horizontal border, remainder of row.
LAFCC:  .byte $85               ;Blank tiles, 5 spaces.
;              N    A    M    E    :
LAFCD:  .byte $31, $24, $30, $28, $44
LAFD2:  .byte $B1               ;Show name, 8 characters.
LAFD3:  .byte $80               ;Blank tiles, remainder of row.
LAFD4:  .byte $86               ;Blank tiles, 6 spaces.
;              S    T    R    E    N    G    T    H    :
LAFD5:  .byte $36, $37, $35, $28, $31, $2A, $37, $2B, $44
LAFDE:  .byte $D8               ;Show strength.
LAFDF:  .byte $80               ;Blank tiles, remainder of row.
LAFE0:  .byte $87               ;Blank tiles, 7 spaces.
;              A    G    I    L    I    T    Y    :
LAFE1:  .byte $24, $2A, $2C, $2F, $2C, $37, $3C, $44
LAFE9:  .byte $D9               ;Show agility.
LAFEA:  .byte $80               ;Blank tiles, remainder of row.
LAFEB:  .byte $84               ;Blank tiles, 4 spaces.
;              M    A    X    I    M    U    M
LAFEC:  .byte $30, $24, $3B, $2C, $30, $38, $30
LAFF3:  .byte $81               ;Blank tile, 1 space.
;              H    P    :    
LAFF4:  .byte $2B, $33, $44
LAFF7:  .byte $DC               ;Show maximum hit points.
LAFF8:  .byte $80               ;Blank tiles, remainder of row.
LAFF9:  .byte $84               ;Blank tiles, 4 spaces.
;              M    A    X    I    M    U    M
LAFFA:  .byte $30, $24, $3B, $2C, $30, $38, $30
LB001:  .byte $81               ;Blank tile, 1 space.
;              M    P    :
LB002:  .byte $30, $33, $44
LB005:  .byte $DD               ;Show maximum magic points.
LB006:  .byte $80               ;Blank tiles, remainder of row.
LB007:  .byte $82               ;Blank tiles, 2 spaces.
;              A    T    T    A    C    K
LB008:  .byte $24, $37, $37, $24, $26, $2E
LB00E:  .byte $81               ;Blank tile, 1 space.
;              P    O    W    E    R    :
LB00F:  .byte $33, $32, $3A, $28, $35, $44
LB015:  .byte $DA               ;Show attack power.
LB016:  .byte $80               ;Blank tiles, remainder of row.
LB017:  .byte $81               ;Blank tile, 1 space.
;              D    E    F    E    N    S    E
LB018:  .byte $27, $28, $29, $28, $31, $36, $28
LB01F:  .byte $81               ;Blank tile, 1 space.
;              P    O    W    E    R    :
LB020:  .byte $33, $32, $3A, $28, $35, $44
LB026:  .byte $DB               ;Show defense power.
LB027:  .byte $80               ;Blank tiles, remainder of row.
LB028:  .byte $82               ;Blank tiles, 2 spaces.
;              W    E    A    P    O    N    :
LB029:  .byte $3A, $28, $24, $33, $32, $31, $44
LB030:  .byte $B8               ;Show weapon, first half.
LB031:  .byte $87               ;Blank tiles, 7 spaces.
LB032:  .byte $83               ;Blank tiles, 3 spaces.
LB033:  .byte $B8               ;Show weapon, second half.
LB034:  .byte $83               ;Blank tiles, 3 spaces.
;              A    R    M    O    R    :
LB035:  .byte $24, $35, $30, $32, $35, $44
LB03B:  .byte $B9               ;Show armor, first half.
LB03C:  .byte $87               ;Blank tiles, 7 spaces.
LB03D:  .byte $83               ;Blank tiles, 3 spaces.
LB03E:  .byte $B9               ;Show armor, second half.
LB03F:  .byte $82               ;Blank tiles, 2 spaces.
;              S    H    I    E    L    D    :
LB040:  .byte $36, $2B, $2C, $28, $2F, $27, $44
LB047:  .byte $BA               ;Show shield, first half.
LB048:  .byte $87               ;Blank tiles, 7 spaces.
LB049:  .byte $83               ;Blank tiles, 3 spaces.
LB04A:  .byte $BA               ;Show shield, second half.

;----------------------------------------------------------------------------------------------------

DialogDat:
LB04B:  .byte $01               ;Window options.  Display window.
LB04C:  .byte $05               ;Window height.   5 blocks.
LB04D:  .byte $18               ;Window Width.    24 tiles.
LB04E:  .byte $92               ;Window Position. Y = 9 blocks, X = 2 blocks.
LB04F:  .byte $88               ;Horizontal border, remainder of row.
LB050:  .byte $80               ;Blank tiles, remainder of row.
LB051:  .byte $80               ;Blank tiles, remainder of row.
LB052:  .byte $80               ;Blank tiles, remainder of row.
LB053:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

CmdNonCmbtDat:
LB054:  .byte $80               ;Window options.  Selection window.
LB055:  .byte $05               ;Window height.   5 blocks.
LB056:  .byte $10               ;Window Width.    16 tiles.
LB057:  .byte $16               ;Window Position. Y = 1 block, X = 6 blocks.
LB058:  .byte $08               ;Window columns.  2 columns 8 tiles apart.
LB059:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tile.
LB05A:  .byte $8B               ;Horizontal border, 3 spaces.
;              C    O    M    M    A    N    D
LB05B:  .byte $26, $32, $30, $30, $24, $31, $27
LB062:  .byte $88               ;Horizontal border, remainder of row.
LB063:  .byte $81               ;Blank tile, 1 space.
;              T    A    L    K
LB064:  .byte $37, $24, $2F, $2E
LB068:  .byte $84               ;Blank tiles, 4 spaces.
;              S    P    E    L    L
LB069:  .byte $36, $33, $28, $2F, $2F
LB06E:  .byte $81               ;Blank tile, 1 space.
;              S    T    A    T    U    S
LB06F:  .byte $36, $37, $24, $37, $38, $36
LB075:  .byte $82               ;Blank tiles, 2 spaces.
;              I    T    E    M
LB076:  .byte $2C, $37, $28, $30 
LB07A:  .byte $80               ;Blank tiles, remainder of row.
LB07B:  .byte $81               ;Blank tile, 1 space.
;              S    T    A    I    R    S
LB07C:  .byte $36, $37, $24, $2C, $35, $36
LB082:  .byte $82               ;Blank tiles, 2 spaces.
;              D    O    O    R
LB083:  .byte $27, $32, $32, $35 
LB087:  .byte $80               ;Blank tiles, remainder of row.
LB088:  .byte $81               ;Blank tile, 1 space.
;              S    E    A    R    C    H
LB089:  .byte $36, $28, $24, $35, $26, $2B
LB08F:  .byte $82               ;Blank tiles, 2 spaces.
;              T    A    K    E
LB090:  .byte $37, $24, $2E, $28
LB094:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

CmdCmbtDat:
LB095:  .byte $80               ;Window options.  Selection window.
LB096:  .byte $03               ;Window height.   3 blocks.
LB097:  .byte $10               ;Window Width.    16 tiles.
LB098:  .byte $16               ;Window Position. Y = 1 block, X = 6 blocks.
LB099:  .byte $08               ;Window columns.  2 columns 8 tiles apart.
LB09A:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tile.
LB09B:  .byte $8B               ;Horizontal border, 3 spaces.
;              C    O    M    M    A    N    D
LB09C:  .byte $26, $32, $30, $30, $24, $31, $27
LB0A3:  .byte $88               ;Horizontal border, remainder of row.
LB0A4:  .byte $81               ;Blank tile, 1 space.
;              F    I    G    H    T
LB0A5:  .byte $29, $2C, $2A, $2B, $37
LB0AA:  .byte $83               ;Blank tiles, 3 spaces.
;              S    P    E    L    L
LB0AB:  .byte $36, $33, $28, $2F, $2F
LB0B0:  .byte $81               ;Blank tile, 1 space.
;              R    U    N
LB0B1:  .byte $35, $38, $31
LB0B4:  .byte $85               ;Blank tiles, 5 spaces.
;              I    T    E    M
LB0B5:  .byte $2C, $37, $28, $30
LB0B9:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

SpellDat:
LB0BA:  .byte $80               ;Window options.  Selection window.
LB0BB:  .byte $0B               ;Window height.   11 blocks.
LB0BC:  .byte $0C               ;Window Width.    12 tiles.
LB0BD:  .byte $29               ;Window Position. Y = 2 block, X = 9 blocks.
LB0BE:  .byte $00               ;Window columns.  1 column.
LB0BF:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tile.
LB0C0:  .byte $8B               ;Horizontal border, 3 spaces.
;              S    P    E    L    L
LB0C1:  .byte $36, $33, $28, $2F, $2F
LB0C6:  .byte $88               ;Horizontal border, remainder of row.
LB0C7:  .byte $D6               ;Calculate number of spells player has.
LB0C8:  .byte $81               ;Blank tile, 1 space.
LB0C9:  .byte $C0               ;Get spell for current window row.
LB0CA:  .byte $E8               ;Display spells in window.
LB0CB:  .byte $E9               ;Finish variable length window.

;----------------------------------------------------------------------------------------------------

PlayerInvDat:
LB0CC:  .byte $A0               ;Window options.  Selection window, single spaced.
LB0CD:  .byte $0B               ;Window height.   11 blocks.
LB0CE:  .byte $0C               ;Window Width.    12 tiles.
LB0CF:  .byte $39               ;Window Position. Y = 3 block, X = 9 blocks.
LB0D0:  .byte $00               ;Window columns.  1 column.
LB0D1:  .byte $11               ;Cursor home.     Y = 1 tile, X = 1 tile.
LB0D2:  .byte $88               ;Horizontal border, remainder of row.
LB0D3:  .byte $D4               ;Calculate number of items player has.
LB0D4:  .byte $81               ;Blank tile, 1 space.
LB0D5:  .byte $BB               ;Display item, first half.
LB0D6:  .byte $82               ;Blank tile, 2 spaces.
LB0D7:  .byte $BB               ;Display item, second half.
LB0D8:  .byte $E8               ;Display items in window.
LB0D9:  .byte $E9               ;Finish variable length window.

;----------------------------------------------------------------------------------------------------

ShopInvDat:
LB0DA:  .byte $A0               ;Window options.  Selection window, single spaced.
LB0DB:  .byte $08               ;Window height.   8 blocks.
LB0DC:  .byte $12               ;Window Width.    18 tiles.
LB0DD:  .byte $25               ;Window Position. Y = 2 block, X = 5 blocks.
LB0DE:  .byte $00               ;Window columns.  1 column.
LB0DF:  .byte $11               ;Cursor home.     Y = 1 tile, X = 1 tile.
LB0E0:  .byte $88               ;Horizontal border, remainder of row.
LB0E1:  .byte $D5               ;Calculate number of items shop has.
LB0E2:  .byte $81               ;Blank tile, 1 space.
LB0E3:  .byte $BC               ;Display item, first half.
LB0E4:  .byte $81               ;Blank tile, 1 space.
LB0E5:  .byte $C8               ;Display item cost.
LB0E6:  .byte $82               ;Blank tile, 2 spaces.
LB0E7:  .byte $BC               ;Display item, second half.
LB0E8:  .byte $80               ;Blank tiles, remainder of row.
LB0E9:  .byte $E8               ;Display items in window.
LB0EA:  .byte $E9               ;Finish variable length window.

;----------------------------------------------------------------------------------------------------

YesNo1Dat:
LB0EB:  .byte $80               ;Window Options.  Selection window.
LB0EC:  .byte $03               ;Window Height.   3 blocks.
LB0ED:  .byte $08               ;Window Width.    8 tiles.
LB0EE:  .byte $25               ;Window Position. Y = 2 blocks, X = 5 blocks.
LB0EF:  .byte $00               ;Window columns.  1 column.
LB0F0:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tile.
LB0F1:  .byte $88               ;Horizontal border, remainder of row.
LB0F2:  .byte $81               ;Blank tile, 1 space.
;              Y    E    S
LB0F3:  .byte $3C, $28, $36
LB0F6:  .byte $80               ;Blank tiles, remainder of row.
LB0F7:  .byte $81               ;Blank tile, 1 space.
;              N    O
LB0F8:  .byte $31, $32
LB0FA:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

BuySellDat:
LB0FB:  .byte $80               ;Window Options.  Selection window.
LB0FC:  .byte $03               ;Window Height.   3 blocks.
LB0FD:  .byte $08               ;Window Width.    8 tiles.
LB0FE:  .byte $25               ;Window Position. Y = 2 blocks, X = 5 blocks.
LB0FF:  .byte $00               ;Window columns.  1 column.
LB100:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tile.
LB101:  .byte $88               ;Horizontal border, remainder of row.
LB102:  .byte $81               ;Blank tile, 1 space.
;              B    U    Y
LB103:  .byte $25, $38, $3C
LB106:  .byte $80               ;Blank tiles, remainder of row.
LB107:  .byte $81               ;Blank tile, 1 space.
;              S    E    L    L
LB108:  .byte $36, $28, $2F, $2F
LB10C:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

AlphabetDat:
LB10D:  .byte $01               ;Window options.  Display window.
LB10E:  .byte $07               ;Window height.   7 blocks.
LB10F:  .byte $18               ;Window Width.    24 tiles.
LB110:  .byte $52               ;Window Position. Y = 5 blocks, X = 2 blocks.
LB111:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    _    B    _    C    _    D    _    E    _    F    _    G    _    H
LB112:  .byte $81, $24, $81, $25, $81, $26, $81, $27, $81, $28, $81, $29, $81, $2A, $81, $2B
;              _    I    _    J    _    K    _    L    _    M    _    N    _    O    _    P
LB122:  .byte $81, $2C, $81, $2D, $81, $2E, $81, $2F, $81, $30, $81, $31, $81, $32, $81, $33
;              _    Q    _    R    _    S    _    T    _    U    _    V    _    W    _    X
LB132:  .byte $81, $34, $81, $35, $81, $36, $81, $37, $81, $38, $81, $39, $81, $3A, $81, $3B
;              _    Y    _    Z    _    -    _    '    _    !    _    ?    _    (    _    )
LB142:  .byte $81, $3C, $81, $3D, $81, $49, $81, $40, $81, $4C, $81, $4B, $81, $4F, $81, $4E
LB152:  .byte $80               ;Blank tiles, remainder of row.
;              _    a    _    b    _    c    _    d    _    e    _    f    _    g    _    h
LB153:  .byte $81, $0A, $81, $0B, $81, $0C, $81, $0D, $81, $0E, $81, $0F, $81, $10, $81, $11
;              _    i    _    j    _    k    _    l    _    m    _    n    _    o    _    p
LB163:  .byte $81, $12, $81, $13, $81, $14, $81, $15, $81, $16, $81, $17, $81, $18, $81, $19
;              _    q    _    r    _    s    _    t    _    u    _    v    _    w    _    x
LB173:  .byte $81, $1A, $81, $1B, $81, $1C, $81, $1D, $81, $1E, $81, $1F, $81, $20, $81, $21
;              _    y    _    z    _    ,    _    .    _    B    A    C    K
LB183:  .byte $81, $22, $81, $23, $81, $48, $81, $47, $81, $25, $24, $26, $2E
LB190:  .byte $82               ;Blank tiles, 2 spaces.
;              E    N    D
LB191:  .byte $28, $31, $27

;----------------------------------------------------------------------------------------------------

MsgSpeedDat:
LB194:  .byte $A1               ;Window options.  Selection window, single spaced.
LB195:  .byte $07               ;Window Height.   7 blocks.
LB196:  .byte $12               ;Window Width.    18 tiles.
LB197:  .byte $74               ;Window Position. Y = 7 blocks, X = 4 blocks.
LB198:  .byte $00               ;Window columns.  1 column.
LB199:  .byte $86               ;Cursor home.     Y = 8 tiles, X = 6 tiles.
LB19A:  .byte $88               ;Horizontal border, remainder of row.
;              _    W    h    i    c    h    _    M    e    s    s    a    g    e
LB19B:  .byte $81, $3A, $11, $12, $0C, $11, $81, $30, $0E, $1C, $1C, $0A, $10, $0E
LB1A9:  .byte $80               ;Blank tiles, remainder of row.
LB1AA:  .byte $80               ;Blank tiles, remainder of row.
;              _    S    p    e    e    d    _    D    o    _    Y    o    u
LB1AB:  .byte $81, $36, $19, $0E, $0E, $0D, $81, $27, $18, $81, $3C, $18, $1E
LB1B8:  .byte $80               ;Blank tiles, remainder of row.
LB1B9:  .byte $80               ;Blank tiles, remainder of row.
;              _    W    a    n    t    _    T    o    _    U    s    e    ?
LB1BA:  .byte $81, $3A, $0A, $17, $1D, $81, $37, $18, $81, $38, $1C, $0E, $4B
LB1C7:  .byte $80               ;Blank tiles, remainder of row.
LB1C8:  .byte $80               ;Blank tiles, remainder of row.
LB1C9:  .byte $80               ;Blank tiles, remainder of row.
LB1CA:  .byte $86               ;Blank tiles, 6 spaces.
;              F    A    S    T
LB1CB:  .byte $29, $24, $36, $37
LB1CF:  .byte $80               ;Blank tiles, remainder of row.
LB1D0:  .byte $80               ;Blank tiles, remainder of row.
LB1D1:  .byte $86               ;Blank tiles, 6 spaces.
;              N    O    R    M    A    L
LB1D7:  .byte $31, $32, $35, $30, $24, $2F
LB1D8:  .byte $80               ;Blank tiles, remainder of row.
LB1D9:  .byte $80               ;Blank tiles, remainder of row.
LB1DA:  .byte $86               ;Blank tiles, 6 spaces.
;              S    L    O    W
LB1DE:  .byte $36, $2F, $32, $3A
LB1DF:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

InputNameDat:
LB1E0:  .byte $01               ;Window options.  Display window.
LB1E1:  .byte $02               ;Window Height.   2 blocks.
LB1E2:  .byte $14               ;Window Width.    20 tiles.
LB1E3:  .byte $73               ;Window Position. Y = 7 blocks, X = 3 blocks.
LB1E4:  .byte $88               ;Horizontal border, remainder of row.
;              _    I    N    P    U    T    _    Y    O    U    R    _    N    A    M    E
LB1E5:  .byte $81, $2C, $31, $33, $38, $37, $81, $3C, $32, $38, $35, $81, $31, $24, $30, $28
;              !
LB1F5:  .byte $4C
LB1F6:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

NameEntryDat:
LB1F7:  .byte $01               ;Window options.  Display window.
LB1F8:  .byte $03               ;Window Height.   3 blocks.
LB1F9:  .byte $0C               ;Window Width.    12 tiles.
LB1FA:  .byte $35               ;Window Position. Y = 3 blocks, X = 5 blocks.
LB1FB:  .byte $8B               ;Horizontal border, 3 spaces.
;              N    A    M    E
LB1FC:  .byte $31, $24, $30, $28
LB200:  .byte $88               ;Horizontal border, remainder of row.
;              _    *    *    *    *    *    *    *    *
LB201:  .byte $81, $41, $41, $41, $41, $41, $41, $41, $41
LB20A:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

ContChngErsDat:
LB20B:  .byte $81               ;Window Options.  Selection window.
LB20C:  .byte $04               ;Window Height.   4 blocks.
LB20D:  .byte $18               ;Window Width.    24 tiles.
LB20E:  .byte $42               ;Window Position. Y = 4 blocks, X = 2 blocks.
LB20F:  .byte $00               ;Window columns.  1 column.
LB210:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB211:  .byte $88               ;Horizontal border, remainder of row.
;              _    C    O    N    T    I    N    U    E    _    A    _    Q    U    E    S
LB212:  .byte $81, $26, $32, $31, $37, $2C, $31, $38, $28, $81, $24, $81, $34, $38, $28, $36
;              T
LB222:  .byte $37
LB223:  .byte $80               ;Blank tiles, remainder of row.
;              _    C    H    A    N    G    E    _    M    E    S    S    A    G    E    _
LB224:  .byte $81, $26, $2B, $24, $31, $2A, $28, $81, $30, $28, $36, $36, $24, $2A, $28, $81
;              S    P    E    E    D
LB234:  .byte $36, $33, $28, $28, $27
LB239:  .byte $80               ;Blank tiles, remainder of row.
;              _    E    R    A    S    E    _    A    _    Q    U    E    S    T
LB23A:  .byte $81, $28, $35, $24, $36, $28, $81, $24, $81, $34, $38, $28, $36, $37
LB248:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

FullMenuDat:
LB249:  .byte $81               ;Window Options.  Selection window.
LB24A:  .byte $06               ;Window Height.   6 blocks.
LB24B:  .byte $18               ;Window Width.    24 tiles.
LB24C:  .byte $42               ;Window Position. Y = 4 blocks, X = 2 blocks.
LB24D:  .byte $00               ;Window columns.  1 column.
LB24E:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB24F:  .byte $88               ;Horizontal border, remainder of row.
;              _    C    O    N    T    I    N    U    E    _    A    _    Q    U    E    S
LB250:  .byte $81, $26, $32, $31, $37, $2C, $31, $38, $28, $81, $24, $81, $34, $38, $28, $36
;              T
LB260:  .byte $37
LB261:  .byte $80               ;Blank tiles, remainder of row.
;              _    C    H    A    N    G    E    _    M    E    S    S    A    G    E    _
LB262:  .byte $81, $26, $2B, $24, $31, $2A, $28, $81, $30, $28, $36, $36, $24, $2A, $28, $81
;              S    P    E    E    D
LB272:  .byte $36, $33, $28, $28, $27
LB277:  .byte $80               ;Blank tiles, remainder of row.
;              _    B    E    G    I    N    _    A    _    N    E    W    _    Q    U    E
LB278:  .byte $81, $25, $28, $2A, $2C, $31, $81, $24, $81, $31, $28, $3A, $81, $34, $38, $28
;              S    T
LB288:  .byte $36, $37
LB28A:  .byte $80               ;Blank tiles, remainder of row.
;              _    C    O    P    Y    _    A    _    Q    U    E    S    T
LB28B:  .byte $81, $26, $32, $33, $3C, $81, $24, $81, $34, $38, $28, $36, $37
LB298:  .byte $80               ;Blank tiles, remainder of row.
;              _    E    R    A    S    E    _    A    _    Q    U    E    S    T
LB299:  .byte $81, $28, $35, $24, $36, $28, $81, $24, $81, $34, $38, $28, $36, $37
LB2A7:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

NewQuestDat:
LB2A8:  .byte $81               ;Window Options.  Selection window.
LB2A9:  .byte $02               ;Window Height.   2 blocks.
LB2AA:  .byte $18               ;Window Width.    24 tiles.
LB2AB:  .byte $42               ;Window Position. Y = 4 blocks, X = 2 blocks.
LB2AC:  .byte $00               ;Window columns.  1 column.
LB2AD:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB2AE:  .byte $88               ;Horizontal border, remainder of row.
;              _    B    E    G    I    N    _    A    _    N    E    W    _    Q    U    E
LB2AF:  .byte $81, $25, $28, $2A, $2C, $31, $81, $24, $81, $31, $28, $3A, $81, $34, $38, $28
;              S    T
LB2BF:  .byte $36, $37
LB2C1:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList1Dat1:
LB2C2:  .byte $81               ;Window Options.  Selection window.
LB2C3:  .byte $02               ;Window Height.   2 blocks.
LB2C4:  .byte $14               ;Window Width.    20 tiles.
LB2C5:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB2C6:  .byte $00               ;Window columns.  1 column.
LB2C7:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB2C8:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB2C9:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
LB2D9:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList2Dat1:
LB2DA:  .byte $81               ;Window Options.  Selection window.
LB2DB:  .byte $02               ;Window Height.   2 blocks.
LB2DC:  .byte $14               ;Window Width.    20 tiles.
LB2DD:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB2DE:  .byte $00               ;Window columns.  1 column.
LB2DF:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB2E0:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB2E1:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
LB2F1:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList12Dat1:
LB2F2:  .byte $81               ;Window Options.  Selection window.
LB2F3:  .byte $03               ;Window Height.   3 blocks.
LB2F4:  .byte $14               ;Window Width.    20 tiles.
LB2F5:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB2F6:  .byte $00               ;Window columns.  1 column.
LB2F7:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB2F8:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB2F9:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
LB309:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB30A:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
LB31A:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList3Dat1:
LB31B:  .byte $81               ;Window Options.  Selection window.
LB31C:  .byte $02               ;Window Height.   2 blocks.
LB31D:  .byte $14               ;Window Width.    20 tiles.
LB31E:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB31F:  .byte $00               ;Window columns.  1 column.
LB320:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB321:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB322:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
LB332:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList13Dat1:
LB333:  .byte $81               ;Window Options.  Selection window.
LB334:  .byte $03               ;Window Height.   3 blocks.
LB335:  .byte $14               ;Window Width.    20 tiles.
LB336:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB337:  .byte $00               ;Window columns.  1 column.
LB338:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB339:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB33A:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
LB34A:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB34B:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
LB35B:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList23Dat1:
LB35C:  .byte $81               ;Window Options.  Selection window.
LB35D:  .byte $03               ;Window Height.   3 blocks.
LB35E:  .byte $14               ;Window Width.    20 tiles.
LB35F:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB360:  .byte $00               ;Window columns.  1 column.
LB361:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB362:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB363:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
LB373:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB374:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
LB384:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList123Dat1:
LB385:  .byte $81               ;Window Options.  Selection window.
LB386:  .byte $04               ;Window Height.   4 blocks.
LB387:  .byte $14               ;Window Width.    20 tiles.
LB388:  .byte $95               ;Window Position. Y = 9 blocks, X = 5 blocks.
LB389:  .byte $00               ;Window columns.  1 column.
LB38A:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB38B:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB38C:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
LB39C:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB39D:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
LB3AD:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB3AE:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
LB3BE:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList1Dat2:
LB3BF:  .byte $81               ;Window Options.  Selection window.
LB3C0:  .byte $02               ;Window Height.   2 blocks.
LB3C1:  .byte $18               ;Window Width.    24 tiles.
LB3C2:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB3C3:  .byte $00               ;Window columns.  1 column.
LB3C4:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB3C5:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB3C6:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
;              :
LB3D6:  .byte $44
LB3D7:  .byte $B5               ;Display Log 1 character's name.
LB3D8:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList2Dat2:
LB3D9:  .byte $81               ;Window Options.  Selection window.
LB3DA:  .byte $02               ;Window Height.   2 blocks.
LB3DB:  .byte $18               ;Window Width.    24 tiles.
LB3DC:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB3DD:  .byte $00               ;Window columns.  1 column.
LB3DE:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB3DF:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB3E0:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
;              :
LB3F0:  .byte $44
LB3F1:  .byte $B6               ;Display Log 2 character's name.
LB3F2:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList12Dat2:
LB3F3:  .byte $81               ;Window Options.  Selection window.
LB3F4:  .byte $03               ;Window Height.   3 blocks.
LB3F5:  .byte $18               ;Window Width.    24 tiles.
LB3F6:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB3F7:  .byte $00               ;Window columns.  1 column.
LB3F8:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB3F9:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB3FA:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
;              :
LB40A:  .byte $44
LB40B:  .byte $B5               ;Display Log 1 character's name.
LB30C:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB40D:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
;              :
LB41D:  .byte $44
LB41E:  .byte $B6               ;Display Log 2 character's name.
LB41F:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList3Dat2:
LB420:  .byte $81               ;Window Options.  Selection window.
LB421:  .byte $02               ;Window Height.   2 blocks.
LB422:  .byte $18               ;Window Width.    24 tiles.
LB423:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB424:  .byte $00               ;Window columns.  1 column.
LB425:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB426:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB427:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
;              :
LB437:  .byte $44
LB438:  .byte $B7               ;Display Log 3 character's name.
LB439:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList13Dat2:
LB43A:  .byte $81               ;Window Options.  Selection window.
LB43B:  .byte $03               ;Window Height.   3 blocks.
LB43C:  .byte $18               ;Window Width.    24 tiles.
LB43D:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB43E:  .byte $00               ;Window columns.  1 column.
LB43F:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB440:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB441:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
;              :
LB451:  .byte $44
LB452:  .byte $B5               ;Display Log 1 character's name.
LB453:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB454:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
;              :
LB464:  .byte $44
LB465:  .byte $B7               ;Display Log 3 character's name.
LB466:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList23Dat2:
LB467:  .byte $81               ;Window Options.  Selection window.
LB468:  .byte $03               ;Window Height.   3 blocks.
LB469:  .byte $18               ;Window Width.    24 tiles.
LB46A:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB46B:  .byte $00               ;Window columns.  1 column.
LB46C:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB46D:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB46E:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
;              :
LB47E:  .byte $44
LB47F:  .byte $B6               ;Display Log 2 character's name.
LB480:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB481:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
;              :
LB491:  .byte $44
LB492:  .byte $B7               ;Display Log 3 character's name.
LB493:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

LogList123Dat2:
LB494:  .byte $81               ;Window Options.  Selection window.
LB495:  .byte $04               ;Window Height.   4 blocks.
LB496:  .byte $18               ;Window Width.    24 tiles.
LB497:  .byte $63               ;Window Position. Y = 6 blocks, X = 3 blocks.
LB498:  .byte $00               ;Window columns.  1 column.
LB499:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tiles.
LB49A:  .byte $88               ;Horizontal border, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    1
LB49B:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $01
;              :
LB4AB:  .byte $44
LB4AC:  .byte $B5               ;Display Log 1 character's name.
LB4AD:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    2
LB4AE:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $02
;              :
LB4BE:  .byte $44
LB4BF:  .byte $B6               ;Display Log 2 character's name.
LB4C0:  .byte $80               ;Blank tiles, remainder of row.
;              _    A    D    V    E    N    T    U    R    E    _    L    O    G    _    3
LB4C1:  .byte $81, $24, $27, $39, $28, $31, $37, $38, $35, $28, $81, $2F, $32, $2A, $81, $03
;              :
LB4D1:  .byte $44
LB4D2:  .byte $B7               ;Display Log 3 character's name.
LB4D3:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

EraseLogDat:
LB4D4:  .byte $01               ;Window options.  Display window.
LB4D5:  .byte $06               ;Window height.   6 blocks.
LB4D6:  .byte $14               ;Window Width.    20 tiles.
LB4D7:  .byte $73               ;Window Position. Y = 7 blocks, X = 3 blocks.
LB4D8:  .byte $88               ;Horizontal border, remainder of row.
LB4D9:  .byte $81               ;Blank tile, 1 space.
LB4DA:  .byte $B4               ;Display character's name.
LB4DB:  .byte $80               ;Blank tiles, remainder of row.
;              _    L    E    V    E    L
LB4DC:  .byte $81, $2F, $28, $39, $28, $2F
LB4E2:  .byte $82               ;Blank tile, 2 spaces.
LB4E3:  .byte $A1               ;Display character's level.
LB4E4:  .byte $80               ;Blank tiles, remainder of row.
;              _    D    o    _    Y    o    u    _    W    a    n    t    _    T    o
LB4E5:  .byte $81, $27, $18, $81, $3C, $18, $1E, $81, $3A, $0A, $17, $1D, $81, $37, $18
LB4F4:  .byte $80               ;Blank tiles, remainder of row.
;              _    E    r    a    s    e    _    T    h    i    s
LB4F5:  .byte $81, $28, $1B, $0A, $1C, $0E, $81, $37, $11, $12, $1C
LB500:  .byte $80               ;Blank tiles, remainder of row.
;              _    C    h    a    r    a    c    t    e    r    ?
LB501:  .byte $81, $26, $11, $0A, $1B, $0A, $0C, $1D, $0E, $1B, $4B
LB50C:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

YesNo2Dat:
LB50D:  .byte $80               ;Window Options.  Selection window.
LB50E:  .byte $03               ;Window Height.   3 blocks.
LB50F:  .byte $08               ;Window Width.    8 tiles.
LB510:  .byte $3A               ;Window Position. Y = 3 blocks, X = 10 blocks.
LB511:  .byte $00               ;Window columns.  1 column.
LB512:  .byte $21               ;Cursor home.     Y = 2 tiles, X = 1 tile.
LB513:  .byte $88               ;Horizontal border, remainder of row.
LB514:  .byte $81               ;Blank tile, 1 space.
;              Y    E    S
LB515:  .byte $3C, $28, $36
LB518:  .byte $80               ;Blank tiles, remainder of row.
LB519:  .byte $81               ;Blank tile, 1 space.
;              N    O
LB51A:  .byte $31, $32
LB51C:  .byte $80               ;Blank tiles, remainder of row.

;----------------------------------------------------------------------------------------------------

DoDialog:
LB51D:  JSR FindDialogEntry     ;($B532)Get pointer to desired dialog text.
LB520:  JSR InitDialogVars      ;($B576)Initialize the dialog variables.

LB523:* JSR CalcWordCoord       ;($B5AF)Calculate coordinates of word in text window.
LB526:  JSR WordToScreen        ;($B5E6)Send dialog word to the screen.
LB529:  JSR CheckDialogEnd      ;($B594)Check if dialog buffer is complete.
LB52C:  BCC -

LB52E:  JSR DialogToScreenBuf   ;($B85D)Copy dialog buffer to screen buffer.
LB531:  RTS                     ;

;----------------------------------------------------------------------------------------------------

FindDialogEntry:
LB532:  STA TextEntry           ;Store byte and process later.

LB534:  AND #NBL_UPPER          ;
LB536:  LSR                     ;
LB537:  LSR                     ;Keep upper nibble and shift it to lower nibble.
LB538:  LSR                     ;
LB539:  LSR                     ;
LB53A:  STA TextBlock           ;

LB53C:  TXA                     ;Get upper/lower text block bit and move to upper nibble.
LB53D:  ASL                     ;
LB53E:  ASL                     ;
LB53F:  ASL                     ;
LB540:  ASL                     ;
LB541:  ADC TextBlock           ;Add to text block byte. Text block calculation complete.

LB543:  CLC                     ;
LB544:  ADC #$01                ;Use TextBlock as pointer into bank table. Incremented
LB546:  STA BankPtrIndex        ;by 1 as first pointer is for intro routine.

LB548:  LDA #PRG_BANK_2         ;Prepare to switch to PRG bank 2.
LB54A:  STA NewPRGBank          ;

LB54C:  LDX #$9F                ;Store data pointer in $9F,$A0
LB54E:  JSR GetAndStrDatPtr     ;($FD00)

LB551:  LDA TextEntry           ;
LB553:  AND #NBL_LOWER          ;Keep only lower nibble for text entry number.
LB555:  STA TextEntry           ;

LB557:  TAX                     ;Keep copy of entry number in X.
LB558:  BEQ ++++                ;Entry 0? If so, done! branch to exit.

LB55A:  LDY #$00                ;No offset from pointer.
LB55C:* LDX #DialogPtr          ;DialogPtr is the pointer to use.
LB55E:  LDA #PRG_BANK_2         ;PRG bank 2 is where the text is stored.

LB560:  JSR GetBankDataByte     ;($FD1C)Retreive data byte.

LB563:  INC DialogPtrLB         ;
LB565:  BNE +                   ;Increment dialog pointer.
LB567:  INC DialogPtrUB         ;

LB569:* CMP #TXT_END1           ;At the end of current text entry?
LB56B:  BEQ +                   ;If so, branch to check nect entry.

LB56D:  CMP #TXT_END2           ;Also used as end of entry marker.
LB56F:  BNE --                  ;Branch if not end of entry.

LB571:* DEC TextEntry           ;Incremented past current text entry.
LB573:  BNE ---                 ;Are we at right entry? if not, branch to try next entry.

LB575:* RTS                     ;Done. DialogPtr points to desired text entry.

;----------------------------------------------------------------------------------------------------

InitDialogVars:
LB576:  LDA #$00                ;
LB578:  STA TxtIndent           ;
LB57B:  STA Dialog00            ;
LB57E:  STA DialogEnd           ;
LB581:  STA WrkBufBytsDone      ;
LB584:  LDA #$08                ;Initialize the dialog variables.
LB586:  STA TxtLineSpace        ;
LB589:  LDA WndTxtXCoord        ;
LB58B:  STA Unused6510          ;
LB58E:  LDA WndTxtYCoord        ;
LB590:  STA Unused6511          ;
LB593:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckDialogEnd:
LB594:  LDA DialogEnd           ;
LB597:  BNE +                   ;Is dialog buffer complete?
LB599:  CLC                     ;If so, clear the carry flag.
LB59A:  RTS                     ;

LB59B:* LDX WndTxtYCoord        ;
LB59D:  LDA Unused6512          ;
LB5A0:  BNE +                   ;
LB5A2:  STX Unused6512          ;Dialog buffer not complete. Set carry.
LB5A5:* LDA Unused6513          ;The other variables have no effect.
LB5A8:  BNE +                   ;
LB5AA:  STX Unused6513          ;
LB5AD:* SEC                     ;
LB5AE:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CalcWordCoord:
LB5AF:  JSR GetTxtWord          ;($B635)Get the next word of text.

LB5B2:  BIT Dialog00            ;Should never branch.
LB5B5:  BMI CalcCoordEnd        ;

LB5B7:  LDA WndTxtXCoord        ;Make sure x coordinate after word is
LB5B9:  STA WndXPosAW           ;the same as current x coordinate.

LB5BC:  LDA #$00                ;Zero out word buffer index.
LB5BE:  STA WordBufIndex        ;

SearchWordBuf:
LB5C1:  LDX WordBufIndex        ;
LB5C4:  LDA WordBuffer,X        ;Get next character in the word buffer.
LB5C7:  INC WordBufIndex        ;

LB5CA:  CMP #TL_BLANK_TILE1     ;Has a space in the word buffer been found?
LB5CC:  BEQ WordBufBreakFound   ;If so, branch to see if it will fit it into text window.

LB5CE:  CMP #TXT_SUBEND         ;Has a sub-buffer end character been found?
LB5D0:  BCS WordBufBreakFound   ;If so, branch to see if word will fit it into text window.

LB5D2:  INC WndXPosAW           ;Increment window position pointer.

LB5D5:  JSR CheckBetweenWords   ;($B8F9)Check for non-word character.
LB5D8:  BCS SearchWordBuf       ;Still in word? If so, branch.

WordBufBreakFound:
LB5DA:  LDX WndXPosAW           ;Is X position at beginning of line?
LB5DD:  BEQ +                   ;If so, branch to skip modifying X position.

LB5DF:  DEC WndXPosAW           ;Dcrement index so it points to last character position.

LB5E2:* JSR CheckForNewLine     ;($B915)Move text to new line, if necessary.

CalcCoordEnd:
LB5E5:  RTS                     ;End coordinate calculations.

;----------------------------------------------------------------------------------------------------

WordToScreen:
LB5E6:  LDX #$00                ;Zero out word buffer index.
LB5E8:  STX WordBufLen          ;

LB5EB:* LDX WordBufLen          ;
LB5EE:  LDA WordBuffer,X        ;Get next character in the word buffer.
LB5F1:  INC WordBufLen          ;

LB5F4:  CMP #TXT_SUBEND         ;Is character a control character that will cause a newline?
LB5F6:  BCS TxtCntrlChars       ;If so, branch to determine the character.

LB5F8:  PHA                     ;
LB5F9:  JSR TextToPPU           ;($B9C7)Send dialog text character to the screen.
LB5FC:  PLA                     ;

LB5FD:  JSR CheckBetweenWords   ;($B8F9)Check for non-word character.
LB600:  BCS -                   ;Was the character a text character?
LB602:  RTS                     ;If so, branch to get another character.

TxtCntrlChars:
LB603:  CMP #TXT_WAIT           ;Was wait found?
LB605:  BEQ WaitFound           ;If so, branch to wait.

LB607:  CMP #TXT_END1           ;Was the end character found?
LB609:  BEQ DialogEndFound      ;If so, branch to end dialog.

LB60B:  CMP #TXT_NEWL           ;Was a newline character found?
LB60D:  BEQ NewLineFound        ;If so, branch to do newline routine.

LB60F:  CMP #TXT_NOP            ;Was a no-op found?
LB611:  BEQ NewLineFound        ;If so, branch to do newline routine.

DoDialogEnd:
LB613:  LDA #TXT_END2           ;Dialog is done. Load end of dialog marker.
LB615:  STA DialogEnd           ;Set end of dialog flag.
LB618:  RTS                     ;

NewLineFound:
LB619:  JMP DoNewline           ;($B91D)Go to next line in dialog window.

WaitFound:
LB61C:  JSR DoNewline           ;($B91D)Go to next line in dialog window.
LB61F:  JSR DoWait              ;($BA59)Wait for user interaction.

LB622:  LDA TxtIndent           ;Is an indent active?
LB625:  BNE +                   ;If so, branch to skip newline.

LB627:  JSR MoveToNextLine      ;($B924)Move to the next line in the text window.
LB62A:* RTS                     ;

DialogEndFound:
LB62B:  JSR DoNewline           ;($B91D)Go to next line in dialog window.
LB62E:  LDA #$00                ;Set cursor X position to beginning of line.
LB630:  STA WndTxtXCoord        ;
LB632:  JMP DoDialogEnd         ;($B613)End current dialog.

;----------------------------------------------------------------------------------------------------

GetTxtWord:
LB635:  LDA #$00                ;Zero out word buffer length.
LB637:  STA WordBufLen          ;

GetTxtByteLoop:
LB63A:  JSR GetTextByte         ;($B662)Get text byte from ROM or work buffer.
LB63D:  CMP #TXT_NOP            ;Is character a no-op character?
LB63F:  BNE BuildWordBuf        ;If not, branch to add to word buffer.

LB641:  BIT Dialog00            ;Branch always.
LB644:  BPL GetTxtByteLoop      ;Get next character.

BuildWordBuf:
LB646:  CMP #TXT_OPN_QUOTE      ;"'"(open quotes).
LB648:  BEQ TxtSetIndent        ;Has open quotes been found? If so, branch to set indent.

LB64A:  CMP #TXT_INDENT         ;" "(Special indent blank space).
LB64C:  BNE +                   ;Has indent character been found? If not, branch to skip indent.

TxtSetIndent:
LB64E:  LDX #$01                ;Set text indent to 1 space.
LB650:  STX TxtIndent           ;

LB653:* LDX WordBufLen          ;Add character to word buffer.
LB656:  STA WordBuffer,X        ;
LB659:  INC WordBufLen          ;Increment buffer length.
LB65C:  JSR CheckBetweenWords   ;($B8F9)Check for non-word character.
LB65F:  BCS GetTxtByteLoop      ;End of word? If not, branch to get next byte.
LB661:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetTextByte:
LB662:  LDX WrkBufBytsDone      ;Are work buffer bytes waiting to be returned?
LB665:  BEQ GetROMByte          ;If not, branch to retreive a ROM byte instead.

WorkBufDone:
LB667:  LDA WorkBuffer,X        ;Grab the next byte from the work buffer.
LB66A:  INC WrkBufBytsDone      ;
LB66D:  CMP #TXT_SUBEND         ;Is it the end marker for the work buffer?
LB66F:  BNE +                   ;If not, branch to return another work buffer byte.

LB671:  LDX #$00                ;Work buffer bytes all processed.
LB673:  STX WrkBufBytsDone      ;
LB676:  BEQ GetROMByte          ;Branch always and grab a byte from ROM.

LB678:* RTS                     ;Return work buffer byte.

GetROMByte:
LB679:  LDA #PRG_BANK_2         ;PRG bank 2 is where the text is stored.
LB67B:  LDX #DialogPtr          ;DialogPtr is the pointer to use.
LB67D:  LDY #$00                ;No offset from pointer.

LB67F:  JSR GetBankDataByte     ;($FD1C)Get text byte from PRG bank 2 and store in A.
LB682:  JSR IncDialogPtr        ;($BA9F)Increment DialogPtr.

LB685:  CMP #TXT_PLRL           ;Plural control character?
LB687:  BEQ JmpDoPLRL           ;If so, branch to process.

LB689:  CMP #TXT_DESC           ;Object description control character?
LB68B:  BEQ JmpDoDESC           ;If so, branch to process.

LB68D:  CMP #TXT_PNTS           ;"Points" control character?
LB68F:  BEQ JmpDoPNTS           ;If so, brach to process.

LB691:  CMP #TXT_AMTP           ;Numeric amount + "Points" control character?
LB693:  BEQ JmpDoAMTP           ;If so, branch to process.

LB695:  CMP #TXT_AMNT           ;Numeric amount control character?
LB697:  BEQ JmpDoAMNT           ;If so, branch to process.

LB699:  CMP #TXT_SPEL           ;Spell description control character?
LB69B:  BEQ JmpDoSPEL           ;If so, branch to process.

LB69D:  CMP #TXT_NAME           ;Name description control character?
LB69F:  BEQ JmpDoNAME           ;If so, branch to process.

LB6A1:  CMP #TXT_ITEM           ;Item description control character?
LB6A3:  BEQ JmpDoITEM           ;If so, branch to process.

LB6A5:  CMP #TXT_COPY           ;Buffer copy control character?
LB6A7:  BEQ JmpDoCOPY           ;If so, branch to process.

LB6A9:  CMP #TXT_ENMY           ;Enemy name control character?
LB6AB:  BEQ JmpDoENMY           ;If so, branch to process.

LB6AD:  CMP #TXT_ENM2           ;Enemy name control character?
LB6AF:  BEQ JmpDoENM2           ;If so, branch to process.

LB6B1:  RTS                     ;No control character. Return ROM byte.

;----------------------------------------------------------------------------------------------------

JmpDoCOPY:
LB6B2:  JMP DoCOPY              ;($B7E8)Copy description buffer straight into work buffer.

JmpDoNAME:
LB6B5:  JMP DoNAME              ;($B7F9)Jump to get player's name.

JmpDoENMY:
LB6B8:  JMP DoENMY              ;($B804)Jump to get enemy name.

JmpDoSPEL:
LB6BB:  JMP DoSPEL              ;($B7D8)Jump to get spell description.

JmpDoDESC:
LB6BE:  JMP DoDESC              ;($B794)Jump do get object description proceeded by 'a' or 'an'.

JmpDoENM2:
LB6C1:  JMP DoENM2              ;(B80F)Jump to get enemy name preceeded by 'a' or 'an'.

JmpDoITEM:
LB6C4:  JMP DoITEM              ;($B757)Jump to get item description.

JmpDoPNTS:
LB6C7:  JMP DoPNTS              ;($B71E)Jump to write "Points" to buffer.

JmpDoAMTP:
LB6CA:  JMP DoAMTP              ;($B724)Jump to do BCD converion and write "Points" to buffer.

;----------------------------------------------------------------------------------------------------

JmpDoAMNT:
LB6CD:  JSR BinWordToBCD        ;($B6DA)Convert word in $00/$01 to BCD.

WorkBufEndChar:
LB6D0:  LDA #TXT_SUBEND         ;Place termination character at end of work buffer.
LB6D2:  STA WorkBuffer,Y        ;

LB6D5:  LDX #$00                ;Set index to beginning of work buffer.
LB6D7:  JMP WorkBufDone         ;($B667)Done building work buffer.

;----------------------------------------------------------------------------------------------------

BinWordToBCD:
LB6DA:  LDA #$05                ;Largest BCD from two bytes is 5 digits.
LB6DC:  STA SubBufLength        ;

LB6DF:  LDA GenWrd00LB          ;
LB6E1:  STA BCDByte0            ;Load word to convert to BCD.
LB6E3:  LDA GenWrd00UB          ;
LB6E5:  STA BCDByte1            ;
LB6E7:  LDA #$00                ;3rd byte is always 0.
LB6E9:  STA BCDByte2            ;

LB6EB:  JSR ConvertToBCD        ;($A753)Convert binary word to BCD.
LB6EE:  JSR ClearBCDLeadZeros   ;($A764)Remove leading zeros from BCD value.

LB6F1:  LDY #$00                ;
LB6F3:* LDA TempBuffer,X        ;Transfer contents of BCD buffer to work buffer.
LB6F6:  STA WorkBuffer,Y        ;
LB6F9:  INY                     ;BCD buffer is backwards so it needs to be
LB6FA:  DEX                     ;written in reverse into the work buffer.
LB6FB:  BPL -                   ;
LB6FD:  RTS                     ;

;----------------------------------------------------------------------------------------------------

JmpDoPLRL:
LB6FE:  LDA #$01                ;Start with a single byte in the buffer.
LB700:  STA SubBufLength        ;

LB703:  LDA GenWrd00UB          ;
LB705:  BNE +                   ;Is the numeric value greater than 1?
LB707:  LDX GenWrd00LB          ;
LB709:  DEX                     ;If so, add an 's' to the end of the buffer.
LB70A:  BEQ EndPlrl             ;

LB70C:* LDA #$1C                ;'s' character.
LB70E:  STA WorkBuffer          ;

LB711:  LDY #$01                ;Increment buffer size.
LB713:  INC SubBufLength        ;
LB716:  JMP WorkBufEndChar      ;($B6D0)Place termination character on work buffer.

EndPlrl:
LB719:  LDY #$00                ;
LB71B:  JMP WorkBufEndChar      ;($B6D0)Place termination character on work buffer.

;----------------------------------------------------------------------------------------------------

DoPNTS:
LB71E:  LDY #$00                ;BCD value is 5 bytes max.
LB720:  LDA #$05                ;
LB722:  BNE +                   ;Branch always.

DoAMTP:
LB724:  JSR BinWordToBCD        ;($B6DA)Convert word in $00/$01 to BCD.

LB727:  LDA SubBufLength        ;
LB72A:  CLC                     ;Increase buffer length by 6.
LB72B:  ADC #$06                ;

LB72D:* STA SubBufLength        ;Set initial buffer length.

LB730:  LDX #$05                ;
LB732:* LDA PNTSTbl,X           ;
LB735:  STA WorkBuffer,Y        ;Load "Point" into work buffer.
LB738:  INY                     ;
LB739:  DEX                     ;
LB73A:  BPL -                   ;

LB73C:  LDA GenWrd00UB          ;
LB73E:  BNE +                   ;Is number to convert to BCD greater than 1? 
LB740:  LDX GenWrd00LB          ;If so, add an "s" to the end of "Point".
LB742:  DEX                     ;
LB743:  BEQ ++                  ;

LB745:* LDA #TXT_LWR_S          ;Add "s" to the end of the buffer.
LB747:  STA WorkBuffer,Y        ;
LB74A:  INY                     ;
LB74B:  INC SubBufLength        ;Increment buffer length.
LB74E:* JMP WorkBufEndChar      ;($B6D0)Place termination character on work buffer.

PNTSTbl:                        ;(Point backwards).
;              t    n    i    o    P   BLNK
LB751:  .byte $1D, $17, $12, $18, $33, $5F

;----------------------------------------------------------------------------------------------------

DoITEM:
LB757:  JSR GetDescHalves       ;($B75D)Get full description and store in work buffer.
LB75A:  JMP WorkBufEndChar      ;($B6D0)Place termination character on work buffer.

GetDescHalves:
LB75D:  LDA #$00                ;Start with first half of description.
LB75F:  STA WndDescHalf         ;

LB762:  JSR PrepGetDesc         ;($B77E)Do some prep then locate description.
LB765:  JSR UpdateDescBufLen    ;($B82B)Save desc buffer length and zero index.
LB768:  LDA #TL_BLANK_TILE1     ;
LB76A:  STA WorkBuffer,Y        ;Place a blank space between words.

LB76D:  INY                     ;
LB76E:  TYA                     ;Save pointer into work buffer.
LB76F:  PHA                     ;

LB770:  INC WndDescHalf         ;Do second half of description.
LB773:  JSR PrepGetDesc         ;($B77E)Do some prep then locate description.
LB776:  STY DescLength          ;Store length of description string.

LB779:  PLA                     ;Restore current index into the work buffer.
LB77A:  TAY                     ;
LB77B:  JMP XferTempToWork      ;($B830)Transfer temp buffer contents to work buffer.

PrepGetDesc:
LB77E:  LDA #$09                ;Set max buffer length to 9.
LB780:  STA SubBufLength        ;

LB783:  LDA #$20                ;
LB785:  STA WndOptions          ;Set some window parameters.
LB788:  LDA #$04                ;
LB78A:  STA WndParam            ;

LB78D:  LDA DescBuf             ;Load first byte from description buffer and remove upper 2 bits.
LB78F:  AND #$3F                ;
LB791:  JMP LookupDescriptions  ;($A790)Get description from tables.

DoDESC:
LB794:  JSR GetDescHalves       ;($B75D)Get full description and store in work buffer.
LB797:  JSR CheckAToAn          ;($B79D)Check if item starts with vowel and convert 'a' to 'an'.
LB79A:  JMP WorkBufEndChar      ;($B6D0)Place termination character on work buffer.

CheckAToAn:
LB79D:  JSR WorkBufShift        ;($B7CB)Shift work buffer to insert character.
LB7A0:  LDA WorkBuffer          ;Get first character in work buffer.
LB7A3:  CMP #TXT_UPR_A          ;'A'.
LB7A5:  BEQ VowelFound          ;A found?  If so, branch to add 'n'.
LB7A7:  CMP #TXT_UPR_I          ;'I'.
LB7A9:  BEQ VowelFound          ;I found?  If so, branch to add 'n'.
LB7AB:  CMP #TXT_UPR_U          ;'U'.
LB7AD:  BEQ VowelFound          ;U found?  If so, branch to add 'n'.
LB7AF:  CMP #TXT_UPR_E          ;'E'.
LB7B1:  BEQ VowelFound          ;E found?  If so, branch to add 'n'.
LB7B3:  CMP #TXT_UPR_O          ;'O'.
LB7B5:  BNE VowelNotFound       ;O found?  If so, branch to add 'n'.

VowelNotFound:
LB7B7:  LDA #TL_BLANK_TILE1     ;
LB7B9:  STA WorkBuffer          ;No vowel at start of description.  Just insert space.
LB7BC:  RTS                     ;

VowelFound:
LB7BD:  JSR WorkBufShift        ;($B7CB)Shift work buffer to insert character.
LB7C0:  LDA #TXT_LWR_N          ;'n'.
LB7C2:  STA WorkBuffer          ;Insert 'n' into work buffer.
LB7C5:  LDA #TL_BLANK_TILE1     ;
LB7C7:  STA WorkBuffer+1        ;Insert space into work buffer after 'n'.
LB7CA:  RTS                     ;

WorkBufShift:
LB7CB:  LDX #$26                ;Prepare to shift 39 bytes.

LB7CD:* LDA WorkBuffer,X        ;Move buffer value over 1 byte.
LB7D0:  STA WorkBuffer+1,X      ;
LB7D3:  DEX                     ;More to shift?
LB7D4:  BPL -                   ;If so, branch to shift next byte.

LB7D6:  INY                     ;Done shifting. Buffer is now 1 byte longer.
LB7D7:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DoSPEL:
LB7D8:  LDA #$09                ;Max. buffer length is 9.
LB7DA:  STA SubBufLength        ;

LB7DD:  LDA DescBuf             ;Get spell description byte.
LB7DF:  JSR WndGetSpellDesc     ;($A7EB)Get spell description.
LB7E2:  JSR UpdateDescBufLen    ;($B82B)Save desc buffer length and zero index.
LB7E5:  JMP WorkBufEndChar      ;($B6D0)Place termination character on work buffer.

;----------------------------------------------------------------------------------------------------

DoCOPY:
LB7E8:  LDX #$00                ;Start at beginning of buffers.

LB7EA:* LDA DescBuf,X           ;Copy description buffer byte into work buffer.
LB7EC:  STA WorkBuffer,X        ;
LB7EF:  INX                     ;
LB7F0:  CMP #TXT_SUBEND         ;End of buffer reached? If not, branch to copy more.
LB7F2:  BNE -                   ;

LB7F4:  LDX #$00                ;Reset index.
LB7F6:  JMP WorkBufDone         ;($B667)Done building work buffer.

;----------------------------------------------------------------------------------------------------

DoNAME:
LB7F9:  JSR NameToNameBuf       ;($B87F)Copy all 8 name bytes to name buffer.
LB7FC:  JSR NameBufToWorkBuf    ;($B81D)Copy name buffer to work buffer.

BufFinished:
LB7FF:  LDX #$00                ;Zero out index.
LB801:  JMP WorkBufDone         ;($B667)Done building work buffer.

;----------------------------------------------------------------------------------------------------

DoENMY:
LB804:  LDA EnNumber            ;Get current enemy number.
LB806:  JSR GetEnName           ;($B89F)Put enemy name into name buffer.
LB809:  JSR NameBufToWorkBuf    ;($B81D)Copy name buffer to work buffer.
LB80C:  JMP BufFinished         ;($B7FF)Finish building work buffer.

DoENM2:
LB80F:  LDA EnNumber            ;Get current enemy number.
LB811:  JSR GetEnName           ;($B89F)Put enemy name into name buffer.
LB814:  JSR NameBufToWorkBuf    ;($B81D)Copy name buffer to work buffer.
LB817:  JSR CheckAToAn          ;($B79D)Check if item starts with vowel and convert 'a' to 'an'.
LB81A:  JMP BufFinished         ;($B7FF)Finish building work buffer.

;----------------------------------------------------------------------------------------------------

NameBufToWorkBuf:
LB81D:  LDX #$00                ;Zero out index.
LB81F:* LDA NameBuffer,X        ;Copy name buffer byte to work buffer.
LB822:  STA WorkBuffer,X        ;

LB825:  INX                     ;
LB826:  CMP #TXT_SUBEND         ;Has end of buffer marker been reached?
LB828:  BNE -                   ;If not, branch to copy another byte.
LB82A:  RTS                     ;

;----------------------------------------------------------------------------------------------------

UpdateDescBufLen:
LB82B:  STY DescLength          ;Save length of description buffer.
LB82E:  LDY #$00                ;Zero index.

;----------------------------------------------------------------------------------------------------

XferTempToWork:
LB830:  LDX DescLength          ;Is there data to transfer?
LB833:  BEQ NoXfer              ;If not, branch to exit.

LB835:  LDA #$00                ;Start current index at 0.
LB837:  STA ThisTempIndex       ;
LB839:  LDX SubBufLength        ;X stores end index.

LB83C:* LDA TempBuffer-1,X      ;Transfer temp buffer byte into work buffer.
LB83F:  STA WorkBuffer,Y        ;

LB842:  DEX                     ;
LB843:  INY                     ;Update indexes.
LB844:  INC ThisTempIndex       ;

LB846:  LDA ThisTempIndex       ;At end of buffer?
LB848:  CMP DescLength          ;
LB84B:  BNE -                   ;If not, branch to get another byte.
LB84D:  RTS                     ;

NoXfer:
LB84E:  DEY                     ;Nothing to transfer. Decrement index and exit.
LB84F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

ClearDialogOutBuf:
LB850:  LDX #$00                ;Base of buffer.
LB852:  LDA #TL_BLANK_TILE1     ;Blank tile pattern table index.

LB854:* STA DialogOutBuf,X      ;Loop to load blank tiles into the dialog out buffer.
LB857:  INX                     ;
LB858:  CPX #$B0                ;Have 176 bytes been written?
LB85A:  BCC -                   ;If not, branch to continue writing.
LB85C:  RTS                     ;

;----------------------------------------------------------------------------------------------------

DialogToScreenBuf:
LB85D:  LDA #$08                ;Total rows=8.
LB85F:  STA RowsRemaining       ;

LB861:  LDX #$00                ;Zero out WinBufRAM index.
LB863:  LDY #$00                ;Zero out DialogOutBuf index.

NewDialogRow:
LB865:  LDA #$16                ;Total columns = 22.
LB867:  STA ColsRemaining       ;

CopyDialogByte:
LB869:  LDA DialogOutBuf,Y      ;Copy dialog buffer to background screen buffer.
LB86C:  STA WinBufRAM+$0265,X   ;

LB86F:  INX                     ;Increment screen buffer index.
LB870:  INY                     ;Increment dialog buffer index.

LB871:  DEC ColsRemaining       ;Are there stil characters left in current row?
LB873:  BNE CopyDialogByte      ;If so, branch to get next character.

LB875:  TXA                     ;
LB876:  CLC                     ;Move to next row in WinBufRAM by adding
LB877:  ADC #$0A                ;10 to the WinBufRAM index.
LB879:  TAX                     ;

LB87A:  DEC RowsRemaining       ;One more row completed.
LB87C:  BNE NewDialogRow        ;More rows left to get? If so, branch to get more.
LB87E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

NameToNameBuf:
LB87F:  LDY #$00                ;Zero indexes.
LB881:  LDX #$00                ;

LB883:* LDA DispName0,X         ;
LB885:  STA NameBuffer,Y        ;Copy name 2 bytes at a time into name buffer.
LB888:  LDA DispName4,X         ;
LB88B:  STA NameBuffer+4,Y      ;

LB88E:  INX                     ;Increment namme index.
LB88F:  INY                     ;Increment buffer index.

LB890:  CPY #$04                ;Has all 8 bytes been copied?
LB892:  BNE -                   ;If not, branch to copy 2 more bytes.

LB894:  LDY #$08                ;Start at last index in name buffer.
LB896:  JSR FindNameEnd         ;($B8D9)Find index of last character in name buffer.

EndNameBuf:
LB899:  LDA #TXT_SUBEND         ;
LB89B:  STA NameBuffer,Y        ;Put end of buffer marker after last character in name buffer.
LB89E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

GetEnName:
LB89F:  CLC                     ;
LB8A0:  ADC #$01                ;Increment enemy number and save it on the stack.
LB8A2:  PHA                     ;

LB8A3:  LDA #$00                ;Start with first half of name.
LB8A5:  STA WndDescHalf         ;

LB8A8:  LDA #$0B                ;Max buf length of first half of name is 11 characters.
LB8AA:  STA SubBufLength        ;

LB8AD:  PLA                     ;Restore enemy number.
LB8AE:  JSR GetEnDescHalf       ;($A801)Get first half of enemy name.

LB8B1:  LDY #$00                ;Start at beginning of name buffer.
LB8B3:  JSR AddTempBufToNameBuf ;($B8EA)Add temp buffer to name buffer.
LB8B6:  JSR FindNameEnd         ;($B8D9)Find index of last character in name buffer.

LB8B9:  LDA #TL_BLANK_TILE1     ;Store a blank tile after first half.
LB8BB:  STA NameBuffer,Y        ;

LB8BE:  INY                     ;
LB8BF:  TYA                     ;Move to next spot in name buffer and store the index.
LB8C0:  PHA                     ;

LB8C1:  INC WndDescHalf         ;Move to second half of enemy name.

LB8C4:  LDA #$09                ;Max buf length of second half of name is 9 characters.
LB8C6:  STA SubBufLength        ;

LB8C9:  LDA DescEntry           ;Not used in this set of functions.
LB8CB:  JSR GetEnDescHalf       ;($A801)Get second half of enemy name.

LB8CE:  PLA                     ;Restore index to end of namme buffer.
LB8CF:  TAY                     ;

LB8D0:  JSR AddTempBufToNameBuf ;($B8EA)Add temp buffer to name buffer.
LB8D3:  JSR FindNameEnd         ;($B8D9)Find index of last character in name buffer.
LB8D6:  JMP EndNameBuf          ;($B899)Put end of buffer character in name buffer.

;----------------------------------------------------------------------------------------------------

FindNameEnd:
LB8D9:  LDA NameBuffer-1,Y      ;Sart at end of name buffer.

LB8DC:  CMP #TL_BLANK_TILE2     ;Is current character not a blank space?
LB8DE:  BEQ +                   ;
LB8E0:  CMP #TL_BLANK_TILE1     ;
LB8E2:  BNE ++                  ;If not, branch to end.  Last character found.

LB8E4:* DEY                     ;Blank character space found.
LB8E5:  BMI +                   ;If no characters in buffer, branch to end.
LB8E7:  BNE FindNameEnd         ;If more characters in buffer, branch to process next character.
LB8E9:* RTS                     ;

;----------------------------------------------------------------------------------------------------

AddTempBufToNameBuf:
LB8EA:  LDX SubBufLength        ;Get pointer to end of temp buffer.

LB8ED:* LDA TempBuffer-1,X      ;Append temp buffer to name buffer.
LB8F0:  STA NameBuffer,Y        ;

LB8F3:  INY                     ;Increment index in name buffer.
LB8F4:  DEX                     ;Decrement index in temp buffer.

LB8F5:  BNE -                   ;More byte to append? if so branch to do more.
LB8F7:  RTS                     ;
LB8F8:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckBetweenWords:
LB8F9:  CMP #TXT_SUBEND         ;End of buffer marker.
LB8FB:  BCS NonWordChar         ;
LB8FD:  CMP #TL_BLANK_TILE1     ;Blank space.
LB8FF:  BEQ NonWordChar         ;
LB901:  CMP #TXT_PERIOD         ;"."(period).
LB903:  BEQ NonWordChar         ;
LB905:  CMP #TXT_COMMA          ;","(comma).
LB907:  BEQ NonWordChar         ;
LB909:  CMP #TXT_APOS           ;"'"(apostrophe).
LB90B:  BEQ NonWordChar         ;
LB90D:  CMP #TXT_PRD_QUOTE      ;".'"(Period end-quote).
LB90F:  BEQ NonWordChar         ;

LB911:  SEC                     ;Alpha-numberic character found. Set carry and return.
LB912:  RTS                     ;

NonWordChar:
LB913:  CLC                     ;Non-word character found. Clear carry and return.
LB914:  RTS                     ;

;----------------------------------------------------------------------------------------------------

CheckForNewLine:
LB915:  LDA WndXPosAW           ;Will this word extend to the end of the current text row?
LB918:  CMP #$16                ;If so, branch to move to the next line.
LB91A:  BCS MoveToNextLine      ;($B924)Move to the next line in the text window.
LB91C:  RTS                     ;

DoNewline:
LB91D:  LDA WndTxtXCoord        ;Update position after text word with current
LB91F:  STA WndXPosAW           ;cursor position.
LB922:  BEQ NewlineEnd          ;At beginning of text line? If so, branch to exit.

MoveToNextLine:
LB924:  LDX WndTxtYCoord        ;Move to the next line in the text window.
LB926:  INX                     ;

LB927:  CPX #$08                ;Are we at or beyond the last row in the dialog box?
LB929:  BCS ScrollDialog        ;If so, branch to scroll the dialog window.

LB92B:  LDA TxtLineSpace        ;
LB92E:  LSR                     ;
LB92F:  LSR                     ;It looks like there used to be some code for controlling
LB930:  EOR #$03                ;how many lines to skip when going to a new line. The value
LB932:  CLC                     ;in TxtLineSpace is always #$08 so the line always increments
LB933:  ADC WndTxtYCoord        ;by 1.
LB935:  STA WndTxtYCoord        ;

LineDone:
LB937:  LDA TxtIndent           ;
LB93A:  STA WndXPosAW           ;Add the indent value to the cursor X position.
LB93D:  STA WndTxtXCoord        ;

LB93F:  CLC                     ;Clear carry to indicate the line was incremented.

NewlineEnd:
LB940:  RTS                     ;End line increment.

;----------------------------------------------------------------------------------------------------

ScrollDialog:
LB941:  JSR Scroll1Line         ;($B967)Scroll dialog text up by one line.

LB944:  LDA TxtLineSpace        ;Is text double spaced?
LB947:  CMP #$04                ;If so, scroll up an additional line.
LB949:  BNE ScrollUpdate        ;Else update display with scrolled text.
LB94B:  JSR Scroll1Line         ;($B967)Scroll dialog text up by one line.

ScrollUpdate:
LB94E:  LDA #$13                ;Start dialog scrolling at line 19 on the screen.
LB950:  STA DialogScrlY         ;

LB953:  LDA #$00                ;Zero out buffer index.
LB955:  STA DialogScrlInd       ;

LB958:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.

LB95B:* JSR Display2ScrollLines ;($B990)Display two scrolled lines on screen.
LB95E:  LDA DialogScrlY         ;
LB961:  CMP #$1B                ;Has entire dialog window been updated?
LB963:  BCC -                   ;If not, branch to update more.
LB965:  BCS LineDone            ;($B937)Scroll done, branch to exit.

Scroll1Line:
LB967:  LDX #$00                ;Prepare to scroll dialog text.

ScrollDialogLoop:
LB969:  LDA DialogOutBuf+$16,X  ;Get byte to move up one row.
LB96C:  AND #$7F                ;
LB96E:  CMP #$76                ;Is it a text byte?
LB970:  BCS NextScrollByte      ;If not, branch to skip moving it up.

LB972:  PHA                     ;Get byte to be replaced.
LB973:  LDA DialogOutBuf,X      ;
LB976:  AND #$7F                ;
LB978:  CMP #$76                ;Is it a text byte?
LB97A:  PLA                     ;
LB97B:  BCS NextScrollByte      ;If not, branch to skip replacing byte.

LB97D:  STA DialogOutBuf,X      ;Move text byte up one row.

NextScrollByte:
LB980:  INX                     ;Increment to next byte.
LB981:  CPX #$9A                ;Have all the bytes been moved up?
LB983:  BNE ScrollDialogLoop    ;If not, branch to get next dialog byte.

_ClearDialogOutBuf:
LB985:  LDA #TL_BLANK_TILE1     ;Blank tile,
LB987:* STA DialogOutBuf,X      ;Write blank tiles to the entire text buffer.
LB98A:  INX                     ;
LB98B:  CPX #$B0                ;Has 176 bytes been written?
LB98D:  BNE -                   ;If not, branch to write more.
LB98F:  RTS                     ;

;----------------------------------------------------------------------------------------------------

Display2ScrollLines:
LB990:  JSR Display1ScrollLine  ;($B9A0)Write one line of scrolled text to the screen.
LB993:  INC DialogScrlY         ;Move to next dialog line to scroll up.
LB996:  JSR Display1ScrollLine  ;($B9A0)Write one line of scrolled text to the screen.
LB999:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LB99C:  INC DialogScrlY         ;Move to next dialog line to scroll up.
LB99F:  RTS                     ;

Display1ScrollLine:
LB9A0:  LDA DialogScrlY         ;
LB9A3:  STA ScrnTxtYCoord       ;Set indexes to the beginning of the line to scroll.
LB9A6:  LDA #$05                ;Dialog line starts on 5th screen tile.
LB9A8:  STA ScrnTxtXCoord       ;

DisplayScrollLoop:
LB9AB:  LDX DialogScrlInd       ;
LB9AE:  LDA DialogOutBuf,X      ;Get dialog buffer byte to update.
LB9B1:  STA PPUDataByte         ;Put it in the PPU buffer.
LB9B3:  JSR WndCalcPPUAddr      ;($ADC0)Calculate PPU address for window/text byte.
LB9B6:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LB9B9:  INC DialogScrlInd       ;
LB9BC:  INC ScrnTxtXCoord       ;Update buffer pointer and x cursor position.
LB9BF:  LDA ScrnTxtXCoord       ;

LB9C2:  CMP #$1B                ;Have all 22 text byte in the line been scrolled up?
LB9C4:  BNE DisplayScrollLoop   ;If not, branch to do the next one.
LB9C6:  RTS                     ;

;----------------------------------------------------------------------------------------------------

TextToPPU:
LB9C7:  PHA                     ;Save word buffer character.

LB9C8:  LDA WndTxtXCoord        ;Make sure x position before and after a word are the same.
LB9CA:  STA WndXPosAW           ;

LB9CD:  JSR CheckForNewLine     ;($B915)Move text to new line, if necessary.

LB9D0:  LDA WndTxtYCoord        ;Get row number.
LB9D2:  JSR CalcWndYByteNum     ;($BAA6)Calculate the byte number of row start in dialog window.
LB9D5:  ADC WndTxtXCoord        ;Add x position to get final buffer index value.
LB9D7:  TAX                     ;Save the index in X.

LB9D8:  PLA                     ;Restore the word buffer character.
LB9D9:  CMP #TL_BLANK_TILE1     ;Is it a blank tile?
LB9DB:  BEQ CheckXCoordIndent   ;If so, branch to check if the x position is at the indent mark.

LB9DD:  CMP #TXT_OPN_QUOTE      ;Is character an open quote?
LB9DF:  BNE CheckNextBufByte    ;If so, branch to skip any following spaces.

LB9E1:  LDY WndTxtXCoord        ;
LB9E3:  CPY #$01                ;Is the X coord at the indent?
LB9E5:  BNE CheckNextBufByte    ;If so, branch to skip any following spaces.

LB9E7:  DEY                     ;Move back a column to line things up properly.
LB9E8:  STY WndTxtXCoord        ;
LB9EA:  DEX                     ;
LB9EB:  JMP CheckNextBufByte    ;($B9F5)Check next buffer byte.

CheckXCoordIndent:
LB9EE:  LDY WndTxtXCoord        ;Is X position at the indent mark?
LB9F0:  CPY TxtIndent           ;
LB9F3:  BEQ EndTextToPPU        ;If so, branch to end.

CheckNextBufByte:
LB9F5:  PHA                     ;Save the word buffer character.
LB9F6:  LDA DialogOutBuf,X      ;Get next word in Dialog buffer
LB9F9:  STA PPUDataByte         ;and prepare to save it in the PPU.
LB9FB:  TAY                     ;
LB9FC:  PLA                     ;Restore original text byte. Is it a blank tile?
LB9FD:  CPY #TL_BLANK_TILE1     ;If so, branch.  This keeps the indent even.
LB9FF:  BNE +

LBA01:  STA DialogOutBuf,X      ;Store original character in PPU data byte.
LBA04:  STA PPUDataByte         ;

LBA06:* LDA TxtIndent           ;Is the text indented?
LBA09:  BEQ CalcTextWndPos      ;If not, branch to skip text SFX.

LBA0B:  LDA PPUDataByte         ;Is current PPU data byte a window non-character tile?
LBA0D:  CMP #TL_BLANK_TILE1     ;
LBA0F:  BCS CalcTextWndPos      ;If so, branch to skip text SFX.

LBA11:  LDA WndTxtXCoord        ;
LBA13:  LSR                     ;Only play text SFX every other printable character.
LBA14:  BCC CalcTextWndPos      ;

LBA16:  LDA #SFX_TEXT           ;Text SFX.
LBA18:  BRK                     ;
LBA19:  .byte $04, $17          ;($81A0)InitMusicSFX, bank 1.

CalcTextWndPos:
LBA1B:  LDA WndTxtXCoord        ;
LBA1D:  CLC                     ;Dialog text columns start on the 5th screen column.
LBA1E:  ADC #$05                ;Need to add current dialog column to this offset.
LBA20:  STA ScrnTxtXCoord       ;

LBA23:  LDA WndTxtYCoord        ;
LBA25:  CLC                     ;Dialog text lines start on the 19th screen line.
LBA26:  ADC #$13                ;Need to add current dialog line to this offset.
LBA28:  STA ScrnTxtYCoord       ;

LBA2B:  JSR WndCalcPPUAddr      ;($ADC0)Calculate PPU address for window/text byte.
LBA2E:  JSR AddPPUBufEntry      ;($C690)Add data to PPU buffer.

LBA31:  LDX MessageSpeed        ;Load text speed to use as counter to slow text.
LBA33:* JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LBA36:  DEX                     ;Delay based on message speed.
LBA37:  BPL -                   ;Loop to slow text speed.

LBA39:  INC WndTxtXCoord        ;Set pointer to X position for next character.

EndTextToPPU:
LBA3B:  RTS                     ;Done witing text character to PPU.

;----------------------------------------------------------------------------------------------------

;This code does not appear to be used.  It looks at a text byte and sets the carry if the character
;is a lowercase vowel or uppercase or a non-alphanumeric character. It clears the carry otherwise.

LBA3C:  LDA PPUDataByte         ;Prepare to look through vowel table below.
LBA3E:  LDX #$04                ;

LBA40:* CMP VowelTbl,X          ;Is text character a lowercase vowel?
LBA43:  BEQ TextSetCarry        ;If so, branch to set carry and exit.
LBA45:  DEX                     ;Done looking through vowel table?
LBA46:  BPL -                   ;If not, branch to look at next entry.

LBA48:  CMP #$24                ;Lowercase letters.
LBA4A:  BCC TextClearCarry      ;Is character lower case? If so, branch to clear carry.

LBA4C:  CMP #$56                ;non-alphanumeric characters.
LBA4E:  BCC TextSetCarry        ;If uppercase of other character, set carry.

TextClearCarry:
LBA50:  CLC                     ;Clear carry and return.
LBA51:  RTS                     ;

TextSetCarry:
LBA52:  SEC                     ;Set carry and return.
LBA53:  RTS                     ;

VowelTbl:
;              a    i    u    e    o
LBA54:  .byte $0A, $12, $1E, $0E, $18

;----------------------------------------------------------------------------------------------------

DoWait:
LBA59:  JSR TxtCheckInput       ;($BA97)Check for player button press.
LBA5C:  BNE TxtBtnPressed       ;Has A or B been pressed? If so, branch.

LBA5E:  LDA #$10                ;Initialize animation with down arrow visible.
LBA60:  STA FrameCounter        ;

TxtWaitLoop:
LBA62:  JSR TxtWaitAnim         ;($BA76)
LBA65:  JSR WaitForNMI          ;($FF74)Wait for VBlank interrupt.
LBA68:  JSR TxtCheckInput       ;($BA97)Check for player button press.
LBA6B:  BEQ TxtWaitLoop         ;Has A or B been pressed? If not, branch to loop.

TxtBtnPressed:
LBA6D:  JSR TxtClearArrow       ;($BA80)Clear down arrow animation.
LBA70:  LDA TxtIndent           ;
LBA73:  STA WndTxtXCoord        ;Start a new line with any active indentation.
LBA75:  RTS                     ;

TxtWaitAnim:
LBA76:  LDX #$43                ;Down arrow tile.
LBA78:  LDA FrameCounter        ;
LBA7A:  AND #$1F                ;Get bottom 5 bits of frame counter.
LBA7C:  CMP #$10                ;Is value >= 16?
LBA7E:  BCS +                   ;If so, branch to show down arrow tile.

TxtClearArrow:
LBA80:  LDX #TL_BLANK_TILE1     ;Blank tile.

LBA82:* STX PPUDataByte         ;Prepare to load arrow animation tile into PPU.

LBA84:  LDA #$10                ;Place wait animation tile in the middle X position on the screen.
LBA86:  STA ScrnTxtXCoord       ;

LBA89:  LDA WndTxtYCoord        ;
LBA8B:  CLC                     ;Dialog window starts 19 tiles from top of screen.
LBA8C:  ADC #$13                ;This converts window Y coords to screen Y coords.
LBA8E:  STA ScrnTxtYCoord       ;

LBA91:  JSR WndCalcPPUAddr      ;($ADC0)Calculate PPU address for window/text byte.
LBA94:  JMP AddPPUBufEntry      ;($C690)Add data to PPU buffer.

TxtCheckInput:
LBA97:  JSR GetJoypadStatus     ;($C608)Get input button presses.
LBA9A:  LDA JoypadBtns          ;Get joypad button presses.
LBA9C:  AND #IN_A_OR_B          ;Mask off everything except A and B buttons.
LBA9E:  RTS                     ;

;----------------------------------------------------------------------------------------------------

IncDialogPtr:
LBA9F:  INC DialogPtrLB         ;
LBAA1:  BNE +                   ;Increment dialog pointer.
LBAA3:  INC DialogPtrUB         ;
LBAA5:* RTS                     ;

;----------------------------------------------------------------------------------------------------

CalcWndYByteNum:
LBAA6:  STA TxtRowNum           ;Store row number in lower byte of multiplicand word.
LBAA8:  LDA #$00                ;
LBAAA:  STA TxtRowStart         ;Upper byte is always 0. Always start at beginning of row.

LBAAC:  LDX #TxtRowNum          ;Index to multiplicand word.
LBAAE:  LDA #$16                ;22 text characters per line.
LBAB0:  JSR IndexedMult         ;($A6EB)Find buffer index for start of row.

LBAB3:  LDA TxtRowNum           ;
LBAB5:  CLC                     ;Store results in A and return.
LBAB6:  RTS                     ;

;----------------------------------------------------------------------------------------------------

;Item descriptions, first table, first half.
ItemNames11TbL:
;              B    a    m    b    o    o  
LBAB7:  .byte $25, $0A, $16, $0B, $18, $18, $FF        
;              C    l    u    b   
LBABE:  .byte $26, $15, $1E, $0B, $FF
;              C    o    p    p    e    r   
LBAC3:  .byte $26, $18, $19, $19, $0E, $1B, $FF
;              H    a    n    d   
LBACA:  .byte $2B, $0A, $17, $0D, $FF
;              B    r    o    a    d   
LBACF:  .byte $25, $1B, $18, $0A, $0D, $FF
;              F    l    a    m    e   
LBAD5:  .byte $29, $15, $0A, $16, $0E, $FF
;              E    r    d    r    i    c    k    '    s   
LBADB:  .byte $28, $1B, $0D, $1B, $12, $0C, $14, $40, $1C, $FF
;              C    l    o    t    h    e    s   
LBAE5:  .byte $26, $15, $18, $1D, $11, $0E, $1C, $FF
;              L    e    a    t    h    e    r   
LBAED:  .byte $2F, $0E, $0A, $1D, $11, $0E, $1B, $FF
;              C    h    a    i    n   
LBAF5:  .byte $26, $11, $0A, $12, $17, $FF
;              H    a    l    f   
LBAFB:  .byte $2B, $0A, $15, $0F, $FF
;              F    u    l    l   
LBB00:  .byte $29, $1E, $15, $15, $FF
;              M    a    g    i    c   
LBB05:  .byte $30, $0A, $10, $12, $0C, $FF
;              E    r    d    r    i    c    k    '    s   
LBB0B:  .byte $28, $1B, $0D, $1B, $12, $0C, $14, $40, $1C, $FF
;              S    m    a    l    l   
LBB15:  .byte $36, $16, $0A, $15, $15, $FF
;              L    a    r    g    e   
LBB1B:  .byte $2F, $0A, $1B, $10, $0E, $FF
;              S    i    l    v    e    r   
LBB21:  .byte $36, $12, $15, $1F, $0E, $1B, $FF
;              H    e    r    b   
LBB28:  .byte $2B, $0E, $1B, $0B, $FF
;              T    o    r    c    h   
LBB2D:  .byte $37, $18, $1B, $0C, $11, $FF
;              D    r    a    g    o    n    '    s   
LBB33:  .byte $27, $1B, $0A, $10, $18, $17, $40, $1C, $FF
;              W    i    n    g    s   
LBB3C:  .byte $3A, $12, $17, $10, $1C, $FF
;              M    a    g    i    c   
LBB42:  .byte $30, $0A, $10, $12, $0C, $FF
;              F    a    i    r    y   
LBB48:  .byte $29, $0A, $12, $1B, $22, $FF
;              B    a    l    l    _    o    f   
LBB4E:  .byte $25, $0A, $15, $15, $5F, $18, $0F, $FF
;              T    a    b    l    e    t   
LBB56:  .byte $37, $0A, $0B, $15, $0E, $1D, $FF
;              F    a    i    r    y   
LBB5D:  .byte $29, $0A, $12, $1B, $22, $FF
;              S    i    l    v    e    r   
LBB63:  .byte $36, $12, $15, $1F, $0E, $1B, $FF
;              S    t    a    f    f    _    o    f   
LBB6A:  .byte $36, $1D, $0A, $0F, $0F, $5F, $18, $0F, $FF
;              S    t    o    n    e    s    _    o    f   
LBB73:  .byte $36, $1D, $18, $17, $0E, $1C, $5F, $18, $0F, $FF
;              G    w    a    e    l    i    n    '    s   
LBB7D:  .byte $2A, $20, $0A, $0E, $15, $12, $17, $40, $1C, $FF
;              R    a    i    n    b    o    w   
LBB87:  .byte $35, $0A, $12, $17, $0B, $18, $20, $FF

;----------------------------------------------------------------------------------------------------

;Item descriptions, second table, first half.
ItemNames21TbL:
;              C    u    r    s    e    d   
LBB8F:  .byte $26, $1E, $1B, $1C, $0E, $0D, $FF
;              D    e    a    t    h   
LBB96:  .byte $27, $0E, $0A, $1D, $11, $FF
;              F    i    g    h    t    e    r    '    s   
LBB9C:  .byte $29, $12, $10, $11, $1D, $0E, $1B, $40, $1C, $FF
;              E    r    d    r    i    c    k    '    s   
LBBA6:  .byte $28, $1B, $0D, $1B, $12, $0C, $14, $40, $1C, $FF
;              S    e    c    r    e    t   
LBBB0:  .byte $36, $0E, $0C, $1B, $0E, $1D, $FF

;----------------------------------------------------------------------------------------------------

;Item descriptions, first table, second half.
ItemNames12TbL:
;              P    o    l    e   
LBBB7:  .byte $33, $18, $15, $0E, $FF
;             None
LBBBC:  .byte $FF
;              S    w    o    r    d   
LBBBD:  .byte $36, $20, $18, $1B, $0D, $FF
;              A    x    e   
LBBC3:  .byte $24, $21, $0E, $FF
;              S    w    o    r    d   
LBBC7:  .byte $36, $20, $18, $1B, $0D, $FF
;              S    w    o    r    d   
LBBCD:  .byte $36, $20, $18, $1B, $0D, $FF
;              S    w    o    r    d   
LBBD3:  .byte $36, $20, $18, $1B, $0D, $FF
;             None
LBBD4:  .byte $FF
;              A    r    m    o    r   
LBBDA:  .byte $24, $1B, $16, $18, $1B, $FF
;              M    a    i    l   
LBBE0:  .byte $30, $0A, $12, $15, $FF
;              P    l    a    t    e   
LBBE5:  .byte $33, $15, $0A, $1D, $0E, $FF
;              P    l    a    t    e   
LBBEB:  .byte $33, $15, $0A, $1D, $0E, $FF
;              A    r    m    o    r   
LBBF1:  .byte $24, $1B, $16, $18, $1B, $FF
;              A    r    m    o    r   
LBBF7:  .byte $24, $1B, $16, $18, $1B, $FF
;              S    h    i    e    l    d   
LBBFD:  .byte $36, $11, $12, $0E, $15, $0D, $FF
;              S    h    i    e    l    d   
LBC04:  .byte $36, $11, $12, $0E, $15, $0D, $FF
;              S    h    i    e    l    d   
LBC0B:  .byte $36, $11, $12, $0E, $15, $0D, $FF
;             None
LBC12:  .byte $FF
;             None
LBC13:  .byte $FF
;              S    c    a    l    e   
LBC14:  .byte $36, $0C, $0A, $15, $0E, $FF
;             None
LBC1A:  .byte $FF
;              K    e    y   
LBC1B:  .byte $2E, $0E, $22, $FF
;              W    a    t    e    r   
LBC1F:  .byte $3A, $0A, $1D, $0E, $1B, $FF
;              L    i    g    h    t   
LBC25:  .byte $2F, $12, $10, $11, $1D, $FF
;             None
LBC2B:  .byte $FF
;              F    l    u    t    e   
LBC2C:  .byte $29, $15, $1E, $1D, $0E, $FF
;              H    a    r    p   
LBC32:  .byte $2B, $0A, $1B, $19, $FF
;              R    a    i    n   
LBC37:  .byte $35, $0A, $12, $17, $FF
;              S    u    n    l    i    g    h    t   
LBC3C:  .byte $36, $1E, $17, $15, $12, $10, $11, $1D, $FF
;              L    o    v    e   
LBC45:  .byte $2F, $18, $1F, $0E, $FF
;              D    r    o    p   
LBC4A:  .byte $27, $1B, $18, $19, $FF

;----------------------------------------------------------------------------------------------------

;Item descriptions, second table, second half.
ItemNames22TbL:
;              B    e    l    t   
LBC4F:  .byte $25, $0E, $15, $1D, $FF
;              N    e    c    k    l    a    c    e   
LBC54:  .byte $31, $0E, $0C, $14, $15, $0A, $0C, $0E, $FF
;              R    i    n    g   
LBC5D:  .byte $35, $12, $17, $10, $FF
;              T    o    k    e    n   
LBC62:  .byte $37, $18, $14, $0E, $17, $FF
;              P    a    s    s    a    g    e   
LBC68:  .byte $33, $0A, $1C, $1C, $0A, $10, $0E, $FF

;----------------------------------------------------------------------------------------------------

;Enemy names, first half.
EnNames1Tbl:
;              S    l    i    m    e   
LBC70:  .byte $36, $15, $12, $16, $0E, $FF
;              R    e    d   
LBC76:  .byte $35, $0E, $0D, $FF
;              D    r    a    k    e    e   
LBC7A:  .byte $27, $1B, $0A, $14, $0E, $0E, $FF
;              G    h    o    s    t   
LBC81:  .byte $2A, $11, $18, $1C, $1D, $FF
;              M    a    g    i    c    i    a    n   
LBC87:  .byte $30, $0A, $10, $12, $0C, $12, $0A, $17, $FF
;              M    a    g    i    d    r    a    k    e    e   
LBC90:  .byte $30, $0A, $10, $12, $0D, $1B, $0A, $14, $0E, $0E, $FF
;              S    c    o    r    p    i    o    n   
LBC9B:  .byte $36, $0C, $18, $1B, $19, $12, $18, $17, $FF
;              D    r    u    i    n   
LBCA4:  .byte $27, $1B, $1E, $12, $17, $FF
;              P    o    l    t    e    r    g    e    i    s    t   
LBCAA:  .byte $33, $18, $15, $1D, $0E, $1B, $10, $0E, $12, $1C, $1D, $FF
;              D    r    o    l    l   
LBCB6:  .byte $27, $1B, $18, $15, $15, $FF
;              D    r    a    k    e    e    m    a   
LBCBC:  .byte $27, $1B, $0A, $14, $0E, $0E, $16, $0A, $FF
;              S    k    e    l    e    t    o    n   
LBCC5:  .byte $36, $14, $0E, $15, $0E, $1D, $18, $17, $FF
;              W    a    r    l    o    c    k   
LBCCE:  .byte $3A, $0A, $1B, $15, $18, $0C, $14, $FF
;              M    e    t    a    l   
LBCD6:  .byte $30, $0E, $1D, $0A, $15, $FF
;              W    o    l    f   
LBCDC:  .byte $3A, $18, $15, $0F, $FF
;              W    r    a    i    t    h   
LBCE1:  .byte $3A, $1B, $0A, $12, $1D, $11, $FF
;              M    e    t    a    l   
LBCE8:  .byte $30, $0E, $1D, $0A, $15, $FF
;              S    p    e    c    t    e    r   
LBCEE:  .byte $36, $19, $0E, $0C, $1D, $0E, $1B, $FF
;              W    o    l    f    l    o    r    d   
LBCF6:  .byte $3A, $18, $15, $0F, $15, $18, $1B, $0D, $FF
;              D    r    u    i    n    l    o    r    d   
LBCFF:  .byte $27, $1B, $1E, $12, $17, $15, $18, $1B, $0D, $FF
;              D    r    o    l    l    m    a    g    i   
LBD09:  .byte $27, $1B, $18, $15, $15, $16, $0A, $10, $12, $FF
;              W    y    v    e    r    n   
LBD13:  .byte $3A, $22, $1F, $0E, $1B, $17, $FF
;              R    o    g    u    e   
LBD1A:  .byte $35, $18, $10, $1E, $0E, $FF
;              W    r    a    i    t    h   
LBD20:  .byte $3A, $1B, $0A, $12, $1D, $11, $FF
;              G    o    l    e    m   
LBD27:  .byte $2A, $18, $15, $0E, $16, $FF
;              G    o    l    d    m    a    n   
LBD2D:  .byte $2A, $18, $15, $0D, $16, $0A, $17, $FF
;              K    n    i    g    h    t   
LBD35:  .byte $2E, $17, $12, $10, $11, $1D, $FF
;              M    a    g    i    w    y    v    e    r    n   
LBD3C:  .byte $30, $0A, $10, $12, $20, $22, $1F, $0E, $1B, $17, $FF
;              D    e    m    o    n   
LBD47:  .byte $27, $0E, $16, $18, $17, $FF
;              W    e    r    e    w    o    l    f   
LBD4D:  .byte $3A, $0E, $1B, $0E, $20, $18, $15, $0F, $FF
;              G    r    e    e    n   
LBD56:  .byte $2A, $1B, $0E, $0E, $17, $FF
;              S    t    a    r    w    y    v    e    r    n   
LBD5C:  .byte $36, $1D, $0A, $1B, $20, $22, $1F, $0E, $1B, $17, $FF
;              W    i    z    a    r    d   
LBD67:  .byte $3A, $12, $23, $0A, $1B, $0D, $FF
;              A    x    e   
LBD6E:  .byte $24, $21, $0E, $FF
;              B    l    u    e   
LBD72:  .byte $25, $15, $1E, $0E, $FF
;              S    t    o    n    e    m    a    n   
LBD77:  .byte $36, $1D, $18, $17, $0E, $16, $0A, $17, $FF
;              A    r    m    o    r    e    d   
LBD80:  .byte $24, $1B, $16, $18, $1B, $0E, $0D, $FF
;              R    e    d   
LBD88:  .byte $35, $0E, $0D, $FF
;              D    r    a    g    o    n    l    o    r    d   
LBD8C:  .byte $27, $1B, $0A, $10, $18, $17, $15, $18, $1B, $0D, $FF
;              D    r    a    g    o    n    l    o    r    d   
LBD97:  .byte $27, $1B, $0A, $10, $18, $17, $15, $18, $1B, $0D, $FF

;----------------------------------------------------------------------------------------------------

;Enemy names, second half.
EnNames2Tbl:
;             None
LBDA2:  .byte $FF
;              S    l    i    m    e   
LBDA3:  .byte $36, $15, $12, $16, $0E, $FF
;             None
LBDA9:  .byte $FF
;             None
LBDAA:  .byte $FF
;             None
LBDAB:  .byte $FF
;             None
LBDAC:  .byte $FF
;             None
LBDAD:  .byte $FF
;             None
LBDAE:  .byte $FF
;             None
LBDAF:  .byte $FF
;             None
LBDB0:  .byte $FF
;             None
LBDB1:  .byte $FF
;             None
LBDB2:  .byte $FF
;             None
LBDB3:  .byte $FF
;              S    c    o    r    p    i    o    n   
LBDB4:  .byte $36, $0C, $18, $1B, $19, $12, $18, $17, $FF
;             None
LBDBD:  .byte $FF
;             None
LBDBE:  .byte $FF
;              S    l    i    m    e   
LBDBF:  .byte $36, $15, $12, $16, $0E, $FF
;             None
LBDC5:  .byte $FF
;             None
LBDC6:  .byte $FF
;             None
LBDC7:  .byte $FF
;             None
LBDC8:  .byte $FF
;             None
LBDC9:  .byte $FF
;              S    c    o    r    p    i    o    n   
LBDCA:  .byte $36, $0C, $18, $1B, $19, $12, $18, $17, $FF
;              K    n    i    g    h    t   
LBDD3:  .byte $2E, $17, $12, $10, $11, $1D, $FF
;             None
LBDDA:  .byte $FF
;             None
LBDDB:  .byte $FF
;             None
LBDDC:  .byte $FF
;             None
LBDDD:  .byte $FF
;              K    n    i    g    h    t   
LBDDE:  .byte $2E, $17, $12, $10, $11, $1D, $FF
;             None
LBDE5:  .byte $FF
;              D    r    a    g    o    n   
LBDE6:  .byte $27, $1B, $0A, $10, $18, $17, $FF
;             None
LBDED:  .byte $FF
;             None
LBDEE:  .byte $FF
;              K    n    i    g    h    t   
LBDEF:  .byte $2E, $17, $12, $10, $11, $1D, $FF
;              D    r    a    g    o    n   
LBDF6:  .byte $27, $1B, $0A, $10, $18, $17, $FF
;             None
LBDFD:  .byte $FF
;              K    n    i    g    h    t   
LBDFE:  .byte $2E, $17, $12, $10, $11, $1D, $FF
;              D    r    a    g    o    n   
LBE05:  .byte $27, $1B, $0A, $10, $18, $17, $FF
;             None
LBE0C:  .byte $FF
;             None
LBE0D:  .byte $FF

;----------------------------------------------------------------------------------------------------

WndCostTblPtr:
LBE0E:  .word WndCostTbl        ;($BE10)Pointer to table below.

WndCostTbl:
LBE10:  .word $000A             ;Bamboo pole        - 10    gold.
LBE12:  .word $003C             ;Club               - 60    gold.
LBE14:  .word $00B4             ;Copper sword       - 180   gold.
LBE16:  .word $0230             ;Hand axe           - 560   gold.
LBE18:  .word $05DC             ;Broad sword        - 1500  gold.
LBE1A:  .word $2648             ;Flame sword        - 9800  gold.
LBE1C:  .word $0002             ;Erdrick's sword    - 2     gold.
LBE1E:  .word $0014             ;Clothes            - 20    gold.
LBE20:  .word $0046             ;Leather armor      - 70    gold.
LBE22:  .word $012C             ;Chain mail         - 300   gold.
LBE24:  .word $03E8             ;Half plate         - 1000  gold.
LBE26:  .word $0BB8             ;Full plate         - 3000  gold.
LBE28:  .word $1E14             ;Magic armor        - 7700  gold.
LBE2A:  .word $0002             ;Erdrick's armor    - 2     gold.
LBE2C:  .word $005A             ;Small shield       - 90    gold.
LBE2E:  .word $0320             ;Large shield       - 800   gold.
LBE30:  .word $39D0             ;Silver shield      - 14800 gold.
LBE32:  .word $0018             ;Herb               - 24    gold.
LBE34:  .word $0008             ;Torch              - 8     gold.
LBE36:  .word $0014             ;Dragon's scale     - 20    gold.
LBE38:  .word $0046             ;Wings              - 70    gold.
LBE3A:  .word $0035             ;Magic key          - 53    gold.
LBE3C:  .word $0026             ;Fairy water        - 38    gold.
LBE3E:  .word $0000             ;Ball of light      - 0     gold.
LBE40:  .word $0000             ;Tablet             - 0     gold.
LBE42:  .word $0000             ;Fairy flute        - 0     gold.
LBE44:  .word $0000             ;Silver harp        - 0     gold.
LBE46:  .word $0000             ;Staff of rain      - 0     gold.
LBE48:  .word $0000             ;Stones of sunlight - 0     gold.
LBE4A:  .word $0000             ;Gwaelin's love     - 0     gold.
LBE4C:  .word $0000             ;Stones of sunlight - 0     gold.
LBE4E:  .word $0168             ;Cursed belt        - 360   gold.
LBE50:  .word $0960             ;Death necklace     - 2400  gold.
LBE52:  .word $001E             ;Fighter's ring     - 30    gold.
LBE54:  .word $0000             ;Erdrick's token    - 0     gold.

;----------------------------------------------------------------------------------------------------

;Spell nammes.  Unlike the other tables, the spell names do not have a second half.

SpellNameTbl:
;              H    E    A    L
LBE56:  .byte $2B, $28, $24, $2F, $FF
;              H    U    R    T
LBE5B:  .byte $2B, $38, $35, $37, $FF
;              S    L    E    E    P
LBE60:  .byte $36, $2F, $28, $28, $33, $FF
;              R    A    D    I    A    N    T
LBE66:  .byte $35, $24, $27, $2C, $24, $31, $37, $FF
;              S    T    O    P    S    P    E    L    L
LBE6E:  .byte $36, $37, $32, $33, $36, $33, $28, $2F, $2F, $FF
;              O    U    T    S    I    D    E
LBE78:  .byte $32, $38, $37, $36, $2C, $27, $28, $FF
;              R    E    T    U    R    N
LBE80:  .byte $35, $28, $37, $38, $35, $31, $FF
;              R    E    P    E    L
LBE87:  .byte $35, $28, $33, $28, $2F, $FF
;              H    E    A    L    M    O    R    E
LBE8D:  .byte $2B, $28, $24, $2F, $30, $32, $35, $28, $FF
;              H    U    R    T    M    O    R    E
LBE96:  .byte $2B, $38, $35, $37, $30, $32, $35, $28, $FF

;----------------------------------------------------------------------------------------------------

;Unused.
LBE9F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
LBEAF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBEBF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBECF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBEDF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBEEF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBEFF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF0F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF1F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF2F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF3F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF4F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF5F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF6F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF7F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF8F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBF9F:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBFAF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBFBF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
LBFCF:  .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

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
