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

#include "../include/macros.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#ifdef TEST
void bin2hex(char s[], uint32_t p[], int r) {
  int i;
  printf("%-8s %i : ", s, r);
  for(i=0; i<4; i++) {
    printf("%08X ", p[i]);
  }
  printf("\n\n");
}
#endif

#define CyclicShiftPlane(A, dx, dz) \
  a0 = ROTR32(A[(0 - dx) & 3], dz); \
  a1 = ROTR32(A[(1 - dx) & 3], dz); \
  a2 = ROTR32(A[(2 - dx) & 3], dz); \
  a3 = ROTR32(A[(3 - dx) & 3], dz); \
  A[0] = a0; A[1] = a1; A[2] = a2; A[3] = a3; \

#define ShufflePlane(A, dx) \
  a0 = A[(0 - dx) & 3]; \
  a1 = A[(1 - dx) & 3]; \
  a2 = A[(2 - dx) & 3]; \
  a3 = A[(3 - dx) & 3]; \
  A[0] = a0; A[1] = a1; A[2] = a2; A[3] = a3; \
/**  
void shift(uint32_t A[3][4], int d) {
    uint32_t  *p=(uint32_t*)A[1];
    uint32_t  i, j, x, r;
    uint32_t  a[4];

    i = -1;
    r = 0x1500;
    x = 1;
    
    if (d) {
      i = 2;
      r = 0x181F;
      x = 0;
    }

    do {
      for (j=0; j<4; j++) {
        a[j] = ROTR32(p[(j - x) & 3], r & 0xFF); 
      }
      memcpy(p, a, 16);
      p += 4;
      x += i;
      r >>= 8;
    } while (r != 0); 
}*/

    uint16_t rc[12]=
    { 0x058, 0x038, 0x3c0, 0x0d0, 
      0x120, 0x014, 0x060, 0x02c, 
      0x380, 0x0f0, 0x1a0, 0x012 };
      
void xoodoo(void *state) {
    uint32_t e[4], a0, a1, a2, a3, t;
    int      i, x, y, j;
    uint32_t *p, *q;
    uint32_t (*A)[4] = (uint32_t(*)[4])state; 
    
    p=(uint32_t*)A[0];
      
    // 12 rounds by default
    for (i=0; i<12; i++) {
      // θ
      for (x=0; x<4; x++) {
        e[x] = ROTR32(p[x] ^ p[x+4] ^ p[x+8], 18);
        e[x]^= ROTR32(e[x], 9);
      }

      for (x=0; x<12; x++) {
        p[x] ^= e[(x - 1) & 3];
      }

      // ρ_west
      XCHG(p[7], p[4]);
      XCHG(p[7], p[5]);
      XCHG(p[7], p[6]);

      for (x=0; x<4; x++) {
        p[x+8] = ROTR32(p[x+8], 21); 
      }
  
      // ι
      p[0] ^= (uint32_t)rc[i];

      // χ
      for (x=0; x<4; x++) {
        a0 = p[x+0];
        a1 = p[x+4];
        a2 = p[x+8];

        p[x+0] ^= ~a1 & a2;        
        p[x+4] ^= ~a2 & a0;        
        p[x+8] ^= ~a0 & a1;                
      }

      // ******
      // ρ_east
      // ******
      for (x=0;x<4; x++) {       
        p[x+4] = ROTR32(p[x+4], 31); 
        p[x+8] = ROTR32(p[x+8], 24);
      } 
      XCHG(p[8], p[10]);
      XCHG(p[9], p[11]); 
    }
}

#ifdef TEST

// test vector
uint32_t xoodoo_tv[12]=
{ 0xfe04fab0, 0x42d5d8ce, 0x29c62ee7, 0x2a7ae5cf,
  0xea36eba3, 0x14649e0a, 0xfe12521b, 0xfe2eff69,
  0xf1826ca5, 0xfc4c41e0, 0x1597394f, 0xeb092faf };

int main(void)
{
    int     i, equ;
    uint8_t state[48];

    // initialize state
    memset(state, 0, 48);

    // apply permutation
    for (i=0; i<384; i++) {
      xoodoo(state);
    }

    // check if okay
    equ = memcmp(state, xoodoo_tv, sizeof(xoodoo_tv))==0;

    printf("XooDoo Test %s\n", equ ? "OK" : "FAILED");
    return 0;
}
#endif
