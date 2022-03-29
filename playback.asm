/*
 * playback.asm
 *
 *  Created: 05/05/2019 19:39:30
 *   Author: mwbis
 */ 

.ifndef PLAYBACK
.equ PLAYBACK = 1

; === inclusions ===
.include "sound_driver.asm"

; === definitions ===

; === macros ===
.macro MUL1_3		; multiply a1 by 3
	push	a0
	mov		a0, @0
	lsl		a0
	add		@0, a0
	pop		a0
	.endm

; === save-slot subroutines === 
memory_init:	
	; brief:	clears the user memory slots			
	; arg:		void
	; ret:		void 
	STI2	current_slot_addr, save_slot1
	rcall	clear_slot
	STI2	current_slot_addr, save_slot2
	rcall	clear_slot
	STI2	current_slot_addr, save_slot3
	rcall	clear_slot
	ret

clear_slot:
	; brief:	clears the current memory slot			
	; arg:		current_slot_addr
	; ret:		void 
	clr		a0
	LDIX	current_slot_addr
	LDX2	yh, yl
	st		-y, a0
	INC2	yh, yl
	ldi		w, tone_size*slot_size
	clear_slot_loop:			; fill the whole slot with 0's
		st		y+, a0
		subi	w, 1
		brne	clear_slot_loop
	ret

check_memory:
	PUSH4	a3, a2, a1, a0
	LDIX	current_slot_addr
	LDX2	yh, yl
	set
	ldi		a3, slot_size
	check_memory_loop:
		LDY3	a2, a1, a0
		TST3	a2, a1, a0 
		breq	PC+2
			clt
		subi	a3, 1
		brne	check_memory_loop
	POP4	a3, a2, a1, a0
	ret

start_recording:				; arg: a0 (save slot) 
	push w
	PUSH3	a1, a2, a3				; save registers
	tst a0							; switch case 
	brne	start_recording_1
		STI2	current_slot_addr, save_slot0
	start_recording_1:
	cpi a0, 1
	brne	start_recording_2
		STI2	current_slot_addr, save_slot1
	start_recording_2:
	cpi a0, 2
	brne	start_recording_3
		STI2	current_slot_addr, save_slot2
	start_recording_3:
	cpi a0, 3
	brne	start_recording_4
		STI2	current_slot_addr, save_slot3
	start_recording_4:
	rcall clear_slot				; clear slot for new use
	POP3	a1, a2, a3				; restore registers 
	pop w
	ret

end_recording:					; arg: void
	PUSH3	a1, a2, a3				; save registers
	LDIX	current_slot_addr			
	LDX2	yh, yl
	ADDI2	yh, yl, -1
	ld		a1, y					; check loop around flag in startX:
	tst		a1
	breq	end_recording_end		; if never looped, first tone is starting tone
		LDIX	current_save_tone		; if looped, next tone is starting tone
		ld		a1, X
		inc		a1
		cpi		a1, slot_size
		brlo	PC+2					; make sure save slot loops around
			clr a1
		st		y, a1					; store this as first tone 
	end_recording_end: 
	POP3	a1, a2, a3				; restore registers 
	ret

; === playback subroutines === 
play_RAM_song:
	STI		current_play_tone, 0
	STI2	current_play_dura, 0

	set
	play_RAM_song_loop:
	sbic BUTTON, 0			; back_button
	rjmp	PC+5
		rcall	stop_tone
		rcall	matrix_reset
		clr		a0
		ret
	brtc	play_RAM_song_loop
		rcall	load_tone
		push	a0
		rcall	new_tone
		pop		a0
		rcall	matrix_main
		rjmp play_RAM_song_loop

play_ProgM_song:
	STI		current_play_tone, 0
	STI2	current_play_dura, 1
	set
	clr		a0
	play_ProgM_song_loop:
	sbic BUTTON, 0			; back_button
	rjmp	PC+5
		rcall	stop_tone
		rcall	matrix_reset
		clr		a0
		ret
	brtc	play_ProgM_song_loop
		clr4	a3, a2, a1, a0
		rcall	load_freq
		rcall	new_tone_save_data
		rcall	matrix_main
		rjmp play_ProgM_song_loop


; === tone subroutines === 
save_tone:						; arg: a0 (tone code)
	PUSH3	a1, a2, a3				; save registers
	LDIX	current_slot_addr		; load previous tone from memory
	LDX2	a3, a2
	LDIY	current_save_tone
	ld		a1, y
	MUL1_3	a1
	add a2, a1
	brcc	PC+2
		inc		a3
	MOV2	yh, yl, a3, a2			; y is now previous tone pointer
	ld		a1, y					; a1 is previous tone
	cp      a0, a1					; compare previous and current tones
	brne	save_tone_new_tone			; case same: simply increase duration
		INC2	yh, yl
		LDY2	a3, a2
		ADDI2	yh, yl,	-3
		INC2	a3, a2						
		brcs	save_tone_end			; test for overflow: C=1 -> make a new tone 
	save_tone_new_tone:				; case different: make new tone
		ADDI2	yh, yl,	3
		LDIX	current_save_tone
		ld		a1, x
		inc		a1						; a1 is previous save_tone
		st		x, a1
		cpi		a1, slot_size
		brlo	save_tone_dont_loop	; make sure save slot loops around
			LDIX	current_slot_addr		
			LDX2	yh, yl				; y is now new tone pointer 
			ldi		w, 1					
			st		-y, w				; set loop flag in startX:
			INC2	yh, yl
			STI		current_save_tone, 0
		save_tone_dont_loop:
		st	y, a0						; store new tone, y is now new duration pointer
		clr a3
		ldi a2, 0x01					; set new period (= 1)				
	save_tone_end:
	INC2	yh, yl 
	STY2	a3, a2					; store period 
	POP3 a1, a2, a3					; restore registers
	ret

load_tone:						; arg: (void), ret: a0, tone
	PUSH3	a1, a2, a3				; save registers
	LDIY	current_play_dura
	LDY2	a3, a2					; load current duration
	ADDI2	yh, yl,	-2
	TST2	a3, a2
	breq	load_tone_next_tone		; check if (duration == 0) 	; case yes: go to next tone
		DEC2	a3, a2					; case no: update duration 
		STY2	a3, a2					; 
		LDIX	current_slot_addr		; load previous tone from memory
		LDX2	a3, a2						
		LDIY	current_play_tone
		ld		a1, y
		MUL1_3	a1
		add a2, a1
		brcc	PC+2
			inc		a3
		MOV2	yh, yl, a3, a2			; y is now current tone pointer
		ld		a0, y					; a0 is current tone
		POP3	a1, a2, a3				; restore registers 
		ret
	load_tone_next_tone:
		LDIX	current_slot_addr		; load previous tone from memory
		LDX2	a3, a2						
		LDIY	current_play_tone
		ld		a1, y
		inc		a1						; increment to next tone
		st		y, a1						
		cpi		a1, slot_size
		brsh	load_tone_make_loop		; make sure save slot loops around
			MUL1_3	a1
			add a2, a1
			brcc	PC+2
				inc		a3
			rjmp load_tone_end
		load_tone_make_loop:
			STI	current_play_tone, 0
		load_tone_end:
		MOV2	yh, yl, a3, a2			; y is now next tone pointer
		ld		a0, y+					; a0 is current tone
		LDY2	a3, a2					
		TST2	a3, a2
		breq	load_tone_next_tone		; make sure new tone isn't null-tone
			DEC2	a3, a2
			LDIY	current_play_dura
			STY2	a3, a2					; save current duration
			POP3	a1, a2, a3				; restore registers 
			ret

load_freq:
	LDIY	current_play_dura
	LDY2	a3, a2					; load current duration
	ADDI2	yh, yl,	-2
	TST2	a3, a2
	breq	load_freq_next_tone		; check if (duration == 0) 	; case yes: go to next tone
		DEC2	a3, a2					; case no: update duration 
		STY2	a3, a2					; 
		LDIX	current_slot_addr		; load current tone from memory
		LDX2	a3, a2
		INC2	a3, a2		
		LDIY	current_play_tone
		clr		a1
		ld		a0, y
		LSL2	a1, a0					; multiply by 2 (tone data is 2 words wide)
		ADD2	a3, a2, a1, a0
		MOV2	zh, zl, a3, a2			; z is now current tone pointer
		MUL2Z
		LPM2	a1, a0					; a1:a0 is current tone frequency
		LPM2	a3, a2					; a3:a2 is current tone duration
		ret
	load_freq_next_tone:
		LDIX	current_slot_addr		; load previous tone from memory
		LDX2	zh, zl	
		MUL2Z
		LPM2	xh, xl					; extract end of song pointer
		ADDI2	xh, xl, -2
		DIV2Z					
		LDIY	current_play_tone
		clr		a1
		ld		a0, y
		inc		a0
		st		y, a0
		LSL2	a1, a0					; multiply by 2 
		ADD2	zh, zl, a1, a0
		CP2	zh, zl, xh, xl			; compare with end of song pointer
		brlo	load_freq_end			; make sure song loops around
			STI	current_play_tone, 0
	load_freq_end:
	MUL2Z
	LPM2	a1, a0					; a1:a0 is current tone frequency
	LPM2	a3, a2					; a3:a2 is current tone duration
	TST2	a3, a2
	breq	load_freq_next_tone		; make sure new tone isn't null-tone
		DEC2	a3, a2
		;LDIY	current_play_dura
		;STY2	a3, a2					; save current duration 
		STI2 current_play_dura, 1
		ret

; === debug functions ===
fill_memory_slot1: 
	LDIY	save_slot1
	ldi		a0, 1
	LDI2	a2, a1, 5
	ldi		w, 8
	fill_memory_loop:
		st		y+, a0
		lsl		a0
		STY2	a2, a1
		subi	w, 1
		brne	fill_memory_loop
	ret

.endif
