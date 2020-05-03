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
		INCLUDE	"pletter\unpletter5.asm"
		ENDMODULE

Picture1:	INCBIN	"pic1.plet5"
Picture2:	INCBIN	"pic2.plet5"
Picture3:	INCBIN	"pic3.plet5"

TestEnd:	EQU	$

		SAVESNA	"example_pletter.sna", TestBegin

