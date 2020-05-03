/* Reference implementation of SPIX_8(l_ad=2, l_m=16)
 Written by:
 Yunjie Yi <yunjie.yi@uwaterloo.ca>
 */
; asmY.asm
;
; Created: 2018/9/19 16:21:28
; Author : Yunjie Yi
;

; Warnning: before run, set R19 - R16, R23 - R20, and a,b,c, R13(u)
.include "m128def.inc"
main:
;; Initialize the stack pointer begin --------------
INIT: ldi r28, high(RAMEND) 
out SPH, r28
ldi r28, low(RAMEND)
out SPL, r28
;; Initialize the stack pointer end--------------------


ldi R20,0x0f  ;;0-5
STS $521, R20
ldi R20,0x47
STS $522, R20
ldi R20,0x04
STS $523, R20
ldi R20,0xB2
STS $524, R20
ldi R20,0x43
STS $525, R20
ldi R20,0xB5
STS $526, R20
ldi R20,0xF1
STS $527, R20
ldi R20,0X37
STS $528, R20
ldi R20,0x44
STS $529, R20
ldi R20,0x96
STS $52A, R20  
ldi R20,0x73
STS $52B, R20
ldi R20,0xEE
STS $52C, R20 ;;0-5


ldi R20,0xE5 ;;6-11
STS $52D, R20
ldi R20,0x4C
STS $52E, R20
ldi R20,0x0B
STS $52F, R20
ldi R20,0xF5
STS $530, R20
ldi R20,0x47
STS $531, R20
ldi R20,0x07
STS $532, R20
ldi R20,0xB2
STS $533, R20
ldi R20,0x82
STS $534, R20
ldi R20,0xB5
STS $535, R20
ldi R20,0xA1
STS $536, R20  
ldi R20,0x37
STS $537, R20
ldi R20,0x78
STS $538, R20 ;;6-11

ldi R20,0x96  ;;12-17
STS $539, R20
ldi R20,0xA2
STS $53A, R20
ldi R20,0xEE
STS $53B, R20
ldi R20,0xB9
STS $53C, R20
ldi R20,0x4C
STS $53D, R20
ldi R20,0xF2
STS $53E, R20
ldi R20,0xF5
STS $53F, R20
ldi R20,0x85
STS $540, R20
ldi R20,0x07
STS $541, R20
ldi R20,0x23
STS $542, R20  
ldi R20,0x82
STS $543, R20
ldi R20,0xD9
STS $544, R20 ;;12-17

ldi R20,0x08  ;;SC 0-5
STS $621, R20
ldi R20,0x64
STS $622, R20
ldi R20,0x86
STS $623, R20
ldi R20,0x6B
STS $624, R20
ldi R20,0xE2
STS $625, R20
ldi R20,0x6F
STS $626, R20
ldi R20,0x89
STS $627, R20
ldi R20,0X2C
STS $628, R20
ldi R20,0xE6
STS $629, R20
ldi R20,0xDD
STS $62A, R20  
ldi R20,0xCA
STS $62B, R20
ldi R20,0x99
STS $62C, R20 ;;SC 0-5


ldi R20,0x17 ;;SC 6-11
STS $62D, R20
ldi R20,0xEA
STS $62E, R20
ldi R20,0x8E
STS $62F, R20
ldi R20,0x0F
STS $630, R20
ldi R20,0x64
STS $631, R20
ldi R20,0x04
STS $632, R20
ldi R20,0x6B
STS $633, R20
ldi R20,0x43
STS $634, R20
ldi R20,0x6F
STS $635, R20
ldi R20,0xF1
STS $636, R20  
ldi R20,0x2C
STS $637, R20
ldi R20,0x44
STS $638, R20 ;;SC 6-11

ldi R20,0xDD  ;;SC 12-17
STS $639, R20
ldi R20,0x73
STS $63A, R20
ldi R20,0x99
STS $63B, R20
ldi R20,0xE5
STS $63C, R20
ldi R20,0xEA
STS $63D, R20
ldi R20,0x0B
STS $63E, R20
ldi R20,0x0F
STS $63F, R20
ldi R20,0x47
STS $640, R20
ldi R20,0x04
STS $641, R20
ldi R20,0xB2
STS $642, R20  
ldi R20,0x43
STS $643, R20
ldi R20,0xB5
STS $644, R20 ;;SC 12-17


;; (t, t') is from 521 - 544

;; (SC, SC') is from 621 - 644

;; Load R0 to R31 total 256 bits-------
LDI R23, 0x00 ;1 R7 - R0
LDI R22, 0x00
LDI R21, 0x00
LDI R20, 0x00
LDI R19, 0x00
LDI R18, 0x00
LDI R17, 0x00
LDI R16, 0x00
MOV R7, R23
MOV R6, R22
MOV R5, R21
MOV R4, R20
MOV R3, R19
MOV R2, R18
MOV R1, R17
MOV R0, R16

LDI R23, 0x00 ;2 R15 - R8
LDI R22, 0x00
LDI R21, 0x00
LDI R20, 0x00
LDI R19, 0x00
LDI R18, 0x00
LDI R17, 0x00
LDI R16, 0x00
MOV R15, R23
MOV R14, R22
MOV R13, R21
MOV R12, R20
MOV R11, R19
MOV R10, R18
MOV R9, R17
MOV R8, R16

LDI R23, 0x00 ;3 R23 - R16
LDI R22, 0x00
LDI R21, 0x00
LDI R20, 0x00
LDI R19, 0x00
LDI R18, 0x00
LDI R17, 0x00
LDI R16, 0x00

LDI R31, 0x00 ;4 R31 - R24
LDI R30, 0x00
LDI R29, 0x00
LDI R28, 0x00
LDI R27, 0x00
LDI R26, 0x00
LDI R25, 0x00
LDI R24, 0x00

;; End Initialization of R0 - R31 --------

CALL FFUNAE


start:  
	rjmp start

;;this is the mode 
FFUNAE:
;;AE mode for the Sli-light 8 bit.
CALL FFUN3A
CALL FFUNKEY
CALL FFUNAD
CALL FFUNM
CALL FFUNKEY

RET

;;this is the key absorption part in the mode
FFUNKEY:

PUSH R28                ;xor with key0 

LDI R28,0x00
EOR R23,R28
LDI R28,0x00
EOR R22,R28
LDI R28,0x00
EOR R21,R28
LDI R28,0x00
EOR R20,R28

LDI R28,0x00
EOR R7,R28
LDI R28,0x00
EOR R6,R28
LDI R28,0x00
EOR R5,R28
LDI R28,0x00
EOR R4,R28

POP R28

CALL FFUN3A

PUSH R28

LDI R28,0x00     ;xor with key1
EOR R23,R28
LDI R28,0x00
EOR R22,R28
LDI R28,0x00
EOR R21,R28
LDI R28,0x00
EOR R20,R28

LDI R28,0x00
EOR R7,R28
LDI R28,0x00
EOR R6,R28
LDI R28,0x00
EOR R5,R28
LDI R28,0x00
EOR R4,R28

POP R28

CALL FFUN3A

RET


;;this is the AD absorption part in the mode
FFUNAD:

PUSH R28

LDI R28,0x00     ;xor with key1
EOR R23,R28
LDI R28,0x00
EOR R22,R28
LDI R28,0x00
EOR R21,R28
LDI R28,0x00
EOR R20,R28

LDI R28,0x00
EOR R7,R28
LDI R28,0x00
EOR R6,R28
LDI R28,0x00
EOR R5,R28
LDI R28,0x00
EOR R4,R28

LDI R28,0x01     ;;Domain seperator
EOR R0,R28

POP R28

CALL FFUN3B

PUSH R28

LDI R28,0x00     ;xor with key1
EOR R23,R28
LDI R28,0x00
EOR R22,R28
LDI R28,0x00
EOR R21,R28
LDI R28,0x00
EOR R20,R28

LDI R28,0x00
EOR R7,R28
LDI R28,0x00
EOR R6,R28
LDI R28,0x00
EOR R5,R28
LDI R28,0x00
EOR R4,R28

LDI R28,0x01   ;;Domain seperator
EOR R0,R28

POP R28

CALL FFUN3B

RET


;;this is the message absorption part in the mode 
FFUNM:

PUSH R26
PUSH R27

LDI R26, 0x00
LDI R27, 0x10

STS $51B, R26  ;Save R26 to the Mem location $51b
STS $51C, R27  ;Save R27 to the Mem location $51c

WHILM:	CP R26, R27 ; Compare n(START at 0) with limit
		BRSH NEXTM
		
		PUSH R28             ;xor with Ms
		LDI R28,0x00     
		EOR R23,R28
		LDI R28,0x00
		EOR R22,R28
		LDI R28,0x00
		EOR R21,R28
		LDI R28,0x00
		EOR R20,R28

		LDI R28,0x00
		EOR R7,R28
		LDI R28,0x00
		EOR R6,R28
		LDI R28,0x00
		EOR R5,R28
		LDI R28,0x00
		EOR R4,R28


		LDI R28,0x02   ;;Domain seperator
		EOR R0,R28

		POP R28         ;end xor with Ms


		POP R27    ;;recover R27 R26 
		POP R26

		CALL FFUN3B

		PUSH R26 ;; begin one level operation in figure 2, pass r0 - r31 in
		PUSH R27

		LDS R26, $51B
		inc R26 ; n++
		STS $51B, R26

		LDS R27, $51C

		rjmp WHILM ; Go back to beginning of WHILE loop
NEXTM:

		POP R27
		POP R26

RET


;;this is permutation box part 1
FFUN3A:
;; Begin: initialization the pointer (516, 515) for the (t,t') in data memory--------
PUSH R26
LDI R26, 0x05
STS $516, R26
LDI R26, 0x21
STS $515, R26
POP R26
;; End: initialization the pointer for the (t,t') in data memory--------

;; Begin: initialization the pointer (519, 518) for the (SC, SC') in data memory--------
PUSH R26
LDI R26, 0x06
STS $519, R26
LDI R26, 0x21
STS $518, R26
POP R26
;; End: initialization the pointer for the (SC, SC') in data memory--------


PUSH R27
PUSH R12
PUSH R13
LDI R27, 0x00
STS $512, R27
MOV R12, R27

LDI R27, 0x12   ;; if change this, you have also change the value in the following loop
MOV R13 ,R27

WHIL5:	CP R12, R13 ; Compare n(START at 0) with limit(=5)
		BRSH NEXTD5
		
		POP R13
		POP R12
		POP R27
		CALL FFUN2
		PUSH R27   
		PUSH R12
		PUSH R13

		LDS R12, $512
		inc R12 ; n++
		STS $512, R12

		LDI R27, 0x12
		MOV R13 ,R27

		rjmp WHIL5
NEXTD5:
POP R13
POP R12
POP R27
RET

;;this is permutation box part 2
FFUN3B:
;; Begin: initialization the pointer (516, 515) for the (t,t') in data memory--------
PUSH R26
LDI R26, 0x05 ;; begin load i for (t, t')
STS $516, R26
LDI R26, 0x21
STS $515, R26 ;; end load i for (t, t')
POP R26
;; End: initialization the pointer for the (t,t') in data memory--------

;; Begin: initialization the pointer (519, 518) for the (SC, SC') in data memory--------
PUSH R26
LDI R26, 0x06 ;; begin load i for (SC, SC')
STS $519, R26
LDI R26, 0x21
STS $518, R26 ;; end load i for (SC, SC')
POP R26
;; End: initialization the pointer for the (SC, SC') in data memory--------


PUSH R27   ;; temp value
PUSH R12
PUSH R13
LDI R27, 0x00 ;; begin: reset WHILE LOOP i to be 0
STS $512, R27 ;; end: reset WHILE LOOP i to be 0
MOV R12, R27

LDI R27, 0x09
MOV R13 ,R27

WHIL5B:	CP R12, R13 ; Compare n(START at 0) with limit(=5)
		BRSH NEXTD5B
		
		POP R13 ;; begin one level operation in figure 2, pass r0 - r31 in
		POP R12
		POP R27
		CALL FFUN2
		PUSH R27   
		PUSH R12
		PUSH R13 ;; end one level operation in figure 2, output r0 - r31, and moved two pointers to the next and next 

		LDS R12, $512
		inc R12 ; n++
		STS $512, R12

		LDI R27, 0x09
		MOV R13 ,R27

		rjmp WHIL5B ; Go back to beginning of WHILE loop
NEXTD5B:
POP R13
POP R12
POP R27
RET


;;this is permutation round 
FFUN2:

PUSH R14
PUSH R27  ;; Begin: load (t, t') from data memory to R14
PUSH R26
LDS R27, $516 ;; load 
LDS R26, $515
ld R14, X
inc R26
STS $515, R26
POP R26
POP R27 ;; End: load from data memory

CALL FFUN ;send r14 and r23-r16 to the FFUN
POP R14

; get SC
PUSH R15
PUSH R27  ;; Begin: load (t, t') from data memory to R14
PUSH R26
LDS R27, $519 ;; load 
LDS R26, $518
ld R15, X
inc R26
STS $518, R26
POP R26
POP R27 ;; End: load from data memory

;; Begin xor with Sc
PUSH R22
LDI R22, 0xff
EOR R31, R22
EOR R30, R22
EOR R29, R22
EOR R28, R22
EOR R27, R22
EOR R26, R22
EOR R25, R22
EOR R24, R15
POP R22
POP R15
;; End xor with Sc

;; Begin xor with xor r23-r22 which is "1"
EOR R31, R23
EOR R30, R22
EOR R29, R21
EOR R28, R20
EOR R27, R19
EOR R26, R18
EOR R25, R17
EOR R24, R16
;; End xor with xor r31-r24 which is "1"


PUSH R23  ;3
PUSH R22
PUSH R21
PUSH R20
PUSH R19
PUSH R18
PUSH R17
PUSH R16

MOV R23, R7
MOV R22, R6
MOV R21, R5
MOV R20, R4
MOV R19, R3
MOV R18, R2
MOV R17, R1
MOV R16, R0

PUSH R14
PUSH R27
PUSH R26
LDS R27, $516
LDS R26, $515
ld R14, X
inc R26
STS $515, R26
POP R26
POP R27

CALL FFUN ;send r14 and r23-r16 to the FFUN
POP R14

; get SC
PUSH R24
PUSH R27 
PUSH R26
LDS R27, $519
LDS R26, $518
ld R24, X
inc R26
STS $518, R26
POP R26
POP R27

;; Begin xor with Sc
PUSH R25
LDI R25, 0xff
EOR R15, R25
EOR R14, R25
EOR R13, R25
EOR R12, R25
EOR R11, R25
EOR R10, R25
EOR R9, R25
EOR R8, R24
POP R25
POP R24
;; End xor with Sc


EOR R15, R23
EOR R14, R22
EOR R13, R21
EOR R12, R20
EOR R11, R19
EOR R10, R18
EOR R9, R17
EOR R8, R16


MOV R7, R23 
MOV R6, R22
MOV R5, R21
MOV R4, R20
MOV R3, R19
MOV R2, R18
MOV R1, R17
MOV R0, R16

POP R16
POP R17
POP R18
POP R19
POP R20
POP R21
POP R22
POP R23




PUSH R31
PUSH R30
PUSH R29
PUSH R28
PUSH R27
PUSH R26
PUSH R25
PUSH R24

MOV R31, R23
MOV R30, R22
MOV R29, R21
MOV R28, R20
MOV R27, R19
MOV R26, R18
MOV R25, R17
MOV R24, R16

MOV R23, R15
MOV R22, R14
MOV R21, R13
MOV R20, R12
MOV R19, R11
MOV R18, R10
MOV R17, R9
MOV R16, R8

MOV R15, R7
MOV R14, R6
MOV R13, R5
MOV R12, R4
MOV R11, R3
MOV R10, R2
MOV R9, R1
MOV R8, R0

POP R0
POP R1
POP R2
POP R3
POP R4
POP R5
POP R6
POP R7

RET


;;this is Simeck box
FFUN:
PUSH R12
PUSH R13
PUSH R27

LDI R27, 8 
MOV R13, R27
LDI R27, 0
MOV R12, R27
WHIL2:	CP R12, R13
		BRSH NEXTB2
		call SimeckRF
		inc R12
		rjmp WHIL2
NEXTB2:

POP R27
POP R13
POP R12
RET


SimeckRF:
PUSH R0
PUSH R1
PUSH R2
PUSH R3
PUSH R24
PUSH R25
PUSH R26
PUSH R27
PUSH R29
PUSH R31


MOV R3,R23
MOV R2,R22
MOV R1,R21
MOV R0,R20

LDI R29, 5 ;SET a
CALL LCircularShift 

MOV R27, R23
MOV R26, R22
MOV R25, R21
MOV R24, R20

MOV R23, R3
MOV R22, R2
MOV R21, R1
MOV R20, R0

LDI R29, 0 ;SET b
CALL LCircularShift


AND R27, R23
AND R26, R22
AND R25, R21
AND R24, R20

MOV R23, R3
MOV R22, R2
MOV R21, R1
MOV R20, R0

LDI R29, 1 ;SET c
CALL LCircularShift 

EOR R23, R27
EOR R22, R26
EOR R21, R25
EOR R20, R24

EOR R23, R19
EOR R22, R18
EOR R21, R17
EOR R20, R16

;BEGIN XOR rc0
SBR R31, 0xFF 
EOR R23, R31
EOR R22, R31
EOR R21, R31
LDI R31, 1
AND R31, R14
SBR R31, 0xFE
EOR R20, R31
LSR R14
CLC
;END XOR rc0

MOV R19, R3
MOV R18, R2
MOV R17, R1
MOV R16, R0

POP R31
POP R29
POP R27
POP R26
POP R25
POP R24
POP R3
POP R2
POP R1
POP R0
RET


;;this is circular shift
LCircularShift:
	PUSH R15
	PUSH R30
	PUSH R31


	LDI R30, 0
	MOV R15, R30
	WHIL:	CP R15, R29
			BRSH NEXTA
			LDI R30, 0
			CLC
			ROL R20
			BRCC carry1
			SBR R30, 1
			CLC
			carry1:
			ROL R21
			BRCC carry2
			SBR R30, 2
			CLC
			carry2: 
			ROL R22
			BRCC carry3
			SBR R30, 4
			CLC
			carry3:
			ROL R23
			BRCC carry4
			SBR R30, 8
			CLC
			carry4:
			LDI R31, 8
			AND R31, R30 
			CPI R31, 1
			BRLO NEXT1
			SBR R20, 1 
			NEXT1:   


			LDI R31, 1
			AND R31, R30 ; 
			CPI R31, 1 
			BRLO NEXT2 
			SBR R21, 1
			NEXT2:   

			LDI R31, 2
			AND R31, R30 
			CPI R31, 1 
			BRLO NEXT3 
			SBR R22, 1
			NEXT3:   


			LDI R31, 4
			AND R31, R30 
			CPI R31, 1 
			BRLO NEXT4 
			SBR R23, 1
			NEXT4:   
			CLC
			inc R15
			rjmp WHIL
	NEXTA:
	POP R31
	POP R30
	POP R15
RET


