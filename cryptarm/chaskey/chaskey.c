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

#include "chaskey.h"

void chas_encryptx(void *key, void *data)
{
   int      i;
   uint32_t *x=(uint32_t*)data;
   uint32_t *k=(uint32_t*)key;

   // mix key
   for (i=0; i<4; i++) x[i] ^= k[i];

   // apply permutation
   for (i=16; i>0; i--) {
     x[0] += x[1];
     x[1]=ROTR32(x[1],27) ^ x[0];
     x[2] += x[3];
     x[3]=ROTR32(x[3],24) ^ x[2];
     x[2] += x[1];
     x[0]=ROTR32(x[0],16) + x[3];
     x[3]=ROTR32(x[3],19) ^ x[0];
     x[1]=ROTR32(x[1],25) ^ x[2];
     x[2]=ROTR32(x[2],16);
   }
   // mix key
   for (i=0; i<4; i++) x[i] ^= k[i];
}
