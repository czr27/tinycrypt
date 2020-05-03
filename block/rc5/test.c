

// RC5 test in C
// Odzhan

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

// 128-bit master key
uint8_t key[16]={
  0x1b,0xec,0x52,0xf7,0xfc,0xcc,0x95,0x24,
  0x49,0x3d,0x8f,0xae,0x11,0x7a,0x0b,0xc8 };
  
// 64-bit plain text
uint8_t plain[8]={
  0x4d,0xbf,0x44,0xc6,0xb1,0xbe,0x73,0x6e };
  
// 64-bit cipher text
uint8_t cipher[8]={
  0x02, 0xb5, 0xd6, 0x01, 0x24, 0x1f, 0xc6, 0x2b };
  
void rc5(void *mk, void *data);

int main(void) {
    int     equ;
    uint8_t data[8];
    
    memcpy(data, plain, 8);
    rc5(key, data);
    equ = (memcmp(cipher, data, 8)==0);
    printf("RC5 test : %s\n", equ ? "OK" : "FAILED");
    return 0;
}
