/*
 * memory_allocation.asm
 *
 *  Created: 05/05/2019 19:46:27
 *   Author: mwbis
 */ 

.ifndef MEM_ALLOC
.equ MEM_ALLOC = 1

.set	tone_size	= 3
.set	slot_size	= 50

.dseg
.org 0x100
	start0:				.byte	1
	save_slot0:			.byte	(3*50)	; format: [ 1byte tonecode, 2bytes duration]
	start1:				.byte	1
	save_slot1:			.byte	(3*50)	
	start2:				.byte	1
	save_slot2:			.byte	(3*50)
	start3:				.byte	1
	save_slot3:			.byte	(3*50)	
	
	tone_1:	.byte	3;for matrix.asm
	tone_2: .byte	3
	tone_3: .byte	3
	tone_4: .byte	3
	matrix_show_pointer: .byte 2	

	enc_old:.byte	1;for encoder.asm

	current_slot_addr:	.byte	2	
	current_save_tone:	.byte	1
	current_play_tone:	.byte	1
	current_play_dura:	.byte	2		

	tone0period_addr:	.byte	2
	tone0length_addr:	.byte	2
	
.cseg


; === notes === 
.set	P	=	0x0000		; pause
.set	O	=	2 			; whole beat [
.set	H	=	(2*O)			; half beat
.set	Q	=	(4*O)			; quarter beat
.set	E	=	(8*O)			; eigth beat

.set	prescaler = 1
.set	fc4	=  262
.set	C4	= -clock/(prescaler*2* fc4 )
.set	fdb4	=  277
.set	Db4	= -clock/(prescaler*2* fdb4)
.set	fd4	=  294
.set	D4	= -clock/(prescaler*2* fd4 )
.set	feb4 =  311
.set	Eb4	= -clock/(prescaler*2* feb4)
.set	fe4	=  330
.set	E4	= -clock/(prescaler*2* fe4 )
.set	ff4	=  349
.set	F4	= -clock/(prescaler*2* ff4 )
.set	fgb4 =  370
.set	Gb4	= -clock/(prescaler*2* fgb4)
.set	fg4	=  392
.set	G4	= -clock/(prescaler*2* fg4 )
.set	fab4	=  415
.set	Ab4	= -clock/(prescaler*2* fab4)
.set	fla4	=  440
.set	LA4	= -clock/(prescaler*2* fla4)
.set	fbb4	=  466
.set	Bb4	= -clock/(prescaler*2* fbb4)
.set	fb4	=  494
.set	B4	= -clock/(prescaler*2* fb4 )
.set	fc5	=  523
.set	C5	= -clock/(prescaler*2* fc5 )
.set	fdb5	=  554
.set	Db5	= -clock/(prescaler*2* fdb5)
.set	fd5	=  587
.set	D5	= -clock/(prescaler*2* fd5 )
.set	feb5	=  662
.set	Eb5	= -clock/(prescaler*2* feb5)
.set	fe5	=  659
.set	E5	= -clock/(prescaler*2* fe5 )
.set	ff5	=  698
.set	F5	= -clock/(prescaler*2* ff5 )
.set	fgb5	=  740
.set	Gb5	= -clock/(prescaler*2* fgb5)
.set	fg5	=  784
.set	G5	= -clock/(prescaler*2* fg5 )
.set	fab5	=  831
.set	Ab5	= -clock/(prescaler*2* fab5)
.set	fla5	=  880
.set	LA5	= -clock/(prescaler*2* fla5)
.set	fbb5	=  932
.set	Bb5	= -clock/(prescaler*2* fbb5)
.set	fb5	=  988
.set	B5	= -clock/(prescaler*2* fb5 )
.set	fc6	= 1046
.set	C6	= -clock/(prescaler*2* fc6 )

; === songs === 
.org 100
mario_start: 					; format : note, duration
.dw		mario_end
.dw 	E5, fe5/H,		P,25,    E5, fe5/H,		P,125,   E5, fe5/H,		P,125 
.dw		C5, fc5/H,		P,25,    E5, fe5/H,		P,125,   G5, fg5/H,		P,325,   G4, fg4/H,		P,325     
.dw		C5, fc5/H,		P,250,   G4, fg4/H,		P,250,	 E4, fe4/H,		P,250
.dw		LA4,fla4/H,		P,125,   B4, fb4/H,		P,125,   Bb4, fbb4/H,	P,25,    LA4, fla4/H,	P,125
.dw		G4,fg4/Q+fg4/E,	P,75,  E5,fe5/Q+fe5/E,  P,75,  G5,fg5/Q+fg5/E,  P,75,    LA5, fla5/H,	P,125
.dw		F5, ff5/H,		P,25,    G5, fg5/H,		P,125,   E5, fe5/H,		P,125,   C5, fc5/H,		P,25,     D5, fd5/H,	P,25,    B4, fb4/H,  P,250
.dw		C5, fc5/H,		P,250,   G4, fg4/H,		P,250,	 E4, fe4/H,		P,250
.dw		LA4,fla4/H,		P,125,   B4, fb4/H,		P,125,   Bb4, fbb4/H,	P,25,    LA4, fla4/H,	P,125
.dw		G4,fg4/Q+fg4/E,	P,75,  E5,fe5/Q+fe5/E,  P,75,  G5,fg5/Q+fg5/E,  P,75,    LA5, fla5/H,	P,125
.dw		F5, ff5/H,		P,25,    G5, fg5/H,		P,125,   E5, fe5/H,		P,125,   C5, fc5/H,		P,25,     D5, fd5/H,	P,25,    B4, fb4/H,  P,250
.dw		P,100,			P,4000
mario_end: 

nyan_start:
.dw		nyan_end
.dw		Eb4,feb4/Q, E4,fe4/Q,	Gb4,fgb4/Q, P,62,		B4,fb4/Q,	P,62,		Eb4,feb4/Q,	E4,fe4/Q,   Gb4,fgb4/Q,	B4,fb4/Q,   Db5,fdb5/Q,	Eb5,feb5/Q,	Db5,fdb5/Q
.dw		Bb4,fbb4/Q, B4,fb4/Q,	P,62,		Gb4,fgb4/Q,	P,62,		Eb4,feb4/Q,	E4,fe4/Q,	Gb4,fgb4/Q, P,62,		B4,fb4/Q,   P,62,		Db5,fdb5/Q,	Bb4,fbb4/Q
.dw		B4,fb4/Q,   Db5,fdb5/Q,	E5,fe5/Q,	Eb5,feb5/Q,	E5,fe5/Q,	Db5,fdb5/Q,	Gb5,fgb5/Q,	P,62,		Ab5,fab5/Q,	P,62,		Eb5,feb5/Q,	Eb5,feb5/Q,	P,62
.dw		B4,fb4/Q,	D5,fd5/Q,	Db5,fdb5/Q, B4,fb4/Q,	P,62,		B4,fb4/Q,	P,62,		Db5,fdb5/Q, P,62,		D5,fd5/Q,   P,62,		D5,fd5/Q,	Db5,fdb5/Q
.dw		B4,fb4/Q,   Db5,fdb5/Q,	Eb5,feb5/Q, Gb5,fgb5/Q,	Ab5,fab5/Q,	Eb5,feb5/Q,	Gb5,fgb5/Q,	Db5,fdb5/Q, Eb5,feb5/Q,	B4,fb4/Q,   Db5,fdb5/Q,	B4,fb4/Q,	Eb5,feb5/Q
.dw		P,62,		Gb5,fgb5/Q,	P,62,		Ab5,fab5/Q,	Eb5,feb5/Q,	Gb5,fgb5/Q,	Db5,fdb5/Q,	Eb5,feb5/Q, B4,fb4/Q,	D5,fd5/Q,	Eb5,feb5/Q,	D5,fd5/Q,	Db5,fdb5/Q
.dw		B4,fb4/Q,   Db5,fdb5/Q,	D5,fd5/Q,	P,62,		B4,fb4/Q,	Db5,fdb5/Q,	Eb5,feb5/Q,	Gb5,fgb5/Q,	Db5,fdb5/Q,	Eb5,feb5/Q, Db5,fdb5/Q, B4,fb4/Q,	Db5,fdb5/Q
.dw		P,62,		B4,fb4/Q,   P,62,		Db5,fdb5/Q,	P, 62,		Gb5,fgb5/Q,	P,62,		Ab5,fab5/Q, P,62,		Eb5,feb5/Q,	Eb5,feb5/Q,	P,62,		B4,fb4/Q
.dw		D5,fd5/Q,	Db5,fdb5/Q, B4,fb4/Q,	P,62,		B4,fb4/Q,	P,62,		Db5,fdb5/Q, P,62,		D5,fd5/Q,	P,62,		D5,fd5/Q,	Db5,fdb5/Q, B4,fb4/Q
.dw		Db5,fdb5/Q,	Eb5,feb5/Q, Gb5,fgb5/Q,	Ab5,fab5/Q,	Eb5,feb5/Q,	Gb5,fgb5/Q,	Db5,fdb5/Q,	Eb5,feb5/Q, B4,fb4/Q,	Db5,fdb5/Q,	B4,fb4/Q,	Eb5,feb5/Q, P,62
.dw		P,100,		P,4000
nyan_end:

sw_start:
.dw		sw_end
.dw		LA4,fla4,	P,50,		LA4,fla4/O,	P,50,		LA4,fla4/O,	P,50,		F4,ff4*7/20, P,50,		C5,fc5*3/20, P,50,		LA4,fla4/O,	P,50,	F4,ff4*7/20,	P,50,   C5,fc5*3/20,	P,50,    LA4,fla4+fla4/Q,	P,250
.dw		E5,fe5/O,	P,50,		E5,fe5/O,	P,50,		E5,fe5/O,	P,50,       F5,ff5*7/20, P,50,		C5,fc5*3/20, P,50,		Ab4,fab4/O,	P,50,   F4,ff4*7/20,	P,50,   C5,fc5*3/20,	P,50,    LA4,fla4+fla4/Q,	P,250
.dw		LA5,fla5/O,	P,50,		LA4,fla4*3/10, P,50,	LA4,fla4*3/20, P,50,    LA5,fla5/O,	 P,50,		Ab5,fab5*7/20, P,50,    G5,fg5/Q,	P,50,   Gb5,fgb5/Q,		P,50,   F5,ff5/Q,		P,50,    Gb5,fgb5/H,		P,162
.dw		Bb4,fbb4/H,	P,50,		Eb5,feb5/O,	P,50,		D5,fd5*3/10, P,25,		Db5,fdb5*1/5, P,50,		C5,fc5/Q,	 P,50,		B4,fb4/Q,	P,50,   C5,fc5/O,		P,162
.dw		F4,ff4/H,	P,50,		Ab4,fab4/O,	P,50,		F4,ff4*7/20, P,50,		LA4,fla4*3/20,P,50,		C5,fc5/O,	 P,50,		LA4,fla4*2/5, P,50,	C5,fc5*3/20,	P,50,	E5,fe5*13/20,	P,250
.dw		LA5,fla5/O,	P,50,		LA4,fla4*3/10, P,50,	LA4,fla4*3/20, P,50,    LA5,fla5/O,	 P,50,		Ab5,fab5*7/20, P,50,    G5,fg5/Q,	P,50,   Gb5,fgb5/Q,		P,50,   F5,ff5/Q,		P,50,    Gb5,fgb5/H,		P,162
.dw		Bb4,fbb4/H,	P,50,		Eb5,feb5/O,	P,50,		D5,fd5*3/10, P,25,		Db5,fdb5*1/5, P,50,		C5,fc5/Q,	 P,50,		B4,fb4/Q,	P,50,   C5,fc5/O,		P,162
.dw		F4,ff4/H,	P,50,		Ab4,fab4/O,	P,50,		F4,ff4*7/20, P,50,		C5,fc5*3/20, P,50,		LA4,fla4/O,	 P,50,		F4,ff4*7/20, P,50,	C5,fc5*3/20,	P,50,	LA4,fla4/O,		P,250
.dw		P,100,		P,4000
sw_end:

; === matrix === 

;RGB color code for different tones: lsb first
no_color:.db 0x00, 0x00, 0x00, 0 ; pixel is off 
h_color: .db 0x02, 0x02, 0x02, 0 ; low-intensity "white" light
a_color: .db 0x03, 0x03, 0x00, 0 ; low-intensity yellow
g_color: .db 0x00, 0x0F, 0x00, 0 ; low-intensity pure red
f_color: .db 0x00, 0x05, 0x05, 0 ; low-intensity pink
e_color: .db 0x00, 0x00, 0x0F, 0 ; low-intensity pure blue
d_color: .db 0x04, 0x00, 0x04, 0 ; low-intensity cyan
c_color: .db 0x08, 0x00, 0x00, 0 ; low-intensity pure green

;lookup table for matrix show
matrix_show_start: ; pattern of the matrix color show
.db 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 3, 2, 2, 2, 2, 3, 4, 4, 3, 2, 1, 1, 2, 3, 4
.db 4, 3, 2, 1, 1, 2, 3, 4, 4, 3, 2, 2, 2, 2, 3, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4
matrix_show_end:

.endif