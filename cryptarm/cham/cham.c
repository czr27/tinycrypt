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

#include "cham.h"

void cham(void *key, void *data)
{
    int      i;
    uint32_t x0, x1, x2, x3, k0, k1, k2, t0;
    uint32_t rk[2*KW];
    uint32_t *x, *k;

    k = (uint32_t*)key;
    x = (uint32_t*)data;

    // derive round keys from 128-bit key
    for (i=0; i<KW; i++) {
      k0    = k[i];
      k1    = ROTR32(k0, 31);
      k2    = ROTR32(k0, 24);
      k0   ^= k1;
      rk[i] = k0 ^ k2;
      k2    = ROTR32(k2, 29);
      k0   ^= k2;
      rk[(i+KW)^1] = k0;
    }

    // load 128-bit plain text
    x0 = x[0]; x1 = x[1];
    x2 = x[2]; x3 = x[3];

    // perform encryption
    for (i=0; i<R; i++)
    {
      k0 = x3;   // backup x3
      x0^= i;    // xor by round number

      // execution depends on (i % 2)
      x3 = rk[i & 7];
      x3^= (i & 1) ? ROTR32(x1, 24) : ROTR32(x1, 31);

      x3+= x0;
      x3 = (i & 1) ? ROTR32(x3, 31) : ROTR32(x3, 24);

      // swap
      x0 = x1; x1 = x2; x2 = k0;
    }
    x[0] = x0; x[1] = x1;
    x[2] = x2; x[3] = x3;
}
