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
ENTITY SmallFG3 IS
	PORT ( -- INPUT SHARES ---------------------------------
          A, B : IN  STD_LOGIC;
			 -- OUTPUT SHARES --------------------------------
          Y 	: OUT STD_LOGIC);
END SmallFG3;



-- ARCHITECTURE : Bit
----------------------------------------------------------------------------------
ARCHITECTURE Bit OF SmallFG3 IS

BEGIN

	Y <= (A NOR (NOT B));

END Bit;
