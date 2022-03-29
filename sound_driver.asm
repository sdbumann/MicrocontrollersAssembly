/*
 * sound_driver.asm
 *
 *  Created: 05/05/2019 13:52:31
 *   Author: mwbis
 */ 

; ======================== test program ================================

.ifndef SOUND_DRIV
.equ SOUND_DRIV = 1

; === inclusions ===
.include "macros.asm"			; include macro definitions
.include "definitions.asm"
.include "memory_allocation.asm"

; === definitions ===
.set no_button   = 0b00000000
.set back_button = 0b00000001
.set c_button    = 0b00000010
.set d_button    = 0b00000100
.set e_button    = 0b00001000
.set f_button    = 0b00010000
.set g_button    = 0b00100000
.set a_button    = 0b01000000
.set h_button    = 0b10000000

; === macros ===
.macro	ORI_IO					; immediate OR on an I/O register
	in 		w,	@0				
	ori		w,	@1
	out		@0,	w
	.endm

.macro ANDI_IO					; immediate AND on an I/O register
	in 		w,	@0				
	andi	w,	@1
	out		@0,	w
	.endm

.macro	BREQ2					; test register pair @0:@1 for zero
	tst		@1					; test low register
	brne	PC+3
	tst		@0					; test high register
	breq	@2					; word is 0
	.endm

.macro MUL2_40					;multiply a3:a2 by 40 (= 0x28)
	PUSH2	a1, a0
	LSL2	@0, @1
	LSL2	@0, @1
	LSL2	@0, @1
	MOV2	a1,a0, @0,@1
	LSL2	@0, @1
	LSL2	@0, @1
	ADD2	@0, @1, a1, a0
	POP2	a1, a0
	.endm

.macro	FREQ_TO_DATA
	LDI2 a1, a0, -clock/2/@0
	LDI2 a3, a2,  @0/5
	.endm

; === interrupt routine ===
play_tone:
	in		_sreg, SREG				; save state
	push	w						
	PUSH2	a1, a0
	PUSHY

	LDIY	tone0period_addr			; load tone period
	LDY2	a1, a0

	BREQ2	a1, a0, _pause					; check if tone is pause
		INVP	PORTE,	SPEAKER					; make a sound by inverting speaker-pin
		out		TCNT1L,	a0						; set timer for next interval
		out		TCNT1H,	a1
		rjmp	_endpause
	_pause:									; no sound
		OUTI	TCNT1L, low (-4000)			; set timer for next 1 ms interval
		OUTI	TCNT1H, high(-4000)
	_endpause:

	LDIY	tone0length_addr			; load tone duration
	LDY2	a1, a0

	subi	a0, 1
	sbci	a1, 0
	brne	_not_over				; if tone is over - set for silence
		STI2	tone0period_addr, 0x0000
		_ORI  _sreg, (1<<SREG_T)	;set T-bit flag to let main know next tone must be played
	_not_over:
	LDIY	tone0length_addr			; save remaining tone duration
	STY2	a1, a0

	POPY							; restore state
	POP2	a1, a0
	pop		w 
	out		SREG, _sreg
	reti


; === subroutines === 
buzzer_init:					; arg : void
	ORI_IO	DDRE,   (1<<SPEAKER)	; set buzzer to output
	OUTI	TCCR1B, 1				; timer1: CS=1 CK/1
	sei								; set global interrupt
	ret

new_tone:						; arg : a0 (tone code) , a3:a2 (tone duration [nb_periods])

	cpi		a0, h_button					; B4
	brlo	PC+6
		FREQ_TO_DATA 494
		rjmp new_tone_save_data
	cpi		a0, a_button					; A4
	brlo	PC+6
		FREQ_TO_DATA 440
		rjmp new_tone_save_data
	cpi		a0, g_button					; G4
	brlo	PC+6
		FREQ_TO_DATA 392
		rjmp new_tone_save_data
	cpi		a0, f_button					; F4
	brlo	PC+6
		FREQ_TO_DATA 349
		rjmp new_tone_save_data
	cpi		a0, e_button					; E4
	brlo	PC+6
		FREQ_TO_DATA 330
		rjmp new_tone_save_data
	cpi		a0, d_button					; D4
	brlo	PC+6
		FREQ_TO_DATA 294
		rjmp new_tone_save_data
	cpi		a0, c_button					; C4
	brlo	PC+6
		FREQ_TO_DATA 262
	rjmp new_tone_save_data
	LDI2 a1, a0, 0x00				; pause	
	LDI2 a3, a2,  50

new_tone_save_data:
	LDIY	tone0period_addr			; save tone period
	STY2	a1, a0
	LDIY	tone0length_addr			; save tone duration
	STY2	a3, a2
	clt								; clear T-bit flag
	ORI_IO 	TIMSK,	(1<<TOIE1)		; enable timer	
	ret

stop_tone:
	ANDI_IO 	TIMSK,	-(1<<TOIE1)		; disable timer		
	STI2	tone0period_addr, 0x0000	; reset saved tone period
	STI2	tone0length_addr, 0x0000	; reset saved duration
	ret

.endif
