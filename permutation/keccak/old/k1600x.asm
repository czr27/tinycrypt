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
; Keccak-p[800, 24] in x86 assembly
;
; size: 236 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------
    bits   64
  
    %macro  pushx 1-*
      %rep  %0
        push    %1
      %rotate 1
      %endrep
    %endmacro

    %macro  popx 1-*

      %rep %0
      %rotate -1
        pop     %1
      %endrep

    %endmacro
    
    %ifndef BIN
      global k1600
    %endif
    
; void k1600(void *state);    
k1600:
    pushx  rax, rbx, rcx, rdx, rsi, rdi, rbp
    
    sub    rsp, 5*8
    lea    rbx, [rel k1600_v]
    push   rdi                  ; rsi = s
    pop    rsi 
    push   rsp                  ; rdi = b
    pop    rdi
    xor    eax, eax             ; n = 0
k1600_l1:    
    push   rax                  ; save n
    push   5                    ; ecx = 5
    pop    rcx    
    push   rcx                  ; save 5
    push   rdi                  ; save b
    push   rsi                  ; save s
theta_l0:
    ; Theta
    lodsq                       ; t  = s[i     ];  
    xor    rax, [rsi+ 5*8-8]    ; t ^= s[i +  5];
    xor    rax, [rsi+10*8-8]    ; t ^= s[i + 10];
    xor    rax, [rsi+15*8-8]    ; t ^= s[i + 15];
    xor    rax, [rsi+20*8-8]    ; t ^= s[i + 20];
    stosq                       ; b[i] = t;
    loop   theta_l0        
    pop    rsi                  ; restore s
    pop    rdi                  ; restore b
    pop    rcx                  ; rcx = 5
    xor    eax, eax             ; j = 0
theta_l1:
    movzx  ebp, byte[rbx+rax+4] ; t = b[m[(i + 4)]];
    mov    rbp, [rdi+rbp*8]     ;     
    movzx  edx, byte[rbx+rax+1] ; rdx = b[m[(i + 1)]];
    mov    rdx, [rdi+rdx*8]     ; 
    rol    rdx, 1               ; t ^= ROTL64(rdx, 1);
    xor    rbp, rdx
theta_l2:
    xor    [rsi+rax*8], rbp     ; s[j] ^= t;
    add    al, 5                ; j+=5 
    cmp    al, 25               ; j<25
    jb     theta_l2    
    sub    al, 24               ; i=i+1
    loop   theta_l1             ; i<5 
    ; *************************************
    ; Rho Pi
    ; *************************************
    mov    rbp, [rsi+1*8]       ; t = s[1];
rho_l0:
    lea    ecx, [rcx+rax-4]     ; r = r + i + 1;
    rol    rbp, cl              ; t = ROTL64(t, r); 
    movzx  edx, byte[rbx+rax+7] ; edx = p[i];
    xchg   [rsi+rdx*8], rbp     ; XCHG(s[p[i]], t);
    inc    eax                  ; i++
    cmp    al, 24+5             ; i<24
    jnz    rho_l0               ; 
    ; *************************************
    ; Chi
    ; *************************************
    xor    ecx, ecx             ; i = 0   
chi_l0:    
    push   rsi                  ; save s
    push   rdi                  ; save b
    ; memcpy(&b, &s[i], 5*8);
    lea    rsi, [rsi+rcx*8]     ; esi = &s[i];
    mov    cl, 5
    rep    movsd
    pop    rdi                  ; restore b
    pop    rsi                  ; restore s
    xor    eax, eax             ; i = 0
chi_l1:
    movzx  ebp, byte[rbx+rax+1]
    movzx  edx, byte[rbx+rax+2]
    mov    rbp, [rdi+rbp*8]     ; t = ~b[m[(i + 1)]] 
    not    rbp            
    and    rbp, [rdi+rdx*8]
    lea    edx, [rax+rcx]       ; edx = j + i    
    xor    [rsi+rdx*8], rbp     ; st[j + i] ^= t;  
    inc    eax                  ; j++
    cmp    al, 5                ; j<5
    jnz    chi_l1        
    add    cl, al               ; i+=5;
    cmp    cl, 25               ; i<25
    jb     chi_l0
    
    ; Iota
    xor    eax, eax             ; j = 0
iota_L0:
    push   r8
    pop    rbp
    shr    ebp, 7
    imul   ebp, ebp, 113
    inc    al
    cmp    al, 7
    jne    iota_L0
         
    pop    rax                  ; restore n
    inc    al
    cmp    al, 24               ; n<24
    jne    k1600_l1
    
    add    rsp, 5*8             ; release bc
    popx   rax, rbx, rcx, rdx, rsi, rdi, rbp
    ret

    // F(j,7)
    mov     j, 0                // j = 0
    mov     d, 113
L9:
    // if((c=(c<<1)^((c>>7)*113))&2)
    lsr     t, c, 7             // t = c >> 7
    mul     t, t, d             // t = t * 113 
    eor     c, t, c, lsl 1      // c = t ^ (c << 1)
    and     c, c, 255           // c = c % 256 
    tbz     c, 1, L10           // if (c & 2)
    
    //   *s^=1ULL<<((1<<j)-1);
    mov     v, 1                // v = 1
    lsl     u, v, j             // u = v << j 
    sub     u, u, 1             // u = u - 1
    lsl     v, v, u             // v = v << u
    ldr     t, [s]              // t = s[0]
    eor     t, t, v             // t ^= v
    str     t, [s]              // s[0] = t
L10:    
    add     j, j, 1             // j = j + 1
    cmp     j, 7                // j < 7
    bne     L9
    
k1600_v:
    ; modulo 5    
    dd     003020100h, 002010004h, 000000403h
    ; rho pi
    dd     0110b070ah, 010050312h, 004181508h 
    dd     00d13170fh, 00e14020ch, 001060916h
