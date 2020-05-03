;
;  Copyright © 2017 Odzhan. All Rights Reserved.
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

; -----------------------------------------------
; PRESENT-128 block cipher in AMD64 assembly (encryption only)
;
; size: 193 bytes
;
; global calls use Linux/AMD64 ABI
;
; -----------------------------------------------
    bits 64

    %ifndef BIN
      global present
    %endif
    
    %define k0   rbp
    %define k1   rdi
    
present:
    push    rbp
    push    rbx
    push    rdi   ; save mk
    push    rsi   ; save data
    ; load 128-bit key
    ; k0=rev(k[0]); k1=rev(k[1]);
    mov     k0, [rdi]
    bswap   k0
    mov     k1, [rdi+8]
    bswap   k1
    ; load 64-bit plaintext
    ; t=rev(x[0]);
    lodsq
    bswap   rax
    ; i = 0
    xor     ebx, ebx
L0:
    ; mix key
    ; p = t ^ k0;
    xor     rax, k0
    ; F(j,8) ((B*)&p)[j] = S(((B*)&p)[j]);
    push    8
    pop     rcx
L1:
    call    S
    ror     rax, 8
    loop    L1
    ; r = 0x30201000
    mov     edx, 0x30201000
    ; t = 0
    xor     esi, esi
L2:
    ; t |= ((p >> j) & 1) << (r & 255);
    shr     rax, 1
    jnc     L3
    bts     rsi, rdx
L3:    
    ; r = ROTR32(r+1, 8);
    inc     dl
    ror     edx, 8
    ; j++, j < 64
    add     cl, 4
    jne     L2
    
    ; save t
    push    rsi
    ; p = (k0 << 61) | (k1 >> 3);
    push    k0
    pop     rax
    push    k1
    pop     rcx
    shl     rax, 61
    shr     rcx, 3
    or      rax, rcx
    ; k1 = (k1 << 61) | (k0 >> 3);
    shl     k1, 61
    shr     k0, 3
    or      k1, k0
    ; p = R(p, 56);
    ror     rax, 56
    ; apply nonlinear layer
    ; ((B*)&p)[0] = S(((B*)&p)[0]);
    call    S
    ; i++
    inc     bl
    ; k0 = R(p, 8) ^ ((i + 1) >> 2);
    mov     ecx, ebx
    shr     ecx, 2
    push    rax
    pop     k0
    ror     k0, 8
    xor     k0, rcx
    ; k1 ^= (((i + 1) & 3) << 62);
    mov     ecx, ebx
    and     ecx, 3
    shl     rcx, 62
    xor     k1, rcx
    ; restore t in rax
    pop     rax
    ; i < 32-1
    cmp     bl, 32-1
    jne     L0
    ; x[0] = rev(t ^ k0);
    xor     rax, k0
    bswap   rax
    pop     rdi
    stosq
    pop     rdi
    pop     rbx    
    pop     rbp     
    ret
    
    ; nonlinear layer
S0:
    pop     rbx              ; rbx = sbox
    mov     cl, al           ; cl = x
    shr     al, 4            ; al = sbox[x >> 4] << 4
    xlatb                    ; 
    shl     al, 4    
    xchg    al, cl
    and     al, 15           ; al |= sbox[x & 0x0F]  
    xlatb
    or      al, cl    
    pop     rcx
    pop     rbx    
    ret
S:
    push    rbx 
    push    rcx 
    call    S0
    ; sbox
    db      0xc, 0x5, 0x6, 0xb, 0x9, 0x0, 0xa, 0xd
    db      0x3, 0xe, 0xf, 0x8, 0x4, 0x7, 0x1, 0x2
    
