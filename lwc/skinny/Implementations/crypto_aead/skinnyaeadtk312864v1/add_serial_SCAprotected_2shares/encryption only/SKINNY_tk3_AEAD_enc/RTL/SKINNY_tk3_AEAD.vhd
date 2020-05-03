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
	Input1       : in  STD_LOGIC_VECTOR (127       downto 0); -- Message or Associated Data (share 1)
	Input2       : in  STD_LOGIC_VECTOR (127       downto 0); -- Message or Associated Data (share 2)
	N            : in  STD_LOGIC_VECTOR (127-nl*32 downto 0);
	K1           : in  STD_LOGIC_VECTOR (127       downto 0); -- Key (share 1)
	K2				 : in  STD_LOGIC_VECTOR (127       downto 0); -- Key (share 2)
	Block_Size	 : in  STD_LOGIC_VECTOR (  3       downto 0); -- Size of the given block as Input (in BYTES) - 1
	Output1      : out STD_LOGIC_VECTOR (127       downto 0); -- Ciphertext (share 1)
	Output2      : out STD_LOGIC_VECTOR (127       downto 0); -- Ciphertext (share 2) 
	Tag1			 : out STD_LOGIC_VECTOR (127-tl*64 downto 0); -- Tag (share 1)
	Tag2			 : out STD_LOGIC_VECTOR (127-tl*64 downto 0); -- Tag (share 2)
	done         : out STD_LOGIC);
end SKINNY_tk3_AEAD;

architecture dfl of SKINNY_tk3_AEAD is

	signal N_Padded				: STD_LOGIC_VECTOR(127 downto 0);

	signal full_size				: STD_LOGIC;

	signal Plaintext1  			: STD_LOGIC_VECTOR(127 downto 0);
	signal Plaintext2  			: STD_LOGIC_VECTOR(127 downto 0);
	signal Ciphertext1  			: STD_LOGIC_VECTOR(127 downto 0);
	signal Ciphertext2  			: STD_LOGIC_VECTOR(127 downto 0);
	signal tk1 		 				: STD_LOGIC_VECTOR(127 downto 0);
	signal tk2 		 				: STD_LOGIC_VECTOR(127 downto 0);
	signal tk3_1	 				: STD_LOGIC_VECTOR(127 downto 0);
	signal tk3_2	 				: STD_LOGIC_VECTOR(127 downto 0);
	
	signal LFSR_Output			: STD_LOGIC_VECTOR( 63 downto 0);
	signal LFSR_rst         	: STD_LOGIC;
	signal LFSR_en          	: STD_LOGIC;
		
	signal Auth_Reg_rst			: STD_LOGIC;
	signal Auth_Reg_en			: STD_LOGIC;
	
	signal Tag_Reg_rst			: STD_LOGIC;
	signal Tag_Reg_en				: STD_LOGIC;
	
	signal Domain_Separation	: STD_LOGIC_VECTOR(  7 downto 0);
	
	signal Cipher_rst				: STD_LOGIC;
	signal Cipher_done			: STD_LOGIC;
	
begin
		
	LFSRInst: entity work.LFSR
	Port Map (
		clk,
		LFSR_rst,
		LFSR_en,
		LFSR_Output);

	CipherInst: entity work.Skinny384_serial
	Port Map (
		clk,
		Cipher_rst,
		Cipher_done,
		tk1,
		tk2,
		tk3_1,
		tk3_2,
		Plaintext1,
		Plaintext2,
		Ciphertext1,
		Ciphertext2);

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
	
	tk1							<= LFSR_Output( 7 downto  0) & LFSR_Output(15 downto  8) & LFSR_Output(23 downto 16) & LFSR_Output(31 downto 24) &
										LFSR_Output(39 downto 32) & LFSR_Output(47 downto 40) & LFSR_Output(55 downto 48) & LFSR_Output(63 downto 56) &
										x"00000000000000" & Domain_Separation;

	tk2							<= N_Padded;
	tk3_1							<= K1;
	tk3_2							<= K2;

	-----------------------------------------------------

	MainPart1: entity work.MainPart
	Generic Map (tl, 1)
	Port Map (
		clk,
		a_data,
		enc,
		Block_Size,
		full_size,
		Auth_Reg_rst,
		Auth_Reg_en,
		Tag_Reg_rst,
		Tag_Reg_en,
		Input1,
		Plaintext1,
		Ciphertext1,
		Output1,
		Tag1);

	MainPart2: entity work.MainPart
	Generic Map (tl, 0)
	Port Map (
		clk,
		a_data,
		enc,
		Block_Size,
		full_size,
		Auth_Reg_rst,
		Auth_Reg_en,
		Tag_Reg_rst,
		Tag_Reg_en,
		Input2,
		Plaintext2,
		Ciphertext2,
		Output2,
		Tag2);
		
end dfl;

