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

#define RC5_R 12
#define RC5_K (2*(RC5_R+1))

void rc5(void *mk, void *data) {
    W A=0xB7E15163,B,i,*k,X,S[RC5_K],L[4],*x=data,*K=mk;

    // copy 128-bit key to local buffer
    F(i,4)L[i]=K[i];
    
    // initialize S
    F(i,RC5_K)S[i]=A,A+=0x9E3779B9;
    A=B=0; k=S;
    
    // create subkeys
    F(i,RC5_K*3)
      A=S[i%RC5_K]=R(S[i%RC5_K]+(A+B),3),
      B=L[i%4]=R(L[i%4]+(A+B),(A+B));
    
    // add first two subkeys to 64-bits of plaintext
    A=x[0]+*k++;B=x[1]+*k++;
    // do 12 rounds on each 32-bit word
    F(i,RC5_K-2)X=R(A^B,B&255)+*k++,A=B,B=X;
    // store ciphertext
    x[0]=A; x[1]=B;
}
