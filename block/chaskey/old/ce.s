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
	.file	"ce.c"
	.text
	.align	2
	.global	chaskey
	.type	chaskey, %function
chaskey:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	sub	r0, r0, #4
	sub	r4, r1, #4
	add	r5, r1, #12
	mov	ip, r0
	mov	r3, r4
.L2:
	ldr	lr, [r3, #4]!
	ldr	r2, [ip, #4]!
	cmp	r3, r5
	eor	r2, r2, lr
	str	r2, [r3]
	bne	.L2
	ldr	lr, [r1]
	ldr	ip, [r1, #4]
	ldr	r3, [r1, #8]
	ldr	r2, [r1, #12]
	mov	r6, #16
.L3:
	add	lr, lr, ip
	eor	ip, lr, ip, ror #27
	add	r3, r3, r2
	eor	r2, r3, r2, ror #24
	add	r3, ip, r3
	add	lr, r2, lr, ror #16
	subs	r6, r6, #1
	eor	ip, r3, ip, ror #25
	eor	r2, lr, r2, ror #19
	mov	r3, r3, ror #16
	bne	.L3
	str	lr, [r1]
	str	ip, [r1, #4]
	str	r3, [r1, #8]
	str	r2, [r1, #12]
.L4:
	ldr	r2, [r4, #4]!
	ldr	r3, [r0, #4]!
	cmp	r4, r5
	eor	r3, r3, r2
	str	r3, [r4]
	bne	.L4
	ldmfd	sp!, {r4, r5, r6, pc}
	.size	chaskey, .-chaskey
	.ident	"GCC: (Raspbian 4.9.2-10) 4.9.2"
	.section	.note.GNU-stack,"",%progbits
