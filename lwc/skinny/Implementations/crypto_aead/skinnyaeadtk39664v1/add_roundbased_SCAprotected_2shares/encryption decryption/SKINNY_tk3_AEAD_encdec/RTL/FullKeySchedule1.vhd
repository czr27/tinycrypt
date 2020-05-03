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

entity FullKeySchedule1 is
	port(
		Input	  		: in  std_logic_vector(127 downto 0);
		Output		: out std_logic_vector(127 downto 0));
end entity FullKeySchedule1;

architecture dfl of FullKeySchedule1 is

	type INT_ARRAY is array (integer range <>) of integer;
	constant PT: INT_ARRAY(0 to 15) := (13, 14, 11, 10, 15,  8,  9, 12,  3,  5,  7,  4,  1,  2,  0,  6);

begin

	Gen_TK1: for i in 0 to 15 generate
		Output((15-i)*8+7 downto (15-i)*8) <= input((15-PT(i))*8+7 downto (15-PT(i))*8);
	end generate;

	--SKINNY-128-384:
	--Order:
	--13 14 11 10 15  8  9 12  3  5  7  4  1  2  0  6

end architecture;
