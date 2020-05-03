#define R(v,n)(((v)<<(n))|((v)>>(32-(n)))) 
#define F(a,b)for(a=0;a<b;a++) 
typedef unsigned int W;void rc5(void*mk,void*p){W A=0xB7E15163,B,i,X,S[26],L[4],*x=p,*k=mk;F(i,4)L[i]=k[i];F(i,26)S[i]=A,A+=0x9E3779B9;A=B=0;k=S;F(i,78)A=S[i%26]=R(S[i%26]+A+B,3),B=L[i%4]=R(L[i%4]+A+B,A+B);A=x[0]+*k++;B=x[1]+*k++;F(i,12)X=R(A^B,B%32)+*k++,A=B,B=X;x[0]=A;x[1]=B;}