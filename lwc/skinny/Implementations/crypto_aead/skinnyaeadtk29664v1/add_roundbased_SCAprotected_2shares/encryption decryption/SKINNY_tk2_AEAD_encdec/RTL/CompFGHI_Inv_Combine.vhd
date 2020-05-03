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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CompFGHI_Inv_Combine is 
    Port ( x : in  STD_LOGIC_VECTOR(7 downto 0);
			  y : in  STD_LOGIC_VECTOR(1 downto 0);
			  z : out STD_LOGIC_VECTOR(7 downto 0));
end CompFGHI_Inv_Combine;

architecture Behavioral of CompFGHI_Inv_Combine is

begin

	z <= x(7) & (x(6) xor y(1)) & (x(5) xor y(0)) & x(4 downto 0);
	
end Behavioral;

