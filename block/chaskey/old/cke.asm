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
;
; -----------------------------------------------
; Chaskey-LTS block cipher in x86 assembly (encryption only)
;
; size: 89 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32

%ifndef BIN
  global chas_encryptx
  global _chas_encryptx
%endif

%define v0 eax
%define v1 ebx
%define v2 edx
%define v3 ebp

chas_encryptx:
_chas_encryptx:
    pushad
    mov     edi, [esp+32+ 8]
    mov     esi, [esp+32+12]
    push    esi
    ; load buf
    lodsd
    xchg    eax, v3
    lodsd
    xchg    eax, v1
    lodsd
    xchg    eax, v2
    lodsd
    xchg    eax, v3
    ; pre-whiten
    xor     v0, [edi   ]
    xor     v1, [edi+ 4]
    xor     v2, [edi+ 8]
    xor     v3, [edi+12]
    ; 16 rounds
    push    16
    pop     ecx
ck_l0:    
    ; apply permutation
    add     v0, v1
    rol     v1, 5
    xor     v1, v0
    rol     v0, 16
    add     v2, v3
    rol     v3, 8
    xor     v3, v2
    add     v0, v3
    rol     v3, 13
    xor     v3, v0
    add     v2, v1
    rol     v1, 7
    xor     v1, v2
    rol     v2, 16
    loop    ck_l0
    ; post-whiten
    xor     v0, [edi   ]
    xor     v1, [edi+ 4]
    xor     v2, [edi+ 8]
    xor     v3, [edi+12]
    pop     edi
    ; save buf
    stosd
    xchg    eax, v1
    stosd
    xchg    eax, v2
    stosd
    xchg    eax, v3
    stosd
    popad
    ret
