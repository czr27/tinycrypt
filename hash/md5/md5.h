

#ifndef MD5_H
#define MD5_H

#define R(v,n)(((v)<<(n))|((v)>>(32-(n))))
#define F(n)for(i=0;i<n;i++)

typedef unsigned long long Q;
typedef unsigned int W;
typedef unsigned char B;

typedef struct _md5_ctx {
    W s[4];
    union {
      B b[64];
      W w[16];
      Q q[8];
    }x;
    Q len;
} md5_ctx;

#ifdef __cplusplus
extern "C" {
#endif

void md5_init(md5_ctx *ctx);
void md5_update(md5_ctx *ctx, const void *data, W len);
void md5_final(void *out, md5_ctx *ctx);

#ifdef __cplusplus
}
#endif

#endif
