#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define ROUND 22
#define K 64
#define N 32
#define R 80
#define W 8
#define KW K/W

//---------------------------------------------//
// cipher      |   n     k     r     w    k/w  //
//---------------------------------------------//
//											   //
// CHAM-32/64  |   32    64    80    8     8   //
//											   //
//---------------------------------------------//

uint8_t ROL(uint8_t , int );
uint8_t ROR(uint8_t, int);
int Power();
void Setkey(void*, void*);
void Encryption(void*, void*, void*);
void Decryption(void*, void*, void*);