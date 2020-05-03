/**
  Copyright © 2017 Odzhan. All Rights Reserved.

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

#include "noekeon.h"

void Noekeonx(void *key, void *data) {
    int      i, j;
    uint32_t t;
    w256_t   rc;
    uint32_t *x, *k;

    x = (uint32_t*)data;
    k = (uint32_t*)key;

    // constants
    rc.w[ 0] = 0x6c361b80; rc.w[1] = 0x9a4dabd8;
    rc.w[ 2] = 0x63bc5e2f; rc.w[3] = 0x6a3597c6;
    rc.b[16] = 0xd4;

    for (i=0;;i++) {
      x[0] ^= rc.b[i];
      // Theta
      t = x[0] ^ x[2];
      t ^= ROTR32(t, 8) ^ ROTR32(t, 24);

      x[1] ^= t; x[3] ^= t;

      // mix key
      x[0]^= k[0]; x[1]^= k[1];
      x[2]^= k[2]; x[3]^= k[3];

      t = x[1] ^ x[3];
      t ^= ROTR32(t, 8) ^ ROTR32(t, 24);

      x[0]^= t; x[2] ^= t;

      if (i==Nr) break;

      // Pi1
      x[1] = ROTR32(x[1], 31);
      x[2] = ROTR32(x[2], 27);
      x[3] = ROTR32(x[3], 30);

      // Gamma
      x[1]^= ~((x[3]) | (x[2]));
      x[0]^= x[2] & x[1];

      XCHG(x[0], x[3]);

      x[2]^= x[0] ^ x[1] ^ x[3];
      x[1]^= ~((x[3]) | (x[2]));
      x[0]^= x[2] & x[1];

      // Pi2
      x[1] = ROTR32(x[1], 1);
      x[2] = ROTR32(x[2], 5);
      x[3] = ROTR32(x[3], 2);
    }
}
