	.text
	.intel_syntax noprefix
	.file	"beltx.c"
	.globl	H
	.align	16, 0x90
	.type	H,@function
H:                                      # @H
	.cfi_startproc
# BB#0:
	cmp	edi, 10
	jne	.LBB0_2
# BB#1:
	xor	edx, edx
	movzx	eax, dl
	ret
.LBB0_2:
	movzx	eax, dil
	cmp	eax, 10
	setb	cl
	add	al, cl
	mov	dl, 29
	je	.LBB0_7
# BB#3:                                 # %.preheader.preheader
	movzx	r8d, al
	xor	edi, edi
	mov	dl, 29
	.align	16, 0x90
.LBB0_4:                                # %.preheader
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
	mov	esi, 116
	.align	16, 0x90
.LBB0_5:                                #   Parent Loop BB0_4 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	mov	cl, dl
	and	cl, 99
	mov	al, cl
	shr	al
	xor	al, cl
	mov	cl, al
	shr	cl, 2
	xor	cl, al
	mov	al, cl
	shr	al, 4
	xor	al, cl
	shl	al, 7
	shr	dl
	or	al, dl
	and	dl, 99
	mov	cl, dl
	shr	cl
	xor	cl, dl
	mov	dl, cl
	shr	dl, 2
	xor	dl, cl
	mov	cl, dl
	shr	cl, 4
	xor	cl, dl
	shl	cl, 7
	shr	al
	mov	dl, al
	or	dl, cl
	add	esi, -2
	jne	.LBB0_5
# BB#6:                                 #   in Loop: Header=BB0_4 Depth=1
	inc	edi
	cmp	edi, r8d
	jne	.LBB0_4
.LBB0_7:                                # %.loopexit
	movzx	eax, dl
	ret
.Lfunc_end0:
	.size	H, .Lfunc_end0-H
	.cfi_endproc

	.globl	G
	.align	16, 0x90
	.type	G,@function
G:                                      # @G
	.cfi_startproc
# BB#0:
	push	rbp
.Ltmp0:
	.cfi_def_cfa_offset 16
	push	r14
.Ltmp1:
	.cfi_def_cfa_offset 24
	push	rbx
.Ltmp2:
	.cfi_def_cfa_offset 32
.Ltmp3:
	.cfi_offset rbx, -32
.Ltmp4:
	.cfi_offset r14, -24
.Ltmp5:
	.cfi_offset rbp, -16
	and	edx, 7
	add	edi, dword ptr [rsi + 4*rdx]
	movzx	eax, dil
	xor	r9d, r9d
	cmp	eax, 10
	mov	r8d, 0
	je	.LBB1_7
# BB#1:
	setb	al
	add	al, dil
	mov	r8d, 29
	je	.LBB1_7
# BB#2:                                 # %.preheader.preheader.i
	movzx	r8d, al
	xor	r10d, r10d
	mov	al, 29
	.align	16, 0x90
.LBB1_3:                                # %.preheader.i
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_4 Depth 2
	mov	esi, 116
	.align	16, 0x90
.LBB1_4:                                #   Parent Loop BB1_3 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	mov	r11b, al
	and	r11b, 99
	mov	dl, r11b
	shr	dl
	xor	dl, r11b
	mov	r11b, dl
	shr	r11b, 2
	xor	r11b, dl
	mov	bl, r11b
	shr	bl, 4
	xor	bl, r11b
	shl	bl, 7
	shr	al
	or	bl, al
	and	al, 99
	mov	r11b, al
	shr	r11b
	xor	r11b, al
	mov	al, r11b
	shr	al, 2
	xor	al, r11b
	mov	dl, al
	shr	dl, 4
	xor	dl, al
	shl	dl, 7
	shr	bl
	mov	al, bl
	or	al, dl
	add	esi, -2
	jne	.LBB1_4
# BB#5:                                 #   in Loop: Header=BB1_3 Depth=1
	inc	r10d
	cmp	r10d, r8d
	jne	.LBB1_3
# BB#6:                                 # %H.exit.loopexit
	movzx	r8d, al
.LBB1_7:                                # %H.exit
	mov	r10d, r8d
	shl	r10d, 8
	mov	eax, edi
	shr	eax, 24
	cmp	eax, 10
	je	.LBB1_14
# BB#8:
	movzx	eax, al
	cmp	eax, 10
	setb	dl
	add	al, dl
	mov	r9d, 29
	je	.LBB1_14
# BB#9:                                 # %.preheader.preheader.i.1
	movzx	r9d, al
	xor	r11d, r11d
	mov	al, 29
	.align	16, 0x90
.LBB1_10:                               # %.preheader.i.1
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_11 Depth 2
	mov	esi, 116
	.align	16, 0x90
.LBB1_11:                               #   Parent Loop BB1_10 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	mov	dl, al
	and	dl, 99
	mov	bl, dl
	shr	bl
	xor	bl, dl
	mov	dl, bl
	shr	dl, 2
	xor	dl, bl
	mov	bl, dl
	shr	bl, 4
	xor	bl, dl
	shl	bl, 7
	shr	al
	or	bl, al
	and	al, 99
	mov	dl, al
	shr	dl
	xor	dl, al
	mov	al, dl
	shr	al, 2
	xor	al, dl
	mov	dl, al
	shr	dl, 4
	xor	dl, al
	shl	dl, 7
	shr	bl
	mov	al, bl
	or	al, dl
	add	esi, -2
	jne	.LBB1_11
# BB#12:                                #   in Loop: Header=BB1_10 Depth=1
	inc	r11d
	cmp	r11d, r9d
	jne	.LBB1_10
# BB#13:                                # %H.exit.loopexit.1
	movzx	r9d, al
.LBB1_14:                               # %H.exit.1
	or	r9d, r10d
	shl	r9d, 8
	mov	edx, edi
	shr	edx, 16
	movzx	esi, dl
	xor	eax, eax
	cmp	esi, 10
	mov	r10d, 0
	je	.LBB1_21
# BB#15:
	setb	sil
	add	sil, dl
	mov	r10d, 29
	je	.LBB1_21
# BB#16:                                # %.preheader.preheader.i.2
	movzx	r10d, sil
	xor	r11d, r11d
	mov	dl, 29
	.align	16, 0x90
.LBB1_17:                               # %.preheader.i.2
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_18 Depth 2
	mov	esi, 116
	.align	16, 0x90
.LBB1_18:                               #   Parent Loop BB1_17 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	mov	bpl, dl
	and	bpl, 99
	mov	bl, bpl
	shr	bl
	xor	bl, bpl
	mov	bpl, bl
	shr	bpl, 2
	xor	bpl, bl
	mov	r14b, bpl
	shr	r14b, 4
	xor	r14b, bpl
	shl	r14b, 7
	shr	dl
	or	r14b, dl
	and	dl, 99
	mov	bpl, dl
	shr	bpl
	xor	bpl, dl
	mov	dl, bpl
	shr	dl, 2
	xor	dl, bpl
	mov	bl, dl
	shr	bl, 4
	xor	bl, dl
	shl	bl, 7
	shr	r14b
	mov	dl, r14b
	or	dl, bl
	add	esi, -2
	jne	.LBB1_18
# BB#19:                                #   in Loop: Header=BB1_17 Depth=1
	inc	r11d
	cmp	r11d, r10d
	jne	.LBB1_17
# BB#20:                                # %H.exit.loopexit.2
	movzx	r10d, dl
.LBB1_21:                               # %H.exit.2
	or	r10d, r9d
	shl	r10d, 8
	shr	edi, 8
	and	r10d, 16776960
	movzx	edx, dil
	cmp	edx, 10
	je	.LBB1_28
# BB#22:
	setb	dl
	add	dl, dil
	mov	eax, 29
	je	.LBB1_28
# BB#23:                                # %.preheader.preheader.i.3
	movzx	ebp, dl
	xor	esi, esi
	mov	dl, 29
	.align	16, 0x90
.LBB1_24:                               # %.preheader.i.3
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_25 Depth 2
	mov	edi, 116
	.align	16, 0x90
.LBB1_25:                               #   Parent Loop BB1_24 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	mov	al, dl
	and	al, 99
	mov	bl, al
	shr	bl
	xor	bl, al
	mov	r9b, bl
	shr	r9b, 2
	xor	r9b, bl
	mov	al, r9b
	shr	al, 4
	xor	al, r9b
	shl	al, 7
	shr	dl
	or	al, dl
	and	dl, 99
	mov	bl, dl
	shr	bl
	xor	bl, dl
	mov	dl, bl
	shr	dl, 2
	xor	dl, bl
	mov	bl, dl
	shr	bl, 4
	xor	bl, dl
	shl	bl, 7
	shr	al
	mov	dl, al
	or	dl, bl
	add	edi, -2
	jne	.LBB1_25
# BB#26:                                #   in Loop: Header=BB1_24 Depth=1
	inc	esi
	cmp	esi, ebp
	jne	.LBB1_24
# BB#27:                                # %H.exit.loopexit.3
	movzx	eax, dl
.LBB1_28:                               # %H.exit.3
	or	eax, r10d
	shl	eax, 8
	or	eax, r8d
	rol	eax, cl
	pop	rbx
	pop	r14
	pop	rbp
	ret
.Lfunc_end1:
	.size	G, .Lfunc_end1-G
	.cfi_endproc

	.globl	belt
	.align	16, 0x90
	.type	belt,@function
belt:                                   # @belt
	.cfi_startproc
# BB#0:
	push	rbp
.Ltmp6:
	.cfi_def_cfa_offset 16
	push	r15
.Ltmp7:
	.cfi_def_cfa_offset 24
	push	r14
.Ltmp8:
	.cfi_def_cfa_offset 32
	push	r13
.Ltmp9:
	.cfi_def_cfa_offset 40
	push	r12
.Ltmp10:
	.cfi_def_cfa_offset 48
	push	rbx
.Ltmp11:
	.cfi_def_cfa_offset 56
	sub	rsp, 24
.Ltmp12:
	.cfi_def_cfa_offset 80
.Ltmp13:
	.cfi_offset rbx, -56
.Ltmp14:
	.cfi_offset r12, -48
.Ltmp15:
	.cfi_offset r13, -40
.Ltmp16:
	.cfi_offset r14, -32
.Ltmp17:
	.cfi_offset r15, -24
.Ltmp18:
	.cfi_offset rbp, -16
	mov	qword ptr [rsp], rsi    # 8-byte Spill
	mov	r15, rdi
	mov	ebx, dword ptr [rsi]
	mov	r14d, dword ptr [rsi + 4]
	mov	eax, dword ptr [rsi + 8]
	mov	dword ptr [rsp + 20], eax # 4-byte Spill
	mov	ebp, dword ptr [rsi + 12]
	xor	r13d, r13d
	mov	dword ptr [rsp + 16], 1 # 4-byte Folded Spill
	.align	16, 0x90
.LBB2_1:                                # =>This Inner Loop Header: Depth=1
	lea	eax, [r13 + 1]
	mov	dword ptr [rsp + 8], eax # 4-byte Spill
	mov	ecx, 5
	mov	edi, ebx
	mov	rsi, r15
	mov	edx, r13d
	call	G
	mov	r12d, eax
	xor	r12d, r14d
	mov	ecx, 21
	mov	edi, ebp
	mov	rsi, r15
	mov	edx, dword ptr [rsp + 8] # 4-byte Reload
	call	G
	mov	r14d, eax
	xor	r14d, dword ptr [rsp + 20] # 4-byte Folded Reload
	lea	edx, [r13 + 2]
	mov	ecx, 13
	mov	edi, r12d
	mov	rsi, r15
	call	G
	sub	ebx, eax
	mov	dword ptr [rsp + 20], ebx # 4-byte Spill
	lea	edi, [r14 + r12]
	lea	edx, [r13 + 3]
	mov	ecx, 21
	mov	rsi, r15
	call	G
	xor	eax, dword ptr [rsp + 16] # 4-byte Folded Reload
	add	r12d, eax
	mov	rdi, r14
	sub	edi, eax
	mov	qword ptr [rsp + 8], rdi # 8-byte Spill
	lea	edx, [r13 + 4]
	mov	ecx, 13
	mov	rsi, r15
	call	G
	mov	r14d, eax
	add	r14d, ebp
	lea	edx, [r13 + 5]
	mov	ecx, 21
	mov	edi, ebx
	mov	rsi, r15
	call	G
	mov	ebx, eax
	xor	ebx, r12d
	lea	edx, [r13 + 6]
	mov	ecx, 5
	mov	edi, r14d
	mov	rsi, r15
	call	G
	mov	ebp, eax
	mov	rax, qword ptr [rsp + 8] # 8-byte Reload
	xor	ebp, eax
	inc	dword ptr [rsp + 16]    # 4-byte Folded Spill
	cmp	r13d, 49
	lea	eax, [r13 + 7]
	mov	r13d, eax
	jne	.LBB2_1
# BB#2:
	mov	rax, qword ptr [rsp]    # 8-byte Reload
	mov	dword ptr [rax], r14d
	mov	dword ptr [rax + 4], ebp
	mov	dword ptr [rax + 8], ebx
	mov	ecx, dword ptr [rsp + 20] # 4-byte Reload
	mov	dword ptr [rax + 12], ecx
	add	rsp, 24
	pop	rbx
	pop	r12
	pop	r13
	pop	r14
	pop	r15
	pop	rbp
	ret
.Lfunc_end2:
	.size	belt, .Lfunc_end2-belt
	.cfi_endproc


	.ident	"clang version 3.8.1-24 (tags/RELEASE_381/final)"
	.section	".note.GNU-stack","",@progbits
