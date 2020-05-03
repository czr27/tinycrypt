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

entity CompFGHI2 is -- x XNOR (w NAND u)
    Port ( x : in  STD_LOGIC;
			  w : in  STD_LOGIC;
			  u : in  STD_LOGIC;
           z : out STD_LOGIC);
end CompFGHI2;

architecture Behavioral of CompFGHI2 is

begin

	z <= x XNOR (w NAND u);
	
end Behavioral;

