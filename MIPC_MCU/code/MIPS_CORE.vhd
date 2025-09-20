---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;


ENTITY MIPS_CORE IS
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
END MIPS_CORE;
-------------------------------------------------------------------------------------
ARCHITECTURE structure OF MIPS_CORE IS
	-- declare signals used to connect VHDL components
	SIGNAL pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL read_data1_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL sign_extend_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL addr_res_w 		: STD_LOGIC_VECTOR(7 DOWNTO 0 );
	SIGNAL alu_result_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_src_w 		: STD_LOGIC;
	SIGNAL branch_w 		: STD_LOGIC;
	SIGNAL bne_w            : STD_LOGIC;
	SIGNAL lui_w            : STD_LOGIC;
	SIGNAL jmp_ctrl_w       : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL reg_dst_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL reg_write_w 		: STD_LOGIC;
	SIGNAL zero_w 			: STD_LOGIC;
	SIGNAL mem_write_w 		: STD_LOGIC;
	SIGNAL MemtoReg_w 		: STD_LOGIC;
	SIGNAL mem_read_w 		: STD_LOGIC;
	SIGNAL alu_op_w 		: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL instruction_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mclk_cnt_q		: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL inst_cnt_w		: STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
	
	
	-- INTERRUPT --
	SIGNAL ISR_ctl_w, PC_HOLD_w, jmp_isr_w : STD_LOGIC;
	SIGNAL state     : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL EPC	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
					-- copy important signals to output pins for easy 
					-- display in Simulator
   instruction_top_o 	<= 	instruction_w;
   
   alu_result_o 		<= 	alu_result_w;  -- ADDRESS BUS
   read_data2_o 		<= 	read_data2_w;  -- DATA BUS
   MemWrite_ctrl_o 		<= 	mem_write_w;
   MemRead_ctrl_o       <=  mem_read_w;

   ISR_ctl_o <= ISR_ctl_w;
-------------------- Interrupt Routine ---------------------------------------------
   process(clk_i, rst_i, INTR_i, state)
   
   BEGIN
       if (rst_i = '1') then
	       state <= "00";
	       INTA_o  <= '1';
	       ISR_ctl_w <= '0';
		   PC_HOLD_w <= '0';
	   elsif (falling_edge(clk_i)) then
	       if (state = "00") then
		      if(INTR_i = '1') then
			     INTA_o    <= '0';
				 PC_HOLD_w <= '1';
				 ISR_ctl_w <= '1';
				 state   <= "01";
			  end if;
				 
		   elsif(state = "01") then
		      INTA_o <= '1';
			  --ISR_ctl_w <= '1';
			  PC_HOLD_w <= '0';
			  state <= "10";
		   
		   else
		      ISR_ctl_w <= '0';
		      state <= "00";
		   end if;
		end if;
    end process;

----------------------------------------------------------------------------------------
	-- connect the 5 MIPS components   
	IFE : Ifetch
	generic map(
		WORD_GRANULARITY	=> 	WORD_GRANULARITY,
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
		PC_WIDTH			=>	PC_WIDTH,
		ITCM_ADDR_WIDTH		=>	ITCM_ADDR_WIDTH,
		WORDS_NUM			=>	DATA_WORDS_NUM,
		INST_CNT_WIDTH		=>	INST_CNT_WIDTH
	)
	PORT MAP (	
		clk_i 			=> clk_i,  
		rst_i 			=> rst_i, 
		add_result_i 	=> addr_res_w,
		Branch_ctrl_i 	=> branch_w,
		zero_i 			=> zero_w,
		jmp_i           => jmp_ctrl_w,
		alu_res_i       => alu_result_w,
		PC_HOLD_i       => PC_HOLD_w,
		ISR_ctl_i       => ISR_ctl_w,
		jmp_isr_i       => jmp_isr_w,
		INTR_i          => INTR_i,
		ISR_addr_i      => ADDRESS_BUS_i,
		pc_o 			=> pc_o,
		instruction_o 	=> instruction_w,
    	pc_plus4_o	 	=> pc_plus4_w,
		inst_cnt_o		=> inst_cnt_w,
		EPC             => EPC
	);

	ID : Idecode
   	generic map(
		DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
	)
	PORT MAP (	
			clk_i 				=> clk_i,  
			rst_i 				=> rst_i,
        	instruction_i 		=> instruction_w,
        	dtcm_data_rd_i 		=> DATA_BUS_i,
			alu_result_i 		=> alu_result_w,
			RegWrite_ctrl_i 	=> reg_write_w,
			MemtoReg_ctrl_i 	=> MemtoReg_w,
			RegDst_ctrl_i 		=> reg_dst_w,
			pc_plus4_i          => pc_plus4_w,
			Jmp_ctrl_i          => jmp_ctrl_w,
			lui_ctrl_i          => lui_w,
			INTR_i              => INTR_i,
			ISR_ctl_i           => ISR_ctl_w,
			EPC                 => EPC,
			GIE_o               => GIE_o,
			read_data1_o 		=> read_data1_w,
        	read_data2_o 		=> read_data2_w,
			sign_extend_o 		=> sign_extend_w	 
		);

	CTL:   control
	PORT MAP ( 	
			opcode_i 			=> instruction_w(DATA_BUS_WIDTH-1 DOWNTO 26),
			ISR_ctl_i           => ISR_ctl_w,
			RegDst_ctrl_o 		=> reg_dst_w,
			ALUSrc_ctrl_o 		=> alu_src_w,
			MemtoReg_ctrl_o 	=> MemtoReg_w,
			RegWrite_ctrl_o 	=> reg_write_w,
			MemRead_ctrl_o 		=> mem_read_w,
			MemWrite_ctrl_o 	=> mem_write_w,
			Branch_ctrl_o 		=> branch_w,
			bne_o               => bne_w,
			lui_o               => lui_w,
			ALUOp_ctrl_o 		=> alu_op_w,
			Jmp_ctrl_o          => jmp_ctrl_w,
			jmp_isr_o           => jmp_isr_w
		);

	EXE:  Execute
   	generic map(
		DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
		FUNCT_WIDTH 		=>	FUNCT_WIDTH,
		PC_WIDTH 			=>	PC_WIDTH
	)
	PORT MAP (	
		read_data1_i 	=> read_data1_w,
        read_data2_i 	=> read_data2_w,
		sign_extend_i 	=> sign_extend_w,
        funct_i			=> instruction_w(5 DOWNTO 0),
		ALUOp_ctrl_i 	=> alu_op_w,
		ALUSrc_ctrl_i 	=> alu_src_w,
		pc_plus4_i      => pc_plus4_w,
		bne_i           => bne_w,
		zero_o 			=> zero_w,
        alu_res_o		=> alu_result_w,
		addr_res_o 		=> addr_res_w			
	);


---------------------------------------------------------------------------------------
--									IPC - MCLK counter register
---------------------------------------------------------------------------------------
process (clk_i , rst_i)
begin
	if rst_i = '1' then
		mclk_cnt_q	<=	(others	=> '0');
	elsif rising_edge(clk_i) then
		mclk_cnt_q	<=	mclk_cnt_q + '1';
	end if;
end process;

mclk_cnt_o	<=	mclk_cnt_q;
inst_cnt_o	<=	inst_cnt_w;
---------------------------------------------------------------------------------------
END structure;

