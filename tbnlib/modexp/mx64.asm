;
;  Copyright © 2016, 2017 Odzhan, Peter Ferrie. All Rights Reserved.
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
; Modular Exponentiation in x86 assembly
;
; size: 1xx bytes
;
; global calls use fastcall
;
; -----------------------------------------------

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

  bits 64
  
  %ifndef BIN
    global _modexp
    global modexp
  %endif

_modexp:
modexp:
    pushx   rbx, rsi, rdi, rbp
    mov     rbx, [rcx+16]    ; exponent
    mov     rbp, [rcx+24]    ; modulus
    mov     rdi, [rcx+32]    ; result
    mov     rcx, [rcx+ 8]    ; max bytes
    push    1
    pop     rdx              ; x = 1
    jmp     init_mx
mulmod:
    pushx   rbx, rsi, rdi, rbp
init_mx:    
; cf=1 : r = mulmod (r, t, m);
; cf=0 : t = mulmod (t, t, m);
    push   rdi               ; save edi
    ; r=x
    sub    rsp, rcx          ; create space for r and assign x
    ; t=b
    sub    rsp, rcx          ; create space for t and assign b
    push   rsp
    pop    rdi
    push   rcx
    rep    movsb
    pop    rcx
    push   rsp
    pop    rsi
    pushx  rcx, rdx, rdi
    loop   $+2               ; skip 1
    xchg   eax, edx          ; r=x
    stosb
    xor    al, al            ; zero remainder of buffer
    rep    stosb
    popx   rcx, rdx, rdi
    call    ld_fn
    
; cf=1 : r = addmod (r, t, m);
; cf=0 : t = addmod (t, t, m);

; ebp  : m
; esi  : t
; edi  : r or t
; ecx  : size in bytes
;
addmod:
    shr     ecx, 2            ; /= 4
    clc
    pushx   rcx, rsi, rdi
am_l1:
    lodsd
    adc     eax, [rdi]
    stosd
    loop    am_l1
    popx    rcx, rsi, rdi
    push    rbp
    pop     rsi
    push    rcx
    loop    $+2
am_l2:
    mov     eax, [rdi+rcx*4]
    cmp     eax, [rsi+rcx*4]
    loope   am_l2
    pop     rcx
    jb      am_l4
am_l3:
    mov     eax, [rdi]
    sbb     eax, [rsi]
    stosd
    lodsd
    loop    am_l3
am_l4:
    ret
    ; -----------------------------
ld_fn:
    sub     edx, 1
    js      cntbits
    sub     dword[rsp], addmod - mulmod
cntbits:
    xor     edx, edx
    lea     eax, [edx+ecx*8]
cnt_l1:
    sub     eax, 1
    jz      xm_l1
    bt      [rbx], eax
    jnc     cnt_l1
xm_l1:
    ; if (e & 1)
    bt      [rbx], edx
xm_l2:
    pushfq
    pushx   rax, rbx, rcx, rdx, rsi, rdi, rbp
    cdq
    cmovnc  rdi, rsi
    push    rdi
    pop     rbx
    call    qword[rsp+28+8]
    popx    rax, rbx, rcx, rdx, rsi, rdi, rbp
    popfq
    cmc
    jnc     xm_l2
    
    add     edx, 1
    sub     eax, 1
    jns     xm_l1

    ; return r
    push    rdi
    pop     rsi
    lea     rsp, [rsp+rcx*2+4]
    pop     rdi
    rep     movsb
    popx    rbx, rsi, rdi, rbp
    ret
