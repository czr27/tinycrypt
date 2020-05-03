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

entity SKINNY_tk3_AEAD is
Generic (
	nl				 : integer := 0;  -- 0: 128-bit nonce, 1: 96-bit nonce
	tl				 : integer := 0); -- 0: 128-bit tag,   1: 64-bit tag
Port (  
	clk          : in  STD_LOGIC;
	rst      	 : in  STD_LOGIC;
	a_data       : in  STD_LOGIC;
	enc          : in  STD_LOGIC;
	gen_tag      : in  std_logic;
	Input        : in  STD_LOGIC_VECTOR (127       downto 0);  -- Message or Associated Data
	N            : in  STD_LOGIC_VECTOR (127-nl*32 downto 0);
	K            : in  STD_LOGIC_VECTOR (127       downto 0);
	Block_Size	 : in  STD_LOGIC_VECTOR (  3       downto 0); -- Size of the given block as Input (in BYTES) - 1
	Output       : out STD_LOGIC_VECTOR (127       downto 0); -- Ciphertext 
	Tag			 : out STD_LOGIC_VECTOR (127-tl*64 downto 0); -- Tag
	done         : out STD_LOGIC);
end SKINNY_tk3_AEAD;

architecture dfl of SKINNY_tk3_AEAD is

	signal N_Padded				: STD_LOGIC_VECTOR(127 downto 0);

	signal full_size				: STD_LOGIC;

	signal Plaintext  			: STD_LOGIC_VECTOR(127 downto 0);
	signal Ciphertext  			: STD_LOGIC_VECTOR(127 downto 0);
	signal Key 		 				: STD_LOGIC_VECTOR(383 downto 0);
	
	signal LFSR_Output			: STD_LOGIC_VECTOR( 63 downto 0);
	signal LFSR_rst         	: STD_LOGIC;
	signal LFSR_en          	: STD_LOGIC;
		
	signal Auth_Reg_rst			: STD_LOGIC;
	signal Auth_Reg_en			: STD_LOGIC;
	signal Auth_Reg_Input		: STD_LOGIC_VECTOR(127 downto 0);
	signal Auth_Reg_Output		: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Tag_Reg_rst			: STD_LOGIC;
	signal Tag_Reg_en				: STD_LOGIC;
	signal Tag_Reg_Input			: STD_LOGIC_VECTOR(127 downto 0);
	signal Tag_Reg_Output		: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Input_FullSize		: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_NotFullSize	: STD_LOGIC_VECTOR(127 downto 0);
	signal Input_Padded			: STD_LOGIC_VECTOR(127 downto 0);
	
	signal Ciphertext_Final		: STD_LOGIC_VECTOR(127 downto 0);
	signal Domain_Separation	: STD_LOGIC_VECTOR(  7 downto 0);
	
	signal Cipher_rst				: STD_LOGIC;
	signal Cipher_done			: STD_LOGIC;
	
begin
		
	PaddingInst: entity work.Padding
	Port Map ( 
		Input,
		Block_Size,
		Input_Padded);

	LFSRInst: entity work.LFSR
	Port Map (
		clk,
		LFSR_rst,
		LFSR_en,
		LFSR_Output);

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

	CipherInst: entity work.Skinny384
	Port Map (
		clk,
		Cipher_rst,
		Cipher_done,
		Key,
		Plaintext,
		Ciphertext);

	ControlInst: entity work.Controller
	Generic Map (nl, tl)
	Port Map (
		clk,
		rst,
		a_data,
		enc,
		gen_tag,
		full_size,
		LFSR_rst,
		LFSR_en,
		Auth_Reg_rst,
		Auth_Reg_en,
		Tag_Reg_rst,
		Tag_Reg_en,
		Cipher_rst,
		Cipher_done,
		Domain_Separation,
		done);
	
	-----------------------------------------------------

	Gen_Nonce128: IF nl = 0 GENERATE -- 128-bit
		N_Padded					<= N;
	END GENERATE;	

	Gen_Nonce96: IF nl = 1 GENERATE -- 96-bit
		N_Padded					<= N & x"00000000";
	END GENERATE;	
	
	full_size					<= '1' when Block_Size  = "1111" else '0';
	
	Key							<= LFSR_Output( 7 downto  0) & LFSR_Output(15 downto  8) & LFSR_Output(23 downto 16) & LFSR_Output(31 downto 24) &
										LFSR_Output(39 downto 32) & LFSR_Output(47 downto 40) & LFSR_Output(55 downto 48) & LFSR_Output(63 downto 56) &
										x"00000000000000" & Domain_Separation & N_Padded & K;

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

