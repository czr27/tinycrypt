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

entity SKINNY_tk3_Hash is
Port (  
	clk          : in  STD_LOGIC;
	rst      	 : in  STD_LOGIC;
	absorb		 : in  STD_LOGIC;
	gen      	 : in  std_logic;
	Message      : in  STD_LOGIC_VECTOR (127       downto 0); -- Message
	Block_Size	 : in  STD_LOGIC_VECTOR (  3       downto 0); -- Size of the given block as Input (in BYTES) - 1
	Hash         : out STD_LOGIC_VECTOR (255       downto 0); -- Hash 
	done         : out STD_LOGIC);
end SKINNY_tk3_Hash;

architecture dfl of SKINNY_tk3_Hash is

	signal full_size					: STD_LOGIC;
	signal all_pad						: STD_LOGIC;
	signal all_zero					: STD_LOGIC;
	signal Counter						: STD_LOGIC_VECTOR(  1 downto 0);
	
	signal Input_Padded				: STD_LOGIC_VECTOR(127 downto 0);

	signal Plaintext  				: STD_LOGIC_VECTOR(127 downto 0);
	signal Ciphertext  				: STD_LOGIC_VECTOR(127 downto 0);
	signal Key 		 					: STD_LOGIC_VECTOR(383 downto 0);
	
	signal Cipher_rst					: STD_LOGIC;
	signal Cipher_done				: STD_LOGIC;
		
	signal State_Reg_rst				: STD_LOGIC;
	signal State_Reg_en				: STD_LOGIC;
	signal State_Reg_Input			: STD_LOGIC_VECTOR(383 downto 0);
	signal State_Reg_Output			: STD_LOGIC_VECTOR(383 downto 0);
	
	signal State_Temp_Reg1_en		: STD_LOGIC;
	signal State_Temp_Reg1_Output	: STD_LOGIC_VECTOR(127 downto 0);

	signal State_Temp_Reg2_en		: STD_LOGIC;
	signal State_Temp_Reg2_Output	: STD_LOGIC_VECTOR(127 downto 0);
	
begin
		
	PaddingInst: entity work.Padding
	Port Map ( 
		Message,
		Block_Size,
		all_pad,
		all_zero,
		Input_Padded);

	StateTempReg1Inst: entity work.Reg_en
	Generic Map (128)
	Port Map (
		clk,
		State_Temp_Reg1_en,
		Ciphertext,
		State_Temp_Reg1_Output);

	StateTempReg2Inst: entity work.Reg_en
	Generic Map (128)
	Port Map (
		clk,
		State_Temp_Reg2_en,
		Ciphertext,
		State_Temp_Reg2_Output);

	StateRegInst: entity work.Reg_en_clr
	Generic Map (384, 255)
	Port Map (
		clk,
		State_Reg_rst,
		State_Reg_en,
		State_Reg_Input,
		State_Reg_Output);

	CipherInst: entity work.Skinny384_serial
	Port Map (
		clk,
		Cipher_rst,
		Cipher_done,
		Key,
		Plaintext,
		Ciphertext);

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
		State_Temp_Reg1_en,
		State_Temp_Reg2_en,
		Counter,
		Cipher_rst,
		Cipher_done,
		done);
	
	-----------------------------------------------------

	full_size								<= '1' when Block_Size  = "1111" else '0';
	
	Key(383 downto 256)					<= State_Reg_Output(383 downto 256) XOR Input_Padded;
	Key(255 downto   0)					<= State_Reg_Output(255 downto   0);

	Plaintext 								<= "000000" & Counter & x"000000000000000000000000000000";
	
	State_Reg_Input(383 downto 256)	<= State_Temp_Reg1_Output;
	State_Reg_Input(255 downto 128)	<= State_Temp_Reg2_Output;
	State_Reg_Input(127 downto   0)	<= Ciphertext;
		
	Hash(255 downto 128)					<= State_Reg_Output(383 downto 256);
	Hash(127 downto   0)					<= State_Temp_Reg1_Output;
	
end dfl;

