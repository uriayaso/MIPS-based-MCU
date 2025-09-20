LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
----------------------notes------------------
--still need to clr the fifowen bit on the falling edge of the fifo clk 
--

ENTITY FIR IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		W	: integer := 24; --- SAMPLE BITS WIDTH
		K	: integer := 8; --- NUMBER OF SAMPELS IN FIFO
		q	: integer := 8; --- number of coeffecents BITS
		M	: integer := 8 --- memory, number of past sampels
	);
	PORT(	
------- CLKS------------------
		FIFOCLK_i			:IN STD_LOGIC;
		FIRCLK_i			:IN STD_LOGIC;
		rst_i				:IN STD_LOGIC;
-------CHIP SELECT INPUTS-------------------
		FIRIN_SEL_i			:IN STD_LOGIC;
		COEF0_3_SEL_i		:IN STD_LOGIC;
		COEF4_7_SEL_i		:IN STD_LOGIC;
		FIROUT_SEL_i		:IN STD_LOGIC;
		FIRCTRL_SEL_i		:IN STD_LOGIC;
		MemRead_ctrl_i, MemWrite_ctrl_i : IN STD_LOGIC;
---------DATA BUS INPUT BIDIRACTIONAL------
		DATA_BUS		:INOUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
--------FIR INTERUPT FLAG----------------
		FIRIFG_o			:OUT STD_LOGIC;
        FIFOEMPTY_o         :OUT STD_LOGIC		
	);
END FIR;

ARCHITECTURE DATA_FLOW OF FIR IS
---------REGISTERS---------------
	SIGNAL FIRIN_R		:STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0):= (others => '0');
	SIGNAL FIROUT_R		:STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0):= (others => '0');
	SIGNAL COEF0_3_R	:STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0):= (others => '0');
	SIGNAL COEF4_7_R	:STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL FIRCTRL_R	:STD_LOGIC_VECTOR(7 DOWNTO 0):= (others => '0');
-------REGISTERS ENABELS------------------
	SIGNAL firin_en_w, coef0_3_en_w, coef4_7_en_w, fir_ctrl_en_w	:STD_LOGIC;
-------BIDRPIN ENABLES-------------------
	SIGNAL firin_bid_w, firout_bid_w, coef0_3_bid_w, coef4_7_bid_w, fir_ctrl_bid_w	:STD_LOGIC;
------ FIR RESULT------------------
	SIGNAL	fri_res_w	:STD_LOGIC_VECTOR (W-1 DOWNTO 0);
------ FIR CONTROL BITS------------
	SIGNAL	FIR_CTRL_ReadToBus	:STD_LOGIC_VECTOR (DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	FIR_res_ready_w	:STD_LOGIC;
	SIGNAL	FIFOFULL_w		:STD_LOGIC;
	SIGNAL	FIFO_EMPTY_w	:STD_LOGIC;
-------------INTERNAL SIGNALS-------------
	SIGNAL X_n_w		:STD_LOGIC_VECTOR (W-1 DOWNTO 0);
	signal FIFORENA_w		:STD_LOGIC;
	signal FIFOWREN_pulse_w : std_logic := '0';
	signal wen_tog_r           : std_logic := '0';
	signal wen_tog_f     : std_logic := '0'; -- delayed toggle for edge detect	
	
BEGIN
	firin_en_w <= (FIRIN_SEL_i and MemWrite_ctrl_i);
	coef0_3_en_w <= (COEF0_3_SEL_i and MemWrite_ctrl_i);
	coef4_7_en_w <= (COEF4_7_SEL_i and MemWrite_ctrl_i);
	fir_ctrl_en_w <= (FIRCTRL_SEL_i and MemWrite_ctrl_i);

	firin_bid_w <= (FIRIN_SEL_i and MemRead_ctrl_i);
	firout_bid_w <= (FIROUT_SEL_i and MemRead_ctrl_i);
	coef0_3_bid_w <= (COEF0_3_SEL_i and MemRead_ctrl_i);
	coef4_7_bid_w <= (COEF4_7_SEL_i and MemRead_ctrl_i);
	fir_ctrl_bid_w <= (FIRCTRL_SEL_i and MemRead_ctrl_i);
	
---------load word-----------------
FIRIN_TO_BUS:	BidirPin generic map( DATA_BUS_WIDTH )
				PORT map(
				FIRIN_R,
				firin_bid_w,
				open,
				DATA_BUS
				);

FIROUT_TO_BUS:	BidirPin generic map( DATA_BUS_WIDTH )
				PORT map(
				FIROUT_R,
				firout_bid_w,
				open,
				DATA_BUS
				);

COEF0_3_R_TO_BUS:	BidirPin generic map( DATA_BUS_WIDTH )
				PORT map(
				COEF0_3_R,
				coef0_3_bid_w,
				open,
				DATA_BUS
				);

COEF4_7_R_TO_BUS:	BidirPin generic map( DATA_BUS_WIDTH )
				PORT map(
				COEF4_7_R,
				coef4_7_bid_w,
				open,
				DATA_BUS
				);

FIRCTRL_R_TO_BUS:	BidirPin generic map( DATA_BUS_WIDTH )
				PORT map(
				FIR_CTRL_ReadToBus,
				fir_ctrl_bid_w,
				open,
				DATA_BUS
				);

-----FIROUT-register-----------
process (FIFOCLK_i)
BEGIN
	if (rst_i ='1') then
		FIROUT_R <= (others => '0');
	elsif (falling_edge(FIFOCLK_i)) then
		if(FIR_res_ready_w = '1') then
			FIROUT_R <= X"00" & fri_res_w;
		end if;
	end if;
end process;

---------STORE WORD--------------------------
------FIRIN-register-----------
process (FIFOCLK_i)
BEGIN
	if(rst_i='1') then
		FIRIN_R<= (others => '0');
	elsif (rising_edge(FIFOCLK_i)) then
		if (firin_en_w = '1') then 
			FIRIN_R <= DATA_BUS;
		end if;
	end if;
end process;


------COEF0_3_R-register-----------
process (FIFOCLK_i)
BEGIN
	if(rst_i='1') then
		COEF0_3_R<= (others => '0');
	elsif (rising_edge(FIFOCLK_i)) then
		if (coef0_3_en_w = '1') then 
			COEF0_3_R <= DATA_BUS;
		end if;
	end if;
end process;

------COEF4_7_R-register-----------
process (FIFOCLK_i)
BEGIN
	if(rst_i='1') then
		COEF4_7_R<= (others => '0');
	elsif (rising_edge(FIFOCLK_i)) then
		if (coef4_7_en_w = '1') then 
			COEF4_7_R <= DATA_BUS;
		end if;
	end if;
end process;

------FIRCTRL-register-----------
-- rising-edge toggle when SW writes FIRCTRL with bit5=1
process(FIFOCLK_i, rst_i)
begin
  if rst_i = '1' then
    wen_tog_r <= '0';
  elsif (rising_edge(FIFOCLK_i)) then
    if (fir_ctrl_en_w = '1') then
		FIRCTRL_R(1 DOWNTO 0) <= DATA_BUS(1 DOWNTO 0);
		FIRCTRL_R(4) <= DATA_BUS(4);
		if(DATA_BUS(5)='1') then
			wen_tog_r <= not wen_tog_r;  -- DFF with D=~Q (i.e., "T flip-flop")
		end if;
    end if;
  end if;
end process;

-- falling-edge copy
process(FIFOCLK_i, rst_i)
begin
  if rst_i = '1' then
    wen_tog_f <= '0';
  elsif falling_edge(FIFOCLK_i) then
    wen_tog_f <= wen_tog_r;
  end if;
end process;

-- half-cycle pulse (high only between rise and fall)
FIFOWREN_pulse_w <= '1' when (wen_tog_r /= wen_tog_f) else '0';


FIR_CTRL_ReadToBus (DATA_BUS_WIDTH-1 DOWNTO 7) <= (others => '0');-- 31 downto 7
FIR_CTRL_ReadToBus (6) <= FIR_res_ready_w;--bit 6
FIR_CTRL_ReadToBus (5) <= '0';-- FIFOWEN
FIR_CTRL_ReadToBus (4) <= FIRCTRL_R(4);--bit 4 FIFORST
FIR_CTRL_ReadToBus (3) <= FIFOFULL_w;--bit 3
FIR_CTRL_ReadToBus (2) <= FIFO_EMPTY_w;--bit 2 
FIR_CTRL_ReadToBus (1) <= FIRCTRL_R(1);--bit 1 FIRRST
FIR_CTRL_ReadToBus (0) <= FIRCTRL_R(0);--bit 0 FIRENA

---------FIFO COMPONENET------------
FIFO_COMP: fifo
	generic map(W => W, K => K) 
	port map(
	FIFOCLK_i => FIFOCLK_i,
	FIFORST_i => FIRCTRL_R(4),
	FIFOWREN_i => FIFOWREN_pulse_w,---write ENABLE
	FIFOIN_i => FIRIN_R (W-1 DOWNTO 0),
	FIFOREN_i => FIFORENA_w,
	X_n_o => X_n_w,
	FIFOFULL_o => FIFOFULL_w,
	FIFOEMPTY_o => FIFO_EMPTY_w	
	);
-------FIR COMPONENT--------------
FIR_ACCE: FIR_eccelerator
		generic map ( W => W, M => M, q => q)
		port map (
    FIRCLK_i => FIRCLK_i,   		
    FIRRST_i =>  FIRCTRL_R(1),	
    FIRENA_i =>  FIRCTRL_R(0),
    Xn_i 	=> 	 X_n_w,			
    COEF0_i =>  COEF0_3_R (7 DOWNTO 0),			
    COEF1_i =>  COEF0_3_R (15 DOWNTO 8), 			
    COEF2_i =>  COEF0_3_R (23 DOWNTO 16), 			
    COEF3_i =>  COEF0_3_R (31 DOWNTO 24), 			
    COEF4_i =>  COEF4_7_R (7 DOWNTO 0),  			
    COEF5_i =>  COEF4_7_R (15 DOWNTO 8), 			
    COEF6_i =>  COEF4_7_R (23 DOWNTO 16), 			
    COEF7_i =>  COEF4_7_R (31 DOWNTO 24), 			
    Yn_o 	=>	fri_res_w,			
    OUTPUT_valid => FIR_res_ready_w	    	
		);
------ PULS SYNCHRONIZER COMPONENT--------------
PULS_SYNC: puls_synchronizer
			port map(
			FIRCLK_i => FIRCLK_i,    		
			FIREN_i => FIRCTRL_R(0),   		
			FIFOCLK_i => FIFOCLK_i,
			FIFOREN_o => FIFORENA_w
			);
			
FIRIFG_o <= '1' WHEN ((FIR_res_ready_w ='1' and (FIFORENA_w = '1')) OR (FIFO_EMPTY_w = '1')) ELSE '0';
	
FIFOEMPTY_o <= FIFO_EMPTY_w;
	
END DATA_FLOW;
