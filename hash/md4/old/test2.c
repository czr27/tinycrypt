
#include <openssl/md4.h>

#define md4_init(x) MD4_Init(x)
#define md4_update(x,y,z) MD4_Update(x,y,z)
#define md4_final(x,y) MD4_Final(x,y)

typedef MD4_CTX md4_ctx;

#ifdef TEST

// test code written by Markku-Juhani O. Saarinen

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void md4(void *out, const void *in, size_t inlen)
{
    md4_ctx ctx;

    md4_init(&ctx);
    md4_update(&ctx, in, inlen);
    md4_final(out, &ctx);
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

int md4_selftest(void)
{
    // Grand hash of hash results.
    const uint8_t md4_res[16] = {
       0x75, 0xe6, 0x08, 0x16, 0x24, 0xf7, 0x1a, 0x25, 
       0x14, 0x22, 0x38, 0xf0, 0xdb, 0xe2, 0xf2, 0xfa };
    // Parameter sets.
    const size_t s2_in_len[6] = { 0,  3,  64, 65, 255, 1024 };

    size_t i, j, inlen;
    uint8_t in[1024], md[16];
    md4_ctx ctx;

    // 256-bit hash for testing.
    md4_init(&ctx);

    for (j = 0; j < 6; j++) {
        inlen = s2_in_len[j];

        selftest_seq(in, inlen, inlen);
        md4(md, in, inlen);
        md4_update(&ctx, md,16);
    }

    // Compute and compare the hash of hashes.
    md4_final(md, &ctx);
    
    for (i = 0; i < 16; i++) {
      if (md[i] != md4_res[i])
        return -1;
    }

    return 0;
}

int main(int argc, char **argv)
{
    int     i;
    md4_ctx c;
    uint8_t dgst[16];
    
    if (argc>1) {
      md4_init(&c);
      md4_update(&c, argv[1], strlen(argv[1]));
      md4_final(dgst, &c);
      
      for(i=0;i<16;i++) {
        printf("%02x", dgst[i]);
      }
      putchar('\n');
    }
    printf("md4_selftest() = %s\n",
         md4_selftest() ? "FAIL" : "OK");

    return 0;
}

#endif
