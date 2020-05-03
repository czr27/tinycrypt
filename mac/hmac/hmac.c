/**
  Copyright © 2017 Odzhan. All Rights Reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  3. The name of the author may not be used to endorse or promote products
  derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

#include <stdint.h>

void hmac_sha1 (void *text, size_t text_len, 
  void *key, size_t key_len, void* dgst)
{
    SHA_CTX  ctx;
    uint8_t  k_ipad[64];
    uint8_t  k_opad[64];
    uint8_t  tk[SHA_DIGEST_LENGTH];
    uint32_t i;
    uint8_t  *k=(uint8_t*)key;

    if (key_len > 64) {
      SHA1_Init (&ctx);
      SHA1_Update (&ctx, key, key_len);
      SHA1_Final (tk, &ctx);

      key = tk;
      key_len = SHA_DIGEST_LENGTH;
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
    SHA1_Init (&ctx);                             // init context for 1st pass
    SHA1_Update (&ctx, k_ipad, 64);               // start with inner pad
    SHA1_Update (&ctx, text, text_len);           // then text of datagram
    SHA1_Final (dgst, &ctx);                      // finish up 1st pass
    /**
     * perform outer
     */
    SHA1_Init (&ctx);                             // init context for 2nd pass
    SHA1_Update (&ctx, k_opad, 64);               // start with outer pad
    SHA1_Update (&ctx, dgst, SHA_DIGEST_LENGTH);  // then results of 1st hash
    SHA1_Final (dgst, &ctx);                      // finish up 2nd pass
}
