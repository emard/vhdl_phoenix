---------------------------------------------------------------------------------
-- Phoenix sound effect1 by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity phoenix_effect1 is
generic(
  Vmax: real := 5.0; -- V
  IVmax: real := 65535.0; -- integer representation of Vmax
  -- Command
  Cmd_Fs: real := 25.0; -- MHz
  Cmd_V: real := 12.0; -- V
  Cmd_Vd: real := 0.46; -- V
  Cmd_Vce: real := 0.20; -- V
  Cmd_R1: real := 100.0; -- k
  Cmd_R2: real := 33.0; -- k
  Cmd_R3: real := 0.47; -- k
  Cmd_C: real := 6.8; -- uF
  Cmd_Div2n: integer := 8;
  -- Oscillator
  Osc_Fs: real := 25.0; -- MHz
  Osc_Vb: real := 5.0; -- V
  Osc_Vce: real := 0.20; -- V
  Osc_R1: real := 47.0; -- k
  Osc_R2: real := 47.0; -- k
  Osc_C: real := 0.001; -- uF
  -- Filter
  Filt_Fs: real := 25.0; -- MHz
  Filt_V1: real := 5.0; -- V
  Filt_R1: real := 100.0; -- k
  Filt_R2: real := 10.0; -- k
  Filt_C: real := 0.047; -- uF

  C_commande_VF1: integer := 43559;
  C_commande_k1: integer := 16477;
  C_commande_VF2: integer := 9300;
  C_commande_k2: integer := 306;
  C_oscillateur_VF1: integer := 65535;
  C_oscillateur_k1: integer := 18;
  C_oscillateur_VF2: integer := 2621;
  C_oscillateur_k2: integer := 9;
  C_filter_VF1: integer := 65535;
  C_filter_k1: integer := 83;
  C_filter_VF2: integer := 0;
  C_filter_k2: integer := 83
);
port(
 clk50    : in std_logic;
 clk10    : in std_logic;
 reset    : in std_logic;
 trigger  : in std_logic;
 filter   : in std_logic;
 divider  : in std_logic_vector(3 downto 0);
 snd      : out std_logic_vector(7 downto 0)
); end phoenix_effect1;

architecture struct of phoenix_effect1 is
  -- command charge
  constant Cmd_div: integer := integer(2**Cmd_Div2n);
  constant Cmd_VFc: real := (Cmd_V*Cmd_R2 + Cmd_Vd*Cmd_R1)/(Cmd_R1 + Cmd_R2); -- V
  constant Cmd_RCc: real := Cmd_R1*Cmd_R2/(Cmd_R1 + Cmd_R2)*Cmd_C/1000.0; -- s
  constant Cmd_ikc: integer := integer(floor(Cmd_RCc/2**Cmd_Div2n * Cmd_Fs * 1.0E6));
  constant Cmd_iVFc: integer := integer(floor(Cmd_VFc/Vmax*IVmax));
  constant Cmd_VFd: real := (Cmd_V/Cmd_R1+Cmd_Vd/Cmd_R2+(Cmd_Vd+Cmd_Vce)/Cmd_R3)/(1/Cmd_R1+1/Cmd_R2+1/Cmd_R3); -- V
  constant Cmd_RCd: real := 1.0/(1.0/Cmd_R1+1.0/Cmd_R2+1.0/Cmd_R3)*Cmd_C/1000.0; -- s
  constant Cmd_ikd: integer := integer(floor(Cmd_RCd/2**Cmd_Div2n * Cmd_Fs * 1.0E6));
  constant Cmd_iVFd: integer := integer(floor(Cmd_VFd/Vmax*IVmax));

  signal u_c1  : unsigned(15 downto 0) := (others => '0');
  signal u_c2  : unsigned(15 downto 0) := (others => '0');
  signal flip  : std_logic := '0';

  signal u_cf  : unsigned(15 downto 0) := (others => '0');

  signal sound : std_logic := '0';
 
begin

-- Commande
-- R1 = 100k, R2 = 33k, R3 = 0.47k C=6.8e-6 SR=10MHz
-- Charge   : VF1 = 43559, k1 = 6591 (R1//R2)
-- Decharge : VF2 =  9300, k2 =  123 (R1//R2//R3)
-- Div = 2^8

-- Commande clk50 = 25 MHz, clk10 = 25 MHz
-- R1 = 100k, R2 = 33k, R3 = 0.47k C=6.8e-6 SR=25MHz
-- Charge   : VF1 = 43559, k1 = 16477 (R1//R2)
-- Decharge : VF2 =  9300, k2 =   306 (R1//R2//R3)
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
   if trigger = '1' then
    if cnt > Cmd_ikc then
     cnt := (others => '0');
     u_c1 <= u_c1 + (Cmd_iVFc - u_c1)/Cmd_div;
    end if;
   else
    if cnt > Cmd_ikd then
     cnt := (others => '0');
     u_c1 <= u_c1 - (u_c1 - Cmd_iVFd)/Cmd_div;
    end if; 
   end if;
  end if;
 end if;
end process;

-- Oscillateur
-- R1 = 47k, R2 = 47k, C=0.001e-6 SR=50MHz
-- Charge   : VF1 = 65535, k1 = 37 (R1+R2)
-- Decharge : VF2 =  2621, k2 = 18 (R2)
-- Div = 2^7

-- Oscillateur
-- R1 = 47k, R2 = 47k, C=0.001e-6 SR=25MHz
-- Charge   : VF1 = 65535, k1 = 18 (R1+R2)
-- Decharge : VF2 =  2621, k2 = 9 (R2)
-- Div = 2^7

process (clk50)
 variable cnt  : unsigned(5 downto 0) := (others => '0');
begin
 if rising_edge(clk50) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c2 <= (others => '0');
   flip <= '0';
  else
   if u_c2 > u_c1   then flip <= '0'; end if;
   if u_c2 < u_c1/2 then flip <= '1'; end if; 
   cnt  := cnt + 1;
   if flip = '1' then
    if cnt > C_oscillateur_k1 then
     cnt := (others => '0');
     u_c2 <= u_c2 + (C_oscillateur_VF1 - u_c2)/128;
    end if;
   else
    if cnt > C_oscillateur_k2 then
     cnt := (others => '0');
     u_c2 <= u_c2 - (u_c2 - C_oscillateur_VF2)/128; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- Diviseur
-- LS163 : Count up, Sync load when 0xF (no toggle sound if divider = 0xF)
-- LS74  : Divide by 2

process (flip)
 variable cnt  : unsigned(3 downto 0) := (others => '0');
begin
 if rising_edge(flip) then
  cnt  := cnt + 1;
  if cnt = "0000" then
   cnt := unsigned(divider);
   if divider /= "1111" then sound <=  not sound; end if;
  end if;
 end if;
end process;
 
-- filter
-- R1 = 10k, R2 = 100k, C=0.047e-6, SR=10MHz
-- Charge :   VF1= 65535, k1 = 33 (R1//R2)
-- Decharge : VF2=    0 , k2 = 33 (R1//R2)
-- Div = 2^7

-- filter
-- R1 = 10k, R2 = 100k, C=0.047e-6, SR=25MHz
-- Charge :   VF1= 65535, k1 = 83 (R1//R2)
-- Decharge : VF2=     0, k2 = 83 (R1//R2)
-- Div = 2^7
 
process (clk10)
 variable cnt  : unsigned(7 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  if reset = '1' then
   cnt  := (others => '0');
   u_cf <= (others => '0');
  else
   cnt  := cnt + 1;
   if sound = '1' then
    if cnt > C_filter_k1 then
     cnt := (others => '0');
     u_cf <= u_cf + (C_filter_VF1 - u_cf)/128;
    end if;
   else
    if cnt > C_filter_k2 then
     cnt := (others => '0');
     u_cf <= u_cf - (u_cf - C_filter_VF2)/128; 
    end if; 
   end if;
  end if;
 end if;
end process;
 
with filter select 
 snd <= std_logic_vector(u_cf(15 downto 8)) when '1',  sound&"0000000" when others;
 
end struct;

