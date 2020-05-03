

// Cisco PIX password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/md5.h>

unsigned char itoa64[] =
	"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

void to64(char *s, unsigned long v, int n)
{
	while (--n >= 0) {
		*s++ = itoa64[v&0x3f];
		v >>= 6;
	}
}

char *pix_pwd (char *pwd)
{
  char    x[16];
  MD5_CTX ctx;
  static  char r[16+1];
  uint8_t dgst[MD5_DIGEST_LENGTH];
  char    *p;
  int     i;
  
  memset (x, 0, sizeof x);
  strncpy (x, pwd, 16);
  
  MD5_Init (&ctx);
  MD5_Update (&ctx, x, 16);
  MD5_Final (dgst, &ctx);
  
  p = r;

  to64(p, *(uint32_t*) (dgst+0), 4); p += 4;
  to64(p, *(uint32_t*) (dgst+4), 4); p += 4;
  to64(p, *(uint32_t*) (dgst+8), 4); p += 4;
  to64(p, *(uint32_t*) (dgst+12),4); p += 4;
  
  return r;
}

int main (int argc, char *argv[])
{
  if (argc != 2) {
    printf ("\n  usage: cisco_pix <password>\n");
    return 0;
  }
  
  printf ("\n  Cisco PIX : %s\n", pix_pwd (argv[1]));
  return 0;
}
