library ieee;
use ieee.std_logic_1164.all;

entity uart_deserializer is
  generic
  (
    divisor: integer := 434 -- divisor = 50MHz / 115200 Baud = 434
  );
  port
  (
    CLK       : in  std_logic;
    nRESET    : in  std_logic;
    RX        : in  std_logic;
    DATA      : out std_logic_vector(7 downto 0);
    BYTE_READY: out std_logic
  );
end;

architecture rtl of uart_deserializer is
  constant halfbit    : integer := divisor / 2;
  signal rx_buffer    : std_logic_vector(7 downto 0);
  signal rx_bit_count : integer range 0 to 10;
  signal rx_count     : integer range 0 to divisor;
  signal rx_avail     : std_logic;
  signal rx_shift_reg : std_logic_vector(7 downto 0);
  signal rx_bit       : std_logic;
begin

process(CLK, nRESET) is
begin
  if nRESET = '0' then
    rx_buffer    <= (others => '0');
    rx_bit_count <= 0;
    rx_count     <= 0;
    rx_avail     <= '0';
  elsif CLK'event and CLK = '1' then
    if rx_count /= 0 then
      rx_count <= rx_count - 1;
    else
      if rx_bit_count = 0 then -- wait for startbit
        if rx_bit = '0' then -- FOUND
          rx_count <= halfbit;
          rx_bit_count <= rx_bit_count + 1;
        end if;
      elsif rx_bit_count = 1 then -- sample mid of startbit
        if rx_bit = '0' then -- OK
          rx_count <= divisor;
          rx_bit_count <= rx_bit_count + 1;
          rx_shift_reg <= "00000000";
        else -- ERROR
          rx_bit_count <= 0;
        end if;
      elsif rx_bit_count = 10 then -- stopbit
        if rx_bit = '1' then -- OK
          rx_buffer <= rx_shift_reg;
          rx_avail <= '1';
          rx_count <= 0;
          rx_bit_count <= 0;
        else -- ERROR
          rx_count <= divisor;
          rx_bit_count <= 0;
        end if;
      else
        rx_shift_reg(6 downto 0) <= rx_shift_reg(7 downto 1);
        rx_shift_reg(7) <= rx_bit;
        rx_count <= divisor;
        rx_bit_count <= rx_bit_count + 1;
      end if;
    end if;
    if rx_avail = '1' then
      rx_avail <= '0';
    end if;
  end if;
end process;

sync: process (nRESET, CLK) is
begin
  if nRESET = '0' then
    rx_bit <= '1';
  elsif CLK'event and CLK = '0' then
    rx_bit <= RX;
  end if;
end process;

DATA <= rx_shift_reg;
BYTE_READY <= rx_avail;

end rtl;
