

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

// matrix used for s-box 1 generation in seed
uint8_t A1[8][8] = {
    {1,0,0,0,1,0,1,0},
    {1,1,1,1,1,1,1,0},
    {1,0,0,0,0,1,0,1},
    {0,1,0,0,0,0,1,0},
    {0,1,0,0,0,1,0,1},
    {0,0,1,0,0,0,0,1},
    {1,0,0,0,1,0,0,0}, 
    {0,0,0,1,0,1,0,0}, 
};

// matrix used for s-box 2 generation in seed
uint8_t A2[8][8] = {
    {0,1,0,0,0,1,0,1},
    {1,0,0,0,0,1,0,1},
    {1,1,1,1,1,1,1,0},
    {0,0,1,0,0,0,0,1},
    {1,0,0,0,1,0,1,0},
    {1,0,0,0,1,0,0,0},
    {0,1,0,0,0,0,1,0},
    {0,0,0,1,0,1,0,0},
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

// Matrix Multiplcation
uint8_t matmul(uint8_t mat[8][8], uint8_t a) {
    uint8_t res = 0;
    int     x, y;
    
    for (x = 0; x < 8; x++) {
      if (a & (1 << (7 - x))) {
        for (y = 0; y < 8; y++) {
          res ^= mat[y][x] << (7 - y);
        }
      }
    }
    return res;
}

int main(void)
{  
    int      x, i;
    uint8_t  s0[256], s1[256];
    uint32_t g = 0x9e3779b9;
       
    for (x=0; x<256; x++) {
      s0[x] = matmul(A1, gf_exp(x, 247, 99)) ^ 169;
      s1[x] = matmul(A2, gf_exp(x, 251, 99)) ^ 56;      
    }

    bin2hex("SEED sbox", s0, 256);
    bin2hex("SEED inverse sbox", s1, 256);

    printf ("\n // SEED constants");
    
    for (i=0; i<16; i++) {
      if ((i & 1)==0) putchar('\n');
      printf (" 0x%08x, ", g);
      g = (g << 1) | (g >> 32-1);
    }
    putchar('\n');    
    return 0;
}
