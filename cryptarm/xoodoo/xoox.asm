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
; Xoodoo permutation function in x86-64 assembly
;
; size: 186 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

      bits 64

      %ifndef BIN
        global xoodoo
      %endif

%define x0 eax
%define x1 ebx
%define x2 edx

xoodoo:
    push   rdi
    push   rsi
    push   rbx
    push   rbp
    
    xor    eax, eax          ; r = 0
    push   32
    pop    rcx
    
    sub    rsp, rcx          ; allocate 32 bytes of memory
xoo_main:
    mov    cl, 4                ; i = 4
    cdq
    ;
    ; Theta
    ;
    ; e[i] = ROTR32(x[i] ^ x[i+4] ^ x[i+8], 18);
    ; e[i]^= ROTR32(e[i], 9);
xd_l1:
    mov    eax, [rdi+rdx*4]  ; eax  = x[i]
    xor    eax, [rdi+16]     ; eax ^= x[i+4]
    xor    eax, [rdi+32]     ; eax ^= x[i+8]
    ror    eax, 18
    mov    ebx, eax
    ror    ebx, 9
    xor    eax, ebx
    mov    [rsp+rdx*4], eax  ; e[i] = eax
    inc    rdx
    loop   xd_l1
    ; x[i]^= e[(i - 1) & 3];
    mov    edx, -1           ; edx = -1
    mov    cl, 12
xd_l2:
    mov    eax, edx          ; eax = edx & 3
    and    eax, 3
    mov    eax, [rsp+rax*4]  ; eax = e[(i - 1) & 3]
    inc    rdx               ; i++
    xor    [rdi+rdx*4], eax  ; x[i] ^= eax
    loop   xd_l2

    mov    cl, 4
xd_lx:
    ; XCHG(x[7], x[4]);
    mov    eax, [rdi+7*4]
    xchg   eax, [rdi+4*4]

    ; XCHG(x[4], x[5]);
    xchg   eax, [rdi+5*4]

    ; XCHG(x[5], x[6]);
    xchg   eax, [rdi+6*4]
    ; x[7] = x[6];
    mov    [rdi+7*4], eax

    ; x[0] ^= rc[r];
    call   ld_rc
    dw     0x58,  0x38, 0x3c0, 0xd0
    dw     0x120, 0x14,  0x60, 0x2c
    dw     0x380, 0xf0, 0x1a0, 0x12
ld_rc:
    pop    rbp                  ; ebx = rc
    movzx  ebp, word[rbp+rax*2] ; ebp = rc[r]
    xor    [rdi], ebp
    mov    cl, 4
xd_l6:
    ; x0 = x[i+0];
    mov    ebp, [rdi]

    ; x1 = x[i+4];
    mov    x1, [rdi+16]

    ; x2 = ROTR32(x[i+8], 21);
    mov    x2, [rdi+32]
    ror    x2, 21

    ; x[i+8] = ROTR32((~x0 & x1) ^ x2, 24);
    not    x0
    and    x0, x1
    xor    x0, x2
    ror    x0, 24
    mov    [rdi+32], x0

    ; x[i+4] = ROTR32((~x2 & x0) ^ x1, 31);
    mov    ebp, x2
    not    ebp
    and    ebp, [rdi]
    xor    ebp, x1
    rol    ebp, 1
    mov    [rdi+16], ebp

    ; x[i+0] ^= ~x1 & x2;
    not    x1
    and    x1, x2
    xor    [rdi], x1
    loop   xd_l6

    ; XCHG(x[8], x[10]);
    ; XCHG(x[9], x[11]);
    mov    rbp, [rdi+8*4]
    xchg   rbp, [rdi+10*4]
    mov    [rdi+8*4], rbp

    ; --r
    inc    al
    cmp    al, 12
    jnz    xoo_main

    ; release memory
    add    rsp, 32
    ; restore registers
    pop    rbp
    pop    rbx
    pop    rsi
    pop    rdi
    ret
