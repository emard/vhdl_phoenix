---------------------------------------------------------------------------------
-- Phoenix sound effect3 (noise) by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

-- this module generates noisy sound of ship missile shooting
-- ship explosions and enemy mothership explosion
-- it is often head throught all the levels of the game

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_effect3 is
generic(
  C_commande1_VF1: integer := 59507;
  C_commande1_k1: integer := 14164;
  C_commande1_VF2: integer := 8651;
  C_commande1_k2: integer := 219;

  C_commande2_VF1: integer := 57869;
  C_commande2_k1: integer := 859;
  C_commande2_VF2: integer := 0;
  C_commande2_k2: integer := 31211;

  C_commande2_chop_k: integer := 62500;

  C_oscillateur_min_VF1: integer := 65535;
  C_oscillateur_min_k1: integer := 469;
  C_oscillateur_min_VF2: integer := 2621;
  C_oscillateur_min_k2: integer := 10;

  C_oscillateur_max_VF1: integer := 65535;
  C_oscillateur_max_k1: integer := 35;
  C_oscillateur_max_VF2: integer := 2621;
  C_oscillateur_max_k2: integer := 10
);
port(
 clk50    : in std_logic;
 clk10    : in std_logic;
 reset    : in std_logic;
 trigger1 : in std_logic;
 trigger2 : in std_logic;
 snd      : out std_logic_vector(7 downto 0)
); end phoenix_effect3;

architecture struct of phoenix_effect3 is

 signal u_c1  : unsigned(15 downto 0) := (others => '0');
 signal u_c2  : unsigned(15 downto 0) := (others => '0');
 signal u_c3  : unsigned(15 downto 0) := (others => '0');
 signal flip3 : std_logic := '0';
 
 signal k_ch     : unsigned(25 downto 0) := (others =>'0');

 signal u_ctrl1   : unsigned(15 downto 0) := (others => '0');
 signal u_ctrl2   : unsigned(15 downto 0) := (others => '0');
 signal u_ctrl1_f : unsigned( 7 downto 0) := (others => '0');
 signal u_ctrl2_f : unsigned( 7 downto 0) := (others => '0');
 signal sound     : unsigned( 7 downto 0) := (others => '0');

 signal shift_reg : std_logic_vector(17 downto 0) := (others => '0');
 
begin

-- Commande1
-- R1 = 1k, R2 = 0.33k, R3 = 20k C=6.8e-6 SR=10MHz
-- Charge   : VF1 = 59507, k1 = 5666 (R1+R2+R3)
-- Decharge : VF2 =  8651, k2 =   88 (R2)
-- Div = 2^8

process (clk10)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c1 <= (others => '0');
  else
   cnt  := cnt + 1;
   if trigger1 = '1' then
    if cnt > C_commande1_k1 then
     cnt := (others => '0');
     u_c1 <= u_c1 + (C_commande1_VF1 - u_c1)/256;
    end if;
   else
    if cnt > C_commande1_k2 then
     cnt := (others => '0');
     u_c1 <= u_c1 - (u_c1 - C_commande1_VF2)/256; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- Commande2
-- R1 = 1k, R2 = 0.33k, R3 = 47k C=6.8e-6 SR=10MHz
-- Charge   : VF1 = 57869, k1 =   344 (R1+R2)//R3
-- Decharge : VF2 =     0, k2 = 12484 (R3)
-- Div = 2^8

process (clk10)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c2 <= (others => '0');
  else
   cnt  := cnt + 1;
   if trigger2 = '1' then
    if cnt > C_commande2_k1 then
     cnt := (others => '0');
     u_c2 <= u_c2 + (C_commande2_VF1 - u_c2)/256;
    end if;
   else
    if cnt > C_commande2_k2 then
     cnt := (others => '0');
     u_c2 <= u_c2 - (u_c2 - C_commande2_VF2)/256; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- control voltage from command1 is R3 voltage (not u_c1 voltage)   
with trigger1 select
u_ctrl1 <= (to_unsigned(C_commande1_VF1,16) - u_c1) when '1', (others=>'0') when others;

-- control voltage from command2 is u_c2 voltage
u_ctrl2 <= u_c2;

-- sum up and scaled both control voltages to vary R1 resistor of oscillator
k_ch <= shift_right(((u_ctrl1/2 + u_ctrl2/2) * to_unsigned(C_oscillateur_min_k1-C_oscillateur_max_k1,10)),15) + C_oscillateur_max_k1;  

-- Oscillateur
-- R1 = 47k..2.533k, R2 = 1k, C=0.05e-6, SR=50MHz
-- Charge   : VF1 = 65536, k_ch = 938..69 (R1+R2, C)
-- Decharge : VF2 =  2621, k2   = 20      (R2, C)
-- Div = 2^7

process (clk50)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk50) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c3 <= (others => '0');
  else
   if u_c3 > X"AAAA" then flip3 <= '0'; end if;
   if u_c3 < X"5555" then flip3 <= '1'; end if; 
   cnt  := cnt + 1;
   if flip3 = '1' then
    if cnt > k_ch then
     cnt := (others => '0');
     u_c3 <= u_c3 + (C_oscillateur_min_VF1 - u_c3)/128;
    end if;
   else
    if cnt > C_oscillateur_max_k2 then
     cnt := (others => '0');
     u_c3 <= u_c3 - (u_c3 - C_oscillateur_max_VF2)/128; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- noise generator triggered by oscillator output
process (flip3)
begin
 if rising_edge(flip3) then
  shift_reg <= shift_reg(16 downto 0) & not(shift_reg(17) xor shift_reg(16));
 end if;
end process;

-- modulated (chop) command1 voltage with noise generator output
with shift_reg(17) xor shift_reg(16) select
u_ctrl1_f <= u_ctrl1(15 downto 8)/2 when '0', (others => '0') when others;


-- modulated (chop) command2 voltage with noise generator output
-- and add 400Hz filter (raw sub-sampling)
-- f=10 MHz, k = 25000
process (clk10)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  cnt  := cnt + 1;
  if cnt > C_commande2_chop_k then
   cnt := (others => '0');
   if (shift_reg(17) xor shift_reg(16)) = '0' then
    u_ctrl2_f <= u_ctrl2(15 downto 8)/2;
   else
    u_ctrl2_f <= (others => '0');
   end if;
  end if;
 end if;
end process;

-- mix modulated noises 1 and 2
sound <= u_ctrl1_f + u_ctrl2_f;

snd <= std_logic_vector(sound);
 
end struct;
