

// test code written by Markku-Juhani O. Saarinen

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>

#include "blake2.h"

int blake2(void *out, size_t outlen,
    const void *key, size_t keylen,
    const void *in, size_t inlen)
{
    blake2_ctx ctx;

    if (blake2_init(&ctx, outlen, key, keylen))
        return -1;
    blake2_update(&ctx, in, inlen);
    blake2_final(out, &ctx);

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

int blake2_selftest()
{
  #ifdef S
    // grand hash of hash results for BLAKE2s
    const uint8_t blake2_res[32] = {
        0x6A, 0x41, 0x1F, 0x08, 0xCE, 0x25, 0xAD, 0xCD,
        0xFB, 0x02, 0xAB, 0xA6, 0x41, 0x45, 0x1C, 0xEC,
        0x53, 0xC5, 0x98, 0xB2, 0x4F, 0x4F, 0xC7, 0x87,
        0xFB, 0xDC, 0x88, 0x79, 0x7F, 0x4C, 0x1D, 0xFE };
    const size_t b2_md_len[4] = { 16, 20, 28, 32 };
    const size_t b2_in_len[6] = { 0,  3,  64, 65, 255, 1024 };
  #else
    // grand hash of hash results for BLAKE2b
    const uint8_t blake2_res[32] = {
        0xC2, 0x3A, 0x78, 0x00, 0xD9, 0x81, 0x23, 0xBD,
        0x10, 0xF5, 0x06, 0xC6, 0x1E, 0x29, 0xDA, 0x56,
        0x03, 0xD7, 0x63, 0xB8, 0xBB, 0xAD, 0x2E, 0x73,
        0x7F, 0x5E, 0x76, 0x5A, 0x7B, 0xCC, 0xD4, 0x75 };
    const size_t b2_md_len[4] = { 20, 32, 48, 64 };
    const size_t b2_in_len[6] = { 0, 3, 128, 129, 255, 1024 };
  #endif
    // parameter sets


    size_t i, j, outlen, inlen;
    uint8_t in[1024], md[OUTLEN], key[KEYLEN];
    blake2_ctx ctx;

    // 256-bit hash for testing
    if (blake2_init(&ctx, 32, NULL, 0))
        return -1;

    for (i = 0; i < 4; i++) {
        outlen = b2_md_len[i];
        for (j = 0; j < 6; j++) {
            inlen = b2_in_len[j];

            selftest_seq(in, inlen, inlen);     // unkeyed hash
            blake2(md, outlen, NULL, 0, in, inlen);
            blake2_update(&ctx, md, outlen);   // hash the hash

            selftest_seq(key, outlen, outlen);  // keyed hash
            blake2(md, outlen, key, outlen, in, inlen);
            blake2_update(&ctx, md, outlen);   // hash the hash
        }
    }

    // compute and compare the hash of hashes
    blake2_final(md,&ctx);
    for (i = 0; i < 32; i++) {
        if (md[i] != blake2_res[i])
            return -1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    printf("blake2%s_selftest() = %s\n", VERSION,
         blake2_selftest() ? "FAIL" : "OK");

    return 0;
}
