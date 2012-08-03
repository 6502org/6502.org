;*********************************************************************
;  2005/09/04	RAC	Synched with SBCOS 5/30/05 release
;---------------------------------------------------------------------
;  SBC Firmware V5.1, 5-30-05, by Daryl Rictor
;  SBC Firmware V5.0, 8-19-03, by Daryl Rictor
;
; ----------------- assembly instructions ---------------------------- 
;               *= $E700                ; start of operating system
Start_OS	jmp MonitorBoot         ; easy access to monitor program
Jmp_CR		jmp   Print_CR		
Jmp_1sp	   	jmp   Print1SP		; jump table for usable monitor
Jmp_2sp	  	jmp   Print2SP		; routines
Jmp_xsp	  	jmp   PrintXSP		; This will not change in future
Jmp_nib	   	jmp   PrintDig		; releases, only be added to
Jmp_byte	jmp   Print1Byte
jmp_wrd	   	jmp   Print2Byte
jmp_bell	jmp   Bell
jmp_delay	jmp   Delay
jmp_scan	jmp   Scan_input
jmp_inp		jmp   Input_chr  
jmp_out		jmp   Output
jmp_input	jmp   Input
jmp_input1	jmp   Input1
;
;
;*********************************************************************       
;  local Zero-page variables
;
Prompt         =     $32               ; 1 byte   
linecnt        =     $33               ; 1 byte
Modejmp        =     $34               ; 1 byte
Hexdigcnt      =     $35               ; 1 byte
OPCtxtptr      =     $36               ; 1 byte
Memchr         =     $37               ; 1 byte
Startaddr      =     $38               ; 2 bytes
Startaddr_H    =     $39
Addrptr        =     $3a               ; 2 bytes
Addrptr_H       =    $3b
Hexdigits      =     $3c               ; 2 bytes
Hexdigits_H    =     $3d
Memptr         =     $3e               ; 2 bytes
Memptr_H       =     $3f
;
; Local Non-Zero Page Variables
;
buffer         =     $0300             ; keybd input buffer (127 chrs max)
PCH            =     $03e0             ; hold program counter (need PCH next to PCL for Printreg routine)
PCL            =     $03e1             ;  ""
ACC            =     $03e2             ; hold Accumulator (A)
XREG           =     $03e3             ; hold X register
YREG           =     $03e4             ; hold Y register
SPTR           =     $03e5             ; hold stack pointer
PREG           =     $03e6             ; hold status register (P)
ChrInVect      =     $03eb             ; holds Character Input Address
ScanInVect     =     $03ee             ; holds Character Scan Input address
ChrOutVect     =     $03f1             ; holds Character Output Address
BRKvector      =     $03f4             ; holds application break vector
RESvector      =     $03f7             ; 2F7,8,9 holds application reset vector & checksum
INTvector      =     $03fa             ; 2FA,B,C holds application interrupt vector & checksum
NMIvector      =     $03fd             ; 2FD,E,F holds application NMI vector & checksum

;               
; *************************************************************************
; kernal commands
; *************************************************************************
; PrintRegCR   - subroutine prints a CR, the register contents, CR, then returns
; PrintReg     - same as PrintRegCR without leading CR
; Print2Byte   - prints AAXX hex digits
; Print1Byte   - prints AA hex digits
; PrintDig     - prints A hex nibble (low 4 bits)
; Print_CR     - prints a CR (ASCII 13)and LF (ASCII 10)
; PrintXSP     - prints # of spaces in X Reg
; Print2SP     - prints 2 spaces
; Print1SP     - prints 1 space
; Input_dos    - Alternate prompt for DOS
; Input_assem  - Alternate input prompt for Assember
; Input        - print <CR> and prompt then get a line of input, store at buffer
; Input_Chr    - get one byte from input port, waits for input
; Scan_Input   - Checks for an input character (no waiting)
; Output       - send one byte to the output port
; Bell         - send ctrl-g (bell) to output port
; Delay        - delay loop
; *************************************************************************
;
RegData        .byte" PC=  A=  X=  Y=  S=  P= (NVRBDIZC)="
;
PrintReg       Jsr   Print_CR          ; Lead with a CR
               ldx   #$ff              ;
               ldy   #$ff              ;
Printreg1      iny                     ;
               lda   Regdata,y         ;
               jsr   Output            ;
               cmp   #$3D              ; "="
               bne   Printreg1         ;
Printreg2      inx                     ;
               cpx   #$07              ;
               beq   Printreg3         ; done with first 6
               lda   PCH,x             ;  
               jsr   Print1Byte        ;
               cpx   #$00              ;
               bne   Printreg1         ;
               bra   Printreg2         ;
Printreg3      dex                     ;
               lda   PCH,x             ; get Preg
               ldx   #$08              ; 
Printreg4      rol                     ;
               tay                     ;
               lda   #$31              ;
               bcs   Printreg5         ;
               dec                     ;
Printreg5      jsr   Output            ;
               tya                     ;
               dex                     ;
               bne   Printreg4         ;
; fall into the print CR routine
Print_CR       PHA                     ; Save Acc
               LDA   #$0D              ; "cr"
               JSR   OUTPUT            ; send it
               LDA   #$0A              ; "lf"
               JSR   OUTPUT            ; send it
               PLA                     ; Restore Acc
               RTS                     ; 

Print2Byte     JSR   Print1Byte        ;  prints AAXX hex digits
               TXA                     ;
Print1Byte     PHA                     ;  prints AA hex digits
               LSR                     ;  MOVE UPPER NIBBLE TO LOWER
               LSR                     ;
               LSR                     ;
               LSR                     ;
               JSR   PrintDig          ;
               PLA                     ;
PrintDig       PHY                     ;  prints A hex nibble (low 4 bits)
               AND   #$0F              ;
               TAY                     ;
               LDA   Hexdigdata,Y      ;
               PLY                     ;
               jmp   output            ;
PrintXSP1      JSR   Print1SP          ;
               dex                     ;
PrintXSP       cpx   #$00              ;
               bne   PrintXSP1         ;
               rts                     ;
Print2SP       jsr   Print1SP          ; print 2 SPACES
Print1SP       LDA   #$20              ; print 1 SPACE
               JMP   OUTPUT            ;
;
Input_Dos      lda   #$3e	       ; DOS prompt ">"
		.byte $2c
Input_Assem    lda   #$21              ; Assembler Prompt "!"
               .byte $2c               ; mask out next line to bypass 
Input          lda   #$2A              ; Monitor Prompt "*"
               sta   Prompt            ; save prompt chr 
Input1         jsr   Print_CR          ; New Line
               lda   Prompt            ; get prompt
               jsr   Output            ; Print Prompt
               ldy   #$ff              ; pointer
InputWait      jsr   Input_Chr         ; get a character
               cmp   #$20              ; is ctrl char?
               BCS   InputSave         ; no, echo chr 
               cmp   #$0d              ; cr
               Beq   InputDone         ; done
               cmp   #$1B              ; esc
               beq   Input1            ; cancel and new line
               cmp   #$08              ; bs
               beq   backspace         ;
	       cmp   #$09		   ; TAB key
	       beq   tabkey		   ;
               cmp   #$02              ; Ctrl-B
               bne   InputWait         ; Ignore other codes
               brk                     ; Force a keyboard Break cmd
backspace      cpy   #$ff              ;
               beq   InputWait         ; nothing to do
               dey                     ; remove last char
               Lda   #$08              ; backup one space
               jsr   Output            ;
               Lda   #$20              ; Print space (destructive BS)
               jsr   Output            ;
               Lda   #$08              ; backup one space
               jsr   Output            ;
               BRA   InputWait         ; ready for next key
tabkey	   lda   #$20		   ; convert tab to space
		   iny			   ; move cursor
               bmi   InputTooLong	   ; line too long?
               sta   Buffer,y		   ; no, save space in buffer
		   jsr   output		   ; print the space too
               tya   			   ; test to see if tab is on multiple of 8
		   and   #$07		   ; mask remainder of cursor/8
               bne   tabkey		   ; not done, add another space
		   bra   InputWait	   ; done. 
InputSave      CMP   #$61              ;   ucase
               BCC   InputSave1        ;
               SBC   #$20              ;
InputSave1     INY                     ;
               BMI   InputTooLong      ; get next char (up to 127)
               STA   Buffer,y          ;
               JSR   Output            ; OutputCharacter
               BRA   InputWait         ;
InputDone      INY                     ;
InputTooLong   LDA   #$0d              ; force CR at end of 128 characters 
               sta   Buffer,y          ;
               JSR   Output            ;
;               lda   #$0a              ; lf Char   
;               JSR   Output            ;
               RTS                     ;
;
Input_chr      jmp   (ChrInVect)       ;
Scan_input     jmp   (ScanInVect)      ; 
Output         jmp   (ChrOutVect)      ;
;
bell           LDA  #$07               ; Ctrl G Bell
               jmp  Output             ; 
;
Delay          PHA                     ; use A to execute a delay loop
delay1         DEC                     ;
               BNE   delay1            ;
               PLA                     ;
               DEC                     ;
               BNE   Delay             ;
GRTS           RTS                     ;
;
;
BRKroutine     sta   ACC               ; save A    Monitor"s break handler
               stx   Xreg              ; save X
               sty   Yreg              ; save Y
               pla                     ; 
               sta   Preg              ; save P
               pla                     ; PCL
               plx                     ; PCH
               sec                     ;
               sbc   #$02              ;
               sta   PCL               ; backup to BRK cmd
               bcs   Brk2              ;
               dex                     ;
Brk2           stx   PCH               ; save PC
               TSX                     ; get stack pointer
               stx   SPtr              ; save stack pointer
               jsr   Bell              ; Beep speaker
               jsr   PrintReg          ; dump register contents 
               ldx   #$FF              ; 
               txs                     ; clear stack
               cli                     ; enable interrupts again
               jmp   Monitor           ; start the monitor

;*************************************************************************
;     
;  Monitor Program 
;
;**************************************************************************
MonitorBoot    
               jsr   bell              ; beep ready
               JSR   Version           ;
Monitor        LDX   #$FF              ; 
               TXS		       ;  Init the stack
               JSR   IEC_Init	       ; call CBM_IEC initialization
               JSR   input             ;  line input
               LDA   #$00              ;
               TAY                     ;  set to 1st character in line
               sta   LineCnt           ; normal list vs range list 
Mon01          STA   Memchr            ;
Mon02          STZ   Hexdigits         ;  holds parsed hex
               STZ   Hexdigits+1       ;
               JSR   ParseHexDig       ;  Get any Hex chars
               LDX   #CmdCount         ;  get # of cmds currently used
Mon08          CMP   CmdAscii,X        ;  is non hex cmd chr?
               BEQ   Mon09             ;  yes x= cmd number
               DEX                     ;
               BPL   Mon08             ;
               BRA   Monitor           ;  no
Mon09          PHX                     ;  save command
               PHY                     ;  Save input line pointer
               TXA                     ;
               ASL                     ;  ptr * 2
               TAX                     ;  
               JSR   Mon10             ;  Execute cmd
               PLY                     ;
               PLX                     ;
               BEQ   Monitor           ;  done
               LDA   Cmdseccode,X      ;  
               BMI   Mon02             ;
               BRA   Mon01             ;
Mon10          JMP   (Cmdjmptbl,X)     ;
;--------------- Routines used by the Monitor commands ----------------------
ParseHexDig    STZ   Hexdigcnt         ;  cntr
               BRA   ParseHex05        ;
ParseHex03     TXA                     ;  parse hex dig
               LDX   #$04              ;  
ParseHex04     ASL   Hexdigits         ;
               ROL   Hexdigits+1       ;
               DEX                     ;
               BNE   ParseHex04        ;
               TSB   Hexdigits         ;
               DEC   Hexdigcnt         ;
ParseHex05     LDA   buffer,Y          ;
               LDX   #$0F              ;   is hex chr?
               INY                     ;
ParseHex07     CMP   Hexdigdata,X      ;
               BEQ   ParseHex03        ;   yes
               DEX                     ;
               BPL   ParseHex07        ;
               RTS                     ; Stored in HexDigits if HexDigCnt <> 0
;
Help_cmd       lda   #<Helptxt         ;  lower byte - Menu of Commands
               sta   addrptr           ;
               lda   #>Helptxt         ;  upper byte
               sta   addrptr+1         ;
               bra   Help_cmd3         ;
Help_Cmd4      cmp   #$7e              ;  "~"
               beq   Help_Cmd1         ;
               jsr   Output            ;
               bra   Help_cmd2         ;
Help_cmd1      jsr   Print_CR          ;     
Help_cmd2      jsr   Inc_addrptr       ;
Help_cmd3      lda   (addrptr)         ;
               bne   Help_cmd4         ;
               rts                     ;
Version        jsr   Print_CR          ; 
               ldx   #$FF              ; set txt pointer
               lda   #$0d              ; 
PortReadyMsg   inx                     ;
               JSR   Output            ; put character to Port
               lda   porttxt,x         ; get message text
               bne   PortReadyMsg      ; 
               rts                     ;
;
Excute_cmd     jsr   exe1              ;
               ldx   #$FF              ; reset stack
               txs                     ;
               jmp   Monitor           ;
exe1           JMP   (Hexdigits)       ;
;
DOT_cmd        LDX   Hexdigits         ; move address to addrptr
               LDA   Hexdigits+1       ;
               STX   Addrptr           ;
               STA   Addrptr+1         ;
               inc   LineCnt           ; range list command
               RTS                     ;
;
CR_cmd         CPY   #$01              ;
               BNE   SP_cmd            ;
               LDA   Addrptr           ; CR alone - move addrptr to hexdigits
               ORA   #$0F              ;  to simulate entering an address
               STA   Hexdigits         ; *** change 07 to 0f for 16 byte/line
               LDA   Addrptr+1         ;
               STA   Hexdigits+1       ;
               BRA   SP_cmd2           ;
SP_cmd         LDA   Hexdigcnt         ; Space command entry
               BEQ   SP_cmd5           ; any digits to process? no - done
               LDX   Memchr            ; yes - is sec cmd code 0 ? yes - 
               BEQ   SP_cmd1           ; yes - 
               DEX                     ; Is sec cmd = 1?       
               BEQ   SP_cmd3           ;       yes - is sec cmd code 1 ?
               LDA   Hexdigits         ;             no - ":" cmd processed
               STA   (Addrptr)         ;
               JMP   Inc_addrptr       ; set to next address and return
SP_cmd1        JSR   DOT_cmd           ; sec dig = 0  move address to addrptr
               BRA   SP_cmd3           ;
SP_cmd2        LDA   Addrptr           ; CR cmd entry 
               BIT   #$0F              ; *** changed 07 to 0F for 16 bytes/line
               BEQ   SP_cmd3           ; if 16, print new line
               cpy   #$00              ; if TXT cmd, don"t print the - or spaces between chrs
               beq   TXT_cmd1          ;
               BIT   #$07              ; if 8, print -
               BEQ   SP_cmd33          ;
               BRA   SP_cmd4           ; else print next byte
SP_cmd3        JSR   Print_CR          ; "." cmd - display address and data 
               jsr   Scan_Input        ; see if brk requested
               bcs   SP_brk            ; if so, stop 
               LDA   Addrptr+1         ; print address
               LDX   Addrptr           ;
               JSR   Print2Byte        ;
SP_cmd33       LDA   #$20              ; " " print 1 - 16 bytes of data
               JSR   OUTPUT            ;
               LDA   #$2D              ; "-"
               JSR   OUTPUT            ;
SP_cmd4        LDA   #$20              ; " " 
               JSR   OUTPUT            ;
               cpy   #$00              ;
               beq   TXT_Cmd1          ;
               LDA   (Addrptr)         ;
               JSR   Print1Byte        ;
SP_cmd44       SEC                     ;  checks if range done
               LDA   Addrptr           ;
               SBC   Hexdigits         ;
               LDA   Addrptr+1         ;
               SBC   Hexdigits+1       ;
               jsr   Inc_addrptr       ;
               BCC   SP_cmd2           ; loop until range done
SP_brk         STZ   Memchr            ; reset sec cmd code
SP_cmd5        RTS                     ; done or no digits to process
;
TXT_Cmd        PHY                     ;
               ldy   #$00              ;
               jsr   SP_cmd            ;
               PLY                     ;
               RTS                     ;
TXT_cmd1       LDA   (Addrptr)         ;
               AND   #$7F              ;
               CMP   #$7F              ;
               BEQ   TXT_Cmd2          ;
               CMP   #$20              ; " "
               BCS   TXT_Cmd3          ;
TXT_Cmd2       LDA   #$2E              ; "." use "." if not printable char
TXT_Cmd3       JSR   OUTPUT            ;
               BRA   SP_cmd44          ;
;
Inc_addrptr    INC   Addrptr           ;  increments addrptr
               BNE   Inc_addr1         ;
               INC   Addrptr+1         ;
Inc_addr1      RTS                     ;
;
Insert_cmd     lda   Linecnt           ;  "I" cmd code
               beq   Insert_3          ; abort if no . cmd entered
               sec                     ;
               lda   Hexdigits         ;
               sbc   addrptr           ;
               tax                     ;
               lda   Hexdigits+1       ;
               sbc   addrptr+1         ;
               tay                     ;
               bcc   Insert_3          ;
               clc                     ;
               txa                     ;
               adc   memptr            ;
               sta   hexdigits         ;
               tya                     ;
               adc   memptr+1          ;
               sta   hexdigits+1       ;
Insert_0       LDA   (memptr)          ;
               STA   (Hexdigits)       ;
               lda   #$FF              ;
               DEC   Hexdigits         ;  
               cmp   Hexdigits         ;  
               BNE   Insert_1          ;
               DEC   Hexdigits+1       ;
Insert_1       dec   Memptr            ;  
               cmp   Memptr            ;
               bne   Insert_2          ;
               dec   Memptr+1          ;
Insert_2       SEC                     ;  
               LDA   memptr            ;
               SBC   Addrptr           ;
               LDA   memptr+1          ;
               SBC   Addrptr+1         ;
               bcc   Insert_3          ;
               jsr   Scan_Input        ; see if brk requested
               bcc   Insert_0          ; if so, stop List
Insert_3       RTS                     ;
;
Move_cmd       lda   Linecnt           ; *** any changes to this routine affect EEPROM_WR too!!!
               bne   Move_cmd3         ; abort if no . cmd was used
Move_brk       RTS                     ;
Move_cmd1      INC   Addrptr           ;  increments addrptr
               BNE   Move_cmd2         ;
               INC   Addrptr+1         ;
Move_cmd2      inc   Hexdigits         ;  "M" cmd code
               bne   Move_cmd3         ;
               inc   Hexdigits+1       ;
Move_cmd3      SEC                     ;  checks if range done
               LDA   Memptr            ;
               SBC   Addrptr           ;
               LDA   Memptr+1          ;
               SBC   Addrptr+1         ;
               BCC   Move_brk          ;  exit if range done
               jsr   Scan_Input        ; see if brk requested
               bcs   Move_brk          ; 
               LDA   (Addrptr)         ;  Moves one byte
               STA   (Hexdigits)       ;
               BRA   Move_cmd1         ; (zapped after move from eeprom_wr)
EEPROM_TEST    lda   (Addrptr)         ;    moved along with Move_cmd for EEPROM_WR
               eor   (Hexdigits)       ;    ""
               bmi   EEPROM_TEST       ;    ""
               bra   Move_cmd1         ;    ""

EEPROM_WR      lda   Addrptr           ;  move the Move_cmd sub to $0280 (kybrd buffer)
               pha                     ;  adding EEPROM test routine 
               lda   Addrptr+1         ;  then run the burn program from RAM
               pha                     ;  
               lda   #<Move_cmd        ;
               sta   Addrptr           ;
               lda   #>Move_cmd        ;
               sta   Addrptr+1         ;
               ldy   #$2E              ;  47 instructions
EEPROM_WR1     lda   (Addrptr),y       ;
               sta   $0280,y           ;
               dey                     ;
               bpl   EEPROM_WR1        ;
               lda   #$EA              ; NOP instruction
               sta   $02A5             ; *
               sta   $02A6             ; * affected by changes to Move_cmd routine
               sta   $029C             ; * affected by changes to Move_cmd routine
               sta   $029D             ; * affected by changes to Move_cmd routine
               sta   $029E             ; * affected by changes to Move_cmd routine
               sta   $029F             ; * affected by changes to Move_cmd routine
               sta   $02A0             ; * affected by changes to Move_cmd routine
               pla                     ;
               sta   Addrptr+1         ;
               pla                     ;
               sta   Addrptr           ;        
               jmp   $0280             ;
;
Dest_cmd       LDX   Hexdigits         ;  ">" cmd code
               LDA   Hexdigits+1       ;
               STX   Memptr            ;  move address to memptr
               STA   Memptr+1          ;
               RTS                     ;  
                                       ;
LIST_cmd       lda   LineCnt           ;  Check for normal/range
               beq   List_cmd_1        ;  0 = normal  1=range 
               LDA   Addrptr           ;  Dissassemble range of code
               LDX   Addrptr+1         ;  move addrptr to startaddr
               STA   Startaddr         ;
               STX   Startaddr+1       ;
List_range     sec                     ;
               lda   Startaddr         ;
               sbc   Addrptr           ;
               lda   Startaddr+1       ; 
               sbc   Addrptr+1         ;
               bcc   List_done         ;
               jsr   List_Line         ;  list one line
               jsr   Scan_Input        ; see if brk requested
               bcs   List_done         ; if so, stop List
               SEC                     ;  checks if range done
               LDA   Hexdigits         ;
               SBC   Startaddr         ;
               LDA   Hexdigits+1       ;
               SBC   Startaddr+1       ;
               BCS   List_range        ;  if not, loop until done
               stz   LineCnt           ;
List_done      RTS                     ;
List_cmd_1     LDA   Hexdigcnt         ; Dissassemble one page of cmds
               BEQ   List1             ; followed with more pages 
               LDX   Hexdigits         ;
               LDA   Hexdigits+1       ;
               STX   Startaddr         ;
               STA   Startaddr+1       ;
List1          LDA   #$14              ; one page of dissassembly
               STA   Linecnt           ;
List2          JSR   List_line         ;
               DEC   Linecnt           ;
               BNE   List2             ;
               RTS                     ;
List_line      JSR   Print_CR          ; 
               JSR   List_one          ; one line of dissassembly
               CLC                     ;
               LDA   Startaddr         ; inc address pointer to next cmd
               ADC   Hexdigcnt         ;
               STA   Startaddr         ;
               BCC   List3             ;
               INC   Startaddr+1       ;
List3          RTS                     ;
List_one       LDA   (Startaddr)       ; Dissassemble one CMD from Startaddr
               TAX                     ; Initialize List Cmd pointers
               LDA   OPCtxtidx,X       ;
               STA   OPCtxtptr         ;
               LDA   OPCaddmode,X      ;
               AND   #$0F              ; mask out psuedo-modes
               STA   Modejmp           ;
               TAX                     ;
               LDA   ModeByteCnt,X     ;
               STA   Hexdigcnt         ;
               LDA   Startaddr+1       ;
               LDX   Startaddr         ;
               JSR   Print2Byte        ; print address 
               LDA   #$2D              ;  "-"
               JSR   OUTPUT            ;
               JSR   Print2SP          ; print "  "
               LDX   #$01              ;---------
List4          LDY   #$00              ;print up to 3 ascii chars...
List5          CPY   Hexdigcnt         ;  two spaces...
               BCS   List6             ;  up to three hex chars...
               LDA   (Startaddr),Y     ;  two spaces
               CPX   #$00              ;
               BNE   List8             ;
               JSR   Print1Byte        ;
               BRA   List7             ;
List6          CPX   #$00              ;
               BNE   List7             ;
               JSR   Print2SP          ;
List7          LDA   #$20              ; " "
List8          AND   #$7F              ;
               CMP   #$7F              ;
               BEQ   List9             ;
               CMP   #$20              ; " "
               BCS   List10            ;
List9          LDA   #$2E              ; "." use "." if not printable char
List10         JSR   OUTPUT            ;
               INY                     ;
               CPY   #$03              ;
               BCC   List5             ;
               JSR   Print2SP          ;
               DEX                     ;
               BEQ   List4             ;---------
               LDA   OPCtxtptr         ; get opcode text
               ASL                     ;
               ADC   OPCtxtptr         ;
               TAX                     ;
               LDY   #$FD              ;
List11         LDA   OPCtxtData,X      ;
               JSR   OUTPUT            ; print opcode text
               INX                     ;
               INY                     ;
               BNE   List11            ;
               LDA   OPCtxtptr         ;
               CMP   #$42              ; 4chr opcodes start
               BMI   List12		   ;
               CMP   #$46              ; the .xx cmds
               BPL   List12            ; 
               lda   (startaddr)	   ; get opcode of 4byte code
               lsr
               lsr
               lsr
               lsr
               AND   #$07              ; strip last 3 bits
               ora   #$30              ; add CHR '0'
               jsr   Output            ; print it
               lda   #$20              ; " "
               jsr   Output            ; 
               jmp   List13            ;
List12         JSR   Print2SP          ;
List13         LDA   Modejmp           ; setup to print operand
               ASL                     ;
               TAX                     ;
               JMP   (ModeJmpTbl,X)    ; goto operand printing command

IMM_mode       LDA   #$23              ; print #$HH
               JSR   output            ;
ZP_mode        LDA   #$24              ; print $HH
               JSR   output            ;
               LDY   #$01              ;
Byte_mode      LDA   (Startaddr),Y     ;
               JMP   Print1Byte        ;
ZP_X_mode      JSR   ZP_mode           ; print $HH,X
X_mode         LDA   #$2C              ; print ,X
               JSR   output            ;
               LDA   #$58              ; 
               JMP   output            ;
ZP_Y_mode      JSR   ZP_mode           ; print $HH,Y
Y_mode         LDA   #$2C              ; Print ,Y
               JSR   output            ;
               LDA   #$59              ; 
               JMP   output            ;
INDZP_mode     JSR   IND0_mode         ; Print ($HH)
               JSR   ZP_mode           ;
IND1_mode      LDA   #$29              ; Print )
               JMP   output            ;
INDZP_X_mode   JSR   IND0_mode         ; Print ($HH,X)
               JSR   ZP_mode           ;
               JSR   X_mode            ;
               BRA   IND1_mode         ;
INDZP_Y_mode   JSR   INDZP_mode        ; Print ($HH),Y
               BRA   Y_mode            ;
ABS_mode       LDA   #$24              ; Print $HHHH
               JSR   output            ;
               LDY   #$02              ;
               JSR   Byte_mode         ;
               DEY                     ;
               BRA   Byte_mode         ;
ABS_X_mode     JSR   ABS_mode          ; Print $HHHH,X
               BRA   X_mode            ;
ABS_Y_mode     JSR   ABS_mode          ; Print $HHHH,Y
               BRA   Y_mode            ;
INDABS_mode    JSR   IND0_mode         ; Print ($HHHH)
               JSR   ABS_mode          ;
               BRA   IND1_mode         ;
INDABSX_mode   JSR   IND0_mode         ; Print ($HHHH,X)
               JSR   ABS_mode          ;
               JSR   X_mode            ;
               BRA   IND1_mode         ;
IMPLIED_mode   RTS                     ; Implied/Accumulator mode 
IND0_mode      LDA   #$28              ; Print (
               JMP   output            ;
BBREL_mode     JSR   ZP_mode		   ;
		   LDA   #$2C              ; Print ,
               JSR   output            ;
               LDA   #$24              ; Print $
               JSR   output            ;
               LDY   #$02		   ;
               LDA   (Startaddr),Y     ;
               STA   Memchr            ;
               CLC                     ;
               LDA   Startaddr         ;
               ADC   #$03              ;
               JMP   REL_mode0         ;
REL_mode       LDA   #$24              ; Print $HHHH as Relative Branch
               JSR   output            ;
               LDY   #$01              ;
               LDA   (Startaddr),Y     ;
               STA   Memchr            ;
               CLC                     ;
               LDA   Startaddr         ;
               ADC   #$02              ;
REL_mode0      TAX                     ;
               LDA   Startaddr+1       ;
               ADC   #$00              ;
               TAY                     ;
               CLC                     ;
               TXA                     ;
               ADC   Memchr            ;
               TAX                     ;
               TYA                     ;
               LDY   Memchr            ;
               BPL   Rel_mode1         ;
               DEC                     ;
Rel_mode1      ADC   #$00              ;
               JMP   Print2Byte        ;
;
;mini assembler code
;
Assem_Init     tsx                     ;
               inx                     ;
               inx                     ;
               inx                     ;
               inx                     ;
               stz   $0100,x           ;
               jsr   version           ;  show version and ? prompt
               jmp   Assembler         ;
Asm_Help       lda   #<AsmHelptxt      ;  lower byte - Menu of Commands
               sta   addrptr           ;
               lda   #>AsmHelptxt      ;  upper byte
               sta   addrptr+1         ;
               bra   AsmHelp3          ;
ASmHelp4       cmp   #$7e              ;  "~"
               beq   AsmHelp1          ;
               jsr   Output            ;
               bra   AsmHelp2          ;
AsmHelp1       jsr   Print_CR          ;     
AsmHelp2       jsr   Inc_addrptr       ;
AsmHelp3       lda   (addrptr)         ;
               bne   AsmHelp4          ;
               jsr   Opcode_List       ;  

Assembler      LDX   #$FF              ;
               TXS                     ; init stack
               stz   HexDigCnt         ;
               jsr   Input_assem       ;
               ldy   #$00              ; beginning of input line
               lda   buffer            ;
               cmp   #$0d              ; Enter = done 
               bne   Asm01             ;
               JMP   Monitor           ; exit assembler
Asm01          cmp   #$3f              ; "?" Print Help
               beq   Asm_Help          ;
               cmp   #$20              ; space
               beq   Asm_opfetch       ;
               cmp   #$3b              ;  ";" ignore line
               beq   Assembler         ;
               cmp   #$4C              ;  "L" list
               beq   Asm_List          ;
               cmp   #$24              ;  "$" ignore this
               bne   Asm02             ;
               iny                     ;
Asm02          STZ   Hexdigits         ;  holds parsed hex
               STZ   Hexdigits+1       ;
               JSR   ParseHexDig       ;  get Hex Chars 
               LDX   Hexdigcnt         ;
               Beq   Asm_Err           ;
               cmp   #$4C              ; "L" do list               ???
               Beq   Asm_List1         ;
               cmp   #$20              ; Space
               Beq   Asm_opfetch       ;
Asm_Err        tya                     ;  get line pointer
               tax                     ;
               lda   #$0a              ; LF move down one line
               jsr   output            ;
               jsr   PrintXSP          ; move to where error occured
               lda   #$5E              ; "^"                       ???
               jsr   Output            ; mark it 
               jsr   bell              ; 
               bra   Assembler         ;
Asm_list       stz   HexDigcnt         ;
Asm_List1      jsr   List_Cmd_1        ;
Asm_hop        bra   Assembler         ;
Asm_opfetch    lda   HexDigCnt         ;
               beq   Asm_op01          ; no address change
               LDX   Hexdigits         ;
               LDA   Hexdigits+1       ;
               STX   AddrPtr           ;
               STA   AddrPtr+1         ;
               dey                     ;
Asm_stripSP    iny                     ;
Asm_op01       lda   buffer,y          ;
               cmp   #$20              ; strip spaces
               beq   Asm_stripSP       ;
               cmp   #$0d              ; done
               beq   Asm_hop           ;
               cmp   #$3b              ; ";" comment char done
               beq   Asm_hop           ;
               ldx   #$00              ;
               stx   OpcTxtPtr         ;
               sty   LineCnt           ;
Asm_opclp      ldy   LineCnt           ;
               lda   OpcTxtPtr         ;
               ASL                     ;
               adc   OpcTxtPtr         ;
               tax                     ;
               lda   buffer,y          ;
               iny                     ;
               cmp   OpcTxtData,x      ;
               bne   Asm_getnext       ;
               lda   buffer,y          ;
               inx                     ;
               iny                     ;
               cmp   OpcTxtData,x      ;
               bne   Asm_getnext       ;
               lda   buffer,y          ;
               inx                     ;
               iny                     ;
               cmp   OpcTxtData,x      ;
               beq   Asm_goodop        ;
Asm_getnext    ldx   OpcTxtPtr         ;
               inx                     ;
               stx   OpcTxtPtr         ;
               cpx   #$4A              ; last one? then err
               bne   Asm_opclp
Asm_err2       jmp   Asm_err
Asm_goodop     lda   #$00
               sta   ModeJmp           ; 
               dec   ModeJmp           ; init to FF for () check
               sta   HexDigits         ; and Byte holder
               sta   HexDigits+1       ; 
               sta   HexDigCnt         ;
               ldx   OpcTxtPtr         ;
               cpx   #$42              ; 
               bmi   Asm_goodSP        ; not a 4 chr opcode
               cpx   #$46              
               bpl   Asm_goodSP        ; not a 4 chr opcode
               lda   buffer,y          ; get next chr
               iny                     ; advance pointer
               cmp   #$38              ; 
               bpl   Asm_err2          ; not chr "0"-"7"
               cmp   #$30
               bmi   Asm_err2          ; not chr "0"-"7"
               ASL
               ASL
               ASL
               ASL
               sta   startaddr_H       ; temp holder for 4th chr opcode
               LDA   #$80              ; flag for 
Asm_goodSP     ldx   buffer,y          ; get next operand char
               iny                     ; point to next operand chr
               cpx   #$20              ;  sp
               bne   Asm_GoodSP2
               cmp   #$80
               bmi   Asm_goodSP
Asm_goodSP1    ldx   OpcTxtPtr         ; check if its a BBRx or BBSx opcode
               cpx   #$44              ; 
               bpl   Asm_GoodSP        ;
               ldx   HexDigCnt         ;
               beq   Asm_goodSP        ;
               cmp   #$D0              ; already have zp & rel?
               bpl   Asm_GoodSP        ; we don't care then
               cmp   #$C0              ; already got a zp address?
               bpl   Asm_Err2          ; then error
               ldx   HexDigits+1
               bne   Asm_err2          ; not zero page
               ldx   HexDigits
               stx   startaddr         ; temp zp value for BBRx & BBSx cmds 
               ora   #$40              ; mark zp address fetched
               and   #$F7              ; mask out zp address found
               bra   Asm_goodSP        ; get next chr
Asm_goodSp2    cpx   #$0d              ;  CR
               bne   Asm_eol
Asm_jmp1       jmp   Asm_modeSrch
Asm_eol        cpx   #$3b              ;  ";"
               beq   Asm_jmp1
               pha
               lda   OpcTxtPtr
               cmp   #$46              ; normal opcode if <=45h
               bmi   Asm_opnd1
               bne   Asm_xtra1
               cpx   #$24              ; $ .db pseudo-opcode
               beq   Asm_db1
               dey
Asm_db1        jsr   ParseHexDig
               plx
               ldx   HexDigCnt
               beq   Asm_err2          ; no digits retrieved
               ldy   #$00
               lda   #$01
               PHA
               lda   HexDigits
               sta   (AddrPtr),y
               jmp   Asm_save
Asm_xtra1      cmp   #$47              ; .dw pseudo-opcode
               bne   Asm_xtra2 
               cpx   #$24              ; $
               beq   Asm_dw1
               dey
Asm_dw1        jsr   ParseHexDig
               plx
               ldx   HexDigCnt
               beq   Asm_err1          ; no digits retrieved
               ldy   #$00
               lda   #$02
               PHA
               lda   HexDigits
               sta   (AddrPtr),y
               lda   HexDigits+1
               iny
               sta   (AddrPtr),y
               jmp   Asm_save
Asm_xtra2      cmp   #$48              ; .ds pseudo-opcode
               bne   Asm_err1 
               jmp   Asm_txt
Asm_opnd1      pla
               cpx   #$23              ;  #    20
               bne   Asm_parse01
               ora   #$20
               jmp   Asm_goodSP 
Asm_parse01    cpx   #$28              ;  (   04
               bne   Asm_parse02
               ora   #$04
               ldx   modeJmp
               bpl   Asm_err1          ;  more than one ( 
               inc   ModeJmp
               jmp   Asm_goodSP 
Asm_parse02    cpx   #$29              ;  )
               bne   Asm_parse03
               ldx   ModeJmp
               bne   Asm_err1          ;  ) without (
               inc   ModeJmp
               jmp   Asm_goodSP 
Asm_parse03    cpx   #$2C              ;  ,
               bne   Asm_parse04
               ldx   buffer,y
               cpx   #$58              ;  X        02
               bne   Asm_parse31
               ora   #$02
               iny
               jmp   Asm_goodSP
Asm_parse31    cpx   #$59              ;  Y        01 
               beq   Asm_parse32
               cmp   #$80              ;  is BBRx or BBSx cmd active?
               bmi   Asm_err1          ;  , without X or Y or 4byte opcode      
               jmp   Asm_goodSP1       ;  save zp address
Asm_parse32    ora   #$01
               iny
               jmp   Asm_goodSP 
Asm_parse04    cpx   #$24              ;  $
               beq   Asm_parse42       ;   
               dey                     ; not #$(),X,Y  so try Hexdig, if not err
Asm_parse42    pha
               jsr   ParseHexDig
               dey                     ; adjust input line pointer
               pla
               ldx   HexDigCnt
               beq   Asm_err1          ; no digits retrieved
               ldx   HexDigits+1    
               bne   Asm_parse41
               ora   #$08              ; <256               08
               jmp   Asm_goodSP
Asm_parse41    ora   #$10              ; 2 bytes            10 
               jmp   Asm_goodSP 
Asm_err1       jmp   Asm_Err
Asm_ModeSrch   ldx   #$0F              ; # of modes
Asm_ModeS1     cmp   Asm_ModeLst,x
               beq   Asm_ModeFnd 
               dex   
               bpl   Asm_ModeS1
               bra   Asm_Err1          ; invalid Mode
Asm_ModeFnd    stx   Memchr            ; save mode
               cmp   #$80              ; is it 4 chr opcode?
               bmi   Asm_opcSrch       ;no
               txa
               ora   startaddr_H       ; adjust the psuedo mode               
               sta   Memchr            ; set proper mode
Asm_opcSrch    ldx   #$00
Asm_opcSrch1   lda   OpcTxtidx,x
               cmp   OpcTxtPtr
               bne   Asm_srchNxt   
               lda   OPCaddmode,x
               cmp   Memchr
               beq   Asm_OpcFnd
Asm_srchNxt    inx
               bne   Asm_opcSrch1 
               lda   Memchr            ;
               cmp   #$02              ; ZP
               bne   Asm_srchAlt 
               LDA   #$01              ; ABS
               sta   Memchr
               bra   Asm_opcSrch
Asm_srchAlt    cmp   #$01              ; ABS
               bne   Asm_srchA0
               LDA   #$0A              ; REL
               sta   Memchr
               bra   Asm_opcSrch
Asm_srchA0     cmp   #$0d               ;  ind zp
               bne   Asm_srchA1
               LDA   #$0b              ; ind Abs
               sta   Memchr
               bra   Asm_opcSrch
Asm_SrchA1     cmp   #$07              ; zp,y
               bne   Asm_Err1          ; no more modes to try, bad mode err
               LDA   #$09              ; ABS,y
               sta   Memchr
               bra   Asm_opcSrch
Asm_OpcFnd     lda   Memchr
               and   #$0F              ; mask out psuedo modes
               sta   Memchr            ;
               CMP   #$0E              ; BBR mode?
               bne   Asm_opcFnd0       ;
               jsr   Asm_BRelCalc      ;
               sta   HexDigits_H       ;
               lda   Startaddr         ;
               sta   Hexdigits         ;
               bra   Asm_OpcFnd1       ;   
Asm_OpcFnd0    cmp   #$0A              ; is Rel Mode?
               bne   Asm_OpcFnd1 
               jsr   Asm_RelCalc       ; adjust rel address
Asm_OpcFnd1    ldy   #$00
               txa
               sta   (AddrPtr),y
               iny
               ldx   Memchr            ; 
               lda   ModeByteCnt,x
               PHA                     ; Save # of bytes
               cmp   #$01
               beq   Asm_EchoL
               lda   HexDigits
               sta   (AddrPtr),y
               iny
               lda   ModeByteCnt,x
               cmp   #$02
               beq   Asm_EchoL
               lda   HexDigits+1
               sta   (AddrPtr),y
Asm_EchoL      lda   AddrPtr
               sta   StartAddr
               lda   AddrPtr+1
               sta   StartAddr+1
               jsr   List_One
Asm_Save       clc
               PLA
               adc   AddrPtr
               sta   AddrPtr
               bcc   Asm_done
               inc   AddrPtr+1
Asm_done       jmp   Assembler
Asm_BRelCalc   jsr   Asm_relsub
               sbc   #$03
               bra   Asm_RelC1
Asm_RelSub     sec
               lda   Hexdigits
               sbc   AddrPtr
               sta   Memptr
               lda   Hexdigits+1
               sbc   AddrPtr+1
               sta   Memptr+1
               sec
               lda   Memptr
               rts 
Asm_RelCalc    jsr   Asm_relsub
               sbc   #$02
Asm_Relc1      sta   Memptr
               bcs   Asm_relC2
               dec   Memptr+1
Asm_relC2      lda   Memptr+1               
               beq   Asm_relC4         ; positive
               cmp   #$FF              ; negative
               bne   Asm_txtErr
               lda   Memptr
               bpl   Asm_txtErr
Asm_relC3      sta   HexDigits
               rts
Asm_relC4      lda   Memptr
               bpl   Asm_relC3
Asm_txtErr     jmp   Asm_Err
Asm_txt        plx                      ; process the .ds pseudo-opcode
               dey
               tya
               tax
               ldy   #$fe
Asm_txt1       iny
Asm_txt2       lda   buffer,x           ; get next operand char
               inx                      ; point to next operand chr
               cmp   #$0d             ;  CR
               beq   Asm_txt9
               cmp   #$27             ; "
               bne   Asm_txt3
               cpy   #$ff             ; opening " found?
               bne   Asm_txt9         ; no, closing, so done
               bra   Asm_txt1         ; yes, get first text chr
Asm_txt3       cpy   #$ff             ; already found opening "?
               beq   Asm_txt4         ; 
               sta   (AddrPtr),y      ; yes, save chr
               bra   Asm_txt1
Asm_txt4       cmp   #$20             ; no, if not a space, then err
               beq   Asm_txt2
               txa
               tay
               bra   Asm_txtErr
Asm_txt9       tya
               pha
               jmp   Asm_save
;
Opcode_List    ldy   #$49              ; Number of Opcodes (64)
               ldx   #$00              ; pointer to characters
Opcode_List1   txa                     ; 
               and   #$0F              ; Print CR after each 16 opcodes 
               bne   Opcode_List2      ; not divisible by 16
               jsr   Print_CR          ;
Opcode_List2   lda   OPCtxtData,x      ; get opcode chr data
               jsr   Output            ; print 1st char
               inx                     ;
               lda   OPCtxtData,x      ; 
               jsr   Output            ; print 2nd char
               inx                     ;
               lda   OPCtxtData,x      ;
               jsr   Output            ; print 3rd char
               inx                     ;
               cpy   #$08              ; 
               bpl   Opcode_List3      ; not 4 byte code
               cpy   #$04              ;
               bmi   Opcode_list3      ;
               lda   #$78              ; add 'x'
               jsr   output            ; for RMBx, SMBx,BBRx, & BBSx
Opcode_List3   lda   #$20              ; print space
               jsr   Output            ;
               dey                     ;
               bne   Opcode_List1      ; 
               jsr   Print_CR          ; one last CR-LF
               rts                     ;
;
;-----------DATA TABLES ------------------------------------------------
;
Hexdigdata     .byte "0123456789ABCDEF";hex char table 
;     
CmdCount       =$12                    ; number of commands to scan for
CmdAscii       .byte $0D               ; 0 enter    cmd codes
               .byte $20               ; 1 SPACE
               .byte $2E               ; 2 .
               .byte $3A               ; 3 :
               .byte $3E               ; 4 >  
               .byte $3f               ; 5 ? - Help
               .byte $21               ; 6 ! - Assembler
	       .byte $24	       ; 7 $ - DOS command interpreter
               .byte $47               ; 8 g - Go
               .byte $49               ; 9 i - Insert
               .byte $4C               ; A l - List
               .byte $4D               ; B m - Move
               .byte $51               ; C q - Query memory (text dump)
               .byte $52               ; D r - Registers
               .byte $40               ; E @ - Cold Start Basic
               .byte $23               ; F # - Warm Start Basic
               .byte $55               ;10 U - Xmodem/IntelHEX uploader   
               .byte $56               ;11 v - Version
               .byte $57               ;12 w - "(W)rite" eeprom
    
Cmdjmptbl      .word CR_cmd            ; 0  enter   cmd jmp table
               .word SP_cmd            ; 1   space
               .word DOT_cmd           ; 2    .
               .word DOT_cmd           ; 3    :
               .word Dest_cmd          ; 4    >  
               .word Help_Cmd          ; 5    ?
               .word Assem_init        ; 6    !
               .word Dos_Init	       ; 7    $
               .word Excute_cmd        ; 8    g
               .word Insert_Cmd        ; 9    i
               .word LIST_cmd          ; A    l
               .word Move_cmd          ; B    m
               .word TXT_cmd           ; C    q
               .word Printreg          ; D    r
               .word LAB_COLD	       ; E    @ $A300
               .word $0000             ; F    #
               .word Xmodem	       ;10    U
               .word Version           ;11    v
               .word EEPROM_WR         ;12    w  
;     
Cmdseccode     .byte $00               ; 0   enter       secondary command table
               .byte $FF               ; 1   sp
               .byte $01               ; 2   .
               .byte $02               ; 3   :
               .byte $00               ; 4   > 
               .byte $00               ; 5   ?
               .byte $00               ; 6   !
		.byte $00	       ; 7   $
               .byte $00               ; 8   g
               .byte $00               ; 9   i
               .byte $00               ; A   l
               .byte $00               ; B   m
               .byte $00               ; C   q
               .byte $00               ; D   r
               .byte $00               ; E   @
               .byte $00               ; F   #
               .byte $00               ;10   U
               .byte $00               ;11   V
               .byte $00               ;12   W
;
;     
OPCtxtidx      .byte $0B               ;0   operand text index
               .byte $23               ;1
               .byte $49               ;2
               .byte $49               ;3
               .byte $3B               ;4
               .byte $23               ;5
               .byte $02               ;6
               .byte $44               ;7
               .byte $25               ;8
               .byte $23               ;9
               .byte $02               ;A
               .byte $49               ;B
               .byte $3B               ;C
               .byte $23               ;D
               .byte $02               ;E
               .byte $42               ;F
               .byte $09               ;10
               .byte $23               ;11
               .byte $23               ;12
               .byte $49               ;13
               .byte $3A               ;14
               .byte $23               ;15
               .byte $02               ;16
               .byte $44               ;17
               .byte $0E               ;18
               .byte $23               ;19
               .byte $19               ;1A
               .byte $49               ;1B
               .byte $3A               ;1C
               .byte $23               ;1D
               .byte $02               ;1E
               .byte $42               ;1F
               .byte $1D               ;20
               .byte $01               ;21
               .byte $49               ;22
               .byte $49               ;23
               .byte $06               ;24
               .byte $01               ;25
               .byte $2C               ;26
               .byte $44               ;27
               .byte $29               ;28
               .byte $01               ;29
               .byte $2C               ;2A
               .byte $49               ;2B
               .byte $06               ;2C
               .byte $01               ;2D
               .byte $2C               ;2E
               .byte $42               ;2F
               .byte $07               ;30
               .byte $01               ;31
               .byte $01               ;32
               .byte $49               ;33
               .byte $06               ;34
               .byte $01               ;35
               .byte $2C               ;36
               .byte $44               ;37
               .byte $31               ;38
               .byte $01               ;39
               .byte $15               ;3A
               .byte $49               ;3B
               .byte $06               ;3C
               .byte $01               ;3D
               .byte $2C               ;3E
               .byte $42               ;3F
               .byte $2E               ;40
               .byte $18               ;41
               .byte $49               ;42
               .byte $49               ;43
               .byte $49               ;44
               .byte $18               ;45
               .byte $21               ;46
               .byte $44               ;47
               .byte $24               ;48
               .byte $18               ;49
               .byte $21               ;4A
               .byte $49               ;4B
               .byte $1C               ;4C
               .byte $18               ;4D
               .byte $21               ;4E
               .byte $42               ;4F
               .byte $0C               ;50
               .byte $18               ;51
               .byte $18               ;52
               .byte $49               ;53
               .byte $49               ;54
               .byte $18               ;55
               .byte $21               ;56
               .byte $44               ;57
               .byte $10               ;58
               .byte $18               ;59
               .byte $27               ;5A
               .byte $49               ;5B
               .byte $49               ;5C
               .byte $18               ;5D
               .byte $21               ;5E
               .byte $42               ;5F
               .byte $2F               ;60
               .byte $00               ;61
               .byte $49               ;62
               .byte $49               ;63
               .byte $37               ;64
               .byte $00               ;65
               .byte $2D               ;66
               .byte $44               ;67
               .byte $28               ;68
               .byte $00               ;69
               .byte $2D               ;6A
               .byte $49               ;6B
               .byte $1C               ;6C
               .byte $00               ;6D
               .byte $2D               ;6E
               .byte $42               ;6F
               .byte $0D               ;70
               .byte $00               ;71
               .byte $00               ;72
               .byte $49               ;73
               .byte $37               ;74
               .byte $00               ;75
               .byte $2D               ;76
               .byte $44               ;77
               .byte $33               ;78
               .byte $00               ;79
               .byte $2B               ;7A
               .byte $49               ;7B
               .byte $1C               ;7C
               .byte $00               ;7D
               .byte $2D               ;7E
               .byte $42               ;7F
               .byte $0A               ;80
               .byte $34               ;81
               .byte $49               ;82
               .byte $49               ;83
               .byte $36               ;84
               .byte $34               ;85
               .byte $35               ;86
               .byte $45               ;87
               .byte $17               ;88
               .byte $06               ;89
               .byte $3D               ;8A
               .byte $49               ;8B
               .byte $36               ;8C
               .byte $34               ;8D
               .byte $35               ;8E
               .byte $43               ;8F
               .byte $03               ;90
               .byte $34               ;91
               .byte $34               ;92
               .byte $49               ;93
               .byte $36               ;94
               .byte $34               ;95
               .byte $35               ;96
               .byte $45               ;97
               .byte $3F               ;98
               .byte $34               ;99
               .byte $3E               ;9A
               .byte $49               ;9B
               .byte $37               ;9C
               .byte $34               ;9D
               .byte $37               ;9E
               .byte $43               ;9F
               .byte $20               ;A0
               .byte $1E               ;A1
               .byte $1F               ;A2
               .byte $49               ;A3
               .byte $20               ;A4
               .byte $1E               ;A5
               .byte $1F               ;A6
               .byte $45               ;A7
               .byte $39               ;A8
               .byte $1E               ;A9
               .byte $38               ;AA
               .byte $49               ;AB
               .byte $20               ;AC
               .byte $1E               ;AD
               .byte $1F               ;AE
               .byte $43               ;AF
               .byte $04               ;B0
               .byte $1E               ;B1
               .byte $1E               ;B2
               .byte $49               ;B3
               .byte $20               ;B4
               .byte $1E               ;B5
               .byte $1F               ;B6
               .byte $45               ;B7
               .byte $11               ;B8
               .byte $1E               ;B9
               .byte $3C               ;BA
               .byte $49               ;BB
               .byte $20               ;BC
               .byte $1E               ;BD
               .byte $1F               ;BE
               .byte $43               ;BF
               .byte $14               ;C0
               .byte $12               ;C1
               .byte $49               ;C2
               .byte $49               ;C3
               .byte $14               ;C4
               .byte $12               ;C5
               .byte $15               ;C6
               .byte $45               ;C7
               .byte $1B               ;C8
               .byte $12               ;C9
               .byte $16               ;CA
               .byte $40               ;CB
               .byte $14               ;CC
               .byte $12               ;CD
               .byte $15               ;CE
               .byte $43               ;CF
               .byte $08               ;D0
               .byte $12               ;D1
               .byte $12               ;D2
               .byte $49               ;D3
               .byte $49               ;D4
               .byte $12               ;D5
               .byte $15               ;D6
               .byte $45               ;D7
               .byte $0F               ;D8
               .byte $12               ;D9
               .byte $26               ;DA
               .byte $41               ;DB
               .byte $49               ;DC
               .byte $12               ;DD
               .byte $15               ;DE
               .byte $43               ;DF
               .byte $13               ;E0
               .byte $30               ;E1
               .byte $49               ;E2
               .byte $49               ;E3
               .byte $13               ;E4
               .byte $30               ;E5
               .byte $19               ;E6
               .byte $45               ;E7
               .byte $1A               ;E8
               .byte $30               ;E9
               .byte $22               ;EA
               .byte $49               ;EB
               .byte $13               ;EC
               .byte $30               ;ED
               .byte $19               ;EE
               .byte $43               ;EF
               .byte $05               ;F0
               .byte $30               ;F1
               .byte $30               ;F2
               .byte $49               ;F3
               .byte $49               ;F4
               .byte $30               ;F5
               .byte $19               ;F6
               .byte $45               ;F7
               .byte $32               ;F8
               .byte $30               ;F9
               .byte $2A               ;FA
               .byte $49               ;FB
               .byte $49               ;FC
               .byte $30               ;FD
               .byte $19               ;FE
               .byte $43               ;FF
;     
OPCaddmode     .byte $03               ;0   opcode address mode
               .byte $04               ;1
               .byte $03               ;2
               .byte $03               ;3
               .byte $02               ;4
               .byte $02               ;5
               .byte $02               ;6
               .byte $0F               ;7
               .byte $03               ;8
               .byte $00               ;9
               .byte $03               ;A
               .byte $03               ;B
               .byte $01               ;C
               .byte $01               ;D
               .byte $01               ;E
               .byte $0E               ;F
               .byte $0A               ;10
               .byte $05               ;11
               .byte $0D               ;12
               .byte $03               ;13
               .byte $02               ;14
               .byte $06               ;15
               .byte $06               ;16
               .byte $1F               ;17
               .byte $03               ;18
               .byte $09               ;19
               .byte $03               ;1A
               .byte $03               ;1B
               .byte $01               ;1C
               .byte $08               ;1D
               .byte $08               ;1E
               .byte $1E               ;1F
               .byte $01               ;20
               .byte $04               ;21
               .byte $03               ;22
               .byte $03               ;23
               .byte $02               ;24
               .byte $02               ;25
               .byte $02               ;26
               .byte $2F               ;27
               .byte $03               ;28
               .byte $00               ;29
               .byte $03               ;2A
               .byte $03               ;2B
               .byte $01               ;2C
               .byte $01               ;2D
               .byte $01               ;2E
               .byte $2E               ;2F
               .byte $0A               ;30
               .byte $05               ;31
               .byte $0D               ;32
               .byte $03               ;33
               .byte $06               ;34
               .byte $06               ;35
               .byte $06               ;36
               .byte $3F               ;37
               .byte $03               ;38
               .byte $09               ;39
               .byte $03               ;3A
               .byte $03               ;3B
               .byte $08               ;3C
               .byte $08               ;3D
               .byte $08               ;3E
               .byte $3E               ;3F
               .byte $03               ;40
               .byte $04               ;41
               .byte $03               ;42
               .byte $03               ;43
               .byte $03               ;44
               .byte $02               ;45
               .byte $02               ;46
               .byte $4F               ;47
               .byte $03               ;48
               .byte $00               ;49
               .byte $03               ;4A
               .byte $03               ;4B
               .byte $01               ;4C
               .byte $01               ;4D
               .byte $01               ;4E
               .byte $4E               ;4F
               .byte $0A               ;50
               .byte $05               ;51
               .byte $0D               ;52
               .byte $03               ;53
               .byte $03               ;54
               .byte $06               ;55
               .byte $06               ;56
               .byte $5F               ;57
               .byte $03               ;58
               .byte $09               ;59
               .byte $03               ;5A
               .byte $03               ;5B
               .byte $03               ;5C
               .byte $08               ;5D
               .byte $08               ;5E
               .byte $5E               ;5F
               .byte $03               ;60
               .byte $04               ;61
               .byte $03               ;62
               .byte $03               ;63
               .byte $02               ;64
               .byte $02               ;65
               .byte $02               ;66
               .byte $6F               ;67
               .byte $03               ;68
               .byte $00               ;69
               .byte $03               ;6A
               .byte $03               ;6B
               .byte $0B               ;6C
               .byte $01               ;6D
               .byte $01               ;6E
               .byte $6E               ;6F
               .byte $0A               ;70
               .byte $05               ;71
               .byte $0D               ;72
               .byte $03               ;73
               .byte $06               ;74
               .byte $06               ;75
               .byte $06               ;76
               .byte $7F               ;77
               .byte $03               ;78
               .byte $09               ;79
               .byte $03               ;7A
               .byte $03               ;7B
               .byte $0C               ;7C
               .byte $08               ;7D
               .byte $08               ;7E
               .byte $7E               ;7F
               .byte $0A               ;80
               .byte $04               ;81
               .byte $03               ;82
               .byte $03               ;83
               .byte $02               ;84
               .byte $02               ;85
               .byte $02               ;86
               .byte $0F               ;87
               .byte $03               ;88
               .byte $00               ;89
               .byte $03               ;8A
               .byte $03               ;8B
               .byte $01               ;8C
               .byte $01               ;8D
               .byte $01               ;8E
               .byte $0E               ;8F
               .byte $0A               ;90
               .byte $05               ;91
               .byte $0D               ;92
               .byte $03               ;93
               .byte $06               ;94
               .byte $06               ;95
               .byte $07               ;96
               .byte $1F               ;97
               .byte $03               ;98
               .byte $09               ;99
               .byte $03               ;9A
               .byte $03               ;9B
               .byte $01               ;9C
               .byte $08               ;9D
               .byte $08               ;9E
               .byte $1E               ;9F
               .byte $00               ;A0
               .byte $04               ;A1    changed from 0d to 04
               .byte $00               ;A2
               .byte $03               ;A3
               .byte $02               ;A4
               .byte $02               ;A5
               .byte $02               ;A6
               .byte $2F               ;A7
               .byte $03               ;A8
               .byte $00               ;A9
               .byte $03               ;AA
               .byte $03               ;AB
               .byte $01               ;AC
               .byte $01               ;AD
               .byte $01               ;AE
               .byte $2E               ;AF
               .byte $0A               ;B0
               .byte $05               ;B1
               .byte $0D               ;B2     
               .byte $03               ;B3
               .byte $06               ;B4
               .byte $06               ;B5
               .byte $07               ;B6
               .byte $3F               ;B7
               .byte $03               ;B8
               .byte $09               ;B9
               .byte $03               ;BA
               .byte $03               ;BB
               .byte $08               ;BC
               .byte $08               ;BD
               .byte $09               ;BE
               .byte $3E               ;BF
               .byte $00               ;C0
               .byte $04               ;C1
               .byte $03               ;C2
               .byte $03               ;C3
               .byte $02               ;C4
               .byte $02               ;C5
               .byte $02               ;C6
               .byte $4F               ;C7
               .byte $03               ;C8
               .byte $00               ;C9
               .byte $03               ;CA
               .byte $03               ;CB
               .byte $01               ;CC
               .byte $01               ;CD
               .byte $01               ;CE
               .byte $4E               ;CF
               .byte $0A               ;D0
               .byte $05               ;D1
               .byte $0D               ;D2
               .byte $03               ;D3
               .byte $03               ;D4
               .byte $06               ;D5
               .byte $06               ;D6
               .byte $5F               ;D7
               .byte $03               ;D8
               .byte $09               ;D9
               .byte $03               ;DA
               .byte $03               ;DB
               .byte $03               ;DC
               .byte $08               ;DD
               .byte $08               ;DE
               .byte $5E               ;DF
               .byte $00               ;E0
               .byte $04               ;E1
               .byte $03               ;E2
               .byte $03               ;E3
               .byte $02               ;E4
               .byte $02               ;E5
               .byte $02               ;E6
               .byte $6F               ;E7
               .byte $03               ;E8
               .byte $00               ;E9
               .byte $03               ;EA
               .byte $03               ;EB
               .byte $01               ;EC
               .byte $01               ;ED
               .byte $01               ;EE
               .byte $6E               ;EF
               .byte $0A               ;F0
               .byte $05               ;F1
               .byte $0D               ;F2
               .byte $03               ;F3
               .byte $03               ;F4
               .byte $06               ;F5
               .byte $06               ;F6
               .byte $7F               ;F7
               .byte $03               ;F8
               .byte $09               ;F9
               .byte $03               ;FA
               .byte $03               ;FB
               .byte $03               ;FC
               .byte $08               ;FD
               .byte $08               ;FE
               .byte $7E               ;FF
;     
;
ModeByteCnt    .byte $02               ;0  opcode mode byte count
               .byte $03               ;1
               .byte $02               ;2
               .byte $01               ;3
               .byte $02               ;4
               .byte $02               ;5
               .byte $02               ;6
               .byte $02               ;7
               .byte $03               ;8
               .byte $03               ;9
               .byte $02               ;A
               .byte $03               ;B
               .byte $03               ;C
               .byte $02               ;D
               .byte $03               ;E
               .byte $02               ;F 
;     
;
ModeJmpTbl     .word IMM_mode          ;0  Operand print table
               .word ABS_mode          ;1
               .word ZP_mode           ;2
               .word IMPLIED_mode      ;3
               .word INDZP_X_mode      ;4
               .word INDZP_Y_mode      ;5
               .word ZP_X_mode         ;6
               .word ZP_Y_mode         ;7
               .word ABS_X_mode        ;8
               .word ABS_Y_mode        ;9
               .word REL_mode          ;a
               .word INDABS_mode       ;b
               .word INDABSX_mode      ;c
               .word INDZP_mode        ;d
		   .word BBREL_mode        ;e
               .word ZP_mode           ;f  dup of ZP for RMB,SMB cmds
;
;
Asm_ModeLst    .byte $28               ;0 IMM_mode
               .byte $10               ;1 ABS_mode
               .byte $08               ;2 ZP_mode
               .byte $00               ;3 IMPLIED_mode
               .byte $0E               ;4 INDZP_X_mode
               .byte $0D               ;5 INDZP_Y_mode
               .byte $0A               ;6 ZP_X_mode
               .byte $09               ;7 ZP_Y_mode
               .byte $12               ;8 ABS_X_mode
               .byte $11               ;9 ABS_Y_mode
               .byte $40               ;A REL_mode   Never set!!!
               .byte $14               ;B INDABS_mode
               .byte $16               ;C INDABSX_mode
               .byte $0C               ;D INDZP_mode
               .byte $D0               ;E BBREL_mode
               .byte $88               ;F used for RMBx & SMBx 
;
;              
OPCtxtData     .byte "ADC"             ;0
               .byte "AND"             ;1
               .byte "ASL"             ;2
               .byte "BCC"             ;3
               .byte "BCS"             ;4
               .byte "BEQ"             ;5
               .byte "BIT"             ;6
               .byte "BMI"             ;7
               .byte "BNE"             ;8
               .byte "BPL"             ;9
               .byte "BRA"             ;A
               .byte "BRK"             ;B
               .byte "BVC"             ;C
               .byte "BVS"             ;D
               .byte "CLC"             ;E
               .byte "CLD"             ;F
               .byte "CLI"             ;10
               .byte "CLV"             ;11
               .byte "CMP"             ;12
               .byte "CPX"             ;13
               .byte "CPY"             ;14
               .byte "DEC"             ;15
               .byte "DEX"             ;16
               .byte "DEY"             ;17
               .byte "EOR"             ;18
               .byte "INC"             ;19
               .byte "INX"             ;1A
               .byte "INY"             ;1B
               .byte "JMP"             ;1C
               .byte "JSR"             ;1D
               .byte "LDA"             ;1E
               .byte "LDX"             ;1F
               .byte "LDY"             ;20
               .byte "LSR"             ;21
               .byte "NOP"             ;22
               .byte "ORA"             ;23
               .byte "PHA"             ;24
               .byte "PHP"             ;25
               .byte "PHX"             ;26
               .byte "PHY"             ;27
               .byte "PLA"             ;28
               .byte "PLP"             ;29
               .byte "PLX"             ;2A
               .byte "PLY"             ;2B
               .byte "ROL"             ;2C
               .byte "ROR"             ;2D
               .byte "RTI"             ;2E
               .byte "RTS"             ;2F
               .byte "SBC"             ;30
               .byte "SEC"             ;31
               .byte "SED"             ;32
               .byte "SEI"             ;33
               .byte "STA"             ;34
               .byte "STX"             ;35
               .byte "STY"             ;36
               .byte "STZ"             ;37
               .byte "TAX"             ;38
               .byte "TAY"             ;39
               .byte "TRB"             ;3A
               .byte "TSB"             ;3B
               .byte "TSX"             ;3C
               .byte "TXA"             ;3D
               .byte "TXS"             ;3E
               .byte "TYA"             ;3F
               .byte "WAI"             ;40
               .byte "STP"             ;41
               .byte "BBR"             ;42 4Byte Opcodes
               .byte "BBS"             ;43
               .byte "RMB"             ;44
               .byte "SMB"             ;45
               .byte ".DB"             ;46 define 1 byte for assembler
               .byte ".DW"             ;47 define 1 word for assembler
               .byte ".DS"             ;48 define a string block for assembler
               .byte "???"             ;49 for invalid opcode
;
;
HelpTxt        .byte "~Current commands are :~"
               .byte "Syntax = {} required, [] optional, HHHH hex address, DD hex data~"
               .byte "~"
               .byte "[HHHH][ HHHH]{Return} - Hex dump address(s)(up to 16 if no address entered)~"
               .byte "[HHHH]{.HHHH}{Return} - Hex dump range of addresses (16 per line)~"
               .byte "[HHHH]{:DD}[ DD]{Return} - Change data bytes~"
               .byte "[HHHH]{G}{Return} - Execute a program (use RTS to return to monitor)~"
               .byte "{HHHH.HHHH>HHHH{I}{Return} - move range at 2nd HHHH down to 1st to 3rd HHHH~"
               .byte "[HHHH]{L}{Return} - List (disassemble) 20 lines of program~"
               .byte "[HHHH]{.HHHH}{L}{Return} - Dissassemble a range~"
               .byte "{HHHH.HHHH>HHHH{M}{Return} - Move range at 1st HHHH thru 2nd to 3rd HHHH~"
               .byte "[HHHH][ HHHH]{Q}{Return} - Text dump address(s)~"
               .byte "[HHHH]{.HHHH}{Q}{Return} - Text dump range of addresses (16 per line)~"
               .byte "{R}{Return} - Print register contents from memory locations~"
               .byte "{U}{Return} - Upload File (Xmodem/CRC or Intel Hex)~"
               .byte "{V}{Return} - Monitor Version~"
               .byte "{HHHH.HHHH>HHHH{W}{Return} - Write data in RAM to EEPROM~"
               .byte "{!}{Return} - Enter Assembler~"
               .byte "{@}{Return} - Cold-Start Enhanced Basic~"
               .byte "{#}{Return} - Warm_Start Enhanced Basic~"
	       .byte "<$>{Return} - Enter CBM-DOS Command Interpreter~"
               .byte "{?}{Return} - Print menu of commands~~"
               .byte $00
AsmHelpTxt     .byte "~Current commands are :~"
               .byte "Syntax = {} required, [] optional~"
               .byte "HHHH=hex address, OPC=Opcode, DD=hex data, '_'=Space Bar or Tab~"
               .byte "'$' Symbols are optional, all values are HEX.~"
               .byte "Any input after a 'semi-colon' is ignored.~"
               .byte "~"
               .byte "{HHHH}{Return} - Set input address~"
               .byte "[HHHH][_]{OPC}[_][#($DD_HHHH,X),Y]{Return} - Assemble line~"
               .byte "[HHHH]{L}{Return} - List (disassemble) 20 lines of program~"
               .byte "{Return} - Exit Assembler back to Monitor~"
               .byte "{?}{Return} - Print menu of commands~~"
               .byte $00
;
Porttxt        .byte "65C02 Monitor v5.1 (5-30-05) Ready"
               .byte  $0d, $0a
               .byte "Modules installed: Enhanced Basic Interpreter (c) Lee Davison"
               .byte  $0d, $0a
               .byte "                 : Commodore Serial IEC BIOS (c) Richard Cini"
               .byte  $0d, $0a
               .byte "(Press ? for help)"
               .byte $00
;
; *** VERSION Notes ***
; 3.5 added the text dump command, "q"
; 4.0 reorganized structure, added RAM vectors for chrin, scan_in, and chrout
; 4.1 fixed set time routine so 20-23 is correct    
; 4.2 RST, IRQ, NMI, BRK all jmp ind to 02xx page to allow user prog to control
; 4.3 added status register bits to printreg routine
; 4.4 refined set time to reduce unneeded sec"s and branches, disp time added CR,
;     and added zeromem to the reset routine, ensuring a reset starts fresh every time!
;     continued to re-organize - moved monitor"s brk handler into mon area.
; 4.5 nop out the jsr scan_input in the eeprom write routine to prevent BRK"s
; 4.6 added version printout when entering assember to show ? prompt
; 4.7 added Lee Davison's Enhanced Basic to ROM Image 
; 4.9 Added all of the WDC opcodes to the disassembler and mini-assembler
; 5.0 Added TAB key support to the input routine, expands tabs to spaces
; 5.1 Added jump table at the start of the monitor to commonly used routines
;
;end of file
