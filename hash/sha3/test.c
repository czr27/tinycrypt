

// this test code was originally written by Markku-Juhani O. Saarinen
// i've adapted to work with this

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>

#include "sha3.h"

int sha3(void *out, size_t outlen,
    const void *in, size_t inlen)
{
    sha3_ctx ctx;

    sha3_init(&ctx, outlen);
    sha3_update(&ctx, in, inlen);
    sha3_final(out, &ctx);

    return 0;
}

// Deterministic sequences (Fibonacci generator).

static void selftest_seq(uint8_t *out, size_t len, uint32_t seed)
{
    size_t i;
    uint32_t t, a , b;

    a = 0xDEAD4BAD * seed;              // prime
    b = 1;

    for (i = 0; i < len; i++) {         // fill the buf
        t = a + b;
        a = b;
        b = t;
        out[i] = (t >> 24) & 0xFF;
    }
}

int sha3_selftest()
{
    // grand hash of hash results
    const uint8_t sha3_res[32] = {
      0xfe, 0xd2, 0x6d, 0x05, 0x27, 0x6a, 0xf6, 0x00,
      0x6c, 0xaa, 0x39, 0x36, 0xe1, 0x4b, 0xaa, 0x09,
      0x33, 0x3e, 0xce, 0x1d, 0x12, 0xad, 0x66, 0x6e,
      0xab, 0x62, 0x2c, 0x9c, 0xda, 0xe7, 0x3f, 0x89 };
      
    // parameter sets
    const size_t md_len[4] = { 20, 32, 48, 64 };
    const size_t in_len[6] = { 0, 3, 128, 129, 255, 1024 };

    size_t i, j, outlen, inlen;
    uint8_t in[1024], md[64];
    sha3_ctx ctx;

    // 256-bit hash for testing
    sha3_init(&ctx, 32);

    for (i = 0; i < 4; i++) {
        outlen = md_len[i];
        for (j = 0; j < 6; j++) {
            inlen = in_len[j];

            selftest_seq(in, inlen, inlen);     // unkeyed hash
            sha3(md, outlen, in, inlen);
            sha3_update(&ctx, md, outlen);   // hash the hash
        }
    }

    // compute and compare the hash of hashes
    sha3_final(md,&ctx);
    
    for (i = 0; i < 32; i++) {
      if (md[i] != sha3_res[i])
        return -1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    printf("sha3_selftest() = %s\n",
         sha3_selftest() ? "FAIL" : "OK");

    return 0;
}
