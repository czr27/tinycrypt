

// Oracle 10 and 11 password algorithms
// Odzhan

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include <openssl/sha.h>
#include <openssl/des.h>

#define MAX_USERNAME 31
#define MAX_PASSWORD 31

uint8_t pwd_key[]={0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef};

// convert hexadecimal string to binary
size_t hex2bin (void *bin, char hex[]) {
  size_t  len, i;
  int     x;
  uint8_t *p=(uint8_t*)bin;
  
  len = strlen (hex);
  
  if ((len & 1) != 0) {
    return 0; 
  }
  
  for (i=0; i<len; i++) {
    if (isxdigit((int)hex[i]) == 0) {
      return 0; 
    }
  }
  
  for (i=0; i<len / 2; i++) {
    sscanf (&hex[i * 2], "%2x", &x);
    p[i] = (uint8_t)x;
  } 
  return len / 2;
}

// create password hash for oracle 10
char *oracle10_pwd (char *pwd, char *id)
{
  wchar_t          in[128];
  size_t           len, i, slen;
  uint8_t          out[32], iv[8];
  DES_key_schedule ks;
  static char      pwd10[8+1];
  
  memset (in, 0, sizeof in);
  memset (out, 0, sizeof out);
  
  slen=strlen (id);
  // convert the user name to Unicode big endian     
  for (i=0, len=0; i<slen && i<MAX_USERNAME; i++) {
    in[len++] = (toupper (id[i]) << 8);
  }
  
  slen=strlen (pwd);
  // convert the password to Unicode, appending to user name
  for (i=0; i<slen && i<MAX_PASSWORD; i++) {
    in[len++] = (toupper (pwd[i]) << 8);
  }

  len <<= 1;

  memset (iv, 0, sizeof iv);
  DES_set_key ((DES_cblock*)pwd_key, &ks);
  DES_ncbc_encrypt ((uint8_t*)in, out, len, &ks, &iv, DES_ENCRYPT);

  DES_set_key ((DES_cblock*)iv, &ks);
  memset (iv, 0, sizeof iv);
  DES_ncbc_encrypt ((uint8_t*)in, out, len, &ks, &iv, DES_ENCRYPT);

  for (i=0; i<8; i++) {
    _snprintf (&pwd10[i*2], 2, "%02X", iv[i]);
  }
  return pwd10;
}

char *oracle11_pwd (char *pwd, uint8_t *salt)
{
  size_t      i, slen;
  SHA_CTX     ctx;
  uint8_t     sbin[128], out[SHA_DIGEST_LENGTH];
  static char pwd11[32];
  
  slen=hex2bin (sbin, salt);
  
  SHA1_Init (&ctx);
  SHA1_Update (&ctx, pwd, strlen (pwd));
  SHA1_Update (&ctx, sbin, slen);
  SHA1_Final (out, &ctx);

  for (i=0; i<SHA_DIGEST_LENGTH; i++) {
    _snprintf (&pwd11[i*2], 2, "%02X", out[i]);
  }
  return pwd11;
}

int main (int argc, char *argv[])
{
  char *id, *pwd, *salt;
  
  if (argc != 3) {
    printf ("\n  usage: oracle_pwd <password> <salt | user name>\n");
    return 0;
  }
  pwd=argv[1];
  id=argv[2];
  salt=argv[2];
  
  printf ("\n  Oracle 10 : %s",   oracle10_pwd (pwd, id));
  printf ("\n  Oracle 11 : %s\n", oracle11_pwd (pwd, salt));
  return 0;
}
