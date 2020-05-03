

// Microsoft Lanman password algorithm
// Odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef _MSC_VER
#include <windows.h>
#endif

#include <openssl/des.h>

#if defined (_WIN32) || defined (_WIN64)
#pragma comment (lib, "user32.lib")
#pragma comment (lib, "gdi32.lib")
#pragma comment (lib, "advapi32.lib")
#endif

#define MAX_PWD 14

void DES_str_to_key (char str[], uint8_t key[]) 
{
  int i;

  key[0] = str[0] >> 1;
  key[1] = ((str[0] & 0x01) << 6) | (str[1] >> 2);
  key[2] = ((str[1] & 0x03) << 5) | (str[2] >> 3);
  key[3] = ((str[2] & 0x07) << 4) | (str[3] >> 4);
  key[4] = ((str[3] & 0x0F) << 3) | (str[4] >> 5);
  key[5] = ((str[4] & 0x1F) << 2) | (str[5] >> 6);
  key[6] = ((str[5] & 0x3F) << 1) | (str[6] >> 7);
  key[7] = str[6] & 0x7F;

  for (i = 0;i < 8;i++) {
      key[i] = (key[i] << 1);
  }
  DES_set_odd_parity ((DES_cblock*)key);
}

char* lm (char *pwd) 
{
  DES_cblock       key1, key2;
  DES_key_schedule ks1, ks2;
  const char       ptext[]="KGS!@#$%";
  static char      hash[8+1];
  uint8_t          pw[MAX_PWD+1], ctext[16];
  int              i;
  
  memset (pw, 0, sizeof (pw));
  strncpy (pw, pwd, MAX_PWD);
  CharToOem (CharUpper (pw), pw);

  DES_str_to_key (&pw[0], (uint8_t*)&key1);
  DES_str_to_key (&pw[7], (uint8_t*)&key2);
  
  DES_set_key (&key1, &ks1);
  DES_set_key (&key2, &ks2);
  
  DES_ecb_encrypt ((const_DES_cblock*)ptext, 
    (DES_cblock*)&ctext[0], &ks1, DES_ENCRYPT);
    
  DES_ecb_encrypt ((const_DES_cblock*)ptext, 
    (DES_cblock*)&ctext[8], &ks2, DES_ENCRYPT);

  for (i=0; i<16; i++) {
    _snprintf (&hash[i*2], 2, "%02X", ((uint8_t*)ctext)[i]);
  }
  return hash;
}

int main (int argc, char *argv[]) 
{
  char *pwd;
  
  if (argc != 2) {
    printf ("\n  usage: lm <password>\n");
    return 0;
  }
  pwd=argv[1];
  
  printf ("\n  Microsoft Lanman : %s\n", lm (pwd));
  return 0;
}
