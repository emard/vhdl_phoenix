---------------------------------------------------------------------------------
-- DE2-35 Top level for Phoenix by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix is
generic (
  C_test_picture: boolean := false;
  C_tile_rom: boolean := true; -- false: disable tile ROM to try game logic on small FPGA
  -- reduce ROMs: 14 is normal game, 13 will draw initial screen, 12 will repeatedly blink 1 line of garbage
  C_autofire: boolean := false;
  C_audio: boolean := true;
  C_prog_rom_addr_bits: integer range 12 to 14 := 14; 
  C_osd: boolean := false;
  C_vga: boolean := true
);
port(
 clk_pixel    : in std_logic; -- 11 MHz for TV, 25 MHz for VGA
 reset        : in std_logic;

 osd_hex      : in std_logic_vector(63 downto 0) := (others => '0');

 dip_switch   : in std_logic_vector(7 downto 0);
 -- game controls, normal logic '1':pressed, '0':released
 btn_coin: in std_logic;
 btn_player_start: in std_logic_vector(1 downto 0);
 btn_fire, btn_left, btn_right, btn_barrier: in std_logic;

 vga_r, vga_g, vga_b: out std_logic_vector(1 downto 0);
 vga_hsync, vga_vsync, vga_blank, vga_vblank: out std_logic;

 video_r      : out std_logic_vector(1 downto 0);
 video_g      : out std_logic_vector(1 downto 0);
 video_b      : out std_logic_vector(1 downto 0);
 video_clk    : out std_logic;
 video_csync  : out std_logic;
 video_vblank, video_hblank_bg, video_hblank_fg: out std_logic;
 video_hs     : out std_logic;
 video_vs     : out std_logic;

 sound_fire   : out std_logic; -- '1' when missile fires
 sound_explode: out std_logic; -- '1' when ship explodes
 sound_burn   : out std_logic; -- bird burns
 sound_fireball: out std_logic; -- bird explodes in 2 fireballs
 sound_ab     : out std_logic_vector(15 downto 0);
 audio_select : in std_logic_vector(2 downto 0) := (others => '0');
 audio        : out std_logic_vector(11 downto 0)
);
end phoenix;

architecture struct of phoenix is

 signal reset_n: std_logic;

 signal hclk   : std_logic;
 signal hclk_n : std_logic;
 signal hclk_div: std_logic;
 signal hcnt, S_hcnt   : std_logic_vector(9 downto 1);
 signal vcnt   : std_logic_vector(8 downto 1);
 signal S_vcnt: std_logic_vector(9 downto 1);
 signal sync   : std_logic;
 signal adrsel : std_logic; 
 signal rdy    : std_logic := '1'; 
 signal vblank       : std_logic;
 signal hblank_bkgrd : std_logic;
 signal hblank_frgrd : std_logic; 
 signal S_vga_blank, S_vga_vblank: std_logic;
 signal S_vga_vsync, S_vga_hsync: std_logic;
 signal S_vga_fetch_next: std_logic;
 signal S_osd_pixel: std_logic;
 signal S_osd_green: std_logic_vector(1 downto 0) := (others => '0');
 signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(1 downto 0);

 signal cpu_adr  : std_logic_vector(15 downto 0);
 signal cpu_di   : std_logic_vector( 7 downto 0);
 signal cpu_do   : std_logic_vector( 7 downto 0);
 signal cpu_wr_n : std_logic;
 signal prog_do  : std_logic_vector( 7 downto 0);
 signal S_prog_rom_addr : std_logic_vector(13 downto 0);

 signal frgnd_horz_cnt : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_horz_cnt : std_logic_vector(7 downto 0) := (others =>'0');
 signal vert_cnt       : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal bkgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal frgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal bkgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal frgnd_ram_we : std_logic := '0';
 signal bkgnd_ram_we : std_logic := '0';

 signal frgnd_graph_adr : std_logic_vector(10 downto 0) := (others =>'0');
 signal bkgnd_graph_adr : std_logic_vector(10 downto 0) := (others =>'0');
 signal palette_adr     : std_logic_vector( 7 downto 0) := (others =>'0'); 

 signal frgnd_clk : std_logic;
 signal bkgnd_clk : std_logic;

 signal frgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal frgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_bit0_graph_r : std_logic_vector(7 downto 0) := (others =>'0');
 signal frgnd_bit1_graph_r : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit0_graph_r : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit1_graph_r : std_logic_vector(7 downto 0) := (others =>'0');

 signal fr_bit0  : std_logic;
 signal fr_bit1  : std_logic;
 signal bk_bit0  : std_logic;
 signal bk_bit1  : std_logic;
 signal fr_lin   : std_logic_vector(2 downto 0);
 signal bk_lin   : std_logic_vector(2 downto 0);

 signal color_set : std_logic;
 signal color_id  : std_logic_vector(5 downto 0);
 signal rgb_0     : std_logic_vector(7 downto 0);
 signal rgb_1     : std_logic_vector(7 downto 0);

 signal player2      : std_logic := '0';
 signal pl2_cocktail : std_logic := '0';
 signal bkgnd_offset : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_a      : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_b      : std_logic_vector(7 downto 0) := (others =>'0');

 signal clk10 : std_logic;
 signal snd1  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal snd2  : std_logic_vector( 1 downto 0) := (others =>'0');
 signal snd3  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal song  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal mixed : std_logic_vector(11 downto 0) := (others =>'0');
 signal sound_string : std_logic_vector(31 downto 0);

 signal coin         : std_logic;
 signal player_start : std_logic_vector(1 downto 0);
 signal buttons      : std_logic_vector(3 downto 0);
 signal R_autofire   : std_logic_vector(21 downto 0);
begin

-- game core uses inverted control logic
coin <= not btn_coin; -- insert coin
player_start <= not btn_player_start; -- select 1 or 2 players
buttons(1) <= not btn_right; -- Right
buttons(2) <= not btn_left; -- Left
buttons(3) <= not btn_barrier; -- Protection 

G_not_autofire: if not C_autofire generate
  buttons(0) <= not btn_fire; -- Fire
end generate;

G_yes_autofire: if C_autofire generate
  process(clk_pixel)
  begin
    if rising_edge(clk_pixel) then
      if btn_fire='1' then
        R_autofire <= R_autofire-1;
      else
        R_autofire <= (others => '0');
      end if;
    end if;
  end process;
  buttons(0) <= not R_autofire(R_autofire'high);
end generate;

-- video address/sync generator
G_tv: if not C_vga generate
video_gen : entity work.phoenix_video
port map(
 clk11    => clk_pixel,
 reset    => reset,
 hclk     => hclk,
 hcnt     => hcnt,
 vcnt     => vcnt,
 adrsel   => adrsel, -- RAM address selector ('0')cpu / ('1')video_generator
 rdy      => rdy,    -- Ready ('1')cpu can access RAMs read/write 
 vblank       => vblank,
 hblank_frgrd => hblank_frgrd,
 hblank_bkgrd => hblank_bkgrd
);
hclk_n  <= not hclk;
reset_n <= not reset;
end generate;

G_vga: if C_vga generate
  G_tv_vga_helper:
  entity work.phoenix_video_vga
  port map
  (
    clk11    => clk_pixel,
    hcnt     => hcnt,
    vcnt     => S_vcnt,
    sync     => sync,
    vsync    => video_vs,
    hsync    => video_hs,
    adrsel   => adrsel, -- RAM address selector ('0')cpu / ('1')video_generator
    rdy      => rdy,    -- Ready ('1')cpu can access RAMs read/write 
    vblank   => vblank,
    hblank_frgrd => hblank_frgrd,
    hblank_bkgrd => hblank_bkgrd,
    reset    => reset
  );
  reset_n <= not reset;

  process(clk_pixel)
  begin
    if rising_edge(clk_pixel) then
      hclk <= not hclk;
      hclk_n <= not hclk;
    end if;
  end process;

  -- VGA video generator - pixel clock synchronous
  vgabitmap: entity work.vga
  --generic map -- workaround for wrong video size
  --(
  --  C_resolution_x => 638,
  --  C_hsync_front_porch => 18
  --)
  port map (
      clk_pixel => clk_pixel,
      test_picture => '1', -- shows test picture when VGA is disabled (on startup)
      fetch_next => S_vga_fetch_next,
      line_repeat => open,
      red_byte    => (others => '0'), -- framebuffer inputs not used
      green_byte  => (others => '0'), -- rgb signal is synchronously generated
      blue_byte   => (others => '0'), -- and replaced
      beam_x(9 downto 1) => hcnt,
      beam_x(0 downto 0) => open,
      beam_y(9 downto 9) => open,
      beam_y(8 downto 0) => S_vcnt,
      vga_r(7 downto 6) => S_vga_r, vga_r(5 downto 0) => open,
      vga_g(7 downto 6) => S_vga_g, vga_g(5 downto 0) => open,
      vga_b(7 downto 6) => S_vga_b, vga_b(5 downto 0) => open,
      vga_hsync => S_vga_hsync,
      vga_vsync => S_vga_vsync,
      vga_blank => S_vga_blank, -- '1' when outside of horizontal or vertical graphics area
      vga_vblank => S_vga_vblank -- '1' when outside of vertical graphics area (used for vblank interrupt)
  );
  vga_hsync <= S_vga_hsync;
  vga_vsync <= S_vga_vsync;
  --adrsel <= '1' when hcnt < 32 else '0';
  --rdy <= S_vga_blank;
  --vblank <= S_vga_vblank;
  --hblank_frgrd <= S_vga_blank and not S_vga_vblank;
  --hblank_bkgrd <= S_vga_blank and not S_vga_vblank;
  vcnt <= S_vcnt(8 downto 1);

  -- OSD overlay for the green channel
  G_osd: if C_osd generate
  I_osd: entity work.osd
  --generic map -- workaround for wrong video size
  --(
  --  C_resolution_x => C_resolution_x
  --)
  port map
  (
    clk_pixel => clk_pixel,
    vsync => S_vga_vsync,
    fetch_next => S_vga_fetch_next,
    probe_in(63 downto 0) => osd_hex(63 downto 0),
    osd_out => S_osd_pixel
  );
  S_osd_green <= (others => S_osd_pixel);
  end generate;

  G_yes_test_picture: if C_test_picture generate
    -- only test picture, no game
    vga_r     <= S_vga_r;
    vga_g     <= S_vga_g or S_osd_green;
    vga_b     <= S_vga_b;
  end generate;
  G_no_test_picture: if not C_test_picture generate
    -- normal game picture
    vga_r     <= rgb_1(0) & rgb_0(0);
    vga_g     <= (rgb_1(2) & rgb_0(2)) or S_osd_green;
    vga_b     <= rgb_1(1) & rgb_0(1);
  end generate;
  vga_blank <= S_vga_blank;
  vga_vblank <= S_vga_vblank;
end generate;

-- microprocessor 8085
cpu8085 : entity work.T8080se
 generic map(Mode => 2, T2Write => 0)
port map(
 RESET_n => reset_n,
 CLK     => clk_pixel,
 CLKEN  => '1', -- fixme: use it to make 5.5 MHz clock average
 READY  => rdy,
 HOLD  => '1',
 INT   => '1',
 INTE  => open,
 DBIN  => open,
 SYNC  => open, 
 VAIT  => open,
 HLDA  => open,
 WR_n  => cpu_wr_n,
 A     => cpu_adr,
 DI   => cpu_di,
 DO   => cpu_do
);

-- mux prog, ram, vblank, switch... to processor data bus in
cpu_di <= prog_do when cpu_adr(14) = '0' else
          frgnd_ram_do when cpu_adr(13 downto 10) = 2#00_00# else
          bkgnd_ram_do when cpu_adr(13 downto 10) = 2#00_10# else
          buttons & '1' & player_start & coin when cpu_adr(13 downto 10) = 2#11_00# else
          not vblank & dip_switch(6 downto 0) when cpu_adr(13 downto 10) = 2#11_10# else
          prog_do;

-- write enable to RAMs from cpu
frgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(14 downto 10) = "10000" and adrsel = '0' else '0';
bkgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(14 downto 10) = "10010" and adrsel = '0' else '0';

-- RAMs address mux cpu/video_generator, bank0 for player1, bank1 for player2
frgnd_ram_adr <= player2 & cpu_adr(9 downto 0) when adrsel ='0' else player2 & vert_cnt(7 downto 3) & frgnd_horz_cnt(7 downto 3); 
bkgnd_ram_adr <= player2 & cpu_adr(9 downto 0) when adrsel ='0' else player2 & vert_cnt(7 downto 3) & bkgnd_horz_cnt(7 downto 3); 

-- demux cpu data to registers : background scrolling, sound control,
-- player id (1/2), palette color set. 
process (clk_pixel)
begin
 if rising_edge(clk_pixel) then
  if cpu_wr_n = '0' then
   case cpu_adr(14 downto 10) is
    when "10110" => bkgnd_offset <= cpu_do;
    when "11000" => sound_b      <= cpu_do;
    when "11010" => sound_a      <= cpu_do;
    when "10100" => player2      <= cpu_do(0);
                    color_set    <= cpu_do(1);
    when others => null;
   end case;
  end if; 
 end if;
end process;

-- player2 and cocktail mode (flip horizontal/vertical)
pl2_cocktail <= player2 and dip_switch(7);

-- horizontal scan video RAMs address background and foreground
-- with flip and scroll offset
frgnd_horz_cnt <= hcnt(8 downto 1) when pl2_cocktail = '0' else not hcnt(8 downto 1);
bkgnd_horz_cnt <= frgnd_horz_cnt + bkgnd_offset;

-- vertical scan video RAMs address
vert_cnt <= S_vcnt(9 downto 2) when pl2_cocktail = '0' else not (S_vcnt(9 downto 2) + X"30");

-- get tile_ids from RAMs
frgnd_tile_id <= frgnd_ram_do;
bkgnd_tile_id <= bkgnd_ram_do; 

-- address graphix ROMs with tile_ids and line counter
frgnd_graph_adr <= frgnd_tile_id & vert_cnt(2 downto 0);
bkgnd_graph_adr <= bkgnd_tile_id & vert_cnt(2 downto 0);

-- latch foreground/background next graphix byte, high bit and low bit
-- and palette_ids (fr_lin, bklin)
process (clk_pixel)
begin
 if rising_edge(clk_pixel) then
  if (pl2_cocktail = '0' and (frgnd_horz_cnt(2 downto 0) = "111")) or
     (pl2_cocktail = '1' and (frgnd_horz_cnt(2 downto 0) = "000")) then
     frgnd_bit0_graph_r <= frgnd_bit0_graph;
     frgnd_bit1_graph_r <= frgnd_bit1_graph;
     fr_lin <= frgnd_tile_id(7 downto 5);
  end if;
  if (pl2_cocktail = '0' and (bkgnd_horz_cnt(2 downto 0) = "111")) or
     (pl2_cocktail = '1' and (bkgnd_horz_cnt(2 downto 0) = "000")) then  
     bkgnd_bit0_graph_r <= bkgnd_bit0_graph;
     bkgnd_bit1_graph_r <= bkgnd_bit1_graph;
     bk_lin <= bkgnd_tile_id(7 downto 5);
  end if;
 end if;
end process;

-- demux background and foreground pixel bits (0/1) from graphix byte with horizontal counter
-- and apply horizontal and vertical blanking
fr_bit0 <= frgnd_bit0_graph_r(to_integer(unsigned(frgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_frgrd)= '0' else '0'; 
fr_bit1 <= frgnd_bit1_graph_r(to_integer(unsigned(frgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_frgrd)= '0' else '0'; 
bk_bit0 <= bkgnd_bit0_graph_r(to_integer(unsigned(bkgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_bkgrd)= '0' else '0'; 
bk_bit1 <= bkgnd_bit1_graph_r(to_integer(unsigned(bkgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_bkgrd)= '0' else '0'; 

-- select pixel bits and palette_id with foreground priority
color_id  <=  (fr_bit0 or fr_bit1) &  fr_bit1 & fr_bit0 & fr_lin when (fr_bit0 or fr_bit1) = '1' else
              (fr_bit0 or fr_bit1) &  bk_bit1 & bk_bit0 & bk_lin;

-- address palette with pixel bits color and color set
palette_adr <= '0' & color_set & color_id;

-- output video to top level
video_clk   <= hclk;
video_csync <= sync;
video_vblank <= vblank;
video_hblank_fg <= hblank_frgrd;
video_hblank_bg <= hblank_bkgrd;
video_r     <= rgb_1(0) & rgb_0(0);
video_g     <= rgb_1(2) & rgb_0(2);
video_b     <= rgb_1(1) & rgb_0(1);

G_yes_tile_rom: if C_tile_rom generate
-- foreground graphix ROM bit0
frgnd_bit0 : entity work.prom_ic39
port map(
 clk  => hclk_n,
 addr => frgnd_graph_adr,
 data => frgnd_bit0_graph
);

-- foreground graphix ROM bit1
frgnd_bit1 : entity work.prom_ic40
port map(
 clk  => hclk_n,
 addr => frgnd_graph_adr,
 data => frgnd_bit1_graph
);

-- background graphix ROM bit0
bkgnd_bit0 : entity work.prom_ic23
port map(
 clk  => hclk_n,
 addr => bkgnd_graph_adr,
 data => bkgnd_bit0_graph
);

-- background graphix ROM bit1
bkgnd_bit1 : entity work.prom_ic24
port map(
 clk  => hclk_n,
 addr => bkgnd_graph_adr,
 data => bkgnd_bit1_graph
);

-- color palette ROM RBG low intensity
palette_0 : entity work.prom_palette_ic40
port map(
 clk  => hclk,
 addr => palette_adr,
 data => rgb_0
);

-- color palette ROM RBG high intensity
palette_1 : entity work.prom_palette_ic41
port map(
 clk  => hclk,
 addr => palette_adr,
 data => rgb_1
);
end generate;

G_no_tile_rom: if not C_tile_rom generate
  -- dummy replacement for missing tile ROMs
  frgnd_bit0_graph <= frgnd_graph_adr(10 downto 3);
  frgnd_bit1_graph <= "00000000";
  bkgnd_bit0_graph <= bkgnd_graph_adr(10 downto 3);
  bkgnd_bit1_graph <= "00000000";
  rgb_0 <= palette_adr;
  rgb_1 <= palette_adr;
end generate;

-- Program PROM
S_prog_rom_addr(C_prog_rom_addr_bits-1 downto 0) <= cpu_adr(C_prog_rom_addr_bits-1 downto 0);
prog : entity work.phoenix_prog
port map(
 clk  => clk_pixel,
 addr => S_prog_rom_addr,
 data => prog_do
);

-- foreground RAM   0x4000-0x433F
-- cpu working area 0x4340-0x43FF 
frgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => clk_pixel,
 we   => frgnd_ram_we,
 addr => frgnd_ram_adr,
 d    => cpu_do,
 q    => frgnd_ram_do
);

-- background RAM   0x4800-0x4B3F
-- cpu working area 0x4B40-0x4BFF 
-- stack pointer downward from 0x4BFF
bkgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => clk_pixel,
 we   => bkgnd_ram_we,
 addr => bkgnd_ram_adr,
 d    => cpu_do,
 q    => bkgnd_ram_do
);

G_audio: if C_audio generate
effect1: entity work.phoenix_effect1
port map
(
  clk50    => clk_pixel,
  clk10    => clk_pixel,
  reset    => '0',
  trigger  => sound_a(4),
  filter   => sound_a(5),
  divider  => sound_a(3 downto 0),
  snd      => snd1
);

effect2 : entity work.phoenix_effect2
port map
(
  clk50    => clk_pixel,
  clk10    => clk_pixel,
  reset    => '0',
  trigger1 => sound_b(4),
  trigger2 => sound_b(5),
  divider  => sound_b(3 downto 0),
  snd      => snd2
);

effect3 : entity work.phoenix_effect3
port map
(
  clk50    => clk_pixel,
  clk10    => clk_pixel,
  reset    => '0',
  trigger1 => sound_b(6),
  trigger2 => sound_b(7),
  snd      => snd3
);

sound_burn <= sound_b(4);
sound_fire <= sound_b(6); -- '1' when fire sound
sound_explode <= sound_b(7); -- '1' when explode sound
sound_fireball <= sound_a(1) and not sound_a(0); -- ambiguity: mothership descend also triggers this
sound_ab <= sound_b & sound_a;

music: entity work.phoenix_music
port map
(
  clk10    => clk_pixel,
  reset    => '0',
  trigger  => sound_a(7),
  sel_song => sound_a(6),
  snd      => song
);

-- mix effects and music
mixed <= std_logic_vector
       (
         unsigned("00"  & snd1 & "00") +
         unsigned("0"   & snd2 & "000000000") +
         unsigned("00"  & snd3 & "00") +
         unsigned("00"  & song & "00" )
       );

-- select sound or/and effect
with audio_select select
audio <= "00"   & snd1  & "00"        when "100",
         "0"    & snd2  & "000000000" when "101",
         "00"   & snd3  & "00"        when "110",
         "00"   & song  & "00"        when "111",
                  mixed               when others;
end generate;

end struct;
