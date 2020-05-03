/**
  Copyright (C) 2016 Odzhan. All Rights Reserved.

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
  
#define R(v,n)(((v)>>(n))|((v)<<(32-(n))))
#define X(u,v)t=u,u=v,v=t
#define F(a,b)for(a=0;a<b;a++)
typedef unsigned char B;
typedef unsigned int W;

#define rev __builtin_bswap32

typedef unsigned char uint8_t;
typedef unsigned int uint32_t;

#define rev32(x) __builtin_bswap32(x)

typedef union _w32_t {
    uint8_t b[4];
    uint32_t w;
} w32_t;

// compute (c * x^4) mod (x^4 + (a + 1/a) * x^3 + a * x^2 + (a + 1/a) * x + 1)
// over GF(256)
uint32_t Mod(uint32_t c) {
    uint32_t c1, c2;
    
    c2=(c<<1) ^ ((c & 0x80) ? 0x14d : 0);
    c1=c2 ^ (c>>1) ^ ((c & 1) ? (0x14d>>1) : 0);

    return c | (c1 << 8) | (c2 << 16) | (c1 << 24);
}

// compute RS(12,8) code with the above polynomial as generator
// this is equivalent to multiplying by the RS matrix
uint32_t RS(uint64_t x) {
    uint32_t i, low, high;
      
    low  = rev32(x & 0xFFFFFFFF);
    high = x >> 32;
    
    for (i=0; i<8; i++) {
      high = Mod(high >> 24) ^ (high << 8) ^ (low & 255);
      low >>= 8;
    }
    return high;
}

uint8_t gen_q_byte(uint8_t x, uint8_t *p) {
    uint8_t a, b, x0, x1, t;
    int8_t i;
    
    for (i=0; i<2; i++) {
      a = (x >> 4) ^ (x & 15);
      b = (x >> 4) ^ ((x >> 1) & 15) ^ ((x << 3) & 0x8);
      
      x0 = p[a];
      x1 = p[b+16];
      
      // if first pass, swap
      if (i==0) {
        t = x0; x0 = x1; x1 = t;
      }
      x1 <<= 4;
      x  = x0 | x1;
      p += 32;
    }
    return x;
}
  
uint8_t qb[64]=
{ 0x18, 0xd7, 0xf6, 0x23, 0xb0, 0x95, 0xce, 0x4a,
  0xce, 0x8b, 0x21, 0x53, 0x4f, 0x6a, 0x07, 0xd9,
  0xab, 0xe5, 0xd6, 0x09, 0x8c, 0x3f, 0x42, 0x17,
  0x7d, 0x4f, 0x21, 0xe6, 0xb9, 0x03, 0x58, 0xac,
  0x82, 0xdb, 0x7f, 0xe6, 0x13, 0x49, 0xa0, 0x5c,
  0xe1, 0xb2, 0xc4, 0x73, 0xd6, 0x5a, 0x9f, 0x80,
  0xc4, 0x57, 0x61, 0xa9, 0xe0, 0x8d, 0xb2, 0xf3,
  0x9b, 0x15, 0x3c, 0xed, 0x46, 0xf7, 0x02, 0xa8 };

// generate Q box
void gen_qbox(uint8_t *p_tbl, uint8_t *q_tbl) {
    uint8_t i, t[256];
    
    // expand initial values
    for(i=0; i<64; i++) {
      t[i*2  ] = qb[i] & 15;
      t[i*2+1] = qb[i] >> 4;
    }

    // generate Q boxes
    for(i=0; (int)i<256; i++) {
      qbox[i    ] = gen_q_byte(i, t);
      qbox[i+256] = gen_q_byte(i, &t[64]);
    }
}

// The H function
uint32_t H(uint8_t *qbox, uint32_t x_in, uint32_t *L) {
    int      i, j;
    uint32_t r=0x9C53A000;
    w32_t    x;
    
    x.w = x_in * 0x01010101;
    
    for (i=4; i>=0; i--) {
      for (j=0; j<4; j++) {
        r = R(r, 31);
        x.b[j] = qbox[((r & 1) << 8) + x.b[j]];
      }
      if (i>0) {
        x.w ^= L[(i-1)*2];
      }
    }
    return x.w;
}

void tf_setkey(tf_ctx *ctx, void *key) {
    uint32_t key_copy[8];
    w32_t    x;
    uint8_t  *sbp;
    uint32_t *p=key_copy;
    w128_t   *mk=(w128_t*)key;
    uint32_t a, b=0, T, i;
    
    tf_init(ctx);

    // copy key to local space
    memcpy ((uint8_t*)key_copy, key, 32);

    for(i=0; i<40;) {
      p = key_copy;
    calc_mds:
      a = mds(H(ctx, i++, p++));
      // swap
      T=a; a=b; b=T;
      if (i & 1) goto calc_mds;
        
      b = R(b, 24);
      
      a += b; b += a;
      
      k[i-2] = a;
      k[i-1] = R(b, 23);
    }

    p += 4;

    for(i=0; i<4; i++) {
      *p = RS(mk->q[i]);
       p-= 2;
    }
    
    p += 2;
    
    for(i=0; i<256; i++) {
      x = H(ctx, i, p);
      sbox[256*0] = (x & 255);
      sbox[256*1] = (x >>  8) & 255;
      sbox[256*2] = (x >> 16) & 255;
      sbox[256*3] = (x >> 24) & 255;
    }
}

// 0b110101 01111100 11010011 11001110

uint32_t mds(uint32_t w) {
    w32_t acc, x;
    int i;
    uint32_t j, x0, y;

    uint8_t m[4][4] = { 
      { 0x01, 0xEF, 0x5B, 0x5B },
      { 0x5B, 0xEF, 0xEF, 0x01 },
      { 0xEF, 0x5B, 0x01, 0xEF },
      { 0xEF, 0x01, 0xEF, 0x5B } };

    x.w = w;
    acc.w = 0;

    for (i=0; i<4; i++) {
      for (j=0; j<4; j++) {
        x0 = m[i][j];
        y  = x.b[j];
        while (y) {
          if (x0 > (x0 ^ 0x169))
            x0 ^= 0x169;
          if (y & 1)
            acc.b[i] ^= x0;
          x0 <<= 1;
          y >>= 1;
        }
      }
    }
    return acc.w;
}

// The G function
uint32_t G(uint8_t *sbp, uint32_t w) {
    w32_t    x;
    uint32_t i;
    
    x.w = w;

    for (i=0; i<4; i++) {
      x.b[i] = sbp[x.b[i]];
      sbp += 256;
    }
    return mds(x.w);
}

// encrypt/decrypt 128-bits of data
// encryption which inlines F function
void twofish(void *mk, void *data) {
    int      i;
    uint32_t a, b, c, d, t0, t1, t;
    uint32_t *k, *x=(uint32_t*)data;
  
    
    // load 128-bits of plaintext
    a = x[0] ^ k[0]; b = x[1] ^ k[1];
    c = x[2] ^ k[2]; d = x[3] ^ k[3];
    
    // 16 rounds
    for (i=0; i<32; i+=2) {
      // G
      t0 = G(sbox, a);
      t1 = G(sbox, R(b, 24));
      // PHT
      t0 += t1; t1 += t0;
      // F
      c ^= t0 + k[i+4];
      c  = R(c, 1);
      d  = R(d, 31);
      d ^= t1 + k[i+5];
      // swap
      X(a, c); X(b, d);
    }

    // store 128-bits of ciphertext
    x[0] = c ^ k[4]; x[1] = d ^ k[5];
    x[2] = a ^ k[6]; x[3] = b ^ k[7];
}

