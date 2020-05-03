#define P(a,l)x=a;a=S[c=l>>r%4*2&3];S[c]=x;
r,c,x,y,z;
G(unsigned*S){
for(r=24;r;*S^=r--% 4 ? 0 : 0x9e377901+r){
  for(c=4;c--;*S++ = z ^ y ^ 8 * (x & y))
    x = *S << 24 | *S >> 8, 
    y = S[4] << 9 | S[4] >> 23, 
    z = S[8], S[8] = x ^ 2 * z ^ 4 * (y & z),
    S[4] = y ^ x ^ 2 * (x | z);
    S -= 4;
    P(*S, 33)
    P(S[3], 222)
  }
}
