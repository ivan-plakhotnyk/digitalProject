library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL;
-- Entity describes a parameterizable single-cycle processor that takes two input
--  vectors and outputs the product of the two vectors using a parameterizable ALU and
--  register bank to apply the appropriate operation and store the appropriate data.
entity param_single_cycle_processor is
    generic( size     : NATURAL := 16;
             num_regs : NATURAL := 8);
    Port (  CLK, RST, START: in STD_LOGIC; -- start initiates FSM
            PROC_OUT : out STD_LOGIC_VECTOR(size-1 downto 0); -- processor output
            A: in STD_LOGIC_VECTOR(size-1 downto 0); -- input vector
            B: in STD_LOGIC_VECTOR(size-1 downto 0) -- input vector
            ); 
end param_single_cycle_processor;

architecture Behavioral of param_single_cycle_processor is
    -- indivdiaul FSM state description in state assignment
    type fsm_states is (IDLE, LOAD_B, LOAD_A, MASK, SET_BITS, TEST_BIT,
                         ADD_A, SHIFT_B, SHIFT_A, UPDATE, OUTPUT);
    signal state, next_state : fsm_states;
    -- IMM input vector to processor (immediate value)
    signal IMM : STD_LOGIC_VECTOR(size-1 downto 0);
    -- SEL controls mux before ALU input A, output is either IMM or reg_bank_A
    signal SEL : STD_LOGIC;
    -- ALU_OUT controls FSM transitions from TEST_BIT to OUTPUT
    signal ALU_OUT : STD_LOGIC_VECTOR(size-1 downto 0); -- ALU output
    -- mux_out is input to ALU input A (either IMM (A or B) or reg_bank_A value
    signal mux_out : STD_LOGIC_VECTOR(size-1 downto 0); 
    signal reg_bank_out_B : STD_LOGIC_VECTOR(size-1 downto 0); -- reg bank B output
    signal reg_bank_out_A : STD_LOGIC_VECTOR(size-1 downto 0); -- reg bank A output
    -- SH controls number of bits for shift
    signal SH_int : UNSIGNED(log2(size)-1 downto 0);
    -- opcode controls ALU operation of fixed size
    signal opcode_int : STD_LOGIC_VECTOR (3 downto 0);
    -- RREG_A controls mux for register read channel A (log2 for addressing)
    signal RREG_A : UNSIGNED(log2(num_regs)-1 downto 0); 
    -- RREG_B controls mux for register read channel B
    signal RREG_B : UNSIGNED(log2(num_regs)-1 downto 0); 
    -- WREG controls active register when write enabled (encoded)
    signal WREG : UNSIGNED(log2(num_regs)-1 downto 0); 
    -- FLAGS display errors generated in process (fixed size and encoded)
    signal FLAGS_int : STD_LOGIC_VECTOR(7 downto 0);
    -- Write enable
    signal WEN:  STD_LOGIC;
begin
   
ALU_ent : entity work.param_alu
    generic map (size => size)
    port map(  A => STD_LOGIC_VECTOR(mux_out), -- input A of [data_size]
               B => STD_LOGIC_VECTOR(reg_bank_out_B), -- input B of [data_size]
               opcode => opcode_int, -- log2(13) => 4 bit addressing
               SH     => SH_int, -- shift addressing
               Output => ALU_OUT, -- ALU output [data_size]
               flags  => FLAGS_int); -- 1 bit per flag (fixed 8-bit)

reg_bank : entity work.param_reg_bank
    generic map ( data_size => size, -- default bus size
                  num_regs => num_regs) -- default number of registers
    port map ( clk  => CLK,
               rst  => RST, 
               wen  => WEN,
               wreg => WREG, -- vector points to register being written to
               r_reg_A => RREG_A, -- read reg bank A -- controls mux 1 for data output
               r_reg_B => RREG_B, -- read reg bank B -- controls mux 2 for data output
               D_in    => ALU_OUT, -- data input 
               D_out_A => reg_bank_out_A, -- data output from mux 1 (reg bank A)
               D_out_B => reg_bank_out_B); -- data output from mux 2 (reg bank B)
               
-- define state assignment : state moves on rising edge if reset is low
state_assignment : process (clk) is
begin
    if rising_edge(clk) then
        if (rst = '1') then 
            state <= IDLE; -- state returns to idle if reset = 1
        else
            state <= next_state; -- else transition
        end if;
    end if;
end process state_assignment;

-- defines individual state transition conditions that layout the process
--  of the multiplication of two numbers
state_transitions : process (state, start,alu_out) is
begin
    case state is
        -- IDLE : reset state i.e. do nothing
        when IDLE => 
            if (START = '1') then -- START signal initiates transitions
                next_state <= LOAD_B; -- begin sequence
            else
                next_state <= state; -- idle
            end if;
        -- LOAD_B : load multiplicand : Reg1 gets input vector B (IMM)
        when LOAD_B => 
            next_state <= LOAD_A;
        -- LOAD_A : load multiplier : Reg2 gets input vector A (IMM)
        when LOAD_A => 
            next_state <= MASK; 
        -- MASK : Set bit 0 mask : Reg6 gets Reg0 + 1 = 0 + 1 = 1
        when MASK => 
            next_state <= SET_BITS;
        -- SET_BITS : set the number of bits to compare : R7 gets R6 shifted [SH] bits
        when SET_BITS => 
            next_state <= TEST_BIT;
        -- TEST_BIT : Reg3 <= Reg1 AND Reg6 (bit0 AND 1) (i.e. is bit0 = 1)
        when TEST_BIT => 
            if (flags_int(2) = '1') then -- bit0 = 1
                next_state <= ADD_A; -- if match then continue
            else -- i.e. alu_out = 0
                next_state <= SHIFT_B; -- else skip to shift
            end if;
        -- ADD_A : add multiplier to result : R3 <= R3 + R2
        when ADD_A =>
                next_state <= SHIFT_B;
        -- SHIFT_B : get the next bit (shift B right) : R1 <= R1 >> 1 
        when SHIFT_B => 
            next_state <= SHIFT_A;
        -- SHIFT_A : times multiplier by 2 (shift A left)
        when SHIFT_A =>
            next_state <= UPDATE;
        -- UPDATE : update Reg7 to repeat process or exit R7 <= R7 - 1
        when UPDATE =>
            if (flags_int(4) = '1') then -- if theres still remaining bits then
                next_state <= TEST_BIT; -- repeat process
            else -- i.e. operation complete : OUT <= R3
                next_state <= OUTPUT; -- output result
            end if;
        -- OUTPUT_RESULT : processor outputs the value at the ALU output then idles
        when OUTPUT =>
            next_state <= state; -- Idle until reset
        end case;
end process state_transitions;

PROC_OUT <= STD_LOGIC_VECTOR(ALU_OUT);

--PROC_OUT <= STD_LOGIC_VECTOR(ALU_OUT); when state = output else 
--                        (others => '1'); -- output ALU data

-- combinational logic
mux_out <= (IMM) when SEL = '1' else
            reg_bank_out_A; -- catch all 
-- Output for the states of the FSM (According to the table of outputs)
-- opcode_int sets ALU opcode for the operation required at each state
opcode_int <= "1000" when state = MASK     else
              "1100" when state = SET_BITS else
              "0100" when state = TEST_BIT else
              "1010" when state = ADD_A    else
              "1101" when state = SHIFT_B  else 
              "1100" when state = SHIFT_A  else
              "1001" when state = UPDATE   else
              (others=>'0'); -- catch all (includes IDLE,LOAD_B,LOAD_A,OUTPUT_RESULT)
-- SH_int 
SH_int <= to_unsigned(log2(size/2), log2(size)) when state = SET_BITS else
          to_unsigned(1, log2(size)) when state = SHIFT_B or state = SHIFT_A else 
          (others=>'0'); -- catch all
          
-- (combinational logic for SEL below internal signal declaration)
SEL <= '1' when state = LOAD_A or state = LOAD_B else 
       '0'; -- when LOAD is high, pass A or B to IMM
-- IMM 
IMM <= A when state = LOAD_A else 
       B when state = LOAD_B else
       (others=>'0'); -- catch all
       
RREG_A <= to_unsigned(6, log2(num_regs)) when state = SET_BITS or state = TEST_BIT else
          to_unsigned(2, log2(num_regs)) when state = ADD_A    or state = SHIFT_A else
          to_unsigned(1, log2(num_regs)) when state = SHIFT_B  else
          to_unsigned(0, log2(num_regs)) when state = MASK     else
          to_unsigned(7, log2(num_regs)) when state = UPDATE   else
          to_unsigned(3, log2(num_regs)) when state = OUTPUT   else 
          (others=>'0'); -- catch all
          
RREG_B <= to_unsigned(1, log2(num_regs)) when state = TEST_BIT else
          to_unsigned(3, log2(num_regs)) when state = ADD_A    else 
          (others=>'0'); -- catch all
-- WEN is high for LOAD_A,LOAD_B,MASK,SET_BITS,ADD_A,SHIFT_B,SHIFT_B,and UPDATE. Thus:
WEN <= '1' when state /= IDLE or state /= TEST_BIT or state /= OUTPUT else 
       '0';

WREG <= to_unsigned(1, log2(num_regs)) when state = LOAD_B   or state = SHIFT_B else
        to_unsigned(2, log2(num_regs)) when state = LOAD_A   or state = SHIFT_A else
        to_unsigned(6, log2(num_regs)) when state = MASK     else
        to_unsigned(7, log2(num_regs)) when state = SET_BITS or state = UPDATE else
        to_unsigned(3, log2(num_regs)) when state = ADD_A    else 
        (others=>'0'); -- catch all
        
end Behavioral;
