/**
  Copyright © 2018 Odzhan. All Rights Reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  3. The name of the author may not be used to endorse or promote products
  derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

#define COUNTER_LENGTH 4
#define BLOCK_LENGTH   16
#define TAG_LENGTH     16
#define BC_KEY_LENGTH  16
#define ENCRYPT        BCEncrypt

void BCEncrypt(void *in, void *out, void *key);

#include "../include/macros.h"

#include "aesx.h"

#define PRESENT_RNDS 32

//void aes(void*,void*);
//void aes_encrypt (aes_ctx *ctx, void *state, int enc);

typedef unsigned char u8;
typedef unsigned int u32;
/*
size_t hex2bin (void *bin, char hex[]) {
  size_t len, i;
  int x;
  uint8_t *p=(uint8_t*)bin;
  
  len = strlen (hex);
  
  if ((len & 1) != 0) {
    return 0; 
  }
  
  for (i=0; i<len; i++) {
    if (isxdigit((int)hex[i]) == 0) {
      return 0; 
    }
  }
  
  for (i=0; i<len / 2; i++) {
    sscanf (&hex[i * 2], "%2x", &x);
    p[i] = (uint8_t)x;
  } 
  return len / 2;
} 
 
uint8_t sub_byte(uint8_t x)
{
  const uint8_t sbox[16] =
  { 0xc, 0x5, 0x6, 0xb, 0x9, 0x0, 0xa, 0xd,
    0x3, 0xe, 0xf, 0x8, 0x4, 0x7, 0x1, 0x2 };

  return (sbox[(x & 0xF0) >> 4] << 4) |
          sbox[(x & 0x0F)];
}

void present(void *key, void *data) {
  w64_t  p, t, k0, k1;
  int    i, j, r;

  w128_t *k=(w128_t*)key;
  w64_t  *x=(w64_t*)data;

  // load 128-bit key
  k0.q = k->q[0]; k1.q = k->q[1];

  // load 64-bit plain text
  p.q = x->q;

  for (i=0; i<PRESENT_RNDS-1; i++) {
    // apply key whitening
    p.q ^= k1.q;
    // apply non-linear operation
    // replace 16 nibbles with sbox values
    for (j=0; j<8; j++) {
      p.b[j] = sub_byte(p.b[j]);
    }
    // apply linear operation
    // bit permutation
    t.q = 0;
    r   = 0x30201000;

    for (j=0; j<64; j++) {
      t.q |= ((p.q >> j) & 1) << (r & 255);
      r = ROTR32(r+1, 8);
    }
    p.q = t.q;

    // create next round key
    k0.q ^= (i + i) + 2;
    t.q   = k1.q;

    // rotate
    k1.q = (k1.q << 61) | (k0.q >> 3);
    k0.q = (k0.q << 61) | ( t.q >> 3);

    //
    k1.q    = ROTL64(k1.q, 8);
    k1.b[0] = sub_byte(k1.b[0]);
    k1.q    = ROTR64(k1.q, 8);
  }
  // post whitening and save
  x->q = (p.q ^ k1.q);
}*/
/**
typedef union _lm_t {
  u32 ctr;
  u32 w[BLOCK_LENGTH/sizeof(u32)];
  u8  b[BLOCK_LENGTH];
} lm_t;

#define F(a,b)for(a=0;a<b;a++)
  
void lm(u8*b,u32 l,u8*k,u8*t) 
{
  u32 i,j;
  struct{u32 c;u8 b[12];}m;
  
  F(i,16)t[i]=0;
  m.c=0;i=0;
  while(l){
    m.b[i++]=*b++;
    if(i==12) {
      m.c++;
      E(k,&m);
      F(i,16)
        t[i]^=m.b[i];      
      i=0;
    }
    l--;
  }
  m.b[i++]=0x80;
  j=i;
  F(i,j)t[i]^=m.b[i];
  k+=16;
  E(k,t);
}
*/
void BCEncrypt(void *in, void *out, void *key) {
  u8      temp[BLOCK_LENGTH];
  aes_ctx c;
  //AES_ctx c;

  memcpy(temp, in, BLOCK_LENGTH);
  
  aes_setkey(&c, key);
  aes_encrypt(&c, temp, AES_ENCRYPT);
  //aes(key, temp);
  //AES_init_ctx(&c, key);
  //AES_ECB_encrypt(&c, temp);
  memcpy(out, temp, BLOCK_LENGTH);
}

void encodeCounter(unsigned int counter, uint8_t* output) {
  int i;
  for(i = COUNTER_LENGTH-1; i>=0; i--) {
    output[i] = counter;
    counter >>= 8;
  }
}

void lightmac2(uint8_t* message, u32 messageLength, uint8_t* output, uint8_t* key) {
  // Intermediate values used to store computations
  uint8_t value[BLOCK_LENGTH];
  uint8_t blockInput[BLOCK_LENGTH];
  uint8_t blockOutput[BLOCK_LENGTH];
  
  u32 counter;
  unsigned int i;

  for(i = 0; i < BLOCK_LENGTH; i++) {
    blockOutput[i]=blockInput[i]=value[i] = 0;
  }

  // Note: the counter starts at 1, not 0.
  counter = 1;
  
  // We stop the moment we are left with a message of length less than
  // BLOCK_LENGTH-COUNTER_LENGTH, after which padding occurs.
  while(messageLength >= (BLOCK_LENGTH - COUNTER_LENGTH)) {

    encodeCounter(counter, blockInput);

    // Appending BLOCK_LENGTH-COUNTER_LENGTH bytes of the message to
    // the counter to form a byte string of length BLOCK_LENGTH.
    for(i = 0; i < (BLOCK_LENGTH - COUNTER_LENGTH); i++) {
      blockInput[i+COUNTER_LENGTH] = message[i];
    }

    BCEncrypt(blockInput, blockOutput, key);

    // XORing the block cipher output to the previously XORed block
    // cipher outputs.
    for(i = 0; i < BLOCK_LENGTH; i++) {
      value[i] ^= blockOutput[i];
    }
    messageLength -= (BLOCK_LENGTH - COUNTER_LENGTH);
    message       += (BLOCK_LENGTH - COUNTER_LENGTH);
    counter++;
  }

  // Copying the remaining part of the message, and then applying
  // padding.
  for(i = 0; i < messageLength; i++) {
    blockInput[i] = message[i];
  }
  // Padding step 1: appending a '1'
  blockInput[messageLength] = 0x80;
  // Padding step 2: append as many zeros as necessary to complete the
  // block.
  for(i = messageLength+1; i < BLOCK_LENGTH; i++) {
    blockInput[i] = 0x00;
  }

  // Xoring the final block with the sum of the previous block cipher
  // outputs
  for(i = 0; i < BLOCK_LENGTH; i++) {
    value[i] ^= blockInput[i];
  }

  // Using the second part of the key for the final block cipher call.
  key += BC_KEY_LENGTH;
  BCEncrypt(value, blockOutput, key);
  
  // Truncation is performed to the most significant bits. We assume big endian encoding.
  for(i = 0; i < TAG_LENGTH; i++) {
    output[i] = blockOutput[i];
  }
}

#ifdef TEST

#include <stdio.h>
#include <stdint.h>
#include <string.h>

u8 k1[16]={0x63, 0xcd, 0xae, 0x6e, 0xbf, 0x34, 0xdb, 0xd5, 0x54, 0x1b, 0xd9, 0xf6, 0x93, 0x0c, 0xdc, 0x09};
u8 k2[16]={0xde, 0x9b, 0x7a, 0x5a, 0xa6, 0xa0, 0x5a, 0xe7, 0xec, 0x93, 0xe0, 0x3f, 0x30, 0x1d, 0x77, 0xef};

u8 m1[64]={0x55, 0x7f, 0xbd, 0x6b, 0x41, 0x52, 0xce, 0xf6, 0x92, 0x41, 0x04, 0xec, 0xf5, 0xd5, 0x28, 0xaf, 
         0x8f, 0xb0, 0xaa, 0x10, 0x43, 0xa6, 0xa8, 0xd9, 0xc3, 0x57, 0xb5, 0x0e, 0xe0, 0x04, 0x83, 0xab, 
         0xe2, 0xe0, 0x50, 0xec, 0x80, 0x36, 0x86, 0x0f, 0xa2, 0x24, 0x59, 0x38, 0x54, 0x29, 0xa7, 0x52, 
         0x6d, 0x10, 0x04, 0xc4, 0x87, 0x9e, 0x64, 0xa5, 0x80, 0x50, 0x06, 0xb2, 0xe4, 0x47, 0x37, 0xf2};

u8 t1[16]={0xc7, 0x17, 0xaa, 0x88, 0xf4, 0x87, 0x97, 0xa2, 0x1f, 0xc5, 0xf2, 0xff, 0x33, 0x93, 0x50, 0xc6};
        
        
u8 k3[16]={0x63, 0xcd, 0xae, 0x6e, 0xbf, 0x34, 0xdb, 0xd5, 0x54, 0x1b, 0xd9, 0xf6, 0x93, 0x0c, 0xdc, 0x09};
u8 k4[16]={0xde, 0x9b, 0x7a, 0x5a, 0xa6, 0xa0, 0x5a, 0xe7, 0xec, 0x93, 0xe0, 0x3f, 0x30, 0x1d, 0x77, 0xef};

u8 m2[64]={0x55, 0x7f, 0xbd, 0x6b, 0x41, 0x52, 0xce, 0xf6, 0x92, 0x41, 0x04, 0xec, 0xf5, 0xd5, 0x28, 0xaf, 
         0x8f, 0xb0, 0xaa, 0x10, 0x43, 0xa6, 0xa8, 0xd9, 0xc3, 0x57, 0xb5, 0x0e, 0xe0, 0x04, 0x83, 0xab, 
         0xe2, 0xe0, 0x50, 0xec, 0x80, 0x36, 0x86, 0x0f, 0xa2, 0x24, 0x59, 0x38, 0x54, 0x29, 0xa7, 0x52, 
         0x6d, 0x10, 0x04, 0xc4, 0x87, 0x9e, 0x64, 0xa5, 0x80, 0x50, 0x06, 0xb2};
         
u8 t2[16]={0xa5, 0x5b, 0x49, 0x3a, 0xf6, 0x22, 0x6e, 0x2e, 0x15, 0x3d, 0x8f, 0xd4, 0x3c, 0x13, 0x51, 0xf0};
 
void bin2hex(char *s, void *p, int len) {
    int i;
    printf("%s : ", s);
    for (i=0; i<len; i++) {
      printf ("%02x", ((uint8_t*)p)[i]);
    }
    putchar('\n');
}
/**
#include "sha2.h"
 
 void deriveKey(void*key,char*id,void*out) {
     SHA256_CTX c;
     u8         h[32];
     
     SHA256_Init(&c);
     SHA256_Update(&c,key,BC_KEY_LENGTH);
     SHA256_Update(&c,id,strlen(id));
     SHA256_Final(h, &c);
     
     memcpy(out, h, BC_KEY_LENGTH);
 }
 */
char* test_lm(void *k1_tv,void *k2_tv, void *m_tv, u32 m_len, void *tag_tv, void *r)  
{
    u8       key[BC_KEY_LENGTH*2];
    
    //deriveKey(k1_tv, "k1", key);
    //deriveKey(k2_tv, "k2", &key[BC_KEY_LENGTH]);
    
    memcpy(key, k1_tv, 16);
    memcpy(&key[16], k2_tv, 16);
    
    lightmac2(m_tv, m_len, r, key);
  
    return (memcmp(r, tag_tv, TAG_LENGTH)==0) ? "OK" : "FAILED";
}

int main(void) {
  
  char *s1,*s2, r1[TAG_LENGTH], r2[TAG_LENGTH];
  
  memset(r1, 0, sizeof(r1));
  memset(r2, 0, sizeof(r2));
  
  s1 = test_lm(k1, k2, m1, 64, t1, r1);
  bin2hex("r1", r1, TAG_LENGTH);
  
  s2 = test_lm(k3, k4, m2, 60, t2, r2);
  bin2hex("r2", r2, TAG_LENGTH);
  
  printf("\nTest #1 : %s\nTest #2 : %s\n", s1, s2);
  return 0;
}

#endif
