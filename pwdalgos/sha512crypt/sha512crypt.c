

// SHA512 crypt password algorithm
// Odzhan

#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <stdalign.h>

#include <openssl/sha.h>

#ifdef _MSC_VER
#define snprintf _snprintf
#endif

#ifndef MIN
#define MIN(a,b) ( (a) > (b) ? (b) : (a) )
#endif
#ifndef MAX
#define MAX(a,b) ( (a) > (b) ? (a) : (b) )
#endif

/* Define our magic string to mark salt for SHA512 "encryption"
   replacement.  */
char sha512_salt_prefix[] = "$6$";

/* Prefix for optional rounds specification.  */
char sha512_rounds_prefix[] = "rounds=";

/* Maximum salt string length.  */
#define SALT_LEN_MAX 16
/* Default number of rounds if not explicitly specified.  */
#define ROUNDS_DEFAULT 5000
/* Minimum number of rounds.  */
#define ROUNDS_MIN 1000
/* Maximum number of rounds.  */
#define ROUNDS_MAX 999999999

/* Table with characters for base64 transformation.  */
char b64t[64] =
"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

char *sha512_crypt_r (char *key, char *salt, char *buffer, size_t buflen)
{
  unsigned char alt_result[64];
  unsigned char temp_result[64];
  SHA512_CTX ctx;
  SHA512_CTX alt_ctx;
  size_t salt_len;
  size_t key_len;
  size_t cnt;
  char *cp;
  char *copied_key = NULL;
  char *copied_salt = NULL;
  char *p_bytes;
  char *s_bytes;
  char *num;
  char *endp;
  char *tmp;
  unsigned long int srounds;
  
  /* Default number of rounds.  */
  size_t rounds = ROUNDS_DEFAULT;
  int rounds_custom = 0;

  /* Find beginning of salt string.  The prefix should normally always
     be present.  Just in case it is not.  */
  if (strncmp (sha512_salt_prefix, salt, sizeof (sha512_salt_prefix) - 1) == 0)
    /* Skip salt prefix.  */
    salt += sizeof (sha512_salt_prefix) - 1;

  if (strncmp (salt, sha512_rounds_prefix, sizeof (sha512_rounds_prefix) - 1) == 0)
  {
      num = salt + strlen (sha512_rounds_prefix) - 1;
      srounds = strtoul (num, &endp, 10);
      if (*endp == '$')
      {
        salt = endp + 1;
        rounds = MAX (ROUNDS_MIN, MIN (srounds, ROUNDS_MAX));
        rounds_custom = 1;
	    }
    }

  salt_len = MIN (strcspn (salt, "$"), SALT_LEN_MAX);
  key_len = strlen (key);

  if ((key - (char *) 0) % __alignof (uint64_t) != 0)
  {
    tmp = (char *) alloca (key_len + __alignof (uint64_t));
    key = copied_key = memcpy (tmp + __alignof (uint64_t) - (tmp - (char *) 0) % __alignof (uint64_t), key, key_len);
  }

  if ((salt - (char *) 0) % __alignof (uint64_t) != 0)
  {
    tmp = (char *) alloca (salt_len + __alignof (uint64_t));
    salt = copied_salt = memcpy (tmp + __alignof (uint64_t) - (tmp - (char *) 0) % __alignof (uint64_t), salt, salt_len);
  }

  /* Prepare for the real work.  */
  SHA512_Init (&ctx);

  /* Add the key string.  */
  SHA512_Update (&ctx, key, key_len);

  /* The last part is the salt string.  This must be at most 16
     characters and it ends at the first `$' character (for
     compatibility with existing implementations).  */
  SHA512_Update (&ctx, salt, salt_len);


  /* Compute alternate SHA512 sum with input KEY, SALT, and KEY.  The
     final result will be added to the first context.  */
  SHA512_Init (&alt_ctx);

  /* Add key.  */
  SHA512_Update (&alt_ctx, key, key_len);

  /* Add salt.  */
  SHA512_Update (&alt_ctx, salt, salt_len);

  /* Add key again.  */
  SHA512_Update (&alt_ctx, key, key_len);

  /* Now get result of this (64 bytes) and add it to the other
     context.  */
  SHA512_Final (alt_result, &alt_ctx);

  /* Add for any character in the key one byte of the alternate sum.  */
  for (cnt = key_len; cnt > 64; cnt -= 64)
    SHA512_Update (&ctx, alt_result, 64);
  
  SHA512_Update (&ctx, alt_result, cnt);

  /* Take the binary representation of the length of the key and for every
     1 add the alternate sum, for every 0 the key.  */
  for (cnt = key_len; cnt > 0; cnt >>= 1)
    if ((cnt & 1) != 0)
      SHA512_Update (&ctx, alt_result, 64);
    else
      SHA512_Update (&ctx, key, key_len);

  /* Create intermediate result.  */
  SHA512_Final (alt_result, &ctx);

  /* Start computation of P byte sequence.  */
  SHA512_Init (&alt_ctx);

  /* For every character in the password add the entire password.  */
  for (cnt = 0; cnt < key_len; ++cnt)
    SHA512_Update (&alt_ctx, key, key_len);

  /* Finish the digest.  */
  SHA512_Final (temp_result, &alt_ctx);

  /* Create byte sequence P.  */
  cp = p_bytes = (char*)alloca (key_len);
  for (cnt = key_len; cnt >= 64; cnt -= 64) {
    memcpy (cp, temp_result, 64);
    cp += 64;
  }
  memcpy (cp, temp_result, cnt);

  /* Start computation of S byte sequence.  */
  SHA512_Init (&alt_ctx);

  /* For every character in the password add the entire password.  */
  for (cnt = 0; cnt < 16 + alt_result[0]; ++cnt)
    SHA512_Update (&alt_ctx, salt, salt_len);

  /* Finish the digest.  */
  SHA512_Final (temp_result, &alt_ctx);

  /* Create byte sequence S.  */
  cp = s_bytes = (char*)alloca (salt_len);
  for (cnt = salt_len; cnt >= 64; cnt -= 64) {
    memcpy (cp, temp_result, 64);
    cp += 64;
  }
  memcpy (cp, temp_result, cnt);

  /* Repeatedly run the collected hash value through SHA512 to burn
     CPU cycles.  */
  for (cnt = 0; cnt < rounds; ++cnt)
    {
      /* New context.  */
      SHA512_Init (&ctx);

      /* Add key or last result.  */
      if ((cnt & 1) != 0)
        SHA512_Update (&ctx, p_bytes, key_len);
      else
        SHA512_Update (&ctx, alt_result, 64);

      /* Add salt for numbers not divisible by 3.  */
      if (cnt % 3 != 0)
        SHA512_Update (&ctx, s_bytes, salt_len);

      /* Add key for numbers not divisible by 7.  */
      if (cnt % 7 != 0)
        SHA512_Update (&ctx, p_bytes, key_len);

      /* Add key or last result.  */
      if ((cnt & 1) != 0)
        SHA512_Update (&ctx, alt_result, 64);
      else
        SHA512_Update (&ctx, p_bytes, key_len);

      /* Create intermediate result.  */
      SHA512_Final (alt_result, &ctx);
    }

    /* Now we can construct the result string.  It consists of three
       parts.  */
    cp = strncpy (buffer, sha512_salt_prefix, MAX (0, buflen));
    cp += MIN(strlen(sha512_salt_prefix), MAX (0, buflen));
    buflen -= sizeof (sha512_salt_prefix) - 1;

  if (rounds_custom)
    {
      int n = snprintf (cp, MAX (0, buflen), "%s%u$",
			sha512_rounds_prefix, (unsigned int)rounds);
      cp += n;
      buflen -= n;
    }

  cp = strncpy (cp, salt, MIN ((size_t) MAX (0, buflen), salt_len));
  cp += MIN(strlen(salt), MIN ((size_t) MAX (0, buflen), salt_len));
  buflen -= MIN ((size_t) MAX (0, buflen), salt_len);

  if (buflen > 0)
    {
      *cp++ = '$';
      --buflen;
    }

#define b64_from_24bit(B2, B1, B0, N)					      \
  do {									      \
    unsigned int w = ((B2) << 16) | ((B1) << 8) | (B0);			      \
    int n = (N);							      \
    while (n-- > 0 && buflen > 0)					      \
      {									      \
	*cp++ = b64t[w & 0x3f];						      \
	--buflen;							      \
	w >>= 6;							      \
      }									      \
  } while (0)

  b64_from_24bit (alt_result[0], alt_result[21], alt_result[42], 4);
  b64_from_24bit (alt_result[22], alt_result[43], alt_result[1], 4);
  b64_from_24bit (alt_result[44], alt_result[2], alt_result[23], 4);
  b64_from_24bit (alt_result[3], alt_result[24], alt_result[45], 4);
  b64_from_24bit (alt_result[25], alt_result[46], alt_result[4], 4);
  b64_from_24bit (alt_result[47], alt_result[5], alt_result[26], 4);
  b64_from_24bit (alt_result[6], alt_result[27], alt_result[48], 4);
  b64_from_24bit (alt_result[28], alt_result[49], alt_result[7], 4);
  b64_from_24bit (alt_result[50], alt_result[8], alt_result[29], 4);
  b64_from_24bit (alt_result[9], alt_result[30], alt_result[51], 4);
  b64_from_24bit (alt_result[31], alt_result[52], alt_result[10], 4);
  b64_from_24bit (alt_result[53], alt_result[11], alt_result[32], 4);
  b64_from_24bit (alt_result[12], alt_result[33], alt_result[54], 4);
  b64_from_24bit (alt_result[34], alt_result[55], alt_result[13], 4);
  b64_from_24bit (alt_result[56], alt_result[14], alt_result[35], 4);
  b64_from_24bit (alt_result[15], alt_result[36], alt_result[57], 4);
  b64_from_24bit (alt_result[37], alt_result[58], alt_result[16], 4);
  b64_from_24bit (alt_result[59], alt_result[17], alt_result[38], 4);
  b64_from_24bit (alt_result[18], alt_result[39], alt_result[60], 4);
  b64_from_24bit (alt_result[40], alt_result[61], alt_result[19], 4);
  b64_from_24bit (alt_result[62], alt_result[20], alt_result[41], 4);
  b64_from_24bit (0, 0, alt_result[63], 2);

  if (buflen <= 0)
    {
      errno = ERANGE;
      buffer = NULL;
    }
  else
    *cp = '\0';		/* Terminate the string.  */

  return buffer;
}


/* This entry point is equivalent to the `crypt' function in Unix
   libcs.  */
char *sha512_crypt (char *key, char *salt)
{
  /* We don't want to have an arbitrary limit in the size of the
     password.  We can compute an upper bound for the size of the
     result in advance and so we can prepare the buffer we pass to
     `cpx_sha512_crypt_r'.  */
  char *buffer=0, *new_buffer;
  int buflen=0;
  int needed = (sizeof (sha512_salt_prefix) - 1
		+ sizeof (sha512_rounds_prefix) + 9 + 1
		+ strlen (salt) + 1 + 86 + 1);

  if (buflen < needed)
  {
    new_buffer = (char *) realloc (buffer, needed);
    if (new_buffer == NULL)
      return NULL;

    buffer = new_buffer;
    buflen = needed;
  }
  return sha512_crypt_r (key, salt, buffer, buflen);
}

int main (int argc, char *argv[])
{  
  if (argc < 3) {
    printf ("\n  usage: sha512crypt <password> <salt>\n");
    return 0;
  }
 
  printf ("\n  SHA512Crypt : %s\n", sha512_crypt (argv[1], argv[2]));
  return 0;
}
