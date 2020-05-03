/**
  Copyright © 2015, 2018 Odzhan. All Rights Reserved.

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
  
#include "rc5.h"

#define R(v,n)(((v)<<(n))|((v)>>(32-(n))))
#define F(a,b)for(a=0;a<b;a++)
typedef unsigned int W;

void rc5(void*mk,void*p){
    W A=0xB7E15163,B,i,X,S[26],L[4],*x=p,*k=mk;

    F(i,4)L[i]=k[i];k=S;
    
    F(i,26)S[i]=A,A+=0x9E3779B9;
    A=B=0;
    
    F(i,26*3)
      A=S[i%26]=R(S[i%26]+A+B,3),
      B=L[i%4]=R(L[i%4]+A+B,A+B);
      
    A=x[0]+*k++;B=x[1]+*k++;

    F(i,12)
      X=R(A^B,B&255)+*k++,
      A=B,B=X;
      
    x[0]=A;x[1]=B;;
}

void rc5_encryptx(void *key, void *data)
{
    uint32_t A, B, t;
    uint32_t L[4], S[RC5_KR];
    int      i, j,r;    
    
    uint32_t *k=(uint32_t*)key;
    uint32_t *x=(uint32_t*)data;
    
    // initialize L with 128-bit key
    memcpy(&L, key, 16);

    A = 0xC983AE2D; //RC5_P;
    
    // initialize S with constants
    for (i=RC5_KR-1; i>=0; i--) {
      A -= RC5_Q;     
      S[i] = A;
    }
    
    A = B = 0;
    r = (RC5_KR*3) - 1;
    
    // create subkeys
    for (i=0, j=0; r>0; i++, j++, r--) {
      // i needs reset?
      if (i==RC5_KR) i=0;
      
      A = S[i%RC5_KR] = ROTR32(S[i%RC5_KR] + A+B, 32-3);  
      B = L[j%4] = ROTR32(L[j%4] + A+B, 32-U8V(A+B));
    }
    
    // assign subkeys to k ptr 
    k = S;
    
    // load plaintext
    A = x[0] + *k; k++; 
    B = x[1] + *k; k++;

    // apply encryption
    for (i=RC5_KR-2; i>0; i--) {
      // original spec uses ROTL32
      A = ROTR32(A ^ B, 32 - U8V(B)) + *k; k++;   
      // rotate
      XCHG(A, B);
    }
    // save
    x[0] = A; x[1] = B;
}

