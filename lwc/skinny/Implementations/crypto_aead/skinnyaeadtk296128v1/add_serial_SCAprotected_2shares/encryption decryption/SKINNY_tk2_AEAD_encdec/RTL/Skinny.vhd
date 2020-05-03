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
ENTITY Skinny256_serial IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
          DECRYPT    : IN  STD_LOGIC;
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
END Skinny256_serial;



-- ARCHITECTURE : Word
----------------------------------------------------------------------------------
ARCHITECTURE Word OF Skinny256_serial IS

	-- SIGNALS --------------------------------------------------------------------
   SIGNAL ROUND_CTL : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL KEY_CTL   : STD_LOGIC_VECTOR(1 DOWNTO 0);

	SIGNAL ROUND_KEY1 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ROUND_KEY2 : STD_LOGIC_VECTOR( 7 DOWNTO 0);
	SIGNAL ROUND_CST  : STD_LOGIC_VECTOR( 7 DOWNTO 0);

	SIGNAL SHARE1_FIRST_KEY : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL SHARE2_FIRST_KEY : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
   SIGNAL SHARE1_KEY : STD_LOGIC_VECTOR (255 DOWNTO 0);
   SIGNAL SHARE2_KEY : STD_LOGIC_VECTOR (127 DOWNTO 0);
	
BEGIN

	SHARE1_KEY	<= TK1 & TK2_1;
	SHARE2_KEY  <=       TK2_2;

   -- KEY SELECTION --------------------------------------------------------------
   KS1 : ENTITY work.KeySelection  PORT MAP (DECRYPT, SHARE1_KEY, SHARE1_FIRST_KEY);
   KS2 : ENTITY work.KeySelection2 PORT MAP (DECRYPT, SHARE2_KEY, SHARE2_FIRST_KEY);
   -------------------------------------------------------------------------------
   
	-- ROUND FUNCTION -------------------------------------------------------------
	RF : ENTITY work.RoundFunction PORT MAP (CLK, RESET, DECRYPT, ROUND_CTL, ROUND_CST, ROUND_KEY1, ROUND_KEY2, SHARE1_IN, SHARE2_IN, SHARE1_OUT, SHARE2_OUT);
	-------------------------------------------------------------------------------

   -- KEY EXPANSION --------------------------------------------------------------
   KE1 : ENTITY work.KeyExpansion  PORT MAP (CLK, RESET, DECRYPT, KEY_CTL, SHARE1_FIRST_KEY, ROUND_KEY1);
   KE2 : ENTITY work.KeyExpansion2 PORT MAP (CLK, RESET, DECRYPT, KEY_CTL, SHARE2_FIRST_KEY, ROUND_KEY2);
	-------------------------------------------------------------------------------

   -- CONTROL LOGIC --------------------------------------------------------------
   CL : ENTITY work.ControlLogic PORT MAP (CLK, RESET, DECRYPT, DONE, ROUND_CTL, KEY_CTL, ROUND_CST);
	-------------------------------------------------------------------------------

END Word;
