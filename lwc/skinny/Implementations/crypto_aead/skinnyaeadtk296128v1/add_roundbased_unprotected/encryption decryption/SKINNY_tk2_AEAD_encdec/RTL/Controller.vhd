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

entity Controller is
	Generic (
		nl				 			: integer := 0;  -- 0: 128-bit nonce, 1: 96-bit nonce
		tl				 			: integer := 0); -- 0: 128-bit tag,   1: 64-bit tag
	Port(
		clk						: in  std_logic;
		rst						: in  std_logic;
		a_data					: in  std_logic;
		enc						: in  std_logic;
		dec						: in  std_logic;
		gen_tag					: in  std_logic;
		full_size				: in  std_logic;
		LFSR_rst					: out std_logic;
		LFSR_en					: out std_logic;
		Auth_rst					: out std_logic;
		Auth_en					: out std_logic;
		Tag_rst					: out std_logic;
		Tag_en					: out std_logic;
		Cipher_rst				: out std_logic;
		Cipher_dec				: out std_logic;
		Cipher_done				: in  std_logic;
		Domain_Separation		: out std_logic_vector(7 downto 0);
		done						: out std_logic);
end entity Controller;


architecture dfl of Controller is

	constant d0       			: STD_LOGIC_VECTOR(2 downto 0) := "000";
	constant d1       			: STD_LOGIC_VECTOR(2 downto 0) := "001";
	constant d2       			: STD_LOGIC_VECTOR(2 downto 0) := "010";
	constant d3      				: STD_LOGIC_VECTOR(2 downto 0) := "011";
	constant d4       			: STD_LOGIC_VECTOR(2 downto 0) := "100";
	constant d5       			: STD_LOGIC_VECTOR(2 downto 0) := "101";

	signal d							: STD_LOGIC_VECTOR(2 downto 0);

	signal encdec_started			: STD_LOGIC;
	signal encdec_started_update	: STD_LOGIC;

	type FSM_STATES is  (S_IDLE, S_Start_Cipher, S_Wait_for_Cipher_done, S_Wait_for_Idle);

  	signal fsm_state    : FSM_STATES := S_IDLE;
  	signal next_state   : FSM_STATES;

begin

	Auth_rst				<= rst;
	Tag_rst				<= rst;
	
	Domain_Separation	<=	"000" & std_logic_vector(to_unsigned(nl,1)) & std_logic_vector(to_unsigned(tl,1)) & d;
	
	Cipher_dec			<= dec and full_size;
	
	----------------------------------------------------
		
	FSM: process(clk, rst, next_state, encdec_started_update)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				fsm_state 	   <= S_IDLE;	
				encdec_started	<= '0';
			else
				fsm_state		<= next_state;
				encdec_started	<= encdec_started_update;
			end if;
		end if;
	end process;	
			
	----------------------------------------------------			
				
	state_change:	process(fsm_state, rst, a_data, enc, dec, gen_tag, full_size, encdec_started, Cipher_done)
	begin
		LFSR_rst						<= rst;
		LFSR_en						<= '0';
		Auth_en						<= '0';
		Tag_en						<= '0';
		Cipher_rst					<= '1';
		encdec_started_update	<= encdec_started;
		d								<= d0;
		done 			   			<= '0';
		
		next_state					<= fsm_state;
		
		case fsm_state is
		when S_IDLE =>
			if (rst = '0') then
				if ((enc = '1') or (dec = '1')) then
					LFSR_rst					<= not encdec_started;
					encdec_started_update<= '1';
				end if;	

				Tag_en						<= enc;
				
				if (gen_tag = '1') then
					LFSR_rst					<= not encdec_started;
				end if;

				if (a_data = '1') or (enc = '1') or (dec = '1') or (gen_tag = '1') then
					next_state				<= S_Start_Cipher;
				end if;
			end if;

		when S_Start_Cipher =>
			if (a_data = '1') then
				if (full_size = '1') then
					d						<= d2;
				else
					d						<= d3;
				end if;
			elsif (enc = '1') or (dec = '1') then
				if (full_size = '1') then
					d						<= d0;
				else
					d						<= d1;
				end if;
			elsif (gen_tag = '1') then
				if (full_size = '1') then
					d						<= d4;
				else
					d						<= d5;
				end if;
			end if;	

			next_state						<= S_Wait_for_Cipher_done;

		when S_Wait_for_Cipher_done =>
			Cipher_rst						<= '0';
			
			if (Cipher_done = '1') then
				LFSR_en						<= '1';
				Auth_en						<= a_data;
				Tag_en						<= dec;
				done							<= '1';
				next_state					<= S_Wait_for_Idle;
			end if;
		
		when S_Wait_for_Idle =>
			Cipher_rst						<= '0';

			if (a_data = '0') and (enc = '0') and (dec = '0') and (gen_tag = '0') then
				next_state 					<= S_IDLE;
			end if;
		end case;
	end process;	

end architecture;
