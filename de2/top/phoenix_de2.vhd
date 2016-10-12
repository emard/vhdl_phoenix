---------------------------------------------------------------------------------
-- DE2-35 Top level for Phoenix by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
--
-- Main features
--  PS2 keyboard input
--  wm8731 sound output
--  NO board SRAM used
--
-- Uses pll for 18MHz and 11MHz generation from 50MHz
--
-- Board switch :
--   0 - 7 : dip switch
--             0-1 : lives 3-6
--             3-2 : bonus life 30K-60K
--               4 : coin 1-2
--             6-5 : unkonwn
--               7 : upright-cocktail  
--   8 -10 : sound_select
--             0XX : all mixed (normal)
--             100 : sound1 only 
--             101 : sound2 only
--             110 : sound3 only
--             111 : melody only 
-- Board key :
--      0 : reset
--   
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_de2 is
generic
(
  C_hdmi_generic_serializer: boolean := true; -- serializer type: false: vendor-specific, true: generic=vendor-agnostic
  C_hdmi_audio: boolean := true -- HDMI generator type: false: video only, true: video+audio capable
);
port
(
  CLOCK_50: in std_logic;
  ledr: out std_logic_vector(7 downto 0);
  VGA_R, VGA_G, VGA_B: out std_logic_vector(9 downto 0);
  VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK, VGA_SYNC: out std_logic;
  ps2_clk: in std_logic;
  ps2_dat: in std_logic;
  gpio_0: inout std_logic_vector(35 downto 0)
  --hdmi_d: out std_logic_vector(2 downto 0);
  --hdmi_clk: out std_logic;
  --btn_left, btn_right: in std_logic
);
end;

architecture struct of phoenix_de2 is
  signal clk_pixel, clk_pixel_shift: std_logic;
 
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_r8, S_vga_g8, S_vga_b8: std_logic_vector(7 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  signal S_audio: std_logic_vector(11 downto 0);

  signal btn_left, btn_right: std_logic;
  signal hdmi_dp, hdmi_dn: std_logic_vector(2 downto 0);
  signal hdmi_clkp, hdmi_clkn: std_logic;

  signal kbd_intr      : std_logic;
  signal kbd_scancode  : std_logic_vector(7 downto 0);
  signal JoyPCFRLDU    : std_logic_vector(7 downto 0);

  signal coin         : std_logic;
  signal player_start : std_logic_vector(1 downto 0);
  signal button_left, button_right, button_protect, button_fire: std_logic;

  signal reset        : std_logic;
  signal clock_stable : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
begin
  G_sdr: if C_hdmi_generic_serializer or not C_hdmi_audio generate
  clkgen_sdr: entity work.clk_50_250_25MHz
  port map(
      inclk0 => clock_50, c0 => clk_pixel_shift, c1 => clk_pixel,
      locked => clock_stable
  );
  --clk_pixel_shift <= clock_50;
  --clk_pixel <= clock_50;
  end generate;

  reset <= not clock_stable;
  -- dip_switch(3 downto 0) <= sw(4 downto 1);

  -- get scancode from keyboard
  keybord : entity work.io_ps2_keyboard
  port map (
    clk       => clk_pixel,
    kbd_clk   => ps2_clk,
    kbd_dat   => ps2_dat,
    interrupt => kbd_intr,
    scancode  => kbd_scancode
  );

  -- translate scancode to joystick
  Joystick : entity work.kbd_joystick
  port map (
    clk         => clk_pixel,
    kbdint      => kbd_intr,
    kbdscancode => std_logic_vector(kbd_scancode),
    JoyPCFRLDU  => JoyPCFRLDU
  );

  -- joystick to inputs
  coin            <= not JoyPCFRLDU(7); -- F3 : Add coin
  player_start(1) <= not JoyPCFRLDU(6); -- F2 : Start 2 Players
  player_start(0) <= not JoyPCFRLDU(5); -- F1 : Start 1 Player
  button_fire     <= not JoyPCFRLDU(4); -- SPACE : Fire
  button_right    <= not JoyPCFRLDU(3); -- RIGHT arrow : Right
  button_left     <= not JoyPCFRLDU(2); -- LEFT arrow  : Left
  button_protect  <= not JoyPCFRLDU(0); -- UP arrow : Protection

  phoenix : entity work.phoenix
  generic map
  (
    C_audio => true,
    C_vga => true
  )
  port map
  (
    clk_pixel    => clk_pixel,
    reset        => reset,
    dip_switch   => dip_switch,
    btn_coin     => coin or (not gpio_0(0)),
    btn_player_start(0) => player_start(0) or (not gpio_0(2)),
    btn_player_start(1) => player_start(1) or (not gpio_0(4)),
    btn_left     => button_left or not gpio_0(6),
    btn_right    => button_right or not gpio_0(8),
    btn_barrier  => button_protect or (not gpio_0(10)),
    btn_fire     => button_fire or (not gpio_0(12)),
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank,
    audio        => S_audio
  );

  -- virtual GND's for GPIO controls
  gpio_0(1) <= '0';
  gpio_0(3) <= '0';
  gpio_0(5) <= '0';
  gpio_0(7) <= '0';
  gpio_0(9) <= '0';
  gpio_0(11) <= '0';
  gpio_0(13) <= '0';
  
  VGA_R(9 downto 8) <= S_vga_r; VGA_R(7 downto 0) <= (others => S_vga_r(0));
  VGA_G(9 downto 8) <= S_vga_g; VGA_G(7 downto 0) <= (others => S_vga_g(0));
  VGA_B(9 downto 8) <= S_vga_b; VGA_B(7 downto 0) <= (others => S_vga_b(0));
  VGA_HS <= S_vga_hsync;
  VGA_VS <= S_vga_vsync;
  VGA_BLANK <= S_vga_blank;
  VGA_SYNC <= S_vga_hsync or S_vga_vsync;
  VGA_CLK <= clk_pixel;

  -- some debugging with LEDs
  ledr(0) <= not gpio_0(0);
  ledr(1) <= (not gpio_0(2)) or (not gpio_0(4));
  ledr(2) <= not gpio_0(6);
  ledr(3) <= not gpio_0(8);
  ledr(4) <= (not gpio_0(10)) or (not gpio_0(12));
  ledr(5) <= S_vga_r(1); -- when game works, changing color on
  ledr(6) <= S_vga_g(1); -- large area of the screen should
  ledr(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs
  
  G_hdmi_video_only: if not C_hdmi_audio generate
  vga2dvi_converter: entity work.vga2dvid
  generic map
  (
    C_ddr     => false,
    C_depth   => 2 -- 2bpp (2 bit per pixel)
  )
  port map
  (
    clk_pixel => clk_pixel, -- 25 MHz
    clk_shift => clk_pixel_shift, -- 250 MHz

    in_red   => S_vga_r,
    in_green => S_vga_g,
    in_blue  => S_vga_b,

    in_blank => S_vga_blank,
    in_hsync => S_vga_hsync,
    in_vsync => S_vga_vsync,

    -- single-ended output ready for differential buffers
    out_red   => dvid_red,
    out_green => dvid_green,
    out_blue  => dvid_blue,
    out_clock => dvid_clock
  );
  -- true differential pins defined in constraints
  --hdmi_d <= dvid_red(0) & dvid_green(0) & dvid_blue(0);
  --hdmi_clk <= dvid_clock(0);

  -- GPIO "differential" output buffering for HDMI
  hdmi_output: entity work.hdmi_out
  port map
  (
    tmds_in_rgb    => dvid_red(0) & dvid_green(0) & dvid_blue(0),
    tmds_out_rgb_p => hdmi_dp,   -- D2+ red  D1+ green  D0+ blue
    tmds_out_rgb_n => hdmi_dn,   -- D2- red  D1- green  D0+ blue
    tmds_in_clk    => dvid_clock(0),
    tmds_out_clk_p => hdmi_clkp, -- CLK+ clock
    tmds_out_clk_n => hdmi_clkn  -- CLK- clock
  );
  end generate;
  gpio_0(16) <= hdmi_clkp;
  gpio_0(17) <= hdmi_clkn;
  gpio_0(18) <= hdmi_dp(0);
  gpio_0(19) <= hdmi_dn(0);
  gpio_0(20) <= hdmi_dp(1);
  gpio_0(21) <= hdmi_dn(1);
  gpio_0(22) <= hdmi_dp(2);
  gpio_0(23) <= hdmi_dn(2);

end struct;
