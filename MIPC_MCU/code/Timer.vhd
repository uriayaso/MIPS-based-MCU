LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.aux_package.all;


ENTITY Timer IS
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
END Timer;

ARCHITECTURE behavior OF Timer IS

    SIGNAL BTCNT_clk_w, en_w, pwm_w : STD_LOGIC;
	SIGNAL HEU0_w, Q24_w, Q28_w, Q32_w : STD_LOGIC;
	
	SIGNAL BTCCR0_w, BTCCR1_w     : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL BTCTL_i, BTCNT_i, BTCCR0_i, BTCCR1_i     : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL BTCNT_r, BTCL0_r, BTCL1_r     : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL BTCTL_r  :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL BTCTL_wr_EN, BTCTL_rd_EN, BTCNT_wr_EN, BTCNT_rd_EN : STD_LOGIC;
	SIGNAL BTCCR0_wr_EN, BTCCR0_rd_EN, BTCCR1_wr_EN, BTCCR1_rd_EN : STD_LOGIC;
	
	SIGNAL BTCLR_w, BTHOLD_w, BTOUTMD_w, BTOUTEN_w : STD_LOGIC;
	SIGNAL BTIP_w, BTSSEL_w        :STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN
   en_w <= not BTHOLD_w;
   Q24_w <= BTCNT_r(23);
   Q28_w <= BTCNT_r(27);
   Q32_w <= BTCNT_r(31);
   
   BTCTL_wr_EN <= CS_BTCTL_i and MemWrite_ctrl_i;
   BTCTL_rd_EN <= CS_BTCTL_i and MemRead_ctrl_i;
   BTCNT_wr_EN <= CS_BTCNT_i and MemWrite_ctrl_i;
   BTCNT_rd_EN <= CS_BTCNT_i and MemRead_ctrl_i;
   BTCCR0_wr_EN <= CS_BTCCR0_i and MemWrite_ctrl_i;
   BTCCR0_rd_EN <= CS_BTCCR0_i and MemRead_ctrl_i;
   BTCCR1_wr_EN <= CS_BTCCR1_i and MemWrite_ctrl_i;
   BTCCR1_rd_EN <= CS_BTCCR1_i and MemRead_ctrl_i;

----------------------- LW ---------------------------------------

BTCTL_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(X"000000" & BTCTL_r, BTCTL_rd_EN,
                               BTCTL_i, DataBus);
BTCNT_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(BTCNT_r, BTCNT_rd_EN,
                               BTCNT_i, DataBus);							   
BTCCR0_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(BTCCR0_i, BTCCR0_rd_EN,
                               BTCCR0_w, DataBus);
BTCCR1_to_Bus : BidirPin generic map(DATA_BUS_WIDTH)
                      port map(BTCCR1_i, BTCCR1_rd_EN,
                               BTCCR1_w, DataBus);							   

------------------ SW -----------------
process(rst_i, MCLK_i)
BEGIN
       if (rst_i = '1') then
	       BTCTL_r <= X"00";
	   elsif(falling_edge(MCLK_i)) then
	        if(BTCTL_wr_EN = '1') then 
	          BTCTL_r <= BTCTL_i(7 DOWNTO 0);
		    end if;
	   end if;
end process;

process(rst_i, MCLK_i)
BEGIN
       if (rst_i = '1') then
	       BTCCR0_i <= X"00000000";
	   elsif(falling_edge(MCLK_i)) then
	        if(BTCCR0_wr_EN = '1') then 
	          BTCCR0_i <= BTCCR0_w;
		    end if;
	   end if;
end process;
process(rst_i, MCLK_i)
BEGIN
       if (rst_i = '1') then
	       BTCCR1_i <= X"00000000";
	   elsif(falling_edge(MCLK_i)) then
	        if(BTCCR1_wr_EN = '1') then 
	          BTCCR1_i <= BTCCR1_w;
		    end if;
	   end if;
end process;

   
   BTIP_w    <= BTCTL_r(1 DOWNTO 0);
   BTCLR_w   <= BTCTL_r(2);
   BTSSEL_w  <= BTCTL_r(4 DOWNTO 3);
   BTHOLD_w  <= BTCTL_r(5);	
   BTOUTEN_w <= BTCTL_r(6); 
   BTOUTMD_w <= BTCTL_r(7);   
   
------ TIMER process ----------------------------------
  process(BTCNT_clk_w, BTCLR_w, HEU0_w, BTCNT_wr_EN)
  begin
    if BTCLR_w = '1' then
      BTCNT_r <= (others => '0');
    elsif rising_edge(BTCNT_clk_w) then
	  if BTCNT_wr_EN = '1' then
	    BTCNT_r <= BTCNT_i;
      elsif (en_w = '1' and BTCNT_wr_EN = '0') then
		if (HEU0_w = '1') then
			BTCNT_r <= (others=>'0');
		else
			BTCNT_r <= BTCNT_r + 1;
		end if;
      end if;
    end if;
  end process;
-------------------------------------------------------
 --- Input registers -- 
	process(BTCNT_r, BTCCR0_i)
    begin
         if (BTCNT_r = x"00000000") then
         BTCL0_r <= BTCCR0_i;
         end if;
    end process;

	process(BTCNT_r, BTCCR1_i)
    begin
         if (BTCNT_r = x"00000000") then
         BTCL1_r <= BTCCR1_i;
         end if;
    end process;	

-------------------------------------------------------

------ PWM UNIT --------------------------------------
  process(BTCNT_clk_w, BTCLR_w, BTOUTMD_w)
  begin
    if BTCLR_w = '1' then                  -- RESET ALL
		if BTOUTMD_w = '0' then 
		pwm_w <= '0';
		else 
		pwm_w <= '1';
		end if;
    elsif rising_edge(BTCNT_clk_w) then
      if BTOUTEN_w = '1' then
        case BTOUTMD_w is
          when '0' =>  -- Mode 0: Set at BTCL1, Reset at BTCL0
            if BTCNT_r = BTCL1_r then
              pwm_w  <= '1';
            elsif BTCNT_r = BTCL0_r then
              pwm_w  <= '0';
            end if;
          when '1' =>  -- Mode 1: Reset at BTCL1, Set at BTCL0
            if BTCNT_r = BTCL1_r then
              pwm_w  <= '0';
            elsif BTCNT_r = BTCL0_r then
              pwm_w  <= '1';
            end if;
		  when others =>             -- 
              pwm_w <= '0';
        end case;
      end if;
    end if;
  end process;

PWM_o <= pwm_w;

---------------------------------------------------------
	process(BTCNT_r, BTCL0_r)
    begin
         if (BTCNT_r = BTCL0_r and BTCNT_r /= X"00000000") then
           HEU0_w <= '1';
		 else
		   HEU0_w <= '0';
         end if;
    end process;  
------ Mux for clk ------------------------------------
    with BTSSEL_w select
	     BTCNT_clk_w <=    MCLK_i  when "00",
		                   MCLK2_i when "01",
						   MCLK4_i when "10",
						   MCLK8_i when others;
-------------------------------------------------------
------ Mux for IFG ------------------------------------
    with BTIP_w select
	     BTIFG_o <=        HEU0_w  when "00",
		                   Q24_w   when "01",
						   Q28_w   when "10",
						   Q32_w   when others;
-------------------------------------------------------


end behavior;