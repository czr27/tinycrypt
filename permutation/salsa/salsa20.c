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

#include "salsa20.h"

void salsa20_core(void *input, void *output) {
    W a,b,c,d,i,r,t,*s=(W*)input, *x=(W*)output;
    W v[8]={0xC840, 0x1D95, 0x62EA, 0xB73F,     // column index
            0x3210, 0x4765, 0x98BA, 0xEDCF };   // diagonal index
            
    // load state into local buffer
    F(16)x[i]=s[i];
    
    // for 80 rounds
    F(80) {
      d=v[i%8];
      a=(d&15);b=(d>>4&15);
      c=(d>>8&15);d>>=12;
      
      x[b]^=R((x[a]+x[d]), 7);
      x[c]^=R((x[b]+x[a]), 9);
      x[d]^=R((x[c]+x[b]),13);
      x[a]^=R((x[d]+x[c]),18);
    }
    // add state to local buffer
    F(16)x[i]+=s[i];
}

void salsa20_setkey(salsa_ctx *c, void *key, void *nonce) {
    W   *k=(W*)key, *n=(W*)nonce;
    int i;
    // 32-bit integers are: "expand 32-byte k"
    c->w[ 0] = 0x61707865;
    // copy 1st half of 256-bit key 
    F(4) c->w[i+1] = k[i];
    c->w[ 5] = 0x3320646E;
    // copy 64-bit nonce
    c->w[ 6] = n[0];
    c->w[ 7] = n[1];
    // set 64-bit counter
    c->w[ 8] = 0;
    c->w[ 9] = 0;
    c->w[10] = 0x79622D32;
    // copy 2nd half of 256-bit key
    F(4) c->w[i+11] = k[i+4];
    c->w[15] = 0x6B206574;
}

void salsa20_encrypt(salsa_ctx *ctx, void *in, W len) {
    B c[64],*p=in;
    W i,r;

    // if we have data to encrypt/decrypt
    if(len) {
      while(len) {
        // permute state
        salsa20_core(ctx, c);
        // increase counter
        ctx->q[4]++;
        // encrypt/decrypt 64 bytes or whatever is remaining
        r = (len > 64) ? 64 : len;
        // xor buffer with stream
        F(r)p[i] ^= c[i];
        // decrease length, advance buffer
        len -= r;
        p   += r;
      }
    }
}

void salsa20_keystream(salsa_ctx *ctx, void *out, W len) {
    B s[64], i;
    
    // zero initialize buffer
    for(i=0;i<64;i++) s[i]=0;
    // encrypt it
    salsa20_encrypt(ctx, s, 64);
    // return len-bytes
    for(i=0;i<len;i++) ((B*)out)[i] = s[i];
}
