;
;  Copyright © 2020 Odzhan. All Rights Reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are
;  met:
;
;  1. Redistributions of source code must retain the above copyright
;  notice, this list of conditions and the following disclaimer.
;
;  2. Redistributions in binary form must reproduce the above copyright
;  notice, this list of conditions and the following disclaimer in the
;  documentation and/or other materials provided with the distribution.
;
;  3. The name of the author may not be used to endorse or promote products
;  derived from this software without specific prior written permission.
;
;  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
;  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
;  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
;  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;  POSSIBILITY OF SUCH DAMAGE.
;
; -----------------------------------------------
; ULZ depacker in x86 assembly
;
; size: 124 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
    
    %ifndef BIN
      global ulz_depackx
      global _ulz_depackx
    %endif
    
ulz_depackx:
_ulz_depackx:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   ebx, eax          ; ebx = inlen
    lodsd
    xchg   edi, eax          ; edi = outbuf
    lodsd
    xchg   esi, eax          ; esi = inbuf
    add    ebx, esi          ; ebx += inbuf
ulz_main:
    xor    ecx, ecx
    mul    ecx
    ; while (in < end) {
    cmp    esi, ebx
    jae    ulz_exit
    ; token = *in++;
    lodsb
    ; if(token >= 32) {
    cmp    al, 32
    jb     ulz_copy2
    ; len = token >> 5
    mov    cl, al
    shr    cl, 5
    ; if(len == 7)
    cmp    cl, 7
    jne    ulz_copy1
    ; len = add_mod(len, &in);
    call   add_mod
ulz_copy1:
    ; while(len--) *out++ = *in++;
    rep    movsb
    ; if(in >= end) break;
    cmp    esi, ebx
    jae    ulz_exit
ulz_copy2:
    ; len = (token & 15) + 4;
    mov    cl, al
    and    cl, 15
    add    cl, 4
    ; if(len == (15 + 4))
    cmp    cl, 15 + 4
    jne    ulz_copy3
    ; len = add_mod(len, &in);
    call   add_mod
ulz_copy3:
    ; dist = ((token & 16) << 12) + *(uint16_t*)in;
    and    al, 16
    shl    eax, 12
    xchg   eax, edx
    ; eax = *(uint16_t*)in;
    ; in += 2;
    lodsw
    add    edx, eax
    ; p = out - dist
    push   esi
    mov    esi, edi
    sub    esi, edx
    ; while(len--) *out++ = *p++;
    rep    movsb
    pop    esi
    jmp    ulz_main
    ; }
ulz_exit:
    ; return (uint32_t)(out - (uint8_t*)outbuf);
    sub    edi, [esp+32+8]
    mov    [esp+28], edi
    popad
    ret
    
; static uint32_t add_mod(uint32_t x, uint8_t** p);
add_mod:
    push   eax               ; save eax
    xchg   eax, ecx          ; eax = len
    xor    ecx, ecx          ; i = 0
am_loop:
    mov    dl, byte[esi]     ; c = *(*p)++
    inc    esi
    push   edx               ; save c
    shl    edx, cl           ; x += (c << i)
    add    eax, edx
    pop    edx               ; restore c
    cmp    dl, 128           ; if(c < 128) break;
    jb     am_exit
    add    cl, 7             ; i+=7
    cmp    cl, 21            ; i<=21
    jbe    am_loop
am_exit:
    xchg   eax, ecx          ; ecx = len
    pop    eax               ; restore eax
    ret
    
