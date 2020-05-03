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
  
#ifndef BLABLA_H
#define BLABLA_H

#include "../../macros.h"

#define BLABLA_STATE_LEN 128
#define BLABLA_BLK_LEN   128
#define BLABLA_KEY_LEN    32
#define BLABLA_NONCE_LEN  16
#define BLABLA_ROUNDS     10

typedef union _blabla_ctx_t {
  uint8_t b[128];
  uint32_t w[32];
  uint64_t q[16];
} blabla_ctx;

#ifdef __cplusplus
extern "C" {
#endif

  void blabla_setkey(blabla_ctx*, const void*, const void*);
  void blabla_encrypt(blabla_ctx*,void*,size_t);
  void blabla_keystream(blabla_ctx*,void*,size_t);
  
#ifdef __cplusplus
}
#endif

#endif
  
