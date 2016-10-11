---------------------------------------------------------------------------------
-- Phoenix sound effect2 by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

-- this module outputs sound of mothership's descend
-- it could be heard at beginning of level 5
-- the prrrrr...vioooouuuuu sound
-- fixme:
-- the VCO control levels are too coarse (quantized)
-- frequency transitions are heard in large steps
-- instead of continous sweep

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity phoenix_effect2 is
generic(
 Vmax: real := 5.0; -- V
 Vmax_bits: integer := 16; -- number of bits to represent vmax
 -- Oscillator 1
 Osc1_Fs: real := 25.0; -- MHz
 Osc1_Vb: real := 5.0; -- V
 Osc1_Vce: real := 0.2; -- V
 Osc1_R1: real := 47.0; -- k
 Osc1_R2: real := 100.0; -- k
 Osc1_C1: real := 0.01; -- uF
 Osc1_C2: real := 0.47; -- uF
 Osc1_C3: real := 1.0; -- uF
 Osc1_Div2n: integer := 8; -- bits divisor
 Osc1_bits: integer := 16; -- bits counter
 -- Oscillator 2
 Osc2_Fs: real := 25.0; -- MHz
 Osc2_Vb: real := 5.0; -- V
 Osc2_Vce: real := 0.2; -- V
 Osc2_R1: real := 510.0; -- k
 Osc2_R2: real := 510.0; -- k
 Osc2_C: real := 1.0; -- uF
 Osc2_Div2n: integer := 8; -- bits divisor
 Osc2_bits: integer := 16; -- bits counter
 -- Filter 2
 Filt2_Fs: real := 25.0; -- MHz
 Filt2_V: real := 5.0; -- V
 Filt2_R1: real := 10.0; -- k
 Filt2_R2: real := 5.1; -- k
 Filt2_R3: real := 5.1; -- k
 Filt2_R4: real := 5.0; -- k
 Filt2_R5: real := 10.0; -- k
 Filt2_C: real := 100.0; -- uF
 Filt2_Div2n: integer := 8; -- bits divisor
 Filt2_bits: integer := 16; -- bits counter
 -- Oscillator 3
 Osc3_Fs: real := 25.0; -- MHz
 Osc3_Vb: real := 5.0; -- V
 Osc3_Vce: real := 0.2; -- V
 Osc3_R1: real := 20.0; -- k
 Osc3_R2: real := 20.0; -- k
 Osc3_C: real := 0.001; -- uF
 Osc3_Div2n: integer := 8; -- bits divisor
 Osc3_bits: integer := 16; -- bits counter

  C_oscillateur1_VF1: integer := 65535;
  C_oscillateur1_VF2: integer := 2621;
  C_oscillateur1_T0_k1: integer := 144;
  C_oscillateur1_T0_k2: integer := 98;
  C_oscillateur1_T1_k1: integer := 6891;
  C_oscillateur1_T1_k2: integer := 4688;
  C_oscillateur1_T2_k1: integer := 14499;
  C_oscillateur1_T2_k2: integer := 9863;
  C_oscillateur1_T3_k1: integer := 21246;
  C_oscillateur1_T3_k2: integer := 14453;
  
  C_flip1_0: integer := 22020;
  C_flip1_1: integer := 33063;
  C_flip1_scale: integer := 84; -- ??

  C_oscillateur2_VF1: integer := 65535;
  C_oscillateur2_k1: integer := 99609;
  C_oscillateur2_VF2: integer := 2621;
  C_oscillateur2_k2: integer := 49805;

  C_filter2_VF0: integer := 13159;
  C_filter2_VF1: integer := 19738;
  C_filter2_VF2: integer := 52377;
  C_filter2_VF3: integer := 58957;
  C_filter2_k: integer := 29804;

  C_oscillateur3_VF1: integer := 65535;
  C_oscillateur3_k1: integer := 16;
  C_oscillateur3_VF2: integer := 2621;
  C_oscillateur3_k2: integer := 8
);
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
 -- integer representation of voltage, full range
 constant IVmax: integer := integer(2**Vmax_bits)-1;
 -- Oscillator1 --
 constant Osc1_div: integer := integer(2**Osc1_Div2n);
 -- Oscillator1 charge/discharge voltages
 constant Osc1_VFc: real := Osc1_Vb; -- V
 constant Osc1_iVFc: integer := integer(Osc1_VFc/Vmax*IVmax);
 constant Osc1_VFd: real := Osc1_Vce; -- V
 constant Osc1_iVFd: integer := integer(Osc1_VFd/Vmax*IVmax);
 -- Oscillator1 charge/discharge time constants
 constant Osc1_T0_RCc: real := (Osc1_R1+Osc1_R2)*Osc1_C1/1000.0; -- s
 constant Osc1_T0_ikc: integer := integer(Osc1_T0_RCc/2**Osc1_Div2n * Osc1_Fs * 1.0E6);
 constant Osc1_T0_RCd: real := Osc1_R2*Osc1_C1/1000.0; -- s
 constant Osc1_T0_ikd: integer := integer(Osc1_T0_RCd/2**Osc1_Div2n * Osc1_Fs * 1.0E6);

 constant Osc1_T1_RCc: real := (Osc1_R1+Osc1_R2)*(Osc1_C1+Osc1_C2)/1000.0; -- s
 constant Osc1_T1_ikc: integer := integer(Osc1_T1_RCc/2**Osc1_Div2n * Osc1_Fs * 1.0E6);
 constant Osc1_T1_RCd: real := Osc1_R2*(Osc1_C1+Osc1_C2)/1000.0; -- s
 constant Osc1_T1_ikd: integer := integer(Osc1_T1_RCd/2**Osc1_Div2n * Osc1_Fs * 1.0E6);

 constant Osc1_T2_RCc: real := (Osc1_R1+Osc1_R2)*(Osc1_C1+Osc1_C3)/1000.0; -- s
 constant Osc1_T2_ikc: integer := integer(Osc1_T2_RCc/2**Osc1_Div2n * Osc1_Fs * 1.0E6);
 constant Osc1_T2_RCd: real := Osc1_R2*(Osc1_C1+Osc1_C3)/1000.0; -- s
 constant Osc1_T2_ikd: integer := integer(Osc1_T2_RCd/2**Osc1_Div2n * Osc1_Fs * 1.0E6);

 constant Osc1_T3_RCc: real := (Osc1_R1+Osc1_R2)*(Osc1_C1+Osc1_C2+Osc1_C3)/1000.0; -- s
 constant Osc1_T3_ikc: integer := integer(Osc1_T3_RCc/2**Osc1_Div2n * Osc1_Fs * 1.0E6);
 constant Osc1_T3_RCd: real := Osc1_R2*(Osc1_C1+Osc1_C2+Osc1_C3)/1000.0; -- s
 constant Osc1_T3_ikd: integer := integer(Osc1_T3_RCd/2**Osc1_Div2n * Osc1_Fs * 1.0E6);


 signal u_c1  : unsigned(15 downto 0) := (others => '0');
 signal u_c2  : unsigned(15 downto 0) := (others => '0');
 signal u_c3  : unsigned(16 downto 0) := (others => '0');
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

-- Oscillateur1
-- R1 = 47k, R2 = 100k, C1=0.01e-6, C2=0.047e-6, C3=1.000e-6 SR=25MHz
-- Div = 2^8

-- trigger = 00
-- Charge   : VF1 = 65535, k1 = 144 (R1+R2, C1)
-- Decharge : VF2 =  2621, k2 = 98 (R2, C1)
-- trigger = 01
-- Charge   : VF1 = 65535, k1 = 6891 (R1+R2, C1+C2)
-- Decharge : VF2 =  2621, k2 = 4688 (R2, C1+C2)
-- trigger = 10
-- Charge   : VF1 = 65535, k1 = 14499 (R1+R2, C1+C3)
-- Decharge : VF2 =  2621, k2 = 9863 (R2, C1+C3)
-- trigger = 11
-- Charge   : VF1 = 65535, k1 = 21246 (R1+R2, C1+C2+C3)
-- Decharge : VF2 =  2621, k2 = 14453 (R2, C1+C2+C3)

triggers <= trigger2 & trigger1;

with triggers select
kc <= to_unsigned(C_oscillateur1_T0_k1,16) when "00",
      to_unsigned(C_oscillateur1_T1_k1,16) when "01",
      to_unsigned(C_oscillateur1_T2_k1,16) when "10",
      to_unsigned(C_oscillateur1_T3_k1,16) when others;
   
with triggers select
kd <= to_unsigned(C_oscillateur1_T0_k2,16) when "00",
      to_unsigned(C_oscillateur1_T1_k2,16) when "01",
      to_unsigned(C_oscillateur1_T2_k2,16) when "10",
      to_unsigned(C_oscillateur1_T3_k2,16) when others;

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
     u_c1 <= u_c1 + (C_oscillateur1_VF1 - u_c1)/256;
    end if;
   else
    if cnt > kd then
     cnt := (others => '0');
     u_c1 <= u_c1 - (u_c1 - C_oscillateur1_VF2)/256; 
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

-- Oscillateur2
-- R1 = 510k, R2 = 510k, C=1.000e-6, SR=25MHz
-- Charge   : VF1 = 65535, k1 = 99609 (R1+R2, C)
-- Decharge : VF2 =  2621, k2 = 49805 (R2, C)
-- Div = 2^8

process (clk10)
 variable cnt  : unsigned(16 downto 0) := (others => '0');
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
    if cnt > C_oscillateur2_k1 then
     cnt := (others => '0');
     u_c2 <= u_c2 + (C_oscillateur2_VF1 - u_c2)/256;
    end if;
   else
    if cnt > C_oscillateur2_k2 then
     cnt := (others => '0');
     u_c2 <= u_c2 - (u_c2 - C_oscillateur2_VF2)/256; 
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

-- Filtre
-- V1 = 5V
-- R1 = 10k, R2 = 5.1k, R3 = 5.1k, R4 = 5k, R5 = 10k, C=100.0e-6, SR=25MHz 
-- Rp = R3//R4//R4//R1 = 1.68k
-- Rs = 1/(1/R2 + 1/R3 - Rp/(R3*R3)) = 3.05k
-- k = 29804 (Rs*C)
-- Div = 2^8

-- VF00 = 13159 (V*Rp*Rs)/(R4*R3)
-- VF01 = 19738 (V*Rp*Rs)/(R4p*R3)
-- VF10 = 52377 (V*Rp*Rs)/(R4*R3) + V*Rs/R2
-- VF11 = 58957 (V*Rp*Rs)/(R4p*R3) + V*Rs/R2

flips <= flip2 & flip1;

with flips select
vf <= to_unsigned(C_filter2_VF0,16) when "00",
      to_unsigned(C_filter2_VF1,16) when "01",
      to_unsigned(C_filter2_VF2,16) when "10",
      to_unsigned(C_filter2_VF3,16) when others;

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
    if cnt > C_filter2_k then
     cnt := (others => '0');
     u_cf <= u_cf + (vf - u_cf)/256;
    end if;
   else
    if cnt > C_filter2_k then
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

u_cf_scaled <= u_cf*to_unsigned(C_flip1_scale,8);

with flip1 select
 u_ctrl <= to_unsigned(C_flip1_0,16)+u_cf_scaled(23 downto 8) when '0',
           to_unsigned(C_flip1_1,16)+u_cf_scaled(23 downto 8) when others;

-- Oscillateur3
-- R1 = 20k, R2 = 20k, C=0.001e-6 SR=50MHz
-- Charge   : VF1 = 65535, k1 = 31 (R1+R2)
-- Decharge : VF2 =  2621, k2 = 16 (R2)
-- Div = 2^6

-- Oscillateur3
-- R1 = 20k, R2 = 20k, C=0.001e-6 SR=25MHz
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
    if cnt > C_oscillateur3_k1 then
     cnt := (others => '0');
     u_c3 <= u_c3 + (C_oscillateur3_VF1 - u_c3)/64;
    end if;
   else
    if cnt > C_oscillateur3_k2 then
     cnt := (others => '0');
     u_c3<= u_c3 - (u_c3 - C_oscillateur3_VF2)/64; 
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
