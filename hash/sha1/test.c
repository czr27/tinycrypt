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
  
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef TEST
#include <openssl/sha.h>

#define sha1_ctx SHA_CTX
#define sha1_init SHA1_Init
#define sha1_update SHA1_Update
#define sha1_final SHA1_Final
#else
#include "sha1.h"
#endif

int sha1_selftest(void) {
    
    uint32_t i, equ=0;
    uint8_t  dgst[20], buf[64];
    sha1_ctx ctx;
    uint8_t  sha1_tv[]=
      {0x34, 0x68, 0x5b, 0xc2, 0xfa, 0x72, 0x09, 0x24, 
       0x5c, 0xdc, 0xb6, 0xb8, 0x17, 0xf2, 0x95, 0x09, 
       0x48, 0xfb, 0xf2, 0x1f};
    
    memset(dgst, 0, sizeof(dgst));
    
    for(i=0; i<64; i++) {
      memset(buf, 0, sizeof(buf));
      buf[i] = (uint8_t)i;
      
      sha1_init(&ctx);
      sha1_update(&ctx, buf, (i + 1));
      sha1_update(&ctx, dgst, 20);
      sha1_final(dgst, &ctx);
    }
    
    equ = (memcmp(dgst, sha1_tv, 20)==0);
    return equ;
}

int main(int argc, char **argv)
{
    sha1_ctx ctx;
    int      i;
    uint8_t  dgst[20];
    
    if(argc == 2) {
      sha1_init(&ctx);
      sha1_update(&ctx, argv[1], strlen(argv[1]));
      sha1_final(dgst, &ctx);
      
      printf("SHA-1 : ");
      for(i=0; i<20; i++) {
        printf("%02x", dgst[i]);
      }
      putchar('\n');
      return 0;
    }
    
    printf("sha1_selftest() = %s\n",
         sha1_selftest() ? "OK" : "FAIL");
         
    return 0;
}
