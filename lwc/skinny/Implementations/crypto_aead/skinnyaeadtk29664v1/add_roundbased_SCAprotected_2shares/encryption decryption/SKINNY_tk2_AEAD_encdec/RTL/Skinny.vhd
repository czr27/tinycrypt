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
ENTITY Skinny256 IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
		    DECRYPT		: IN	STD_LOGIC;
          DONE       : OUT STD_LOGIC;
   	    -- KEY PORT -------------------------------------
          TK1        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          TK2_1      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          TK2_2      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          SHARE1_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE2_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE1_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE2_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END Skinny256;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF Skinny256 IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL ROUND_TK1  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK2_1: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK2_2: STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL ROUND_CST  : STD_LOGIC_VECTOR(  5 DOWNTO 0);
	SIGNAL FIRST  	   : STD_LOGIC;
	SIGNAL LAST   	   : STD_LOGIC;

	SIGNAL TK1_DEC   		: STD_LOGIC_VECTOR (127 DOWNTO 0);
	SIGNAL TK2_1_DEC 		: STD_LOGIC_VECTOR (127 DOWNTO 0);
	SIGNAL TK2_2_DEC 		: STD_LOGIC_VECTOR (127 DOWNTO 0);

	SIGNAL SELECTED_TK1	: STD_LOGIC_VECTOR (127 DOWNTO 0);
	SIGNAL SELECTED_TK2_1: STD_LOGIC_VECTOR (127 DOWNTO 0);
	SIGNAL SELECTED_TK2_2: STD_LOGIC_VECTOR (127 DOWNTO 0);

BEGIN

	FullKeyScheuleInst1:   entity work. FullKeySchedule1 Port Map (TK1,   TK1_DEC);
	FullKeyScheuleInst2_1: entity work. FullKeySchedule2 Port Map (TK2_1, TK2_1_DEC);
	FullKeyScheuleInst2_2: entity work. FullKeySchedule2 Port Map (TK2_2, TK2_2_DEC);

	SELECTED_TK1	<= TK1   WHEN DECRYPT = '0' ELSE TK1_DEC;
	SELECTED_TK2_1	<= TK2_1 WHEN DECRYPT = '0' ELSE TK2_1_DEC;
	SELECTED_TK2_2	<= TK2_2 WHEN DECRYPT = '0' ELSE TK2_2_DEC;
	
	-- ROUND FUNCTION -------------------------------------------------------------
	RF : ENTITY work.RoundFunction PORT MAP (CLK, RESET, DECRYPT, FIRST, LAST, ROUND_CST, ROUND_TK1, ROUND_TK2_1, ROUND_TK2_2, SHARE1_IN, SHARE2_IN, SHARE1_OUT, SHARE2_OUT);
	-------------------------------------------------------------------------------

   -- KEY EXPANSION --------------------------------------------------------------
   KE : ENTITY work.KeyExpansion  PORT MAP (CLK, RESET, DECRYPT, LAST, SELECTED_TK1, SELECTED_TK2_1, SELECTED_TK2_2, ROUND_TK1, ROUND_TK2_1, ROUND_TK2_2);
	-------------------------------------------------------------------------------

   -- CONTROL LOGIC --------------------------------------------------------------
   CL : ENTITY work.ControlLogic  PORT MAP (CLK, RESET, DECRYPT, DONE, FIRST, LAST, ROUND_CST);
	-------------------------------------------------------------------------------

END Round;
