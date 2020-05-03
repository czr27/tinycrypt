
// test unit for CHAM cipher
// odzhan

#include "cham.h"

#include <stdio.h>

void print_bytes(char *s, void *p, int len) {
  int i;
  printf("%s : ", s);
  for (i=0; i<len; i++) {
    printf ("%02x ", ((uint8_t*)p)[i]);
  }
  printf("\n\n");
}

int main(void)
{
  uint32_t key[4]   = {0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c};
  uint32_t plain[4] = {0x33221100, 0x77665544, 0xbbaa9988, 0xffeeddcc};
  uint32_t cipher[4]= {0xc3746034, 0xb55700c5, 0x8d64ec32, 0x489332f7};  
  
  uint32_t buf[4];
  int      equ;
  
  printf("\nCHAM128/128 Test\n\n");
  
  memcpy(buf, plain, 16);
  cham(key, buf);
  
  equ = memcmp(buf, cipher, 16)==0;
  printf("Encryption %s\n", equ ? "OK" : "FAILED");
  
  return 0;
} 
