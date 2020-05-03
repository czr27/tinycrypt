

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

#pragma intrinsic(fabs,pow,sin)

uint32_t sin2int (uint32_t i)
{
    uint32_t r;
    r = (uint32_t)(fabs(sin(i)*pow(2,32)));
    return r;
}

int main(void)
{
    int      i;
    uint32_t t[64];

    // create T constants
    for (i=0; i<64; i++) {
      t[i] = sin2int(i+1);
    }
    bin2hex("MD5 T constants", t, 64);  
    return 0;
}


