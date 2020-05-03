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
  
#define R(v,n)(((v)>>(n))|((v)<<(32-(n))))
#define ROTATE(a,b) (((a) >> (b)) | ((a) << (32 - b)))

#define F(a,b)for(a=0;a<b;a++)
typedef unsigned int W;
typedef unsigned char B;

void cube2(void *p) {
  int i, r;
  W   y[16], *x=p;
  B   c = 1;

  for (r = 0;r < 16;++r) {
    x[0]^=c;c=(c<<1)^(-(c>>7)&0xF5);
    
    for (i = 0;i < 16;++i) x[i + 16] += x[i];
    for (i = 0;i < 16;++i) y[i ^ 8] = x[i];
    for (i = 0;i < 16;++i) x[i] = ROTATE(y[i],25);
    for (i = 0;i < 16;++i) x[i] ^= x[i + 16];
    for (i = 0;i < 16;++i) y[i ^ 2] = x[i + 16];
    for (i = 0;i < 16;++i) x[i + 16] = y[i];
    for (i = 0;i < 16;++i) x[i + 16] += x[i];
    for (i = 0;i < 16;++i) y[i ^ 4] = x[i];
    for (i = 0;i < 16;++i) x[i] = ROTATE(y[i],21);
    for (i = 0;i < 16;++i) x[i] ^= x[i + 16];
    for (i = 0;i < 16;++i) y[i ^ 1] = x[i + 16];
    for (i = 0;i < 16;++i) x[i + 16] = y[i];
  }
}

void cube(void *p) {
    W i,j,k,r,*s=p,y[16];
    B c=1;
    
    F(r,16) {
      s[0]^=c;c=(c<<1)^(-(c>>7)&0xF5);
      for(k=25,j=8;j>0;k-=4,j-=4) {          
        F(i,16)s[i+16]+=s[i];
        F(i,16)y[i^j]=s[i];
        F(i,16)s[i]=R(y[i],k);
        F(i,16)s[i]^=s[i+16];
        F(i,16)y[i^(j>>2)]=s[i+16];
        F(i,16)s[i+16]=y[i];
      }
    }
}


#ifdef TEST

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

uint8_t tv[]=
{0x68,  0x85,  0x33,  0x09,  0xBB,  0x6D,  0x8D,  0xE1, 
 0xB7,  0x88,  0x64,  0x2C,  0x5B,  0xE6,  0x7D,  0x9D, 
 0xB7,  0x6B,  0xE2,  0x5B,  0x6B,  0x20,  0xB8,  0xE1, 
 0x36,  0xFC,  0x93,  0x1D,  0xA0,  0x1D,  0x57,  0x10, 
 0x88,  0x4F,  0x31,  0x6F,  0xE9,  0xDE,  0x3E,  0x35, 
 0x74,  0xFD,  0x98,  0xB0,  0xCC,  0xA8,  0x70,  0xAA, 
 0xB6,  0x46,  0x1E,  0x0A,  0x50,  0x77,  0xAF,  0xF3, 
 0x40,  0x02,  0xEC,  0xCD,  0xD4,  0xAC,  0xA8,  0xFC };
 
void bin2hex(char *str, uint8_t *x, int len) {
    int i;
    
    printf("%s : ", str);
    for (i=0; i<len; i++) {
      if (!(i & 7)) putchar('\n');
      printf(" 0x%02X, ", x[i]);
    }
    printf("\n");
}

int main(void) {
    uint8_t s[128];
    int     i;
    
    memset(s, 0, sizeof(s));
    F(i,10) cube(s);
    bin2hex("state", s, 64);
    
    memset(s, 0, sizeof(s));
    F(i,10) cube2(s);
    bin2hex("state", s, 64);
    
    return 0;
}

#endif
