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
ENTITY SBoxInv IS
	PORT ( -- CONTROL PORTS --------------------------------
          SE1 : IN  STD_LOGIC;
          SE2 : IN  STD_LOGIC;
			 -- INPUT EXPANSION ------------------------------
			 E1  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			 E2  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			 -- OUTPUT EXPANSION -----------------------------
			 N1  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			 N2  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
          -- INPUT SHARES ---------------------------------
          X1  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
          X2  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
          XS1 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
          XS2 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			 -- OUTPUT SHARES --------------------------------
          Y1  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
          Y2  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END SBoxInv;



-- ARCHITECTURE : WORD
----------------------------------------------------------------------------------
ARCHITECTURE Word OF SBoxInv IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL S1, S2, T1, T2, C1, C2, F1, F2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

	-- COMBINE FUNCTION -----------------------------------------------------------
	CB : ENTITY work.FGHI_Inv_Combine PORT MAP (X1, X2, E1, E2, T1, T2, F1, F2);
	-------------------------------------------------------------------------------

   -- FIRST INPUT ----------------------------------------------------------------
   S1 <= XS1 WHEN (SE1 = '1') ELSE T1;
   S2 <= XS2 WHEN (SE1 = '1') ELSE T2;
   -------------------------------------------------------------------------------
   
	-- THRESHOLD IMPLEMENTATION ---------------------------------------------------
	TI : ENTITY work.SboxFGHI_Inv_dp1 PORT MAP (S1, S2, C1, C2, N1, N2);
	-------------------------------------------------------------------------------

	-- FINAL RESULT ---------------------------------------------------------------
	Y1 <= C1 WHEN (SE2 = '0') ELSE F1;
	Y2 <= C2 WHEN (SE2 = '0') ELSE F2;
	-------------------------------------------------------------------------------

END Word;
