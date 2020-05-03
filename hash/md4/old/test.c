

// Test unit for MD4 in C
// Odzhan

#include "md4.h"

#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
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

char *md4_dgst[] =
{ "31d6cfe0d16ae931b73c59d7e0c089c0",
  "bde52cb31de33e46245e05fbdbd6fb24",
  "a448017aaf21d8525fc10ae87aa6729d",
  "d9130a8164549fe818874806e1c7014b",
  "d79e1c308aa5bbcdeea8ed63df412da9",
  "043f8582f241db351ce627e153e7f0e4",
  "e33b4ddc9c38f2199c3e7b164fcc0536"
};

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

/************************************************
*
* HMAC
*
************************************************/
void MD4_HMAC (void *text, size_t text_len, 
void *key, size_t key_len, void *dgst)
{
  MD4_CTX ctx;
  uint8_t k_ipad[64], k_opad[64], tk[MD4_DIGEST_LENGTH];
  size_t  i;
  uint8_t *k=(uint8_t*)key;

  if (key_len > 64) {
    MD4_Init (&ctx);
    MD4_Update (&ctx, key, key_len);
    MD4_Final (tk, &ctx);

    k = tk;
    key_len = MD4_DIGEST_LENGTH;
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
  MD4_Init (&ctx);                       /* init context for 1st pass */
  MD4_Update (&ctx, k_ipad, 64);         /* start with inner pad */
  MD4_Update (&ctx, text, text_len);     /* then text of datagram */
  MD4_Final (dgst, &ctx);                /* finish up 1st pass */
  /**
  * perform outer
  */
  MD4_Init (&ctx);                       /* init context for 2nd pass */
  MD4_Update (&ctx, k_opad, 64);         /* start with outer pad */
  MD4_Update (&ctx, dgst, MD4_DIGEST_LENGTH); /* then results of 1st hash */
  MD4_Final (dgst, &ctx);                /* finish up 2nd pass */
}

void MD4 (void *in, size_t len, void *out)
{
  MD4_CTX ctx;
  
  MD4_Init (&ctx);
  MD4_Update (&ctx, in, len);
  MD4_Final (out, &ctx);
}

int run_tests (void)
{
  uint8_t dgst[MD4_DIGEST_LENGTH], tv[MD4_DIGEST_LENGTH];
  int     i, fails=0;
  MD4_CTX ctx;
  
  for (i=0; i<sizeof(text)/sizeof(char*); i++)
  {
    MD4_Init (&ctx);
    MD4_Update (&ctx, text[i], strlen(text[i]));
    MD4_Final (dgst, &ctx);
    
    hex2bin (tv, md4_dgst[i]);
    
    if (memcmp (dgst, tv, MD4_DIGEST_LENGTH) != 0) {
      printf ("\nFailed for \"%s\"", text[i]);
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
