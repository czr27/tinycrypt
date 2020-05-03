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

entity LFSR is
	port(
		clk		: in  std_logic;
		rst		: in  std_logic;
		en	   	: in  std_logic;
		Output	: out std_logic_vector(23 downto 0));
end entity LFSR;


architecture dfl of LFSR is

	signal Update	: std_logic_vector(23 downto 0);
	signal Reg   	: std_logic_vector(23 downto 0);
	
begin

	Update <= Reg(22 downto 4) & (Reg(3) XOR Reg(23)) & (Reg(2) XOR Reg(23)) & Reg(1) & (Reg(0) XOR Reg(23)) & Reg(23);

	GenReg:	Process(clk, en)
	begin
		if (clk'event AND clk = '1') then
			if (rst = '1') then
				Reg	<= x"000001";
			elsif (en = '1') then
				Reg	<= Update;
			end if;	
		end if;
	end process;

	Output	<= Reg;
	

end architecture;
