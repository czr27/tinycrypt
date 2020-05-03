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
	enc			 : in  std_logic;
	Block_Size	 : in  std_logic_vector(  3 downto 0);
	full_size	 : in  std_logic;
	Auth_Reg_rst : in  std_logic;
	Auth_Reg_en  : in  std_logic;
	Tag_Reg_rst  : in  std_logic;
	Tag_Reg_en   : in  std_logic;
	Input			 : in  std_logic_vector(127 downto 0);
	Plaintext	 : out std_logic_vector(127 downto 0);
	Ciphertext	 : in  std_logic_vector(127 downto 0);
	Output		 : out std_logic_vector(127 downto 0);
	Tag			 : out STD_LOGIC_VECTOR(127-tl*64 downto 0));
end MainPart;

architecture dfl of MainPart is

	signal Auth_Reg_Input		: STD_LOGIC_VECTOR(127 downto 0);
	signal Auth_Reg_Output		: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Tag_Reg_Input			: STD_LOGIC_VECTOR(127 downto 0);
	signal Tag_Reg_Output		: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Input_Padded			: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_FullSize		: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_NotFullSize	: STD_LOGIC_VECTOR(127 downto 0);

	signal Ciphertext_Final		: STD_LOGIC_VECTOR(127 downto 0);

begin
		
	PaddingInst: entity work.Padding
	Generic Map (withConstant)
	Port Map ( 
		Input,
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
	
	Plaintext 					<= Input_Padded when a_data = '1' else Input_FullSize when enc = '1' else Tag_Reg_Output;
	
	Tag_Reg_Input				<=	Input_Padded XOR Tag_Reg_Output;
	
	Auth_Reg_Input				<= Ciphertext XOR Auth_Reg_Output;
	
	Ciphertext_Final			<= Input_NotFullSize XOR Ciphertext;
	
	Output						<= Ciphertext_Final;
	
	Gen_Tag128: IF tl = 0 GENERATE -- 128-bit
		Tag						<= Auth_Reg_Input;
	END GENERATE;	

	Gen_Tag64: IF tl = 1 GENERATE -- 64-bit
		Tag						<= Auth_Reg_Input(127 downto 64);
	END GENERATE;	
	
end dfl;

