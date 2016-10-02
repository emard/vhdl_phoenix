---------------------------------------------------------------------------------
-- Phoenix sound effect2 by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_effect2 is
port(
 clk50    : in std_logic;
 clk10    : in std_logic;
 reset    : in std_logic;
 trigger1 : in std_logic;
 trigger2 : in std_logic;
 divider  : in std_logic_vector(3 downto 0);
 snd      : out std_logic_vector(1 downto 0)
); end phoenix_effect2;

architecture struct of phoenix_effect2 is

 signal u_c1  : unsigned(15 downto 0) := (others => '0');
 signal u_c2  : unsigned(15 downto 0) := (others => '0');
 signal u_c3  : unsigned(15 downto 0) := (others => '0');
 signal flip1 : std_logic := '0';
 signal flip2 : std_logic := '0';
 signal flip3 : std_logic := '0';
 
 signal triggers : std_logic_vector(1 downto 0) := "00";
 signal kc       : unsigned(15 downto 0) := (others =>'0');
 signal kd       : unsigned(15 downto 0) := (others =>'0');

 signal u_cf  : unsigned(15 downto 0) := (others => '0');
 signal flips : std_logic_vector(1 downto 0) := "00";
 signal vf    : unsigned(15 downto 0) := (others =>'0');

 signal u_cf_scaled  : unsigned(23 downto 0) := (others => '0');
 signal u_ctrl       : unsigned(15 downto 0) := (others => '0');

 signal sound: std_logic := '0';
 
begin

-- Oscillateur1
-- R1 = 47k, R2 = 100k, C1=0.01e-6, C2=0.047e-6, C3=1.000e-6 SR=10MHz
-- Div = 2^8

-- trigger = 00
-- Charge   : VF1 = 65535, k1 = 57 (R1+R2, C1)
-- Decharge : VF2 =  2621, k2 = 39 (R2, C1)
-- trigger = 01
-- Charge   : VF1 = 65535, k1 = 2756 (R1+R2, C1+C2)
-- Decharge : VF2 =  2621, k2 = 1875 (R2, C1+C2)
-- trigger = 10
-- Charge   : VF1 = 65535, k1 = 5800 (R1+R2, C1+C3)
-- Decharge : VF2 =  2621, k2 = 3945 (R2, C1+C3)
-- trigger = 11
-- Charge   : VF1 = 65535, k1 = 8498 (R1+R2, C1+C2+C3)
-- Decharge : VF2 =  2621, k2 = 5781 (R2, C1+C2+C3)

triggers <= trigger2 & trigger1;

with triggers select
kc <= to_unsigned(  57,16) when "00",
      to_unsigned(2756,16) when "01",
      to_unsigned(5800,16) when "10",
      to_unsigned(8498,16) when others;
   
with triggers select
kd <= to_unsigned(  39,16) when "00",
      to_unsigned(1875,16) when "01",
      to_unsigned(3945,16) when "10",
      to_unsigned(5781,16) when others;

process (clk10)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c1 <= (others => '0');
  else
   if u_c1 > X"AAAA" then flip1 <= '0'; end if;
   if u_c1 < X"5555" then flip1 <= '1'; end if; 
   cnt  := cnt + 1;
   if flip1 = '1' then
    if cnt > kc then
     cnt := (others => '0');
     u_c1 <= u_c1 + (65535 - u_c1)/256;
    end if;
   else
    if cnt > kd then
     cnt := (others => '0');
     u_c1 <= u_c1 - (u_c1 - 2621)/256; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- Oscillateur2
-- R1 = 510k, R2 = 510k, C=1.000e-6, SR=10MHz
-- Charge   : VF1 = 65535, k1 = 39844 (R1+R2, C)
-- Decharge : VF2 =  2621, k2 = 19922 (R2, C)
-- Div = 2^8

process (clk10)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c2 <= (others => '0');
  else
   if u_c2 > X"AAAA" then flip2 <= '0'; end if;
   if u_c2 < X"5555" then flip2 <= '1'; end if; 
   cnt  := cnt + 1;
   if flip2 = '1' then
    if cnt > 39844 then
     cnt := (others => '0');
     u_c2 <= u_c2 + (65535 - u_c2)/256;
    end if;
   else
    if cnt > 19922 then
     cnt := (others => '0');
     u_c2 <= u_c2 - (u_c2 - 2621)/256; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- Filtre
-- V1 = 5V
-- R1 = 10k, R2 = 5.1k, R3 = 5.1k, R4 = 5k, R5 = 10k, C=100.0e-6, SR=10MHz 
-- Rp = R3//R4//R4//R1 = 1.68k
-- Rs = 1/(1/R2 + 1/R3 - Rp/(R3*R3)) = 3.05k
-- k = 11922 (Rs*C)
-- Div = 2^8

-- VF00 = 13159 (V*Rp*Rs)/(R4*R3)
-- VF01 = 19738 (V*Rp*Rs)/(R4p*R3)
-- VF10 = 52377 (V*Rp*Rs)/(R4*R3) + V*Rs/R2
-- VF11 = 58957 (V*Rp*Rs)/(R4p*R3) + V*Rs/R2

flips <= flip2 & flip1;

with flips select
vf <= to_unsigned(13159,16) when "00",
      to_unsigned(19738,16) when "01",
      to_unsigned(52377,16) when "10",
      to_unsigned(58957,16) when others;

process (clk10)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk10) then
  if reset = '1' then
   cnt  := (others => '0');
   u_cf <= (others => '0');
  else
   cnt  := cnt + 1;
   if vf > u_cf then
    if cnt > 11922 then
     cnt := (others => '0');
     u_cf <= u_cf + (vf - u_cf)/256;
    end if;
   else
    if cnt > 11922 then
     cnt := (others => '0');
     u_cf <= u_cf - (u_cf - vf)/256; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- U_CTRL 

-- flip1 = 0  u_ctrl = 5V*Rp/R4  + u_cf*Rp/R3 # 22020 + u_cf*84/256
-- flip1 = 1  u_ctrl = 5V*Rp/R4p + u_cf*Rp/R3 # 33063 + u_cf*84/256 

u_cf_scaled <= u_cf*to_unsigned(84,8);

with flip1 select
 u_ctrl <= to_unsigned(22020,16)+u_cf_scaled(23 downto 8) when '0',
           to_unsigned(33063,16)+u_cf_scaled(23 downto 8) when others;

-- Oscillateur3
-- R1 = 20k, R2 = 20k, C=0.001e-6 SR=50MHz
-- Charge   : VF1 = 65535, k1 = 31 (R1+R2)
-- Decharge : VF2 =  2621, k2 = 16 (R2)
-- Div = 2^6

process (clk50)
 variable cnt  : unsigned(5 downto 0) := (others => '0');
begin
 if rising_edge(clk50) then
  if reset = '1' then
   cnt  := (others => '0');
   u_c3 <= (others => '0');
   flip3 <= '0';
  else
   if u_c3 > u_ctrl   then flip3 <= '0'; end if;
   if u_c3 < u_ctrl/2 then flip3 <= '1'; end if; 
   cnt  := cnt + 1;
   if flip3 = '1' then
    if cnt > 31 then
     cnt := (others => '0');
     u_c3 <= u_c3 + (65535 - u_c3)/64;
    end if;
   else
    if cnt > 16 then
     cnt := (others => '0');
     u_c3<= u_c3 - (u_c3 - 2621)/64; 
    end if; 
   end if;
  end if;
 end if;
end process;

-- Diviseur
-- LS163 : Count up, Sync load when 0xF (no toggle sound if divider = 0xF)
-- LS74  : Divide by 2

process (flip3)
 variable cnt  : unsigned(3 downto 0) := (others => '0');
begin
 if rising_edge(flip3) then
  cnt  := cnt + 1;
  if cnt = "0000" then
   cnt := unsigned(divider);
   if divider /= "1111" then sound <=  not sound; end if;
  end if;
 end if;
end process;

with trigger2 select
 snd <= '0'&sound when '1',
        sound&'0' when others;

end struct;
