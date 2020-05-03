	.file	"present.c"
	.intel_syntax noprefix
	.text
	.globl	S
	.type	S, @function
S:
.LFB0:
	.cfi_startproc
	mov	al, dil
	mov	BYTE PTR -16[rsp], 12
	mov	BYTE PTR -15[rsp], 5
	shr	al, 4
	mov	BYTE PTR -14[rsp], 6
	mov	BYTE PTR -13[rsp], 11
	and	eax, 15
	mov	BYTE PTR -12[rsp], 9
	mov	BYTE PTR -11[rsp], 0
	mov	BYTE PTR -10[rsp], 10
	mov	BYTE PTR -9[rsp], 13
	and	edi, 15
	mov	BYTE PTR -8[rsp], 3
	mov	BYTE PTR -7[rsp], 14
	mov	BYTE PTR -6[rsp], 15
	mov	BYTE PTR -5[rsp], 8
	mov	BYTE PTR -4[rsp], 4
	mov	BYTE PTR -3[rsp], 7
	mov	BYTE PTR -2[rsp], 1
	mov	BYTE PTR -1[rsp], 2
	movzx	eax, BYTE PTR -16[rsp+rax]
	sal	eax, 4
	or	al, BYTE PTR -16[rsp+rdi]
	ret
	.cfi_endproc
.LFE0:
	.size	S, .-S
	.globl	present
	.type	present, @function
present:
.LFB1:
	.cfi_startproc
	push	r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	push	rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	xor	r10d, r10d
	push	rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	movabs	rbx, 13510936322113536
	sub	rsp, 16
	.cfi_def_cfa_offset 48
	mov	rdx, QWORD PTR [rdi]
	mov	r9, QWORD PTR 8[rdi]
	mov	r8, QWORD PTR [rsi]
	lea	r11, 8[rsp]
	bswap	rdx
	bswap	r9
	bswap	r8
.L5:
	xor	r8, rdx
	xor	ecx, ecx
	mov	QWORD PTR 8[rsp], r8
.L3:
	movzx	edi, BYTE PTR [rcx+r11]
	call	S
	mov	BYTE PTR [rcx+r11], al
	inc	rcx
	cmp	rcx, 8
	jne	.L3
  
	mov	r12, QWORD PTR 8[rsp]    ; p
	xor	r8d, r8d                 ; t = 0
	mov	rax, rbx                 ; r = 0x0030002000100000;
	xor	ebp, ebp                 ; j = 0;
.L4:
	mov	cl, bpl                  ; cl = j
	mov	rdi, r12                 ; rdi = p
	inc	rbp                      ; j++
	shr	rdi, cl                  ; rdi >>= j
	mov	cl, al                   ; cl = (r & 255)
	inc	rax                      ; r++
	and	edi, 1                   ; rdi &= 1 
	ror	rax, 16                  ; r = R(r, 16)
	sal	rdi, cl                  ; rdi <<= cl
	or	r8, rdi                  ; t |= rdi
	cmp	rbp, 64                  ; j<64
	jne	.L4
  
	mov	rcx, rdx
	sal	rdx, 61
	mov	rax, r9
	mov	rdi, rdx
	shr	r9, 3
	sal	rax, 61
	or	rdi, r9
	shr	rcx, 3
	rol	rdi, 8
	or	rcx, rax
	mov	QWORD PTR 8[rsp], rdi
	movzx	edi, dil
	call	S
	mov	BYTE PTR 8[rsp], al
	mov	rdx, QWORD PTR 8[rsp]
	inc	r10
	mov	rdi, r10
	mov	r9, r10
	shr	rdi, 2
	sal	r9, 62
	ror	rdx, 8
	xor	r9, rcx
	xor	rdx, rdi
	cmp	r10, 31
	jne	.L5
	xor	rdx, r8
	bswap	rdx
	mov	QWORD PTR [rsi], rdx
	add	rsp, 16
	.cfi_def_cfa_offset 32
	pop	rbx
	.cfi_def_cfa_offset 24
	pop	rbp
	.cfi_def_cfa_offset 16
	pop	r12
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE1:
	.size	present, .-present
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
