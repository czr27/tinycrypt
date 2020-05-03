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
; NORX permutation function in x86 assembly
;
; size: 115 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

   bits 32

   %ifndef BIN
     global _norx_permutex 
     global norx_permutex 
   %endif
   
%define a eax
%define b ebx
%define c edx
%define d edi

%define x edi
%define t ebp
%define r ecx

_norx_permutex:
norx_permutex:
    pushad
nrx_main:
    call   load_idx
    dw     040c8H, 051d9H, 062eaH, 073fbH
    dw     050faH, 061cbH, 072d8H, 043e9H
load_idx:
    pop    esi   
    push   8
    pop    ecx
nrx_perm:
    mov    edi, [esp+32+4] ; ebx = state
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
    mov    r, 1F100B08h ; load rotation values
nrx_rnd:
    mov    t, [a]
    and    t, [b]
    shl    t, 1
    xor    t, [a]
    xor    t, [b]
    mov    [a], t
    
    xor    t, [d]
    ror    t, cl
    mov    [d], t
    
    xchg   c, a
    xchg   d, b 
    
    shr    r, 8       ; shift until all done 
    jnz    nrx_rnd
    
    pop    ecx
    loop   nrx_perm
    popad
    ret
    