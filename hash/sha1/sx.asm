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
; SHA-1 permutation function in x86 assembly
;
; size: 191 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
    
    %ifndef BIN
      global sha1_compress
      global _sha1_compress
    %endif

    %define _a [edi   ]
    %define _b [edi+ 4]
    %define _c [edi+ 8]
    %define _d [edi+12]
    %define _e [edi+16]

sha1_compress:
_sha1_compress:
    pushad
    mov    esi, [esp+32+4] ; sha1_ctx
    
    ; allocate 512 bytes of local memory for state and expanded buffer
    sub    esp, 80*4+20
    mov    edi, esp
    
    ; load the 160-bit state
    ; F(5)x[i]=c->s[i];
    push   esi
    push   5
    pop    ecx
    rep    movsd
    
    ; load buffer in big endian order
    ; F(16)w[i]=rev32(c->x.w[i]);
    mov    cl, 16
sha1_L0:
    lodsd
    bswap  eax
    stosd
    loop   sha1_L0
    
    ; expand buffer
    ; for(i=16;i<80;i++)
    ;   w[i]=R(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
    mov    cl, 64
sha1_L2:
    mov    eax, [edi -  3*4]
    xor    eax, [edi -  8*4]
    xor    eax, [edi - 14*4]
    xor    eax, [edi - 16*4]
    rol    eax, 1
    stosd
    loop   sha1_L2
    
    pop    esi
    
    mov    edi, esp
    xchg   eax, ecx     ; i = 0
    ; permute
sha1_L3:
    mov    edx, _c
    cmp    al, 20
    jae    sha1_L4
    ; t = FF(x[1],x[2],x[3])+0x5A827999L;
    xor    edx, _d
    and    edx, _b
    xor    edx, _d
    add    edx, 0x5A827999
    jmp    sha1_L7
sha1_L4:
    cmp    al, 40
    jae    sha1_L5
    ; t = HH(x[1],x[2],x[3])+0x6ED9EBA1L;
    xor    edx, _d
    xor    edx, _b
    add    edx, 0x6ED9EBA1
    jmp    sha1_L7
sha1_L5:
    cmp    al, 60
    jae    sha1_L6
    ; t = GG(x[1],x[2],x[3])+0x8F1BBCDCL;
    mov    ebp, edx
    or     edx, _d
    and    edx, _b
    and    ebp, _d
    or     edx, ebp
    add    edx, 0x8F1BBCDC
    jmp    sha1_L7
sha1_L6
    ; t = HH(x[1],x[2],x[3])+0xCA62C1D6L;
    xor    edx, _d
    xor    edx, _b
    add    edx, 0xCA62C1D6
sha1_L7:
    ; t+=R(x[0],5)+x[4]+w[i];
    mov    ebp, _a
    rol    ebp, 5
    add    ebp, _e
    add    edx, ebp
    add    edx, [edi+4*eax+20]
    
    ; x[4]=x[3];x[3]=x[2];x[2]=R(x[1],30);x[1]=x[0];x[0]=t;
    mov    ebp, _d
    mov    _e, ebp
    mov    ebp, _c
    mov    _d, ebp
    mov    ebp, _b
    rol    ebp, 30
    mov    _c, ebp
    mov    ebp, _a
    mov    _b, ebp
    mov    _a, edx
    
    inc    eax             ; i++
    cmp    al, 80          ; i<80
    jne    sha1_L3

    ; update state and return
    ; F(5)c->s[i]+=x[i];
    push   5
    pop    ecx
sha1_L8:
    mov    edx, [edi]      ; eax=x[i]
    add    [esi], edx      ; c->s[i] += edx
    cmpsd                  ; advance esi + edi
    loop   sha1_L8
    
    lea    esp, [edi+4*eax]
    popad
    ret
    
