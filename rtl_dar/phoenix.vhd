---------------------------------------------------------------------------------
-- DE2-35 Top level for Phoenix by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix is
port(
 clock_50     : in std_logic;
 clock_11     : in std_logic;
 reset        : in std_logic;
-- tv15Khz_mode : in std_logic;
 dip_switch   : in std_logic_vector(7 downto 0);
 ps2_clk      : in std_logic;
 ps2_dat      : in std_logic;
 video_r      : out std_logic_vector(1 downto 0);
 video_g      : out std_logic_vector(1 downto 0);
 video_b      : out std_logic_vector(1 downto 0);
 video_clk    : out std_logic;
 video_csync  : out std_logic;
-- video_blank  : out std_logic;
-- video_hs     : out std_logic;
-- video_vs     : out std_logic;
 audio_select : in std_logic_vector(2 downto 0);
 audio        : out std_logic_vector(11 downto 0)
);
end phoenix;

architecture struct of phoenix is

 signal reset_n: std_logic;

 signal hclk   : std_logic;
 signal hclk_n : std_logic;
 signal hcnt   : std_logic_vector(9 downto 1);
 signal vcnt   : std_logic_vector(8 downto 1);
 signal sync   : std_logic;
 signal adrsel : std_logic; 
 signal rdy    : std_logic; 
 signal vblank       : std_logic;
 signal hblank_bkgrd : std_logic;
 signal hblank_frgrd : std_logic; 
 
 signal cpu_adr  : std_logic_vector(15 downto 0);
 signal cpu_di   : std_logic_vector( 7 downto 0);
 signal cpu_do   : std_logic_vector( 7 downto 0);
 signal cpu_wr_n : std_logic;
 signal prog_do  : std_logic_vector( 7 downto 0);
 
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
 
 signal kbd_intr      : std_logic;
 signal kbd_scancode  : std_logic_vector(7 downto 0);
 signal JoyPCFRLDU    : std_logic_vector(7 downto 0);

 signal coin         : std_logic;
 signal player_start : std_logic_vector(1 downto 0);
 signal buttons      : std_logic_vector(3 downto 0);
 
begin

-- make 10MHz clock from 50MHz
process (clock_50)
 variable cnt : std_logic_vector(3 downto 0) := (others => '0');
begin
 if rising_edge(clock_50) then
  cnt := std_logic_vector(unsigned(cnt) + 1);
  clk10 <= '0';
  if cnt = X"5" then
   cnt := (others => '0');
   clk10 <= '1';
  end if;   
 end if;
end process;

-- video address/sync generator
video_gen : entity work.phoenix_video
port map(
 clk11    => clock_11,
 reset    => reset,
 hclk     => hclk,
 hcnt     => hcnt,
 vcnt     => vcnt,
 sync     => sync,
 adrsel   => adrsel, -- RAM address selector ('0')cpu / ('1')video_generator
 rdy      => rdy,    -- Ready ('1')cpu can access RAMs read/write 
 vblank       => vblank,
 hblank_frgrd => hblank_frgrd,
 hblank_bkgrd => hblank_bkgrd
);

hclk_n  <= not hclk;
reset_n <= not reset;

-- microprocessor 8085
cpu8085 : entity work.T8080se
 generic map(Mode => 2, T2Write => 0)
port map(
 RESET_n => reset_n,
 CLK     => hclk_n,
 CLKEN  => '1',
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
process (hclk)
begin
 if rising_edge(hclk) then
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
vert_cnt <= vcnt when pl2_cocktail = '0' else not (vcnt + X"30");

-- get tile_ids from RAMs
frgnd_tile_id <= frgnd_ram_do;
bkgnd_tile_id <= bkgnd_ram_do; 

-- address graphix ROMs with tile_ids and line counter
frgnd_graph_adr <= frgnd_tile_id & vert_cnt(2 downto 0);
bkgnd_graph_adr <= bkgnd_tile_id & vert_cnt(2 downto 0);

-- latch foreground/background next graphix byte, high bit and low bit
-- and palette_ids (fr_lin, bklin)
process (hclk)
begin
 if rising_edge(hclk) then
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
video_r     <= rgb_1(0) & rgb_0(0);
video_g     <= rgb_1(2) & rgb_0(2);
video_b     <= rgb_1(1) & rgb_0(1);

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

-- Program PROM
prog : entity work.phoenix_prog
port map(
 clk  => hclk,
 addr => cpu_adr(13 downto 0),
 data => prog_do
);

-- foreground RAM   0x4000-0x433F
-- cpu working area 0x4340-0x43FF 
frgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => hclk,
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
 clk  => hclk,
 we   => bkgnd_ram_we,
 addr => bkgnd_ram_adr,
 d    => cpu_do,
 q    => bkgnd_ram_do
);

-- sound effect1
effect1 : entity work.phoenix_effect1
port map(
clk50    => clock_50,
clk10    => clk10,
reset    => '0',
trigger  => sound_a(4),
filter   => sound_a(5),
divider  => sound_a(3 downto 0),
snd      => snd1
);

-- sound effect2
effect2 : entity work.phoenix_effect2
port map(
clk50    => clock_50,
clk10    => clk10,
reset    => '0',
trigger1 => sound_b(4),
trigger2 => sound_b(5),
divider  => sound_b(3 downto 0),
snd      => snd2
);

-- sound effect3
effect3 : entity work.phoenix_effect3
port map(
clk50    => clock_50,
clk10    => clk10,
reset    => '0',
trigger1 => sound_b(6),
trigger2 => sound_b(7),
snd      => snd3
);

-- melody
music : entity work.phoenix_music
port map(
clk10    => clk10,
reset    => '0',
trigger  => sound_a(7),
sel_song => sound_a(6),
snd      => song
);

-- mix effects and music
mixed <= std_logic_vector(
      unsigned("00"  & snd1 & "00") +
      unsigned("0"   & snd2 & "000000000")+
      unsigned("00"  & snd3 & "00")+
      unsigned("00"  & song & "00" ));

-- select sound or/and effect
with audio_select select
audio <= "00"   & snd1  & "00"        when "100",
         "0"    & snd2  & "000000000" when "101",
         "00"   & snd3  & "00"        when "110",
         "00"  &  song  & "00"        when "111",
                  mixed               when others;

-- get scancode from keyboard
keybord : entity work.io_ps2_keyboard
port map (
  clk       => clock_11,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
Joystick : entity work.kbd_joystick
port map (
  clk         => clock_11,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  JoyPCFRLDU  => JoyPCFRLDU 
);

-- joystick to inputs
coin            <= not JoyPCFRLDU(7); -- F3 : Add coin
player_start(1) <= not JoyPCFRLDU(6); -- F2 : Start 2 Players
player_start(0) <= not JoyPCFRLDU(5); -- F1 : Start 1 Player
buttons(0)      <= not JoyPCFRLDU(4); -- SPACE : Fire
buttons(1)      <= not JoyPCFRLDU(3); -- RIGHT arrow : Right
buttons(2)      <= not JoyPCFRLDU(2); -- LEFT arrow  : Left
buttons(3)      <= not JoyPCFRLDU(0); -- UP arrow : Protection 

end struct;
