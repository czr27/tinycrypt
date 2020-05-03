

// Microsoft NTLM v1 password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/md4.h>

#define MAX_PWD 128

char *ntlm (char *mbs)
{
  MD4_CTX     ctx;
  uint16_t    wcs[MAX_PWD];
  uint8_t     dgst[16];
  char        *p;
  static char pwd[32];
  size_t      len, i;
  
  // convert to wide character
  len=mbstowcs (wcs, mbs, MAX_PWD);
  
  MD4_Init (&ctx);
  MD4_Update (&ctx, wcs, len*2);
  MD4_Final (dgst, &ctx);
  
  // convert to hex
  for (i=0; i<16; i++) {
    _snprintf (&pwd[i*2], 2, "%02x", dgst[i]);
  }
  return pwd;
}

int main (int argc, char *argv[])
{
  if (argc != 2) {
    printf ("\n  usage: ntlm <password>\n");
    return 0;
  }
  
  printf ("\n  Microsoft NTLM : %s\n", ntlm (argv[1]));
  return 0;
}
