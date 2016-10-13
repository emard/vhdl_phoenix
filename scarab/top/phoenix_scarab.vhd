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

entity phoenix_scarab is
generic
(
  C_test_picture: boolean := false;
  C_hdmi_audio_islands: std_logic := '0'; -- for hdmi-audio core: generate audio islands
  C_hdmi_audio: boolean := true -- ture: use hdmi-audio core, false: hdmi simple core (video-only)
);
port(
  clk_50mhz: in std_logic;
  porta: in std_logic_vector(6 downto 0);
  sw: in std_logic_vector(4 downto 1);
  
  AUDIO_L, AUDIO_R: out std_logic;

  -- warning TMDS_in is used as output
  -- TMDS_in_P, TMDS_in_N: out std_logic_vector(2 downto 0);
  -- TMDS_in_CLK_P, TMDS_in_CLK_N: out std_logic;
  -- FPGA_SDA, FPGA_SCL: inout std_logic; -- i2c on TMDS_in
  TMDS_out_P, TMDS_out_N: out std_logic_vector(2 downto 0);
  TMDS_out_CLK_P, TMDS_out_CLK_N: out std_logic;
 
  leds      : out std_logic_vector(7 downto 0)
);
end phoenix_scarab;

architecture struct of phoenix_scarab is
  signal clk_pixel, clk_pixel_shift: std_logic;
 

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_r8, S_vga_g8, S_vga_b8: std_logic_vector(7 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;

  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  signal S_hdmi_pd0, S_hdmi_pd1, S_hdmi_pd2: std_logic_vector(9 downto 0);
  signal tmds_d: std_logic_vector(3 downto 0);
  signal tx_in: std_logic_vector(29 downto 0);

  signal S_audio: std_logic_vector(11 downto 0);
  signal S_audio_pwm: std_logic;

  signal reset        : std_logic;
  signal clock_stable : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
begin
  clk_50_50_250_25_11MHz : entity work.clk_50_50_250_25_11MHz
  port map
  (
    reset => '0',
    locked => clock_stable,
    CLK_50M_IN  => clk_50MHz,
    CLK_50M => open,
    CLK_11M => open,
    CLK_250M => clk_pixel_shift,
    CLK_25M => clk_pixel
  );
  
  reset <= not clock_stable;
  dip_switch(3 downto 0) <= sw(4 downto 1);

  phoenix : entity work.phoenix
  generic map
  (
    C_test_picture => C_test_picture,
    C_audio => true,
    C_vga => true
  )
  port map
  (
    clk_pixel    => clk_pixel,
    reset        => reset,
    dip_switch   => dip_switch,
    btn_coin     => not porta(0),
    btn_player_start(0) => not porta(1),
    btn_player_start(1) => not porta(2),
    btn_left     => not porta(3),
    btn_right    => not porta(4),
    btn_barrier  => not porta(5),
    btn_fire     => not porta(6),
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank
  );
  -- some debugging with LEDs
  leds(0) <= not porta(0);
  leds(1) <= (not porta(1)) or (not porta(2));
  leds(2) <= not porta(3);
  leds(3) <= not porta(4);
  leds(4) <= (not porta(5)) or (not porta(6));
  leds(5) <= S_vga_r(1); -- when game works, changing color on
  leds(6) <= S_vga_g(1); -- large area of the screen should
  leds(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs

  G_hdmi_no_audio: if not C_hdmi_audio generate
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

    hdmi_output1: entity work.hdmi_out
    port map
    (
      tmds_in_clk    => dvid_clock(0), -- clk_25MHz or tmds_clk
      tmds_out_clk_p => tmds_out_clk_p,
      tmds_out_clk_n => tmds_out_clk_n,
      tmds_in_rgb    => dvid_red(0) & dvid_green(0) & dvid_blue(0),
      tmds_out_rgb_p => tmds_out_p,
      tmds_out_rgb_n => tmds_out_n
    );

--  hdmi_output2: entity work.hdmi_out
--  port map
--  (
--    tmds_in_clk    => dvid_clock(0), -- clk_25MHz or tmds_clk
--    tmds_out_clk_p => tmds_in_clk_p,
--    tmds_out_clk_n => tmds_in_clk_n,
--    tmds_in_rgb    => dvid_red(0) & dvid_green(0) & dvid_blue(0),
--    tmds_out_rgb_p => tmds_in_p,
--    tmds_out_rgb_n => tmds_in_n
--  );
  end generate;

  G_hdmi_yes_audio: if C_hdmi_audio generate
    S_vga_r8 <= S_vga_r & S_vga_r(0) & S_vga_r(0) & S_vga_r(0) & S_vga_r(0) & S_vga_r(0) & S_vga_r(0);
    S_vga_g8 <= S_vga_g & S_vga_g(0) & S_vga_g(0) & S_vga_g(0) & S_vga_g(0) & S_vga_g(0) & S_vga_g(0);
    S_vga_b8 <= S_vga_b & S_vga_b(0) & S_vga_b(0) & S_vga_b(0) & S_vga_b(0) & S_vga_b(0) & S_vga_b(0);
    av_hdmi_out: entity work.av_hdmi
    generic map
    (
      FREQ => 25000000,
      FS => 48000,
      CTS => 25000,
      N => 6144
    )
    port map
    (
      I_CLK_PIXEL    => clk_pixel,
      I_R            => S_vga_r8,
      I_G            => S_vga_g8,
      I_B            => S_vga_b8,
      I_BLANK        => S_vga_blank,
      I_HSYNC        => not S_vga_hsync,
      I_VSYNC        => not S_vga_vsync,
      I_AUDIO_ENABLE => C_hdmi_audio_islands,
      I_AUDIO_PCM_L  => S_audio & "0000",
      I_AUDIO_PCM_R  => S_audio & "0000",
      O_TMDS_PD0     => S_HDMI_PD0,
      O_TMDS_PD1     => S_HDMI_PD1,
      O_TMDS_PD2     => S_HDMI_PD2
    );

    -- tx_in <= S_HDMI_PD2 & S_HDMI_PD1 & S_HDMI_PD0; -- this would be normal bit order, but
    -- generic serializer follows vendor specific serializer style
    tx_in <=  S_HDMI_PD2(0) & S_HDMI_PD2(1) & S_HDMI_PD2(2) & S_HDMI_PD2(3) & S_HDMI_PD2(4) & S_HDMI_PD2(5) & S_HDMI_PD2(6) & S_HDMI_PD2(7) & S_HDMI_PD2(8) & S_HDMI_PD2(9) &
              S_HDMI_PD1(0) & S_HDMI_PD1(1) & S_HDMI_PD1(2) & S_HDMI_PD1(3) & S_HDMI_PD1(4) & S_HDMI_PD1(5) & S_HDMI_PD1(6) & S_HDMI_PD1(7) & S_HDMI_PD1(8) & S_HDMI_PD1(9) &
              S_HDMI_PD0(0) & S_HDMI_PD0(1) & S_HDMI_PD0(2) & S_HDMI_PD0(3) & S_HDMI_PD0(4) & S_HDMI_PD0(5) & S_HDMI_PD0(6) & S_HDMI_PD0(7) & S_HDMI_PD0(8) & S_HDMI_PD0(9);

    generic_serializer_inst: entity work.serializer_generic
    PORT MAP
    (
      tx_in => tx_in,
      tx_inclock => CLK_PIXEL_SHIFT, -- NOTE: generic serializer needs I_CLK_PIXEL_x10
      tx_syncclock => CLK_PIXEL,
      tx_out => tmds_d
    );
    dvid_clock(0) <= tmds_d(3);
    dvid_red(0)   <= tmds_d(2);
    dvid_green(0) <= tmds_d(1);
    dvid_blue(0)  <= tmds_d(0);

    av_hdmi_output1: entity work.hdmi_out
    port map
    (
      tmds_in_clk    => dvid_clock(0), -- clk_25MHz or tmds_clk
      tmds_out_clk_p => tmds_out_clk_p,
      tmds_out_clk_n => tmds_out_clk_n,
      tmds_in_rgb    => dvid_red(0) & dvid_green(0) & dvid_blue(0),
      tmds_out_rgb_p => tmds_out_p,
      tmds_out_rgb_n => tmds_out_n
    );
  end generate;

  -- output audio to 3.5mm jack
  sigma_delta_dac: entity work.dac
  generic map
  (
    C_bits => 8
  )
  port map
  (
    clk_i => clk_pixel,
    res_n_i => '1', -- never reset
    dac_i => S_audio(11 downto 4),
    dac_o => S_audio_pwm
  );

  audio_l <= S_audio_pwm;
  audio_r <= S_audio_pwm;

end struct;
