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

#ifndef DES_H
#define DES_H

#include "../../macros.h"

#define DES_BLK_LEN 8
#define DES_ROUNDS 16

#define ROTTABLE      0x7EFC 
#define ROTTABLE_INV  0x3F7E

#define DES_ENCRYPT 0
#define DES_DECRYPT 1

typedef union _des_ctx_t {
	w64_t keys[16+1];
} des_ctx;
  
/* the FIPS 46-3 (1999-10-25) name for triple DES is triple data encryption algorithm so TDEA.
* Also we only implement the three key mode  */

#ifdef __cplusplus
extern "C" {
#endif

  void des_str2key (void*, w64_t*);
	void des_setkey (uint8_t ks[128], void *);
  void des_enc (uint8_t ks[128], void*, void*, int);
	
  void des3_enc (void*, void*, void*, void*, void*);
  void des3_dec (void*, void*, void*, void*, void*);
  
void des_cbc_enc (void*, void*, void*, uint32_t, void*);
uint32_t des_cbc_dec (void*, void*, void*, uint32_t, void*);
  
#ifdef __cplusplus
}
#endif

#endif
