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
ENTITY CompFGHICombine IS
    PORT ( X : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			  Y : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			  Z : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END CompFGHICombine;



-- ARCHITECTURE : BEHAVIORAL
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF CompFGHICombine IS

BEGIN

	Z <= (X(7 DOWNTO 4) & (X(3) XOR Y(1))  & (X(2) XOR Y(0)))  & X(1 DOWNTO 0);
	
END Behavioral;

