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
; Keccak-p[1600, 24] in x64 assembly
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
      global k1600_permutex
      global _k1600_permutex
    %endif
    
; void k1600_permutex(void *state);    
k1600_permutex:
_k1600_permutex:
                pushx  rax, rbx, rcx, rdx, rsi, rdi, rbp
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
                inc    dl                   ; lfsr = 1    
                sub    rsp, 6*8             ; create local space
                mov    rdi, rsp             ; edi = bc   
k1600_l1:    
                push   rax
theta_l0:
                ; Theta
                mov    rax, [rsi+rax     ]  ; t  = st[i     ];  
                xor    rax, [rsi+rax+05*8]  ; t ^= st[i +  5];
                xor    rax, [rsi+rax+10*8]  ; t ^= st[i + 10];
                xor    rax, [rsi+rax+15*8]  ; t ^= st[i + 15];
                xor    rax, [rsi+rax+20*8]  ; t ^= st[i + 20];
                mov    [rdi+rax], rax       ; bc[i] = t;
                add    al, 8
                cmp    al, 5*8
                jnz    theta_l0
                
                xor    eax, eax    
theta_l1:
                movzx  ebp, byte[rbx+rax+4] ; ebp = m[(i + 4)];
                mov    rbp, [rdi+rbp*4]     ; t   = bc[m[(i + 4)]];    
                movzx  edx, byte[rbx+rax+1] ; edx = m[(i + 1)];
                mov    rdx, [rdi+rdx*4]     ; edx = bc[m[(i + 1)]];
                rol    rdx, 1               ; t  ^= ROTL64(edx, 1);
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
                mov    rbp, [esi+1*8]       ; t = st[1];
rho_l0:
                lea    ecx, [ecx+eax-4]     ; r = r + i + 1;
                rol    rbp, cl              ; t = ROTL64(t, r); 
                movzx  edx, byte[rbx+rax+7] ; edx = p[i];
                xchg   [rsi+rdx*8], rbp     ; XCHG(st[p[i]], t);
                inc    al                  ; i++
                cmp    al, 24+5             ; i<24
                jnz    rho_l0               ; 
                
                ; *************************************
                ; Chi
                ; *************************************
                xor    ecx, ecx             ; i = 0   
chi_l0:    
                ; memcpy(&bc, &st[i], 5*8);
                lea    rsi, [rsi+rcx*8]     ; esi = &st[i];
                mov    cl, (5*8)/4
                rep    movsd
                
                xor    eax, eax
chi_l1:
                movzx  ebp, byte[rbx+rax+1]
                movzx  edx, byte[rbx+rax+2]
                mov    rbp, [rdi+rbp*8]     ; t = ~bc[m[(i + 1)]] 
                not    rbp            
                and    rbp, [rdi+rdx*8]
                lea    rdx, [rax+rcx]       ; edx = j + i    
                xor    [rsi+rdx*8], rbp     ; st[j + i] ^= t;  
                add    al, 1                ; j++
                cmp    al, 5                ; j<5
                jnz    chi_l1
                
                add    cl, al               ; i+=5;
                cmp    cl, 25               ; i<25
                jb     chi_l0
                
                ; Iota
                mov    dl, 1                ; i = 1
                xor    ebp, ebp
iota_l0:    
                test   al, 1                ; t & 1
                je     iota_l1 
                
                lea    rcx, [rdx-1]         ; ecx = (i - 1)
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
                
                xor    [rsi], rbp           ; st[0] ^= rc(&lfsr);      
                pop    rax
                dec    rax                  ; --rnds
                jnz    k1600_l1             ; rnds<24
                
                add    rsp, 6*8
                
                popx   rax, rbx, rcx, rdx, rsi, rdi, rbp
                ret
