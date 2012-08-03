;*********************************************************************
;  2005/09/04	RAC	Synched with SBCOS 5/30/05 release
; ----------------- assembly instructions ---------------------------- 
;
; this is a subroutine library only
; it must be included in an executable source file
;
;
;*** I/O Locations *******************************
; define the i/o address of the ACIA1 chip
;*** 6551 CIA ************************
ACIA1dat       =     $7f70
ACIA1sta       =     $7f71
ACIA1cmd       =     $7f72
ACIA1ctl       =     $7f73
;
;***********************************************************************
; 6551 I/O Support Routines
;
ACIA1_init     LDX   #<ACIA1_Input      ; set up RAM vectors for
               LDA   #>ACIA1_Input      ; Input, Output, and Scan
               TAY                     	; Routines
               EOR   #$A5              	;
               sta   ChrInVect+2       	;
               sty   ChrInVect+1       	;
               stx   ChrInVect         	;
               LDX   #<ACIA1_Scan  	;
               LDA   #>ACIA1_Scan       ;
               TAY                     	;
               EOR   #$A5              	;
               sta   ScanInVect+2      	;
               sty   ScanInVect+1      	;
               stx   ScanInVect        	;
               LDX   #<ACIA1_Output     ;
               LDA   #>ACIA1_Output     ;
               TAY                     	;
               EOR   #$A5              	;
               sta   ChrOutVect+2      	;
               sty   ChrOutVect+1      	;
               stx   ChrOutVect        	;
               lda   #<ACIA1_scan      	; setup BASIC vectors
               sta   VEC_IN
	       lda   #>ACIA1_scan	; BASIC's chr input
               sta   VEC_IN+1
               lda   #<ACIA1_Output	
               sta   VEC_OUT
	       lda   #>ACIA1_Output	; BASIC's chr output 
               sta   VEC_OUT+1
	       lda   #<Psave
               sta   VEC_SV
	       lda   #>Psave		; SAVE cmd
               sta   VEC_SV+1
	       lda   #<pload
               sta   VEC_LD
	       lda   #>pload		; LOAD cmd
               sta   VEC_LD+1

ACIA1portset   lda   #$1F               ; 19.2K/8/1
               sta   ACIA1ctl           ; control reg 
               lda   #$0B               ; N parity/echo off/rx int off/ dtr active low
               sta   ACIA1cmd           ; command reg 
               rts                      ; done
;
; input chr from ACIA1 (waiting)
;
ACIA1_Input
               lda   ACIA1Sta           ; Serial port status             
               and   #$08               ; is recvr full
               beq   ACIA1_Input        ; no char to get
               Lda   ACIA1dat           ; get chr
               RTS                      ;
;
; non-waiting get character routine 
;
ACIA1_Scan     clc
               lda   ACIA1Sta           ; Serial port status
               and   #$08               ; mask rcvr full bit
               beq   ACIA1_scan2
               Lda   ACIA1dat           ; get chr
	         sec
ACIA1_scan2    rts
;
; output to OutPut Port
;
ACIA1_Output   PHA                      ; save registers
ACIA1_Out1     lda   ACIA1Sta           ; serial port status
               and   #$10               ; is tx buffer empty
               beq   ACIA1_Out1         ; no
               PLA                      ; get chr
               sta   ACIA1dat           ; put character to Port
               RTS                      ; done
;
;end of file
