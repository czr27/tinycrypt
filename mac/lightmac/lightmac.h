
#ifndef LIGHTMAC_H
#define LIGHTMAC_H

#include <stdint.h>

typedef uint8_t u8;
typedef uint32_t u32;
typedef uint64_t u64;

#if defined(AES)
  
  // AES-128/128
  
  #include "aes.h"
    
  #define CTR_LEN     4
  #define BLK_LEN    16
  #define TAG_LEN    16
  #define BC_KEY_LEN 16

  #define ENC(x,y) aes(x,y)

#elif defined(PRESENT)

  // PRESENT-64/128
  
  #include "present.h"
  
  #define CTR_LEN     1
  #define BLK_LEN     8
  #define TAG_LEN     8
  #define BC_KEY_LEN 16

  #define ENC(x,y) present(x,y)

#endif

#define MSG_LEN    (BLK_LEN - CTR_LEN)
#define LM_KEY_LEN (BC_KEY_LEN * 2)

#ifdef __cplusplus
extern "C" {
#endif

void lightmac(void *data, uint32_t len, void *tag, void *mk);

#ifdef __cplusplus
}
#endif

#endif
