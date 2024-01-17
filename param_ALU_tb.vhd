library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL; -- allows use of logarithms

entity param_ALU_tb is
--  testbench empty entity
end param_ALU_tb;

architecture Behavioral of param_ALU_tb is
    constant data_size : NATURAL := 16; -- minimum 3 bits as log2(2)-1 = 1-1, 0 downto 0 error
    signal A : STD_LOGIC_VECTOR (data_size -1 downto 0);
    signal B : STD_LOGIC_VECTOR (data_size -1 downto 0);
    signal opcode : STD_LOGIC_VECTOR (3 downto 0);
    signal SH : UNSIGNED (log2(data_size)-1 downto 0); -- shift address
    signal Output : STD_LOGIC_VECTOR (data_size -1 downto 0); -- ALU output of [data_size] bits
    signal flags : STD_LOGIC_VECTOR(7 downto 0); -- flags encoded in fixed 8-bit bus
    
    type test_vector is record
        A_TV : STD_LOGIC_VECTOR (data_size-1 downto 0); -- A_TV, Test Vector for signal A
        B_TV : STD_LOGIC_VECTOR (data_size-1 downto 0);
        opcode_TV : STD_LOGIC_VECTOR (3 downto 0);   
        SH_TV :  UNSIGNED (log2(data_size)-1 downto 0);
        Output_TV : STD_LOGIC_VECTOR (data_size -1 downto 0);
        flags_TV : STD_LOGIC_VECTOR(7 downto 0);
    end record;

type test_vector_array is array (NATURAL range <>) of test_vector;
        
constant test_vectors : test_vector_array := (
----------- Code must fall into this parameter to stay within the margins ----------- |
-- Test vectors use binary and hex representation due to margin restrictions
--  in the follow order:
-- input A , input B, opcode (hex), SH (hex), output, flags
    -- Shift left
    -- Shift Right
    -- Rotate Left
    -- Rotate Right
----------- Code must fall into this parameter to stay within the margins ----------- |

-- ALU_OUT <= A,  opcode b"0000" = X"0"
-- -ve, +ve
(b"1110011001101010",b"0000000000000000",X"0",X"0",b"1110011001101010",b"00101010"),--1
(b"0010111100101111",b"0000000000000000",X"0",X"0",b"0010111100101111",b"01010010"),--2
-- ALU_OUT <= A & B, opcode b"0000" = X"0"
-- +ve +ve,-ve -ve, +ve -ve, -ve +ve
(b"0000000000000000",b"0111101001000100",X"4",X"0",b"0000000000000000",b"01100001"),
(b"1000000000000000",b"1011111000101011",X"4",X"0",b"1000000000000000",b"00101010"),
(b"0000000000000001",b"1011010100111001",X"4",X"0",b"0000000000000001",b"01010110"),
(b"1000011000100001",b"0101100111110000",X"4",X"0",b"0000000000100000",b"01010010"),
--ALU_OUT <= A | B
-- +ve +ve, -- +ve -ve, -ve +ve, -ve -ve
(b"0000000000000000",b"0111111110011101",X"5",X"0",b"0111111110011101",b"01010010"),
(b"0111111111111111",b"1101110000110111",X"5",X"0",b"1111111111111111",b"00101010"),
(b"1000000000000000",b"0110100011000010",X"5",X"0",b"1110100011000010",b"00101010"),-- 
(b"1111110010100111",b"1110100011011111",X"5",X"0",b"1111110011111111",b"00101010"),-- 
--ALU_OUT <= A XOR B 
-- +ve +ve, -ve +ve, +ve -ve, -ve -ve
(b"0000000000000000",b"0101111110001011",X"6",X"0",b"0101111110001011",b"01010010"),-- 
(b"1000000000000000",b"0000000010101010",X"6",X"0",b"1000000010101010",b"00101010"),-- 
(b"0000000000000001",b"1111001101011100",X"6",X"0",b"1111001101011101",b"00101010"),-- 
(b"1101110010010010",b"1101111001111111",X"6",X"0",b"0000001011101101",b"01010010"),-- 
-- ALU_OUT <= NOT A 
-- -ve, +ve
(b"1110101011100010",b"0000000000000000",X"7",X"0",b"0001010100011101",b"01010010"),-- 
(b"0111111011111000",b"0000000000000000",X"7",X"0",b"1000000100000111",b"00101010"),-- 
-- ALU_OUT <= A+1
-- +ve, -ve
(b"0000001111000011",b"0000000000000000",X"8",X"0",b"0000001111000100",b"01010010"),-- 
(b"1111101100101010",b"0000000000000000",X"8",X"0",b"1111101100101011",b"00101010"),-- 
-- ALU_OUT <= A-1
-- -ve, +ve
(b"1101000100101100",b"0000000000000000",X"9",X"0",b"1101000100101011",b"00101010"),-- 
(b"0101100100011110",b"0000000000000000",X"9",X"0",b"0101100100011101",b"01010010"),-- 
-- ALU_OUT <= A+B
-- +ve -ve, -ve +ve, +ve +ve,  -ve -ve
(b"0111111111111111",b"1101000011101001",X"A",X"0",b"0101000011101000",b"01010010"),-- 
(b"1000000000000000",b"0111010110000111",X"A",X"0",b"1111010110000111",b"00101010"),-- 
(b"0100001010011010",b"0011000100001010",X"A",X"0",b"0111001110100100",b"01010010"),-- 
(b"1110100110010010",b"1110011011101011",X"A",X"0",b"1101000001111101",b"00101010"),--
-- ALU_OUT <= A-B
-- +ve +ve, -ve -ve, -ve +ve, +ve -ve
(b"0111111111111111",b"0010000101111110",X"B",X"0",b"0101111010000001",b"01010010"),-- 
(b"1011000001101111",b"1110001100010110",X"B",X"0",b"1100110101011001",b"00101010"),-- 
(b"1010101111000001",b"0110111101010111",X"B",X"0",b"0011110001101010",b"11010010"),-- 
(b"0000011011010001",b"1111011010101100",X"B",X"0",b"0001000000100101",b"01010010"),-- 
-- overflow flag tests
-- A+1
(b"0111111111111111",b"0000000000000000",b"1000",X"0", b"1000000000000000", b"10101010"),--72
-- A-1
(b"1000000000000000",b"0000000000000000",b"1001",X"0", b"0111111111111111", b"11010010"),--88
-- A+B
(b"0010010000100101",b"0110110011110101",b"1010",X"0", b"1001000100011010", b"10101010"),--107
(b"0101100110111110",b"0101001001011010",b"1010",X"0", b"1010110000011000", b"10101010"),--115
-- A-B
(b"1010101111000001",b"0110111101010111",b"1011",X"0", b"0011110001101010", b"11010010"),--122
(b"1000000011000111",b"0110101101100011",b"1011",X"0", b"0001010101100100", b"11010010"),--123
(b"0101010011110010",b"1011100101110001",b"1011",X"0", b"1001101110000001", b"10101010"),--129 -- 21746 - (-65,535+14,705)
(b"0101100110101011",b"1001000010100001",b"1011",X"0", b"1100100100001010", b"10101010"),--130
-- Shift Right
(b"1000000000000000", b"0000000000000000", x"D", x"0", b"1000000000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"1", b"1100000000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"2", b"1110000000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"3", b"1111000000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"4", b"1111100000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"5", b"1111110000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"6", b"1111111000000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"7", b"1111111100000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"8", b"1111111110000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"9", b"1111111111000000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"A", b"1111111111100000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"B", b"1111111111110000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"C", b"1111111111111000", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"D", b"1111111111111100", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"E", b"1111111111111110", b"00101010"),
(b"1000000000000000", b"0000000000000000", x"D", x"F", b"1111111111111111", b"00101010"),
-- Rotate Left
(b"1000000000000001", b"0000000000000000", x"E", x"2", b"0000000000000110", b"01010010"),
(b"1000000000000001", b"0000000000000000", x"E", x"1", b"0000000000000011", b"01010010"),
(b"1000000000000001", b"0000000000000000", x"E", x"0", b"1000000000000001", b"00101010"),
--Shift left
(b"0000100000000000", b"0000000000000000", x"C", x"1", b"0001000000000000", b"01010010"),
(b"0000100000000000", b"0000000000000000", x"C", x"2", b"0010000000000000", b"01010010"),
(b"0000100000000000", b"0000000000000000", x"C", x"3", b"0100000000000000", b"01010010"),
(b"0000100000000000", b"0000000000000000", x"C", x"4", b"1000000000000000", b"00101010"),
-- Rotate Right
(b"1000000000000001", b"0000000000000000", x"F", x"0", b"1000000000000001", b"00101010"),
(b"1000000000000001", b"0000000000000000", x"F", x"1", b"1100000000000000", b"00101010"),
(b"1000000000000001", b"0000000000000000", x"F", x"2", b"0110000000000000", b"01010010"),
(b"1000000000000001", b"0000000000000000", x"F", x"3", b"0011000000000000", b"01010010"),
-- intentionally wrong
(b"0000000000000010", b"0000000000000010", x"A", x"0", b"0000000000000101", b"01010010")

);
begin

UUT : entity work.param_ALU
        generic map ( size => data_size)
        port map ( A => A, -- configure ports
                   B => B,
                   opcode => opcode,
                   SH => SH,
                   Output => Output,
                   flags => flags);
tb: process 
begin
    wait for 100ns;
    
    for i in test_vectors'range loop -- loop test vectors
        A <= test_vectors(i).A_TV; -- assign vector values
        B <= test_vectors(i).B_TV;
        opcode <= test_vectors(i).opcode_TV;
        SH <= test_vectors(i).SH_TV;
        Output <= test_vectors(i).Output_TV;
        flags <= test_vectors(i).flags_TV;
        wait for 20ns; -- allow propergation
        -- assert correct operation
        assert ((Output = test_vectors(i).Output_TV)
            and (flags = test_vectors(i).flags_TV))
        report -- if output doesn't match expected output
            "Test sequence " &
             integer'image(i+1) &
             " failed : " &
             " A is "&
             integer'image(to_integer(signed(A))) &
             " B is "&
             integer'image(to_integer(signed(B))) &
             ", opcode "&
             integer'image(to_integer(unsigned(opcode)))&
             ", ALU_output : "&
              integer'image(to_integer(signed(Output))) &
             ", expected : "&
              integer'image(to_integer(signed(test_vectors(i).Output_TV)))&
              ", ALU_flags : "&
              std_logic'image(((flags(7))))&
              std_logic'image(((flags(6))))&
              std_logic'image(((flags(5))))&
              std_logic'image(((flags(4))))&
              std_logic'image(((flags(3))))&
              std_logic'image(((flags(2))))&
              std_logic'image(((flags(1))))&
              std_logic'image(((flags(0))))&
              " exp : " &
              std_logic'image(((test_vectors(i).flags_TV(7))))&
              std_logic'image(((test_vectors(i).flags_TV(6))))&
              std_logic'image(((test_vectors(i).flags_TV(5))))&
              std_logic'image(((test_vectors(i).flags_TV(4))))&
              std_logic'image(((test_vectors(i).flags_TV(3))))&
              std_logic'image(((test_vectors(i).flags_TV(2))))&
              std_logic'image(((test_vectors(i).flags_TV(1))))&
              std_logic'image(((test_vectors(i).flags_TV(0))))
        severity warning;
        assert((Output /= test_vectors(i).Output_TV)
                or (flags /= test_vectors(i).flags_TV))
        report -- if output doesn't match expected output
            "Test sequence " &
             integer'image(i+1) &
             " passed" --&
             --" A : "&
             --integer'image(to_integer(signed(A))) &
             --" B : "&
             --integer'image(to_integer(signed(B))) &
             --", opcode "&
             --integer'image(to_integer(unsigned(opcode)))&
             --", ALU_output : "&
             -- integer'image(to_integer(signed(Output))) &
             --", expected : "&
             -- integer'image(to_integer(signed(test_vectors(i).Output_TV)))&
             -- ", ALU_flags : "&
             -- std_logic'image(((flags(7))))&
             -- std_logic'image(((flags(6))))&
             -- std_logic'image(((flags(5))))&
             ---- std_logic'image(((flags(4))))&
             ---- std_logic'image(((flags(3))))&
            --  std_logic'image(((flags(2))))&
            --  std_logic'image(((flags(1))))&
             -- std_logic'image(((flags(0))))&
             -- " exp : " &
             -- std_logic'image(((test_vectors(i).flags_TV(7))))&
             -- std_logic'image(((test_vectors(i).flags_TV(6))))&
             -- std_logic'image(((test_vectors(i).flags_TV(5))))&
             -- std_logic'image(((test_vectors(i).flags_TV(4))))&
             -- std_logic'image(((test_vectors(i).flags_TV(3))))&
             -- std_logic'image(((test_vectors(i).flags_TV(2))))&
             -- std_logic'image(((test_vectors(i).flags_TV(1))))&
             -- std_logic'image(((test_vectors(i).flags_TV(0))))
        severity note;
        end loop;
    wait;
end process;
end Behavioral;
