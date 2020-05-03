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
  
  .global xtea_encryptx

// key
k   .req r0
x   .req r1

// data
x0  .req r2
x1  .req r3

sum .req r4
t0  .req r5
t1  .req r6
c   .req r7
i   .req r8

  // xtea_encryptx(void *key, void *data);
xtea_encryptx:
  // save registers
  push  {r0-r12, lr}

  // 32 rounds by default
  mov   i, #64               // number of rounds

  // load 64-bit plain text
  ldm   x, {x0, x1}          // x0  = x[0], x1 = x[1];
  mov   sum, #0              // sum = 0;
  ldr   c, =#0x9E3779B9      // c   = 0x9E3779B9;
xtea_loop:
  mov   t0, sum              // t0 = sum;
  tst   i, #1                // if (i & 1)

  // the next 2 only execute if (i % 2) is not zero
  addne sum, c               // sum += 0x9E3779B9;
  lsrne t0, sum, #11         // t0 = sum >> 11

  and   t0, #3               // t0 %= 4
  ldr   t0, [k, t0, lsl #2]  // t0 = k[t0];
  add   t1, sum, t0          // t1 = sum + t0
  mov   t0, x1, lsl #4       // t0 = (x1 << 4)
  eor   t0, x1, lsr #5       // t0^= (x1 >> 5)
  add   t0, x1               // t0+= x1
  eor   t0, t1               // t0^= t1
  mov   t1, x1               // backup x1
  add   x1, t0, x0           // x1 = t0 + x0

  // XCHG(x0, x1)
  mov   x0, t1               // x0 = x1
  subs  i, i, #1             // i--
  bne   xtea_loop            // i>0

  // save 64-bit cipher text
  stm   x, {x0, x1}

  // restore registers
  pop   {r0-r12, pc}
