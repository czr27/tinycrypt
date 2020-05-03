

// Cisco Type 8 password algorithm
// Odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>

#include <openssl/sha.h>

#if defined (_WIN32) || defined (_WIN64)
#pragma comment (lib, "user32.lib")
#pragma comment (lib, "gdi32.lib")
#pragma comment (lib, "advapi32.lib")
#endif

#define MIN_SALT_LEN 14
#define MAX_SALT_LEN 14

unsigned char itoa64[] =
	"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

void sha256_hmac (void *text, size_t text_len, 
  void *key, size_t key_len, void* dgst)
{
  SHA256_CTX ctx;
  uint8_t    k_ipad[64], k_opad[64], tk[SHA256_DIGEST_LENGTH];
  size_t     i;
  uint8_t    *k=(uint8_t*)key;

  if (key_len > 64) {
    SHA256_Init (&ctx);
    SHA256_Update (&ctx, key, key_len);
    SHA256_Final (tk, &ctx);

    key = tk;
    key_len = SHA256_DIGEST_LENGTH;
  }

  memset (k_ipad, 0x36, sizeof (k_ipad));
  memset (k_opad, 0x5c, sizeof (k_opad));

  /** XOR key with ipad and opad values */
  for (i=0; i<key_len; i++) {
    k_ipad[i] ^= k[i];
    k_opad[i] ^= k[i];
  }
  /**
   * perform inner 
   */
  SHA256_Init (&ctx);                   /* init context for 1st pass */
  SHA256_Update (&ctx, k_ipad, 64);     /* start with inner pad */
  SHA256_Update (&ctx, text, text_len); /* then text of datagram */
  SHA256_Final (dgst, &ctx);            /* finish up 1st pass */
  /**
   * perform outer
   */
  SHA256_Init (&ctx);                   /* init context for 2nd pass */
  SHA256_Update (&ctx, k_opad, 64);     /* start with outer pad */
  SHA256_Update (&ctx, dgst, SHA256_DIGEST_LENGTH); /* then results of 1st hash */
  SHA256_Final (dgst, &ctx);            /* finish up 2nd pass */
}

/**
 * Password-Based Key Derivation Function 2 (PKCS #5 v2.0).
 * Code based on IEEE Std 802.11-2007, Annex H.4.2.
 */
 
#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

int sha256_pbkdf2 (void *pwd, size_t pwd_len, void *salt, size_t salt_len,
  uint32_t rounds, void *key, size_t key_len)
{
  uint8_t *asalt, obuf[SHA256_DIGEST_LENGTH];
  uint8_t *k=(uint8_t*)key;
  uint8_t d1[SHA256_DIGEST_LENGTH], d2[SHA256_DIGEST_LENGTH];
  size_t i, j, count, r;

  if ((asalt = (uint8_t*)malloc(salt_len + 4)) == NULL)
    return -1;

  memcpy(asalt, salt, salt_len);

  for (count = 1; key_len > 0; count++) {
    asalt[salt_len + 0] = (count >> 24) & 0xff;
    asalt[salt_len + 1] = (count >> 16) & 0xff;
    asalt[salt_len + 2] = (count >>  8) & 0xff;
    asalt[salt_len + 3] = count & 0xff;
    sha256_hmac(asalt, salt_len + 4, pwd, pwd_len, d1);
    memcpy(obuf, d1, sizeof(obuf));

    for (i = 1; i < rounds; i++) {
      sha256_hmac(d1, sizeof(d1), pwd, pwd_len, d2);
      memcpy(d1, d2, sizeof(d1));
      for (j = 0; j < sizeof(obuf); j++)
        obuf[j] ^= d1[j];
    }

    r = MIN(key_len, SHA256_DIGEST_LENGTH);
    memcpy(k, obuf, r);
    k += r;
    key_len -= r;
  };
  free(asalt);
  return 0;
}

char* b64encode (char *out, uint8_t *d, size_t len)
{
  size_t   i;
  uint32_t c, t;
  char     *r=out;
  
  for (i=0; i<len; i+=3)
  {
    c = d[i];
    t = itoa64[c >> 2];
    c = (c & 3) << 8;
    
    if (i+1 >= len)
    {
      *r++ = t;
      *r++ = itoa64[c >> 8];
      break;
    }
    
    c |= d[i+1];
    t <<= 8;
    t |= itoa64[c >> 4];
    c = (c & 0xf) << 8;
    
    if (i+2 >= len)
    {
      *r++ = (t >> 8);
      *r++ = (t & 255);
      *r++ = itoa64[c >> 6];
      break;
    }
    
    c |= d[i+2];
    
    *r++ = (t >> 8);
    *r++ = (t & 255);
    *r++ = itoa64[c >> 6];
    *r++ = itoa64[c & 0x3f];
  }
  return out;
}

char *cisco8_pwd (char *pwd, uint8_t *salt, size_t slen)
{
  static char spwd[64];
  size_t      plen;
  uint8_t     r[64], s[32];
  char        *p;
  
  memset (spwd, 0, sizeof (spwd));
  
  _snprintf (spwd, sizeof spwd, "$%i$%s$", 8, salt);
  plen=strlen (pwd);
  sha256_pbkdf2 (pwd, plen, salt, slen, 20000, r, SHA256_DIGEST_LENGTH);
  plen=strlen (spwd);
  
  b64encode (&spwd[plen], r, SHA256_DIGEST_LENGTH);
  return spwd;
}

int main (int argc, char *argv[])
{
  char    *pwd;
  uint8_t salt[MAX_SALT_LEN+1];
  size_t  salt_len=0, plen;
  uint8_t *salt_ptr=salt;
  int     i;
  uint8_t r[64];
  
  memset (salt, 0, sizeof salt);
  srand (time(0));
  
  if (argc < 2) {
    printf ("\n  usage: cisco8 <password> <14-byte salt>\n");
    return 0;
  }
  pwd=argv[1];
  plen=strlen (pwd);
  
  if (argc==3) {
    salt_ptr = argv[2];
    salt_len=strlen (salt_ptr);
  } else {
    while (salt_len < MAX_SALT_LEN) {
      salt[salt_len++] = itoa64[rand() % strlen (itoa64)];
    }
  }
  pwd=cisco8_pwd (pwd, salt_ptr, salt_len);
  printf ("\n  Cisco Type 8 : %s\n", pwd);
  return 0;
}
