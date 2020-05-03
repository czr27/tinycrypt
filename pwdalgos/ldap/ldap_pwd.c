

// LDAP password algorithms, RFC2307 Standard
// Odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>

#include <openssl/sha.h>
#include <openssl/md5.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/bio.h>

#if defined (_WIN32) || defined (_WIN64)
#pragma comment (lib, "user32.lib")
#pragma comment (lib, "gdi32.lib")
#pragma comment (lib, "advapi32.lib")
#endif

#define MIN_SALT_LEN  4
#define MAX_SALT_LEN 16

BIO *ctx, *cmd;

void B64_Open (void)
{
  // Construct an OpenSSL ctx
  ctx = BIO_new (BIO_s_mem());

  // Tell the ctx to encode base64
  cmd = BIO_new (BIO_f_base64());
  BIO_set_flags (cmd, BIO_FLAGS_BASE64_NO_NL);
  ctx = BIO_push (cmd, ctx);  
}

void B64_Close (void)
{
  BIO_free_all (ctx);
}

size_t B64_Encode (void *data, size_t data_len, 
  char *out, size_t outlen, int flush)
{
  char *buf;
  long len;
  
  // Encode all the data
  BIO_write (ctx, data, data_len);
  
  if (flush) BIO_flush (cmd);
  
  // Get the data out of the ctx
  len = BIO_get_mem_data (ctx, &buf);
  if (out != NULL) {
    memcpy (out, buf, len);
  }
  return len;
}

char *ldap_smd5_pwd (char *pwd, uint8_t *salt, size_t salt_len)
{
  MD5_CTX     ctx;
  uint8_t     out[MD5_DIGEST_LENGTH];
  static char r[MD5_DIGEST_LENGTH*2+64];

  memset (r, 0, sizeof r);
  
  B64_Open();
  
  MD5_Init (&ctx);
  MD5_Update (&ctx, pwd, strlen (pwd));
  MD5_Update (&ctx, salt, salt_len);
  MD5_Final (out, &ctx);
  
  B64_Encode (out, MD5_DIGEST_LENGTH, NULL, 0, FALSE);
  B64_Encode (salt, salt_len, r, sizeof r, TRUE);
  
  B64_Close();
  return r;
}

char *ldap_md5_pwd (char *pwd)
{
  MD5_CTX     ctx;
  uint8_t     out[MD5_DIGEST_LENGTH];
  static char r[MD5_DIGEST_LENGTH*2+64];
  
  memset (r, 0, sizeof r);
  
  B64_Open();
  
  MD5_Init (&ctx);
  MD5_Update (&ctx, pwd, strlen (pwd));
  MD5_Final (out, &ctx);
  
  B64_Encode (out, MD5_DIGEST_LENGTH, r, sizeof r, TRUE);
  B64_Close();
  return r;
}

char *ldap_ssha_pwd (char *pwd, uint8_t *salt, size_t salt_len)
{
  SHA_CTX     ctx;
  uint8_t     out[SHA_DIGEST_LENGTH];
  static char r[SHA_DIGEST_LENGTH*2+64];
  int         i;
  size_t      slen;
  
  memset (r, 0, sizeof r);
  
  // base64 encode the salt
  B64_Open();

  SHA1_Init (&ctx);
  SHA1_Update (&ctx, pwd, strlen (pwd));
  SHA1_Update (&ctx, salt, salt_len);
  SHA1_Final (out, &ctx);
  
  B64_Encode (out, SHA_DIGEST_LENGTH, NULL, 0, FALSE);
  B64_Encode (salt, salt_len, r, sizeof (r), TRUE);
  
  B64_Close();
  return r;
}

char *ldap_sha1_pwd (char *pwd)
{
  SHA_CTX     ctx;
  uint8_t     out[MD5_DIGEST_LENGTH];
  static char r[SHA_DIGEST_LENGTH*2+64];
  
  memset (r, 0, sizeof r);
  
  B64_Open();
  
  SHA1_Init (&ctx);
  SHA1_Update (&ctx, pwd, strlen (pwd));
  SHA1_Final (out, &ctx);
  
  B64_Encode (out, SHA_DIGEST_LENGTH, r, sizeof r, TRUE);
  B64_Close();
  return r;
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

int main (int argc, char *argv[])
{
  char    *pwd;
  uint8_t salt[MAX_SALT_LEN];
  size_t  salt_len=0;
  
  memset (salt, 0, sizeof salt);
  srand (time(0));
  
  if (argc < 2) {
    printf ("\n  usage: ldap_pwd <password> <salt in hex>\n");
    return 0;
  }
  pwd=argv[1];
  if (argc==3) {
    salt_len=hex2bin (salt, argv[2]);
  } else {
    while (salt_len < MIN_SALT_LEN) {
      salt[salt_len++] = (uint8_t)rand() % 255;
    }
  }

  printf ("\n  LDAP MD5   : {MD5}%s",    ldap_md5_pwd (pwd));
  printf ("\n  LDAP SHA1  : {SHA}%s",    ldap_sha1_pwd (pwd));
  printf ("\n  LDAP SMD5  : {SMD5}%s",   ldap_smd5_pwd (pwd, salt, salt_len));
  printf ("\n  LDAP SSHA1 : {SSHA}%s\n", ldap_ssha_pwd (pwd, salt, salt_len));
  
  return 0;
}
