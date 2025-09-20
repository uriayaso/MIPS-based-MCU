---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Idecode module (implements the register file for the MIPS computer
LIBRARY IEEE; 		
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


ENTITY Idecode IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		PC_WIDTH : integer := 10
	);
	PORT(	clk_i,rst_i		: IN 	STD_LOGIC;
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
END Idecode;


ARCHITECTURE behavior OF Idecode IS
TYPE register_file IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL RF_q					: register_file;
	SIGNAL write_reg_addr_w 	: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_reg_data1_w	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL write_reg_data_w		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL rs_register_w		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL rt_register_w		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL rd_register_w		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL ra_register_w		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL PC_link_w            : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL PC_back_ISR            : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL imm_value_w			: STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	SIGNAL shmt_w				: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	signal shift_w              : STD_LOGIC;
	SIGNAL upper_imm_w          : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_mux_w     : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL sign_extend_shmt_w	:STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);


BEGIN
	rs_register_w 			<= instruction_i(25 DOWNTO 21);
   	rt_register_w 			<= instruction_i(20 DOWNTO 16);
   	rd_register_w			<= instruction_i(15 DOWNTO 11);
	ra_register_w           <= "11111";
   	imm_value_w 			<= instruction_i(15 DOWNTO 0);
	shmt_w					<= instruction_i(10 DOWNTO 6);
	PC_link_w               <= X"00000" & B"00" & pc_plus4_i;
	
	
	shift_w <= '1' when (((instruction_i(5 DOWNTO 0) = "000000") or (instruction_i(5 DOWNTO 0) = "000010"))
                        and (instruction_i(31 DOWNTO 26) = "000000"))	ELSE
                '0';	
	-- Read Register 1 Operation
	read_data1_o <= RF_q(CONV_INTEGER(rs_register_w)) WHEN shift_w = '0' ELSE
					sign_extend_shmt_w;
	
	-- Read Register 2 Operation mux with shmt sign Extend		 
	read_data2_o <= RF_q(CONV_INTEGER(rt_register_w));
	
	-- Mux for Register Write Address
	write_reg_addr_w <= rd_register_w WHEN RegDst_ctrl_i = "10" ELSE
                        ra_register_w WHEN RegDst_ctrl_i = "01" ELSE	
						rt_register_w WHEN RegDst_ctrl_i = "00" ELSE
						(others => '0');
	
	-- Mux to bypass data memory for Rformat instructions
	write_reg_data1_w <= alu_result_i(DATA_BUS_WIDTH-1 DOWNTO 0) WHEN (MemtoReg_ctrl_i = '0') ELSE 
						dtcm_data_rd_i;

	with write_data_mux_w select
	      write_reg_data_w <= PC_link_w         when "01",
		                      upper_imm_w       when "10",
							  write_reg_data1_w when others;
						
	-----
    upper_imm_w <= alu_result_i(15 DOWNTO 0) & X"0000";
	write_data_mux_w(0) <= '1' when (RegDst_ctrl_i = "01" and Jmp_ctrl_i = "10") else '0'; 
	write_data_mux_w(1) <= lui_ctrl_i;
	
	-- Sign Extend 16-bits to 32-bits
    sign_extend_o <= 	X"0000" & imm_value_w WHEN imm_value_w(15) = '0' ELSE
						X"FFFF" & imm_value_w;

	-- Sign Extend 5-bits to 32-bits
    sign_extend_shmt_w <= 	X"000000" & B"000" & shmt_w WHEN shmt_w(4) = '0' ELSE
							X"FFFFFF" & B"111" & shmt_w;
							
	GIE_o <= RF_q(26)(0);						

	process(clk_i,rst_i, INTR_i, ISR_ctl_i)
	begin
		if (rst_i='1') then
			FOR i IN 0 TO 31 LOOP
				-- RF_q(i) <= CONV_STD_LOGIC_VECTOR(i,32);
				RF_q(i) <= CONV_STD_LOGIC_VECTOR(0,32);
			END LOOP;
		elsif (clk_i'event and clk_i='1') then
			if (RegWrite_ctrl_i = '1' AND write_reg_addr_w /= 0) then
				RF_q(CONV_INTEGER(write_reg_addr_w)) <= write_reg_data_w;
				-- index is integer type so we must use conv_integer for type casting
			end if;
		end if;
		if (INTR_i = '1') then
		    RF_q(26)(0) <= '0';
	    ELSIF (rs_register_w = "11011" and Jmp_ctrl_i = "01") then   -- reti then GIE = 1
		    RF_q(26)(0) <= '1';
		end if;
		if(ISR_ctl_i = '1') then
		    RF_q(27) <= EPC;
		end if;
end process;

END behavior;





