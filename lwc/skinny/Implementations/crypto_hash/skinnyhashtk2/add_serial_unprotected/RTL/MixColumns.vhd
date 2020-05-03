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
ENTITY MixColumns is
	PORT ( X : IN	STD_LOGIC_VECTOR (31 DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR (31 DOWNTO 0));
END MixColumns;


-- ARCHITECTURE : COLUMN
----------------------------------------------------------------------------------
ARCHITECTURE Column of MixColumns is

	-- CONSTANT -------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;

BEGIN

	Y(( 4 * W - 1) DOWNTO ( 3 * W)) <= X((4 * W - 1) DOWNTO (3 * W)) XOR X(( 2 * W - 1) DOWNTO ( 1 * W)) XOR X(( 1 * W - 1) DOWNTO ( 0 * W));
	Y(( 3 * W - 1) DOWNTO ( 2 * W)) <= X((4 * W - 1) DOWNTO (3 * W));
	Y(( 2 * W - 1) DOWNTO ( 1 * W)) <= X((3 * W - 1) DOWNTO (2 * W)) XOR X(( 2 * W - 1) DOWNTO ( 1 * W));
	Y(( 1 * W - 1) DOWNTO ( 0 * W)) <= X((4 * W - 1) DOWNTO (3 * W)) XOR X(( 2 * W - 1) DOWNTO ( 1 * W));

END Column;
