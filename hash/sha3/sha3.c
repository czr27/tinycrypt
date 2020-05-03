/**
  Copyright © 2015, 2016 Odzhan. All Rights Reserved.

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

#include "sha3.h"

void sha3_compress(void *p) {
    W n,i,j,r,x,y,t,Y,b[5],*s=p;
    B c=1;

    F(n,24){
      // Theta
      F(i,5){b[i]=0;F(j,5)b[i]^=s[i+j*5];}
      F(i,5){
        t=b[(i+4)%5]^R(b[(i+1)%5],63);
        F(j,5)s[i+j*5]^=t;}
      t=s[1],y=r=0,x=1;
      // Rho and Pi
      F(j,24)
        r+=j+1,Y=(x*2)+(y*3),x=y,y=Y%5,
        Y=s[x+y*5],s[x+y*5]=R(t, -r),t=Y;
      // Chi
      F(j,5){
        F(i,5)b[i]=s[i+j*5];
        F(i,5)
          s[i+j*5]=b[i]^( b[(i+2)%5] &~ b[(i+1)%5]);}
      // Iota
      F(j,7)
        if((c=(c<<1)^((c>>7)*113))&2)
          *s^=1ULL<<((1<<j)-1);
    }
}

void sha3_init(sha3_ctx *c, int len) {
    W i;
    
    // zero initialize state
    F(i,25)c->s.q[i]=0;
    
    c->h = len;            // set output length
    c->r = 200-(2*len);    // set the rate
    c->i = 0;              // set the buffer index
}

void sha3_update(sha3_ctx *c, const void *in, W len) {
    W i;
    B *p=(B*)in;
  
    F(i,len) {
      // absorb byte into state
      c->s.b[c->i++] ^= p[i];
      // buffer filled?    
      if(c->i == c->r) {
        // permute
        sha3_compress(&c->s);
        // reset index 
        c->i=0;
      }
    }
}

void sha3_final(void *out, sha3_ctx *c) {
    B   *p=(B*)out;
    int i;
    
    // add domain parameter
    c->s.b[c->i]^=6;
    // add 1 bit
    c->s.b[c->r-1]^=0x80;
    // permute
    sha3_compress(&c->s);
    // return hash
    F(i,c->h)p[i]=c->s.b[i];
}
