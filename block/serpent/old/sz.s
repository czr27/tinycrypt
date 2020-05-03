	.file	"sz.c"
	.intel_syntax noprefix
	.section	.rodata
	.align 32
.LC0:
	.byte	-125
	.byte	31
	.byte	106
	.byte	-75
	.byte	-34
	.byte	36
	.byte	7
	.byte	-55
	.byte	-49
	.byte	114
	.byte	9
	.byte	-91
	.byte	-79
	.byte	-114
	.byte	-42
	.byte	67
	.byte	104
	.byte	-105
	.byte	-61
	.byte	-6
	.byte	29
	.byte	78
	.byte	-80
	.byte	37
	.byte	-16
	.byte	-117
	.byte	-100
	.byte	54
	.byte	29
	.byte	66
	.byte	122
	.byte	-27
	.byte	-15
	.byte	56
	.byte	12
	.byte	107
	.byte	82
	.byte	-92
	.byte	-23
	.byte	-41
	.byte	95
	.byte	-78
	.byte	-92
	.byte	-55
	.byte	48
	.byte	-114
	.byte	109
	.byte	23
	.byte	39
	.byte	92
	.byte	72
	.byte	-74
	.byte	-98
	.byte	-15
	.byte	61
	.byte	10
	.byte	-47
	.byte	15
	.byte	-114
	.byte	-78
	.byte	71
	.byte	-84
	.byte	57
	.byte	101
	.text
	.globl	subbytes
	.type	subbytes, @function
subbytes:
.LFB0:
	.cfi_startproc
	mov	edx, esi
	mov	r8, rdi
	lea	rsi, .LC0[rip]
	lea	rdi, -64[rsp]
	mov	ecx, 16
	and	edx, 7
	rep movsd
	lea	rcx, -96[rsp]
	lea	r9, [rsp+rdx*8]
	xor	eax, eax
	lea	rsi, 1[rcx]
.L2:
	mov	dl, al
	shr	dl
	and	edx, 127
	mov	dl, BYTE PTR -64[rdx+r9]
	mov	dil, dl
	shr	dl, 4
	and	edi, 15
	mov	BYTE PTR [rax+rcx], dil
	mov	BYTE PTR [rsi+rax], dl
	add	rax, 2
	cmp	rax, 16
	jne	.L2
	lea	rax, -80[rsp]
	xor	esi, esi
.L5:
	mov	cl, BYTE PTR [rsi+rax]
	xor	edi, edi
.L4:
	mov	rdx, rdi
	shr	cl
	inc	edi
	and	edx, 3
	lea	r9, [r8+rdx*4]
	mov	edx, DWORD PTR [r9]
	mov	r10d, edx
	and	edx, 1
	sal	edx, 7
	shr	r10d
	or	ecx, edx
	cmp	dil, 8
	mov	DWORD PTR [r9], r10d
	jne	.L4
	mov	BYTE PTR [rax+rsi], cl
	inc	rsi
	cmp	rsi, 16
	jne	.L5
	xor	edx, edx
.L7:
	mov	sil, BYTE PTR [rax+rdx]
	mov	cl, sil
	and	esi, 15
	shr	cl, 4
	and	ecx, 15
	movzx	ecx, BYTE PTR -96[rsp+rcx]
	sal	ecx, 4
	or	cl, BYTE PTR -96[rsp+rsi]
	mov	BYTE PTR [rax+rdx], cl
	inc	rdx
	cmp	rdx, 16
	jne	.L7
	xor	edx, edx
.L10:
	mov	r9d, DWORD PTR [rax+rdx]
	xor	edi, edi
.L9:
	mov	rcx, rdi
	mov	sil, r9b
	inc	edi
	and	ecx, 3
	and	esi, 1
	shr	r9d
	lea	r10, [r8+rcx*4]
	movzx	esi, sil
	sal	esi, 31
	mov	ecx, DWORD PTR [r10]
	shr	ecx
	or	ecx, esi
	cmp	dil, 32
	mov	DWORD PTR [r10], ecx
	jne	.L9
	mov	DWORD PTR [rax+rdx], r9d
	add	rdx, 4
	cmp	rdx, 16
	jne	.L10
	ret
	.cfi_endproc
.LFE0:
	.size	subbytes, .-subbytes
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC1:
	.string	"K:%x\n"
	.text
	.globl	serpent
	.type	serpent, @function
serpent:
.LFB1:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	push	rbx
	.cfi_def_cfa_offset 24
	.cfi_offset 3, -24
	xor	eax, eax
	mov	rbx, rsi
	sub	rsp, 72
	.cfi_def_cfa_offset 96
	lea	rbp, 32[rsp]
	mov	QWORD PTR 8[rsp], rdi
.L21:
	mov	dl, BYTE PTR 8[rsp+rax]
	inc	rax
	mov	BYTE PTR -1[rax+rbp], dl
	cmp	rax, 32
	jne	.L21
	mov	esi, DWORD PTR 32[rsp]
	lea	rdi, .LC1[rip]
	xor	eax, eax
	call	printf@PLT
	lea	rdi, 16[rsp]
	lea	rsi, 4[rbp]
	xor	ecx, ecx
.L23:
	mov	eax, DWORD PTR 32[rsp]
	xor	eax, DWORD PTR 44[rsp]
	lea	edx, 128[rcx]
	xor	eax, DWORD PTR 52[rsp]
	xor	eax, DWORD PTR 60[rsp]
	xor	eax, edx
	mov	edx, eax
	sal	eax, 11
	shr	edx, 21
	xor	eax, -1144141824
	xor	edx, 1265
	or	eax, edx
	xor	edx, edx
	mov	DWORD PTR [rdi+rcx*4], eax
.L22:
	mov	r8d, DWORD PTR [rsi+rdx]
	mov	DWORD PTR 0[rbp+rdx], r8d
	add	rdx, 4
	cmp	rdx, 28
	jne	.L22
	inc	rcx
	mov	DWORD PTR 60[rsp], eax
	cmp	rcx, 4
	jne	.L23
	mov	esi, -29
	call	subbytes
	mov	eax, DWORD PTR 16[rsp]
	xor	DWORD PTR [rbx], eax
	mov	eax, DWORD PTR 20[rsp]
	xor	DWORD PTR 4[rbx], eax
	mov	eax, DWORD PTR 24[rsp]
	xor	DWORD PTR 8[rbx], eax
	mov	eax, DWORD PTR 28[rsp]
	xor	DWORD PTR 12[rbx], eax
	add	rsp, 72
	.cfi_def_cfa_offset 24
	pop	rbx
	.cfi_def_cfa_offset 16
	pop	rbp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE1:
	.size	serpent, .-serpent
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
