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

entity FullKeySchedule3 is
	port(
		Input	  		: in  std_logic_vector(127 downto 0);
		Output		: out std_logic_vector(127 downto 0));
end entity FullKeySchedule3;

architecture dfl of FullKeySchedule3 is

	type INT_ARRAY is array (integer range <>) of integer;
	constant PT: INT_ARRAY(0 to 15) := (13, 14, 11, 10, 15,  8,  9, 12,  3,  5,  7,  4,  1,  2,  0,  6);

	signal TK3 : std_logic_vector(127 downto 0);

begin

	Gen_TK3_1: for i in 0 to 7 generate
		TK3((15-i)*8+7)	<= input((15-i)*8+4);
		TK3((15-i)*8+6)	<= input((15-i)*8+3);
		TK3((15-i)*8+5)	<= input((15-i)*8+2); 
		TK3((15-i)*8+4)	<= input((15-i)*8+1);
		TK3((15-i)*8+3)	<= input((15-i)*8+0); 
		TK3((15-i)*8+2)	<= input((15-i)*8+5) XOR input((15-i)*8+7);
		TK3((15-i)*8+1)	<= input((15-i)*8+4) XOR input((15-i)*8+6);
		TK3((15-i)*8+0)	<= input((15-i)*8+3) XOR input((15-i)*8+5);
	end generate;

	Gen_TK3_2: for i in 8 to 15 generate
		TK3((15-i)*8+7)	<= input((15-i)*8+5);
		TK3((15-i)*8+6)	<= input((15-i)*8+4);
		TK3((15-i)*8+5)	<= input((15-i)*8+3);
		TK3((15-i)*8+4)	<= input((15-i)*8+2);
		TK3((15-i)*8+3)	<= input((15-i)*8+1);
		TK3((15-i)*8+2)	<= input((15-i)*8+0);
		TK3((15-i)*8+1)	<= input((15-i)*8+5) XOR input((15-i)*8+7);
		TK3((15-i)*8+0)	<= input((15-i)*8+4) XOR input((15-i)*8+6);
	end generate;
		
	Gen_TK3: for i in 0 to 15 generate
		Output((15-i)*8+7 downto (15-i)*8) <= TK3((15-PT(i))*8+7 downto (15-PT(i))*8);
	end generate;


	--SKINNY-128-384:
	--Order:
	--13 14 11 10 15  8  9 12  3  5  7  4  1  2  0  6
	--
	--Number of applying LFSR:
	--27 27 27 27 27 27 27 27 28 28 28 28 28 28 28 28
	
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

end architecture;
