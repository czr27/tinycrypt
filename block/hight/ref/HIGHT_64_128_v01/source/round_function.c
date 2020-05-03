/*
 *
 * University of Luxembourg
 * Laboratory of Algorithmics, Cryptology and Security (LACS)
 *
 * FELICS - Fair Evaluation of Lightweight Cryptographic Systems
 *
 * Copyright (C) 2015 University of Luxembourg
 *
 * Written in 2015 by Daniel Dinu <dumitru-daniel.dinu@uni.lu>
 *
 * This file is part of FELICS.
 *
 * FELICS is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * FELICS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <stdint.h>

#include "round_function.h"


uint8_t F0(uint8_t x)
{
	uint8_t temp1, temp2, temp3;
	

	temp1 = ((x << 1) & 0xFF) ^ ((x >> 7) & 0xFF);
	temp2 = ((x << 2) & 0xFF) ^ ((x >> 6) & 0xFF);
	temp3 = ((x << 7) & 0xFF) ^ ((x >> 1) & 0xFF);

	return temp1 ^ temp2 ^ temp3;
}

uint8_t F1(uint8_t x)
{
	uint8_t temp1, temp2, temp3;

	temp1 = ((x << 3) & 0xFF) ^ ((x >> 5) & 0xFF);
	temp2 = ((x << 4) & 0xFF) ^ ((x >> 4) & 0xFF);
	temp3 = ((x << 6) & 0xFF) ^ ((x >> 2) & 0xFF);

	return temp1 ^ temp2 ^ temp3;
}
