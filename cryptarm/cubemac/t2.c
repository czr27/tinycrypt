
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

#define R(v,n)(((v)<<(n))|((v)>>(32-(n))))
#define F(a,b)for(a=0;a<b;a++)
  
typedef unsigned char B;
typedef unsigned int W;
  
void P(void*p){
    W i,j,k,n,y[16],*s=p;

    F(n,16){
      for(k=7,j=2;j>0;k+=4,j--){
        F(i,16)s[i+16]+=s[i];
        F(i,16)y[i^(j*4)]=s[i];
        F(i,16)s[i]=R(y[i],k); // <<
        F(i,16)s[i]^=s[i+16];
        F(i,16)y[i^j]=s[i+16];
        F(i,16)s[i+16]=y[i];
      }
    }
}

W A(B*s,B*m,W ml){
    W i,j=0;

    F(i,ml){
      s[j++]^=m[i];
      if(j==32)P(s),j=0;
    }
    return j;
}

void cubemac(void*k,W kl,void*m,W ml,void*t){
    W i;
    union{B b[128];W w[32];}s;

    F(i,32)s.w[i]=0;
    s.w[0]=16;s.w[1]=32;s.w[2]=16;
    P(&s);
    A(s.b,k,kl);
    i=A(s.b,m,ml);
    s.b[i]^=0x80;
    P(&s);
    s.w[31]^=1;
    P(&s);
    P(&s);
    F(i,16)((B*)t)[i]=s.b[i];
}
