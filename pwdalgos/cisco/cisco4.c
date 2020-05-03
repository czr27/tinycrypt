

// Cisco Type 4 password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/sha.h>

#define MAX_PWD 25

uint8_t itoa64[] =
	"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

void b64encode (char *out, uint8_t *d, size_t len)
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
}

char *cisco4_pwd (char *pwd)
{
  SHA256_CTX   ctx;
  static  char r[SHA256_DIGEST_LENGTH*2+32];
  uint8_t      dgst[SHA256_DIGEST_LENGTH];
  char         *p;
  int          i;
  size_t       plen=strlen(pwd);
  
  plen = (plen > MAX_PWD) ? MAX_PWD : plen;
  
  SHA256_Init (&ctx);
  SHA256_Update (&ctx, pwd, strlen (pwd));
  SHA256_Final (dgst, &ctx);
  
  b64encode (r, dgst, SHA256_DIGEST_LENGTH);
  return r;
}

int main (int argc, char *argv[])
{
  if (argc != 2) {
    printf ("\n  usage: cisco4 <password>\n");
    return 0;
  }
  
  printf ("\n  Cisco Type 4 : %s\n", cisco4_pwd (argv[1]));
  return 0;
}
