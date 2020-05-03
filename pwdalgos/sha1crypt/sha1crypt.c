
// SHA1Crypt password algorithm
// Odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>

#include <openssl/sha.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/bio.h>

#if defined (_WIN32) || defined (_WIN64)
#pragma comment (lib, "user32.lib")
#pragma comment (lib, "gdi32.lib")
#pragma comment (lib, "advapi32.lib")
#endif

#define MAGIC		"{ssha}"
#define MAGICLEN	6

#define SALT_MAXLEN	8
#define SALT_MINLEN	2

#define SALTLEN		(MAGICLEN + (((SALT_MAXLEN + 2) / 3) * 4))

char *Base64Encode (void *data, size_t data_len, char *out, size_t outlen)
{
  char *buf;
  long len;
  
  // Construct an OpenSSL ctx
  BIO *ctx = BIO_new (BIO_s_mem());

  // Tell the ctx to encode base64
  BIO *cmd = BIO_new (BIO_f_base64());
  ctx = BIO_push (cmd, ctx);

  // Encode all the data
  BIO_write (ctx, data, data_len);
  BIO_flush (ctx);

  // Get the data out of the ctx
  len = BIO_get_mem_data (ctx, &buf);
  memcpy (out, buf, outlen);
  
  BIO_free_all (ctx);

  return out;
}

size_t Base64Decode (void *in, size_t in_len, void *out, size_t outlen)
{
  uint8_t inbuf[256];
  size_t  bufsize=256, len, pos=0;
  BIO     *ctx, *cmd;
  
  uint8_t *input=(uint8_t*)in;
  uint8_t *output=(uint8_t*)out;
  
  // Construct an OpenSSL context
  cmd = BIO_new (BIO_f_base64());
  ctx = BIO_new_mem_buf (in, in_len);

  // Tell the context to encode base64
  ctx = BIO_push (cmd, ctx);
  
  while ((len = BIO_read (ctx, inbuf, bufsize)) > 0) {
    memcpy (&output[pos], inbuf, len);
    pos += len;
  }

  BIO_free_all (ctx);
  return pos;
}

char *sha1_gensalt (uint8_t n) 
{
  static char salt[SALTLEN + 1];
  uint8_t     seed[SALT_MAXLEN];

  if (n > SALT_MAXLEN) n = SALT_MAXLEN;
  if (n < SALT_MINLEN) n = SALT_MINLEN;

  if (RAND_bytes (seed, n) <= 0) 
  {
    printf ("RAND error: %s\n", ERR_error_string(ERR_get_error(), NULL));
    exit (1);
  }

  memcpy (salt, MAGIC, MAGICLEN);
  Base64Encode (seed, n, &salt[MAGICLEN], sizeof (salt) - MAGICLEN);
  return salt;
}

#define HASHLEN		(MAGICLEN + (((SHA_DIGEST_LENGTH + SALTLEN + 2) / 3) * 4))

char *sha1crypt(const char *password, const char *salt) 
{
    static char hash[HASHLEN + 1];

    SHA_CTX ctx;

    uint8_t final[SHA_DIGEST_LENGTH + SALT_MAXLEN + 2];
    uint8_t buffer[SALT_MAXLEN + 2];
    int m, n = strlen(password);

    if (strncmp(salt, MAGIC, MAGICLEN) != 0) {
      printf ("\n  invalid magic value");
      return NULL;
    }

    if (strlen(salt += MAGICLEN) > (((SALT_MAXLEN + 2) / 3) * 4)) {
      printf ("\n  invalid salt length");
      return NULL;
    }

    m = Base64Decode ((char *)salt, strlen (salt), buffer, sizeof (buffer));

    if ((m > SALT_MAXLEN) || (m < SALT_MINLEN)) {
      printf ("\n  invalid decoded salt %i", m);
      return NULL;
    }

    memset (hash, 0, sizeof hash);
    _snprintf (hash, sizeof(hash), "%s", MAGIC);

    SHA1_Init (&ctx);
    SHA1_Update (&ctx, password, n);
    SHA1_Update (&ctx, buffer, m);
    SHA1_Final (final, &ctx);

    memcpy (&final[SHA_DIGEST_LENGTH], buffer, m);
    Base64Encode (final, SHA_DIGEST_LENGTH + m, &hash[MAGICLEN], sizeof(hash) - MAGICLEN);
    memset (final, 0, sizeof(final));

    return hash;
}

char *sha1hash(const char *password, const int n) {
    return sha1crypt (password, sha1_gensalt (n));
}

int main (int argc, char *argv[])
{
  char salt[SALTLEN+1];
  
  if (argc < 2) {
    printf ("\n  usage: sha1crypt <password>\n");
    return 0;
  }
  if (argc==2) {
    printf ("\n  SHA1Crypt : %s", sha1hash (argv[1], SALT_MINLEN));
  } else {
    memset (salt, 0, sizeof salt);
    memcpy (salt, MAGIC, MAGICLEN);
    strncpy (&salt[MAGICLEN], argv[2], sizeof (salt) - MAGICLEN); 
    printf ("\n  SHA1Crypt : %s", sha1crypt (argv[1], salt));
  }
  return 0;
}
