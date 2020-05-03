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
ENTITY RoundFunction IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
          ROUND_CTL  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
   	    -- CONSTANT PORT --------------------------------
          ROUND_CST  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
   	    -- KEY PORT -------------------------------------
          ROUND_TK1  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
          ROUND_TK2_1: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
          ROUND_TK2_2: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          SHARE1_IN  : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          SHARE2_IN  : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          SHARE1_OUT : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
          SHARE2_OUT : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : ROW
----------------------------------------------------------------------------------
ARCHITECTURE Row OF RoundFunction IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;
	CONSTANT N : INTEGER := 128;

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, SHIFTROWS, STATE_NEXT : STD_LOGIC_VECTOR((2 * 16 * W - 1) DOWNTO 0);
	SIGNAL SUBSTITUTE, ADDITION			: STD_LOGIC_VECTOR((2 *  1 * W - 1) DOWNTO 0);
	SIGNAL COLUMN, MIXCOLUMN				: STD_LOGIC_VECTOR((2 *  4 * W - 1) DOWNTO 0);
	SIGNAL E1, E2, N1, N2					: STD_LOGIC_VECTOR(              1  DOWNTO 0);

BEGIN

   -- SIGNAL ASSIGNMENTS ---------------------------------------------------------
   COLUMN(( 4 * W - 1) DOWNTO (0 * W)) <= STATE((0 * N + 16 * W - 1) DOWNTO (0 * N + 15 * W)) & STATE((0 * N + 12 * W - 1) DOWNTO (0 * N + 11 * W)) & STATE((0 * N + 8 * W - 1) DOWNTO (0 * N + 7 * W)) & STATE((0 * N + 4 * W - 1) DOWNTO (0 * N + 3 * W));
	COLUMN(( 8 * W - 1) DOWNTO (4 * W)) <= STATE((1 * N + 16 * W - 1) DOWNTO (1 * N + 15 * W)) & STATE((1 * N + 12 * W - 1) DOWNTO (1 * N + 11 * W)) & STATE((1 * N + 8 * W - 1) DOWNTO (1 * N + 7 * W)) & STATE((1 * N + 4 * W - 1) DOWNTO (1 * N + 3 * W));

	-- REGISTER STAGES ------------------------------------------------------------
	RS1 : ENTITY work.RegisterStage PORT MAP (CLK, RESET, ROUND_CTL(0), SHARE1_IN, STATE_NEXT((1 * N - 1) DOWNTO (0 * N)), SHIFTROWS((1 * N - 1) DOWNTO (0 * N)), STATE((1 * N - 1) DOWNTO (0 * N)));
	RS2 : ENTITY work.RegisterStage PORT MAP (CLK, RESET, ROUND_CTL(0), SHARE2_IN, STATE_NEXT((2 * N - 1) DOWNTO (1 * N)), SHIFTROWS((2 * N - 1) DOWNTO (1 * N)), STATE((2 * N - 1) DOWNTO (1 * N)));

	EX1 : ENTITY work.Expansion GENERIC MAP (SIZE => 2) PORT MAP (CLK, RESET, ROUND_CTL(2), N1, E1);
	EX2 : ENTITY work.Expansion GENERIC MAP (SIZE => 2) PORT MAP (CLK, RESET, ROUND_CTL(2), N2, E2);

	-- SUBSTITUTION ---------------------------------------------------------------
	SB : ENTITY work.SBox
	PORT MAP (
		ROUND_CTL(2),
		E1, E2, N1, N2,
		STATE((16 * W - 1) DOWNTO (15 * W)),
		STATE((32 * W - 1) DOWNTO (31 * W)),
		SUBSTITUTE((1 * W - 1) DOWNTO (0 * W)),
		SUBSTITUTE((2 * W - 1) DOWNTO (1 * W))
	);

	-- CONSTANT AND KEY ADDITION --------------------------------------------------
	KA1 : ENTITY work.AddConstKey PORT MAP (ROUND_CST, ROUND_TK2_1, SUBSTITUTE((1 * W - 1) DOWNTO (0 * W)), ADDITION((1 * W - 1) DOWNTO (0 * W)));
	KA2 : ENTITY work.AddConstKey PORT MAP (ROUND_TK1, ROUND_TK2_2, SUBSTITUTE((2 * W - 1) DOWNTO (1 * W)), ADDITION((2 * W - 1) DOWNTO (1 * W)));

	-- SHIFT ROWS -----------------------------------------------------------------
	SR1 : ENTITY work.ShiftRows PORT MAP (STATE((1 * N - 1) DOWNTO (0 * N)), SHIFTROWS((1 * N - 1) DOWNTO (0 * N)));
	SR2 : ENTITY work.ShiftRows PORT MAP (STATE((2 * N - 1) DOWNTO (1 * N)), SHIFTROWS((2 * N - 1) DOWNTO (1 * N)));

	-- MIX COLUMNS ----------------------------------------------------------------
	MC1 : ENTITY work.MixColumns PORT MAP (COLUMN(( 4 * W - 1) DOWNTO (0 * W)), MIXCOLUMN(( 4 * W - 1) DOWNTO (0 * W)));
	MC2 : ENTITY work.MixColumns PORT MAP (COLUMN(( 8 * W - 1) DOWNTO (4 * W)), MIXCOLUMN(( 8 * W - 1) DOWNTO (4 * W)));

   -- MULTIPLEXERS ---------------------------------------------------------------
   STATE_NEXT((16 * W - 1) DOWNTO (12 * W)) <= STATE((15 * W - 1) DOWNTO (12 * W)) & MIXCOLUMN(( 4 * W - 1) DOWNTO ( 3 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE((15 * W - 1) DOWNTO (11 * W));
	STATE_NEXT((32 * W - 1) DOWNTO (28 * W)) <= STATE((31 * W - 1) DOWNTO (28 * W)) & MIXCOLUMN(( 8 * W - 1) DOWNTO ( 7 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE((31 * W - 1) DOWNTO (27 * W));

	STATE_NEXT((12 * W - 1) DOWNTO ( 8 * W)) <= STATE((11 * W - 1) DOWNTO ( 8 * W)) & MIXCOLUMN(( 3 * W - 1) DOWNTO ( 2 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE((11 * W - 1) DOWNTO ( 7 * W));
	STATE_NEXT((28 * W - 1) DOWNTO (24 * W)) <= STATE((27 * W - 1) DOWNTO (24 * W)) & MIXCOLUMN(( 7 * W - 1) DOWNTO ( 6 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE((27 * W - 1) DOWNTO (23 * W));

	STATE_NEXT(( 8 * W - 1) DOWNTO ( 4 * W)) <= STATE(( 7 * W - 1) DOWNTO ( 4 * W)) & MIXCOLUMN(( 2 * W - 1) DOWNTO ( 1 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE(( 7 * W - 1) DOWNTO ( 3 * W));
	STATE_NEXT((24 * W - 1) DOWNTO (20 * W)) <= STATE((23 * W - 1) DOWNTO (20 * W)) & MIXCOLUMN(( 6 * W - 1) DOWNTO ( 5 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE((23 * W - 1) DOWNTO (19 * W));

	STATE_NEXT(( 4 * W - 1) DOWNTO ( 0 * W)) <= STATE(( 3 * W - 1) DOWNTO ( 0 * W)) & MIXCOLUMN(( 1 * W - 1) DOWNTO ( 0 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE(( 3 * W - 1) DOWNTO ( 0 * W)) & SUBSTITUTE((1 * W - 1) DOWNTO ( 0 * W)) WHEN (ROUND_CTL(2) = '0') ELSE STATE(( 3 * W - 1) DOWNTO ( 0 * W)) & ADDITION((1 * W - 1) DOWNTO (0 * W));
	STATE_NEXT((20 * W - 1) DOWNTO (16 * W)) <= STATE((19 * W - 1) DOWNTO (16 * W)) & MIXCOLUMN(( 5 * W - 1) DOWNTO ( 4 * W)) WHEN (ROUND_CTL(1) = '1') ELSE STATE((19 * W - 1) DOWNTO (16 * W)) & SUBSTITUTE((2 * W - 1) DOWNTO ( 1 * W)) WHEN (ROUND_CTL(2) = '0') ELSE STATE((19 * W - 1) DOWNTO (16 * W)) & ADDITION((2 * W - 1) DOWNTO (1 * W));

	-- ROUND OUTPUT ---------------------------------------------------------------
	SHARE1_OUT <= STATE((0 * N + 16 * W - 1) DOWNTO (0 * N + 0 * W));
	SHARE2_OUT <= STATE((1 * N + 16 * W - 1) DOWNTO (1 * N + 0 * W));

END Row;
