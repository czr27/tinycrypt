

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

// Modular exponentiation
int powmod (int b, int e, int m)
{
    int r = 1;
    
    while (e > 0) {
      if (e & 1) {
        r = r * b % m;
      }
      b = b * b % m;
      e >>= 1;
    }
    return r;
}

int main(void)
{  
    int      x, i;
    uint8_t  s0[256], s1[256];

    // create sbox
    for (x=0; x<256; x++) {
      s0[x] = powmod(45, x, 257) % 256;            
    }
    // create inverse sbox
    for (i=0; i<256; i++) {
      s1[s0[i]] = i;
    }
    bin2hex("SAFER sbox", s0, 256);
    bin2hex("SAFER inverse sbox", s1, 256);   
    return 0;
}
