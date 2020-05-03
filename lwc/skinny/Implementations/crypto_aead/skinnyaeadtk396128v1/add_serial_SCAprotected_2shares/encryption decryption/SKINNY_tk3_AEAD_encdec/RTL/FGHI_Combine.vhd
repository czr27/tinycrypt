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
ENTITY FGHI_Combine IS
	PORT ( X1 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			 X2 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			 X3 : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
          X4 : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
          Y1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			 Y2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
          Z1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			 Z2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END FGHI_Combine;



-- ARCHITECTURE : BEHAVIORAL
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF FGHI_Combine IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL YY1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL YY2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
BEGIN
	
	-- COMBINE FUNCTIONS ----------------------------------------------------------
	CB1: ENTITY work.CompFGHICombine PORT MAP (X1, X3, YY1); -- (x1(7 DOWNTO 4) & (x1(3) xor x3(1))  & (x1(2) xor x3(0)))  & x1(1 DOWNTO 0)
	CB2: ENTITY work.CompFGHICombine PORT MAP (X2, X4, YY2); -- (x2(7 DOWNTO 4) & (x2(3) xor x4(1))  & (x2(2) xor x4(0)))  & x2(1 DOWNTO 0)

	-- OUTPUT Y -------------------------------------------------------------------
	Y1	<= YY1;
	Y2	<= YY2;

	-- OUTPUT Z -------------------------------------------------------------------
	Z1(0) <= YY1(2);
	Z1(2) <= YY1(6);
	Z1(1) <= YY1(7);
	Z1(3) <= YY1(1);
	Z1(4) <= YY1(3);
	Z1(5) <= YY1(0);
	Z1(6) <= YY1(4);
	Z1(7) <= YY1(5);

	Z2(0) <= YY2(2);
	Z2(2) <= YY2(6);
	Z2(1) <= YY2(7);
	Z2(3) <= YY2(1);
	Z2(4) <= YY2(3);
	Z2(5) <= YY2(0);
	Z2(6) <= YY2(4);
	Z2(7) <= YY2(5);

END Behavioral;

