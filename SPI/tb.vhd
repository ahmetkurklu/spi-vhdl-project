library ieee;
use ieee.std_logic_1164.all;	   
use ieee.numeric_std.all;

entity tb is
end tb;

architecture seq of tb is

  signal clk: std_logic;
  signal clr: std_logic;
  signal rd: std_logic;
  signal wr: std_logic;
  signal data_in: std_logic_vector(7 downto 0);
  signal data_out: std_logic_vector(7 downto 0);
  signal rdy : std_logic;
  signal MOSI : std_logic;
  signal MISO : std_logic;
  signal SCK: std_logic;

begin

  UUT: entity work.SPI port map(clk, clr, rd, wr, data_in, data_out, rdy, MOSI, MISO, SCK);
  
  CLOCK: process
  begin
    clk<='1';
    wait for 5 ns;
    clk<='0';
    wait for 5 ns;
  end process;

  RESET:process
  begin
    clr <= '1'; 
    wait for 3 ns;
    clr <= '0';
    wait;
  end process;

  ECRITURE:process
  begin
    wr <= '0';
    wait for 30 ns;
    wr <= '1';
    wait for 30 ns;
    wr <= '0';
    wait for 1640 ns;
    wr<= '1';
    wait for 30 ns;
    wr <='0';
    wait;
  end process;
  
  LECTURE:process
  begin
    rd <= '0';
    wait for 30 ns;
    rd <= '1';
    wait for 30 ns;
    rd <= '0';
    wait;
  end process;


  ENTREE_DATA:process
  begin
    data_in <= "10101010";
    wait;
  end process;

  ENTREE_SPI:process
  begin
    MISO <= '0';
    wait for 30 ns;
    MISO <= '1';
    wait for 200 ns;
    MISO <= '0';
    wait for 200 ns;
    MISO <= '0';
    wait for 200 ns;
    MISO <= '1';
    wait for 200 ns;
    MISO <= '0';
    wait for 200 ns;
    MISO <= '1';
    wait for 200 ns;
    MISO <= '0';
    wait for 200 ns;
    MISO <= '1';
    wait for 200 ns;
    MISO <= '0';
    wait;
  end process;

end architecture;
