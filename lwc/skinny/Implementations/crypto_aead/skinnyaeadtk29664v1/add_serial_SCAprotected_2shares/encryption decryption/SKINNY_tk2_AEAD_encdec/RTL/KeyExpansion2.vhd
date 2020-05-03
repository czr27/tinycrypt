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
ENTITY KeyExpansion2 IS
	PORT ( CLK			: IN  STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
          RESET		: IN  STD_LOGIC;
          DECRYPT		: IN  STD_LOGIC;
			 KEY_CTL		: IN	STD_LOGIC_VECTOR(  1 DOWNTO 0);
		    -- KEY PORT -------------------------------------
			 KEY			: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 ROUND_KEY	: OUT STD_LOGIC_VECTOR(  7 DOWNTO 0));
END KeyExpansion2;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeyExpansion2 IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CLK_H, CLK_CE_H, CLK_GATE_H	: STD_LOGIC;
	SIGNAL CLK_L, CLK_CE_L, CLK_GATE_L	: STD_LOGIC;
	SIGNAL TK2						: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL TK2_NEXT	         : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL TK2_PERM	         : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL TK2_LFSR	         : STD_LOGIC_VECTOR(  7 DOWNTO 0);

BEGIN

	-- CLOCK GATING ---------------------------------------------------------------
	CLK_CE_H <= '1' WHEN (RESET = '1' OR KEY_CTL(0) = '1' OR KEY_CTL(1) = '1') ELSE '0';
	CLK_CE_L <= '1' WHEN (RESET = '1' OR KEY_CTL(0) = '1' OR KEY_CTL(1) = '1') ELSE '0';

	GATE : PROCESS(CLK, CLK_CE_H, CLK_CE_L)
	BEGIN
		IF (NOT(CLK) = '1') THEN
			CLK_GATE_H	<= CLK_CE_H;
			CLK_GATE_L	<= CLK_CE_L;
		END IF;
	END PROCESS;

	CLK_H <= CLK AND CLK_GATE_H;
	CLK_L	<= CLK AND CLK_GATE_L;
	-------------------------------------------------------------------------------

	-- TWEAKEY ARRAY PERMUTATIONS : TK2 -------------------------------------------

		-- REGISTER STAGE -------------------------------------------------------------
		TK2_C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT(127 DOWNTO 120), KEY(127 DOWNTO 120), TK2(127 DOWNTO 120));
		TK2_C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT(119 DOWNTO 112), KEY(119 DOWNTO 112), TK2(119 DOWNTO 112));
		TK2_C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT(111 DOWNTO 104), KEY(111 DOWNTO 104), TK2(111 DOWNTO 104));
		TK2_C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT(103 DOWNTO  96), KEY(103 DOWNTO  96), TK2(103 DOWNTO  96));

		TK2_C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT( 95 DOWNTO  88), KEY( 95 DOWNTO  88), TK2( 95 DOWNTO  88));
		TK2_C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT( 87 DOWNTO  80), KEY( 87 DOWNTO  80), TK2( 87 DOWNTO  80));
		TK2_C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT( 79 DOWNTO  72), KEY( 79 DOWNTO  72), TK2( 79 DOWNTO  72));
		TK2_C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK2_NEXT( 71 DOWNTO  64), KEY( 71 DOWNTO  64), TK2( 71 DOWNTO  64));

		TK2_C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 63 DOWNTO  56), KEY( 63 DOWNTO  56), TK2( 63 DOWNTO  56));
		TK2_C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 55 DOWNTO  48), KEY( 55 DOWNTO  48), TK2( 55 DOWNTO  48));
		TK2_C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 47 DOWNTO  40), KEY( 47 DOWNTO  40), TK2( 47 DOWNTO  40));
		TK2_C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 39 DOWNTO  32), KEY( 39 DOWNTO  32), TK2( 39 DOWNTO  32));

		TK2_C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 31 DOWNTO  24), KEY( 31 DOWNTO  24), TK2( 31 DOWNTO  24));
		TK2_C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 23 DOWNTO  16), KEY( 23 DOWNTO  16), TK2( 23 DOWNTO  16));
		TK2_C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT( 15 DOWNTO   8), KEY( 15 DOWNTO   8), TK2( 15 DOWNTO   8));
		TK2_C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK2_NEXT(  7 DOWNTO   0), KEY(  7 DOWNTO   0), TK2(  7 DOWNTO   0));

		-- PERMUTATION -------------------------------------------------------------
		P2 : ENTITY work.Permutation PORT MAP (DECRYPT, TK2, TK2_PERM);

		-- TK2 LFSR ----------------------------------------------------------------
		TK2_LFSR <= TK2(63 DOWNTO 56) WHEN (RESET = '1') ELSE TK2(62 DOWNTO 56) & (TK2(63) XOR TK2(61)) WHEN DECRYPT = '0' ELSE (TK2(126) XOR TK2(120)) & TK2(127 DOWNTO 121);

		-- NEXT KEY ----------------------------------------------------------------
		TK2_NEXT <= TK2(119 DOWNTO 64) & TK2_LFSR & TK2(55 DOWNTO 0) & TK2(127 DOWNTO 120) WHEN (DECRYPT = '0' AND KEY_CTL(1) = '0') ELSE
                  TK2(119 DOWNTO  0) & TK2_LFSR                                          WHEN (DECRYPT = '1' AND KEY_CTL(1) = '0') ELSE TK2_PERM;

		-- ROUND KEY ---------------------------------------------------------------
		ROUND_KEY(7 DOWNTO 0) <= TK2(127 DOWNTO 120) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

END Round;