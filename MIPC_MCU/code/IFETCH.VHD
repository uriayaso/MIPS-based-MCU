---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


ENTITY Ifetch IS
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
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	SIGNAL pc_q				  	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_r 			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_addr_w 			: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0);
	signal next_pc_mux1_w : std_logic_vector(NEXT_PC_WIDTH-1 downto 0);

	SIGNAL rst_flag_q			: STD_LOGIC;
	SIGNAL inst_cnt_q 			: STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL pc_prev_q			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);  
	SIGNAL jmp_addr_w           : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL jmp_ctrl_w           : STD_LOGIC_VECTOR(1 DOWNTO 0);
	
	SIGNAL instruction_w        : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
BEGIN

--ROM for Instruction Memory
	inst_memory: altsyncram
	GENERIC MAP (
		operation_mode => "ROM",
		width_a => DATA_BUS_WIDTH,
		widthad_a => ITCM_ADDR_WIDTH,
		numwords_a => WORDS_NUM,
		lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "C:\LABS\FinalProject\test\ITCM.hex",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		clock0     => clk_i,
		address_a  => itcm_addr_w, 
		q_a 	   => instruction_o 
	);
	
	-- Instructions always start on word address - not byte
	pc_q(1 DOWNTO 0) 	<= "00";
	
	-- send address to inst. memory address register
	G1: 
	if (WORD_GRANULARITY = True) generate 		-- i.e. each WORD has unike address
		itcm_addr_w <= next_pc_w;
	elsif (WORD_GRANULARITY = False) generate 	-- i.e. each BYTE has unike address
		itcm_addr_w <= next_pc_w & "00";
	end generate;
		
	-- Adder to increment PC by 4
	pc_plus4_r( 1 DOWNTO 0 )  		 <= "00";
    pc_plus4_r(PC_WIDTH-1 DOWNTO 2)  <= pc_q(PC_WIDTH-1 DOWNTO 2) + 1;
	
	-- Jump terget addres
	jmp_addr_w(1 DOWNTO 0 ) <= "00";
	jmp_addr_w(27 DOWNTO 2) <= instruction_o(25 DOWNTO 0);
	jmp_addr_w(31 DOWNTO 28) <= pc_plus4_r(PC_WIDTH-1 DOWNTO 6);
									
PROCESS(clk_i, rst_i)
BEGIN
    if(rst_i = '1') THEN
	   EPC <= (OTHERS => '0');
	elsif(rising_edge(clk_i) and INTR_i = '1') THEN
	    if(jmp_isr_i = '1') THEN
		    EPC <= (X"00000" & B"00" & pc_q) - 4;
		ELSE
           	EPC <= (X"00000" & B"00" & pc_plus4_r) - 4;
        end if;
    end if;
end PROCESS;	
	-- Mux to select Branch Address or PC + 4        
	------------------------------------------------------------------------------------				
	next_pc_mux1_w  <= 	(others => '0') WHEN rst_flag_q = '1' ELSE
					add_result_i  WHEN ((Branch_ctrl_i = '1') AND (zero_i = '1')) ELSE
					pc_plus4_r(PC_WIDTH-1 DOWNTO 2);				
					
	-- Mux to select jump addres/ next pc
	jmp_ctrl_w <= "11" WHEN ISR_ctl_i = '1' ELSE
	              "00" WHEN (instruction_o(5 DOWNTO 0) /= "001000" and jmp_i /= "10") or rst_flag_q = '1' ELSE
	              jmp_i;
				  
	
	with jmp_ctrl_w select
	     next_pc_w <=      next_pc_mux1_w                   when "00",
		                   alu_res_i(PC_WIDTH-1 DOWNTO 2)   when "01",
						   jmp_addr_w(PC_WIDTH-1 DOWNTO 2)  when "10",
						   ISR_addr_i(PC_WIDTH-1 DOWNTO 2)  when others;
						  
	-------------------------------------------------------------------------------------
	process (clk_i)
	BEGIN
		IF(clk_i'EVENT  AND clk_i='1') THEN
			rst_flag_q <= rst_i;
		end if;
	end process;
	-------------------------------------------------------------------------------------
	PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			pc_q(PC_WIDTH-1 DOWNTO 2) <= (OTHERS => '0') ; 
		ELSIF(clk_i'EVENT  AND clk_i='1' and PC_HOLD_i = '0') THEN
			pc_q(PC_WIDTH-1 DOWNTO 2) <= next_pc_w;	
		END IF;
	END PROCESS;
---------------------------------------------------------------------------------------
--						IPC - instruction counter register
---------------------------------------------------------------------------------------
process (clk_i , rst_i)
begin
	if rst_i = '1' then
		pc_prev_q	<=	(others	=> '0');
	elsif falling_edge(clk_i) then
		pc_prev_q	<=	pc_q;
	end if;
end process;
---------------------------------------------------------------------------------------
process (clk_i , rst_i)
begin
	if rst_i = '1' then
		inst_cnt_q	<=	(others	=> '0');
	elsif rising_edge(clk_i) then
		if pc_prev_q = pc_q then
			inst_cnt_q	<=	inst_cnt_q + '1';
		end if;
	end if;
end process;
---------------------------------------------------------------------------------------
	-- copy output signals - allows read inside module
	pc_o 				<= 	pc_q;
	pc_plus4_o 			<= 	pc_plus4_r;
	inst_cnt_o			<=	inst_cnt_q;
END behavior;


