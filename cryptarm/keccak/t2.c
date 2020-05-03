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

#define R(v,n)(((v)<<(n))|((v)>>(8-(n))))
#define F(a,b)for(a=0;a<b;a++)
  
void keccak(void*p){
  unsigned char R=1,n,i,j,r,x,y,t,Y,b[5],*s=p;

  F(n,18){
    F(i,5){b[i]=0;F(j,5)b[i]^=s[i+5*j];}
    F(i,5){
      t=b[(i+4)%5]^R(b[(i+1)%5],1);
      F(j,5)s[i+5*j]^=t;}
    t=s[1],y=r=0,x=1;
    F(j,24)
      r+=j+1,Y=x+x+3*y,x=y,y=Y%5,
      Y=s[x+5*y],s[x+5*y]=R(t,r%8),t=Y;
    F(j,5){
      F(i,5)b[i]=s[i+5*j];
      F(i,5)
        s[i+5*j]=b[i]^(b[(i+2)%5]&~b[(i+1)%5]);}
    F(j,7)
      if((R=(R+R)^(113*(R>>7)))&2)
        *s^=1<<((1<<j)-1);
  }
}

#ifdef TEST

#include <stdio.h>
#include <stdint.h>

void bin2hex(uint8_t x[], int len) {
    int i;
    for (i=0; i<len; i++) {
      if ((i & 7)==0) putchar('\n');
      printf ("0x%02x,", x[i]);
    }
    putchar('\n');
}

// Keccak-f[200, 18] permutation function
// 210 bytes of x86 assembly

uint8_t tv1[]={
  0x3c,0x28,0x26,0x84,0x1c,0xb3,0x5c,0x17,
  0x1e,0xaa,0xe9,0xb8,0x11,0x13,0x4c,0xea,
  0xa3,0x85,0x2c,0x69,0xd2,0xc5,0xab,0xaf,
  0xea };

uint8_t tv2[]={
  0x1b,0xef,0x68,0x94,0x92,0xa8,0xa5,0x43,
  0xa5,0x99,0x9f,0xdb,0x83,0x4e,0x31,0x66,
  0xa1,0x4b,0xe8,0x27,0xd9,0x50,0x40,0x47,
  0x9e };

int main(void)
{
    uint8_t  out[25];
    int      equ;

    memset(out, 0, sizeof(out));

    k200(out);
    equ = memcmp(out, tv1, sizeof(tv1))==0;
    printf("Test 1 %s\n", equ ? "OK" : "Failed");
    //bin2hex(out, 25);

    k200(out);
    equ = memcmp(out, tv2, sizeof(tv2))==0;
    printf("Test 2 %s\n", equ ? "OK" : "Failed");
    //bin2hex(out, 25);

    return 0;
}
#endif