

// Microsoft NTLM v2 password algorithm
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <openssl/md4.h>
#include <openssl/md5.h>

void MD5_HMAC (void *text, size_t text_len,
  void *key, size_t key_len, uint8_t r[])
{
	MD5_CTX ctx;
	uint8_t ipad[65], opad[65], tk[16];
  size_t  i;
  uint8_t *k=key;
  
	if (key_len > 64)
	{
    MD5_Init (&ctx);
		MD5_Update (&ctx, key, key_len);
		MD5_Final (tk, &ctx);

		k       = tk;
		key_len = 16;
	}

	memset (ipad, 0x36, sizeof (ipad));
	memset (opad, 0x5c, sizeof (opad));
  
	for(i=0; i<key_len; i++) {
		ipad[i] ^= k[i];
		opad[i] ^= k[i];
	}

	MD5_Init (&ctx);
	MD5_Update (&ctx, ipad, 64);
	MD5_Update (&ctx, text, text_len);
	MD5_Final (tk, &ctx);

	MD5_Init (&ctx);
	MD5_Update (&ctx, opad, 64);
	MD5_Update (&ctx, tk, 16);
	MD5_Final (r, &ctx);
}

// create NTLM hash using md4
void ntlm_v1 (uint8_t *out, char *pwd)
{
	MD4_CTX ctx;
  size_t  pwd_len;
  wchar_t wcs_pwd[128];
  
  pwd_len=mbstowcs (wcs_pwd, pwd, 128);
  
	MD4_Init (&ctx);
	MD4_Update (&ctx, pwd, pwd_len*2);
	MD4_Final (out, &ctx);
}

// convert hexadecimal string to binary
size_t hex2bin (void *bin, size_t bin_len, char hex[]) {
  size_t  len, i;
  int     x;
  uint8_t *p=(uint8_t*)bin;
  
  len = strlen (hex);
  
  if (len > bin_len) 
    len = bin_len;
  
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

void ntlm_v2 (char *id, char *pwd, uint8_t *out)
{
	uint8_t ntlm[MD4_DIGEST_LENGTH], mac[MD5_DIGEST_LENGTH];
  wchar_t wcs_id[256];
  
  // create ntlm v1 hash
	ntlm_v1 (pwd, ntlm);

  // create identity
  strncpy (mbs_id, uname);
  strncat (mbs_id, domain);
  
  // convert to wide string
  id_len=mbstowcs (wcs_id, mbs_id, 256);

  // hash it
	MD5_HMAC (wcs_id, id_len*2, ntlm, MD4_DIGEST_LENGTH, out);
}

int main(int argc, char *argv[])
{
  // 8 byte client and server challenges
  uint8_t cc[8], sc[8];
  uint8_t challenge[16];
  
  if (argc < 2) {
    printf ("\n  usage: ntlmv2 <domain\\id> <password> <client challenge> <server challenge>\n");
    return 0;
  }
  
  // parse client challenge
  cc_len=hex2bin (cc, sizeof cc, cc_str);
  
  // parse server challenge
  sc_len=hex2bin (sc, sizeof sc, cc_str);
  
  // create NTLM v2 part
  ntlm_v2 (id, pwd, r);
  
  memcpy (challenge, sc, 16);
  memcpy (challenge[16], cc, 16);
  
  MD5_HMAC (challenge, 32 , digest, 16, r);
	return 0;
}
