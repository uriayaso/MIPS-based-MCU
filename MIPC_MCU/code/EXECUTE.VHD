---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.aux_package.all;


ENTITY  Execute IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		FUNCT_WIDTH : integer := 6;
		PC_WIDTH : integer := 10;
		k : integer := 5
	);
	PORT(	read_data1_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			funct_i 		: IN 	STD_LOGIC_VECTOR(FUNCT_WIDTH-1 DOWNTO 0);
			ALUOp_ctrl_i 	: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0);
			ALUSrc_ctrl_i 	: IN 	STD_LOGIC;
			pc_plus4_i 		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			bne_i           : IN    STD_LOGIC;    -- for branch mux
			zero_o 			: OUT	STD_LOGIC;
			alu_res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_res_o 		: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 )
	);
END Execute;


ARCHITECTURE behavior OF Execute IS
SIGNAL a_input_w, b_input_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
SIGNAL alu_out_mux_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
SIGNAL branch_addr_r 			: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL alu_ctl_w, alu_ctl_rtype_w				: STD_LOGIC_VECTOR(3 DOWNTO 0);
--------Signals for Branch--
Signal zero_w : STD_LOGIC;
------- Signals for Shifter --
SIGNAL a_shifter, b_shifter : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
signal dir :STD_LOGIC_VECTOR(2 DOWNTO 0);
signal shift_res : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
	a_input_w <= 	read_data1_i;
	-- ALU input mux
	b_input_w <= 	read_data2_i WHEN (ALUSrc_ctrl_i = '0') ELSE
					sign_extend_i(DATA_BUS_WIDTH-1 DOWNTO 0);
--------------------------------------------------------------------------------------------------------
--  Generate ALU control bits
--------------------------------------------------------------------------------------------------------
	with funct_i Select
	alu_ctl_rtype_w <= "0000" when "100100",  -- AND
	                   "0001" when "100101",  -- OR
					   "0010" when "100000",  -- add
					   "0010" when "001000",  -- add for jr
					   "0011" when "100001",  -- addu
					   "0100" when "100110",  -- xor
					   "0101" when "000000",  -- shift left
					   "0101" when "000010",  -- shift right
					   "0110" when "100010",  -- sub
					   "0111" when "101010",  -- slt
					   unaffected when others;
	
	
	with ALUOp_ctrl_i select
         alu_ctl_w <= "0010" when "000",  -- addi
		              "0110" when "001",  -- sub for branches
                      "0000" when "011",  --andi
                      "0100" when "101",  -- xori
                      "0001" when "110",  -- ori
					  "1110" when "100",  -- mul
					  "0111" when "111",  -- slti
                      alu_ctl_rtype_w when "010", -- Rtype
					  unaffected when others;
--------------------------------------------------------------------------------------------------------
-- Shifter
    a_shifter <= a_input_w when alu_ctl_w = "0101" else X"00000000";
	b_shifter <= b_input_w when alu_ctl_w = "0101" else X"00000000";
    dir <= funct_i(3 DOWNTO 1);      ---  000-sll , 001-srl

shifter_unit : Shifter generic map(DATA_BUS_WIDTH,k)
                       port map(
					    x => a_shifter,
						Y => b_shifter,
						dir => dir,
						res => shift_res
						);
                       					   
--------------------------------------------------------------------------------------------------------
-- Branch
   with bne_i Select
        zero_o <= zero_w when '0',
		          not zero_w when '1',
				  unaffected when others;
				  
--------------------------------------------------------------------------------------------------------

	-- Generate Zero Flag
	zero_w <= 	'1' WHEN (alu_out_mux_w(DATA_BUS_WIDTH-1 DOWNTO 0) = X"00000000") ELSE
				'0';    
	
	-- Select ALU output        
	alu_res_o <= 	X"0000000" & B"000"  & alu_out_mux_w(31) WHEN  alu_ctl_w = "0111" ELSE   -- SLT if 111
					alu_out_mux_w(DATA_BUS_WIDTH-1 DOWNTO 0);
					
	-- Adder to compute Branch Address
	branch_addr_r	<= pc_plus4_i(PC_WIDTH-1 DOWNTO 2) + sign_extend_i(7 DOWNTO 0) ;
	addr_res_o 		<= branch_addr_r(7 DOWNTO 0);


PROCESS (alu_ctl_w, a_input_w, b_input_w, shift_res)
	BEGIN		
 	CASE alu_ctl_w IS	-- Select ALU operation
						-- ALU performs ALUresult = A_input AND B_input
		WHEN "0000" 	=>	alu_out_mux_w 	<= a_input_w AND b_input_w; 
						-- ALU performs ALUresult = A_input OR B_input
     	WHEN "0001" 	=>	alu_out_mux_w 	<= a_input_w OR b_input_w;
						-- ALU performs ALUresult = A_input + B_input
	 	WHEN "0010" 	=>	alu_out_mux_w 	<= a_input_w + b_input_w;
						-- ALU performs ADDU/JR
 	 	WHEN "0011" 	=>	alu_out_mux_w   <= a_input_w + b_input_w;
						-- ALU performs XOR
 	 	WHEN "0100" 	=>	alu_out_mux_w 	<= a_input_w XOR b_input_w;
						-- ALU performs SHIFT
 	 	WHEN "0101" 	=>	alu_out_mux_w 	<= shift_res;
						-- ALU performs ALUresult = A_input -B_input
 	 	WHEN "0110" 	=>	alu_out_mux_w 	<= a_input_w - b_input_w;
						-- ALU performs SLT
  	 	WHEN "0111" 	=>	alu_out_mux_w 	<= a_input_w - b_input_w ;
		                -- ALU performs MUL
		WHEN "1110"     =>  alu_out_mux_w   <= a_input_w(15 DOWNTO 0) * b_input_w(15 DOWNTO 0);
		
 	 	WHEN OTHERS	    =>	alu_out_mux_w 	<= X"00000000" ;
		
  	END CASE;
  END PROCESS;
  
END behavior;

