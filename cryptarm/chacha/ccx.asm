;
;  Copyright © 2015 Odzhan, Peter Ferrie. All Rights Reserved.
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
; size: 221 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32

    %ifndef BIN
      global _cc20_setkeyx
      global _cc20_encryptx
    %endif

; void cc_setkey(chacha_ctx *ctx, void *key, void *iv)
_cc20_setkeyx:
cc20_setkeyx:
    pushad
    mov    edi, [esp+32+4] ; ctx
    ; copy "expand 32-byte k" into state
    call   load_iv
    dd     061707865h, 03320646Eh
    dd     079622D32h, 06B206574h
load_iv:
    pop    esi
    push   4
    pop    ecx
    rep    movsd
    ; copy 256-bit key
    mov    esi, [esp+32+8] ; key
    mov    cl, 8
    rep    movsd
    ; set 64-bit block counter to zero
    xchg   ecx, eax
    stosd
    stosd
    ; store 64-bit nonce
    mov    esi, [esp+32+12] ; iv
    movsd
    movsd
    popad
    ret

%define a eax
%define b ebx
%define c edx
%define d edi

%define x edi
%define t ebp
%define r ecx

; void chacha_permute(chacha_blk *blk, uint16_t index)
chacha_permute:
    pushad

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
    ; load ecx with rotate values
    ; 16, 12, 8, 7
    mov    ecx, 07080C10h
    ;mov    ecx, 100C0807h ; 07080C10h
    mov    t, [b]
q_l1:
    ; x[a] = PLUS(x[a],x[b]);
    add    t, [a]
    mov    [a], t
    ; x[d] = ROTATE(XOR(x[d],x[a]),cl);
    ; also x[b] = ROTATE(XOR(x[b],x[c]),cl);
    xor    t, [d]
    rol    t, cl
    mov    [d], t
    xchg   c, a
    xchg   d, b
    ; --------------------------------------------
    shr    ecx, 8
    jnz    q_l1

    popad
    ret

; void cc20_streamx (chacha_ctx *ctx, void *in, uint32_t len)
; do not call directly
; expects state in ebx, length in eax, input in edx
_cc20_streamx:
cc20_streamx:
    pushad

    ; copy state to edi
    push   64
    pop    ecx
    mov    ebx, esi
    rep    movsb

    pop    edi
    push   edi
    mov    cl, 20/2
e_l1:
    ; load indexes
    call   load_idx
    dw     040c8H, 051d9H, 062eaH, 073fbH
    dw     050faH, 061cbH, 072d8H, 043e9H
load_idx:
    pop    esi  ; pointer to indexes
    push   ecx
    mov    cl, 8
e_l2:
    call   chacha_permute
    add    esi, 2
    loop   e_l2
    pop    ecx
    loop   e_l1

    ; add state to x
    mov    cl, 16
add_state:
    mov    eax, [ebx+ecx*4-4]
    add    [edi+ecx*4-4], eax
    loop   add_state

    ; update block counter
    stc
    adc    dword[ebx+12*4], ecx
    adc    dword[ebx+13*4], ecx

    ; restore registers
    popad
    ret

_cc20_encryptx:
cc20_encryptx:
    pushad
    lea     esi, [esp+32+4]
    lodsd
    xchg    ecx, eax          ; ecx = length
    lodsd
    xchg    ebx, eax          ; ebx = buf
    lodsd
    xchg    esi, eax          ; esi = ctx
    pushad
    pushad
    mov     edi, esp          ; edi = stream[64]
cc_l0:
    xor     eax, eax
    jecxz   cc_l2             ; exit if len==0
    call    cc20_streamx
cc_l1:
    mov     dl, byte[edi+eax]
    xor     byte[ebx], dl
    inc     ebx
    inc     eax
    cmp     al, 64
    loopnz  cc_l1
    jmp     cc_l0
cc_l2:
    popad
    popad
    popad
    ret
