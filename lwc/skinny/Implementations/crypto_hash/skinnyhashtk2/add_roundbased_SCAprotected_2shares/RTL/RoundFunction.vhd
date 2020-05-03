--
-- SKINNY-Hash Reference Hardware Implementation
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
ENTITY RoundFunction IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
			 LAST			: IN	STD_LOGIC;
   	    -- CONSTANT PORT --------------------------------
          ROUND_CST  : IN  STD_LOGIC_VECTOR (  5 DOWNTO 0);
   	    -- KEY PORT -------------------------------------
          ROUND_TK1_1: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          ROUND_TK1_2: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          ROUND_TK2_1: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          ROUND_TK2_2: IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          SHARE1_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE2_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE1_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE2_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF RoundFunction IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE1, STATE1_NEXT, SUB1_OUT, ADD1_OUT, SHIFT1_OUT, MIX1_OUT, S_MID_A1, S_MID_C1	: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL STATE2, STATE2_NEXT, SUB2_OUT, ADD2_OUT, SHIFT2_OUT, MIX2_OUT, S_MID_A2, S_MID_C2	: STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL S_MID_B1, STATE_EX1	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL S_MID_B2, STATE_EX2	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	SIGNAL RESET_OR_LAST			: STD_LOGIC;
	
BEGIN

	-- REGISTER STAGE -------------------------------------------------------------
	RS1 : ENTITY work.ScanFF GENERIC MAP (SIZE => 128) PORT MAP (CLK, RESET, STATE1_NEXT, SHARE1_IN, STATE1);
	RS2 : ENTITY work.ScanFF GENERIC MAP (SIZE => 128) PORT MAP (CLK, RESET, STATE2_NEXT, SHARE2_IN, STATE2);

	RESET_OR_LAST 	<= RESET OR LAST;

	RS_EX1 : ENTITY work.Reg_clr GENERIC MAP (SIZE => 32) PORT MAP (CLK, RESET_OR_LAST, S_MID_B1, STATE_EX1);
	RS_EX2 : ENTITY work.Reg_clr GENERIC MAP (SIZE => 32) PORT MAP (CLK, RESET_OR_LAST, S_MID_B2, STATE_EX2);

	-- ENCRYPTION -----------------------------------------------------------------

	-- SUBSTITUTION ---------------------------------------------------------------
	SB : FOR I IN 0 TO 15 GENERATE
		S_Com: entity work.FGHI_Combine
		port map(
			STATE1    ((8 * I + 7) DOWNTO (8 * I)), 
			STATE2    ((8 * I + 7) DOWNTO (8 * I)),
			STATE_EX1 ((2 * I + 1) DOWNTO (2 * I)),
			STATE_EX2 ((2 * I + 1) DOWNTO (2 * I)),
			S_MID_A1  ((8 * I + 7) DOWNTO (8 * I)),
			S_MID_A2  ((8 * I + 7) DOWNTO (8 * I)),
			SUB1_OUT  ((8 * I + 7) DOWNTO (8 * I)),
			SUB2_OUT  ((8 * I + 7) DOWNTO (8 * I)));

		S_TI: entity work.SboxFGHI_dp1
		port map(
			S_MID_A1  ((8 * I + 7) DOWNTO (8 * I)),
			S_MID_A2  ((8 * I + 7) DOWNTO (8 * I)),
			S_MID_C1  ((8 * I + 7) DOWNTO (8 * I)),
			S_MID_C2  ((8 * I + 7) DOWNTO (8 * I)),
			S_MID_B1  ((2 * I + 1) DOWNTO (2 * I)),
			S_MID_B2  ((2 * I + 1) DOWNTO (2 * I)));	
	END GENERATE;

	-- CONSTANT AND KEY ADDITION --------------------------------------------------
	KA1 : ENTITY work.AddConstKey Generic Map (1) PORT MAP (ROUND_CST,       ROUND_TK1_1, ROUND_TK2_1, SUB1_OUT, ADD1_OUT);
	KA2 : ENTITY work.AddConstKey Generic Map (0) PORT MAP ((others => '0'), ROUND_TK1_2, ROUND_TK2_2, SUB2_OUT, ADD2_OUT);

	-- SHIFT ROWS -----------------------------------------------------------------
	SR1 : ENTITY work.ShiftRows PORT MAP (ADD1_OUT, SHIFT1_OUT);
	SR2 : ENTITY work.ShiftRows PORT MAP (ADD2_OUT, SHIFT2_OUT);

	-- MIX COLUMNS ----------------------------------------------------------------
	MC1 : ENTITY work.MixColumns PORT MAP (SHIFT1_OUT, MIX1_OUT);
	MC2 : ENTITY work.MixColumns PORT MAP (SHIFT2_OUT, MIX2_OUT);

	-------------------------------------------------------------------------------

	-- ROUND OUTPUT ---------------------------------------------------------------
	STATE1_NEXT <= MIX1_OUT WHEN (LAST = '1') ELSE S_MID_C1;
	STATE2_NEXT <= MIX2_OUT WHEN (LAST = '1') ELSE S_MID_C2;

	SHARE1_OUT <= STATE1_NEXT;
	SHARE2_OUT <= STATE2_NEXT;

END Round;
