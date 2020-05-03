		DEVICE	ZXSPECTRUM48

		ORG	32768

TestBegin:	EQU	$

		di
		xor	a
		out	(254), a
		ld	sp, TestBegin
Loop:
		ld	hl, Picture1
		ld	de, 16384
		call	Unpack
		call	SomeWait

		ld	hl, Picture2
		ld	de, 16384
		call	Unpack
		call	SomeWait

		ld	hl, Picture3
		ld	de, 16384
		call	Unpack
		call	SomeWait
		jr	Loop

SomeWait:	xor	a
		in	a, (254)
		cpl
		and	31
		jr	z, SomeWait
		ret

Unpack:		MODULE	UNPACK
;		INCLUDE	"aplib\aplib156b.asm"
		INCLUDE	"aplib\aplib197b.asm"
;		INCLUDE	"aplib\aplib227b.asm"
;		INCLUDE	"aplib\aplib247b.asm"
		ENDMODULE

Picture1:	INCBIN	"pic1.appack"
Picture2:	INCBIN	"pic2.appack"
Picture3:	INCBIN	"pic3.appack"

TestEnd:	EQU	$

		SAVESNA	"example_aplib.sna", TestBegin

