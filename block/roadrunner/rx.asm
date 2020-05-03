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
; RoadRunneR-64/128 block cipher in x86 assembly
;
; size: 135 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------


    bits 32
    
    %ifndef BIN
      global roadrunner
      global _roadrunner
    %endif

struc pushad_t
  _edi resd 1
  _esi resd 1
  _ebp resd 1
  _esp resd 1
  _ebx resd 1
  _edx resd 1
  _ecx resd 1
  _eax resd 1
  .size:
endstruc

roadrunner:
_roadrunner:
    pushad
    mov    edi, [esp+32+4]    ; k = mk
    mov    esi, [esp+32+8]    ; x = data
    xor    ebx, ebx           ; k_idx = 0
    ; apply K-Layer
    ; x[0] ^= ((W*)mk)[0];
    mov    ebp, [edi]         ; t = ((W*)mk)[0]
    xor    [esi], ebp         ; x[0] ^= t 
    ; apply 12 rounds of encryption
    ; for(r=12; r>0; r--) {
    push   12             
    pop    ecx
rr_L0:    
    ; F round
    pushad                    ; save all registers: for(r=12
    mov    ebp, [esi]         ; t = x[0]
    mov    edx, ecx           ; edx = r
    mov    cl, 3              ; i = 3
rr_L1:
    inc    ebx                ; k_idx = (k_idx + 4) % 16
    and    ebx, 3
    pushad                    ; save all registers: for(i=3
    ; add constant
    cmp    cl, 1              ; if (i == 1)
    jne    rr_L2
    xor    [esi+3], dl        ; p[3] ^= r
rr_L2:
    lea    edi, [edi+ebx*4]   ; edi = &k[k_idx]
    ; apply S-Layer
    ; S(p);
    call   S
    ; for (j=3; j>=0; j--) { 
    mov    cl, 4              ; j = 4 
    ; apply L-Layer
rr_L3:
    ; s = R(p[j], 1) ^ p[j]; 
    mov    al, [esi]          ; s = p[j]
    rol    al, 1              ; s = R(s, 1)
    xor    al, [esi]          ; s^= p[j]
    ; s = R(s, 1) ^ p[j];
    rol    al, 1              ; s = R(s, 1) 
    xor    al, [esi]          ; s^= p[j]
    
    ; apply K-Layer
    ; p[j] = s ^ ((B*)k)[(k_idx%16)+j];
    xor    al, byte[edi]
    mov    [esi], al
    cmpsb
    loop   rr_L3              ; j>0; j--
    
    popad                     ; restore registers: for(i=3
    loop   rr_L1              ; i>0; i--
    
    ; apply S-Layer
    ; S(p);    
    call   S
    ; add upper 32-bits
    ; x[0]^= x[1];
    lodsd
    xor    eax, [esi]
    mov    [esi-4], eax
    
    ; x[1] = t;
    mov    [esi], ebp
    mov    [esp+_ebx], ebx    ; save k_idx
    popad                     ; restore registers: for(r=12
    loop   rr_L0              ; r>0; r--
    
    ; permute
    ; X(x[0], x[1]);
    lodsd
    xchg   eax, [esi]
    
    ; apply K-layer
    ; x[0] ^= ((W*)mk)[1];    
    xor    eax, [edi+4]
    mov    [esi-4], eax  
    
    popad
    ret    

; S-Layer    
S:
    pushad
    mov    ebx, esi      ; ebx = esi
    lodsd
    mov    edx, eax      ; t = ROTR32(x[0], 16); 
    ror    edx, 16
    and    [ebx+3], dl   ; x[3] &= t[0];
    xor    [ebx+3], ah   ; x[3] ^= x[1];
    or     [ebx+1], dl   ; x[1] |= t[0];    
    xor    [ebx+1], al   ; x[1] ^= x[0];
    mov    dl, [ebx+3]
    and    [ebx+0], dl   ; x[0] &= x[3];
    xor    [ebx+0], dh   ; x[0] ^= t[1];
    and    dh, [ebx+1]   ; t[1] &= x[1];
    xor    [ebx+2], dh   ; x[2] ^= t[1]; 
    popad
    ret
