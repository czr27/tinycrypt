

// Cisco Type 5 password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/md5.h>

#define MAX_PWD 25

uint8_t itoa64[] =
  "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

char *magic = "$1$";

void to64(char *s, uint32_t v, int n)
{
  while (--n >= 0) {
    *s++ = itoa64[v & 0x3f];
    v >>= 6;
  }
}

int is_md5_salt(const char *salt)
{
  return (!strncmp (salt, magic, strlen (magic)));
}

char *md5crypt(char *pw, char *salt)
{
  static  char passwd[120], *p;
  char    *sp, *ep;
  uint8_t final[MD5_DIGEST_LENGTH];
  int     sl, pl, i, j;
  size_t  l;
  MD5_CTX ctx, ctx1;

  // Refine the Salt first
  sp = salt;

  // If it starts with the magic string, then skip that 
  if (!strncmp (sp, magic, strlen (magic)))
    sp += strlen(magic);

  // It stops at the first '$', max 8 chars 
  for (ep=sp; *ep && *ep != '$' && ep < (sp+8); ep++)
    continue;

  // get the length of the true salt 
  sl = ep - sp;

  MD5_Init (&ctx);

  // The password first, since that is what is most unknown 
  MD5_Update (&ctx, pw, strlen (pw));

  // Then our magic string 
  MD5_Update (&ctx, magic, strlen (magic));

  // Then the raw salt 
  MD5_Update (&ctx, sp, sl);

  // Then just as many characters of the MD5(pw,salt,pw) 
  MD5_Init (&ctx1);
  MD5_Update (&ctx1, pw, strlen (pw));
  MD5_Update (&ctx1, sp, sl);
  MD5_Update (&ctx1, pw, strlen (pw));
  MD5_Final (final, &ctx1);
  
  for (pl = strlen (pw); pl > 0; pl -= MD5_DIGEST_LENGTH)
    MD5_Update (&ctx, final, pl > MD5_DIGEST_LENGTH ? MD5_DIGEST_LENGTH : pl);

  // Don't leave anything around in vm they could use. 
  memset (final, 0, sizeof final);

  // Then something really weird... 
  for (j=0,i = strlen(pw); i ; i >>= 1) 
  {
    if (i & 1) {
      MD5_Update (&ctx, final+j, 1);
    } else {
      MD5_Update (&ctx, pw+j, 1);
    }
  }
  // Now make the output string 
  strcpy (passwd, magic);
  strncat (passwd, sp, sl);
  strcat (passwd, "$");

  MD5_Final (final, &ctx);

  // * and now, just to make sure things don't run too fast
  // * On a 60 Mhz Pentium this takes 34 msec, so you would
  // * need 30 seconds to build a 1000 entry dictionary...
   
  for (i=0; i<1000; i++) {
    MD5_Init (&ctx1);
    if (i & 1) {
      MD5_Update (&ctx1, pw, strlen (pw));
    } else {
      MD5_Update(&ctx1,final,MD5_DIGEST_LENGTH);
    }
    if (i % 3) {
      MD5_Update (&ctx1, sp, sl);
    }
    if (i % 7) {
      MD5_Update (&ctx1, pw, strlen (pw));
    }
    if(i & 1) {
      MD5_Update (&ctx1, final, MD5_DIGEST_LENGTH);
    } else {
      MD5_Update (&ctx1, pw, strlen (pw));
    }
    MD5_Final (final, &ctx1);
  }
  
  p = passwd + strlen (passwd);

  l = (final[ 0]<<16) | (final[ 6]<<8) | final[12]; to64(p,l,4); p += 4;
  l = (final[ 1]<<16) | (final[ 7]<<8) | final[13]; to64(p,l,4); p += 4;
  l = (final[ 2]<<16) | (final[ 8]<<8) | final[14]; to64(p,l,4); p += 4;
  l = (final[ 3]<<16) | (final[ 9]<<8) | final[15]; to64(p,l,4); p += 4;
  l = (final[ 4]<<16) | (final[10]<<8) | final[ 5]; to64(p,l,4); p += 4;
  l =                    final[11]                ; to64(p,l,2); p += 2;
  *p = '\0';

  // Don't leave anything around in vm they could use. 
  memset (final, 0, sizeof final);
  return passwd;
}

int main (int argc, char *argv[])
{
  if (argc != 3) {
    printf ("\n  usage: cisco5 <password> <salt>\n");
    return 0;
  }
  
  printf ("\n  Cisco Type 5 : %s", md5crypt (argv[1], argv[2]));
  return 0;
}
