/**
  Copyright © 2015, 2018 Odzhan. All Rights Reserved.

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
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR x0 PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

#include "rc6.h"

/*
    0xb7e15163, 0x19a9d7aa, 0x7b725df1, 0xdd3ae438, 0x3f036a7f, 0xa0cbf0c6, 0x294770d, 0x645cfd54,
    0xc625839b, 0x27ee09e2, 0x89b69029, 0xeb7f1670, 0x4d479cb7, 0xaf1022fe, 0x10d8a945, 0x72a12f8c,
    0xd469b5d3, 0x36323c1a, 0x97fac261, 0xf9c348a8, 0x5b8bceef, 0xbd545536, 0x1f1cdb7d, 0x80e561c4,
    0xe2ade80b, 0x44766e52, 0xa63ef499, 0x8077ae0, 0x69d00127, 0xcb98876e, 0x2d610db5, 0x8f2993fc,
    0xf0f21a43, 0x52baa08a, 0xb48326d1, 0x164bad18, 0x7814335f, 0xd9dcb9a6, 0x3ba53fed, 0x9d6dc634,
    0xff364c7b, 0x60fed2c2, 0xc2c75909, 0x248fdf50,
}
*/

void rc6_encryptx (void *key, void *data)
{
    uint32_t x0, x1, x2, x3, t0, t1, t2;
    uint32_t L[8], S[RC6_KR];
    uint32_t *x, *kp;
    int      i, j, r;

    x=(uint32_t*)data;

    // initialize L with 256-bit key
    memcpy(&L, key, 32);

    x0 = 0xE96A3D2F;

    // initialize S with constants
    for (i=RC6_KR; i>0;) {
      x0 -= RC6_Q;
      S[--i] = x0;
    }

    x0 = x1 = 0;
    r = (RC6_KR*3);

    // create sub keys
    for (i=0, j=0; r>0; i++, j++, r--) {
      // i needs reset?
      if (i==RC6_KR) i=0;
      j &= 7;

      x0 = S[i] = ROTL32(S[i] + x0+x1, 3);
      x1 = L[j] = ROTL32(L[j] + x0+x1, x0+x1);
    }

    // assign sub keys to k
    kp = S;

    // load plain text
    x0 = x[0]; x1 = x[1] + *kp++;
    x2 = x[2]; x3 = x[3] + *kp++;

    // apply encryption
    for (i=RC6_ROUNDS; i>0; i--) {
      t0 = ROTL32(x1 * (x1 + x1 + 1), 5);
      t1 = ROTL32(x3 * (x3 + x3 + 1), 5);

      t2 = x3; // backup x3

      x0 ^= t0;
      x2 ^= t1;
      x3 = ROTL32(x0, t1);
      t1 = *kp++;
      x3 += t1;

      x0 = x1; // move x1 into x0
      x1 = ROTL32(x2, t0);
      t0 = *kp++;
      x1 += t0;

      x2 = t2;  // move x3 into x2
    }
    // save cipher text
    x[0] = x0 + kp[0]; x[1] = x1;
    x[2] = x2 + kp[1]; x[3] = x3;
}
