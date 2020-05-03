	.file	"hbox.c"
	.intel_syntax noprefix
	.text
	.globl	H
	.type	H, @function
H:
.LFB0:
	.cfi_startproc
	xor	eax, eax
	cmp	dil, 10
	mov	dl, dil
	je	.L1
	lea	eax, 1[rdi]
	cmp	dil, 9
	cmovbe	edx, eax
	mov	al, 29
	xor	esi, esi
	movzx	ecx, dl
.L4:
	cmp	esi, ecx
	jge	.L1
	mov	edi, 116
.L5:
	mov	dl, al
	shr	al
	and	edx, 99
	mov	r8b, dl
	shr	r8b
	xor	edx, r8d
	mov	r8b, dl
	shr	r8b, 2
	xor	edx, r8d
	mov	r8b, dl
	shr	r8b, 4
	xor	edx, r8d
	sal	edx, 7
	or	eax, edx
	dec	edi
	jne	.L5
	inc	esi
	jmp	.L4
.L1:
	ret
	.cfi_endproc
.LFE0:
	.size	H, .-H
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
