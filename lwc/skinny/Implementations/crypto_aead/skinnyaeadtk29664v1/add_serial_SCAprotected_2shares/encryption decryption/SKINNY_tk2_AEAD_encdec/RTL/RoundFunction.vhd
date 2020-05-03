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

-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY RoundFunction IS
   PORT ( CLK        : IN  STD_LOGIC;
   		 -- CONTROL PORTS --------------------------------
          RESET      : IN  STD_LOGIC;
          DECRYPT    : IN  STD_LOGIC;
          ROUND_CTL  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
   	    -- CONSTANT PORT --------------------------------
          ROUND_CST  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
   	    -- KEY PORT -------------------------------------
          ROUND_KEY1 : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          ROUND_KEY2 : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
   	    -- DATA PORTS -----------------------------------
          SHARE1_IN  : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          SHARE2_IN  : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
          SHARE1_OUT : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
          SHARE2_OUT : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : ROW
----------------------------------------------------------------------------------
ARCHITECTURE Row OF RoundFunction IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, SHIFTROWS, STATE_NEXT   : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL SUBSTITUTE_ENC, SUBSTITUTE_DEC : STD_LOGIC_VECTOR( 15 DOWNTO 0);
	SIGNAL ADDITION_IN, ADDITION_OUT		  : STD_LOGIC_VECTOR( 15 DOWNTO 0);
	SIGNAL COLUMN, MIXCOLUMN				  : STD_LOGIC_VECTOR( 63 DOWNTO 0);
	SIGNAL EXP1, EXP2, NE1, NE2, ND1, ND2 : STD_LOGIC_VECTOR(  1 DOWNTO 0);

BEGIN

   -- SIGNAL ASSIGNMENTS ---------------------------------------------------------
   COLUMN(31 DOWNTO  0) <= STATE(127 DOWNTO 120) & STATE( 95 DOWNTO  88) & STATE( 63 DOWNTO  56) & STATE( 31 DOWNTO  24);
   COLUMN(63 DOWNTO 32) <= STATE(255 DOWNTO 248) & STATE(223 DOWNTO 216) & STATE(191 DOWNTO 184) & STATE(159 DOWNTO 152);

	-- REGISTER STAGES ------------------------------------------------------------
	RS1 : ENTITY work.RegisterStage PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(127 DOWNTO   0), SHIFTROWS(127 DOWNTO   0), STATE(127 DOWNTO   0));
	RS2 : ENTITY work.RegisterStage PORT MAP (CLK, ROUND_CTL(0), STATE_NEXT(255 DOWNTO 128), SHIFTROWS(255 DOWNTO 128), STATE(255 DOWNTO 128));

   -- EXPANSION STAGES -----------------------------------------------------------   
	EX1 : ENTITY work.Expansion GENERIC MAP (SIZE => 2) PORT MAP (CLK, RESET, ROUND_CTL(2), DECRYPT, NE1, ND1, EXP1);
	EX2 : ENTITY work.Expansion GENERIC MAP (SIZE => 2) PORT MAP (CLK, RESET, ROUND_CTL(2), DECRYPT, NE2, ND2, EXP2);
	
	-- ENCRYPTION -----------------------------------------------------------------
	SBE : ENTITY work.SBox PORT MAP (ROUND_CTL(2), EXP1, EXP2, NE1, NE2, STATE(127 DOWNTO 120), STATE(255 DOWNTO 248), SUBSTITUTE_ENC( 7 DOWNTO 0), SUBSTITUTE_ENC(15 DOWNTO 8));

	-- DECRYPTION -----------------------------------------------------------------	
	SBD : ENTITY work.SBoxInv PORT MAP (ROUND_CTL(3), ROUND_CTL(2), EXP1, EXP2, ND1, ND2, STATE(127 DOWNTO 120), STATE(255 DOWNTO 248), ADDITION_OUT(7 DOWNTO 0), ADDITION_OUT(15 DOWNTO 8), SUBSTITUTE_DEC( 7 DOWNTO 0), SUBSTITUTE_DEC(15 DOWNTO 8));

	-- CONSTANT AND KEY ADDITION --------------------------------------------------	
	ADDITION_IN( 7 DOWNTO 0) <= SUBSTITUTE_ENC( 7 DOWNTO 0) WHEN (DECRYPT = '0') ELSE STATE(127 DOWNTO 120);
	ADDITION_IN(15 DOWNTO 8) <= SUBSTITUTE_ENC(15 DOWNTO 8) WHEN (DECRYPT = '0') ELSE STATE(255 DOWNTO 248);
	
	KA1 : ENTITY work.AddConstKey PORT MAP (ROUND_CST,       ROUND_KEY1, ADDITION_IN( 7 DOWNTO 0), ADDITION_OUT( 7 DOWNTO 0));
	KA2 : ENTITY work.AddConstKey PORT MAP (ROUND_KEY2, (OTHERS => '0'), ADDITION_IN(15 DOWNTO 8), ADDITION_OUT(15 DOWNTO 8));

	-- SHIFT ROWS -----------------------------------------------------------------
	SR1 : ENTITY work.ShiftRows PORT MAP (DECRYPT, STATE(127 DOWNTO   0), SHIFTROWS(127 DOWNTO   0));
	SR2 : ENTITY work.ShiftRows PORT MAP (DECRYPT, STATE(255 DOWNTO 128), SHIFTROWS(255 DOWNTO 128));

	-- MIX COLUMNS ----------------------------------------------------------------
	MC1 : ENTITY work.MixColumns PORT MAP (DECRYPT, COLUMN(31 DOWNTO  0), MIXCOLUMN(31 DOWNTO  0));
	MC2 : ENTITY work.MixColumns PORT MAP (DECRYPT, COLUMN(63 DOWNTO 32), MIXCOLUMN(63 DOWNTO 32));

   -- MULTIPLEXERS ---------------------------------------------------------------
   STATE_NEXT(127 DOWNTO  96) <= STATE(119 DOWNTO  96) & MIXCOLUMN(31 DOWNTO 24) WHEN (ROUND_CTL(1) = '1') ELSE SHARE1_IN(127 DOWNTO  96) WHEN (RESET = '1') ELSE STATE(119 DOWNTO  88);
   STATE_NEXT(255 DOWNTO 224) <= STATE(247 DOWNTO 224) & MIXCOLUMN(63 DOWNTO 56) WHEN (ROUND_CTL(1) = '1') ELSE SHARE2_IN(127 DOWNTO  96) WHEN (RESET = '1') ELSE STATE(247 DOWNTO 216);
   
   STATE_NEXT( 95 DOWNTO  64) <= STATE( 87 DOWNTO  64) & MIXCOLUMN(23 DOWNTO 16) WHEN (ROUND_CTL(1) = '1') ELSE SHARE1_IN( 95 DOWNTO  64) WHEN (RESET = '1') ELSE STATE( 87 DOWNTO  56);
   STATE_NEXT(223 DOWNTO 192) <= STATE(215 DOWNTO 192) & MIXCOLUMN(55 DOWNTO 48) WHEN (ROUND_CTL(1) = '1') ELSE SHARE2_IN( 95 DOWNTO  64) WHEN (RESET = '1') ELSE STATE(215 DOWNTO 184);
   
   STATE_NEXT( 63 DOWNTO  32) <= STATE( 55 DOWNTO  32) & MIXCOLUMN(15 DOWNTO  8) WHEN (ROUND_CTL(1) = '1') ELSE SHARE1_IN( 63 DOWNTO  32) WHEN (RESET = '1') ELSE STATE( 55 DOWNTO  24);
   STATE_NEXT(191 DOWNTO 160) <= STATE(183 DOWNTO 160) & MIXCOLUMN(47 DOWNTO 40) WHEN (ROUND_CTL(1) = '1') ELSE SHARE2_IN( 63 DOWNTO  32) WHEN (RESET = '1') ELSE STATE(183 DOWNTO 152);
   
   STATE_NEXT( 31 DOWNTO   0) <= STATE( 23 DOWNTO   0) & MIXCOLUMN( 7 DOWNTO  0) WHEN (ROUND_CTL(1) = '1') ELSE SHARE1_IN( 31 DOWNTO   0) WHEN (RESET = '1') ELSE STATE( 23 DOWNTO   0) & ADDITION_OUT( 7 DOWNTO 0) WHEN (DECRYPT = '0') ELSE STATE( 23 DOWNTO   0) & SUBSTITUTE_DEC( 7 DOWNTO 0);
   STATE_NEXT(159 DOWNTO 128) <= STATE(151 DOWNTO 128) & MIXCOLUMN(39 DOWNTO 32) WHEN (ROUND_CTL(1) = '1') ELSE SHARE2_IN( 31 DOWNTO   0) WHEN (RESET = '1') ELSE STATE(151 DOWNTO 128) & ADDITION_OUT(15 DOWNTO 8) WHEN (DECRYPT = '0') ELSE STATE(151 DOWNTO 128) & SUBSTITUTE_DEC(15 DOWNTO 8);

	-- ROUND OUTPUT ---------------------------------------------------------------
	SHARE1_OUT <= STATE(127 DOWNTO   0);
	SHARE2_OUT <= STATE(255 DOWNTO 128);

END Row;
