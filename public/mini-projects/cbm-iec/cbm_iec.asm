;===============================================================
;  Commodore Serial IEC BIOS for Generic 6502-based SBC
;  Copyright (c) 2002-2005 Richard A. Cini
;
;  Based on and derived from the Commodore VIC-20 Kernal ROM
;  Copyright (c) 1980 Commodore Business Machines Ltd.
;
;  Hardware Requirements:
;    Code uses 65C02-specific instructions (primarily BRA) and
;    assumes a single available MOS/CSG 6522 VIA and a buffer/
;    adapter board to provide buffering of the VIA signals as 
;    required by CBM serial IEC peripherals. See schematic for
;    details.
;
;    VIA signals used:	PA.0 - CLK_IN
;			PA.1 - DATA_IN
;			PA.2 - ATN_IN (unimplemented)
;			PA.7 - ATN_OUT
;			CA2  - CLK_OUT
;			CB1  - SRQ_IN
;			CB2  - DATA_OUT
;    Other VIA usage:   Timer 2
;
;  Applications Programming Interface:
;    The API is Commodore-compatible and follows the same semantics.
;    It includes both high-level (OPEN, CLOSE, LOAD, SAVE) as well
;    as low-level I/O routines. Console output uses monitor routine
;    OUTPUT. 
;
;    The following PET "BASIC 4.0" disk commands are supported in 
;    this release: CATALOG, COLLECT, COPY, DS, HEADER, INITIALIZE
;    RENAME, and SCRATCH. The following BASIC 4.0 commands are not
;    supported: CONCAT, DOPEN, DCLOSE, RECORD, APPEND, DSAVE, DLOAD.
;
;  Revision History:
;  =================
;  2002/11/18	0.10	Initial coding
;  2003/01/17	0.20	First clean compile. Waiting for working test
;			  board in order to do live test.
;  2003/05/22   0.80	Live printer test works! Working on disk drives.
;  2003/05/28   	Added mapping for GETIN
;  2003/06/04		Revised CLRCH to match VIC20 ROM
;  2003/06/06   0.90	Changes to SBIDLE (immediate RTS).
;  2003/07/15   0.91	Started adding "PET BASIC 4.0" DOS commands
;  2003/07/21		Only CATALOG and DS working as tests of different
;			  parameter parsing methods.
;  2003/07/27   0.92	SCRATCH command works properly. COPY works, too,
;			  except that it won't work with spaces between params.
;  2003/07/29		Appears to be issue with using CONFOPS in SCRATCH and
;			  HEADER commands (some index variable trashed).
;  2003/07/30		Moved OTDSBU and FLGERR to right after LISTEN as it
;			  is in the Kernal ROM. Maybe timing issue throwing
;			  off DNP.
;  2003/08/08	0.93	Appeared to have resolved DNP error. Problem appears to
;			  result from calling CLRCH on a non-responding device.
;  2003/09/05   0.99b	Synched with latest source from Daryl
;  2005/01/06	0.99c	Minor fixes to DOS command dispatcher
;  2005/08/09	0.99d	Changes to IOERMS to hopefully fix message problems
;
;  TODO:  RESTORE key/NMI processing
;	  SYNTAX ERROR not posted on invalid DOS command
;	  Call to CONFOPS doesn't work properly.
;
;
;===============================================================
;//////////////////////////////////////////////////////////
RAMBOT  = $0400		; Bottom of RAM
RAMTOP  = $7eff		; Top of RAM
D1ORB	=$7F50		;50 Port B output register
D1ORA  	=D1ORB+1	;51 Port A output register (clk_in, data_in, atn_out)
D1DDRB 	=D1ORB+2	;52 DDRB (data direction register)
D1DDRA 	=D1ORB+3	;53 DDRA (data direction register)
D1TM1L 	=D1ORB+4	;54 Timer 1 latch LSB
D1TM1H 	=D1ORB+5	;55 Timer 1 latch MSB
D1T1CL 	=D1ORB+6	;56 Timer 1 counter LSB
D1T1CH 	=D1ORB+7	;57 Timer 1 counter MSB
D1TM2L 	=D1ORB+8	;58 Timer 2 latch LSB
D1TM2H 	=D1ORB+9	;59 Timer 2 latch MSB
D1SHFR 	=D1ORB+10	;5A shift register
D1ACR  	=D1ORB+11	;5B ACR (aux control register)
D1PCR  	=D1ORB+12	;5C PCR (peripheral control register clk_out, srq_in, data_in)
D1IFR  	=D1ORB+13	;5D IFR (interrupt flag register)
D1IER  	=D1ORB+14	;5E IER (interrupt enable register)
D1ORAH 	=D1ORB+15	;5F Port A output register (unlatched)

; Offsets to direct-mode informational message strings
KIM_SRCH  =$8c	;SEARCHING
KIM_FOR   =$96	; FOR
KIM_LOAD  =$9a	;LOADING
KIM_SAVE  =$a1	;WRITING
KIM_VERF  =$a9	;VERIFYING
KIM_FOUND =$b2	;FOUND
KIM_OK    =$b8	;OK
KIM_RDY   =$bb	;READY
KIM_PMPT  =$c2	;Confirmation Prompt
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
; RAM Variables
;
;USRPOK MUST be the first location (assumed and used by SAVE routine)
; these addresses cannot have $FF in the LSB otherwise JMP INDIRECT
; bug could be triggered. This is probably why Commodore coded
; the USRPOK location at $00 absolute.
USRPOK	= $14	;{*}USR jump (C64: DDR)
USRVEC 	= $15	;{*}USR vector (C64: processor reg)
; OSSTAR MUST remain in Z-page for SAVE to work
OSSTAR 	= $17	;{*}POINTER: start of memory (used in SAVE)
CSTAT 	= $19	;status word ST
STIMOT 	= $1a	;serial bus timeout flag
IOFLG2 	= $1b	;{*}I/O flag #2 (0=load, 1=verify)
C3PO 	= $1c	;serial deferred character flag
BSOUT 	= $1d	;serial deferred character (buffered character)
INDEV 	= $1e	;input device (default 0=KEYBOARD)
OUTDEV 	= $1f	;output device (default 3=SCREEN)
CMDMOD 	= $20	;command mode (program running=0/direct=$80)
SBITCF 	= $21	;serial bit count/EOI flag
CYCLE 	= $22	;cycle count
CNTDN 	= $23	;bit countdown
COPNFL 	= $24	;number of open files (max 10)
FNMLEN 	= $25	;number of characters in filename
FNPTR 	= $26	;POINTER: filename
LOGFIL 	= $28	;current logical file#
SECADR 	= $29	;current secondary address
CHANNL 	= $2a	;current device number
STAL 	= $2b	;{*}POINTER: I/O start address
MEMUSS 	= $2d	;{*}POINTER: I/O end address
BUFIDX	= $2f	;{reserved for CRUNCHER; index to current char in Buffer}
;
KWCNT	= $30	;{reserved for CRUNCHER; index number of keyword}
TMP3	= $31	;{GETBYT conversion variable}
SAL 	= $de	;{*}POINTER: start address
EAL 	= $e0	;{*}POINTER: end address/end of program
;
;  2005/09/04	RAC	Synched with v2.09 (5/30/05 release) of SBCOS
;			  and EhBASIC. Last buffer address is $0267 so
;			  buffer addresses below should work fine.
FILTBL 	 = $0270	;0270-0279 logical file table
DEVTBL 	 = $027a	;027a-0283 open device table
SECATB 	 = $0284	;0284-028d secondary address table
VarStart =SECATB+$0a
CMD_DEV	 =VarStart	;DOS device# for current command
FNMLEN   =VarStart+1	;DOS filename count/command string count
CSRMOD   =VarStart+2	;DOS InQuote flag
FNM1	 =VarStart+3	;3-20 = 18 chars for drv:name of new name
FNM2	 =VarStart+21	;21-38 = 18 chars for drv:name of old name
;///////////////////////////////////////////////////////////////
;###############################################################
; API -- DO NOT RE-ORDER ENTRIES
_IEC	 JMP IEC_Init	; initialization code; called at monitor startup
_DOS	 JMP Dos_Init	; main entry to DOS
; API routines begin here
_SETTMO  JMP SETTMO	; set IEC bus timeout
_SETNAM	 JMP SETNAM	; set filename parameters
_SETLFS  JMP SETLFS	; set logical file parameters
_MEMBOT  JMP MEMBOT	; set bottom of memory
_OPEN    JMP OPEN	; open logical file
_CLOSE 	 JMP CLOSE	; close logical file
_CLALL   JMP CLOSEALL	; close all open logical files
_CHKIN	 JMP CHKIN	; set channel for input
_CHKOUT	 JMP CHKOUT	; set channel for output
_GETIN	 JMP GETIN	; get character from head of keyboard buffer
_CHRIN	 JMP CHRIN	; get character from channel
_CHROUT	 JMP CHROUT	; send character to IEC
_READST	 JMP READST	; read IEC status variable
_CLRCH	 JMP CLRCH	; clear I/O channels
_SETMS	 JMP SETMS	; set system message mode
_LOAD	 JMP LOAD	; load
_SAVE	 JMP SAVE	; save
; Pseudo-internal routines. Declared here for full compatibility
;  with Commodore VIC-20/C64 kernal API
_ACPTR	 JMP ACPTR	; get character from IEC (low-level)
_CIOUT	 JMP CIOUT	; output character to IEC (low-level)
_LISTEN  JMP LISTEN	; send LISTEN command
_LSECOND JMP SECOND	; send secondary address
_TALK	 JMP TALK	; send TALK command
_TSECOND JMP TALKSA	; send TALK command with secondary address
_UNLSTN  JMP UNLISTEN	; send UNLISTEN command
_UNTALK  JMP UNTALK	; send UNTALK command
;###############################################################

;===============================================================
; IEC_Init - Initialization routine
;	Called from MonitorBoot in sbcos.asm
;
;===============================================================
IEC_Init

	lda #$80
	jsr SETMS	; command mode (80=direct; 0=programmed)
;	jsr SETTMO	; BUGBUG - see notes in SETTMO header
 	lda #$00	;
	sta CSRMOD	; cursor mode (0=direct; 80=programmed)
	sta D1TM2L
	sta D1TM2H
	jsr SETTMO	; enable timeouts (0=enable; 80=disable)
	ldx #$03	; screen device
	jsr CLR2	; set default devices (in CLRCH)
	ldy #>RAMBOT	; MSB
	ldx #<RAMBOT	; LSB
	clc
	jsr MEMBOT	; set bottom of RAM to YYXX
	lda #$4c
	sta USRPOK	; set JSR opcode
	rts


;===============================================================
; SETTMO - Set/clear serial bus timeout flag FE6F
;
;  PARAMS   :  .A=bit7 clear to enable serial timeouts
;	       .A=bit7 set to disable serial timeout
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  nothing
;  PRE-CALLS:  none
;  COMMENTS :  Serial device timeout is 64ms. Should be left
;		"enabled" for most uses.
;	BUGBUG: conflicting info in Programmer's Ref Guide
;		lead one to believe that this should be set
;		to #$80 to "enable" timeout testing.
;===============================================================
SETTMO

	STA STIMOT
	RTS


;===============================================================
; SETNAM - Set pointer to filename string FE49
;
;  PARAMS   :  .A=length of string
;	       .X=LSB of string address
;	       .Y=MSB of string address
;  RETURNS  :  nothing
;  PRE-CALLS:  none
;  COMMENTS :  none
;===============================================================
SETNAM
	STA FNMLEN		;set length
	STX FNPTR		;ptr L
	STY FNPTR+1		;ptr H
	RTS


;===============================================================
; SETLFS - Set logical file parameters FE50
;
;  PARAMS   :  .A=logical filenumber to open (LFN $ff reserved
;			for Kernal use).
;	       .X=device to open (4-31 allowed)
;	       .Y=device-speific command (secondary address) or 
;			0xff for none
;  RETURNS  :  none
;  PRE-CALLS:  none
;  COMMENTS :  Devices: 0-3	(reserved - don't use)
;			4-7	printer
;			8-11	disk drive
;			9-31	undefined
;===============================================================
SETLFS
	STA LOGFIL		;file#
	STX CHANNL		;device
	STY SECADR		;secondary address
	RTS


;===============================================================
; MEMBOT - Read/set bottom of memory FE82
;
;  PARAMS   :  .X=LSB of address
;	       .Y=MSB of address
;	       Call with CY=1 (SEC) to read, CY=0 (CLC) to write
;  RETURNS  :  nothing
;  PRE-CALLS:  Setting/clearing Carry Flag
;  COMMENTS :  Used as a pre-call to SAVE to set the bottom
;		memory address used for saving memory.
;===============================================================
MEMBOT
	BCC STOBOT
	LDX OSSTAR		; address L
	LDY OSSTAR+1		; address H

STOBOT
	STX OSSTAR		; address L
	STY OSSTAR+1		; address H
	RTS


;===============================================================
; SETMS - Control OS Messages FE66
;
;  PARAMS   :  .A=message number; BIT7=kernal, BIT6=control, 
;		BIT5-0=message number.
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  none
;  PRE-CALLS:  none
;  COMMENTS :  $80=direct mode; $00=programmed
;===============================================================
SETMS
	STA CMDMOD		;save message #
	LDA CSTAT		;get status

ISETMS1				; set ST bits
	ORA CSTAT		;twiddle bits
	STA CSTAT		;save status
;(***ADDED)
;	jsr Print1Byte
	RTS


;===============================================================
; OPEN - Open logical file for device access  F40A
;
;  PARAMS   :  none
;  RETURNS  :  Errors 1,2,4,5,6
;  PRE-CALLS:  SETNAM, SETLFS
;  COMMENTS :  Devices 4-31 allowed
;===============================================================
OPEN
	LDX LOGFIL		;get file number
	BNE IOPEN_S1		;F411 <>0 not "save"
	JMP IOERMS6		;$F78D "NOT INPUT FILE" error

IOPEN_S1	
	JSR FIND		;locate file# in table, X is free spot
	BNE IOPEN_S2		;F419 not found; any more free spots
	JMP IOERMS2		;$F781 "FILE OPEN" error

IOPEN_S2	
	LDX COPNFL		;get # of open files
	CPX #$0A		;10 files open?
	BCC IOPEN_S3		;F422 no, OK to open it
	JMP IOERMS1		;"TOO MANY FILES" error

IOPEN_S3			; check device# before opening logical file
	LDA CHANNL		; get device#
	CMP #$03
	BCS IOPEN_S4		; device 4 or greater, send SA to IEEE
	jmp IOERMS9		; anything else, ILLEGAL DEVICE error

IOPEN_S4			; All tests passed, so open the logical file
	INC COPNFL		;bump count
	LDA LOGFIL
	STA FILTBL,X		;save file# in table
	LDA SECADR		;flag and save SA
	ORA #%01100000		;$60
	STA SECADR
	STA SECATB,X
	LDA CHANNL		;save device
	STA DEVTBL,X
	JSR SENDSA		;send secondary to IEEE
	CLC
	RTS


;===============================================================
; CLOSE - Close logical device file  F34A
;
;  PARAMS   :  .A=logical filenumber to close
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  none
;  PRE-CALLS:  OPEN
;  COMMENTS :  Devices 4-31 allowed.
;===============================================================
CLOSE
	JSR FIND1		;$F3D4 locate file#
	BEQ ICLSE		;$F351 found it, go to closer
	CLC
	RTS			;not found, return CY=0

ICLSE
	JSR FLATRB		;get file attributes
	TXA			;save table offset
	PHA			;push it
	LDA CHANNL		;get device
	CMP #$03		;screen?
	BCS ICLSE1		;$F3AE device#>3, close IEEE 
	CLC			; invalid device (<3)
	RTS

ICLSE1
	BIT SECADR		; test bit7 of secondary address
	BMI ICLSEX		; if not file-oriented channel, just exit

	LDA CHANNL		;get device number and
	JSR LISTEN		;command it to listen
	LDA SECADR		;get secondary address
	AND #%11101111		;$EF
	ORA #%11100000		;$E0 CLOSE command
	JSR SECOND		;send secondary address
	JSR UNLISTEN		;finally, command device to unlisten
	PLA			;restore table offset
	TAX
	DEC COPNFL		;decrement # of open files
	CPX COPNFL		;no more files open, go to ready
	BEQ ICLSEX		;$F3CD return CY=0
	LDY COPNFL		;delete device by moving last entry
 	LDA FILTBL,Y		;in table into deleted position
	STA FILTBL,X
	LDA DEVTBL,Y
	STA DEVTBL,X
	LDA SECATB,Y
	STA SECATB,X

ICLSEX
	CLC
	RTS			;exit clear


;===============================================================
; CLOSEALL - Close all open logical files F3EF
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  none
;  PRE-CALLS:  OPEN
;  COMMENTS :  none
;===============================================================
CLOSEALL
	LDA #$00
	STA COPNFL		;zero-out count of open files
	JSR CLRCH		; restore I/O channels
	RTS


;===============================================================
; READST- Read status word FE57
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  .A=device status, as follows:
;		bit0 - Write time out
;		bit1 - Read time out
;		bit2 - {reserved}
;		bit3 - {reserved}
;		bit4 - {reserved}
;		bit5 - {reserved}
;		bit6 - EOI
;		bit7 - Device not present
;  PRE-CALLS:  none
;  COMMENTS :  none
;===============================================================
READST
	LDA CSTAT		;get status
	ORA CSTAT		;clear status bits
	STA CSTAT		;save status
	RTS			


;===============================================================
; CHKIN - Set open channel for input F2C7
;
;  PARAMS   :  .A=unused
;	       .X=logical file number from OPEN call
;	       .Y=unused
;  RETURNS  :  Errors 3,5,6
;  PRE-CALLS:  OPEN
;  COMMENTS :  Associated device must be a logical input device
;		(terminal or disk drive). Call automatically sends
;		the talk address and the secondary address (if
;		specified) to the device.
;===============================================================
CHKIN
	JSR FIND		;find file# in tables
	BEQ ICHKI1		;$F2CF found, continue
	JMP IOERMS3		;'FILE NOT OPEN' error

ICHKI1
	JSR FLATRB		;set file# params
	LDA CHANNL		;get device 
	CMP #$03
	BCS ICHKI3		;$F2F0 IEEE? yes, handle IEEE
	jmp IOERMS9		; ILLEGAL DEVICE
;	CLC
;	RTS

ICHKI3				;handle IEEE			
	TAX			;copy device
	JSR TALK		;command device to talk 
	LDA SECADR		;is there a secondary address?
	BPL ICHKI4		;$F2FE yes, send it
	JSR CLKWAIT		;no, send regular talk command
	jmp ICHKI5		;$F301

ICHKI4
	JSR TALKSA		;send secondary address talk

ICHKI5
	TXA			;restore device#
	BIT CSTAT		;BIT7= Dev not present
	BPL ICHKIEX		;all clear, exit
;	pla
;	pla
	JMP IOERMS5		;"DEVICE NOT PRESENT" error; Exit

ICHKIEX
	STA INDEV		; save as input device
	CLC
	RTS


;===============================================================
; CHKOUT - Set open channel for output F309
;
;  PARAMS   :  .A=unused
;	       .X=logical file number from OPEN call
;	       .Y=unused
;  RETURNS  :  Errors 3,5,7
;  PRE-CALLS:  OPEN
;  COMMENTS :  Associated device must be an output device (printer
;		or disk drive). Call automatically sends the listen
;		address and the secondary address (if specified)
;		to the device.
;===============================================================
CHKOUT
	JSR FIND		;locate file# in tables
	BEQ ICHKO1		;$F311 found, continue
	JMP IOERMS3		;$F784 "FILE NOT OPEN" error

ICHKO1
	JSR FLATRB		;set file attributes
	LDA CHANNL		;get device
	CMP #$03
	BCS ICHKO2		;$F2F0 IEEE? yes, handle IEEE
	jmp IOERMS9		; "Illegal Device"
;	CLC
;	RTS

ICHKO2
	TAX			;save device#
	JSR LISTEN		;command device to listen
	LDA SECADR		;is there an SA?
	BPL ICHKO_S4		;$F33F yes, send SA

	JSR CLRATN		;no, clear ATN line and make sure
	BNE ICHKO_S5		; device is present

ICHKO_S4
	JSR SECOND		;send SA

ICHKO_S5
	TXA			;restore device#
	BIT CSTAT		;BIT7=Dev not present
	BPL ICHKO_S6		;$F32E
;	pla
;	pla
	JMP IOERMS5		;$F78A "DEVICE NOT PRESENT" error

ICHKO_S6
	STA OUTDEV		;set OUTDEV and exit
	CLC
	RTS


;===============================================================
; GETIN - Get a byte from the head of the keyboard queue
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  .A=character returned from buffer
;  COMMENTS :  None
;===============================================================
GETIN
	JSR Scan_Input		; map KERNAL routine to SBCOS
	RTS


;===============================================================
; CHRIN - Read a character from the input channel F20E
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  .A=character returned from channel
;	       Status returned according to READST
;  PRE-CALLS:  OPEN, CHKIN
;  COMMENTS :  Devices 4-31 allowed. Associated device must be
;		a logical input device (disk drive).
;===============================================================
CHRIN
	LDA INDEV		;get input device
	CMP #$03		; allowed IEC device?
	BCS CHINIE		; yes, go get char
	CLC			; return clear
	RTS

CHINIE
	LDA CSTAT		;any IEEE errors? 
	BEQ ACPTR		;no, get next char from device
	LDA #$0D		;yes, return <CR> and exit
	CLC
	RTS


;===============================================================
; ACPTR - Receive a byte over the serial bus EF19
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  .A=byte received from serial device
;	       Status returned according to READST.
;  PRE-CALLS:  TALK, [TALKSA]
;  COMMENTS :  Internal routine used to receive a single buffered
;		data byte on the bus using full handshaking to 
;		a talking device. Also is the back-end input
;		routine to CHRIN.
;===============================================================
ACPTR
	SEI           		;kill interrupts
	LDA #$00			
	STA CNTDN		;zero-out bit count
	JSR SCLK1		;assert CLK

IACPLP1
	JSR SDCLK		;get CLK answer
	BCC IACPLP1		;wait for CLK=H
	JSR SOUT1		; answer with DATA=H
				; not called in c64

IACPTR1
	LDA #$01		; delay for 256us...
	STA D1TM2H

IACPLP2
	LDA D1IFR
	AND #%00100000		;Timer2 time-out flagged?
	BNE IACPTR2

	JSR SDCLK		;...then check CLK again
	BCS IACPLP2		;CLK=H, then EOI (ignore)
	BCC IACPTR3A		;CLK=L, then start clocking data

IACPTR2
	LDA CNTDN		; get bit count
	BEQ IACPTR3		; no more to shift, move on
	JMP FLGER02		; error code 2 (read timeout)

IACPTR3
	JSR SOUT0		; clear DATA
	JSR UNLSTN2		; send unlisten
	LDA #$40		;EOF error
	JSR ISETMS1
	INC CNTDN
	BNE IACPTR1

IACPTR3A
	LDA #$08		;set bit count
	STA CNTDN		

IACPLP4				; clock in bits
	LDA D1ORAH
	CMP D1ORAH
	BNE IACPLP4
	LSR A
	BCC IACPLP4
	LSR A
	ROR CYCLE

IACPLP5
	LDA D1ORAH
	CMP D1ORAH
	BNE IACPLP5
	LSR A
	BCS IACPLP5
	DEC CNTDN
	BNE IACPLP4
	JSR SOUT0		; clear DATA
	LDA CSTAT		; error? 
	BEQ IACPEX		; no, continue shifting
	JSR UNLSTN2		; yes, unlisten and exit.

IACPEX
	LDA CYCLE
	CLI
	CLC
	RTS


;===============================================================
; CHROUT - Write a character to the output channel F27A
;
;  PARAMS   :  .A=character to write to output channel
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST
;  PRE-CALLS:  OPEN, CHKOUT
;  COMMENTS :  Associated device must be a logical output device
;		(printer or disk drive). Care must be taken when
;		using CHROUT since data will be sent to all listening
;		devices (setup with CHKOUT). Unless this is the
;		desired effect, be sure to UNLISTEN all unintended
;		devices. Channel is left open after the call.
;===============================================================
CHROUT
	PHA			; save char
	LDA OUTDEV		; get output device
	CMP #$03		; is it the screen?
	BNE NOTSCR		; no, test other devices

				; SCREEN
	PLA			; restore character
	JSR OUTPUT		; send it to the terminal
	RTS			; and return

NOTSCR				; NOT the SCREEN
	PLA			; restore character; CY should not be effected
	BCS CIOUT		; IEC? Yes, send it.
	JMP IOERMS7		; Otherwise, "Not Output File" error

	; fall-through to CIOUT
	
;===============================================================
; CIOUT - Transmit a byte over the serial bus EEE4
;
;  PARAMS   :  .A=character to write to output channel
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  LISTEN, [SECOND]
;  COMMENTS :  Internal routine used to send a single buffered
;		data byte on the bus using full handshaking to 
;		a listening device, such as filename and program
;		address info during SAVE. Also is the back-end
;		output routine to CHROUT.
;
;		When UNLISTEN is called to end the transmission,
;		the byte is sent with EOI set. 
;===============================================================
CIOUT
	BIT C3PO       		;deferred character?
	BMI ICIOUT1		; no, send it now	
	SEC
	ROR C3PO
	BNE ICIOUT2		;send it later

ICIOUT1	
	PHA			;save byte	
	JSR OTDSBU		;send it immediately	
	PLA			;restore it	

ICIOUT2	
	STA BSOUT		;deferred character	
	CLC
	RTS


;===============================================================
; SECOND - Send secondary address to a device commanded to LISTEN EEC0
;
;  PARAMS   :  .A=secondary address (4-31) OR 0x60
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  LISTEN
;  COMMENTS :  Device must be an input device. Secondary address
;		must be first ORed with 0x60 before calling this
;		routine.
;===============================================================
SECOND
	STA BSOUT		; save secondary address
	JSR ILISTEX		; output with ATN
				;CLK=0, DATA=1, pause, output

CLRATN				; CLRATN - Clear the ATN line
	LDA D1ORAH		; ATN=0, DATA=1, CLK=1
	AND #%01111111		;$7F
	STA D1ORAH			
	RTS			


;===============================================================
; TALK - Command a device to TALK EE14
;
;  PARAMS   :  .A=device number (4-31)
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  none
;  COMMENTS :  Device must be an output device.
;===============================================================
TALK
	ORA #%01000000		;$40 BIT6 = Talk address
	.byte $2c
	; fall through to LISTEN

;===============================================================
; LISTEN - Command a device to LISTEN EE17
;
;  PARAMS   :  .A=device number (4-31)
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  none
;  COMMENTS :  Associated device must be an input device. Can 
;		be used to send a single buffered data byte on
;		the bus using full handshaking but without
;		creating a logical file. When UNLISTEN is
;		called to end the transmission, the byte is sent
;		with EOI set.
;===============================================================
LISTEN
	ORA #%00100000		;$20 BIT5 = Listen address
	JSR SBIDLE		; Wait for RS232 idle state

LSNOIDLE
	PHA			;save device address
	BIT C3PO		;char waiting?
	BPL LISN1		;no, branch $EE2B
	SEC			;yes, output bit
	ROR SBITCF		;bit count
	JSR OTDSBU		;output
	LSR C3PO		;go to next
	LSR SBITCF			

LISN1
	PLA			;restore device address
	STA BSOUT		;save to xmit buffer
	JSR SOUT1		;send DATA=1
	CMP #%00111111		;$3F Data=0? 7-5=DATA 4=SRQ 3-1=CLK
	BNE LISN2		;no answer yet, send ATN
	JSR SCLK1		;send SCLK=1 answer

LISN2				; ATN sequence
	LDA D1ORAH			
	ORA #%10000000		;$80 set PA.7=1 Assert ATN (inverted to 0)
	STA D1ORAH		; (LOW at IEC port is "true" and HIGH is "false")

ILISTEX
	JSR SCLK0		;send SCLK=0 (true)
	JSR SOUT1		;send DATA=1 (false)
	JSR DDELAY		;wait 1ms

; Fall-through to OTDSBU

;===============================================================
; OTDSBU- Send one byte on serial bus EE49
;
OTDSBU
	SEI			;kill interrupts
	JSR SOUT1		;send DATA=1
	JSR SDCLK		;Get clk_in/data_in status
	LSR A			;shift to data_in
	BCS FLGERR		;data_in=1, device not present
	JSR SCLK1		;got device ack, ack with CLK=1
	BIT SBITCF		;more bits?
	BPL OTDLP3		;$EE66 yes, skip EOI handler
OTDLP1
	JSR SDCLK		;wait for DIn=H
	LSR A			;roll data into carry
	BCC OTDLP1		;$EE5A
OTDLP2
	JSR SDCLK		;wait for DIn=L
	LSR A			;roll data into carry
	BCS OTDLP2		;$EE60
OTDLP3
	JSR SDCLK		;wait again for DIn=H
	LSR A			;roll data into carry
	BCC OTDLP3		;$EE66
	JSR SCLK0		;send CLK=0
	LDA #$08		;bit counter
	STA CNTDN		;save as bit count-down
OTDLP4
	LDA D1ORAH		;wait for idle
	CMP D1ORAH			
	BNE OTDLP4
	LSR A			
	LSR A			; LSR to data_in 
	BCC FLGER03		; data_in=0 time-out error
	ROR BSOUT		;get bit
	BCS OTDSB1		; if 1, send DATA=1
	JSR SOUT0		;not 1, must be 0; DATA=0
	BNE OTDSB2
OTDSB1
	JSR SOUT1		;send DATA=1
OTDSB2
	JSR SCLK1		;clock it out
	nop			;The NOP instruction is 2 clock cycles,
	nop			; so maybe this is a short delay to let
	nop			; signals settle
	nop
	LDA D1PCR		;get PCR
	AND #%11011111		;$DF CB2=L (DATA=1)
	ORA #%00000010		;$02 CA2=H (CLK=0)
	STA D1PCR		;output it
	DEC CNTDN		;process next bit
	BNE OTDLP4		;loop
	LDA #$04		;set time-out
	STA D1TM2H			
OTDLP5
	LDA D1IFR		;test timer
	AND #%00100000		;$20
	BNE FLGER03		; bus timeout
	JSR SDCLK		;wait for data_in=L
	LSR A
	BCS OTDLP5		;$EEA5
	CLI
	RTS


;===============================================================
; FLGERR - Set CSTAT EEB4
;
FLGERR
	LDA #$80		; Error $80 - device not present
	.byte $2C

FLGER02
	LDA #$02		; Error $02 - read timeout
	.byte $2C

FLGER03
	LDA #$03		; Error $03 - write timeout
	JSR ISETMS1		;$FE6A set status
	CLI
	CLC
; (*** changed from JMP)
	bcc UNLSTN1


;===============================================================
; TALKSA - Send secondary address to a device commanded to TALK EECE
;
;  PARAMS   :  .A=secondary address (4-31)
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  TALK
;  COMMENTS :  Device must be an output device.
;===============================================================
TALKSA
	STA BSOUT     		;save secondary address to xmit
	JSR ILISTEX		; output with ATN
				;CLK=0, DATA=1, pause

CLKWAIT				; Wait for CLK
	SEI			;kill interrupts
	JSR SOUT0		;DATA=0
	JSR CLRATN		;clear ATN
	JSR SCLK1		;CLK=1

CLKWAIT1
	JSR SDCLK		;wait for CLK=0
	BCS CLKWAIT1
	CLI			
	RTS


;===============================================================
; UNTALK - Send an UNTALK command EEF6
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  none
;  COMMENTS :  All devices previously commanded to TALK will be
;		commanded to UNTALK.
;===============================================================
UNTALK
	JSR SCLK0		;CLK=0
	LDA D1ORAH
	ORA #%10000000		;$80 send ATN
	STA D1ORAH

	LDA #$5F		; %01011111 UNTALK
	.byte $2C		;really BIT $3FA9 to skip EF04
	
	; Fall through to UNLISTEN
;===============================================================
; UNLISTEN - Send an UNLISTEN command EF04
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Status returned according to READST.
;  PRE-CALLS:  none
;  COMMENTS :  All devices previously commanded to LISTEN will
;		be commanded to UNLISTEN.
;===============================================================
UNLISTEN
	LDA #$3F		; %00111111 UNLISTEN
	JSR LSNOIDLE		; send UNLSTN; skip idle test

UNLSTN1
	JSR CLRATN		;clear ATN

UNLSTN2
	TXA			
	LDX #$0B		;pause loop (40ms)

IUNLP1
	DEX			
	BNE IUNLP1		; pause
	TAX			
	JSR SCLK1		;CLK=1
	JMP SOUT1		;DATA=1 EXIT


;===============================================================
; CLRCH - Restore default I/O F3F3
;
;  PARAMS   :  .A=unused
;	       .X=unused
;	       .Y=unused
;  RETURNS  :  Nothing
;  PRE-CALLS:  None
;  COMMENTS :  None
;===============================================================
CLRCH
	LDX #$03		; see if device is output device
	CPX OUTDEV
	BCS CLR1		; No. See if it's an input device then.
	JSR UNLISTEN		; Yes. Send unlisten command to IEC

CLR1				; Not an output device. Maybe it's an input
	CPX INDEV
	BCS CLR2		; No. Restore default devices
	JSR UNTALK		; Yes. Send untalk command to IEC

CLR2	STX OUTDEV
	LDA #$00
	STA INDEV		;restore default I/O devices
	RTS


;===============================================================
; LOAD - Load RAM from device
;
;  PARAMS   :  .A = 0 (load) or 1 (verify)
;	       If a "relocated load" is required, set:
;		 .X = LSB of "from" address
;		 .Y = MSB of "from" address
;	       Otherwise, set .X/.Y to $ff for the default
;		starting address (MEMBOT). For SA 0-2, the address
;		is set from the file header. For SA 3, .X/.Y
;		required to be set.
;  RETURNS  :  .X/.Y is LSB/MSB of RAM load address
;  PRE-CALLS:  MEMBOT, SETLFS, SETNAM
;  COMMENTS :  Removed check for STOP key
;===============================================================
LOAD
	STX MEMUSS		;save load location from call
	STY MEMUSS+1
	STA IOFLG2		;load/verify flag
	LDA #$00
	STA CSTAT		;clear ST 
	LDA CHANNL		;get device
	CMP #$07		; LOADING from IEC drives allowed
	BCS SERLOAD
	JMP IOERMS9		;exit through "ILLEGAL DEVICE" error

SERLOAD
	LDY FNMLEN		;get filename length
	BNE SERLO_S1		;F563 filename required on IEEE
	JMP IOERMS8		;$F793 "FILENAME MISSING" error

SERLO_S1				
	JSR SSADR		;$E4BC print "Searching"
	LDA #$60
	STA SECADR		;set default SA to 0
	JSR SENDSA		;send it
	LDA CHANNL		;get device
	JSR TALK		;command it to talk
	LDA SECADR		;get SA
	JSR TALKSA		;send SA for talk
	JSR ACPTR		;get char
	STA EAL			;save it as start address L
	LDA CSTAT		;status
	LSR A
	LSR A
	BCS SERLDEX		;$F5C7 timeout? Yes, error
	JSR ACPTR		;get next char
	STA EAL+1		;save as start address H
	JSR SLDPCH		;$E4C1 print "Loading" msg and set load
				;address based on file type
SERLDLP				
	LDA #%11111101		;$FD timeout bit
	AND CSTAT		;clear it
	STA CSTAT		;save ST
;	JSR STOP		;check for STOP key
;	BNE SERLO_S2		;F598 not pressed, continue
;	JMP SAVEXIT1		;$F6CE close file and exit

SERLO_S2	
	JSR ACPTR		;get next char - program byte
	TAX			;save it
	LDA CSTAT		;check status
	LSR A
	LSR A
	BCS SERLDLP		;$F58A error, interrupt process
	TXA			;restore char
	LDY IOFLG2		;check load/verify flag
	BEQ SERLD1		;$F5B3 =0, load
	LDY #$00		;verify comparison
	CMP (EAL),Y
	BEQ SERLD2		;$F5B5 match, continue
	LDA #$10		;not a match, error
	JSR ISETMS1		; $FE6A set status
	.byte $2C		;bit $ae91
SERLD1				
	STA (EAL),Y		;save byte
SERLD2				
	INC EAL			;increment address
	BNE SERLO_S3		;$F5BB
	INC EAL+1			

SERLO_S3				
	BIT CSTAT		;test for EOF
	BVC SERLDLP		;$F58A not EOF, loop
	JSR UNTALK		;EOF, send untalk
	JSR SERSAV1A		;close file
	BCC LOADEX		;$F641 exit no error
SERLDEX				
	JMP IOERMS4		;$F787 "FILE NOT FOUND" error
LOADEX				
	CLC			
	LDX EAL			;return program end address 
	LDY EAL+1			
	RTS			


;===============================================================
; SAVE - Save RAM to device
;
;  PARAMS   :  .A = offset to Z-page pointer containing starting
;		    address (calculated as TAX/LDA USRPOK,X). So, 
;		    if USRPOK is at $14 and word pointer is at
;		    $17 (OSSTAR), set .A with $03
;	       .X = LSB of "to" address
;	       .Y = MSB of "to" address
;	       "From" address set by calling MEMBOT with .X/.Y of
;		starting location (MEMBOT sets OSSTAR)
;  RETURNS  :  nothing
;  PRE-CALLS:  MEMBOT, SETLFS, SETNAM
;  COMMENTS :  Removed check for STOP key
;===============================================================
SAVE
	STX EAL			;copy "save to" address
	STY EAL+1
	TAX
	LDA USRPOK,X
	STA STAL		;save start address L
	LDA USRVEC,X
	STA STAL+1		;save start address H
	LDA CHANNL		;get device
	CMP #$07		; SAVING to IEC drives allowed
	BCS SERSAV
	JMP IOERMS9		;$F796 "ILLEGAL DEVICE" error
SERSAV
	LDA #$61		;SA=1
	STA SECADR		;set it
	LDY FNMLEN		;get filename length
	BNE SERSAV_S1		;$F69D not 0, continue
	JMP IOERMS8		;$F793 "FILENAME MISSING" error

SERSAV_S1
	JSR SENDSA		;send filename
	JSR SAVEMS		;print "Saving" message
	LDA CHANNL		;get device
	JSR LISTEN		;command it to listen EE17
	LDA SECADR		;get SA
	JSR SECOND		;send it
	LDY #$00
	JSR RSTTPP		;save start address to SAL
	LDA SAL
	JSR CIOUT		;send start address L...
	LDA SAL+1
	JSR CIOUT		;...and start address H

SERSAVLP
	JSR CKWRPT		;reached end yet?
	BCS SERSAV1		;$F6D7 yes, go to ready
	LDA (SAL),Y		;get program byte
	JSR CIOUT		;send it
;	JSR STOP		; SAVE abort test
;	BNE SAVEXIT2
;	JSR SERSAV1A
;	LDA #$00
;	SEC
;	RTS

SAVEXIT2
	JSR INCRDP		;$FD1B bump current address
	BNE SERSAVLP		;$F6BC continue saving
SERSAV1
	JSR UNLISTEN		;send unlisten

SERSAV1A
	BIT SECADR
	BMI SERSAVRC
	LDA CHANNL		;get device
	JSR LISTEN		;command it to listen
	LDA SECADR		;get SA
	AND #%11101111		;$EF twiddle some bits
	ORA #%11100000		;$E0
	JSR SECOND		;send SA
	JSR UNLISTEN		;send unlisten 

SERSAVRC
	CLC
	RTS			;return clear


;***************************************************************
;===============================================================
; Utility Routines
;===============================================================
;***************************************************************

;===============================================================
; SOUT1 - Serial data output "1" ("false") E4A0
;
SOUT1
	LDA D1PCR		;load PCR
	AND #%11011111		;$DF CB2=L
	STA D1PCR		;save change
	RTS
		

;===============================================================
; SOUT0- Serial data output "0" ("true") E4A9
;
SOUT0
	LDA D1PCR		;load PCR
	ORA #%00100000		;$20 CB2=H
	STA D1PCR		;save change
	RTS			


;===============================================================
; SDCLK - Get SDCLK status E4B2
;	Returns status of PA.0 (CLK_IN) in CY
;
SDCLK
	LDA D1ORAH		;load register
	CMP D1ORAH		;any change?
	BNE SDCLK		;yes (unstable), loop
	LSR A			;shift PA.0 (clk_in) to CY
	RTS			


;===============================================================
; SCLK1 - Set Serial CLK_OUT "1" ("false") EF84
;
SCLK1
	LDA D1PCR		;PCR
	AND #%11111101		;$FD CA2=L
	STA D1PCR		;save it
	RTS			


;===============================================================
; SCLK0 - Set Serial CLK_OUT "0" ("true") EF8D
;
SCLK0
	LDA D1PCR		;PCR
	ORA #%00000010		;$02 CA2=H
	STA D1PCR		;save it
	RTS			


;===============================================================
; DDELAY - Delay 1ms EF96
;	Used only by LISTEN
;
DDELAY
	LDA #$04		;set time-out counter
	STA D1TM2H		; IFR cleared on write (was D2)

DLYLOOP
	LDA D1IFR		;IFR
	AND #%00100000		;Timer2 time-out flagged?
	BEQ DLYLOOP		;no, loop
	RTS			


;===============================================================
; SBIDLE - RS232 idle test F160
;	Used only by IEC_LISTEN
;
SBIDLE

;2003/06/06 -- added
;	Theory behind returning with no idle test being performed is
;	that the former RS232/User Port functions on VIA1 were replaced
;	by the VIA2 IEC functions for T1 (IRQ pulse; not implemented)
;	and T2 (IEC timing). WORKS.
	RTS
;
;
;	PHA			;save .A
;	LDA D1IER		;get IER (was D1)
;	BEQ SBIDLEX		;no interrupts enabled or pending, exit
;
;SBIDLLP				; wait for RS232 timers to time-out
;	LDA D1IER		;get IER
;	AND #%01100000		;$60 mask all but T1 & T2
;	BNE SBIDLLP		;loop
;	LDA #%00010000		;$10 set only CB1 as eligible for IRQs	
;	STA D1IER		;(D1.CB1 is RS232 Rx)
;SBIDLEX	
;	PLA
;	RTS


;===============================================================
; FIND - Look for logical file number in open-file table F3CF
;	On entry to FIND1, .A=file#			
;	On exit, .X=offset in file table			
;
FIND
	LDA #$00			
	STA CSTAT		;clear status
	TXA		
FIND1
	LDX COPNFL		;get #of open files

FINDLOOP
	DEX			
	BMI FEXIT		;reached 0, then exit
	CMP FILTBL,X		;is this the one?
	BNE FINDLOOP		;$F3D6 no, try again
FEXIT
	RTS			;return


;===============================================================
; RSTTPP - Reset memory pointers FBD2
;
RSTTPP
	LDA STAL+1
	STA SAL+1
	LDA STAL
	STA SAL
	RTS


;===============================================================
; CKWRPT - Check read/write pointer for end address FD11
;
CKWRPT
	SEC
	LDA SAL			;SAL is current address
	SBC EAL			;EAL is end address
	LDA SAL+1
	SBC EAL+1
	RTS


;===============================================================
; INCRDP - Increment memory read/write pointer FD1B
;
INCRDP
	INC SAL
	BNE INCRSK
	INC SAL+1
INCRSK
	RTS


;===============================================================
; SSADR - Get SECADR patch for LOAD/VERIFY E4BC
;
SSADR
	LDX SECADR		;get secondary address
	JMP SRCHMS		;print "Searching..."


;===============================================================
; SLDPCH - Relocated patch for serial LOAD/VERIFY E4C1
;
SLDPCH
	TXA
	BNE SLDEXIT		;load location not set in LOAD call, so
				;continue with load

	LDA MEMUSS		;get specified load address from call...
	STA EAL			;and save as program start address
	LDA MEMUSS+1
	STA EAL+1

SLDEXIT	
	JMP LOADMS		;print "Loading"


;===============================================================
; FLATRB - Set file values F3DF
;	On entry, .X = offset in the file tables
;
FLATRB
	LDA FILTBL,X
	STA LOGFIL		;get file#
	LDA DEVTBL,X
	STA CHANNL		;get device
	LDA SECATB,X
	STA SECADR		;get SA
	RTS			


;===============================================================
; SENDSA - Send secondary address F495
;	Called by OPEN, LOAD, SAVE
;
SENDSA
	LDA SECADR		;get SA
	BMI SNDSARC		;$F4C5 neg, exit
	LDY FNMLEN		;get filename length
	BEQ SNDSARC		;$F4C5 0, error	
	LDA CHANNL		;get device
	JSR LISTEN		;command it to listen
	LDA SECADR		;get SA
	ORA #%11110000		;$F0
	JSR SECOND		;$EEC0	sent it
	LDA CSTAT		;status
	BPL SENDSA1		;$F4B2 OK, continue
;	brk
	PLA			;error, set RTS for caller's caller
	PLA
	JMP IOERMS5		;$F78A "DEVICE NOT PRESENT" error

SENDSA1	
	LDA FNMLEN		;get filename length
	BEQ SNDSARU		;$F4C2 len=0, send unlisten and exit
	LDY #$00

SENDSALP
	LDA (FNPTR),Y		;send filename to IEEE
	JSR CIOUT		;send char
	INY
	CPY FNMLEN
	BNE SENDSALP		;$F4B8 loop

SNDSARU
	JSR UNLISTEN		;done, send unlisten command

SNDSARC
	CLC
	RTS


;===============================================================
; SRCHMS - Print "Searching for [filename]" F647
;
; FIXME -- IEC loading and saving must have filename, so "FOR"
;		must always be printed (this is a leftover from
;		tape processing).
;
SRCHMS
	LDA CMDMOD		;direct mode?
	BPL SRCHEX		;$F669 no, exit
	LDY #KIM_SRCH		;"Searching for"
	JSR DMSG		;output message
	LDA FNMLEN		;filename length
	BEQ SRCHEX		;$F669 no filename, skip "for"
	LDY #KIM_FOR		;point to "FOR" in "Searching For"
	JSR DMSG		;print it

; FLNMMS - Print filename only
;
FLNMMS				
	LDY FNMLEN		;get filename length
	BEQ SRCHEX		;$F669 no filename, exit
	LDY #$00
FLNMLP
	LDA (FNPTR),Y		;print filename
	JSR OUTPUT
	INY
	CPY FNMLEN
	BNE FLNMLP
SRCHEX
	RTS			;exit


;===============================================================
; LOADMS - Print "Loading" or "Verifying" F66A
;
LOADMS
	LDY #KIM_LOAD		;"Loading" assumed
	LDA IOFLG2		;check load/verify flag-0=load
	BEQ DOMESG		;$F672 load, print message
	LDY #KIM_VERF		;flag=1, "Verifying"
DOMESG
	JMP DMSG		;print message


;===============================================================
; SAVEMS - Print "Saving [filename]"  F728
;
SAVEMS
	LDA CMDMOD		;direct mode?
	BPL SVRET		;no, exit
	LDY #KIM_SAVE		;yes, print 'Saving
	JSR DMSG		;print message
	JMP FLNMMS		;print filename
SVRET
	RTS


;===============================================================
;IOERMS - I/O Error Messages F77E
;
;  PARAMS   :  .A = unused. Error 0 is "Break Error"
;	       .X = unused
;	       .Y = unused
;  RETURNS  :  nothing
;  PRE-CALLS:  none
;  COMMENTS :  Should only be called during a file-oriented operation
;		since it calls CLRCH to clear the I/O channel of errors.
;
IOERMS1
	LDA #$06		;Too Many Files
	.byte $2C	
IOERMS2
	LDA #$14		;File Already Open 
	.byte $2C 
IOERMS3
	LDA #$1d		;File Not Open
	.byte $2C 
IOERMS4
	LDA #$2a		;File Not Found
	.byte $2C 
IOERMS5
	LDA #$38		;Device Not Present
	.byte $2C 
IOERMS6
	LDA #$4a		;Not Input File
	.byte $2C 
IOERMS7
	LDA #$58		;Not Output File
	.byte $2C 
IOERMS8
	LDA #$67		;Missing File Name
	.byte $2C 
IOERMS9
	LDA #$77		;Illegal Device 
	PHA			; save offset/error#
	JSR CLRCH		; clear I/O channel
;	BIT CMDMOD		; BIT7=1 for direct
;	BVC IOERMSEX		; must be RUN mode, exit
	jsr Print_CR		; preserves .A
	PLA			; restore error#
	TAY			; copy error# to .Y for DMSG
	JSR DMSG		; print message. Call with .Y/preserves .A
	ldy #$ec		;
	JSR DMSG		; print " ERROR"
	jsr Print_CR

IOERMSEX
;	jsr CLOSEALL
;	jmp DPROMPT
	SEC
	RTS			; return error# and CY=1 to caller
	

;===============================================================
; System Informational (non I/O) Messages
;
;  PARAMS   :  .A = unused
;	       .X = unused
;	       .Y = offset to start of message in message table
;  RETURNS  :  nothing
;  PRE-CALLS:  none
;  COMMENTS :  Can be called when non-I/O operations are in effect.
;
;
PRMERR
	lda #$d9		;Bad Parameter error
	.byte $2c
SNERR
	lda #$e6		;Syntax error
	tay			; copy message number to offset
;	BIT CMDMOD		; BIT7=1 for direct
;	BVC SMSGEX		; must be RUN mode, exit
	jsr Print_CR
	JSR DMSG		; print error message
	ldy #$ec		;
	JSR DMSG		; print " ERROR"
	jsr Print_CR

SMSGEX
	SEC
	RTS

	
;===============================================================
; DMSG -- Print Error Messages
;
;  PARAMS   :  .A = unused
;	       .X = unused
;	       .Y = offset to start of message in message table
;  RETURNS  :  nothing
;  PRE-CALLS:  none
;  COMMENTS :  Can be called when non-I/O operations are in effect.
DMSG
	PHA			; preserve .A

DMSG1	LDA KRNLMSGS,Y
	PHP			;save character
	AND #%01111111		;$7F clear character shift
	JSR OUTPUT		;output character
	INY			;increment
	PLP
	BPL DMSG1		;loop
	
	PLA			; restore .A
	CLC
	RTS			; exit clear


;==========================================================
; KRNLMSGS - KERNEL I/O messages
;
KRNLMSGS
; VIC-20 Kernal I/O Error messages
	.byte "BREAK", $CB			;00h
	.byte "TOO MANY FILE", $D3		;06
	.byte "FILE OPE", $CE			;14
	.byte "FILE NOT OPE", $CE		;1d
	.byte "FILE NOT FOUN", $C4		;2a
	.byte "DEVICE NOT PRESEN", $D4		;38
	.byte "NOT INPUT FIL", $C5		;4a
	.byte "NOT OUTPUT FIL", $C5		;58
	.byte "MISSING FILENAM", $C5		;67
	.byte "ILLEGAL DEVICE NUMBE", $D2	;77
; PET/VIC/C64 Kernal I/O Informational messages
	.byte "SEARCHING", $A0, "FOR", $A0	;8c
	.byte "LOADIN", $C7			;9a
	.byte "WRITING", $A0			;a1
	.byte "VERIFYIN", $C7			;a9
	.byte "FOUND", $A0			;b2
	.byte "OK", $8D				;b8
	.byte "READY.", $8D			;bb
	.byte "ARE YOU SURE ", $BF		;c2
	.byte "BAD DISK", $8D			;d0
	.byte "BAD PARAMETE",$D2		;d9
	.byte "SYNTA", $d8			;e6
	.byte " ERROR",$8d			;ec-f2

;###############################################################
; PET BASIC 4.0 DISK COMMAND PROCESSOR
;###############################################################
;
; All routines use .Y as an index into the command line buffer.
; .X is used in the functions with filenames as an index into the
;	disk command string being built.
;
SIGNONMSG
	.byte $0d, $0a, "Commodore DOS Command Interpreter v.1.0", $0d, $0a
	.byte "(c) 2003 Richard A. Cini", $0d, $0a, "Ready.", $00

;  DLIST - Dispatch Location List
DLIST
	.word CATALOG
	.word COLLECT
	.word COPY
	.word DS
	.word HEADER
	.word INITDRV
	.word RENAME
	.word SCRATCH
	.word Exit_Dos
;	.word HelpCmd

;  WLIST - ASCII Token Table
WLIST
	.byte "CATALO",$C7	; disk directory (non-native)
	.byte "COLLEC",$D4	; collect/validate
	.byte "COP",$D9		; copy
	.byte "D",$D3		; DS (non-native)
	.byte "HEADE",$D2	; header/new
	.byte "INITIALIZ",$C5	; initialize
	.byte "RENAM",$C5	; rename
	.byte "SCRATC",$C8	; scratch
	.byte "QUI",$D4		; quits DOS
;	.byte "HEL",$D0		; Help
	.byte $00		; end of table marker

NUMCMDS =$0a

;===============================================================
; Dos_Init -- CBM DOS Command Interpreter
;
;  PARAMS   :  None. Called directly by the command parser in
;		the System Monitor.
;  COMMENTS :  Actual command line retrieved by calling the 
;		Input_DOS function; command line is stored
;		in the Buffer variable. Commands use file
;		number 255 for itself.
;===============================================================
Dos_Init

	ldx #$00	; clear working variables
	stx BUFIDX	; index into command line buffer
	stx KWCNT	; token count (used for indexed dispatch)
	stx TMP3	; {unused}

; Print DOS sign-on message
MSGLOOP lda SIGNONMSG,x
	beq DPROMPT
	jsr OUTPUT
	inx
	bne MSGLOOP

DPROMPT			; prompt loop
	jsr Input_DOS	; Returns command line in Buffer; terminated with <CR>
	jsr Print_CR	;

CRUNCH			; start parsing buffer for initial keyword
	ldy #$00	; start at char 0 in buffer

LOOPOT	lda Buffer,y	; get character
	bne CNCHER	; if 0, error_exit
	cmp #$0d	; <CR>?
	beq DPROMPT	; Prompt again
 	cmp #"A"	; Check if in alpha range...
	bcc LOOPBK	; No...BELOW
	cmp #"["	; "Z"+1
	bcs LOOPBK	; No...ABOVE

			; tokenize if in tables (except we don't reduce to token#)
	sty BUFIDX	; save current index into Buffer for this compare
	ldx #$00	; start at 0th token
	stx KWCNT	; save token number

LOOPIN			; loop to compare token character against Buffer
	sec		; setup for subtraction
	sbc WLIST,x	; check character
	beq LNEXT	; Matched character? Y=continue checking
	cmp #$80	; No but 80h remainder?
	beq BYEBYE	; Yes, end of keyword and token match. Go to dispatcher...

LOOPNO	lda WLIST,X	; No match, so loop through rest of keyword
	beq LOOPBK	; At end of token list, discard character in Buffer
	bmi CONTLP	; At end of token, compare to next token
	inx
	bne LOOPNO	; loop

CONTLP	inc KWCNT	; Increment token count
	cmp #NUMCMDS	; reached max# of commands
	bpl CNCHER	; yes
	ldy BUFIDX	; point to beginning of Buffer
	.byte $A9	; Skip "iny" (LDA #)

LNEXT			; character in Buffer matched token
	iny		; increment command buffer pointer
	lda Buffer,y	; get next character in command line buffer
	inx		; point to next character in token list
	bne LOOPIN	; compare

LOOPBK
	iny
	bne LOOPOT

BYEBYE			; Command dispatcher. X=command# Y=Buffer index
	sty BUFIDX	; save last index value
	lda KWCNT	; KWCNT should be index# of command in DLIST
	asl a		; Multiply by 2
; SEE ALTERNATIVE METHOD BELOW TO AVOID JMP INDIRECT BUG
	tay			
	lda DLIST+1,y	; Index into dispatch list
	sta USRVEC+1	; save MSB
	lda DLIST,y
	sta USRVEC	; save LSB
	lda #>DPROMPT	; MSB setup stack for return
	pha
	lda #<DPROMPT	; LSB
	pha 
	jmp (USRVEC)	; Jump to actual routine. When routine completes,
			; execution should continue at DPROMPT.
; ALTERNATE CODE
;	tay
;	lda DLIST+1,y
;	pha
;	lda DLIST,y
;	pha
;	rts
;
;DLIST
;	.word CATALOG-1	; address-1 because RTS adds one before branching
;	.word et cetera
;
; END OF ALTERNATE


Exit_Dos		; We get here on "QUIT" command
	pla		; Pop address of "DPROMPT" off of
	pla		; the stack and...
CNCHRT
	jmp Start_OS	; ...return to the Monitor

CNCHER			; Syntax error
	jsr SNERR
	jmp DPROMPT



;===============================================================
; CATALOG - CATALOG[,device] where device is 8-11
;
;===============================================================
CATALOG

	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq CAT0	; Yes. Do directory with ID=8
	cmp #$2C	; comma?
	beq CDRV	; Yes. Get drive ID
	jmp CAERR	; Anything else is an error

CDRV			; got comma-look for drive number
	iny		; move to next character
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; get byte parameter. Should pickup any errors.
	bcs CAERR	; error catch-all
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi CAERR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl CAERR	; yes...error
	sta CMD_DEV	; overwrite default device

CAT0
	jsr Print_CR	; start on new line
	LDA #$01	; setup filename "$"
	LDX #<SDIR	; LSB
	LDY #>SDIR	; MSB
	JSR SETNAM
	LDA #$ff	; handle $ff
	LDX CMD_DEV	; device
	LDY #$00	; secondary
	JSR SETLFS	; set file parameters...
	JSR OPEN	; ...and open
	LDX #$ff	; set channel for input
	JSR CHKIN	; ignore
	JSR CHRIN	; ignore first two bytes retrieved 
	JSR CHRIN	;(starting address of BASIC line)

SKIP	JSR CHRIN 	;skip poiner to next BASIC line (2 bytes)
BCK1	JSR CHRIN
LINE	JSR CHRIN	;get BASIC line# LSB (#blocks)	
	tay		; move save LSB to .Y
	JSR CHRIN	;get BASIC line# MSB
	PHA		; push MSB
	TYA		; move lsb from .Y to .A...
	TAX		; ..then to .X
	PLA		; restore MSB to .A
	JSR Prt_AX_Dec	; in BASIC; print AX as unsigned integer
	LDA #$20	; print a <space>
	JSR OUTPUT

LP2			; print the filename
	JSR CHRIN	; get character
	BEQ C2		; EOL?
	JSR OUTPUT	; no, print char
	SEC
	BCS LP2		; loop

C2			; EOL reached
	jsr Print_CR	; print CRLF
	JSR CHRIN	; get next char (s/b nxt_ptr_L or 0)
	BNE BCK1	; If not 0, get next char (nxt_ptr_H)
	JSR CHRIN	; Got first 0, so check for second. Two nulls here means end of dir.
	BNE LINE	; not 0 so loop back and get line#

EXIT
	jsr Print_CR
	JSR CLRCH
	LDA #$ff	; We reached the end of the directory so close up
	JSR CLOSE
	jmp DPROMPT	
	
CAERR	jsr PRMERR
	jmp DPROMPT


;===============================================================
; COLLECT - COLLECT[,device] where device is 8-11
;
;===============================================================
COLLECT

	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq COL0	; Yes. Do command with ID=8
	cmp #$2C	; comma?
	beq COLDRV	; Yes. Get drive ID
	jmp CERROR	; Anything else is an error

COLDRV			; got comma-look for drive number
	iny		; move to next character
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; get byte parameter. Should pickup any errors.
	bcs CERROR	; error catch-all
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi CERROR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl CERROR	; yes...error
	sta CMD_DEV	; overwrite default device

COL0
	LDA #$00	; setup filename (none required)
	JSR SETNAM
	LDA #$ff	; setup OPEN params
	LDX CMD_DEV
	LDY #$0f
	JSR SETLFS
	JSR OPEN	; OPEN device
	LDX #$ff	; set channel for output
	JSR CHKOUT
	JSR READST
	lda #$56	; select validate command
	JSR CHROUT	; send command to channel
	JSR CLRCH
	LDA #$ff	; Now close the file
	JSR CLOSE
	jmp DPROMPT

CERROR	jsr PRMERR
	jmp DPROMPT


;===============================================================
; COPY - COPY[,device] "dest"="src" where device is 8-11.
;	Copies source file to destination file. The copy command
;	built into the 1541 does not support copying across
;	different drive IDs. Dual-drive units, like the 4040 or
;	8050 supported true cross-disk copying and disk backups.
;
;	No spaces can exist between file parameters.
;===============================================================
COPY
	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq CPYERR	; Yes. Command with no params. Error
	cmp #$2C	; comma?
	beq CPYDRV	; Yes. Get drive ID
	bne NOCDRV	; No. Skip drive ID

CPYERR	jsr PRMERR
	jmp DPROMPT

CPYDRV			; got comma-look for drive number
	iny		; move to next character
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; Get byte parameter. A/Y set to first char after numeric parm
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi CPYERR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl CPYERR	; yes...error
	sta CMD_DEV	; overwrite default device

NOCDRV			; drive ID cleared. Parse for filenames and build command.
	ldx #$00	; start at 0 of command buffer
CCL0		
	lda SCPY,x	; copy drive command string to buffer
	beq RCPY
	sta FNM1,x
	inx
	bne CCL0

RCPY			; RENAME command can come to here...
	iny		; move to next character
	jsr SKIPSP	; skip any spaces
	cmp #$22
	bne CPYERR
	lda #$11	; Yes. Got first quote
	sta FNMLEN	; set filename length variable to 16+1
	iny		; get first char of filename 1

CQLOOP1
	lda Buffer,y	; get char (not a leading space)
	cmp #$22	; second quote?
	bne NOTYET1	; No. Copy character
	beq CHKEQ	; Yes. Check for equal sign

NOTYET1
	sta FNM1,x	; Quote not found yet so copy filename
	inx		; next char in FNM1
	iny		; next char in Buffer
	dec FNMLEN
	beq CHKEQ	; Done. Check for equal sign
	bra CQLOOP1	; No. Copy more.

CHKEQ			; check for the equal sign
	iny		; next char in Buffer past quote
	jsr SKIPSP	; skip any spaces
;	lda Buffer,y	; SKIPSP loads .A with current char in buffer (***DEL)
	cmp #$3D	;"="
	bne CPYERR	; missing = 
	sta FNM1,x	; save "=" in command buffer

			; start parsing for second filename
	inx		; next char in FNM1
	iny		; next char in Buffer past equal sign
	jsr SKIPSP	; skip any spaces again
	cmp #$22	; quote?
	bne CPYERR	; No. Missing second file name
	lda #$11	; Yes. Got first quote of second name
	sta FNMLEN	; set filename length variable to 16+1
	iny		; get first char of filename 2

CQLOOP2
	lda Buffer,y	; get char (not a leading space)
	cmp #$22	; second quote of second filename?
	bne NOTYET2	; No. Copy character of filename
	beq CFN2D	; Yes. Do command

NOTYET2
	sta FNM1,x	; Quote not found yet so copy filename
	inx		; next char in FNM1
	iny		; next char in Buffer
	dec FNMLEN
	beq CFN2D	; Done. Pointer points at last quote
	bra CQLOOP2	; No. Copy more.

CFN2D			; filenames done, so we can now send the command
	LDA #$00	; setup filename (none required)
	sta FNM1,x	; zero-terminate string
	JSR SETNAM
	LDA #$ff	; setup OPEN params
	LDX CMD_DEV
	LDY #$0f
	JSR SETLFS
	JSR OPEN	; OPEN device
	LDX #$ff	; set channel for output
	JSR CHKOUT
	JSR READST
	ldx #$00

CCMDL
	lda FNM1,x	; get char in command string
	beq CCMDL1
	JSR CHROUT	; send character to channel
	inx
	bra CCMDL	; copy more

CCMDL1
	JSR CLRCH	; Done, so clear channel status
	LDA #$ff	; Now close the file
	JSR CLOSE
	jmp DPROMPT


;===============================================================
; DS - DS[,device] where device is 8-11. Reads the directory
;	on the disk and prints it to the console.
; 
;===============================================================
DS

	lda #$08	; default to unit 8
	sta CMD_DEV	; save default device for current command
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to first character past keyword
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq DOSTAT	; Yes. No param so just do command
	cmp #$2C	; comma?
	beq DDRV	; Yes. Get drive ID
	jmp DSERR	; Anything else is an error

DDRV
	iny		; Got comma; point to next char
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; get byte parameter into TMP3
	bcs DSERR	; invalid parameter
	lda TMP3	; get converted parameter
	cmp #$08	; Below 8?
	bmi DSERR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl DSERR	; yes...error
	sta CMD_DEV	; overwrite default device

DOSTAT			; we have a valid unit number, so get status
	LDA #$00	; setup filename
	JSR SETNAM	; none required for DS
	LDA #$ff	; setup OPEN params
	LDX CMD_DEV
	LDY #$0f
	JSR SETLFS
	JSR OPEN	; open device
	LDX #$ff	; set channel for input
	JSR CHKIN
DSLOOP	JSR CHRIN	; read until receiving <CR>
	JSR OUTPUT
	CMP #$0D
	BNE DSLOOP
	JSR CLRCH
	LDA #$FF	; Now close the file
	JSR CLOSE
	jmp DPROMPT

DSERR	jsr PRMERR
	jmp DPROMPT


;===============================================================
; HEADER - HEADER[,device] "DiskName",Ivv where device is 8-11.
;	Ivv is a two-character disk ID. DiskName can be up to
;	16 characters long. If the Ivv parameter is not present,
;	the command results in the drive erasing all of the
;	files on an already-formatted disk.
;===============================================================
HEADER
	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq HDRERR	; Yes. Command with no params. Error
	cmp #$2C	; comma?
	beq HDRDRV	; Yes. Get drive ID
	bne NOHDRV	; No. Skip drive ID

HDRERR	jsr PRMERR
	jmp DPROMPT

HDRDRV			; got comma-look for drive number
	iny		; move to next character
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; get byte parameter. Should pickup any errors.
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi HDRERR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl HDRERR	; yes...error
	sta CMD_DEV	; overwrite default device

NOHDRV			; drive ID cleared. Parse for params and build command.
	ldx #$00	; start at 0 of command buffer
HCL0			; copy command string to command buffer
	lda SNEW,x
	beq HCL1 
	sta FNM1,x
	inx
	bne HCL0

HCL1
	iny		; move to next character
	jsr SKIPSP	; skip any spaces
	cmp #$22
	bne HDRERR	; No. Missing quote error
	lda #$11	; Yes. Got first quote
	sta FNMLEN	; set filename length variable to 16+1
	iny		; increment buffer pointer

HQLOOP1
	lda Buffer,y	; get char (not a leading space)
	cmp #$22	; test for second quote
	bne NOTYETH	; No. copy character
	beq HFN1D	; Yes. Move on to second param

NOTYETH
	sta FNM1,x	; Quote not found yet so copy filename
	inx		; next char in FNM1
	iny		; next char in Buffer
	dec FNMLEN
	beq HFN1D	; Done processing disk name
	bra HQLOOP1	; No. Copy more.

HFN1D			; hit max filename length or second quote
;	inx		; next char in FNM1
	iny		; next char in Buffer
	jsr SKIPSP
;	lda Buffer,y
	cmp #$2C	; comma?
	beq IPARAM	; Yes. Get disk ID param
	bne NEWDISK	; No. Directory erase command, so NEW disk

IPARAM
	sta FNM1,x	; save comma to disk command buffer
	inx		; next char in FNM1
	iny		; next char in Buffer
	lda Buffer,y	; get next char 
			; take the next two ASCII chars as the ID parameter
	jsr CHKASC
	bcs HDRERR
	sta FNM1,x	; save first ID
	inx		; next slots
	iny
	lda Buffer,y	; get next char 
	jsr CHKASC
	bcs HDRERR
	sta FNM1,x	; save second ID

NEWDISK 
	inx		; Done; move to last slot of command string
;	jsr CONFOPS	; Query user to make sure that the NEW operation is OK
;	bcs NEWEXIT	; Not OK; abort operation
	LDA #$00	; setup filename (none required)
	sta FNM1,x 	; zero-terminate command string
	JSR SETNAM
	LDA #$ff	; setup OPEN params
	LDX CMD_DEV
	LDY #$0f
	JSR SETLFS
	JSR OPEN	; OPEN device
	LDX #$ff	; set channel for output
	JSR CHKOUT
	JSR READST
	ldx #$00

NEWCMDL
	lda FNM1,x	; get char in command string
	beq NEWEX1	; end of string; done
	JSR CHROUT	; send character to channel
	inx
	bra NEWCMDL	; Loop

NEWEX1
	JSR CLRCH	; Command done, so clear channel status
	LDA #$ff	; Close the file
	JSR CLOSE

NEWEXIT
	jmp DPROMPT


;===============================================================
; INITDRV - INITIALIZE[,device] where device is 8-11
;
;===============================================================
INITDRV

	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq INIT0	; Yes. Do command with ID=8
	cmp #$2C	; comma?
	beq INDRV	; Yes. Get drive ID
	jmp INERROR	; Anything else is an error

INDRV			; got comma-look for drive number
	iny		; move to next character
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; get byte parameter. Should pickup any errors.
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi INERROR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl INERROR	; yes...error
	sta CMD_DEV	; overwrite default device

INIT0
	LDA #$00	; setup filename (none required)
	JSR SETNAM
	LDA #$ff	; setup OPEN params
	LDX CMD_DEV
	LDY #$0f
	JSR SETLFS
	JSR OPEN	; OPEN device
	LDX #$ff	; set channel for output
	JSR CHKOUT
	JSR READST
	lda #$49	; select initialize command
	JSR CHROUT	; send command to channel
	JSR CLRCH
	LDA #$ff	; Now close the file
	JSR CLOSE
	jmp DPROMPT

INERROR
	jsr PRMERR
	jmp DPROMPT

	
;===============================================================
; RENAME - RENAME[,device] "NewName"="OldName" where
;	device is 8-11. OldName and NewName can be up to 16
;	characters each. Assumes that the rename occurs on the
;	same drive (i.e., you can't rename and copy a file 
;	across two drives in the same operation). There can be
;	no spaces between filename parameters.
;===============================================================
RENAME
	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq RNERROR	; Yes. Command with no params. Error
	cmp #$2C	; comma?
	beq RENDRV	; Yes. Get drive ID
	bne NORDRV	; No. Skip drive ID

RENDRV			; got comma-look for drive number
	iny		; move to next character
	jsr SKIPSP	; skip any spaces after comma. A/Y set to current char/offset
	jsr GETBYT	; get byte parameter. A/Y set to first char after numeric param
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi RNERROR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl RNERROR	; yes...error
	sta CMD_DEV	; overwrite default device

NORDRV			; drive ID cleared. Parse for filename and build command.
	ldx #$00	; start at 0 of command buffer
RCL0			; copy command string to command buffer
	lda SREN,x
	sta FNM1,x
	inx
	bne RCL0
	jmp RCPY	; coninue RENAME command through COPY code.

RNERROR
	jsr PRMERR
	jmp DPROMPT

;===============================================================
; SCRATCH - SCRATCH[,device] "filename" where device is 8-11.
;	Filename can be up to 16 characters.
;===============================================================
SCRATCH	
	ldx #$08	; set default device to U8
	stx CMD_DEV
	lda #$ff	; system LFN
	jsr CLOSE	; close it just in case 

	ldy BUFIDX	; get current offset into command line
			; need to do this since dispatcher
			; destroys .Y
	iny		; move to next char in buffer
	lda Buffer,y	; get it
	cmp #$0d	; end of line?
	beq SCRERR	; Yes. Command with no params. Error
	cmp #$2C	; comma?
	beq SCRDRV	; Yes. Get drive ID
	bne NOSDRV	; No. Skip drive ID

SCRERR	jsr PRMERR
	jmp DPROMPT

SCRDRV			; got comma-look for drive number
	iny		; next char in Buffer
	jsr SKIPSP	; skip any spaces after comma. A/Y set to first char after last space
	jsr GETBYT	; Get byte parameter. A/Y set to first char after numeric param
	lda TMP3	; load converted value
	cmp #$08	; Below 8?
	bmi SCRERR	; yes...error
	cmp #$0c	; above 11 (11+1)?
	bpl SCRERR	; yes...error
	sta CMD_DEV	; overwrite default device

NOSDRV			; Drive ID cleared. Begin building drive command string.
	ldx #$00	; Start at beginning of command buffer

SCMDL
	lda SSCR,x	; Copy drive command to buffer
	beq SCMDD
	sta FNM1,x
	inx
	bne SCMDL

SCMDD			; Copy parameter to drive command buffer
	iny
	jsr SKIPSP	; skip any spaces between device ID and string
	cmp #$22	; next char a quote?
	bne SCRERR	; No. Missing quote error
	lda #$11	; 
	sta FNMLEN	; set max filename length variable to 16+1
	iny		; next char (first char of filename)

SQLOOP1
	lda Buffer,y	; get char (not a leading space)
	cmp #$22	; second quote
	bne NOTYET3	; No. Copy character.
	beq SFN1D	; Yes. Do command. Could be NULL string

NOTYET3
	sta FNM1,x	; Quote not found yet so put char in command buffer
	inx		; next char in FNM1
	iny		; next char in Buffer
	dec FNMLEN
	beq SFN1D	; reached max# of chars, so do command (***ADDED)
	bra SQLOOP1	; No. Copy more. (branch always)

SFN1D			; Hit max filename length or second quote so
	jsr CONFOPS	; filename is done. Query user to make sure that this is OK
	bcs SCMDL4	; Not OK, exit
	LDA #$00	; setup filename (none required)
	sta FNM1,x	; terminate disk command string (***ADDED)
	JSR SETNAM
	LDA #$ff	; setup OPEN params
	LDX CMD_DEV
	LDY #$0f
	JSR SETLFS
	JSR OPEN	; OPEN device
	LDX #$ff	; set channel for output
	JSR CHKOUT
	JSR READST
	ldx #$00	; start at beginning of command buffer

SCMDL2
	lda FNM1,x	; get char in command string
;	cmp #$00	; end of string?
	beq SCMDL3
	JSR CHROUT	; send character to channel
	inx
	bra SCMDL2	; Copy more.

SCMDL3
	JSR CLRCH	; Done, so clear channel status
	LDA #$ff	; Now close the file
	JSR CLOSE

SCMDL4
	jmp DPROMPT


;===============================================================
; GETBYT - Get byte-sized parameter from the command line
; Converts 2-char string literal to integer (i.e., 00-99)
; Call with .Y equal to the offset of the first char of the
; 	ASCII string to be converted to decimal. Returns with
;	.Y set to the first character after the numeric parameter.
; Returns decimal number in TMP3. Destroys A.
;
GETBYT
	lda  Buffer,y	; get char
	cmp  #$30	;  ascii "0"
	bmi  GERROR	; not a valid digit
	cmp  #$3a	; ascii "9"+1
	bpl  GERROR	; mask out valid ascii digit
	and  #$0f	; convert it to binary
	sta  TMP3
	iny
	lda  Buffer,y	; get next digit
	cmp  #$30
	bmi  NONDIG	; test it for valid ascii code
	cmp  #$3a
	bpl  NONDIG	; next chr is not a digit, we are done
	lda  TMP3	; get value
	asl		; mult x2
	sta  TMP3	; save it
	asl
	asl		; mult x8
	clc
	adc  TMP3	; add val*8 to val*2
	sta  TMP3	; value *10 in temp
	lda  Buffer,y	; get second digit again
	and  #$0f	; already tested, so convert to bin
	adc  TMP3	; add to first digit
	sta  TMP3
	iny		; adjust buffer pointer if needed
	clc
NONDIG	rts		; return with value in temp

GERROR	
	sec
	ret
	

;===============================================================
; SKIPSP - Skip any spaces in command buffer. 
; .Y is index into buffer; .A is char at current pointer
SKIPSP
	lda Buffer,y	; reload char at current offset
	cmp #" "	; space?
	bne SPEXIT	; No...just exit
	iny		; Yes...check next char and loop
	bra SKIPSP		

SPEXIT
	rts


;===============================================================
; CHKASC - Check if char in .A is an ASCII char (0-9; A-Z)
CHKASC
	cmp #"0"	; 0-9=30h-39h; A-Z=41h-5ah
	bmi ASCERR
	cmp #$5b	; "Z"+1
	bpl ASCERR
			; in range of 30-5a; now exclude punctuation 3a-40
	cmp #$3a	; "9"+1
	bmi ASCOK
	cmp #$40	; last punct
	bpl ASCOK

ASCERR
	sec
	rts

ASCOK
	clc
	rts


;====================================================================
; CONFOPS - Query "Are you sure?"
;		
CONFOPS
;	jsr Print_CR
	ldy #$c2	;print "Are you sure?"
	jsr DMSG
;	jsr InputWait	;get line of input from KBD no prompt; <CR> ends
	jsr Input_Chr	;get a single character (waits for input)
	cmp #"Y"	;"Y" Yes
	beq CONF1
	cmp #"N"	;"N"
	beq CONF2
	cmp #$0d	;<CR>?
	beq CONF2	; exit
	bra CONFOPS	; loop

CONF1
	clc
	rts

CONF2
	sec
	rts

	
;Print AX as unsigned integer
; Used by the CATALOG command
Prt_AX_Dec
	STA	FAC1_1		; save high byte as FAC1 mantissa1
	STX	FAC1_2		; save low byte as FAC1 mantissa2
	LDX	#$90		; set exponent to 16d bits
	SEC			; set integer is +ve flag
	JSR	LAB_STFA	; set exp=X, clearFAC1 ...	
	JSR	LAB_296E	; convert FAC1 to string
;decimal string is now ready at Decss+1 ($F0), terminated with $00.
	ldy	#$01
lp1	lda	Decss,y
	beq	done2
	jsr	OUTPUT
	iny
	bra	lp1
done2	rts


; Disk command strings. Collect and Initialize are single-byte commands
; sent directly by the command code.
SDIR	.byte "$"		; catalog/directory filename
SCPY	.byte "C0:",$00		; copy
SNEW	.byte "N0:",$00		; header/new
SREN	.byte "R0:",$00		; rename
SSCR	.byte "S0:",$00		; scratch
;###############################################################
