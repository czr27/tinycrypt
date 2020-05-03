--
-- SKINNY-AEAD Reference Hardware Implementation
-- 
-- Copyright 2019:
--     Amir Moradi & Pascal Sasdrich for the SKINNY Team
--     https://sites.google.com/site/skinnycipher/
-- 
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as
-- published by the Free Software Foundation; either version 2 of the
-- License, or (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
-- 



-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY SBoxInv IS
	PORT ( X : IN	STD_LOGIC_VECTOR (7 DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR (7 DOWNTO 0));
END SBoxInv;



-- ARCHITECTURE : WORD
----------------------------------------------------------------------------------
ARCHITECTURE Word OF SBoxInv IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL O, P : STD_LOGIC_VECTOR(39 DOWNTO 0);

BEGIN


	-- 8-BIT S-BOX ----------------------------------------------------------------
	P(7 DOWNTO 0) <= X(7 DOWNTO 3) & X(1) & X(2) & X(0);

	GEN : FOR I IN 0 TO 3 GENERATE
		-- ENCRYPTION
		O((8 * I +  7) DOWNTO (8 * I + 4)) <= P((8 * I + 7) DOWNTO (8 * I + 5)) & (P(8 * I + 4) XOR (P(8 * I + 7) NOR P(8 * I + 6)));
		O((8 * I +  3) DOWNTO (8 * I + 0)) <= P((8 * I + 3) DOWNTO (8 * I + 1)) & (P(8 * I + 0) XOR (P(8 * I + 3) NOR P(8 * I + 2)));

		P((8 * I + 15) DOWNTO (8 * I + 8)) <= O((8 * I + 5)) & O((8 * I + 4)) & O((8 * I + 0)) & O((8 * I + 3)) & O((8 * I + 1)) & O((8 * I + 7)) & O((8 * I + 6)) & O((8 * I + 2));
	END GENERATE;

	Y <= O(31 DOWNTO 24);
	-------------------------------------------------------------------------------

END Word;
