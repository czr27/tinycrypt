

// PSafe V3 password algorithm
// Odzhan

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <openssl/sha.h>

#define PSAFE_VERSION 3
#define SaltLengthV3 32
#define HASHLEN      32
#define ITER_LEN      4
#define MIN_HASH_ITERATIONS 2048

typedef struct _PSAFE_ENTRY {
  uint32_t iterations;
  uint8_t  salt[SaltLengthV3];
  uint8_t  hash[HASHLEN];
} PSAFE_ENTRY;

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

char *psafev3_pwd (char pwd[], uint8_t salt[], uint32_t rounds)
{
  SHA256_CTX  ctx;
  uint8_t     dgst[SHA256_DIGEST_LENGTH];
  uint8_t     sbin[SaltLengthV3 + ITER_LEN];
  int         i;
  static char hash[256];
  size_t      salt_len;
  char        *p=hash;
  
  memset (hash, 0, sizeof hash);
  memset (sbin, 0, sizeof sbin);
  
  rounds=(rounds < MIN_HASH_ITERATIONS) ? MIN_HASH_ITERATIONS : rounds;

  salt_len=strlen (salt);
  memcpy (sbin, (uint8_t*)&rounds, ITER_LEN);
  
  if (salt_len==0) {
    srand (time(0));
    while (salt_len < SaltLengthV3) {
      sbin[ITER_LEN+salt_len++] = rand () % 255;
    }
  } else {
    salt_len=hex2bin (&sbin[ITER_LEN], salt);
  }
  
  // first, the salt
  SHA256_Init (&ctx);
  SHA256_Update (&ctx, pwd, strlen (pwd));
  SHA256_Update (&ctx, &sbin[ITER_LEN], salt_len);
  SHA256_Final (dgst, &ctx);

  // then the digest for number of rounds
  for (i=0; i<=rounds; i++) {
    SHA256_Init (&ctx);
    SHA256_Update (&ctx, dgst, SHA256_DIGEST_LENGTH);
    SHA256_Final (dgst, &ctx);
  }
  
  memset (hash, 0, sizeof hash);
  
  // format JTR signature
  _snprintf (p, 256, "$pwsafe$*%i*", PSAFE_VERSION);
  p += strlen (p);
  
  // format salt
  for (i=0; i<SaltLengthV3; i++) {
    _snprintf (p, 2, "%02x", sbin[ITER_LEN+i]);
    p += 2;
  }
  
   // format iterations
  _snprintf (p, 10, "*%ld*", *(uint32_t*)sbin);
  p += strlen (p);
  
  // format hash
  for (i=0; i<SHA256_DIGEST_LENGTH; i++) {
    _snprintf (p, 2, "%02x", dgst[i]);
    p += 2;
  }
  
  return hash;
}

int main (int argc, char *argv[])
{
  char        *pwd, *salt="";
  PSAFE_ENTRY e;

  if (argc < 2) {
    printf ("\n  usage: psafe <password> <salt> <iterations>\n");
    return 0;
  }
  
  memset (e, 0, sizeof e);
  pwd=argv[1];
  if (argc >= 3) {
    salt=argv[2];
  }
  e.iterations=(argc==4) ? atoi(argv[3]) : MIN_HASH_ITERATIONS;
 
  printf ("\n  PSafe V3 : %s\n", psafev3_pwd (e));
  return 0;
}
