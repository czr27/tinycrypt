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
ENTITY Skinny256 IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
          DONE       : OUT STD_LOGIC;
   	    -- KEY PORT -------------------------------------
          TK1_1      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          TK1_2      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
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
	SIGNAL ROUND_TK1_1: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK1_2: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK2_1: STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL ROUND_TK2_2: STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL ROUND_CST : STD_LOGIC_VECTOR(  5 DOWNTO 0);
	SIGNAL LAST      : STD_LOGIC;

BEGIN

	-- ROUND FUNCTION -------------------------------------------------------------
	RF : ENTITY work.RoundFunction PORT MAP (CLK, RESET, LAST, ROUND_CST, ROUND_TK1_1, ROUND_TK1_2, ROUND_TK2_1, ROUND_TK2_2, SHARE1_IN, SHARE2_IN, SHARE1_OUT, SHARE2_OUT);
	-------------------------------------------------------------------------------

   -- KEY EXPANSION --------------------------------------------------------------
   KE : ENTITY work.KeyExpansion  PORT MAP (CLK, RESET, LAST, TK1_1, TK1_2, TK2_1, TK2_2, ROUND_TK1_1, ROUND_TK1_2, ROUND_TK2_1, ROUND_TK2_2);
	-------------------------------------------------------------------------------

   -- CONTROL LOGIC --------------------------------------------------------------
   CL : ENTITY work.ControlLogic  PORT MAP (CLK, RESET, DONE, LAST, ROUND_CST);
	-------------------------------------------------------------------------------

END Round;
