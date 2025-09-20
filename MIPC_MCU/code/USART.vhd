LIBRARY IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;
----------------------------------------------------------------------------
entity USART is
  generic (
    DATA_BUS_WIDTH : integer := 32;
	REG_SIZE : integer := 8;
    g_CLKS_PER_BIT : integer := 217     -- Needs to be set correctly
    );
  port (
    rst_i, clk_i       : in  std_logic;
    CS_UART_i, MemRead_i, MemWrite_i ,A0_i, A1_i  : in  std_logic;
	DataBus      : INOUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); 
	RX_i         : IN std_logic := '1';    -- IN TOP
	UART_Status_ERROR_o : OUT std_logic;
	TX_o                : OUT std_logic := '1';
	RXIFG_o    : OUT std_logic := '0';
	TXIFG_o    : OUT std_logic
    );
end USART;

ARCHITECTURE behavior OF USART IS
    SIGNAL CS_UTCL_w, CS_RXBF_w, CS_TXBF_w : std_logic;
	SIGNAL UTCL_wr_EN, UTCL_rd_EN, RXBF_rd_EN, TXBF_wr_EN, TXBF_rd_EN : std_logic;
	SIGNAL UTCL_r, RXBF_r, TXBF_r, RX_DATA : STD_LOGIC_VECTOR(REG_SIZE-1 DOWNTO 0);
	SIGNAL SWRST, PENA, PEV, BAUDRATE, FE, PE, OE , BUSY, TX_DV, RX_DV : std_logic;
	SIGNAL RX_BUSY, TX_BUSY, RXIFG_w : std_logic;
	
BEGIN

CS_UTCL_w <= CS_UART_i and (not A0_i) and (not A1_i);
CS_RXBF_w <= CS_UART_i and A0_i and (not A1_i);
CS_TXBF_w <= CS_UART_i and (not A0_i) and A1_i;

UTCL_wr_EN <= CS_UTCL_w and MemWrite_i;
UTCL_rd_EN <= CS_UTCL_w and MemRead_i;
RXBF_rd_EN <= CS_RXBF_w and MemRead_i;
TXBF_wr_EN <= CS_TXBF_w and MemWrite_i;
TXBF_rd_EN <= CS_TXBF_w and MemRead_i;
-------LW--------------------------------------------------------------
UTCL_to_BUS : BidirPin  generic map(DATA_BUS_WIDTH)
                        port map(X"000000" & UTCL_r, UTCL_rd_EN,
                               open, DataBus);
RXBF_to_BUS : BidirPin  generic map(DATA_BUS_WIDTH)
                        port map(X"000000" & RXBF_r, RXBF_rd_EN,
                               open, DataBus);
TXBF_to_BUS : BidirPin  generic map(DATA_BUS_WIDTH)
                        port map(X"000000" & TXBF_r, TXBF_rd_EN,
                               open, DataBus);							   
------ SW -------------------------------------------------------------
process(rst_i, clk_i)
BEGIN
    if(rst_i = '1') then
	    UTCL_r(3 DOWNTO 0) <= X"1";
	elsif(rising_edge(clk_i)) then
	    if(UTCL_wr_EN = '1') then
	        UTCL_r(3 DOWNTO 0) <= DataBus(3 DOWNTO 0);
	    elsif(SWRST = '1') then
		    UTCL_r <= X"01";
		end if;
		UTCL_r(4) <= FE;
		UTCL_r(5) <= PE;
		UTCL_r(6) <= OE;
		UTCL_r(7) <= BUSY;
	end if;
end process;

process(rst_i, clk_i)
BEGIN
    if(rst_i = '1') then
	    TXBF_r <= X"00";
	elsif(rising_edge(clk_i)) then
	    if(TXBF_wr_EN = '1') then
	        TXBF_r <= DataBus(REG_SIZE-1 DOWNTO 0);
			TX_DV <= '1';
		else
		    TX_DV <= '0';
		end if;
	end if;
end process;


process(rst_i, clk_i)
BEGIN
    if(rst_i = '1') then
	   RXBF_r <= X"00";
	   RXIFG_w <= '0';
	elsif(rising_edge(clk_i))then
	    if(RX_DV = '1' and  RXBF_rd_EN = '0') then
		    RXBF_r  <= RX_DATA;
		    RXIFG_w <= '1';
		elsif(RX_DV = '0' and RXBF_rd_EN = '1') then
			RXBF_r  <= X"00";		
		    RXIFG_w <= '0';
		end if;
	end if;
end process;	
	
	
-----------------------------------------------------------------------
SWRST    <= UTCL_r(0);
PENA     <= UTCL_r(1);
PEV      <= UTCL_r(2);
BAUDRATE <= UTCL_r(3);

BUSY <= RX_BUSY or TX_BUSY;
UART_Status_ERROR_o <= FE or OE or PE;
RXIFG_o <= RXIFG_w or UART_Status_ERROR_o;

RX : UART_RX   generic map (
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
  port map (
    rst_i        => SWRST,
    i_Clk        => clk_i,
    i_RX_Serial  => RX_i,               -- if zero then start RX
	PENA_i       => PENA,
	PEV_i        => PEV,
    o_RX_DV      => RX_DV,
    o_RX_Byte    => RX_DATA,
	FE_o         => FE,
	PE_o         => PE,
	OE_o         => OE,
	RX_BUSY_o    => RX_BUSY
);

TX : UART_TX   generic map (
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
  port map (
    rst_i         => SWRST,
    i_Clk         => clk_i,
    i_TX_DV       => TX_DV,
	i_TX_Byte     => TXBF_r,
	PENA_i        => PENA,
	o_TX_Active   => TX_BUSY,
    o_TX_Serial   => TX_o,
    o_TX_Done     => TXIFG_o
);

end behavior;