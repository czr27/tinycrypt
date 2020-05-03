#include "func.h"

int main()
{
	uint8_t key[8] = { 0x13, 0x1a, 0x7b, 0x4f, 0x23, 0xd5, 0x96, 0x08};
	uint8_t RK[16];
	uint8_t PT[4] = {0xa3, 0x1b, 0xfc, 0x79};
	uint8_t CT[4];
	uint8_t RCT[4];

	Setkey(key, RK);
	Encryption(PT, CT, RK);
	Decryption(CT, RCT, RK);

	printf("PT  : %x%x%x%x\n", PT[0], PT[1], PT[2], PT[3]);
	printf("CT  : %x%x%x%x\n", CT[0], CT[1], CT[2], CT[3]);
	printf("RCT : %x%x%x%x\n", RCT[0], RCT[1], RCT[2], RCT[3]);

} 