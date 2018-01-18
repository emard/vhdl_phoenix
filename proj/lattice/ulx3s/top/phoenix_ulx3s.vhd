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

library ecp5u;
use ecp5u.components.all;

entity phoenix_ulx3s is
generic
(
  C_ps2_keyboard: boolean := false;
  C_clock_blinky: boolean := false
);
port(
  clk_25MHz: in std_logic;

  -- UART1 (WiFi serial)
  wifi_rxd: out   std_logic;
  wifi_txd: in    std_logic;
  -- WiFi additional signaling
  wifi_en: inout  std_logic := 'Z'; -- '0' will disable wifi by default
  wifi_gpio0, wifi_gpio2, wifi_gpio16, wifi_gpio17: inout std_logic := 'Z';
  
  usb_fpga_dp, usb_fpga_dn: inout  std_logic := 'Z'; -- US2 connector

  -- Onboard blinky
  led: out std_logic_vector(7 downto 0);
  btn: in std_logic_vector(6 downto 0);
  sw: in std_logic_vector(3 downto 0);
  oled_csn, oled_clk, oled_mosi, oled_dc, oled_resn: out std_logic;

  -- GPIO
  gp, gn: inout std_logic_vector(27 downto 0);

  -- SHUTDOWN: logic '1' here will shutdown power on PCB >= v1.7.5
  shutdown: out std_logic := '0';

  -- Audio jack 3.5mm
  audio_l, audio_r, audio_v: inout std_logic_vector(3 downto 0) := (others => 'Z');

  -- for vendor-specific serializer
  --hdmi_d0, hdmi_d1, hdmi_d2: out std_logic;
  --hdmi_clk: out std_logic

  -- Digital Video (differential outputs)
  gpdi_dp, gpdi_dn: out std_logic_vector(2 downto 0);
  gpdi_clkp, gpdi_clkn: out std_logic;

  -- i2c shared for digital video and RTC
  gpdi_scl, gpdi_sda: inout std_logic

    --rs232_tx: out std_logic;
    --rs232_rx: in std_logic;
    --flash_so: in std_logic;
    --flash_cen, flash_sck, flash_si: out std_logic;
    --sdcard_so: in std_logic;
    --sdcard_cen, sdcard_sck, sdcard_si: out std_logic;
    --p_ring: out std_logic;
    --p_tip: out std_logic_vector(3 downto 0);
    --led: out std_logic_vector(7 downto 0);
    --btn_left, btn_right, btn_up, btn_down, btn_center: in std_logic;
    --sw: in std_logic_vector(3 downto 0);
    --j1_2, j1_3, j1_4, j1_8, j1_9, j1_13, j1_14, j1_15: inout std_logic;
    --j1_16, j1_17, j1_18, j1_19, j1_20, j1_21, j1_22, j1_23: inout std_logic;
    --j2_2, j2_3, j2_4, j2_5, j2_6, j2_7, j2_8, j2_9: inout std_logic;
    --j2_10, j2_11, j2_12, j2_13, j2_16: inout std_logic;
    --sram_a: out std_logic_vector(18 downto 0);
    --sram_d: inout std_logic_vector(15 downto 0);
    --sram_wel, sram_lbl, sram_ubl: out std_logic
    -- sram_oel: out std_logic -- XXX the old ULXP2 board needs this!
);
end;

architecture struct of phoenix_ulx3s is
  signal clk_pixel, clk_pixel_shift, clkn_pixel_shift: std_logic;
  signal clk_stable: std_logic := '1';

  signal S_audio: std_logic_vector(23 downto 0) := (others => '0');
  signal S_spdif_out: std_logic;
  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  signal ddr_d: std_logic_vector(2 downto 0);
  signal ddr_clk: std_logic;

  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  
  signal reset        : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');

  signal kbd_intr      : std_logic;
  signal kbd_scancode  : std_logic_vector(7 downto 0);
  signal JoyPCFRLDU    : std_logic_vector(7 downto 0);

  signal btn_coin, btn_fire, btn_barrier, btn_left, btn_right: std_logic;
  signal btn_player_start: std_logic_vector(1 downto 0);

  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
  signal R_blinky: std_logic_vector(25 downto 0);
  signal R_blinky_shift: std_logic_vector(28 downto 0);
begin
  wifi_gpio0 <= btn(0);

  G_ddr: if true generate
    clkgen_125_25: entity work.clk_25_100_125_25
    port map
    (
      clki => clk_25MHz,         --  25 MHz input from board
      clkop => clk_pixel_shift,  -- 125 MHz
      clkos => clkn_pixel_shift, -- 125 MHz inverted
      clkos2 => clk_pixel,       --  25 MHz
      clkos3 => open             -- 100 MHz
    );
  end generate;

  reset <= not clk_stable;
  dip_switch(3 downto 0) <= sw(3 downto 0);

  G_yes_ps2_keyboard: if C_ps2_keyboard generate
    -- get scancode from keyboard
    keybord: entity work.io_ps2_keyboard
    port map
    (
      clk       => clk_pixel,
      kbd_clk   => usb_fpga_dp, -- D+
      kbd_dat   => usb_fpga_dn, -- D-
      interrupt => kbd_intr,
      scancode  => kbd_scancode
    );

    -- translate scancode to joystick
    Joystick: entity work.kbd_joystick
    port map
    (
      clk         => clk_pixel,
      kbdint      => kbd_intr,
      kbdscancode => std_logic_vector(kbd_scancode), 
      JoyPCFRLDU  => JoyPCFRLDU 
    );

    -- joystick to inputs
    btn_coin            <= not JoyPCFRLDU(7); -- F3 : Add coin
    btn_player_start(1) <= not JoyPCFRLDU(6); -- F2 : Start 2 Players
    btn_player_start(0) <= not JoyPCFRLDU(5); -- F1 : Start 1 Player
    btn_left            <= not JoyPCFRLDU(2); -- LEFT arrow  : Left
    btn_right           <= not JoyPCFRLDU(3); -- RIGHT arrow : Right
    btn_fire            <= not JoyPCFRLDU(4); -- SPACE : Fire
    btn_barrier         <= not JoyPCFRLDU(0); -- UP arrow : Protection 
  end generate;

  G_no_ps2_keyboard: if not C_ps2_keyboard generate
    btn_coin            <= btn(4);   -- down  : insert coin
    btn_player_start(0) <= btn(3);   -- up    : Start 1 Player
    btn_player_start(1) <=    '0';   -- none  : Start 2 Players
    btn_left            <= btn(5);   -- LEFT arrow  : Left
    btn_right           <= btn(6);   -- RIGHT arrow : Right
    btn_fire            <= btn(1);   -- btn1  : Fire
    btn_barrier         <= btn(2);   -- btn2  : Protection 
  end generate;

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
    C_audio => true,
    C_vga => true
  )
  port map
  (
    clk_pixel    => clk_pixel,
    reset        => reset,
    dip_switch   => dip_switch,
    btn_coin     => btn_coin,
    btn_player_start => btn_player_start,
    btn_left     => btn_left,
    btn_right    => btn_right,
    btn_fire     => btn_fire,
    btn_barrier  => btn_barrier,
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank,
    audio        => S_audio(23 downto 12)
  );
  
  G_spdif_out: entity work.spdif_tx
  generic map
  (
    C_clk_freq => 25000000,  -- Hz
    C_sample_freq => 48000   -- Hz
  )
  port map
  (
    clk => clk_pixel,
    data_in => S_audio,
    spdif_out => S_spdif_out
  );
  audio_l(3 downto 0) <= S_audio(23 downto 20);
  audio_r(3 downto 0) <= S_audio(23 downto 20);
  audio_v(1 downto 0) <= (others => S_spdif_out);

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
      C_ddr     => true,
      C_depth   => 2 -- 2bpp (2 bit per pixel)
  )
  port map
  (
      clk_pixel => clk_pixel, -- 25 MHz
      clk_shift => clk_pixel_shift, -- 125 MHz

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

  -- this module instantiates vendor specific modules ddr_out to
  -- convert SDR 2-bit input to DDR clocked 1-bit output (single-ended)
  G_vgatext_ddrout: entity work.ddr_dvid_out_se
  port map
  (
    clk       => clk_pixel_shift,
    clk_n     => clkn_pixel_shift,
    in_red    => dvid_red,
    in_green  => dvid_green,
    in_blue   => dvid_blue,
    in_clock  => dvid_clock,
    out_red   => ddr_d(2),
    out_green => ddr_d(1),
    out_blue  => ddr_d(0),
    out_clock => ddr_clk
  );

  gpdi_data_channels: for i in 0 to 2 generate
    gpdi_diff_data: OLVDS
    port map(A => ddr_d(i), Z => gpdi_dp(i), ZN => gpdi_dn(i));
  end generate;
  gpdi_diff_clock: OLVDS
  port map(A => ddr_clk, Z => gpdi_clkp, ZN => gpdi_clkn);
  
  


end struct;
