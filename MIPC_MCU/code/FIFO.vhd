LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;

entity FIFO is
  generic (
    W : integer := 24;   -- data width
    K : integer := 8    -- entries
  );
  port (
    FIFOCLK_i     		: IN  std_logic;  
    FIFORST_i     		: IN  std_logic;  

    FIFOWREN_i   		: IN  std_logic; 
    FIFOIN_i	 		: IN  std_logic_vector(W-1 downto 0);

    FIFOREN_i   		: IN  std_logic; 
    X_n_o 				: OUT std_logic_vector(W-1 downto 0);

    FIFOFULL_o    		: OUT std_logic;  
    FIFOEMPTY_o   		: OUT std_logic  
	);
end FIFO;

architecture rtl of FIFO is
	subtype rowVector is std_logic_vector (W-1 DOWNTO 0);
	TYPE matrix IS ARRAY (0 TO k-1) OF rowVector;
-----storage-------------
	SIGNAL FIFO_MAT : matrix;
-----pointers------------
	signal w_ptr	: integer range 0 to K-1 :=0;
	signal r_ptr	: integer range 0 to K-1 :=0;
	signal counter	: integer range 0 to K :=0;
---------------------------
	signal read_ena :std_logic;
	signal write_ena :std_logic;
	signal write_data_w :std_logic_vector (W-1 DOWNTO 0);
	signal rd_data_w	:std_logic_vector (W-1 DOWNTO 0);
	
begin


	write_data_w <=	FIFOIN_i;
----internal read write enables---------------
	read_ena <= '1' when ((FIFOREN_i = '1' and counter > 0) or 
						  (FIFOREN_i = '1' and counter = 0 and FIFOWREN_i ='1'))
					else  '0';
	write_ena <= '1' when ((FIFOWREN_i = '1' and counter < k) or 
						  (FIFOWREN_i = '1' and counter = k and FIFOREN_i = '1'))
					else  '0';
-----------------------------------------------

process (FIFOCLK_i)
begin
	if (falling_edge(FIFOCLK_i)) then
	
		if (FIFORST_i ='1') then
			w_ptr <= 0;
			r_ptr <= 0;
			counter <= 0;
			rd_data_w <= (others => '0');
		else
		--write
			if(write_ena ='1') then 
				FIFO_MAT(w_ptr) <= write_data_w;
				if (w_ptr = K-1) then
					w_ptr <= 0;
				else
					w_ptr <= w_ptr + 1;
				end if;
			end if;
		--read 
			if(read_ena ='1') then 
				 rd_data_w<= FIFO_MAT(r_ptr);
				if (r_ptr = k-1) then
					r_ptr <= 0;
				else
					r_ptr <= r_ptr + 1;
				end if;
			end if;	
		-- counter
			if(write_ena ='1' and read_ena ='0') then --only write sample
				counter <= counter + 1;
			elsif (write_ena ='0' and read_ena ='1') then --only read sample
				counter <= counter -1;
			else -- read and write or no read no write
			counter <= counter;---latch
			end if;
		end if;
	end if;
end process;

------outputs-------------
	FIFOFULL_o <= '1' when (counter = K or (counter = K-1 and write_ena ='1')) else '0';
	FIFOEMPTY_o <= '1' when counter = 0 else '0';
	X_n_o <= rd_data_w;
	
end rtl;