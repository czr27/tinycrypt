

// Microsoft SQL password algorithms (2000, 2005, 2012)
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/sha.h>

#define VERSION_LEN 2
#define SALT_LEN    4

// convert string to uppercase
void uppercase (char *out, char *in)
{
  size_t len=strlen (in);
  size_t i;
  
  for (i=0; i<len; i++) 
    out[i] = toupper (in[i]);
}

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

size_t init_entry (char *out, char *salt, uint8_t sbin, int version)
{
  size_t  salt_len=strlen (salt);
  int     i, idx=0;
  
  // exceeds maximum salt?
  if (salt_len > SALT_LEN) {
    salt_len = SALT_LEN;
    salt[salt_len] = 0;
  }
  // convert to binary
  salt_len=hex2bin (sbin, salt);
  
  // if less than max, 
  if (salt_len < SALT_LEN) {
    srand (time(0));
    while (salt_len++ < SALT_LEN) {
      sbin[salt_len] = rand() % 255;
    }
  }
  // add the version
  _snprintf (out, 4, "%02X%02X", version, 0);
  
  idx=strlen(out);
  
  // add the salt
  for (i=0; i<salt_len; i++) {
    _snprintf (&out[(idx+i)*2], 2, "%02X", salt[i]);
  }
  return strlen(out);
}

// MS SQL 2000
char *msql2k (char *pwd, char *salt) {
  static char sql2k[128];
  SHA_CTX ctx;
  char    uc[128];
  wchar_t wcs[128];
  uint8_t sbin[32], out[32];
  size_t  plen, slen;
  int     i, idx=0;
  
  idx=init_entry (sql2k, salt, sbin, 1);
  
  // convert to uppercase
  uppercase (uc, pwd);
  // convert password to Unicode
  plen=mbstowcs (wcs, uc, sizeof wcs);
  
  // hash with salt
  SHA1_Init (&ctx);
  SHA1_Update (&ctx, wcs, plen*2);
  SHA1_Update (&ctx, sbin, idx - VERSION_LEN);
  SHA1_Final (out, &ctx);
  
  // format to hex
  for (i=0; i<SHA_DIGEST_LENGTH; i++) {
    _snprintf (&sql2k[(idx+i)*2], 2, "%02X", out[i]);
  }
  return sql2k;
}

// MS SQL 2005
char *msql2k5 (char *pwd, char *salt)
{
  static char sql2k5[128];
  SHA_CTX ctx;
  char    uc[128];
  wchar_t wcs[128];
  uint8_t sbin[32], out[32];
  size_t  plen, slen;
  int     i, idx=0;
  
  idx=init_entry (sql2k5, salt, 1);
  
  // convert password to Unicode
  plen=mbstowcs (wcs, pwd, sizeof wcs);
  
  // hash with salt
  SHA1_Init (&ctx);
  SHA1_Update (&ctx, wcs, plen*2);
  SHA1_Update (&ctx, sbin, slen);
  SHA1_Final (out, &ctx);
  
  // format to hex
  idx+=SALT_LEN;
  for (i=0; i<SHA_DIGEST_LENGTH; i++) {
    _snprintf (&sql2k5[(idx+i)*2], 2, "%02X", out[i]);
  }
  return sql2k5;
}

// MS SQL 2012
char *msql2k12 (char *pwd, char *salt)
{
  static char sql2k12[SHA512_DIGEST_LENGTH*2+32];
  SHA512_CTX ctx;
  uint8_t    out[SHA512_DIGEST_LENGTH];
  uint8_t    sbin[4];
  size_t     salt_len, pwd_len;
  int        i, idx;
  wchar_t    wcs_pwd[128];
  
  idx=init_entry (sql2k12, salt, 2);
  
  // convert to unicode
  pwd_len=mbstowcs (wcs_pwd, pwd, 128);
  
  // get salt
  salt_len=hex2bin (sbin, salt);
  
  SHA512_Init (&ctx);
  SHA512_Update (&ctx, wcs_pwd, pwd_len*2);
  SHA512_Update (&ctx, sbin, salt_len);
  SHA512_Final (out, &ctx);
  
  idx+=SALT_LEN;
  for (i=0; i<SHA512_DIGEST_LENGTH; i++) {
    _snprintf (&sql2k12[(idx+i)*2], 2, "%02X", out[i]);
  }
  return sql2k12;
}

int main (int argc, char *argv[])
{
  char *pwd, *salt;
  
  if (argc != 3) {
    printf ("\n  usage: msql_pwd <password> <salt>\n");
    return 0;
  }
  
  pwd=argv[1];
  salt=argv[2];
  
  printf ("\nMS SQL 2000 : %s",   msql2k  (pwd, salt));
  printf ("\nMS SQL 2005 : %s",   msql2k5 (pwd, salt));
  printf ("\nMS SQL 2012 : %s\n", msql2k12(pwd, salt));
  
  return 0;
}
