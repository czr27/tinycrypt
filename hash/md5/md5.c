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
  
#include "md5.h"

#define FF(x,y,z)((z)^((x)&((y)^(z))))
#define GG(x,y,z)FF(z,x,y)
#define HH(x,y,z)((x)^(y)^(z))
#define II(x,y,z)((y)^((x)|(~z)))

void md5_compress(md5_ctx *ctx) {
    W a, b, c, d, i, t, s;
    B rotf[]={7,12,17,22};
    B rotg[]={5, 9,14,20};
    B roth[]={4,11,16,23};
    B roti[]={6,10,15,21};

    B sigma[]=
    { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
      1,6,11,0,5,10,15,4,9,14,3,8,13,2,7,12,
      5,8,11,14,1,4,7,10,13,0,3,6,9,12,15,2,
      0,7,14,5,12,3,10,1,8,15,6,13,4,11,2,9 };

    W tc[64] =
    { 0xD76AA478, 0xE8C7B756, 0x242070DB, 0xC1BDCEEE, 
      0xF57C0FAF, 0x4787C62A, 0xA8304613, 0xFD469501,
      0x698098D8, 0x8B44F7AF, 0xFFFF5BB1, 0x895CD7BE,
      0x6B901122, 0xFD987193, 0xA679438E, 0x49B40821,
      0xF61E2562, 0xC040B340, 0x265E5A51, 0xE9B6C7AA,
      0xD62F105D, 0x02441453, 0xD8A1E681, 0xE7D3FBC8,
      0x21E1CDE6, 0xC33707D6, 0xF4D50D87, 0x455A14ED,
      0xA9E3E905, 0xFCEFA3F8, 0x676F02D9, 0x8D2A4C8A,
      0xFFFA3942, 0x8771F681, 0x6D9D6122, 0xFDE5380C,
      0xA4BEEA44, 0x4BDECFA9, 0xF6BB4B60, 0xBEBFBC70,
      0x289B7EC6, 0xEAA127FA, 0xD4EF3085, 0x04881D05,
      0xD9D4D039, 0xE6DB99E5, 0x1FA27CF8, 0xC4AC5665,
      0xF4292244, 0x432AFF97, 0xAB9423A7, 0xFC93A039,
      0x655B59C3, 0x8F0CCC92, 0xFFEFF47D, 0x85845DD1,
      0x6FA87E4F, 0xFE2CE6E0, 0xA3014314, 0x4E0811A1,
      0xF7537E82, 0xBD3AF235, 0x2AD7D2BB, 0xEB86D391 }; 
    
    a = ctx->s[0];
    b = ctx->s[1];
    c = ctx->s[2];
    d = ctx->s[3];

    for(i=0;i<64;i++) {
      if(i<16) {
        s=rotf[i%4];
        a+=FF(b,c,d);
      } else if(i<32) {
        s=rotg[i%4];
        a+=GG(b,c,d);
      } else if (i<48) {
        s=roth[i%4];
        a+=HH(b, c, d);
      } else {
        s=roti[i%4];
        a+=II(b,c,d);
      }
      a+=ctx->x.w[sigma[i]]+tc[i];
      a=R(a,s)+b;
      t=a;a=d;d=c;c=b;b=t;
    }
    ctx->s[0] += a;
    ctx->s[1] += b;
    ctx->s[2] += c;
    ctx->s[3] += d;
}

void md5_init(md5_ctx *c) {
    c->s[0]=0x67452301;
    c->s[1]=0xefcdab89;
    c->s[2]=0x98badcfe;
    c->s[3]=0x10325476;
    c->len =0;
}

void md5_update(md5_ctx *c, const void *in, W len) {
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
        md5_compress(c);
        idx=0;
      }
    }
}

void md5_final(void *out, md5_ctx *c) {
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
      md5_compress(c);
      // zero initialize buffer
      F(16)c->x.w[i]=0;
    }
    // add total bits
    c->x.q[7]=c->len*8;
    // compress
    md5_compress(c);
    // return hash
    F(4)p[i]=c->s[i];
}

