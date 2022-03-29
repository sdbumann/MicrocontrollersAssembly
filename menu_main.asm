;
; menu.asm
;
; Created: 09.05.2019 11:49:35
; Author : samuel
;


; === interrupt vector table ===
.org	0
	jmp	menu_reset
.org	OVF1addr
	jmp	play_tone

;======================includes======================;
.include "playback.asm"
.include "matrix.asm"
.include "encoder.asm"
.include "lcd.asm"
.include "printf.asm"
.include "menu.asm"

;====================definitions=====================;
.equ super_mario_mode	= 0
.equ nyan_cat_mode		= 1
.equ star_wars_mode		= 2
.equ save_song_1_mode	= 3
.equ save_song_2_mode	= 4
.equ save_song_3_mode	= 5

;=======================macros=======================;
.macro MENU_BACK_BUTTON; if back_button (button 0) pressed back to menu_main
	sbic	BUTTON, 0			; back_button
	rjmp	PC + 3
		rcall	matrix_reset
		rjmp	menu_main
.endmacro

;=======================reset========================;
menu_reset:
	; initializations
	LDSP	RAMEND					; load stack pointer
	
	OUTI	DDRD,	0x00			; initialize buttons as input
	OUTI	DDRB,	0xFF			; initialize LEDS as output
	rcall	encoder_init			; initilaize encoder
	rcall	buzzer_init				; initialize buzzer
	rcall	matrix_init				; initialize LED-matrix
	rcall	LCD_init				; initialize LCD-display
	rcall	memory_init				; initialize RAM storage

	set								; set T-flag for buzzer
	ldi		a0, 0x00				; initialize a0 to empty		
	rcall	start_recording
;	rjmp	menu_main
	
;=======================main========================;
menu_main: ;navigation trough play_piano and play_music
	rcall encoder; a0,b0: if button=up then increment/decrement a0; if button=down then incremnt/decrement b0 
	CYCLIC a0, 0, 1 ; if a0<0 -> a0=1; if a0>1 -> a0=0 
	PRINTF LCD
	.db CR,CR, FDEC+FSIGN,a,": ", 0, 0
	rcall menui 
	.db "play_piano  |play_music  ",0
	rcall encoder; encoder pressed -> T=1 
	brtc menu_main ;branch if T=0
		tst a0
		breq PC+3 ;branch if Z=1
			ldi a0, 0 ; here if Z=0/a0=1
			rjmp menu_play_music
		ldi a0, 0 ; here if Z=1/a0=0
		rjmp menu_play_piano

;=====================functions=====================;
menu_play_piano: 
	sbic BUTTON, 0			; back_button
	rjmp	PC+5
		rcall	stop_tone ; here if back_button pressed
		rcall	end_recording
		rcall	matrix_reset
		rjmp	menu_main
	nop
	brtc menu_play_piano		; empty loop for tone to play in
		in		a0, BUTTON
		com		a0
		push	a0
		rcall	new_tone
		pop		a0
		rcall	save_tone
		rcall	matrix_main
		rcall	encoder			; encoder pressed -> T=1 
		brtc	menu_play_piano ;branch if T=0
			rcall	stop_tone ; here if T=1
			rcall	end_recording
			rcall	matrix_reset
			rcall	menu_piano_save
			rcall	LCD_clear
			PRINTF	LCD
			.db CR,CR, "1: play_piano",0
		rjmp	menu_play_piano

menu_piano_save:
	MENU_BACK_BUTTON			; if back_button (button 0) pressed back to menu_main

	rcall	encoder				; a0,b0: if button=up then increment/decrement a0; if button=down then incremnt/decrement b0 
	CYCLIC	a0, 0, 2			; if a0<0 -> a0=2; if a0>2 -> a0=0 
	PRINTF	LCD
	.db CR,CR, FDEC+FSIGN,a,": slot: ",0 ,0
	rcall	menui
	.db "save_1   |save_2    |save_3    ",0
	
	rcall	encoder				; encoder pressed -> T=1 
	brtc	menu_piano_save		;branch if T=0
		inc		a0
		rcall	start_recording	; slot_0 is reserved for throwaway 
	ret
	
menu_play_music:		
	MENU_BACK_BUTTON			; if back_button (button 0) pressed back to menu_main
	
	rcall	encoder				; a0,b0: if button=up then increment/decrement a0; if button=down then incremnt/decrement b0 
	CYCLIC	a0, 0, 5
	PRINTF	LCD
	.db CR,CR, FDEC+FSIGN,a,": ",0 ,0
	rcall	menui
	.db "super_mario |nyan_cat    |star_wars   |save_1     |save_2     |save_3     ",0 ,0
	rcall	encoder				; encoder pressed -> T=1
	CYCLIC	a0, 0, 5
	in		w,	SREG			; skip if bit t is set
	sbrs	w, SREG_T
		rjmp	menu_play_music
	cpi		a0, super_mario_mode
		brne	nyan_menu
		STI2	current_slot_addr, mario_start ; here if super_mario song was selected
		rcall	play_ProgM_song
		rjmp	menu_play_music
	nyan_menu:
	cpi		a0, nyan_cat_mode
	brne	sw_menu
		STI2	current_slot_addr, nyan_start ; here if nyan song was selected
		rcall	play_ProgM_song
		rjmp	menu_play_music
	sw_menu:
	cpi		a0, star_wars_mode
	brne	save_1_menu
		STI2	current_slot_addr, sw_start ; here if star wars song was selected
		rcall	play_ProgM_song
		rjmp	menu_play_music
	save_1_menu:
	cpi		a0, save_song_1_mode 
	brne	 save_2_menu
		STI2	current_slot_addr, save_slot1 ; here if star save_song_slot_1 was selected
		rjmp	menu_play_music_play_RAM
	save_2_menu:
	cpi		a0, save_song_2_mode
	brne	save_3_menu
		STI2	current_slot_addr, save_slot2 ; here if star save_song_slot_1 was selected
		rjmp	menu_play_music_play_RAM
	save_3_menu:
	ldi		w, save_song_3_mode
	cpse	a0, w
		rjmp	menu_play_music
	STI2	current_slot_addr, save_slot3 ; here if star save_song_slot_1 was selected

	menu_play_music_play_RAM:
	rcall	check_memory ; checks if memory is empty
	brts	menu_play_music_null_memory
		rcall	play_RAM_song
		rjmp	menu_play_music
	menu_play_music_null_memory: ; here if memory is empty
		PRINTF	LCD 
		.db CR,"slot is empty", 0, 0
		WAIT_MS	1500
		clt
	rjmp	menu_play_music


