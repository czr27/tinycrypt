
// test unit for lightmac-speck64/128
// odzhan

#include "speck.h"
#include "lightmac.h"

#ifdef USE_ASM
#define LMX_TAG(w,x,y,z) lightmac_tagx(w,x,y,z)
#else
#define LMX_TAG(w,x,y,z) lightmac_tag(w,x,y,z)
#endif
  
int lightmac_verify(const void *msg, 
    uint32_t msglen, void* tag, void* key) 
{      
  uint8_t tempTag[TAG_LENGTH];

  LMX_TAG(msg, msglen, tempTag, key);

  return memcmp(tag, tempTag, TAG_LENGTH) == 0;
}

size_t hex2bin (void *bin, char hex[]) {
  size_t len, i;
  int x;
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

// print digest
void bin2hex (uint8_t dgst[], size_t len)
{
  size_t i;
  for (i=0; i<len; i++) {
    printf ("%02x", dgst[i]);
  }
  putchar ('\n');
}

// test vectors
char *tv_tags[]=
{"5879618221708542",
 "a341cb594f222049",
 "339306bc29b1722f",
 "c228f5f63e8a147b",
 "a632c0bef0cc1582",
 "575be292aa881e6c",
 "383bbdcad0cf0b91",
 "7160ddad2be774ee",
 "8e52b43b71067d97" };

#define NUMVECS 9

int main(void) 
{
  uint8_t key[LIGHTMAC_KEY_LENGTH];
  uint8_t message[2056];
  uint8_t output[TAG_LENGTH], tag[TAG_LENGTH];
  char    temp[4113];
  int     messageLengths[NUMVECS] = {0, 257, 514, 771, 1028, 1285, 1542, 1799, 2056};
  int     i, j, equ;
  
  for(i = 0; i < 4; i++) {
    for(j = 0; j < 256; j++) {
      message[2*j + i*512] = (uint8_t) i;
      message[2*j+1 + i*512] = (uint8_t) j;
    }
  }
  for(j = 0; j < 4; j++) {
    message[2048+2*j] = (uint8_t) 4;
    message[2048+2*j+1] = (uint8_t) j;
  }

  hex2bin(key, "0123456789abcdeffedcba98765432109cf35e82f26719c4f91cf900cc2cbcc1");

  bin2hex(key, LIGHTMAC_KEY_LENGTH);
  
  for (i=0; i<NUMVECS; i++) {
    hex2bin(tag, tv_tags[i]);
    equ = lightmac_verify(message, messageLengths[i], tag, key);
    printf ("\nTest vector #%i for length %4i : %s", 
        (i+1), messageLengths[i], equ ? "OK" : "FAILED");
  }
}
