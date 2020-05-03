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
; RC5 Block Cipher in x86 assembly (Encryption only)
;
; https://people.csail.mit.edu/rivest/Rivest-rc5rev.pdf
;
; size: 120 bytes for single call
;
; global calls use cdecl convention
;
; -----------------------------------------------

  bits 32
  
%ifndef BIN
  global rc5
  global _rc5
%endif

%define RC5_ROUNDS  12    ; 20 to strengthen against weakness

%define RC5_KR      (2*(RC5_ROUNDS+1))

; rc5(void *key, void *data) 
_rc5:
rc5:
    pushad
    mov    esi, [esp+32+4]     ; edi = key / L
    mov    ebx, [esp+32+8]     ; esi = data
    xor    ecx, ecx            ; ecx = 0
    mov    cl, RC5_KR*4+16     ; allocate space for key and sub keys
    sub    esp, ecx            ; esp = S
    ; copy 128-bit key to local buffer
    mov    edi, esp            ; edi = L
    mov    cl, 16
    rep    movsb
    ; initialize S / sub keys 
    mov    eax, 0xB7E15163     ; eax = RC6_P
    mov    cl, RC5_KR
    push   edi    
init_subkeys:
    stosd
    add    eax, 0x9E3779B9     ; A += RC6_Q
    loop   init_subkeys
    pop    edi
    mov    esi, ebx            ; esi = data
    mul    ecx                 ; eax = 0, edx = 0
    xor    ebx, ebx            ; ebx = 0
set_idx:    
    xor    ebp, ebp            ; i % RC6_KR    
init_key_loop:
    cmp    ebp, RC5_KR
    je     set_idx    

    ; A = S[i%RC6_KR] = ROTL32(S[i%RC5_KR] + A+B, 3); 
    add    eax, ebx            ; A += B
    add    eax, [edi+ebp*4]    ; A += S[i%RC5_KR]
    rol    eax, 3              ; A  = ROTL32(A, 3)
    mov    [edi+ebp*4], eax    ; S[i%RC6_KR] = A
    
    ; B = L[i%4] = ROTL32(L[i%4] + A+B, A+B);
    add    ebx, eax            ; B += A
    mov    ecx, ebx            ; save A+B in ecx
    push   edx                 ; save i
    and    dl, 3               ; %= 4
    add    ebx, [edi+edx*4-16] ; B += L[i%4]    
    rol    ebx, cl             ; B = ROTL32(B, A+B)
    mov    [edi+edx*4-16], ebx ; L[i%4] = B    
    pop    edx                 ; restore i    
    inc    ebp
    inc    edx                 ; i++
    cmp    dl, RC5_KR*3        ; i<RC6_KR*3
    jnz    init_key_loop    
    
    push   esi                 ; save ptr to data    
    lodsd                      ; eax = x->w[0]
    add    eax, [edi]          ; A  += *k; k++;
    scasd
    xchg   eax, ebx            ; XCHG(A, B);
    lodsd                      ; eax = x->w[1]
    mov    dl, RC5_KR - 1   
    jmp    mix_key
enc_loop:
    ; A = ROTL32(A ^ B, B) + *k*; k++;
    xor   eax, ebx             ; A ^= B 
    mov   ecx, ebx             ; ecx = B 
    rol   eax, cl              ; A = ROTL32(A ^ B, B)
mix_key:     
    add   eax, [edi]           ; A += *k; k++;
    scasd
    xchg  eax, ebx             ; XCHG(A, B);
    dec   edx
    jnz   enc_loop    
    
    pop   esp                  ; restore ptr to data    
    xchg  esp, edi
    stosd                      ; x->w[0] = A
    xchg  eax, ebx
    stosd                      ; x->w[1] = B         
    popad
    ret
