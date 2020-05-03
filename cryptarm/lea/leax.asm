;
;  Copyright © 2017 Odzhan, Peter Ferrie. All Rights Reserved.
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
; LEA-128/128 Block Cipher in x86 assembly (Encryption only)
;
; size: 136 bytes (careful of rotates, bug)
;
; global calls use cdecl convention
;
; -----------------------------------------------

    %ifndef BIN
      global lea128_encryptx
      global _lea128_encryptx
    %endif

    bits 32

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

; key
%define k0 ebx
%define k1 edx
%define k2 edi
%define k3 ebp

; plain text
%define x0 dword[esi+4*0]
%define x1 dword[esi+4*1]
%define x2 dword[esi+4*2]
%define x3 dword[esi+4*3]

%define t0 ecx

%define LEA128_RNDS 24

lea128_encryptx:
_lea128_encryptx:
    pushad
    ; initialize 4 constants
    mov    edi, 0xc3efe9db   ; c0
    mov    esi, 0x88c4d604   ; c1
    mov    ebp, 0xe789f229   ; c2
    pushad
    mov    dword[esp+_esp], 0xc6f98763   ; c3
    mov    esi, [esp+64+4]   ; esi = key
    ; load key
    lodsd
    xchg   eax, k0
    lodsd
    xchg   eax, k1
    lodsd
    xchg   eax, k2
    lodsd
    xchg   eax, k3
    mov    esi, [esp+64+8]   ; esi = data
    xor    eax, eax          ; i = 0
lea_l0:
    push   eax
    ; t0 = ROTR32(c[i % 4], 28);
    ; c[i % 4] = t0;    
    and    al, 3
    mov    t0, [esp+eax*4+4]
    ror    dword[esp+eax*4+4], 28
    ; **************************************
    ; create sub key
    ; **************************************
    ; k0 = ROTR32(k0 + c0, 31);
    add    k0, t0
    rol    k0, 1
    ; k1 = ROTR32(k1 + ROTR32(c0, 31), 29);
    rol    t0, 1
    add    k1, t0
    ror    k1, 29
    ; k2 = ROTR32(k2 + ROTR32(c0, 30), 26);
    ror    t0, 1
    add    k2, t0
    ror    k2, 26
    ; k3 = ROTR32(k3 + ROTR32(c0, 29), 21);
    ror    t0, 1
    add    k3, t0
    ror    k3, 21
    ; **************************************
    ; encrypt block
    ; **************************************
    ; t0 = x0;
    push   x0
    ; x0 = ROTR32((x0 ^ k0) + (x1 ^ k1),23);
    mov    t0, x1
    xor    x0, k0
    xor    t0, k1
    add    x0, t0
    ror    x0, 23
    ; x1 = ROTR32((x1 ^ k2) + (x2 ^ k1), 5);
    mov    t0, x2
    xor    x1, k2
    xor    t0, k1
    add    x1, t0
    ror    x1, 5
    ; x2 = ROTR32((x2 ^ k3) + (x3 ^ k1), 3);
    mov    t0, x3
    xor    x2, k3
    xor    t0, k1
    add    x2, t0
    ror    x2, 3
    ; x3 = t0;
    pop    x3
    pop    eax
    ; i++;
    inc    eax
    ; i<LEA128_RNDS
    cmp    al, LEA128_RNDS
    jnz    lea_l0

    popad
    popad
    ret

