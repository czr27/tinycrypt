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
; SHACAL2 block cipher in x86 assembly
;
; size: 432 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------
    bits 32

    %define _a dword[edi+0*4]
    %define _b dword[edi+1*4]
    %define _c dword[edi+2*4]
    %define _d dword[edi+3*4]
    %define _e dword[edi+4*4]
    %define _f dword[edi+5*4]
    %define _g dword[edi+6*4]
    %define _h dword[edi+7*4]

    %define s0 eax
    %define s1 ebx
    %define i  ecx
    %define t1 edx
    %define t2 esi
    %define t3 ebp

shacal2:
_shacal2:
    pushad
    mov    esi, [esp+32+4]  ; esi = key
    mov    ebx, [esp+32+8]  ; ebx = data
    sub    esp, 512
    mov    edi, esp
    ; F(16)w[i]=rev32(k[i]);
    push   16
    pop    ecx
s_L0:
    lodsd
    bswap  eax
    stosd
    loop   s_L0
    ; for(i=16;i<64;i++)
    ;   w[i]=SIG1(w[i-2])+w[i-7]+SIG0(w[i-15])+w[i-16];
    mov    cl, 48
s_L1:
    mov    s0, [edi-15*4]
    mov    t1, s0
    mov    t2, s0
    ror    s0, 7
    ror    t1, 18
    shr    t2, 3
    xor    s0, t1
    xor    s0, t2
    mov    s1, [edi-2*4]
    mov    t1, s1
    mov    t2, s1
    ror    s1, 17
    ror    t1, 19
    shr    t2, 10
    xor    s1, t1
    xor    s1, t2
    add    s0, [edi-16*4]
    add    s1, [edi-7*4]
    add    s0, s1
    stosd
    loop   s_L1
    ; F(8)s[i]=rev32(x[i]);
    mov    cl, 8
s_L2:
    lodsd
    bswap  eax
    stosd
    loop   s_L2
s_L3:
    ; t1=s[7]+EP1(s[4])+CH(s[4],s[5],s[6])+w[i]+K[i];
    mov    s1, _e
    mov    t1, s1
    ror    s1, 25
    ror    t1, 6
    xor    s1, t1
    ror    t1, 11-6
    xor    s1, t1
    mov    t1, _f
    xor    t1, _g
    and    t1, _e
    xor    t1, _g
    add    t1, s1
    add    t1, _h
    ; t2=EP0(s[0])+MAJ(s[0],s[1],s[2]);s[7]=t1+t2;
    mov    t2, s0
    mov    t3, s0
    ror    s0, 22
    ror    t2, 2
    xor    s0, t2
    ror    t2, 13-2
    xor    s0, t2
    mov    t2, t3
    or     t2, _a
    and    t2, _b
    and    t3, _a
    or     t2, t3
    add    t2, s0
    add    _c, t1
    add    t2, t1
    mov    _g, t2
    inc    i
    cmp    i, 64
    jne    s_L3
    ; F(8)x[i]=rev32(s[i]);
    mov    cl, 8
s_L6:
    lodsd
    bswap  eax
    stosd
    loop   s_L6
    popad
    ret

_k dd 0428a2f98h, 071374491h, 0b5c0fbcfh, 0e9b5dba5h
   dd 03956c25bh, 059f111f1h, 0923f82a4h, 0ab1c5ed5h
   dd 0d807aa98h, 012835b01h, 0243185beh, 0550c7dc3h
   dd 072be5d74h, 080deb1feh, 09bdc06a7h, 0c19bf174h
   dd 0e49b69c1h, 0efbe4786h, 00fc19dc6h, 0240ca1cch
   dd 02de92c6fh, 04a7484aah, 05cb0a9dch, 076f988dah 
   dd 0983e5152h, 0a831c66dh, 0b00327c8h, 0bf597fc7h
   dd 0c6e00bf3h, 0d5a79147h, 006ca6351h, 014292967h 
   dd 027b70a85h, 02e1b2138h, 04d2c6dfch, 053380d13h
   dd 0650a7354h, 0766a0abbh, 081c2c92eh, 092722c85h 
   dd 0a2bfe8a1h, 0a81a664bh, 0c24b8b70h, 0c76c51a3h
   dd 0d192e819h, 0d6990624h, 0f40e3585h, 0106aa070h 
   dd 019a4c116h, 01e376c08h, 02748774ch, 034b0bcb5h
   dd 0391c0cb3h, 04ed8aa4ah, 05b9cca4fh, 0682e6ff3h 
   dd 0748f82eeh, 078a5636fh, 084c87814h, 08cc70208h
   dd 090befffah, 0a4506cebh, 0bef9a3f7h, 0c67178f2h
