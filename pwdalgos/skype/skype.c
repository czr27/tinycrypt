

// Skype password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/md5.h>

char *skype_pwd (char *id, char *pwd) {
  MD5_CTX     ctx;
  char        *skype = "\nskyper\n";
  uint8_t     dgst[MD5_DIGEST_LENGTH];
  int         i;
  static char hash[MD5_DIGEST_LENGTH*2+1];

  MD5_Init (&ctx);
  MD5_Update (&ctx, id, strlen (id));
  MD5_Update (&ctx, skype, strlen (skype));
  MD5_Update (&ctx, pwd, strlen (pwd));
  MD5_Final (dgst, &ctx);

  memset (hash, 0, sizeof hash);
  
  for (i=0; i<MD5_DIGEST_LENGTH; i++) {
    _snprintf (&hash[i*2], 2, "%02x", dgst[i]);
  }
  return hash;
}

int main (int argc, char *argv[])
{
  char *id, *pwd;
  
  if (argc != 3) {
    printf ("\n  usage: skype_pwd <id> <password>\n");
    return 0;
  }
  id=argv[1];
  pwd=argv[2];
  
  printf("\n  Login ID   : %s\n  Password   : %s", id, pwd);       
  printf ("\n  Skype hash : %s\n", skype_pwd (id, pwd));
  return 0;
}
