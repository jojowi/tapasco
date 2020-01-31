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

create_pblock pblock_hbm_ic_0_3
resize_pblock pblock_hbm_ic_0_3 -add CLOCKREGION_X0Y0:CLOCKREGION_X0Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_0_3]
add_cells_to_pblock pblock_hbm_ic_0_3 [get_cells [list system_i/hbm/smartconnect_0 system_i/hbm/smartconnect_1 system_i/hbm/smartconnect_2 system_i/hbm/smartconnect_3]]

create_pblock pblock_hbm_ic_4_7
resize_pblock pblock_hbm_ic_4_7 -add CLOCKREGION_X1Y0:CLOCKREGION_X1Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_4_7]
add_cells_to_pblock pblock_hbm_ic_4_7 [get_cells [list system_i/hbm/smartconnect_4 system_i/hbm/smartconnect_5 system_i/hbm/smartconnect_6 system_i/hbm/smartconnect_7]]

create_pblock pblock_hbm_ic_8_11
resize_pblock pblock_hbm_ic_8_11 -add CLOCKREGION_X2Y0:CLOCKREGION_X2Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_8_11]
add_cells_to_pblock pblock_hbm_ic_8_11 [get_cells [list system_i/hbm/smartconnect_8 system_i/hbm/smartconnect_9 system_i/hbm/smartconnect_10 system_i/hbm/smartconnect_11]]

create_pblock pblock_hbm_ic_12_15
resize_pblock pblock_hbm_ic_12_15 -add CLOCKREGION_X3Y0:CLOCKREGION_X3Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_12_15]
add_cells_to_pblock pblock_hbm_ic_12_15 [get_cells [list system_i/hbm/smartconnect_12 system_i/hbm/smartconnect_13 system_i/hbm/smartconnect_14 system_i/hbm/smartconnect_15]]

create_pblock pblock_hbm_ip_0_3
resize_pblock pblock_hbm_ip_0_3 -add CLOCKREGION_X0Y8:CLOCKREGION_X0Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ip_0_3]
add_cells_to_pblock pblock_hbm_ip_0_3 [get_cells [list system_i/arch/target_ip_00_000 system_i/arch/target_ip_00_001 system_i/arch/target_ip_00_002 system_i/arch/target_ip_00_003]]

create_pblock pblock_hbm_ip_4_7
resize_pblock pblock_hbm_ip_4_7 -add CLOCKREGION_X1Y8:CLOCKREGION_X1Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ip_4_7]
add_cells_to_pblock pblock_hbm_ip_4_7 [get_cells [list system_i/arch/target_ip_00_004 system_i/arch/target_ip_00_005 system_i/arch/target_ip_00_006 system_i/arch/target_ip_00_007]]

create_pblock pblock_hbm_ip_8_11
resize_pblock pblock_hbm_ip_8_11 -add CLOCKREGION_X2Y8:CLOCKREGION_X2Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ip_8_11]
add_cells_to_pblock pblock_hbm_ip_8_11 [get_cells [list system_i/arch/target_ip_00_008 system_i/arch/target_ip_00_009 system_i/arch/target_ip_00_010 system_i/arch/target_ip_00_011]]

create_pblock pblock_hbm_ip_12_15
resize_pblock pblock_hbm_ip_12_15 -add CLOCKREGION_X3Y8:CLOCKREGION_X3Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ip_12_15]
add_cells_to_pblock pblock_hbm_ip_12_15 [get_cells [list system_i/arch/target_ip_00_012 system_i/arch/target_ip_00_013 system_i/arch/target_ip_00_014 system_i/arch/target_ip_00_015]]

create_pblock pblock_hbm_ic_16_19
resize_pblock pblock_hbm_ic_16_19 -add CLOCKREGION_X4Y0:CLOCKREGION_X4Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_16_19]
add_cells_to_pblock pblock_hbm_ic_16_19 [get_cells [list system_i/hbm/smartconnect_16 system_i/hbm/smartconnect_17 system_i/hbm/smartconnect_18 system_i/hbm/smartconnect_19]]

create_pblock pblock_hbm_ic_20_23
resize_pblock pblock_hbm_ic_20_23 -add CLOCKREGION_X5Y0:CLOCKREGION_X5Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_20_23]
add_cells_to_pblock pblock_hbm_ic_20_23 [get_cells [list system_i/hbm/smartconnect_20 system_i/hbm/smartconnect_21 system_i/hbm/smartconnect_22 system_i/hbm/smartconnect_23]]

create_pblock pblock_hbm_ic_24_27
resize_pblock pblock_hbm_ic_24_27 -add CLOCKREGION_X6Y0:CLOCKREGION_X6Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_24_27]
add_cells_to_pblock pblock_hbm_ic_24_27 [get_cells [list system_i/hbm/smartconnect_24 system_i/hbm/smartconnect_25 system_i/hbm/smartconnect_26 system_i/hbm/smartconnect_27]]

create_pblock pblock_hbm_ic_28_31
resize_pblock pblock_hbm_ic_28_31 -add CLOCKREGION_X7Y0:CLOCKREGION_X7Y11
set_property IS_SOFT TRUE [get_pblocks pblock_hbm_ic_28_31]
add_cells_to_pblock pblock_hbm_ic_28_31 [get_cells [list system_i/hbm/smartconnect_28 system_i/hbm/smartconnect_29 system_i/hbm/smartconnect_30 system_i/hbm/smartconnect_31]]

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

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets system_i/hbm/clocking_0/ibuf/U0/IBUF_OUT[0]]