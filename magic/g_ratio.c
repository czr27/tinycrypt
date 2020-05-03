

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#pragma intrinsic(fabs,pow,sin)

uint32_t golden_ratio(void) {
    uint32_t r;
    r = (uint32_t)(fabs((sqrt((double)5)-1)/2)*pow(2,32));
    return r;
}

uint32_t euler_number(void) {
    uint32_t r;
    r = (uint32_t)(fabs(exp((double)1)-2)*pow(2,32)+1);
    return r;
}

int main(void)
{
  printf ("\nEuler Number = %08X\n", euler_number());  
  printf ("\nGolden Ratio = %08X\n", golden_ratio());
  return 0;
}
