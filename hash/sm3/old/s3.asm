;
;  Copyright © 2017 Odzhan. All Rights Reserved.
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
; SM3-256 cryptographic hash in x86 assembly
;
; size: 469 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

  bits 32

SM3_CBLOCK         EQU 64
SM3_DIGEST_LENGTH  EQU 32
SM3_LBLOCK         EQU SM3_DIGEST_LENGTH/4

struc SM3_CTX
  len    resd 2
  state  resb SM3_DIGEST_LENGTH
  buffer resb SM3_CBLOCK
endstruc

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

%ifndef BIN
  global SM3_Initx
  global _SM3_Initx

  global SM3_Updatex
  global _SM3_Updatex

  global SM3_Finalx
  global _SM3_Finalx
%endif

SM3_Initx:
_SM3_Initx:
    pushad
    mov     edi, [esp+32+4]
    xor     eax, eax
    stosd
    stosd
    call    s3i_l0
    dd      0x7380166f, 0x4914b2b9
    dd      0x172442d7, 0xda8a0600
    dd      0xa96f30bc, 0x163138aa
    dd      0xe38dee4d, 0xb0fb0e4e
s3i_l0
    pop     esi
    push    8
    pop     ecx
    rep     movsd
    popad
    ret

; update context
SM3_Updatex:
_SM3_Updatex:
    pushad
    lea    esi, [esp+32+4]
    lodsd
    xchg   ebx, eax          ; ebx=ctx
    lodsd
    push   eax               ; save in
    lodsd                    ; eax=len
    pop    esi               ; esi=in

    ; idx = ctx->len & SM3_CBLOCK - 1;
    mov    edx, [ebx+len]
    and    edx, SM3_CBLOCK - 1

    ; limit of (2^32)-1 bytes each update
    ; ctx->len += len;
    add    dword[ebx+len+0], eax
    adc    dword[ebx+len+4], 0

upd_l1:
    ; r = (len >= (SM3_CBLOCK - idx)) ? SM3_CBLOCK - idx : len;
    push   SM3_CBLOCK
    pop    ecx
    sub    ecx, edx
    cmp    ecx, eax
    cmovae ecx, eax
    ; memcpy ((void*)&ctx->buffer[idx], p, r);
    lea    edi, [ebx+buffer+edx]
    ; idx += r
    add    edx, ecx
    ; len -= r
    sub    eax, ecx
    rep    movsb
    ; if ((idx + r) < SM3_CBLOCK) break;
    cmp    edx, SM3_CBLOCK
    jb     ex_upd
    call   _SM3_Transformx
    cdq
    jmp    upd_l1
ex_upd:
    popad
    ret

; finalize context
SM3_Finalx:
_SM3_Finalx:
    pushad
    mov    ebx, [esp+32+8] ; ctx
    ; uint64_t len=ctx->len & SM3_CBLOCK - 1;
    mov    eax, [ebx+len+0]
    and    eax, SM3_CBLOCK - 1
    cdq
    ; memset (&ctx->buffer[len], 0, SM3_CBLOCK - len);
    lea    edi, [ebx+buffer+eax]
    push   SM3_CBLOCK
    pop    ecx
    sub    ecx, eax
    xchg   eax, edx
    rep    stosb
    ; ctx->buffer[len] = 0x80;
    mov    byte[ebx+buffer+edx], 80h
    ; if (len >= 56)
    cmp    edx, 56
    jb     calc_len
    ; SM3_Transform (ctx);
    call   _SM3_Transformx
    ; memset (ctx->buffer, 0, SM3_CBLOCK);
    lea    edi, [ebx+buffer]
    mov    cl, SM3_CBLOCK/4
    rep    stosd
calc_len:
    ; ctx->buf.v64[7] = SWAP64(ctx->len * 8);
    mov    eax, [ebx+len+0]
    mov    edx, [ebx+len+4]
    shld   edx, eax, 3
    shl    eax, 3
    bswap  eax
    bswap  edx
    mov    dword[ebx+buffer+7*8+0], edx
    mov    dword[ebx+buffer+7*8+4], eax
    ; SM3_Transform(ctx);
    call   _SM3_Transformx
    ; for (i=0; i<SM3_LBLOCK; i++) {
    ;   ctx->s.v32[i] = SWAP32(ctx->s.v32[i]);
    ; }
    ;
    ; memcpy (dgst, ctx->s.v8, SM3_DIGEST_LENGTH);
    mov    cl, SM3_LBLOCK
    lea    esi, [ebx+state]
    mov    edi, [esp+32+4] ; dgst
swap_words:
    lodsd
    bswap  eax
    stosd
    loop   swap_words
    popad
    ret

%define _a dword[edi+0*4]
%define _b dword[edi+1*4]
%define _c dword[edi+2*4]
%define _d dword[edi+3*4]
%define _e dword[edi+4*4]
%define _f dword[edi+5*4]
%define _g dword[edi+6*4]
%define _h dword[edi+7*4]

_SM3_Transformx:
    pushad

    ; load state into esi
    lea     esi, [ebx+state]
    push    esi  ; save for later

    ; allocate 512 bytes
    push    64
    pop     ecx
    shl     ecx, 3
    sub     esp, ecx

    ; load state into local buffer
    mov     edi, esp
    push    8
    pop     ecx
    rep     movsd

    ; store message in big endian format
    mov     cl, 16
s3t_l0:
    lodsd
    bswap   eax
    stosd
    loop    s3t_l0

    ; expand message
    mov     cl, 68-16
s3t_l1:
    ; x = ROTL32(w[i-3], 15);
    mov     eax, [edi- 3*4]
    rol     eax, 15
    ; y = ROTL32(w[i-13], 7);
    mov     ebx, [edi-13*4]
    rol     ebx, 7
    ; x ^= w[i-16];
    xor     eax, [edi-16*4]
    ; x ^= w[i-9];
    xor     eax, [edi- 9*4]
    ; y ^= w[i-6];
    xor     ebx, [edi- 6*4]
    ; x ^= ROTL32(x, 15) ^ ROTL32(x, 23);
    mov     edx, eax
    rol     edx, 15
    xor     eax, edx
    rol     edx, 23-15
    xor     eax, edx
    ; x ^= y;
    xor     eax, ebx
    ; w[i] = x;
    stosd
    loop    s3t_l1

    ; permute message
    mov     edi, esp
s3t_l2:
    ; t  = (i < 16) ? 0x79cc4519 : 0x7a879d8a;
    cmp     ecx, 16
    sbb     eax, eax
    and     eax, 0x79cc4519 - 0x7a879d8a
    add     eax, 0x7a879d8a
    ; ss2 = ROTL32(a, 12);
    mov     ebx, _a
    rol     ebx, 12
    ; ss1 = ROTL32(ss2 + e + ROTL32(t, i), 7);
    rol     eax, cl
    add     eax, ebx
    add     eax, _e
    rol     eax, 7
    ; ss2 ^= ss1;
    xor     ebx, eax
    ; tt1 = d + ss2 + (w[i] ^ w[i+4]);
    mov     ebp, eax         ; save ss1
    mov     esi, [edi+4*ecx+32]       ; esi = w[i]
    mov     edx, esi         ; save w[i]
    xor     esi, [edi+4*ecx+32+16]    ; esi ^= w[i+4]
    add     esi, _d
    lea     eax, [esi+ebx]   ; set tt1
    ; tt2 = h + ss1 + w[i];
    lea     ebx, [edx+ebp]
    add     ebx, _h
    ; if (i < 16) {
    cmp     ecx, 16
    jae     s3t_l3
    ; tt1 += F(a, b, c);
    mov     edx, _c
    xor     edx, _b
    xor     edx, _a
    add     eax, edx
    ; tt2 += F(e, f, g);
    mov     edx, _g
    xor     edx, _f
    xor     edx, _e
    add     ebx, edx
    jmp     s3t_l4
s3t_l3:
    ; tt1 += FF(a, b, c);
    mov     edx, _b
    or      edx, _a
    mov     ebp, _b
    and     edx, _c
    and     ebp, _a
    or      edx, ebp
    add     eax, edx
    ; tt2 += GG(e, f, g);
    mov     edx, _g
    xor     edx, _f
    and     edx, _e
    xor     edx, _g
    add     ebx, edx
s3t_l4:
    ; d = c;
    mov     edx, _c
    mov     _d, edx
    ; c = ROTL32(b, 9);
    mov     edx, _b
    rol     edx, 9
    mov     _c, edx
    ; b = a;
    mov     edx, _a
    mov     _b, edx
    ; a = tt1;
    mov     _a, eax
    ; h = g;
    mov     edx, _g
    mov     _h, edx
    ; g = ROTL32(f, 19);
    mov     edx, _f
    rol     edx, 19
    mov     _g, edx
    ; f = e;
    mov     edx, _e
    mov     _f, edx
    ; e = P0(tt2);
    ; e = x ^ ROTL32(x,  9) ^ ROTL32(x, 17)
    mov     edx, ebx
    rol     edx, 9
    xor     ebx, edx
    rol     edx, 17-9
    xor     ebx, edx
    mov     _e, ebx

    inc     ecx
    cmp     ecx, 64
    jnz     s3t_l2

    mov     esi, esp
    lea     esp, [esi+ecx*8]

    pop     edi
    mov     cl, 8
s3t_l5:
    lodsd
    xor     eax, [edi]
    stosd
    loop    s3t_l5
    popad
    ret

