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
  
#include "blabla.h"

#define R(v,n)(((v)>>(n))|((v)<<(64-(n))))
#define F(n)for(i=0;i<n;i++)
#define X(a,b)(t)=(a),(a)=(b),(b)=(t)
typedef unsigned char B;
typedef unsigned long long W;

// setup the key/internal state
void blabla_setkey(blabla_ctx *c, const void *key, const void *nonce) {
    int i;
    
    c->q[ 0] = 0x6170786593810fab;
    c->q[ 1] = 0x3320646ec7398aee;
    c->q[ 2] = 0x79622d3217318274;
    c->q[ 3] = 0x6b206574babadada;

    // copy 256-bit key
    F(4) c->q[i+4] = ((W*)key)[i];
    
    c->q[ 8] = 0x2ae36e593e46ad5f;
    c->q[ 9] = 0xb68f143029225fc9;
    c->q[10] = 0x8da1e08468303aa6;
    c->q[11] = 0xa48a209acd50a4a7;
    c->q[12] = 0x7fdc12f23f90778c;
    
    // set 64-bit counter
    c->q[13] = 1; 
    
    // copy 128-bit nonce
    F(2)c->q[i+14]=((W*)nonce)[i];
}

void blabla_stream(blabla_ctx *s, void *out) {
    W a,b,c,d,i,t,r,*x=(W*)out;
    uint16_t v[8]={0xC840,0xD951,0xEA62,0xFB73,
                   0xFA50,0xCB61,0xD872,0xE943};
            
    // store internal state in buffer
    F(16)x[i] = s->q[i];
    
    // permute buffer
    F(80) {
      d=v[i%8];
      a=(d&15);b=(d>>4&15);
      c=(d>>8&15);d>>=12;
      
      for(r=0x3F101820;r;r>>=8)
        x[a]+=x[b],
        x[d]=R(x[d]^x[a],(r&255)),
        X(a,c),X(b,d);
    }
    // add internal state to buffer
    F(16)x[i] += s->q[i];
    // increase counter of internal state
    s->q[13]++;
}

// encrypt or decrypt stream of len-bytes
void blabla_encrypt(blabla_ctx *ctx, void *buf, size_t len) {
    W i, r;
    B c[128], *p=(B*)buf;
    
    while(len) {
      // generate 128-bytes of ciphertext
      blabla_stream(ctx, c);
      r = len>128?128:len;
      // xor plaintext with ciphertext
      F(r) p[i] ^= c[i];
      // decrease total length, advance buffer
      len -= r; p+= r;
    }
}

// generate key stream of len-bytes
void blabla_keystream(blabla_ctx *c, void *buf, size_t len) {
    W i;
    
    F(len)((B*)buf)[i]=0;           // zero initialize buffer
    blabla_encrypt(c, buf, len);    // encrypt it
}
