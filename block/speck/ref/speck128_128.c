#include <stdint.h>
#include <stdio.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint64_t u64;

#define ROTR64(v,n)(((v)>>(n))|((v)<<(64-(n))))

void KeyExpansion ( u64 l[], u64 k[] )
{
    u8 i;
    for ( i=0 ; i<31 ; i++ )
    {
        l[i+1] = ( k[i] + ROTR64(l[i], 8) ) ^ i;
        k[i+1] = ROTR64(k[i], 61) ^ l[i+1];
    }
}

void Encrypt ( u64 text[], u64 crypt[], u64 key[] )
{
    u8 i;
    crypt[0] = text[0];
    crypt[1] = text[1];

    for ( i=0 ; i<32 ; i++ )
    {
        crypt[0] = ( ROTR64(crypt[0], 8) + crypt[1] ) ^ key[i];
        crypt[1] = ROTR64(crypt[1], 61) ^ crypt[0];
    }
}

void Decrypt ( u64 text[], u64 crypt[], u64 key[] )
{
    u8 i;
    crypt[0] = text[0];
    crypt[1] = text[1];

    for ( i=0 ; i<32 ; i++ )
    {
        crypt[1] = ROTR64( crypt[0] ^ crypt[1], 61);
        crypt[0] = ROTR64( (crypt[0] ^ key[31-i]) - crypt[1], 8 );
    }
}

int main ()
{

    u64 text[2];
    text[0] = 0x6c61766975716520;
    text[1] = 0x7469206564616d20;
    u64 crypt[2] = {0};
    u64 l[32] = {0};
    u64 k[32] = {0};
    l[0] = 0x0f0e0d0c0b0a0908;
    k[0] = 0x0706050403020100;


    KeyExpansion ( l, k );
    Encrypt ( text, crypt, k );
    printf("%llx %llx\n%llx %llx\n\n\n", text[0], text[1], crypt[0], crypt[1]);

    KeyExpansion ( l, k );
    Decrypt ( crypt, text, k );
    printf("%llx %llx\n%llx %llx\n\n\n", text[0], text[1], crypt[0], crypt[1]);


    return 0;
}

