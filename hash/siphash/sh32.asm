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
; Half SipHash for 32-bit hashes
;
; size: 142 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------
    bits 32
    
%ifndef BIN
  global _xhalfsiphashx   
  global xhalfsiphashx   
%endif
    
; don't change these    
%define cROUNDS 2
%define dROUNDS 4

%define v0 ebx    
%define v1 ebp    
%define v2 edx    
%define v3 edi

_xhalfsiphashx:
xhalfsiphashx:
    pushad
    lea    esi, [esp+32+ 4]
    lodsd
    push   eax               ; save inlen
    lodsd
    push   eax               ; save data
    lodsd

    ; initialize state
    mov    v0, [eax]
    push   v0
    pop    v2       
    mov    v1, [eax+4]
    push   v1
    pop    v3
    xor    v2, 0x6c796765
    xor    v3, 0x74656462
    
    ; update state in 4-byte blocks
    pop    esi               ; esi = data 
    pop    ecx               ; ecx = inlen
    push   ecx               ; save inlen
    shr    ecx, 2            ; inlen /= 4 
    jz     shx_l2   
shx_l0:
    clc
    lodsd
    call   xsipround
    loop   shx_l0
shx_l2:    
    pop    ecx               ; restore inlen
    mov    eax, ecx
    push   edx               ; save edx
    cdq                      ; edx = 0
    shl    eax, 24
shx_l3:
    and    ecx, 3            ; inlen &= 3
    jz     shx_l4            ; if (left > 0) 
    shl    edx, 8            ; t <<= 8
    mov    dl, byte[esi+ecx-1] ; t |= in[left]
    loop   shx_l3            ; while (--left > 0) 
shx_l4:
    or     eax, edx          ; b |= t
    pop    edx               ; restore edx
    clc
shx_l5:
    pushfd    
    call   xsipround
    popfd
    cmc
    jnc    shx_l5
    xor    v1, v3            ; v[1] ^= v[3]
    mov    [esp+28], v1      ; pushad_t._eax = v1
    popad
    ret

; CF=0 for normal update    
; CF=1 for final update    
xsipround:
    push   ecx               ; save ecx
    push   cROUNDS 
    pop    ecx
    jnc    sr_l0             ; skip if no carry
    
    xor    eax, eax          ; w=0 if last round
    add    ecx, ecx          ; assumes: cROUNDS=2, dROUNDS=4
    not    dl                ; requires edx to be v2
sr_l0:
    xor    v3, eax           ; v3 ^= w    
sr_l1:    
    add    v0, v1            ; v[0] += v[1];
    rol    v1, 5             ; v[1] = ROTL(v[1], 5);
    xor    v1, v0            ; v[1] ^= v[0];
    rol    v0, 16            ; v[0] = ROTL(v[0], 16);
    add    v2, v3            ; v[2] += v[3]; 
    rol    v3, 8             ; v[3] = ROTL(v[3], 8); 
    xor    v3, v2            ; v[3] ^= v[2]; 
    add    v0, v3            ; v[0] += v[3];
    rol    v3, 7             ; v[3] = ROTL(v[3], 7);
    xor    v3, v0            ; v[3] ^= v[0];
    add    v2, v1            ; v[2] += v[1];
    rol    v1, 13            ; v[1] = ROTL(v[1], 13);
    xor    v1, v2            ; v[1] ^= v[2];
    rol    v2, 16            ; v[2] = ROTL(v[2], 16);
    loop   sr_l1
    xor    v0, eax           ; v0 ^= w
    pop    ecx               ; restore ecx
    ret    
    
    
   