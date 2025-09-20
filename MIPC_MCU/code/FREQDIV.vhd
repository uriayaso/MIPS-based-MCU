LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.aux_package.all;


ENTITY freq_divider IS
	generic(
		n : INTEGER := 2;
		m : INTEGER := 1;
		k : INTEGER := 0
	);
	PORT(
	     rst_i, clk_i                  : IN  STD_LOGIC;
	     clk2_o, clk4_o, clk8_o, clk_FIR_o : OUT STD_LOGIC
	);
END freq_divider;

ARCHITECTURE rtl OF freq_divider IS

    SIGNAL q_int : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"00000000";

BEGIN

	process(rst_i, clk_i)
    begin
        if (rst_i = '1') then
             q_int <= (others => '0');
		elsif (rising_edge(clk_i)) then
		     q_int <= q_int + 1;
        end if;
    end process;
	
	clk2_o <= q_int(k);     -- clk/2
	clk4_o <= q_int(m);     -- clk/4
	clk8_o <= q_int(n);     -- clk/8
    clk_FIR_o <= q_int(6);
end rtl;