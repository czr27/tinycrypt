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
	.file	"chaskey.c"
	.text
	.align	2
	.global	chas_encrypt
	.type	chas_encrypt, %function
chas_encrypt:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, lr}
	sub	r1, r1, #4
	sub	lr, r2, #4
	add	r5, r2, #12
	mov	r4, r1
	mov	r3, lr
.L2:
	ldr	r6, [r3, #4]!
	ldr	ip, [r4, #4]!
	cmp	r3, r5
	eor	ip, ip, r6
	str	ip, [r3]
	bne	.L2
	mov	r4, #16
.L5:
	cmp	r0, #1
	ldmia	r2, {r3, r6}
	ldr	r7, [r2, #12]
	ldr	ip, [r2, #8]
	bne	.L3
	add	r3, r6, r3
	eor	r6, r3, r6, ror #27
	add	ip, r7, ip
	eor	r7, ip, r7, ror #24
	add	ip, r6, ip
	add	r3, r7, r3, ror #16
	eor	r6, ip, r6, ror #25
	str	r3, [r2]
	mov	ip, ip, ror #16
	eor	r3, r3, r7, ror #19
	str	r3, [r2, #12]
	str	r6, [r2, #4]
	str	ip, [r2, #8]
	b	.L4
.L3:
	eor	r7, r7, r3
	mov	ip, ip, ror #16
	eor	r6, r6, ip
	mov	r7, r7, ror #13
	rsb	r3, r7, r3
	mov	r6, r6, ror #7
	rsb	ip, r6, ip
	mov	r3, r3, ror #16
	eor	r8, ip, r7
	eor	r6, r6, r3
	mov	r8, r8, ror #8
	mov	r6, r6, ror #5
	rsb	ip, r8, ip
	rsb	r3, r6, r3
	str	r8, [r2, #12]
	str	ip, [r2, #8]
	str	r6, [r2, #4]
	str	r3, [r2]
.L4:
	subs	r4, r4, #1
	bne	.L5
.L6:
	ldr	r2, [lr, #4]!
	ldr	r3, [r1, #4]!
	cmp	lr, r5
	eor	r3, r3, r2
	str	r3, [lr]
	bne	.L6
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
	.size	chas_encrypt, .-chas_encrypt
	.ident	"GCC: (Raspbian 4.9.2-10) 4.9.2"
	.section	.note.GNU-stack,"",%progbits
