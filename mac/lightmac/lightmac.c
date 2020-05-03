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


#include "lightmac.h"

void lightmac(void *data, u32 len, void *tag, void *key) {
    int  i;
    u8   m[BLK_LEN], v[TAG_LEN]; 
    u8   *t=(u8*)tag, *k=(u8*)key, *p=(u8*)data;
    
    union {
      u8  b[8];
      u64 q;
    } s;
    
    // 1. zero initialize V
    for(i=0;i<TAG_LEN;i++) v[i] = 0;

    // 2. set protected counter sum to 1
    s.q = 1;
    
    // 3. while we have blocks of data equal to (n - s)
    while (len >= MSG_LEN) {
      // 4. add counter s to M in big endian byte order
      for(i=0;i<CTR_LEN;i++) {
        m[CTR_LEN-i-1] = s.b[i];
      }
      // 5. add data to M
      for(i=0;i<MSG_LEN;i++) {
        m[CTR_LEN+i] = p[i];
      }
      // 6. encrypt M with K1
      ENC(k, m);
      // 7. update V
      for(i=0;i<TAG_LEN;i++) v[i] ^= m[i];
      // 8. decrease length and advance data pointer
      len -= MSG_LEN;
      p += MSG_LEN;
      // 9. update counter
      s.q++;
    }
    // 10. absorb any data less than (n - s)
    for(i=0;i<len;i++) v[i] ^= p[i];
    // 11. add end bit
    v[i] ^= 0x80;
    // 12. encrypt V with K2
    k += BC_KEY_LEN;
    ENC(k, v);
    // 13. return V in T
    for(i=0;i<TAG_LEN;i++) t[i] = v[i];
}
