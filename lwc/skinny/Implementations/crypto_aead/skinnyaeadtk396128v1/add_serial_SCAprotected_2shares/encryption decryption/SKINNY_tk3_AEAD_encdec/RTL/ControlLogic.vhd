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
ENTITY ControlLogic IS
	PORT ( CLK		: IN	STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
		  	 RESET		: IN  STD_LOGIC;
		  	 DECRYPT		: IN  STD_LOGIC;
		    DONE			: OUT STD_LOGIC;
			 ROUND_CTL	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			 KEY_CTL 	: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			 -- CONST PORT -----------------------------------
          ROUND_CST  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END ControlLogic;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF ControlLogic IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, UPDATE : STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL FINAL			: STD_LOGIC;

	SIGNAL COUNTER			: INTEGER RANGE 0 TO 84;

BEGIN

	-- CONTROL LOGIC --------------------------------------------------------------
	PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			IF (RESET = '1' OR COUNTER = 84) THEN
				COUNTER <= 0;
			ELSE
				COUNTER <= COUNTER + 1;
			END IF;
		END IF;
	END PROCESS;

	KEY_CTL(0) 	 <= '1' WHEN (DECRYPT = '0' AND COUNTER > 63 AND COUNTER < 72) ELSE '1' WHEN (DECRYPT = '1' AND (COUNTER > 4 AND COUNTER < 13)) ELSE '0';
	KEY_CTL(1)	 <= '1' WHEN (DECRYPT = '0' AND COUNTER = 80) ELSE '1' WHEN (DECRYPT = '1' AND COUNTER = 84) ELSE '0';

	ROUND_CTL(0) <= '0' WHEN (RESET = '1') ELSE '1' WHEN (DECRYPT = '0' AND COUNTER = 80) ELSE '1' WHEN (DECRYPT = '1' AND COUNTER =  4) ELSE '0';
	ROUND_CTL(1) <= '0' WHEN (RESET = '1') ELSE '1' WHEN (DECRYPT = '0' AND COUNTER > 80) ELSE '1' WHEN (DECRYPT = '1' AND COUNTER <  4) ELSE '0';
	ROUND_CTL(2) <= '0' WHEN (RESET = '1') ELSE '1' WHEN (DECRYPT = '0' AND COUNTER > 63) ELSE '1' WHEN (DECRYPT = '1' AND COUNTER > 68) ELSE '0';
	ROUND_CTL(3) <= '0' WHEN (RESET = '1') ELSE '1' WHEN (DECRYPT = '0' AND COUNTER < 16) ELSE '1' WHEN (DECRYPT = '1' AND COUNTER >  4 AND COUNTER < 21) ELSE '0';

	-- CONST: STATE ---------------------------------------------------------------
	REG : PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			IF (RESET = '1') THEN
				STATE <= "0" & DECRYPT & "0" & DECRYPT & "0" & DECRYPT;
			ELSIF (COUNTER = 84) THEN
				STATE <= UPDATE;
			END IF;
		END IF;
	END PROCESS;

	-- UPDATE FUNCTION ------------------------------------------------------------
	UPDATE 	<= STATE(4 DOWNTO 0) & (STATE(5) XNOR STATE(4)) WHEN (DECRYPT = '0') ELSE (STATE(5) XNOR STATE(0)) & STATE(5 DOWNTO 1);

	-- CONSTANT -------------------------------------------------------------------
	ROUND_CST(7 DOWNTO 4) <= "0000";
	ROUND_CST(3) <= UPDATE(3) WHEN ((DECRYPT = '0' AND COUNTER = 64) OR (DECRYPT = '1' AND COUNTER = 5)) ELSE '0';
	ROUND_CST(2) <= UPDATE(2) WHEN ((DECRYPT = '0' AND COUNTER = 64) OR (DECRYPT = '1' AND COUNTER = 5)) ELSE '0';
	ROUND_CST(1) <= UPDATE(1) WHEN ((DECRYPT = '0' AND COUNTER = 64) OR (DECRYPT = '1' AND COUNTER = 5)) ELSE UPDATE(5) WHEN ((DECRYPT = '0' AND COUNTER = 68) OR (DECRYPT = '1' AND COUNTER = 9)) ELSE '1' WHEN ((DECRYPT = '0' AND COUNTER = 72) OR (DECRYPT = '1' AND COUNTER = 13)) ELSE '0';
	ROUND_CST(0) <= UPDATE(0) WHEN ((DECRYPT = '0' AND COUNTER = 64) OR (DECRYPT = '1' AND COUNTER = 5)) ELSE UPDATE(4) WHEN ((DECRYPT = '0' AND COUNTER = 68) OR (DECRYPT = '1' AND COUNTER = 9)) ELSE '0';

	-- DONE SIGNAL ----------------------------------------------------------------
	DONE <= '1' WHEN (DECRYPT = '0' AND UPDATE = "010101" AND COUNTER = 0) ELSE 
	        '1' WHEN (DECRYPT = '1' AND UPDATE = "000000" AND COUNTER = 0) ELSE 
	        '0';

END Round;
