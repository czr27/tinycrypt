

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

void bin2hex(const char *s, uint32_t x[], int len) {
    int i;
    printf ("\n // %s", s);
    for (i=0; i<len; i++) {
      if ((i & 3)==0) putchar('\n');
      printf (" 0x%08x,", x[i]);
    }
    putchar('\n');
}

#pragma intrinsic(fabs,pow,sqrt)

uint32_t p[64] =
{  2,   3,   5,   7,  11,  13,  17,  19, 
  23,  29,  31,  37,  41,  43,  47,  53,
  59,  61,  67,  71,  73,  79,  83,  89, 
  97, 101, 103, 107, 109, 113, 127, 131,
 137, 139, 149, 151, 157, 163, 167, 173, 
 179, 181, 191, 193, 197, 199, 211, 223,
 227, 229, 233, 239, 241, 251, 257, 263, 
 269, 271, 277, 281, 283, 293, 307, 311 };

// square root of integer, return fractional part as integer
uint32_t sqrt2int (uint32_t x) {
    uint32_t r;
    r = (uint32_t)(fabs(sqrt((double)p[x]))*pow(2,32));
    return r;
}

// cube root of integer, return fractional part as integer
uint32_t cbr2int (uint32_t x) {
    uint32_t r;
    r = (uint32_t)(fabs(pow((double)p[x],1.0/3.0))*pow(2,32));
    return r;
}

int main(void)
{
    int      i;
    uint32_t h[8], k[64];
    
    // create H constants
    for (i=0; i<8; i++) {
      h[i] = sqrt2int(i);
    }
    bin2hex("SHA-256 H constants", h, 8);
    
    // create K constants
    for (i=0; i<64; i++) {
      k[i] = cbr2int(i);
    }
    bin2hex("SHA-256 K constants", k, 64);  
    return 0;
}
