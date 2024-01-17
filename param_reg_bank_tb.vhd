library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL; -- allows use of logarithms
----------- Code must fall into this parameter to stay within the margins ----------- |

entity param_reg_bank_tb is
-- empty entity for test bench
end param_reg_bank_tb;

architecture Behavioral of param_reg_bank_tb is
    --clock period
    constant clk_period : time := 10ns;
    --generics
    constant num_regs  : NATURAL := 8; -- 8 registers
    constant data_size : NATURAL := 16; -- 16-bits
    -- inputs
    signal clk, rst, wen : STD_LOGIC;
    -- wreg: register select/addressing vector thus log2 of number of registers
    signal wreg    : UNSIGNED(log2(num_regs)-1 downto 0); 
    -- mux select for data out A (read reg bank A)
    signal r_reg_A : UNSIGNED(log2(num_regs)-1 downto 0);
    -- mux select for data out B (read reg bank B)
    signal r_reg_B : UNSIGNED(log2(num_regs)-1 downto 0); 
    signal D_in    : STD_LOGIC_VECTOR (data_size -1 downto 0); -- Data input
    -- outputs
    signal D_out_A : STD_LOGIC_VECTOR (data_size -1 downto 0); -- Data output from mux A
    signal D_out_B : STD_LOGIC_VECTOR (data_size -1 downto 0); -- Data output from mux B
    
type test_vector is record
    -- log2(num_regs)-1 downto 0 = 3 bits
    wreg_TV, r_reg_A_TV, r_reg_B_TV : UNSIGNED (log2(num_regs)-1 downto 0); 
    -- data-size -1 downto 0 = 16 bits
    D_in_TV, D_out_A_TV, D_out_B_TV : STD_LOGIC_VECTOR (data_size-1 downto 0); 
end record;

type test_vector_array is array
    (NATURAL range<>) of test_vector;
    
constant test_vectors : test_vector_array := (
-- |----------inputs------------|----outputs----| 
-- wreg, r_reg_A, r_reg_B, D_in, D_out_A, D_out_B
----------- Code must fall into this parameter to stay within the margins ----------- |
    -- write 0 to all registers to clear Undefined
    (B"001",B"000",B"000",X"0000",X"0000",X"0000"), -- 0. : Zero to Reg1
    (B"010",B"000",B"001",X"0000",X"0000",X"0000"), -- 1. : Zero to Reg2
    (B"011",B"001",B"010",X"0000",X"0000",X"0000"), -- 2. : Zero to Reg3
    (B"100",B"010",B"011",X"0000",X"0000",X"0000"), -- 3. : Zero to Reg4
    (B"101",B"011",B"100",X"0000",X"0000",X"0000"), -- 4. : Zero to Reg5
    (B"110",B"100",B"101",X"0000",X"0000",X"0000"), -- 5. : Zero to Reg6
    (B"111",B"101",B"110",X"0000",X"0000",X"0000"), -- 6. : Zero to Reg7
    (B"000",B"110",B"111",X"FFFF",X"0000",X"0000"), -- 7. : Attempt to write to Reg0
    (B"000",B"000",B"000",X"0000",X"0000",X"0000"), -- 8. : Confirm no write to Reg0
    -- Test loop : Test data is only passed to enabled register for every register, 
    -- write a constant to all registers for error checking, CCCC in later loops = error
    (B"001",B"000",B"000",X"CCCC",X"0000",X"0000"), -- 9. Write CCCC to all regs
    (B"010",B"000",B"001",X"CCCC",X"0000",X"CCCC"), -- 10.
    (B"011",B"010",B"000",X"CCCC",X"CCCC",X"0000"), -- 11. 
    (B"100",B"000",B"011",X"CCCC",X"0000",X"CCCC"), -- 12. 
    (B"101",B"100",B"000",X"CCCC",X"CCCC",X"0000"), -- 13.
    (B"110",B"000",B"101",X"CCCC",X"0000",X"CCCC"), -- 14.
    (B"111",B"110",B"000",X"CCCC",X"CCCC",X"0000"), -- 15.
    (B"000",B"000",B"111",X"0000",X"0000",X"CCCC"), -- 16. All regs at CCCC
    -- wreg, r_reg_A, r_reg_B, D_in, D_out_A, D_out_B
    -- 17. write to reg2, readA reg1, readA reg0, Input FFFF, outA CCCC, outB 0000
    (B"010",B"001",B"000",X"FFFF",X"CCCC",X"0000"), -- 17.
    -- 18. write to reg3, readA reg2, readA reg1, Input FFF0, outA FFFF, outB CCCC
    (B"011",B"010",B"001",X"FFF0",X"FFFF",X"CCCC"), -- 18.
    -- 19. write to reg4, readA reg3, readA reg2, Input FF00, outA FFF0, outB FFFF
    (B"100",B"011",B"010",X"FF00",X"FFF0",X"FFFF"), -- 19.
    -- 20. write to reg5, readA reg4, readA reg3, Input F000, outA FFF0, outB FF00
    (B"101",B"011",B"100",X"F000",X"FFF0",X"FF00"), -- 20.
    -- 21. write to reg6, readA reg5, readA reg4, Input AABB, outA F000, outB FF00
    (B"110",B"101",B"100",X"AABB",X"F000",X"FF00"), -- 21.
    -- 22. write to reg7, readA reg6, readA reg5, Input BBAA, outA F000, outB AABB
    (B"111",B"101",B"110",X"BBAA",X"F000",X"AABB"), -- 22.
    -- 23. attempt to write to reg with write enabled disabled (wen disabled at i = 23)
    -- write to reg7, readA reg7, readA reg6, Input ABBA, outA BBAA, outB AABB
    (B"111",B"111",B"110",X"ABBA",X"BBAA",X"AABB"), -- 23.
    -- 24. confirm write to any reg with reg disabled
    (B"000",B"111",B"110",X"0000",X"BBAA",X"AABB"), -- 24.
    -- 25. Attemp a purposefully incorrect vector
    (B"000",B"111",B"110",X"0000",X"ABBA",X"ABBA"), -- 25.
    -- 26. Tidy up wave graph after final iteration
    (B"000",B"000",B"000",X"0000",X"0000",X"0000") -- 25.
    );
begin
UUT : entity work.param_reg_bank
        generic map ( data_size => data_size, -- configure generics
                      num_regs  => num_regs)
        port map ( clk => clk, -- configure ports
                   rst => rst,
                   wen => wen,
                   wreg => wreg,
                   r_reg_A => r_reg_A,
                   r_reg_B => r_reg_B,
                   D_in => D_in,
                   D_out_A => D_out_A,
                   D_out_B => D_out_B);
--clock process
clk_process : process
begin
   clk <= '0';
   wait for clk_period/2;
   clk <= '1';
   wait for clk_period/2;
end process;
-- TESTING STRATEGY lets test this mofo
   -- Test 1 :
--  Test Data in is not passed if 
TEST : process
begin
    wait for 100ns;-- global reset
    wait until falling_edge(clk);
    rst <= '1';
    wait for clk_period/2;
    rst <= '0';
    wait for clk_period/2;
    wen <= '0';
    wait for clk_period/2;
    wen <= '1';
    D_in <= X"0000";
    for i in 0 to 7 loop
        wreg <= to_unsigned(i, wreg'length);
        wait for clk_period*2;
    end loop;
    for i in test_vectors'range loop -- loop test vectors
        wait until falling_edge(clk);
        if i = 23 then
            wen <= '0';
        else wen <= '1';
        end if;
        wreg <= test_vectors(i).wreg_TV; -- assign vector values
        r_reg_A <= test_vectors(i).r_reg_A_TV;
        r_reg_B <= test_vectors(i).r_reg_B_TV;
        D_in <= test_vectors(i).D_in_TV;
--        wen <= '0';
        D_out_A <= test_vectors(i).D_out_A_TV;
        D_out_B <= test_vectors(i).D_out_B_TV;
        wait for clk_period*2; -- allow propergation
        -- assert correct operation
        assert ((D_out_A = test_vectors(i).D_out_A_TV)
            and (D_out_B = test_vectors(i).D_out_B_TV))
        report -- if output doesn't match expected output
            "Test sequence " &
             integer'image(i) &
             " failed {recieved/expected} : " &
             " wreg {"&
               integer'image(to_integer(unsigned(wreg))) &  
             "/"&
               integer'image(to_integer(unsigned(test_vectors(i).wreg_TV))) &                             
             "} data out A {"&
              integer'image(to_integer(unsigned(D_out_A))) &
             "/"&
              integer'image(to_integer(unsigned(test_vectors(i).D_out_A_TV))) &
             "}, data out B {"&
              integer'image(to_integer(unsigned(D_out_B))) &
             "/"&
              integer'image(to_integer(unsigned(test_vectors(i).D_out_B_TV)))&
             "}"
        severity error;
        -- assert failed operation (either or)
        assert ((D_out_A /= test_vectors(i).D_out_A_TV) 
            or (D_out_B /= test_vectors(i).D_out_B_TV))
        report -- if output does match expected output
            "Test sequence " &
             integer'image(i) &
              " passed." 
        severity note;
        end loop;
    wait for clk_period*5;
    rst <= '1'; -- set reset high forever to signal end of operations
    wait;

end process;

end Behavioral;
