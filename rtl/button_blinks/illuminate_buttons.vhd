---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity illuminate_buttons is
generic
(
  C_autofire: boolean := true;
  C_railroad_bits: integer := 23
);
port
(
  clk: in std_logic;
  btn_coin: in std_logic;
  led_coin: out std_logic;
  btn_player_start: in std_logic_vector(1 downto 0);
  led_player_start: out std_logic_vector(1 downto 0);
  btn_left: in std_logic;
  led_left: out std_logic;
  btn_right: in std_logic;
  led_right: out std_logic;
  btn_barrier: in std_logic;
  led_barrier: out std_logic;
  btn_fire: in std_logic;
  led_fire: out std_logic
);
end;

architecture struct of illuminate_buttons is
  signal R_railroad: std_logic_vector(C_railroad_bits-1 downto 0) := (others => '1');
  signal R_direction: std_logic := '1';
  signal S_railroad: std_logic;
  signal R_autofire: std_logic_vector(21 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      --if R_railroad = 0 or (not R_railroad) = 0 then
      --else
        if R_direction = '0' then
          R_railroad <= R_railroad + 1;
        else
          R_railroad <= R_railroad - 1;
        end if;

        if ( (    R_railroad) = 0 and R_direction = '1') or btn_left = '1' then
          R_direction <= '0';
          R_railroad <= (others => '0');
          R_railroad(0) <= '1';
        end if;
        if ( (not R_railroad) = 0 and R_direction = '0') or btn_right = '1' then
          R_direction <= '1';
          R_railroad <= (others => '1');
          R_railroad(0) <= '0';
        end if;

      --end if;
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
  led_left <= not S_railroad;
  led_right <= S_railroad;

  G_not_autofire: if not C_autofire generate
    led_fire <= btn_fire; -- Fire
  end generate;

  G_yes_autofire: if C_autofire generate
    process(clk)
    begin
      if rising_edge(clk) then
        if btn_fire='1' then
          R_autofire <= R_autofire-1;
        else
          R_autofire <= (others => '0');
        end if;
      end if;
    end process;
    led_fire <= R_autofire(R_autofire'high);
  end generate;
  
  led_barrier <= btn_barrier;

end struct;
