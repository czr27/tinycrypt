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
   	    -- CONSTANT PORT --------------------------------
          ROUND_CST  : IN  STD_LOGIC_VECTOR (  5 DOWNTO 0);
   	    -- KEY PORT -------------------------------------
          ROUND_KEY  : IN  STD_LOGIC_VECTOR (383 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          ROUND_IN   : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          ROUND_OUT  : OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF RoundFunction IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, STATE_NEXT, SUB_OUT, ADD_OUT, SHIFT_OUT, MIX_OUT	: STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN

	-- REGISTER STAGE -------------------------------------------------------------
	RS : ENTITY work.ScanFF GENERIC MAP (SIZE => 128) PORT MAP (CLK, RESET, STATE_NEXT, ROUND_IN, STATE);

	-- ENCRYPTION -----------------------------------------------------------------
	-------------------------------------------------------------------------------

	-- SUBSTITUTION ---------------------------------------------------------------
	SB : FOR I IN 0 TO 15 GENERATE
			S : ENTITY work.SBox PORT MAP (STATE((8 * I + 7) DOWNTO (8 * I)), SUB_OUT((8 * I + 7) DOWNTO (8 * I)));
	END GENERATE;

	-- CONSTANT AND KEY ADDITION --------------------------------------------------
	KA : ENTITY work.AddConstKey PORT MAP (ROUND_CST, ROUND_KEY, SUB_OUT, ADD_OUT);

	-- SHIFT ROWS -----------------------------------------------------------------
	SR : ENTITY work.ShiftRows PORT MAP (ADD_OUT, SHIFT_OUT);

	-- MIX COLUMNS ----------------------------------------------------------------
	MC : ENTITY work.MixColumns PORT MAP (SHIFT_OUT, MIX_OUT);

	-------------------------------------------------------------------------------

	-- ROUND OUTPUT ---------------------------------------------------------------
	STATE_NEXT <= MIX_OUT;

	ROUND_OUT <= STATE_NEXT;

END Round;
