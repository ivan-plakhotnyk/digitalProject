library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all; -- allows use of logrithms
-- This entity describes a parameterizable ALU capable of taking two input vectors A 
--  and B and performing certain arthimetic, logic and shifting operations (13 total),
--  producing an output vector of the same size with 8 different flag possibilities.
entity param_ALU is
    generic (data_size : NATURAL := 32); -- parameterizable bit width
    Port ( A : in STD_LOGIC_VECTOR(data_size -1 downto 0); -- input A of [data_size]
           B : in STD_LOGIC_VECTOR(data_size -1 downto 0); -- input B of [data_size]
           opcode : in STD_LOGIC_VECTOR(3 downto 0); -- log2(13) => 4 bit addressing
           SH : in UNSIGNED(log2(data_size)-1 downto 0); -- shift addressing
           Output : out STD_LOGIC_VECTOR(data_size -1 downto 0); -- ALU out [data_size]
           flags : out STD_LOGIC_VECTOR(7 downto 0)); -- 1 bit per flag (fixed 8-bit)
end param_ALU;
architecture Behavioral of param_ALU is
    -- internal signal for computation
    signal int_compute : SIGNED (data_size-1 downto 0); 
begin
-- opcode configuration
int_compute <=  SIGNED(A)       when opcode = "0000" else -- A
                SIGNED(A AND B) when opcode = "0100" else -- A AND B
                SIGNED(A OR B)  when opcode = "0101" else -- A OR B
                SIGNED(A XOR B) when opcode = "0110" else -- A XOR B
                SIGNED(NOT A)   when opcode = "0111" else -- !A
                SIGNED(A) + 1 when opcode = "1000" else -- A + 1
                SIGNED(A) - 1 when opcode = "1001" else -- A -1
                SIGNED(A) + SIGNED(B) when opcode = "1010" else -- A + B
                SIGNED(A) - SIGNED(B) when opcode = "1011" else -- A - B
                -- shift left [SH] bits :
                SHIFT_LEFT(SIGNED(A), to_integer(SH))   when opcode = "1100" else 
                -- shift right [SH] bits :
                SHIFT_RIGHT(SIGNED(A), to_integer(SH))  when opcode = "1101" else 
                -- shift left [SH] bits : 
                ROTATE_LEFT(SIGNED(A), to_integer(SH))  when opcode = "1110" else 
                -- shift left [SH] bits :
                ROTATE_RIGHT(SIGNED(A), to_integer(SH)) when opcode = "1111" else 
                (others => '0'); -- catch all
-- flag configurations 
--  each bit of flag vector represents output characteristic and the flag vector can 
--  have multiple active bits e.g. output could be non-zero, =1 (unity), and greater
--  than zero : 01010110
flags(0) <= '1' when int_compute = 0  else '0'; -- zero flag
flags(1) <= '1' when int_compute /= 0 else '0'; -- not-zero flag
flags(2) <= '1' when int_compute = 1  else '0'; -- unity flag
flags(3) <= '1' when int_compute < 0  else '0'; -- less than zero flag
flags(4) <= '1' when int_compute > 0  else '0'; -- greater than zero flag
flags(5) <= '1' when int_compute <= 0 else '0'; -- less than or equal to zero flag
flags(6) <= '1' when int_compute >= 0 else '0'; -- greater than or equal to zero flag
-- 6 possible cases for overflow flag (flags(7))
flags(7) <= --Addition
            '1' when opcode = "1010" and (SIGNED(A) > 0) -- 1. +ve + ve = -ve
                and (SIGNED(B) > 0) and (int_compute < 0) else
            '1' when opcode = "1010" and (SIGNED(A) < 0) -- 2. -ve + -ve = +ve
                and (SIGNED(B) < 0) and (int_compute > 0) else
            --Subtraction
            '1' when opcode = "1011" and (SIGNED(A) < 0) -- 3. -ve - +ve = +ve
                and (SIGNED(B) > 0) and (int_compute > 0) else
            '1' when opcode = "1011" and (SIGNED(A) > 0) -- 4.
                and (SIGNED(B) < 0) and (int_compute < 0) else
            -- A + 1
            '1' when opcode = "1000" and (SIGNED(A) > 0) -- 5. -- A + 1 < A
                and (int_compute < 0) else
            -- A - 1
            '1' when opcode = "1001" and (SIGNED(A) < 0) -- 6. -- A - 1 > A
                and (int_compute > 0) else
            '0'; -- catch the rest
Output <= STD_LOGIC_VECTOR(int_compute); -- cast computation to logic vector for output
end Behavioral;
