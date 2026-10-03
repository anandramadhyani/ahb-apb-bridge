# sdc/bridge_top.sdc
create_clock -name hclk -period 6.67 [get_ports hclk]

set clk_idx [lsearch [all_inputs] [get_ports hclk]]
set inputs_no_clk [lreplace [all_inputs] $clk_idx $clk_idx]

set_input_delay  0.3 -clock hclk $inputs_no_clk
set_output_delay 0.3 -clock hclk [all_outputs]

set_clock_uncertainty 0.1 [get_clocks hclk]