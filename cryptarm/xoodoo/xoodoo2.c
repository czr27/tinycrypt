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

#include "include/macros.h"

#define memset(x,y,z) __stosb(x,y,z)

// state buffer and round constants
typedef struct _xoodoo_ctx {
  union {
    uint8_t  b[48];
    uint32_t w[12];    
    uint32_t m[3][4];
  } s;
  uint8_t  rc_s[6], rc_p[7];
} xoodoo_ctx;

#define CyclicShiftLane(a, dz) ((a >> (32 - (dz % 32))) | (a << (dz % 32))) % (1 << 32)

#define ReduceX(x) ((x % 4) + 4) % 4
#define ReduceZ(z) ((z % 32) + 32) % 32

void xoodoo_init(xoodoo_ctx *c) {
    uint8_t s, p;
    int     i;
    
    // zero initialize state
    memset(c->s.b, 0, 48);
#ifdef RC    
    s = p = 1;
    
    // initialize s round constants
    for (i=0; i<6; i++) {
      c->rc_s[i] = s;
      s = (s * 5) % 7;
    }
    
    // initialize p round constants
    for (i=0; i<7; i++) {
      c->rc_p[i] = p;
      p ^= (p << 2);
      
      if (p & 0x10) p ^= 0x16; 
      if (p & 0x08) p ^= 0x0B; 
    }
#endif    
}

void CyclicShiftPlane(uint32_t A[4], int dx, int dz) {
    int      i, index;
    uint32_t p[4];
    
    for (i=0; i<4; i++) {
      index = ReduceX(i - dx);
      p[i] = ROTL32(A[index], ReduceZ(dz));
    }
    memcpy(A, p, sizeof(p));
}

void Round(xoodoo_ctx *c, uint32_t i) {
    uint32_t P[4], E[4], B[3][4];
    uint32_t x, y, rc;

    uint8_t rc_s[7]={0x01, 0x05, 0x04, 0x06, 0x02, 0x03};    
    uint8_t rc_p[7]={0x01, 0x05, 0x07, 0x06, 0x03, 0x04, 0x02};
    
    uint32_t (*A)[4] = c->s.m;
    
    // θ
    // P = A[0] ^ A[1] ^ A[2]    
    for (x=0; x<4; x++) {
      P[x] = A[0][x] ^ A[1][x] ^ A[2][x];
    }

    // E = CyclicShiftPlane(P, 1, 5) ^ CyclicShiftPlane(P, 1, 14)    
    // for y in range(3): A[y] = A[y] ^ E
    for (y=0; y<3; y++) {
      for (x=0; x<4; x++) {
        A[y][x] ^= ROTL32(P[ReduceX(x - 1)], ReduceZ( 5));
        A[y][x] ^= ROTL32(P[ReduceX(x - 1)], ReduceZ(14));
      }
    }        
    
    // ρ_west
    // A[1] = CyclicShiftPlane(A[1], 1, 0)
    // A[2] = CyclicShiftPlane(A[2], 0, 11)
    CyclicShiftPlane(A[1], 1,  0);
    CyclicShiftPlane(A[2], 0, 11);
    
    // ι
    // rc = (self.rc_p[-i % 7] ^ 0x08) << self.rc_s[-i % 6]
    // A[0][0] = A[0][0] ^ rc
    rc = (rc_p[-i % 7] ^ 0x08) << rc_s[-i % 6];
    A[0][0] ^= rc;
    
    // χ
    // B = State()
    // B[0] = ~A[1] & A[2]
    // B[1] = ~A[2] & A[0]
    // B[2] = ~A[0] & A[1]
    for (x=0; x<4; x++) {
      B[0][x] = ~A[1][x] & A[2][x];
      B[1][x] = ~A[2][x] & A[0][x];
      B[2][x] = ~A[0][x] & A[1][x];
    }
        
    // for y in range(3): A[y] = A[y] ^ B[y]
    for (y=0; y<3; y++) {
      for (x=0; x<4; x++) {
        A[y][x] ^= B[y][x];
      }
    }
    
    // ******
    // ρ_east
    // ******
    // A[1] = CyclicShiftPlane(A[1], 0, 1)   
    // A[2] = CyclicShiftPlane(A[2], 2, 8)
    CyclicShiftPlane(A[1], 0, 1);    
    CyclicShiftPlane(A[2], 2, 8);    
}

void xoodoo_perm(xoodoo_ctx *c, uint32_t r) {
    int i; // must be signed
    
    for (i=(1-r); i<1; i++) {
      Round(c, i);
    }
}
  
#ifdef TEST 

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
 
uint32_t xoodoo_tv[12]=
{ 0xfe04fab0, 0x42d5d8ce, 0x29c62ee7, 0x2a7ae5cf, 
  0xea36eba3, 0x14649e0a, 0xfe12521b, 0xfe2eff69, 
  0xf1826ca5, 0xfc4c41e0, 0x1597394f, 0xeb092faf };
  
int main(void) 
{
    int        i, equ;
    xoodoo_ctx c;
    
    // initialize context
    xoodoo_init(&c);
    
    // apply permutation
    for (i=0; i<384; i++) {
      xoodoo_perm(&c, 12);
    }
    
    // check if okay
    equ = memcmp(c.s.b, xoodoo_tv, sizeof(xoodoo_tv))==0;
    
    printf("XooDoo Test %s\n", equ ? "OK" : "FAILED");
    return 0;
}
#endif
