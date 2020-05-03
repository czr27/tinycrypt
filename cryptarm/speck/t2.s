	.file	"t2.c"
	.cpu ARC700
	.arc_attribute Tag_ARC_PCS_config, 2
	.arc_attribute Tag_ARC_ABI_rf16, 0
	.arc_attribute Tag_ARC_ABI_pic, 0
	.arc_attribute Tag_ARC_ABI_tls, 0
	.arc_attribute Tag_ARC_ABI_sda, 2
	.arc_attribute Tag_ARC_ABI_exceptions, 1
	.section	.text
	.align 4
	.global	speck
	.type	speck, @function
speck:
	ld_s r3,[r0]	;17
	ld_s r12,[r0,4]	;17
	ld r5,[r0,8]	;25
	ld r6,[r0,12]	;25
	ld_s r2,[r1,4]	;17
	ld_s r0,[r1]	;17
	mov r4,0		;5
	.align 2
.L2:
	ror r0,r0,8
	ror r12,r12,8
	add_s r0,r0,r2 ;1
	add_s r12,r12,r3 ;1
	xor_s r0,r0,r3
	ror r2,r2,29
	ror r3,r3,29
	xor r7,r12,r4
	add r4,r4,1
	mov_s r12,r5	;0
	xor_s r2,r2,r0
	xor r3,r3,r7
	brne.d r4, 27, @.L3
	mov r5,r6		;5
	st_s r0,[r1]		;18
	j_s.d [blink]
	st_s r2,[r1,4]		;18
	.align 2
.L3:
	mov r6,r7		;5
	b_s @.L2
	.size	speck, .-speck
	.ident	"GCC: (ARCompact/ARCv2 ISA elf32 toolchain 2017.09) 7.1.1 20170710"
	.section	.note.GNU-stack,"",@progbits
