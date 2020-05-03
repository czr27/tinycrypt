	.file	"craft2.c"
	.intel_syntax noprefix
	.text
	.globl	craft
	.type	craft, @function
craft:
.LFB2:
	.cfi_startproc
	push	ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	call	__x86.get_pc_thunk.cx
	add	ecx, OFFSET FLAT:_GLOBAL_OFFSET_TABLE_
	mov	ebp, esp
	.cfi_def_cfa_register 5
	push	edi
	push	esi
	push	ebx
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	lea	esi, -60[ebp]
	sub	esp, 92
	mov	eax, DWORD PTR 16[ebp]
	mov	edi, DWORD PTR 8[ebp]
	mov	DWORD PTR -100[ebp], esi
	lea	esi, -44[ebp]
	mov	DWORD PTR -96[ebp], eax
	xor	eax, eax
.L2:
	mov	edx, DWORD PTR 12[ebp]
	mov	dl, BYTE PTR [edx+eax]
	mov	bl, dl
	xor	bl, BYTE PTR [edi+eax]
	mov	BYTE PTR -76[ebp+eax], bl
	mov	bl, dl
	xor	bl, BYTE PTR 16[edi+eax]
	mov	edx, DWORD PTR -100[ebp]
	mov	BYTE PTR [edx+eax], bl
	movzx	ebx, BYTE PTR Q@GOTOFF[eax+ecx]
	mov	edx, DWORD PTR 12[ebp]
	mov	dl, BYTE PTR [edx+ebx]
	mov	bl, dl
	xor	bl, BYTE PTR [edi+eax]
	mov	BYTE PTR [esi+eax], bl
	mov	bl, dl
	xor	bl, BYTE PTR 16[edi+eax]
	mov	BYTE PTR -28[ebp+eax], bl
	inc	eax
	cmp	eax, 16
	jne	.L2
	mov	eax, DWORD PTR -96[ebp]
	xor	esi, esi
	add	eax, 4
	mov	DWORD PTR -100[ebp], eax
	lea	eax, -92[ebp]
	mov	DWORD PTR -104[ebp], eax
.L7:
	mov	eax, DWORD PTR -96[ebp]
	mov	ebx, esi
.L4:
	mov	dl, BYTE PTR [eax]
	xor	dl, BYTE PTR 8[eax]
	mov	edi, edx
	mov	dl, BYTE PTR 12[eax]
	xor	edi, edx
	mov	edx, edi
	mov	BYTE PTR [eax], dl
	mov	dl, BYTE PTR 12[eax]
	xor	BYTE PTR 4[eax], dl
	inc	eax
	cmp	DWORD PTR -100[ebp], eax
	jne	.L4
	mov	edi, DWORD PTR -96[ebp]
	mov	al, BYTE PTR RC4@GOTOFF[esi+ecx]
	and	ebx, 3
	sal	ebx, 4
	xor	BYTE PTR 4[edi], al
	mov	al, BYTE PTR RC3@GOTOFF[esi+ecx]
	xor	BYTE PTR 5[edi], al
	lea	edi, -12[ebp]
	xor	eax, eax
	add	ebx, edi
.L5:
	mov	edi, DWORD PTR -96[ebp]
	mov	dl, BYTE PTR -64[eax+ebx]
	xor	BYTE PTR [edi+eax], dl
	inc	eax
	cmp	eax, 16
	jne	.L5
	xor	eax, eax
	cmp	esi, 31
	jne	.L12
.L11:
	inc	esi
	cmp	esi, 32
	jne	.L7
	add	esp, 92
	pop	ebx
	.cfi_remember_state
	.cfi_restore 3
	pop	esi
	.cfi_restore 6
	pop	edi
	.cfi_restore 7
	pop	ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
.L12:
	.cfi_restore_state
	mov	edi, DWORD PTR -96[ebp]
	movzx	ebx, BYTE PTR P@GOTOFF[eax+ecx]
	mov	dl, BYTE PTR [edi+eax]
	inc	eax
	cmp	eax, 16
	mov	BYTE PTR -92[ebp+ebx], dl
	jne	.L12
	xor	eax, eax
.L10:
	mov	edi, DWORD PTR -104[ebp]
	movzx	ebx, BYTE PTR [eax+edi]
	mov	edi, DWORD PTR -96[ebp]
	mov	bl, BYTE PTR S@GOTOFF[ecx+ebx]
	mov	BYTE PTR [edi+eax], bl
	inc	eax
	cmp	eax, 16
	jne	.L10
	jmp	.L11
	.cfi_endproc
.LFE2:
	.size	craft, .-craft
	.globl	RC4
	.section	.rodata
	.align 32
	.type	RC4, @object
	.size	RC4, 32
RC4:
	.byte	1
	.byte	8
	.byte	4
	.byte	2
	.byte	9
	.byte	12
	.byte	6
	.byte	11
	.byte	5
	.byte	10
	.byte	13
	.byte	14
	.byte	15
	.byte	7
	.byte	3
	.byte	1
	.byte	8
	.byte	4
	.byte	2
	.byte	9
	.byte	12
	.byte	6
	.byte	11
	.byte	5
	.byte	10
	.byte	13
	.byte	14
	.byte	15
	.byte	7
	.byte	3
	.byte	1
	.byte	8
	.globl	RC3
	.align 32
	.type	RC3, @object
	.size	RC3, 32
RC3:
	.byte	1
	.byte	4
	.byte	2
	.byte	5
	.byte	6
	.byte	7
	.byte	3
	.byte	1
	.byte	4
	.byte	2
	.byte	5
	.byte	6
	.byte	7
	.byte	3
	.byte	1
	.byte	4
	.byte	2
	.byte	5
	.byte	6
	.byte	7
	.byte	3
	.byte	1
	.byte	4
	.byte	2
	.byte	5
	.byte	6
	.byte	7
	.byte	3
	.byte	1
	.byte	4
	.byte	2
	.byte	5
	.globl	Q
	.align 4
	.type	Q, @object
	.size	Q, 16
Q:
	.byte	12
	.byte	10
	.byte	15
	.byte	5
	.byte	14
	.byte	8
	.byte	9
	.byte	2
	.byte	11
	.byte	3
	.byte	7
	.byte	4
	.byte	6
	.byte	0
	.byte	1
	.byte	13
	.globl	P
	.align 4
	.type	P, @object
	.size	P, 16
P:
	.byte	15
	.byte	12
	.byte	13
	.byte	14
	.byte	10
	.byte	9
	.byte	8
	.byte	11
	.byte	6
	.byte	5
	.byte	4
	.byte	7
	.byte	1
	.byte	2
	.byte	3
	.byte	0
	.globl	S
	.align 4
	.type	S, @object
	.size	S, 16
S:
	.byte	12
	.byte	10
	.byte	13
	.byte	3
	.byte	14
	.byte	11
	.byte	15
	.byte	7
	.byte	8
	.byte	9
	.byte	1
	.byte	5
	.byte	0
	.byte	2
	.byte	4
	.byte	6
	.section	.text.__x86.get_pc_thunk.cx,"axG",@progbits,__x86.get_pc_thunk.cx,comdat
	.globl	__x86.get_pc_thunk.cx
	.hidden	__x86.get_pc_thunk.cx
	.type	__x86.get_pc_thunk.cx, @function
__x86.get_pc_thunk.cx:
.LFB3:
	.cfi_startproc
	mov	ecx, DWORD PTR [esp]
	ret
	.cfi_endproc
.LFE3:
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
