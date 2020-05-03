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
ENTITY AddConstKey IS
	PORT ( -- CONST PORT -----------------------------------
			 ROUND_CST		: IN	STD_LOGIC_VECTOR( 7 DOWNTO 0);
			 -- KEY PORT -------------------------------------
			 ROUND_KEY		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			 -- DATA PORTS -----------------------------------
			 DATA_IN			: IN	STD_LOGIC_VECTOR( 7 DOWNTO 0);
			 DATA_OUT		: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0));
END AddConstKey;



-- ARCHITECTURE : WORD
----------------------------------------------------------------------------------
ARCHITECTURE Word OF AddConstKey IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CONST_ADDITION	: STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

	-- CONSTANT ADDITION ----------------------------------------------------------
	CONST_ADDITION <= DATA_IN XOR ROUND_CST;
	-------------------------------------------------------------------------------

	-- ROUNDKEY ADDITION ----------------------------------------------------------
	DATA_OUT <= CONST_ADDITION XOR ROUND_KEY(7 DOWNTO 0) XOR ROUND_KEY(15 DOWNTO 8);
	-------------------------------------------------------------------------------

END Word;