library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;


entity param_ALU is
    generic (data_size : NATURAL := 32); -- only one generic allowed
    Port ( A : in STD_LOGIC_VECTOR (data_size -1 downto 0); -- input A of [data_size] bits
           B : in STD_LOGIC_VECTOR (data_size -1 downto 0); -- input B of [data_size] bits
           opcode : in STD_LOGIC_VECTOR (3 downto 0); -- the number of operations for the ALU is const (13) and thus requires 4 bits
           SH : in UNSIGNED (log2(data_size)-1 downto 0); -- shift address
           Output : out STD_LOGIC_VECTOR (data_size -1 downto 0); -- ALU output of [data_size] bits
           flags : out STD_LOGIC_VECTOR(7 downto 0) -- flags encoded in fixed 8-bit bus
    );
end param_ALU;


architecture Behavioral of param_ALU is
    signal int_compute : SIGNED (data_size -1 downto 0);


begin


int_compute <=  SIGNED(A)       when opcode = "0000" else -- A
                SIGNED(A AND B) when opcode = "0100" else -- A AND B
                SIGNED(A OR B)  when opcode = "0101" else -- A OR B
                SIGNED(A XOR B) when opcode = "0110" else -- A XOR B
                SIGNED(NOT A)   when opcode = "0111" else -- !A
                SIGNED(A) + "1" when opcode = "1000" else -- A + 1
                SIGNED(A) - "1" when opcode = "1001" else -- A -1
                SIGNED(A) + SIGNED(B) when opcode = "1010" else -- A + B
                SIGNED(A) - SIGNED(B) when opcode = "1011" else -- A - B
                SHIFT_LEFT(SIGNED(A), to_integer(SH))   when opcode = "1100" else -- shift left [SH] bits
                SHIFT_RIGHT(SIGNED(A), to_integer(SH))  when opcode = "1101" else -- shift right [SH] bits
                ROTATE_LEFT(SIGNED(A), to_integer(SH))  when opcode = "1110" else -- shift left [SH] bits
                ROTATE_RIGHT(SIGNED(A), to_integer(SH)) when opcode = "1111" else -- shift left [SH] bits
                (others => '0'); -- catch all


flags(0) <= '1' when int_compute = 0  else '0';  -- flag when output = 0
flags(1) <= '1' when int_compute /= 0 else '0'; -- flag when output != 0
flags(2) <= '1' when int_compute = 1  else '0'; -- flag when output = 1
flags(3) <= '1' when int_compute < 0  else '0'; -- flag when output < 0
flags(4) <= '1' when int_compute > 0  else '0'; -- flag when output > 0
flags(5) <= '1' when int_compute <= 0 else '0'; -- flag when output <= 0
flags(6) <= '1' when int_compute >= 0 else '0'; -- flag when output >= 0
-- 6 possible cases for overflow flag (flags(7))
flags(7) <= -- for addition: flag when -A + -B = +C and +A + +B = -C
            '1' when opcode = "1010" and (SIGNED(A) < 0) and (SIGNED(B) < 0) and (int_compute > 0) else
            '1' when opcode = "1010" and (SIGNED(A) > 0) and (SIGNED(B) > 0) and (int_compute < 0) else
            -- for subtraction: flag when  A - -B = -C and -A - +B = +C
            '1' when opcode = "1011" and (SIGNED(A) > 0) and (SIGNED(B) < 0) and (int_compute < 0) else
            '1' when opcode = "1011" and (SIGNED(A) < 0) and (SIGNED(B) > 0) and (int_compute < 0) else 
            -- for multiplacation and division : flag when +A * +B < C and 
            '1' when opcode = "0100" and (SIGNED(A) > 0) and (SIGNED(B) > 0) and (int_compute < 0) else 
            '1' when int_compute = "0" else '0';


Output <= STD_LOGIC_VECTOR(int_compute); -- cast back to std logic vector
    


end Behavioral;
