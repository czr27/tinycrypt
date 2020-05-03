
.686
.model flat, stdcall

;option casemap:none
option prologue:none
option epilogue:none

BIGINT    STRUCT
  dd  4 dup (?)
BIGINT    ENDS

VBIGINT STRUCT
  dd  8 dup (?)
VBIGINT ENDS

addmod    PROTO :DWORD, :DWORD, :DWORD
adduintmod  PROTO :DWORD, :DWORD, :DWORD
compare   PROTO :DWORD, :DWORD
comparezero PROTO :DWORD
compareone  PROTO :DWORD
converth2bmod PROTO :DWORD, :DWORD
copy    PROTO :DWORD, :DWORD
div2    PROTO :DWORD
div2mod   PROTO :DWORD
fixmod    PROTO :DWORD
invmod    PROTO :DWORD
modulo    PROTO :DWORD, :DWORD
mulmod    PROTO :DWORD, :DWORD, :DWORD
multiply  PROTO :DWORD, :DWORD, :DWORD
setmod    PROTO :DWORD
submod    PROTO :DWORD, :DWORD, :DWORD
zero    PROTO :DWORD

ECPOINT   STRUCT
  INFINITY  dd  ?
  X   dd  4 dup (?)
  Y   dd  4 dup (?)
ECPOINT   ENDS

ECPOINTJ  STRUCT
  X   dd  4 dup (?)
  Y   dd  4 dup (?)
  Z   dd  4 dup (?)
ECPOINTJ  ENDS

ECP_Add   PROTO :DWORD, :DWORD
ECP_Copy  PROTO :DWORD, :DWORD
ECP_Dbl   PROTO :DWORD, :DWORD
ECP_Mul   PROTO :DWORD, :DWORD, :DWORD
ECP_A2J   PROTO :DWORD, :DWORD
ECP_J2A   PROTO :DWORD, :DWORD
ECP_Add_J PROTO :DWORD, :DWORD
ECP_Dbl_J PROTO :DWORD, :DWORD

set_N   PROTO
set_P   PROTO

.data

tempECMInt  BIGINT<>
tempECMPnt1 ECPOINTJ<>
tempECMPnt2 ECPOINTJ<>

tempInt1  BIGINT<>
tempInt2  BIGINT<>
tempInt3  BIGINT<>
_PC   BIGINT<>
_NC   BIGINT<>

; RandomCurve1-P128-WiteG
; y^2 = x^3 - 3*x + 103744651967215942079424252318256895516 mod 340282366920938463444927863358058659863
; N = 340282366920938463450938462077435853809

_A    dd  000000014h, 000000000h, 0FFFFFFFFh, 0FFFFFFFFh
_B    dd  07C72961Ch, 082522799h, 000CE59BEh, 04E0C7E41h
_P    dd  000000017h, 000000000h, 0FFFFFFFFh, 0FFFFFFFFh
_N    dd  093E53BF1h, 05369EFB0h, 0FFFFFFFFh, 0FFFFFFFFh
KEY_BASEPOINT dd  1
    dd  0FD79309Fh, 061174BA8h, 09A2B41A1h, 0504E0BD3h
    dd  0D469DED4h, 0BB0D8845h, 07279A790h, 09A45FA6Dh
    
comment ~    
set_P   proc
  invoke  setmod, offset _P
  ret
set_P   endp

set_N   proc
  invoke  setmod, offset _N
  ret
set_N   endp

ECP_Zero_J  proc  ptrA:DWORD

  pushad

  xor eax, eax
  mov ecx, (16+16+16)/4
  mov edi, dword ptr [esp+20h+4]
  cld
  rep stosd

  popad
  ret 4

ECP_Zero_J  endp

ECP_Copy  proc  ptrA:DWORD, ptrB:DWORD

  pushad

  mov esi, dword ptr [esp+20h+4]
  mov edi, dword ptr [esp+20h+4+4]

  ;assume esi: ptr ECPOINT
  ;assume edi: ptr ECPOINT

  mov eax, [esi+ECPOINT.INFINITY]
  mov [edi+ECPOINT.INFINITY], eax

  lea ebx, [esi+ECPOINT.X]
  lea ebp, [edi+ECPOINT.X]
  invoke  copy, ebx, ebp

  lea ebx, [esi+ECPOINT.Y]
  lea ebp, [edi+ECPOINT.Y]
  invoke  copy, ebx, ebp

  popad
  ret 8

ECP_Copy  endp

ECP_Zero  proc  ptrA:DWORD

  pushad

  xor eax, eax
  mov ecx, (4+16+16)/4
  mov edi, dword ptr [esp+20h+4]
  cld
  rep stosd

  popad
  ret 4

ECP_Zero  endp

ECP_Mul   proc  ptrInt:DWORD, ptrA:DWORD, ptrB:DWORD

  pushad

  mov ebp, dword ptr [esp+20h+4]  ;ptrInt
  mov esi, dword ptr [esp+20h+8]  ;ptrA

  mov edi, offset tempECMPnt1
  mov ebx, offset tempECMInt

  invoke  copy, ebp, ebx      ;n
  invoke  ECP_A2J, esi, edi   ;edi = P (J)

  mov esi, offset tempECMPnt2
  ;assume esi: ptr ECPOINTJ

  lea eax, [esi+ECPOINTJ.Z]
  invoke  zero, eax     ;esi = Q (J) inf.

  invoke  comparezero, ebx
  jz  @done

mul_loop:
  ; if (b & 1) 
  ; {
  invoke  div2, ebx
  jnc @F
  
  ; point_add();
  invoke  ECP_Add_J, edi, esi
  ; }
  @@:

  ; b >>= 1;
  ; if (b==0) break;
  invoke  comparezero, ebx
  jz  @done
  
  ; point_double(); 
  invoke  ECP_Dbl_J, edi, edi
  jmp mul_loop

@done:
  invoke  ECP_J2A, esi, dword ptr [esp+20h+12]

  invoke  ECP_Zero_J, esi
  invoke  ECP_Zero_J, edi

  popad
  ret 12

ECP_Mul   endp

ECP_J2A   proc  ptrA:DWORD, ptrB:DWORD

  pushad

  mov esi, dword ptr [esp+20h+4]  ;ptrA
  mov edi, dword ptr [esp+20h+8]  ;ptrB

  ;assume esi: ptr ECPOINTJ
  ;assume edi: ptr ECPOINT

  lea ebp, [esi+ECPOINTJ.Y]
  lea ecx, [esi+ECPOINTJ.Z]

  lea eax, [edi+ECPOINT.X]
  lea edx, [edi+ECPOINT.Y]

  invoke  comparezero, ecx
  jz  @return0

  ; T1 = Z
  invoke  copy, ecx, offset tempInt1
  
  ; T1 = (T1 ^ -1) mod p
  invoke  invmod, offset tempInt1
  
  ; calculate Z^2
  ; T2 = T1 ^ 2 mod p
  invoke  mulmod, offset tempInt1, offset tempInt1, offset tempInt2
  
  ; calculate Z^3
  ; T1 = T1 * T2 mod p
  invoke  mulmod, offset tempInt1, offset tempInt2, offset tempInt1
  
  ; multiply Y by Z^3 
  ; AY = JY * T1 mod p
  invoke  mulmod, ebp, offset tempInt1, edx

  ; multiply X by Z^2   
  ; AX = JX * T2 mod p
  invoke  mulmod, esi, offset tempInt2, eax

  invoke  zero, offset tempInt1
  invoke  zero, offset tempInt2

  mov dword ptr[edi+ECPOINT.INFINITY], 1

@ret: popad
  ret 8

@return0:
  mov [edi].INFINITY, 0
  jmp @ret

ECP_J2A   endp

ECP_Dbl_J proc  ptrA:DWORD, ptrB:DWORD

  pushad

  mov esi, dword ptr [esp+20h+4]
  mov edi, dword ptr [esp+20h+8]

  ;assume esi: ptr ECPOINTJ
  ;assume edi: ptr ECPOINTJ

  lea edx, [esi].Y
  lea ecx, [esi].Z

  lea ebx, [edi].Y
  lea ebp, [edi].Z

  invoke  comparezero, ecx
  jz  @return0

  invoke  mulmod, ecx, ecx, offset tempInt1 ;T1 = Z^2
  invoke  mulmod, edx, ecx, ebp     ;Z_2 = Z*Y
  invoke  addmod, ebp, ebp, ebp     ;Z = 2*Z

  invoke  adduintmod, offset _A, 3, offset tempInt2
  invoke  comparezero, offset tempInt2    ;(_A == -3)

  jnz @nm3

    invoke  submod, esi, offset tempInt1, offset tempInt2     ;T2 = X - T1
    invoke  addmod, esi, offset tempInt1, offset tempInt1     ;T1 = X + T1
    invoke  mulmod, offset tempInt1, offset tempInt2, offset tempInt2 ;T2 = T1 * T2
    invoke  addmod, offset tempInt2, offset tempInt2, offset tempInt1 ;T1 = 2*T2
    invoke  addmod, offset tempInt1, offset tempInt2, offset tempInt1 ;T1 = T1 + T2
    jmp @F

  @nm3:
    invoke  mulmod, offset tempInt1, offset tempInt1, offset tempInt1 ;T1 = T1^2
    invoke  mulmod, offset _A, offset tempInt1, offset tempInt1   ;T1 = A * T1
    invoke  mulmod, esi, esi, offset tempInt2       ;T2 = X^2
    invoke  addmod, offset tempInt1, offset tempInt2, offset tempInt1 ;T1 = T1 + T2
    invoke  addmod, offset tempInt2, offset tempInt2, offset tempInt2 ;T2 = 2*T2
    invoke  addmod, offset tempInt1, offset tempInt2, offset tempInt1 ;T1 = T1 + T2
@@:
  invoke  addmod, edx, edx, ebx     ;Y_2 = 2*Y
  invoke  mulmod, ebx, ebx, ebx     ;Y = Y^2
  invoke  mulmod, ebx, ebx, offset tempInt2 ;T2 = Y^2
  invoke  mulmod, ebx, esi, ebx     ;Y = Y*X

  invoke  div2mod, offset tempInt2    ;T2 = T2/2
  invoke  mulmod, offset tempInt1, offset tempInt1, edi
              ;X_2 = T1^2
  invoke  submod, edi, ebx, edi     ;X = X - Y
  invoke  submod, edi, ebx, edi     ;X = X - Y
  invoke  submod, ebx, edi, ebx     ;Y = Y - X
  invoke  mulmod, ebx, offset tempInt1, ebx ;Y = Y * T1
  invoke  submod, ebx, offset tempInt2, ebx ;Y = Y - T2

  invoke  zero, offset tempInt1
  invoke  zero, offset tempInt2

@ret: popad
  ret 8

@return0:
  invoke  zero, ebp
  jmp @ret
ECP_Dbl_J endp

ECP_Dbl   proc  ptrA:DWORD, ptrB:DWORD
  pushad

  mov esi, dword ptr [esp+20h+4]

  ;assume esi: ptr ECPOINT
  ;assume edi: ptr ECPOINT

  mov eax, [esi].INFINITY
  test  eax, eax
  jz  @return0

  lea ebx, [esi].X
  lea ebp, [esi].Y

  invoke  comparezero, ebp
  jz  @return0

  ; square Px
  ; T1 = (Px^2) mod p
  invoke  mulmod, ebx, ebx, offset tempInt1
  
  ; multiply T1 by 2 by adding T1 to T1
  ; T2 = (T1 + T1) mod p
  invoke  addmod, offset tempInt1, offset tempInt1, offset tempInt2
  
  ; now get (Px ^ 2) * 3 by adding T2 to T1
  ; T1 = (T1 + T2) mod p
  invoke  addmod, offset tempInt1, offset tempInt2, offset tempInt1
  
  ; add a to T1
  ; T1 = T1 + a mod p
  invoke  addmod, offset tempInt1, offset _A, offset tempInt1
  
  ; so that's the top part done..
  ; now
  ; Int1 = 3 * x1 ^ 2 + a

  invoke  addmod, ebp, ebp, offset tempInt2   ;Int2 = 2*y1
  invoke  invmod, offset tempInt2       ;Int2 = (2*y1)^(-1)
  invoke  mulmod, offset tempInt1, offset tempInt2, offset tempInt1
                ;Int1 = (3*x1^2 + a)/(2*y1)

  invoke  mulmod, offset tempInt1, offset tempInt1, offset tempInt2
                ;Int2 = [(3*x1^2 + a)/(2*y1)]^2
  invoke  submod, offset tempInt2, ebx, offset tempInt2 ;Int2 = [(3*x1^2 + a)/(2*y1)]^2 - x1
  invoke  submod, offset tempInt2, ebx, offset tempInt2 ;Int2 = [(3*x1^2 + a)/(2*y1)]^2 - 2*x1
                ;Int2 = x3

;-----
  invoke  submod, ebx, offset tempInt2, offset tempInt3 ;Int3 = x1 - x3
  invoke  mulmod, offset tempInt1, offset tempInt3, offset tempInt3
                ;Int3 = [(3*x1^2 + a)/(2*y1)](x1 - x3)
  invoke  submod, offset tempInt3, ebp, offset tempInt1 ;Int1 = [(3*x1^2 + a)/(2*y1)](x1 - x3) - y1
                ;Int1 = y3
;-----

  mov edi, dword ptr [esp+20h+4+4]

  mov [edi].INFINITY , 1
  lea ebx, [edi].X
  lea ebp, [edi].Y

  invoke  copy, offset tempInt2, ebx
  invoke  copy, offset tempInt1, ebp

  invoke  zero, offset tempInt1
  invoke  zero, offset tempInt2
  invoke  zero, offset tempInt3

@returnB:
  popad
  ret 8

@return0:
  mov edi, dword ptr [esp+20h+4+4]
  and [edi].INFINITY , 0
  jmp @returnB

ECP_Dbl   endp

ECP_Add_J proc  ptrA:DWORD, ptrB:DWORD

  pushad

  mov esi, dword ptr [esp+20h+4]
  mov edi, dword ptr [esp+20h+8]

  ;assume esi: ptr ECPOINTJ
  ;assume edi: ptr ECPOINTJ

  lea edx, [esi].Y
  lea ecx, [esi].Z    ;P

  lea ebx, [edi].Y    ;Q
  lea ebp, [edi].Z
          ;A=P: X2 = esi, Y2 = edx, Z2 = ecx
          ;B=Q: X  = edi, Y  = ebx, Z  = ebp
  invoke  comparezero, ecx
  jz  @ret      ;if (Z2 == 0) return B, do nothing

  invoke  comparezero, ebp
  jz  @returnA    ;if (Z  == 0) return A

  invoke  compareone, ecx
  jz  @F

  invoke  mulmod, ecx, ecx, offset tempInt1     ;T1 = Z2^2  
  invoke  mulmod, offset tempInt1, edi, edi     ;X = X*T1
  invoke  mulmod, offset tempInt1, ecx, offset tempInt1   ;T1 = Z2*T1
  invoke  mulmod, offset tempInt1, ebx, ebx     ;Y = Y*T1
@@:
  invoke  mulmod, ebp, ebp, offset tempInt1     ;T1 = Z^2
  invoke  mulmod, offset tempInt1, esi, offset tempInt2   ;T2 = X2*T1
  invoke  mulmod, offset tempInt1, ebp, offset tempInt1   ;T1 = Z*T1
  invoke  mulmod, offset tempInt1, edx, offset tempInt1   ;T1 = Y2*T1
  invoke  submod, offset tempInt1, ebx, offset tempInt1   ;T1 = T1 - Y
  invoke  submod, offset tempInt2, edi, offset tempInt2   ;T2 = T2 - X
  invoke  comparezero, offset tempInt2
  jnz @T2ne0

    invoke  comparezero, offset tempInt1
    jnz @return0

      invoke  ECP_Dbl_J, esi, edi
      jmp @ret

@T2ne0:
  invoke  compareone, ecx
  jz  @F

    invoke  mulmod, ebp, ecx, ebp       ;Z = Z*Z2

@@:
  invoke  mulmod, ebp, offset tempInt2, ebp     ;Z = Z*T2
  invoke  mulmod, offset tempInt2, offset tempInt2, offset tempInt3
                  ;T3 = T2^2
  invoke  mulmod, offset tempInt2, offset tempInt3, offset tempInt2
                  ;T2 = T2*T3
  invoke  mulmod, offset tempInt3, edi, offset tempInt3   ;T3 = X*T3
  invoke  mulmod, offset tempInt1, offset tempInt1, edi   ;X = T1^2
  invoke  mulmod, offset tempInt2, ebx, ebx     ;Y = T2*Y
  invoke  submod, edi, offset tempInt2, offset tempInt2   ;T2 = X - T2
  invoke  addmod, offset tempInt3, offset tempInt3, edi   ;X = 2*T3
  invoke  submod, offset tempInt2, edi, edi     ;X = T2 - X
  invoke  submod, offset tempInt3, edi, offset tempInt2   ;T2 = T3 - X
  invoke  mulmod, offset tempInt1, offset tempInt2, offset tempInt2
                  ;T2 = T1*T2
  invoke  submod, offset tempInt2, ebx, ebx     ;Y = T2 - Y

@ret:
  invoke  zero, offset tempInt1
  invoke  zero, offset tempInt2
  invoke  zero, offset tempInt3
  popad
  ret 8

@return0:
          ;A=P: X2 = esi, Y2 = edx, Z2 = ecx
          ;B=Q: X  = edi, Y  = ebx, Z  = ebp
  invoke  zero, ebp
  jmp @ret
@returnA:
  invoke  copy, esi, edi
  invoke  copy, edx, ebx
  invoke  copy, ecx, ebp

  jmp @ret

ECP_Add_J endp

ECP_Add   proc  ptrA:DWORD, ptrB:DWORD

  pushad

  mov esi, dword ptr [esp+20h+4]
  mov edi, dword ptr [esp+20h+4+4]

  ;assume esi: ptr ECPOINT
  ;assume edi: ptr ECPOINT

  mov eax, [esi].INFINITY
  test  eax, eax
  jz  @returnB

  mov eax, [edi].INFINITY
  test  eax, eax
  jz  @returnA

; zaden z punktow nie jest w nieskonczonosci

  lea ebx, [esi].X
  lea ebp, [edi].X
  lea eax, [esi].Y
  lea edx, [edi].Y

  invoke  compare, ebx, ebp
  jnz @AisntminusB

  invoke  compare, eax, edx
  jz  @doubleA

; sprawdzmy czy A = -B

  ;jesli x1 == x2 musimy sprawdzic czy y2 = -y1 (modulo prime), wiemy ze y2 != y1
  ;wiec mozemy pominac sytuacje kiedy y2=y1=0

  invoke  submod, offset _P, eax, offset tempInt1 ;-y1 mod p
  invoke  compare, edx, offset tempInt1     ;cmp y2, -y1 mod p
  jz  @return0

@AisntminusB:

; dodajemy punkty :)
; add points :)

  ; calculate s
  ; T1 = Py - Qy mod p
  invoke  submod, edx, eax, offset tempInt1
  
  ; T2 = Px - Qx
  invoke  submod, ebp, ebx, offset tempInt2
  
  ; T2 = T2 ^ -1 mod p
  invoke  invmod, offset tempInt2
  
  ; s = T1 * T2 mod p 
  invoke  mulmod, offset tempInt1, offset tempInt2, offset tempInt3
  
  ; T1 = s^2 mod p
  invoke  mulmod, offset tempInt3, offset tempInt3, offset tempInt1

  ; T1 = T1 - Qx mod p 
  invoke  submod, offset tempInt1, ebx, offset tempInt1
  
  ; Rx = ((s^2) - Qx) - Px mod p
  invoke  submod, offset tempInt1, ebp, offset tempInt1
  
  ; Rx = (Qx)
  invoke  submod, ebx, offset tempInt1, offset tempInt2
  
  ; s = (s * ) mod p
  invoke  mulmod, offset tempInt3, offset tempInt2, offset tempInt3

  ; Ry = (s - Py) mod p
  invoke  submod, offset tempInt3, eax, offset tempInt2

  
  invoke  copy, offset tempInt1, ebp
  invoke  copy, offset tempInt2, edx

@returnB:
  invoke  zero, offset tempInt1
  invoke  zero, offset tempInt2
  invoke  zero, offset tempInt3

  popad
  ret 8

@doubleA:
  invoke  ECP_Dbl, esi, edi
  jmp @returnB

@return0:
  and [edi].INFINITY , 0
  jmp @returnB

@returnA:
  invoke  ECP_Copy, esi, edi
  jmp @returnB

ECP_Add   endp
~
; When you go from Affine to Jacobian, X and Y stay the same, and Z is equal to 1
ECP_A2J   proc  ptrA:DWORD, ptrB:DWORD

  pushad

  mov esi, dword ptr [esp+20h+4]  ;ptrA
  mov edi, dword ptr [esp+20h+8]  ;ptrB

  ;assume esi: ptr ECPOINT
  ;assume edi: ptr ECPOINTJ

  lea eax, [esi+ECPOINT.X]
  lea edx, [esi+ECPOINTJ.Y]

  lea ebp, [edi+ECPOINTJ.Y]
  lea ecx, [edi+ECPOINTJ.Z]

  cmp dword ptr[esi+ECPOINT.INFINITY], 0
  jz  exit_a2j

  invoke  copy, eax, edi      ;X2 = X1
  invoke  copy, edx, ebp      ;Y2 = Y1

  invoke  zero, ecx
  inc dword ptr [ecx]     ;Z2 = 1
  jmp  exit_a2jx
  
exit_a2j:
  invoke  zero, ecx
exit_a2jx:  
  popad
  retn 8

ECP_A2J   endp

    end
    