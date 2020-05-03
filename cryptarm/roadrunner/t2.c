/**
  Copyright (C) 2018 Odzhan. All Rights Reserved.

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

#define R(v,n)(((v)<<(n))&255|((v)>>(8-(n)))&255)
#define F(a,b)for(a=0;a<b;a++)

typedef unsigned char B;
typedef unsigned int W;

void S(B*x){
    B t;

    t=x[3];x[3]&=x[2];
    x[3]^=x[1];x[1]|=x[2];
    x[1]^=*x;*x&=x[3];
    *x^=t;t&=x[1];x[2]^=t;
}

void roadrunner(void*mk,void*p){
    W i,j,l=4,r,t,*k=mk,*x=p;
    B *v;
    
    *x^=*k;

    for(r=12;r>0;r--){
      t=*x;
      for(i=0;i<3;i++){
        v=p;
        if(i==2)v[3]^=r;
        S(v);
        for(j=0;j<4;j++){
          *v^=R(R(*v,1)^*v,1);
          *v++^=((B*)k)[l++&15];
        }
      }
      S(p);
      *x^=x[1];x[1]=t;
    }
    t=*x;*x=x[1];x[1]=t;
    *x^=k[1];
}
