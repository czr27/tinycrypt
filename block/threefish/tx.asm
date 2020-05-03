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
; Threefish-256/256 block cipher in AMD64 assembly (Encryption only)
;
; size: 205 bytes
;
; -----------------------------------------------

    bits 64
    
    %ifndef BIN
      global threefish
    %endif
    
threefish:
    push   rbx             ; save rbx
    push   rbp
    ; allocate 96-bytes of local memory
    push   96
    pop    rcx
    sub    rsp, rcx
    ; rbx = data
    push   rsi
    pop    rbx
    ; rsi = master key
    push   rdi
    pop    rsi
    ; rdi = &c[0]
    push   rsp
    pop    rdi
    ; copy 256-bit master key to local memory
    mov    cl, 4
    ; t = 0x1BD11BDAA9FC1A22;
    mov    rax, 0x1BD11BDAA9FC1A22
tx_L0:
    xor    rax, [rsi]       ; t ^= mk[i]
    movsq                   ; c[i] = mk[i]
    loop   tx_L0
    stosq                   ; c[4] = t
    ; copy 128-bit tweak to local memory
    mov    rax, [rsi]       ; t = mk[4]
    movsq                   ; c[5] = mk[4]
    xor    rax, [rsi]       ; t ^= mk[5]
    movsq                   ; c[6] = mk[5]
    stosq                   ; c[7] = c[5] ^ c[6]
    ; store rotational values
    ; c[8] = 0x203a2e190517340e
    mov    rax, 0x203a2e190517340e
    stosq
    ; c[9] = 0x20160c2125283910
    mov    rax, 0x20160c2125283910
    stosq
    push   rsp
    pop    rsi              ; rsi = &c[0]
    ; apply 72 rounds
    ; i=0
    xchg   eax, ecx
tf_main:
    ; add key every 4 rounds
    ; if (!(i & 3))
    test   al, 3
    je     add_key
tf_end:
    cdq                             ; j = 0
    cmp    al, 72                   ; if(i==72) break;
    jne    tf_mix
    
    add    rsp, 96
    pop    rbp
    pop    rbx
    ret
tf_mix:
    ; r=((B*)c)[8+(i%8)+(j<<2)], x[j] += x[j+1],
    mov    ecx, eax                 ; ecx = i % 8
    and    ecx, 7
    lea    ecx, [ecx+4*edx]         ; ecx += (j<<2)
    movzx  ecx, byte[rsi+rcx+64]    ; set r
    
    mov    rdi, [rbx+8*rdx+8]       ; rdi = x[j+1]
    add    [rbx+8*rdx], rdi         ; x[j] += rdi
    
    ; x[j+1] = R(x[j+1], r), x[j+1] ^= x[j];
    rol    rdi, cl                  ; rdi = R(rdi, cl)
    xor    rdi, [rbx+8*rdx]         ; rdi ^= x[j]
    mov    [rbx+8*rdx+8], rdi         ; x[j+1] = rdi
    
    add    dl, 2                    ; j += 2
    cmp    dl, 4                    ; j < 4
    jne    tf_mix
    
    ; permute
    ; t=x[1],x[1]=x[3],x[3]=t;
    mov    rdi, [rbx+8*1]           ;
    xchg   [rbx+8*3], rdi           ; X(x[1], x[3])
    mov    [rbx+8*1], rdi           ; 
    
    inc    al                       ; i++
    jmp    tf_main
    ; create subkey and add to block
add_key:
    xor    ecx, ecx                 ; j = 0
    xor    edi, edi                 ; t = 0
ak_L0:
    push   rax                      ; save i
    shr    eax, 2                   ; i /= 4
    push   rax                      ; save i/4
    ; x[j] += c[((i/4) + j) % 5] + t
    add    eax, ecx                 ; rax = (i/4) + j
    push   rax                      ; save (i/4) + j
    cdq                             ; rdx = 0
    push   5
    pop    rbp
    div    ebp                      ; 
    mov    rax, [rsi+8*rdx]         ; rax = c[(((i/4)+j)%5] 
    add    rax, rdi                 ; rax += t
    add    [rbx+8*rcx], rax         ; x[j] += rax
    ; t = (j < 2) ? c[(((i/4)+j) % 3) + 5] : i/4
    pop    rax                      ; restore (i/4) + j
    cdq
    push   3
    pop    rbp
    div    ebp
    pop    rdi                      ; restore i/4
    pop    rax                      ; restore i
    cmp    cl, 2                   
    cmovb  rdi, [rsi+8*rdx+5*8]     ; (j<2)
    inc    cl
    cmp    cl, 4
    jne    ak_L0
    jmp    tf_end
    

