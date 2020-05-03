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

entity FGHI_Inv_Combine is
    Port ( x1 : in  STD_LOGIC_VECTOR (7 downto 0);
			  x2 : in  STD_LOGIC_VECTOR (7 downto 0);
			  x3 : in  STD_LOGIC_VECTOR (1 downto 0);
           x4 : in  STD_LOGIC_VECTOR (1 downto 0);
           y1 : out STD_LOGIC_VECTOR (7 downto 0);
			  y2 : out STD_LOGIC_VECTOR (7 downto 0);
           z1 : out STD_LOGIC_VECTOR (7 downto 0);
			  z2 : out STD_LOGIC_VECTOR (7 downto 0));
end FGHI_Inv_Combine;

architecture Behavioral of FGHI_Inv_Combine is

	signal yy1 : STD_LOGIC_VECTOR (7 downto 0);
	signal yy2 : STD_LOGIC_VECTOR (7 downto 0);
	
begin
	
	Combine1: entity work.CompFGHI_Inv_Combine
	port map(x1, x3, yy1);
	
	Combine2: entity work.CompFGHI_Inv_Combine
	port map(x2, x4, yy2);

	y1	<= yy1;
	y2	<= yy2;

	z1(2) <= yy1(0);
	z1(6) <= yy1(2);
	z1(7) <= yy1(1);
	z1(1) <= yy1(3);
	z1(3) <= yy1(4);
	z1(0) <= yy1(5);
	z1(4) <= yy1(6);
	z1(5) <= yy1(7);

	z2(2) <= yy2(0);
	z2(6) <= yy2(2);
	z2(7) <= yy2(1);
	z2(1) <= yy2(3);
	z2(3) <= yy2(4);
	z2(0) <= yy2(5);
	z2(4) <= yy2(6);
	z2(5) <= yy2(7);

end Behavioral;

