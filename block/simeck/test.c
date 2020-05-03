

// test unit for SIMECK-64/128
// odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>

// 128-bit master key
uint8_t key[16]=
{0x00, 0x01, 0x02, 0x03, 0x08, 0x09, 0x0a, 0x0b,
 0x10, 0x11, 0x12, 0x13, 0x18, 0x19, 0x1a, 0x1b};
 
// 64-bit plain text
uint8_t plain[8]=
{0x75, 0x6e, 0x64, 0x20, 0x6c, 0x69, 0x6b, 0x65};

// 64-bit cipher text
uint8_t cipher[8]=
{0xed, 0xb7, 0x7a, 0x5f, 0x02, 0x69, 0xce, 0x45};

void simeck(void *mk, void *data);

int main(void){
    uint8_t data[8];
    int     equ;

    memcpy(data, plain, 8);
    simeck(key, data);
    equ = (memcmp(cipher, data, 8) == 0);
    printf("SIMECK test : %s\n", equ ? "OK" : "FAILED");
    return 0;
}
