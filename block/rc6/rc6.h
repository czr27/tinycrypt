
// RC6 in C
// Odzhan

#ifndef RC6_H
#define RC6_H

#define RC6_ROUNDS 20
#define RC6_KR     (2*(RC6_ROUNDS+2))

#define R(v,n)(((v)<<(n))|((v)>>(32-(n))))
#define F(n)for(i=0;i<n;i++)
typedef unsigned int W;

typedef struct _rc6_ctx {
  W x[RC6_KR];
} rc6_ctx;

#ifdef __cplusplus
extern "C" {
#endif

void rc6(void *mk, void *data);
  
#ifdef __cplusplus
}
#endif

#endif
