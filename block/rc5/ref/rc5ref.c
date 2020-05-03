/* RC5REF.C -- Reference implementation of RC5-32/12/16 in C.        */
/* Copyright (C) 1995 RSA Data Security, Inc.                        */

#include <stdio.h>
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

typedef unsigned int WORD; /* Should be 32-bit = 4 bytes        */
#define w        32             /* word size in bits                 */
#define r        12             /* number of rounds                  */  
#define b        16             /* number of bytes in key            */
#define c         4             /* number  words in key = ceil(8*b/w)*/
#define t        26             /* size of table S = 2*(r+1) words   */

WORD S[t];                      /* expanded key table                */
WORD P = 0xb7e15163, Q = 0x9e3779b9;  /* magic constants             */

/* Rotation operators. x must be unsigned, to get logical right shift*/
#define ROTL(x,y) (((x)<<(y&(w-1))) | ((x)>>(w-(y&(w-1)))))
#define ROTR(x,y) (((x)>>(y&(w-1))) | ((x)<<(w-(y&(w-1)))))

void RC5_ENCRYPT(WORD *pt, WORD *ct) /* 2 WORD input pt/output ct    */
{ WORD i, A=pt[0]+S[0], B=pt[1]+S[1];
  for (i=1; i<=r; i++) 
    { A = ROTL(A^B,B)+S[2*i]; 
      B = ROTL(B^A,A)+S[2*i+1]; 
    }
  ct[0] = A; ct[1] = B;  
} 

void RC5_DECRYPT(WORD *ct, WORD *pt) /* 2 WORD input ct/output pt    */
{ WORD i, B=ct[1], A=ct[0];
  for (i=r; i>0; i--) 
    { B = ROTR(B-S[2*i+1],A)^A; 
      A = ROTR(A-S[2*i],B)^B; 
    }
  pt[1] = B-S[1]; pt[0] = A-S[0];  
} 

void RC5_SETUP(unsigned char *K) /* secret input key K[0...b-1]      */
{  WORD i, j, k, u=w/8, A, B, L[c]; 
   /* Initialize L, then S, then mix key into S */
   
   for (i=b-1,L[c-1]=0; i!=-1; i--) {
     L[i/u] = (L[i/u]<<8)+K[i];
   }
   
   for (S[0]=P,i=1; i<t; i++) {
     S[i] = S[i-1]+Q;
   }
   for (A=B=i=j=k=0; k<3*t; k++,i=(i+1)%t,j=(j+1)%c)   
     { A = S[i] = ROTL(S[i]+(A+B),3);  
       B = L[j] = ROTL(L[j]+(A+B),(A+B)); 
     } 
} 

void bin2hex(const char *s, void *bin, int len) {
    int  i;
    char x;
    
    printf ("\n%s=", s);
    
    for (i=0; i<len; i++) {
      if ((i & 7)==0) putchar('\n');
      if (i==len-1) x='\n'; else x=',';
      printf ("0x%02x%c ", ((uint8_t*)bin)[i], x);
    }
}

// 128-bit key
unsigned char tv_key[16]={
  0x1b,0xec,0x52,0xf7,0xfc,0xcc,0x95,0x24,
  0x49,0x3d,0x8f,0xae,0x11,0x7a,0x0b,0xc8 };
  
// 64-bit plaintext
unsigned char tv_plaintext[8]={
  0x4d,0xbf,0x44,0xc6,0xb1,0xbe,0x73,0x6e };
  
// 64-bit ciphertext
uint8_t tv_ciphertext[8]={
  0x26,0x3d,0xff,0x14,0xe7,0x2b,0xde,0x08 };
  
void main(int argc, char *argv[])
{ WORD i, j, pt1[2], pt2[2], ct[2] = {0,0};
  
    memcpy(pt1, tv_plaintext, 8);
    
    /* Setup, encrypt, and decrypt */
    RC5_SETUP(tv_key);  
    RC5_ENCRYPT(pt1, ct);  
    RC5_DECRYPT(ct, pt2);
    
    bin2hex("result", ct, 8);
}

