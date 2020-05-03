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
			 KEY			: IN  STD_LOGIC_VECTOR(383 DOWNTO 0);
			 ROUND_KEY	: OUT STD_LOGIC_VECTOR( 23 DOWNTO 0));
END KeyExpansion;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeyExpansion IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;
	CONSTANT N : INTEGER := 128;
	CONSTANT T : INTEGER := 384;
	
	CONSTANT KA1 : INTEGER := T-N;
	CONSTANT KA2 : INTEGER := T-3*N;
	CONSTANT KA3 : INTEGER := T-5*N;
		
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CLK_H, CLK_CE_H, CLK_GATE_H		: STD_LOGIC;
	SIGNAL CLK_L, CLK_CE_L, CLK_GATE_L		: STD_LOGIC;
	SIGNAL TK1, TK2, TK3							: STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL TK1_NEXT,  TK2_NEXT,  TK3_NEXT		: STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL TK1_PERM,  TK2_PERM,  TK3_PERM		: STD_LOGIC_VECTOR(( 8 * W - 1) DOWNTO 0);
	SIGNAL TK1_NPERM, TK2_NPERM, TK3_NPERM		: STD_LOGIC_VECTOR(( 8 * W - 1) DOWNTO 0);
	SIGNAL TK1_LFSR,  TK2_LFSR,  TK3_LFSR		: STD_LOGIC_VECTOR(( 1 * W - 1) DOWNTO 0);

BEGIN

	-- CLOCK GATING ---------------------------------------------------------------
	CLK_CE_H <= '1' WHEN (KEY_CTL(0) = '1' OR KEY_CTL(1) = '1') ELSE '0';
	CLK_CE_L <= '1' WHEN (KEY_CTL(0) = '1') ELSE '0';

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

	-- TWEAKEY ARRAY PERMUTATIONS : TK1 -------------------------------------------
	-- REGISTER STAGE -------------------------------------------------------------
	TK1_C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 8 * W - 1) DOWNTO ( 7 * W)), KEY((KA1 + 16 * W - 1) DOWNTO (KA1 + 15 * W)), TK1((16 * W - 1) DOWNTO (15 * W)));
	TK1_C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 7 * W - 1) DOWNTO ( 6 * W)), KEY((KA1 + 15 * W - 1) DOWNTO (KA1 + 14 * W)), TK1((15 * W - 1) DOWNTO (14 * W)));
	TK1_C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 6 * W - 1) DOWNTO ( 5 * W)), KEY((KA1 + 14 * W - 1) DOWNTO (KA1 + 13 * W)), TK1((14 * W - 1) DOWNTO (13 * W)));
	TK1_C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 5 * W - 1) DOWNTO ( 4 * W)), KEY((KA1 + 13 * W - 1) DOWNTO (KA1 + 12 * W)), TK1((13 * W - 1) DOWNTO (12 * W)));

	TK1_C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 4 * W - 1) DOWNTO ( 3 * W)), KEY((KA1 + 12 * W - 1) DOWNTO (KA1 + 11 * W)), TK1((12 * W - 1) DOWNTO (11 * W)));
	TK1_C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 3 * W - 1) DOWNTO ( 2 * W)), KEY((KA1 + 11 * W - 1) DOWNTO (KA1 + 10 * W)), TK1((11 * W - 1) DOWNTO (10 * W)));
	TK1_C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 2 * W - 1) DOWNTO ( 1 * W)), KEY((KA1 + 10 * W - 1) DOWNTO (KA1 +  9 * W)), TK1((10 * W - 1) DOWNTO ( 9 * W)));
	TK1_C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK1_NPERM(( 1 * W - 1) DOWNTO ( 0 * W)), KEY((KA1 +  9 * W - 1) DOWNTO (KA1 +  8 * W)), TK1(( 9 * W - 1) DOWNTO ( 8 * W)));

	TK1_C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 8 * W - 1) DOWNTO ( 7 * W)), KEY((KA1 +  8 * W - 1) DOWNTO (KA1 +  7 * W)),  TK1(( 8 * W - 1) DOWNTO ( 7 * W)));
	TK1_C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 7 * W - 1) DOWNTO ( 6 * W)), KEY((KA1 +  7 * W - 1) DOWNTO (KA1 +  6 * W)),  TK1(( 7 * W - 1) DOWNTO ( 6 * W)));
	TK1_C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 6 * W - 1) DOWNTO ( 5 * W)), KEY((KA1 +  6 * W - 1) DOWNTO (KA1 +  5 * W)),  TK1(( 6 * W - 1) DOWNTO ( 5 * W)));
	TK1_C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 5 * W - 1) DOWNTO ( 4 * W)), KEY((KA1 +  5 * W - 1) DOWNTO (KA1 +  4 * W)),  TK1(( 5 * W - 1) DOWNTO ( 4 * W)));

	TK1_C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 4 * W - 1) DOWNTO ( 3 * W)), KEY((KA1 +  4 * W - 1) DOWNTO (KA1 +  3 * W)),  TK1(( 4 * W - 1) DOWNTO ( 3 * W)));
	TK1_C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 3 * W - 1) DOWNTO ( 2 * W)), KEY((KA1 +  3 * W - 1) DOWNTO (KA1 +  2 * W)),  TK1(( 3 * W - 1) DOWNTO ( 2 * W)));
	TK1_C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 2 * W - 1) DOWNTO ( 1 * W)), KEY((KA1 +  2 * W - 1) DOWNTO (KA1 +  1 * W)),  TK1(( 2 * W - 1) DOWNTO ( 1 * W)));
	TK1_C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK1_NEXT(( 1 * W - 1) DOWNTO ( 0 * W)), KEY((KA1 +  1 * W - 1) DOWNTO (KA1 +  0 * W)),  TK1(( 1 * W - 1) DOWNTO ( 0 * W)));

	-- PERMUTATION -------------------------------------------------------------
	TK1_P1 : ENTITY work.Permutation PORT MAP (TK1((16 * W - 1) DOWNTO (8 * W)), TK1_PERM);

	-- NO LFSR -----------------------------------------------------------------
	TK1_LFSR <= TK1((8 * W - 1) DOWNTO (7 * W));

	-- NEXT KEY ----------------------------------------------------------------
	TK1_NEXT <= TK1((15 * W - 1) DOWNTO (8 * W)) & TK1_LFSR & TK1(( 7 * W - 1) DOWNTO (0 * W)) & TK1((16 * W - 1) DOWNTO (15 * W));

	-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
	TK1_NPERM <= TK1_NEXT(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK1_PERM((8 * W - 1) DOWNTO (0 * W));

	-- ROUND KEY ---------------------------------------------------------------
	ROUND_KEY((1 * W - 1) DOWNTO (0 * W)) <= TK1((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');


	-- TWEAKEY ARRAY PERMUTATIONS : TK2 -------------------------------------------
	-- REGISTER STAGE -------------------------------------------------------------
	TK2_C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 8 * W - 1) DOWNTO ( 7 * W)), KEY((KA2 + 32 * W - 1) DOWNTO (KA2 + 31 * W)), TK2((16 * W - 1) DOWNTO (15 * W)));
	TK2_C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 7 * W - 1) DOWNTO ( 6 * W)), KEY((KA2 + 31 * W - 1) DOWNTO (KA2 + 30 * W)), TK2((15 * W - 1) DOWNTO (14 * W)));
	TK2_C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 6 * W - 1) DOWNTO ( 5 * W)), KEY((KA2 + 30 * W - 1) DOWNTO (KA2 + 29 * W)), TK2((14 * W - 1) DOWNTO (13 * W)));
	TK2_C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 5 * W - 1) DOWNTO ( 4 * W)), KEY((KA2 + 29 * W - 1) DOWNTO (KA2 + 28 * W)), TK2((13 * W - 1) DOWNTO (12 * W)));

	TK2_C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 4 * W - 1) DOWNTO ( 3 * W)), KEY((KA2 + 28 * W - 1) DOWNTO (KA2 + 27 * W)), TK2((12 * W - 1) DOWNTO (11 * W)));
	TK2_C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 3 * W - 1) DOWNTO ( 2 * W)), KEY((KA2 + 27 * W - 1) DOWNTO (KA2 + 26 * W)), TK2((11 * W - 1) DOWNTO (10 * W)));
	TK2_C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 2 * W - 1) DOWNTO ( 1 * W)), KEY((KA2 + 26 * W - 1) DOWNTO (KA2 + 25 * W)), TK2((10 * W - 1) DOWNTO ( 9 * W)));
	TK2_C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK2_NPERM(( 1 * W - 1) DOWNTO ( 0 * W)), KEY((KA2 + 25 * W - 1) DOWNTO (KA2 + 24 * W)), TK2(( 9 * W - 1) DOWNTO ( 8 * W)));

	TK2_C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 8 * W - 1) DOWNTO ( 7 * W)), KEY((KA2 + 24 * W - 1) DOWNTO (KA2 + 23 * W)),  TK2(( 8 * W - 1) DOWNTO ( 7 * W)));
	TK2_C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 7 * W - 1) DOWNTO ( 6 * W)), KEY((KA2 + 23 * W - 1) DOWNTO (KA2 + 22 * W)),  TK2(( 7 * W - 1) DOWNTO ( 6 * W)));
	TK2_C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 6 * W - 1) DOWNTO ( 5 * W)), KEY((KA2 + 22 * W - 1) DOWNTO (KA2 + 21 * W)),  TK2(( 6 * W - 1) DOWNTO ( 5 * W)));
	TK2_C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 5 * W - 1) DOWNTO ( 4 * W)), KEY((KA2 + 21 * W - 1) DOWNTO (KA2 + 20 * W)),  TK2(( 5 * W - 1) DOWNTO ( 4 * W)));

	TK2_C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 4 * W - 1) DOWNTO ( 3 * W)), KEY((KA2 + 20 * W - 1) DOWNTO (KA2 + 19 * W)),  TK2(( 4 * W - 1) DOWNTO ( 3 * W)));
	TK2_C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 3 * W - 1) DOWNTO ( 2 * W)), KEY((KA2 + 19 * W - 1) DOWNTO (KA2 + 18 * W)),  TK2(( 3 * W - 1) DOWNTO ( 2 * W)));
	TK2_C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 2 * W - 1) DOWNTO ( 1 * W)), KEY((KA2 + 18 * W - 1) DOWNTO (KA2 + 17 * W)),  TK2(( 2 * W - 1) DOWNTO ( 1 * W)));
	TK2_C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK2_NEXT(( 1 * W - 1) DOWNTO ( 0 * W)), KEY((KA2 + 17 * W - 1) DOWNTO (KA2 + 16 * W)),  TK2(( 1 * W - 1) DOWNTO ( 0 * W)));


	-- PERMUTATION -------------------------------------------------------------
	TK2_P2 : ENTITY work.Permutation PORT MAP (TK2((16 * W - 1) DOWNTO (8 * W)), TK2_PERM);

	-- NO LFSR -----------------------------------------------------------------
	TK2_LFSR <= TK2((8 * W - 1) DOWNTO (7 * W)) WHEN (RESET = '1') ELSE TK2((8 * W - 2) DOWNTO (7 * W)) & (TK2(8 * W - 1) XOR TK2(8 * W - (W / 8) - 2));

	-- NEXT KEY ----------------------------------------------------------------
	TK2_NEXT <= TK2((15 * W - 1) DOWNTO (8 * W)) & TK2_LFSR & TK2(( 7 * W - 1) DOWNTO (0 * W)) & TK2((16 * W - 1) DOWNTO (15 * W));

	-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
	TK2_NPERM <= TK2_NEXT(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK2_PERM((8 * W - 1) DOWNTO (0 * W));

	-- ROUND KEY ---------------------------------------------------------------
	ROUND_KEY((2 * W - 1) DOWNTO (1 * W)) <= TK2((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

	-- TWEAKEY ARRAY PERMUTATIONS : TK3 -------------------------------------------
	-- REGISTER STAGE -------------------------------------------------------------
	TK3_C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 8 * W - 1) DOWNTO ( 7 * W)), KEY((KA3 + 48 * W - 1) DOWNTO (KA3 + 47 * W)), TK3((16 * W - 1) DOWNTO (15 * W)));
	TK3_C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 7 * W - 1) DOWNTO ( 6 * W)), KEY((KA3 + 47 * W - 1) DOWNTO (KA3 + 46 * W)), TK3((15 * W - 1) DOWNTO (14 * W)));
	TK3_C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 6 * W - 1) DOWNTO ( 5 * W)), KEY((KA3 + 46 * W - 1) DOWNTO (KA3 + 45 * W)), TK3((14 * W - 1) DOWNTO (13 * W)));
	TK3_C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 5 * W - 1) DOWNTO ( 4 * W)), KEY((KA3 + 45 * W - 1) DOWNTO (KA3 + 44 * W)), TK3((13 * W - 1) DOWNTO (12 * W)));

	TK3_C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 4 * W - 1) DOWNTO ( 3 * W)), KEY((KA3 + 44 * W - 1) DOWNTO (KA3 + 43 * W)), TK3((12 * W - 1) DOWNTO (11 * W)));
	TK3_C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 3 * W - 1) DOWNTO ( 2 * W)), KEY((KA3 + 43 * W - 1) DOWNTO (KA3 + 42 * W)), TK3((11 * W - 1) DOWNTO (10 * W)));
	TK3_C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 2 * W - 1) DOWNTO ( 1 * W)), KEY((KA3 + 42 * W - 1) DOWNTO (KA3 + 41 * W)), TK3((10 * W - 1) DOWNTO ( 9 * W)));
	TK3_C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_H, RESET, TK3_NPERM(( 1 * W - 1) DOWNTO ( 0 * W)), KEY((KA3 + 41 * W - 1) DOWNTO (KA3 + 40 * W)), TK3(( 9 * W - 1) DOWNTO ( 8 * W)));

	TK3_C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 8 * W - 1) DOWNTO ( 7 * W)), KEY((KA3 + 40 * W - 1) DOWNTO (KA3 + 39 * W)),  TK3(( 8 * W - 1) DOWNTO ( 7 * W)));
	TK3_C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 7 * W - 1) DOWNTO ( 6 * W)), KEY((KA3 + 39 * W - 1) DOWNTO (KA3 + 38 * W)),  TK3(( 7 * W - 1) DOWNTO ( 6 * W)));
	TK3_C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 6 * W - 1) DOWNTO ( 5 * W)), KEY((KA3 + 38 * W - 1) DOWNTO (KA3 + 37 * W)),  TK3(( 6 * W - 1) DOWNTO ( 5 * W)));
	TK3_C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 5 * W - 1) DOWNTO ( 4 * W)), KEY((KA3 + 37 * W - 1) DOWNTO (KA3 + 36 * W)),  TK3(( 5 * W - 1) DOWNTO ( 4 * W)));

	TK3_C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 4 * W - 1) DOWNTO ( 3 * W)), KEY((KA3 + 36 * W - 1) DOWNTO (KA3 + 35 * W)),  TK3(( 4 * W - 1) DOWNTO ( 3 * W)));
	TK3_C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 3 * W - 1) DOWNTO ( 2 * W)), KEY((KA3 + 35 * W - 1) DOWNTO (KA3 + 34 * W)),  TK3(( 3 * W - 1) DOWNTO ( 2 * W)));
	TK3_C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 2 * W - 1) DOWNTO ( 1 * W)), KEY((KA3 + 34 * W - 1) DOWNTO (KA3 + 33 * W)),  TK3(( 2 * W - 1) DOWNTO ( 1 * W)));
	TK3_C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK_L, RESET, TK3_NEXT(( 1 * W - 1) DOWNTO ( 0 * W)), KEY((KA3 + 33 * W - 1) DOWNTO (KA3 + 32 * W)),  TK3(( 1 * W - 1) DOWNTO ( 0 * W)));


	-- PERMUTATION -------------------------------------------------------------
	TK3_P3 : ENTITY work.Permutation PORT MAP (TK3((16 * W - 1) DOWNTO (8 * W)), TK3_PERM);

	-- NO LFSR -----------------------------------------------------------------
	TK3_LFSR <= TK3((8 * W - 1) DOWNTO (7 * W)) WHEN (RESET = '1') ELSE (TK3(8 * W - (W / 8) - 1) XOR TK3(7 * W)) & TK3((8 * W - 1) DOWNTO (7 * W + 1));

	-- NEXT KEY ----------------------------------------------------------------
	TK3_NEXT <= TK3((15 * W - 1) DOWNTO (8 * W)) & TK3_LFSR & TK3(( 7 * W - 1) DOWNTO (0 * W)) & TK3((16 * W - 1) DOWNTO (15 * W));

	-- PERMUTAION OR NEXT KEY ----------------------------------------------------------------
	TK3_NPERM <= TK3_NEXT(( 16 * W - 1) DOWNTO ( 8 * W)) WHEN KEY_CTL(1) = '0' ELSE TK3_PERM((8 * W - 1) DOWNTO (0 * W));

	-- ROUND KEY ---------------------------------------------------------------
	ROUND_KEY((3 * W - 1) DOWNTO (2 * W)) <= TK3((16 * W - 1) DOWNTO (15 * W)) WHEN (KEY_CTL(0) = '1') ELSE (OTHERS => '0');

END Round;

