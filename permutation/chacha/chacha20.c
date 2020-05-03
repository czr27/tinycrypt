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

#include "chacha20.h"

void chacha20_core(void *input, void *output) {
    W a,b,c,d,i,t,r,*s=input,*x=output;
    W v[8]={0xC840,0xD951,0xEA62,0xFB73,
            0xFA50,0xCB61,0xD872,0xE943};
            
    // load state into local buffer
    F(16)x[i]=s[i];
    
    // for 80 rounds
    F(80) {
      d=v[i%8];
      a=(d&15);b=(d>>4&15);
      c=(d>>8&15);d>>=12;
      
      for(r=0x19181410;r;r>>=8)
        x[a]+=x[b],
        x[d]=R(x[d]^x[a],(r&255)),
        // swap
        X(a,c),X(b,d);
    }
    // add state to local buffer
    F(16)x[i]+=s[i];
}

void chacha20_setkey(chacha_ctx *c, void *key, void *nonce) {
    W   *k=(W*)key, *n=(W*)nonce;
    int i;
    // store "expand 32-byte k"
    c->w[0]=0x61707865; c->w[1]=0x3320646E;
    c->w[2]=0x79622D32; c->w[3]=0x6B206574;
    // copy 256-bit key
    F(8)c->w[i+4] = k[i];
  #ifdef GX
    // set 32-bit counter
    c->w[12] = 1;
    // copy 96-bit nonce
    F(3)c->w[i+13] = n[i];
  #else
    // set 64-bit counter
    c->w[12] = 0; c->w[13] = 0;
    // set 64-bit nonce
    F(2)c->w[i+14] = n[i];
  #endif
}

void chacha20_encrypt(chacha_ctx *ctx, void *in, W len) {
    B c[64],*p=in;
    W i,r;

    // if we have data to encrypt/decrypt
    if(len) {
      while(len) {
        // permute state
        chacha20_core(ctx, c);
        // increase counter
      #ifdef GX
        ctx->w[12]++;
      #else
        ctx->q[6]++;
      #endif
        // encrypt 64 bytes or whatever is remaining
        r = (len > 64) ? 64 : len;
        // xor plaintext with ciphertext
        F(r)p[i] ^= c[i];
        // decrease length, advance buffer
        len -= r;
        p   += r;
      }
    }
}

void chacha20_keystream(chacha_ctx *ctx, void *out, W len) {
    B s[64], i;
    
    // zero initialize buffer
    for(i=0;i<64;i++) s[i]=0;
    // encrypt it
    chacha20_encrypt(ctx, s, 64);
    // return len-bytes
    for(i=0;i<len;i++) ((B*)out)[i] = s[i];
}
