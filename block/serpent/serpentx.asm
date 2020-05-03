;
;  Copyright © 2015, 2018 Odzhan, Peter Ferrie. All Rights Reserved.
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
; Serpent-256 block cipher in x86 assembly (Encryption only)
;
; size: 364 bytes
;
; global calls use cdecl convention
;
; -----------------------------------------------
    bits 32
    
    %ifndef BIN
      global serpent
    %endif

    %define x  edi
    %define k  esi
    
    %define x0 eax
    %define x1 ebx
    %define x2 ecx
    %define x3 edx
    %define x4 ebp

serpent:
    pushad
    mov    esi, [esp+32+4]    ; esi = mk
    ; allocate 64 bytes of memory
    pushad
    pushad
    ; copy 256-bit key to local memory
    ; F(i,8)k[i]=((W*)mk)[i];
    mov    edi, esp
    push   8
    pop    ecx
    rep    movsd
sx_main:
    ; create a subkey for this round
    ; rk[j]=R((k[0]^k[3]^k[5]^k[7]^0x9e3779b9UL^(i*4+j)),21);
    xor    edx, edx           ; edx = j
    mov    esi, esp           ; esi = k
    lea    edi, [esi+32]      ; edi = rk
sx_subkey:
    mov    eax, [esi]         ; t =k[0]
    xor    eax, [esi+3*4]     ; t^=k[3]
    xor    eax, [esi+5*4]     ; t^=k[5]
    xor    eax, [esi+7*4]     ; t^=k[7]
    xor    eax, 0x9e3779b9    ; t^=0x9e3779b9UL
    lea    ebp, [edx+4*ecx]   ; ebp=(j+4*i)
    xor    eax, ebp           ; t^=ebp
    ror    eax, 21            ; t = R(t, 21)
    mov    [edi+4*edx], eax   ; rk[j]=t
    
    ; F(s,7)k[s]=k[s+1];
    pushad
    push   esi                ; save k
    cmpsd                     ; esi = &k[1]
    pop    edi                ; edi = &k[0]
    mov    cl, 7
    rep    movsd
    ; k[7]=rk[j];
    stosd
    popad
    
    ; j++
    inc    edx
    cmp    dl, 4
    jne    sx_subkey
    
    ; sbox(rk, 3-i);
    dec    edx    
    sub    edx, ecx           ; 3 - i
    call   sbox
    
    mov    esi, [esp+96+8]    ; esi = data
        
    ; linear layer  
    ; x[0]^=rk[0];x[1]^=rk[1];
    ; x[2]^=rk[2];x[3]^=rk[3];
    pushad
    mov    cl, 4
xor_key:
    mov    eax, [edi]         ; eax = rk[i]
    xor    [esi], eax         ; x[i]^= eax
    cmpsd                     ; advance esi and edi
    loop   xor_key
    popad
    
    ; if(i==32)break;
    cmp    cl, 32
    je     sx_end
    
    ; nonlinear layer
    ; sbox(x, i);
    mov    edx, ecx
    mov    edi, esi
    call   sbox
    
    ; if(++i != 32) {
    inc    ecx
    cmp    cl, 32
    je     sx_main
    
    ; linear layer
    pushad
    lodsd
    xchg   x3, eax
    lodsd
    xchg   x1, eax
    lodsd
    xchg   x2, eax
    lodsd
    xchg   x3, eax
    ; x[0]=R(x[0],19);x[2]=R(x[2],29);
    ror    x0, 19
    ror    x2, 29
    ; x[1]^=x[0]^x[2];x[3]^=x[2]^(x[0]<<3);
    xor    x1, x0
    xor    x1, x2
    xor    x3, x2
    mov    x4, x0
    shl    x4, 3
    xor    x3, x4
    ; x[1]=R(x[1],31);x[3]=R(x[3],25);
    ror    x1, 31
    ror    x3, 25
    ; x[0]^=x[1]^x[3];x[2]^=x[3]^(x[1]<<7);
    xor    x0, x1
    xor    x0, x3
    xor    x2, x3
    mov    x4, x1
    shl    x4, 7
    xor    x2, x4
    ; x[0]=R(x[0],27);x[2]=R(x[2],10);
    ror    x0, 27
    ror    x2, 10
    stosd
    xchg   x1, eax
    stosd
    xchg   x2, eax
    stosd
    xchg   x3, eax
    stosd
    popad
    jmp    sx_main
    
sx_end:
    popad
    popad
    popad
    ret

    ; edx = idx
    ; edi = x
sbox:
    pushad
    call   init_sbox    
; sbox
  db 083h, 01Fh, 06Ah, 0B5h, 0DEh, 024h, 007h, 0C9h
  db 0CFh, 072h, 009h, 0A5h, 0B1h, 08Eh, 0D6h, 043h
  db 068h, 097h, 0C3h, 0FAh, 01Dh, 04Eh, 0B0h, 025h
  db 0F0h, 08Bh, 09Ch, 036h, 01Dh, 042h, 07Ah, 0E5h
  db 0F1h, 038h, 00Ch, 06Bh, 052h, 0A4h, 0E9h, 0D7h
  db 05Fh, 0B2h, 0A4h, 0C9h, 030h, 08Eh, 06Dh, 017h
  db 027h, 05Ch, 048h, 0B6h, 09Eh, 0F1h, 03Dh, 00Ah
  db 0D1h, 00Fh, 08Eh, 0B2h, 047h, 0ACh, 039h, 065h  
init_sbox:
    pop    esi               ; esi=sbox
    and    edx, 7            ; %= 8
    lea    esi, [esi+8*edx]  ; esi = &sbox[i*8]
    mov    edx, edi
    call   ld_perm
    
; void permute (out, in);
; edi = out
; esi = in
; CF = type
permute:
    pushad
    xchg   eax, ecx    ; ecx should be zero
    push   16
    pop    ecx
    pushad
    rep    stosb
    popad
    cdq            ; m=0
    jnc    do_fp
    ; initial permutation
ip_m_l:
    mov    eax, edx
    and    eax, 3
    shr    dword[esi+4*eax], 1
    rcr    byte[edi], 1
    inc    edx
    test   dl, 7
    jne    ip_m_l
    inc    edi
    loop   ip_m_l
xit_perm:
    popad
    ret
    ; final permutation
do_fp:
    mov    cl, 4    ; n=4
fp_m_l:
    mov    eax, edx
    and    eax, 3
    shr    dword[esi], 1
    rcr    dword[edi+4*eax], 1
    inc    edx
    test   dl, 31
    jne    fp_m_l
    lodsd
    loop   fp_m_l
    popad
    ret
    
ld_perm:
    pop    ebp
    
    pushad          ; create 2 16-byte blocks
    mov    ebx, esp          ; ebx=sb
    mov    edi, esp          ; edi=sb
    mov    cl, 8             ; SERPENT_BLK_LEN/2
sb_l1:
    lodsb                    ; t = sbp[i/2];
    aam    16
    stosw
    loop   sb_l1
    
    ; permute (&tmp_blk, blk, SERPENT_IP);
    mov    esi, edx
    stc
    call   ebp ;permute
    mov    esi, edi
    mov    cl, 16
    push   esi
sb_l2:
    lodsb
    aam    16
    xchg   ah, al
    xlatb
    xchg   ah, al
    xlatb
    aad    16 
    stosb
    loop   sb_l2
    
    pop    esi
    mov    edi, edx
    ; permute (blk, &tmp_blk, SERPENT_FP);
    call   ebp
    popad
    popad
    ret
