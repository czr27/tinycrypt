

// Oracle 10g password algorithm
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/des.h>

#define MAX_USERNAME 31
#define MAX_PASSWORD 31

uint8_t pwd_key[]={0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef};

int main (int argc, char *argv[])
{
  wchar_t          in[128];
  size_t           len, i, slen;
  uint8_t          out[32], iv[8];
  DES_key_schedule ks;
  
  if (argc != 3) {
    printf ("\n  usage: oracle_pwd <username> <password>\n");
    return 0;
  }
  memset (in, 0, sizeof in);
  memset (out, 0, sizeof out);
  
  slen=strlen (argv[1]);
  // convert the user name to Unicode      
  for (i=0, len=0; i<slen && i<MAX_USERNAME; i++) {
    in[len++] = (toupper (argv[1][i]) << 8);
  }
  
  slen=strlen (argv[2]);
  // convert the password to Unicode, appending to user name
  for (i=0; i<slen && i<MAX_PASSWORD; i++) {
    in[len++] = (toupper (argv[2][i]) << 8);
  }

  len <<= 1;

  memset (iv, 0, sizeof iv);
  DES_set_key ((DES_cblock*)pwd_key, &ks);
  DES_ncbc_encrypt ((uint8_t*)in, out, len, &ks, &iv, DES_ENCRYPT);

  DES_set_key ((DES_cblock*)iv, &ks);
  memset (iv, 0, sizeof iv);
  DES_ncbc_encrypt ((uint8_t*)in, out, len, &ks, &iv, DES_ENCRYPT);

  for (i=0; i<8; i++) {
    printf ("%02X", iv[i]);
  }
  return 0;  
}
    