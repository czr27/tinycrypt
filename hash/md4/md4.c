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

#include "md4.h"

#define FF(x,y,z)((z)^((x)&((y)^(z))))
#define GG(x,y,z)(((x)& (y))|((z)&((x)|(y))))
#define HH(x,y,z)((x)^(y)^(z))

void md4_compress(md4_ctx *c) {
    W i,t,s[4]; 
    B r[16]={3,7,11,19,3,5,9,13,3,9,11,15};
    B g[16]={0,4,8,12,1,5,9,13,2,6,10,14,3,7,11,15};
    B h[16]={0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15};

    // load state
    F(4)s[i]=c->s[i];
    
    // permute
    F(48) {
      if(i<16){
        s[0]+=FF(s[1],s[2],s[3])+c->x.w[i];
        t=r[i%4];
      } else if(i<32){
        s[0]+=GG(s[1],s[2],s[3])+c->x.w[g[i%16]]+0x5a827999L;
        t=r[4+i%4];
      } else {
        s[0]+=HH(s[1],s[2],s[3])+c->x.w[h[i%16]]+0x6ed9eba1L;
        t=r[8+i%4];
      }
      t=R(s[0],t);s[0]=s[3];s[3]=s[2];s[2]=s[1];s[1]=t;
    }
    // update state
    F(4)c->s[i]+=s[i];
}

void md4_init(md4_ctx *c) {
    c->s[0]=0x67452301;
    c->s[1]=0xefcdab89;
    c->s[2]=0x98badcfe;
    c->s[3]=0x10325476;
    c->len =0;
}

void md4_update(md4_ctx *c, const void *in, W len) {
    B *p=(B*)in;
    W i, idx;
    
    // get buffer index
    idx = c->len & 63;
    // update total length
    c->len += len;
    
    for (i=0;i<len;i++) {
      // add byte to buffer
      c->x.b[idx]=p[i]; idx++;
      // buffer filled?
      if(idx == 64) {
        // compress it
        md4_compress(c);
        idx=0;
      }
    }
}

void md4_final(void *out, md4_ctx *c) {
    W i,len,*p=(W*)out;
    
    // get buffer index
    i = len = c->len & 63;
    // zero remainder of buffer
    while(i < 64) c->x.b[i++]=0;
    // add 1 bit
    c->x.b[len]=0x80;
    // if index exceeds area for total bits
    if(len >= 56) {
      // compress it
      md4_compress(c);
      // zero initialize buffer
      F(16)c->x.w[i]=0;
    }
    // add total bits
    c->x.q[7]=c->len*8;
    // compress
    md4_compress(c);
    // return hash
    F(4)p[i]=c->s[i];
}

