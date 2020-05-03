#include <stdint.h>
#include <string.h>

#include "utils.h"
#include "present.h"

void BCEncrypt(const uint8_t input[8], uint8_t output[8], const uint8_t key[16]) {
    uint8_t result[8];
    
    memcpy(result, input, 8);
    speck64_encryptx(key, result);
    memcpy(output, result, 8);
}

