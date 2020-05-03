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
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

#include "rc5.h"

void rc5_encryptx(void *key, void *data)
{
    uint32_t A, B, T;
    uint32_t L[4], S[RC5_KR];
    int      i, j, r;

    uint32_t *kp=(uint32_t*)key;
    uint32_t *x=(uint32_t*)data;

    // initialize L with 128-bit key
    memcpy(&L, key, 16);

    A = 0xC983AE2D;

    // initialize S with constants
    for (i=RC5_KR; i>0;) {
      A -= RC5_Q;
      S[--i] = A;
    }

    A = B = 0;
    r = (RC5_KR*3);

    // create sub keys
    for (i=0, j=0; r>0; i++, j++, r--) {
      // i needs reset?
      if (i==RC5_KR) i=0;
      j &= 3;

      A = S[i] = ROTL32(S[i] + A+B, 3);
      B = L[j] = ROTL32(L[j] + A+B, A+B);
    }

    // assign sub keys to k ptr
    kp = S;

    // load 64-bit plain text
    A = x[0] + *kp++;
    B = x[1] + *kp++;

    // apply encryption
    for (i=RC5_ROUNDS*2; i>0; i--) {
      T = B;
      B = ROTL32(A ^ B, B) + *kp++;
      A = T;
    }
    // save 64-bit ciphertext
    x[0] = A; x[1] = B;
}

