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

#include "gimli.h"

void gimlix(void *state)
{
    int      r, j;
    uint32_t t, x, y, z;
    uint32_t *s=(uint32_t*)state;

    for (r=24; r>0; --r) {
      // apply SP-box
      for (j=0; j<4; j++) {
        x = ROTR32(s[    j],  8);
        y = ROTR32(s[4 + j], 23);
        z =        s[8 + j];

        s[8 + j] = x ^ (z << 1) ^ ((y & z) << 2);
        s[4 + j] = y ^ x        ^ ((x | z) << 1);
        s[j]     = z ^ y        ^ ((x & y) << 3);
      }

      // apply Linear layer
      t = r & 3;

      // if zero, do small swap
      if (t == 0) {
        XCHG(s[0], s[1]);
        XCHG(s[2], s[3]);

        // add constant
        s[0] ^= (0x9e377900 | r);
      }
      // if 2, do big swap
      if (t == 2) {
        XCHG(s[0], s[2]);
        XCHG(s[1], s[3]);
      }
    }
}
