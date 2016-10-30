---------------------------------------------------------------------------------
-- HID report decoder for Saitek Cyborg Rumble Game pad.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity joystick is
port
(
  clk: in std_logic;
  -- HID report input from VNC2 (joystick)
  hid_report: in std_logic_vector(71 downto 0);
  audio_enable: out std_logic;
  coin: out std_logic;
  player: out std_logic_vector(1 downto 0);
  left, right, barrier, fire: out std_logic
);
end;

architecture struct of joystick is
  signal S_joy_hat: std_logic_vector(3 downto 0);
  signal S_joy_left_pad_x, S_joy_right_pad_x: std_logic_vector(7 downto 0);
  signal R_audio_enable: std_logic := '0';
  signal R_joy_coin: std_logic;
  signal R_joy_player: std_logic_vector(1 downto 0);
  signal S_joy_left, S_joy_right: std_logic;
  signal R_joy_left, R_joy_right, R_joy_barrier, R_joy_fire: std_logic;
begin
  -- either HAT left/right or left/right paddle X
  S_joy_hat <= hid_report(17*4+3 downto 17*4);
  S_joy_left_pad_x <= hid_report(4*4+7 downto 4*4);
  S_joy_right_pad_x <= hid_report(8*4+7 downto 8*4);
  S_joy_left  <= '1' when S_joy_hat=5 or S_joy_hat=6 or S_joy_hat=7 or S_joy_left_pad_x < 126 or S_joy_right_pad_x < 126 else '0';
  S_joy_right <= '1' when S_joy_hat=1 or S_joy_hat=2 or S_joy_hat=3 or S_joy_left_pad_x > 130 or S_joy_right_pad_x > 130 else '0';
  process(clk)
  begin
    if rising_edge(clk) then
      -- left up trigger disables audio
      -- right up trigger enables audio
      if hid_report(14*4+2)='1' then
        R_audio_enable <= '0';
      elsif hid_report(14*4+3)='1' then
        R_audio_enable <= '1';
      end if;
      R_joy_coin <= hid_report(16*4+2); -- "FPS" button inserts coin
      R_joy_player(0) <= hid_report(15*4+2); -- "BACK" button 1-player
      R_joy_player(1) <= hid_report(15*4+3); -- "START" button 2-player
      R_joy_left  <= S_joy_left;
      R_joy_right <= S_joy_right;
      -- barrier: any A,B,X,Y button
      R_joy_barrier <= hid_report(13*4+2) or hid_report(13*4+3) or hid_report(14*4+0) or hid_report(14*4+1);
      -- fire: left or right trigger
      R_joy_fire <= hid_report(15*4+0) or hid_report(15*4+1);
    end if;
  end process;
  audio_enable <= R_audio_enable;
  coin <= R_joy_coin;
  player <= R_joy_player;
  left <= R_joy_left;
  right <= R_joy_right;
  barrier <= R_joy_barrier;
  fire <= R_joy_fire;
end struct;
