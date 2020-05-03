

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/sha.h>

int main(void) {
    
    uint8_t    buf[128], dgst[32];
    SHA256_CTX ctx;
    int        i;
    
    memset(buf, 0, sizeof(buf));
    
    SHA256_Init(&ctx);
    
    for(i=1; i<128; i++) {
      buf[i] = i;
      
      SHA256_Update(&ctx, buf, i);
    }
    SHA256_Final(dgst, &ctx);
    
    printf("SHA256 Hash = ");
    for(i=0; i<32; i++) {
      if((i & 7) == 0) putchar('\n');
      printf("0x%02X, ", dgst[i]);
    }
    putchar('\n');
    
    return 0;
}
