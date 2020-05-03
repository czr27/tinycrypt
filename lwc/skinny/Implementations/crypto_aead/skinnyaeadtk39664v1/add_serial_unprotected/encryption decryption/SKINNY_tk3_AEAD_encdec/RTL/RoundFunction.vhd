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
          DECRYPT    : IN  STD_LOGIC;
          ROUND_CTL  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
   	    -- CONSTANT PORT --------------------------------
          ROUND_CST  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
   	    -- KEY PORT -------------------------------------
          ROUND_KEY  : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          ROUND_IN   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          ROUND_OUT  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : ROW
----------------------------------------------------------------------------------
ARCHITECTURE Row OF RoundFunction IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, STATE_NEXT, SHIFTROWS     : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL COLUMN, MIXCOLUMN	             : STD_LOGIC_VECTOR( 31 DOWNTO 0);
	SIGNAL SUBSTITUTE_ENC, SUBSTITUTE_DEC   : STD_LOGIC_VECTOR(  7 DOWNTO 0);
	SIGNAL ADDITION_IN, ADDITION_OUT		    : STD_LOGIC_VECTOR(  7 DOWNTO 0);

BEGIN

   -- SIGNAL ASSIGNMENTS ---------------------------------------------------------
   COLUMN <= STATE((16 * 8 - 1) DOWNTO (15 * 8)) & STATE((12 * 8 - 1) DOWNTO (11 * 8)) & STATE((8 * 8 - 1) DOWNTO (7 * 8)) & STATE((4 * 8 - 1) DOWNTO (3 * 8));

	-- REGISTER STAGES ------------------------------------------------------------
	C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((16 * 8 - 1) DOWNTO (15 * 8)), SHIFTROWS((16 * 8 - 1) DOWNTO (15 * 8)), STATE((16 * 8 - 1) DOWNTO (15 * 8)));
	C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((15 * 8 - 1) DOWNTO (14 * 8)), SHIFTROWS((15 * 8 - 1) DOWNTO (14 * 8)), STATE((15 * 8 - 1) DOWNTO (14 * 8)));
	C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((14 * 8 - 1) DOWNTO (13 * 8)), SHIFTROWS((14 * 8 - 1) DOWNTO (13 * 8)), STATE((14 * 8 - 1) DOWNTO (13 * 8)));
	C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((13 * 8 - 1) DOWNTO (12 * 8)), SHIFTROWS((13 * 8 - 1) DOWNTO (12 * 8)), STATE((13 * 8 - 1) DOWNTO (12 * 8)));

	C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((12 * 8 - 1) DOWNTO (11 * 8)), SHIFTROWS((12 * 8 - 1) DOWNTO (11 * 8)), STATE((12 * 8 - 1) DOWNTO (11 * 8)));
	C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((11 * 8 - 1) DOWNTO (10 * 8)), SHIFTROWS((11 * 8 - 1) DOWNTO (10 * 8)), STATE((11 * 8 - 1) DOWNTO (10 * 8)));
	C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT((10 * 8 - 1) DOWNTO ( 9 * 8)), SHIFTROWS((10 * 8 - 1) DOWNTO ( 9 * 8)), STATE((10 * 8 - 1) DOWNTO ( 9 * 8)));
	C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 9 * 8 - 1) DOWNTO ( 8 * 8)), SHIFTROWS(( 9 * 8 - 1) DOWNTO ( 8 * 8)), STATE(( 9 * 8 - 1) DOWNTO ( 8 * 8)));

	C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 8 * 8 - 1) DOWNTO ( 7 * 8)), SHIFTROWS(( 8 * 8 - 1) DOWNTO ( 7 * 8)), STATE(( 8 * 8 - 1) DOWNTO ( 7 * 8)));
	C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 7 * 8 - 1) DOWNTO ( 6 * 8)), SHIFTROWS(( 7 * 8 - 1) DOWNTO ( 6 * 8)), STATE(( 7 * 8 - 1) DOWNTO ( 6 * 8)));
	C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 6 * 8 - 1) DOWNTO ( 5 * 8)), SHIFTROWS(( 6 * 8 - 1) DOWNTO ( 5 * 8)), STATE(( 6 * 8 - 1) DOWNTO ( 5 * 8)));
	C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 5 * 8 - 1) DOWNTO ( 4 * 8)), SHIFTROWS(( 5 * 8 - 1) DOWNTO ( 4 * 8)), STATE(( 5 * 8 - 1) DOWNTO ( 4 * 8)));

	C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 4 * 8 - 1) DOWNTO ( 3 * 8)), SHIFTROWS(( 4 * 8 - 1) DOWNTO ( 3 * 8)), STATE(( 4 * 8 - 1) DOWNTO ( 3 * 8)));
	C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 3 * 8 - 1) DOWNTO ( 2 * 8)), SHIFTROWS(( 3 * 8 - 1) DOWNTO ( 2 * 8)), STATE(( 3 * 8 - 1) DOWNTO ( 2 * 8)));
	C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 2 * 8 - 1) DOWNTO ( 1 * 8)), SHIFTROWS(( 2 * 8 - 1) DOWNTO ( 1 * 8)), STATE(( 2 * 8 - 1) DOWNTO ( 1 * 8)));
	C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(( 1 * 8 - 1) DOWNTO ( 0 * 8)), SHIFTROWS(( 1 * 8 - 1) DOWNTO ( 0 * 8)), STATE(( 1 * 8 - 1) DOWNTO ( 0 * 8)));

	-- KEY & CONSTANT ADDITION ----------------------------------------------------
	ADDITION_IN <= SUBSTITUTE_ENC WHEN (DECRYPT = '0') ELSE STATE(127 DOWNTO 120);

	-- ENCRYPTION -----------------------------------------------------------------
	SBE : ENTITY work.SBox PORT MAP (STATE(127 DOWNTO 120), SUBSTITUTE_ENC);
	
	-- DECRYPTION -----------------------------------------------------------------
	SBD : ENTITY work.SBoxInv PORT MAP (ADDITION_OUT, SUBSTITUTE_DEC);
		
	-- SHARED ---------------------------------------------------------------------
	KA : ENTITY work.AddConstKey PORT MAP (ROUND_CST, ROUND_KEY, ADDITION_IN, ADDITION_OUT);
	SR : ENTITY work.ShiftRows   PORT MAP (DECRYPT, STATE, SHIFTROWS);
	MC : ENTITY work.MixColumns  PORT MAP (DECRYPT, COLUMN, MIXCOLUMN);
   
	-- MULTIPLEXER ----------------------------------------------------------------
   STATE_NEXT((16 * 8 - 1) DOWNTO (12 * 8)) <= STATE((15 * 8 - 1) DOWNTO (12 * 8)) & MIXCOLUMN((4 * 8 - 1) DOWNTO (3 * 8)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN((16 * 8 - 1) DOWNTO (12 * 8)) WHEN (RESET = '1') ELSE STATE((15 * 8 - 1) DOWNTO (11 * 8));
   STATE_NEXT((12 * 8 - 1) DOWNTO ( 8 * 8)) <= STATE((11 * 8 - 1) DOWNTO ( 8 * 8)) & MIXCOLUMN((3 * 8 - 1) DOWNTO (2 * 8)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN((12 * 8 - 1) DOWNTO ( 8 * 8)) WHEN (RESET = '1') ELSE STATE((11 * 8 - 1) DOWNTO ( 7 * 8));
   STATE_NEXT(( 8 * 8 - 1) DOWNTO ( 4 * 8)) <= STATE(( 7 * 8 - 1) DOWNTO ( 4 * 8)) & MIXCOLUMN((2 * 8 - 1) DOWNTO (1 * 8)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN(( 8 * 8 - 1) DOWNTO ( 4 * 8)) WHEN (RESET = '1') ELSE STATE(( 7 * 8 - 1) DOWNTO ( 3 * 8));
   STATE_NEXT(( 4 * 8 - 1) DOWNTO ( 0 * 8)) <= STATE(( 3 * 8 - 1) DOWNTO ( 0 * 8)) & MIXCOLUMN((1 * 8 - 1) DOWNTO (0 * 8)) WHEN (ROUND_CTL(1) = '1') ELSE ROUND_IN(( 4 * 8 - 1) DOWNTO ( 0 * 8)) WHEN (RESET = '1') ELSE STATE(( 3 * 8 - 1) DOWNTO ( 0 * 8)) & ADDITION_OUT WHEN (DECRYPT = '0') ELSE STATE(( 3 * 8 - 1) DOWNTO ( 0 * 8)) & SUBSTITUTE_DEC;

	-- ROUND OUTPUT ---------------------------------------------------------------
	ROUND_OUT <= STATE;

END Row;
