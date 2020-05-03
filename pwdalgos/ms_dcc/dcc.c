

// Microsoft Domain Cached Credentials
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/sha.h>
#include <openssl/md4.h>

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

// return md4 hash in r
void md4 (uint8_t r[MD4_DIGEST_LENGTH], void *in, size_t len)
{
  MD4_CTX     ctx;
  
  MD4_Init (&ctx);
  MD4_Update (&ctx, in, len);
  MD4_Final (r, &ctx);
}

// domain cache credential v1
void dcc_hash (uint8_t r[], char *id, char *pwd)
{
  wchar_t wcs_pwd[128], wcs_id[128];
  uint8_t t[128];
  size_t  ulen, plen, i;

  memset (t, 0, sizeof t);
  memset (wcs_pwd, 0, sizeof wcs_pwd);
  memset (wcs_id, 0, sizeof wcs_id);
  
  ulen=strlen (id);
  
  // convert user name to lowercase
  for (i=0; i<ulen && i<sizeof t; i++) {
    t[i] = tolower (id[i]);
  }
  
  // convert user name and password to Unicode
  plen=mbstowcs (wcs_pwd, pwd, 128);
  ulen=mbstowcs (wcs_id, t, 128);
  
  // NTLM (password)
  md4 (t, wcs_pwd, plen*2);
  // append user name
  memcpy (&t[MD4_DIGEST_LENGTH], wcs_id, ulen*2);
  // apply md4 again
  md4 (r, t, MD4_DIGEST_LENGTH + ulen*2);
}

char *dccv1_pwd (char *id, char *pwd)
{
  uint8_t     r[MD4_DIGEST_LENGTH];
  static char v1[MD4_DIGEST_LENGTH*2+1];
  size_t      i;
  
  memset (r, 0, sizeof r);
  
  // get hash
  dcc_hash (r, id, pwd);
  
  memset (v1, 0, sizeof v1);

  // convert to string
  for (i=0; i<MD4_DIGEST_LENGTH; i++) {
    _snprintf (&v1[i*2], 2, "%02x", r[i]);
  }
  return v1;
}

char *dccv2_pwd (char *id, char *pwd, uint32_t count)
{
  uint8_t     r0[MD4_DIGEST_LENGTH];
  static char v2[MD4_DIGEST_LENGTH*2+1];
  size_t      i, ulen;
  wchar_t     wcs_id[128];
  uint8_t     lc_id[128];
  
  memset (r0, 0, sizeof r0);
  memset (lc_id, 0, sizeof lc_id);
  memset (wcs_id, 0, sizeof wcs_id);
  
  dcc_hash (r0, id, pwd);
  
  // convert user name to lowercase
  ulen=strlen (id);
  for (i=0; i<ulen && i<sizeof lc_id; i++) {
    lc_id[i] = tolower (id[i]);
  }
  
  ulen=mbstowcs (wcs_id, lc_id, 128);
 
  SHA1_PBKDF2 (r0, MD4_DIGEST_LENGTH, wcs_id, ulen*2, 
    count, r0, MD4_DIGEST_LENGTH); 

  memset (v2, 0, sizeof v2);
  
  // convert to string
  for (i=0; i<MD4_DIGEST_LENGTH; i++) {
    _snprintf (&v2[i*2], 2, "%02x", r0[i]);
  }
  return v2;
}

int main (int argc, char *argv[])
{
  char *id, *pwd;
  
  if (argc != 3) {
    printf ("\n  usage: dcc <domain\\id> <password>\n");
    return 0;
  }
  id=argv[1];
  pwd=argv[2];
  
  printf ("\n  DCC v1 : %s",   dccv1_pwd (id, pwd));
  printf ("\n  DCC v2 : %s\n", dccv2_pwd (id, pwd, 10240));
  return 0;
}
