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
ENTITY Permutation is
	PORT ( X : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
          Y : OUT STD_LOGIC_VECTOR (127 DOWNTO 0));
END Permutation;



-- ARCHITECTURE : PARALLEL
----------------------------------------------------------------------------------
ARCHITECTURE Parallel OF Permutation IS


BEGIN

	-- ROW 1 ----------------------------------------------------------------------
	Y((16 * 8 - 1) DOWNTO (15 * 8)) <= X(( 7 * 8 - 1) DOWNTO ( 6 * 8));
	Y((15 * 8 - 1) DOWNTO (14 * 8)) <= X(( 1 * 8 - 1) DOWNTO ( 0 * 8));
	Y((14 * 8 - 1) DOWNTO (13 * 8)) <= X(( 8 * 8 - 1) DOWNTO ( 7 * 8));
	Y((13 * 8 - 1) DOWNTO (12 * 8)) <= X(( 3 * 8 - 1) DOWNTO ( 2 * 8));

	-- ROW 2 ----------------------------------------------------------------------
	Y((12 * 8 - 1) DOWNTO (11 * 8)) <= X(( 6 * 8 - 1) DOWNTO ( 5 * 8));
	Y((11 * 8 - 1) DOWNTO (10 * 8)) <= X(( 2 * 8 - 1) DOWNTO ( 1 * 8));
	Y((10 * 8 - 1) DOWNTO ( 9 * 8)) <= X(( 4 * 8 - 1) DOWNTO ( 3 * 8));
	Y(( 9 * 8 - 1) DOWNTO ( 8 * 8)) <= X(( 5 * 8 - 1) DOWNTO ( 4 * 8));

	-- ROW 3 ----------------------------------------------------------------------
	Y(( 8 * 8 - 1) DOWNTO ( 7 * 8)) <= X((16 * 8 - 1) DOWNTO (15 * 8));
	Y(( 7 * 8 - 1) DOWNTO ( 6 * 8)) <= X((15 * 8 - 1) DOWNTO (14 * 8));
	Y(( 6 * 8 - 1) DOWNTO ( 5 * 8)) <= X((14 * 8 - 1) DOWNTO (13 * 8));
	Y(( 5 * 8 - 1) DOWNTO ( 4 * 8)) <= X((13 * 8 - 1) DOWNTO (12 * 8));

	-- ROW 4 ----------------------------------------------------------------------
	Y(( 4 * 8 - 1) DOWNTO ( 3 * 8)) <= X((12 * 8 - 1) DOWNTO (11 * 8));
	Y(( 3 * 8 - 1) DOWNTO ( 2 * 8)) <= X((11 * 8 - 1) DOWNTO (10 * 8));
	Y(( 2 * 8 - 1) DOWNTO ( 1 * 8)) <= X((10 * 8 - 1) DOWNTO ( 9 * 8));
	Y(( 1 * 8 - 1) DOWNTO ( 0 * 8)) <= X(( 9 * 8 - 1) DOWNTO ( 8 * 8));

END Parallel;
