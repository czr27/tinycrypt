	.arch armv8-a
	.file	"rc4.c"
	.text
	.align	2
	.global	RC4_set_key
	.type	RC4_set_key, %function
RC4_set_key:
	mov	x3, 0
.L2:
	add	x4, x0, x3
	strb	w3, [x4, 8]
	add	x3, x3, 1
	cmp	x3, 256
	bne	.L2
	mov	x3, 0
	mov	w4, 0
	stp	wzr, wzr, [x0]
.L3:
	udiv	w5, w3, w1
	add	x7, x0, x3
	ldrb	w6, [x7, 8]
	msub	w5, w5, w1, w3
	add	x3, x3, 1
	cmp	x3, 256
	ldrb	w5, [x2, x5]
	add	w5, w5, w6
	add	w4, w5, w4
	and	w4, w4, 255
	add	x5, x0, x4, uxtb
	ldrb	w8, [x5, 8]
	strb	w8, [x7, 8]
	strb	w6, [x5, 8]
	bne	.L3
	ret
	.size	RC4_set_key, .-RC4_set_key
	.align	2
	.global	RC4
	.type	RC4, %function
RC4:
	ldrb	w7, [x0]
	uxtw	x10, w1
	ldrb	w6, [x0, 4]
	mov	x8, 0
.L7:
	cmp	x10, x8
	add	w4, w7, w8
	uxtb	w4, w4
	bne	.L8
	add	w7, w7, w1
	uxtb	w7, w7
	stp	w7, w6, [x0]
	ret
.L8:
	add	w4, w4, 1
	add	x4, x0, x4, uxtb
	ldrb	w5, [x4, 8]
	add	w6, w6, w5
	uxtb	w6, w6
	add	x9, x0, x6, uxtb
	ldrb	w11, [x9, 8]
	strb	w11, [x4, 8]
	strb	w5, [x9, 8]
	ldrb	w4, [x4, 8]
	add	w5, w5, w4
	add	x5, x0, x5, uxtb
	ldrb	w4, [x5, 8]
	ldrb	w5, [x2, x8]
	eor	w4, w4, w5
	strb	w4, [x3, x8]
	add	x8, x8, 1
	b	.L7
	.size	RC4, .-RC4
	.ident	"GCC: (Debian 6.3.0-18) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
