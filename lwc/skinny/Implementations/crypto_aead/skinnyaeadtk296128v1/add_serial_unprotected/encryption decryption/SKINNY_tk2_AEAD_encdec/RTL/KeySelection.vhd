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
ENTITY KeySelection IS
   PORT ( -- CONTROL PORT ---------------------------------
          DECRYPT		: IN  STD_LOGIC;
		    -- KEY PORTS ------------------------------------
		    KEY			: IN  STD_LOGIC_VECTOR(255 DOWNTO 0);
			 FIRST_KEY	: OUT STD_LOGIC_VECTOR(255 DOWNTO 0));
END KeySelection;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF KeySelection IS
	
	-- SELECTION FUNCTIONS --------------------------------------------------------
	TYPE INT_ARRAY IS ARRAY (INTEGER RANGE <>) OF INTEGER;
	constant PT: INT_ARRAY(0 to 15) := (8,  9, 10, 11, 12, 13, 14, 15,  2,  0, 4,  7,  6,  3,  5,  1);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL TK2 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
BEGIN

	GEN_TK1: FOR I IN 0 to 15 GENERATE
		FIRST_KEY((15-I)*8+7+128 DOWNTO (15-I)*8+128) <= KEY((15-I)*8+7+128 DOWNTO (15-I)*8+128) WHEN DECRYPT = '0' ELSE
		                                                 KEY((15-PT(I))*8+7+128 DOWNTO (15-PT(I))*8+128);
	END GENERATE;
	
	GEN_TK2_1: FOR I IN 0 to 7 GENERATE
		TK2((15-I)*8+7) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+2) XOR KEY((15-I)*8+4);
		TK2((15-I)*8+6) <= KEY((15-I)*8+1) XOR KEY((15-I)*8+3) XOR KEY((15-I)*8+5) XOR KEY((15-I)*8+7);
		TK2((15-I)*8+5) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+2) XOR KEY((15-I)*8+4) XOR KEY((15-I)*8+6); 
		TK2((15-I)*8+4) <= KEY((15-I)*8+1) XOR KEY((15-I)*8+3) XOR KEY((15-I)*8+7);
		TK2((15-I)*8+3) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+2) XOR KEY((15-I)*8+6); 
		TK2((15-I)*8+2) <= KEY((15-I)*8+1) XOR KEY((15-I)*8+7);
		TK2((15-I)*8+1) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+6);
		TK2((15-I)*8+0) <= KEY((15-I)*8+7);
	END GENERATE;

	GEN_TK2_2: FOR I IN 8 to 15 GENERATE
		TK2((15-I)*8+7) <= KEY((15-I)*8+1) XOR KEY((15-I)*8+3) XOR KEY((15-I)*8+5) XOR KEY((15-I)*8+7);
		TK2((15-I)*8+6) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+2) XOR KEY((15-I)*8+4) XOR KEY((15-I)*8+6);
		TK2((15-I)*8+5) <= KEY((15-I)*8+1) XOR KEY((15-I)*8+3) XOR KEY((15-I)*8+7);
		TK2((15-I)*8+4) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+2) XOR KEY((15-I)*8+6);
		TK2((15-I)*8+3) <= KEY((15-I)*8+1) XOR KEY((15-I)*8+7);
		TK2((15-I)*8+2) <= KEY((15-I)*8+0) XOR KEY((15-I)*8+6);
		TK2((15-I)*8+1) <= KEY((15-I)*8+7);
		TK2((15-I)*8+0) <= KEY((15-I)*8+6);
	END GENERATE;
		
	GEN_TK2: FOR I IN 0 to 15 GENERATE
		FIRST_KEY((15-I)*8+7 DOWNTO (15-I)*8) <= KEY((15-I)*8+7 DOWNTO (15-I)*8) WHEN DECRYPT = '0' ELSE
		                                         TK2((15-PT(I))*8+7 DOWNTO (15-PT(I))*8);
	END GENERATE;

	--SKINNY-128-256:
	--Order:
	-- 8  9 10 11 12 13 14 15  2  0  4  7  6  3  5  1
	--
	--Number of applying LFSR:
	--23 23 23 23 23 23 23 23 24 24 24 24 24 24 24 24
	--
	--TK2:
	--After applying LFSR 23 times:
	--Bit 7: 0 2 4
	--Bit 6: 1 3 5 7
	--Bit 5: 0 2 4 6
	--Bit 4: 1 3 7
	--Bit 3: 0 2 6
	--Bit 2: 1 7
	--Bit 1: 0 6
	--Bit 0: 7
	
	--TK2:
	--After applying LFSR 24 times:
	--Bit 7: 1 3 5 7
	--Bit 6: 0 2 4 6
	--Bit 5: 1 3 7
	--Bit 4: 0 2 6
	--Bit 3: 1 7
	--Bit 2: 0 6
	--Bit 1: 7
	--Bit 0: 6
	
END Round;
