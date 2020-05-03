/**
  Copyright © 2015 Odzhan. All Rights Reserved.

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
  
#include "cc20.h"
  
// generate stream of bytes
void xchacha_permute (w512_t *state, w512_t *out)
{
    int      i, j, k, idx;
    uint32_t *x;
    uint32_t a, b, c, d, r, t;
    
    // 16-bit integers of each index
    uint16_t idx16[8]=
    { 0xC840, 0xD951, 0xEA62, 0xFB73, 
      0xFA50, 0xCB61, 0xD872, 0xE943 };
    
    // copy state to out
    memcpy (out->b, state->b, 64);

    x = out->w;
    
    // apply 20 rounds
    for (i=0; i<20; i+=2) {
      for (j=0; j<8; j++) {
        idx = idx16[j];
        
        a = ((idx      ) & 0xF);
        b = ((idx >>  4) & 0xF);
        c = ((idx >>  8) & 0xF);
        d = ((idx >> 12) & 0xF);
        
        r = 0x07080C10;
        
        do {
          x[a]+= x[b]; 
          x[d] = ROTL32(x[d] ^ x[a], (r & 0xFF));
          XCHG(a, c);
          XCHG(b, d);
          r >>= 8;            
        } while (r != 0);
      }
    }
    // add state to out
    for (i=0; i<16; i++) {
      out->w[i] += state->w[i];
    }
    // update counter
    state->w[12]++;
    // stopping at 2^70 bytes per nonce is user's responsibility
}

// encrypt or decrypt stream of bytes
void xchacha20 (uint32_t len, void *in, w512_t *s) 
{
    uint8_t *p=(uint8_t*)in;
    int     r, i;
    w512_t  c;
    
    // if we have data
    if (len != 0) {
      while (len) {   
        // permutate stream      
        xchacha_permute(s, &c);
        
        // xor full block or whatever remains
        r=(len>64) ? 64 : len;
        
        // xor input with stream
        for (i=0; i<r; i++) {
          p[i] ^= c.b[i];
        }      
        len -= r;
        p += r;
      }
    } else {  
      // initialize state with key, nonce, counter
      // store "expand 32-byte k"
      s->w[0] = 0x61707865; s->w[1] = 0x3320646E;
      s->w[2] = 0x79622D32; s->w[3] = 0x6B206574;
      
      // store 256-bit key
      memcpy (&s->b[16], p, 32);      
      
      // initialize 32-bit counter
      s->w[12] = 1;
      
      // store 64-bit nonce
      memcpy (&s->w[13], &p[32], 12);   
    }
}

