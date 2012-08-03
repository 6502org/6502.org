;*********************************************************************
;  2005/09/04	RAC	Synched with SBCOS 5/30/05 release
; ----------------- assembly instructions ---------------------------- 
;
;****************************************************************************
; Reset, Interrupt, & Break Handlers
;****************************************************************************
;               *= $FF00             ; put this in last page of ROM

;--------------Reset handler----------------------------------------------
Reset          SEI                     ; diable interupts
               CLD                     ; clear decimal mode                      
               LDX   #$FF              ;
               TXS                     ; init stack pointer
;
; you can patch in a test for keypress here to bypass memory erase.
; It will then test the vectors, and jump to your routine.
;
Zeromem        lda   #$7F              ; top page of RAM
               sta   $01               ; 
               lda   #$00              ; top of page & fill chr
               sta   $00               ;
Zeromem1       sta   ($00)             ; loop will fill loc 0 of each page then 
               dec   $00               ; fill from ff->01 of that page
               bne   zeromem1          ; then will drop one page and fill loc 0
               dec   $01               ; doing that until page is back to FF
               bpl   Zeromem1          ;
               sta   $01               ; fix last byte from ff to 00
Set_Vectors    lda   RESvector+1       ; reset vector 
               EOR   #$A5              ; on reset, perform code @ label reset
               CMP   RESvector+2       ; if checksm ok, then jmp ind to address
               beq   nextvec1          ; else set up to jmp to monitor
               LDX   #<Start_OS        ; *** only outside reference in reset routine
               LDA   #>Start_OS        ; *** points to Monitor Boot routine
               TAY                     ;
               EOR   #$A5              ;
               sta   RESvector+2       ;
               sty   RESvector+1       ;
               stx   RESvector         ;
Nextvec1       lda   NMIvector+1       ; set up NMI vectors if checksum invalid
               EOR   #$A5              ;  
               CMP   NMIvector+2       ;
               beq   nextvec2          ;
               LDX   #<INTret          ; set up to point to RTI command 
               LDA   #>INTret          ; (no system NMI applications)
               TAY                     ;
               EOR   #$A5              ;
               sta   NMIvector+2       ;
               sty   NMIvector+1       ;
               stx   NMIvector         ;
Nextvec2       lda   INTvector+1       ;
               EOR   #$A5              ;
               CMP   INTvector+2       ;
               beq   Nextvec3          ;
               LDX   #<INTret          ; set up to point to RTI command 
               LDA   #>INTret          ; (no system INT applications)
               TAY                     ;
               EOR   #$A5              ;
               sta   INTvector+2       ;
               sty   INTvector+1       ;
               stx   INTvector         ;
Nextvec3       lda   BRKvector+1       ;
               EOR   #$A5              ;
               CMP   BRKvector+2       ;
               beq   Nextvec4          ;
               LDX   #<BRKroutine      ; set up to point to my BRK routine
               LDA   #>BRKroutine      ; 
               TAY                     ;
               EOR   #$A5              ;
               sta   BRKvector+2       ;
               sty   BRKvector+1       ;
               stx   BRKvector         ;
Nextvec4       lda   #<ACIA1_Scan
               sta   VEC_IN
		   lda   #>ACIA1_Scan
               sta   VEC_IN+1
	         lda   #<ACIA1_Output
               sta   VEC_OUT
		   lda   #>ACIA1_OUTPUT
               sta   VEC_OUT+1
	         lda   #<Psave
               sta   VEC_SV
	         lda   #>Psave
               sta   VEC_SV+1
		   lda   #<pload
               sta   VEC_LD
		   lda   #>pload
               sta   VEC_LD+1
;
; select the IO device driver here       
;
		   jsr   VIA1_init	   ; init the I/O devices
		   jsr   VIA2_init	   ; init the I/O devices
		   jsr   ACIA1_init	   ; init the I/O devices

Clr_regs       lda   #$00              ; Clear registers
               TAY                     ;
               TAX                     ;
               CLC                     ; clear flags
               CLD                     ; clear decimal mode
               CLI                     ; Enable interrupt system
               JMP  (RESvector)        ; Monitor for cold reset                       
;
NMIjump        jmp  (NMIvector)        ;
INTret         RTI                     ; Null Interrupt return
Interrupt      PHX                     ;
               PHA                     ;
               TSX                     ; get stack pointer
               LDA   $0103,X           ; load INT-P Reg off stack
               AND   #$10              ; mask BRK
               BNE   BrkCmd            ; BRK CMD
               PLA                     ;
               PLX                     ;
               jmp   (INTvector)       ; let user routine have it 
BrkCmd         pla                     ;
               plx                     ;
               jmp   (BRKvector)       ; patch in user BRK routine
RRTS           rts                     ; documented RTS instruction
;
;
;
; *** VERSION Notes ***
; 3.5 added the text dump command, 'q'
; 4.0 reorganized structure, added RAM vectors for chrin, scan_in, and chrout
; 4.1 fixed set time routine so 20-23 is correct    
; 4.2 RST, IRQ, NMI, BRK all jmp ind to 02xx page to allow user prog to control
; 4.3 added status register bits to printreg routine
; 4.4 refined set time to reduce unneeded sec's and branches, disp time added CR,
;     and added zeromem to the reset routine, ensuring a reset starts fresh every time!
;     continued to re-organize - moved monitor's brk handler into mon area.

;  65C02 Firmware Notes
;
;  NMIjmp      =     $FFFA             
;  RESjmp      =     $FFFC             
;  INTjmp      =     $FFFE             

               *=    $FFFA
               .word  NMIjump
               .word  Reset 
               .word  Interrupt
;end of file
