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
generic
(
  C_hdmi_generic_serializer: boolean := false; -- serializer type: false: vendor-specific, true: generic=vendor-agnostic
  C_hdmi_audio: boolean := true -- HDMI generator type: false: video only, true: video+audio capable
);
port
(
  clk_25m: in std_logic;
  led: out std_logic_vector(7 downto 0);
  gpio: inout std_logic_vector(47 downto 0);
  hdmi_d: out std_logic_vector(2 downto 0);
  hdmi_clk: out std_logic;
  btn_left, btn_right: in std_logic
);
end;

architecture struct of phoenix_tb276 is
  signal clk_pixel, clk_pixel_shift: std_logic;
 
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_r8, S_vga_g8, S_vga_b8: std_logic_vector(7 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  signal S_audio: std_logic_vector(11 downto 0);

  signal reset        : std_logic;
  signal clock_stable : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
begin
  G_sdr: if C_hdmi_generic_serializer or not C_hdmi_audio generate
  clkgen_sdr: entity work.pll_25M_250M_25M
  port map(
      inclk0 => clk_25m, c0 => clk_pixel_shift, c1 => clk_pixel,
      locked => clock_stable
  );
  end generate;

  G_ddr: if C_hdmi_audio and not C_hdmi_generic_serializer generate
  clkgen_ddr: entity work.clk_25M_125M_25M
  port map(
      inclk0 => clk_25m, c0 => clk_pixel_shift, c1 => clk_pixel,
      locked => clock_stable
  );
  end generate;

  reset <= not clock_stable;
  -- dip_switch(3 downto 0) <= sw(4 downto 1);

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
    btn_coin     => (not gpio(0)) or (not btn_right),
    btn_player_start(0) => (not gpio(2)) or (not btn_left),
    btn_player_start(1) => not gpio(4),
    btn_left     => not gpio(6),
    btn_right    => not gpio(8),
    btn_barrier  => (not gpio(10)) or (not btn_right),
    btn_fire     => (not gpio(12)) or (not btn_left),
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank,
    audio        => S_audio
  );

  -- virtual gnd's
  gpio(1) <= '0';
  gpio(3) <= '0';
  gpio(5) <= '0';
  gpio(7) <= '0';
  gpio(9) <= '0';
  gpio(11) <= '0';
  gpio(13) <= '0';

  -- some debugging with LEDs
  led(0) <= not gpio(0);
  led(1) <= (not gpio(2)) or (not gpio(4));
  led(2) <= not gpio(6);
  led(3) <= not gpio(8);
  led(4) <= (not gpio(10)) or (not gpio(12));
  led(5) <= S_vga_r(1); -- when game works, changing color on
  led(6) <= S_vga_g(1); -- large area of the screen should
  led(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs
  
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
  hdmi_d <= dvid_red(0) & dvid_green(0) & dvid_blue(0);
  hdmi_clk <= dvid_clock(0);
  
  -- GPIO "differential" output buffering for HDMI
  --hdmi_output: entity work.hdmi_out
  --port map
  --(
  --  tmds_in_rgb    => dvid_red(0) & dvid_green(0) & dvid_blue(0),
  --  tmds_out_rgb_p => hdmi_dp,   -- D2+ red  D1+ green  D0+ blue
  --  tmds_out_rgb_n => hdmi_dn,   -- D2- red  D1- green  D0+ blue
  --  tmds_in_clk    => dvid_clock(0),
  --  tmds_out_clk_p => hdmi_clkp, -- CLK+ clock
  --  tmds_out_clk_n => hdmi_clkn  -- CLK- clock
  --);
  end generate;

  G_hdmi_video_audio: if C_hdmi_audio generate
  S_vga_r8 <= S_vga_r & S_vga_r(0) & S_vga_r(0) & S_vga_r(0) & S_vga_r(0) & S_vga_r(0) & S_vga_r(0);
  S_vga_g8 <= S_vga_g & S_vga_g(0) & S_vga_g(0) & S_vga_g(0) & S_vga_g(0) & S_vga_g(0) & S_vga_g(0);
  S_vga_b8 <= S_vga_b & S_vga_b(0) & S_vga_b(0) & S_vga_b(0) & S_vga_b(0) & S_vga_b(0) & S_vga_b(0);
  av_hdmi_out: entity work.av_hdmi
  generic map
  (
    C_generic_serializer => C_hdmi_generic_serializer,
    FREQ => 25000000,
    FS => 48000,
    CTS => 25000,
    N => 6144
  )
  port map
  (
    I_CLK_PIXEL_x5 => clk_pixel_shift,
    I_CLK_PIXEL    => clk_pixel,
    I_R            => S_vga_r8,
    I_G	           => S_vga_g8,
    I_B            => S_vga_b8,
    I_BLANK        => S_vga_blank,
    I_HSYNC        => not S_vga_hsync,
    I_VSYNC        => not S_vga_vsync,
    I_AUDIO_ENABLE => not gpio(46), -- set jumper accross pins 75-76 to enable audio
    I_AUDIO_PCM_L  => S_audio & "0000",
    I_AUDIO_PCM_R  => S_audio & "0000",
    O_TMDS_D0      => HDMI_D(0),
    O_TMDS_D1      => HDMI_D(1),
    O_TMDS_D2      => HDMI_D(2),
    O_TMDS_CLK     => HDMI_CLK
  );
  end generate;
  gpio(47) <= '0'; -- simulate GND for jumper to gpio(46)
  gpio(31 downto 20) <= S_audio;
end struct;
