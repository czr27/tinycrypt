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
      //x0 = ((0x9e3779b9 * i) & 0xFFFFFFFF) + 0x19a9d7aa;
      S[--i] = x0;      
    }

    x0 = x1 = 0;
    r = (RC6_KR*3);
    
    // create sub keys
    for (i=0, j=0; r>0; i++, j++, r--) {
      // i needs reset?
      if (i==RC6_KR) i = 0;
      j &= 7;
      
      x0 = S[i] = ROTR32(S[i] + x0+x1, 29);  
      x1 = L[j] = ROTR32(L[j] + x0+x1, 32-(x0+x1));
    }

    // assign sub keys to k 
    kp = S;
    
    // load 128-bit plain text
    x0 = x[0]; x1 = x[1] + *kp++;
    x2 = x[2]; x3 = x[3] + *kp++;
    
    // apply encryption
    for (i=RC6_ROUNDS; i>0; i--) {
      t0 = ROTR32(x1 * (x1 + x1 + 1), 27);
      t1 = ROTR32(x3 * (x3 + x3 + 1), 27);
      
      t2 = x3; // backup x3
      
      x0 ^= t0;
      x2 ^= t1;
      x3 = ROTR32(x0, 32-t1);
      t1 = *kp++;
      x3 += t1;
      
      x0 = x1; // move x1 into x0
      x1 = ROTR32(x2, 32-t0); 
      t0 = *kp++;
      x1 += t0;
      
      x2 = t2;  // move x3 into x2
    }
    // save 128-bit cipher text
    x[0] = x0 + kp[0]; x[1] = x1;
    x[2] = x2 + kp[1]; x[3] = x3;
}
      