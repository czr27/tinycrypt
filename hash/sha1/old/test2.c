
#include <openssl/sha.h>

#define sha1_init(x) SHA1_Init(x)
#define sha1_update(x,y,z) SHA1_Update(x,y,z)
#define sha1_final(x,y) SHA1_Final(x,y)

typedef SHA_CTX sha1_ctx;

// test code written by Markku-Juhani O. Saarinen

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void sha1(void *out, const void *in, size_t inlen)
{
    sha1_ctx ctx;

    sha1_init(&ctx);
    sha1_update(&ctx, in, inlen);
    sha1_final(out, &ctx);
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


int sha1_selftest(void)
{
    // Grand hash of hash results.
    const uint8_t sha1_res[20] = {
      0x0c, 0xce, 0x6c, 0x1a, 0x08, 0x73, 0xdb, 0x99,
      0xd4, 0x91, 0xd1, 0xc7, 0x82, 0x48, 0x24, 0x18,
      0x20, 0xd9, 0x36, 0xe9 };
    // Parameter sets.
    const size_t s2_in_len[6] = { 0,  3,  64, 65, 255, 1024 };

    size_t i, j, outlen, inlen;
    uint8_t in[1024], md[32], key[32];
    sha1_ctx ctx;

    // 160-bit hash for testing.
    sha1_init(&ctx);

    for (j = 0; j < 6; j++) {
        inlen = s2_in_len[j];

        selftest_seq(in, inlen, inlen);
        sha1(md, in, inlen);
        sha1_update(&ctx, md, 20);
    }

    // Compute and compare the hash of hashes.
    sha1_final(md, &ctx);
    
    for (i = 0; i < 20; i++) {
      if (md[i] != sha1_res[i])
        return -1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    printf("sha1_selftest() = %s\n",
         sha1_selftest() ? "FAIL" : "OK");

    return 0;
}
