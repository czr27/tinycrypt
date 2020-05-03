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
			 KEY_CTL		: IN	STD_LOGIC_VECTOR(1 DOWNTO 0);
		    -- KEY PORT -------------------------------------
			 TK1_IN		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 TK2_IN		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 TK3_IN1		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 TK3_IN2		: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 ROUND_TK1	: OUT STD_LOGIC_VECTOR(  7 DOWNTO 0);
			 ROUND_TK2	: OUT STD_LOGIC_VECTOR(  7 DOWNTO 0);
			 ROUND_TK3_1: OUT STD_LOGIC_VECTOR(  7 DOWNTO 0);
			 ROUND_TK3_2: OUT STD_LOGIC_VECTOR(  7 DOWNTO 0));
END KeyExpansion;


-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeyExpansion IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;
	CONSTANT N : INTEGER := 128;
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CLK_H, CLK_CE_H, CLK_GATE_H		: STD_LOGIC;
	SIGNAL CLK_L, CLK_CE_L, CLK_GATE_L		: STD_LOGIC;

	SIGNAL TK1_1, TK2_1, TK3_1							: STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL TK1_NEXT_1,  TK2_NEXT_1,  TK3_NEXT_1	: STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL TK1_PERM_1,  TK2_PERM_1,  TK3_PERM_1	: STD_LOGIC_VECTOR(( 8 * W - 1) DOWNTO 0);
	SIGNAL TK1_NPERM_1, TK2_NPERM_1, TK3_NPERM_1	: STD_LOGIC_VECTOR(( 8 * W - 1) DOWNTO 0);
	SIGNAL TK1_LFSR_1,  TK2_LFSR_1,  TK3_LFSR_1	: STD_LOGIC_VECTOR(( 1 * W - 1) DOWNTO 0);

	SIGNAL TK1_2, TK2_2, TK3_2							: STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL TK1_NEXT_2,  TK2_NEXT_2,  TK3_NEXT_2	: STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL TK1_PERM_2,  TK2_PERM_2,  TK3_PERM_2	: STD_LOGIC_VECTOR(( 8 * W - 1) DOWNTO 0);
	SIGNAL TK1_NPERM_2, TK2_NPERM_2, TK3_NPERM_2	: STD_LOGIC_VECTOR(( 8 * W - 1) DOWNTO 0);
	SIGNAL TK1_LFSR_2,  TK2_LFSR_2,  TK3_LFSR_2	: STD_LOGIC_VECTOR(( 1 * W - 1) DOWNTO 0);
	
BEGIN

	-- CLOCK GATING ---------------------------------------------------------------
	CLK_CE_H <= '1' WHEN (KEY_CTL(0) = '1' OR KEY_CTL(1) = '1' OR RESET = '1') ELSE '0';
	CLK_CE_L <= '1' WHEN (KEY_CTL(0) = '1' OR RESET = '1') ELSE '0';

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

	-- SHARE 1 --------------------------------------------------------------------
	
	-- TWEAKEY ARRAY PERMUTATIONS : TK1 -------------------------------------------
		-- REGISTER STAGE -------------------------------------------------------------
		C15_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 8 * W - 1) DOWNTO ( 7 * W)), TK1_IN((16 * W - 1) DOWNTO (15 * W)), TK1_1((16 * W - 1) DOWNTO (15 * W)));
		C14_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 7 * W - 1) DOWNTO ( 6 * W)), TK1_IN((15 * W - 1) DOWNTO (14 * W)), TK1_1((15 * W - 1) DOWNTO (14 * W)));
		C13_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 6 * W - 1) DOWNTO ( 5 * W)), TK1_IN((14 * W - 1) DOWNTO (13 * W)), TK1_1((14 * W - 1) DOWNTO (13 * W)));
		C12_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 5 * W - 1) DOWNTO ( 4 * W)), TK1_IN((13 * W - 1) DOWNTO (12 * W)), TK1_1((13 * W - 1) DOWNTO (12 * W)));

		C11_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 4 * W - 1) DOWNTO ( 3 * W)), TK1_IN((12 * W - 1) DOWNTO (11 * W)), TK1_1((12 * W - 1) DOWNTO (11 * W)));
		C10_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 3 * W - 1) DOWNTO ( 2 * W)), TK1_IN((11 * W - 1) DOWNTO (10 * W)), TK1_1((11 * W - 1) DOWNTO (10 * W)));
		C09_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 2 * W - 1) DOWNTO ( 1 * W)), TK1_IN((10 * W - 1) DOWNTO ( 9 * W)), TK1_1((10 * W - 1) DOWNTO ( 9 * W)));
		C08_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM_1(( 1 * W - 1) DOWNTO ( 0 * W)), TK1_IN(( 9 * W - 1) DOWNTO ( 8 * W)), TK1_1(( 9 * W - 1) DOWNTO ( 8 * W)));

		C07_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 8 * W - 1) DOWNTO ( 7 * W)), TK1_IN(( 8 * W - 1) DOWNTO ( 7 * W)),  TK1_1(( 8 * W - 1) DOWNTO ( 7 * W)));
		C06_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 7 * W - 1) DOWNTO ( 6 * W)), TK1_IN(( 7 * W - 1) DOWNTO ( 6 * W)),  TK1_1(( 7 * W - 1) DOWNTO ( 6 * W)));
		C05_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 6 * W - 1) DOWNTO ( 5 * W)), TK1_IN(( 6 * W - 1) DOWNTO ( 5 * W)),  TK1_1(( 6 * W - 1) DOWNTO ( 5 * W)));
		C04_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 5 * W - 1) DOWNTO ( 4 * W)), TK1_IN(( 5 * W - 1) DOWNTO ( 4 * W)),  TK1_1(( 5 * W - 1) DOWNTO ( 4 * W)));

		C03_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 4 * W - 1) DOWNTO ( 3 * W)), TK1_IN(( 4 * W - 1) DOWNTO ( 3 * W)),  TK1_1(( 4 * W - 1) DOWNTO ( 3 * W)));
		C02_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 3 * W - 1) DOWNTO ( 2 * W)), TK1_IN(( 3 * W - 1) DOWNTO ( 2 * W)),  TK1_1(( 3 * W - 1) DOWNTO ( 2 * W)));
		C01_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 2 * W - 1) DOWNTO ( 1 * W)), TK1_IN(( 2 * W - 1) DOWNTO ( 1 * W)),  TK1_1(( 2 * W - 1) DOWNTO ( 1 * W)));
		C00_TK1_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT_1(( 1 * W - 1) DOWNTO ( 0 * W)), TK1_IN(( 1 * W - 1) DOWNTO ( 0 * W)),  TK1_1(( 1 * W - 1) DOWNTO ( 0 * W)));

		-- PERMUTATION -------------------------------------------------------------
		P1_1 : ENTITY work.Permutation PORT MAP (TK1_1((16 * W - 1) DOWNTO (8 * W)), TK1_PERM_1);

		-- NO LFSR -----------------------------------------------------------------
		TK1_LFSR_1 <= TK1_1((8 * W - 1) DOWNTO (7 * W));

		-- NEXT KEY ----------------------------------------------------------------
		TK1_NEXT_1 <= TK1_1((15 * W - 1) DOWNTO (8 * W)) & TK1_LFSR_1 & TK1_1(( 7 * W - 1) DOWNTO (0 * W)) & TK1_1((16 * W - 1) DOWNTO (15 * W));

		-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
		TK1_NPERM_1 <= TK1_NEXT_1(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK1_PERM_1((8 * W - 1) DOWNTO (0 * W));

		-- ROUND KEY ---------------------------------------------------------------
		ROUND_TK1 <= TK1_1((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

	-- TWEAKEY ARRAY PERMUTATIONS : TK2 -------------------------------------------

		-- REGISTER STAGE -------------------------------------------------------------
		C15_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 8 * W - 1) DOWNTO ( 7 * W)), TK2_IN((16 * W - 1) DOWNTO (15 * W)), TK2_1((16 * W - 1) DOWNTO (15 * W)));
		C14_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 7 * W - 1) DOWNTO ( 6 * W)), TK2_IN((15 * W - 1) DOWNTO (14 * W)), TK2_1((15 * W - 1) DOWNTO (14 * W)));
		C13_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 6 * W - 1) DOWNTO ( 5 * W)), TK2_IN((14 * W - 1) DOWNTO (13 * W)), TK2_1((14 * W - 1) DOWNTO (13 * W)));
		C12_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 5 * W - 1) DOWNTO ( 4 * W)), TK2_IN((13 * W - 1) DOWNTO (12 * W)), TK2_1((13 * W - 1) DOWNTO (12 * W)));

		C11_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 4 * W - 1) DOWNTO ( 3 * W)), TK2_IN((12 * W - 1) DOWNTO (11 * W)), TK2_1((12 * W - 1) DOWNTO (11 * W)));
		C10_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 3 * W - 1) DOWNTO ( 2 * W)), TK2_IN((11 * W - 1) DOWNTO (10 * W)), TK2_1((11 * W - 1) DOWNTO (10 * W)));
		C09_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 2 * W - 1) DOWNTO ( 1 * W)), TK2_IN((10 * W - 1) DOWNTO ( 9 * W)), TK2_1((10 * W - 1) DOWNTO ( 9 * W)));
		C08_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM_1(( 1 * W - 1) DOWNTO ( 0 * W)), TK2_IN(( 9 * W - 1) DOWNTO ( 8 * W)), TK2_1(( 9 * W - 1) DOWNTO ( 8 * W)));

		C07_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 8 * W - 1) DOWNTO ( 7 * W)), TK2_IN(( 8 * W - 1) DOWNTO ( 7 * W)),  TK2_1(( 8 * W - 1) DOWNTO ( 7 * W)));
		C06_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 7 * W - 1) DOWNTO ( 6 * W)), TK2_IN(( 7 * W - 1) DOWNTO ( 6 * W)),  TK2_1(( 7 * W - 1) DOWNTO ( 6 * W)));
		C05_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 6 * W - 1) DOWNTO ( 5 * W)), TK2_IN(( 6 * W - 1) DOWNTO ( 5 * W)),  TK2_1(( 6 * W - 1) DOWNTO ( 5 * W)));
		C04_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 5 * W - 1) DOWNTO ( 4 * W)), TK2_IN(( 5 * W - 1) DOWNTO ( 4 * W)),  TK2_1(( 5 * W - 1) DOWNTO ( 4 * W)));

		C03_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 4 * W - 1) DOWNTO ( 3 * W)), TK2_IN(( 4 * W - 1) DOWNTO ( 3 * W)),  TK2_1(( 4 * W - 1) DOWNTO ( 3 * W)));
		C02_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 3 * W - 1) DOWNTO ( 2 * W)), TK2_IN(( 3 * W - 1) DOWNTO ( 2 * W)),  TK2_1(( 3 * W - 1) DOWNTO ( 2 * W)));
		C01_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 2 * W - 1) DOWNTO ( 1 * W)), TK2_IN(( 2 * W - 1) DOWNTO ( 1 * W)),  TK2_1(( 2 * W - 1) DOWNTO ( 1 * W)));
		C00_TK2_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT_1(( 1 * W - 1) DOWNTO ( 0 * W)), TK2_IN(( 1 * W - 1) DOWNTO ( 0 * W)),  TK2_1(( 1 * W - 1) DOWNTO ( 0 * W)));

		-- PERMUTATION -------------------------------------------------------------
		P2_1 : ENTITY work.Permutation PORT MAP (TK2_1((16 * W - 1) DOWNTO (8 * W)), TK2_PERM_1);

		-- NO LFSR -----------------------------------------------------------------
		TK2_LFSR_1 <= TK2_1((8 * W - 1) DOWNTO (7 * W)) WHEN (RESET = '1') ELSE TK2_1((8 * W - 2) DOWNTO (7 * W)) & (TK2_1(8 * W - 1) XOR TK2_1(8 * W - (W / 8) - 2));

		-- NEXT KEY ----------------------------------------------------------------
		TK2_NEXT_1 <= TK2_1((15 * W - 1) DOWNTO (8 * W)) & TK2_LFSR_1 & TK2_1(( 7 * W - 1) DOWNTO (0 * W)) & TK2_1((16 * W - 1) DOWNTO (15 * W));

		-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
		TK2_NPERM_1 <= TK2_NEXT_1(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK2_PERM_1((8 * W - 1) DOWNTO (0 * W));

		-- ROUND KEY ---------------------------------------------------------------
		ROUND_TK2 <= TK2_1((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

	-- TWEAKEY ARRAY PERMUTATIONS : TK3 -------------------------------------------
		-- REGISTER STAGE -------------------------------------------------------------
		C15_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 8 * W - 1) DOWNTO ( 7 * W)), TK3_IN1((16 * W - 1) DOWNTO (15 * W)), TK3_1((16 * W - 1) DOWNTO (15 * W)));
		C14_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 7 * W - 1) DOWNTO ( 6 * W)), TK3_IN1((15 * W - 1) DOWNTO (14 * W)), TK3_1((15 * W - 1) DOWNTO (14 * W)));
		C13_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 6 * W - 1) DOWNTO ( 5 * W)), TK3_IN1((14 * W - 1) DOWNTO (13 * W)), TK3_1((14 * W - 1) DOWNTO (13 * W)));
		C12_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 5 * W - 1) DOWNTO ( 4 * W)), TK3_IN1((13 * W - 1) DOWNTO (12 * W)), TK3_1((13 * W - 1) DOWNTO (12 * W)));

		C11_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 4 * W - 1) DOWNTO ( 3 * W)), TK3_IN1((12 * W - 1) DOWNTO (11 * W)), TK3_1((12 * W - 1) DOWNTO (11 * W)));
		C10_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 3 * W - 1) DOWNTO ( 2 * W)), TK3_IN1((11 * W - 1) DOWNTO (10 * W)), TK3_1((11 * W - 1) DOWNTO (10 * W)));
		C09_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 2 * W - 1) DOWNTO ( 1 * W)), TK3_IN1((10 * W - 1) DOWNTO ( 9 * W)), TK3_1((10 * W - 1) DOWNTO ( 9 * W)));
		C08_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_1(( 1 * W - 1) DOWNTO ( 0 * W)), TK3_IN1(( 9 * W - 1) DOWNTO ( 8 * W)), TK3_1(( 9 * W - 1) DOWNTO ( 8 * W)));

		C07_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 8 * W - 1) DOWNTO ( 7 * W)), TK3_IN1(( 8 * W - 1) DOWNTO ( 7 * W)),  TK3_1(( 8 * W - 1) DOWNTO ( 7 * W)));
		C06_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 7 * W - 1) DOWNTO ( 6 * W)), TK3_IN1(( 7 * W - 1) DOWNTO ( 6 * W)),  TK3_1(( 7 * W - 1) DOWNTO ( 6 * W)));
		C05_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 6 * W - 1) DOWNTO ( 5 * W)), TK3_IN1(( 6 * W - 1) DOWNTO ( 5 * W)),  TK3_1(( 6 * W - 1) DOWNTO ( 5 * W)));
		C04_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 5 * W - 1) DOWNTO ( 4 * W)), TK3_IN1(( 5 * W - 1) DOWNTO ( 4 * W)),  TK3_1(( 5 * W - 1) DOWNTO ( 4 * W)));

		C03_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 4 * W - 1) DOWNTO ( 3 * W)), TK3_IN1(( 4 * W - 1) DOWNTO ( 3 * W)),  TK3_1(( 4 * W - 1) DOWNTO ( 3 * W)));
		C02_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 3 * W - 1) DOWNTO ( 2 * W)), TK3_IN1(( 3 * W - 1) DOWNTO ( 2 * W)),  TK3_1(( 3 * W - 1) DOWNTO ( 2 * W)));
		C01_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 2 * W - 1) DOWNTO ( 1 * W)), TK3_IN1(( 2 * W - 1) DOWNTO ( 1 * W)),  TK3_1(( 2 * W - 1) DOWNTO ( 1 * W)));
		C00_TK3_1 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_1(( 1 * W - 1) DOWNTO ( 0 * W)), TK3_IN1(( 1 * W - 1) DOWNTO ( 0 * W)),  TK3_1(( 1 * W - 1) DOWNTO ( 0 * W)));

		-- PERMUTATION -------------------------------------------------------------
		P3_1 : ENTITY work.Permutation PORT MAP (TK3_1((16 * W - 1) DOWNTO (8 * W)), TK3_PERM_1);

		-- NO LFSR -----------------------------------------------------------------
		TK3_LFSR_1 <= TK3_1((8 * W - 1) DOWNTO (7 * W)) WHEN (RESET = '1') ELSE (TK3_1(8 * W - (W / 8) - 1) XOR TK3_1(7 * W)) & TK3_1((8 * W - 1) DOWNTO (7 * W + 1));

		-- NEXT KEY ----------------------------------------------------------------
		TK3_NEXT_1 <= TK3_1((15 * W - 1) DOWNTO (8 * W)) & TK3_LFSR_1 & TK3_1(( 7 * W - 1) DOWNTO (0 * W)) & TK3_1((16 * W - 1) DOWNTO (15 * W));

		-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
		TK3_NPERM_1 <= TK3_NEXT_1(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK3_PERM_1((8 * W - 1) DOWNTO (0 * W));

		-- ROUND KEY ---------------------------------------------------------------
		ROUND_TK3_1 <= TK3_1((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

	-- ============================================================================
	-- SHARE 2 --------------------------------------------------------------------

	-- TWEAKEY ARRAY PERMUTATIONS : TK3 -------------------------------------------
		-- REGISTER STAGE -------------------------------------------------------------
		C15_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 8 * W - 1) DOWNTO ( 7 * W)), TK3_IN2((16 * W - 1) DOWNTO (15 * W)), TK3_2((16 * W - 1) DOWNTO (15 * W)));
		C14_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 7 * W - 1) DOWNTO ( 6 * W)), TK3_IN2((15 * W - 1) DOWNTO (14 * W)), TK3_2((15 * W - 1) DOWNTO (14 * W)));
		C13_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 6 * W - 1) DOWNTO ( 5 * W)), TK3_IN2((14 * W - 1) DOWNTO (13 * W)), TK3_2((14 * W - 1) DOWNTO (13 * W)));
		C12_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 5 * W - 1) DOWNTO ( 4 * W)), TK3_IN2((13 * W - 1) DOWNTO (12 * W)), TK3_2((13 * W - 1) DOWNTO (12 * W)));

		C11_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 4 * W - 1) DOWNTO ( 3 * W)), TK3_IN2((12 * W - 1) DOWNTO (11 * W)), TK3_2((12 * W - 1) DOWNTO (11 * W)));
		C10_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 3 * W - 1) DOWNTO ( 2 * W)), TK3_IN2((11 * W - 1) DOWNTO (10 * W)), TK3_2((11 * W - 1) DOWNTO (10 * W)));
		C09_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 2 * W - 1) DOWNTO ( 1 * W)), TK3_IN2((10 * W - 1) DOWNTO ( 9 * W)), TK3_2((10 * W - 1) DOWNTO ( 9 * W)));
		C08_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM_2(( 1 * W - 1) DOWNTO ( 0 * W)), TK3_IN2(( 9 * W - 1) DOWNTO ( 8 * W)), TK3_2(( 9 * W - 1) DOWNTO ( 8 * W)));

		C07_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 8 * W - 1) DOWNTO ( 7 * W)), TK3_IN2(( 8 * W - 1) DOWNTO ( 7 * W)),  TK3_2(( 8 * W - 1) DOWNTO ( 7 * W)));
		C06_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 7 * W - 1) DOWNTO ( 6 * W)), TK3_IN2(( 7 * W - 1) DOWNTO ( 6 * W)),  TK3_2(( 7 * W - 1) DOWNTO ( 6 * W)));
		C05_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 6 * W - 1) DOWNTO ( 5 * W)), TK3_IN2(( 6 * W - 1) DOWNTO ( 5 * W)),  TK3_2(( 6 * W - 1) DOWNTO ( 5 * W)));
		C04_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 5 * W - 1) DOWNTO ( 4 * W)), TK3_IN2(( 5 * W - 1) DOWNTO ( 4 * W)),  TK3_2(( 5 * W - 1) DOWNTO ( 4 * W)));

		C03_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 4 * W - 1) DOWNTO ( 3 * W)), TK3_IN2(( 4 * W - 1) DOWNTO ( 3 * W)),  TK3_2(( 4 * W - 1) DOWNTO ( 3 * W)));
		C02_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 3 * W - 1) DOWNTO ( 2 * W)), TK3_IN2(( 3 * W - 1) DOWNTO ( 2 * W)),  TK3_2(( 3 * W - 1) DOWNTO ( 2 * W)));
		C01_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 2 * W - 1) DOWNTO ( 1 * W)), TK3_IN2(( 2 * W - 1) DOWNTO ( 1 * W)),  TK3_2(( 2 * W - 1) DOWNTO ( 1 * W)));
		C00_TK3_2 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT_2(( 1 * W - 1) DOWNTO ( 0 * W)), TK3_IN2(( 1 * W - 1) DOWNTO ( 0 * W)),  TK3_2(( 1 * W - 1) DOWNTO ( 0 * W)));

		-- PERMUTATION -------------------------------------------------------------
		P3_2 : ENTITY work.Permutation PORT MAP (TK3_2((16 * W - 1) DOWNTO (8 * W)), TK3_PERM_2);

		-- NO LFSR -----------------------------------------------------------------
		TK3_LFSR_2 <= TK3_2((8 * W - 1) DOWNTO (7 * W)) WHEN (RESET = '1') ELSE (TK3_2(8 * W - (W / 8) - 1) XOR TK3_2(7 * W)) & TK3_2((8 * W - 1) DOWNTO (7 * W + 1));

		-- NEXT KEY ----------------------------------------------------------------
		TK3_NEXT_2 <= TK3_2((15 * W - 1) DOWNTO (8 * W)) & TK3_LFSR_2 & TK3_2(( 7 * W - 1) DOWNTO (0 * W)) & TK3_2((16 * W - 1) DOWNTO (15 * W));

		-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
		TK3_NPERM_2 <= TK3_NEXT_2(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK3_PERM_2((8 * W - 1) DOWNTO (0 * W));

		-- ROUND KEY ---------------------------------------------------------------
		ROUND_TK3_2 <= TK3_2((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

END Round;