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

#define F(n)for(i=0;i<n;i++)
typedef unsigned char B;
typedef unsigned int W;
typedef struct _ctx{B x,y,s[256];}ctx;

void rc4(W l,B *in,ctx*c){
  B j,t,x,y,*s=c->s;
  W i;
  
  if(!l){
    F(256)s[i]=i;
    j=c->x=c->y=0;
    F(256)
      j+=s[i]+in[i%16],
      t=s[i],s[i]=s[j],s[j]=t;
  }else{
    x=c->x;y=c->y;
    F(l)
      x++,y+=s[x],
      t=s[x],s[x]=s[y],s[y]=t,
      j=s[x]+s[y],
      in[i]^=s[j];
    c->x=x;c->y=y;
  }
}

#ifdef TEST

#include <stdio.h>
#include <stdint.h>

B key[]=
{0x00,0x53,0xA6,0xF9,0x4C,0x9F,0xF2,0x45,0x98,0xEB,0x3E,0x91,0xE4,0x37,0x8A,0xDD};

B s1[]=
{0x3f, 0xc0, 0x4a, 0x29, 0xea, 0xed, 0x21, 0xbb,
 0x1c, 0x12, 0x6b, 0x6e, 0x22, 0xf6, 0x55, 0xd8,
 0xfe, 0x37, 0x87, 0xaf, 0x61, 0xae, 0x90, 0xf0,
 0xa7, 0x09, 0x1e, 0x5f, 0x82, 0xdd, 0xa8, 0x81,
 0xa1, 0x26, 0x2e, 0xa8, 0x22, 0x31, 0xb2, 0x14,
 0x48, 0x79, 0x7b, 0x17, 0xf1, 0xf7, 0xf8, 0xf7,
 0x8f, 0x27, 0x61, 0x70, 0xf0, 0x16, 0x7f, 0xaf,
 0xbb, 0x54, 0x8f, 0x55, 0x53, 0x6b, 0x40, 0xdf};

void bin2hex(char *s, void *p, int len) {
  int i;
  printf("%s : ", s);
  for (i=0; i<len; i++) {
    if ((i&7)==0) putchar('\n');
    printf ("0x%02x, ", ((uint8_t*)p)[i]);
  }
  printf("\n");
}

int main(void){
  B   e,stream[64]={0};
  ctx c;
  
  // set key
  rc4(0,key,&c);
  rc4(sizeof(stream),stream,&c);

  e=(memcmp(stream,s1,64)==0);
  printf("RC4 Test: %s\n",e?"OK":"FAILED");
  return 0;
}

#endif