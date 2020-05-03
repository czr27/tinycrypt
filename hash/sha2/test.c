

// this test code was originally written by Markku-Juhani O. Saarinen
// i've adapted to work with this

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sha256.h"

void sha256(void *out, const void *in, size_t inlen)
{
    sha256_ctx ctx;

    sha256_init(&ctx);
    sha256_update(&ctx, in, inlen);
    sha256_final(out, &ctx);
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

int sha256_selftest(void)
{
    // Grand hash of hash results.
    const uint8_t sha256_res[32] = {
      0x47, 0xc5, 0x9c, 0x6f, 0x17, 0x4c, 0x6a, 0x99,
      0xaf, 0xa2, 0x24, 0x7b, 0x30, 0x0e, 0x88, 0x5a,
      0x39, 0x6d, 0x0a, 0xfe, 0x76, 0x47, 0xc1, 0x0f,
      0xfe, 0x15, 0x2e, 0x8b, 0x05, 0x4b, 0x47, 0x72, };
    // Parameter sets.
    const size_t s2_in_len[6] = { 0,  3,  64, 65, 255, 1024 };

    size_t i, j, inlen;
    uint8_t in[1024], md[32];
    sha256_ctx ctx;

    // 256-bit hash for testing.
    sha256_init(&ctx);

    for (j = 0; j < 6; j++) {
        inlen = s2_in_len[j];

        selftest_seq(in, inlen, inlen);     // unkeyed hash
        sha256(md, in, inlen);
        sha256_update(&ctx, md, 32);   // hash the hash
    }
    // Compute and compare the hash of hashes.
    sha256_final(md, &ctx);
    
    for (i = 0; i < 32; i++) {
      if (md[i] != sha256_res[i])
        return -1;
    }

    return 0;
}

uint8_t sha2_tv[32] = {
  0x31, 0xC3, 0x0A, 0x45, 0x43, 0xC3, 0x1B, 0x27, 
  0xA9, 0x99, 0x7C, 0x5B, 0xBE, 0x86, 0x8C, 0x13, 
  0x14, 0x09, 0x3E, 0x76, 0x2E, 0xAC, 0x84, 0xC8, 
  0x59, 0x19, 0xD6, 0x8D, 0x49, 0xBD, 0x49, 0xC9 };

int main(int argc, char **argv)
{
    uint8_t    buf[128], dgst[32];
    sha256_ctx ctx;
    int        i;
    
    memset(buf, 0, sizeof(buf));
    
    sha256_init(&ctx);
    
    for(i=1; i<128; i++) {
      buf[i] = i;
      
      sha256_update(&ctx, buf, i);
    }
    sha256_final(dgst, &ctx);
    
    printf("SHA256 Hash = ");
    for(i=0; i<32; i++) {
      if((i & 7) == 0) putchar('\n');
      printf("0x%02X, ", dgst[i]);
    }
    putchar('\n');

    return 0;
}
