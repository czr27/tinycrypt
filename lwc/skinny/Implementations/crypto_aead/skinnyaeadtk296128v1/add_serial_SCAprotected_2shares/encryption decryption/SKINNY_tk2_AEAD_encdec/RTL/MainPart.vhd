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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MainPart is
Generic (
	tl				 : integer := 0; -- 0: 128-bit tag,   1: 64-bit tag
	withConstant : integer);
Port (  
	clk          : in  std_logic;
	a_data		 : in  std_logic;
	dec			 : in  std_logic;
	gen_tag		 : in  std_logic;
	Block_Size	 : in  std_logic_vector(  3 downto 0);
	full_size	 : in  std_logic;
	Auth_Reg_rst : in  std_logic;
	Auth_Reg_en  : in  std_logic;
	Tag_Reg_rst  : in  std_logic;
	Tag_Reg_en   : in  std_logic;
	Input			 : in  std_logic_vector(127 downto 0);
	Cipher_Input : out std_logic_vector(127 downto 0);
	Cipher_Output: in  std_logic_vector(127 downto 0);
	Output		 : out std_logic_vector(127 downto 0);
	Tag			 : out STD_LOGIC_VECTOR (127-tl*64 downto 0));
end MainPart;

architecture dfl of MainPart is

	signal Auth_Reg_Input		: STD_LOGIC_VECTOR(127 downto 0);
	signal Auth_Reg_Output		: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Tag_Reg_Input			: STD_LOGIC_VECTOR(127 downto 0);
	signal Tag_Reg_Output		: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Input_for_Padding	: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_Padded			: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_FullSize		: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_NotFullSize	: STD_LOGIC_VECTOR(127 downto 0);

	signal Cipher_Output_Final	: STD_LOGIC_VECTOR(127 downto 0);

begin
		
	PaddingInst: entity work.Padding
	Generic Map (withConstant)
	Port Map ( 
		Input_for_Padding,
		Block_Size,
		Input_Padded);

	AuthRegInst: entity work.Reg_en_clr
	Generic Map (128)
	Port Map (
		clk,
		Auth_Reg_rst,
		Auth_Reg_en,
		Auth_Reg_Input,
		Auth_Reg_Output);

	TagRegInst: entity work.Reg_en_clr
	Generic Map (128)
	Port Map (
		clk,
		Tag_Reg_rst,
		Tag_Reg_en,
		Tag_Reg_Input,
		Tag_Reg_Output);

	Input_FullSize				<= Input when full_size = '1' else (others => '0');
	Input_NotFullSize			<= Input when full_size = '0' else (others => '0');
	
	Input_for_Padding			<= Cipher_Output_Final when dec = '1' else Input;
	
	Cipher_Input				<= Input_Padded when a_data = '1' else Tag_Reg_Output when gen_tag = '1' else Input_FullSize;
	
	Tag_Reg_Input				<=	Input_Padded XOR Tag_Reg_Output;
	
	Auth_Reg_Input				<= Cipher_Output XOR Auth_Reg_Output;
	
	Cipher_Output_Final		<= Input_NotFullSize XOR Cipher_Output;
	
	Output						<= Cipher_Output_Final;
	
	Gen_Tag128: IF tl = 0 GENERATE -- 128-bit
		Tag						<= Auth_Reg_Input;
	END GENERATE;	

	Gen_Tag64: IF tl = 1 GENERATE -- 64-bit
		Tag						<= Auth_Reg_Input(127 downto 64);
	END GENERATE;	
	
end dfl;

