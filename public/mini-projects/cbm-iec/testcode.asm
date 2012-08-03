	*=$8100

_PRN	JMP PRNTEST
_ERR	JMP READERR
_RLOAD  JMP RLOAD
_RSAVE	JMP RSAVE
_DTEST	JMP DTEST

; 2003/07/09 notes:
; RLOAD: (1) doesn't clear drive status on exit
;	 (2) prints "019D" for size
; RSAVE: saves file of size 32,000 (125 blocks), type PRG

;-------------------------------------
; Subroutine to test the printer
;-------------------------------------
PRNTEST
;; SETNAM
	lda #$00	; no filename
	jsr SETNAM

;; SETLFS
	lda #$01	; file handle
	ldx #$04	; device
	ldy #$ff	; command
	jsr SETLFS
	jsr OPEN

;; CHKOUT - set channel for output
	ldx #$01	; handle 1 for output
	jsr CHKOUT

;; CHROUT - output character
	ldx #$20	; start at {space}
CHR_LOOP
	txa		; move char to .A
	jsr CHROUT	; send it
	inx
	cpx #$7f	; max char
	bmi CHR_LOOP

;; CLOSE
	lda #$01	; close handle 1	
	jsr CLOSE
	rts		;JMP START_OS	; JMP to monitor...

;-------------------------------------
; Subroutine to read the error channel
;-------------------------------------
READERR

	; setup filename
	LDA #$00
	JSR SETNAM

	; setup OPEN params and OPEN channel
	LDA #$0f
	LDX #$08
	LDY #$0f
	JSR SETLFS
	JSR OPEN	;"OPEN 15,8,15"

	; set channel for input
	LDX #$0f
	JSR CHKIN

	; read until receiving <CR>
LOOP	JSR CHRIN
	JSR OUTPUT
	CMP #$0D
	BNE LOOP

	; Now close the file
	LDA #$0F
	JSR CLOSE
	JSR CLRCH
	rts	;JMP START_OS	; JMP to monitor...
	

;-------------------------------------
; Subroutine to test LOAD command
;PARAMS: .A = 0 (load) or 1 (verify)
;       If a "relocated load" is required, set:
;	 .X = LSB of "from" address
;	 .Y = MSB of "from" address
;       Otherwise, set .X/.Y to $ff for the default
;	starting address (MEMBOT). For SA 0-2, the address
;	is set from the file header. For SA 3, .X/.Y
;	required to be set.
;  RETURNS  :  .X/.Y is LSB/MSB of RAM load address
;  PRE-CALLS:  MEMBOT, SETLFS, SETNAM
;-------------------------------------
RLOAD
	
	LDA #$08	; setup filename
	LDX #<SFNM	;LSB
	LDY #>SFNM	;MSB
	JSR SETNAM

	LDA #$20	; setup FS params
	LDX #$08
	LDY #$01	; SA=1 to take info from header; SA=0 for relocated load
	JSR SETLFS

	; setup params and call LOAD
	LDA #$00	; 0=load; 1=verify
	LDX #$ff	; LSB of "from" or FF for default from MEMBOT
	LDY #$ff	; MSB of "from"
	JSR LOAD	; returns highest loaded address in YYXX
	tya		; print highest loaded address
	JSR Print_CR
	JSR Print2Byte	; in Monitor; print AAXX in hexadecimal
	JSR Print_CR
	rts


;-------------------------------------
; Subroutine to test SAVE command
;  PARAMS:  .A = offset to Z-page pointer containing starting
;	    address (calculated as TAX/LDA USRPOK,X). So, 
;	    if USRPOK is at $14 and word pointer is at
;	    $17 (OSSTAR), set .A with $03
;	    .X = LSB of "to" address
;	    .Y = MSB of "to" address
;	    "From" address set by calling MEMBOT with .X/.Y of
;		starting location (MEMBOT sets OSSTAR)
;  RETURNS  :  nothing
;  PRE-CALLS:  MEMBOT, SETLFS, SETNAM
;-------------------------------------
RSAVE
	
	LDA #$08	; setup filename
	LDX #<SFNM	;LSB
	LDY #>SFNM	;MSB
	JSR SETNAM

	LDA #$20	; setup FS params
	LDX #$08
	LDY #$00
	JSR SETLFS

	; setup params and call SAVE
	LDA #$03	; offset to ZPage pointer
	LDX #$ff	; LSB of "to"
	LDY #$7e	; MSB of "to"; $7fxx is I/O block
	JSR SAVE
	rts

SFNM	.byte "TESTFILE"


; Test of DDelay routine. At 1MHz, this should pause for ~2 sec.
; 256*8 (2048) passes of 1ms each
DTEST
	ldy  #$08
	ldx  #$00
tst2	jsr  DDELAY	; pause 1ms
	dex
	bne  tst2
	dey
	bne  tst2
	rts

