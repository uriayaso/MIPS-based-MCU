LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.aux_package.all;



ENTITY IC IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		REG_SIZE : integer := 8
	);
	PORT(	
	
	rst_i, clk_i : IN STD_LOGIC;
	INTA, GIE         : IN STD_LOGIC;
	CS_IC_i : IN STD_LOGIC;
	A0_i, A1_i : IN STD_LOGIC;
	MemRead_ctrl_i, MemWrite_ctrl_i : IN STD_LOGIC;
	INTR_SRC_i    : IN STD_LOGIC_VECTOR(REG_SIZE-1 DOWNTO 0);
	DataBus      : INOUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	FIFOEMPTY_i  : IN STD_LOGIC;
	UART_status_error_i : IN STD_LOGIC;
	INTR         : OUT STD_LOGIC
	);
END IC;	


ARCHITECTURE behavior OF IC IS
    SIGNAL CS_IE_i, CS_IFG_i, CS_TYPE_i, INTA_Delayed : STD_LOGIC;
    SIGNAL IE_i, IFG_i, TYPE_i : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL IE_r, IFG_r, TYPE_r, type_w : STD_LOGIC_VECTOR(REG_SIZE-1 DOWNTO 0);
	SIGNAL IE_wr_EN, IE_rd_EN, IFG_wr_EN, IFG_rd_EN, TYPE_wr_EN, TYPE_rd_EN : STD_LOGIC; 
    SIGNAL IRQ_r, CLR_IRQ_r : STD_LOGIC_VECTOR(REG_SIZE-1 DOWNTO 0); 	
	SIGNAL IFG : STD_LOGIC;
	SIGNAL IE_o, IFG_o, TYPE_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL UART_status_error  : STD_LOGIC;
	SIGNAL IRQ_FIFO, IRQ_FIR : STD_LOGIC;
	
BEGIN

CS_IE_i   <= CS_IC_i and (not A0_i) and (not A1_i);
CS_IFG_i  <= CS_IC_i and A0_i and (not A1_i);
CS_TYPE_i <= CS_IC_i and (not A0_i) and A1_i;

IE_wr_EN   <= CS_IE_i   and MemWrite_ctrl_i;
IE_rd_EN   <= CS_IE_i   and MemRead_ctrl_i;
IFG_wr_EN  <= CS_IFG_i  and MemWrite_ctrl_i;
IFG_rd_EN  <= CS_IFG_i  and MemRead_ctrl_i;
TYPE_rd_EN <= (CS_TYPE_i and MemRead_ctrl_i) or (not INTA);

IFG <= (IE_r(0) and IRQ_r(0)) or (IE_r(1) and IRQ_r(1)) or (IE_r(2) and IRQ_r(2)) or
       (IE_r(3) and IRQ_r(3)) or (IE_r(4) and IRQ_r(4)) or (IE_r(5) and IRQ_r(5)) or
	   (IE_r(6) and IRQ_r(6)); 

IE_o <= X"000000" & IE_r;
IFG_o <= X"000000" & IFG_r;
TYPE_o <= X"000000" & TYPE_r;

----------------------- LW ---------------------------------------
IE_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(IE_o, IE_rd_EN,
                               open, DataBus);
IFG_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(IFG_o, IFG_rd_EN,
                               open, DataBus);							   
TYPE_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(TYPE_o, TYPE_rd_EN,
                               open, DataBus);							   
------------------ SW -----------------
process(rst_i, clk_i)
BEGIN
       if (rst_i = '1') then
	       IE_r <= X"00";
	   elsif(falling_edge(clk_i)) then
	        if(IE_wr_EN = '1') then 
	          IE_r <= DataBus(REG_SIZE-1 DOWNTO 0);
		    end if;
	   end if;
end process;

process(rst_i, clk_i, IFG_wr_EN)
BEGIN
       if (rst_i = '1') then
	       IFG_r <= X"00";
	   elsif(falling_edge(clk_i)) then
	        if(IFG_wr_EN = '1') then 
	          IFG_r <= DataBus(REG_SIZE-1 DOWNTO 0);
			elsif(IFG_wr_EN = '0') then 
			    IFG_r <= (IE_r and IRQ_r);
		    end if;
	   end if;
end process;

---------------------------------------------------------------------------
-- INTR
process(clk_i, IFG)
BEGIN
    if(rising_edge(clk_i)) then
	    if(IFG = '1') then
		    INTR <= GIE;
	    else
		    INTR <= '0';
		end if;
	end if;
end process;
-----------------------RX--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(0), CLR_IRQ_r(0))
BEGIN
    if(rst_i = '1') then
	    IRQ_r(0) <= '0';
	elsif(CLR_IRQ_r(0) = '0') then
	    IRQ_r(0) <= '0';
	elsif(rising_edge(INTR_SRC_i(0))) then
        IRQ_r(0) <= '1';
    end if;	
end process;
-----------------------TX--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(1), CLR_IRQ_r(1))
BEGIN
    if(rst_i = '1') then
	    IRQ_r(1) <= '0';
	elsif(CLR_IRQ_r(1) = '0') then
	    IRQ_r(1) <= '0';
	elsif(rising_edge(INTR_SRC_i(1))) then
        IRQ_r(1) <= '1';
    end if;	
end process;		
-----------------------TIMER--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(2), CLR_IRQ_r(2))
BEGIN
    if(rst_i = '1') then
	    IRQ_r(2) <= '0';
	elsif(CLR_IRQ_r(2) = '0') then
	    IRQ_r(2) <= '0';
	elsif(rising_edge(INTR_SRC_i(2))) then
        IRQ_r(2) <= '1';
    end if;	
end process;	

-----------------------KEY1--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(3), CLR_IRQ_r(3))
BEGIN
    if(rst_i = '1') then
	    IRQ_r(3) <= '0';
	elsif(CLR_IRQ_r(3) = '0') then
	    IRQ_r(3) <= '0';
	elsif(rising_edge(INTR_SRC_i(3))) then
        IRQ_r(3) <= '1';
    end if;	
end process;

-----------------------KEY2--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(4), CLR_IRQ_r(4))
BEGIN
    if(rst_i = '1') then
	    IRQ_r(4) <= '0';
	elsif(CLR_IRQ_r(4) = '0') then
	    IRQ_r(4) <= '0';
	elsif(rising_edge(INTR_SRC_i(4))) then
        IRQ_r(4) <= '1';
    end if;	
end process;

-----------------------KEY3--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(5), CLR_IRQ_r(5))
BEGIN
    if(rst_i = '1') then
	    IRQ_r(5) <= '0';
	elsif(CLR_IRQ_r(5) = '0') then
	    IRQ_r(5) <= '0';
	elsif(rising_edge(INTR_SRC_i(5))) then
        IRQ_r(5) <= '1';
    end if;	
end process;
-----------------------FIFO--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(6), CLR_IRQ_r(6))
BEGIN
    if(rst_i = '1') then
		IRQ_FIFO <= '0';
	elsif(CLR_IRQ_r(6) = '0') then
	    IRQ_FIFO <= '0';
	elsif(rising_edge(INTR_SRC_i(6)) and FIFOEMPTY_i = '1') then
        IRQ_FIFO <= '1';		
    end if;	
end process;

-----------------------FIR--------------------------------------------
process(rst_i, clk_i, INTR_SRC_i(6), CLR_IRQ_r(7))
BEGIN
    if(rst_i = '1') then
		IRQ_FIR  <= '0';
	elsif(CLR_IRQ_r(7) = '0') then
	    IRQ_FIR <= '0';
	elsif(rising_edge(INTR_SRC_i(6))and FIFOEMPTY_i = '0') then
        IRQ_FIR <= '1';		
    end if;	
end process;
-----------------------------------------------------------------------

IRQ_r(7) <= '0';
IRQ_r(6) <= IRQ_FIFO or IRQ_FIR;

------------- Priority Encoder ---------------------------------------
process(clk_i, IFG_r, UART_status_error_i, IRQ_FIFO)
    variable t : STD_LOGIC_VECTOR(REG_SIZE-1 DOWNTO 0);
BEGIN
    --t := X"00";
	if(rising_edge(clk_i)) then
	if IFG_r(0) = '1' THEN         -- RXIFG
	    if UART_status_error_i = '1' THEN
		   t := X"04";             -- UART STATUS ERROR
		ELSE
		   t := X"08";             -- RX
		end if;
	elsif IFG_r(1) = '1' THEN      -- TX
	    t := X"0c";
	elsif IFG_r(2) = '1' THEN      -- BT
	    t := X"10";	
	elsif IFG_r(3) = '1' THEN         --KEY1
	    t := X"14";
	elsif IFG_r(4) = '1' THEN         --KEY2
	    t := X"18";
	elsif IFG_r(5) = '1' THEN         --KEY3
	    t := X"1c";
	elsif IFG_r(6) = '1' THEN         -- FIR
	    if IRQ_FIFO = '1' THEN
		   t := X"20";               -- FIFOEMPTY
		ELSE
		   t := X"24";               -- FIROUT
		end if;
	end if;
	end if;
    type_w <= t;
end process;

type_r <= (others=>'0') when rst_i = '1' else type_w;

-----------------------------------------------------------------------   
PROCESS (rst_i, clk_i) BEGIN
	IF (rst_i = '1') THEN
		INTA_Delayed <= '1';
	ELSIF (falling_edge(clk_i)) THEN
		INTA_Delayed <= INTA;
	END IF;
END PROCESS;

-- Clear IRQ When Interrupt Ack recv
CLR_IRQ_r(0) <= '0' WHEN (TYPE_r = X"08" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(1) <= '0' WHEN (TYPE_r = X"0C" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(2) <= '0' WHEN (TYPE_r = X"10" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(3) <= '0' WHEN (TYPE_r = X"14" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(4) <= '0' WHEN (TYPE_r = X"18" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(5) <= '0' WHEN (TYPE_r = X"1C" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(6) <= '0' WHEN (TYPE_r = X"20" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_r(7) <= '0' WHEN (TYPE_r = X"24" AND INTA = '1' AND INTA_Delayed = '0' and FIFOEMPTY_i = '0') ELSE '1';

END behavior;