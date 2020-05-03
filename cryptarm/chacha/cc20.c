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

// setup the key
void cc20_setkey(cc20_ctx *c, void *key, void *nonce)
{
    int i;
    
    // constants are "expand 32-byte k"
    c->w[0] = 0x61707865; c->w[1] = 0x3320646E;
    c->w[2] = 0x79622D32; c->w[3] = 0x6B206574;

    // copy 256-bit key
    memcpy(&c->b[16], key, 32);
  
    // set 32-bit block counter and 96-bit nonce/iv
    c->w[12] = 1;
    memcpy(&c->w[13], nonce, 12);
}

void F(uint32_t s[16])
{
    int      i;
    uint32_t a, b, c, d, r, t, idx;
    
    uint16_t idx16[8]=
    { 0xC840, 0xD951, 0xEA62, 0xFB73,    // column index
      0xFA50, 0xCB61, 0xD872, 0xE943 };  // diagonal index
    
    for (i=0; i<8; i++) {
      idx = idx16[i];
        
      a = (idx         & 0xF);
      b = ((idx >>  4) & 0xF);
      c = ((idx >>  8) & 0xF);
      d = ((idx >> 12) & 0xF);
  
      r = 0x07080C10;
      
      // The quarter-round
      do {
        s[a]+= s[b]; 
        s[d] = ROTL32(s[d] ^ s[a], r & 0xFF);
        XCHG(c, a);
        XCHG(d, b);
        r >>= 8;
      } while (r != 0);
    }    
}

// generate stream of bytes
void cc20_stream (cc20_ctx *c, w512_t *x)
{
    int i;

    // copy state to x
    memcpy(x->b, c->b, 64);
    // apply 20 rounds
    for (i=0; i<20; i+=2) {
      F(x->w);
    }
    // add state to x
    for (i=0; i<16; i++) {
      x->w[i] += c->w[i];
    }
    // update block counter
    c->w[12]++;
    // stopping at 2^70 bytes per nonce is user's responsibility
}

// encrypt or decrypt stream of bytes
void cc20_encrypt (uint32_t len, void *in, cc20_ctx *ctx) 
{
    uint32_t i, r;
    w512_t   s;
    uint8_t  *p=(uint8_t*)in;
    
    while (len) {      
      cc20_stream(ctx, &s);
      
      r=(len>64) ? 64 : len;
      
      // xor input with stream
      for (i=0; i<r; i++) {
        p[i] ^= s.b[i];
      }
    
      len -= r;
      p   += r;
    }
}

