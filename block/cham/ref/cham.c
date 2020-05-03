#include "func.h"

uint8_t ROL(uint8_t input, int k)
{
	uint8_t temp;
	temp = input;
	temp >>= (8 - k);
	input <<= k;
	temp |= input;
	return temp;
}

uint8_t ROR(uint8_t input, int k)
{
	uint8_t temp;
	temp = input;
	temp <<= (8 - k);
	input >>= k;
	temp |= input;
	return temp;
}

int Power()	// 이게 int : 32bit 말고 8bit으로 진행되야 하나봄 
{
	int i;
	int result = 1;
	for (i = 0; i < W; i++)
		result *= 2;
	return result;
}

//---------------------------------------------//
// cipher      |   n     k     r     w    k/w  //
//---------------------------------------------//
//											   //
// CHAM-32/64  |   32    64    80     8     8  //
//											   //
//---------------------------------------------//

void Setkey(void *input, void *output)
{
	int i;
	//input = key    ,    output = RK
	// Round Key setting( w-bit 길이 , 2K/W 개 ) - 32/64로 가정하고 8bit 길이의 RK가 16개 생성됨
	for (i = 0; i < KW; i++)
	{
		((uint8_t*)output)[i]				= ((uint8_t*)input)[i] ^ ROL(((uint8_t*)input)[i], 1) ^ ROL(((uint8_t*)input)[i], 8);	// RK[0] ~ RK[7]
		((uint8_t*)output)[(i + KW) ^ 1]	= ((uint8_t*)input)[i] ^ ROL(((uint8_t*)input)[i], 1) ^ ROL(((uint8_t*)input)[i], 11);	// RK[8] ~ RK[15]
	}
};


// PT는 8bit 길이의 조각 4개로 구성되어있음
// PT = PT[0] || PT[1] || PT[2] || PT[3]
void Encryption(void *PT, void *CT, void*RK)
{
	int i;
	uint8_t x[4];
	uint8_t x_temp;

	x[0] = ((uint8_t*)PT)[0];
	x[1] = ((uint8_t*)PT)[1];
	x[2] = ((uint8_t*)PT)[2];
	x[3] = ((uint8_t*)PT)[3];

	// ROUND 진행
	for (i = 0; i < R; i++)
	{
		if (i % 2 == 0)	// 현재 라운드가 짝수 라운드 이면 (EVEN) -> 0 round 부터 시작함
			x_temp = ROL((x[0] ^ i) + (((ROL(x[1], 8) ^ ((uint8_t*)RK)[i % (2*KW)])) % Power()), 1);
		
		else			// 현재 라운드가 홀수 라운드 이면 (ODD)
			x_temp = ROL((x[0] ^ i) + (((ROL(x[1], 1) ^ ((uint8_t*)RK)[i % (2 * KW)])) % Power()), 8);

		x[0] = x[1];
		x[1] = x[2];
		x[2] = x[3];
		x[3] = x_temp;
	}

	((uint8_t*)CT)[0] = x[0];
	((uint8_t*)CT)[1] = x[1];
	((uint8_t*)CT)[2] = x[2];
	((uint8_t*)CT)[3] = x[3];
};


void Decryption(void *CT, void *RCT, void*RK)
{
	int i;
	uint8_t x[4];
	uint8_t x_temp;
	uint8_t a, b, c, d, e;


	x[0] = ((uint8_t*)CT)[0];
	x[1] = ((uint8_t*)CT)[1];
	x[2] = ((uint8_t*)CT)[2];
	x[3] = ((uint8_t*)CT)[3];

	// ROUND 진행
	for (i = R-1; i >=0 ; i--)
	{
		x_temp = x[3];
		x[3] = x[2];
		x[2] = x[1];
		x[1] = x[0];
		
		if (i % 2 == 0)	// 현재 라운드가 짝수 라운드 이면 (EVEN) -> 79 round 부터 시작함
			x[0] = (ROR(x_temp, 1) - ((ROL(x[1], 8) ^ ((uint8_t*)RK)[i % (2 * KW)]) % Power())) ^ i;

		else			// 현재 라운드가 홀수 라운드 이면 (ODD)
			x[0] = (ROR(x_temp, 8) - ((ROL(x[1], 1) ^ ((uint8_t*)RK)[i % (2 * KW)]) % Power())) ^ i;
	}

	((uint8_t*)RCT)[0] = x[0];
	((uint8_t*)RCT)[1] = x[1];
	((uint8_t*)RCT)[2] = x[2];
	((uint8_t*)RCT)[3] = x[3];

}