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

entity phoenix_de2 is
port(
 clock_50  : in std_logic;
-- clock_27  : in std_logic;
-- ext_clock : in std_logic;
-- ledr      : out std_logic_vector(17 downto 0);
-- ledg      : out std_logic_vector(8 downto 0);
 key       : in std_logic_vector(3 downto 0);
 sw        : in std_logic_vector(17 downto 0);

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

 ps2_clk : in std_logic;
 ps2_dat : inout std_logic;

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
 
 vga_r     : out std_logic_vector(9 downto 0);
 vga_g     : out std_logic_vector(9 downto 0);
 vga_b     : out std_logic_vector(9 downto 0);
 vga_clk   : out std_logic;
 vga_blank : out std_logic;
 vga_hs    : out std_logic;
 vga_vs    : out std_logic;
 vga_sync  : out std_logic;

 i2c_sclk : out std_logic;
 i2c_sdat : inout std_logic;
 
-- td_clk27 : in std_logic;
-- td_reset : out std_logic;
-- td_data  : in std_logic_vector(7 downto 0);
-- td_hs    : in std_logic;
-- td_vs    : in std_logic;

 aud_adclrck : out std_logic;
 aud_adcdat  : in std_logic;
 aud_daclrck : out std_logic;
 aud_dacdat  : out std_logic;
 aud_xck     : out std_logic;
 aud_bclk    : out std_logic
 
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
end phoenix_de2;

architecture struct of phoenix_de2 is

 signal clk11  : std_logic;
 signal clk18  : std_logic;
 signal pll_locked :std_logic;
 
 signal r         : std_logic_vector(1 downto 0);
 signal g         : std_logic_vector(1 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal video_clk : std_logic;
 signal csync     : std_logic;
 
 signal audio        : std_logic_vector(11 downto 0);
 signal sound_string : std_logic_vector(31 downto 0);
 signal reset        : std_logic;
 
 alias  reset_n      : std_logic is key(0);
 alias  dip_switch   : std_logic_vector(7 downto 0) is sw(7 downto 0);
 alias  audio_select : std_logic_vector(2 downto 0) is sw(10 downto 8);
 
begin

reset <= not reset_n;
-- tv15Khz_mode <= sw();

clk_11_18 : entity work.pll50_to_11_and_18
port map(
 inclk0 => clock_50,
 c0 => clk11,
 c1 => clk18,
 locked => pll_locked
);

phoenix : entity work.phoenix
port map(
 clock_50     => clock_50,
 clock_11     => clk11,
-- reset        => writing_ram,
 reset        => reset,
-- tv15Khz_mode => tv15Khz_mode,
 dip_switch   => dip_switch,
 ps2_clk      => ps2_clk,
 ps2_dat      => ps2_dat,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_clk    => video_clk,
 video_csync  => csync,
-- video_blank  => blank,
-- video_hs     => hsync,
-- video_vs     => vsync,
  audio_select => audio_select,
 audio        => audio
-- adr_cpu_out  => adr_cpu,
-- do_prog      => sram_dq(7 downto 0)
);
vga_clk   <= video_clk;
vga_sync  <= '0';
vga_blank <= '1';
vga_hs    <= csync;
vga_vs    <= '1';

vga_r <= r & "00000000";
vga_g <= g & "00000000";
vga_b <= b & "00000000";

-- synchro composite/ synchro horizontale
-- vga_hs <= csync when tv15Khz_mode = '1' else hsync;
-- commutation rapide / synchro verticale
-- vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

sound_string <= "0000" & audio & "0000" & audio;

wm8731_dac : entity work.wm8731_dac
port map(
 clk18MHz => clk18,
 sampledata => sound_string,
 i2c_sclk => i2c_sclk,
 i2c_sdat => i2c_sdat,
 aud_bclk => aud_bclk,
 aud_daclrck => aud_daclrck,
 aud_dacdat => aud_dacdat,
 aud_xck => aud_xck
); 

end struct;
