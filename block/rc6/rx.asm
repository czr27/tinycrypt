;
;  Copyright © 2015, 2017 Odzhan, Peter Ferrie. All Rights Reserved.
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
; RC6 block cipher in x86 assembly (encryption only)
;
; https://people.csail.mit.edu/rivest/pubs/RRSY98.pdf
;
; size: 170 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

        bits 32


        %ifndef BIN
          global rc6
          global _rc6
        %endif
        
%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))

%define A esi
%define B ebx
%define C edx
%define D ebp
        
rc6:
_rc6:
    pushad
    mov    esi, [esp+32+4]     ; edi = key / L
    mov    ebx, [esp+32+8]     ; esi = data
    xor    ecx, ecx            ; ecx = 0
    mov    cl, RC6_KR*4+32     ; allocate space for key and sub keys
    sub    esp, ecx            ; esp = S
    ; copy 256-bit key to local buffer
    mov    edi, esp            ; edi = L
    mov    cl, 32
    rep    movsb
    ; initialize S / sub keys 
    push   edi                 ; save S
    mov    eax, 0xB7E15163     ; eax = RC6_P
    mov    cl, RC6_KR    
init_subkeys:
    stosd                      ; S[i] = A
    add    eax, 0x9E3779B9     ; A += RC6_Q
    loop   init_subkeys
    pop    edi                 ; restore S
    mov    esi, ebx            ; esi = data
    mul    ecx                 ; eax = 0, edx = 0
    xor    ebx, ebx            ; ebx = 0
set_idx:    
    xor    ebp, ebp            ; i % RC6_KR    
init_key_loop:
    cmp    ebp, RC6_KR
    je     set_idx    

    ; A = S[i%RC6_KR] = ROTL32(S[i%RC6_KR] + A+B, 3); 
    add    eax, ebx            ; A += B
    add    eax, [edi+ebp*4]    ; A += S[i%RC6_KR]
    rol    eax, 3              ; A  = ROTL32(A, 3)
    mov    [edi+ebp*4], eax    ; S[i%RC6_KR] = A
    
    ; B = L[i%4] = ROTL32(L[i%4] + A+B, A+B);
    add    ebx, eax            ; B += A
    mov    ecx, ebx            ; save A+B in ecx
    push   edx                 ; save i
    and    dl, 7               ; %= 8
    add    ebx, [edi+edx*4-32] ; B += L[i%8]    
    rol    ebx, cl             ; B = ROTL32(B, A+B)
    mov    [edi+edx*4-32], ebx ; L[i%8] = B    
    pop    edx                 ; restore i    
    inc    ebp
    inc    edx                 ; i++
    cmp    dl, RC6_KR*3        ; i<RC6_KR*3
    jnz    init_key_loop   

    push   esi               ; save ptr to data    
    ; load plaintext
    lodsd
    push   eax               ; save A
    lodsd
    xchg   eax, B            ; load B
    lodsd
    xchg   eax, C            ; load C
    lodsd
    xchg   eax, D            ; load D
    pop    A                 ; restore A
    
    push   20                ; ecx = RC6_ROUNDS
    pop    ecx    
    ; B += *k; k++;
    add    B, [edi]
    scasd
    ; D += *k; k++;
    add    D, [edi]
    scasd
r6c_l3:
    push   ecx    
    ; T0 = ROTL32(B * (2 * B + 1), 5);
    lea    eax, [B+B+1]
    imul   eax, B
    rol    eax, 5
    ; T1 = ROTL32(D * (2 * D + 1), 5);
    lea    ecx, [D+D+1]
    imul   ecx, D
    rol    ecx, 5
    ; A = ROTL32(A ^ T0, T1) + *k; k++;
    xor    A, eax
    rol    A, cl       ; T1 should be ecx
    add    A, [edi]    ; += *k; 
    scasd              ; k++;
    ; C = ROTL32(C ^ T1, T0) + *k; k++;
    xor    C, ecx      ; C ^= T1
    xchg   eax, ecx    ; 
    rol    C, cl       ; rotate by T0
    add    C, [edi]
    scasd
    ; swap
    xchg   D, eax
    xchg   C, eax
    xchg   B, eax
    xchg   A, eax
    xchg   D, eax
    ; decrease counter
    pop    ecx
    loop   r6c_l3
    
    ; A += *k; k++;
    add    A, [edi]
    scasd
    ; C += *k; k++;
    add    C, [edi]
    scasd
    ; save ciphertext  
    pop    esp         ; esp = data
    xchg   esp, edi    ; esp = fixed stack, edi = data
    xchg   eax, A
    stosd              ; save A
    xchg   eax, B      
    stosd              ; save B 
    xchg   eax, C
    stosd              ; save C 
    xchg   eax, D 
    stosd              ; save D
    popad
    ret
    
