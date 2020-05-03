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

/**
MARU AUTHENTICATED ENCRYPTION pronounced "MAY"
1. void wrap(B*buf,W l);
2. int unwrap(B*buf,W l);
*/
#define R(v,n)(((v)>>(n))|((v)<<(32-(n))))
#define F(a,b)for(a=0;a<b;a++)

typedef unsigned char B;
typedef unsigned int W;

typedef struct _ctx_t {
    B mk[32],ek[16],l,b[128+16];
    union{B c[8];B n[8];}v;
}ctx;

W X(W w){
    W t=w&0x80808080;
    return((w^t)<<1)^((t>>7)*0x1B);
}

B S(B x){
    B i,z,y=x;

    if(x){
      for(i=1,y=1;i>0;i++){
        y^=X(y);
        if(y==x)break;
      }
      x=~i;y=1;
      F(i,x)y^=X(y);
    }
    z=y;
    F(i,4)y=(y>>7)|(y<<1),z^= y;
    return z^0x63;
}

void E(B*ek,B*s){
    W i,w;
    B k[16],c=1;
    union{B b[16];W w[4];}v;

    F(i,16)k[i]=ek[i],v.b[i]=s[i];
    for(;;){
      F(i,16)s[i]=v.b[i]^k[i];
      if(c==108)break;
      k[0]^=c;c=X(c);
      w=((W*)&k)[3];
      F(i,4)
        w=R(w,8),k[i]^=S(w),k[i+4]^=k[i],
        k[i+8]^=k[i+4],k[i+12]^=k[i+8];
      F(i,16)v.b[(i%4)+(((i/4)-(i%4))%4)*4]=S(s[i]);
      if(c!=108){
        F(i,4)
          w=v.w[i],
          v.w[i]=R(w,8)^R(w,16)^R(w,24)^X(R(w,8)^w);
      }
    }
}

void M(ctx*c,B*t){
    B i,j,s,l=c->l,*p=c->b;
    struct{B s;B b[15];}m;

    F(i,16)t[i]=0;
    s=0;i=0;
    while(l){
      m.b[i++]=*p++;
      if(i==15){
        s++;m.s=s;
        E(c->mk,(void*)&m);
        F(i,16)t[i]^=m.b[i];
        i=0;
      }
      l--;
    }
    m.b[i++]=0x80;
    F(j,i)t[j]^=m.b[j];
    E(&c->mk[16],t);
}

B AE(ctx*c,B e){
    B t[16],s[16],r=1;
    if(e){
      r=enc(c->ek,s);
      L(c,t);
    }else{
      L(c,t);
      r=enc(c->ek,s);
    }
    return r;
}
