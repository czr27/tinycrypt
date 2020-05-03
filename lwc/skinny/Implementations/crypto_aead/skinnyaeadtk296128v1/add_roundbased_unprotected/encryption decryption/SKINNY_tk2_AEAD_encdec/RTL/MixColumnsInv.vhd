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
ENTITY MixColumnsInv is
	PORT ( X : IN	STD_LOGIC_VECTOR (127 DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR (127 DOWNTO 0));
END MixColumnsInv;



-- ARCHITECTURE : PARALLEL
----------------------------------------------------------------------------------
ARCHITECTURE Parallel of MixColumnsInv is


	-- SIGNALS --------------------------------------------------------------------
	SIGNAL C1_X3X0, C2_X3X0, C3_X3X0, C4_X3X0	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL C1_X3X1, C2_X3X1, C3_X3X1, C4_X3X1	: STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

	-- X3 XOR X1 (DECRYPT) --------------------------------------------------------
	C1_X3X1 <= X(95 DOWNTO 88) XOR X(31 DOWNTO 24);
	C2_X3X1 <= X(87 DOWNTO 80) XOR X(23 DOWNTO 16);
	C3_X3X1 <= X(79 DOWNTO 72) XOR X(15 DOWNTO  8);
	C4_X3X1 <= X(71 DOWNTO 64) XOR X( 7 DOWNTO  0);
	-------------------------------------------------------------------------------

	-- X3 XOR X0 (ENCRYPT) --------------------------------------------------------
	C1_X3X0 <= X(127 DOWNTO 120) XOR X(31 DOWNTO 24);
	C2_X3X0 <= X(119 DOWNTO 112) XOR X(23 DOWNTO 16);
	C3_X3X0 <= X(111 DOWNTO 104) XOR X(15 DOWNTO  8);
	C4_X3X0 <= X(103 DOWNTO  96) XOR X( 7 DOWNTO  0);
	-------------------------------------------------------------------------------

	-- COLUMN 1 -------------------------------------------------------------------
	Y(127 DOWNTO 120) <= X(95 DOWNTO 88);
	Y( 95 DOWNTO  88) <= C1_X3X1 XOR X(63 DOWNTO 56);
	Y( 63 DOWNTO  56) <= C1_X3X1;
	Y( 31 DOWNTO  24) <= C1_X3X0;
	-------------------------------------------------------------------------------

	-- COLUMN 2 -------------------------------------------------------------------
	Y(119 DOWNTO 112) <= X(87 DOWNTO 80);
	Y( 87 DOWNTO  80) <= C2_X3X1 XOR X(55 DOWNTO 48);
	Y( 55 DOWNTO  48) <= C2_X3X1;
	Y( 23 DOWNTO  16) <= C2_X3X0;
	-------------------------------------------------------------------------------

	-- COLUMN 3 -------------------------------------------------------------------
	Y(111 DOWNTO 104) <= X(79 DOWNTO 72);
	Y( 79 DOWNTO  72) <= C3_X3X1 XOR X(47 DOWNTO 40);
	Y( 47 DOWNTO  40) <= C3_X3X1;
	Y( 15 DOWNTO   8) <= C3_X3X0;
	-------------------------------------------------------------------------------

	-- COLUMN 4 -------------------------------------------------------------------
	Y(103 DOWNTO 96) <= X(71 DOWNTO 64);
	Y( 71 DOWNTO 64) <= C4_X3X1 XOR X(39 DOWNTO 32);
	Y( 39 DOWNTO 32) <= C4_X3X1;
	Y(  7 DOWNTO  0) <= C4_X3X0;
	-------------------------------------------------------------------------------

END Parallel;
