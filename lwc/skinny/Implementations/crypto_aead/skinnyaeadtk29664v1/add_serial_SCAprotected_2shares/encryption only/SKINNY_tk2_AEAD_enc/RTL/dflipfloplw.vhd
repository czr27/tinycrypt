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
ENTITY dflipfloplw IS
	PORT ( CLK  : IN  STD_LOGIC;
			 SEL	: IN  STD_LOGIC;
			 D0   : IN  STD_LOGIC;
			 D1   : IN  STD_LOGIC;
			 Q    : OUT STD_LOGIC);
END dflipfloplw;



-- ARCHITECTURE : STRUCTURAL
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF dflipfloplw IS
BEGIN

	GenFF: Process(CLK, SEL, D0, D1)
	begin
		if rising_edge(CLK) then
			if (SEL = '1') then
				Q	<= D1;
			else
				Q	<= D0;
			end if;	
		end if;
	end process;

END Structural;
