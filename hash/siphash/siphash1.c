/*
   SipHash reference C implementation

   Copyright (c) 2012-2016 Jean-Philippe Aumasson
   <jeanphilippe.aumasson@gmail.com>
   Copyright (c) 2012-2014 Daniel J. Bernstein <djb@cr.yp.to>

   To the extent possible under law, the author(s) have dedicated all copyright
   and related and neighboring rights to this software to the public domain
   worldwide. This software is distributed without any warranty.

   You should have received a copy of the CC0 Public Domain Dedication along
   with
   this software. If not, see
   <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* default: SipHash-2-4 */
#define cROUNDS 2
#define dROUNDS 4

#define ROTL(x, b) (uint64_t)(((x) << (b)) | ((x) >> (64 - (b))))
void sipround1(uint64_t v[], uint64_t w, uint8_t last);

uint64_t xsiphash(const size_t inlen, const uint8_t *in, const uint8_t *key) {

    uint64_t v[4];
    uint64_t *k=(uint64_t*)key;
    uint64_t m;

    int i;
    const uint8_t *end = in + inlen - (inlen % sizeof(uint64_t));
    int left = inlen & 7;
    uint64_t b = ((uint64_t)inlen) << 56;
    
    v[0] = k[0] ^ 0x736f6d6570736575ULL;
    v[1] = k[1] ^ 0x646f72616e646f6dULL;
    v[2] = k[0] ^ 0x6c7967656e657261ULL;
    v[3] = k[1] ^ 0x7465646279746573ULL;
    
    for (; in!=end; in+=8) {
      m = ((uint64_t*)in)[0];
      sipround1(v, m, 0);
    }

    while (--left >= 0) {
      b |= ((uint64_t)in[left]) << (8 * left);   
    }

    for (i=0; i<2; i++) {
      sipround1(v, b, i);
      b = 0;
    }
    return v[0] ^ v[1] ^ v[2] ^ v[3];
}

void sipround1(uint64_t v[], uint64_t w, uint8_t last)
{
  int i, rnds=cROUNDS;
  
  v[2] ^= (uint8_t)-last;
  rnds += (last * 2);
  
  v[3] ^= w;
  
  for (i=0; i<rnds; i++)
  {  
    v[0]+= v[1];                                                              
    v[1] = ROTL(v[1], 13);                                                     
    v[1]^= v[0];                                                              
    v[0] = ROTL(v[0], 32);                                                     
    v[2]+= v[3];                                                              
    v[3] = ROTL(v[3], 16);                                                     
    v[3]^= v[2];                                                              
    v[0]+= v[3];                                                              
    v[3] = ROTL(v[3], 21);                                                     
    v[3]^= v[0];                                                              
    v[2]+= v[1];                                                              
    v[1] = ROTL(v[1], 17);                                                     
    v[1]^= v[2];                                                              
    v[2] = ROTL(v[2], 32); 
  }
  v[0] ^= w;  
}  
