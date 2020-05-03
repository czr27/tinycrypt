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
          DONE       : OUT STD_LOGIC;
   	    -- KEY PORT -------------------------------------
          TK1        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          TK2        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          TK3_1      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          TK3_2      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          SHARE1_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE2_IN  : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE1_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
          SHARE2_OUT : OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END Skinny384;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF Skinny384 IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL ROUND_TK1  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK2  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK3_1: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK3_2: STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL ROUND_CST  : STD_LOGIC_VECTOR(  5 DOWNTO 0);
	SIGNAL LAST    	: STD_LOGIC;

BEGIN

	-- ROUND FUNCTION -------------------------------------------------------------
	RF : ENTITY work.RoundFunction PORT MAP (CLK, RESET, LAST, ROUND_CST, ROUND_TK1, ROUND_TK2, ROUND_TK3_1, ROUND_TK3_2, SHARE1_IN, SHARE2_IN, SHARE1_OUT, SHARE2_OUT);
	-------------------------------------------------------------------------------

   -- KEY EXPANSION --------------------------------------------------------------
   KE : ENTITY work.KeyExpansion  PORT MAP (CLK, RESET, LAST, TK1, TK2, TK3_1, TK3_2, ROUND_TK1, ROUND_TK2, ROUND_TK3_1, ROUND_TK3_2);
	-------------------------------------------------------------------------------

   -- CONTROL LOGIC --------------------------------------------------------------
   CL : ENTITY work.ControlLogic  PORT MAP (CLK, RESET, DONE, LAST, ROUND_CST);
	-------------------------------------------------------------------------------

END Round;
