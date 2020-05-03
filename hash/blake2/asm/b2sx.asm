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

; -----------------------------------------------
; blake2s in x86 assembly
;
; size: 497 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
    
    %ifndef BIN
      global _b2s_initx
      global _b2s_updatex
      global _b2s_finalx
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

struc blake2s_ctx
  s      resd 16
  h      resd 16
  idx    resd 1
  outlen resd 1
  x      resb 64
  len    resd 2
endstruc

%define a eax
%define b edx
%define c esi
%define d edi
%define x edi

%define t0 ebp


b2s_idx16:
    dw 0xC840, 0xD951, 0xEA62, 0xFB73 
    dw 0xFA50, 0xCB61, 0xD872, 0xE943

b2s_sigma64:
    dq 0xfedcba9876543210, 0x357b20c16df984ae 
    dq 0x491763eadf250c8b, 0x8f04a562ebcd1397 
    dq 0xd386cb1efa427509, 0x91ef57d438b0a6c2 
    dq 0xb8293670a4def15c, 0xa2684f05931ce7bd 
    dq 0x5a417d2c803b9ef6, 0x0dc3e9bf5167482a
    
b2s_iv:
    dd 0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A
    dd 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19
 
G:
    pushad
    
    popad
    ret
    
void G(W *s, W *m) {
    W i, j, a, b, c, d, r, t;

    Q *p=sigma, z;
    
    for(i=0;i<80;) {
      z=*p++;
      while(z) {
        d=v[i++%8];
        a=(d&15);b=(d>>4&15);
        c=(d>>8&15);d>>=12;
        r=0x07080C10;
        for(j=0;j<4;j++) {
          if(!(j&1)) {
            s[a]+=m[z&15];
            z>>=4;
          }
          s[a]+=s[b];
          s[d]=R(s[d]^s[a],(r&255));
          X(a,c),X(b,d);
          r>>=8;
        }
      }
    }
}

; void blake2s_init(blake2s_ctx*c, uint32_t outlen, 
;   void *key, uint32_t keylen)
blake2s_init:
    or     eax, -1
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   edi, eax         ; edi = c
    lodsd
    xchg   ecx, eax         ; ecx = outlen
    ; if(outlen==0 || outlen > 32 || keylen > 32) return -1;
    jecxz  b2s_exit         ; outlen == 0
    cmp    ecx, 32          ; outlen > 32
    ja     b2s_exit
    lodsd
    xchg   ebp, eax         ; ebp = key
    lodsd
    xchg   edx, eax         ; edx = keylen
    cmp    edx, 32          ; keylen > 32
    ja     b2s_exit
    
    ; initialize state
    ; F(8)c->s[i] = iv[i];
    mov    esi, b2s_iv
    lodsd                   ; t = iv[0]
    ; c->s[0]  ^= 0x01010000^(keylen<<8)^outlen;
    xor    eax, ecx         ; t ^= outlen
    shl    edx, 8           ; 
    xor    eax, edx         ; t ^= keylen << 8
    xor    eax, 0x01010000  ; t ^= 0x01010000
    stosd                   ; s[0] = t
    push   7
    pop    ecx
    rep    movsd
    ; c->len.q  = 0;
    ; c->idx    = 0;
    ; c->outlen = outlen;


; void blake2s_update(blake2s_ctx*c,void *in,uint32_t len)
blake2s_update:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   edi, eax           ; edi = c
    lodsd
    xchg   ecx, eax           ; ecx = in
    lodsd
    xchg   ecx, eax           ; ecx = len, eax = in
    jecxz  ex_upd
    xchg   esi, eax           ; esi = in
    mov    edx, [edi+idx]     ; edx = idx
b2_upd:
    ; if (c->idx == 64) {
    cmp    dl, 64
    jne    b2_ab
    ; c->len.q += 64;
    add    dword[edi+len+0], edx   
    mov    dl, 0              ; last=0
    adc    dword[edi+len+4], edx
    ; blake2s_compress(c, 0);
    call   blake2s_compress
b2_ab:
    ; c->x.b[c->idx++] = *p++;
    lodsb                     ; al = *p++
    mov    [edi+edx+x], al    ; c->x.b[c->idx] = al
    inc    edx                ; c->idx++
    loop   b2_upd             
    mov    [edi+idx], edx     ; save idx  
ex_upd:
    popad
    ret 
    
; void blake2s_final(void*out, blake2s_ctx*c)
blake2s_final:
    pushad
    mov    edx, [esp+32+8]    ; ctx
    ; c->len.q += c->idx;
    mov    ecx, [edx+idx]
    xor    eax, eax           ; eax = 0
    add    [edx+len+0], ecx
    adc    [edx+len+4], eax
    ; while(c->idx<64) c->x.b[c->idx++]=0;
    lea    edi, [edx+ecx+x]
    neg    ecx
    add    ecx, 64
    rep    stosb
    ; blake2s_compress(c,1);
    mov    edi, edx          ; edi = c
    cdq
    inc    edx               ; edx = 1
    call   blake2s_compress
    ; F(c->outlen)((B*)out)[i]=((B*)c->s)[i];
    mov    ecx, [edi+outlen] ; ecx = outlen
    mov    esi, [esp+32+4]   ; esi = out
    rep    movsb
    popad
    ret
