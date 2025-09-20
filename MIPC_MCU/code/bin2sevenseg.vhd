library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bin2sevenseg is
    port (
        bin  : in  std_logic_vector(3 downto 0);
        segs : out std_logic_vector(6 downto 0)
    );
end bin2sevenseg;

architecture behavior of bin2sevenseg is
begin

    with bin select
        segs <= "1000000" when "0000", -- 0
                "1111001" when "0001", -- 1
                "0100100" when "0010", -- 2
                "0110000" when "0011", -- 3
                "0011001" when "0100", -- 4
                "0010010" when "0101", -- 5
                "0000010" when "0110", -- 6
                "1111000" when "0111", -- 7
                "0000000" when "1000", -- 8
                "0011000" when "1001", -- 9
                "0001000" when "1010", -- A
                "0000011" when "1011", -- b
                "1000110" when "1100", -- C
                "0100001" when "1101", -- d
                "0000110" when "1110", -- E
                "0001110" when "1111", -- F
                "1111111" when others; -- Blank (off)

end behavior;
