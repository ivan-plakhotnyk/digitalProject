library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.ALL;
----------- Code must fall into this parameter to stay within the margins ----------- |

entity param_single_cycle_processor is
    generic( size     : NATURAL := 50;
             num_regs : NATURAL := 8);
    Port (  CLK, RST, WEN, SEL : in STD_LOGIC; -- clock, reset, write enable, mux select
            -- SH controls number of bits for shift
            SH       : in  UNSIGNED(size-1 downto 0);
            -- opcode controls ALU operation of fixed size
            opcode   : in  STD_LOGIC_VECTOR (size-1 downto 0);
            -- IMM input vector to processor (immediate value)
            IMM      : in  STD_LOGIC_VECTOR(size-1 downto 0); 
            -- RREG_A controls mux for register read channel A (thelog2 for addressing)
            RREG_A   : in  UNSIGNED(log2(size)-1 downto 0); 
            -- RREG_B controls mux for register read channel B
            RREG_B   : in  UNSIGNED(size-1 downto 0); 
            -- WREG controls active register when write enabled (encoded)
            WREG     : in  UNSIGNED(log2(size)-1 downto 0); 
            PROC_OUT : out STD_LOGIC_VECTOR(size-1 downto 0); -- system output
            -- FLAGS display errors generated in process (fixed size)
            FLAGS    : out STD_LOGIC_VECTOR(7 downto 0)); 
end param_single_cycle_processor;

architecture Behavioral of param_single_cycle_processor is
    -- different fsm states are:
    -- full description in state assignment
    -- IDLE : reset state, LOAD_B : R1 <= B(IMM), LOAD_A : R2 <= A(IMM)
    -- SET_BITS : R6 <= R0 + 1, 
    type fsm_states is (IDLE, LOAD_B, LOAD_A, MASK, SET_BITS, TEST_BIT,
                         ADD_A, SHIFT_B, SHIFT_A, UPDATE, OUTPUT);
    signal state, next_state : fsm_states; -- of type current state and next state

    -- add internal signals here
    signal START : STD_LOGIC; -- controls FSM transition from IDLE
    signal ALU_OUT : STD_LOGIC_VECTOR(size-1 downto 0); -- controls FSM transitions from TEST_BIT to OUTPUT
    signal mux_out: STD_LOGIC_VECTOR(size-1 downto 0);
    signal reg_bank_out_B : STD_LOGIC_VECTOR(size-1 downto 0);
    signal reg_bank_out_A : STD_LOGIC_VECTOR(size-1 downto 0);
begin
    -- add combinational logic here
    PROC_OUT <= STD_LOGIC_VECTOR(ALU_OUT);
    mux_out <= (IMM) when SEL = '1' else
               reg_bank_out_B; -- includes 0 and undefined
   
ALU_ent : entity work.param_alu
    generic map (size => size)
    port map(  A => STD_LOGIC_VECTOR(mux_out), -- input A of [data_size]
               B => STD_LOGIC_VECTOR(reg_bank_out_A), -- input B of [data_size]
               opcode => opcode, -- log2(13) => 4 bit addressing
               SH     => SH, -- shift addressing
               Output => ALU_OUT, -- ALU output [data_size]
               flags  => FLAGS); -- 1 bit per flag (fixed 8-bit)

reg_bank : entity work.param_reg_bank
    generic map ( data_size => size, -- default bus size
                  num_regs => num_regs) -- default number of registers
    port map ( clk  => CLK,
               rst  => RST, 
               wen  => wen,
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
                next_state <= SHIFT_A;
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
                next_state <= OUTPUT; -- output result
            end if;
        end case;
end process state_transitions;
-- FSM outputs:
--     type fsm_states is (IDLE, LOAD_B, LOAD_A, MASK, SET_BITS, TEST_BIT, ADD_A, SHIFT_B, SHIFT_A, UPDATE, OUTPUT);
-- signal <= '1' when state = some_state or...    

end Behavioral;
-------------- copy and pasted from lab 3 for reference -----------------



--architecture Behavioral of Control is
--type fsm_states is (IDLE, GEN_0, GEN_1, LD_R1, LD_R2, STORE, HOLD);
--signal state, next_state: fsm_states;
----internal signals
--signal done, cnt_en : STD_LOGIC;
--signal cnt_out : UNSIGNED(4 downto 0);
--begin
----combinational logic for the done signal
--done <= '1' when cnt_out =

---- defines each state transition
--state_transitions : process (state, nxt, done) is
--begin
--case state is
---- Reset state
--when IDLE =>
--if nxt = '1' then
--next_state <= GEN_0; -- Conditional transition (dependant on next)
--else
--next_state <= state; -- do nothing
--end if;
---- State 1
--when GEN_0 =>
--if nxt = '1' then
--next_state <= GEN_1;
--else
--next_state <= state;
--end if;
---- State 2
--when GEN_1 =>
--if nxt = '1'then
--next_state<=LD_R1;
--else
--next_state <= state;
--end if;
---- State 3
--when LD_R1 =>
--next_state<=LD_R2; -- unconditional transition (dependence on next removed)
---- State 4
--when LD_R2 =>
--next_state<=STORE;
---- State 5
--when STORE =>
--next_state<=HOLD;
---- State 6
--when HOLD => -- conditional transition
--if nxt = '1'then
--if (done = '0') then
--next_state <= LD_R1;
--elsif (done = '1') then
--next_state <= GEN_0;
--end if;
--else
--next_state <= state;
--end if;
--end case;
--end process state_transitions;
---- FSM outputs
---- declares output for high states then catches all with zero (except Mem_Addr)
--mem_wr <= '1' when state = GEN_0 or
--state = GEN_1 or
--state = STORE else
--'0'; -- catch all
--r1_en <= '1' when state = LD_R1 else
--'0';
--r2_en <= '1' when state = LD_R2 else
--'0';
--out_en <= '1' when state = GEN_0 or
--state = GEN_1 or
--state = STORE else
--'0';
--Mux_Sel <= "10" when state = GEN_0 else
--"11" when state = GEN_1 else
--"00";
--cnt_en <= nxt when state = GEN_0 or
--state = GEN_1 or
--state = HOLD else
--'0';
--Mem_Addr <= (cnt_out - 2) when state = LD_R1 else
--(cnt_out - 1) when state = LD_R2 else
--cnt_out; -- all other states are don't care
--end Behavioral;

--Counter VHDL
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
---- This entity describes a 5-bit Counter limited to 23 with enable and synchronous
---- reset.
-- entity CNT_to_24 is
--  Port ( clk : in STD_LOGIC;
--      en : in STD_LOGIC;
--      rst : in STD_LOGIC;
--      CNT_out : out UNSIGNED (4 downto 0));
-- end CNT_to_24;
-- architecture Behavioral of CNT_to_24 is
--  --internal signal for the counter
--  signal CNTInt: UNSIGNED (4 downto 0);
-- begin
----Counter process
-- CNT: process (clk) -- No reset in sensitivity list
-- begin
--  if (rising_edge(clk)) then
--      if (rst = '1') then -- synchronous reset
--              CNTInt <= (others => '0');
--      else
--      if (en = '1') then
--              if(CNTInt = 24) then
--                  CNTInt <= (others => '0'); -- reset counter when it reaches 24
--              else
--                  CNTInt<=(CNTInt+1);
--              end if;
--      end if;
--      end if;
--  end if;
--end process CNT;
--  CNT_out <= CNTInt;
--end Behavioral;
