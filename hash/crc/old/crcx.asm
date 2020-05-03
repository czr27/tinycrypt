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

    bits 32
    
    %ifndef BIN
      global crc16x
      global _crc16x      
      
      global crc32cx
      global _crc32cx
    
      global crc32x
      global _crc32x
    %endif

crc16x:    
_crc16x:
    pushad
    popad
    ret
    
crc32cx:    
_crc32cx:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   edx, eax          ; edx = crc
    lodsd
    xchg   ecx, eax          ; ecx = inlen
    lodsd
    xchg   esi, eax          ; esi = in
    xor    eax, eax          ; eax = 0
    jecxz  crcc_l3            ; if (inlen==0) return crc;
crcc_l0:
    lodsb                    ; al = *p++
    xor    dl, al            ; crc ^= al
    xchg   eax, ecx
    mov    cl, 8
crcc_l1:
    shr    edx, 1            ; crc >>= 1
    jnc    crcc_l2
    xor    edx, 0x82F63B78
crcc_l2:
    loop   crcc_l1
    xchg   eax, ecx
    loop   crcc_l0
crcc_l3:
    mov    [esp+28], edx     ; return crc    
    popad
    ret
    
    
crc32x:    
_crc32x:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   edx, eax          ; edx = crc
    not    edx
    lodsd
    xchg   ecx, eax          ; ecx = inlen
    lodsd
    xchg   esi, eax          ; esi = in
    xor    eax, eax          ; eax = 0
    jecxz  crc_l3            ; if (inlen==0) return crc;
crc_l0:
    lodsb                    ; al = *p++
    xor    dl, al            ; crc ^= al
    xchg   eax, ecx
    mov    cl, 8
crc_l1:
    shr    edx, 1            ; crc >>= 1
    jnc    crc_l2
    xor    edx, 0xEDB88320
crc_l2:
    loop   crc_l1
    xchg   eax, ecx
    loop   crc_l0
crc_l3:    
    not    edx
    mov    [esp+28], edx     ; return ~crc    
    popad
    ret
    