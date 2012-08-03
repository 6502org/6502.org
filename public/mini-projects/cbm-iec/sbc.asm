;*********************************************************************
;  2005/09/04	RAC	Synched with SBCOS 5/30/05 release
;  2003/09/05	RAC	Reordered system code to enable user to remove
;			EhBASIC easily and to minimize memory holes
;			to maximize user ROM space.
; Assumed Memory Map
; 0000-7EFF - RAM (32K minus 256 bytes of I/O) 
; 7F00-7F4F - Five unused decoded I/O Blocks (16 bytes each) 
; 7F50-7F5F - VIA1 (16 bytes) 
; 7F60-7F6F - VIA2 (16 bytes) 
; 7F70-7F7F - 65C51 (16 bytes) 
; 7F80-7FFF - undecoded I/O blocks (128 bytes) 
; 8000-FFFF - EPROM (32K) 
;  8000-AFFF -- unused (12.3k)			 } 
;  B000-D8FF -- EhBASIC (10.5k)  		 } 22.8k contiguous space
;  D900-E5FF -- CBM IEC drivers and DOS (3.25k)  } 26.1k contiguous space
;  E600-FFFF -- System BIOS, monitor and assembler (6.5k)
;
; Assumed RAM Map
; Page 0 Z-page
; Page 1 Processor Stack
; Page 2 Free above $026f
; Page 3 Reserved for system monitor and related buffers
; Page 4 Start of free RAM
;
; Compile with TASS: tass /c sbc.asm sbc.bin sbc.lst
;

	*= $8002			; create exact 32k bin image
	.byte "A0",$C3,$C2,$CD		; ROM signature

; "User-mode" programs
;	.include testcode.asm		; $8010  start of test code

; System code
	*=$B000	
;	.include source.asm       	; $b000  Enhanced BASIC
	.include basic209.asm		; $b000  EhBASIC
	.include basldsv.asm	   	; $d77e  EhBASIC load & save support for sim
;					; $d7ec - d8ff free (113/275 bytes)

	*=$D900
	.include cbm_iec.asm		; $D900  Serial IEC routines and DOS
;					; $E53c - E5FF free (c3/195 bytes)
	*=$E600
	.include VIA1.asm		; $E600  VIA1 init
	.include VIA2.asm		; $E62D  VIA2 init
	.include ACIA1.asm	  	; $E64A  ACIA init (19200,n,8,1)
;					; $E6D2 - E6FF free (2e/46 bytes)
	*=$E700
	.include sbcos.asm        	; $E700  OS
;					; $F980 - F9FF (80/128 bytes)
	*=$FA00
	.include upload.asm        	; $FA00  Intel Hex & Xmodem-CRC uploader
;					; $FEFE - FEFF (2 bytes)
	*=$FF00
	.include reset.asm        	; $FF00  Reset & IRQ handler


