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
ENTITY RegisterStage is
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
			 RESET   : IN  STD_LOGIC;
          SE      : IN  STD_LOGIC;
   	    -- DATA INPUT PORTS -----------------------------
			 DRst : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          D    : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          DS   : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
   	    -- DATA OUTPUT PORTS ----------------------------
          Q    : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END RegisterStage;



-- ARCHITECTURE : STRUCTURAL
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF RegisterStage IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := 8;
	
	SIGNAL   DIN : STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN

	DIN <= DRst WHEN RESET = '1' ELSE D;
	
   C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((16 * W - 1) DOWNTO (15 * W)), DS((16 * W - 1) DOWNTO (15 * W)), Q((16 * W - 1) DOWNTO (15 * W)));
   C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((15 * W - 1) DOWNTO (14 * W)), DS((15 * W - 1) DOWNTO (14 * W)), Q((15 * W - 1) DOWNTO (14 * W)));
   C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((14 * W - 1) DOWNTO (13 * W)), DS((14 * W - 1) DOWNTO (13 * W)), Q((14 * W - 1) DOWNTO (13 * W)));
   C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((13 * W - 1) DOWNTO (12 * W)), DS((13 * W - 1) DOWNTO (12 * W)), Q((13 * W - 1) DOWNTO (12 * W)));

   C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((12 * W - 1) DOWNTO (11 * W)), DS((12 * W - 1) DOWNTO (11 * W)), Q((12 * W - 1) DOWNTO (11 * W)));
   C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((11 * W - 1) DOWNTO (10 * W)), DS((11 * W - 1) DOWNTO (10 * W)), Q((11 * W - 1) DOWNTO (10 * W)));
   C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN((10 * W - 1) DOWNTO ( 9 * W)), DS((10 * W - 1) DOWNTO ( 9 * W)), Q((10 * W - 1) DOWNTO ( 9 * W)));
   C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 9 * W - 1) DOWNTO ( 8 * W)), DS(( 9 * W - 1) DOWNTO ( 8 * W)), Q(( 9 * W - 1) DOWNTO ( 8 * W)));

   C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 8 * W - 1) DOWNTO ( 7 * W)), DS(( 8 * W - 1) DOWNTO ( 7 * W)), Q(( 8 * W - 1) DOWNTO ( 7 * W)));
   C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 7 * W - 1) DOWNTO ( 6 * W)), DS(( 7 * W - 1) DOWNTO ( 6 * W)), Q(( 7 * W - 1) DOWNTO ( 6 * W)));
   C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 6 * W - 1) DOWNTO ( 5 * W)), DS(( 6 * W - 1) DOWNTO ( 5 * W)), Q(( 6 * W - 1) DOWNTO ( 5 * W)));
   C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 5 * W - 1) DOWNTO ( 4 * W)), DS(( 5 * W - 1) DOWNTO ( 4 * W)), Q(( 5 * W - 1) DOWNTO ( 4 * W)));

   C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 4 * W - 1) DOWNTO ( 3 * W)), DS(( 4 * W - 1) DOWNTO ( 3 * W)), Q(( 4 * W - 1) DOWNTO ( 3 * W)));
   C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 3 * W - 1) DOWNTO ( 2 * W)), DS(( 3 * W - 1) DOWNTO ( 2 * W)), Q(( 3 * W - 1) DOWNTO ( 2 * W)));
   C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 2 * W - 1) DOWNTO ( 1 * W)), DS(( 2 * W - 1) DOWNTO ( 1 * W)), Q(( 2 * W - 1) DOWNTO ( 1 * W)));
   C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => W) PORT MAP (CLK, SE, DIN(( 1 * W - 1) DOWNTO ( 0 * W)), DS(( 1 * W - 1) DOWNTO ( 0 * W)), Q(( 1 * W - 1) DOWNTO ( 0 * W)));

END Structural;
