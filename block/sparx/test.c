
#include <stdio.h>
#include <string.h>

#include "sparx.h"

void print_bytes(char *s, void *p, int len) {
  int i;
  
  printf("%s : ", s);
  
  for (i=0; i<len; i++) {
    printf ("%04x ", ((uint16_t*)p)[i]);
  }
  putchar('\n');
}

uint16_t key[]=
{ 0x0011, 0x2233, 0x4455, 0x6677, 
  0x8899, 0xaabb, 0xccdd, 0xeeff,
  0xffee, 0xddcc, 0xbbaa, 0x9988, 
  0x7766, 0x5544, 0x3322, 0x1100 };

uint16_t plain[]=
{ 0x0123, 0x4567, 0x89ab, 0xcdef,
  0xfedc, 0xba98, 0x7654, 0x3210 };
  
uint16_t cipher[]=
{ 0x3328, 0xe637, 0x14c7, 0x6ce6,
  0x32d1, 0x5a54, 0xe4b0, 0xc820 };
  
int main(int argc, char *argv[])
{
  uint16_t subkeys[40+1][8] = {{0}};
  int      equ;
  
  print_bytes("PT", plain, 8);
  print_bytes("CT", cipher, 8);
  
  sparx_setkey(subkeys, key);  
  sparx_encrypt(plain, subkeys);
  
  equ = memcmp(plain, cipher, 16)==0;  
  
  printf ("\nEncryption : %s : ",
      equ ? "OK" : "FAILED"); 
      
  print_bytes("CT", plain, 8);
  
  return 0;
}

