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
;  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS ORdancing
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
; Bel-T block cipher in x86 assembly (encryption only)
;
; size: 210 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
    
    %ifndef BIN
      global belt
      global _belt
    %endif
    
struc pushad_t
  _edi dd ?
  _esi dd ?
  _ebp dd ?
  _esp dd ?
  _ebx dd ?
  _edx dd ?
  _ecx dd ?
  _eax dd ?
  .size:
endstruc

%define t   eax

%define a   ebx
%define b   ecx
%define c   edx
%define d   esi
%define e   edi

%define G   ebp

belt:
_belt:
    pushad
    mov    edi, [esp+32+4]   ; k = mk
    mov    esi, [esp+32+8]   ; x = data
    xor    eax, eax
    
    push   esi               ; save x
    push   eax               ; save j
    push   edi               ; save k
    push   eax               ; save i
    
    lodsd
    xchg   a, eax            ; a = x[0]
    lodsd
    xchg   b, eax            ; b = x[1]
    lodsd
    xchg   c, eax            ; c = x[2]
    lodsd
    xchg   d, eax            ; d = x[3]
    call   b_L0
    ; ------------------------
    ; G function
    ; ------------------------
    pushad
    mov    esi, [esp+_esp]   ; esi=esp
    lodsd                    ; eax=return address
    lodsd                    ; edx=x
    xchg   eax, edx          ; 
    lodsd                    ; eax=r
    push   eax               ; save r
    lodsd                    ; eax=i
    lodsd                    ; eax=k
    xchg   eax, edi          ; edi=k
    lodsd                    ; eax=j
    inc    dword[esi-4]      ; j++
    and    eax, 7            ; j &= 7
    add    edx, [edi+eax*4]  ; x += k[j&7]
    mov    al, 4
g_H0:
    ; if (x==10) return 0;
    sub    dl, 10
    jz     g_H3
    ; if (x<10) x++;
    adc    dl, 10
    movzx  ecx, dl
    ; t = 0x1d;
    mov    dl, 0x1d
g_H1:
    push   ecx
    ; j = 116;
    mov    cl, 116
g_H2:
    ; w = t & 99;
    mov    bl, dl
    and    bl, 99
    ; w ^= (w >> 1)
    mov    bh, bl
    shr    bh, 1
    xor    bl, bh
    ; w ^= (w >> 2)
    mov    bh, bl
    shr    bh, 2
    xor    bl, bh
    ; w ^= (w >> 4)
    mov    bh, bl
    shr    bh, 4
    xor    bl, bh
    ; t = t >> 1 | w << 7
    shl    bl, 7
    shr    dl, 1
    or     dl, bl
    loop   g_H2
    pop    ecx
    loop   g_H1
g_H3:
    ror    edx, 8     ; u.w = ROTR(u.w, 8)
    dec    eax
    jnz    g_H0
    
    pop    ecx        ; ecx=r
    rol    edx, cl    ; return ROTL32(u.w, r);
    mov    [esp+_eax], edx
    popad
    retn   2*4
    ; -----------------------
b_L0:    
    pop    G
b_L1:
    push   5
    push   a
    call   G   
    xor    b, t       ; b ^= G(a, k, j+0, 5);
    
    push   21
    push   d
    call   G     
    xor    c, t       ; c ^= G(d, k, j+1,21);
    
    push   13
    push   b
    call   G       
    sub    a, t       ; a -= G(b, k, j+2,13);
    
    push   21
    lea    t, [b + c]
    push   t
    call   G          ; e  = G(b + c, k, j+3,21);
    xchg   t, e
    
    pop    t          ; t = i
    inc    t          ; i++
    push   t          ; save i
    
    xor    e, t       ; e ^= i;
    add    b, e       ; b += e;
    sub    c, e       ; c -= e;
    
    push   13
    push   c
    call   G
    add    d, t       ; d += G(c, k, j+4,13);
    
    push   21
    push   a
    call   G
    xor    b, t       ; b ^= G(a, k, j+5,21);
    
    push   5
    push   d
    call   G
    xor    c, t       ; c ^= G(d, k, j+6, 5);
    
    xchg   a, b
    xchg   c, d
    xchg   b, c
    
    pop    eax
    push   eax
    cmp    al, 8
    jnz    b_L1
    
    pop    eax       ; remove i
    pop    eax       ; remove k
    pop    eax       ; remove j
    pop    edi       ; restore x

    xchg   eax, b
    stosd            ; x[0] = b
    xchg   eax, d
    stosd            ; x[1] = d
    xchg   eax, a
    stosd            ; x[2] = a
    xchg   eax, c
    stosd            ; x[3] = c
    popad            ; restore registers
    ret
    
