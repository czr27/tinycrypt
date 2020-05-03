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
ENTITY CompFGHI2 IS
    PORT ( X : IN  STD_LOGIC;
			  W : IN  STD_LOGIC;
			  U : IN  STD_LOGIC;
           Z : OUT STD_LOGIC);
END CompFGHI2;



-- ARCHITECTURE : BEHAVIORAL
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF CompFGHI2 IS

BEGIN

	Z <= X XNOR (W NAND U);
	
END Behavioral;