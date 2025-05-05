.include "m328Pdef.inc"

; Stack setup
ldi r20, high(RAMEND)
out SPH, r20
ldi r20, low(RAMEND)
out SPL, r20

; Constants
.EQU PL = 0xe1
.EQU PH = 0xb7
.EQU QL = 0x37
.EQU QH = 0x9e
.EQU R = 8
.EQU T = 18
.EQU W = 16
.EQU U = 2
.EQU B = 12
.EQU C = 6
.EQU N = 54

; Secret key bytes
	.EQU BY0 = 0x0200
	.EQU BY1 = 0x0201
	.EQU BY2 = 0x0202
	.EQU BY3 = 0x0203
	.EQU BY4 = 0x0204
	.EQU BY5 = 0x0205
	.EQU BY6 = 0x0206
	.EQU BY7 = 0x0207
	.EQU BY8 = 0x0208
	.EQU BY9 = 0x0209
	.EQU BY10 = 0x020A
	.EQU BY11 = 0x020B

; Macros
.MACRO INPUT
    .DEF AH = R16
    ldi AH, high(@0) ; Load high byte of first word
    .DEF AL = R17
    ldi AL, low(@0)  ; Load low byte of first word
    .DEF BH = R18
    ldi BH, high(@1) ; Load high byte of second word
    .DEF BL = R19
    ldi BL, low(@1)  ; Load low byte of second word
.ENDMACRO

.MACRO SECRET_KEY
	LDI R20, @11
	STS BY0, R20
	LDI R20, @10
	STS BY1, R20
	LDI R20, @9
	STS BY2, R20
	LDI R20, @8
	STS BY3, R20
	LDI R20, @7
	STS BY4, R20
	LDI R20, @6
	STS BY5, R20
	LDI R20, @5
	STS BY6, R20
	LDI R20, @4
	STS BY7, R20
	LDI R20, @3
	STS BY8, R20
	LDI R20, @2
	STS BY9, R20
	LDI R20, @1
	STS BY10, R20
	LDI R20, @0
	STS BY11, R20
.ENDMACRO

.MACRO ROTL_WORD
		TST @2
		BREQ ZEROL
		MOV R25, @2
	ROTL:
		ROL @1
		BST @0, 7
		ROL @0
		BLD @1, 0
		DEC R25
		BRNE ROTL
	ZEROL:
		nop
.ENDMACRO

.MACRO ROTR_WORD
    TST @2
    BREQ ZEROR
    MOV R25, @2          
ROTR:
    ROR @0    // Start with HIGH byte
    BST @1, 0
    ROR @1    // Then LOW byte
    BLD @0, 7
    DEC R25
    BRNE ROTR
ZEROR:
    nop
.ENDMACRO

.MACRO XOR_WORD
	EOR @1, @3
	EOR @0, @2
.ENDMACRO

.MACRO ADD_WORD
	ADD @1, @3
	ADC @0, @2
.ENDMACRO

.MACRO SUB_WORD
	SUB @1, @3
	SBC @0, @2
.ENDMACRO

;--------------------------------------------------------;--------------------------------------------------------
;RC5_SETUP
;--------------------------------------------------------
.MACRO RC5_SETUP
		;BUILD L5:
		lds r0, BY11	;r0=k[11]
		lds r1, BY10	;r1=k[10]
		;REPRESENTATION
		sts 0x022A, r1
		sts 0x022B, r0
		;BUILD L4:
		lds r0, BY9		;r0=k[9]
		lds r1, BY8		;r1=k[8]
		;REPRESENTATION
		sts 0x0228, r1
		sts 0x0229, r0
		;BUILD L3:
		lds r0, BY7		;r0=k[7]
		lds r1, BY6		;r1=k[6]
		;REPRESENTATION
		sts 0x0226, r1
		sts 0x0227, r0
		;BUILD L2:
		lds r0, BY5		;r0=k[5]
		lds r1, BY4		;r1=k[4]
		;REPRESENTATION
		sts 0x0224, r1
		sts 0x0225, r0
		;BUILD L1:
		lds r0, BY3		;r0=k[3]
		lds r1, BY2		;r1=k[2]
		;REPRESENTATION
		sts 0x0222, r1
		sts 0x0223, r0
		;BUILD L0:
		lds r0, BY1		;r0=k[1]
		lds r1, BY0		;r1=k[0]
		;REPRESENTATION
		sts 0x0220, r1
		sts 0x0221, r0

		;----------Initialize expanded key table s--------------

		;----s[0] -> S0L (LOW W KEDA )---------
		.EQU S0L = 0x0210
		.EQU S0H = 0x0211
		.EQU S1L = 0x0212
		.EQU S1H = 0x0213

		ldi ZL , low(S0L)
		ldi ZH , high(S0L)

		;int s[0] = pw
		ldi R21, PL
		ldi R22, PH
		STS S0L, R21
		STS S0H, R22

		;Load Qw into reg (R21:R22)
		ldi R21, QL
		ldi R22, QH

		ldi R20, T
		subi R20, 1
	LOOP_S:
		LD R23, Z+
		LD R24, Z+
		ADD_WORD R24, R23, R22, R21
		ST Z, R23
		STD Z+1, R24
		DEC R20
		BRNE LOOP_S

		;----KEY EXPANSION (MIX IN L ARRAY )

		clr R0
		clr R1
		clr R2
		clr R3

		ldi ZL, low(S0L)
		ldi ZH, high(S0L)
		ldi YL, low(0x0220)
		ldi YH, high(0x0220)

		ldi R20, N
	LOOP_MIX:
		ADD_WORD R1, R0, R3, R2
		LD R23, Z
		LDD R24, Z+1
		ADD_WORD R1, R0, R24, R23
		ldi R22, 3
		ROTL_WORD R1, R0, R22
		ST Z, R0
		STD Z+1, R1

		ADD_WORD R3, R2, R1, R0
		mov R22, R2
		andi R22, 0x0F
		LD R23, Y
		LDD R24, Y+1
		ADD_WORD R3, R2, R24, R23
		ROTL_WORD R3, R2, R22
		ST Y, R2
		STD Y+1, R3

		call I_RESET
		call J_RESET

		DEC R20
		BRNE LOOP_MIX
.ENDMACRO

;------ENCRYPT-----------
.MACRO RC5_ENCRYPT
		LDI XL, 0x14
		LDI XH, 0x02

		LDS R22, S0L
		LDS R21, S0H
		ADD_WORD AH, AL, R21, R22
		LDS R22, S1L
		LDS R21, S1H
		ADD_WORD BH, BL, R21, R22

		LDI R20, R
	LOOP_E:
		LDI R22, 0x0F
		AND R22, BL
		LD R23, X+
		LD R24, X+
		XOR_WORD AH, AL, BH, BL
		ROTL_WORD AH, AL, R22
		ADD_WORD AH, AL, R24, R23

		LDI R22, 0x0F
		AND R22, AL
		LD R23, X+
		LD R24, X+
		XOR_WORD BH, BL, AH, AL
		ROTL_WORD BH, BL, R22
		ADD_WORD BH, BL, R24, R23

		DEC R20
		BRNE LOOP_E
.ENDMACRO

;----DECRYPT----------

.MACRO RC5_DECRYPT
    LDI XL, 0x34      
    LDI XH, 0x02
    LDI R20, R
LOOP_D:
    ; First decryption step
    LDI R22, 0x0F
    AND R22, AL        ; Use AL for rotation amount
    LD R23, -X         
    LD R24, -X
    SUB_WORD BH, BL, R23, R24  ; Changed order to R23, R24
    ROTR_WORD BH, BL, R22
    XOR_WORD BH, BL, AH, AL
    
    ; Second decryption step
    LDI R22, 0x0F
    AND R22, BL        ; Use BL for rotation amount
    LD R23, -X
    LD R24, -X
    SUB_WORD AH, AL, R23, R24  ; Changed order to R23, R24
    ROTR_WORD AH, AL, R22
    XOR_WORD AH, AL, BH, BL
    
    DEC R20
    BRNE LOOP_D
    
    ; Subtract initial values
    LDS R22, S0H
    LDS R21, S0L
    SUB_WORD AH, AL, R22, R21
    LDS R22, S1H
    LDS R21, S1L
    SUB_WORD BH, BL, R22, R21
.ENDMACRO

;-------------- LCD INIT --------------------

.MACRO LCD

LCD_write_2:
	LDI		R25, 0XFF
	OUT		DDRD, R25	;set port D for data
	OUT		DDRB, R25	;set port B for cmd	
	CBI		PORTB, 0	;EN = 0 DISPLAY
	RCALL  delay_ms_2	;WAIT FOR POWER ON
	RCALL  LCD_init_2	;subroutine -> int LCD
	RCALL  disp_message_2 ;sub -> display only

end_2: RJMP end_dis
;--------------------------------
LCD_init_2:
    LDI R25, 0x33    ; Initialize to 4-bit mode
    RCALL command_wrt_2
    RCALL delay_ms_2 ; Delay for stability
    LDI R25, 0x32
    RCALL command_wrt_2
    RCALL delay_ms_2
    LDI R25, 0x28    ; 2-line display
    RCALL command_wrt_2
    RCALL delay_ms_2
    LDI R25, 0x0C    ; Display ON
    RCALL command_wrt_2
    LDI R25, 0x01    ; Clear display
    RCALL command_wrt_2
    RCALL delay_ms_2 ; Delay after clearing
    LDI R25, 0x06    ; Shift cursor
    RCALL command_wrt_2
    RET

; LCD Command write (4-bit)
command_wrt_2:
    MOV R30, R25
    ANDI R30, 0xF0
    OUT PORTD, R30
    SBI PORTB, 0 ; EN = 1
    CBI PORTB, 1 ; RS = 0
    RCALL delay_short_2
    CBI PORTB, 0 ; EN = 0
    RCALL delay_us_2
    MOV R30, R25
    SWAP R30 ; Swap nibbles
    ANDI R30, 0xF0
    OUT PORTD, R30
    SBI PORTB, 0
    RCALL delay_short_2
    CBI PORTB, 0
    RCALL delay_us_2
    RET
;-------------------------------
data_wrt_2:
	MOV R30, R25
    ANDI R30, 0xF0
    OUT PORTD, R30
    SBI PORTB, 1	;rs = 1 3l4an el data
	SBI PORTB, 0	;EN = 1
	RCALL delay_short_2
    CBI PORTB, 0
	RCALL delay_us_2
    ;-------
	MOV R30, R25
    SWAP R30		;SWAP NIBBLES
    ANDI R30, 0xF0
    OUT PORTD, R30
    SBI PORTB, 0
	RCALL delay_short_2
    CBI PORTB, 0
	RCALL delay_us_2
    RET
;-----------------
disp_message_2:
    ; Display first character
    MOV R25, R16
    RCALL data_wrt_2
    RCALL delay_seconds_2

    ; Display second character
    MOV R25, R17
    RCALL data_wrt_2
    RCALL delay_seconds_2

    ; Display third character
    MOV R25, R18
    RCALL data_wrt_2
    RCALL delay_seconds_2

    ; Display fourth character
    MOV R25, R19
    RCALL data_wrt_2
    RCALL delay_seconds_2

    ; Add a delay for stability
    LDI R28, 12 ; Wait 3 seconds
l2_2: RCALL delay_seconds_2
    DEC R28
    BRNE l2_2
    RET
;------------------------
delay_short_2:
    NOP
    NOP
    RET

delay_us_2:
    LDI R20, 90
l3_2: RCALL delay_short_2
    DEC R20
    BRNE l3_2
    RET

delay_ms_2:
    LDI R29, 40
l4_2: RCALL delay_us_2
    DEC R29
    BRNE l4_2
    RET

delay_seconds_2:
    LDI R20, 255
l5_2: 
    LDI R29, 255
l6_2:
    LDI R30, 20
l7_2:
    DEC R30
    BRNE l7_2
    DEC R29
    BRNE l6_2
    DEC R20
    BRNE l5_2
    RET

end_dis:
nop
.ENDMACRO

;--------------------------------------------------------
; Main Program Start
; Main Program Start
start:
    SECRET_KEY 00,00,00,00,00,50,00,00,00,00,00,00
    RC5_SETUP

    ; Test case 1: "Kemo" as 0x4B65 and 0x6D6F
    INPUT 0x4B65, 0x6D6F ; Load "Kemo" into registers
    LCD                  ; Display "Kemo"

    RC5_ENCRYPT
    LCD                  ; Display encrypted text

    RC5_DECRYPT
    LCD                  ; Display "Kemo" (decrypted text)

    ; Test case 2: "0080" as 0x3030 and 0x3830
    INPUT 0x3030, 0x3830 ; Load "0080" into registers
    LCD                  ; Display "0080"

    RC5_ENCRYPT
    LCD                  ; Display encrypted text

    RC5_DECRYPT
    LCD                  ; Display "0080" (decrypted text)

    ; Restart the program
    RJMP start           ; Restart instead of freezing;----------------------------------
;----reset------

I_RESET:
    INC ZL
    INC ZL
    LDI R21, 0x34 ; Ensure ZL does not exceed the memory range
    CPSE ZL, R21
    RET
    LDI ZL, low(S0L) ; Reset ZL to the start of S0L
    RET

J_RESET:
    INC YL
    INC YL
    LDI R21, 0x0C ; Ensure YL does not exceed the memory range
    CPSE YL, R21
    RET
    LDI YL, low(0x0220) ; Reset YL to the start of the key table
    RET
