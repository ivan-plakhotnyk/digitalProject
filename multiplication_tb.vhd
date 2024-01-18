library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity multiplication_tb is
-- empty entity for testbench
end multiplication_tb;
architecture Behavioral of multiplication_tb is
    constant clk_period : time := 10ns; -- clock period
    constant data_size : NATURAL := 16; -- data size of [size] bits
    constant num_regs  : NATURAL := 8; -- number of registers
    signal CLK, RST, START: STD_LOGIC;-- clock, reset, write enable, mux select
    signal A: STD_LOGIC_VECTOR(data_size-1 downto 0); -- input A(128 to 255 for unsigned)
    signal B: STD_LOGIC_VECTOR(data_size-1 downto 0); -- input B(128 to 255 for unsigned)
    signal PROC_OUT : STD_LOGIC_VECTOR(data_size-1 downto 0); -- output of processor
begin
UUT: entity work.param_single_cycle_processor 
    generic map ( data_size => data_size,
                  num_regs => num_regs)
    Port map (CLK => CLK,
              RST => RST,
              START => START, 
              PROC_OUT => PROC_OUT,
              A => A,
              B => B); 
--clock process
clk_process : process
begin
   clk <= '0';
   wait for clk_period/2;
   clk <= '1';
   wait for clk_period/2;
end process;
-- TESTING STRATEGY -- 
-- Testbench aims to test the operation of the processor by passing it two vectors
--  whilst observing the output in decimal and checking the major operations such as
--  correct reseting as follows:
--  0. Global reset, sync to falling edge, system reset
--  1. Test correct operation in full
--  2. Test mid process reset
--  4. Test delayed-start
-- note: min and max transition time is based on FSM skipping or including additional 
--  steps and assumes 80h (128) goes through the least additional steps and FFh (255)
--  goes through the most additional steps ( min : 355ns and max : 435ns (in sim)
TEST: process
begin 
    wait for 100 ns; -- global reset
    wait until falling_edge(clk); -- sync to falling edge
    rst<='1'; -- system reset
    wait for clk_period;
    rst<='0';
    wait for clk_period;
    -- Test 1. Test full operation 
    A<=X"0080"; --  load A (from 128)
    B<=X"00FF"; --  load B (to 255)
    START <='1'; -- initiate FSM
    wait for clk_period;
    START<='0';
    wait for clk_period*45; -- wait for max possible transition time (435ns)
    rst<='1';
    wait for clk_period;
    rst<='0';
    -- Test 2. Mid-process reset
    A<=X"008F"; --  load A
    B<=X"00F8"; --  load B
    START <='1'; -- initiate FSM
    wait for clk_period;
    START<='0';
    wait for clk_period*20; -- wait for max possible transition time (435ns)
    rst<='1'; -- mid-process reset
    wait for clk_period;
    rst<='0';
    -- Test 3. Test delayed-start
    A<=X"00FF"; --  load A
    B<=X"00FF"; --  load B
    wait for clk_period*5; -- wait a bit
    START<='1';
    wait for clk_period;
    START<='0';
    wait for clk_period*45;
    rst <='1'; -- end on reset high 
    wait;
end process;

end Behavioral;
