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
port(
  clk_50mhz: in std_logic;
  porta: in std_logic_vector(6 downto 0);
  sw: in std_logic_vector(4 downto 1);

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
 
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  -- signal audio        : std_logic_vector(11 downto 0);
  -- signal sound_string : std_logic_vector(31 downto 0);

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
    -- audio_select => audio_select,
    -- audio        => audio
    -- adr_cpu_out  => adr_cpu,
    -- do_prog      => sram_dq(7 downto 0)
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

-- synchro composite/ synchro horizontale
-- vga_hs <= csync when tv15Khz_mode = '1' else hsync;
-- commutation rapide / synchro verticale
-- vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

--sound_string <= "0000" & audio & "0000" & audio;

--wm8731_dac : entity work.wm8731_dac
--port map(
-- clk18MHz => clk18,
-- sampledata => sound_string,
-- i2c_sclk => i2c_sclk,
-- i2c_sdat => i2c_sdat,
-- aud_bclk => aud_bclk,
-- aud_daclrck => aud_daclrck,
-- aud_dacdat => aud_dacdat,
-- aud_xck => aud_xck
-- ); 

end struct;
