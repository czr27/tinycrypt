/*
   SipHash reference C implementation
   Copyright (c) 2012-2016 Jean-Philippe Aumasson
   <jeanphilippe.aumasson@gmail.com>
   Copyright (c) 2012 Daniel J. Bernstein <djb@cr.yp.to>
   To the extent possible under law, the author(s) have dedicated all copyright
   and related and neighboring rights to this software to the public domain
   worldwide. This software is distributed without any warranty.
   You should have received a copy of the CC0 Public Domain Dedication along
   with
   this software. If not, see
   <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

#include "vectors.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "../../macros.h"

#define PRINTHASH(n)                                                           \
    printf("    { ");                                                          \
    for (int j = 0; j < n; ++j) {                                              \
        printf("0x%02x, ", out[j]);                                            \
    }                                                                          \
    printf("},\n");

int siphash(const uint8_t *in, const size_t inlen, const uint8_t *k,
            uint8_t *out, const size_t outlen);
            
uint64_t xsiphash(const size_t inlen, const uint8_t *in, const uint8_t *key);
uint64_t xsiphashx(const size_t inlen, const uint8_t *in, const uint8_t *key);
uint32_t xhalfsiphashx(const size_t inlen, const uint8_t *in, const uint8_t *key);
            
int halfsiphash(const uint8_t *in, const size_t inlen, const uint8_t *k,
                uint8_t *out, const size_t outlen);

const char *functions[4] = {
    "const uint8_t vectors_sip64[64][8] =",
    "const uint8_t vectors_sip128[64][16] =",
    "const uint8_t vectors_hsip32[64][4] =",
    "const uint8_t vectors_hsip64[64][8] =",
};

const char *labels[4] = {
    "SipHash 64-bit tag:", "SipHash 128-bit tag:", "HalfSipHash 32-bit tag:",
    "HalfSipHash 64-bit tag:",
};

size_t lengths[4] = {8, 16, 4, 8};

typedef union _w128_t {
  uint8_t b[16];
  uint32_t w[8];
  uint64_t q[2];
} w128_t;

int main() {
    uint8_t in[64], k[16];
    int i;
    int fails = 0;
    w128_t out;
    
    for (i = 0; i < 16; ++i)
        k[i] = i;

    for (int version = 0; version < 4; ++version) {
#ifdef GETVECTORS
        printf("%s\n{\n", functions[version]);
#else
        printf("%s\n", labels[version]);
#endif

        for (i = 0; i < 64; ++i) {
            in[i] = i;
            int len = lengths[version];
            if (version < 2) {
                if (len==16) {
                  siphash(in, i, k, out.b, len);
                } else {
                  out.q[0] = xsiphash(i, in, k);
                }
            }
            else {
              //out.w[0] = xhalfsiphashx(in, i, k, out.b, len);
              out.w[0] = xhalfsiphashx(i, in, k);
            }
#ifdef GETVECTORS
            PRINTHASH(len);
#else
            const uint8_t *v = NULL;
            switch (version) {
            case 0:
                v = (uint8_t *)vectors_sip64;
                break;
            case 1:
                v = (uint8_t *)vectors_sip128;
                break;
            case 2:
                v = (uint8_t *)vectors_hsip32;
                break;
            case 3:
                v = (uint8_t *)vectors_hsip64;
                break;
            default:
                break;
            }

            if (memcmp(out.b, v + (i * len), len)) {
                printf("fail for %d bytes\n", i);
                fails++;
            }
#endif
        }

#ifdef GETVECTORS
        printf("};\n");
#else
        if (!fails)
            printf("OK\n");
#endif
        fails = 0;
    }

    return 0;
}
