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
; Chaskey Message Authentication Code
;
; size: 229 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32

    %ifndef BIN
      global chaskey_setkey   
      global _chaskey_setkey   
      
      global chaskey_mac
      global _chaskey_mac   
    %endif
        
    %define k0 ebp
    %define k1 ebx
    %define k2 ecx
    %define k3 edx
        
chaskey_setkey:
_chaskey_setkey:
    pushad
    mov    edi, [esp+32+4]   ; edi = out
    mov    esi, [esp+32+8]   ; esi = in
    push   edi
    movsd
    movsd
    movsd
    movsd
    pop    esi
    clc
sk_l0:
    pushfd

    lodsd
    xchg   eax, k0
    lodsd
    xchg   eax, k1
    lodsd
    xchg   eax, k2
    lodsd
    xchg   eax, k3

    lea    eax, [k0+k0]
    add    k3, k3
    push   k3
    sbb    dl, dl
    and    dl, 0x87
    xor    al, dl   
    stosd
    
    lea    eax, [k1+k1]
    shr    k0, 31
    or     eax, k0
    stosd
    
    lea    eax, [k2+k2]
    shr    k1, 31
    or     eax, k1
    stosd
    
    pop    eax
    shr    k2, 31
    or     eax, k2
    stosd

    popfd
    cmc
    jc     sk_l0
    
    popad
    ret
    
%define x0 eax    
%define x1 edx    
%define x2 ebp    
%define x3 ebx
    
; ecx = 16    
; edi = x
permute:
    pushad
    mov    cl, 12
    mov    esi, edi
    lodsd
    xchg   eax, x3
    lodsd
    xchg   eax, x1
    lodsd
    xchg   eax, x2
    lodsd
    xchg   eax, x3
cp_l0:
    add    x0, x1 ; x[0] += x[1];
    ror    x1, 27 ; x[1] = R(x[1],27) ^ x[0];
    xor    x1, x0
    add    x2, x3 ; x[2] += x[3];
    ror    x3, 24 ; x[3] = R(x[3],24) ^ x[2];
    xor    x3, x2
    add    x2, x1 ; x[2] += x[1];
    ror    x0, 16 ; x[0] = R(x[0],16) + x[3];
    add    x0, x3
    ror    x3, 19 ; x[3] = R(x[3],19) ^ x[0];
    xor    x3, x0  
    ror    x1, 25 ; x[1] = R(x[1],25) ^ x[2];
    xor    x1, x2
    ror    x2, 16 ; x[2] = R(x[2],16);
    loop   cp_l0
    stosd
    xchg   eax, x1
    stosd
    xchg   eax, x2
    stosd
    xchg   eax, x3
    stosd
    popad   
    ret
    
; ecx = length
; esi = input
; edi = v   
chas_xor:
    pushad
    jecxz  cx_l1
cx_l0:    
    mov    al, [esi]
    xor    [edi], al
    cmpsb
    loop   cx_l0
cx_l1:    
    popad
    ret    
    
; chaskey    
chaskey_mac:
_chaskey_mac:
    pushad
    lea    esi, [esp+32+4]
    pushad                   ; allocate 32 bytes
    mov    edi, esp          ; edi = v
    lodsd
    xchg   eax, ebp          ; ebp = tag ptr
    lodsd
    xchg   eax, ebx          ; ebx = msg ptr
    lodsd
    xchg   edx, eax          ; edx = msglen
    lodsd
    xchg   eax, esi          ; esi = key

    ; copy 128-bit master key to local memory
    ; F(16) v[i] = k[i];
    push   16
    pop    ecx
    push   edi               ; save v
    rep    movsb
    pop    edi               ; restore v
    push   esi               ; save &key[16]
    mov    esi, ebx          ; esi = msg    
    ; absorb message
cm_l0:
    mov    cl, 16
    ; r = (len > 16) ? 16 : len;
    cmp    edx, ecx
    cmovb  ecx, edx
    
    ; xor v with msg data
    ; F(r) v[i] ^= p[i];
    call   chas_xor
    mov    cl, 16
    
    ; final block?
    ; if (len <= 16) {
    cmp    edx, ecx
    jbe    cm_l2
    
    call   permute

    ; len -= 16
    sub    edx, ecx
    ; p += 16
    add    esi, ecx
    
    jmp    cm_l0
cm_l2:    
    pop    esi
    ; if (len < 16) {
    je     cm_l3
    ; v[len] ^= 1;
    xor    byte[edi+edx], 1
    ; k += (len == 16) ? 16 : 32;
    add    esi, ecx 
cm_l3:   
    ; mix key
    ; F(16) v[i] ^= k[i];
    call   chas_xor
    ; permute(v);
    call   permute
    ; F(16) v[i] ^= k[i];
    call   chas_xor
    ; F(16) t[i] = k[i];
    mov    esi, edi
    mov    edi, ebp
    rep    movsb
        
    popad
    popad
    ret
    
    
