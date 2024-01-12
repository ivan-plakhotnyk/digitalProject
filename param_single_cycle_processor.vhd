library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL;
----------- Code must fall into this parameter to stay within the margins ----------- |

entity param_single_cycle_processor is
    generic( size     : NATURAL := 50;
             num_regs : NATURAL := 8);
    Port (  CLK, RST, START: in STD_LOGIC; -- clock, reset, write enable, mux select
            PROC_OUT : out STD_LOGIC_VECTOR(size-1 downto 0);
            A: in STD_LOGIC_VECTOR(size-1 downto 0);
            B: in STD_LOGIC_VECTOR(size-1 downto 0)
            ); 
end param_single_cycle_processor;

architecture Behavioral of param_single_cycle_processor is

    
    -- different fsm states are:
    -- full description in state assignment
    -- IDLE : reset state, LOAD_B : R1 <= B(IMM), LOAD_A : R2 <= A(IMM)
    -- SET_BITS : R6 <= R0 + 1, 
    type fsm_states is (IDLE, LOAD_B, LOAD_A, MASK, SET_BITS, TEST_BIT,
                         ADD_A, SHIFT_B, SHIFT_A, UPDATE, OUTPUT_RESULT);
    signal state, next_state : fsm_states; -- of type current state and next state
    -- IMM input vector to processor (immediate value)
    signal IMM   :  STD_LOGIC_VECTOR(15 downto 0);
    -- add internal signals here
    signal SEL : STD_LOGIC;
    signal ALU_OUT : STD_LOGIC_VECTOR(size-1 downto 0); -- controls FSM transitions from TEST_BIT to OUTPUT
    signal mux_out: STD_LOGIC_VECTOR(size-1 downto 0);
    signal reg_bank_out_B : STD_LOGIC_VECTOR(size-1 downto 0);
    signal reg_bank_out_A : STD_LOGIC_VECTOR(size-1 downto 0);
    -- SH controls number of bits for shift
    signal SH_int: UNSIGNED(log2(size)-1 downto 0);
    -- opcode controls ALU operation of fixed size
    signal opcode_int   : STD_LOGIC_VECTOR (3 downto 0);
            -- RREG_A controls mux for register read channel A (thelog2 for addressing)
    signal RREG_A   :   UNSIGNED(log2(num_regs)-1 downto 0); 
            -- RREG_B controls mux for register read channel B
    signal RREG_B   :   UNSIGNED(log2(num_regs)-1 downto 0); 
            -- WREG controls active register when write enabled (encoded)
    signal WREG     :   UNSIGNED(log2(num_regs)-1 downto 0); 
            -- FLAGS display errors generated in process (fixed size)
    signal FLAGS_int    :  STD_LOGIC_VECTOR(7 downto 0);
    
    signal WEN:  STD_LOGIC;
begin
    -- add combinational logic here
    PROC_OUT <= STD_LOGIC_VECTOR(ALU_OUT);
    mux_out <= (IMM) when SEL = '1' else
               reg_bank_out_A; -- includes 0 and undefined
   
ALU_ent : entity work.param_alu
    generic map (data_size => size)
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
               r_reg_A => RREG_A, -- read reg bank A -- controls mux 1 for data output (read)
               r_reg_B => RREG_B, -- read reg bank B -- controls mux 2 for data output (read)
               D_in    => ALU_OUT, -- data input vector
               D_out_A => reg_bank_out_A, -- data output vector from mux 1 (reg bank A)
               D_out_B => reg_bank_out_B); -- data output vector from mux 2 (reg bank B)
               
-- define state assignment : state moves on rising edge if reset is low
state_assignment : process (clk) is
begin
    if rising_edge(clk) then
        if (rst = '1') then 
            state <= IDLE; -- state returns to idle if reset = 1
        else
            state <= next_state; -- else state gets next state
        end if;
    end if;
end process state_assignment;

-- defines individual state transition conditions
state_transitions : process (state, start,alu_out) is
begin
    case state is
        -- reset state i.e. do nothing
        when IDLE => 
            if (START = '1') then -- START initiates transitions
                next_state <= LOAD_B; -- conditional transition
            else
                next_state <= state;
            end if;
        -- load multiplicand : R1 gets input vector B (IMM)
        when LOAD_B => 
            next_state <= LOAD_A;
        -- load multiplier : R2 gets input vector A (IMM)
        when LOAD_A => 
            next_state <= MASK; 
        -- Set bit 0 mask : R6 gets R0 + 1 = 0 + 1 = 1
        when MASK => 
            next_state <= SET_BITS;
        -- set the number of bits to compare : R7 gets R6 shifted [SH] bits
        when SET_BITS => 
            next_state <= TEST_BIT;
        -- bitwise AND of bit 0 and 1 :R3 <= R1 AND R6 (if bit 0 is high then transition)
        when TEST_BIT => 
            if (UNSIGNED(ALU_OUT) = 1) then
                next_state <= ADD_A;
            else -- i.e. alu_out = 0
                next_state <= SHIFT_B;
            end if;
        -- add multiplier to result : R3 <= R3 + R2
        when ADD_A =>
                next_state <= SHIFT_B;
        -- get the next bit (shift B right) : R1 <= R1 >> 1 
        when SHIFT_B => 
            next_state <= SHIFT_A;
        -- shift A left
        when SHIFT_A =>
            next_state <= UPDATE;
        when UPDATE =>
            if (UNSIGNED(ALU_OUT) > 0) then -- if theres still remaining bits then
                next_state <= TEST_BIT; -- repeat process
            else -- i.e. operation complete : OUT <= R3
                next_state <= OUTPUT_RESULT; -- output result
            end if;
        when OUTPUT_RESULT =>
            next_state <= state;
        end case;
end process state_transitions;
-- FSM outputs:
--     type fsm_states is (IDLE, LOAD_B, LOAD_A, MASK, SET_BITS, TEST_BIT, ADD_A, SHIFT_B, SHIFT_A, UPDATE, OUTPUT);
-- signal <= '1' when state = some_state or...    
--Output for the statets of the FSM(According to the table of outputs)
opcode_int <= "0000" when state = IDLE or state = LOAD_B or state = LOAD_A or state = OUTPUT_RESULT else
              "1000" when state = MASK else
              "1100" when state = SET_BITS else
              "0100" when state = TEST_BIT else
              "1010" when state = ADD_A else
              "1101" when state = SHIFT_B else 
              "1100" when state  = SHIFT_A else
              "1001" when state = UPDATE else
              (others=>'0');
SH_int <= to_unsigned(3, log2(size)) when  state =  SET_BITS else
          to_unsigned(1, log2(size)) when  state = SHIFT_B or state = SHIFT_A else to_unsigned(0, log2(size));
SEL <= '1' when state = LOAD_A or state = LOAD_B else '0';
IMM <= A when state = LOAD_A else
       B when state = LOAD_B else
       (others=>'0');
RREG_A <= to_unsigned(6, log2(num_regs)) when state = SET_BITS or state = TEST_BIT else
          to_unsigned(2, log2(num_regs)) when state = ADD_A or state = SHIFT_A else
          to_unsigned(1, log2(num_regs)) when state = SHIFT_B else
          to_unsigned(0, log2(num_regs)) when state = MASK else
          to_unsigned(7, log2(num_regs)) when state = UPDATE else
          to_unsigned(3, log2(num_regs)) when state = OUTPUT_RESULT else to_unsigned(0, log2(num_regs));
RREG_B <= to_unsigned(1, log2(num_regs)) when state = TEST_BIT else
          to_unsigned(3, log2(num_regs)) when state = ADD_A else to_unsigned(0, log2(num_regs));
WEN <= '1' when state = LOAD_A or state = LOAD_B or state = MASK or state = SET_BITS or
        state = ADD_A or state = SHIFT_B or state = SHIFT_A or state = UPDATE else '0';
WREG <= to_unsigned(1, log2(num_regs)) when state = LOAD_B or state = SHIFT_B else
        to_unsigned(2, log2(num_regs)) when state = LOAD_A or state = SHIFT_A else
        to_unsigned(6, log2(num_regs)) when state = MASK else
        to_unsigned(7, log2(num_regs)) when state = SET_BITS or state = UPDATE else
        to_unsigned(3, log2(num_regs)) when state = ADD_A else to_unsigned(0, log2(num_regs));
end Behavioral;
