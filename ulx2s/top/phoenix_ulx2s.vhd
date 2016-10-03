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

entity phoenix_ulx2s is
generic
(
  C_clock_blinky: boolean := true
);
port(
    clk_25m: in std_logic;
    rs232_tx: out std_logic;
    rs232_rx: in std_logic;
    flash_so: in std_logic;
    flash_cen, flash_sck, flash_si: out std_logic;
    sdcard_so: in std_logic;
    sdcard_cen, sdcard_sck, sdcard_si: out std_logic;
    p_ring: out std_logic;
    p_tip: out std_logic_vector(3 downto 0);
    led: out std_logic_vector(7 downto 0);
    btn_left, btn_right, btn_up, btn_down, btn_center: in std_logic;
    sw: in std_logic_vector(3 downto 0);
    j1_2, j1_3, j1_4, j1_8, j1_9, j1_13, j1_14, j1_15: inout std_logic;
    j1_16, j1_17, j1_18, j1_19, j1_20, j1_21, j1_22, j1_23: inout std_logic;
    j2_2, j2_3, j2_4, j2_5, j2_6, j2_7, j2_8, j2_9: inout std_logic;
    j2_10, j2_11, j2_12, j2_13, j2_16: inout std_logic;
    sram_a: out std_logic_vector(18 downto 0);
    sram_d: inout std_logic_vector(15 downto 0);
    sram_wel, sram_lbl, sram_ubl: out std_logic
    -- sram_oel: out std_logic -- XXX the old ULXP2 board needs this!
);
end;

architecture struct of phoenix_ulx2s is
  signal clk_pixel, clk_pixel_shift, clk_stable: std_logic;

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;

  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  
  signal reset        : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
  signal R_blinky: std_logic_vector(25 downto 0);
  signal R_blinky_shift: std_logic_vector(28 downto 0);
begin
  reset <= not clk_stable;
  dip_switch(3 downto 0) <= sw(3 downto 0);

  clk_25_250_25MHz: entity work.clk_25_250_25
  port map
  (
    CLK => clk_25m, -- 25 MHz input
    CLKOP => clk_pixel_shift, -- 250 MHz
    CLKOK => clk_pixel, -- 25 MHz
    LOCK => clk_stable
  );

  G_clock_blinky: if C_clock_blinky generate
    process(clk_pixel)
    begin
      if rising_edge(clk_pixel) then
        R_blinky <= R_blinky + 1;
      end if;
    end process;

    process(clk_pixel_shift)
    begin
      if rising_edge(clk_pixel_shift) then
        R_blinky_shift <= R_blinky_shift + 1;
      end if;
    end process;
  end generate;

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
    ps2_clk      => j1_2, -- ps2_clk,
    ps2_dat      => j1_3, -- ps2_dat,
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank
  );

  -- some debugging with LEDs
  led(0) <= R_blinky(R_blinky'high);
  led(1) <= R_blinky_shift(R_blinky_shift'high);
  --led(2) <= not csync;
  --led(3) <= vblank;
  --led(4) <= blank;
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

      in_hsync => S_vga_hsync,
      in_vsync => S_vga_vsync,
      in_blank => S_vga_blank,

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
        tmds_out_rgb_p(2) => j1_22,  -- D2+ red    JB2
        tmds_out_rgb_n(2) => j2_9,   -- D2- red    JB6
        tmds_out_rgb_p(1) => j1_21,  -- D1+ green  JB3
        tmds_out_rgb_n(1) => j2_8,   -- D1- green  JB7
        tmds_out_rgb_p(0) => j1_20,  -- D0+ blue   JB4
        tmds_out_rgb_n(0) => j2_7,   -- D0- blue   JB8
        tmds_in_clk    => dvid_clock(0),
        tmds_out_clk_p => j1_23, -- CLK+ clock     JB1
        tmds_out_clk_n => j2_16  -- CLK- clock     JB5
  );

end struct;
