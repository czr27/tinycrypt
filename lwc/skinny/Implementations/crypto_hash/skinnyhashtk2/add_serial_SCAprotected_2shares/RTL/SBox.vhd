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
ENTITY SBox IS
	PORT ( -- CONTROL PORTS --------------------------------
          SE  : IN  STD_LOGIC;
			 -- INPUT EXPANSION ------------------------------
			 E1  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			 E2  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			 -- OUTPUT EXPANSION -----------------------------
			 N1  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			 N2  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
          -- INPUT SHARES ---------------------------------
          X1  : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
          X2  : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
			 -- OUTPUT SHARES --------------------------------
          Y1  : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
          Y2  : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
END SBox;



-- ARCHITECTURE : WORD
----------------------------------------------------------------------------------
ARCHITECTURE Word OF SBox IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL C1, C2, F1, F2 : STD_LOGIC_VECTOR((W - 1) DOWNTO 0);

BEGIN

	-- COMBINE FUNCTIONS ----------------------------------------------------------
	CB1 : ENTITY work.CombineFG PORT MAP (X1, E1, C1);
	CB2 : ENTITY work.CombineFG PORT MAP (X2, E2, C2);
	-------------------------------------------------------------------------------

	-- COMPONENT FUNCTIONS --------------------------------------------------------
	CF1 : ENTITY work.ComponentFG PORT MAP (C1, C2, F1, F2);
	-------------------------------------------------------------------------------

	-- EXPANSION FUNCTIONS --------------------------------------------------------
	E10 : ENTITY work.SmallFG3 PORT MAP (C1(2), C2(3), N1(0));
	E11 : ENTITY work.SmallFG3 PORT MAP (C1(6), C2(7), N1(1));
	E20 : ENTITY work.SmallFG3 PORT MAP (C1(3), C2(2), N2(0));
	E21 : ENTITY work.SmallFG3 PORT MAP (C1(7), C2(6), N2(1));
	-------------------------------------------------------------------------------

	-- FINAL RESULT ---------------------------------------------------------------
	Y1(0) <= C1(2) WHEN (SE = '1') ELSE F1(5);
	Y1(1) <= C1(7) WHEN (SE = '1') ELSE F1(3);
	Y1(2) <= C1(6) WHEN (SE = '1') ELSE F1(0);
	Y1(3) <= C1(1) WHEN (SE = '1') ELSE F1(4);
	Y1(4) <= C1(3) WHEN (SE = '1') ELSE F1(6);
	Y1(5) <= C1(0) WHEN (SE = '1') ELSE F1(7);
	Y1(6) <= C1(4) WHEN (SE = '1') ELSE F1(1);
	Y1(7) <= C1(5) WHEN (SE = '1') ELSE F1(2);

	Y2(0) <= C2(2) WHEN (SE = '1') ELSE F2(5);
	Y2(1) <= C2(7) WHEN (SE = '1') ELSE F2(3);
	Y2(2) <= C2(6) WHEN (SE = '1') ELSE F2(0);
	Y2(3) <= C2(1) WHEN (SE = '1') ELSE F2(4);
	Y2(4) <= C2(3) WHEN (SE = '1') ELSE F2(6);
	Y2(5) <= C2(0) WHEN (SE = '1') ELSE F2(7);
	Y2(6) <= C2(4) WHEN (SE = '1') ELSE F2(1);
	Y2(7) <= C2(5) WHEN (SE = '1') ELSE F2(2);
	-------------------------------------------------------------------------------

END Word;
