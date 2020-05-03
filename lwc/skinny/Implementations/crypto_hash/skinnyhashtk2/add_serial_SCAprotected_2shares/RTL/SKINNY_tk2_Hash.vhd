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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SKINNY_tk2_Hash is
Port (  
	clk          : in  STD_LOGIC;
	rst      	 : in  STD_LOGIC;
	absorb		 : in  STD_LOGIC;
	gen      	 : in  std_logic;
	InitialMask  : in  STD_LOGIC_VECTOR (255 downto 0); -- Random initial Mask only used with rst = '1'
	Message1     : in  STD_LOGIC_VECTOR ( 31 downto 0); -- Message (share 1)
	Message2     : in  STD_LOGIC_VECTOR ( 31 downto 0); -- Message (share 2)
	Block_Size	 : in  STD_LOGIC_VECTOR (  1 downto 0); -- Size of the given block as Input (in BYTES) - 1
	Hash1        : out STD_LOGIC_VECTOR (255 downto 0); -- Hash (share 1)
	Hash2        : out STD_LOGIC_VECTOR (255 downto 0); -- Hash (share 2)
	done         : out STD_LOGIC);
end SKINNY_tk2_Hash;

architecture dfl of SKINNY_tk2_Hash is

	signal full_size					: STD_LOGIC;
	signal all_pad						: STD_LOGIC;
	signal all_zero					: STD_LOGIC;
	signal Counter						: STD_LOGIC;
	
	signal Input_Padded1				: STD_LOGIC_VECTOR(31 downto 0);
	signal Input_Padded2				: STD_LOGIC_VECTOR(31 downto 0);

	signal Plaintext1  				: STD_LOGIC_VECTOR(127 downto 0);
	signal Plaintext2  				: STD_LOGIC_VECTOR(127 downto 0);
	signal Ciphertext1  				: STD_LOGIC_VECTOR(127 downto 0);
	signal Ciphertext2  				: STD_LOGIC_VECTOR(127 downto 0);
	signal tk1_1	 					: STD_LOGIC_VECTOR(127 downto 0);
	signal tk1_2	 					: STD_LOGIC_VECTOR(127 downto 0);
	signal tk2_1	 					: STD_LOGIC_VECTOR(127 downto 0);
	signal tk2_2	 					: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Cipher_rst					: STD_LOGIC;
	signal Cipher_done				: STD_LOGIC;
		
	signal State_Reg_rst				: STD_LOGIC;
	signal State_Reg_en				: STD_LOGIC;
	signal State_Reg_ResetValue1  : STD_LOGIC_VECTOR(255 downto 0);
	signal State_Reg_ResetValue2	: STD_LOGIC_VECTOR(255 downto 0);
	signal State_Reg_Input1			: STD_LOGIC_VECTOR(255 downto 0);
	signal State_Reg_Input2			: STD_LOGIC_VECTOR(255 downto 0);
	signal State_Reg_Output1		: STD_LOGIC_VECTOR(255 downto 0);
	signal State_Reg_Output2		: STD_LOGIC_VECTOR(255 downto 0);
	
	signal State_Temp_Reg_en		: STD_LOGIC;
	signal State_Temp_Reg_Output1 : STD_LOGIC_VECTOR(127 downto 0);
	signal State_Temp_Reg_Output2	: STD_LOGIC_VECTOR(127 downto 0);

begin
		
	PaddingInst1: entity work.Padding
	Generic Map (1)
	Port Map ( 
		Message1,
		Block_Size,
		all_pad,
		all_zero,
		Input_Padded1);
		
	PaddingInst2: entity work.Padding
	Generic Map (0)
	Port Map ( 
		Message2,
		Block_Size,
		all_pad,
		all_zero,
		Input_Padded2);		

	StateTempRegInst1: entity work.Reg_en
	Generic Map (128)
	Port Map (
		clk,
		State_Temp_Reg_en,
		Ciphertext1,
		State_Temp_Reg_Output1);

	StateTempRegInst2: entity work.Reg_en
	Generic Map (128)
	Port Map (
		clk,
		State_Temp_Reg_en,
		Ciphertext2,
		State_Temp_Reg_Output2);

	StateRegInst1: entity work.Reg_en_clr
	Generic Map (256)
	Port Map (
		clk,
		State_Reg_rst,
		State_Reg_en,
		State_Reg_ResetValue1,
		State_Reg_Input1,
		State_Reg_Output1);

	StateRegInst2: entity work.Reg_en_clr
	Generic Map (256)
	Port Map (
		clk,
		State_Reg_rst,
		State_Reg_en,
		State_Reg_ResetValue2,
		State_Reg_Input2,
		State_Reg_Output2);
		
	CipherInst: entity work.Skinny256_serial
	Port Map (
		clk,
		Cipher_rst,
		Cipher_done,
		tk1_1,
		tk1_2,
		tk2_1,
		tk2_2,
		Plaintext1,
		Plaintext2,
		Ciphertext1,
		Ciphertext2);
		
	ControlInst: entity work.Controller
	Port Map (
		clk,
		rst,
		absorb,
		gen,
		full_size,
		all_pad,
		all_zero,
		State_Reg_rst,
		State_Reg_en,
		State_Temp_Reg_en,
		Counter,
		Cipher_rst,
		Cipher_done,
		done);
	
	-----------------------------------------------------

	full_size								<= '1' when Block_Size  = "11" else '0';
	
	tk1_1										<= (State_Reg_Output1(255 downto 224) XOR Input_Padded1) & State_Reg_Output1(223 downto 128);
	tk1_2										<= (State_Reg_Output2(255 downto 224) XOR Input_Padded2) & State_Reg_Output2(223 downto 128);

	tk2_1										<= State_Reg_Output1(127 downto   0);
	tk2_2										<= State_Reg_Output2(127 downto   0);

	Plaintext1 								<= "0000000" & Counter & x"000000000000000000000000000000";
	Plaintext2 								<= (others => '0');
	
	State_Reg_ResetValue1				<= InitialMask;
	State_Reg_ResetValue2				<= InitialMask(255 downto 224) & (not InitialMask(223)) & InitialMask(222 downto 0);
	
	State_Reg_Input1(255 downto 128)	<= State_Temp_Reg_Output1;
	State_Reg_Input2(255 downto 128)	<= State_Temp_Reg_Output2;

	State_Reg_Input1(127 downto   0)	<= Ciphertext1;
	State_Reg_Input2(127 downto   0)	<= Ciphertext2;
		
	Hash1										<= State_Reg_Output1(255 downto 128) & State_Temp_Reg_Output1;
	Hash2										<= State_Reg_Output2(255 downto 128) & State_Temp_Reg_Output2;
	
end dfl;

