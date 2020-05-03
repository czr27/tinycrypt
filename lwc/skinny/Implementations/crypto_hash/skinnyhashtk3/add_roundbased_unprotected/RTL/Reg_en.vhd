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

entity Reg_en is
	generic (size	: integer);
	port(
		clk		: in  std_logic;
		en	   	: in  std_logic;
		Input		: in  std_logic_vector(size-1 downto 0);
		Output	: out std_logic_vector(size-1 downto 0));
end entity Reg_en;


architecture dfl of Reg_en is
begin

	GenReg:	Process(clk, en, Input)
	begin
		if (clk'event AND clk = '1') then
			if (en = '1') then
				Output	<= Input;
			end if;	
		end if;
	end process;

end architecture;
