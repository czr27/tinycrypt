	.file	"shax.c"
	.intel_syntax noprefix
	.section	.rodata
	.align 32
.LC0:
	.long	1116352408
	.long	1899447441
	.long	-1245643825
	.long	-373957723
	.long	961987163
	.long	1508970993
	.long	-1841331548
	.long	-1424204075
	.long	-670586216
	.long	310598401
	.long	607225278
	.long	1426881987
	.long	1925078388
	.long	-2132889090
	.long	-1680079193
	.long	-1046744716
	.long	-459576895
	.long	-272742522
	.long	264347078
	.long	604807628
	.long	770255983
	.long	1249150122
	.long	1555081692
	.long	1996064986
	.long	-1740746414
	.long	-1473132947
	.long	-1341970488
	.long	-1084653625
	.long	-958395405
	.long	-710438585
	.long	113926993
	.long	338241895
	.long	666307205
	.long	773529912
	.long	1294757372
	.long	1396182291
	.long	1695183700
	.long	1986661051
	.long	-2117940946
	.long	-1838011259
	.long	-1564481375
	.long	-1474664885
	.long	-1035236496
	.long	-949202525
	.long	-778901479
	.long	-694614492
	.long	-200395387
	.long	275423344
	.long	430227734
	.long	506948616
	.long	659060556
	.long	883997877
	.long	958139571
	.long	1322822218
	.long	1537002063
	.long	1747873779
	.long	1955562222
	.long	2024104815
	.long	-2067236844
	.long	-1933114872
	.long	-1866530822
	.long	-1538233109
	.long	-1090935817
	.long	-965641998
	.text
	.globl	sha256_compress
	.type	sha256_compress, @function
sha256_compress:
.LFB0:
	.cfi_startproc
	push	r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	push	r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	mov	r10, rdi
	push	r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	push	r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	lea	rsi, .LC0[rip]
	push	rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	push	rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	mov	ecx, 64
	xor	eax, eax
	sub	rsp, 424
	.cfi_def_cfa_offset 480
	lea	rdi, 168[rsp]
	lea	r13, 168[rsp]
	rep movsd
	lea	rsi, -88[rsp]
.L2:
	mov	edx, DWORD PTR 32[r10+rax]
	add	rax, 4
	bswap	edx
	mov	DWORD PTR -4[rax+rsi], edx
	cmp	rax, 64
	jne	.L2
	lea	r11, 56[rsi]
	lea	r9, 4[rsi]
	lea	rdi, 64[rsi]
	lea	r8, 36[rsi]
	xor	ecx, ecx
.L3:
	mov	eax, DWORD PTR [r11+rcx]
	mov	ebx, DWORD PTR [r9+rcx]
	mov	edx, eax
	mov	ebp, eax
	shr	eax, 10
	rol	ebp, 13
	rol	edx, 15
	xor	edx, ebp
	mov	ebp, ebx
	xor	edx, eax
	mov	eax, DWORD PTR [rsi+rcx]
	add	eax, DWORD PTR [r8+rcx]
	rol	ebp, 14
	add	edx, eax
	mov	eax, ebx
	shr	ebx, 3
	ror	eax, 7
	xor	eax, ebp
	xor	eax, ebx
	add	eax, edx
	mov	DWORD PTR [rdi+rcx], eax
	add	rcx, 4
	cmp	rcx, 192
	jne	.L3
	xor	eax, eax
.L4:
	mov	edx, DWORD PTR [r10+rax]
	mov	DWORD PTR -120[rsp+rax], edx
	add	rax, 4
	cmp	rax, 32
	jne	.L4
	mov	ebp, DWORD PTR -120[rsp]
	mov	r15d, DWORD PTR -92[rsp]
	xor	r8d, r8d
	mov	ecx, DWORD PTR -104[rsp]
	mov	r11d, DWORD PTR -100[rsp]
	mov	ebx, DWORD PTR -96[rsp]
	mov	edi, DWORD PTR -116[rsp]
	mov	r9d, ebp
	mov	eax, ebp
	mov	esi, DWORD PTR -112[rsp]
	ror	eax, 13
	ror	r9d, 2
	mov	r14d, DWORD PTR -108[rsp]
	xor	r9d, eax
	mov	eax, ebp
	rol	eax, 10
	xor	r9d, eax
.L5:
	mov	edx, ecx
	mov	eax, ecx
	mov	r12d, r11d
	ror	eax, 11
	ror	edx, 6
	and	r12d, ecx
	xor	edx, eax
	mov	eax, ecx
	rol	eax, 7
	xor	edx, eax
	mov	eax, DWORD PTR 0[r13+r8]
	add	eax, DWORD PTR -88[rsp+r8]
	add	r8, 4
	add	edx, eax
	mov	eax, ecx
	not	eax
	and	eax, ebx
	xor	eax, r12d
	add	eax, edx
	mov	edx, esi
	add	eax, r15d
	xor	edx, edi
	mov	r15d, ebx
	lea	r12d, [rax+r14]
	mov	r14d, esi
	and	edx, ebp
	and	r14d, edi
	xor	edx, r14d
	mov	r14d, esi
	add	edx, r9d
	add	eax, edx
	cmp	r8, 256
	je	.L14
	mov	esi, edi
	mov	ebx, r11d
	mov	edi, eax
	mov	r11d, ecx
	mov	ecx, r12d
	jmp	.L5
.L14:
	mov	DWORD PTR -116[rsp], eax
	mov	DWORD PTR -92[rsp], ebx
	xor	eax, eax
	mov	DWORD PTR -104[rsp], r12d
	mov	DWORD PTR -100[rsp], ecx
	mov	DWORD PTR -96[rsp], r11d
	mov	DWORD PTR -112[rsp], edi
	mov	DWORD PTR -108[rsp], esi
.L6:
	mov	edx, DWORD PTR -120[rsp+rax]
	add	DWORD PTR [r10+rax], edx
	add	rax, 4
	cmp	rax, 32
	jne	.L6
	add	rsp, 424
	.cfi_def_cfa_offset 56
	pop	rbx
	.cfi_def_cfa_offset 48
	pop	rbp
	.cfi_def_cfa_offset 40
	pop	r12
	.cfi_def_cfa_offset 32
	pop	r13
	.cfi_def_cfa_offset 24
	pop	r14
	.cfi_def_cfa_offset 16
	pop	r15
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE0:
	.size	sha256_compress, .-sha256_compress
	.globl	sha256_init
	.type	sha256_init, @function
sha256_init:
.LFB1:
	.cfi_startproc
	mov	DWORD PTR [rdi], 1779033703
	mov	DWORD PTR 4[rdi], -1150833019
	mov	DWORD PTR 8[rdi], 1013904242
	mov	DWORD PTR 12[rdi], -1521486534
	mov	DWORD PTR 16[rdi], 1359893119
	mov	DWORD PTR 20[rdi], -1694144372
	mov	DWORD PTR 24[rdi], 528734635
	mov	DWORD PTR 28[rdi], 1541459225
	mov	QWORD PTR 104[rdi], 0
	ret
	.cfi_endproc
.LFE1:
	.size	sha256_init, .-sha256_init
	.globl	sha256_update
	.type	sha256_update, @function
sha256_update:
.LFB2:
	.cfi_startproc
	push	r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	push	rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	mov	edx, edx
	push	rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	mov	rcx, QWORD PTR 104[rdi]
	lea	r12, [rsi+rdx]
	mov	rbp, rdi
	mov	rbx, rsi
	mov	eax, ecx
	add	rcx, rdx
	and	eax, 63
	mov	QWORD PTR 104[rdi], rcx
.L17:
	cmp	rbx, r12
	je	.L21
	cmp	eax, 64
	jne	.L18
	mov	rdi, rbp
	call	sha256_compress
	add	QWORD PTR 96[rbp], 512
	xor	eax, eax
.L18:
	inc	rbx
	mov	cl, BYTE PTR -1[rbx]
	mov	edx, eax
	inc	eax
	mov	BYTE PTR 32[rbp+rdx], cl
	jmp	.L17
.L21:
	pop	rbx
	.cfi_def_cfa_offset 24
	pop	rbp
	.cfi_def_cfa_offset 16
	pop	r12
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE2:
	.size	sha256_update, .-sha256_update
	.globl	sha256_final
	.type	sha256_final, @function
sha256_final:
.LFB3:
	.cfi_startproc
	mov	eax, DWORD PTR 104[rsi]
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rdi
	push	rbx
	.cfi_def_cfa_offset 24
	.cfi_offset 3, -24
	mov	rbx, rsi
	and	eax, 63
	mov	edx, eax
.L23:
	mov	ecx, edx
	inc	edx
	cmp	edx, 64
	mov	BYTE PTR 32[rbx+rcx], 0
	jne	.L23
	mov	edx, eax
	cmp	eax, 55
	mov	BYTE PTR 32[rbx+rdx], -128
	ja	.L24
.L27:
	mov	rax, QWORD PTR 96[rbx]
	mov	rdi, rbx
	bswap	rax
	mov	QWORD PTR 88[rbx], rax
	call	sha256_compress
	xor	eax, eax
	jmp	.L25
.L24:
	mov	rdi, rbx
	call	sha256_compress
	xor	eax, eax
.L26:
	mov	DWORD PTR 32[rbx+rax], 0
	add	rax, 4
	cmp	rax, 64
	jne	.L26
	jmp	.L27
.L25:
	mov	edx, DWORD PTR [rbx+rax]
	bswap	edx
	mov	DWORD PTR 0[rbp+rax], edx
	add	rax, 4
	cmp	rax, 32
	jne	.L25
	pop	rbx
	.cfi_def_cfa_offset 16
	pop	rbp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE3:
	.size	sha256_final, .-sha256_final
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
