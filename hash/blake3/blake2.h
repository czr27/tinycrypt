

#ifndef BLAKE2_H
#define BLAKE2_H

#define R(v,n)(((v)>>(n))|((v)<<(WORDLEN-(n))))
#define X(a,b)(t)=(a),(a)=(b),(b)=(t)
#define F(n)for(i=0;i<n;i++)

typedef unsigned char B;
typedef unsigned long long Q;

// parameters for BLAKE2s
#ifdef S
#define VERSION  "s"
#define WORDLEN  32
#define BLOCKLEN 64
#define ROUNDS   80
#define ROTATION 0x07080C10
#define OUTLEN   32
#define KEYLEN   32
typedef unsigned int W;
#else
// parameters for BLAKE2b
#define VERSION   "b"
#define WORDLEN   64
#define BLOCKLEN 128
#define ROUNDS    96
#define ROTATION 0x3F101820
#define OUTLEN    64
#define KEYLEN    64
typedef unsigned long long W;
#endif

typedef struct _blake2_ctx {
    W s[16], idx, outlen;
    union {
      B b[BLOCKLEN];
      W w[BLOCKLEN/(WORDLEN/8)];
    }x;
    Q len;
} blake2_ctx;

#ifdef __cplusplus
extern "C" {
#endif

int blake2_init(blake2_ctx*,W,const void*,W);
void blake2_update(blake2_ctx*,const void*,W);
void blake2_final(void*,blake2_ctx*);

#ifdef __cplusplus
}
#endif

#endif
