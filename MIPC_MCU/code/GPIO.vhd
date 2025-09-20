LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.aux_package.all;

ENTITY gpio IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		PC_WIDTH : integer := 10
	);
	PORT(	CS_LEDR_i, CS_HEX01_i, CS_HEX23_i, CS_HEX45_i, CS_SW_i      : IN 	STD_LOGIC;
			DATA_BUS_i : INOUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			ADDRESS_BUS_i : IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_i, MemWrite_i : IN STD_LOGIC;
			SW_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			LEDR_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			HEX0_o, HEX1_o, HEX2_o, HEX3_o, HEX4_o, HEX5_o : out STD_LOGIC_VECTOR(6 downto 0)
	);
END gpio;


ARCHITECTURE behavior OF gpio IS

    SIGNAL SW_rd_EN, LEDR_EN, HEX0_EN, HEX1_EN, HEX2_EN, HEX3_EN, HEX4_EN, HEX5_EN, A0_w  : STD_LOGIC;
	SIGNAL LEDR_w : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL HEX0_w, HEX1_w, HEX2_w, HEX3_w, HEX4_w, HEX5_w : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
    
	A0_w     <= ADDRESS_BUS_i(0);
    SW_rd_EN    <= CS_SW_i and MemRead_i;
	LEDR_EN  <= CS_LEDR_i and MemWrite_i;
	HEX0_EN  <= CS_HEX01_i and MemWrite_i and (not A0_w);
	HEX1_EN  <= CS_HEX01_i and MemWrite_i and A0_w;
	HEX2_EN  <= CS_HEX23_i and MemWrite_i and (not A0_w);
	HEX3_EN  <= CS_HEX23_i and MemWrite_i and A0_w;
	HEX4_EN  <= CS_HEX45_i and MemWrite_i and (not A0_w);
	HEX5_EN  <= CS_HEX45_i and MemWrite_i and A0_w;
	
SW_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(X"000000" & SW_i, SW_rd_EN,
                               open, DATA_BUS_i);    
							   
-------------------------------------------------------------							   
	process(DATA_BUS_i, LEDR_EN)
    begin
         if (LEDR_EN = '1') then
         LEDR_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;

	process(DATA_BUS_i, HEX0_EN)
    begin
         if (HEX0_EN = '1') then
         HEX0_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;

	process(DATA_BUS_i, HEX1_EN)
    begin
         if (HEX1_EN = '1') then
         HEX1_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;

	process(DATA_BUS_i, HEX2_EN)
    begin
         if (HEX2_EN = '1') then
         HEX2_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;	
	
	process(DATA_BUS_i, HEX3_EN)
    begin
         if (HEX3_EN = '1') then
         HEX3_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;

	process(DATA_BUS_i, HEX4_EN)
    begin
         if (HEX4_EN = '1') then
         HEX4_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;

	process(DATA_BUS_i, HEX5_EN)
    begin
         if (HEX5_EN = '1') then
         HEX5_w <= DATA_BUS_i(7 DOWNTO 0);
         end if;
    end process;	

-------------------------------------------------------------
	
LEDR_o <= LEDR_w;

	---- HEX Segment ----
	HEX0_Module: bin2sevenseg port map(HEX0_w(3 downto 0), HEX0_o);
	HEX1_Module: bin2sevenseg port map(HEX1_w(7 downto 4), HEX1_o);
	
	HEX2_Module: bin2sevenseg port map(HEX2_w(3 downto 0), HEX2_o);
	HEX3_Module: bin2sevenseg port map(HEX3_w(7 downto 4), HEX3_o);
	
	HEX4_Module: bin2sevenseg port map(HEX4_w(3 downto 0), HEX4_o);
	HEX5_Module: bin2sevenseg port map(HEX5_w(7 downto 4), HEX5_o);


END behavior;
