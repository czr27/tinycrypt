#define R(v,n)(((v)<<(n))|((v)>>(32-(n))))
#define X(a,b)(t)=(s[a]),(s[a])=(s[b]),(s[b])=(t)
void gimli(void*p){unsigned int r,j,t,x,y,z,*s=p;for(r=24;r>0;--r){for(j=0;j<4;j++)x=R(s[j],24),y=R(s[4+j],9),z=s[8+j],s[8+j]=x^(z+z)^((y&z)*4),s[4+j]=y^x^((x|z)*2),s[j]=z^y^((x&y)*8);t=r&3;if(!t)X(0,1),X(2,3),*s^=0x9e377900|r;if(t==2)X(0,2),X(1,3);}}
