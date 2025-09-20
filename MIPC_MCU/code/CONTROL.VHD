---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;


ENTITY control IS
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
END control;

ARCHITECTURE behavior OF control IS

	SIGNAL  rtype_w, lw_w, sw_w, beq_w, itype_imm_w, mul_w, xori_w,
            addi_w, ori_w, andi_w, slti_w, bne_w, jmp_w, jal_w, lui_w   : STD_LOGIC;

BEGIN           
				-- Code to generate control signals using opcode bits
	rtype_w 			<=  '1'	WHEN	opcode_i = R_TYPE_OPC and (ISR_ctl_i = '0')  		ELSE '0';
	lw_w          		<=  '1'	WHEN  	opcode_i = LW_OPC and (ISR_ctl_i = '0')  			ELSE '0';
 	sw_w          		<=  '1'	WHEN  	opcode_i = SW_OPC and (ISR_ctl_i = '0')  			ELSE '0';
   	beq_w         		<=  '1'	WHEN  	opcode_i = BEQ_OPC  and (ISR_ctl_i = '0') 		ELSE '0';
	itype_imm_w			<=	'1'	WHEN	((opcode_i = ADDI_OPC) or 
										( opcode_i = ORI_OPC)  or 
										( opcode_i = ANDI_OPC) or
										( opcode_i = SLTI_OPC) or
          								( opcode_i = XORI_OPC) or
 				                        (opcode_i = LI_OPC)) and (ISR_ctl_i = '0')	    ELSE '0';
    xori_w              <=  '1' WHEN    opcode_i = XORI_OPC   and (ISR_ctl_i = '0')       ELSE '0';
    addi_w              <=  '1' WHEN    ((opcode_i = ADDI_OPC) OR
                                         (opcode_i = LI_OPC)) and (ISR_ctl_i = '0')    	ELSE '0';	
    ori_w               <=  '1' WHEN    opcode_i = ORI_OPC and (ISR_ctl_i = '0')         ELSE '0';	
    andi_w              <=  '1' WHEN    opcode_i = ANDI_OPC  and (ISR_ctl_i = '0')        ELSE '0';
    slti_w              <=  '1' WHEN    opcode_i = SLTI_OPC  and (ISR_ctl_i = '0')        ELSE '0';	
    mul_w               <=  '1' WHEN    opcode_i = MUL_OPC  and (ISR_ctl_i = '0')         ELSE '0';	
	bne_w               <=  '1' WHEN    opcode_i = BNE_OPC  and (ISR_ctl_i = '0')         ELSE '0';
	jmp_w               <=  '1' WHEN    opcode_i = JMP_OPC  and (ISR_ctl_i = '0')         ELSE '0';
    jal_w               <=  '1' WHEN    opcode_i = JAL_OPC and (ISR_ctl_i = '0')	        ELSE '0';
	lui_w               <=  '1' WHEN    opcode_i = LUI_OPC  and (ISR_ctl_i = '0')         ELSE '0';
	
    RegDst_ctrl_o(0)    <=  jal_w;	
  	RegDst_ctrl_o(1)    <=  rtype_w or mul_w;
 	ALUSrc_ctrl_o  		<=  lw_w OR sw_w or itype_imm_w or lui_w;
	MemtoReg_ctrl_o 	<=  lw_w;
  	RegWrite_ctrl_o 	<=  rtype_w OR lw_w or itype_imm_w or mul_w or jal_w or lui_w;
  	MemRead_ctrl_o 		<=  lw_w;
   	MemWrite_ctrl_o 	<=  sw_w; 
 	Branch_ctrl_o      	<=  beq_w or bne_w;   
    bne_o               <=  bne_w;
	lui_o               <=  lui_w;
	
	Jmp_ctrl_o(0)   <= rtype_w;
    Jmp_ctrl_o(1)   <= jmp_w or jal_w;
	jmp_isr_o       <= jmp_w or jal_w or Branch_ctrl_o;
	ALUOp_ctrl_o(0) <=  beq_w or bne_w or xori_w or andi_w or slti_w;
	ALUOp_ctrl_o(1) <=  rtype_w or andi_w or ori_w or slti_w;
	ALUOp_ctrl_o(2) <=  mul_w or xori_w or ori_w or slti_w;

   END behavior;


