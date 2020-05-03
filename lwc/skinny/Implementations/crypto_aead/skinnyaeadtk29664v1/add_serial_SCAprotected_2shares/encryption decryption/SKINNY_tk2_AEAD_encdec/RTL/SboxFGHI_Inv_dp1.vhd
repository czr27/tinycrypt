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
ENTITY SboxFGHI_Inv_dp1 IS
    PORT ( X1 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			  X2 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
           Y1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           Y2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           Y3 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
           Y4 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END SboxFGHI_Inv_dp1;



-- ARCHITECTURE : BEHAVIORAL
----------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF SboxFGHI_Inv_dp1 IS

   -- SIGNALS --------------------------------------------------------------------
	SIGNAL XX1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL XX2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL YY1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL YY2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

	XX1(0) <= X1(0);
	XX1(1) <= X1(2);
	XX1(2) <= X1(1);
	XX1(3) <= X1(3);
	XX1(4) <= X1(4);
	XX1(5) <= X1(5);
	XX1(6) <= X1(6);
	XX1(7) <= X1(7);

	XX2(0) <= X2(0);
	XX2(1) <= X2(2);
	XX2(2) <= X2(1);
	XX2(3) <= X2(3);
	XX2(4) <= X2(4);
	XX2(5) <= X2(5);
	XX2(6) <= X2(6);
	XX2(7) <= X2(7);

	CF:   ENTITY work.CompFGHI1  PORT MAP (XX1(0), XX1(2), XX1(3), YY1(0));  -- X1(0) XOR  (X1(2)  NOR X1(3)) 	
	CFp1: ENTITY work.CompFGHIp1 PORT MAP (XX1(2), XX2(3), Y3(0));           -- (X1(2) NOR (not X2(3))
		
	YY1(1) <= XX1(1);
	YY1(2) <= XX1(2);
	YY1(3) <= XX1(3);

	CF3:  ENTITY work.CompFGHI1  PORT MAP (XX1(4), XX1(6), XX1(7), YY1(4));  --	X1(4) XOR  (X1(6)  NOR X1(7))	
	CFp3: ENTITY work.CompFGHIp1 PORT MAP (XX1(6), XX2(7), Y3(1));           -- (X1(6) NOR (not X2(7))

	YY1(5) <= XX1(5);
	YY1(6) <= XX1(6);
	YY1(7) <= XX1(7);

	------------------------------------

	CF2:  ENTITY work.CompFGHI2  PORT MAP (XX2(0), XX2(2), XX2(3), YY2(0));  -- X2(0) XNOR (X2(2) NAND X2(3)) 	
	CFp2: ENTITY work.CompFGHIp1 PORT MAP (XX1(3), XX2(2), Y4(0));           -- (X1(3) NOR (not X2(2))
	
	YY2(1) <= XX2(1);
	YY2(2) <= XX2(2);
	YY2(3) <= XX2(3);

	CF4:  ENTITY work.CompFGHI2  PORT MAP (XX2(4), XX2(6), XX2(7), YY2(4));   -- X2(4) XNOR (X2(6) NAND X2(7))
	CFp4: ENTITY work.CompFGHIp1 PORT MAP (XX1(7), XX2(6), Y4(1));            -- (X1(7) NOR (not X2(6))
	
	YY2(5) <= XX2(5);
	YY2(6) <= XX2(6);
	YY2(7) <= XX2(7);
	
	------------------------------------

	Y1(5) <= YY1(0);
	Y1(3) <= YY1(1);
	Y1(0) <= YY1(2);
	Y1(4) <= YY1(3);
	Y1(6) <= YY1(4);
	Y1(7) <= YY1(5);
	Y1(2) <= YY1(6);
	Y1(1) <= YY1(7);

	Y2(5) <= YY2(0);
	Y2(3) <= YY2(1);
	Y2(0) <= YY2(2);
	Y2(4) <= YY2(3);
	Y2(6) <= YY2(4);
	Y2(7) <= YY2(5);
	Y2(2) <= YY2(6);
	Y2(1) <= YY2(7);
	
END Behavioral;


