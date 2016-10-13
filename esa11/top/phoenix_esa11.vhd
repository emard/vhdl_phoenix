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
generic
(
  C_test_picture: boolean := false;
  C_hdmi_ddr: boolean := false;
  C_hdmi_audio: boolean := true -- true: use hdmi-audio core, false: hdmi simple core (video-only)
);
port
(
  i_100MHz_P, i_100MHz_N: in std_logic;

  M_EXPMOD0, M_EXPMOD1, M_EXPMOD2, M_EXPMOD3: inout std_logic_vector(7 downto 0); -- EXPMODs
  M_DIP: in std_logic_vector(3 downto 0);
  M_7SEG_A, M_7SEG_B, M_7SEG_C, M_7SEG_D, M_7SEG_E, M_7SEG_F, M_7SEG_G, M_7SEG_DP: out std_logic;
  M_7SEG_DIGIT: out std_logic_vector(3 downto 0);
  M_LED: out std_logic_vector(7 downto 0);
  -- PS/2 keyboard
  PS2_A_DATA, PS2_A_CLK, PS2_B_DATA, PS2_B_CLK: inout std_logic;
  -- AUDIO
  AUDIO_L, AUDIO_R: out std_logic;
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
  end component;

  component clk_d100_100_200_250_25MHz is
  Port (
      clk_100mhz_in_p : in STD_LOGIC;
      clk_100mhz_in_n : in STD_LOGIC;
      clk_100mhz : out STD_LOGIC;
      clk_200mhz : out STD_LOGIC;
      clk_250mhz : out STD_LOGIC;
      clk_25mhz : out STD_LOGIC;
      reset : in STD_LOGIC;
      locked : out STD_LOGIC
  );
  end component;

  signal clk_pixel, clk_pixel_shift: std_logic;

  signal kbd_intr      : std_logic;
  signal kbd_scancode  : std_logic_vector(7 downto 0);
  signal JoyPCFRLDU    : std_logic_vector(7 downto 0);

  signal coin         : std_logic;
  signal player_start : std_logic_vector(1 downto 0);
  signal button_left, button_right, button_protect, button_fire: std_logic;

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_r8, S_vga_g8, S_vga_b8: std_logic_vector(7 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  signal S_hdmi_pd0, S_hdmi_pd1, S_hdmi_pd2: std_logic_vector(9 downto 0);
  signal tmds_d: std_logic_vector(3 downto 0);
  signal tx_in: std_logic_vector(29 downto 0);
  signal tmds_rgb: std_logic_vector(2 downto 0);
  signal tmds_clk: std_logic;

  signal S_audio: std_logic_vector(11 downto 0);
  signal S_audio_pwm: std_logic;

  signal reset        : std_logic;
  signal clock_stable : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
begin
  G_hdmi_sdr: if not C_hdmi_ddr generate
  clk100in_out100_200_250_25: clk_d100_100_200_250_25MHz
  port map
  (
    clk_100mhz_in_p => i_100MHz_P,
    clk_100mhz_in_n => i_100MHz_N,
    reset => '0',
    locked => clock_stable,
    clk_100mhz => open,
    clk_200mhz => open,
    clk_250mhz => clk_pixel_shift,
    clk_25mhz  => clk_pixel
  );
  end generate;

  G_hdmi_ddr: if C_hdmi_ddr generate
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
  end generate;

  reset <= not clock_stable;
  dip_switch(3 downto 0) <= M_HEX(3 downto 0);

  -- get scancode from keyboard
  keybord : entity work.io_ps2_keyboard
  port map (
    clk       => clk_pixel,
    kbd_clk   => ps2_a_clk,
    kbd_dat   => ps2_a_data,
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
  coin            <= not JoyPCFRLDU(7); -- F3 : Insert coin
  player_start(1) <= not JoyPCFRLDU(6); -- F2 : Start 2 Players
  player_start(0) <= not JoyPCFRLDU(5); -- F1 : Start 1 Player
  button_fire     <= not JoyPCFRLDU(4); -- SPACE : Fire
  button_right    <= not JoyPCFRLDU(3); -- RIGHT arrow : Right
  button_left     <= not JoyPCFRLDU(2); -- LEFT arrow  : Left
  button_protect  <= not JoyPCFRLDU(0); -- UP arrow : Protection

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
    btn_coin     => not M_BTN(2),
    btn_player_start(0) => not M_BTN(3),
    btn_player_start(1) => not M_BTN(1),
    btn_left     => not M_BTN(0),
    btn_right    => not M_BTN(4),
    btn_barrier  => not M_BTN(1),
    btn_fire     => not M_BTN(3),
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank,
    -- audio_select => audio_select,
    audio        => S_audio
  );
  M_7SEG_A <= kbd_scancode(0);
  M_7SEG_B <= kbd_scancode(1);
  M_7SEG_C <= kbd_scancode(2);
  M_7SEG_D <= kbd_scancode(3);
  M_7SEG_E <= kbd_scancode(4);
  M_7SEG_F <= kbd_scancode(5);
  M_7SEG_G <= kbd_scancode(6);
  M_7SEG_DP <= kbd_scancode(7);
  M_7SEG_DIGIT <= "0001";

  -- some debugging with LEDs
  M_LED(0) <= kbd_scancode(0);
  M_LED(1) <= kbd_scancode(1);
  M_LED(2) <= kbd_scancode(2);
  M_LED(3) <= kbd_scancode(3);
  M_LED(4) <= kbd_scancode(4);
  M_LED(5) <= S_vga_r(1); -- when game works, changing color on
  M_LED(6) <= S_vga_g(1); -- large area of the screen should
  M_LED(7) <= S_vga_b(1); -- also be "visible" on RGB indicator LEDs

  G_hdmi_no_audio: if not C_hdmi_audio generate
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
      I_AUDIO_ENABLE => M_DIP(0),
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
    GENERIC MAP
    (
      C_output_bits => 1
    )
    PORT MAP
    (
      tx_in => tx_in,
      tx_inclock => CLK_PIXEL_SHIFT, -- NOTE: generic serializer needs I_CLK_PIXEL_x10
      tx_syncclock => CLK_PIXEL,
      tx_out => tmds_d
    );

    -- differential output buffering for HDMI clock and video
    av_hdmi_output: entity work.hdmi_out
    port map
    (
      tmds_in_clk => tmds_d(3), -- clk_25MHz or tmds_clk
      tmds_out_clk_p => VID_CLK_P,
      tmds_out_clk_n => VID_CLK_N,
      tmds_in_rgb => tmds_d(2 downto 0),
      tmds_out_rgb_p => VID_D_P,
      tmds_out_rgb_n => VID_D_N
    );
  end generate;

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
