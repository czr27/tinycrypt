#ifndef BLF_H
#define BLF_H

#include <stdint.h>
#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/** 
 * Schneier states the maximum key length to be 56 bytes.
 * The way how the sub keys are initialized by the key up
 * to (N+2)*4 i.e. 72 bytes are utilized.
 * Warning: For normal blowfish encryption only 56 bytes
 * of the key affect all cipher bits.
 */

#define BLF_N	16			/* Number of Subkeys */
#define BLF_MAXKEYLEN ((BLF_N-2)*4)	/* 448 bits */
#define BLF_MAXUTILIZED ((BLF_N+2)*4)	/* 576 bits */

/* Blowfish context */
typedef struct BlowfishContext {
	uint32_t S[4][256];	/* S-Boxes */
	uint32_t P[BLF_N + 2];	/* Subkeys */
} blf_ctx;

/* Raw access to customized Blowfish
 *	blf_key is just:
 *	Blowfish_initstate( state )
 *	Blowfish_expand0state( state, key, keylen )
 */

void Blowfish_encipher(blf_ctx *, uint32_t *);
void Blowfish_decipher(blf_ctx *, uint32_t *);
void Blowfish_initstate(blf_ctx *);
void Blowfish_expand0state(blf_ctx *, const uint8_t *, uint16_t);
void Blowfish_expandstate(blf_ctx *, const uint8_t *, uint16_t, const uint8_t *, uint16_t);

/* Standard Blowfish */

void blf_key(blf_ctx *, const uint8_t *, uint16_t);
void blf_enc(blf_ctx *, uint32_t *, uint16_t);
void blf_dec(blf_ctx *, uint32_t *, uint16_t);

/* Converts uint8_t to uint32_t */
uint32_t Blowfish_stream2word(const uint8_t *, uint16_t ,
				    uint16_t *);

void blf_ecb_encrypt(blf_ctx *, uint8_t *, uint32_t);
void blf_ecb_decrypt(blf_ctx *, uint8_t *, uint32_t);

void blf_cbc_encrypt(blf_ctx *, uint8_t *, uint8_t *, uint32_t);
void blf_cbc_decrypt(blf_ctx *, uint8_t *, uint8_t *, uint32_t);
#endif
