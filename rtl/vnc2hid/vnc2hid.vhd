---------------------------------------------------------------------------
-- (c) 2015 Alexey Spirkov
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl/c files are used commercially or otherwise sold,
-- please contact me for explicit permission at me _at_ alsp.net.
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY vnc2hid IS
GENERIC
(
  C_clock_freq : integer := 50000000;
  C_baud_rate  : integer := 115200
);
PORT
(
  CLK             : IN  STD_LOGIC;
  RESET_N         : IN  STD_LOGIC;
  USB_TX          : IN  STD_LOGIC;
  HID_REPORT      : OUT STD_LOGIC_VECTOR(71 downto 0);
  NEW_VNC2_MODE_N : OUT STD_LOGIC;
  NEW_FRAME       : IN  STD_LOGIC
);
END;

ARCHITECTURE vhdl OF vnc2hid IS
  signal keyb_data: std_logic_vector(7 downto 0);
  signal byte_ready: std_logic;
  signal byte_count: integer range 0 to 8;
  signal R_HID_REPORT: std_logic_vector(71 downto 0);
  signal frame_signal_prev: std_logic;
BEGIN
  inst_rx : entity work.uart_deserializer
  generic map
  (
    divisor => C_clock_freq / C_baud_rate
  )
  port map
  (
    CLK        => CLK,
    nRESET     => RESET_N,
    RX         => USB_TX,
    DATA       => keyb_data,
    BYTE_READY => byte_ready
  );
	
  process(CLK, RESET_N, NEW_FRAME, byte_ready)
  begin
    if RESET_N = '0' then
      byte_count <= 0;
      R_HID_REPORT <= (others => '0');
    elsif NEW_FRAME = '0' then
      byte_count <= 0;
    elsif CLK'event and CLK = '1' and byte_ready = '1' then
      R_HID_REPORT(byte_count*8+7 downto byte_count*8) <= keyb_data;
      byte_count <= byte_count + 1;
    end if;
  end process;
  HID_REPORT <= R_HID_REPORT;
  NEW_VNC2_MODE_N <= '0';
END vhdl;
