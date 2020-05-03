/* The nonlinear primitive */
#define H(A, B) ( ( (A) ^ (B) ) ^ ( ( (A) & (B) ) << 1) )

/* The quarter-round */
#define G(A, B, C, D)                               \
do                                                  \
{                                                   \
    (A) = H(A, B); (D) ^= (A); (D) = ROTR((D), R0); \
    (C) = H(C, D); (B) ^= (C); (B) = ROTR((B), R1); \
    (A) = H(A, B); (D) ^= (A); (D) = ROTR((D), R2); \
    (C) = H(C, D); (B) ^= (C); (B) = ROTR((B), R3); \
} while (0)

/* The full round */
static NORX_INLINE void F(norx_word_t S[16])
{
    /* Column step */
    G(S[ 0], S[ 4], S[ 8], S[12]);
    G(S[ 1], S[ 5], S[ 9], S[13]);
    G(S[ 2], S[ 6], S[10], S[14]);
    G(S[ 3], S[ 7], S[11], S[15]);
    /* Diagonal step */
    G(S[ 0], S[ 5], S[10], S[15]);
    G(S[ 1], S[ 6], S[11], S[12]);
    G(S[ 2], S[ 7], S[ 8], S[13]);
    G(S[ 3], S[ 4], S[ 9], S[14]);
}

/* The core permutation */
static NORX_INLINE void norx_permute(norx_state_t state)
{
    size_t i;
    norx_word_t * S = state->S;

    for (i = 0; i < NORX_L; ++i) {
        F(S);
    }
}