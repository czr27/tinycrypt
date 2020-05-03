

// Cisco Type 9 password algorithm
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/sha.h>

#include <errno.h>

/* Sane default values */
#define SCRYPT_HASH_LEN 64 /* This can be user defined - 
 *but 64 is the reference size
 */
#define SCRYPT_SAFE_N 30 /* This is much higher than you want. It's just
        * a blocker for insane defines
        */
#define SCRYPT_SALT_LEN 16 /* This is just a recommended size */
#define SCRYPT_MCF_LEN 125 /* mcf is 120 byte + nul */
#define SCRYPT_MCF_ID "$s1"
#define SCRYPT_N 16384
#define SCRYPT_r 8
#define SCRYPT_p 16

/************************************************
 *
 * HMAC
 *
 ************************************************/
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

uint32_t le32dec(const void *pp)
{
  const uint8_t *p = (uint8_t const *)pp;

  return ((uint32_t)(p[0]) + ((uint32_t)(p[1]) << 8) +
      ((uint32_t)(p[2]) << 16) + ((uint32_t)(p[3]) << 24));
}

void le32enc(void *pp, uint32_t x)
{
  uint8_t * p = (uint8_t *)pp;

  p[0] = x & 0xff;
  p[1] = (x >> 8) & 0xff;
  p[2] = (x >> 16) & 0xff;
  p[3] = (x >> 24) & 0xff;
}


void blkcpy(void * dest, void * src, size_t len)
{
  size_t * D = dest;
  size_t * S = src;
  size_t L = len / sizeof(size_t);
  size_t i;

  for (i = 0; i < L; i++)
    D[i] = S[i];
}

void blkxor(void * dest, void * src, size_t len)
{
  size_t * D = dest;
  size_t * S = src;
  size_t L = len / sizeof(size_t);
  size_t i;

  for (i = 0; i < L; i++)
    D[i] ^= S[i];
}

void dump_hex (void *in, size_t len)
{
  size_t i;
  uint8_t *p=(uint8_t*)in;
  for (i=0; i<len; i++) {
    if ((i & 7) == 0) putchar('\n');
    printf ("%02x ", p[i]);
  }
  putchar ('\n');
}

void
salsa20_8(uint32_t B[16])
{
  uint32_t x[16];
  size_t i;

  blkcpy(x, B, 64);
  for (i = 0; i < 8; i += 2) {
#define R(a,b) (((a) << (b)) | ((a) >> (32 - (b))))
    /* Operate on columns. */
    x[ 4] ^= R(x[ 0]+x[12], 7);  x[ 8] ^= R(x[ 4]+x[ 0], 9);
    x[12] ^= R(x[ 8]+x[ 4],13);  x[ 0] ^= R(x[12]+x[ 8],18);

    x[ 9] ^= R(x[ 5]+x[ 1], 7);  x[13] ^= R(x[ 9]+x[ 5], 9);
    x[ 1] ^= R(x[13]+x[ 9],13);  x[ 5] ^= R(x[ 1]+x[13],18);

    x[14] ^= R(x[10]+x[ 6], 7);  x[ 2] ^= R(x[14]+x[10], 9);
    x[ 6] ^= R(x[ 2]+x[14],13);  x[10] ^= R(x[ 6]+x[ 2],18);

    x[ 3] ^= R(x[15]+x[11], 7);  x[ 7] ^= R(x[ 3]+x[15], 9);
    x[11] ^= R(x[ 7]+x[ 3],13);  x[15] ^= R(x[11]+x[ 7],18);

    /* Operate on rows. */
    x[ 1] ^= R(x[ 0]+x[ 3], 7);  x[ 2] ^= R(x[ 1]+x[ 0], 9);
    x[ 3] ^= R(x[ 2]+x[ 1],13);  x[ 0] ^= R(x[ 3]+x[ 2],18);

    x[ 6] ^= R(x[ 5]+x[ 4], 7);  x[ 7] ^= R(x[ 6]+x[ 5], 9);
    x[ 4] ^= R(x[ 7]+x[ 6],13);  x[ 5] ^= R(x[ 4]+x[ 7],18);

    x[11] ^= R(x[10]+x[ 9], 7);  x[ 8] ^= R(x[11]+x[10], 9);
    x[ 9] ^= R(x[ 8]+x[11],13);  x[10] ^= R(x[ 9]+x[ 8],18);

    x[12] ^= R(x[15]+x[14], 7);  x[13] ^= R(x[12]+x[15], 9);
    x[14] ^= R(x[13]+x[12],13);  x[15] ^= R(x[14]+x[13],18);
#undef R
  }
  for (i = 0; i < 16; i++)
    B[i] += x[i];
}

void
blockmix_salsa8(uint32_t * Bin, uint32_t * Bout, uint32_t * X, size_t r)
{
  size_t i;

  /* 1: X <-- B_{2r - 1} */
  blkcpy(X, &Bin[(2 * r - 1) * 16], 64);

  /* 2: for i = 0 to 2r - 1 do */
  for (i = 0; i < 2 * r; i += 2) {
    /* 3: X <-- H(X \xor B_i) */
    blkxor(X, &Bin[i * 16], 64);
    salsa20_8(X);

    /* 4: Y_i <-- X */
    /* 6: B' <-- (Y_0, Y_2 ... Y_{2r-2}, Y_1, Y_3 ... Y_{2r-1}) */
    blkcpy(&Bout[i * 8], X, 64);

    /* 3: X <-- H(X \xor B_i) */
    blkxor(X, &Bin[i * 16 + 16], 64);
    salsa20_8(X);

    /* 4: Y_i <-- X */
    /* 6: B' <-- (Y_0, Y_2 ... Y_{2r-2}, Y_1, Y_3 ... Y_{2r-1}) */
    blkcpy(&Bout[i * 8 + r * 16], X, 64);
  }
}

/**
 * integerify(B, r):
 * Return the result of parsing B_{2r-1} as a little-endian integer.
 */
static uint64_t
integerify(void * B, size_t r)
{
  uint32_t * X = (void *)((uintptr_t)(B) + (2 * r - 1) * 64);

  return (((uint64_t)(X[1]) << 32) + X[0]);
}

/**
 * smix(B, r, N, V, XY):
 * Compute B = SMix_r(B, N).  The input B must be 128r bytes in length;
 * the temporary storage V must be 128rN bytes in length; the temporary
 * storage XY must be 256r + 64 bytes in length.  The value N must be a
 * power of 2 greater than 1.  The arrays B, V, and XY must be aligned to a
 * multiple of 64 bytes.
 */
static void
smix(uint8_t * B, size_t r, uint64_t N, uint32_t * V, uint32_t * XY)
{
  uint32_t * X = XY;
  uint32_t * Y = &XY[32 * r];
  uint32_t * Z = &XY[64 * r];
  uint64_t i;
  uint64_t j;
  size_t k;

  /* 1: X <-- B */
  for (k = 0; k < 32 * r; k++)
    X[k] = le32dec(&B[4 * k]);

  /* 2: for i = 0 to N - 1 do */
  for (i = 0; i < N; i += 2) {
    /* 3: V_i <-- X */
    blkcpy(&V[i * (32 * r)], X, 128 * r);

    /* 4: X <-- H(X) */
    blockmix_salsa8(X, Y, Z, r);

    /* 3: V_i <-- X */
    blkcpy(&V[(i + 1) * (32 * r)], Y, 128 * r);

    /* 4: X <-- H(X) */
    blockmix_salsa8(Y, X, Z, r);
  }

  /* 6: for i = 0 to N - 1 do */
  for (i = 0; i < N; i += 2) {
    /* 7: j <-- Integerify(X) mod N */
    j = integerify(X, r) & (N - 1);

    /* 8: X <-- H(X \xor V_j) */
    blkxor(X, &V[j * (32 * r)], 128 * r);
    blockmix_salsa8(X, Y, Z, r);

    /* 7: j <-- Integerify(X) mod N */
    j = integerify(Y, r) & (N - 1);

    /* 8: X <-- H(X \xor V_j) */
    blkxor(Y, &V[j * (32 * r)], 128 * r);
    blockmix_salsa8(Y, X, Z, r);
  }

  /* 10: B' <-- X */
  for (k = 0; k < 32 * r; k++)
    le32enc(&B[4 * k], X[k]);
}

/**
 * crypto_scrypt(passwd, passwdlen, salt, saltlen, N, r, p, buf, buflen):
 * Compute scrypt(passwd[0 .. passwdlen - 1], salt[0 .. saltlen - 1], N, r,
 * p, buflen) and write the result into buf.  The parameters r, p, and buflen
 * must satisfy r * p < 2^30 and buflen <= (2^32 - 1) * 32.  The parameter N
 * must be a power of 2 greater than 1.
 *
 * Return 0 on success; or -1 on error
 */
int scrypt(uint8_t * passwd, size_t passwdlen,
    uint8_t * salt, size_t saltlen, uint64_t N, uint32_t r, uint32_t p,
    uint8_t * buf, size_t buflen)
{
  void * B0, * V0, * XY0;
  uint8_t * B;
  uint32_t * V;
  uint32_t * XY;
  uint32_t i;

  /* Sanity-check parameters. */
#if SIZE_MAX > UINT32_MAX
  if (buflen > (((uint64_t)(1) << 32) - 1) * 32) {
    errno = EFBIG;
    goto err0;
  }
#endif
  if ((uint64_t)(r) * (uint64_t)(p) >= (1 << 30)) {
    errno = EFBIG;
    goto err0;
  }
  if (r == 0 || p == 0) {
    errno = EINVAL;
    goto err0;
  }
  if (((N & (N - 1)) != 0) || (N < 2)) {
    errno = EINVAL;
    goto err0;
  }
  if ((r > SIZE_MAX / 128 / p) ||
#if SIZE_MAX / 256 <= UINT32_MAX
      (r > SIZE_MAX / 256) ||
#endif
      (N > SIZE_MAX / 128 / r)) {
    errno = ENOMEM;
    goto err0;
  }

  /* Allocate memory. */
#ifdef HAVE_POSIX_MEMALIGN
  if ((errno = posix_memalign(&B0, 64, 128 * r * p)) != 0)
    goto err0;
  B = (uint8_t *)(B0);
  if ((errno = posix_memalign(&XY0, 64, 256 * r + 64)) != 0)
    goto err1;
  XY = (uint32_t *)(XY0);
#ifndef MAP_ANON
  if ((errno = posix_memalign(&V0, 64, 128 * r * N)) != 0)
    goto err2;
  V = (uint32_t *)(V0);
#endif
#else
  if ((B0 = malloc(128 * r * p + 63)) == NULL)
    goto err0;
  B = (uint8_t *)(((uintptr_t)(B0) + 63) & ~ (uintptr_t)(63));
  if ((XY0 = malloc(256 * r + 64 + 63)) == NULL)
    goto err1;
  XY = (uint32_t *)(((uintptr_t)(XY0) + 63) & ~ (uintptr_t)(63));
#ifndef MAP_ANON
  if ((V0 = malloc(128 * r * N + 63)) == NULL)
    goto err2;
  V = (uint32_t *)(((uintptr_t)(V0) + 63) & ~ (uintptr_t)(63));
#endif
#endif
#ifdef MAP_ANON
  if ((V0 = mmap(NULL, 128 * r * N, PROT_READ | PROT_WRITE,
#ifdef MAP_NOCORE
      MAP_ANON | MAP_PRIVATE | MAP_NOCORE,
#else
      MAP_ANON | MAP_PRIVATE,
#endif
      -1, 0)) == MAP_FAILED)
    goto err2;
  V = (uint32_t *)(V0);
#endif

  /* 1: (B_0 ... B_{p-1}) <-- PBKDF2(P, S, 1, p * MFLen) */
  sha256_pbkdf2 (passwd, passwdlen, salt, saltlen, 1, B, p * 128 * r);

  /* 2: for i = 0 to p - 1 do */
  for (i = 0; i < p; i++) {
    /* 3: B_i <-- MF(B_i, N) */
    smix(&B[i * 128 * r], r, N, V, XY);
  }

  /* 5: DK <-- PBKDF2(P, B, 1, dkLen) */
  sha256_pbkdf2 (passwd, passwdlen, B, p * 128 * r, 1, buf, buflen);

  /* Free memory. */
#ifdef MAP_ANON
  if (munmap(V0, 128 * r * N))
    goto err2;
#else
  free(V0);
#endif
  free(XY0);
  free(B0);

  /* Success! */
  return (0);

err2:
  free(XY0);
err1:
  free(B0);
err0:
  /* Failure! */
  return (-1);
}

unsigned char itoa64[] =
	"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

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

char *cisco9_pwd (char *pwd, uint8_t *salt, size_t slen)
{
  static char spwd[SCRYPT_HASH_LEN*2];
  size_t      plen;
  uint8_t     r[SCRYPT_HASH_LEN];
  char        *p;
  
  memset (spwd, 0, sizeof (spwd));
  
  _snprintf (spwd, sizeof spwd, "$%i$%s$", 9, salt);
  plen=strlen (pwd);
  scrypt (pwd, plen, salt, slen, 16384, 1, 1, r, SHA256_DIGEST_LENGTH);
  plen=strlen (spwd);
  
  b64encode (&spwd[plen], r, SHA256_DIGEST_LENGTH);
  return spwd;
}

int main (int argc, char *argv[])
{
  char    *pwd;
  uint8_t salt[14+1];
  size_t  salt_len=0, plen;
  uint8_t *salt_ptr=salt;
  int     i;
  uint8_t r[64];
  
  memset (salt, 0, sizeof salt);
  srand (time(0));
  
  if (argc < 2) {
    printf ("\n  usage: cisco9 <password> <14-byte salt>\n");
    return 0;
  }
  pwd=argv[1];
  plen=strlen (pwd);
  
  if (argc==3) {
    salt_ptr = argv[2];
    salt_len=strlen (salt_ptr);
  } else {
    while (salt_len < 14) {
      salt[salt_len++] = itoa64[rand() % strlen (itoa64)];
    }
  }
  pwd=cisco9_pwd (pwd, salt_ptr, salt_len);
  printf ("\n  Cisco Type 9 : %s\n", pwd);
  return 0;
}
