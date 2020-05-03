	.arch armv6
	.eabi_attribute 27, 3
	.eabi_attribute 28, 1
	.fpu vfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 4
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"xoodoo.c"
	.text
	.align	2
	.global	xoodoo
	.type	xoodoo, %function
xoodoo:
#define x0 r0 
	@ args = 0, pretend = 0, frame = 64
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	mov	ip, r0
	ldr	r4, .L12
	sub	sp, sp, #64
	add	lr, sp, #16
	ldmia	r4!, {r0, r1, r2, r3}
	stmia	lr!, {r0, r1, r2, r3}
	ldmia	r4!, {r0, r1, r2, r3}
	stmia	lr!, {r0, r1, r2, r3}
	ldmia	r4, {r0, r1, r2, r3}
	add	r4, sp, #16
	stmia	lr, {r0, r1, r2, r3}
	mov	lr, #0
.L2:
	mov	r1, ip
	mov	r0, ip
	mov	r5, #0
.L3:
	ldr	r2, [r0, #16]
	ldr	r3, [r0]
	add	r0, r0, #4
	eor	r3, r3, r2
	ldr	r2, [r0, #28]
	eor	r3, r3, r2
	mov	r3, r3, ror #18
	eor	r3, r3, r3, ror #9
	str	r3, [sp, r5, asl #2]
	add	r5, r5, #1
	cmp	r5, #4
	bne	.L3
	sub	r0, ip, #4
	mov	r2, #0
.L4:
	sub	r3, r2, #1
	and	r3, r3, #3
	add	r5, sp, #64
	add	r3, r5, r3, asl #2
	ldr	r5, [r0, #4]!
	ldr	r3, [r3, #-64]
	add	r2, r2, #1
	eor	r3, r3, r5
	cmp	r2, #12
	str	r3, [r0]
	bne	.L4
	ldr	r2, [ip, #16]
	ldr	r3, [ip, #28]
	mov	r0, #0
	str	r3, [ip, #16]
	ldr	r3, [ip, #20]
	str	r2, [ip, #20]
	ldr	r2, [ip, #24]
	str	r3, [ip, #24]
	str	r2, [ip, #28]
	ldr	r3, [r4, lr, asl #2]
	ldr	r2, [ip]
	eor	r3, r3, r2
	str	r3, [ip]
.L5:
	ldr	r2, [r1, #32]
	ldr	r6, [r1, #16]
	ldr	r5, [r1]
	mov	r3, r2, ror #21
	bic	r2, r6, r5
	eor	r2, r2, r3
	add	r0, r0, #1
	mov	r2, r2, ror #24
	str	r2, [r1, #32]
	bic	r2, r5, r3
	eor	r2, r2, r6
	bic	r3, r3, r6
	mov	r2, r2, ror #31
	eor	r3, r3, r5
	cmp	r0, #4
	str	r2, [r1, #16]
	str	r3, [r1], #4
	bne	.L5
	ldr	r3, [ip, #32]
	ldr	r2, [ip, #40]
	add	lr, lr, #1
	str	r2, [ip, #32]
	str	r3, [ip, #40]
	ldr	r2, [ip, #44]
	ldr	r3, [ip, #36]
	cmp	lr, #12
	str	r2, [ip, #36]
	str	r3, [ip, #44]
	bne	.L2
	add	sp, sp, #64
	@ sp needed
	ldmfd	sp!, {r4, r5, r6, pc}
.L13:
	.align	2
.L12:
	.word	.LANCHOR0
	.size	xoodoo, .-xoodoo
	.section	.rodata
	.align	2
.LANCHOR0 = . + 0
.LC0:
	.word	88
	.word	56
	.word	960
	.word	208
	.word	288
	.word	20
	.word	96
	.word	44
	.word	896
	.word	240
	.word	416
	.word	18
	.ident	"GCC: (Raspbian 4.9.2-10) 4.9.2"
	.section	.note.GNU-stack,"",%progbits
