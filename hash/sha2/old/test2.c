
#include <openssl/sha.h>

#define sha256_init(x) SHA256_Init(x)
#define sha256_update(x,y,z) SHA256_Update(x,y,z)
#define sha256_final(x,y) SHA256_Final(x,y)

typedef SHA256_CTX sha256_ctx;

// test code written by Markku-Juhani O. Saarinen

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
   //   if (!(i&7)) putchar('\n');
   //   printf(" 0x%02x,", md[i]);
      
      if (md[i] != sha256_res[i])
        return -1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    printf("sha256_selftest() = %s\n",
         sha256_selftest() ? "FAIL" : "OK");

    return 0;
}
