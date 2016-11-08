---------------------------------------------------------------------------------
-- Vibration (Rumble) support
-- takes explosion sound input, triggers it
-- and controls PWM of left and right vibration motors
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity vibra is
generic
(
  C_railroad_bits: integer := 22
);
port
(
  clk: in std_logic;
  i_fire, i_burn, i_explode, i_fireball: in std_logic;
  o_left, o_right: out std_logic
);
end;

architecture struct of vibra is
  signal R_railroad: std_logic_vector(C_railroad_bits-1 downto 0) := (others => '1');
  signal S_railroad: std_logic;
  signal R_direction: std_logic := '1';
  signal S_railrd_left, S_railrd_right: std_logic;
  signal R_fire_shift: std_logic_vector(1 downto 0);
  signal R_fire_counter: std_logic_vector(20 downto 0);
begin

  process(clk)
  begin
    if rising_edge(clk) then
      R_fire_shift <= i_fire & R_fire_shift(1); -- downshift
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if R_fire_shift = "10" then  -- rising edge
        R_fire_counter <= (others => '1'); -- start
      else
        if R_fire_counter(R_fire_counter'length-1)='1' then
          R_fire_counter <= R_fire_counter-1;
        end if;
      end if;
    end if;
  end process;

  -- "railroad" action for the rumble-vibration
  process(clk)
  begin
    if rising_edge(clk) then
        if R_direction = '0' then
          R_railroad <= R_railroad + 1;
        else
          R_railroad <= R_railroad - 1;
        end if;

        if ( (    R_railroad) = 0 and R_direction = '1') then
          R_direction <= '0';
          R_railroad <= (others => '0');
          R_railroad(0) <= '1';
        end if;
        if ( (not R_railroad) = 0 and R_direction = '0') then
          R_direction <= '1';
          R_railroad <= (others => '1');
          R_railroad(0) <= '0';
        end if;
    end if;
  end process;
  
  railrd1: entity work.dac
  generic map
  (
    C_bits => 8
  )
  port map
  (
    clk_i => clk,
    res_n_i => '1', -- never reset
    dac_i => R_railroad(R_railroad'length-1 downto R_railroad'length-8),
    dac_o => S_railroad
  );
  S_railrd_left <= not S_railroad;
  S_railrd_right <= S_railroad;

  o_left <= (S_railrd_left and i_explode) or i_burn;
  o_right <= (S_railrd_right and i_explode) or R_fire_counter(R_fire_counter'length-1);

end struct;
