;------------------------------------------------------------------------------
;
; nrv2b_unpack()
;
; input:
;   ESI = src (packed)
;   EDI = dst (unpacked)
; output:
;   EAX = unpacked size
;
; originally written by Z0MBiE in 2004
; minor optimizations added by Odzhan in 2020 (123 bytes)
;------------------------------------------------------------------------------
                bits 32
                
                %ifndef BIN
                  global nrv2b_unpack
                  global _nrv2b_unpack
                %endif
nrv2b_unpack:
_nrv2b_unpack:
                pushad
                
                mov     esi, [esp+32+4] ; input
                mov     edi, [esp+32+8] ; output
                
                push    -1
                pop     ebp

                call    pop_getbit
                add     ebx, ebx
                jnz     x1
                
                mov     ebx, [esi]
                sub     esi, -4
                adc     ebx, ebx
x1:             ret
pop_getbit:
                pop     edx
                jmp     dcl1_n2b
decompr_literals_n2b:
                movsb
decompr_loop_n2b:
                add     ebx, ebx
                jnz     dcl2_n2b
dcl1_n2b:
                mov     ebx, [esi]
                sub     esi, -4
                adc     ebx, ebx
dcl2_n2b:
                jc      decompr_literals_n2b

                push    1
                pop     eax
loop1_n2b:
                call    edx ; getbit
                adc     eax, eax
                call    edx ; getbit
                jnc     loop1_n2b
                xor     ecx, ecx
                sub     eax, 3
                jb      decompr_ebpeax_n2b
                shl     eax, 8
                lodsb
                xor     eax, -1
                jz      decompr_end_n2b
                xchg    ebp, eax
decompr_ebpeax_n2b:
                call    edx ; getbit
                adc     ecx, ecx
                call    edx ; getbit
                adc     ecx, ecx
                jnz     decompr_got_mlen_n2b
                inc     ecx
loop2_n2b:
                call    edx ; getbit
                adc     ecx, ecx
                call    edx ; getbit
                jnc     loop2_n2b
                inc     ecx
                inc     ecx
decompr_got_mlen_n2b:
                cmp     ebp, -0D00h
                adc     ecx, 1
                push    esi
                lea     esi, [edi+ebp]
                rep     movsb
                pop     esi
                jmp     decompr_loop_n2b
decompr_end_n2b:
                sub     edi, [esp+32+8]
                mov     [esp+28], edi
                popa
                ret

;------------------------------------------------------------------------------

; EOF
