---------------------------------------------------------------------------------
-- TB276 Top level for Phoenix by Emard
--
-- Main features
--  NO board SRAM used
--
-- place jumper to 76-77 to ehable hdmi-audio
--
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_reverseu16 is
generic
(
  C_hdmi_generic_serializer: boolean := false; -- serializer type: false: vendor-specific, true: generic=vendor-agnostic
  C_hdmi_audio: boolean := true -- HDMI generator type: false: video only, true: video+audio capable
);
port
(
  clk_50MHz: in std_logic;
  -- USB input (joystick)
  usb_reset_n, usb_tx: in std_logic;
  usb_si: in std_logic; -- USB_NEWFRAME for atari800
  usb_io1: in std_logic; -- USB_NEWFRAME for nes
  usb_cs_n: out std_logic; -- USB_VNC_MODE_N
  -- for vendor-specific serializer
  hdmi_d0, hdmi_d1, hdmi_d2: out std_logic;
  hdmi_clk: out std_logic
  -- for generic serializer
  --hdmi_dp, hdmi_dn: out std_logic_vector(2 downto 0);
  --hdmi_clkp, hdmi_clkn: out std_logic
);
end;

architecture struct of phoenix_reverseu16 is
  signal clk_pixel, clk_pixel_shift: std_logic;

  signal joy_report: std_logic_vector(71 downto 0);
  signal S_joy_hat: std_logic_vector(3 downto 0);
  signal S_joy_left, S_joy_right: std_logic;
  signal S_joy_left_pad_x: std_logic_vector(7 downto 0);

  signal S_audio: std_logic_vector(11 downto 0);
 
  signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
  signal S_hdmi_pd0, S_hdmi_pd1, S_hdmi_pd2: std_logic_vector(9 downto 0);
  signal tmds_d: std_logic_vector(3 downto 0);
  signal tx_in: std_logic_vector(29 downto 0);

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_r8, S_vga_g8, S_vga_b8: std_logic_vector(7 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;

  signal reset        : std_logic;
  signal clock_stable : std_logic;
  signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
begin
  G_sdr: if C_hdmi_generic_serializer or not C_hdmi_audio generate
    clkgen_250_25: entity work.pll_50M_250M_25M_83M333
    port map
    (
      inclk0 => clk_50MHz,    --  50 MHz input from board
      c0 => clk_pixel_shift,  -- 250 MHz
      c1 => clk_pixel,        --  25 MHz
      c2 => open              --  83.333 MHz
    );
    clock_stable <= '1';
  end generate;

  G_ddr: if C_hdmi_audio and not C_hdmi_generic_serializer generate
    clkgen_125_25: entity work.clk_50M_125M_25M
    port map
    (
      inclk0 => clk_50MHz,   --  50 MHz input from board
      c0 => clk_pixel_shift, -- 125 MHz
      c1 => clk_pixel,       --  25 MHz
      locked => clock_stable
    );
  end generate;

  reset <= not clock_stable;

  -- the user input device
  hid: entity work.vnc2hid
  generic map
  (
    C_clock_freq => 25000000,
    C_baud_rate => 115200
  )
  port map
  (
    CLK => clk_pixel, 
    RESET_N => '1',
    USB_TX => USB_TX,
    HID_REPORT => joy_report,
    NEW_VNC2_MODE_N => usb_cs_n,
    NEW_FRAME => usb_io1
  );
  -- dp <= usb_tx; -- debug serial traffic to external rs232
  
  S_joy_hat <= joy_report(17*4+3 downto 17*4);
  S_joy_left_pad_x <= joy_report(4*4+7 downto 4*4);
  S_joy_left  <= '1' when S_joy_hat=5 or S_joy_hat=6 or S_joy_hat=7 or S_joy_left_pad_x < 126 else '0';
  S_joy_right <= '1' when S_joy_hat=1 or S_joy_hat=2 or S_joy_hat=3 or S_joy_left_pad_x > 130 else '0';

  phoenix : entity work.phoenix
  generic map
  (
    C_autofire => true,
    C_audio => true,
    C_osd => true,
    C_vga => true
  )
  port map
  (
    clk_pixel    => clk_pixel,
    reset        => reset,
    osd_hex      => joy_report(71 downto 8),
    dip_switch   => dip_switch,
    btn_coin     => joy_report(16*4+2), -- FPS
    btn_player_start(0) => joy_report(15*4+2), -- BACK
    btn_player_start(1) => joy_report(15*4+3), -- START
    btn_left     => S_joy_left, -- hat left
    btn_right    => S_joy_right, -- hat right
    btn_barrier  => joy_report(13*4+2), -- blue X
    btn_fire     => joy_report(15*4+1), -- right trigger
    vga_r        => S_vga_r,
    vga_g        => S_vga_g,
    vga_b        => S_vga_b,
    vga_hsync    => S_vga_hsync,
    vga_vsync    => S_vga_vsync,
    vga_blank    => S_vga_blank,
    audio        => S_audio
  );

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
      I_AUDIO_ENABLE => '0',
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

    G_generic_serializer: if C_hdmi_generic_serializer generate
      generic_serializer_inst: entity work.serializer_generic
      PORT MAP
      (
        tx_in => tx_in,
        tx_inclock => CLK_PIXEL_SHIFT, -- NOTE: generic serializer needs CLK_PIXEL x10
        tx_syncclock => CLK_PIXEL,
        tx_out => tmds_d
      );
      hdmi_clk <= tmds_d(3);
      hdmi_d2  <= tmds_d(2);
      hdmi_d1  <= tmds_d(1);
      hdmi_d0  <= tmds_d(0);
    end generate;
    G_vendor_specific_serializer: if not C_hdmi_generic_serializer generate
      generic_serializer_inst: entity work.serializer
      PORT MAP
      (
        tx_in => tx_in,
        tx_inclock => CLK_PIXEL_SHIFT, -- NOTE: vendor-specific serializer needs CLK_PIXEL x5
        tx_syncclock => CLK_PIXEL,
        tx_out => tmds_d(2 downto 0)
      );
      hdmi_clk <= CLK_PIXEL;
      hdmi_d2  <= tmds_d(2);
      hdmi_d1  <= tmds_d(1);
      hdmi_d0  <= tmds_d(0);
    end generate;
  end generate;
end struct;
