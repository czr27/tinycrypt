#include <string.h>
#include <stdint.h>
#include <stdio.h>

#define FRAMEBITSEMPTY  0x01
#define FRAMEBITS0      0x02
#define FRAMEBITS00     0x04
#define FRAMEBITS10     0x05
#define FRAMEBITS01     0x06
#define FRAMEBITS11     0x07

/*  Ketje rounds */
#define Ket_StartRounds     12
#define Ket_StepRounds      1
#define Ket_StrideRounds    6

#define Ketje_LaneSize  (SnP_width/8/25)
#define Ketje_BlockSize (((SnP_width <= 400)?2:4)*Ketje_LaneSize)

#define KCP_DeclareKetFunctions(prefix) \
void prefix##_StateAddByte( void *state, unsigned char value, unsigned int offset ); \
unsigned char prefix##_StateExtractByte( void *state, unsigned int offset ); \
void prefix##_StateOverwrite( void *state, unsigned int offset, const unsigned char *data, unsigned int length ); \
void prefix##_Step( void *state, unsigned int size, unsigned char frameAndPaddingBits ); \
void prefix##_FeedAssociatedDataBlocks( void *state, const unsigned char *data, unsigned int nBlocks ); \
void prefix##_UnwrapBlocks( void *state, const unsigned char *ciphertext, unsigned char *plaintext, unsigned int nBlocks ); \
void prefix##_WrapBlocks( void *state, const unsigned char *plaintext, unsigned char *ciphertext, unsigned int nBlocks ); \

#define KeccakP200_implementation      "8-bit compact implementation"
#define KeccakP200_stateSizeInBytes    25
#define KeccakP200_stateAlignment      1

#define KeccakP200_StaticInitialize()
void KeccakP200_Initialize(void *state);
void KeccakP200_AddByte(void *state, unsigned char data, unsigned int offset);
void KeccakP200_AddBytes(void *state, const unsigned char *data, unsigned int offset, unsigned int length);
void KeccakP200_OverwriteBytes(void *state, const unsigned char *data, unsigned int offset, unsigned int length);
void KeccakP200_OverwriteWithZeroes(void *state, unsigned int byteCount);
void KeccakP200_Permute_Nrounds(void *state, unsigned int nrounds);
void KeccakP200_Permute_18rounds(void *state);
void KeccakP200_ExtractBytes(const void *state, unsigned char *data, unsigned int offset, unsigned int length);
void KeccakP200_ExtractAndAddBytes(const void *state, const unsigned char *input, unsigned char *output, unsigned int offset, unsigned int length);

    KCP_DeclareKetFunctions(KetJr)

typedef unsigned char UINT8;
typedef unsigned int tSmallUInt; /*INFO It could be more optimized to use "unsigned char" on an 8-bit CPU    */
typedef UINT8 tKeccakLane;

#define ROL8(a, offset) (UINT8)((((UINT8)a) << (offset&7)) ^ (((UINT8)a) >> (8-(offset&7))))

const UINT8 KeccakP200_RotationConstants[25] =
{
     1,  3,  6, 10, 15, 21, 28, 36, 45, 55,  2, 14, 27, 41, 56,  8, 25, 43, 62, 18, 39, 61, 20, 44
};

const UINT8 KeccakP200_PiLane[25] =
{
    10,  7, 11, 17, 18,  3,  5, 16,  8, 21, 24,  4, 15, 23, 19, 13, 12,  2, 20, 14, 22,  9,  6,  1
};

#define MOD5(argValue)    ((argValue) % 5)

const UINT8 KeccakF200_RoundConstants[] =
{
    0x01, 0x82, 0x8a, 0x00, 0x8b, 0x01, 0x81, 0x09, 0x8a, 0x88, 0x09, 0x0a, 0x8b, 0x8b, 0x89, 0x03, 0x02, 0x80
};

/* ---------------------------------------------------------------- */

void KeccakP200_Initialize(void *argState)
{
    memset( argState, 0, 25 * sizeof(tKeccakLane) );
}

/* ---------------------------------------------------------------- */

void KeccakP200_AddByte(void *argState, unsigned char byte, unsigned int offset)
{
    ((tKeccakLane*)argState)[offset] ^= byte;
}

/* ---------------------------------------------------------------- */

void KeccakP200_AddBytes(void *argState, const unsigned char *data, unsigned int offset, unsigned int length)
{
    tSmallUInt i;
    tKeccakLane * state = (tKeccakLane*)argState + offset;
    for(i=0; i<length; i++)
        state[i] ^= data[i];
}

/* ---------------------------------------------------------------- */

void KeccakP200_OverwriteBytes(void *state, const unsigned char *data, unsigned int offset, unsigned int length)
{
    memcpy((unsigned char*)state+offset, data, length);
}

/* ---------------------------------------------------------------- */

void KeccakP200_OverwriteWithZeroes(void *state, unsigned int byteCount)
{
    memset(state, 0, byteCount);
}

/* ---------------------------------------------------------------- */

void KeccakP200_Permute_Nrounds(void *argState, unsigned int nr)
{
    tSmallUInt x, y;
    tKeccakLane temp;
    tKeccakLane BC[5];
    tKeccakLane *state;
    const tKeccakLane *rc;

    state = (tKeccakLane*)argState;
    rc = KeccakF200_RoundConstants + 18 - nr;
    do
    {
        /* Theta */
        for ( x = 0; x < 5; ++x )
        {
            BC[x] = state[x] ^ state[5 + x] ^ state[10 + x] ^ state[15 + x] ^ state[20 + x];
        }
        for ( x = 0; x < 5; ++x )
        {
            temp = BC[MOD5(x+4)] ^ ROL8(BC[MOD5(x+1)], 1);
            for ( y = 0; y < 25; y += 5 )
            {
                state[y + x] ^= temp;
            }
        }

        /* Rho Pi */
        temp = state[1];
        for ( x = 0; x < 24; ++x )
        {
            BC[0] = state[KeccakP200_PiLane[x]];
            state[KeccakP200_PiLane[x]] = ROL8( temp, KeccakP200_RotationConstants[x] );
            temp = BC[0];
        }

        /*    Chi */
        for ( y = 0; y < 25; y += 5 )
        {
            for ( x = 0; x < 5; ++x )
            {
                BC[x] = state[y + x];
            }
            for ( x = 0; x < 5; ++x )
            {
                state[y + x] = BC[x] ^((~BC[MOD5(x+1)]) & BC[MOD5(x+2)]);
            }
        }

        /*    Iota */
        temp = *(rc++);
        state[0] ^= temp;
    }
    while( temp != 0x80 );
}

/* ---------------------------------------------------------------- */

void KeccakP200_Permute_18rounds(void *argState)
{
    KeccakP200_Permute_Nrounds(argState, 18);
}

/* ---------------------------------------------------------------- */

void KeccakP200_ExtractBytes(const void *state, unsigned char *data, unsigned int offset, unsigned int length)
{
    memcpy(data, (UINT8*)state+offset, length);
}

/* ---------------------------------------------------------------- */

void KeccakP200_ExtractAndAddBytes(const void *argState, const unsigned char *input, unsigned char *output, unsigned int offset, unsigned int length)
{
    unsigned int i;
    tKeccakLane * state = (tKeccakLane*)argState + offset;
    for(i=0; i<length; i++)
        output[i] = input[i] ^ state[i];
}

/* ---------------------------------------------------------------- */

#define Ket_Minimum( a, b ) (((a) < (b)) ? (a) : (b))

    #define prefix                      KetJr
    #define SnP                         KeccakP200
    #define SnP_width                   200
    #define SnP_PermuteRounds           KeccakP200_Permute_Nrounds
    
#define JOIN0(a, b)                         a ## b
#define JOIN(a, b)                          JOIN0(a, b)

#define SnP_AddBytes                        JOIN(SnP, _AddBytes)
#define SnP_AddByte                         JOIN(SnP, _AddByte)
#define SnP_OverwriteBytes                  JOIN(SnP, _OverwriteBytes)
#define SnP_ExtractBytes                    JOIN(SnP, _ExtractBytes)
#define SnP_ExtractAndAddBytes              JOIN(SnP, _ExtractAndAddBytes)

#define Ket_StateTwistIndexes               JOIN(prefix, _StateTwistIndexes)
#define Ket_StateAddByte                    JOIN(prefix, _StateAddByte)
#define Ket_StateExtractByte                JOIN(prefix, _StateExtractByte)
#define Ket_StateOverwrite                  JOIN(prefix, _StateOverwrite)
#define Ket_Step                            JOIN(prefix, _Step)
#define Ket_FeedAssociatedDataBlocks        JOIN(prefix, _FeedAssociatedDataBlocks)
#define Ket_UnwrapBlocks                    JOIN(prefix, _UnwrapBlocks)
#define Ket_WrapBlocks                      JOIN(prefix, _WrapBlocks)

const unsigned char Ket_StateTwistIndexes[] = {  
    0,  6, 12, 18, 24,
    3,  9, 10, 16, 22,
    1,  7, 13, 19, 20,
    4,  5, 11, 17, 23,
    2,  8, 14, 15, 21
};


/* Permutation state management functions   */

void Ket_StateAddByte( void *state, unsigned char value, unsigned int offset )
{
    SnP_AddByte(state, value, Ket_StateTwistIndexes[offset / Ketje_LaneSize] * Ketje_LaneSize + offset % Ketje_LaneSize);
}

unsigned char Ket_StateExtractByte( void *state, unsigned int offset )
{
    unsigned char data[1];

    SnP_ExtractBytes(state, data, Ket_StateTwistIndexes[offset / Ketje_LaneSize] * Ketje_LaneSize + offset % Ketje_LaneSize, 1);
    return data[0];
}

void Ket_StateOverwrite( void *state, unsigned int offset, const unsigned char *data, unsigned int length )
{
	while ( length-- != 0 )
	{
	    SnP_OverwriteBytes(state, data, Ket_StateTwistIndexes[offset / Ketje_LaneSize] * Ketje_LaneSize + offset % Ketje_LaneSize, 1);
		++data;
		++offset;
	}
}

/* Ketje low level functions    */

void Ket_Step( void *state, unsigned int size, unsigned char frameAndPaddingBits)
{

    SnP_AddByte(state, frameAndPaddingBits, Ket_StateTwistIndexes[size / Ketje_LaneSize] * Ketje_LaneSize + size % Ketje_LaneSize);
    SnP_AddByte(state, 0x08, Ket_StateTwistIndexes[Ketje_BlockSize / Ketje_LaneSize] * Ketje_LaneSize);
    SnP_PermuteRounds(state, Ket_StepRounds);
}

void Ket_FeedAssociatedDataBlocks( void *state, const unsigned char *data, unsigned int nBlocks )
{
	unsigned int laneIndex;

    do
    {
		for ( laneIndex = 0; laneIndex < (Ketje_BlockSize / Ketje_LaneSize); ++laneIndex )
		{
	        SnP_AddBytes( state, data, Ket_StateTwistIndexes[laneIndex] * Ketje_LaneSize, Ketje_LaneSize );
			data += Ketje_LaneSize;
		}
        Ket_Step( state, Ketje_BlockSize, FRAMEBITS00 );
    }
    while ( --nBlocks != 0 );
}

void Ket_UnwrapBlocks( void *state, const unsigned char *ciphertext, unsigned char *plaintext, unsigned int nBlocks )
{
	unsigned int laneIndex;

    while ( nBlocks-- != 0 )
    {
		for ( laneIndex = 0; laneIndex < (Ketje_BlockSize / Ketje_LaneSize); ++laneIndex )
		{
	        SnP_ExtractAndAddBytes( state, ciphertext, plaintext, Ket_StateTwistIndexes[laneIndex] * Ketje_LaneSize, Ketje_LaneSize );
	        SnP_AddBytes(state, plaintext, Ket_StateTwistIndexes[laneIndex] * Ketje_LaneSize, Ketje_LaneSize);
			plaintext += Ketje_LaneSize;
			ciphertext += Ketje_LaneSize;
		}
        SnP_AddByte(state, 0x08 | FRAMEBITS11, Ket_StateTwistIndexes[Ketje_BlockSize / Ketje_LaneSize] * Ketje_LaneSize);
        SnP_PermuteRounds(state, Ket_StepRounds);
    }
}

void Ket_WrapBlocks( void *state, const unsigned char *plaintext, unsigned char *ciphertext, unsigned int nBlocks )
{
	unsigned int laneIndex;

    while ( nBlocks-- != 0 )
    {
		for ( laneIndex = 0; laneIndex < (Ketje_BlockSize / Ketje_LaneSize); ++laneIndex )
		{
	        SnP_AddBytes(state, plaintext, Ket_StateTwistIndexes[laneIndex] * Ketje_LaneSize, Ketje_LaneSize);
	        SnP_ExtractBytes( state, ciphertext, Ket_StateTwistIndexes[laneIndex] * Ketje_LaneSize, Ketje_LaneSize );
			plaintext += Ketje_LaneSize;
			ciphertext += Ketje_LaneSize;
		}
        SnP_AddByte(state, 0x08 | FRAMEBITS11, Ket_StateTwistIndexes[Ketje_BlockSize / Ketje_LaneSize] * Ketje_LaneSize);
        SnP_PermuteRounds(state, Ket_StepRounds);
    }
}

#undef SnP_AddBytes
#undef SnP_AddByte
#undef SnP_OverwriteBytes
#undef SnP_ExtractBytes
#undef SnP_ExtractAndAddBytes

#undef Ket_StateExtractByte
#undef Ket_StateOverwrite
#undef Ket_Step
#undef Ket_FeedAssociatedDataBlocks
#undef Ket_UnwrapBlocks
#undef Ket_WrapBlocks

    #undef prefix
    #undef SnP
    #undef SnP_width
    #undef SnP_PermuteRounds
    
    /** The phase is a data element that expresses what Ketje is doing
 * - virgin: the only operation supported is initialization, loading the key and nonce. This will switch
 *   the phase to feedingAssociatedData
 * - feedingAssociatedData: Ketje is ready for feeding associated data, has started feeding associated data
 *   or has finished feeding associated data. It allows feeding some more associated data in which case the phase does not
 *   change. One can also start wrapping plaintext, that sets the phase to wrapping. Finally, one can
 *   start unwrapping ciphertext, that sets the phase to unwrapping.
 * - wrapping: Ketje is ready for wrapping some more plaintext or for delivering the tag.
 *   Wrapping more plaintext does not modify the phase, asking for the tag sets the phase to feedingAssociatedData.
 * - unwrapping: Ketje is ready for unwrapping some more ciphertext or for delivering the tag.
 *   Unwrapping more ciphertext does not modify the phase, asking for the tag sets the phase to feedingAssociatedData.
 */
enum Phase {
    Ketje_Phase_Virgin          = 0,
    Ketje_Phase_FeedingAssociatedData   = 1,
    Ketje_Phase_Wrapping        = 2,
    Ketje_Phase_Unwrapping      = 4
};

#define KCP_DeclareKetjeStructure(prefix, size, alignment) \
    ALIGN(alignment) typedef struct prefix##InstanceStruct { \
        unsigned char state[size]; \
        unsigned int phase; \
        unsigned int dataRemainderSize; \
    } prefix##_Instance;

#define KCP_DeclareKetjeFunctions(prefix) \
    int prefix##_Initialize(prefix##_Instance *instance, const unsigned char *key, unsigned int keySizeInBits, const unsigned char *nonce, unsigned int nonceSizeInBits); \
    int prefix##_FeedAssociatedData(prefix##_Instance *instance, const unsigned char *data, unsigned int dataSizeInBytes); \
    int prefix##_WrapPlaintext(prefix##_Instance *instance, const unsigned char *plaintext, unsigned char *ciphertext, unsigned int dataSizeInBytes); \
    int prefix##_UnwrapCiphertext(prefix##_Instance *instance, const unsigned char *ciphertext, unsigned char *plaintext, unsigned int dataSizeInBytes); \
    int prefix##_GetTag(prefix##_Instance *instance, unsigned char *tag, unsigned int tagSizeInBytes);
    