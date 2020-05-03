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
; ChaCha20 stream cipher in x86 assembly
;
; size: 196 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
 
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
 
%define a eax
%define b ebx
%define c edx
%define d edi

%define x edi
%define t ebp
%define r ecx
 
    %ifndef BIN
      global xchacha20
      global _xchacha20
    %endif
    
    ; ------------------------------------
xchacha20:
_xchacha20:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   ecx, eax          ; ecx = len
    lodsd
    xchg   ebx, eax          ; ebx = input or key+nonce
    lodsd
    jecxz  init_key    
    xchg   esi, eax          ; esi = state
    ; perform encryption/decryption
    pushad
    pushad
    mov    edi, esp          ; edi = c
cx_l0:
    xor    eax, eax
    jecxz  cc_l2             ; exit if len==0
    call   xchacha_permute
cc_l1:
    mov    dl, [edi+eax]
    xor    [ebx], dl
    inc    ebx
    inc    eax
    cmp    al, 64
    loopne cc_l1
    jmp    cx_l0
cc_l2:
    popad
    popad   
    popad
    ret
    ; ----------------------------------
init_key:
    xchg   eax, edi
    mov    esi, ebx    
    ; copy "expand 32-byte k" into state
    mov    eax, 0x61707865
    stosd
    mov    eax, 0x3320646E
    stosd
    mov    eax, 0x79622D32
    stosd
    mov    eax, 0x6B206574
    stosd
    ; copy 256-bit key
    mov    cl, 8
    rep    movsd
    ; set 32-bit counter to zero
    xchg   ecx, eax
    inc    eax
    stosd
    ; store 96-bit nonce and return
    movsd
    movsd
    movsd
    popad
    ret    

    ; esi = state
    ; edi = out
xchacha_permute:
    pushad
    xchg   eax, ecx
    ; memcpy (out->b, state->b, 64);
    pushad
    mov    cl, 16
    rep    movsd
    mov    cl, 20/2
nrx_main:
    call   load_idx
    dw     040c8H, 051d9H, 062eaH, 073fbH
    dw     050faH, 061cbH, 072d8H, 043e9H
load_idx:
    pop    esi   
    push   ecx               ; save rounds
    mov    cl, 8             ; load 8 16-bit values 
nrx_perm:
    mov    edi, [esp+_edi+4] ; edi = out
    lodsb
    aam    16
    movzx  c, al    
    movzx  ebp, ah   
    
    lodsb
    aam    16
    movzx  b, ah
    movzx  a, al
    
    lea    a, [x+a*4]
    lea    b, [x+b*4]
    lea    c, [x+c*4]
    lea    d, [x+ebp*4]

    push   ecx          ; save index counter
    mov    r, 07080C10h ; load rotation values
nrx_rnd:
    mov    t, [b]
    add    [a], t
    
    mov    t, [d]    
    xor    t, [a]
    rol    t, cl
    mov    [d], t
    
    xchg   a, c
    xchg   b, d 
    
    shr    r, 8       ; shift until all done 
    jnz    nrx_rnd
    
    pop    ecx
    loop   nrx_perm
    
    pop    ecx
    loop   nrx_main    
    
    popad
    
    ; add state to x
    mov    cl, 16
add_state:
    lodsd
    add    [edi], eax
    scasd
    loop   add_state

    ; update 32-bit counter
    inc    dword[esi-4*4]
    popad
    ret
    