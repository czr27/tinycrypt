/**
  Copyright © 2015 Odzhan. All Rights Reserved.

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

#ifndef BLOWFISH_H
#define BLOWFISH_H

#include "../../macros.h"

#define BF_ROUNDS  16
#define BF_BLOCK    8
#define BF_KEY_MIN  4
#define BF_KEY_MAX 56

#define BF_ENCRYPT 0
#define BF_DECRYPT 1

#pragma pack(8)
typedef struct _BF_KEY {
  uint32_t p[BF_ROUNDS+2];
  uint32_t sbox1[256];
  uint32_t sbox2[256];
  uint32_t sbox3[256];
  uint32_t sbox4[256];
} BF_KEY;

#ifdef __cplusplus
extern "C" {
#endif

  void BF_encrypt (uint32_t*, const BF_KEY*);
  void BF_decrypt (uint32_t*, const BF_KEY*);
  int BF_set_key (BF_KEY*, uint32_t, uint8_t*);
  void BF_ecb_encrypt(const uint8_t *in, uint8_t *out, BF_KEY *key, int enc);
  
#ifdef __cplusplus
};
#endif

#endif
