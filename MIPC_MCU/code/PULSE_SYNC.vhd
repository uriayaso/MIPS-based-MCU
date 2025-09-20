LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;

entity puls_synchronizer is
  port ( 
 -------source clk----------
    FIRCLK_i     		: IN  std_logic;  
    FIREN_i     		: IN  std_logic;
-------destination clk-------
	FIFOCLK_i     		: IN  std_logic; 
	FIFOREN_o			: OUT std_logic
	);
end puls_synchronizer;

architecture rtl of puls_synchronizer is
  SIGNAL src_tog : STD_LOGIC := '0';
  SIGNAL d_meta, d_sync : STD_LOGIC := '0';
 begin
 
	 PROCESS (FIRCLK_i)
	BEGIN
		IF rising_edge(FIRCLK_i) THEN
			IF FIREN_i = '1' THEN
				src_tog <= NOT src_tog;
      		END IF;
		END IF;
	END PROCESS;

 PROCESS (FIFOCLK_i)
  BEGIN
    IF rising_edge(FIFOCLK_i) THEN
      d_meta <= src_tog;     -- first sync flop (metastability catcher)
      d_sync <= d_meta;      -- second sync flop
    END IF;
  END PROCESS;

  FIFOREN_o <= d_meta XOR d_sync;  
end rtl;