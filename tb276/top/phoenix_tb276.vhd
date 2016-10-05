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

entity phoenix_tb276 is
port
(
  clk_25m: in std_logic;
  --rs232_txd: out std_logic;
  --rs232_rxd: in std_logic;
  led: out std_logic_vector(7 downto 0);
  gpio: inout std_logic_vector(31 downto 0);
  hdmi_dp, hdmi_dn: out std_logic_vector(2 downto 0);
  hdmi_clkp, hdmi_clkn: out std_logic;
  btn_left, btn_right: in std_logic
);
end;

architecture struct of phoenix_tb276 is
  signal clk_pixel, clk_pixel_shift: std_logic;
 
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  --signal tmds_rgb: std_logic_vector(2 downto 0);
  --signal tmds_clk: std_logic;

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  signal S_audio: std_logic_vector(11 downto 0);

  signal reset        : std_logic;
  signal clock_stable : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
begin
  clkgen: entity work.pll_25M_250M_25M_83M333
  port map(
      inclk0 => clk_25m, c0 => clk_pixel_shift, c1 => clk_pixel, c2 => open 
  );
  clock_stable <= '1'; -- todo should be obtained from PLL lock

  reset <= not clock_stable;
  -- dip_switch(3 downto 0) <= sw(4 downto 1);

  phoenix : entity work.phoenix
  generic map
  (
    C_vga => true
  )
  port map
  (
    clk_pixel    => clk_pixel,
    reset        => reset,
    dip_switch   => dip_switch,
    btn_coin     => not gpio(0),
    btn_player_start(0) => not gpio(1),
    btn_player_start(1) => not gpio(2),
    btn_left     => not gpio(3),
    btn_right    => not gpio(4),
    btn_barrier  => not gpio(5),
    btn_fire     => not gpio(6),
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank,
    audio        => S_audio
  );

  -- some debugging with LEDs
  led(0) <= not gpio(0);
  led(1) <= (not gpio(1)) or (not gpio(2));
  led(2) <= not gpio(3);
  led(3) <= not gpio(4);
  led(4) <= (not gpio(5)) or (not gpio(6));
  led(5) <= S_vga_r(1); -- when game works, changing color on
  led(6) <= S_vga_g(1); -- large area of the screen should
  led(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs

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

  -- differential output buffering for HDMI clock and video
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
  gpio(31 downto 20) <= S_audio;
end struct;
