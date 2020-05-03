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

#include "sparx.h"

void AX(void *w) {
    w32_t *x=(w32_t*)w;
    
    x->w[0]  = ROTL16(x->w[0], 9);
    x->w[0] += x->w[1];
    
    x->w[1]  = ROTL16(x->w[1], 2);
    x->w[1] ^= x->w[0];  
}

void sparx_setkey(void *out, void *in)
{
    uint32_t c, i;
    uint8_t  *subkeys=(uint8_t*)out;
    w32_t    *key=(w32_t*)in;
    uint32_t t[3];
    
    for (c=0; c<41; c++) {
      memcpy (subkeys, &key->w[0], 16);
      
      subkeys += 16;

      AX(&key->x[0]);

      key->w[2] += key->w[0];
      key->w[3] += key->w[1];

      AX(&key->x[4]);

      key->w[10] += key->w[8];
      key->w[11] += key->w[9] + c + 1;

      for (i=0; i<3; i++) {
        t[i] = key->x[5+i];
      }

      for (i=15; i>5; i--) {
        key->w[i] = key->w[i-6];
      }

      for (i=0; i<3; i++) {
        key->x[i] = t[i];  
      }
    }
}

void sparx_encrypt(void *buf, void *key)
{
    uint32_t i, j, r, t;
    w32_t    *x, *k;
    
    x=(w32_t*)buf;
    k=(w32_t*)key;
    
    for (i=0; i<10; i++) {
      for (j=0; j<4; j++) {
        for (r=0; r<4; r++) {
          x->x[j] ^= k->x[0]; k++;
          
          AX(&x->x[j]);     
        }
      }
      t = x->w[0] ^ 
          x->w[1] ^ 
          x->w[2] ^ 
          x->w[3];
          
      t = ROTL16(t, 8);

      x->w[4] ^= x->w[2] ^ t;
      x->w[5] ^= x->w[1] ^ t;
      x->w[6] ^= x->w[0] ^ t;
      x->w[7] ^= x->w[3] ^ t;

      XCHG(x->x[0], x->x[2]);
      XCHG(x->x[1], x->x[3]);
    }

    for (i=0; i<4; i++) {    
      x->x[0] ^= k->x[0]; 
      x++; k++;
    }
}

