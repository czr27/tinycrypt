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

ENTITY SKINNY_tk3_Hash_Test IS
END SKINNY_tk3_Hash_Test;
 
ARCHITECTURE behavior OF SKINNY_tk3_Hash_Test IS 
 
 
   COMPONENT SKINNY_tk3_Hash
	Port (  
		clk          : in  STD_LOGIC;
		rst      	 : in  STD_LOGIC;
		absorb		 : in  STD_LOGIC;
		gen      	 : in  std_logic;
		InitialMask  : in  STD_LOGIC_VECTOR (383       downto 0); -- Random initial Mask only used with rst = '1'
		Message1     : in  STD_LOGIC_VECTOR (127       downto 0); -- Message (share 1)
		Message2     : in  STD_LOGIC_VECTOR (127       downto 0); -- Message (share 2)
		Block_Size	 : in  STD_LOGIC_VECTOR (  3       downto 0); -- Size of the given block as Input (in BYTES) - 1
		Hash1        : out STD_LOGIC_VECTOR (255       downto 0); -- Hash (share 1)
		Hash2        : out STD_LOGIC_VECTOR (255       downto 0); -- Hash (share 2)
		done         : out STD_LOGIC);
	end COMPONENT;
    

   --Inputs
   signal clk 			: std_logic := '0';
   signal rst 			: std_logic := '0';
   signal InitialMask: std_logic_vector(383 downto 0) := (others => '0');
	signal absorb 		: std_logic := '0';
   signal gen		 	: std_logic := '0';
   signal Message1	: std_logic_vector(127 downto 0) := (others => '0');
   signal Message2	: std_logic_vector(127 downto 0) := (others => '0');
   signal Block_Size : std_logic_vector(  3 downto 0) := (others => '0');

 	--Outputs
   signal Hash1 		: std_logic_vector(255 downto 0);
   signal Hash2 		: std_logic_vector(255 downto 0);
   signal done 		: std_logic;

   signal Message		: std_logic_vector(127 downto 0) := (others => '0');
   signal Hash			: std_logic_vector(255 downto 0);
	
	signal Mask1		: std_logic_vector(127 downto 0);
	signal Mask2		: std_logic_vector(127 downto 0);
	signal Mask3		: std_logic_vector(127 downto 0);
	signal Mask4		: std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
 	type INT_ARRAY  is array (integer range <>) of integer range 0 to 255;
	type REAL_ARRAY is array (integer range <>) of real;
	type BYTE_ARRAY is array (integer range <>) of std_logic_vector(7 downto 0);

	signal r: INT_ARRAY (63 downto 0);
	signal m: BYTE_ARRAY(63 downto 0);

BEGIN
 
  	maskgen: process
		 variable seed1, seed2: positive;        -- seed values for random generator
		 variable rand: REAL_ARRAY(63 downto 0); -- random real-number value in range 0 to 1.0  
		 variable range_of_rand : real := 256.0; -- the range of random values created will be 0 to +255.
	begin
		 
		FOR i in 0 to 63 loop
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
		Mask4(i*8+7 downto i*8)	<= m(48+i);
	END GENERATE;

	---------
	
   uut: SKINNY_tk3_Hash
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

	InitialMask	<= Mask1 & Mask2 & Mask3;

	Message1		<= Message XOR Mask4;
	Message2		<= Mask4;

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

      if (Hash = x"15C81E6EB26ED692B51CF10A3FE186718C7AA6745CCEB7C82FF63F915F91E27B") then
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
      Message(8*16-1 downto 8*(15-0)) <= x"00";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"1EFD40A650A042DBEFEF8FD5552F70F52F5224036BFC5483CF1828A62B4C5D59") then
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
      Message(8*16-1 downto 8*(15-1)) <= x"0001";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"760BF1C2F83615FF57DF00BA05128B124A4DEA2CC096601130C534DC7571EACB") then
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
      Message(8*16-1 downto 8*(15-2)) <= x"000102";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3F5FF72381989FEED4F8F732DC5414FD9E8712CDD3C4D363A1C9E8A568E33EDE") then
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
      Message(8*16-1 downto 8*(15-3)) <= x"00010203";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"92AD1CB242B43F9A00F65FEB037ACA2DC98958CA0083D132C944C1FA85C36D8F") then
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
      Message(8*16-1 downto 8*(15-4)) <= x"0001020304";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"82275F7D73D518D17529C4C9BABEEAFF6FA893847FD4812F63953EC541D534A4") then
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
      Message(8*16-1 downto 8*(15-5)) <= x"000102030405";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9666827C1DEAB4F702866FDDBBC2123955DD3239C0A8D0B819236F86BEF6B1CF") then
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
      Message(8*16-1 downto 8*(15-6)) <= x"00010203040506";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"CAF9F4CBE060A8762157302310F9D99D70EE2BFBCA9096DF4715E97A023B7B6E") then
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
      Message(8*16-1 downto 8*(15-7)) <= x"0001020304050607";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"DD8B4EB746417A1DFE11DD84A75942AC509F3BB771EDA6ABE6AC20AC0AD6529D") then
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
      Message(8*16-1 downto 8*(15-8)) <= x"000102030405060708";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2B294407D1DFE292C5C7A9C814790E1B9E404487AAB4C02C0BAEBBF3C52A5FD1") then
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
      Message(8*16-1 downto 8*(15-9)) <= x"00010203040506070809";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4A81BF8D703A608277D77B62D5F772398B10165C6B1B28D685A8084F84C82F07") then
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
      Message(8*16-1 downto 8*(15-10)) <= x"000102030405060708090A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4D59F89509488F49A7A41064FAA090533D1026BE23E234AA0FDD719E7261E87A") then
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
      Message(8*16-1 downto 8*(15-11)) <= x"000102030405060708090A0B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D084DB85E4FE3B3BF7EA4D60756FD47E12923A69732763C004AF82B454E083C3") then
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
      Message(8*16-1 downto 8*(15-12)) <= x"000102030405060708090A0B0C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2ECAB36D89C0FB061610F23004CD2D2201DBC9DED28FC67E730B381D3506F88F") then
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
      Message(8*16-1 downto 8*(15-13)) <= x"000102030405060708090A0B0C0D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0EFB66CDC23679848112A8DB50DD3E94478607A8E6CEBE1638F44BF1D5A52F68") then
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
      Message(8*16-1 downto 8*(15-14)) <= x"000102030405060708090A0B0C0D0E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"DC4308BE923BDFB508DA956C20093B2B77EB8F25CE2569050C257677578143C0") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A09D8D868ADF68957378C500ADA9678A362897068D9AB00E9483196C318FD4FF") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"10";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E25E65B8FFF8AE140C4D335352039045C23259AC8841DB5E7BB90F1EF53ABE0A") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"1011";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2F928D72DC6E1EC9C326AB51CEC36370037B8FAADAD29F72FDA3E72E84E59D98") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"101112";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BC81B36DD0228A70A25A24E5CAEBC9C10B9CC81EED72DFF81F50BEA6DEC5E80F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"10111213";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"7792D8E0546CB4C6D5E017E546125624244D8826783485E13700DD6CA87F6587") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"1011121314";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E5147BFBECCBFFCF0B39E1661F66A0D34807AE22ADA7112E5E2F9521D68CA0E0") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"101112131415";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"32757E35E9968AE6775BC18B4F3007FB3AFFB0906F22EFA6EF4A5129480DD4D6") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"10111213141516";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0EE2A877DCEFC0BA2735BFF94B99B9E47A1925DE7AE998DCC12767C1494CA33E") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"1011121314151617";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"30D5C0E13BBE2D922A33D4CD52F23E3EA9F0FD5C53B08107F6630690784D1DB5") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"101112131415161718";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"CA8B33D9F5ABAF4BC4E1021BF1D2595AF7D702360B5CF39F2C41C1A32D49B3CD") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"10111213141516171819";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6B4D168DEBF0359B47B17284EA4F10C56DB925604A14210AE3C797A5A6140C18") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"101112131415161718191A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"930E432EBF0D97FA72942641BDFE47E7E14967DCB3DFF0FD9FAA25CF2751415E") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"101112131415161718191A1B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E176643DF1F2E13B91305E1A45E60BA1B17473A0BFA8279449C9FA54A2B137EB") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"101112131415161718191A1B1C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"536B7862B34ABEF8DAB8BC41A75B2A789D8FD12FD6B4BC15807418825D94CB87") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"101112131415161718191A1B1C1D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"58A351BA6C99725D89F7228C8EE0DBDD5F27D40EBC1E80E9D4604C2FC724B58D") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"101112131415161718191A1B1C1D1E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"852C81E1AAC7A3F7BC2815DFFC3AA89E045C140DF2B83AA9024AC331CB42879C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A784C0BC9D25EAA0B7F668D8AD65305F7B5129340FBE1A14FA8BF26F14F710DB") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"20";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C3A03DB5E25A9B9383A2A903C18C154C01E746F61F80CC91427FF071D417A2F5") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"2021";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C13B53B1E6ABBE02FEE637D295522BF6967672D763941AFD6C33B85EA1329675") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"202122";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9A3BED4F3CC362B1E02BB835237CD6372FC772C12A895EB6B6038F594B611C17") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"20212223";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6209A1A99CE9D706A8D026826F41C190EB08D24DF74BBBCB0E1A3FE76D37347F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"2021222324";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FDBBB386D070E2310D75B68135B5DBCD17360887B4F33167FA332C877F7CF805") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"202122232425";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"44833BA7814C59541AD0666F419BBECF5C515D44FA09D7ED0CF529BC7C82F50B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"20212223242526";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6D9A78C45685FDDA9AFEEE0C171FE05861BF2F29BF6CB359E868AE473206C2C3") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"2021222324252627";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FA6DEA5D430CBB207FE0020D41E0435E299E01DDF64DA6CCF4D4C032C0A11A8E") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"202122232425262728";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"5EF1811296FE71B838CBAAB7667DE04C77AE7727E7772688A189A664DFDF51B6") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"20212223242526272829";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"53A5CB24131BFFB9322C3F621EDC2C481CD82ECB950BBC2D7AF6D0BC8B44AD31") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"202122232425262728292A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D15A41FD8FECC93E3B48CA1BD54C59AF0548F7DB233AEB16F6151987265481F5") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"202122232425262728292A2B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"62CBF7EE9E24B26C0436A4A04BC30E04C118293A846A24267FEFA8B41295961A") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"202122232425262728292A2B2C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9EF89952B7F5880B022AEFF717BFE9237EFCA2064F7DE5E200E75182FFB2D0D2") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"202122232425262728292A2B2C2D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"292613D2882E7B3F6CE45C074087255EC43B0E96F84041530DA4EA24580F972E") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"202122232425262728292A2B2C2D2E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B806BB08C1186D88446A110B49F2BFBC8C8AA4D8433893A3D97EE7F21A911232") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"989ECC1D6573EB62CA827E774CD1C85F1D7FF5B64B2B625173C31FD0E9FE8CF2") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"30";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9F0B5B755272F4F244D8D346F08D8ED9F59019835213C5B17DAEC93D92BE711A") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"3031";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E812C8425AF53BE1E06812B2ED3859E0706C6AC7C01276378DAFFD615D8E37C6") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"303132";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A92EB634040AF1C807F2F5A8DF2E559F4168A7DF007218F89BCC018C4E02A270") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"30313233";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0A1EB1EC7A1B669EAE4B00F1213CDDA237A0F620C94C40F309B3F98F2E044363") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"3031323334";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"694CFB63FC8A97533F129F94F5103408C33C838DE006E93EF29028340173EFFA") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"303132333435";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2E42F721C4D84BF64194F71E0A5FB70F480A4C5464A91115891B72989D40B57E") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"30313233343536";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3ACE46BE82D2C9F12EDE8A09860916FFAFBF89AB3889EC9324281D71788C59FB") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"3031323334353637";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0EE9164A5A0645DCCC610E4CBB6FE4C99640592CFB13666E0CEC14E6FA4344A6") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"303132333435363738";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0C60459C70214DB14B99A180F586B3D7A0F2EDA0D577F5BA7977949CBE154CB3") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"30313233343536373839";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8B2011C770D71C6EAB0979896E2FD7A81B811686BF8E37CF3B1C85494BD85AB2") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"303132333435363738393A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"12638DB690105D5F0B5D3DFC2363C0CFE0E601CD713273385E93096998B6647C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"303132333435363738393A3B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BF8FCF2942FE8E75AE9CDF6F6722D3F14F05447329E31F0B140E5D3DD7A1028F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"303132333435363738393A3B3C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"A7713EC39F7567361F029A71FB0F0A5AD17FAE0A45E378912EBC9AECE42DAB65") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"303132333435363738393A3B3C3D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"25ECA8E8AAE853BE34C306C28F3C89305BC111BDB7C9C7B8E2ED0138107E288B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"303132333435363738393A3B3C3D3E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"30CD8757ED889286E95A823E454F89E17328349DDAD5A73134A6F28D442EAE7B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9363E1A0525915FED18B13DEA1C0994FB3F86B83508B97B73F0A1DD3DB19999F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"40";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"616903796E44D0E1C1ED8A6618DAC6E2E94DAB7EC077AA54C6021C5FFB1550FC") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"4041";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C69D895B98063130E19BBBC000E1BC73189B58D929F24576FE22188DA3312548") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"404142";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F05E5C3A30968E36BBCCDC2EEC5FF1E841E47D3D4450BFAA5AA091ECEC483E6C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"40414243";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3CB02673EEB97F2493B4ABA1593FE87E5FAA3C07AE9E7FFDA94530E02D623C6F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"4041424344";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"6B936E726ED9ECD3697C528622A9529B7DF055614ACD445D1890F8965D118051") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"404142434445";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0158BC07984A8187CE3832F604334AAA8402616155F629A0EFDA43CEEC9EE5FC") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"40414243444546";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"3F456FA1766C9AACA7234A8565C24E2D92DC6684E29E2F857674667BAA0B099C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"4041424344454647";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C41E861B83195B5E1F2FC9E23B42F823B3E4B764EF812E1B5459CDFC69F073D8") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"404142434445464748";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E635B830E0DAD2FB9ABD81EA9A730037E6A50F89969ADCB407D3D7D28477B275") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"40414243444546474849";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"10058F28B999FD86F28481DD849D01A4FD1D40C012676B52A8262A2EFA2FAC6F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"404142434445464748494A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BA946CBFF757FAA9503662036953C60FB6463AD426D513197A7348BE21A5EEC7") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"404142434445464748494A4B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4122F004AA892EB8B9A6E1D2728D3BBD28B69DCB36F0D8A63F5F718DCD9F7924") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"404142434445464748494A4B4C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"078A31D6D9DD8A09E71B3F3CC71A2F682CC1452805B2C21C31DD5DAA0145E733") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"404142434445464748494A4B4C4D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"260B133A65A3C7FB161F60B8AA5E9C7B51A1199016A51D463B6081AA8A4C633B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"404142434445464748494A4B4C4D4E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B6C6E46FC9B08C04AB9E4E8827AA3393ADEFCFF6C9BD49E0EA40C969095CBB4D") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D4931EF4BEB1F42F7F60B2F6FBBF179C222D234FCAB04D05918B281BE536E280") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"50";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"963A5DE8B0A1BEBD734B3ADB4D4B8BC29209E8899FD580753B6E93E1D90D1724") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"5051";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"88DAB38FA92B27BD7E7663389A6EAFEDE0A46063FD53A17F097E820D09A5FFC4") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"505152";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"53EAD6A0D89ED64491FEC30F79CD9DD62A24A2D1005038F66F9267DD602E5D28") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"50515253";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B0E396E7F8BF5EF055B0CAFCD25F23E0159F0C006B46397E065230A1B16514E1") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"5051525354";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D5BC4E35C31869387FDDE44025164D9433CAB3DC732002EB10DE6636DA07A81E") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"505152535455";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8A6063F35CCF6FE2AA730A2489C0C4B724747ACDE0FB05EA9E12F9EFA1AC9FAE") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"50515253545556";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"985F5BD61D93A920166396496C401DA3F8961DD26D2490110F955F2939896AF9") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"5051525354555657";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"CD16740D4E3A31B89CEC51A72EDCA22EB862C238A05672EAFEBA615274CF500A") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"505152535455565758";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"B11C32B484602C03E135D1931F12090765474B1FE07F0D9EB50C9349564ED231") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"50515253545556575859";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"FF28F726B823F3E6270A6CDC27A3885CB12F269FCFEA8CB77E9C9CABB4FEFDC1") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"505152535455565758595A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0A1E5D6E6E6DAEA3981E7B5AF35EFD9B5625E7FE7FA05F3F5EB79F66E765A06B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"505152535455565758595A5B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"1D2B8D8BFC5A63C762AD933538573DA406A2ED8C9C1806CF30859A153D1E8123") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"505152535455565758595A5B5C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"34C4CD3495920111AABE7F47C4B6EB6BA1DD48F8DB33EB47A51B1A8E4CF89D8C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"505152535455565758595A5B5C5D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"0B5371CD59F75741FA7D76F06B982808CA35859A929A366C9721EC7EDBEF6263") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"505152535455565758595A5B5C5D5E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"66597B968CFD1AB9918291CDD72F8648D7C0C7FF9862A2B6B943CE9BE128BC81") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C413446F7842C89BEE7A2A4F5EC8743E3DA9B9A340990EA046AF54CCAD8322DD") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"60";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C11C438A95A5CD279259A6843EC54322786B78407E0F3DB4A63D35AF26F18576") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"6061";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8F3F36F5F0685F3D372B69B9A17F56C925CC619EA59FE9DBC08AED66D39F2A06") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"606162";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"C5BBCEE6AA4F7AE0CFEC5AE52AACCDDD25F761AA98F75183CDADB96699ED9CA4") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"60616263";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"DA7198820FCDB485A5ED05DC026D845029D1E67AC0A1235AE8D196415C90662B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"6061626364";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"05FC01B5D41B622229DC5AB4FE73D23C44F97B507B65089C45A4B8D61AC3DE8B") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"606162636465";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"7BDD28D0E08AD257C5D304AD9B7ABB2C18209782DE7DCA51F88B491BEA5DDA4A") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"60616263646566";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"879B61CB8E0A59897842DBE2B5C64374870AC9CDEDC6BCDDAE0EE8CDCBDE74A3") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"6061626364656667";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"9BE33C54917C46FBC106D68EE4C9FA42051BB75776765EB0076B519F0C40D489") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"606162636465666768";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"34CC922E4A667E53A0535E98A0F7688A07D5CC407EDFE983DC6EF29F37F5C7BA") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"60616263646566676869";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"DA617A6B16FA7ACBB075DFE5890819796262DEEBB8E5664893F2A68DDE5BC9ED") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"606162636465666768696A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"22B47868D4708C3C724040FB007237A321BB0DA6CA59BAF7D1BFE6F48FE263B5") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"606162636465666768696A6B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"826FF1DC4BE1B0FDE14CB8575DE68A19323D4D1C7CCA608F69358C3B0C1BE05F") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"606162636465666768696A6B6C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"66513E2161DE3BA4D820BE6E574A7918BDFFF805997EAF24419616E90979BA23") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"606162636465666768696A6B6C6D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E74EB02C298F7C82FA170D808F14B7FCBD2417C6460A55C112FC82620F8422C0") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"606162636465666768696A6B6C6D6E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"40F9364D9FDAFC040C0478D81BA2A28A1CB4A4E34F31ABF21BF6DC6C74991373") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D9E854010B8DAAEE0F4B22EE2D989AF28103E293F5E389F523F8DD9E9BA58522") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-0)) <= x"70";
      Block_Size <= "0000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"F040278849C86DD3A6C57B1EA111FCF0D5960F770D59F92FC487BC28FD6052DA") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-1)) <= x"7071";
      Block_Size <= "0001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"2A42C1F3277916CA658981400566405C1FBEA243D59F6BF6A8067DFE131652B3") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-2)) <= x"707172";
      Block_Size <= "0010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"D7F9A7A6F4FBA0F930567CD431B80991A300AFA57A84FAB6A098915D843AD1F0") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-3)) <= x"70717273";
      Block_Size <= "0011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"E74E00C59B80DD12559E0CF62E18D1738F4C1B58F0A2A3CD3BB0B26CD6A5BD4C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-4)) <= x"7071727374";
      Block_Size <= "0100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"82EF571C9708BF758ADE792B89B4AE580B325047F192D09AB941D9626C1DB6BC") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-5)) <= x"707172737475";
      Block_Size <= "0101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"4486B45719D6EAC17A3E740A05020AC7AA4053C6F7129BEBD595C13874BE6AE7") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-6)) <= x"70717273747576";
      Block_Size <= "0110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"EE017D680D59BCC06486402F36F44B4F9B8724A71EE48CED40F251FF1209D747") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-7)) <= x"7071727374757677";
      Block_Size <= "0111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"7DDF84D568FD4F2EED34FA636C134B63CFD4BABC089EFE193597391668E5B177") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-8)) <= x"707172737475767778";
      Block_Size <= "1000";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"488ED451CB4294B621DF9BB4298B8DF493FF19887254B0B5DE501D48EB593846") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-9)) <= x"70717273747576777879";
      Block_Size <= "1001";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"AD2488E1930E2CBAF98D7583D67953A16E13DFF69ED2214052B5A91974A6C707") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-10)) <= x"707172737475767778797A";
      Block_Size <= "1010";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"65800B1C608BBCE0C29A69B16AF15BEE8FDABD50C2717C80CCE8A9DAFC995072") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-11)) <= x"707172737475767778797A7B";
      Block_Size <= "1011";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"259F06B6C048F2B7DB26790EF63DADD76385469881A4BC954A2E58E52C8889EE") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-12)) <= x"707172737475767778797A7B7C";
      Block_Size <= "1100";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"8DFDBA8DE0FF5F1523908A6E35A321C3097FF2EC0AF605ACA548798EF23AF5A5") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-13)) <= x"707172737475767778797A7B7C7D";
      Block_Size <= "1101";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"361638370597932C0599E0042031A3928D048ECB7B97246FAC3122A5D340FD5C") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-14)) <= x"707172737475767778797A7B7C7D7E";
      Block_Size <= "1110";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"BB7B7D2F295BB17613BD444AA78980BCEA98510F59A359607462C06AC2DAE9BB") then
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
      Message(8*16-1 downto 8*(15-15)) <= x"000102030405060708090A0B0C0D0E0F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"101112131415161718191A1B1C1D1E1F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"202122232425262728292A2B2C2D2E2F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"303132333435363738393A3B3C3D3E3F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"404142434445464748494A4B4C4D4E4F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"505152535455565758595A5B5C5D5E5F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"606162636465666768696A6B6C6D6E6F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      absorb <= '1';
      Message(8*16-1 downto 8*(15-15)) <= x"707172737475767778797A7B7C7D7E7F";
      Block_Size <= "1111";

      wait until done = '1';
      wait for clk_period*0.5;

      wait for clk_period * 1;
      absorb <= '0';
      wait for clk_period * 1;

      gen        <= '1';
      wait until done = '1';
      wait for clk_period*0.5;

      if (Hash = x"7EF15C7D1C021B56E2DA667698F2FCC1A838A78370DCAF7F362EC2957AA833BF") then
      	 report "--------- Passed --------";
      else
      	 report "********* Failed ********";
      end if;

      --=======================================================================================

      wait;
   end process;

END;
