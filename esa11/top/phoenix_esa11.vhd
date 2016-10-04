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

entity phoenix_esa11 is
port
(
  i_100MHz_P, i_100MHz_N: in std_logic;

  M_EXPMOD0, M_EXPMOD1, M_EXPMOD2, M_EXPMOD3: inout std_logic_vector(7 downto 0); -- EXPMODs
  M_7SEG_A, M_7SEG_B, M_7SEG_C, M_7SEG_D, M_7SEG_E, M_7SEG_F, M_7SEG_G, M_7SEG_DP: out std_logic;
  M_7SEG_DIGIT: out std_logic_vector(3 downto 0);
  M_LED: out std_logic_vector(7 downto 0);
  -- PS/2 keyboard
  PS2_A_DATA, PS2_A_CLK, PS2_B_DATA, PS2_B_CLK: inout std_logic;
  -- HDMI
  VID_D_P, VID_D_N: out std_logic_vector(2 downto 0);
  VID_CLK_P, VID_CLK_N: out std_logic;
  -- VGA
  VGA_RED, VGA_GREEN, VGA_BLUE: out std_logic_vector(7 downto 0);
  VGA_SYNC_N, VGA_BLANK_N, VGA_CLOCK_P: out std_logic;
  VGA_HSYNC, VGA_VSYNC: out std_logic;
  M_BTN: in std_logic_vector(4 downto 0);
  M_HEX: in std_logic_vector(3 downto 0)
);
end;

architecture struct of phoenix_esa11 is
  component clk_d100_100_200_125_25MHz is
  Port (
      clk_100mhz_in_p : in STD_LOGIC;
      clk_100mhz_in_n : in STD_LOGIC;
      clk_100mhz : out STD_LOGIC;
      clk_200mhz : out STD_LOGIC;
      clk_125mhz : out STD_LOGIC;
      clk_25mhz : out STD_LOGIC;
      reset : in STD_LOGIC;
      locked : out STD_LOGIC
  );
  end component clk_d100_100_200_125_25MHz;

  signal clk_pixel, clk_pixel_shift: std_logic;
 
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  signal tmds_rgb: std_logic_vector(2 downto 0);
  signal tmds_clk: std_logic;

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
  clk100in_out100_200_125_25: clk_d100_100_200_125_25MHz
  port map
  (
    clk_100mhz_in_p => i_100MHz_P,
    clk_100mhz_in_n => i_100MHz_N,
    reset => '0',
    locked => clock_stable,
    clk_100mhz => open,
    clk_200mhz => open,
    clk_125mhz => clk_pixel_shift,
    clk_25mhz  => clk_pixel
  );

  reset <= not clock_stable;
  dip_switch(3 downto 0) <= M_HEX(3 downto 0);

  phoenix: entity work.phoenix
  generic map
  (
    C_vga => true
  )
  port map
  (
    clk_pixel    => clk_pixel,
    reset        => reset,
    dip_switch   => dip_switch,
    btn_coin     => not M_BTN(0),
    btn_player_start(0) => not M_BTN(1),
    btn_player_start(1) => not M_BTN(2),
    btn_left     => not M_BTN(1),
    btn_right    => not M_BTN(2),
    btn_barrier  => not M_BTN(3),
    btn_fire     => not M_BTN(4),
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
  --M_LED(0) <= not porta(0);
  --M_LED(1) <= (not porta(1)) or (not porta(2));
  --M_LED(2) <= not porta(3);
  --M_LED(3) <= not porta(4);
  --M_LED(4) <= (not porta(5)) or (not porta(6));
  M_LED(5) <= S_vga_r(1); -- when game works, changing color on
  M_LED(6) <= S_vga_g(1); -- large area of the screen should
  M_LED(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs

  vga2dvi_converter: entity work.vga2dvid
  generic map
  (
      C_ddr     => true,
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

  G_vga_ddrout: entity work.ddr_dvid_out_se
  port map
  (
      clk       => clk_pixel_shift,
      clk_n     => '0', -- inverted shift clock not needed on xilinx
      in_red    => dvid_red,
      in_green  => dvid_green,
      in_blue   => dvid_blue,
      in_clock  => dvid_clock,
      out_red   => tmds_rgb(2),
      out_green => tmds_rgb(1),
      out_blue  => tmds_rgb(0),
      out_clock => tmds_clk
  );

  -- differential output buffering for HDMI clock and video
  hdmi_output: entity work.hdmi_out
  port map
  (
    tmds_in_clk => tmds_clk, -- clk_25MHz or tmds_clk
    tmds_out_clk_p => VID_CLK_P,
    tmds_out_clk_n => VID_CLK_N,
    tmds_in_rgb => tmds_rgb,
    tmds_out_rgb_p => VID_D_P,
    tmds_out_rgb_n => VID_D_N
  );

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
