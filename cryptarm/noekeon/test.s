	.file	"test.c"
	.intel_syntax noprefix
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"%s : "
.LC1:
	.string	"%02x "
	.text
	.p2align 4,,15
	.globl	print_bytes
	.type	print_bytes, @function
print_bytes:
.LFB15:
	.cfi_startproc
	push	r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	push	rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	xor	eax, eax
	push	rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	mov	rbx, rsi
	mov	rsi, rdi
	lea	rdi, .LC0[rip]
	mov	ebp, edx
	call	printf@PLT
	test	ebp, ebp
	jle	.L4
	lea	eax, -1[rbp]
	lea	rbp, .LC1[rip]
	lea	r12, 1[rbx+rax]
	.p2align 4,,10
	.p2align 3
.L3:
	movzx	esi, BYTE PTR [rbx]
	xor	eax, eax
	mov	rdi, rbp
	add	rbx, 1
	call	printf@PLT
	cmp	rbx, r12
	jne	.L3
.L4:
	pop	rbx
	.cfi_def_cfa_offset 24
	pop	rbp
	.cfi_def_cfa_offset 16
	pop	r12
	.cfi_def_cfa_offset 8
	mov	rsi, QWORD PTR stdout[rip]
	mov	edi, 10
	jmp	_IO_putc@PLT
	.cfi_endproc
.LFE15:
	.size	print_bytes, .-print_bytes
	.section	.rodata.str1.1
.LC2:
	.string	"OK"
.LC3:
	.string	"FAILED"
.LC4:
	.string	"\nEncryption : %s : "
.LC5:
	.string	"CT"
	.section	.text.startup,"ax",@progbits
	.p2align 4,,15
	.globl	main
	.type	main, @function
main:
.LFB16:
	.cfi_startproc
	push	rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	lea	rdi, key[rip]
	sub	rsp, 16
	.cfi_def_cfa_offset 32
	mov	rax, QWORD PTR pt[rip]
	mov	rdx, QWORD PTR pt[rip+8]
	mov	rsi, rsp
	mov	QWORD PTR [rsp], rax
	mov	QWORD PTR 8[rsp], rdx
	call	Noekeon@PLT
	lea	rsi, ct[rip]
	mov	edx, 16
	mov	rdi, rsp
	call	memcmp@PLT
	lea	rsi, .LC2[rip]
	test	eax, eax
	lea	rax, .LC3[rip]
	lea	rdi, .LC4[rip]
	cmovne	rsi, rax
	xor	eax, eax
	call	printf@PLT
	lea	rdi, .LC5[rip]
	mov	rsi, rsp
	mov	edx, 16
	call	print_bytes
	add	rsp, 16
	.cfi_def_cfa_offset 16
	xor	eax, eax
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE16:
	.size	main, .-main
	.globl	key
	.data
	.align 16
	.type	key, @object
	.size	key, 16
key:
	.byte	0
	.byte	1
	.byte	2
	.byte	3
	.byte	4
	.byte	5
	.byte	6
	.byte	7
	.byte	8
	.byte	9
	.byte	10
	.byte	11
	.byte	12
	.byte	13
	.byte	14
	.byte	15
	.globl	pt
	.align 16
	.type	pt, @object
	.size	pt, 16
pt:
	.byte	-19
	.byte	31
	.byte	124
	.byte	89
	.byte	-20
	.byte	-122
	.byte	-92
	.byte	-98
	.byte	44
	.byte	108
	.byte	34
	.byte	-82
	.byte	32
	.byte	-76
	.byte	-82
	.byte	-34
	.globl	ct
	.align 16
	.type	ct, @object
	.size	ct, 16
ct:
	.byte	-48
	.byte	54
	.byte	25
	.byte	76
	.byte	-58
	.byte	112
	.byte	59
	.byte	110
	.byte	50
	.byte	-52
	.byte	43
	.byte	111
	.byte	-92
	.byte	-47
	.byte	33
	.byte	64
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
