
#ifndef SHA3_H
#define SHA3_H

#define R(v,n)(((v)>>(n))|((v)<<(64-(n))))
#define F(a,b)for(a=0;a<b;a++)
  
typedef unsigned long long W;
typedef unsigned char B;

typedef struct _sha3_ctx {
    union {
      B b[200];
      W q[25];
    } s;
    int i,h,r;
} sha3_ctx;

#ifdef __cplusplus
extern "C" {
#endif

void sha3_init(sha3_ctx*c, int len);
void sha3_update(sha3_ctx*c, const void*in, W len);
void sha3_final(void*out, sha3_ctx*c);

#ifdef __cplusplus
}
#endif

#endif
