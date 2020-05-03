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

#include "xoodoo.h"

void xoodoo(void *state) {
    uint32_t e[4], x0, x1, x2, t;
    int      r, i;
    uint32_t *x=(uint32_t*)state;

    uint32_t rc[12]=
    { 0x058, 0x038, 0x3c0, 0x0d0,
      0x120, 0x014, 0x060, 0x02c,
      0x380, 0x0f0, 0x1a0, 0x012 };

    // 12 rounds by default
    for (r=0; r<12; r++) {
      // Theta
      for (i=0; i<4; i++) {
        e[i] = ROTR32(x[i] ^ x[i+4] ^ x[i+8], 18);
        e[i]^= ROTR32(e[i], 9);
      }

      for (i=0; i<12; i++) {
        x[i]^= e[(i - 1) & 3];
      }

      // Rho west
      XCHG(x[7], x[4]);
      XCHG(x[7], x[5]);
      XCHG(x[7], x[6]);

      // Iota
      x[0] ^= rc[r];

      // Chi and Rho east
      for (i=0; i<4; i++) {
        x0 = x[i+0];
        x1 = x[i+4];
        x2 = ROTR32(x[i+8], 21);

        x[i+8] = ROTR32((x1 & ~x0) ^ x2, 24);
        x[i+4] = ROTR32((x0 & ~x2) ^ x1, 31);
        x[i+0]^= x2 & ~x1;
      }
      XCHG(x[8], x[10]);
      XCHG(x[9], x[11]);
    }
}
