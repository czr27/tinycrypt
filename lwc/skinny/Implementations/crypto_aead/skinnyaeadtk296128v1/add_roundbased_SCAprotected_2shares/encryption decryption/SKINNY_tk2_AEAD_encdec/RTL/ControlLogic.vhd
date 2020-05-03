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
USE IEEE.NUMERIC_STD.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY ControlLogic IS
	PORT ( CLK			: IN	STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
		  	 RESET		: IN  STD_LOGIC;
			 DECRYPT		: IN	STD_LOGIC;
		    DONE			: OUT STD_LOGIC;
			 FIRST		: OUT STD_LOGIC;
			 LAST			: OUT STD_LOGIC;
			 -- CONST PORT -----------------------------------
          ROUND_CST	: OUT STD_LOGIC_VECTOR (5 DOWNTO 0));
END ControlLogic;



-- ARCHITECTURE : ROUND
----------------------------------------------------------------------------------
ARCHITECTURE Round OF ControlLogic IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL STATE, UPDATE : STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL COUNTER			: INTEGER RANGE 0 TO 4;
	SIGNAL COUNTERIS0		: STD_LOGIC;
	SIGNAL COUNTERIS4		: STD_LOGIC;

BEGIN

	-- CONTROL LOGIC --------------------------------------------------------------
	PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			IF (RESET = '1' OR COUNTER = 4) THEN
				COUNTER <= 0;
			ELSE
				COUNTER <= COUNTER + 1;
			END IF;
		END IF;
	END PROCESS;

	COUNTERIS0 	<= '1' WHEN (COUNTER = 0) ELSE '0';
	COUNTERIS4 	<= '1' WHEN (COUNTER = 4) ELSE '0';
	FIRST 		<= COUNTERIS0;
	LAST 			<= COUNTERIS4;

	-- STATE ----------------------------------------------------------------------
	REG : PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			IF (RESET = '1') THEN
				STATE <= "00" & DECRYPT & "00" & DECRYPT;
			ELSIF (COUNTER = 4) THEN
				STATE <= UPDATE;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------

	-- UPDATE FUNCTION ------------------------------------------------------------
	UPDATE 	<= STATE(4 DOWNTO 0) & (STATE(5) XNOR STATE(4)) WHEN (DECRYPT = '0') ELSE (STATE(5) XNOR STATE(0)) & STATE(5 DOWNTO 1);

	-- CONSTANT -------------------------------------------------------------------
	ROUND_CST <= UPDATE;

	-- DONE SIGNAL ----------------------------------------------------------------
	DONE <= COUNTERIS4 WHEN (DECRYPT = '0' AND UPDATE = "000100") OR (DECRYPT = '1' AND UPDATE = "000001") ELSE '0';

END Round;
