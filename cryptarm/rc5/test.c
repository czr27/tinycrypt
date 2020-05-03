

// RC5 test in C
// Odzhan

#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#include "rc5.h"

typedef struct _tv_t{
  uint8_t *k, *p, *c;
} tv_t;

uint8_t k1[16]=
{0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f};
uint8_t p1[8]={0x96,0x95,0x0d,0xda,0x65,0x4a,0x3d,0x62};
uint8_t c1[8]={0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77};

uint8_t k2[16]={0};
uint8_t p2[8]={0};
uint8_t c2[8]={0xae,0xda,0x56,0xa5,0x19,0x00,0x42,0xce};

tv_t tv[]={{k1,p1,c1},{k2,p2,c2}};

void bin2hex(char *s, void *p, int len) {
  int i;
  printf("%s : ", s);
  for (i=0; i<len; i++) {
    printf ("%02x ", ((uint8_t*)p)[i]);
  }
  printf("\n");
}

int main (int argc, char *argv[])
{
  int     i, e;
  uint8_t p[8];
  
  for (i=0; i<sizeof(tv)/sizeof(tv_t); i++){
    memcpy(p, tv[i].p, 8); 
    
    bin2hex("k", tv[i].k, 16);
    bin2hex("p", tv[i].p, 8);
    
    rc5(tv[i].k, p);
    
    bin2hex("c", p, 8);
    
    e=(memcmp(tv[i].c, p, 8)==0);

    printf ("RC5 encryption test #%i %s\n\n", 
      (i+1), e==0?"passed":"failed");
  }
  return 0;
}
