
// test unit for kuznyechik ripped from markku's code
// odzhan

#include <stdio.h>
#include <time.h>
#include "kuznyechik.h"

void bin2hex(uint8_t *x) {
    int i;
    
    for (i = 0; i < 16; i++)
      printf(" %02X", x[i]);
    printf("\n");
}

void kuznyechik(const void*,void*);

int main(int argc, char **argv) {	
    const uint8_t testvec_key[32] = {
      0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 
      0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 
      0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10, 
      0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF	
    };
    const uint8_t testvec_pt[16] = {
      0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x00, 
      0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99, 0x88
    };
    const uint8_t testvec_ct[16] = { 
      0x7F, 0x67, 0x9D, 0x90, 0xBE, 0xBC, 0x24, 0x30, 
      0x5A, 0x46, 0x8D, 0x42, 0xB9, 0xD4, 0xED, 0xCD
    };
    
    int     i;
    uint8_t buf[16];

    printf("Self-test:\n");		

    for(i=0; i<16; i++)
      buf[i] = testvec_pt[i];
    printf("PT\t=");
    bin2hex(buf);

    kuznyechik(testvec_key, buf);

    printf("CT\t=");
    bin2hex(buf);

    for(i=0; i<16; i++) {
      if(testvec_ct[i]!=buf[i]) {
        fprintf(stderr, "Encryption self-test failure.\n");
        return -1;
      }
    }
    printf("Selt-test OK!\n");
    return 0;
}


