;******** LOAD & SAVE PATCH FOR ENHANCED BASIC ON 65C02 Simulator
;  2005/09/04	RAC	Synched with SBCOS 5/30/05 release

psave		
		jsr	pscan
		ldy	#$00
		lda	itempl
		sta	(itempl),y
		iny
		lda	itemph
		sta	(itempl),y
		ldx	smeml
		lda	smemh
		jsr	print2byte
		jsr	print_cr
		sec
		lda	itempl
		sbc	smeml
		tax
		lda	itemph
		sbc	smemh
		jsr	print2byte
		jsr	print_cr
		rts

pload		
		jsr	pscan
		lda	itempl
		sta	svarl
		sta	sarryl
		sta	earryl
		lda	itemph
		sta	svarh
		sta	sarryh
		sta	earryh
		JMP   LAB_1319		
pscan
		lda	smeml
      	sta	itempl
      	lda	smemh
      	sta	itemph
pscan1	ldy   #$00
		lda   (itempl),y
		bne   pscan2
		iny   
		lda   (itempl),y
		bne   pscan2
		clc
		lda   #$02
		adc   itempl
		sta	itempl
		lda	#$00
		adc	itemph
		sta	itemph
		rts
pscan2	ldy   #$00
		lda	(itempl),y
		tax
		iny
		lda	(itempl),y
		sta	itemph
		stx	itempl
		bra	pscan1
