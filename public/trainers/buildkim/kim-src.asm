; KIM-1 Source Code from Ruud Baltissen
; Last update: 19 October 1997
;
;
; The sourcecode is copied from 'KIM-1 MANUAL' released by MOS Technologies
; and this means that someone probably has the copyrights of it. Until 
; someone clears the mess around 'who owns what from Commodore', leave this
; remark in the sourcecode as a sign of acknowledgement and respect in case
; you intend to use it for your own purposes.
;
;
; I have checked the SRC line by line and added some comment of my own. At 
; this moment it does not mean that it is without faults. I only will be 
; sure about that until I have compiled the SRC and found no differences
; with the original BIN.
;
;
; The SRC can be assembled with my own programmed assembler. This assembler
; for the PC is available as freeware, including sourcecode for Turbo Pascal.
;
;
; Sourcode of the KIM-1
;
.eq PCL = $EF           ; programcounter low
.eq PCH = $F0           ; programcounter high
.eq PREG        = $F1           ; statusregister
.eq SPUSER      = $F2           ; stackpointer

.eq ACC = $F3
.eq YREG        = $F4
.eq XREG        = $F5
.eq CHKHI       = $F6
.eq CHKSUM      = $F7

.eq INL = $F8           ; inputbuffer low
.eq INH = $F9           ; inputbuffer high
.eq POINTL      = $FA           ; addressL on display
.eq POINTH      = $FB           ; addressH on display
.eq TEMP        = $FC
.eq TMPX        = $FD
.eq CHAR        = $FE
.eq MODE        = $FF

.eq INL_A       = $00F8 ; INL as absolute address
;
.eq CHKL        = $17E7
.eq CHKH        = CHKL+1
.eq SAVX        = CHKL+2
.eq VEB = CHKL+5
.eq CNTL30      = CHKL+11
.eq CNTH30      = CHKL+12
.eq TIMH        = CHKL+13
.eq SAL = CHKL+14
.eq SAH = CHKL+15
.eq EAL = CHKL+16
.eq EAH = CHKL+17
.eq ID  = CHKL+18
.eq NMIV        = CHKL+19       ; NMI-vector
.eq RSTV        = CHKL+21       ; RESET-vector
.eq IRQV        = CHKL+23       ; IRQ-vector
;
.eq SAD = $1740
.eq PADD        = SAD+1
.eq SBD = SAD+2
.eq PBDD        = SAD+3
.eq CLK1T       = SAD+4
.eq CLK8T       = SAD+5
.eq CLK64T      = SAD+6
.eq CLKRDT      = SAD+7 ; Read time
.eq CLKKT       = SAD+7
.eq CLKRDI      = SAD+7 ; Read time out bit

;
;
.ba $1800
;
; Dump memory on tape
DUMPT   lda     #$AD    ; load absolute inst
	sta     VEB
	jsr     INTVEB
;
	lda     #$27    ; turn off datainput PB5
	sta     SBD
	lda     #$BF    ; PB7 := output
	sta     PBDD
;
	ldx     #100    ; 100 characters
DUMPT1  lda     #$16    ; sync chars
	jsr     OUTCHT
	dex
	bne     DUMPT1
;
	lda     #$2A    ; start char
	jsr     OUTCHT
;
	lda     ID      ; output ID
	jsr     OUTBT
;
	lda     SAL     ; output start address
	jsr     OUTBTC
	lda     SAH
	jsr     OUTBTC
;
DUMPT2  lda     VEB+1   ; compare for last data byte
	cmp     EAL
	lda     VEB+2
	sbc     EAH
	bcc     DUMPT4
;
	lda     #$2F    ; output EndOfData-char
	jsr     OUTCHT
	lda     CHKL    ; output checksum
	jsr     OUTBT
	lda     CHKH
	jsr     OUTBT
;
	ldx     #2      ; 2 chars
DUMPT3  lda     #4      ; EOT-char
	jsr     OUTCHT
	dex
	bne     DUMPT3
;  
	lda     #0      ; display 0000
	sta     POINTL
	sta     POINTH
	jmp     START
;
DUMPT4  jsr     VEB     ; output data byte
	jsr     OUTBTC
	jsr     INCVEB
	jmp     DUMPT2
;
; Load from tape into memory
TAB     .wo     LOAD12
LOADT   lda     #$8D    ; initialise volatile execution
	sta     VEB     ; block with sta abs
	jsr     INTVEB
;
	lda     #$4C    ; code for JMP
	sta     VEB+3
	lda     TAB
	sta     VEB+4
	lda     TAB+1
	sta     VEB+5
;
; result: jmp LOAD12 (= $190F)
;
	lda     #7      ; reset PB5
	sta     SBD
;
SYNC    lda     #$FF    ; clear SAVX for SYNC-area
	sta     SAVX
;
SYNC1   jsr     RDBIT   ; get a bit
	lsr     SAVX
	ora     SAVX
	sta     SAVX
	lda     SAVX    ; get new char
	cmp     #$16    ; SYNC-char?
	bne     SYNC1
;
	ldx     #10     ; test for 10 SYNC-char
SYNC2   jsr     RDCHT
	cmp     #$16    ; SYNC-char?
	bne     SYNC

	dex
	bne     SYNC2

LOADT4  jsr     RDCHT   ; look for start of
	cmp     #$2A    ;  start char
	beq     LOAD11  ; yes ->

	cmp     #$16    ; SYNC-char?
	bne     SYNC    ; no ->

	beq     LOADT4  ; always ->
;
LOAD11  jsr     RDBYT   ; read ID
	cmp     ID      ; requested ID?
	beq     LOADT5  ; yes ->

	lda     ID
	cmp     #0      ; ignore ID?
	beq     LOADT5  ; yes ->

	cmp     #$FF    ; ignore start address?
	beq     LOADT6  ; yes ->

	bne     LOADT   ; next program, always ->
;
LOADT5  jsr     RDBYT   ; get SA from tape
	jsr     CHKT
	sta     VEB+1
	jsr     RDBYT
	jsr     CHKT
	sta     VEB+2
	jmp     LOADT7
;
LOADT6  jsr     RDBYT   ; get SA from tape
	jsr     CHKT    ;  but ignore
	jsr     RDBYT
	jsr     CHKT
;
LOADT7  ldx     #2
LOAD13  jsr     RDCHT
	cmp     #$2F    ; last char?
	beq     LOADT5  ; yes ->

	jsr     PACKT   ; convert to hex
	bne     LOADT9  ; Y=1, non-hex char

	dex             ; 2 chars?
	bne     LOAD13  ; no -> next one

	jsr     CHKT    ; compute checksum
	jmp     VEB
;
LOAD12  jsr     INCVEB  ; increment datapointer
	jmp     LOADT7
;
LOADT8  jsr     RDBYT   ; EOD compare checksum
	cmp     CHKL
	bne     LOADT9

	jsr     RDBYT
	cmp     CHKH
	bne     LOADT9

	lda     #0
	beq     LOAD10  ; normal exit, always ->
;
LOADT9  lda     #$FF    ; error exit
LOAD10  sta     POINTL
	sta     POINTH
	jmp     START   ; display values
;
; Move start address to VEB+1,2
INTVEB  lda     SAL
	sta     VEB+1
	lda     SAH
	sta     VEB+2
	lda     #$60    ; code for RTS
	sta     VEB+3
	lda     #0
	sta     CHKL
	sta     CHKH
	rts
;
; Compute checksum for tape load
CHKT    tay
	clc
	adc     CHKL
	sta     CHKL
	lda     CHKH
	adc     #0
	sta     CHKH
	tya
	rts
;
; Output one byte
OUTBTC  jsr     CHKT
OUTBT   tay
	lsr
	lsr
	lsr
	lsr
	jsr     HEXOUT  ; output MSD
	tya
	jsr     HEXOUT  ; output LSD
	tya
	rts
;
; Convert LSD of A to ASCII
HEXOUT  and     #$0F
	cmp     #10
	clc
	bmi     HEX1

	adc     #7
HEX1    adc     #$30
;
; Output to tape 1 ASCII
OUTCHT  stx     SAVX
	sty     SAVX+1
	ldy     #8      ; startbit
CHT1    jsr     ONE
	lsr             ; get data bit
	bcs     CHT2

	jsr     ONE
	jmp     CHT3

CHT2    jsr     ZRO
CHT3    jsr     ZRO
	dey             ; all bits?
	bne     CHT1    ; no ->
	ldx     SAVX
	ldy     SAVX+1
	rts
;
; Output a 1 to tape: 9 pulses of 138 us each
ONE     ldx     #9
	pha
ONE1    bit     CLKRDI  ; wait for timeout
	bpl     ONE1

	lda     #126
	sta     CLK1T
	lda     #$A7
	sta     SBD     ; PB7 := 1
ONE2    bit     CLKRDI  ; wait for timeout
	bpl     ONE2

	lda     #126
	sta     CLK1T
	lda     #$27
	sta     SBD     ; PB7 := 0
	dex             ; all pulses?
	bne     ONE1    ; no ->

	pla
	rts
;
; Output a 0 to tape: 6 pulses of 207 us each
ZRO     ldx     #6
	pha
ZRO1    bit     CLKRDI  ; wait for timeout
	bpl     ZRO1

	lda     #195
	sta     CLK1T
	lda     #$A7
	sta     SBD     ; PB7 := 1
ZRO2    bit     CLKRDI  ; wait for timeout
	bpl     ZRO2

	lda     #195
	sta     CLK1T
	lda     #$27
	sta     SBD     ; PB7 := 0
	dex             ; all pulses?
	bne     ZRO1    ; no ->

	pla
	rts
;
; Increment VEB+1,2
INCVEB  inc     VEB+1
	bne     INCVE1

	inc     VEB+2
INCVE1  rts
;
; Read byte from tape
RDBYT   jsr     RDCHT
	jsr     PACKT
RDBYT2  jsr     RDCHT
	jsr     PACKT
	rts
;
; Pack ASCII in A as hex data
PACKT   cmp     #$30    ; ASCII ?
	bmi     PACKT3  ; no ->

	cmp     #$47
	bpl     PACKT3  ; no ->

	cmp     #$40    ; > '9' ?
	bmi     PACKT1  ; no ->

	clc
	adc     #9
PACKT1  rol
	rol
	rol
	rol
	ldy     #4
PACKT2  rol
	rol     SAVX
	dey
	bne     PACKT2

	lda     SAVX
;
; At this point Y already is 0 (= valid hex char)
	ldy     #0      ; set the zero-flag
	rts
;
; Y=0 at this point, done in label RDBIT4 
PACKT3  iny     ; Y:=1 = invalid hex char
	rts
;
; Get 1 char from tape in A
RDCHT   stx     SAVX+2
	ldx     #8      ; read 8 bits
RDCHT1  jsr     RDBIT
	lsr     SAVX+1
	ora     SAVX+1
	sta     SAVX+1
	dex
	bne     RDCHT1
;
	lda     SAVX+1
	rol
	lsr
	ldx     SAVX+2
	rts
;
; Get 1 bit from tape and return it in bit 7 of A
RDBIT   bit     SBD     ; wait for end of startbit
	bpl     RDBIT

	lda     CLKRDT  ; get start bit time
	ldy     #$FF    ; A := 256 - T1
	sty     CLK64T
;
	ldy     #$14
RDBIT3  dey             ; delay 100 us
	bne     RDBIT3

RDBIT2  bit     SBD
	bmi     RDBIT2  ; wait for next start bit
;
	sec
	sbc     CLKRDT
	ldy     #$FF    
	sty     CLK64T
;
	ldy     #7
RDBIT4  dey             ; delay 50 us
	bne     RDBIT4
;
	eor     #$FF    ; complement sign
	and     #$80    ; mask sign
	rts
;
; output 166 us pulse string for testing purposes
;  No documentation found about this. I think it is used to
;  calibrate the 565
PLLCALL lda     #$27
	sta     SBD     ; turn off datin PB5=1
	lda     #$BF
	sta     PBDD
;
PLL1    bit     CLKRDI
	bpl     PLL1

	lda     #154    ; wait 166 us
	sta     CLK1T
	lda     #$A7    ; output PB7=1
	sta     SBD
;
PLL2    bit     CLKRDI
	bpl     PLL2
	lda     #154
	sta     CLK1T
	lda     #$27    ; output PB7=0
	sta     SBD
	jmp     PLL1
;
.ba $1BFA
NMIP27  .wo     PLLCALL
RSTP27  .wo     PLLCALL
IRQP27  .wo     PLLCALL
;
;
;
; KIM-entry via NMI or IRQ
SAVE    sta     ACC
	pla
	sta     PREG
;
; KIM-entry via JSR
SAVEA   pla
	sta     PCL
	sta     POINTL
	pla
	sta     PCH
	sta     POINTH
;
SAVEB   sty     YREG
	stx     XREG
	tsx
	stx     SPUSER
	jsr     INITS
	jmp     START
;
; NMI and IRQ are called via RAM-vector. This enables the programmer
; to insert his own routines.
; Comment: is not initialised anywhere, so any accidental NMI or IRQ 
;  can lead to disaster !
NMIT    jmp     (NMIV)
IRQT    jmp     (IRQV)
;
; The KIM starts here after a reset
RESET   ldx     #$FF
	txs             ; set stack
	stx     SPUSER
	jsr     INITS
;
; Determine characters per second
DETCPS  lda     #$FF    ; count startbit
	sta     CNTH30  ; zero CNTH30
;
; Test first keyboard or teleprinter
	lda     #1      ; mask bit 0
DET1    bit     SAD     ; test for teleprinter
	bne     START   ; no ->

	bmi     DET1    ; no startbit, wait for it ->

	lda     #$FC
DET3    clc             ; this loop counts startbit time
	adc     #1      ; A=0 ?
	bcc     DET2    ; no ->

	inc     CNTH30

DET2    ldy     SAD     ; check for end of startbit
	bpl     DET3    ; no ->

	sta     CNTL30
	ldx     #8
	jsr     GET5    ; get rest of char
;
; Make TTY/KB selection
START   jsr     INIT1
	lda     #1      ; read jumper
	bit     SAD     ; TTY ?
	bne     TTYKB   ; no -> keyboard/display-routine

	jsr     CRLF    ; print return/linefeed
	ldx     #$0A
	jsr     PRTST   ; print 'KIM'
	jmp     SHOW1
;
;
CLEAR   lda     #0
	sta     INL     ; clear inputbuffer
	sta     INH
;
READ    jsr     GETCH   ; get char from TTY
	cmp     #1      ; 1 has no meaning for TTY
	beq     TTYKB   ; 1 = KB-mode ->

	jsr     PACK    
	jmp     SCAN
;
; Main routine for keyboard and display
TTYKB   jsr     SCAND   ; wait until NO key pressed
	bne     START   ; if pressed, wait again ->
TTYKB1  lda     #1      ; check KB/TTY mode
	bit     SAD     ; TTY?
	beq     START   ; yes ->

	jsr     SCAND   ; Wait for key...
	beq     TTYKB1  ; no key ->

	jsr     SCAND   ; debounce key
	beq     TTYKB1  ; no key ->
;
GETK    jsr     GETKEY
	cmp     #$15    ; >= $15 = illegal
	bpl     START   ; yes ->

	cmp     #$14
	beq     PCCMD   ; display Program Counter

	cmp     #$10
	beq     ADDRM   ; addresmode

	cmp     #$11
	beq     DATAM   ; datamode

	cmp     #$12
	beq     STEP    ; step

	cmp     #$13
	beq     GOV     ; execute program
;
; One of the hexidecimal buttons has been pushed
DATA    asl             ; move LSB key number to MSB
	asl     
	asl     
	asl     
	sta     TEMP    ; store for datamode
	ldx     #4

DATA1   ldy     MODE    ; part of address?
	bne     ADDR    ; yes ->

	lda     (POINTL),Y      ; get data
	asl     TEMP
	rol             ; MSB-TEMP = MSB-key -> A
	sta     (POINTL),Y      ; store new data
	jmp     DATA2

ADDR    asl             ; TEMP not needed here
	rol     POINTL  ; MSB-key -> POINTL
	rol     POINTH  ; POINTL -> POINTH

DATA2   dex             ; 4 times = complete nibble?
	bne     DATA1   ; no ->

	beq     DATAM2  ; -> always
;
; Switch to address mode
ADDRM   lda     #1
	bne     DATAM1  ; -> always
;
; Switch to data mode
DATAM   lda     #0
DATAM1  sta     MODE
DATAM2  jmp     START
;
; Increment address on display
STEP    jsr     INCPT
	jmp     START
;
GOV     jmp     GOEXEC
;
; Display PC by moving it to POINT
PCCMD   lda     PCL
	sta     POINTL
	lda     PCH
	sta     POINTH
	jmp     START
;
; Load papertape from TTY
LOAD    jsr     GETCH
	cmp     #$3B    ; ":", semicolon?
	bne     LOAD    ; No -> again

LOADS   lda     #0
	sta     CHKSUM
	sta     CHKHI
;
	jsr     GETBYT  ; get byte CNT
	tax
	jsr     CHK     ; Compute checksum
;
	jsr     GETBYT  ; get address HI
	sta     POINTH
	jsr     CHK     ; Compute checksum
;
	jsr     GETBYT  ; get address LO
	sta     POINTL
	jsr     CHK     ; Compute checksum
;
	txa             ; CNT = 0 ?
	beq     LOAD3
;
LOAD2   jsr     GETBYT  ; get DATA
	sta     (POINTL),y      ; store data
	jsr     CHK
	jsr     INCPT
	dex
	bne     LOAD2

	inx             ; X=1 = data record
			; X=0 = last record
;
LOAD3   jsr     GETBYT  ; compare checksum
	cmp     CHKHI
	bne     LOADE1

	jsr     GETBYT
	cmp     CHKSUM
	bne     LOADER
;
	txa             ; X=0 = last record
	bne     LOAD
;
LOAD7   ldx     #$0C    ; X-OFF KIM
LOAD8   lda     #$27
	sta     SBD     ; disable data in
	jsr     PRTST
	jmp     START
;
LOADE1  jsr     GETBYT  ; dummy
LOADER  ldx     #$11    ; X-OFF error KIM
	bne     LOAD8   ; always ->
;
; Dump to TTY from open cell address to LIMHL, LIMHH
DUMP    lda     #0
	sta     INL
	sta     INH     ; clear record count
DUMP0   lda     #0
	sta     CHKHI   ; clear checksum
	sta     CHKSUM
;
DUMP1   jsr     CRLF
	lda     #$3B    ; ":"
	jsr     OUTCH
;
; Check if POINTL/H >= EAL/H
	lda     POINTL
	cmp     EAL
; 
	lda     POINTH
	sbc     EAH
	bcc     DUMP4   ; no ->
;
	lda     #0      ; print last record
	jsr     PRTBYT  ; 0 bytes
	jsr     OPEN
	jsr     PRTPNT
;
	lda     CHKHI   ; print checksum
	jsr     PRTPNT  ;  for last record
	lda     CHKSUM
	jsr     PRTBYT
	jsr     CHK
	jmp     CLEAR
;
DUMP4   lda     #$18    ; print 24 bytes
	tax             ; save as index
	jsr     PRTBYT
	jsr     CHK
	jsr     PRTPNT
;
DUMP2   ldy     #0
	lda     (POINTL),y
	jsr     PRTBYT  ; print data
	jsr     CHK
	jsr     INCPT
	dex             ; Printed everything?
	bne     DUMP2   ; No ->
;
	lda     CHKHI
	jsr     PRTBYT  ; print checksum
	lda     CHKSUM
	jsr     PRTBYT
	inc     INL     ; increment recourd counter
	bne     DUMP3

	inc     INH
DUMP3   jmp     DUMP0
;
SPACE   jsr     OPEN    ; open new cell
SHOW    jsr     CRLF
SHOW1   jsr     PRTPNT
	jsr     OUTSP   ; print space
	ldy     #0
	lda     (POINTL),y      ; print data
	jsr     PRTBYT
	jsr     OUTSP   ; print space
	jmp     CLEAR
;
RTRN    jsr     INCPT   ; next address
	jmp     SHOW

; Start a program at displayed address. RTI is used as a comfortable
;  way to define all flags in one move.
GOEXEC  ldx     SPUSER  ; user user defined stack
	txs
	lda     POINTH  ; program runs from
	pha             ;  displayed address
	lda     POINTL
	pha
	lda     PREG    ; user defined Flag register
	pha
	ldx     XREG
	ldy     YREG
	lda     ACC
	rti             ; start program 
;
; Take care if TTY-input
SCAN    cmp     #$20    ; open new cell
	beq     SPACE

	cmp     #$7F    ; rub out, restart KIM
	beq     STV

	cmp     #$0D    ; next cell
	beq     RTRN

	cmp     #$0A    ; prev cell
	beq     FEED

	cmp     #$2E    ; "." = modify cell
	beq     MODIFY

	cmp     #$47    ; "G" = exec program
	beq     GOEXEC

	cmp     #$51    ; "Q" = dump from open cell
	beq     DUMPV   ;  to HI limit

	cmp     #$4C    ; "L" = load tape
	beq     LOADV

	jmp     READ    ; ignore illegal CHAR
;
STV     jmp     START
DUMPV   jmp     DUMP
LOADV   jmp     LOAD
;
FEED    sec
	lda     POINTL  ; decrement POINTL/H
	sbc     #1
	sta     POINTL
	bcs     FEED1

	dec     POINTH
FEED1   jmp     SHOW
;
MODIFY  ldy     #0      ; get contents of input buffer
	lda     INL     ;  INL and store in location
	sta     (POINTL),y      ;  specified by POINT
	jmp     RTRN
;
; Subroutine to print POINT = address
PRTPNT  lda     POINTH
	jsr     PRTBYT
	jsr     CHK
	lda     POINTL
	jsr     PRTBYT
	jsr     CHK
	rts
;
; Print ASCII-string from TOP+X to TOP
CRLF    ldx     #7      ; output <RETURN> and <LF>
PRTST   lda     TOP,x
	jsr     OUTCH
	dex             ; everything?
	bpl     PRTST   ; no ->

PRT1    rts
;
; Print 1 hex byte as 2 ASCII chars
PRTBYT  sta     TEMP    ; save A
	lsr             ; shift A 4 times
	lsr
	lsr
	lsr
	jsr     HEXTA   ; convert bit 4..7 to HEX and print
	lda     TEMP
	jsr     HEXTA   ; convert bit 0..7 to HEX and print
	lda     TEMP    ; restore A
	rts
;
HEXTA   and     #$0F    ; mask bit 0..4
	cmp     #$0A    ; > 10 ?
	clc
	bmi     HEXTA1  ; no ->

	adc     #7      ; A..F
HEXTA1  adc     #$30    ; convert to ASCII-char...
	jmp     OUTCH   ;  ...and print it
;
; Get char from TTY in A
GETCH   stx     TMPX
	ldx     #8      ; count 8 bits
	lda     #1
GET1    bit     SAD     ; check if TTY-mode
	bne     GET6    ; no ->

; PA7 is input TTY
	bmi     GET1    ; wait for startbit

	jsr     DELAY   ; delay 1       bit
;
; By delaying another half bit time, you read the bit in the middle
; of every bit.
GET5    jsr     DEHALF  ; delay 1/2 bit time 
GET2    lda     SAD
	and     #$80    ; mask bit 7
	lsr     CHAR    ; shift last result
	ora     CHAR    ; OR it with new bit
	sta     CHAR    ; and store it again
	jsr     DELAY
	dex
	bne     GET2    ; next bit

	jsr     DEHALF  ; why ????
;
	ldx     TMPX
	lda     CHAR
	rol     ; shift off stopbit
	lsr
GET6    rts
;
; Initialization 6530   $1E88
INITS   ldx     #1      ; set display to address mode
	stx     MODE
;
INIT1   ldX     #0
	stx     PADD    ; PA0..PA7 = input
	ldX     #$3F
	stx     PBDD    ; PB0..PB5 = output
			; PB6, PB7 = input
	ldx     #7      ; enable 74145 output 3 to
	stx     SBD     ;  check KB/TTY-mode
	cld
	sei
	rts
;
; Output char in A to TTY       $1E9E
OUTSP   lda     #" "    ; print space
OUTCH   sta     CHAR
	stx     TMPX
	jsr     DELAY
	lda     SBD
	and     #$FE    ; send startbit
	sta     SBD     ; PB0 = 0 -> TTY := (H)
	jsr     DELAY
;
	ldx     #8      ; send character
OUT1    lda     SBD
	and     #$FE    ; clear bit 0
	lsr     CHAR    ; shift byte 
	adc     #0      ; add Carry = former bit 0
	sta     SBD     ; output bit
	jsr     DELAY
	dex             ; all bits?
	bne     OUT1    ; no ->

	lda     SBD
	ora     #1
	sta     SBD     ; stop bit
	jsr     DELAY
	ldx     TMPX
	rts
;
; Delay 1 bit time as determined by DETCPS
DELAY   lda     CNTH30
	sta     TIMH
	lda     CNTL30
DE2     sec
DE4     sbc     #1
	bcs     DE3     ; A<>$FF ->

	dec     TIMH
DE3     ldy     TIMH    ; TIMH > 0 ?
	bpl     DE2     ; yes ->

	rts
;
; Delay half a bit time
DEHALF  lda     CNTH30
	sta     TIMH
	lda     CNTL30
	lsr
	lsr     TIMH
	bcc     DE2

	ora     #$80
	bcs     DE4     ; always ->
; Why not:
;  lsr  TIMH
;  ror
;  jmp  DE2
; ????
;
;
; Determine if key is depressed: NO -> A=0, YES -> A>0
AK      ldy     #3      ; 3 rows
	ldX     #1      ; select 74145 output 0

ONEKEY  lda     #$FF    ; initial value
;
AKA     stx     SBD     ; enable output = select row
	inx
	inx             ; prepare for next row
	and     SAD     ; A := A && (PA0..PA7)
	dey             ; all rows?
	bne     AKA     ; no ->

	ldy     #7
	sty     SBD     ; select 74145 output 3 (not used)
;
	ora     #$80    ; mask bit 7 of A
	eor     #$FF    ; if A still is $FF -> A := 0
	rts
;
; Output to 7-segment-display
SCAND   ldy     #0      ; POINTL/POINTH = address on display
	lda     (POINTL),Y      ; get data from this address
	sta     INH     ; store in INH = 
SCANDS  lda     #$7F    ; PA0..PA6 := output
	sta     PADD

	ldX     #9      ; Start with display at output 4
	ldy     #3      ; 3 bytes to be shown
;
SCAND1  lda     INL_A,y ; get byte
	lsr             ; get MSD by shifting A
	lsr
	lsr
	lsr
	jsr     CONVD
	lda     INL_A,y ; get byte again
	and     #$0F    ; get LSD
	jsr     CONVD
	dey             ; all ?
	bne     SCAND1  ; no ->

	sty     SBD     ; all digits off
	lda     #0
	sta     PADD    ; PA0..PA7 := input
	jmp     AK
;
; Convert digit into 7-segment-value
CONVD   sty     TEMP
	tay
	lda     TABLE,Y
	ldy     #0
	sty     SAD     ; turn off segments
	stx     SBD     ; select 7-s-display
	sta     SAD     ; output code on display

	ldy     #$7F    ; delay ~500 cycles
CONVD1  dey
	bne     CONVD1

	inx             ; next display
	inx
	ldy     TEMP
	rts
;
; Increment POINT = address on display
INCPT   inc     POINTL
	bne     INCPT2

	inc     POINTH
INCPT2  rts
;
; Get key from keyboard in A
GETKEY  ldx     #$21    ; row 0 / disable input TTY
GETKE5  ldy     #1      ; only one row in the time
	jsr     ONEKEY  ; key?
	bne     KEYIN   ; yes ->

	cpx     #$27    ; last row?
	bne     GETKE5  ; no, next one ->

	lda     #$15    ; 15 = no key
	rts
;
KEYIN   ldy     #$FF    ; Y := key number
KEYIN1  asl             ; shift A until
	bcs     KEYIN2  ;  bit = 1 ->
;
; Comment: bit 7 is always 0 so Carry is always 0 the first time
;  and allowing Y to become 0 (key $FF does not exist)
	iny     
	bpl     KEYIN1  ; always ->

KEYIN2  txa
	and     #$0F    ; strip bit4..7
	lsr             ; A := row+1
	tax             ; X := actual row+1
	tya
	bpl     KEYIN4  ; always, because Y<7 -> 

;
; Add 7 to A for every row above 0 to get actual key number
KEYIN3  clc
	adc     #7      ; add (X-1) times 7 to A
KEYIN4  dex             ; countdown to 0
	bne     KEYIN3  

	rts             ; A is always < 21 eg. < $15
;
; Compute checksum
CHK     clc
	adc     CHKSUM
	sta     CHKSUM
	lda     CHKHI
	adc     #0
	sta     CHKHI
	rts
;
; Get 2 hex-chars and pack into INL and INH
;  Non hex char will be loaded as nearsest hex equivalent
GETBYT  jsr     GETCH
	jsr     PACK
	lsr     GETCH
	jsr     PACK
	lda     INL
	rts
;
; Shift char in A into INL and INH
PACK    cmp     #$30    ; is hex?
	bmi     UPDAT2  ; < = no        ->

	cmp     #$47
	bpl     UPDAT2  ; > = no ->

HEXNUM  cmp     #$40    ; A..F ?
	bmi     UPDATE  ; no ->

HEXALP  clc
	adc     #9
UPDATE  rol     ; shift to bit 4..7
	rol
	rol
	rol
	ldy     #4      ; shift into INL/INH
UPDAT1  rol
	rol     INL
	rol     INH
	dey     ; 4 times?
	bne     UPDAT1  ; no ->

	lda     #0      ; if hex number -> A := 0
UPDAT2  rts
;
OPEN    lda     INL     ; move I/O-buffer to POINT
	sta     POINTL
	lda     INH
	sta     POINTH
	rts
;
; Tabels
TOP     .by     0, 0, 0, 0, 0, 0, 10, 13
	.tx     "MIK"
	.by     " ", $13
	.tx     "RRE "
	.by     $13

; Hex -> 7-segment      0    1    2    3    4    5    6    7
TABLE   .by     $BF, $86, $DB, $CF, $E6, $ED, $FD, $87
;               8    9    A    B    C    D    E    F
	.by     $FF, $EF, $F7, $FC, $B9, $DE, $F9, $F1
;
; Comment: if everything is compiled right, next vectors should
;  start at $FFFA
NMIENT  .wo     NMIT
RSTENT  .wo     RESET
IRQENT  .wo     IRQT
.en
