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
; SM4 block cipher in x86 assembly (encryption only)
;
; size: 276 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------

    bits 32
    
    %ifndef BIN
      global sm4
    %endif
    
sm4:
    pushad                     ; save registers
    pushad                     ; allocate 32 bytes for key+plaintext
    mov    edi, esp            ; edi = x
    ; W fk[4]={0xa3b1bac6,0x56aa3350,0x677d9197,0xb27022dc};
    ; F(i,4)x[i+4]=rev(((W*)mk)[i])^fk[i],x[i]=rev(((W*)in)[i]);
    push   2
    pop    ecx
    ; load the 128-bit key and 128-bit plaintext
sm_L0:
    mov    esi, [esp+64+4*ecx] ; esi = mk or data
    push   ecx
    mov    cl, 4
sm_L1:
    lodsd                      ; eax = mk[i] or data[i]
    bswap  eax                 ; reverse byte order
    stosd                      ; x[i]=eax
    loop   sm_L1
    pop    ecx
    loop   sm_L0
    xchg   eax, ecx            ; i = 0
    
    xor    dword[edi-16], 0xa3b1bac6
    xor    dword[edi-12], 0x56aa3350
    xor    dword[edi- 8], 0x677d9197
    xor    dword[edi- 4], 0xb27022dc
    ; F(j,4)c|=((((i*4)+j)*7)&255),c=R(c,8);
    ; calculate round constant
sm_L2:
    push   4                   ; j = 4
    pop    ecx
    cdq                        ; c = 0
sm_L3:
    lea    ebx, [eax*4+ecx-1]  ; ebx = (i*4) + (j-1)
    imul   ebx, ebx, 7         ; ebx *= 7
    or     dl, bl              ; c |= ebx % 256
    ror    edx, 8              ; c = R(c, 8)
    loop   sm_L3
    lea    esi, [esp+32]
sm_L4:
    sub    esi, 16             ; p = &x[s*4]
    ; add round constant or sub key
    ; c ^= p[(i+1)%4] ^ p[(i+2)%4] ^ p[(i+3)%4];
    lea    edi, [eax+1]        ; c ^= p[(i+1)%4]
    and    edi, 3
    xor    edx, [esi+4*edi]
    lea    edi, [eax+2]        ; c ^= p[(i+2)%4]
    and    edi, 3
    xor    edx, [esi+4*edi]
    lea    edi, [eax+3]        ; c ^= p[(i+3)%4]
    and    edi, 3
    xor    edx, [esi+4*edi]
    ; non-linear layer
    ; F(j,4)c=(c&-256)|S(c),c=R(c,8);
    xchg   eax, edx
    mov    cl, 4
sm_L5:
    call   S
    ror    eax, 8
    loop   sm_L5
    xchg   eax, edx
    ; linear layer
    ; c = p[i%4] ^= c ^ ((s) ? R(c,19)^R(c,9) : R(c,30)^R(c,22)^R(c,14)^R(c,8));
    mov    edi, edx
    mov    ebp, edx
    ; for key setup
    ror    edi, 19
    ror    ebp, 9
    cmp    esi, esp
    jnz    sm_L6
    ; for encryption
    ror    edi, 30-19
    ror    ebp, 22-9
    xor    edx, edi
    xor    edx, ebp
    ror    edi, (32-30)+14
    ror    ebp, (32-22)+8
sm_L6:
    xor    edx, edi           ; t^= R(t, 30) or R(t, 19)
    xor    edx, ebp           ; t^= R(t, 22) or R(t,  9)
    mov    edi, eax           ; ebx = i % 4
    and    edi, 3
    xor    edx, [esi+4*edi]   ; t ^= p[i%4]
    mov    [esi+4*edi], edx   ; p[i%4] = t
    cmp    esi, esp
    jnz    sm_L4
    
    inc    eax                ; i++
    cmp    al, 32             ; i<32
    jnz    sm_L2

    ; store ciphertext
    ; F(i,4)((W*)data)[3-i]=rev(x[i]);
    mov    edi, [esp+64+8]     ; edi = data
    mov    cl, 4
sm_L7:
    lodsd                      ; eax = x[0]
    bswap  eax
    mov    [edi+4*ecx-4], eax
    loop   sm_L7
    popad                      ; release memory
    popad                      ; restore registers
    ret


    ; *****************************
    ; B S(B x)
    ; *****************************
S:  
    pushad
    ; affine transformation
    ; x = A(x);
    call   A
    ; multiplicative inverse
    ; uses x^8 + x^7 + x^6 + x^5 + x^4 + x^2 + 1 as IRP
    test   al, al            ; if(x){
    jz     sb_l6
    xchg   eax, edx          ; dl = x
    mov    cl, -1            ; i=255 
; for(c=i=0,y=1;--i;y=(!c&&y==x)?c=1:y,y^=(y<<1)^((-(y>>7))&0xF5));
sb_l0:
    mov    al, 1             ; y=1
sb_l1:
    test   ah, ah            ; !c
    jnz    sb_l2    
    cmp    al, dl            ; y!=x
    setz   ah
    jz     sb_l0
sb_l2:
    mov    bl, al            ; y^=(y<<1)^((-(y>>7))&0xF5)
    add    bl, bl
    sbb    bh, bh
    and    bh, 0xF5
    xor    bl, bh
    xor    al, bl
    loop   sb_l1             ; --i
sb_l6:
    ; affine transformation
    call   A
    mov    [esp+28], al
    popad
    ret

A:
    mov    dl, al
    mov    ah, 0xA7           ; m = 0xA7
    xor    al, al             ; s = 0
ax_L0:
    ; for(t=x&m;t!=0;t>>=1)s^=(t&1);
    mov    dh, dl             ; t = x & m
    and    dh, ah
ax_L1:
    test   dh, dh             ; t!=0
    jz     ax_L2
    shr    dh, 1              ; t>>=1
    jnc    ax_L1
    xor    al, 1
    jmp    ax_L1
ax_L2:
    ror    al, 1              ; s = (s>>1) | (s<<7);
    rol    ah, 1              ; m = (m<<1) | (m>>7);
    cmp    ah, 0xA7           ; while(m != 0xA7);
    jne    ax_L0
    xor    al, 0xD3           ; return s ^ 0xD3
    ret
  
