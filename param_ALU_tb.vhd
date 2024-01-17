library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL; -- allows use of logarithms
entity param_ALU_tb is
-- empty entity for testbench
end param_ALU_tb;
architecture Behavioral of param_ALU_tb is
    constant data_size : NATURAL := 16; -- minimum 3 bits as log2(2)-1 = 1-1
    signal A : STD_LOGIC_VECTOR(data_size-1 downto 0); -- input vector of [date_size]
    signal B : STD_LOGIC_VECTOR(data_size-1 downto 0); -- input vector of [date_size]
    signal opcode : STD_LOGIC_VECTOR(3 downto 0); -- fixed size
    signal SH : UNSIGNED(log2(data_size)-1 downto 0); -- controls number of shift 
    signal Output : STD_LOGIC_VECTOR(data_size-1 downto 0); -- ALU output of [data_size]
    signal flags : STD_LOGIC_VECTOR(7 downto 0); -- flags encoded in fixed 8-bit bus
    -- test vector declaration
    type test_vector is record
        A_TV : STD_LOGIC_VECTOR(data_size-1 downto 0); -- A_TV, Test Vector for input A
        B_TV : STD_LOGIC_VECTOR(data_size-1 downto 0); -- Test vector for input B, etc.
        opcode_TV : STD_LOGIC_VECTOR(3 downto 0);   
        SH_TV :  UNSIGNED(log2(data_size)-1 downto 0);
        Output_TV : STD_LOGIC_VECTOR(data_size -1 downto 0);
        flags_TV : STD_LOGIC_VECTOR(7 downto 0);
    end record;
type test_vector_array is array (NATURAL range <>) of test_vector;
constant test_vectors : test_vector_array := (
-- Test vectors use a mixture of binary and hex representation, and do not include a 
--  usual indent due to margin restrictions.
-- ALU_OUT <= A,  opcode b"0000" = X"0"
-- 1. -ve, 2. +ve
(b"1110011001101010",b"0000000000000000",X"0",X"0",b"1110011001101010",b"00101010"),--1
(b"0010111100101111",b"0000000000000000",X"0",X"0",b"0010111100101111",b"01010010"),--2
-- ALU_OUT <= A & B, opcode b"0000" = X"0"
-- 3. +ve +ve, 4. -ve -ve, 5. +ve -ve, 6. -ve +ve
(b"0000000000000000",b"0111101001000100",X"4",X"0",b"0000000000000000",b"01100001"),--3
(b"1000000000000000",b"1011111000101011",X"4",X"0",b"1000000000000000",b"00101010"),--4
(b"0000000000000001",b"1011010100111001",X"4",X"0",b"0000000000000001",b"01010110"),--5
(b"1000011000100001",b"0101100111110000",X"4",X"0",b"0000000000100000",b"01010010"),--6
--ALU_OUT <= A | B
-- 7. +ve +ve, 8. +ve -ve, 9. -ve +ve, 10. -ve -ve
(b"0000000000000000",b"0111111110011101",X"5",X"0",b"0111111110011101",b"01010010"),--7
(b"0111111111111111",b"1101110000110111",X"5",X"0",b"1111111111111111",b"00101010"),--8
(b"1000000000000000",b"0110100011000010",X"5",X"0",b"1110100011000010",b"00101010"),--9
(b"1111110010100111",b"1110100011011111",X"5",X"0",b"1111110011111111",b"00101010"),--10
--ALU_OUT <= A XOR B 
-- 11. +ve +ve, 12. -ve +ve, 13. +ve -ve, 14. -ve -ve
(b"0000000000000000",b"0101111110001011",X"6",X"0",b"0101111110001011",b"01010010"),--11
(b"1000000000000000",b"0000000010101010",X"6",X"0",b"1000000010101010",b"00101010"),--12
(b"0000000000000001",b"1111001101011100",X"6",X"0",b"1111001101011101",b"00101010"),--13
(b"1101110010010010",b"1101111001111111",X"6",X"0",b"0000001011101101",b"01010010"),--14
-- ALU_OUT <= NOT A 
-- -15. ve, 16. +ve
(b"1110101011100010",b"0000000000000000",X"7",X"0",b"0001010100011101",b"01010010"),--15
(b"0111111011111000",b"0000000000000000",X"7",X"0",b"1000000100000111",b"00101010"),--16
-- ALU_OUT <= A+1
-- 17. +ve, 18. -ve
(b"0000001111000011",b"0000000000000000",X"8",X"0",b"0000001111000100",b"01010010"),--17
(b"1111101100101010",b"0000000000000000",X"8",X"0",b"1111101100101011",b"00101010"),--18
-- ALU_OUT <= A-1
-- 19. -ve, 20. +ve
(b"1101000100101100",b"0000000000000000",X"9",X"0",b"1101000100101011",b"00101010"),--19
(b"0101100100011110",b"0000000000000000",X"9",X"0",b"0101100100011101",b"01010010"),--20
-- ALU_OUT <= A+B
-- 21. +ve -ve, 22. -ve +ve, 23. +ve +ve, 24. -ve -ve
(b"0111111111111111",b"1101000011101001",X"A",X"0",b"0101000011101000",b"01010010"),--21
(b"1000000000000000",b"0111010110000111",X"A",X"0",b"1111010110000111",b"00101010"),--22
(b"0100001010011010",b"0011000100001010",X"A",X"0",b"0111001110100100",b"01010010"),--23
(b"1110100110010010",b"1110011011101011",X"A",X"0",b"1101000001111101",b"00101010"),--24
-- ALU_OUT <= A-B
-- 25. +ve +ve, 26. -ve -ve, 27. -ve +ve, 28. +ve -ve
(b"0111111111111111",b"0010000101111110",X"B",X"0",b"0101111010000001",b"01010010"),--25
(b"1011000001101111",b"1110001100010110",X"B",X"0",b"1100110101011001",b"00101010"),--26
(b"1010101111000001",b"0110111101010111",X"B",X"0",b"0011110001101010",b"11010010"),--27
(b"0000011011010001",b"1111011010101100",X"B",X"0",b"0001000000100101",b"01010010"),--28
-- overflow flag tests
-- A+1 : Addition
-- 29. flag case 1 : +ve + +ve = -ve
(b"0111111111111111",b"0000000000000000",X"8",X"0",b"1000000000000000",b"10101010"),--29
-- A-1 : Subtraction
-- 30. flag case 3 : -ve - +ve = +ve
(b"1000000000000000",b"0000000000000000",X"9",X"0",b"0111111111111111",b"11010010"),--30
-- A+B : Addition
-- 31, 32. flag case 1 : +ve + +ve = -ve
(b"0010010000100101",b"0110110011110101",X"A",X"0",b"1001000100011010",b"10101010"),--31
(b"0101100110111110",b"0101001001011010",X"A",X"0",b"1010110000011000",b"10101010"),--32
-- A-B : Subtraction
-- 33, 34. flag case 3 : -ve - +ve = +ve, 35,36. flag case 4 : +ve - -ve = -ve
(b"1010101111000001",b"0110111101010111",X"B",X"0",b"0011110001101010",b"11010010"),--33
(b"1000000011000111",b"0110101101100011",X"B",X"0",b"0001010101100100",b"11010010"),--34
(b"0101010011110010",b"1011100101110001",X"B",X"0",b"1001101110000001",b"10101010"),--35
(b"0101100110101011",b"1001000010100001",X"B",X"0",b"1100100100001010",b"10101010"),--36
-- end of overflow testing
--Shift left
(b"0000100000000000",b"0000000000000000",X"C",X"1",b"0001000000000000",b"01010010"),--37
(b"0101000000000000",b"0000000000000000",X"C",X"3",b"0100000000000000",b"01010010"),--37
(b"0000100000000000",b"0000000000000000",X"C",X"4",b"1000000000000000",b"00101010"),--39
-- Shift Right
(b"1000000000000000",b"0000000000000000",X"D",X"0",b"1000000000000000",b"00101010"),--40
(b"1000000000100000",b"0000000000000000",X"D",X"A",b"1111111111100000",b"00101010"),--41
(b"1000000000000000",b"0000000000000000",X"D",X"F",b"1111111111111111",b"00101010"),--42
-- Rotate Left
(b"1000000000000001",b"0000000000000000",X"E",X"2",b"0000000000000110",b"01010010"),--43
(b"1000000000000001",b"0000000000000000",X"E",X"1",b"0000000000000011",b"01010010"),--44
(b"1000000000000001",b"0000000000000000",X"E",X"0",b"1000000000000001",b"00101010"),--45
-- Rotate Right
(b"1000000000000001",b"0000000000000000",X"F",X"1",b"1100000000000000",b"00101010"),--46
(b"1000000000000001",b"0000000000000000",X"F",X"2",b"0110000000000000",b"01010010"),--47
(b"1000000000000001",b"0000000000000000",X"F",X"3",b"0011000000000000",b"01010010"),--48
-- intentionally wrong: 2 + 2 = 5
(b"0000000000000010",b"0000000000000010",X"A",X"0",b"0000000000000101",b"01010010")--49
);
-- The function coverts the opcode from STD_LOGIC_VECTOR to the String 
-- name of operation for convinience when printing out the test results. 
function opcode_to_operation(opcode: STD_LOGIC_VECTOR (3 downto 0))
return String is variable operation : String(1 to 20);
begin
    if opcode = "0000" then
        return "A";
    elsif opcode = "0100" then
        return "AND";
    elsif opcode = "0101" then
        return "OR";
    elsif opcode = "0110" then
        return "XOR";
    elsif opcode = "0111" then
        return "NOT A";
    elsif opcode = "1000" then
        return "A+1";
    elsif opcode = "1001" then
        return "A-1";
    elsif opcode = "1010" then
        return "A+B";
    elsif opcode = "1011" then
        return "A-B";
    elsif opcode = "1100" then
        return "Shift left";
    elsif opcode = "1101" then
        return "Shift right";
    elsif opcode = "1110" then
        return "Rotate left";
    elsif opcode = "1111" then
        return "Rotate right";
    else
        return "OPCODE ERROR";
    end if;
end function;
begin
UUT : entity work.param_ALU
        generic map ( data_size => data_size)
        port map ( A => A, -- configure ports
                   B => B,
                   opcode => opcode,
                   SH => SH,
                   Output => Output,
                   flags => flags);
-- TESTING STRATEGY -- 
-- This testbench aims to verify the operation of a parameterizable ALU by using test
--  vectors to test every type of operation of varying combinations of positive and 
--  negavtive input pairs and also the overflow flag cases. There is no clock process
--  in this testbench so there is no sync to falling edge or waits dependent on period.
TEST: process 
begin
    wait for 100ns; -- global reset
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
             " A is "& integer'image(to_integer(signed(A))) &
             " B is "& integer'image(to_integer(signed(B))) &
             ", opcode "& integer'image(to_integer(unsigned(opcode)))&
             ", ALU_output : "& integer'image(to_integer(signed(Output))) &
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
              " expected : " &
              std_logic'image(((test_vectors(i).flags_TV(7))))&
              std_logic'image(((test_vectors(i).flags_TV(6))))&
              std_logic'image(((test_vectors(i).flags_TV(5))))&
              std_logic'image(((test_vectors(i).flags_TV(4))))&
              std_logic'image(((test_vectors(i).flags_TV(3))))&
              std_logic'image(((test_vectors(i).flags_TV(2))))&
              std_logic'image(((test_vectors(i).flags_TV(1))))&
              std_logic'image(((test_vectors(i).flags_TV(0))))
        severity warning;
        -- assert failed operation
        assert((Output /= test_vectors(i).Output_TV)
                or (flags /= test_vectors(i).flags_TV))
        report -- if output doesn't match expected output
            "Test sequence " &
             integer'image(i+1) &
             " passed" & 
             " operation: " & opcode_to_operation(opcode)
        severity note;
        end loop;
    wait;
end process;
end Behavioral;
