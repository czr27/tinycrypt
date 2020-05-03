
// monte carlo test for AES-128 and AES-256 in ECB mode
// odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "aes.h"

// 128-bit or 256-bit?
#if AES_KEY_LEN == 32
  uint8_t cipher[16]=
  {0x1F, 0x67, 0x63, 0xDF, 0x80, 0x7A, 0x7E, 0x70,
   0x96, 0x0D, 0x4C, 0xD3, 0x11, 0x8E, 0x60, 0x1A };
 
#else
  uint8_t cipher[16]=
  {0xa0, 0x43, 0x77, 0xab, 0xe2, 0x59, 0xb0, 0xd0, 
   0xb5, 0xba, 0x2d, 0x40, 0xa5, 0x01, 0x97, 0x1b };
#endif

void E(void*);

void aes(void *mk, void *data) {
    uint8_t ctx[K_LEN+16];
    
    memcpy(ctx, data, 16);
    memcpy(&ctx[16], mk, K_LEN);
    
    E(&ctx);
    
    memcpy(data, ctx, 16);
}

void bin2hex(int iter, void *bin, int len) {
    int     i;
    uint8_t *p=bin;
    
    printf("I=%i : ", iter);
    for(i=0;i<16;i++) printf("%02x", p[i]);
    putchar('\n');
}

int main(void) {
    uint8_t key[K_LEN], data[32];
    int     i, j, equ;
    
    memset(key, 0, sizeof(key));
    memset(data,  0, sizeof(data));
    
    for(i=0;i<400;i++) {
      for(j=0;j<10000;j++) {
        #ifdef AES256
          memcpy(&data[16], data, 16);
        #endif
        aes(key, data);
      }
      #ifdef AES256
        for(j=0;j<16;j++) key[j] ^= data[j+16];
        for(j=0;j<16;j++) key[j+16] ^= data[j];
      #else
        for(j=0;j<16;j++) key[j] ^= data[j];
      #endif
    }
    equ = (memcmp(data, cipher, 16)==0);
    
    printf("AES-%i monte carlo test : %s\n",
      K_LEN*8, equ ? "OK" : "FAILED");
}
        
