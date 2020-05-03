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
ENTITY ShiftRowsInv IS
	PORT ( X : IN	STD_LOGIC_VECTOR (127 DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR (127 DOWNTO 0));
END ShiftRowsInv;



-- ARCHITECTURE : PARALLEL
----------------------------------------------------------------------------------
ARCHITECTURE Parallel OF ShiftRowsInv IS

BEGIN

	-- ROW 1 ----------------------------------------------------------------------
	Y(127 DOWNTO 96) <= X(127 DOWNTO 96);

	-- ROW 2 ----------------------------------------------------------------------
	Y( 95 DOWNTO 64) <= X(87 DOWNTO 64) & X(95 DOWNTO 88);

	-- ROW 3 ----------------------------------------------------------------------
	Y( 63 DOWNTO 32) <= X(47 DOWNTO 32) & X(63 DOWNTO 48);

	-- ROW 4 ----------------------------------------------------------------------
	Y( 31 DOWNTO  0) <= X(7 DOWNTO 0) & X(31 DOWNTO 8);

END Parallel;
