/**
  This is free and unencumbered software released into the public domain.

  Anyone is free to copy, modify, publish, use, compile, sell, or
  distribute this software, either in source code form or as a compiled
  binary, for any purpose, commercial or non-commercial, and by any
  means.

  In jurisdictions that recognize copyright laws, the author or authors
  of this software dedicate any and all copyright interest in the
  software to the public domain. We make this dedication for the benefit
  of the public at large and to the detriment of our heirs and
  successors. We intend this dedication to be an overt act of
  relinquishment in perpetuity of all present and future rights to this
  software under copyright law.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.

  For more information, please refer to <http://unlicense.org/> */
  
#include "aes.h"

// Multiplication over GF(2**8)
W M(W x) {
    W t=x&0x80808080;
    return((x^t)<<1)^((t>>7)*0x1b);
}
// SubByte
B S(B x) {
    B i,y,c;
    if(x) {
      for(c=i=0,y=1;--i;y=(!c&&y==x)?c=1:y,y^=M(y));
      x=y;F(4)x^=y=(y<<1)|(y>>7);
    }
    return x^99;
}

void aes(void *mk, void *data) {
    W i,w,x[4],k[4],c=1,*s=data;

    // copy 128-bit plain text + 128-bit master key to local memory
    F(4)x[i]=s[i], k[i]=((W*)mk)[i];

    for(;;) {
      // 1st part of ExpandKey
      w=k[3];F(4)w=(w&-256)|S(w),w=R(w,8);
      // AddConstant, AddRoundKey, 2nd part of ExpandKey
      w=R(w,8)^c;F(4)s[i]=x[i]^k[i], w=k[i]^=w;
      // if round 11, stop
      if(c==108)break; 
      // update constant
      c=M(c);
      // SubBytes and ShiftRows
      F(16)((B*)x)[(i%4)+(((i/4)-(i%4))%4)*4]=S(((B*)s)[i]);
      // if not round 11, MixColumns
      if(c!=108)
        F(4)w=x[i],x[i]=R(w,8)^R(w,16)^R(w,24)^M(R(w,8)^w);
    }
}
