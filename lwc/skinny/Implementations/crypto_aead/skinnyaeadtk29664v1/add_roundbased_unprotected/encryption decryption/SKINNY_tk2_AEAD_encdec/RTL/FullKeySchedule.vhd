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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FullKeySchedule is
	port(
		Input	  		: in  std_logic_vector(255 downto 0);
		Output		: out std_logic_vector(255 downto 0));
end entity FullKeySchedule;

architecture dfl of FullKeySchedule is

	type INT_ARRAY is array (integer range <>) of integer;
	constant PT: INT_ARRAY(0 to 15) := (8,  9, 10, 11, 12, 13, 14, 15,  2,  0, 4,  7,  6,  3,  5,  1);

	signal TK2 : std_logic_vector(127 downto 0);

begin

	Gen_TK1: for i in 0 to 15 generate
		Output((15-i)*8+7+128 downto (15-i)*8+128) <= input((15-PT(i))*8+7+128 downto (15-PT(i))*8+128);
	end generate;
	
	Gen_TK2_1: for i in 0 to 7 generate
		TK2((15-i)*8+7)	<= input((15-i)*8+0) XOR input((15-i)*8+2) XOR input((15-i)*8+4);
		TK2((15-i)*8+6)	<= input((15-i)*8+1) XOR input((15-i)*8+3) XOR input((15-i)*8+5) XOR input((15-i)*8+7);
		TK2((15-i)*8+5)	<= input((15-i)*8+0) XOR input((15-i)*8+2) XOR input((15-i)*8+4) XOR input((15-i)*8+6); 
		TK2((15-i)*8+4)	<= input((15-i)*8+1) XOR input((15-i)*8+3) XOR input((15-i)*8+7);
		TK2((15-i)*8+3)	<= input((15-i)*8+0) XOR input((15-i)*8+2) XOR input((15-i)*8+6); 
		TK2((15-i)*8+2)	<= input((15-i)*8+1) XOR input((15-i)*8+7);
		TK2((15-i)*8+1)	<= input((15-i)*8+0) XOR input((15-i)*8+6);
		TK2((15-i)*8+0)	<= input((15-i)*8+7);
	end generate;

	Gen_TK2_2: for i in 8 to 15 generate
		TK2((15-i)*8+7)	<= input((15-i)*8+1) XOR input((15-i)*8+3) XOR input((15-i)*8+5) XOR input((15-i)*8+7);
		TK2((15-i)*8+6)	<= input((15-i)*8+0) XOR input((15-i)*8+2) XOR input((15-i)*8+4) XOR input((15-i)*8+6);
		TK2((15-i)*8+5)	<= input((15-i)*8+1) XOR input((15-i)*8+3) XOR input((15-i)*8+7);
		TK2((15-i)*8+4)	<= input((15-i)*8+0) XOR input((15-i)*8+2) XOR input((15-i)*8+6);
		TK2((15-i)*8+3)	<= input((15-i)*8+1) XOR input((15-i)*8+7);
		TK2((15-i)*8+2)	<= input((15-i)*8+0) XOR input((15-i)*8+6);
		TK2((15-i)*8+1)	<= input((15-i)*8+7);
		TK2((15-i)*8+0)	<= input((15-i)*8+6);
	end generate;
		
	Gen_TK2: for i in 0 to 15 generate
		Output((15-i)*8+7 downto (15-i)*8) <= TK2((15-PT(i))*8+7 downto (15-PT(i))*8);
	end generate;

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

end architecture;
