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
   PORT ( CLK   : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          SE    : IN  STD_LOGIC;
   	    -- DATA INPUT PORTS -----------------------------
          D     : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          DS    : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
   	    -- DATA OUTPUT PORTS ----------------------------
          Q     : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END RegisterStage;



-- ARCHITECTURE : STRUCTURAL
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF RegisterStage IS

BEGIN
	
   C15 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((16 * 8 - 1) DOWNTO (15 * 8)), DS((16 * 8 - 1) DOWNTO (15 * 8)), Q((16 * 8 - 1) DOWNTO (15 * 8)));
   C14 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((15 * 8 - 1) DOWNTO (14 * 8)), DS((15 * 8 - 1) DOWNTO (14 * 8)), Q((15 * 8 - 1) DOWNTO (14 * 8)));
   C13 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((14 * 8 - 1) DOWNTO (13 * 8)), DS((14 * 8 - 1) DOWNTO (13 * 8)), Q((14 * 8 - 1) DOWNTO (13 * 8)));
   C12 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((13 * 8 - 1) DOWNTO (12 * 8)), DS((13 * 8 - 1) DOWNTO (12 * 8)), Q((13 * 8 - 1) DOWNTO (12 * 8)));

   C11 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((12 * 8 - 1) DOWNTO (11 * 8)), DS((12 * 8 - 1) DOWNTO (11 * 8)), Q((12 * 8 - 1) DOWNTO (11 * 8)));
   C10 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((11 * 8 - 1) DOWNTO (10 * 8)), DS((11 * 8 - 1) DOWNTO (10 * 8)), Q((11 * 8 - 1) DOWNTO (10 * 8)));
   C09 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D((10 * 8 - 1) DOWNTO ( 9 * 8)), DS((10 * 8 - 1) DOWNTO ( 9 * 8)), Q((10 * 8 - 1) DOWNTO ( 9 * 8)));
   C08 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 9 * 8 - 1) DOWNTO ( 8 * 8)), DS(( 9 * 8 - 1) DOWNTO ( 8 * 8)), Q(( 9 * 8 - 1) DOWNTO ( 8 * 8)));

   C07 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 8 * 8 - 1) DOWNTO ( 7 * 8)), DS(( 8 * 8 - 1) DOWNTO ( 7 * 8)), Q(( 8 * 8 - 1) DOWNTO ( 7 * 8)));
   C06 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 7 * 8 - 1) DOWNTO ( 6 * 8)), DS(( 7 * 8 - 1) DOWNTO ( 6 * 8)), Q(( 7 * 8 - 1) DOWNTO ( 6 * 8)));
   C05 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 6 * 8 - 1) DOWNTO ( 5 * 8)), DS(( 6 * 8 - 1) DOWNTO ( 5 * 8)), Q(( 6 * 8 - 1) DOWNTO ( 5 * 8)));
   C04 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 5 * 8 - 1) DOWNTO ( 4 * 8)), DS(( 5 * 8 - 1) DOWNTO ( 4 * 8)), Q(( 5 * 8 - 1) DOWNTO ( 4 * 8)));

   C03 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 4 * 8 - 1) DOWNTO ( 3 * 8)), DS(( 4 * 8 - 1) DOWNTO ( 3 * 8)), Q(( 4 * 8 - 1) DOWNTO ( 3 * 8)));
   C02 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 3 * 8 - 1) DOWNTO ( 2 * 8)), DS(( 3 * 8 - 1) DOWNTO ( 2 * 8)), Q(( 3 * 8 - 1) DOWNTO ( 2 * 8)));
   C01 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 2 * 8 - 1) DOWNTO ( 1 * 8)), DS(( 2 * 8 - 1) DOWNTO ( 1 * 8)), Q(( 2 * 8 - 1) DOWNTO ( 1 * 8)));
   C00 : ENTITY work.ScanFF GENERIC MAP (SIZE => 8) PORT MAP (CLK, SE, D(( 1 * 8 - 1) DOWNTO ( 0 * 8)), DS(( 1 * 8 - 1) DOWNTO ( 0 * 8)), Q(( 1 * 8 - 1) DOWNTO ( 0 * 8)));

END Structural;
