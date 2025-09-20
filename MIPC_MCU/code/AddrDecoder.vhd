LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;


ENTITY addrdecoder IS
	PORT(	A11_i, A6_i, A5_i, A4_i, A3_i, A2_i		        : IN 	STD_LOGIC;
			CS_LEDR_o, CS_HEX01_o, CS_HEX23_o, CS_HEX45_o, CS_SW_o, CS_KEY_0,
			CS_UART_o, CS_BTCTL_o, CS_BTCNT_o, CS_BTCCR0_o, CS_BTCCR1_o, CS_FIRCTL_o,
            CS_FIRIN_o, CS_FIROUT_o, CS_COEF30_o, CS_COEF74_o, CS_IC_o 	: OUT STD_LOGIC
	);
END addrdecoder;

ARCHITECTURE behavior OF addrdecoder IS

    SIGNAL A11_w, A6_w, A5_w, A4_w, A3_w, A2_w : STD_LOGIC;

BEGIN

    A11_w <= A11_i;
	A6_w  <= A6_i;
	A5_w  <= A5_i;
	A4_w  <= A4_i;
	A3_w  <= A3_i;
	A2_w  <= A2_i;
	
	--  DECODER LOGIC --
	CS_LEDR_o   <=  (not A2_w) and (not A3_w) and (not A4_w) and (not A5_w)and (not A6_w) and A11_w;    
	CS_HEX01_o  <= A2_w and (not A3_w) and (not A4_w) and (not A5_w)and (not A6_w) and A11_w;               
	CS_HEX23_o  <= (not A2_w) and A3_w and (not A4_w) and (not A5_w)and (not A6_w) and A11_w;           
	CS_HEX45_o  <= A2_w and A3_w and (not A4_w) and (not A5_w)and (not A6_w) and A11_w;          
	CS_SW_o     <= (not A2_w) and (not A3_w) and A4_w and (not A5_w)and (not A6_w) and A11_w;           
	CS_KEY_0    <= A2_w and (not A3_w) and A4_w and (not A5_w)and (not A6_w) and A11_w; 
	
	CS_UART_o   <= (not A2_w) and A3_w and A4_w and (not A5_w)and (not A6_w) and A11_w; 
	
	CS_BTCTL_o  <= A2_w and A3_w and A4_w and (not A5_w)and (not A6_w) and A11_w; 
	CS_BTCNT_o  <= (not A2_w) and (not A3_w) and (not A4_w) and A5_w and (not A6_w) and A11_w; 
	CS_BTCCR0_o <= A2_w and (not A3_w) and (not A4_w) and A5_w and (not A6_w) and A11_w; 
	CS_BTCCR1_o <= (not A2_w) and A3_w and (not A4_w) and A5_w and (not A6_w) and A11_w;
	
	CS_FIRCTL_o <= A2_w and A3_w and (not A4_w) and A5_w and (not A6_w) and A11_w; 
	CS_FIRIN_o  <= (not A2_w) and (not A3_w) and A4_w and  A5_w and (not A6_w) and A11_w; 
	CS_FIROUT_o <= A2_w and (not A3_w) and A4_w and A5_w and (not A6_w) and A11_w; 
	CS_COEF30_o <= (not A2_w) and A3_w and A4_w and A5_w and (not A6_w) and A11_w; 
	CS_COEF74_o <= A2_w and A3_w and A4_w and A5_w and (not A6_w) and A11_w; 
	
	CS_IC_o     <= (not A2_w) and (not A3_w) and (not A4_w) and (not A5_w) and A6_w and A11_w;
	
	END behavior;
