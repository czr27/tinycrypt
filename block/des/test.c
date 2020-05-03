
// test unit for DES
// odzhan

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

// 64-bit master key (only 56-bits are used)
uint8_t key[8]=
{0x4d, 0x1b, 0xec, 0x52, 0xf7, 0xfc, 0xcc, 0x95};

// 64-bit plain text
uint8_t plain[8]=
{0x24, 0x49, 0x3d, 0x8f, 0xae, 0x11, 0x7a, 0x0b};

// 64-bit cipher text
uint8_t cipher[8]=
{0x84, 0x08, 0x4a, 0x0c, 0xaf, 0x81, 0x13, 0x90};

void des_set_key(void *key, void *ks);
void des_enc(void *data, void *ks);

int main(void) {
    uint8_t data[8], ks[128];
    int     i, equ;
    
    // set master key
    memcpy(data, key, 8);
    
    for(i=0;i<256;i++) {
      // initialize subkeys
      des_set_key(data, ks);
      // encrypt plaintext
      memcpy(data, plain, 8);
      des_enc(data, ks);
    }
    equ=(memcmp(data, cipher, 8)==0);
    printf("DES test : %s\n", equ ? "OK" : "FAILED");
}
