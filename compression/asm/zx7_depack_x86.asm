;
; Decompresses Einar Saukas' ZX7 compressed stream data.
; ZX7 format and original Z80 decompressor by Einar Saukas.
; Original Z80 to 8086 conversion, and size-optimized version, by Peter Ferrie.
; 2016/03/08
;
; The source for the conversion was the original "default" Z80 decompression
; code provided by Einar.  Further size optimization and unrolling were
; independently performed specifically for the 8086.
;
; Updated 2020/01/09: Converted to 32-bit, assembles to 81 bytes.
; Uses cdecl calling convention: uint32_t zx7_decompress(void *inbuf, void *outbuf);
;
; yasm -fwin32 zx7.asm -ozx7.obj
;
; Odzhan
;
        bits 32
        
        %ifndef BIN
          global zx7_decompress
          global _zx7_decompress
        %endif
        
zx7_decompress:
_zx7_decompress:
        pushad
        mov     esi, [esp+32+4]         ; input
        mov     edi, [esp+32+8]         ; output
        call    @@dzx7_init
@@dzx7s_next_bit:
        add     al, al                  ; check next bit
        jnz     @@dzx7s_next_bit_ret    ; no more bits left?
        lodsb                           ; load another group of 8 bits
        adc     al, al
@@dzx7s_next_bit_ret:
        ret
@@dzx7_init:
        pop     ebp
        xor     eax, eax
        mov     al, 80h
        xor     ecx, ecx
@@dzx7s_copy_byte_loop:
        movsb                           ; copy literal byte
@@dzx7s_main_loop:
        call    ebp
        jnc     @@dzx7s_copy_byte_loop  ; next bit indicates either
                                        ; literal or sequence
; determine number of bits used for length (Elias gamma coding)
        xor     ebx, ebx
@@dzx7s_len_size_loop:
        inc     ebx
        call    ebp
        jnc     @@dzx7s_len_size_loop
        jmp     @@dzx7s_len_value_skip
; determine length
@@dzx7s_len_value_loop:
        call    ebp
@@dzx7s_len_value_skip:
        adc     cx, cx
        jb      @@dzx7s_exit            ; check end marker
        dec     ebx
        jnz     @@dzx7s_len_value_loop
        inc     ecx                     ; adjust length
        ; determine offset
        mov     bl, [esi]               ; load offset flag (1 bit) +
                                        ; offset value (7 bits)
        inc     esi
        stc
        adc     bl, bl
        jnc     @@dzx7s_offset_end      ; if offset flag is set, load
                                        ; 4 extra bits
        mov     bh, 10h                 ; bit marker to load 4 bits
@@dzx7s_rld_next_bit:
        call    ebp
        adc     bh, bh                  ; insert next bit into D
        jnc     @@dzx7s_rld_next_bit    ; repeat 4 times, until bit
                                        ; marker is out
        inc     bh                      ; add 128 to DE
@@dzx7s_offset_end:
        shr     ebx, 1                  ; insert fourth bit into E
        ; copy previous sequence
        push    esi
        mov     esi, edi
        sbb     esi, ebx                ; destination = destination - offset - 1
        rep     movsb
        pop     esi                     ; restore source address
                                        ; (compressed data)
        jmp     @@dzx7s_main_loop
@@dzx7s_exit:
        sub     edi, [esp+32+8]
        mov     [esp+28], edi
        popad
        ret
