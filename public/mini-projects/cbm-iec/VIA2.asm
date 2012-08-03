;*********************************************************************
;  2005/09/04	RAC	Synched with SBCOS 5/30/05 release
; ----------------- assembly instructions ---------------------------- 
;
; this is a subroutine library only
; it must be included in an executable source file
;
;
;*** I/O Locations *******************************
; define the i/o address of the Via2 chip
;*** 6522 CIA ************************
Via2Base       =     $7f60
Via2PRB        =     $7f60
Via2PRA        =     $7f61
Via2DDRB       =     $7f62
Via2DDRA       =     $7f63
Via2T1CL       =     $7f64
Via2T1CH       =     $7f65
Via2T1LL       =     $7f66
Via2TALH       =     $7f67
Via2T2CL       =     $7f68
Via2T2CH       =     $7f69
Via2SR         =     $7f6a
Via2ACR        =     $7f6b
Via2PCR        =     $7f6c
Via2IFR        =     $7f6d
Via2IER        =     $7f6e
Via2PRA1       =     $7f6f
;
;***********************************************************************
; 6522 VIA I/O Support Routines
;
Via2_init      ldx   #$00              ; get data from table
Via2init1      lda   Via2idata,x       ; init all 16 regs from 00 to 0F
               sta   Via2Base,x        ; 
               inx                     ; 
               cpx   #$0f              ; 
               bne   Via2init1         ;       
               rts                     ; done
;
Via2idata      .byte $00               ; prb  '00000000'
               .byte $00               ; pra  "00000000'
               .byte $00               ; ddrb 'iiiiiiii'
               .byte $00               ; ddra 'iiiiiiii'
               .byte $00               ; tacl  
               .byte $00               ; tach  
               .byte $00               ; tall  
               .byte $00               ; talh  
               .byte $00               ; t2cl
               .byte $00               ; t2ch
               .byte $00               ; sr
               .byte $00               ; acr
               .byte $00               ; pcr
               .byte $7f               ; ifr
               .byte $7f               ; ier
; 
;
;
;end of file
