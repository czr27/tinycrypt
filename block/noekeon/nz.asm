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
; Noekeon block cipher in x86 assembly
;
; size: 162 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
 
    %ifndef BIN
      global noekeon
      global _noekeon
    %endif
    
%define s0 eax
%define s1 edx
%define s2 ebp
%define s3 esi

%define t  ecx 
    
_noekeon:
noekeon:
    pushad
    mov    esi, [esp+32+4]  ; esi = data
    mov    edi, [esp+32+8]  ; edi = key
    call   load_tab
    db     0x80
    db     0x1B, 0x36, 0x6C, 0xD8 
    db     0xAB, 0x4D, 0x9A, 0x2F 
    db     0x5E, 0xBC, 0x63, 0xC6 
    db     0x97, 0x35, 0x6A, 0xD4
load_tab:
    pop    ebx
    ; save ptr to data
    push   esi
    ; load plaintext
    lodsd
    xchg   s3, eax
    lodsd
    xchg   s1, eax
    lodsd
    xchg   s2, eax
    lodsd
    xchg   s3, eax
nk_l0:    
    push   eax
    xlatb                   ; eax = rc_tab[i]
    mov    t, s0
    xor    t, eax
    mov    eax, t
    rol    eax, 8
    xor    t, eax
    ror    eax, 16
    xor    t, eax
    xor    s1, t
    xor    s3, t
    
    xor    s0, [edi+4*0]    
    xor    s1, [edi+4*1]    
    xor    s2, [edi+4*2]    
    xor    s3, [edi+4*3]
    
    mov    t, s1
    xor    t, s3
    mov    eax, t
    rol    eax, 8
    xor    t, eax
    ror    eax, 16
    xor    t, eax
    xor    s0, t
    xor    s2, t
    
    cmp    dword[esp], 16
    je     nk_l1  
    ; Pi1
    rol    s1, 1
    rol    s2, 5
    rol    s3, 2
    
    ; Gamma
    ; s[1] ^= ~((s[3]) | (s[2]));
    mov    t, s3
    or     t, s2
    not    t
    xor    s1, t

    xchg   s0, s3
    
    xor    s2, s0
    xor    s2, s1
    xor    s2, s3

    mov    t, s3
    or     t, s2
    not    t
    xor    s1, t

    mov    t, s2
    and    t, s1
    xor    s0, t
    
    ; Pi2
    ror    s1, 1
    ror    s2, 5
    ror    s3, 2
    
    pop    eax
    inc    eax
    cmp    al, 16
    jbe    nk_l0
nk_l1:    
    ; restore ptr to data
    pop    edi
    ; store ciphertext
    xchg   s0, eax
    stosd
    xchg   s1, eax
    stosd
    xchg   s2, eax
    stosd
    xchg   s3, eax
    stosd    
    popad
    ret
