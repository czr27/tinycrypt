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
;
; -----------------------------------------------
; BlaBla stream cipher in AMD64 assembly
;
; size: 313 bytes
;
; global calls use Linux/ABI calling convention
;
; -----------------------------------------------


    bits 64
    
    %ifndef BIN
      global blabla_setkey
      global blabla_encrypt
      global blabla_keystream
    %endif
    
blabla_iv1:
    dq     0x6170786593810fab
    dq     0x3320646ec7398aee
    dq     0x79622d3217318274
    dq     0x6b206574babadada
blabla_iv2:
    dq     0x2ae36e593e46ad5f
    dq     0xb68f143029225fc9
    dq     0x8da1e08468303aa6
    dq     0xa48a209acd50a4a7
    dq     0x7fdc12f23f90778c
    
; void blabla_setkey(blabla_ctx *c, const void *key, const void *nonce) 
blabla_setkey:
    push   rsi                  ; save key
    ; copy 4 IV
    lea    rsi, [rel blabla_iv1]
    push   (4*8)/4
    pop    rcx
    rep    movsd
    pop    rsi                  ; restore key
    ; copy 256-bit key to internal state
    ; F(4) c->q[i+4] = k[i];
    mov    cl, 32/4
    rep    movsd
    ; copy 5 more IV
    lea    rsi, [rel blabla_iv2]
    mov    cl, (5*8)/4
    rep    movsd
    ; set 64-bit counter
    ; c->q[13] = 1; 
    push   1
    pop    rax
    stosq
    ; copy 128-bit nonce to internal state
    ; F(2)c->q[i+14]=n[i];
    push   rdx   
    pop    rsi
    movsq
    movsq
    ret    

blabla_v:
    dw     0c840H, 0d951H
    dw     0ea62H, 0fb73H
    dw     0fa50H, 0cb61H
    dw     0d872H, 0e943H
    
; void blabla_stream(blabla_ctx *s, void *out) 
blabla_stream:
    push    rbx
    push    rcx
    push    rsi
    push    rdi
    push    rbp
    
    ; store internal state in buffer
    ; F(16)x[i] = s->q[i];
    push    128/4
    pop     rcx
    xchg    rsi, rdi
    push    rsi               ; save s
    push    rdi               ; save out
    rep     movsd
    pop     rdi               ; restore out
    
    ; permute buffer
    ; F(80) {
    xor     eax, eax
bb_sx0:
    push    rax               ; save i
    ; d=v[i%8];
    and     al, 7 
    lea     rsi, [rel blabla_v]
    movzx   edx, word[rsi+rax*2]
    ; a=(d&15);b=(d>>4&15);
    mov     eax, edx          ; a = d & 15
    and     eax, 15           
    mov     ebx, edx          ; b = d >> 4 & 15
    shr     ebx, 4
    and     ebx, 15
    ; c=(d>>8&15);d>>=12;
    mov     ebp, edx          ; c = d >> 8 & 15
    shr     ebp, 8
    and     ebp, 15
    shr     edx, 12           ; d >>= 12
    
      ; for (r=0x7080C10;r;r>>=8)
    mov    ecx, 0x3F101820 ; load rotation values
bb_sx1:
    ; x[a] += x[b]
    mov    rsi, [rdi+rbx*8]
    add    [rdi+rax*8], rsi
    
    ; x[d] = R(x[d] ^ x[a], (r & 255))
    mov    rsi, [rdi+rdx*8]    
    xor    rsi, [rdi+rax*8]
    ror    rsi, cl
    mov    [rdi+rdx*8], rsi
    
    ; X(a, c); X(b, d);
    xchg   rax, rbp
    xchg   rbx, rdx 
    
    ; r >>= 8
    shr    ecx, 8       ; shift until done 
    jnz    bb_sx1
    
    pop    rax
    inc    al
    cmp    al, 80
    jnz    bb_sx0
    
    ; add internal state to buffer
    ; F(16)x[i] += s->q[i];
    pop     rsi         ; restore state
    push    16
    pop     rcx
bb_sx5:
    lodsq
    add     rax, [rdi]
    stosq
    loop    bb_sx5
    
    ; update 64-bit counter
    ; c->q[13]++;   
    inc     qword[rsi+13*8-128]
    
    pop     rbp
    pop     rdi
    pop     rsi
    pop     rcx
    pop     rbx
    ret
    
; void blabla_encrypt(blabla_ctx *ctx, void *buf, size_t len) 
blabla_encrypt:
    push    rbx               ; save rbx
    
    push    rsi               ; rbx = buf
    pop     rbx 
    
    push    rdx               ; rcx = len
    pop     rcx
    
    sub     rsp, 124
    push    rax
    push    rsp               ; rsi = c[128] 
    pop     rsi
bb_e0:
    jrcxz   bb_e3             ; exit if len==0
    ; blabla_stream(ctx, c);
    call    blabla_stream
    xor     eax, eax          ; i = 0
bb_e1:
    mov     dl, byte[rsi+rax] ;
    xor     byte[rbx], dl     ; *p ^= c[i]
    inc     rbx               ; p++
    inc     al                ; i++
    cmp     al, 128           ; i<128
    loopne  bb_e1             ; --len
    jmp     bb_e0
bb_e3:
    pop     rax
    add     rsp, 124
    pop     rbx               ; restore rbx
    ret

; generate key stream of len-bytes
; void blabla_keystream(blabla_ctx *c, void *buf, size_t len)    
blabla_keystream:
    push    rdi               ; save c
    ; F(len)((B*)buf)[i] = 0;
    push    rsi               ; rdi = buf
    pop     rdi
    push    rdx               ; rcx = len
    pop     rcx
    xor     eax, eax          ; eax = 0
    rep     stosb
    pop     rdi               ; rdi = c
    ; blabla_encrypt(c, buf, len);
    call    blabla_encrypt    
    ret    
    
