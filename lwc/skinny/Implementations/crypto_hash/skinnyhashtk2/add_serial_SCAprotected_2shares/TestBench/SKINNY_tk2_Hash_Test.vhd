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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.textio.all;
USE IEEE.std_logic_textio.all;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL; 

ENTITY SKINNY_tk2_Hash_Test IS
END SKINNY_tk2_Hash_Test;
 
ARCHITECTURE behavior OF SKINNY_tk2_Hash_Test IS 
 
 
   COMPONENT SKINNY_tk2_Hash
	Port (  
		clk          : in  STD_LOGIC;
		rst      	 : in  STD_LOGIC;
		absorb		 : in  STD_LOGIC;
		gen      	 : in  std_logic;
		InitialMask  : in  STD_LOGIC_VECTOR (255 downto 0); -- Random initial Mask only used with rst = '1'
		Message1     : in  STD_LOGIC_VECTOR ( 31 downto 0); -- Message (share 1)
		Message2     : in  STD_LOGIC_VECTOR ( 31 downto 0); -- Message (share 2)
		Block_Size	 : in  STD_LOGIC_VECTOR (  1 downto 0); -- Size of the given block as Input (in BYTES) - 1
		Hash1        : out STD_LOGIC_VECTOR (255 downto 0); -- Hash (share 1)
		Hash2        : out STD_LOGIC_VECTOR (255 downto 0); -- Hash (share 2)
		done         : out STD_LOGIC);
	end COMPONENT;
    

   --Inputs
   signal clk 			: std_logic := '0';
   signal rst 			: std_logic := '0';
   signal InitialMask: std_logic_vector(255 downto 0) := (others => '0');
	signal absorb 		: std_logic := '0';
   signal gen		 	: std_logic := '0';
   signal Message1	: std_logic_vector(31 downto 0) := (others => '0');
   signal Message2	: std_logic_vector(31 downto 0) := (others => '0');
   signal Block_Size : std_logic_vector( 1 downto 0) := (others => '0');

 	--Outputs
   signal Hash1 		: std_logic_vector(255 downto 0);
   signal Hash2 		: std_logic_vector(255 downto 0);
   signal done 		: std_logic;

   signal Message		: std_logic_vector(31  downto 0) := (others => '0');
   signal Hash			: std_logic_vector(255 downto 0);
	
	signal Mask1		: std_logic_vector(127 downto 0);
	signal Mask2		: std_logic_vector(127 downto 0);
	signal Mask3		: std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
 	type INT_ARRAY  is array (integer range <>) of integer range 0 to 255;
	type REAL_ARRAY is array (integer range <>) of real;
	type BYTE_ARRAY is array (integer range <>) of std_logic_vector(7 downto 0);

	signal r: INT_ARRAY (47 downto 0);
	signal m: BYTE_ARRAY(47 downto 0);

BEGIN
 
  	maskgen: process
		 variable seed1, seed2: positive;        -- seed values for random generator
		 variable rand: REAL_ARRAY(47 downto 0); -- random real-number value in range 0 to 1.0  
		 variable range_of_rand : real := 256.0; -- the range of random values created will be 0 to +255.
	begin
		 
		FOR i in 0 to 47 loop
			uniform(seed1, seed2, rand(i));   -- generate random number
			r(i) <= integer(TRUNC(rand(i)*range_of_rand));  -- rescale to 0...255, convert integer part 
			m(i) <= std_logic_vector(to_unsigned(r(i), m(i)'length));
		end loop;
		
		wait for clk_period;
	end process;  

	---------
	
	maskassign: FOR i in 0 to 15 GENERATE
		Mask1(i*8+7 downto i*8)	<= m(i);
		Mask2(i*8+7 downto i*8)	<= m(16+i);
		Mask3(i*8+7 downto i*8)	<= m(32+i);
	END GENERATE;

	---------
	
   uut: SKINNY_tk2_Hash
	PORT MAP (
		clk 			=> clk,
		rst 			=> rst,
		InitialMask => InitialMask,		
		absorb 		=> absorb,
		gen	 		=> gen,
		Message1 	=> Message1,
		Message2 	=> Message2,
		Block_Size 	=> Block_Size,
		Hash1			=> Hash1,
		Hash2			=> Hash2,
		done 			=> done
        );

	InitialMask	<= Mask1 & Mask2;

	Message1		<= Message XOR Mask3(31 downto 0);
	Message2		<= Mask3(31 downto 0);

	Hash			<= Hash1 XOR Hash2;

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      --------- test no. 1 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"5DC460677EBA0DF3B48C60E949097A6C5D58E1C9ECF97C6FE89212B4B91F246F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 2 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"00";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"49BC2538DEC23CD247989DE36F83BB730D307C758405EF15F7E97FCB7F7674D9") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 3 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"0001";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A5CDCF914B9B8368CB4BC005B36F475E514ED3441799D0E8C022FD50BED8E206") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 4 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"000102";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"28FB54A33D65032430AF9B45C3417D52D600D22904C8C4AB3675EF29DFF999B7") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 5 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"5557CAA3489858BBF119D7FCF55CDAA1E9817FD647CF68094432A2487D20D377") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 6 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"04";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C29EF3F3EA35862BBD4FE14DA3F445C46C4AA4FF6BBF97E48E4A43C273B4497C") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 7 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"0405";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F256A87596CEC799C8411E6FF9C1E0084A76B186A7E32CFC322974C049F45BDF") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 8 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"040506";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"54EC1ED5910944FCA7A96084A50B4C77486509CD7941DB981BB4CA35EFEDDFFA") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 9 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3ADD705B5692C51A8F8C24E31448E35F141D26DB52F9ECCF61D5F670081050E9") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 10 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"08";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D60FC0F7D4F8B0632025F018B414929E0DCF8F44DA3437B26DCDBDBBCBAAA01F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 11 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"0809";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"EFD06747DC16995D3D530A49A43374CC595A2B08C82FD6154DD3E10311C23B09") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 12 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"08090A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A39CB2CD90E03CB6049BF2B62A5653A6D5B7A742E1772237B68F853AA17188C3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 13 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"01870E4ECC71AC2F1DE7A564A3ADB5F6DC68165FEEDD4644DA2B0C4FF8960F4D") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 14 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"0C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"565C52E64FC30B0DF148E1EDCEB95F4E6D25C0DABBEBFCDF2430AB38A4E2C371") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 15 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"0C0D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2213AC38B5EFD8D15FDA5A0566697EF6AD1627D9E92CB625A527AD82816D9A90") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 16 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"0C0D0E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BB0A3F1582C882A84DBF3C79A263D4BA85B4A45339904F4263E7DD0143FBF169") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 17 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8E110634307103B6AA92851B083058814F2A64DA807B0824EB8D2865CC6A1447") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 18 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"10";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E3B977E8FB0BE21B87647C3E95F3F5CD8C7605414BB941427659E919C113C399") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 19 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"1011";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B6C464331FE647FAE8D1499DF6EAC58DC88D968BEA7BE93F6CCB492EB28BF576") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 20 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"101112";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"18D52E08641C4674709CD1AC5337CB0B69DDE21B9A9D86E0C1E528023D358FFE") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 21 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"49AF95DF7042862E245669DE5764C8F015DD8643EDB0566270CA8E2E3CC8182F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 22 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"14";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0A6183657CED231C11108505F5428FBD8F73C8D0077C2F2F76DD4C40B395F9CA") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 23 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"1415";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F0E092414C0BDD76BA104C1CDB4E8C0D7BBFBDB3323FADD72B2A6636A5621D47") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 24 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"141516";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D2EC439EAFA9ED6588DAE3D73E08DF40C45B2748F408E544E155E681ED86A792") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 25 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"32DE395A4B04DEB29B545EB6D98D399C93A22E80FA821638873811796CBD6894") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 26 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"18";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"404FF588F46DF08ED4FFA540EA4FA45FE22B51F379B6852758ACF9DA2C4DD5AA") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 27 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"1819";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"AD9E5E779F5B80C83CF543CFC23F857A5F97171A73BFB6DFCE426F81120AC8C3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 28 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"18191A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E36972ED158E30808901C1685A9FAD6602718E9F9D78F0C36878E66C30FAC42B") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 29 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"AA00B724943F843A72F3EA21972DFE281085DE7DB4C6F5F989F19FB05DCAAC8E") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 30 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"1C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"56DACF778C52D30E3A6C65604925CCBE3863C3D0CE516A7E45768B8ED8FC64BE") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 31 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"1C1D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D0FC7777FD29A6365D370E3AEA81D32B642FB4126BFF7966E82460B5B4701C3C") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 32 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"1C1D1E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F873BCE3D0C26800CC7FE1CDEB7B5346F8698A2861FD88EEB8CC78E32FC40600") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 33 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0B9B40297FCF226A1A32E5E811F9969B49A68EA2C7888B0F0C7A8EC2FCB0BB23") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 34 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"20";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4FECF67DBBDBAD39459229AD8B2A30C0972451CA512D74EA08E1B47AA23A682E") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 35 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"2021";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"24BD9C021ACC16F2360C7AECA936FB725824E01557DC8B1003E69530DF24C9DD") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 36 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"202122";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"642A20162EA27F7963F123A12C016101D36C2F2406F473524AACF8F41F8470F2") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 37 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"60263A10B5EE406A195212CD2055054555390AB94D40C1493C175B8B0FB8F863") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 38 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"24";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"91B498ED0F9B8FBFDFA9E70F7D705F2FE4A53F9C9368EE4F655684A2A9B0B180") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 39 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"2425";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B54E7F8F705F7A8490E2818AA11D51CF5CE7CA83E1962055D4102D748557D2C5") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 40 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"242526";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"06FBDC89F38F649EEF44A2FA795ED0CDC5F163CDFD0D189958738E73B39D9FEB") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 41 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"385A8349674785AA3EC8EF2A7F49934DDB7F8AE75A2CD41311345F9407F910DC") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 42 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"28";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B832B32075B0FEAEFFD2ACD202F5F907DB2587A3674B5BAE09FA246C0512DDF4") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 43 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"2829";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A0AE80B6119A1DB71D60B441B41DE8C893855E174F9604AED59B1A4FD5C5E035") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 44 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"28292A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D4FC601D9F150F8213FA37020E17BD5D9A5528D79DAAF22850FC0FFAC7A42E38") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 45 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FA5EA43A0A8FA9A26E631283A7FA627EC2FC2B01E34BACA3C33F0EF4AE666BD4") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 46 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"2C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C805E324C9DBFB7FF2D0CBC6DECFD1D7AB23F963C2A6715CA4A8E54628AB0D34") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 47 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"2C2D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"42C38D98417F5B6FACDBAC4EDF9B28E62B72861F781AFDE3A4BAF12A8DA183C9") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 48 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"2C2D2E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C72925867EE26538E988401EB83F8F21139B0484F0FE53A077A09353207D4481") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 49 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D639CB931FF3834312F48B7003BDF723AD0B4BD17F71A1EF8E72329EF2C10242") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 50 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"30";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E94A0DBCF95AD3610BB803AE7153B3FF3E29293EBAC3A3C18966E607BEB11128") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 51 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"3031";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9BE57940FDBFB88F0F5D8FFFD4F83B4AE7A142B4BAE4D1D8F8573B217B5664DD") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 52 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"303132";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8FFD64892123C9F3A41462C49DD94E1C00869757C438512F92F1794C8CBDA9E0") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 53 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"24839A6C6E38B6F0536FEC59554F290712462C44AF48CB3885DDA1A80F87B833") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 54 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"34";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FA146F748F25A33538E67ACC7AFC7DA9267701F6A694DD88D72B9B124C6E144F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 55 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"3435";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9DC89C072716D919AA07CA5E619BCA1C472E82B7CA343D8C8E0D066BFCD0FD4F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 56 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"343536";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6D0513B7D7839F1CA2BA50A934ED39F03157B8F26A6CAD32FACD96948211CD53") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 57 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"631B486C9ED28BBAD3B4BB319ABD7AE2A0DAB57B161C7C866A41B143E6EBC5A6") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 58 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"38";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4849FB37981B3F2F08851E0619474F0D5D2DFFFFFDBDA4FE91A64556EBD7B464") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 59 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"3839";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"738B9EDE3B300938D31E831CC603F5C81E08C286D95A2F1FD3727F0AF1077051") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 60 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"38393A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A8180ECBE04DFDF4F6005D282D31339F550A67D143CE67BAE8705D76FD5E2D73") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 61 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"28E877FF7E7B92887CE6E635666FF1855A321FDD0898AA6B8909F754454AD664") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 62 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"3C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"529649A1DE546C52795DDDE188FE9E43AC37076C5305AFB98E7D157E2A169D2A") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 63 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"3C3D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"15966399C2A7AFEC095468E54D634FC754599581B76A72AA68E960B3E035A904") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 64 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"3C3D3E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2349C3E9510E33C686A0F260FCB38CFC47D2791B2C2800ACDA2F1C6FB79DAE41") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 65 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"104860318C325A7F08B9C599A394E10492B7E758083FEA4457878F6FCD940E5C") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 66 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"40";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4EBDE9FF001439F0D8E853A3704ECCE098E52DC8BC68991C5483093B5AEFB9C3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 67 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"4041";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3B0D01A8B8AC3E9F721D7B2D2220BB9282D18840AB04B12D28FCB54277C99AD0") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 68 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"404142";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"97FE7F8A538AF5C575608B113E5C303114233AF2EADF3E3BB561709FADA8F6F8") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 69 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4CEE30EB963B5864BF0B70D9E10ECF1B8C60D973294C10A7A095DC327140F184") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 70 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"44";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"808E19FA8A50EC4B7420E4B0EDACC59BD9AD797A587EC1F35289EC13269CBC42") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 71 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"4445";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FC9EB3A6E4A2321C3ADAD941CEAEA8D775217E51F596AB61C2E895957DB4C145") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 72 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"444546";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"21562C437F9571B7CC08E5412728FF991BD8EE33CD11F0231C207144B15B503A") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 73 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D1CE961D70438875C79A850603E9789485E8395C35C7FFBE3FD00EEA35B8E1BF") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 74 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"48";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4A301CF1D0763D7A09E860A5590DFA3A59B1D125DFBF8110882148D2DAFD7E80") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 75 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"4849";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"694A4BC942BB8C5D211982686B1758E8F06CB1F0419BF52587DA23DB5854890B") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 76 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"48494A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"989C7F6C91937B68536B586ECC09BB7E5E38A6CD50E913BC10F8AC163702493C") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 77 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D2F76F78DA6CDBBBE4A53EE4EB28CFFBE22D3D35CA58953C3237E61A7BD5E8B7") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 78 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"4C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"60E74000FA71AF83584AB73869FDCA5B35D9F7D2048225C13E916244116ECEDA") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 79 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"4C4D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0F5F2177BF64759340EF77D71EADF603E6B391525F0D9C7C353CDB5FD2F3071B") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 80 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"4C4D4E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"5F8AC46CEB745991B80E3063A132EFDEC03B945B98F7B58A8B770D46FC5E4E88") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 81 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BF04624CCA981FF57CD7EF1A5EC69D65FA9AB1172E7DCF761E4D817FDE169AFC") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 82 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"50";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B2E673D19384B09413F3DBF4DD0CD3910BB3A9409CAC4E791148B9654E422798") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 83 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"5051";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C063C99D69C74A300536B652FCEAADEDBAAD4A4FC5320832DE04630CF2AF09E3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 84 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"505152";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"AEC4A22D8C2B10012EF588EA437C480FCA3294E2C13ED34FCB6A1E6BA224F104") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 85 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F7EF52C31FBAA0F8ABE22AB358282C767946CA2F12E412E1FB4497F7D7C24CE9") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 86 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"54";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"7ED8696F1B4073099D3C75DAA1A49931BBF904D8443A9FABD83A400BF2E0886C") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 87 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"5455";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3EF16F8A3341D77AC1E52FA6FB9DA36A886F04A2D8CAA6D461237AFCEFD68239") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 88 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"545556";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"1CD19AE76534BDA567502E2B2FF0C9B9E357F7475C4C54EBC55169D1588676BD") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 89 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"AF1181AA43022C7BDFA4DD4781DC33A034FE226B80DBFC9BB31ADB7E35E82D01") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 90 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"58";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"842306B718AF01CF888269C6263FC06FFA50B244460AAF974DC5B470AB54525F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 91 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"5859";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B293351B05C2BF8DAB3DCCA9699284C107D996DEA366954B6913EA6F611E13D2") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 92 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"58595A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"020F80FDC2FBADB87B8B6D1F41DDF0620C965754BA07EE8A5CCD98EFF4B2F9E4") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 93 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F2F38BEE9E5B53D5E694A064827453AAC6CBB7D06D9DE139F708D4C1A59EDD32") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 94 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"5C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F399A12D19EEEF477AA486004B7465C825B0F95A242D0E742357B4A43BE29111") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 95 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"5C5D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D5008E4C76B4DEB8FC566052DC765BDBE9E8BC59CAD4E34A2972D183787ED822") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 96 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"5C5D5E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"143018090D0DCD1354C94768B982AD9FE17CCA33D2127E3EA6E185F6CD5643DF") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 97 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"316E169B8A1E7F38678BCC6FAAD09EA9FBA44345C5BD389B709EE26133D9509B") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 98 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"60";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"732BFFE75E4B5DC9FB35B20E3114EF7C7991AF89C6BDFCB1C617D257E5E7FCFC") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 99 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"6061";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"19B17A75FA084C14F41ED33959E605AB66EB60AE54DFFECC996ABA0B643AAD2D") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 100 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"606162";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8F905BB0568C04CEDCA33D440E6957001010B64A7E68A759861EFC605E94EDB2") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 101 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"32F00E4CA585B449F6CCADDE937C83B9D671F902C4AD7AFD8C79A0F6046EA687") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 102 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"64";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A0D05948074DBDADAE8062562C912B6F4820D4A9F2603D12BC73ECE84F52D163") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 103 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"6465";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6BD933F49B31400106B27B28385DFE37597D4B92710081729D9840B5184E3345") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 104 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"646566";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E431B9B4637852128CFC4E24F2AB65EBE07DB046970DA4F50D36D35F8B5B5412") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 105 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"070D0DCAD664BF57151A41A00E3ED603C06B369F74A522A9D61397C017C324AA") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 106 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"68";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"10B878AEFB92F642F4FF554038F643CC4BD730C99B5F80B940D99A280BBF0AAF") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 107 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"6869";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"EFECCD428551701943A94DD0F6FF2659B237D05907A2663FF67FFBD8B1B95BDB") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 108 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"68696A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F0C91833DA6A7902CF0D16B5DFD2B383F921E0AE547F661253CB13E7480938A6") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 109 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"53F84B2E81E4F523408E549E03E9D295017EDA8E2282CA409AC075ED6B5B6DFA") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 110 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"6C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"95E17AD5B637C2229EDC790904C8AB154D118132F46B21FB958F822797E8ED43") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 111 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"6C6D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"63771A5FB3774939F7FF036363CB572FFB64C6A8B02F0709E14EDE142F221DF3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 112 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"6C6D6E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FD511102C20F7DF6EA2B8212DCD42ED045DB754FC60C5A4008F30C43444575D5") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 113 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"7317CB607CBD354C8304FFD7A00E27C5EDBC0CD0A2D897220218F02731BCA8C2") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 114 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"70";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0817DA18D5070E5BC7C1BA5DA634EDE2B48C0C5EE5256B8D96B2A77E0D6A784F") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 115 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"7071";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4F46318F64973EB299A657245007FB2ED31187A3BABBBA6819A1DE1351EEE7BC") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 116 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"707172";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BBF274EF3B549F3914009EA39B19F3705B998A46A38A2F73B1100D52D69BCE06") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 117 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D9C0DC433C6DA028195F5DBF58642FA34AFAD40C4A5A438AE8FC40BEAE0348D3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 118 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"74";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"786A9177A502A23F12F60E69B32815890604145F1BCAB859DAD26E0FB75A7735") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 119 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"7475";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6B9768A6136630655E8DF0E4791A9D7F1AB31987FEDC5C83567185D010AC65F7") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 120 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"747576";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"39E0A8AABE54F2D5273FB62C680F0B2ED1DDC39DE035D9C432F73389C1990527") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 121 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"EACB2997744400A891E4A9F10D74FEA39E253202001F9AF2EF39407E83B00EAF") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 122 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"78";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8EC977DF1A762B12D3A07B3CB6818CA8E2305E96B7DA4C53A7F740F519535884") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 123 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"7879";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6080BE3F20359E4A268F5C2423E0E9C3E9EB5AFE1E1FBF4ABA4B2DF7F86933B3") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 124 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"78797A";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"89483BC493E12F85413BDAD5F5DA6DCCEF3DCFE6B466C8A31A832827EE97234A") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 125 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"78797A7B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"1A0EAE49674695947A615C633AD840C9F1AC4F5D2721A88891BEFEBFF90F7F29") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 126 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"78797A7B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-0)) <= x"7C";
      Block_Size <= "00";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"1469A8319D83D5EE7DFED058E3045929534C0EC49D019A40E771B8BD88B7794A") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 127 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"78797A7B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-1)) <= x"7C7D";
      Block_Size <= "01";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F7721BBA87B66D5B2F5E6A93F9E0AC08633F87B6021D1FB61DD019C585498353") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 128 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"78797A7B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-2)) <= x"7C7D7E";
      Block_Size <= "10";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"48B8A00E0792C4BEE5E8EC7C2EC0C4E68758A89C160148507DE74903E684876B") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      --------- test no. 129 ----------

      rst     <= '1';
      absorb  <= '0';
      gen     <= '0';
      wait for clk_period * 1;

      rst <= '0';
      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"00010203";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"04050607";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"08090A0B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"0C0D0E0F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"10111213";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"14151617";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"18191A1B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"1C1D1E1F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"20212223";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"24252627";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"28292A2B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"2C2D2E2F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"30313233";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"34353637";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"38393A3B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"3C3D3E3F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"40414243";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"44454647";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"48494A4B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"4C4D4E4F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"50515253";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"54555657";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"58595A5B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"5C5D5E5F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"60616263";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"64656667";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"68696A6B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"6C6D6E6F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"70717273";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"74757677";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"78797A7B";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*4-1 downto 8*(3-3)) <= x"7C7D7E7F";
      Block_Size <= "11";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F3A27A788FD588389A5E454431B2F5EEEE26BE6001F1F8B8EF2D843AE81A5C38") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      wait;
   end process;

END;
