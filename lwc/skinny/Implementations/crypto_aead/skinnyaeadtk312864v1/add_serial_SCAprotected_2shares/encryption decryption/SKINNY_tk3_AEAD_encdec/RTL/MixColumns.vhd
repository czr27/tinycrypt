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
ENTITY MixColumns is
	PORT ( S : IN  STD_LOGIC;
	       X : IN	STD_LOGIC_VECTOR (31 DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR (31 DOWNTO 0));
END MixColumns;



-- ARCHITECTURE : EncDec
----------------------------------------------------------------------------------
ARCHITECTURE EncDec of MixColumns is

BEGIN

	Y(31 DOWNTO 24) <= X(23 DOWNTO 16) WHEN S = '1' ELSE X(31 DOWNTO 24) XOR X(15 DOWNTO 8) XOR X(7 DOWNTO 0);
	Y(23 DOWNTO 16) <= X(23 DOWNTO 16) XOR X(7 DOWNTO 0) XOR X(15 DOWNTO 8) WHEN S = '1' ELSE X(31 DOWNTO 24);
	Y(15 DOWNTO  8) <= X(23 DOWNTO 16) XOR X(7 DOWNTO 0) WHEN S = '1' ELSE X(23 DOWNTO 16) XOR X(15 DOWNTO 8);
	Y( 7 DOWNTO  0) <= X(31 DOWNTO 24) XOR X(7 DOWNTO 0) WHEN S = '1' ELSE X(31 DOWNTO 24) XOR X(15 DOWNTO 8);

END EncDec;