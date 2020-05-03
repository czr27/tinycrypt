

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

// SPECK64/128 test vectors
//
// p = 0x3b7265747475432d 
uint8_t plain64[]=
{ 0x74, 0x65, 0x72, 0x3b,
  0x2d, 0x43, 0x75, 0x74 };

// c = 0x8c6fa548454e028b  
uint8_t cipher64[]=
{ 0x48, 0xa5, 0x6f, 0x8c, 
  0x8b, 0x02, 0x4e, 0x45 };

// key = 0x03020100, 0x0b0a0908, 0x13121110, 0x1b1a1918   
uint8_t key64[]=
{ 0x00, 0x01, 0x02, 0x03,
  0x08, 0x09, 0x0a, 0x0b,
  0x10, 0x11, 0x12, 0x13,
  0x18, 0x19, 0x1a, 0x1b };

#define R(v,n)(((v)>>(n))|((v)<<(32-(n))))
#define F(n)for(i=0;i<n;i++)
typedef unsigned int W;

void speck64(void*mk,void*p){
  W k[4],*x=p,i,t;
  
  F(4)k[i]=((W*)mk)[i];
  
  F(27)
    // apply linear+nonlinear layer, mix key
    x[0] = (R(x[0], 8) + x[1]) ^ k[0],
    x[1] = R(x[1], 29) ^ x[0],
    
    // create next subkey
    k[1] = (R(k[1], 8) + k[0]) ^ i,
    k[0] = R(k[0], 29) ^ k[1],
    
    // permute key
    t = k[1], k[1] = k[2], k[2] = k[3], k[3] = t;
}

int main (void)
{
  uint64_t buf[4];
  int      equ;
  
  // copy plain text to local buffer
  memcpy (buf, plain64, sizeof(plain64));

  speck64(key64, buf);
    
  equ = memcmp(cipher64, buf, sizeof(cipher64))==0;
    
  printf ("\nSPECK64/128 encryption %s\n", equ ? "OK" : "FAILED");
  print_bytes("CT result  ", buf, sizeof(plain64));
  print_bytes("CT expected", cipher64, sizeof(cipher64));
  print_bytes("K ", key64,    sizeof(key64));
  print_bytes("PT", plain64,  sizeof(plain64));

  return 0;
}
