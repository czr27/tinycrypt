/**
  Copyright (C) 2016 Odzhan.
  Copyright (C) 2001, 2014 Marc Schoolderman
  
  All Rights Reserved.

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
  
#ifndef TF_H
#define TF_H

#include "../../macros.h"

#define TF_ENCRYPT 0
#define TF_DECRYPT 1

#pragma pack(push, 1)
typedef struct _tf_ctx_t {
  uint32_t keys[8+2*16];
  uint8_t  qbox[2][256];
  uint8_t  sbox[4*256];
} tf_ctx;
#pragma pack(pop)

#ifdef __cplusplus
extern "C" {
#endif

  // x86 asm
  void tf_setkeyx (tf_ctx*, void*);
  void tf_encx (tf_ctx*, void*, int);

  // C code
  void tf_setkey (tf_ctx*, void*);  
  void tf_enc (tf_ctx*, void*, int);

#ifdef __cplusplus
}
#endif

#endif
