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

#include "lea.h"

void lea128_encryptx(void *key, void *data) {
    uint32_t k0, k1, k2, k3;
    uint32_t x0, x1, x2, x3;
    uint32_t c0, c1, c2, c3;
    
    uint32_t *x, *k, r, t0;

    x = (uint32_t*)data;
    k = (uint32_t*)key;

    // initialize 32-bit constants
    c0 = 0xc3efe9db; c1 = 0x88c4d604;
    c2 = 0xe789f229; c3 = 0xc6f98763;

    // load 128-bit key
    k0 = k[0]; k1 = k[1];
    k2 = k[2]; k3 = k[3];

    // load 128-bit plain text
    x0 = x[0]; x1 = x[1];
    x2 = x[2]; x3 = x[3];

    // perform encryption
    for (r=24; r>0; r--) {
      // create subkey
      k0 = ROTR32(k0 + c0, 31);
      k1 = ROTR32(k1 + ROTR32(c0, 31), 29);
      k2 = ROTR32(k2 + ROTR32(c0, 30), 26);
      k3 = ROTR32(k3 + ROTR32(c0, 29), 21);
      
      // encrypt block
      t0 = x0;
      x0 = ROTR32((x0 ^ k0) + (x1 ^ k1),23);
      x1 = ROTR32((x1 ^ k2) + (x2 ^ k1), 5);
      x2 = ROTR32((x2 ^ k3) + (x3 ^ k1), 3);
      x3 = t0;
      
      // update constants
      t0 = c0; c0 = c1; c1 = c2; c2 = c3;
      c3 = ROTR32(t0, 28);
    }
    // save 128-bit cipher text
    x[0] = x0; x[1] = x1;
    x[2] = x2; x[3] = x3;
}
