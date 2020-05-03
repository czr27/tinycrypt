

// WPA-PSK password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/sha.h>

#define WPA_PSK_LEN 32

void SHA1_HMAC (void *text, size_t text_len, 
  void *key, size_t key_len, void* dgst)
{
    SHA_CTX  ctx;
    uint8_t  k_ipad[64];
    uint8_t  k_opad[64];
    uint8_t  tk[SHA_DIGEST_LENGTH];
    uint32_t i;
    uint8_t  *k=(uint8_t*)key;

    if (key_len > 64) {
      SHA1_Init (&ctx);
      SHA1_Update (&ctx, key, key_len);
      SHA1_Final (tk, &ctx);

      key = tk;
      key_len = SHA_DIGEST_LENGTH;
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
    SHA1_Init (&ctx);                             // init context for 1st pass
    SHA1_Update (&ctx, k_ipad, 64);               // start with inner pad
    SHA1_Update (&ctx, text, text_len);           // then text of datagram
    SHA1_Final (dgst, &ctx);                      // finish up 1st pass
    /**
     * perform outer
     */
    SHA1_Init (&ctx);                             // init context for 2nd pass
    SHA1_Update (&ctx, k_opad, 64);               // start with outer pad
    SHA1_Update (&ctx, dgst, SHA_DIGEST_LENGTH);  // then results of 1st hash
    SHA1_Final (dgst, &ctx);                      // finish up 2nd pass
}

/**
 * Password-Based Key Derivation Function 2 (PKCS #5 v2.0).
 * Code based on IEEE Std 802.11-2007, Annex H.4.2.
 */
 
#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

int SHA1_PBKDF2 (void *pwd, size_t pwd_len, void *salt, size_t salt_len,
  uint32_t rounds, void *key, size_t key_len)
{
    uint8_t  *asalt, obuf[SHA_DIGEST_LENGTH];
    uint8_t  d1[SHA_DIGEST_LENGTH], d2[SHA_DIGEST_LENGTH];
    uint32_t i, j, count;
    size_t   r;
    uint8_t  *k=(uint8_t*)key;

    if ((asalt = (uint8_t*)malloc(salt_len + 4)) == NULL)
      return -1;

    memcpy(asalt, salt, salt_len);

    for (count = 1; key_len > 0; count++) {
      asalt[salt_len + 0] = (count >> 24) & 0xff;
      asalt[salt_len + 1] = (count >> 16) & 0xff;
      asalt[salt_len + 2] = (count >> 8) & 0xff;
      asalt[salt_len + 3] = count & 0xff;
      SHA1_HMAC(asalt, salt_len + 4, pwd, pwd_len, d1);
      memcpy(obuf, d1, sizeof(obuf));

      for (i = 1; i < rounds; i++) {
        SHA1_HMAC(d1, sizeof(d1), pwd, pwd_len, d2);
        memcpy(d1, d2, sizeof(d1));
        for (j = 0; j < sizeof(obuf); j++)
          obuf[j] ^= d1[j];
      }

      r = MIN(key_len, SHA_DIGEST_LENGTH);
      memcpy(k, obuf, r);
      k += r;
      key_len -= r;
    };
    free(asalt);
    return 0;
}

int main (int argc, char *argv[])
{
  uint8_t psk[WPA_PSK_LEN+1];
  int     i;
  
  if (argc!=3) {printf("\n  usage: wpa_psk <key> <ssid>\n"); exit(0);}
  
  SHA1_PBKDF2 (argv[1], strlen(argv[1]), 
    (uint8_t*)argv[2], strlen(argv[2]), 4096, psk, WPA_PSK_LEN);
  
  printf ("\n  WPA PSK : ");
  for (i=0; i<WPA_PSK_LEN; i++) printf ("%02x", psk[i]);
  putchar ('\n');
  return 0;
}
