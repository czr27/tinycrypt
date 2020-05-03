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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CompFGHIp1 is -- (x NOR (NOT w))
    Port ( x : in  STD_LOGIC;
			  w : in  STD_LOGIC;
           z : out STD_LOGIC);
end CompFGHIp1;

architecture Behavioral of CompFGHIp1 is

begin

	z <= (x NOR (NOT w));
	
end Behavioral;

