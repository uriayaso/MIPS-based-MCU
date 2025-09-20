LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;


ENTITY TOP IS
	generic( 
			WORD_GRANULARITY : boolean 	:= G_WORD_GRANULARITY;
	        MODELSIM : integer 			:= G_MODELSIM;
			DATA_BUS_WIDTH : integer 	:= 32;
			ITCM_ADDR_WIDTH : integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH : integer 	:= G_ADDRWIDTH;
			PC_WIDTH : integer 			:= 10;
			FUNCT_WIDTH : integer 		:= 6;
			DATA_WORDS_NUM : integer 	:= G_DATA_WORDS_NUM;
			CLK_CNT_WIDTH : integer 	:= 16;
			INST_CNT_WIDTH : integer 	:= 16;
			REG_SIZE  : integer 	:= 8
	);
	PORT(	rst_i		 		:IN	STD_LOGIC;
			clk_i				:IN	STD_LOGIC;
			SW_i                :IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			KEY1_i, KEY2_i, KEY3_i : IN STD_LOGIC;
			RX_i                : IN STD_LOGIC;
			TX_o                : OUT STD_LOGIC;
			pc_o				:OUT STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_top_o	:OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			LEDR_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			HEX0_o, HEX1_o, HEX2_o, HEX3_o, HEX4_o, HEX5_o : out STD_LOGIC_VECTOR(6 downto 0);
			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
			inst_cnt_o 			:OUT	STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
			pwm_o               :OUT    STD_LOGIC
			
			
	);		
END TOP;

ARCHITECTURE structure OF TOP IS

    SIGNAL MCLK_w, rst_w, MCLK2_w, MCLK4_w, MCLK8_w, MCLK_FIR_w : STD_LOGIC;
    SIGNAL alu_res_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); 
    SIGNAL DATA_BUS_w, DTCM_DataOut_w, DTCM_DataIn_w, MIPS_DataOut_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ADDRESS_BUS_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL CONTROL_BUS_w : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL MemRead_ctrl_w, MemWrite_ctrl_w : STD_LOGIC;
	SIGNAL MemRead_DTCM_w, MemWrite_DTCM_w , DTCM_addr_EN_w: STD_LOGIC;
	SIGNAL CS_DTCM_w : STD_LOGIC;
	
	SIGNAL CS_LEDR_w, CS_HEX01_w, CS_HEX23_w, CS_HEX45_w, CS_SW_w, CS_KEY_w,
			CS_UART_w, CS_BTCTL_w, CS_BTCNT_w, CS_BTCCR0_w, CS_BTCCR1_w, CS_FIRCTL_w,
            CS_FIRIN_w, CS_FIROUT_w, CS_COEF30_w, CS_COEF74_w, CS_IC_w 	: STD_LOGIC;
	--
	SIGNAL DTCM_addr_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); 
	
	-- Timer--
	SIGNAL BTIFG_w, PWM_w : STD_LOGIC;
    SIGNAL FIRIFG_w, FIFOEMPTY_w : STD_LOGIC;
    
    -- INTERRUPT --
	SIGNAL INTR_w, INTA_w, ISR_ctl_w, GIE_w : STD_LOGIC;
    SIGNAL INTR_SRC_w : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- UART --
	SIGNAL RXIFG_w, TXIFG_w, UART_Status_ERROR_w : STD_LOGIC;
	
BEGIN
    
    rst_w <= not rst_i when MODELSIM = 0 else rst_i;
    CS_DTCM_w <= not(CS_LEDR_w or CS_HEX01_w or CS_HEX23_w or CS_HEX45_w or CS_SW_w or CS_KEY_w or
	                 CS_UART_w or CS_BTCTL_w or CS_BTCNT_w or CS_BTCCR0_w or CS_BTCCR1_w or CS_FIRCTL_w or
					 CS_FIRIN_w or CS_FIROUT_w or CS_COEF30_w or CS_COEF74_w or CS_IC_w);
    -- for GPIO contorl
    MemRead_ctrl_w  <= CONTROL_BUS_w(1);
	MemWrite_ctrl_w <= CONTROL_BUS_w(0);
	
	-- for DTCM control
    MemRead_DTCM_w  <= MemRead_ctrl_w and CS_DTCM_w;
    MemWrite_DTCM_w <= MemWrite_ctrl_w and CS_DTCM_w;
	DTCM_addr_EN_w <= MemRead_DTCM_w or MemWrite_DTCM_w;
	
    ADDRESS_BUS_w <= alu_res_w when (ISR_ctl_w = '0') else (OTHERS => 'Z');
   
   
    INTR_SRC_w <= "0" & FIRIFG_w & (not KEY3_i) & (not KEY2_i) & (not KEY1_i) & BTIFG_w & TXIFG_w & RXIFG_w;  --- need to add fir and uart

-----------------------------------------------------------------------------------
-- BUS CONNECTIONS --
							   
DTCM_addr_w <= DATA_BUS_w when ISR_ctl_w = '1' else ADDRESS_BUS_w; 							   
-- ISR							   
ADDR_to_DATA : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(DTCM_DataOut_w, ISR_ctl_w,
                               open, ADDRESS_BUS_w);							   
-- LOAD							   
							   
DTCM_to_DATA_BUS: BidirPin generic map(DATA_BUS_WIDTH)
                      port map(DTCM_DataOut_w , MemRead_DTCM_w, open, DATA_BUS_w);					  

DATA_BUS: 	 BidirPin generic map(DATA_BUS_WIDTH)
                      port map(MIPS_DataOut_w , MemWrite_ctrl_w, open, DATA_BUS_w);	

DTCM_Wr_DATA_BUS: BidirPin generic map(DATA_BUS_WIDTH)
                      port map(DATA_BUS_w , MemWrite_DTCM_w, open, DTCM_DataIn_w);
					  
----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------

    MIPS : MIPS_CORE
	generic map( 
			WORD_GRANULARITY  => WORD_GRANULARITY,
	        MODELSIM          => MODELSIM,
			DATA_BUS_WIDTH    => DATA_BUS_WIDTH,
			ITCM_ADDR_WIDTH   => ITCM_ADDR_WIDTH,
			DTCM_ADDR_WIDTH   => DTCM_ADDR_WIDTH,
			PC_WIDTH          => PC_WIDTH,
			FUNCT_WIDTH       => FUNCT_WIDTH,
			DATA_WORDS_NUM    => DATA_WORDS_NUM,
			CLK_CNT_WIDTH     => CLK_CNT_WIDTH,
			INST_CNT_WIDTH    => INST_CNT_WIDTH
	)
	PORT map(	rst_i		 		=> rst_w,
			clk_i				=> MCLK_w,
			INTR_i              => INTR_w,
			DATA_BUS_i          => DATA_BUS_w,
			ADDRESS_BUS_i       => ADDRESS_BUS_w,
			pc_o				=> pc_o,
			alu_result_o 		=> alu_res_w,
			read_data2_o 		=> MIPS_DataOut_w,
			instruction_top_o	=> instruction_top_o,
			MemWrite_ctrl_o		=> CONTROL_BUS_w(0),
			MemRead_ctrl_o		=> CONTROL_BUS_w(1),
			INTA_o              => INTA_w,
			GIE_o               => GIE_w,
			ISR_ctl_o           => ISR_ctl_w,
			mclk_cnt_o			=> mclk_cnt_o,
			inst_cnt_o 			=> inst_cnt_o
	);	
---------------------------------------------------------------------------------

    GP  : GPIO
	generic map(
		DATA_BUS_WIDTH => DATA_BUS_WIDTH,
		PC_WIDTH       => PC_WIDTH
	)
	PORT map(	CS_LEDR_i => CS_LEDR_w,
				CS_HEX01_i => CS_HEX01_w,
				CS_HEX23_i => CS_HEX23_w,
				CS_HEX45_i => CS_HEX45_w,
				CS_SW_i => CS_SW_w,
			    DATA_BUS_i => DATA_BUS_w,
			    ADDRESS_BUS_i => ADDRESS_BUS_w,
			    MemRead_i => CONTROL_BUS_w(1),
			    MemWrite_i => CONTROL_BUS_w(0),
			    SW_i => SW_i,
			    LEDR_o => LEDR_o,
			    HEX0_o => HEX0_o,
			    HEX1_o => HEX1_o, 
			    HEX2_o => HEX2_o,
			    HEX3_o => HEX3_o,
			    HEX4_o => HEX4_o,
			    HEX5_o => HEX5_o			
	);

---------------------------------------------------------------------------------
    DEC : addrdecoder
	PORT map (	A11_i => ADDRESS_BUS_w(11),
            	A6_i => ADDRESS_BUS_w(6),
				A5_i => ADDRESS_BUS_w(5),
				A4_i => ADDRESS_BUS_w(4),
	            A3_i => ADDRESS_BUS_w(3),
            	A2_i => ADDRESS_BUS_w(2),			                
			    CS_LEDR_o => CS_LEDR_w,
				CS_HEX01_o => CS_HEX01_w,
				CS_HEX23_o => CS_HEX23_w,
				CS_HEX45_o => CS_HEX45_w,
				CS_SW_o => CS_SW_w,
				CS_KEY_0 => CS_KEY_w,
				CS_UART_o => CS_UART_w,
				CS_BTCTL_o => CS_BTCTL_w,
				CS_BTCNT_o => CS_BTCNT_w,
				CS_BTCCR0_o => CS_BTCCR0_w,
				CS_BTCCR1_o => CS_BTCCR1_w,
				CS_FIRCTL_o => CS_FIRCTL_w,
				CS_FIRIN_o => CS_FIRIN_w,
				CS_FIROUT_o => CS_FIROUT_w,
				CS_COEF30_o => CS_COEF30_w,
				CS_COEF74_o => CS_COEF74_w,
				CS_IC_o => CS_IC_w
	);
-------------------------------------------------------------------------------------
    FDIV : freq_divider
	port map ( rst_i  => rst_w,
	           clk_i  => MCLK_w,
			   clk2_o => MCLK2_w,
	           clk4_o => MCLK4_w,
			   clk8_o => MCLK8_w,
			   clk_FIR_o => MCLK_FIR_w
	);
	
---------------------------------------------------------------------------------
    BT : Timer
	generic map(
		DATA_BUS_WIDTH => DATA_BUS_WIDTH
	)
	PORT map(	rst_i     => rst_w,
	            MCLK_i    => MCLK_w,
            	MCLK2_i   => MCLK2_w,
				MCLK4_i   => MCLK4_w,
				MCLK8_i   => MCLK8_w,
			    CS_BTCTL_i   => CS_BTCTL_w,
			    CS_BTCNT_i   => CS_BTCNT_w,			
				CS_BTCCR0_i  => CS_BTCCR0_w,
				CS_BTCCR1_i  => CS_BTCCR1_w,
				MemRead_ctrl_i => MemRead_ctrl_w,
				MemWrite_ctrl_i   => MemWrite_ctrl_w,	  
			    DataBus   => DATA_BUS_w,
			    BTIFG_o   => BTIFG_w,
			    PWM_o     => pwm_o
	);

---------------------------------------------------------------------------------
    ITC : IC	
	generic map(
		DATA_BUS_WIDTH => DATA_BUS_WIDTH,
		REG_SIZE => REG_SIZE
	)
	PORT map(	rst_i            => rst_w,
	            clk_i            => MCLK_w,
            	INTA             => INTA_w,
				GIE              => GIE_w,
				CS_IC_i          => CS_IC_w,
                A0_i             => ADDRESS_BUS_w(0),
                A1_i             => ADDRESS_BUS_w(1),				
				MemRead_ctrl_i   => MemRead_ctrl_w,
				MemWrite_ctrl_i  => MemWrite_ctrl_w,
				INTR_SRC_i       => INTR_SRC_w,
				DataBus          => DATA_BUS_w,	
				FIFOEMPTY_i      => FIFOEMPTY_w,
				UART_status_error_i => UART_Status_ERROR_w,
			    INTR             => INTR_w
	);	
---------------------------------------------------------------------------------
    FIR_acc : FIR
	
	PORT map(	FIFOCLK_i            => MCLK_w,
	            FIRCLK_i             => MCLK_FIR_w,
            	rst_i                => rst_w,
				FIRIN_SEL_i          => CS_FIRIN_w,
				COEF0_3_SEL_i        => CS_COEF30_w,
                COEF4_7_SEL_i        => CS_COEF74_w,
                FIROUT_SEL_i         => CS_FIROUT_w,				
				FIRCTRL_SEL_i        => CS_FIRCTL_w,
				MemRead_ctrl_i       => MemRead_ctrl_w,
				MemWrite_ctrl_i      => MemWrite_ctrl_w,
				DATA_BUS             => DATA_BUS_w,	  
			    FIRIFG_o             => FIRIFG_w,
				FIFOEMPTY_o          => FIFOEMPTY_w
	);	

---------------------------------------------------------------------------------
    UART : USART
	
	PORT map(	rst_i                => rst_w,
	            clk_i                => MCLK_w,
            	CS_UART_i            => CS_UART_w,
				MemRead_i            => MemRead_ctrl_w,
				MemWrite_i           => MemWrite_ctrl_w,
                A0_i                 => ADDRESS_BUS_w(0),
                A1_i                 => ADDRESS_BUS_w(1),				
				DataBus              => DATA_BUS_w,
				RX_i                 => RX_i,
				UART_Status_ERROR_o  => UART_Status_ERROR_w,
				TX_o                 => TX_o,	  
			    RXIFG_o              => RXIFG_w,
				TXIFG_o              => TXIFG_w
	);	


---------------------------------------------------------------------------------	
	-- connect the PLL component
	G0:
	if (MODELSIM = 0) generate
	  MCLK: PLL
		PORT MAP (
			inclk0 	=> clk_i,
			c0 		=> MCLK_w
		);
	else generate
		MCLK_w <= clk_i;
	end generate;


	G1: 
	if (WORD_GRANULARITY = True) generate -- i.e. each WORD has a unike address
		MEM:  dmemory
			generic map(
				DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
				DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
				WORDS_NUM			=>	DATA_WORDS_NUM
			)
			PORT MAP (	
				clk_i 				=> MCLK_w,  
				rst_i 				=> rst_w,
				dtcm_addr_i 		=> DTCM_addr_w((DTCM_ADDR_WIDTH+2)-1 DOWNTO 2), -- increment memory address by 4
				dtcm_data_wr_i 		=> DTCM_DataIn_w,
				MemRead_ctrl_i 		=> MemRead_DTCM_w, 
				MemWrite_ctrl_i 	=> MemWrite_DTCM_w,
				dtcm_data_rd_o 		=> DTCM_DataOut_w 
			);	
	elsif (WORD_GRANULARITY = False) generate -- i.e. each BYTE has a unike address	
		MEM:  dmemory
			generic map(
				DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
				DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
				WORDS_NUM			=>	DATA_WORDS_NUM
			)
			PORT MAP (	
				clk_i 				=> MCLK_w,  
				rst_i 				=> rst_w,
				dtcm_addr_i 		=> DTCM_addr_w(DTCM_ADDR_WIDTH-1 DOWNTO 2)&"00",
				dtcm_data_wr_i 		=> DTCM_DataIn_w,
				MemRead_ctrl_i 		=> MemRead_DTCM_w, 
				MemWrite_ctrl_i 	=> MemWrite_DTCM_w,
				dtcm_data_rd_o 		=> DTCM_DataOut_w
			);
	end generate;

END structure;	