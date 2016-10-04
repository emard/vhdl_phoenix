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

entity phoenix_fleafpga is
generic
(
  C_ps2_keyboard: boolean := true;
  C_clock_blinky: boolean := true
);
port
(
  sys_clock   : in    std_logic;  -- main clock input from 25MHz clock source
  Shield_reset: inout std_logic;  -- Buffered reset signal out to GPIO header

  -- PS2 interface
  PS2_clk1    : inout std_logic;
  PS2_data1   : inout std_logic;

  -- HDMI interface
  LVDS_Red    : out   std_logic;
  LVDS_Green  : out   std_logic;
  LVDS_Blue   : out   std_logic;
  LVDS_ck     : out   std_logic;

  -- LED indicators
  User_LED1   : inout std_logic;
  User_LED2   : out   std_logic;
  User_n_PB1  : in    std_logic
);
end;

architecture struct of phoenix_fleafpga is
  signal clk_dvi, clk_dvin, clk_pixel, clk_stable: std_logic;

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;

  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  
  signal reset        : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');

  signal kbd_intr      : std_logic;
  signal kbd_scancode  : std_logic_vector(7 downto 0);
  signal JoyPCFRLDU    : std_logic_vector(7 downto 0);
  signal btn_coin, btn_left, btn_right, btn_barrier, btn_fire: std_logic;
  signal btn_player_start: std_logic_vector(1 downto 0);
  
  -- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
  signal R_blinky: std_logic_vector(25 downto 0);
  signal R_blinky_shift: std_logic_vector(27 downto 0);
begin
  I_clk_25_d125_25: entity work.clk_25_d125_25
  port map(
    CLKI        =>  sys_clock, --  50 MHz
    CLKOP       =>  clk_dvi,   -- 125 MHz
    CLKOS       =>  clk_dvin,  -- 125 MHz inverted
    CLKOS2      =>  clk_pixel, --  25 MHz
    LOCK        =>  clk_stable
  );
  reset <= not clk_stable;

  dip_switch(3 downto 0) <= (others => '0');

  G_ps2_keyboard: if C_ps2_keyboard generate
    -- get scancode from keyboard
    keybord: entity work.io_ps2_keyboard
    port map
    (
      clk       => clk_pixel,
      kbd_clk   => PS2_clk1,
      kbd_dat   => PS2_data1,
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
    btn_coin            <= JoyPCFRLDU(7); -- F3 : Add coin
    btn_player_start(1) <= JoyPCFRLDU(6); -- F2 : Start 2 Players
    btn_player_start(0) <= JoyPCFRLDU(5); -- F1 : Start 1 Player
    btn_fire            <= JoyPCFRLDU(4); -- SPACE : Fire
    btn_right           <= JoyPCFRLDU(3); -- RIGHT arrow : Right
    btn_left            <= JoyPCFRLDU(2); -- LEFT arrow  : Left
    btn_barrier         <= JoyPCFRLDU(0); -- UP arrow : Protection 
  end generate;

  G_clock_blinky: if C_clock_blinky generate
    process(clk_pixel)
    begin
      if rising_edge(clk_pixel) then
        R_blinky <= R_blinky + 1;
      end if;
    end process;

    process(clk_dvi)
    begin
      if rising_edge(clk_dvi) then
        R_blinky_shift <= R_blinky_shift + 1;
      end if;
    end process;
  end generate;

  phoenix: entity work.phoenix
  generic map
  (
    C_prog_rom_addr_bits => 13,
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
    btn_barrier  => btn_barrier,
    btn_fire     => btn_fire,
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank
  );

  -- some debugging with LEDs
  user_led1 <= R_blinky(R_blinky'high);
  user_led2 <= R_blinky_shift(R_blinky_shift'high);
  --led(5) <= S_vga_r(1); -- when game works, changing color on
  --led(6) <= S_vga_g(1); -- large area of the screen should
  --led(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs

  vga2dvi_converter: entity work.vga2dvid
  generic map
  (
      C_ddr     => true,
      C_depth   => 2 -- 2bpp (2 bit per pixel)
  )
  port map
  (
      clk_pixel => clk_pixel, -- 25 MHz
      clk_shift => clk_dvi, -- 125 MHz

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

  -- vendor specific modules to
  -- convert single ended DDR to phyisical output signals
  G_vgatext_ddrout: entity work.ddr_dvid_out_se
  port map (
    clk       => clk_dvi,
    clk_n     => clk_dvin,
    in_red    => dvid_red,
    in_green  => dvid_green,
    in_blue   => dvid_blue,
    in_clock  => dvid_clock,
    out_red   => LVDS_Red,
    out_green => LVDS_Green,
    out_blue  => LVDS_Blue,
    out_clock => LVDS_ck
  );

end struct;
