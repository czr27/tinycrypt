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
ENTITY Expansion is
	GENERIC (SIZE : INTEGER);
   PORT ( CLK : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RST : IN  STD_LOGIC;
          CLR : IN  STD_LOGIC;
          SEL : IN  STD_LOGIC;
   	    -- DATA INPUT PORTS -----------------------------
          D   : IN  STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0);
          DS  : IN  STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0);
   	    -- DATA OUTPUT PORTS ----------------------------
          Q   : OUT STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0));
END Expansion;



-- ARCHITECTURE : STRUCTURAL
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF Expansion IS

	SIGNAL STATE : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL RESET : STD_LOGIC;
	SIGNAL DIN   : STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0);

BEGIN

   -- DATA MULTIPLEXER -----------------------------------------------------------
   DIN <= D WHEN SEL = '0' ELSE DS;
   
	-- CONTROL SIGNAL FOR SCAN FLIP-FLOPS -----------------------------------------
	RESET <= RST OR CLR;

	-- SCAN FLIP-FLOPS ------------------------------------------------------------
   SFF : ENTITY work.ScanFF GENERIC MAP (SIZE => SIZE) PORT MAP (CLK, RESET, DIN, (OTHERS => '0'), STATE((1 * SIZE - 1) DOWNTO (0 * SIZE)));

	GEN : FOR I IN 1 TO ((32 / SIZE) - 1) GENERATE
	   DFF : ENTITY work.ScanFF GENERIC MAP (SIZE => SIZE) PORT MAP (CLK, RST, STATE((I * SIZE - 1) DOWNTO ((I - 1) * SIZE)), (OTHERS => '0'), STATE(((I + 1) * SIZE - 1) DOWNTO (I * SIZE)));
	END GENERATE;

	Q <= STATE(31 DOWNTO (32 - SIZE));

END Structural;
