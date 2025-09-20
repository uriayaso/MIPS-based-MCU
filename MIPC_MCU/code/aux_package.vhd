---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_comilation_package.all;


package aux_package is


    component TOP IS
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
    END component;

	component MIPS_CORE is
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
			INST_CNT_WIDTH : integer 	:= 16
	);
	PORT(	rst_i		 		:IN	STD_LOGIC;
			clk_i				:IN	STD_LOGIC; 
			INTR_i              :IN	STD_LOGIC; 
			DATA_BUS_i          :IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			ADDRESS_BUS_i       :IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			-- Output important signals to pins for easy display in SignalTap
			pc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			alu_result_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			instruction_top_o	:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemWrite_ctrl_o		:OUT 	STD_LOGIC;
			MemRead_ctrl_o		:OUT 	STD_LOGIC;
			ISR_ctl_o           :OUT 	STD_LOGIC;
			INTA_o              :OUT 	STD_LOGIC;
			GIE_o               :OUT 	STD_LOGIC;
			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
			inst_cnt_o 			:OUT	STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0)
	);	
	end component;
---------------------------------------------------------  
	component control is
		PORT( 	
		opcode_i 			: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);
		ISR_ctl_i           : IN    STD_LOGIC;
		RegDst_ctrl_o 		: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ALUSrc_ctrl_o 		: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
		RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
		MemRead_ctrl_o 		: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;
		Branch_ctrl_o 		: OUT 	STD_LOGIC;
		bne_o               : OUT   STD_LOGIC;
		lui_o               : OUT   STD_LOGIC;
		ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(2 DOWNTO 0);
		Jmp_ctrl_o          : OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		jmp_isr_o           : OUT   STD_LOGIC
	);
	end component;
---------------------------------------------------------	
	component dmemory is
		generic(
		DATA_BUS_WIDTH : integer := 32;
		DTCM_ADDR_WIDTH : integer := 8;
		WORDS_NUM : integer := 256
	);
	PORT(	clk_i,rst_i			: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
	end component;
---------------------------------------------------------		
	component Execute is
		generic(
			DATA_BUS_WIDTH : integer := 32;
			FUNCT_WIDTH : integer := 6;
			PC_WIDTH : integer := 10;
			k : integer := 5
		);
		PORT(	
			read_data1_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			funct_i 		: IN 	STD_LOGIC_VECTOR(FUNCT_WIDTH-1 DOWNTO 0);
			ALUOp_ctrl_i 	: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0);
			ALUSrc_ctrl_i 	: IN 	STD_LOGIC;
			pc_plus4_i 		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			bne_i           : IN    STD_LOGIC; 
			zero_o 			: OUT	STD_LOGIC;
			alu_res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_res_o 		: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 )
		);
	end component;
---------------------------------------------------------		
	component Idecode is
		generic(
			DATA_BUS_WIDTH : integer := 32;
			PC_WIDTH : integer := 10
		);
		PORT(	
			clk_i,rst_i		: IN 	STD_LOGIC;
			instruction_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			alu_result_i	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			RegWrite_ctrl_i : IN 	STD_LOGIC;
			MemtoReg_ctrl_i : IN 	STD_LOGIC;
			RegDst_ctrl_i 	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			pc_plus4_i 		: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			Jmp_ctrl_i       : IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			lui_ctrl_i      : IN    STD_LOGIC;
			INTR_i       : IN    STD_LOGIC;
			ISR_ctl_i     : IN    STD_LOGIC;
			EPC       : IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			GIE_o           : OUT STD_LOGIC;
			read_data1_o	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_o 	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)			 
		);
	end component;
---------------------------------------------------------		
	component Ifetch is
		generic(
			WORD_GRANULARITY : boolean 	:= False;
			DATA_BUS_WIDTH : integer 	:= 32;
			PC_WIDTH : integer 			:= 10;
			NEXT_PC_WIDTH : integer 	:= 8; -- NEXT_PC_WIDTH = PC_WIDTH-2
			ITCM_ADDR_WIDTH : integer 	:= 8;
			WORDS_NUM : integer 		:= 256;
			INST_CNT_WIDTH : integer 	:= 16
		);
		PORT(	
			clk_i, rst_i 	: IN 	STD_LOGIC;
		add_result_i 	: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
        Branch_ctrl_i 	: IN 	STD_LOGIC;
        zero_i 			: IN 	STD_LOGIC;	
		jmp_i 	        : IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		alu_res_i       : IN    STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		PC_HOLD_i       : IN    STD_LOGIC;
		ISR_ctl_i       : IN    STD_LOGIC;
		jmp_isr_i       : IN    STD_LOGIC;
		INTR_i          : IN    STD_LOGIC;
		ISR_addr_i      : IN    STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		pc_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		pc_plus4_o 		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		inst_cnt_o 		: OUT	STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
        EPC 		    : OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)	
		);
	end component;
---------------------------------------------------------
	COMPONENT PLL port(
	    areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0     		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC );
    END COMPONENT;
---------------------------------------------------------	
COMPONENT Shifter IS
  GENERIC (n : INTEGER := 32;
		   k : integer := 5);   -- k=log2(n)
	
	PORT (
	X,Y 	:IN std_logic_vector (n-1 DOWNTO 0);
	dir		:IN std_logic_vector (2 DOWNTO 0);
	res		:OUT std_logic_vector (n-1 DOWNTO 0)
	);
end COMPONENT;

----------------------------------------------------------
COMPONENT gpio IS
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
END COMPONENT;

----------------------------------------------------------
COMPONENT addrdecoder IS
	PORT(	A11_i, A6_i, A5_i, A4_i, A3_i, A2_i		        : IN 	STD_LOGIC;
			CS_LEDR_o, CS_HEX01_o, CS_HEX23_o, CS_HEX45_o, CS_SW_o, CS_KEY_0,
			CS_UART_o, CS_BTCTL_o, CS_BTCNT_o, CS_BTCCR0_o, CS_BTCCR1_o, CS_FIRCTL_o,
            CS_FIRIN_o, CS_FIROUT_o, CS_COEF30_o, CS_COEF74_o, CS_IC_o 	: OUT STD_LOGIC
	);
END COMPONENT;


----------------------------------------------------------
COMPONENT BidirPin is
	generic( width: integer:=16 );
	port(   Dout: 	in 		std_logic_vector(width-1 downto 0);
			en:		in 		std_logic;
			Din:	out		std_logic_vector(width-1 downto 0);
			IOpin: 	inout 	std_logic_vector(width-1 downto 0)
	);
end COMPONENT;

-------------------------------------------------------------
COMPONENT bin2sevenseg is
    port (
        bin  : in  std_logic_vector(3 downto 0);
        segs : out std_logic_vector(6 downto 0)
    );
end COMPONENT;

-------------------------------------------------------------
COMPONENT freq_divider IS
	generic(
		n : INTEGER := 2;
		m : INTEGER := 1;
		k : INTEGER := 0
	);
	PORT(
	     rst_i, clk_i                  : IN  STD_LOGIC;
	     clk2_o, clk4_o, clk8_o, clk_FIR_o : OUT STD_LOGIC
	);
END COMPONENT;

-------------------------------------------------------------
COMPONENT Timer IS
	generic(
		DATA_BUS_WIDTH : integer := 32
	);
	PORT(
	     rst_i, MCLK_i, MCLK2_i, MCLK4_i, MCLK8_i : IN STD_LOGIC;
	     CS_BTCTL_i, CS_BTCNT_i, CS_BTCCR0_i, CS_BTCCR1_i : IN STD_LOGIC;
	     MemRead_ctrl_i, MemWrite_ctrl_i : IN STD_LOGIC;
		 DataBus      : INOUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		 BTIFG_o, PWM_o                    : OUT STD_LOGIC
	);
END COMPONENT;

-------------------------------------------------------------
COMPONENT IC IS
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
END COMPONENT;	

-------------------------------------------------------------
COMPONENT FIR IS
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
END COMPONENT;
-------------------------------------------------------------
COMPONENT FIFO is
  generic (
    W : integer := 24;  -- data width
    K : integer := 8    -- depth (entries)
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
end COMPONENT;
-------------------------------------------------------------
COMPONENT FIR_eccelerator is
  generic (
    W : integer := 24;  -- data width
    M : integer := 8;    -- NUMBER OF PAST SAMPELS 
	q :	integer := 8	-- coeffecent width
  );
  port (
    FIRCLK_i     		: IN  std_logic;  
    FIRRST_i     		: IN  std_logic;  
    FIRENA_i   			: IN  std_logic;
	
    Xn_i	 			: IN  std_logic_vector(W-1 downto 0);
    COEF0_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ; 
    COEF1_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;
    COEF2_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;
    COEF3_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;
    COEF4_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;
    COEF5_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;
    COEF6_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;
    COEF7_i  			: IN  std_logic_vector(q-1 DOWNTO 0) ;	
    Yn_o 				: OUT std_logic_vector(W-1 downto 0);

    OUTPUT_valid	    : OUT std_logic 

	);
end COMPONENT;
-------------------------------------------------------------
COMPONENT puls_synchronizer is
  port ( 
 -------source clk----------
    FIRCLK_i     		: IN  std_logic;  
    FIREN_i     		: IN  std_logic;
-------destination clk-------
	FIFOCLK_i     		: IN  std_logic; 
	FIFOREN_o			: OUT std_logic
	);
end COMPONENT;
-------------------------------------------------------------
COMPONENT USART is
  generic (
    DATA_BUS_WIDTH : integer := 32;
	REG_SIZE : integer := 8;
    g_CLKS_PER_BIT : integer := 217     -- Needs to be set correctly
    );
  port (
    rst_i, clk_i       : in  std_logic;
    CS_UART_i, MemRead_i, MemWrite_i ,A0_i, A1_i  : in  std_logic;
	DataBus      : INOUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); 
	RX_i         : IN std_logic;    -- IN TOP
	UART_Status_ERROR_o : OUT std_logic;
	TX_o                : OUT std_logic;
	RXIFG_o, TXIFG_o    : OUT std_logic
    );
end COMPONENT;
-------------------------------------------------------------
COMPONENT UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 217     -- Needs to be set correctly
    );
  port (
    rst_i       : IN  std_logic;
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
	PENA_i      : IN  std_logic;
	PEV_i       : IN  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0);
	FE_o        : OUT std_logic;
	PE_o        : OUT std_logic;
	OE_o        : OUT std_logic;
	RX_BUSY_o   : OUT std_logic
	
    );
end COMPONENT;
-------------------------------------------------------------
COMPONENT UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 217     -- Needs to be set correctly
    );
  port (
    rst_i       : IN  std_logic;
    i_Clk       : in  std_logic;
    i_TX_DV     : in  std_logic;
    i_TX_Byte   : in  std_logic_vector(7 downto 0);
	PENA_i      : IN  std_logic;
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic
    );
end COMPONENT;
 
-------------------------------------------------------------

end aux_package;



