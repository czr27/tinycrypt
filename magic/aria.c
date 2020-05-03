

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

void bin2hex(const char *s, uint8_t x[], int len) {
    int i;
    printf ("\n // %s", s);
    for (i=0; i<len; i++) {
      if ((i & 7)==0) putchar('\n');
      printf (" 0x%02x,", x[i]);
    }
    putchar('\n');
}

// matrix used for s-box 1 generation in aria
uint8_t A[8][8] = {
    {1,0,0,0,1,1,1,1}, 
    {1,1,0,0,0,1,1,1},
    {1,1,1,0,0,0,1,1},
    {1,1,1,1,0,0,0,1},
    {1,1,1,1,1,0,0,0},
    {0,1,1,1,1,1,0,0},
    {0,0,1,1,1,1,1,0}, 
    {0,0,0,1,1,1,1,1}, 
};

// matrix used for s-box 2 generation in aria
uint8_t B[8][8] = {
    {0,1,0,1,1,1,1,0}, 
    {0,0,1,1,1,1,0,1},
    {1,1,0,1,0,1,1,1},
    {1,0,0,1,1,1,0,1},
    {0,0,1,0,1,1,0,0},
    {1,0,0,0,0,0,0,1},
    {0,1,0,1,1,1,0,1}, 
    {1,1,0,1,0,0,1,1}, 
};

// Multiplication
uint8_t gf_mul(uint8_t x, uint8_t y, uint8_t p)
{
    uint8_t z = 0;

    while (y) {
      if (y & 1) {
        z ^= x;
      }
      x = (x << 1) ^ (x & 0x80 ? p : 0x00);
      y >>= 1;
    }
    return z;
}

// Exponentiation
uint8_t gf_exp(uint8_t b, uint8_t e, uint8_t p)
{
    uint8_t r = 1;
    uint8_t t = b;
    
    while (e > 0) {
      if (e & 1) {
        r = gf_mul(r, t, p);
      }
      t = gf_mul(t, t, p);
      e >>= 1;
    }
    return r;
}

uint8_t matmul8(uint8_t m[8][8], uint8_t x)
{
    int i, j;
    uint8_t y;
    
    y = 0;
    for (i = 0; i < 8; i++) {	
      if (x & (1 << i)) {
        for (j = 0; j < 8; j++)
          y ^= m[j][i] << j;
      }
    }	
    return y;
}

// modular inverse
uint8_t gf_inv(uint8_t a) {
    uint8_t j, b = a;
    for (j = 14; --j;)
        b = gf_mul(b, j & 1 ? b : a, 0x1b); 
    return b;
}

int main(void) 
{
    int     i, p, x;
    uint8_t s1[256], s1_inv[256], s2[256], s2_inv[256];

    for (x=0; x<256; x++) {
      // generate s-box 1 
      s1[x] = matmul8(A, gf_inv(x)) ^ 0x63; 
      // generate s-box 2
      s2[x] = matmul8(B, gf_exp(x, 247, 0x1b)) ^ 0xE2; 
    }
    for (i=0; i<256; i++) {
      s1_inv[s1[i]] = i;
      s2_inv[s2[i]] = i;
    }    
    bin2hex("ARIA s1", s1, 256);    
    bin2hex("ARIA inverse s1", s1_inv, 256);    
    
    bin2hex("ARIA s2", s2, 256);    
    bin2hex("ARIA inverse s2", s2_inv, 256);    
    return 0;
}
