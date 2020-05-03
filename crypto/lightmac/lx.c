/**
  Copyright © 2018 Odzhan. All Rights Reserved.

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

#define COUNTER_LENGTH 4
#define BLOCK_LENGTH   16
#define TAG_LENGTH     16
#define BC_KEY_LENGTH  16
#define ENCRYPT        BCEncrypt

#define R(v,n)(((v)>>(n))|((v)<<(32-(n))))

#define CTR_LEN     4 // 32-bits
#define BLK_LEN    16 // 128-bits
#define TAG_LEN    16 // 128-bits
#define BC_KEY_LEN 16 // 128-bits

#define M_LEN         BLK_LEN-CTR_LEN

#define F(a,b)for(a=0;a<b;a++)
typedef unsigned int W;
typedef unsigned char B;

void bin2hex(char *s, void *p, int len);

// Multiplication over GF(2**8)
W M(W x){
    W t=x&0x80808080;
    return((x^t)*2)^((t>>7)*27);
}
// SubByte
B S(B x){
    B i,y,c;
    if(x){
      for(c=i=0,y=1;--i;y=(!c&&y==x)?c=1:y,y^=M(y));
      x=y;F(i,4)x^=y=(y<<1)|(y>>7);
    }
    return x^99;
}
void E(void*mk,void*s){
    W i,w,x[8],c=1,*k=(W*)&x[4];

    // copy plain text + master key to x
    F(i,4)x[i]=((W*)s)[i], x[i+4]=((W*)mk)[i];

    for(;;) {
      // AddRoundKey, 1st part of ExpandRoundKey
      w=k[3];F(i,4)w=(w&-256)|S(w),w=R(w,8),((W*)s)[i]=x[i]^k[i];

      // AddRoundConstant, perform 2nd part of ExpandRoundKey
      w=R(w,8)^c;F(i,4)w=k[i]^=w;

      // if round 11, stop; 
      if(c==108)break; 
      // update c
      c=M(c);

      // SubBytes and ShiftRows
      F(i,16)((B*)x)[(i%4)+(((i/4)-(i%4))%4)*4]=S(((B*)s)[i]);

      // if not round 11, MixColumns
      if(c!=108)
        F(i,4)w=x[i],x[i]=R(w,8)^R(w,16)^R(w,24)^M(R(w,8)^w);
    }
}

#define swap __builtin_bswap32

// max message for current parameters is 1792 bytes
void tag(W l,B*b,B*k,B*t) {
    int i,j,s;
    B   m[BLK_LEN];

    // initialize tag T
    F(i,TAG_LEN)t[i]=0;

    for(s=1,j=0; l>=M_LEN; s++,l-=M_LEN) {
      // add 8-bit counter S 
      *((W*)m) = swap(s);
      // add bytes to M 
      F(j,M_LEN)
        m[CTR_LEN+j]=*b++;
      // encrypt M with K1
      E(k,m);
      // update T
      F(i,TAG_LEN)t[i]^=m[i];
    }
    // copy remainder of input
    F(i,l)m[i]=b[i];
    // add end bit
    m[i]=0x80;
    // update T 
    F(i,l+1)t[i]^=m[i];
    // encrypt T with K2
    k+=BC_KEY_LEN;
    E(k,t);
}

#ifdef TEST

#include <stdio.h>
#include <stdint.h>
#include <string.h>

B k1[16]={0x63, 0xcd, 0xae, 0x6e, 0xbf, 0x34, 0xdb, 0xd5, 0x54, 0x1b, 0xd9, 0xf6, 0x93, 0x0c, 0xdc, 0x09};
B k2[16]={0xde, 0x9b, 0x7a, 0x5a, 0xa6, 0xa0, 0x5a, 0xe7, 0xec, 0x93, 0xe0, 0x3f, 0x30, 0x1d, 0x77, 0xef};

B m1[64]={0x55, 0x7f, 0xbd, 0x6b, 0x41, 0x52, 0xce, 0xf6, 0x92, 0x41, 0x04, 0xec, 0xf5, 0xd5, 0x28, 0xaf, 
         0x8f, 0xb0, 0xaa, 0x10, 0x43, 0xa6, 0xa8, 0xd9, 0xc3, 0x57, 0xb5, 0x0e, 0xe0, 0x04, 0x83, 0xab, 
         0xe2, 0xe0, 0x50, 0xec, 0x80, 0x36, 0x86, 0x0f, 0xa2, 0x24, 0x59, 0x38, 0x54, 0x29, 0xa7, 0x52, 
         0x6d, 0x10, 0x04, 0xc4, 0x87, 0x9e, 0x64, 0xa5, 0x80, 0x50, 0x06, 0xb2, 0xe4, 0x47, 0x37, 0xf2};

B t1[16]={0x56,0x1f,0x5c,0x0a,0x1b,0xe7,0xcb,0x20,0xd7,0x0c,0xe3,0x48,0x24,0x63,0xde,0x53};
        
        
B k3[16]={0x63, 0xcd, 0xae, 0x6e, 0xbf, 0x34, 0xdb, 0xd5, 0x54, 0x1b, 0xd9, 0xf6, 0x93, 0x0c, 0xdc, 0x09};
B k4[16]={0xde, 0x9b, 0x7a, 0x5a, 0xa6, 0xa0, 0x5a, 0xe7, 0xec, 0x93, 0xe0, 0x3f, 0x30, 0x1d, 0x77, 0xef};

B m2[64]={0x55, 0x7f, 0xbd, 0x6b, 0x41, 0x52, 0xce, 0xf6, 0x92, 0x41, 0x04, 0xec, 0xf5, 0xd5, 0x28, 0xaf, 
         0x8f, 0xb0, 0xaa, 0x10, 0x43, 0xa6, 0xa8, 0xd9, 0xc3, 0x57, 0xb5, 0x0e, 0xe0, 0x04, 0x83, 0xab, 
         0xe2, 0xe0, 0x50, 0xec, 0x80, 0x36, 0x86, 0x0f, 0xa2, 0x24, 0x59, 0x38, 0x54, 0x29, 0xa7, 0x52, 
         0x6d, 0x10, 0x04, 0xc4, 0x87, 0x9e, 0x64, 0xa5, 0x80, 0x50, 0x06, 0xb2};
         
B t2[16]={0xa6,0xe0,0x82,0x8a,0x34,0x57,0x8a,0x5b,0xcf,0x30,0x9f,0x32,0x34,0xa2,0x68,0xbe};
 
void bin2hex(char *s, void *p, int len) {
    int i;
    printf("%s : ", s);
    for (i=0; i<len; i++) {
      printf ("%02x", ((uint8_t*)p)[i]);
    }
    putchar('\n');
}

char* test_lm(void *k1_tv,void *k2_tv, void *m_tv, uint32_t m_len, void *tag_tv, void *r)  
{
    uint8_t       key[BC_KEY_LENGTH*2];
    
    memcpy(key, k1_tv, 16);
    memcpy(&key[16], k2_tv, 16);
    
    tag(m_len, m_tv, key, r);
  
    return (memcmp(r, tag_tv, TAG_LENGTH)==0) ? "OK" : "FAILED";
}

int main(void){
    char *s1,*s2, r1[TAG_LENGTH], r2[TAG_LENGTH];
    
    memset(r1, 0, sizeof(r1));
    memset(r2, 0, sizeof(r2));
    
    s1 = test_lm(k1, k2, m1, 64, t1, r1);
    bin2hex("r1", r1, TAG_LENGTH);
    
    s2 = test_lm(k3, k4, m2, 60, t2, r2);
    bin2hex("r2", r2, TAG_LENGTH);
    
    printf("\nTest #1 : %s\nTest #2 : %s\n", s1, s2);
    return 0;
}

#endif
