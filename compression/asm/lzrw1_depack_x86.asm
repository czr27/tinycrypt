;
;  Copyright © 2019 Odzhan. All Rights Reserved.
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

; LZRW1 decompressor in 62 bytes of x86 assembly
; 
; uint32_t lzrw1_decompress(uint32_t inlen, void *outbuf, void *inbuf);
;
    bits 32
    
    %ifndef BIN
      global lzrw1_decompressx
      global _lzrw1_decompressx
    %endif
    
lzrw1_decompressx:
_lzrw1_decompressx:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   eax, ebp        ; ebp = inlen
    lodsd
    xchg   edi, eax        ; edi = outbuf
    lodsd
    xchg   esi, eax        ; esi = inbuf
    add    ebp, esi        ; ebp = inbuf + inlen
L0:
    push   16 + 1          ; bits = 16
    pop    edx
    lodsw                  ; ctrl = *in++, ctrl |= (*in++) << 8
    xchg   ebx, eax        
L1:
    ; while(in != end) {
    cmp    esi, ebp
    je     L4
    ; if(--bits == 0) goto L0
    dec    edx
    jz     L0
L2:
    ; if(ctrl & 1) {
    shr    ebx, 1
    jc     L3
    movsb                  ; *out++ = *in++;
    jmp    L1
L3:
    lodsb                  ; ofs = (*in & 0xF0) << 4
    aam    16
    cwde
    movzx  ecx, al
    inc    ecx
    lodsb                  ; ofs |= *in++ & 0xFF;
    push   esi             ; save pointer to in
    mov    esi, edi        ; ptr  = out - ofs;
    sub    esi, eax
    rep    movsb           ; while(len--) *out++ = *ptr++;
    pop    esi             ; restore pointer to in
    jmp    L1
L4:
    sub    edi, [esp+32+8] ; edi = out - outbuf
    mov    [esp+28], edi   ; esp+_eax = edi
    popad
    ret
    
