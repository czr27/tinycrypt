
/**
  Maximum Distance Separable (MDS) codes are used as diffusion layers. They provide optimal diffusion effect to meet security of a round function of a block cipher. On the other hand, the constructions of these diffusion layers are various. For example, while the AES use a 4×4 MDS matrix over GF(28), Khazad use an 8×8 involutory MDS matrix over GF(28). In this study, a new involutory 4×4 MDS matrix for the AES-like block ciphers is proposed and an efficient software implementation of this matrix is given. The new involutory matrix replaces Mix Columns operation used in the AES cipher in order to provide equally good performance for both encryption and decryption operations. In the design of our involutory MDS matrix, we use Hadamard matrix construction instead of circulant matrices such as in the AES.
*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

//#define ROTR32(v,n)(((v)>>(n))|((v)<<(32-(n))))

// Multiplication
uint8_t gf_mul(uint8_t x, uint8_t y, uint8_t p)
{
    uint8_t z = 0;

    while (y) {
      if (y & 1) {
        z ^= x;
      }
      x = (x << 1) ^ (x & 0x80 ? p : 0x00);
      y >>= 1;
    }
    return z;
}

// linear layer using involutary matrix
uint32_t mds(uint32_t w) {
    int      i, j;
    uint32_t x0, y;
    
    union {
      uint8_t  b[4];
      uint32_t w;
    } acc, x;

#if defined(SUBFIELD)
#define ROOT 0x13
    uint8_t m[4][4] = {
      { 1,  4,  9, 13 },
      { 4,  1, 13,  9 },
      { 9, 13,  1,  4 },
      {13,  9,  4,  1} };
#elif defined(HADAMARD1)
#define ROOT 0x65
    uint8_t m[4][4] = {
      { 0x01, 0x02, 0xb0, 0xb2 },
      { 0x02, 0x01, 0xb2, 0xb0 },
      { 0xb0, 0xb2, 0x01, 0x02 },
      { 0xb2, 0xb0, 0x02, 0x01 } };
#elif defined(HADAMARD2)
#define ROOT 0x1b
    uint8_t m[4][4] = {
      { 0x01, 0x02, 0xfc, 0xfe },
      { 0x02, 0x01, 0xfe, 0xfc },   
      { 0xfc, 0xfe, 0x01, 0x02 },  
      { 0xfe, 0xfc, 0x02, 0x01 } }; 
#else
#define ROOT 0x1d
    uint8_t m[4][4] = { 
      { 0x01, 0x02, 0x04, 0x06 },
      { 0x02, 0x01, 0x06, 0x04 },
      { 0x04, 0x06, 0x01, 0x02 },
      { 0x06, 0x04, 0x02, 0x01 } };
#endif
    x.w   = w;
    acc.w = 0;

    for (i=0; i<4; i++) {
      for (j=0; j<4; j++) {
        acc.b[j] ^= gf_mul(x.b[i], m[i][j], ROOT);
      }
    }
    return acc.w;
}

// non-linear layer using involutary 4x4 sbox
// This is the Gamma function from Noekeon
void sbox(uint32_t s[]) {
    uint32_t a, b, c, d, t;
    
    a = s[0]; b = s[1]; c = s[2]; d = s[3];
    b ^= ~(d | c); 
    t  = d; 
    d  = a ^ (c & b);
    a  = t;
    c ^= a ^ b ^ d; 
    b ^= ~(d | c);
    a ^= c & b;
    s[0] = a; s[1] = b; s[2] = c; s[3] = d;
}

// modular inverse
uint8_t gf_inv(uint8_t a) {
    uint8_t j, b = a;
    
    for (j = 14; --j;)
        b = gf_mul(b, j & 1 ? b : a, 0x1b); 
    return b;
}

uint32_t mulinv32(uint32_t x) {
    int      i;
    uint32_t r;
    
    for(r=i=0; i<4; i++) {
      r <<= 8;
      r |= gf_inv(x & 0xFF);
      x >>= 8;
    }
    return r;
}

void permute(uint8_t *a) {
    uint8_t tmp;

    tmp   = a[ 1]; 
    a[ 1] = a[ 4]; 
    a[ 4] = tmp;
    
    tmp   = a[ 2]; 
    a[ 2] = a[ 8]; 
    a[ 8] = tmp;
    
    tmp   = a[ 6]; 
    a[ 6] = a[ 9]; 
    a[ 9] = tmp;
    
    tmp   = a[ 3]; 
    a[ 3] = a[12]; 
    a[12] = tmp;
    
    tmp   = a[ 7]; 
    a[ 7] = a[13]; 
    a[13] = tmp;
    
    tmp   = a[11]; 
    a[11] = a[14]; 
    a[14] = tmp;
}

uint8_t invmod(uint8_t a, uint8_t m) {
    uint8_t j = 1, i = 0, b = m, c = a, x, y;

    while (c != 0) {
      x = b / c;
      y = b - x * c;
      b = c; 
      c = y;
      y = j;
      j = i - j * x;
      i = y;
    }
    if((int8_t)i < 0) {
      i += m;
    }
    return i;
}

uint8_t mulmod(uint8_t b, uint8_t e, uint8_t m) {
    uint8_t r = 0, t = b;

    while (e > 0) {
      if (e & 1) {
        r = r + t % m;
      }
      t = t + t % m;
      e >>= 1;
    }
    return r;
}

uint8_t power(uint8_t b, uint8_t e) {
    uint8_t r = 1;

    while (e > 0) {
      if (e & 1) {
        r = r * b;
      }
      b = b * b;
      e >>= 1;
    }
    return r;
}

uint8_t gcd (uint8_t a, uint8_t b) {
    uint8_t c;

    while (a != 0) {
      c = a; 
      a = b % a;  
      b = c;
    }
    return b;
}

void bin2hex(const char *str, void *bin, int len) {
    int i;
    uint8_t *p = (uint8_t*)bin;
    
    printf("%s[%i] = { ", str, len);
    
    for(i=0;i<len;i++) {
      if((i % 8) == 0) putchar('\n');
      printf("0x%02x", p[i]);
      if((i+1) != len) putchar(',');
    }
    printf(" };\n");
}

uint8_t sbox_sq[256] =
{0xb1,0xce,0xc3,0x95,0x5a,0xad,0xe7,0x02,0x4d,0x44,0xfb,0x91,0x0c,0x87,0xa1,0x50,
 0xcb,0x67,0x54,0xdd,0x46,0x8f,0xe1,0x4e,0xf0,0xfd,0xfc,0xeb,0xf9,0xc4,0x1a,0x6e,
 0x5e,0xf5,0xcc,0x8d,0x1c,0x56,0x43,0xfe,0x07,0x61,0xf8,0x75,0x59,0xff,0x03,0x22,
 0x8a,0xd1,0x13,0xee,0x88,0x00,0x0e,0x34,0x15,0x80,0x94,0xe3,0xed,0xb5,0x53,0x23,
 0x4b,0x47,0x17,0xa7,0x90,0x35,0xab,0xd8,0xb8,0xdf,0x4f,0x57,0x9a,0x92,0xdb,0x1b,
 0x3c,0xc8,0x99,0x04,0x8e,0xe0,0xd7,0x7d,0x85,0xbb,0x40,0x2c,0x3a,0x45,0xf1,0x42,
 0x65,0x20,0x41,0x18,0x72,0x25,0x93,0x70,0x36,0x05,0xf2,0x0b,0xa3,0x79,0xec,0x08,
 0x27,0x31,0x32,0xb6,0x7c,0xb0,0x0a,0x73,0x5b,0x7b,0xb7,0x81,0xd2,0x0d,0x6a,0x26,
 0x9e,0x58,0x9c,0x83,0x74,0xb3,0xac,0x30,0x7a,0x69,0x77,0x0f,0xae,0x21,0xde,0xd0,
 0x2e,0x97,0x10,0xa4,0x98,0xa8,0xd4,0x68,0x2d,0x62,0x29,0x6d,0x16,0x49,0x76,0xc7,
 0xe8,0xc1,0x96,0x37,0xe5,0xca,0xf4,0xe9,0x63,0x12,0xc2,0xa6,0x14,0xbc,0xd3,0x28,
 0xaf,0x2f,0xe6,0x24,0x52,0xc6,0xa0,0x09,0xbd,0x8c,0xcf,0x5d,0x11,0x5f,0x01,0xc5,
 0x9f,0x3d,0xa2,0x9b,0xc9,0x3b,0xbe,0x51,0x19,0x1f,0x3f,0x5c,0xb2,0xef,0x4a,0xcd,
 0xbf,0xba,0x6f,0x64,0xd9,0xf3,0x3e,0xb4,0xaa,0xdc,0xd5,0x06,0xc0,0x7e,0xf6,0x66,
 0x6c,0x84,0x71,0x38,0xb9,0x1d,0x7f,0x9d,0x48,0x8b,0x2a,0xda,0xa5,0x33,0x82,0x39,
 0xd6,0x78,0x86,0xfa,0xe4,0x2b,0xa9,0x1e,0x89,0x60,0x6b,0xea,0x55,0x4c,0xf7,0xe2} ;


// "Algorithm P (Shuffling)"

/*

Fisher-Yates shuffle is one such algorithm for achieving a perfect shuffle using a random number generator. The algorithm is named after Ronald Fisher and Frank Yates who first described this algorithm in their book in 1938. Later Donal Knuth and Richard Durstenfeld introduced an improved version of the algorithm in 1964.

It has been around since 1938 but a few poker sites got it wrong and it was exploited. 

A site was exploited is due to off by one (they failed to shuffle the last or first card).

-- To shuffle an array a of n elements (indices 0..n-1):
for i from n−1 downto 1 do
     j ← random integer such that 0 ≤ j ≤ i
     exchange a[j] and a[i]


-- To shuffle an array a of n elements (indices 0..n-1):
for i from 0 to n−2 do
     j ← random integer such that i ≤ j < n
     exchange a[i] and a[j]
     
(* S has items to sample, R will contain the result *)
ReservoirSample(S[1..n], R[1..k])
  // fill the reservoir array
  for i := 1 to k
      R[i] := S[i]

  // replace elements with gradually decreasing probability
  for i := k+1 to n
    (* randomInteger(a, b) generates a uniform integer from the inclusive range {a, ..., b} *)
    j := randomInteger(1, i)
    if j <= k
        R[j] := S[i]
        
def get_permutation(k, lst):
    N = len(lst)
    while N:
        next_item = k/f(N-1)
        lst[N-1], lst[next_item] = lst[next_item], lst[N-1]
        k = k - next_item*f(N-1)
        N = N-1
    return lst
    
getPermutation(k, N) {
    while(N > 0) {
        nextItem = floor(k / (N-1)!)
        output nextItem
        k = k - nextItem * (N-1)!
        N = N - 1
    }
}
     
*/

#define ROTR32(v,n)(((v)>>(n))|((v)<<(32-(n))))
#define ROTR64(v,n)(((v)>>(n))|((v)<<(64-(n))))
#define ROTL64(v,n)(((v)<<(n))|((v)>>(64-(n))))

// bit permutation layer for PRESENT block cipher
uint64_t p_layer(uint64_t x, int inv) {
    uint64_t t, r;
    int      i;
    
    r = 0x0030002000100000;
    
    for(t=i=0; i<64; i++) {
      if(inv) {
        // decryption
        t |= (((x >> (r & 255)) & 1) << i);
      } else {
        // encryption
        t |= ((x >> i) & 1) << (r & 255);
      }
      r  = ROTR64(r+1, 16);
    }
    return t;
}

// bit permutation layer.
// pi holds 8 bytes of 0-7
uint32_t p_layer2(uint32_t x, uint8_t pi[8], int inv) {
    uint32_t i, j, t;

    // for 32-bits
    for(t=i=0; i<4; i++) {
      t <<= 8;
      // for each 8-bits
      for(j=0; j<8; j++) {
        // transpose bit based on value of pi[j]
        if(inv) {
          t |= (((x >> pi[j]) & 1) << j);
        } else {
          t |= (((x >> j) & 1) << pi[j]);
        }
      }
      // discard 8-bits
      x >>= 8;
    }
    return t;
}

// byte substitution
uint32_t s_layer(uint32_t x, uint8_t sbox[16], int inv) {
    union {
      uint8_t  b[4];
      uint32_t w;
    } t;
    uint8_t *s=sbox, sbox_inv[16];
    uint8_t i;
    
    if(inv) {
      // create inverse sbox
      for(i=0; i<16; i++) {
        sbox_inv[sbox[i]] = i;
      }
      s=sbox_inv;
    }
    
    // apply sbox
    for(i=0; i<4; i++) {
      t.b[i] = ((s[(x & 0xF0)>>4]<<4) | s[(x & 0x0F)]);
      x >>= 8;
    }
    return t.w;
}

void p_test(void) {
    uint8_t  t, pi[8];    // pi=permutation
    int      i, j;
    union {
      uint8_t  b[4];
      uint32_t w;
    } x;                  // x=data
    
    // the seed for rand is just an example
    srand(time(0));
    
    // initialize pi to 0-7
    for(i=0; i<8; i++) pi[i] = i;
    
    // randomize pi
    for(i=1; i<=8; i++) {
      j = rand() % i;
      // swap
      t = pi[i]; pi[i] = pi[j]; pi[j] = t;
    }
    
    bin2hex("\n\npi", pi, 8);
    
    // generate some data
    for(i=0; i<4; i++) {
      x.b[i] = rand();
    }
    
    bin2hex("\n\nOriginal: ", x.b, 4);
    
    // apply bit permutation
    x.w = p_layer2(x.w, pi, 0);
    
    bin2hex("\n\nAfter PI: ", x.b, 4);
    
    x.w = p_layer2(x.w, pi, 1);
    
    bin2hex("\n\nInverse PI", x.b, 4);
}
    
// linear layer from serpent using even-mansour construction
void xpermute(void *mk, void *p) {
    uint32_t *x=(uint32_t*)p;
    uint32_t *k=(uint32_t*)mk;
    int      i;
    
    x[0]^=k[0];x[1]^=k[1];
    x[2]^=k[2];x[3]^=k[3];
      
    for(i=0; i<8; i++) {
      x[0]=ROTR32(x[0],19);
      x[2]=ROTR32(x[2],29);
      x[1]^=x[0]^x[2];
      x[3]^=x[2]^(x[0]<<3);
      x[1]=ROTR32(x[1],31);
      x[3]=ROTR32(x[3],25);
      x[0]^=x[1]^x[3];
      x[2]^=x[3]^(x[1]<<7);
      x[0]=ROTR32(x[0],27);
      x[2]=ROTR32(x[2],10);
    }
    
    x[0]^=k[0];x[1]^=k[1];
    x[2]^=k[2];x[3]^=k[3];
}

void zpermute(void *mk, void *p) {
    uint8_t rc = 128;
    uint32_t t;
    uint32_t *k=(uint32_t*)mk;
    uint32_t *x=(uint32_t*)p;
    
    for(;;) {
      x[0]^=rc;
      t=x[0]^x[2];
      t^=ROTR32(t,8)^ROTR32(t,24);
      x[1]^=t;
      x[3]^=t;
      x[0]^=k[0];
      x[1]^=k[1];
      x[2]^=k[2];
      x[3]^=k[3];
      t=x[1]^x[3];
      t^=ROTR32(t,8)^ROTR32(t,24);
      x[0]^=t;
      x[2]^=t;
      // 16th round?
      if(rc==212)break;
      // update round constant
      rc=((rc<<1)^(-(rc>>7)&27));
    }
}

int main(void) {
    union {
      uint8_t  b[16];
      uint32_t w[4];
      uint64_t q[2];
    } s;
    int      i, j, t;
    uint64_t r = 0x0123456789ABCDEF;
    uint8_t  s1[256], s2[256];
    uint8_t perm[16];
    
    //p_test();
    
    // seed the generator
    srand(time(0));
    
    // initialize sbox
    for(i=0; i<16; i++) perm[i] = rand(); s1[i] = rand();
    
    for(i=0; i<4; i++) {
      xpermute(s1, perm);
      bin2hex("result", perm, 16);
    }
    return 0;
    
    // apply random permutation
    for(i=0; i<16; i++) {
      j = rand() % 16; // 0 <= j <= i-1
      // swap
      t = perm[i]; perm[i] = perm[j]; perm[j] = t;
    }
    
    // create the inverse table
    // for(i=0; i<256; i++) s2[s1[i]] = i;
    
    for(i=0; i<8; i++) s.b[i] = rand();
    
    printf("\nBefore MDS\n");
    for(i=0; i<8; i++) printf("%02x ", s.b[i]);

    s.w[0] = s_layer(s.w[0], perm, 0);
    s.w[1] = s_layer(s.w[1], perm, 0);

    printf("\n\nAfter MDS and Sbox\n");
    for(i=0; i<8; i++) printf("%02x ", s.b[i]);
    
    s.w[0] = s_layer(s.w[0], perm, 1);
    s.w[1] = s_layer(s.w[1], perm, 1);
    
    printf("\n\nAfter MDS and Sbox\n");
    for(i=0; i<8; i++) printf("%02x ", s.b[i]);
    putchar('\n');
    
    return 0;
}
