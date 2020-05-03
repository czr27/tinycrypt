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
; SipHash for 64-bit hashes
;
; size: 210 bytes
;
; global calls use Microsoft x64 fastcall convention
;
; -----------------------------------------------
    bits 64
    
    %ifndef BIN
      global siphash  
    %endif
        
    ; don't change these    
    %define cROUNDS 2
    %define dROUNDS 4

    %define v0 rbx    
    %define v1 rbp    
    %define v2 rdx    
    %define v3 rdi

; int siphash(const uint8_t *in, const size_t inlen, const uint8_t *k,
;            uint8_t *out, const size_t outlen)
; system v abi RDI=in, RSI=inlen, RDX=k, RCX=out, R8=outlen, R9
siphash:
    push   rsi                ; save out
    ; initialize state
    mov    v0, [rdx]          ; v0 = k[0]
    mov    v1, [rdx+8]        ; v1 = k[1]
    push   v0                 ; v2 = v0
    pop    v2
    push   v1                 ; v3 = v1
    pop    v3
    mov    rax, 0x736f6d6570736575
    xor    v0, rax
    mov    rax, 0x646f72616e646f6d
    xor    v1, rax
    mov    rax, 0x6c7967656e657261
    xor    v2, rax
    mov    rax, 0x7465646279746573
    xor    v3, rax
    
    ; update state in 8-byte blocks
    push   rcx               ; save inlen
    shr    ecx, 3            ; inlen /= 8 
    jz     shx_l2
shx_l0:
    clc
    lodsq                    ; m = in[0]
    call   sipround
    loop   shx_l0
shx_l2:         
    pop    rcx               ; restore inlen
    push   rcx               ; save inlen
    pop    rax               ; rax=inlen
    push   rdx
    cdq
    shl    rax, 56           ; rax = inlen << 56
shx_l3:
    and    ecx, 7            ; inlen &= 7
    jz     shx_l4
    shl    rdx, 8            ; t <<= 8
    mov    dl, byte[rsi+rcx-1] ; t |= in[left]
    loop   shx_l3
shx_l4:    
    or     rax, rdx
    pop    rdx 
shx_l5:    
    pushfq                   ; save flags
    call   sipround
    popfq                    ; restore flags
    cmc                      ; CF=1 for last round
    jc     shx_l5
    push   v0
    pop    rax
    xor    rax, v1
    xor    rax, v2
    xor    rax, v3
    pop    rdi
    pop    rbp
    pop    rbx
    pop    rsi
    ret

; CF=0 for normal update    
; CF=1 for final update    
sipround:
    push   rcx               ; save rcx
    push   cROUNDS 
    pop    rcx
    jnc    sr_l0             ; skip if no carry
    
    xor    eax, eax          ; w=0 if last round
    add    ecx, ecx          ; assumes: cROUNDS=2, dROUNDS=4
    not    dl                ; requires edx to be v2
sr_l0:
    xor    v3, rax           ; v3 ^= w    
sr_l1:    
    add    v0, v1            ; v[0] += v[1];
    rol    v1, 13            ; v[1] = ROTL(v[1],13);
    xor    v1, v0            ; v[1] ^= v[0];
    rol    v0, 32            ; v[0] = ROTL(v[0], 32);
    add    v2, v3            ; v[2] += v[3]; 
    rol    v3, 16            ; v[3] = ROTL(v[3],16); 
    xor    v3, v2            ; v[3] ^= v[2]; 
    add    v0, v3            ; v[0] += v[3];
    rol    v3, 21            ; v[3] = ROTL(v[3],21);
    xor    v3, v0            ; v[3] ^= v[0];
    add    v2, v1            ; v[2] += v[1];
    rol    v1, 17            ; v[1] = ROTL(v[1], 17);
    xor    v1, v2            ; v[1] ^= v[2];
    rol    v2, 32            ; v[2] = ROTL(v[2], 32);
    loop   sr_l1
    xor    v0, rax           ; v0 ^= w
    pop    rcx               ; restore rcx
    ret  


