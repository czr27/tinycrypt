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
			 LAST 		: IN	STD_LOGIC;
		    -- KEY PORT -------------------------------------
			 TK1			: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
			 TK2_1		: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
			 TK2_2		: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
			 ROUND_TK1	: OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
			 ROUND_TK2_1: OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
			 ROUND_TK2_2: OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END KeyExpansion;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeyExpansion IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL KEY_STATE1,   KEY_NEXT1,   KEY_PERM1	: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL KEY_STATE2_1, KEY_NEXT2_1, KEY_PERM2_1: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL KEY_STATE2_2, KEY_NEXT2_2, KEY_PERM2_2: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL CLK_CE_K, CLK_GATE_K, CLK_K		: STD_LOGIC;

BEGIN

	-- CLOCK GATING ---------------------------------------------------------------
	CLK_CE_K <= '1' WHEN (RESET = '1' OR LAST = '1') ELSE '0';

	GATE : PROCESS(CLK, CLK_CE_K) BEGIN
		IF (NOT(CLK) = '1') THEN
			CLK_GATE_K	<= CLK_CE_K;
		END IF;
	END PROCESS;

	CLK_K <= CLK AND CLK_GATE_K;

	-- REGISTER STAGE -------------------------------------------------------------
	RS1   : ENTITY work.ScanFF GENERIC MAP (SIZE => 128) PORT MAP (CLK_K, RESET, KEY_NEXT1,   TK1,   KEY_STATE1);
	RS2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => 128) PORT MAP (CLK_K, RESET, KEY_NEXT2_1, TK2_1, KEY_STATE2_1);
	RS2_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => 128) PORT MAP (CLK_K, RESET, KEY_NEXT2_2, TK2_2, KEY_STATE2_2);

	-- TK1: PERMUTATION -----------------------------------------------------------
	P1    : ENTITY work.Permutation    PORT MAP (KEY_STATE1, KEY_PERM1);

	-- TK1: NO LFSR ---------------------------------------------------------------
	KEY_NEXT1 <= KEY_PERM1;


	-- TK2: PERMUTATION -----------------------------------------------------------
	-- TK3: PERMUTATION -----------------------------------------------------------
	P2_1   : ENTITY work.Permutation    PORT MAP (KEY_STATE2_1, KEY_PERM2_1);
	P2_2   : ENTITY work.Permutation    PORT MAP (KEY_STATE2_2, KEY_PERM2_2);

	-- TK2: LFSR ------------------------------------------------------------------
	LFSR2 : FOR I IN 0 TO 3 GENERATE
		KEY_NEXT2_1((8 * I + 103) DOWNTO (8 * I + 96)) <= KEY_PERM2_1((8 * I + 102) DOWNTO (8 * I + 96)) & (KEY_PERM2_1(8 * I + 103) XOR KEY_PERM2_1(8 * I + 101));
		KEY_NEXT2_1((8 * I +  71) DOWNTO (8 * I + 64)) <= KEY_PERM2_1((8 * I +  70) DOWNTO (8 * I + 64)) & (KEY_PERM2_1(8 * I +  71) XOR KEY_PERM2_1(8 * I +  69));
		KEY_NEXT2_1((8 * I +  39) DOWNTO (8 * I + 32)) <= KEY_PERM2_1((8 * I +  39) DOWNTO (8 * I + 32));
		KEY_NEXT2_1((8 * I +   7) DOWNTO (8 * I +  0)) <= KEY_PERM2_1((8 * I +   7) DOWNTO (8 * I +  0));

		KEY_NEXT2_2((8 * I + 103) DOWNTO (8 * I + 96)) <= KEY_PERM2_2((8 * I + 102) DOWNTO (8 * I + 96)) & (KEY_PERM2_2(8 * I + 103) XOR KEY_PERM2_2(8 * I + 101));
		KEY_NEXT2_2((8 * I +  71) DOWNTO (8 * I + 64)) <= KEY_PERM2_2((8 * I +  70) DOWNTO (8 * I + 64)) & (KEY_PERM2_2(8 * I +  71) XOR KEY_PERM2_2(8 * I +  69));
		KEY_NEXT2_2((8 * I +  39) DOWNTO (8 * I + 32)) <= KEY_PERM2_2((8 * I +  39) DOWNTO (8 * I + 32));
		KEY_NEXT2_2((8 * I +   7) DOWNTO (8 * I +  0)) <= KEY_PERM2_2((8 * I +   7) DOWNTO (8 * I +  0));
	END GENERATE;

	-- KEY OUTPUT -----------------------------------------------------------------
	ROUND_TK1 	<= KEY_STATE1;
	ROUND_TK2_1 <= KEY_STATE2_1;
	ROUND_TK2_2 <= KEY_STATE2_2;

END Round;
