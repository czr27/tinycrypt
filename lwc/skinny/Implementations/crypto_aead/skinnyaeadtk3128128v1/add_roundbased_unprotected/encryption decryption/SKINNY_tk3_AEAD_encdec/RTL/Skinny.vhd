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
ENTITY Skinny384 IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
		    DECRYPT		: IN	STD_LOGIC;
          DONE       : OUT STD_LOGIC;
   	    -- KEY PORT -------------------------------------
          KEY        : IN  STD_LOGIC_VECTOR (383 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          DATA_IN    : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          DATA_OUT   : OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END Skinny384;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF Skinny384 IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL ROUND_KEY : STD_LOGIC_VECTOR(383 DOWNTO 0);
	SIGNAL ROUND_CST : STD_LOGIC_VECTOR(  5  DOWNTO 0);

	SIGNAL KEY_DEC   		: STD_LOGIC_VECTOR (383 DOWNTO 0);
	SIGNAL SELECTED_KEY	: STD_LOGIC_VECTOR (383 DOWNTO 0);
BEGIN

	FullKeyScheuleInst: entity work. FullKeySchedule
	Port Map (KEY, KEY_DEC);

	SELECTED_KEY	<= KEY WHEN DECRYPT = '0' ELSE KEY_DEC;

	-- ROUND FUNCTION -------------------------------------------------------------
	RF : ENTITY work.RoundFunction PORT MAP (CLK, RESET, DECRYPT, ROUND_CST, ROUND_KEY, DATA_IN, DATA_OUT);
	-------------------------------------------------------------------------------

   -- KEY EXPANSION --------------------------------------------------------------
   KE : ENTITY work.KeyExpansion  PORT MAP (CLK, RESET, DECRYPT, SELECTED_KEY, ROUND_KEY);
	-------------------------------------------------------------------------------

   -- CONTROL LOGIC --------------------------------------------------------------
   CL : ENTITY work.ControlLogic  PORT MAP (CLK, RESET, DECRYPT, DONE, ROUND_CST);
	-------------------------------------------------------------------------------

END Round;
