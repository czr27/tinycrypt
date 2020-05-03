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
USE IEEE.NUMERIC_STD.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY KeySelection3 IS
   PORT ( -- CONTROL PORT ---------------------------------
          DECRYPT		: IN  STD_LOGIC;
		    -- KEY PORTS ------------------------------------
		    KEY			: IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
			 FIRST_KEY	: OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END KeySelection3;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeySelection3 IS
	
	-- SELECTION FUNCTIONS --------------------------------------------------------
	TYPE INT_ARRAY IS ARRAY (INTEGER RANGE <>) OF INTEGER;
	CONSTANT PT: INT_ARRAY(0 TO 15) := (13, 14, 11, 10, 15,  8,  9, 12,  3,  5,  7,  4,  1,  2,  0,  6);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL TK3 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
BEGIN

	GEN_TK3_1: FOR I IN 0 TO 7 GENERATE
		TK3((15-I)*8+7) <= KEY((15-I)*8+4);
		TK3((15-I)*8+6) <= KEY((15-I)*8+3);
		TK3((15-I)*8+5) <= KEY((15-I)*8+2); 
		TK3((15-I)*8+4) <= KEY((15-I)*8+1);
		TK3((15-I)*8+3) <= KEY((15-I)*8+0); 
		TK3((15-I)*8+2) <= KEY((15-I)*8+5) XOR KEY((15-I)*8+7);
		TK3((15-I)*8+1) <= KEY((15-I)*8+4) XOR KEY((15-I)*8+6);
		TK3((15-I)*8+0) <= KEY((15-I)*8+3) XOR KEY((15-I)*8+5);
	END GENERATE;

	GEN_TK3_2: FOR I IN 8 TO 15 GENERATE
		TK3((15-I)*8+7) <= KEY((15-I)*8+5);
		TK3((15-I)*8+6) <= KEY((15-I)*8+4);
		TK3((15-I)*8+5) <= KEY((15-I)*8+3);
		TK3((15-I)*8+4) <= KEY((15-I)*8+2);
		TK3((15-I)*8+3) <= KEY((15-I)*8+1);
		TK3((15-I)*8+2) <= KEY((15-I)*8+0);
		TK3((15-I)*8+1) <= KEY((15-I)*8+5) XOR KEY((15-I)*8+7);
		TK3((15-I)*8+0) <= KEY((15-I)*8+4) XOR KEY((15-I)*8+6);
	END GENERATE;
		
	GEN_TK3: FOR I IN 0 TO 15 GENERATE
		FIRST_KEY((15-I)*8+7 DOWNTO (15-I)*8) <= KEY((15-I)*8+7 DOWNTO (15-I)*8) WHEN DECRYPT = '0' ELSE
		                                         TK3((15-PT(I))*8+7 DOWNTO (15-PT(I))*8);
	END GENERATE;


	--SKINNY-128-384:
	--Order:
	--13 14 11 10 15  8  9 12  3  5  7  4  1  2  0  6
	--
	--Number of applying LFSR:
	--27 27 27 27 27 27 27 27 28 28 28 28 28 28 28 28
	--
	--TK2:
	--After applying LFSR 27 times:
	--Bit 7: 0 2 6
	--Bit 6: 1 7
	--Bit 5: 0 6
	--Bit 4: 7
	--Bit 3: 6
	--Bit 2: 5
	--Bit 1: 4
	--Bit 0: 3
	--TK2:
	--After applying LFSR 28 times:
	--Bit 7: 1 7
	--Bit 6: 0 6
	--Bit 5: 7
	--Bit 4: 6
	--Bit 3: 5
	--Bit 2: 4
	--Bit 1: 3
	--Bit 0: 2
	
	--TK3:
	--After applying LFSR 27 times:
	--Bit 7: 4
	--Bit 6: 3
	--Bit 5: 2
	--Bit 4: 1
	--Bit 3: 0
	--Bit 2: 5 7
	--Bit 1: 4 6
	--Bit 0: 3 5
	--TK3:
	--After applying LFSR 28 times:
	--Bit 7: 5
	--Bit 6: 4
	--Bit 5: 3
	--Bit 4: 2
	--Bit 3: 1
	--Bit 2: 0
	--Bit 1: 5 7
	--Bit 0: 4 6
	
END Round;
