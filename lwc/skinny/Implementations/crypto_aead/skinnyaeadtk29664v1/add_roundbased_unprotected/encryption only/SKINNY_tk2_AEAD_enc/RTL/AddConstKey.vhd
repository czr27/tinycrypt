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
			 CONST			: IN	STD_LOGIC_VECTOR(5 DOWNTO 0);
			 -- KEY PORT -------------------------------------
			 ROUND_KEY		: IN	STD_LOGIC_VECTOR(255 DOWNTO 0);
			 -- DATA PORTS -----------------------------------
			 DATA_IN			: IN	STD_LOGIC_VECTOR(127 DOWNTO 0);
			 DATA_OUT		: OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END AddConstKey;



-- ARCHITECTURE : MIXED
----------------------------------------------------------------------------------
ARCHITECTURE Parallel OF AddConstKey IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CONST_ADDITION	: STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN

	-- CONSTANT ADDITION ----------------------------------------------------------
	CONST_ADDITION(127 DOWNTO 124) <= DATA_IN(127 DOWNTO 124);
	CONST_ADDITION(123 DOWNTO 120) <= DATA_IN(123 DOWNTO 120) XOR CONST(3 DOWNTO 0);
	CONST_ADDITION(119 DOWNTO  90) <= DATA_IN(119 DOWNTO  90);
	CONST_ADDITION( 89 DOWNTO  88) <= DATA_IN( 89 DOWNTO  88) XOR CONST(5 DOWNTO 4);
	CONST_ADDITION( 87 DOWNTO  58) <= DATA_IN( 87 DOWNTO  58);
	CONST_ADDITION( 57) 	    	    <= NOT(DATA_IN(57));
	CONST_ADDITION( 56 DOWNTO   0) <= DATA_IN( 56 DOWNTO   0);
	-------------------------------------------------------------------------------

	-- ROUNDKEY ADDITION ----------------------------------------------------------
	DATA_OUT(127 DOWNTO 96) <= CONST_ADDITION(127 DOWNTO 96) XOR ROUND_KEY(255 DOWNTO 224) XOR ROUND_KEY(127 DOWNTO 96);
	DATA_OUT( 95 DOWNTO 64) <= CONST_ADDITION( 95 DOWNTO 64) XOR ROUND_KEY(223 DOWNTO 192) XOR ROUND_KEY( 95 DOWNTO 64);
	DATA_OUT( 63 DOWNTO 32) <= CONST_ADDITION( 63 DOWNTO 32);
	DATA_OUT( 31 DOWNTO  0) <= CONST_ADDITION( 31 DOWNTO  0);
	-------------------------------------------------------------------------------

END Parallel;
