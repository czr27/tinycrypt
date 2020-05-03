
#include <limits.h>
#include <stddef.h>
#include <string.h>
#include <stdint.h>
 
#include "../../macros.h"
 
#define NORX_W 32           /* Word size: 8, 16, 32 or 64 */
#define NORX_L 4           /* Round number: 4 or 6 */

#if NORX_W == 8
  typedef uint8_t norx_word_t;
  #define ROTR(x, s) ROTR8(x, s)
  #define R0  1
  #define R1  3
  #define R2  5
  #define R3  7
#elif NORX_W == 16
  typedef uint16_t norx_word_t;
  #define ROTR(x, s) ROTR16(x, s)  
  #define R0  8
  #define R1 11
  #define R2 12
  #define R3 15
#elif NORX_W == 32
  typedef uint32_t norx_word_t;
  #define ROTR(x, s) ROTR32(x, s)  
  #define R0  8
  #define R1 11
  #define R2 16
  #define R3 31
#elif NORX_W == 64  
  typedef uint64_t norx_word_t;
  #define ROTR(x, s) ROTR64(x, s)  
  #define R0  8
  #define R1 19
  #define R2 40
  #define R3 63
#endif

typedef union _norx_state_t {
  norx_word_t w[16];
} norx_state;
  
/* The non-linear primitive */
// same as addition without using modular ADD
#define H(A, B) ( ( (A) ^ (B) ) ^ ( ( (A) & (B) ) << 1) )

void norx_permutex(void *state, int rnds);

void norx_permute(void *state, int rnds)
{
    int         i, j;
    uint32_t    a, b, c, d, r, t, idx;
    norx_word_t *s=(norx_word_t*)state;
    
    uint16_t idx16[16]=
    { 0xC840, 0xD951, 0xEA62, 0xFB73,    // column index
      0xFA50, 0xCB61, 0xD872, 0xE943 };  // diagnonal index
    
    for (i=0; i<rnds; i++) {
      for (j=0; j<8; j++) {
        idx = idx16[j];
        
        a = (idx         & 0xF);
        b = ((idx >>  4) & 0xF);
        c = ((idx >>  8) & 0xF);
        d = ((idx >> 12) & 0xF);
    
        r = 0x1F100B08;
        
        /* The quarter-round */
        do {
          s[a] = H(s[a], s[b]); 
          s[d] = ROTR(s[d] ^ s[a], r & 0xFF);
          XCHG(c, a);
          XCHG(d, b);
          r >>= 8;
        } while (r != 0);
      }
    }
}


#ifdef TEST

#include <stdio.h>

uint8_t tv[]=
{ 0xec, 0x5f, 0x46, 0xe8, 0x4f, 0x27, 0x53, 0xd3,
  0x30, 0x22, 0x81, 0x28, 0x0a, 0xa1, 0x41, 0x5a,
  0xa3, 0x45, 0xc8, 0xc2, 0xe9, 0xc3, 0x5a, 0xc1,
  0xe5, 0x00, 0xf3, 0x18, 0x61, 0x82, 0x34, 0xb2,
  0xea, 0xb8, 0x7f, 0xe5, 0x9e, 0xc7, 0xd7, 0x6d,
  0x01, 0x33, 0x51, 0x89, 0xb8, 0x39, 0x03, 0xc4,
  0x5d, 0x24, 0x17, 0xa2, 0xf3, 0xd6, 0xf5, 0xc9,
  0x5e, 0x8c, 0x8f, 0x06, 0x40, 0xbb, 0x85, 0x24 };

int main(void) {
  norx_word_t state1[16], state2[16];
  int         i, equ;

  memset(state1, 0, sizeof(state1));
  memset(state2, 0, sizeof(state2));
  
  for (i=0; i<16; i++) state1[i] = i;
  for (i=0; i<16; i++) state2[i] = i;
  
  norx_permute(state1, 8);
   
  equ = (memcmp(state1, tv, sizeof(state1))==0);
  
  printf ("\nC Test %s\n\n", equ ? "OK" : "FAILED");
  
  printf ("[*] state 1\n");
  for (i=0; i<sizeof(state1); i++) {
    if ((i & 7)==0) putchar('\n');
    printf ("0x%02x, ", ((uint8_t*)&state1)[i]);
  }

  norx_permutex(state2, 8);
  equ = (memcmp(state2, tv, sizeof(state2))==0);
  printf ("\n\nASM Test %s\n\n", equ ? "OK" : "FAILED");
  
  printf("[*] state 2\n");  
  for (i=0; i<sizeof(state2); i++) {
    if ((i & 7)==0) putchar('\n');
    printf ("%02x ", ((uint8_t*)&state2)[i]);
  }
  return 0;
}  
#endif
 