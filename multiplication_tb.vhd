library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity multiplication_tb is
--  Port ( );
end multiplication_tb;

architecture Behavioral of multiplication_tb is
--clock period
constant clk_period : time := 10ns;
constant size     : NATURAL := 16;
constant num_regs : NATURAL := 8;
signal CLK, RST, START:  STD_LOGIC;-- clock, reset, write enable, mux select
signal A:  STD_LOGIC_VECTOR(size-1 downto 0);
signal B:  STD_LOGIC_VECTOR(size-1 downto 0);
signal PROC_OUT :  STD_LOGIC_VECTOR(size-1 downto 0);
begin

UUT: entity work.param_single_cycle_processor 
    generic map ( size => size,
    num_regs => num_regs)
    Port map (CLK => CLK,
             RST => RST,
             START=>START, 
             PROC_OUT =>PROC_OUT,
             A=>A,
             B=>B); 
--clock process
clk_process : process
begin
   clk <= '0';
   wait for clk_period/2;
   clk <= '1';
   wait for clk_period/2;
end process;

tb: process
begin 
    wait for 100 ns;
    rst<='1';
    wait for clk_period;
    rst<='0';
    A<=X"0005";
    B<=X"000A";
    START <='1';
    wait for clk_period;
    START<='0';
    wait;
end process;

end Behavioral;
