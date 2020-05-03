// s2.c
// 2017-12-08  Markku-Juhani O. Saarinen <mjos@iki.fi>

// Show that *all* Aria S-Boxes are affine equivalent.

// S2 is weirdly defined as x^247 but of course 247 == -8  (mod 255)
// Since squaring is linear in a binary field, this is actually
// affine equivalent to the inverse operation x^-1 -- just using an
// adjusted matrix is sufficient. Did the Koreans really not know this ?!?!
 
// S-Boxes S3 and S4 also have x^-1 but with affine op before nonlinear op.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

const uint8_t m1[8][8] = {					// S1 (AES) linear transform 
	{ 1, 0, 0, 0, 1, 1, 1, 1 },
	{ 1, 1, 0, 0, 0, 1, 1, 1 },
	{ 1, 1, 1, 0, 0, 0, 1, 1 },
	{ 1, 1, 1, 1, 0, 0, 0, 1 },
	{ 1, 1, 1, 1, 1, 0, 0, 0 },
	{ 0, 1, 1, 1, 1, 1, 0, 0 },
	{ 0, 0, 1, 1, 1, 1, 1, 0 },
	{ 0, 0, 0, 1, 1, 1, 1, 1 }
};

const uint8_t m2[8][8] = {					// Aria S2 linear transform
	{ 0, 1, 0, 1, 0, 1, 1, 1 },
	{ 0, 0, 1, 1, 1, 1, 1, 1 },
	{ 1, 1, 1, 0, 1, 1, 0, 1 },
	{ 1, 1, 0, 0, 0, 0, 1, 1 },
	{ 0, 1, 0, 0, 0, 0, 1, 1 },
	{ 1, 1, 0, 0, 1, 1, 1, 0 },
	{ 0, 1, 1, 0, 0, 0, 1, 1 },
	{ 1, 1, 1, 1, 0, 1, 1, 0 }
};

uint8_t matmul8(uint8_t x, const uint8_t m[8][8])
{
	int i, j;
	uint8_t y;
	
	y = 0;
	for (i = 0; i < 8; i++) {
		if (x & (1 << i)) {
			for (j = 0; j < 8; j++)
				y ^= m[j][i] << j;
		}
	}
	return y;
}

// Prints out Aria sboxes S1 and S2
int main()
{
	int i, x, j;
	uint8_t gf_log[256], gf_exp[256];
	
	x = 0x01;
	for (i = 0; i < 256; i++) {				// exp and log in GF(2^8)
		gf_exp[i] = x;
		gf_log[x] = i;
		x ^= x << 1;
		if (x & 0x100)
			x ^= 0x11B;						// irreducible polynomial
	}	

	for (j = 1; j <= 2; j++) {
		
		printf("\nS%d = \n", j);
	
		for (i = 0; i < 256; i++) {
		
			x = i;
			if (x > 1)
				x = gf_exp[ 255 - gf_log[x] ];	// x^-1

			if (j == 1)
				x = matmul8(x, m1) ^ 0x63;
			else
				x = matmul8(x, m2) ^ 0xE2;
	
			printf(" %02X", x);
			if ((i & 0xF) == 0xF)
				printf("\n");
		}
	}

	return 0;
}
