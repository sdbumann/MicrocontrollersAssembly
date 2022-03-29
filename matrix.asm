;
; matrix.asm
;
; Created: 05.05.2019 18:05:36
; Author : samuel
;
;======================includes======================;
.include "macros.asm"		; include macro definitions
.include "definitions.asm"	; include register/constant definitions

;========================init========================;
matrix_init:; init matrix and stores pointer to the start of lookup table in memory
	rcall	ws2812b4_init
	LDIX matrix_show_pointer
	LDIZ 2*matrix_show_start
	st x+,zl
	st x, zh
	rcall matrix_reset

	ret

;=======================reset========================;
matrix_reset:;resets tone_1-4 and turns all pixels off
	ldi a0, 0x00
	LDIX tone_1;no color in tone_1
	st x+, a0
	st x+, a0
	st x, a0

	LDIX tone_2;no color in tone_1
	st x+, a0
	st x+, a0
	st x, a0

	LDIX tone_3;no color in tone_1
	st x+, a0
	st x+, a0
	st x, a0

	LDIX tone_4;no color in tone_1
	st x+, a0
	st x+, a0
	st x, a0

	ldi b3, 65
	cli
	matrix_reset_loop:; loop reset all 64 pixels
		subi b3, 1		
		breq pc + 6
			ldi a0, 0x00 ; no color
			ldi a1, 0x00
			ldi a2, 0x00
			rcall ws2812b4_byte3wr
			rjmp matrix_reset_loop
	sei
	ret

;======================includes======================;
.include "WS812B_driver.asm"		; include WS812B_driver (matrix)
.include "memory_allocation.asm"	; include memory_allocation

;=======================macros=======================;
.macro MATRIX_MOVE_TONE;move tone_x --> tone_y
	LDIX @0
	LDIY @1		
	rcall	matrix_move
.endmacro

.macro MATRIX_NEW_TONE_1; put a new RGB color code in tone_1 (RAM)
	cpi a3, @0
	brlo PC + 6
		LDIX tone_1
		LDIZ 2*@1
		rcall matrix_color_in_tone_1
.endmacro


.macro MATRIX_INTI; put RGB code of tone_x in a0, a1 and a2, if pixel to display in matrix_show array is tone_x
	LDIX matrix_show_pointer
	LDX2 zh, zl
	lpm	b0, z
	cpi b0, @0
	brne PC + 6
		LDIX @1
		LDX3 a2, a1, a0
.endmacro

;=====================definitions=====================;
.set no_button=0b00000000
.set c_button=0b00000010
.set d_button=0b00000100
.set e_button=0b00001000
.set f_button=0b00010000
.set g_button=0b00100000
.set a_button=0b01000000
.set h_button=0b10000000

;========================main========================;
matrix_main: ;a0 which button pressed
	push w
	PUSH4 a3, a2, a1, a0
	PUSH3 b3, b1, b0
	mov a3,a0

	MATRIX_MOVE_TONE tone_3, tone_4 ; tone_3-->tone_4
	MATRIX_MOVE_TONE tone_2, tone_3 ; tone_2-->tone_3
	MATRIX_MOVE_TONE tone_1, tone_2 ; tone_1-->tone_2
	
	MATRIX_NEW_TONE_1 no_button, no_color	; if no_button pressed --> no color (pixel off) in tone_1
	MATRIX_NEW_TONE_1 c_button, c_color		; if c_button pressed --> c_color in tone_1
	MATRIX_NEW_TONE_1 d_button, d_color		; if d_button pressed --> d_color in tone_1
	MATRIX_NEW_TONE_1 e_button, e_color		; if e_button pressed --> e_color in tone_1
	MATRIX_NEW_TONE_1 f_button, f_color		; if f_button pressed --> f_color in tone_1
	MATRIX_NEW_TONE_1 g_button, g_color		; if g_button pressed --> g_color in tone_1
	MATRIX_NEW_TONE_1 a_button, a_color		; if a_button pressed --> a_color in tone_1
	MATRIX_NEW_TONE_1 h_button, h_color		; if h_button pressed --> h_color in tone_1
	
	ldi b3, 64 ;loop counter for 64 pixel of matrix
	cli							; not allow interrupts during display of colors on matrix
	matrix_loop:				; loop display colors in all 64 pixels
		MATRIX_INTI 4, tone_4		; if pixel to display in matrix_show array is 4 -> put RGB code of tone_4 in a0, a1 and a2  
		MATRIX_INTI 3, tone_3		; if pixel to display in matrix_show array is 3 -> put RGB code of tone_3 in a0, a1 and a2	
		MATRIX_INTI 2, tone_2		; if pixel to display in matrix_show array is 2 -> put RGB code of tone_2 in a0, a1 and a2
		MATRIX_INTI 1, tone_1		; if pixel to display in matrix_show array is 1 -> put RGB code of tone_1 in a0, a1 and a2	
		rcall	ws2812b4_byte3wr
		INCS2	matrix_show_pointer ; increment matrix_show_pointer
		subi	b3, 1
		brne	matrix_loop	
	sei							; allow interrupts
	LDIX matrix_show_pointer	; if here matrix_show_pointer at end of list -> matrix_show_pointer=matrix_show_start 
	LDIZ 2*matrix_show_start
	STX2 zh, zl

	POP3 b3, b1, b0
	POP4 a3, a2, a1, a0
	pop w

	ret

;======================functions======================;
matrix_move: ;move tone_x --> tone_y
	ld w, x+
	st y+, w
	ld w, x+
	st y+, w
	ld w, x+
	st y+, w
	ret

matrix_color_in_tone_1: ; put a new RGB color code in tone_1 (RAM)
	lpm
	adiw z, 1
	st x+, r0
	lpm
	adiw z, 1
	st x+, r0
	lpm
	adiw z, 1
	st x, r0
	ret

