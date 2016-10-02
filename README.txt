-------------------------------------------------
Phoenix (Amstar) FPGA - DAR - 2016

-------------------------------------------------
Educational use only
Do not redistribute synthetized file with roms
Do not redistribute roms whatever the form
Use at your own risk

-------------------------------------------------
Update 2016 April 18 : Note

make sure to use phoenix.zip roms 
MAME Phoenix (Amstar)

-------------------------------------------------

TV mode only RBG 15kHz
Vertical screen cabinet or Cocktail mode available

DE-35 top_level

PS2 keyboard input (same control keys for both players)
wm8731 sound output
NO board SRAM used
Uses pll for 18MHz and 11MHz generation from 50MHz

-------------------------------------------------
The original arcade hardware PCB contains 8 memory regions

 cpu addressable space
 
 - program                     rom  16Kx8, cpu only access 0x0000 0x3fff

 - foreground tile map bank 1  ram   1Kx8, vid.gen. & cpu  0x4000 0x433f
   cpu working ram             ram       ,                 0x4340 0x43ff 
 - background tile map bank 1  ram   1Kx8, vid.gen. & cpu  0x4800 0x4b3f
   cpu working ram inc.stack   ram       ,                 0x4b40 0x4bff 
 
 - foreground tile map bank 2  ram   1Kx8, vid.gen. & cpu  0x4000 0x433f
   cpu working ram             ram       ,                 0x4340 0x43ff 
 - background tile map bank 2  ram   1Kx8, vid.gen. & cpu  0x4800 0x4b3f
   cpu working ram             ram       ,                 0x4b40 0x4bff 

 non cpu addressable region   

 - foreground graphics      rom 2Kx16,
 - background graphics      rom 2Kx16,
 - color palettes           rom 128x6,

-------------------------------------------------

The pixel clock is 5.5MHz, the cpu (8085A) clock is 5.5MHz.

The game is based on two RAM tile_id maps, there is no sprite. Cpu manages all 
graphix on its own except background scrolling. 

video generator counts 352 pixels horizontal :
   96 pixels (12 tiles) non visible, 
  256 pixels (32 tiles) visible

video generator counts 256 lines vertical : 
   48 lines ( 6 tiles) non visible,
  208 lines (26 tiles) visible

Video generator scans 32(horizontal)x32(vertical) RAM address, only 0-25
vertical address contains tile_id data. Vertical address from 26 to 31
are used by cpu as working ram including stack.

There are 2 banks at the same address for foreground and also 2 banks for
background. Bank 1 is used to store graphix map for player one, bank 2 is
used to store graphix data for player two. Cpu control bank switching with
register at 0x7800 (data bit 0).

Working ram is made of 0xC0 (192) bytes in each bank of each map 
(foreground/background). So there is 4 x 192 bytes available.

Video generator can be inverted when player 2 and cocktail mode active.
Register at 0x5800 contains a background horizontal counter offset to produce
background scrolling.

Background horizontal blanking start about one tile after foreground horizontal
blanking. This allow to keep clean the top most foreground text line and for 
cpu to update this shadowed line with new data (MAME missed that point. So
background graphix appears suddenly at top of the screen). There is also 
about one line less at bottom of the screen.

Remaining graphix stuff is as usual : tile_ids from RAM map address 2 graphix ROMs,
These 2 bytes from graphix ROMs are serialized thru shift register or mux. These 
2 bits selects one color among 4 possibilities (00 = black). Color priority is 
given to foreground over background. The color palette ROMs uses the 2 selector bits
and 3 more bits from the tile_id number itself and one more bit from register 
at 0x7800 (data bit 1). Each palette ROM gives one bit for each color red, 
blue, green. So finally there is 2bits for red, 2bits for blue and 2 bits for green.

-------------------------------------------------
Hardware Registers :

  0x5000 (up to 0x53ff)  - Write, bit 0 = Player 1 or 2 RAM bank switching 
                                  bit 1 = Color palette high bit (6)

  0x5800 (up to 0x5bff)  - Write, background scroll offset

  0x6000 (up to 0x63ff)  - Write, sound control effect2 and 3

                              bits 0-3 : frequency divider
                              bits 4-5 : sound variation speed
                              bits 6-7 : noise generator

  0x6800 (up to 0x6bff)  - Write, sound control effect1 and melody

                              bits 0-3 : frequency divider
                              bits 4-5 : trigger and filter
                              bit    6 : select melody
                                            1 = Jeux Interdits
                                            0 = La lettre à Elise
                              bit    7 : start melody

  0x7000 (up to 0x73ff)  - Read, coin, start, player 1/2 controls

  0x7800 (up to 0x7bff)  - Read, dip switch 0-6 and vblank
  
-------------------------------------------------
Some software data information :

  0x4381-0x4383 : Player1 score in BCD
  0x4385-0x4387 : Player2 score in BCD
  0x4389-0x438b : High    score in BCD
  0x438c-0x438d : Copy of sound control 0x6000 and 0x6800
  0x438f        : Coin counter
  0x4390-0x4391 : Player 1 and Player 2 life counters
  0x439a-0x439b : Maybe frame counter
  0x43a4        : Something to do with game phase (not sure)
                     0 = attract screen
                     1 = ...
                     2 = ...
                     3 = playing
                     4 = player ship distroyed
                     5 = game over screen

  0x43a5        : Timer count down of game phase

  0x4b70-0x4baf : During stage 1 and 2 there are 16 groups of 4 bytes with
                  something to do with birds state (quiet or flying or dead)
                  and birds positions

                  During stage 3 and 4 there are 8 groups of 8 bytes with
                  something to do with eagles state.

  0x4bff        : cpu stack, grow downwards 


--------------------------------------------------------------------
Sound is composed of many analog component and NE555 IC in various
situation and one melody chip.

From MAME melody chip allow to play 2 songs :

 - Jeux Interdits (played when beginning first stage)
 - La lettre à Elise (played when finishing fifth stage)

See 'Phoenix_sound_explanation.txt' and 'Phoenix_sound_sheet.pdf' for more
information about analog parts.
--------------------------------------------------------------------

---------------
VHDL File list 
---------------

rtl_dar/phoenix_de2.vhd         Top level for de2 board 
rtl_dar/phoenix.vhd             Main logic

rtl_dar/pll50_to_11_and_18.vhd  PLL 11MHz and 18 MHz from 50MHz altera mf
rtl_dar/phoenix_video.vhd       Video genertor H/V counter, blanking and syncs
rtl_dar/phoenix_music.vhd       Melody 
rtl_dar/phoenix_effect3.vhd     Sound effect 3
rtl_dar/phoenix_effect2.vhd     Sound effect 2
rtl_dar/phoenix_effect1.vhd     Sound effect 1

rtl_dar/phoenix_prog.vhd        Program PROM
rtl_dar/prom_palette_ic41.vhd   Palette PROM rbg high bit
rtl_dar/prom_palette_ic40.vhd   Palette PROM rbg low  bit
rtl_dar/prom_ic24.vhd           Graphix PROM background low  bit
rtl_dar/prom_ic23.vhd           Graphix PROM background high bit
rtl_dar/prom_ic40.vhd           Graphix PROM foreground low  bit
rtl_dar/prom_ic39.vhd           Graphix PROM foreground high bit

rtl_dar/gen_ram.vhd             Generic RAM (Peter Wendrich + DAR Modification)

wm_8731_dac.vhd                 DE1/DE2 audio dac

io_ps2_keyboard.vhd             Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
kbd_joystick.vhd                Keyboard key to player/coin input

rtl_T80/T80s.vhd                T80 Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
rtl_T80/T80_Reg.vhd
rtl_T80/T80_Pack.vhd
rtl_T80/T80_MCode.vhd
rtl_T80/T80_ALU.vhd
rtl_T80/T80.vhd

----------------------
Quartus project files
----------------------
de2/phoenix_de2.qsf             de2 settings (files,pins...) 
de2/phoenix_de2.qpf             de2 project

-----------------------------
Required ROMs (Not included)
-----------------------------
You need the following 14 ROMs binary files from phoenix.zip 
(MAME Phoenix - Amstar)

b1-ic39.3b   prom_ic39.vhd
b2-ic40.4b   prom_ic40.vhd

ic23.3d      prom_ic23.vhd
ic24.4d      prom_ic24.vhd

ic45         prom_ic45.vhd
ic46         prom_ic46.vhd
ic47         prom_ic47.vhd
ic48         prom_ic48.vhd
h5-ic49.5a   prom_ic49.vhd
h6-ic50.6a   prom_ic50.vhd
h7-ic51.7a   prom_ic51.vhd
h8-ic52.8a   prom_ic52.vhd

mmi6301.ic40 prom_palette_ic40.vhd
mmi6301.ic41 prom_palette_ic41.vhd

------
Tools 
------
You need to build vhdl files from the binary file :
 - Unzip the roms file in the tools/phoenix_unzip directory
 - Double click (execute) the script tools/make_phoenix_proms.bat to get the following files

prom_ic39.vhd
prom_ic40.vhd

prom_ic23.vhd
prom_ic24.vhd

phoenix_prog.vhdl

prom_palette_ic40.vhd
prom_palette_ic41.vhd

*DO NOT REDISTRIBUTE THESE FILES*

VHDL files are needed to compile and include roms directly into the project 

The script make_phoenix_proms.bat uses make_vhdl_prom executables delivered both in linux and windows version. The script itself is delivered only in windows version (.bat) but should be easily ported to linux.

Source code of make_vhdl_prom.c is also delivered.

---------------------------------
Compiling for de2
---------------------------------
You can build the project with ROM image embeded in the sof file. DO NOT REDISTRIBUTE THESE FILES.
3 steps

 - put the VHDL ROM files into the project directory
 - build phoenix_de2
 - program phoenix_de2.sof

--------------------
Keyboard and swicth
--------------------
Use directional left/right key to move, space to fire, up key for shield, F1 to start 1 player,  F2 to start 2 players, F3 for coins.

DE2-board switches :

   0 - 7 : dip switch
             0-1 : lives 3-4-5-6
             3-2 : bonus life 30K-40K-50K-60K
               4 : coin 1-2
             6-5 : unkonwn
               7 : upright-cocktail 
 
   8 -10 : sound_select
             0XX : all mixed (normal)
             100 : sound1 only 
             101 : sound2 only
             110 : sound3 only
             111 : melody only
 
DE2-board key(s) :

      0 : reset

------------------------
End of file
------------------------
