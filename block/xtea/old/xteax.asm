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
; XTEA Block Cipher in x86 assembly (Encryption only)
;
; size: 72 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
    
    %ifndef BIN
      global xtea_encryptx
      global _xtea_encryptx
    %endif

    %define v0  eax
    %define v1  ebx    

    %define x   ebp
    %define y   esi
    
    %define k   edi
    
    %define sum edx
    
xtea_encryptx:    
_xtea_encryptx:
    pushad
    mov    edi, [esp+32+4]   ; edi = key
    mov    esi, [esp+32+8]   ; esi = data
    push   64
    pop    ecx
    xor    edx, edx          ; sum = 0
    push   esi
    lodsd
    xchg   eax, v1
    lodsd
    xchg   eax, v1
xtea_enc:
    mov    x, v1             ; x   = v1 << 4
    shl    x, 4
    
    mov    y, v1             ; y   = v1 >> 5
    shr    y, 5    
    
    xor    x, y              ; x  ^= y
    add    x, v1             ; x  += v1;
    
    mov    y, sum            ; y   = sum
    test   cl, 1
    jz     xtea_l1
    
    add    sum, 0x9E3779B9   ; sum += 0x9E3779B9   
    mov    y, sum     
    shr    y, 11             ; y = sum >> 11  
xtea_l1:    
    and    y, 3              ; y  &= 3
    mov    y, [k+4*y]        ; y = sum + k[y]
    add    y, sum
    
    xor    x, y              ; x ^= y
    
    add    v0, x             ; v0 += x
    xchg   v0, v1            ; XCHG(v0, v1); 
    loop   xtea_enc    
    
    pop    edi               ; edi = v
    stosd                    ; v[0] = v0
    xchg   eax, v1
    stosd                    ; v[1] = v1
    popad
    ret    
    
    