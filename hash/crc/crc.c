
#include "crc.h"

// crc code derived from code here: https://crccalc.com/

static uint64_t crc_table[256];

// reverse bits of x
static uint64_t rbit(uint64_t x, uint64_t wordlen) {
    uint64_t i, r = 0;
    
    for(i=0; i<wordlen; i++) {
      if((x & (1ULL << i)) != 0) {
        r |= ((1ULL << (wordlen - i - 1)));
      }
    }
    return r;
}
 
static void create_table(crc_param *p, uint64_t m) {
    int      j;
    uint64_t i, r;
    
    for(i=0; i<256; i++) {
      r = (p->rin) ? rbit(i, p->wordlen) : i << (p->wordlen - 8);

      for (j=0; j<8; j++) {
        if (r & (1ULL << (p->wordlen - 1))) {
          r = ((r << 1ULL) ^ p->poly);
        } else {
          r <<= 1ULL;
        }
      }
      r = (p->rout) ? rbit(r, p->wordlen) : r;
      crc_table[i] = (r & m);
    }
}

uint64_t crc(const void *input, size_t len, crc_param *p) {
    uint64_t crc, m=~0ULL;
    uint8_t  *data=(uint8_t*)input;
    int      i;
    
    if(p->wordlen<64) m = (1ULL << p->wordlen) - 1;

    create_table(p, m);
    
    crc = p->rin ? rbit(p->iv, p->wordlen) : p->iv;
    
    for(i=0; i<len; i++) {
      if (p->rout) {
        crc = (crc >> 8) ^ crc_table[(crc&0xFF)^data[i]];
      } else {
        crc = (crc << 8) ^ crc_table[(crc>>(p->wordlen-8))^data[i]];  
      }
      crc &= m;
    }
    return (crc ^ p->xor) & m;
}

