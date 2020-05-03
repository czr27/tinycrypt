;###
;### uncrunch.asm -- Standalone Pucrunch decompressor
;### Based on C64 code by Pasi Ojala
;### Ported to Z80 by Jussi Pitkänen <ccfg@pp.inet.fi>
;###
;### Thanks to Jeff Frohwein for his GB-Z80 port.
;###
;### Modified by Aprisobal <aprisobal@tut.by>: decompressor size decreased to 255 bytes
;### !Warning! You must use only apri_pucrunch version with this decompressor!

;## Decompress a pucrunched file.
;## In      : HL = source address
;##           DE = destination address
;## Destroy : AF, BC, DE, HL, AF', BC', DE', HL'
UNCRUNCH
	PUSH	DE			; destination pointer to 2nd register
	EXX				; set
	POP	DE
	EXX

	;INC	HL			; read the header self-modifying the
	;INC	HL			; parameters straight into the code
	;INC	HL			; skip useless data
	;INC	HL
	;INC	HL
	;INC	HL

	LD	A, (HL)			; starting escape
	INC	HL
	LD	(UESC+1), A

	;INC	HL			; skip useless data
	;INC	HL

	LD	A, (HL)			; number of escape bits
	INC	HL
	LD	(UESCB0+1), A
	LD	(UESCB1+1), A

	LD	B, A			; 8 - escape bits
	LD	A, 8
	SUB	B
	LD	(UNOESC+1), A

	LD	A, (HL)			; maxGamma + 1
	INC	HL
	LD	(UMG+1), A

	LD	B, A			; 8 - maxGamma
	LD	A, 9
	SUB	B
	LD	(ULONGRLE+1), a

	LD	A, (HL)			; (1 << maxGamma)
	INC	HL
	LD	(UMG1+1), A

	ADD	A, A			; (2 << maxGamma) - 1
	DEC	A
	LD	(UMG21+1), A

	LD	A, (HL)			; extra LZ77 position bits
	INC	HL
	LD	(UELZPB+1), A

	;INC	HL			; skip useless data
	;INC	HL

	LD	E, (HL)			; RLE table length
	LD	(URLET+1), HL		; RLE table pointer
	INC	HL
	LD	D, 0
	ADD	HL, DE

	LD	C, 128			; start decompression
	JR	ULOOP

UNEWESC
	LD	A, (UESC+1)		; save old escape code
	LD	D, A

UESCB0	LD	B, 2			; ** parameter
	XOR	A			; get new escape code
	CALL	UGETBITS
	LD	(UESC+1), A

	LD	A, D

UNOESC	LD	B, 6			; ** parameter
	CALL	UGETBITS		; get more bits to complete a byte

	EXX				; output the byte
	LD	(DE), A
	INC	DE
	EXX

ULOOP	XOR	A
UESCB1	LD	B, 2			; ** parameter
	CALL	UGETBITS		; get escape code
UESC	CP	0			; ** parameter
	JR	NZ, UNOESC

	CALL	UGET_GAMMA		; get length
	EXX
	LD	B, 0
	LD	C, A
	EXX

	CP	1
	JR	NZ, ULZ77		; LZ77

	XOR	A
	CALL	UGETBIT
	JR	NC, ULZ77_2		; 2-byte LZ77

	CALL	UGETBIT
	JR	NC, UNEWESC		; escaped literal byte

	CALL	UGET_GAMMA		; get length
	EXX
	LD	B, 1
	LD	C, A
	EXX

UMG1	CP	64			; ** parameter
	JR	C, UCHRCODE		; short RLE, get bytecode

ULONGRLE
	LD	B, 2			; ** parameter
	CALL	UGETBITS		; complete length LSB
	EX	AF, AF'

	CALL	UGET_GAMMA		; length MSB
	EXX
	LD	B, A
	EX	AF, AF'
	LD	C, A
	EXX

UCHRCODE
	CALL	UGET_GAMMA		; get byte to repeat

	PUSH	HL
URLET	LD	HL, 0			; ** parameter
	LD	D, 0
	LD	E, A
	ADD	HL, DE

	CP	32
	LD	A, (HL)
	POP	HL
	JR	C, UDORLE

	LD	A, E			; get 3 more bits to complete the
	LD	B, 3			; byte
	CALL	UGETBITS

UDORLE	EXX				; output the byte n times
	INC	C
UDORLEI	LD	(DE), A
	INC	DE
	DEC	C
	JR	NZ, UDORLEI
	DEC	B
	JR	NZ, UDORLEI
	EXX
	JR	ULOOP

ULZ77	CALL	UGET_GAMMA		; offset MSB
UMG21	CP	127			; ** parameter
	RET	Z			; EOF, return

	DEC	A			; (1...126 -> 0...125)
UELZPB	LD	B, 0			; ** parameter
	CALL	UGETBITS		; complete offset MSB

ULZ77_2	EX	AF, AF'
	LD	B, 8			; offset LSB
	CALL	UGETBITS
	CPL				; xor'ed by the compressor

	EXX				; combine them into offset
	LD	L, A
	EX	AF, AF'
	LD	H, A
	INC	HL

	XOR	A			; CF = 0

	PUSH	DE			; (current output position) - (offset)
	EX	DE, HL
	SBC	HL, DE
	POP	DE

	INC	BC

	LDIR				; copy
	EXX
	JP	ULOOP

;## Get a bit from the source stream.
;## Return  : CF = result
UGETBIT
	SLA	C			; shift next bit into CF
	RET	NZ
	LD	C, (HL)			; get next byte
	INC	HL			; increase source stream pointer
	RL	C			; shift next bit into CF, bit0 = 1
	RET

;## Get an Elias Gamma coded value from the source stream.
;## Return  : A = result
UGET_GAMMA
	LD	B, 1
UMG	LD	A, 7			; ** parameter
UGG1	CALL	UGETBIT			; get bits until 0-bit or max
	JR	NC, UGG2
	INC	B
	CP	B
	JR	NZ, UGG1
UGG2	LD	A, 1			; get the actual value
	DEC	B
	
;## Get multiple bits from the source stream.
;## In      : B = number of bits to get
;## Return  : A = result
UGETBITS
	DEC	B
	RET	M
	SLA	C			; shift next bit into CF
	JR	NZ, UGB1
	LD	C, (HL)			; get next byte
	INC	HL			; increase source stream pointer
	RL	C			; shift next bit into CF, bit0 = 1
UGB1	RLA				; rotate next bit into A
	JR	UGETBITS	
	
;ULEN	EQU $-UNCRUNCH

	;DISPLAY /D,ULEN
	