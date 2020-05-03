/**
  Copyright (C) 2018 Odzhan. All Rights Reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  3. The name of the author may not be used to endorse or promote products
  derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

  .arm
  .arch armv6  
  .text
  .align  2
  
  .global rc5_encryptx
  
k  .req r0
x  .req r1

x0 .req r2
x1 .req r3  
  
t0 .req r4
t1 .req r5
t2 .req r6

i  .req r7
j  .req r8
r  .req r9

L  .req r10
S  .req r11
kp .req r11

rc5_encryptx:
  // save registers
  push   {r0-r12, lr}
  
  // allocate memory
  sub    sp, #128
  
  // initialize L with 128-bit key
  // memcpy(&L, key, 16);
  mov    L, sp
  ldm    k, {r2-r5}
  stm    L, {r2-r5}
  
  // initialize S with constants
  ldr    x0, =#0xC983AE2D     // x0 = RC5_P precomputed
  ldr    x1, =#0x9E3779B9     // x1 = RC5_Q
  add    S, sp, #16
  mov    i, #26               // i = RC5_KR, RC5_KR=2*(ROUNDS+1)
init_sub:
  sub    x0, x0, x1           // x0 -= RC5_Q
  subs   i, i, #1             // i--  
  str    x0, [S, i, lsl #2]   // S[i] = x0;  
  bne    init_sub             // i>=0
  
  umull  x0, x1, i, i         // x0 = 0, x1 = 0 
  mov    r, #78               // r = (RC5_KR*3)
  
  // ***********************************************
  // create the round keys
  // ***********************************************    
  mov    j, i                 // j = 0   
rc5_sub:
  cmp    i, #26               // if (i == RC5_KR) i = 0
  moveq  i, #0                // zero if equal
  and    j, #3                // j &= 3

  // x0 = S[i] = ROTL32(S[i] + x0+x1, 3);
  add    x0, x1               // x0 = x0 + x1;
  ldr    t2, [S, i, lsl #2]
  add    x0, t2               // x0 += t2
  ror    x0, #29 
  str    x0, [S, i, lsl #2]   // S[i] = x0
    
  // x1 = L[j] = ROTL32(L[j] + x0+x1, x0+x1);
  add    x1, x0, x1           // x1 = x0 + x1
  rsb    t0, x1, #32          // t0 = 32 - x1  
  ldr    t2, [L, j, lsl #2]
  add    x1, t2               // x1 += t2
  ror    x1, t0               //
  str    x1, [L, j, lsl #2]   // L[j] = x1  
  add    i, #1                // i++   
  add    j, #1                // j++ 
  subs   r, #1                // r--
  bne    rc5_sub
  
  // ***********************************************
  // perform encryption
  // ***********************************************    
  // load plaintext
  ldm    x, {x0, x1}          // x0 = x[0]; x1 = x[1]; 
  
  ldr    t0, [kp], #4
  add    x0, t0               // x0 += *kp++;
  
  ldr    t0, [kp], #4
  add    x1, t0               // x1 += *kp++;
  
  // apply encryption
  mov    i, #24               // i = RC5_KR - 2 
rc5_enc:
  ldr    t0, [kp], #4         // t0 = *kp++;
  eor    x0, x1
  rsb    t1, x1, #32          // t1 = 32 - x1
  mov    t2, x1               // backup x1
  add    x1, t0, x0, ror t1 
  mov    x0, t2
  subs   i, #1                // i--
  bne    rc5_enc              // i>0
  
  // save ciphertext
  stm    x, {x0, x1}          // x[0] = x0; x[1] = x1;
  
  // release memory
  add    sp, #128
  
  // restore registers
  pop    {r0-r12, pc}
  