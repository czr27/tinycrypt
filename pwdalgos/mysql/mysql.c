

// MySQL password algorithm
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/sha.h>

#define ROL32(a, n)(((a) << (n)) | (((a) & 0xffffffff) >> (32 - (n))))
#define ROR32(a, n)((((a) & 0xffffffff) >> (n)) | ((a) << (32 - (n))))

#ifdef BIGENDIAN
#define SWAP32(n) (n)
#else
#define SWAP32(n) \
    ROR32((((n & 0xFF00FF00) >> 8) | ((n & 0x00FF00FF) << 8)), 16)
#define SWAP64(n) \
    ((uint64_t)SWAP32((uint32_t)n) << 32) | ((uint64_t)SWAP32((uint32_t)n) >> 32)
#endif

// post-4.1
char *mysql_v2 (char *pwd) 
{
  SHA_CTX     ctx;
  uint8_t     out[SHA_DIGEST_LENGTH];
  size_t      i;
  static char hash[SHA_DIGEST_LENGTH*2+1];
  
  SHA1_Init (&ctx);
  SHA1_Update (&ctx, pwd, strlen (pwd));
  SHA1_Final (out, &ctx);
  
  SHA1_Init (&ctx);
  SHA1_Update (&ctx, out, SHA_DIGEST_LENGTH);
  SHA1_Final (out, &ctx);
  
  memset (hash, 0, sizeof hash);
  
  for (i=0; i<SHA_DIGEST_LENGTH; i++) {
    _snprintf (&hash[i*2], 2, "%02X", out[i]);
  }
  
  return hash;
}

// pre-4.1
char* mysql_v1 (char *pwd)
{
  uint32_t    nr=1345345333L, add=7, nr2=0x12345671L, t;
  uint32_t    r[2];
  uint8_t     *p;
  static char sql41[32];
  size_t      i, pwd_len=strlen (pwd);
  
  for (i=0; i<pwd_len; i++)
  {
    if (pwd[i] == ' ' || pwd[i] == '\t') continue;
    
    t   = (uint8_t)pwd[i];
    nr  = nr  ^ (((nr & 63) + add) * t)+ (nr << 8);
    nr2 = nr2 + ((nr2 << 8) ^ nr);
    add = add + t;
  }
  r[0]=SWAP32(nr & (((uint32_t) 1L << 31) -1L));
  r[1]=SWAP32(nr2 & (((uint32_t) 1L << 31) -1L));
  
  p=(uint8_t*)r;
  
  memset (sql41, 0, sizeof sql41);
  for (i=0; i<8; i++) {
    _snprintf (&sql41[i*2], 2, "%02X", p[i]);
  }
  return sql41;
}

int main (int argc, char *argv[])
{
  char *pwd;
  
  if (argc != 2) {
    printf ("\n  usage: mysql <password>\n");
    return 0;
  }
  pwd=argv[1];
  
  printf ("\n  mysql v1 : %s", mysql_v1 (pwd));
  printf ("\n  mysql v2 : %s\n", mysql_v2 (pwd));
  return 0;
}


