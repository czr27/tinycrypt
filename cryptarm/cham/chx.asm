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
; size: 120 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

      bits 32
     
      %ifndef BIN
        global cham128_encryptx
        global _cham128_encryptx
      %endif
      
struc pushad_t
  _edi resd 1
  _esi resd 1
  _ebp resd 1
  _esp resd 1
  _ebx resd 1
  _edx resd 1
  _ecx resd 1
  _eax resd 1
  .size:
endstruc
      
%define K 128   ; key length
%define N 128   ; block length
%define R 80    ; number of rounds
%define W 32    ; word length
%define KW K/W  ; number of words per key

%define k  esi     
%define k0 eax     
%define k1 ecx     
%define k2 edx     

%define rk edi

%define x0 ebp
%define x1 ebx
%define x2 edx
%define x3 esi
     
cham128_encryptx:
_cham128_encryptx:
    pushad
    mov    esi, [esp+32+4]  ; k  = in
    pushad
    mov    edi, esp         ; edi = rk    
    xor    ebx, ebx         ; i  = 0
sk_l0:
    lodsd                   ; k0  = k[i];
    mov    k1, k0           ; k1  = ROTR32(k0, 31);
    rol    k1, 1            ;
    mov    k2, k0           ; k2  = ROTR32(k0, 24); 
    ror    k2, 24        
    xor    k0, k1           ; k0 ^= k1;
    xor    k0, k2           ; rk[i] = k0 ^ k2;
    mov    [rk+ebx*4], k0
    xor    k0, k2           ; reset k0
    ror    k2, 29           ; k2 = ROTR32(k2, 29)
    xor    k0, k2    
    lea    ebp, [ebx+KW]    ; ebp = (i+KW)^1
    xor    ebp, 1
    mov    [rk+ebp*4], k0   ; rk[(i+KW)^1] = k0
    inc    ebx
    cmp    bl, KW
    jnz    sk_l0    

    ; perform encryption
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
    mov    edi, [esp+32+8] ; k = keys
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
    popad
    ret   
