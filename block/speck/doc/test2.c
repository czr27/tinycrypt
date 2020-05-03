

// test unit for speck
// odzhan

#include <stdio.h>
#include <string.h>
#include <stdint.h>

void print_bytes(char *s, void *p, int len) {
  int i;
  printf("%s : ", s);
  for (i=0; i<len; i++) {
    printf ("%02x ", ((uint8_t*)p)[i]);
  }
  putchar('\n');
}

// SPECK128/256 test vectors
//
uint8_t key128[]=
{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
  0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
  0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f };

uint8_t plain128[]=
{ 0x70, 0x6f, 0x6f, 0x6e, 0x65, 0x72, 0x2e, 0x20,
  0x49, 0x6e, 0x20, 0x74, 0x68, 0x6f, 0x73, 0x65};

uint64_t cipher128[2] = {0x4eeeb48d9c188f43, 0x4109010405c0f53e};

#define R(v,n)(((v)>>(n))|((v)<<(64-(n))))
#define F(n)for(i=0;i<n;i++)
typedef unsigned long long W;

void speck128(void*mk,void*p){
  W k[4],*x=p,i,t;

  // load 256-bit key
  F(4)k[i]=((W*)mk)[i];
  
  // encrypt 128-bit plaintext
  F(34)
    // apply linear+nonlinear layer
    x[1] = (R(x[1], 8) + x[0]) ^ k[0],
    x[0] = R(x[0], 61) ^ x[1],
    
    // create next subkey
    k[1] = (R(k[1], 8) + k[0]) ^ i,
    k[0] = R(k[0], 61) ^ k[1],
    
    // permute key
    t = k[1],k[1]=k[2],k[2]=k[3],k[3]=t;
}

void speck128(void*,void*);

int main (void)
{
  uint64_t buf[2];
  int      equ;
  
  // copy plain text to local buffer
  memcpy (buf, plain128, sizeof(plain128));

  speck128(key128, buf);
    
  equ = memcmp(cipher128, buf, sizeof(cipher128))==0;
    
  printf ("\nSPECK128/256 encryption %s\n", equ ? "OK" : "FAILED");
  print_bytes("CT result  ", buf, sizeof(buf));
  print_bytes("CT expected", cipher128, sizeof(cipher128));
  print_bytes("K ", key128,    sizeof(key128));
  print_bytes("PT", plain128,  sizeof(plain128));

  return 0;
}
