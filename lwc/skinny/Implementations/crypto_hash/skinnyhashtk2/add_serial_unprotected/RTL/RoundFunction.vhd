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
          ROUND_CTL  : IN  STD_LOGIC_VECTOR(  1 DOWNTO 0);
   	    -- CONSTANT PORT --------------------------------
          ROUND_CST  : IN  STD_LOGIC_VECTOR(  7 DOWNTO 0);
   	    -- KEY PORT -------------------------------------
          ROUND_KEY  : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          ROUND_IN   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          ROUND_OUT  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : ROW
----------------------------------------------------------------------------------
ARCHITECTURE Row OF RoundFunction IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;
	CONSTANT N : INTEGER := 128;
	CONSTANT T : INTEGER := 256;

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, SHIFTROWS, STATE_NEXT : STD_LOGIC_VECTOR((16 * W - 1) DOWNTO 0);
	SIGNAL SUBSTITUTE, ADDITION			: STD_LOGIC_VECTOR(( 1 * W - 1) DOWNTO 0);
	SIGNAL COLUMN, MIXCOLUMN				: STD_LOGIC_VECTOR(( 4 * W - 1) DOWNTO 0);

BEGIN

   -- SIGNAL ASSIGNMENTS ---------------------------------------------------------
   COLUMN <= STATE((16 * W - 1) DOWNTO (15 * W)) & STATE((12 * W - 1) DOWNTO (11 * W)) & STATE((8 * W - 1) DOWNTO (7 * W)) & STATE((4 * W - 1) DOWNTO (3 * W));

	-- REGISTER STAGES ------------------------------------------------------------
	C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((16 * W - 1) DOWNTO (15 * W)), SHIFTROWS((16 * W - 1) DOWNTO (15 * W)), STATE((16 * W - 1) DOWNTO (15 * W)));
	C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((15 * W - 1) DOWNTO (14 * W)), SHIFTROWS((15 * W - 1) DOWNTO (14 * W)), STATE((15 * W - 1) DOWNTO (14 * W)));
	C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((14 * W - 1) DOWNTO (13 * W)), SHIFTROWS((14 * W - 1) DOWNTO (13 * W)), STATE((14 * W - 1) DOWNTO (13 * W)));
	C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((13 * W - 1) DOWNTO (12 * W)), SHIFTROWS((13 * W - 1) DOWNTO (12 * W)), STATE((13 * W - 1) DOWNTO (12 * W)));

	C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((12 * W - 1) DOWNTO (11 * W)), SHIFTROWS((12 * W - 1) DOWNTO (11 * W)), STATE((12 * W - 1) DOWNTO (11 * W)));
	C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((11 * W - 1) DOWNTO (10 * W)), SHIFTROWS((11 * W - 1) DOWNTO (10 * W)), STATE((11 * W - 1) DOWNTO (10 * W)));
	C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((10 * W - 1) DOWNTO ( 9 * W)), SHIFTROWS((10 * W - 1) DOWNTO ( 9 * W)), STATE((10 * W - 1) DOWNTO ( 9 * W)));
	C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 9 * W - 1) DOWNTO ( 8 * W)), SHIFTROWS(( 9 * W - 1) DOWNTO ( 8 * W)), STATE(( 9 * W - 1) DOWNTO ( 8 * W)));

	C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 8 * W - 1) DOWNTO ( 7 * W)), SHIFTROWS(( 8 * W - 1) DOWNTO ( 7 * W)), STATE(( 8 * W - 1) DOWNTO ( 7 * W)));
	C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 7 * W - 1) DOWNTO ( 6 * W)), SHIFTROWS(( 7 * W - 1) DOWNTO ( 6 * W)), STATE(( 7 * W - 1) DOWNTO ( 6 * W)));
	C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 6 * W - 1) DOWNTO ( 5 * W)), SHIFTROWS(( 6 * W - 1) DOWNTO ( 5 * W)), STATE(( 6 * W - 1) DOWNTO ( 5 * W)));
	C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 5 * W - 1) DOWNTO ( 4 * W)), SHIFTROWS(( 5 * W - 1) DOWNTO ( 4 * W)), STATE(( 5 * W - 1) DOWNTO ( 4 * W)));

	C03 : ENTITY work.DataFF GENERIC MAP (SIZE => W) PORT MAP (CLK, 					STATE_NEXT(( 4 * W - 1) DOWNTO ( 3 * W)), 													  STATE(( 4 * W - 1) DOWNTO ( 3 * W)));
	C02 : ENTITY work.DataFF GENERIC MAP (SIZE => W) PORT MAP (CLK, 					STATE_NEXT(( 3 * W - 1) DOWNTO ( 2 * W)), 													  STATE(( 3 * W - 1) DOWNTO ( 2 * W)));
	C01 : ENTITY work.DataFF GENERIC MAP (SIZE => W) PORT MAP (CLK, 					STATE_NEXT(( 2 * W - 1) DOWNTO ( 1 * W)), 													  STATE(( 2 * W - 1) DOWNTO ( 1 * W)));
	C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 1 * W - 1) DOWNTO ( 0 * W)), SHIFTROWS(( 1 * W - 1) DOWNTO ( 0 * W)), STATE(( 1 * W - 1) DOWNTO ( 0 * W)));

	-- SUBSTITUTION ---------------------------------------------------------------
	S : ENTITY work.SBox PORT MAP (STATE((16 * W - 1) DOWNTO (15 * W)), SUBSTITUTE);

	-- CONSTANT AND KEY ADDITION --------------------------------------------------
	KA : ENTITY work.AddConstKey PORT MAP (ROUND_CST, ROUND_KEY, SUBSTITUTE, ADDITION);

	-- SHIFT ROWS -----------------------------------------------------------------
	SR : ENTITY work.ShiftRows PORT MAP (STATE, SHIFTROWS);

	-- MIX COLUMNS ----------------------------------------------------------------
	MC : ENTITY work.MixColumns PORT MAP (COLUMN, MIXCOLUMN);

   -- MULTIPLEXERS ---------------------------------------------------------------
   STATE_NEXT((16 * W - 1) DOWNTO (12 * W)) <= STATE((15 * W - 1) DOWNTO (12 * W)) & MIXCOLUMN((4 * W - 1) DOWNTO (3 * W)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN((16 * W - 1) DOWNTO (12 * W)) WHEN (RESET = '1') ELSE STATE((15 * W - 1) DOWNTO (11 * W));
   STATE_NEXT((12 * W - 1) DOWNTO ( 8 * W)) <= STATE((11 * W - 1) DOWNTO ( 8 * W)) & MIXCOLUMN((3 * W - 1) DOWNTO (2 * W)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN((12 * W - 1) DOWNTO ( 8 * W)) WHEN (RESET = '1') ELSE STATE((11 * W - 1) DOWNTO ( 7 * W));
   STATE_NEXT(( 8 * W - 1) DOWNTO ( 4 * W)) <= STATE(( 7 * W - 1) DOWNTO ( 4 * W)) & MIXCOLUMN((2 * W - 1) DOWNTO (1 * W)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN(( 8 * W - 1) DOWNTO ( 4 * W)) WHEN (RESET = '1') ELSE STATE(( 7 * W - 1) DOWNTO ( 3 * W));
   STATE_NEXT(( 4 * W - 1) DOWNTO ( 0 * W)) <= STATE(( 3 * W - 1) DOWNTO ( 0 * W)) & MIXCOLUMN((1 * W - 1) DOWNTO (0 * W)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN(( 4 * W - 1) DOWNTO ( 0 * W)) WHEN (RESET = '1') ELSE STATE(( 3 * W - 1) DOWNTO ( 0 * W)) & ADDITION;

	-- ROUND OUTPUT ---------------------------------------------------------------
	ROUND_OUT <= STATE;

END Row;
