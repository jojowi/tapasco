set_property PACKAGE_PIN BH27 [get_ports hbm_ref_clk_0_clk_p]
set_property PACKAGE_PIN BJ27 [get_ports hbm_ref_clk_0_clk_n]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports hbm_ref_clk_0_clk_p]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports hbm_ref_clk_0_clk_n]
set_property ODT RTT_48 [get_ports hbm_ref_clk_0_clk_p]

set_property PACKAGE_PIN BH26 [get_ports hbm_ref_clk_1_clk_p]
set_property PACKAGE_PIN BH25 [get_ports hbm_ref_clk_1_clk_n]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports hbm_ref_clk_1_clk_p]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports hbm_ref_clk_1_clk_n]
set_property ODT RTT_48 [get_ports hbm_ref_clk_1_clk_p]

create_clock -period 10 -name hbm_ref_clk_0_clk_p [get_ports hbm_ref_clk_0_clk_p]
create_clock -period 10 -name hbm_ref_clk_1_clk_p [get_ports hbm_ref_clk_1_clk_p]
set_clock_groups -asynchronous -group [get_clocks hbm_ref_clk_0_clk_p -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks hbm_ref_clk_1_clk_p -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out3_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out4_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out5_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out6_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out7_system_clk_wiz_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out1_system_clk_wiz_1 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out2_system_clk_wiz_1 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out3_system_clk_wiz_1 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out4_system_clk_wiz_1 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out5_system_clk_wiz_1 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out6_system_clk_wiz_1 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out7_system_clk_wiz_1 -include_generated_clocks]

set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets */APB_0_PCLK]



#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out1]
#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out2]
#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out3]
#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out4]
#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out5]
#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out6]
#get_property CLOCK_DEDICATED_ROUTE [get_nets system_i/hbm/clocking_0/clk_wiz/inst/clk_out7]




# may cause problems when using ILAs
#create_pblock pblock_pcie4c_ip_i_1
#resize_pblock pblock_pcie4c_ip_i_1 -add CLOCKREGION_X4Y0:CLOCKREGION_X7Y3
#add_cells_to_pblock pblock_pcie4c_ip_i_1 [get_cells system_i/host/axi_pcie3_0/inst/pcie4c_ip_i]
#set_property USER_SLR_ASSIGNMENT in_ic_group [get_cells system_i/host/in_ic]

#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets system_i/hbm/clocking_0/ibuf/U0/IBUF_OUT[0]]