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
ENTITY AddConstKey IS
	PORT ( -- CONST PORT -----------------------------------
			 ROUND_CST		: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			 -- KEY PORT -------------------------------------
			 ROUND_KEY1		: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			 ROUND_KEY2		: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			 -- DATA PORTS -----------------------------------
			 DATA_IN			: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			 DATA_OUT		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END AddConstKey;



-- ARCHITECTURE : WORD
----------------------------------------------------------------------------------
ARCHITECTURE Word OF AddConstKey IS
BEGIN

	DATA_OUT <= DATA_IN XOR ROUND_CST XOR ROUND_KEY1 XOR ROUND_KEY2;

	-------------------------------------------------------------------------------

END Word;
