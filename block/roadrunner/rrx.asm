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
; size: 142 bytes
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

%define key_idx ebx    
%define rnd     ecx 
%define t       edx   
%define x       esi
%define p       esi
%define rk      edi
%define sk      edi
    
roadrunner:
_roadrunner:
    pushad
    mov    edi, [esp+32+8] ; edi : k = mk
    mov    esi, [esp+32+4] ; esi : x = data
    ; key_idx = 4;
    push   4
    pop    ebx
    ; apply K-Layer
    ; x[0] ^= k[0];
    mov    edx, [esi]
    xor    edx, [edi]
    ; apply 12 rounds of encryption
    ; for(r=12; r>0; r--) {
    push   12             
    pop    ecx
rr_encrypt:    
    ; F round
    pushad
    ; t = x->w;
    mov    t, [x]
    ; i = 3;
    mov    cl, 3
f_round:
    ; add round constant
    ; if (i==1)
    cmp    cl, 1
    jne    SLKX
    ; x->b[3] ^= ci;
    mov    eax, [esp+_ecx]  ; ecx has round index   
    xor    [x+3], al  
SLKX:    
    ; -------------------------------
    ; SLK (x, rk + *key_idx);
    pushad  
    ; apply S-Layer
    call   sboxx 
    add    sk, key_idx    
    mov    cl, 4      ; 4 rounds of SLK 
    ; apply L-Layer
slk_round:
    ; t   = ROTL8(*p, 1) ^ *p; 
    movzx  eax, byte[p]
    rol    al, 1
    xor    al, [p]
    ; *p ^= ROTL8(t,  1);
    rol    al, 1 
    xor    [p], al
    ; apply K-Layer
    ; *p++ ^= *sk++;
    mov    al, byte[sk]
    inc    sk
    xor    [p], al
    inc    p
    loop   slk_round 
    popad
    ; -------------------------------- 
    ; advance master key index
    ; *key_idx = (*key_idx + 4) & 15;
    add    key_idx, 4
    and    key_idx, 15
    loop   f_round
    ; apply S-Layer
    ; sbox(x);    
    call   sboxx
    ; add upper 32-bits
    ; blk->w[0]^= blk->w[1];
    mov    eax, [x+4]
    xor    [x], eax
    ; blk->w[1] = t;
    mov    [x+4], t   
    mov    [esp+_ebx], key_idx    
    popad
    ; -------------------------
    loop   rr_encrypt 
    ; XCHG(x->w[0], x->w[1]);        
    mov    eax, [x]
    xchg   eax, [x+4]
    ; x->w[0] ^= rk[1];    
    xor    eax, [rk+4]
    mov    [x], eax  
    popad
    ret    

; S-Layer    
sboxx:
    pushad
    mov    ebx, x        ; ebx = esi
    lodsd
    mov    edx, eax      ; t.w = ROTR32(x->w, 16); 
    ror    edx, 16
    and    [ebx+3], dl   ; x->b[3] &=  t.b[0];
    xor    [ebx+3], ah   ; x->b[3] ^= x->b[1];
    or     [ebx+1], dl   ; x->b[1] |=  t.b[0];    
    xor    [ebx+1], al   ; x->b[1] ^= x->b[0];
    mov    dl, [ebx+3]
    and    [ebx+0], dl   ; x->b[0] &= x->b[3];
    xor    [ebx+0], dh   ; x->b[0] ^=  t.b[1];
    and    dh, [ebx+1]   ;  t.b[1] &= x->b[1];
    xor    [ebx+2], dh   ; x->b[2] ^=  t.b[1]; 
    popad
    ret    
    
 
    
