# -----------------------------------------------
# Test.sdc — Timing constraints (DE10-Standard)
# -----------------------------------------------

# 1) Board clock @ 50 MHz on top-level port 'clk_i'
create_clock -name MCLK -period 20.000 [get_ports {clk_i}]

# 2) Let TimeQuest infer PLL/derived clocks and uncertainties
derive_pll_clocks
derive_clock_uncertainty

# 3) Asynchronous sources (false paths)
#    Reset is asynchronous to MCLK
set_false_path -from [get_ports {rst_i}]

#    Push-buttons (KEYs) are asynchronous; names per your top-level
#    (these lines match when the ports exist; otherwise remove/rename)
set_false_path -from [get_ports {KEY1_i}]
set_false_path -from [get_ports {KEY2_i}]
set_false_path -from [get_ports {KEY3_i}]

#    Slide switches as a vector (adjust name if different)
#    If your top-level has SW_i : in std_logic_vector(...):
set_false_path -from [get_ports {SW_i[*]}]

# 4) (Optional) If you truly have additional unrelated clocks,
#    declare them asynchronous to MCLK. Otherwise leave commented.
# set_clock_groups -asynchronous -group [get_clocks {MCLK}] -group [get_clocks {OTHER_CLK*}]

# -----------------------------------------------
# End of SDC
# -----------------------------------------------
