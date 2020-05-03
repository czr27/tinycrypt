// sha3.h
// 19-Nov-11  Markku-Juhani O. Saarinen <mjos@iki.fi>

#ifndef SHA3_H
#define SHA3_H

#include <stddef.h>
#include <stdint.h>

#ifndef KECCAKF_ROUNDS
#define KECCAKF_ROUNDS 24
#endif

#ifndef ROTL64
#define ROTL64(x, y) (((x) << (y)) | ((x) >> (64 - (y))))
#endif

// state context
typedef struct {
    union {                                 // state:
        uint8_t b[200];                     // 8-bit bytes
        uint64_t q[25];                     // 64-bit words
    } st;
    int pt, rsiz, mdlen;                    // these don't overflow
} sha3_ctx;

// Compression function.
void sha3_keccakf(uint64_t st[25]);

// OpenSSL - like interfece
void sha3_init(sha3_ctx *c, int mdlen);    // mdlen = hash output in bytes
void sha3_update(sha3_ctx *c, const void *data, size_t len);
void sha3_final(void *md, sha3_ctx *c);    // digest goes to md

// compute a sha3 hash (md) of given byte length from "in"
void *sha3(void *md, int mdlen,const void *in, size_t inlen);

// SHAKE128 and SHAKE256 extensible-output functions
#define shake128_init(c) sha3_init(c, 16)
#define shake256_init(c) sha3_init(c, 32)
#define shake_update sha3_update

void shake_xof(sha3_ctx *c);
void shake_out(sha3_ctx *c, void *out, size_t len);

#endif

