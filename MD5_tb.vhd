--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:41:18 12/15/2016
-- Design Name:   
-- Module Name:   /home/sebastian/Dropbox/Studia/Semestr V/VHDL/MD5/MD5_tb.vhd
-- Project Name:  MD5
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: MD5
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.textio.all;
USE ieee.std_logic_textio.all;
use IEEE.NUMERIC_STD.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY MD5_tb IS
END MD5_tb;
 
ARCHITECTURE behavior OF MD5_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT MD5
    PORT(
         data_in : IN  std_logic_vector(31 downto 0);
         data_out : OUT  std_logic_vector(31 downto 0);
         req_data : OUT  std_logic;
         done : OUT  std_logic;
         err:         out STD_LOGIC;
         start:       in  STD_LOGIC;
         clk : IN  std_logic;
         reset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal data_in : std_logic_vector(31 downto 0) := (others => '0');
   signal start : std_logic := '0';
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal data_out : std_logic_vector(31 downto 0);
   signal req_data : std_logic;
   signal done : std_logic;
   signal err : std_logic;

   -- Clock period definitions
   constant clk_period : time := 5 ns;

   -- Input file
   type msg_t is array(0 to 15) of std_logic_vector(31 downto 0);

   --impure function read_file(file_name : in string) return msg_t is
   -- file test_file : text is in file_name;
   -- variable file_line : line;
   -- variable temp : std_logic_vector(399 downto 0);
   -- variable result : msg_t := (others => (others => '0'));
   --begin
   --    readline(test_file, file_line);
   --    read(file_line, temp);

   --    result(0) := temp(63 downto 32);
   --    result(1) := temp(31 downto 0);
   --    return result;
   --end function;

   --signal message : msg_t := read_file("/home/sebastian/programming/md5/test.bin");
   signal message : msg_t := (X"24cda8da", X"aed64a2e", X"312f765a", X"b90c9791",
                              X"fd32d9d0", X"615206cb", X"5b0e5045", X"dbb5f6af",
                              X"f4310a8e", X"58468968", X"c3b8c9aa", X"24db1a8d",
                              X"aec70000", X"00000000", X"00000000", X"00000000");

   --signal message : msg_t := (X"daa8cd24", X"2e4ad6ae", X"5a762f31", X"91970cb9",
   --                           X"d0d932fd", X"cb065261", X"45500e5b", X"aff6b5db",
   --                           X"8e0a31f4", X"68894658", X"aac9b8c3", X"8d1adb24",
   --                           X"0080c7ae", X"00000000", X"00000190", X"00000000");

    signal message_length : std_logic_vector(31 downto 0) := (others => '0');
    signal hash : std_logic_vector(0 to 127) := (others => '0');
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: MD5 PORT MAP (
          data_in => data_in,
          data_out => data_out,
          req_data => req_data,
          done => done,
          err => err,
          start => start,
          clk => clk,
          reset => reset
        );

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
       reset <= '1';
       wait for clk_period;
       reset <= '0';
       message_length <= std_logic_vector(to_unsigned(400, message_length'length));
       start <= '1';
       wait for 0.4*clk_period;
       -- load input message length
       data_in <= message_length;
       wait for 2*clk_period;
       start <= '0';
       -- load input message
       for i in 0 to 15 loop
           data_in <= message(i);
           wait for clk_period;
       end loop;

       -- calculate MD5 hash
       wait for 140*clk_period;
       start <= '1';
       wait for clk_period;
       start <= '0';
       wait for clk_period;
       -- store hash
       for i in 0 to 3 loop
           hash(32*i to 32*i+31) <= data_out;
           wait for clk_period;
       end loop;
       -- done
       wait for 10*clk_period;

      assert false severity failure;
   end process;

END;
