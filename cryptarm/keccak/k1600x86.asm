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
  
struc kws_t
  bc1  resd 1 ; edi
  bc2  resd 1 ; esi
  bc3  resd 1 ; ebp
  bc4  resd 1 ; esp
  bc5  resd 1 ; ebx
  lfsr resd 1 ; edx
  ; ecx
  ; eax
  .size:
endstruc
  
    %ifndef BIN
      global k1600_permutex
      global _k1600_permutex
    %endif
    
; void k1600_permutex(void *state);    
k1600_permutex:
_k1600_permutex:
    push   rsi
    push   rdi
    push   rbx
    push   rbp
    
    push   rcx
    pop    rsi
    call   k1600_l0
    ; modulo 5    
    dd     003020100h, 002010004h, 000000403h
    ; rho pi
    dd     0110b070ah, 010050312h, 004181508h 
    dd     00d13170fh, 00e14020ch, 001060916h
k1600_l0:
    pop    rbx                  ; m + p
    push   24
    pop    rax
    cdq
    inc    rdx                  ; lfsr = 1    
    sub    rsp, 5*8 
    push   rsp
    pop    rdi                  ; rdi = bc  
k1600_l1:    
    push   rax    
    push   5 
    pop    rcx    
    push   rcx
    push   rdi
    push   rsi
theta_l0:
    ; Theta
    lodsq                       ; t  = st[i     ];  
    xor    rax, [rsi+ 5*8-8]    ; t ^= st[i +  5];
    xor    rax, [rsi+10*8-8]    ; t ^= st[i + 10];
    xor    rax, [rsi+15*8-8]    ; t ^= st[i + 15];
    xor    rax, [rsi+20*8-8]    ; t ^= st[i + 20];
    stosq                       ; bc[i] = t;
    loop   theta_l0        
    pop    rsi
    pop    rdi
    pop    rcx    
    xor    eax, eax    
theta_l1:
    movzx  ebp, byte[rbx+rax+4] ; ebp = m[(i + 4)];
    mov    rbp, [rdi+rbp*8]     ; t   = bc[m[(i + 4)]];    
    movzx  edx, byte[rbx+rax+1] ; edx = m[(i + 1)];
    mov    rdx, [rdi+rdx*8]     ; edx = bc[m[(i + 1)]];
    rol    rdx, 1               ; t  ^= ROTL32(edx, 1);
    xor    rbp, rdx
theta_l2:
    xor    [rsi+rax*8], rbp     ; st[j] ^= t;
    add    al, 5                ; j+=5 
    cmp    al, 25               ; j<25
    jb     theta_l2    
    sub    al, 24               ; i=i+1
    loop   theta_l1             ; i<5 
    ; *************************************
    ; Rho Pi
    ; *************************************
    mov    rbp, [rsi+1*8]       ; t = st[1];
rho_l0:
    lea    ecx, [rcx+rax-4]     ; r = r + i + 1;
    rol    rbp, cl              ; t = ROTL32(t, r); 
    movzx  edx, byte[rbx+rax+7] ; edx = p[i];
    xchg   [rsi+rdx*8], rbp     ; XCHG(st[p[i]], t);
    inc    eax                  ; i++
    cmp    al, 24+5             ; i<24
    jnz    rho_l0               ; 
    ; *************************************
    ; Chi
    ; *************************************
    xor    ecx, ecx             ; i = 0   
chi_l0:    
    push   rsi
    push   rdi
    ; memcpy(&bc, &st[i], 5*8);
    lea    rsi, [rsi+rcx*8]     ; esi = &st[i];
    mov    cl, 5
    rep    movsd
    pop    rdi
    pop    rsi
    xor    eax, eax
chi_l1:
    movzx  ebp, byte[ebx+eax+1]
    movzx  edx, byte[ebx+eax+2]
    mov    rbp, [rdi+rbp*8]     ; t = ~bc[m[(i + 1)]] 
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
    ;mov    al, [esp+kws_t+lfsr+4]; al = t = *LFSR
    mov    dl, 1                ; i = 1
    xor    ebp, ebp
iota_l0:    
    test   al, 1                ; t & 1
    je     iota_l1    
    lea    ecx, [edx-1]         ; ecx = (i - 1)
    cmp    cl, 64               ; skip if (ecx >= 32)
    jae    iota_l1    
    btc    rbp, rcx             ; c ^= 1ULL << (i - 1)
iota_l1:    
    add    al, al               ; t << 1
    sbb    ah, ah               ; ah = (t < 0) ? 0x00 : 0xFF
    and    ah, 0x71             ; ah = (ah == 0xFF) ? 0x71 : 0x00  
    xor    al, ah  
    add    dl, dl               ; i += i
    jns    iota_l0              ; while (i != 128)
    ;mov    [esp+kws_t+lfsr+4], al; save t
    xor    [rsi], rbp           ; st[0] ^= rc(&lfsr);      
    pop    rax
    dec    eax
    jnz    k1600_l1             ; rnds<22    
    add    rsp, 5*8             ; release bc
    pop    rbp
    pop    rbx
    pop    rdi
    pop    rsi
    ret
