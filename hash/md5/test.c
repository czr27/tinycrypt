

// test code written by Markku-Juhani O. Saarinen

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "md5.h"

void md5(void *out, const void *in, size_t inlen)
{
    md5_ctx ctx;

    md5_init(&ctx);
    md5_update(&ctx, in, inlen);
    md5_final(out, &ctx);
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

int md5_selftest(void)
{
    // Grand hash of hash results.
    const uint8_t md5_res[16] = {
       0x80, 0x05, 0x62, 0x3b, 0x10, 0xb8, 0xa5, 0x75, 
       0x5e, 0xab, 0xa8, 0x97, 0xd1, 0xa9, 0x1e, 0x2b };
    // Parameter sets.
    const size_t s2_in_len[6] = { 0,  3,  64, 65, 255, 1024 };

    size_t i, j, inlen;
    uint8_t in[1024], md[16];
    md5_ctx ctx;

    // 256-bit hash for testing.
    md5_init(&ctx);

    for (j = 0; j < 6; j++) {
        inlen = s2_in_len[j];

        selftest_seq(in, inlen, inlen);
        md5(md, in, inlen);
        md5_update(&ctx, md,16);
    }

    // Compute and compare the hash of hashes.
    md5_final(md, &ctx);
    
    for (i = 0; i < 16; i++) {
      if (md[i] != md5_res[i])
        return -1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    int     i;
    md5_ctx c;
    uint8_t dgst[16];
    
    if (argc>1) {
      md5_init(&c);
      md5_update(&c, argv[1], strlen(argv[1]));
      md5_final(dgst, &c);
      
      for(i=0;i<16;i++) {
        printf("%02x", dgst[i]);
      }
      putchar('\n');
    }
    printf("md5_selftest() = %s\n",
         md5_selftest() ? "FAIL" : "OK");

    return 0;
}
