

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>

#include "shake128.h"

char *tv_key[] =
{ "84e950051876050dc851fbd99e6247b8",
  "1b801a21fa50971afeba3cc75ea69a88",
  "0a13ad2c7a239b4ba73ea6592ae84ea9",
  "84e950051876050dc851fbd99e6247b8" };

char *tv_hash[] =
{ "8599bd89f63a848c49ca593ec37a12c6",
"3a297aa69f0317aaa3c1ee3e4f351e0802d8e15d6f66c8917b804260571f8218c63bc93fbe6cba518fba8ae378438e6704f01ac60def5818086bad26df228eea7b5830acd42708fa5e73a0694482057d386a9d8c15266561a478983b44e412727388405b678ff8fa6c33a64eec52b7fe422e16e7e92b",
"5feaf99c15f48851943ff9baa6e5055d8377f0dd347aa4dbece51ad3a6d9ce0c01aee9fe2260b80a4673a909b532adcdd1e421c32d6460535b5fe392a58d2634979a5a104d6c470aa3306c400b061db91c463b2848297bca2bc26d1864ba49d7ff949ebca50fbf79a5e63716dc82b600bd52ca7437ed774d169f6bf02e46487956fba2230f34cd2a0485484d",
"8599BD89F63A848C49CA593EC37A12C624AE947CF3F916FF91D1761AA1E20E5278DFF421EDFEFD77E1998490F2C9F4F26F4A2D9501253532A7704E2919280C5B58D748327D9D3953C46DD9498B7AE49E1ABEF7A10DE90E8D988B5A2E9C9DE747373B5906E29CA7AFEFBA53B243D60A636D35EFE783CECC671353060D006D25688451D1576B0E2649ADAED0B6C3A5493DCA413C944D7810A38EDD98A4A92CE666181C91354551BEB42F85AB9E1FAD46E0A9735AEA5B01CA450C2E1D46BF18E57286249F7CD8F6885D3BC78B28D0483300A851B0F4AF6A8A9E83E8C8948898464010922D17F7186DD730D6E0C5DDC4B1D74DD4E46647C3DCA7203B6AFAF0E4051F" };

size_t hex2bin (void *bin, char hex[]) {
    size_t  len, i;
    int     x;
    uint8_t *p=(uint8_t*)bin;

    len = strlen (hex);

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

void bin2hex(char *str, uint8_t *x, int len) {
    int i;
    
    printf("%s : ", str);
    for (i=0; i<len; i++)
      printf("%02X", x[i]);
    printf("\n");
}

int main(void) {
  
    uint8_t   key[16], h[1024], buf[1024];
    int       i, fail=0, h_len;
    shake_ctx c;
    
    for(i=0;i<sizeof(tv_key)/sizeof(char*);i++) {
      hex2bin(key,tv_key[i]);
      h_len = hex2bin(h,tv_hash[i]);
      
      printf("testing output length = %i\n", h_len);
      
      // set the key
      shake128(0, key, &c);
      // get stream
      memset(buf, 0, sizeof(buf));
      shake128(sizeof(buf), buf, &c);
      
      if(memcmp(h, buf, 16)) {
        bin2hex("hash  ", h, 16);
        bin2hex("result", buf, 16);
        printf ("Hash for test vector %i failed\n", i+1);
        fail++;
      }     
    }
    if(!fail) printf ("\nAll SHAKE128 tests passed\n");  
    return 0;
}

