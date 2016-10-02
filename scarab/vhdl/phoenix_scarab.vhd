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
 clk_50mhz  : in std_logic;
-- clock_27  : in std_logic;
-- ext_clock : in std_logic;
-- ledr      : out std_logic_vector(17 downto 0);
-- ledg      : out std_logic_vector(8 downto 0);
 portd     : in std_logic_vector(3 downto 0);
 sw        : in std_logic_vector(4 downto 1);

-- dram_ba_0  : out std_logic;
-- dram_ba_1  : out std_logic;
-- dram_ldqm  : out std_logic;
-- dram_udqm  : out std_logic;
-- dram_ras_n : out std_logic;
-- dram_cas_n : out std_logic;
-- dram_cke   : out std_logic;
-- dram_clk   : out std_logic;
-- dram_we_n  : out std_logic;
-- dram_cs_n  : out std_logic;
-- dram_dq    : inout std_logic_vector(15 downto 0);
-- dram_addr  : out std_logic_vector(11 downto 0);
--
-- fl_addr  : out std_logic_vector(21 downto 0);
-- fl_ce_n  : out std_logic;
-- fl_oe_n  : out std_logic;
-- fl_dq    : inout std_logic_vector(7 downto 0);
-- fl_rst_n : out std_logic;
-- fl_we_n  : out std_logic;
--
-- hex0 : out std_logic_vector(6 downto 0);
-- hex1 : out std_logic_vector(6 downto 0);
-- hex2 : out std_logic_vector(6 downto 0);
-- hex3 : out std_logic_vector(6 downto 0);
-- hex4 : out std_logic_vector(6 downto 0);
-- hex5 : out std_logic_vector(6 downto 0);
-- hex6 : out std_logic_vector(6 downto 0);
-- hex7 : out std_logic_vector(6 downto 0);

-- ps2_clk : in std_logic;
-- ps2_dat : inout std_logic;

-- uart_txd : out std_logic;
-- uart_rxd : in std_logic;
--
-- lcd_rw   : out std_logic;
-- lcd_en   : out std_logic;
-- lcd_rs   : out std_logic;
-- lcd_data : out std_logic_vector(7 downto 0);
-- lcd_on   : out std_logic;
-- lcd_blon : out std_logic;
 
-- sram_addr : out std_logic_vector(17 downto 0);
-- sram_dq   : inout std_logic_vector(15 downto 0);
-- sram_we_n : out std_logic;
-- sram_oe_n : out std_logic;
-- sram_ub_n : out std_logic;
-- sram_lb_n : out std_logic;
-- sram_ce_n : out std_logic;
 
-- otg_addr   : out std_logic_vector(1 downto 0);
-- otg_cs_n   : out std_logic;
-- otg_rd_n   : out std_logic;
-- otg_wr_n   : out std_logic;
-- otg_rst_n  : out std_logic;
-- otg_data   : inout std_logic_vector(15 downto 0);
-- otg_int0   : in std_logic;
-- otg_int1   : in std_logic;
-- otg_dack0_n: out std_logic;
-- otg_dack1_n: out std_logic;
-- otg_dreq0  : in std_logic;
-- otg_dreq1  : in std_logic;
-- otg_fspeed : inout std_logic;
-- otg_lspeed : inout std_logic;
-- 
-- tdi : in std_logic;
-- tcs : in std_logic;
-- tck : in std_logic;
-- tdo : out std_logic;

    -- warning TMDS_in is used as output
    TMDS_in_P, TMDS_in_N: out std_logic_vector(2 downto 0);
    TMDS_in_CLK_P, TMDS_in_CLK_N: out std_logic;
    FPGA_SDA, FPGA_SCL: inout std_logic; -- i2c on TMDS_in
    TMDS_out_P, TMDS_out_N: out std_logic_vector(2 downto 0);
    TMDS_out_CLK_P, TMDS_out_CLK_N: out std_logic;
 
 vga_r     : out std_logic_vector(2 downto 0);
 vga_g     : out std_logic_vector(2 downto 0);
 vga_b     : out std_logic_vector(1 downto 0);
 vga_clk   : out std_logic;
 vga_blank : out std_logic;
 vga_hs    : out std_logic;
 vga_vs    : out std_logic;
 vga_sync  : out std_logic;
 
 leds      : out std_logic_vector(7 downto 0)

 --i2c_sclk : out std_logic;
 --i2c_sdat : inout std_logic;
 
-- td_clk27 : in std_logic;
-- td_reset : out std_logic;
-- td_data  : in std_logic_vector(7 downto 0);
-- td_hs    : in std_logic;
-- td_vs    : in std_logic;

 --aud_adclrck : out std_logic;
 --aud_adcdat  : in std_logic;
 --aud_daclrck : out std_logic;
 --aud_dacdat  : out std_logic;
 --aud_xck     : out std_logic;
 --aud_bclk    : out std_logic
 
-- enet_data  : inout std_logic_vector(15 downto 0);
-- enet_clk   : out std_logic;
-- enet_cmd   : out std_logic;
-- enet_cs_n  : out std_logic;
-- enet_int   : in std_logic;
-- enet_rd_n  : out std_logic;
-- enet_wr_n  : out std_logic;
-- enet_rst_n : out std_logic;
-- 
-- irda_txd : out std_logic;
-- irda_rxd : in std_logic;
-- 
-- sd_dat  : inout std_logic;
-- sd_dat3 : out std_logic;
-- sd_cmd  : out std_logic;
-- sd_clk  : out std_logic;
-- 
-- gpio_0  : inout std_logic_vector(35 downto 0)
-- gpio_1  : inout std_logic_vector(35 downto 0)
);
end phoenix_scarab;

architecture struct of phoenix_scarab is

 signal clk_11m  : std_logic;
 signal clk_25m  : std_logic;
 signal clk_50m  : std_logic;
 signal clk_250m : std_logic;
 
 signal r         : std_logic_vector(1 downto 0);
 signal g         : std_logic_vector(1 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal video_clk : std_logic;
 signal csync, vblank, hblank_fg, hblank_bg: std_logic;
 signal hsync, vsync, blank: std_logic;
 signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);

  signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);
  signal S_vga_vsync, S_vga_hsync: std_logic;
  signal S_vga_vblank, S_vga_blank: std_logic;
  
  signal S_pixel_clk_blinky: std_logic_vector(25 downto 0);

-- signal audio        : std_logic_vector(11 downto 0);
-- signal sound_string : std_logic_vector(31 downto 0);
 signal reset        : std_logic;
 
 signal dip_switch   : std_logic_vector(7 downto 0) := (others => '0');
-- alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
  
begin

reset <= sw(1);
dip_switch(3 downto 0) <= sw(4 downto 1);

-- tv15Khz_mode <= sw();

clk_50_50_250_25_11MHz : entity work.clk_50_50_250_25_11MHz
port map(
reset => '0',
locked => open,
CLK_50M_IN  => clk_50MHz,
CLK_50M => clk_50m,
CLK_11M => clk_11m,
CLK_250M => clk_250m,
CLK_25M => clk_25m
);

phoenix : entity work.phoenix
port map(
 clk_50m     => clk_50m,
 clock_11     => clk_25m,
-- reset        => writing_ram,
 reset        => reset,
-- tv15Khz_mode => tv15Khz_mode,
 dip_switch   => dip_switch,
 ps2_clk      => portd(0), -- ps2_clk,
 ps2_dat      => portd(1), -- ps2_dat,
 vga_r        => S_vga_r,
 vga_g        => S_vga_g,
 vga_b        => S_vga_b,
 vga_hsync    => S_vga_hsync,
 vga_vsync    => S_vga_vsync,
 vga_blank    => S_vga_blank,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_clk    => video_clk,
 video_csync  => csync,
 video_vblank => vblank,
 video_hblank_fg => hblank_fg,
 video_hblank_bg => hblank_bg,
 video_hs     => hsync,
 video_vs     => vsync
 -- audio_select => audio_select,
 --audio        => audio
-- adr_cpu_out  => adr_cpu,
-- do_prog      => sram_dq(7 downto 0)
);
--vga_clk   <= video_clk;
--vga_sync  <= '0';
--vga_blank <= '1';
blank <= vblank or hblank_fg or hblank_bg;

vga_hs    <= hsync;
vga_vs    <= vsync;

vga_r <= r & r(0);
vga_g <= g & g(0);
vga_b <= b;

leds(0) <= not hsync;
leds(1) <= not vsync;
leds(2) <= not csync;
leds(3) <= vblank;
leds(4) <= S_pixel_clk_blinky(S_pixel_clk_blinky'high);
leds(5) <= r(1);
leds(6) <= g(1);
leds(7) <= b(1);

--process(clk_50m)
--begin
--  if rising_edge(clk_50m) then
--    S_pixel_clk_blinky <= S_pixel_clk_blinky + 1;
--  end if;
--end process;

vga2dvi_converter: entity work.vga2dvid
generic map
(
      C_ddr     => false,
      C_depth   => 2 -- 2bpp (2 bit per pixel)
)
port map
(
      clk_pixel => clk_25m, -- clk_25m
      clk_shift => clk_250m,

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

hdmi_output2: entity work.hdmi_out
port map
(
  tmds_in_clk    => dvid_clock(0), -- clk_25MHz or tmds_clk
  tmds_out_clk_p => tmds_in_clk_p,
  tmds_out_clk_n => tmds_in_clk_n,
  tmds_in_rgb    => dvid_red(0) & dvid_green(0) & dvid_blue(0),
  tmds_out_rgb_p => tmds_in_p,
  tmds_out_rgb_n => tmds_in_n
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
