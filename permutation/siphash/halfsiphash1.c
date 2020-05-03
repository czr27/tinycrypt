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

#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* default: SipHash-2-4 */
#define cROUNDS 2
#define dROUNDS 4

#define ROTL(x, b) (uint32_t)(((x) << (b)) | ((x) >> (32 - (b))))

void SIPROUND(
    uint32_t v[4], 
    uint32_t w, 
    uint8_t last)
{
  int i, rnds=cROUNDS;
  
  v[2] ^= (uint8_t)-last;
  rnds += (last * 2);
  
  v[3] ^= w;
  
  for (i=0; i<rnds; i++)
  {
    v[0] += v[1];                                                              
    v[1] = ROTL(v[1], 5);                                                      
    v[1] ^= v[0];                                                              
    v[0] = ROTL(v[0], 16);                                                     
    v[2] += v[3];                                                              
    v[3] = ROTL(v[3], 8);                                                      
    v[3] ^= v[2];                                                              
    v[0] += v[3];                                                              
    v[3] = ROTL(v[3], 7);                                                      
    v[3] ^= v[0];                                                              
    v[2] += v[1];                                                              
    v[1] = ROTL(v[1], 13);                                                     
    v[1] ^= v[2];                                                              
    v[2] = ROTL(v[2], 16);   
  }    
  v[0] ^= w;
}

uint32_t hsh32(
    const uint8_t *data, 
    const size_t inlen, 
    const uint8_t *key) 
{
    uint32_t v[4];
    uint8_t i;
    uint32_t m;
    
    uint8_t *in = (uint8_t*)data;
    uint32_t *k = (uint32_t*)key;
    
    uint32_t k0 = k[0];
    uint32_t k1 = k[1];
    
    int left = inlen & 3;        
    const uint8_t *end = in + inlen - left;
    uint32_t b = ((uint32_t)inlen) << 24;
    
    v[0] = k0;
    v[1] = k1;
    v[2] = k0 ^ 0x6c796765;
    v[3] = k1 ^ 0x74656462;

    for (; in != end; in += 4) {
      m = ((uint32_t*)in)[0];
      SIPROUND(v, m, 0);
    }

    while (--left >= 0) {
      b |= ((uint32_t)in[left]) << (8 * left);   
    }

    for (i=0; i<2; i++) {
      SIPROUND(v, b, i);
      b = 0;
    }
    
    return v[1] ^ v[3];
}
