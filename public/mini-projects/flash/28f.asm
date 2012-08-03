	; Flash a single byte, using the data in FDA, and the addr in 
	; FRADLO/HI. FCNT will contain how many more times we would 
	; have tried it. If it fails, FFDA contains the data that was 
	; read back. Nothing is preserved.
FLASHB:
	LDY #$19        ; Max of 25 retries
	LDX #$0         ; init X
FLOOP:  
	LDA #$40        ; send Program Byte command
	STA (TOADLO,X)
	LDA FDA         ; send the data to be programmed
	STA (TOADLO,X)
	; The next 4 instructions are a time delay: a total of
	; around 10us with a 1.8 MHz clock. The exact amount isn't
	; critical, but should be *at least* 10us.
	ROR 0
	ROL 0
	NOP
	NOP
	; The next 2 instructions count as part of the delay:
	LDA #$C0         ; send the Verify command
	STA (TOADLO,X)
	LDA (TOADLO,X)   ; read the programmed byte
	CMP FDA          ; is it the same?
	BEQ FDONE        ; yes, we're done
	DEY              ; no, try again
	BNE FLOOP
FDONE:  
	STY FCNT         ; save the number of loops
	STA FFDA         ; save the last data we read
	LDA #$0          ; send the Read Mode command
	STA (TOADLO,X)
	RTS

	; Erase the flash. The flash is 128K, but all we
	; can address is 32K, so just erase that (really the
	; entire device is being erased, but we are only verifying
	; the first 32K). Nothing is preserved.
ERASE:
	LDX #$00
	LDA #$00        ; Init our temp storage
	STA FDA         ; We will program all bytes to #$00 first.
	STA TOADLO      ; Flash starts at address $6000.
	LDA #$60
	STA TOADHI
ERASE1:
	JSR FLASHB      ; Program a byte
	INC TOADLO      ; INC to next address
	BNE ERASE1      ; No wrap - go do next address
	INC TOADHI      ; Wrapped - INC hi byte
	LDA #$E0        ; Did we go beyond 32K ?
	CMP TOADHI
	BNE ERASE1      ; No, go do this address
	LDA #$0         ; Yes, get ready to erase
	STA TOADLO
	STA ECNTLO      ; erase-cycle counter
	STA ECNTHI
	LDA #$60        ; back to the beginning
	STA TOADHI
ERASE2:
	LDA #$20        ; send the Erase command
	STA (TOADLO,X)
	STA (TOADLO,X)  ; we must send it twice
	LDA #$3         ; Delay for about 12 ms (10 ms required)
	JSR DELAY       ; 
ERASE3:
	LDA #$A0        ; send the Erase Verify command
	STA (TOADLO,X)
	LDA (TOADLO,X)  ; is the data #$FF ?
	CMP #$FF
	BNE ERASE4      ; no, go INC counters and try again
	INC TOADLO      ; yes, INC the address counter
	BNE ERASE3
	INC TOADHI
	LDA TOADHI
	CMP #$E0        ; are we beyond 32K ?
	BNE ERASE3      ; no, do another erase cycle
EDONE:  
	LDA #$0         ; we're done - send the Read Mode command
	STA (TOADLO,X)
	RTS
ERASE4:
	INC ECNTLO      ; INC the erase-retry counter
	BNE ERASE2
	INC ECNTHI
	LDA ECNTHI
	CMP #$4         ; have we done more than 1000 cycles?
	BEQ EDONE       ; yes - quit (failure)
	BNE ERASE2      ; no - do another erase cycle

