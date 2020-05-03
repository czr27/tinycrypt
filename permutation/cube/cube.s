	.file	"cube.c"
	.intel_syntax noprefix
	.text
	.globl	cube2
	.type	cube2, @function
cube2:
.LFB0:
	.cfi_startproc
	push	rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	lea	rsi, 64[rdi]
	lea	r10, 128[rdi]
	mov	r9d, 16
	lea	r8, -64[rsp]
.L2:
	mov	rax, rsi
.L3:
	mov	edx, DWORD PTR -64[rax]
	add	DWORD PTR [rax], edx
	add	rax, 4
	cmp	r10, rax
	jne	.L3
	xor	edx, edx
.L4:
	mov	ecx, edx
	mov	r11d, DWORD PTR [rdi+rdx*4]
	inc	rdx
	xor	ecx, 8
	cmp	rdx, 16
	movsx	rcx, ecx
	mov	DWORD PTR -64[rsp+rcx*4], r11d
	jne	.L4
	xor	edx, edx
.L5:
	mov	ecx, DWORD PTR [rdx+r8]
	rol	ecx, 7
	mov	DWORD PTR [rdi+rdx], ecx
	add	rdx, 4
	cmp	rdx, 64
	jne	.L5
	mov	rdx, rdi
	mov	rcx, rdi
.L6:
	mov	r11d, DWORD PTR 64[rcx]
	xor	DWORD PTR [rcx], r11d
	add	rcx, 4
	cmp	rsi, rcx
	jne	.L6
	xor	ecx, ecx
.L7:
	mov	r11d, ecx
	mov	ebx, DWORD PTR 64[rdi+rcx*4]
	inc	rcx
	xor	r11d, 2
	cmp	rcx, 16
	movsx	r11, r11d
	mov	DWORD PTR -64[rsp+r11*4], ebx
	jne	.L7
	xor	ecx, ecx
.L8:
	mov	r11d, DWORD PTR [r8+rcx]
	mov	DWORD PTR 64[rdi+rcx], r11d
	add	rcx, 4
	cmp	rcx, 64
	jne	.L8
	mov	rcx, rsi
.L9:
	mov	r11d, DWORD PTR -64[rcx]
	add	DWORD PTR [rcx], r11d
	add	rcx, 4
	cmp	rax, rcx
	jne	.L9
	xor	eax, eax
.L10:
	mov	ecx, eax
	mov	r11d, DWORD PTR [rdi+rax*4]
	inc	rax
	xor	ecx, 4
	cmp	rax, 16
	movsx	rcx, ecx
	mov	DWORD PTR -64[rsp+rcx*4], r11d
	jne	.L10
	xor	eax, eax
.L11:
	mov	ecx, DWORD PTR [r8+rax]
	rol	ecx, 11
	mov	DWORD PTR [rdi+rax], ecx
	add	rax, 4
	cmp	rax, 64
	jne	.L11
.L12:
	mov	eax, DWORD PTR 64[rdx]
	xor	DWORD PTR [rdx], eax
	add	rdx, 4
	cmp	rsi, rdx
	jne	.L12
	xor	eax, eax
.L13:
	mov	edx, eax
	mov	ecx, DWORD PTR 64[rdi+rax*4]
	inc	rax
	xor	edx, 1
	cmp	rax, 16
	movsx	rdx, edx
	mov	DWORD PTR -64[rsp+rdx*4], ecx
	jne	.L13
	xor	eax, eax
.L14:
	mov	edx, DWORD PTR [r8+rax]
	mov	DWORD PTR 64[rdi+rax], edx
	add	rax, 4
	cmp	rax, 64
	jne	.L14
	dec	r9d
	jne	.L2
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE0:
	.size	cube2, .-cube2
	.globl	cube
	.type	cube, @function
cube:
.LFB1:
	.cfi_startproc
	push	rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	lea	r9, 64[rdi]
	lea	r11, 128[rdi]
	mov	esi, 16
	lea	r10, -64[rsp]
.L31:
	mov	eax, 8
.L40:
	lea	ecx, 17[rax]
	mov	rdx, r9
.L32:
	mov	r8d, DWORD PTR -64[rdx]
	add	DWORD PTR [rdx], r8d
	add	rdx, 4
	cmp	r11, rdx
	jne	.L32
	xor	edx, edx
.L33:
	mov	ebx, DWORD PTR [rdi+rdx*4]
	mov	r8d, eax
	xor	r8d, edx
	inc	rdx
	cmp	rdx, 16
	mov	DWORD PTR -64[rsp+r8*4], ebx
	jne	.L33
	xor	edx, edx
.L34:
	mov	r8d, DWORD PTR [rdx+r10]
	ror	r8d, cl
	mov	DWORD PTR [rdi+rdx], r8d
	add	rdx, 4
	cmp	rdx, 64
	jne	.L34
	mov	rdx, rdi
.L35:
	mov	ecx, DWORD PTR 64[rdx]
	xor	DWORD PTR [rdx], ecx
	add	rdx, 4
	cmp	r9, rdx
	jne	.L35
	mov	ebx, eax
	xor	edx, edx
	sar	ebx, 2
.L36:
	mov	r8d, DWORD PTR 64[rdi+rdx*4]
	mov	ecx, ebx
	xor	ecx, edx
	inc	rdx
	cmp	rdx, 16
	mov	DWORD PTR -64[rsp+rcx*4], r8d
	jne	.L36
	xor	edx, edx
.L37:
	mov	ecx, DWORD PTR [r10+rdx]
	mov	DWORD PTR 64[rdi+rdx], ecx
	add	rdx, 4
	cmp	rdx, 64
	jne	.L37
	sub	eax, 4
	jne	.L40
	dec	esi
	jne	.L31
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE1:
	.size	cube, .-cube
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
