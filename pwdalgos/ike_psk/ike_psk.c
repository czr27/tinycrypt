

// IKE Hash
// Odzhan

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#include <openssl/md5.h>

void MD5_HMAC (void *text, size_t text_len, 
  void *key, size_t key_len, void* dgst)
{
    MD5_CTX  ctx;
    uint8_t  k_ipad[64];
    uint8_t  k_opad[64];
    uint8_t  tk[MD5_DIGEST_LENGTH];
    uint32_t i;
    uint8_t  *k=(uint8_t*)key;

    if (key_len > 64) {
      MD5_Init (&ctx);
      MD5_Update (&ctx, key, key_len);
      MD5_Final (tk, &ctx);

      key = tk;
      key_len = MD5_DIGEST_LENGTH;
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
    MD5_Init (&ctx);                             // init context for 1st pass
    MD5_Update (&ctx, k_ipad, 64);               // start with inner pad
    MD5_Update (&ctx, text, text_len);           // then text of datagram
    MD5_Final (dgst, &ctx);                      // finish up 1st pass
    /**
     * perform outer
     */
    MD5_Init (&ctx);                             // init context for 2nd pass
    MD5_Update (&ctx, k_opad, 64);               // start with outer pad
    MD5_Update (&ctx, dgst, MD5_DIGEST_LENGTH);  // then results of 1st hash
    MD5_Final (dgst, &ctx);                      // finish up 2nd pass
}
/*
 *	hstr_i -- Convert two-digit hex string to unsigned integer
 *
 *	Inputs:
 *
 *	cptr	Two-digit hex string
 *
 *	Returns:
 *
 *	Number corresponding to input hex value.
 *
 *	An input of "0A" or "0a" would return 10.
 *	Note that this function does no sanity checking, it's up to the
 *	caller to ensure that *cptr points to at least two hex digits.
 *
 *	This function is a modified version of hstr_i at www.snippets.org.
 */
uint32_t
hstr_i(const char *cptr)
{
      uint32_t i;
      uint32_t j = 0;
      int k;

      for (k=0; k<2; k++) {
            i = *cptr++ - '0';
            if (9 < i)
                  i -= 7;
            j <<= 4;
            j |= (i & 0x0f);
      }
      return j;
}

/*
 *	hex2data -- Convert hex string to binary data
 *
 *	Inputs:
 *
 *	string		The string to convert
 *	data_len	(output) The length of the resultant binary data
 *
 *	Returns:
 *
 *	Pointer to the binary data.
 *
 *	The returned pointer points to malloc'ed storage which should be
 *	free'ed by the caller when it's no longer needed.  If the length of
 *	the input string is not even, the function will return NULL and
 *	set data_len to 0.
 */
uint8_t *
hex2data(const char *string, size_t *data_len) {
   uint8_t *data;
   uint8_t *cp;
   uint32_t i;
   size_t len;

   if (strlen(string) %2 ) {	/* Length is odd */
      *data_len = 0;
      return NULL;
   }

   len = strlen(string) / 2;
   data = (uint8_t*)malloc(len);
   cp = data;
   for (i=0; i<len; i++)
      *cp++=hstr_i(&string[i*2]);
   *data_len = len;
   return data;
}

int main(int argc, char *argv[]) 
{
  int i;
/*
 *	The values below are observed values from a Firewall-1 NG AI R54 system
 *	using IKE Aggressive mode with PSK authentication and MD5 hash.
 *	The ID used was "test", and the valid pre-shared key is "abc123".
 *      The expected hash_r is "f995ec2968f695aeb1d4e4b437f49d26".
 */
/*
  const char *g_xr_hex = "9c1e0e07828af45086a4eb559ad8dafb7d655bab38656609426653565ef7e332bed7212cf24a05048032240256a169a68ee304ca500abe073d150bc50239350446ab568132aebcf34acd25ce23b30d0de9f8e7a89c22ce0dec2dabf0409bc25f0988d5d956916dce220c630d2a1fda846667fdecb20b2dc2d5c5b8273a07095c";
  const char *g_xi_hex = "6f8c74c15bb4dd09b7af8d1c23e7b381a38dddcd4c5afb3b1335ff766f0267df8fdca0ea907ef4482d8164506817d10ba4aed8f108d32c1b082b91772df956bcd5f7a765759bada21c11f28429c48fcd7267be7b3aea96421528b9432110fff607a65b7c41091e5d1a10e143d4701147d7cfc211ba5853cf800d12a11d129724";
  const char *cky_r_hex = "6d08132c8abb6931";
  const char *cky_i_hex = "eac82ea45cbe59e6";
  const char *sai_b_hex = "00000001000000010000002c01010001000000240101000080010001800200018003000180040002800b0001000c000400007080";
  const char *idir_b_hex = "01000000ac100202";
  const char *ni_b_hex = "64745a975dbcd95c2abf7d2eeeb93ac4633a03f1";
  const char *nr_b_hex = "502c0b3872518fa1e7ff8f5a28a3d797f65e2cb1";
*/
  const char *g_xr_hex = "9f7341ddbb10b1755b8d1b1d0df322ebfe9b61bba84832e8802f5948849dc0067a372778920accedb26bfb1a9cd6d44a94af22473a700eb933363665a0b569ba6693736dd1f222d77733b00c80830e99002728ec210919333a83cb880d695dc8e4a9f7c335d7c8beeadd3c5cb0705e98eaf1401e724d6d18dad0cfd4085fa0ed";
  const char *g_xi_hex = "ffec90eebcff9d6ae1ff125bb18feb873270aeaecd46331b44166e19205dee373739c61b3e8de0d9259498503c39d525d7fb789da67cb297fa2d53f99eb769d2e6cab378647a4241eec639a82bd3bdabdfc7ecb75791b1637704fb759af418e6664b7ba9bee46f9afa1e37ae0013bae12205fec7e94022f0c6771cb7e3f34476";
  const char *cky_r_hex = "45e3b461eb3bb9bd";
  const char *cky_i_hex = "2863d9b328c5f856";
  const char *sai_b_hex = "00000001000000010000002c01010001000000240101000080010005800200018003000180040002800b0001000c000400007080";
  const char *idir_b_hex = "011101f4c0a80365";
  
  const char *ni_b_hex = "cb7575191bd1b2a8d81a564fc0eb4e0789f26ca4";
  const char *nr_b_hex = "eb51fbc778a6db0676152116dc336af0";

  const char *expected_hash = "755183cf3195401790cb8257243e1017";

  uint8_t *g_xr, *g_xi, *cky_r, *cky_i, *sai_b, *idir_b, *ni_b, *nr_b;
  size_t g_xr_len, g_xi_len, cky_r_len, cky_i_len, sai_b_len, idir_b_len, ni_b_len, nr_b_len;
  uint8_t *skeyid, *hash_r, *skeyid_data, *hash_r_data;
  size_t skeyid_data_len, hash_r_data_len;
  uint8_t *cp;

  //const uint8_t *psk = (const uint8_t *) "abc123";	/* correct key */
  uint8_t *psk = (uint8_t *) "abcde";	/* correct key */
  size_t psk_len = strlen((char*)psk);

  g_xr = hex2data(g_xr_hex, &g_xr_len);
  g_xi = hex2data(g_xi_hex, &g_xi_len);
  cky_r = hex2data(cky_r_hex, &cky_r_len);
  cky_i = hex2data(cky_i_hex, &cky_i_len);
  sai_b = hex2data(sai_b_hex, &sai_b_len);
  idir_b = hex2data(idir_b_hex, &idir_b_len);
  
  ni_b = hex2data(ni_b_hex, &ni_b_len);
  nr_b = hex2data(nr_b_hex, &nr_b_len);

  skeyid_data_len = ni_b_len + nr_b_len;
  skeyid_data = (uint8_t*)malloc(skeyid_data_len);
  
  cp = skeyid_data;
  memcpy(cp, ni_b, ni_b_len);
  
  cp += ni_b_len;
  memcpy(cp, nr_b, nr_b_len);
  
  skeyid = (uint8_t*)malloc(16);
  
  // =============================================================
  hash_r_data_len = g_xr_len + g_xi_len + cky_r_len + cky_i_len + sai_b_len + idir_b_len;
  hash_r_data = (uint8_t*)malloc(hash_r_data_len);
  cp = hash_r_data;
  
  memcpy(cp, g_xr, g_xr_len);
  cp += g_xr_len;
  
  memcpy(cp, g_xi, g_xi_len);
  cp += g_xi_len;
  
  memcpy(cp, cky_r, cky_r_len);
  cp += cky_r_len;
  
  memcpy(cp, cky_i, cky_i_len);
  cp += cky_i_len;
  
  memcpy(cp, sai_b, sai_b_len);
  cp += sai_b_len;
  
  memcpy(cp, idir_b, idir_b_len);
  hash_r = (uint8_t*)malloc(16);
  
  MD5_HMAC(skeyid_data, skeyid_data_len, psk, psk_len, skeyid);
  MD5_HMAC(hash_r_data, hash_r_data_len, skeyid, 16, hash_r);
  
  putchar('\n');
  for (i = 0;i < 16;i++) {
    printf("%02x", hash_r[i]); 
  }
  return 0;
}
