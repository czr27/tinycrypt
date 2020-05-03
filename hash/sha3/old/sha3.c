/**
  Copyright © 2015, 2016 Odzhan. All Rights Reserved.

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

#include "sha3.h"

// round constant function
// Primitive polynomial over GF(2): x^8+x^6+x^5+x^4+1
uint64_t rc (uint8_t *LFSR)
{
  uint64_t c;
  uint32_t i, t;

  c = 0;
  t = *LFSR;
  
  for (i=1; i<128; i += i) 
  {
    if (t & 1) {
      c ^= (uint64_t)1ULL << (i - 1);
    }
    t = (t & 0x80) ? (t << 1) ^ 0x71 : t << 1;
  }
  *LFSR = (uint8_t)t;
  return c;
}

void SHA3_Transform (SHA3_CTX *c)
{
  uint64_t i, j, rnd, r;
  uint64_t t, bc[5];
  uint8_t  lfsr=1;
  uint64_t *s = (uint64_t*)&c->s.q[0];
  
const uint8_t keccakf_piln[24] = 
{ 10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4, 
  15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1  };
  
  for (rnd=0; rnd<24; rnd++) 
  {
    // Theta
    for (i=0; i<5; i++) {     
      bc[i] = s[i] 
            ^ s[i +  5] 
            ^ s[i + 10] 
            ^ s[i + 15] 
            ^ s[i + 20];
    }
    for (i=0; i<5; i++) {
      t = bc[(i + 4) % 5] ^ ROTR64(bc[(i + 1) % 5], 63);
      for (j=0; j<25; j+=5) {
        s[j + i] ^= t;
      }
    }

    // Rho Pi
    t = s[1];
    for (i=0, r=0; i<24; i++) {
      r += i + 1;
      j = keccakf_piln[i];
      bc[0] = s[j];
      s[j] = ROTR64(t, (64 - r) & 63);
      t = bc[0];
    }

    // Chi
    for (j=0; j<25; j+=5) {
      for (i=0; i<5; i++) {
        bc[i] = s[j + i];
      }
      for (i=0; i<5; i++) {
        s[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
      }
    }
    // Iota
    s[0] ^= rc(&lfsr);
  }
}

// mdlen isn't checked, it presumes caller provides 28,32,48 or 64
void SHA3_Init (SHA3_CTX *c, int mdlen)
{
  memset(c, 0, sizeof(SHA3_CTX));
  
  c->olen = mdlen;                // output length
  c->blen = (25*8) - (2 * mdlen); // bit rate
  c->idx  = 0;
}

void SHA3_Update (SHA3_CTX* c, void *in, uint32_t inlen)
{
  uint32_t i;
  uint8_t  *p=(uint8_t*)in;
  
  // update buffer and state
  for (i=0; i<inlen; i++) {
    // absorb byte into state
    c->s.b[c->idx++] ^= *p++;    
    if (c->idx == c->blen) {
      SHA3_Transform (c);
      c->idx = 0;
    }
  }
}

void SHA3_Final (void* out, SHA3_CTX* c)
{
  // absorb 3 bits, Keccak uses 1
  c->s.b[c->idx] ^= 6;
  // absorb end bit
  c->s.b[c->blen-1] ^= 0x80;
  // update context
  SHA3_Transform (c);
  // copy digest to buffer
  memcpy(out, c->s.b, c->olen);
}
