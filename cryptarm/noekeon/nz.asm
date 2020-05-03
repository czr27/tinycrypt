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
; Noekeon-128/128 Block Cipher in x86 assembly (Encryption only)
;
; size: 152 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
 
    %ifndef BIN
      global Noekeon
      global _Noekeon
    %endif
    
%define x0 ecx
%define x1 edx
%define x2 ebp
%define x3 esi

_Noekeon:
Noekeon:
    pushad
    mov    edi, [esp+32+4]  ; edi = key
    mov    esi, [esp+32+8]  ; esi = data
    ; save ptr to data
    push   esi
    ; load plaintext
    lodsd
    xchg   x0, eax
    lodsd
    xchg   x1, eax
    lodsd
    xchg   x2, eax
    lodsd
    xchg   x3, eax
    push   127
    pop    eax
    inc    eax    
nk_l0:  
    push   eax
    ; s[0] ^= rc;
    xor    x0, eax
    ; t = s[0] ^ s[2];
    mov    eax, x0
    xor    eax, x2
    ; t ^= ROTR32(t, 8) ^ ROTR32(t, 24);
    mov    ebx, eax
    ror    ebx, 8
    xor    eax, ebx
    ror    ebx, 16
    xor    eax, ebx
    ; s[1] ^= t; s[3] ^= t;
    xor    x1, eax
    xor    x3, eax    
    ; s[0]^= k[0]; s[1]^= k[1];
    xor    x0, [edi+4*0]    
    xor    x1, [edi+4*1] 
    ; s[2]^= k[2]; s[3]^= k[3];    
    xor    x2, [edi+4*2]    
    xor    x3, [edi+4*3]
    ; t = s[1] ^ s[3];
    mov    eax, x1
    xor    eax, x3
    ; t ^= ROTR32(t, 8) ^ ROTR32(t, 24);
    mov    ebx, eax
    ror    ebx, 8
    xor    eax, ebx
    ror    ebx, 16
    xor    eax, ebx
    ; s[0]^= t; s[2] ^= t;
    xor    x0, eax
    xor    x2, eax
    
    ; if (i==Nr) break;
    pop    eax
    cmp    al, 0xd4
    je     nk_l1
    
    add    al, al             ; al <<= 1
    jnc    $+4                ;
    xor    al, 27             ;
    ; Pi1
    ; s[1] = ROTR32(s[1], 31);
    rol    x1, 1
    ; s[2] = ROTR32(s[2], 27);
    ror    x2, 27
    ; s[3] = ROTR32(s[3], 30);
    ror    x3, 30
    
    ; Gamma
    ; s[1]^= ~((s[3]) | (s[2]));
    mov    ebx, x3
    or     ebx, x2
    not    ebx
    xor    x1, ebx

    ; s[0] = s[0] ^ s[2] & s[1];
    mov    ebx, x2
    and    ebx, x1
    xor    x0, ebx

    ; XCHG(s[0], s[3]);
    xchg   x0, x3
    
    ; s[2]^= s[0] ^ s[1] ^ s[3];
    xor    x2, x0
    xor    x2, x1
    xor    x2, x3

    ; s[1]^= ~((s[3]) | (s[2]));
    mov    ebx, x3
    or     ebx, x2
    not    ebx
    xor    x1, ebx
    
    ; s[0]^= s[2] & s[1];
    mov    ebx, x2
    and    ebx, x1
    xor    x0, ebx
    
    ; Pi2
    ; s[1] = ROTR32(s[1], 1);
    ror    x1, 1
    ; s[2] = ROTR32(s[2], 5);
    ror    x2, 5
    ; s[3] = ROTR32(s[3], 2);
    ror    x3, 2
    jmp    nk_l0
nk_l1:    
    ; restore ptr to data
    pop    edi
    ; store ciphertext
    xchg   x0, eax
    stosd
    xchg   x1, eax
    stosd
    xchg   x2, eax
    stosd
    xchg   x3, eax
    stosd    
    popad
    ret    
