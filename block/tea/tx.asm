;
;  Copyright © 2015 Odzhan. All Rights Reserved.
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

    ; uses 32 rounds by default
    ; 69 bytes
    
    bits 32
    
    %define ROUNDS 32
    
    global tea
    global _tea
    
tea:
_tea:
    pushad
    mov    esi, [esp+32+8]    ; esi = data
    push   esi                ; save pointer to data buffer
    lodsd                     ;
    xchg   eax, ebx           
    lodsd               
    xchg   eax, ebx           ; v0=v[0], v1=v[1]
    xor    esi, esi
tx_L0:
    mov    edi, [esp+32+4+4]  ; edi = mk
    add    esi, 0x9e3779b9    ; sum = 0x9e3779b9
    xor    ecx, ecx           ; 
tx_L1:
    jnp     tx_L0
    
    ; if(sum == 0x9e3779b9*33) break;
    cmp    esi, (0x9e3779b9 * (ROUNDS+1)) & 0xFFFFFFFF
    je     tx_L2

    mov    edx, ebx           ; t = ((v1 << 4) + k[idx%4]);
    shl    edx, 4             ; 
    add    edx, [edi]         ;
    scasd
    
    lea    ebp, [ebx+esi]     ; t ^= (v1 + sum);
    xor    edx, ebp
    
    mov    ebp, ebx           ; t ^= ((v1 >> 5) + k[(idx+1)%4]);
    shr    ebp, 5
    add    ebp, [edi]
    scasd
    xor    edx, ebp
    
    add    eax, edx           ; v0 += t;
    xchg   eax, ebx           ; t=v0; v0=v1; v1=t;
    dec    ecx
    jmp    tx_L1
tx_L2:
    pop    edi                ; restore pointer to data buffer
    stosd                     ; v[0] = v0
    xchg   eax, ebx
    stosd                     ; v[1] = v1
    popad
    ret
