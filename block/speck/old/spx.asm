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
; SPECK-128/256 block cipher in AMD64 assembly
;
; size: 83 bytes
;
; global calls use microsoft fastcall convention
;
; -----------------------------------------------

    %ifndef BIN
        global speck128
    %endif

    %define k0 rbx   
    %define k1 rcx    
    %define k2 rdx    
    %define k3 rdi

    %define x0 rbp    
    %define x1 rsi

speck128:   
    push   rbp
    push   rbx
    
    push   rsi
    mov    x0, [rsi  ]       ; x0 = data[0]
    mov    x1, [rsi+8]       ; x1 = data[1] 
    
    ; F(4)k[i]=((W*)mk)[i];
    mov    k0, [rdi   ]      ; k0 = mk[0]
    mov    k1, [rdi+ 8]      ; k1 = mk[1]
    mov    k2, [rdi+16]      ; k2 = mk[2]
    mov    k3, [rdi+24]      ; k3 = mk[3]
    
    xor    eax, eax          ; i = 0
spk_L0:
    ; x[1] = (R(x[1], 8) + x[0]) ^ k[0];
    ror    x1, 8
    add    x1, x0
    xor    x1, k0
    ; x[0] = R(x[0], 61) ^ x[1];
    ror    x0, 61
    xor    x0, x1
    ; k[1] = (R(k[1], 8) + k[0]) ^ i;
    ror    k1, 8
    add    k1, k0
    xor    cl, al            ; k1 ^= i
    ; k[0] = R(k[0], 61) ^ k[1];
    ror    k0, 61
    xor    k0, k1
    ; t = k[1], k[1] = k[2], k[2] = k[3], k[3] = t;
    xchg   k1, k2
    xchg   k2, k3
    ; i++
    inc    al
    cmp    al, 34    
    jnz    spk_L0
    
    pop    rax
    ; save 128-bit result
    mov    [rax  ], x0
    mov    [rax+8], x1
    pop    rbx
    pop    rbp
    ret   
