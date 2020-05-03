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
  
#include "sha1.h"

#define FF(x,y,z)((z)^((x)&((y)^(z))))
#define GG(x,y,z)(((x)& (y))|((z)&((x)|(y))))
#define HH(x,y,z)((x)^(y)^(z))

void sha1_compress(sha1_ctx *c) {
    W t,i,w[80],x[5];

    // load 64-bytes in big endian byte order
    F(16)w[i]=rev32(c->x.w[i]);
    
    // expand buffer
    for(i=16;i<80;i++)
      w[i]=R(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
    
    // load 160-bit state
    F(5)x[i]=c->s[i];
    
    // permute
    F(80) {
      if(i<20){
        t = FF(x[1],x[2],x[3])+0x5A827999L;
      } else if(i<40) {
        t = HH(x[1],x[2],x[3])+0x6ED9EBA1L;
      } else if(i<60) {
        t = GG(x[1],x[2],x[3])+0x8F1BBCDCL;
      } else {
        t = HH(x[1],x[2],x[3])+0xCA62C1D6L;
      }
      t+=R(x[0],5)+x[4]+w[i];
      x[4]=x[3];x[3]=x[2];x[2]=R(x[1],30);x[1]=x[0];x[0]=t;
    }
    // update state with result
    F(5)c->s[i]+=x[i];
}

void sha1_init(sha1_ctx *c) {
    c->s[0] = 0x67452301;
    c->s[1] = 0xefcdab89;
    c->s[2] = 0x98badcfe;
    c->s[3] = 0x10325476;
    c->s[4] = 0xc3d2e1f0;
    c->len  = 0;
}

void sha1_update(sha1_ctx *c,const void *in,W len) {
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
        sha1_compress(c);
        idx=0;
      }
    }
}

void sha1_final(void *out, sha1_ctx *c) {
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
      sha1_compress(c);
      // zero buffer
      F(16)c->x.w[i]=0;
    }
    // add total length in bits
    c->x.q[7]=rev64(c->len*8);
    // compress it
    sha1_compress(c);
    // return hash
    F(5)p[i]=rev32(c->s[i]);
}
