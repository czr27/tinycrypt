	.file	"t2.c"
	.intel_syntax noprefix
	.text
	.p2align 4,,15
	.globl	Noekeon
	.type	Noekeon, @function
Noekeon:
.LFB0:
	.cfi_startproc
	mov	edx, -128
	.p2align 4,,10
	.p2align 3
.L2:
	mov	ecx, edx
	add	edx, edx
	shr	cl, 7
	lea	eax, [rcx+rcx]
	add	eax, ecx
	lea	ecx, 0[0+rax*8]
	add	eax, ecx
	xor	edx, eax
	cmp	dl, -44
	jne	.L2
	rep ret
	.cfi_endproc
.LFE0:
	.size	Noekeon, .-Noekeon
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
