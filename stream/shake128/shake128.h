
#ifndef SHAKE128_H
#define SHAKE128_H

#define R(v,n)(((v)>>(n))|((v)<<(64-(n))))
#define F(a,b)for(a=0;a<b;a++)

typedef unsigned long long W;
typedef unsigned char B;

typedef struct _shake_ctx {
    int i;
    union {
      B b[200];
      W q[25];
    } s;
}shake_ctx;

#ifdef __cplusplus
extern "C" {
#endif

void shake128(W len,void *in,shake_ctx *c);

#ifdef __cplusplus
}
#endif

#endif
