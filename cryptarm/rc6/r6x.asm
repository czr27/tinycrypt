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
; RC6-128/256 Block Cipher in x86 assembly (Encryption only)
;
; https://people.csail.mit.edu/rivest/pubs/RRSY98.pdf
;
; size: 168 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

        bits 32


        %ifndef BIN
          global rc6_encryptx
          global _rc6_encryptx
        %endif
        
%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))

%define x0 esi
%define x1 ebx
%define x2 edx
%define x3 ebp
        
rc6_encryptx:
_rc6_encryptx:
    pushad
    
    ;int3
    
    mov    esi, [esp+32+4]       ; esi = key
    mov    ebx, [esp+32+8]       ; ebx = data
    xor    ecx, ecx              ; ecx = 0
    mov    cl, (RC6_KR*4)+32 ; allocate space for key and sub keys
    sub    esp, ecx              ; esp = S
    ; copy 256-bit key to local buffer
    mov    edi, esp            ; edi = L
    push   32
    pop    ecx
    rep    movsb
    
    ; initialize S / sub keys
    push   edi    
    mov    eax, 0xB7E15163     ; 
    mov    cl, RC6_KR   
init_subkeys:
    stosd
    add    eax, 0x9E3779B9
    loop   init_subkeys
    pop    edi
    
    mul    ecx
    
    mov    esi, ebx            ; esi = data
    mov    cl, RC6_KR*3
    xor    ebp, ebp            ; j = 0
set_idx:    
    xor    ebx, ebx            ; i = 0   
init_key:
    cmp    bl, RC6_KR          ; if (i == RC6_KR) i = 0;
    je     set_idx    

    and    ebp, 7              ; j &= 7
    
    ; x0 = S[i%RC6_KR] = ROTR32(S[i%RC6_KR] + x0+x1, 29); 
    add    eax, edx            ; x0 += x1
    add    eax, [edi+ebx*4]    ; x0 += S[i%RC6_KR]
    ror    eax, 29             ; x0  = ROTR32(x0, 29)
    mov    [edi+ebx*4], eax    ; S[i%RC6_KR] = x0
    
    ; x1 = L[i%8] = ROTL32(L[i%8] + x0+x1, x0+x1);
    add    edx, eax            ; x1 += x0
    push   ecx
    mov    ecx, edx            ; save x0+x1 in ecx
    add    edx, [edi+ebp*4-32] ; x1 += L[j%8]    
    rol    edx, cl             ; x1 = ROTR32(x1, 32-(x0+x1))
    mov    [edi+ebp*4-32], edx ; L[j%8] = x1
    inc    ebp                 ; i++
    inc    ebx                 ; j++    
    pop    ecx
    loop   init_key   

    push   esi                 ; save ptr to x    
    ; load 128-bit plain text
    lodsd
    push   eax                 ; save x0
    lodsd
    xchg   eax, x1             ; load x1
    lodsd
    xchg   eax, x2             ; load x2
    lodsd
    xchg   eax, x3             ; load x3
    pop    x0                  ; restore x0
    
    mov    cl, 20    
    ; B += *k; k++;
    add    x1, [edi]
    scasd
    ; D += *k; k++;
    add    x3, [edi]
    scasd
r6c_l3:
    push   ecx    
    ; t0 = ROTR32(x1 * (2 * x1 + 1), 27);
    lea    eax, [x1+x1+1]
    imul   eax, x1
    ror    eax, 27
    ; t1 = ROTR32(x3 * (2 * x3 + 1), 27);
    lea    ecx, [x3+x3+1]
    imul   ecx, x3
    ror    ecx, 27
    ; x0 = ROTR32(x0 ^ t0, 32-t1) + *kp++;
    push   x3           ; backup x3
    xor    x0, eax      ; x0 ^= t0
    xor    x2, ecx      ; x2 ^= t1;    
    rol    x0, cl       ; x3 = ROTR32(x0, 32-t1);
    mov    x3, x0       ; 
    add    x3, [edi]    ; x3 += *kp++;   
    scasd  
    ; ----------------------------
    mov    x0, x1       ; x0 = x1     
    ; x1 = ROTR32(x2, 32-t0);
    xchg   eax, ecx     ; 
    rol    x2, cl       ; x1 = ROTR32(x2, 32-t0);
    mov    x1, x2    
    add    x1, [edi]
    scasd    
    pop    x2           ; x2 = x3
    ; decrease counter
    pop    ecx
    loop   r6c_l3
    
    ; x0 += *k; k++;
    add    x0, [edi]
    scasd
    ; x2 += *k; k++;
    add    x2, [edi]
    scasd
    
    ;int3
    
    ; save cipher text  
    ;pop    esp         ; esp = x
    ;xchg   esp, edi    ; esp = fixed stack, edi = x
    pop    edi
    mov    cl, (RC6_KR*4)+32
    add    esp, ecx
    
    xchg   eax, x0
    stosd              ; save x0    
    xchg   eax, x1      
    stosd              ; save x1 
    xchg   eax, x2
    stosd              ; save x2 
    xchg   eax, x3 
    stosd              ; save x3
    
    popad
    ret
    