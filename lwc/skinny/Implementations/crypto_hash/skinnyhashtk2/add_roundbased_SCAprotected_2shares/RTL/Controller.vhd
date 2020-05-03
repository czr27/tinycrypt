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

entity Controller is
	Port(
		clk						: in  std_logic;
		rst						: in  std_logic;
		absorb					: in  std_logic;
		gen						: in  std_logic;
		full_size				: in  std_logic;
		all_pad					: out std_logic;
		all_zero					: out std_logic;
		State_Reg_rst			: out std_logic;
		State_Reg_en			: out std_logic;
		State_Temp_Reg_en		: out std_logic;
		Counter					: out std_logic;
		Cipher_rst				: out std_logic;
		Cipher_done				: in  std_logic;
		done						: out std_logic);
end entity Controller;

architecture dfl of Controller is

	signal last_block_processed			: STD_LOGIC;
	signal last_block_processed_update	: STD_LOGIC;

	signal Counter_Value						: STD_LOGIC;
	signal Counter_en							: STD_LOGIC;
	signal Counter_rst						: STD_LOGIC;

	type FSM_STATES is  (S_IDLE, S_Start_Cipher, S_Wait_for_Cipher_done, S_Wait_for_Idle);

  	signal fsm_state    : FSM_STATES := S_IDLE;
  	signal next_state   : FSM_STATES;

begin

	State_Reg_rst		<= rst;
	Counter				<= Counter_Value;
	
	----------------------------------------------------
		
	FSM: process(clk, rst, next_state, last_block_processed_update, Counter_rst, Counter_en, Counter_Value)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				fsm_state 	   			<= S_IDLE;	
				last_block_processed		<= '0';
			else
				fsm_state					<= next_state;
				last_block_processed		<= last_block_processed_update;
			end if;
			
			if (Counter_rst = '1') then
				Counter_Value				<= '0';
			elsif (Counter_en = '1') then
				Counter_Value				<= not Counter_Value;
			end if;	
		end if;
	end process;	
			
	----------------------------------------------------			
				
	state_change:	process(fsm_state, rst, absorb, gen, full_size, Counter_Value, Cipher_done, last_block_processed)
	begin
		all_pad												<= '0';
		all_zero												<= '0';
		State_Reg_en										<= '0';
		State_Temp_Reg_en									<= '0';
		Cipher_rst											<= '1';
		Counter_rst											<= '0';
		Counter_en											<= '0';
		last_block_processed_update					<= last_block_processed;
		done 			   									<= '0';
		
		next_state											<= fsm_state;
		
		case fsm_state is
		when S_IDLE =>
			Counter_rst										<= '1';
			
			if (absorb = '1') then
				if (full_size = '0') then
					last_block_processed_update 		<= '1';
				end if;
				
				next_state									<= S_Start_Cipher;
			end if;

			if (gen = '1') then
				next_state									<= S_Start_Cipher;
			end if;

		when S_Start_Cipher =>
			all_pad											<= gen and (not last_block_processed);
			all_zero											<= gen and last_block_processed;
			next_state										<= S_Wait_for_Cipher_done;

		when S_Wait_for_Cipher_done =>
			Cipher_rst										<= '0';
			
			if (Cipher_done = '1') then
				Counter_en									<= '1';
				
				if (Counter_Value = '0') then
					State_Temp_Reg_en						<= '1';
					next_state								<= S_Start_Cipher;
				
					if (gen = '1') and (last_block_processed = '1') then
						next_state							<= S_Wait_for_Idle;
					end if;
				else	
					State_Reg_en							<= '1';
					next_state								<= S_Wait_for_Idle;
					
					if (gen = '1') then
						last_block_processed_update	<= '1';
					
						if (last_block_processed = '0') then
							Counter_rst						<= '1';
							next_state						<= S_Start_Cipher;
						end if;
					end if;	
				end if;
			end if;
		
		when S_Wait_for_Idle =>
			done												<= '1';
			
			if (absorb = '0') and (gen = '0') then
				next_state 									<= S_IDLE;
			end if;
		end case;
	end process;	

end architecture;
