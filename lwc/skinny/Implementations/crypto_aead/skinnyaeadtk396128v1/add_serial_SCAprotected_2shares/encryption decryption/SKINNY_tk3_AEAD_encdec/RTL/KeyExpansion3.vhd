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
ENTITY KeyExpansion3 IS
	PORT ( CLK			: IN  STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
          RESET		: IN  STD_LOGIC;
          DECRYPT		: IN  STD_LOGIC;
			 KEY_CTL		: IN	STD_LOGIC_VECTOR(  1 DOWNTO 0);
		    -- KEY PORT -------------------------------------
			 KEY			: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 ROUND_KEY	: OUT STD_LOGIC_VECTOR(  7 DOWNTO 0));
END KeyExpansion3;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeyExpansion3 IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CLK_H, CLK_CE_H, CLK_GATE_H		: STD_LOGIC;
	SIGNAL CLK_L, CLK_CE_L, CLK_GATE_L		: STD_LOGIC;
	SIGNAL TK3										: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL TK3_NEXT								: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL TK3_PERM								: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL TK3_LFSR								: STD_LOGIC_VECTOR(  7 DOWNTO 0);

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

	-- TWEAKEY ARRAY PERMUTATIONS : TK3 -------------------------------------------

		-- REGISTER STAGE -------------------------------------------------------------
		TK3_C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT(127 DOWNTO 120), KEY(127 DOWNTO 120), TK3(127 DOWNTO 120));
		TK3_C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT(119 DOWNTO 112), KEY(119 DOWNTO 112), TK3(119 DOWNTO 112));
		TK3_C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT(111 DOWNTO 104), KEY(111 DOWNTO 104), TK3(111 DOWNTO 104));
		TK3_C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT(103 DOWNTO  96), KEY(103 DOWNTO  96), TK3(103 DOWNTO  96));

		TK3_C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT( 95 DOWNTO  88), KEY( 95 DOWNTO  88), TK3( 95 DOWNTO  88));
		TK3_C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT( 87 DOWNTO  80), KEY( 87 DOWNTO  80), TK3( 87 DOWNTO  80));
		TK3_C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT( 79 DOWNTO  72), KEY( 79 DOWNTO  72), TK3( 79 DOWNTO  72));
		TK3_C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_H, RESET, TK3_NEXT( 71 DOWNTO  64), KEY( 71 DOWNTO  64), TK3( 71 DOWNTO  64));

		TK3_C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 63 DOWNTO  56), KEY( 63 DOWNTO  56), TK3( 63 DOWNTO  56));
		TK3_C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 55 DOWNTO  48), KEY( 55 DOWNTO  48), TK3( 55 DOWNTO  48));
		TK3_C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 47 DOWNTO  40), KEY( 47 DOWNTO  40), TK3( 47 DOWNTO  40));
		TK3_C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 39 DOWNTO  32), KEY( 39 DOWNTO  32), TK3( 39 DOWNTO  32));

		TK3_C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 31 DOWNTO  24), KEY( 31 DOWNTO  24), TK3( 31 DOWNTO  24));
		TK3_C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 23 DOWNTO  16), KEY( 23 DOWNTO  16), TK3( 23 DOWNTO  16));
		TK3_C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT( 15 DOWNTO   8), KEY( 15 DOWNTO   8), TK3( 15 DOWNTO   8));
		TK3_C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK_L, RESET, TK3_NEXT(  7 DOWNTO   0), KEY(  7 DOWNTO   0), TK3(  7 DOWNTO   0));

		-- PERMUTATION -------------------------------------------------------------
		P3 : ENTITY work.Permutation PORT MAP (DECRYPT, TK3, TK3_PERM);

		-- Tk3 LFSR ----------------------------------------------------------------
		TK3_LFSR <= TK3(63 DOWNTO 56) WHEN (RESET = '1') ELSE (TK3(62) XOR TK3(56)) & TK3(63 DOWNTO 57) WHEN DECRYPT = '0' ELSE	TK3(126 DOWNTO 120) & (TK3(127) XOR TK3(125));

		-- NEXT KEY ----------------------------------------------------------------
		TK3_NEXT <= TK3(119 DOWNTO 64) & TK3_LFSR & TK3(55 DOWNTO 0) & TK3(127 DOWNTO 120) WHEN (DECRYPT = '0' AND KEY_CTL(1) = '0') ELSE
                  TK3(119 DOWNTO  0) & TK3_LFSR                                          WHEN (DECRYPT = '1' AND KEY_CTL(1) = '0') ELSE TK3_PERM;
                  
		-- ROUND KEY ---------------------------------------------------------------
		ROUND_KEY <= TK3(127 DOWNTO 120) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

END Round;