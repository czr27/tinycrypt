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
ENTITY KeyExpansion IS
	PORT ( CLK			: IN  STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
          RESET		: IN  STD_LOGIC;
			 DECRYPT		: IN	STD_LOGIC;
		    -- KEY PORT -------------------------------------
			 KEY			: IN  STD_LOGIC_VECTOR (255 DOWNTO 0);
			 ROUND_KEY	: OUT STD_LOGIC_VECTOR (255 DOWNTO 0));
END KeyExpansion;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeyExpansion IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL KEY_STATE, KEY_NEXT, KEY_PERM, KEY_PERM_Inv	: STD_LOGIC_VECTOR(255 DOWNTO 0);

BEGIN

	-- REGISTER STAGE -------------------------------------------------------------
	RS : ENTITY work.ScanFF GENERIC MAP (SIZE => 256) PORT MAP (CLK, RESET, KEY_NEXT, KEY, KEY_STATE);

	-- TK1: PERMUTATION -----------------------------------------------------------
	P1    : ENTITY work.Permutation    PORT MAP (KEY_STATE (255 DOWNTO 128), KEY_PERM    (255 DOWNTO 128));
	PInv1 : ENTITY work.PermutationInv PORT MAP (KEY_STATE (255 DOWNTO 128), KEY_PERM_Inv(255 DOWNTO 128));

	-- TK1: NO LFSR ---------------------------------------------------------------
	KEY_NEXT(255 DOWNTO 128) <= KEY_PERM(255 DOWNTO 128) WHEN (DECRYPT = '0') ELSE KEY_PERM_Inv(255 DOWNTO 128);


	-- TK2: PERMUTATION -----------------------------------------------------------
	P2    : ENTITY work.Permutation    PORT MAP (KEY_STATE (127 DOWNTO 0), KEY_PERM    (127 DOWNTO 0));
	PInv2 : ENTITY work.PermutationInv PORT MAP (KEY_STATE (127 DOWNTO 0), KEY_PERM_Inv(127 DOWNTO 0));

	-- TK2: LFSR ------------------------------------------------------------------
	LFSR2 : FOR I IN 0 TO 3 GENERATE
		KEY_NEXT((8 * I + 103) DOWNTO (8 * I + 96)) <= KEY_PERM_Inv((8 * I + 103) DOWNTO (8 * I + 96)) WHEN (DECRYPT = '1') ELSE KEY_PERM((8 * I + 102) DOWNTO (8 * I + 96)) & (KEY_PERM(8 * I + 103) XOR KEY_PERM(8 * I + 101));
		KEY_NEXT((8 * I +  71) DOWNTO (8 * I + 64)) <= KEY_PERM_Inv((8 * I +  71) DOWNTO (8 * I + 64)) WHEN (DECRYPT = '1') ELSE KEY_PERM((8 * I +  70) DOWNTO (8 * I + 64)) & (KEY_PERM(8 * I +  71) XOR KEY_PERM(8 * I +  69));
		KEY_NEXT((8 * I +  39) DOWNTO (8 * I + 32)) <= KEY_PERM    ((8 * I +  39) DOWNTO (8 * I + 32)) WHEN (DECRYPT = '0') ELSE (KEY_PERM_Inv(8 * I +  38) XOR KEY_PERM_Inv(8 * I + 32)) & KEY_PERM_Inv((8 * I + 39) DOWNTO (8 * I + 33));
		KEY_NEXT((8 * I +   7) DOWNTO (8 * I +  0)) <= KEY_PERM    ((8 * I +   7) DOWNTO (8 * I +  0)) WHEN (DECRYPT = '0') ELSE (KEY_PERM_Inv(8 * I +   6) XOR KEY_PERM_Inv(8 * I +  0)) & KEY_PERM_Inv((8 * I +  7) DOWNTO (8 * I +  1));
	END GENERATE;

	-- KEY OUTPUT -----------------------------------------------------------------
	ROUND_KEY <= KEY_STATE;

END Round;
