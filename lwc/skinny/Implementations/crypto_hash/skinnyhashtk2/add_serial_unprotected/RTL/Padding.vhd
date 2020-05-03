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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Padding is
	port(
		Input	  		: in  std_logic_vector(31 downto 0);
		Block_Size	: in  std_logic_vector( 1 downto 0);
		all_pad		: in  std_logic;
		all_zero		: in  std_logic;
		Output		: out std_logic_vector(31 downto 0));
end entity Padding;


architecture dfl of Padding is

	signal size	: unsigned(1 downto 0);

	constant v0	 : unsigned(1 downto 0) := "00";
	constant v1	 : unsigned(1 downto 0) := "01";
	constant v2	 : unsigned(1 downto 0) := "10";
	constant v3	 : unsigned(1 downto 0) := "11";
	
begin

	size	<= unsigned(Block_Size) when (all_pad or all_zero) = '0' else "00";

	Output( 4*8-1 downto  3*8)	<= Input( 4*8-1 downto  3*8) when (all_pad or all_zero) = '0' else x"80" when all_zero = '0' else x"00";
	Output( 3*8-1 downto  2*8)	<= Input( 3*8-1 downto  2*8) when size > v0 else x"80" when (all_pad or all_zero) = '0' else x"00";
	Output( 2*8-1 downto  1*8)	<= Input( 2*8-1 downto  1*8) when size > v1 else x"80" when size = v1 else x"00";
	Output( 1*8-1 downto  0*8)	<= Input( 1*8-1 downto  0*8) when size > v2 else x"80" when size = v2 else x"00";

end architecture;
