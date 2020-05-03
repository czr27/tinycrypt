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

#include "sha256.h"

#define CH(x,y,z)(((x)&(y))^(~(x)&(z)))
#define MAJ(x,y,z)(((x)&(y))^((x)&(z))^((y)&(z)))

#define EP0(x)(R(x,2)^R(x,13)^R(x,22))
#define EP1(x)(R(x,6)^R(x,11)^R(x,25))
#define SIG0(x)(R(x,7)^R(x,18)^((x)>>3))
#define SIG1(x)(R(x,17)^R(x,19)^((x)>>10))

void sha256_compress(sha256_ctx *c) {
    W t1,t2,i,w[64],x[8];
    
    W k[64]=
    { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 
      0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 
      0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 
      0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 
      0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 
      0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 
      0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 
      0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 
      0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 }; 
    
    // load input in big endian byte order
    F(16)w[i] = rev32(c->x.w[i]);
    
    // expand input
    for(i=16;i<64;i++)
      w[i] = SIG1(w[i-2])+w[i-7]+SIG0(w[i-15])+w[i-16];
    
    // load state
    F(8)x[i] = c->s[i];
    
    // permute
    F(64) {
      t1 = x[7] + EP1(x[4]) + CH(x[4],x[5],x[6]) + w[i] + k[i];
      t2 = EP0(x[0]) + MAJ(x[0],x[1],x[2]);
      x[7] = x[6],x[6] = x[5],x[5] = x[4],x[4] = x[3] + t1;
      x[3] = x[2],x[2] = x[1],x[1] = x[0], x[0] = t1 + t2;
    }
    // update state
    F(8)c->s[i] += x[i];
}

void sha256_init(sha256_ctx *c) {    
    c->s[0]=0x6a09e667;
    c->s[1]=0xbb67ae85;
    c->s[2]=0x3c6ef372;
    c->s[3]=0xa54ff53a;
    c->s[4]=0x510e527f;
    c->s[5]=0x9b05688c;
    c->s[6]=0x1f83d9ab;
    c->s[7]=0x5be0cd19;
    c->len =0;
}

void sha256_update(sha256_ctx *c,const void *in,W len) {
    B *p=(B*)in;
    W i, idx;
    
    // index = len % 64
    idx = c->len & 63;
    // update total length
    c->len += len;
    
    for (i=0;i<len;i++) {
      // add byte to buffer
      c->x.b[idx]=p[i]; idx++;
      // buffer filled?
      if(idx==64) {
        // compress it
        sha256_compress(c);
        idx=0;
      }
    }
}

void sha256_final(void *out,sha256_ctx *c) {
    W i,len,*p=(W*)out;
    
    // get index
    i = len = c->len & 63;
    // zero remainder of buffer
    while(i < 64) c->x.b[i++]=0;
    // add 1 bit
    c->x.b[len]=0x80;
    
    // exceeds or equals area for total bits?
    if(len >= 56) {
      // compress it
      sha256_compress(c);
      // zero buffer
      F(16)c->x.w[i]=0;
    }
    // add total length in bits
    c->x.q[7]=rev64(c->len*8);
    // compress it
    sha256_compress(c);
    // return hash
    F(8)p[i]=rev32(c->s[i]);
}
