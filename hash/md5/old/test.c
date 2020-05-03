

// MD5 in C test unit
// Odzhan

#include "md5.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

char *text[] =
{ "",
  "a",
  "abc",
  "message digest",
  "abcdefghijklmnopqrstuvwxyz",
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
  "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

char *md5_dgst[] =
{ "d41d8cd98f00b204e9800998ecf8427e",
  "0cc175b9c0f1b6a831c399e269772661",
  "900150983cd24fb0d6963f7d28e17f72",
  "f96b697d7cb7938d525a2f31aaf161d0",
  "c3fcd3d76192e4007dfb496cca67e13b",
  "d174ab98d277d9f5a5611c2c9f419d9f",
  "57edf4a22be3c955ac49da2e2107b67a"
};

size_t hex2bin (void *bin, char hex[]) {
  size_t len, i;
  int x;
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

/************************************************
*
* finalize.
*
************************************************/
void MD5_HMAC (void *text, size_t text_len, 
  void *key, size_t key_len, void *dgst)
{
  MD5_CTX ctx;
  uint8_t k_ipad[65], k_opad[65], tk[MD5_DIGEST_LENGTH];
  size_t  i;
  uint8_t *k=(uint8_t*)key;

  if (key_len > 64) {
    MD5_Init (&ctx);
    MD5_Update (&ctx, key, key_len);
    MD5_Final (tk, &ctx);

    key = tk;
    key_len = MD5_DIGEST_LENGTH;
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
  MD5_Init (&ctx);                   /* init context for 1st pass */
  MD5_Update (&ctx, k_ipad, 64);     /* start with inner pad */
  MD5_Update (&ctx, text, text_len); /* then text of datagram */
  MD5_Final (dgst, &ctx);            /* finish up 1st pass */
  /**
  * perform outer
  */
  MD5_Init (&ctx);                       /* init context for 2nd pass */
  MD5_Update (&ctx, k_opad, 64);         /* start with outer pad */
  MD5_Update (&ctx, dgst, MD5_DIGEST_LENGTH); /* then results of 1st hash */
  MD5_Final (dgst, &ctx);                /* finish up 2nd pass */
}

void MD5 (void *in, size_t len, void *out)
{
  MD5_CTX ctx;
  
  MD5_Init (&ctx);
  MD5_Update (&ctx, in, len);
  MD5_Final (out, &ctx);
}

int run_tests (void)
{
  uint8_t dgst[MD5_DIGEST_LENGTH], tv[MD5_DIGEST_LENGTH];
  int i, fails=0;
  MD5_CTX ctx;
  
  for (i=0; i<sizeof(text)/sizeof(char*); i++)
  {
    MD5_Init (&ctx);
    MD5_Update (&ctx, text[i], strlen(text[i]));
    MD5_Final (dgst, &ctx);
    
    hex2bin (tv, md5_dgst[i]);
    
    if (memcmp (dgst, tv, MD5_DIGEST_LENGTH) != 0) {
      printf ("\nFailed for string: %s", text[i]);
      ++fails;
    }
  }
  return fails;
}

int main (int argc, char *argv[])
{
  if (!run_tests()) {
    printf ("  [ self-test OK!\n");
  }

  return 0;
}
