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
ENTITY ComponentFG IS
	PORT ( -- INPUT SHARES ---------------------------------
          X1 : IN	 STD_LOGIC_VECTOR (7 DOWNTO 0);
          X2 : IN	 STD_LOGIC_VECTOR (7 DOWNTO 0);
			 -- OUTPUT SHARES --------------------------------
          Y1 : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
          Y2 : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
END ComponentFG;



-- ARCHITECTURE : WORD
----------------------------------------------------------------------------------
ARCHITECTURE Word OF ComponentFG IS
BEGIN

	Y10 : ENTITY work.SmallFG1 PORT MAP (X1(0), X1(2), X1(3), Y1(0));
	Y1(1) <= X1(1);
	Y1(2) <= X1(2);
	Y1(3) <= X1(3);
	Y14 : ENTITY work.SmallFG1 PORT MAP (X1(4), X1(6), X1(7), Y1(4));
	Y1(5) <= X1(5);
	Y1(6) <= X1(6);
	Y1(7) <= X1(7);

	Y20 : ENTITY work.SmallFG2 PORT MAP (X2(0), X2(2), X2(3), Y2(0));
	Y2(1) <= X2(1);
	Y2(2) <= X2(2);
	Y2(3) <= X2(3);
	Y24 : ENTITY work.SmallFG2 PORT MAP (X2(4), X2(6), X2(7), Y2(4));
	Y2(5) <= X2(5);
	Y2(6) <= X2(6);
	Y2(7) <= X2(7);

END Word;
