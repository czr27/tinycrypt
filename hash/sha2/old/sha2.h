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

#ifndef SHA2_H
#define SHA2_H

#include "../../macros.h"
   
#define SHA256_CBLOCK        64
#define SHA256_DIGEST_LENGTH 32
#define SHA256_LBLOCK        SHA256_DIGEST_LENGTH/4

#pragma pack(push, 1)
typedef struct _SHA256_CTX {
  uint64_t len;
  union {
    uint8_t  b[SHA256_DIGEST_LENGTH];
    uint32_t w[SHA256_DIGEST_LENGTH/4];
    uint64_t q[SHA256_DIGEST_LENGTH/8];
  } s;
  union {
    uint8_t  b[SHA256_CBLOCK];
    uint32_t w[SHA256_CBLOCK/4];
    uint64_t q[SHA256_CBLOCK/8];
  } buf;
} SHA256_CTX;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct _SHA256X_CTX {
  uint32_t len;
  union {
    uint8_t  b[SHA256_DIGEST_LENGTH];
    uint32_t w[SHA256_DIGEST_LENGTH/4];
    uint64_t q[SHA256_DIGEST_LENGTH/8];
  } s;
  union {
    uint8_t  b[SHA256_CBLOCK];
    uint32_t w[SHA256_CBLOCK/4];
    uint64_t q[SHA256_CBLOCK/8];
  } buf;
} SHA256X_CTX;
#pragma pack(pop)

#define SHA512_CBLOCK        128
#define SHA512_DIGEST_LENGTH 64
#define SHA512_LBLOCK        SHA512_DIGEST_LENGTH/4

#pragma pack(push, 1)
typedef struct _SHA512_CTX {
  union {
    uint8_t  b[SHA512_DIGEST_LENGTH];
    uint32_t w[SHA512_DIGEST_LENGTH/4];
    uint64_t q[SHA512_DIGEST_LENGTH/8];
  } state;
  union {
    uint8_t  b[SHA512_CBLOCK];
    uint32_t w[SHA512_CBLOCK/4];
    uint64_t q[SHA512_CBLOCK/8];
  } buffer;
  uint64_t len[2];
} SHA512_CTX;
#pragma pack(pop)

#ifdef __cplusplus
extern "C" {
#endif

  void SHA256_Init (SHA256_CTX*);
  void SHA256_Update (SHA256_CTX*, void*, uint32_t);
  void SHA256_Final (void*, SHA256_CTX*);

  void SHA512_Init (SHA512_CTX*);
  void SHA512_Update (SHA512_CTX*, void *, uint32_t);
  void SHA512_Final (void*, SHA512_CTX*);
  
  void SHA512_Transform (SHA512_CTX *ctx);
#ifdef __cplusplus
}
#endif

#endif