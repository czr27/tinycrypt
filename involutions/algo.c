////////////////////////////////////////////////////////////
// MR.HAANDI - SolveIt #1
// Keygen by jB
// Aug 4, 2007
//
// http://jardinezchezjb.free.fr / resrever@gmail.com
////////////////////////////////////////////////////////////

#include "all.h"
#include "resource.h"
#include <openssl/sha.h>
#include <stdio.h>

void InitStuff(HWND hWnd)
{
}

/*
* Extended GCD used.
*  Return a^(-1) mod b
*/
int ext_gcd(unsigned int a, unsigned int b)
{
	int n = b;
	unsigned int x = 0, y = 1;
	unsigned int lastx = 1, lasty = 0;
	while(b != 0)
	{
		unsigned int tmp = b;
		unsigned int q = a / b;
		b = a % b;
		a = tmp;
		tmp = x;
		x = lastx - q * x;
		lastx = tmp;
		tmp = y;
		y = lasty - q * y;
		lasty = tmp;
	}
	if((int)lastx < 0) lastx += n;
	return lastx;
}

/* Gauss-Jordan elimination over Zp*
* Awful and slow implementation, used to solve the
* 4 equations system of the crackme.
* Check http://en.wikipedia.org/wiki/Gauss-Jordan_elimination
*/

#define MOD_P 4294967291UL
#define MAT_N 4

typedef unsigned long long uint64_t;
typedef unsigned long uint32_t;

void gauss_jordan(unsigned int *m, unsigned int *v)
{
	int t, i, j;
	unsigned int pvt, tmp;

	for(t = 0; t < MAT_N; t++)
	{
		pvt = ext_gcd(m[MAT_N * t + t], MOD_P);
		v[t] = (uint32_t)((uint64_t)v[t] * pvt % MOD_P);
		for(i = 0; i < MAT_N; i++)
		{ 
			m[MAT_N * t + i] =
				(uint32_t)((uint64_t)m[MAT_N * t + i] * pvt % MOD_P);
		}

		for(j = 0; j < MAT_N; j++)
		{
			if(j != t)
			{
				tmp = (uint32_t)((uint64_t)m[MAT_N * j + t] * v[t] % MOD_P);
				if(v[j] > tmp)
					v[j] = (v[j] - tmp) % MOD_P;
				else
				{
					v[j] = (v[j] + (MOD_P - tmp)) % MOD_P;
				}
			}

		}

		for(j = 0; j < MAT_N; j++)
		{
			for(i = t + 1; i < MAT_N; i++)
			{
				if(j != t)
				{
					tmp = (uint32_t)((uint64_t)m[MAT_N * j + t] * m[MAT_N * t + i] % MOD_P);
					if(m[MAT_N * j + i] >= tmp)
						m[MAT_N * j + i] = (m[MAT_N * j + i] - tmp) % MOD_P;
					else
						m[MAT_N * j + i] = (m[MAT_N * j + i] + (MOD_P - tmp)) % MOD_P;
				}
			}
		}
		for(i = 0; i < MAT_N; i++)
			if(i != t)
				m[MAT_N * i + t] = 0;
	}
}

void GenererSerial(HWND hWnd)
{
	char name[MAX_NAME];
	char serial[MAX_SERIAL];
	int name_len;
	int i;
	unsigned int m[16] = {0};
	unsigned int v[4] = {0};

	name_len = GetDlgItemText(hWnd, IDC_NAME, name, MAX_NAME);
	if(name_len < MIN_NAME)
	{
		SetDlgItemText(hWnd, IDC_SERIAL, "Please enter a longer name...");
		return;
	}
	for(i = 0; i < name_len; i++)
	{
		v[0] += name[i];
		v[1] = (name[i] | 1) * (v[1] + 1);
		v[2] += name[i] ^ 17;
		v[3] = ((name[i] ^ 16) | 1) * (v[3] + 1);
	}

	SHA512((const unsigned char *)name, strlen(name), (unsigned char *)m);
	for(i = 0; i < 16; i++)
	{
		m[i] &= 0xffffff;
	}
	gauss_jordan(m, v);

	sprintf_s(serial, MAX_SERIAL, "%08X-%08X-%08X-%08X", v[0], v[1], v[2], v[3]);
	SetDlgItemText(hWnd, IDC_SERIAL, serial);
}
