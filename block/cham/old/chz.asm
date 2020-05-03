;
;  Copyright © 2018 Odzhan. All Rights Reserved.
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
; CHAM-128/128 block cipher in x86 assembly
;
; size: 124 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

      bits 32
     
      %ifndef BIN
        global cham
        global _cham
      %endif
      
%define K 128   ; key length
%define N 128   ; block length
%define R 80    ; number of rounds
%define W 32    ; word length
%define KW K/W  ; number of words per key
     
%define x0 ebp
%define x1 ebx
%define x2 edx
%define x3 esi
%define rk edi

cham:
_cham:
    pushad
    mov    esi, [esp+32+4]  ; k = key
    mov    ebp, [esp+32+8]  ; x = data
    pushad                  ; allocate 2*KW
    mov    edi, esp         ; edi = rk    
    xor    eax, eax         ; i  = 0
sk_l0:
    mov    ebx, [esi+eax*4] ; ebx = k[i]
    mov    ecx, ebx         ; ecx = k[i]
    mov    edx, ebx         ; edx = k[i]    
    rol    ebx, 1           ; ROTL32(k[i], 1)
    rol    ecx, 8           ; ROTL32(k[i], 8)    
    xor    edx, ebx         ; k[i] ^ ROTL32(k[i], 1) 
    xor    edx, ecx  
    mov    [edi+eax*4], edx ; rk[i] = edx
    xor    edx, ecx         ; reset edx
    rol    ecx, 3           ; k[i] ^ ROTL32(k[i], 11)
    xor    edx, ecx    
    lea    ebx, [eax+KW]
    xor    ebx, 1
    mov    [edi+ebx*4], edx ; rk[(i + KW) ^ 1] = edx
    inc    eax
    cmp    al, KW
    jnz    sk_l0    
    
    xchg   esi, ebp
    push   esi
    lodsd
    xchg   eax, x0
    lodsd
    xchg   eax, x1
    lodsd
    xchg   eax, x2
    lodsd
    xchg   eax, x3
    xor    eax, eax ; i = 0
    ; initialize sub keys
enc_l0: 
    mov    edi, ebp  ; k = keys
    jmp    enc_lx    
enc_l1:
    test   al, 7    ; i & 7
    jz     enc_l0
enc_lx:    
    push   eax      ; save i
    mov    cx, 0x0108
    test   al, 1    ; if ((i & 1)==0)
    jnz    enc_l2
    
    xchg   cl, ch
enc_l2:
    xor    x0, eax          ; x0 ^= i
    mov    eax, x1
    rol    eax, cl          ; 
    xor    eax, [edi]       ; ROTL32(x1, r0) ^ *rk++
    scasd
    add    x0, eax
    xchg   cl, ch
    rol    x0, cl
    
    xchg   x0, x1          ; XCHG(x0, x1);
    xchg   x1, x2          ; XCHG(x1, x2);
    xchg   x2, x3          ; XCHG(x2, x3);
    
    pop    eax      ; restore i
    inc    eax      ; i++
    cmp    al, R    ; i<R
    jnz    enc_l1
    
    pop    edi
    xchg   eax, x0
    stosd           ; x[0] = x0;
    xchg   eax, x1
    stosd           ; x[1] = x1;
    xchg   eax, x2
    stosd           ; x[2] = x2;
    xchg   eax, x3
    stosd           ; x[3] = x3;
    popad
    ret
    
    
