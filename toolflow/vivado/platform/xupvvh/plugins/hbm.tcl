if {[tapasco::is_feature_enabled "HBM"]} {
  proc create_custom_subsystem_hbm {{args {}}} {
    set interfaces  {}
    set hbm [tapasco::get_feature "HBM"]

    dict with hbm {
      set hbmInterfaces [lindex $interfaces 0]

      hbm::validate_pe_configuration $hbmInterfaces
      set numInterfaces [llength $hbmInterfaces]
      puts $numInterfaces
      puts [lindex $hbmInterfaces 0]
      set bothStacks [expr ($numInterfaces > 16)]
      puts "Refclks"
      hbm::create_refclk_ports $bothStacks
      puts "core"
      hbm::generate_hbm_core $hbmInterfaces
    }

  }
}


namespace eval hbm {

  proc even x {expr {($x % 2) == 0}}

  proc get_hbm_interfaces {} {
    set interfaces  {}
    set hbm [tapasco::get_feature "HBM"]

    dict with hbm {
      set hbmInterfaces [lindex $interfaces 0]
    }
    return $hbmInterfaces
  }

  proc validate_pe_configuration {hbmInterfaces} {
    set numInterfaces [llength $hbmInterfaces]

    if { $numInterfaces > 32 } {
      puts "Currently only 32 IPs with HBM connection supported."
      puts "Got $hbmInterfaces"
      exit
    }

    if { $numInterfaces == 0 } {
      puts "No IP with HBM connections found."
      puts "Disable Feature HBM if not used."
      exit
    }
  }

  proc create_refclk_ports {bothStacks} {
      set hbm_ref_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 hbm_ref_clk_0 ]
      set_property CONFIG.FREQ_HZ 100000000 $hbm_ref_clk_0

      if {$bothStacks} {
        set hbm_ref_clk_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 hbm_ref_clk_1 ]
        set_property CONFIG.FREQ_HZ 100000000 $hbm_ref_clk_1
      }
  }

  proc create_hbm_properties {numInterfaces} {
    puts "properties"
    set hbm_properties [list \
      CONFIG.USER_APB_EN {false} \
      CONFIG.USER_SWITCH_ENABLE_00 {false} \
      CONFIG.USER_SWITCH_ENABLE_01 {false} \
      CONFIG.USER_AXI_INPUT_CLK_FREQ {450} \
      CONFIG.USER_AXI_INPUT_CLK_NS {2.222} \
      CONFIG.USER_AXI_INPUT_CLK_PS {2222} \
      CONFIG.USER_AXI_INPUT_CLK_XDC {2.222} \
      CONFIG.HBM_MMCM_FBOUT_MULT0 {51} \
      CONFIG.USER_XSDB_INTF_EN {FALSE}
    ]

    if {$numInterfaces <= 16} {
      set maxSlaves 16
      lappend hbm_properties \
        CONFIG.USER_HBM_DENSITY {4GB} \
        CONFIG.USER_HBM_STACK {1} \
    } else {
      set maxSlaves 32
      lappend hbm_properties \
        CONFIG.USER_HBM_DENSITY {8GB} \
    }

    for {set i $numInterfaces} {$i < $maxSlaves} {incr i} {
      if ([even $i]) {
        set mc [format %02s [expr {$i / 2}]]
        lappend hbm_properties CONFIG.USER_MC_ENABLE_${mc} {false}
        lappend hbm_properties CONFIG.USER_MC${mc}_ECC_BYPASS {true}
      }
      set saxi [format %02s $i]
      lappend hbm_properties CONFIG.USER_SAXI_${saxi} {false}
    }
    puts "properties"
    return $hbm_properties
  }

  proc create_clocking {name port} {
    puts "clocking"
    set group [create_bd_cell -type hier $name]
    set instance [current_bd_instance .]
    current_bd_instance $group

    set hbm_ref_clk [create_bd_pin -type "clk" -dir "O" "hbm_ref_clk"]
    set axi_clk_0 [create_bd_pin -type "clk" -dir "O" "axi_clk_0"]
    set axi_clk_1 [create_bd_pin -type "clk" -dir "O" "axi_clk_1"]
    set axi_clk_2 [create_bd_pin -type "clk" -dir "O" "axi_clk_2"]
    set axi_clk_3 [create_bd_pin -type "clk" -dir "O" "axi_clk_3"]
    set axi_clk_4 [create_bd_pin -type "clk" -dir "O" "axi_clk_4"]
    set axi_clk_5 [create_bd_pin -type "clk" -dir "O" "axi_clk_5"]
    set axi_clk_6 [create_bd_pin -type "clk" -dir "O" "axi_clk_6"]
    set axi_reset [create_bd_pin -type "rst" -dir "O" "axi_reset"]
    set mem_peripheral_aresetn [create_bd_pin -type "rst" -dir "I" "mem_peripheral_aresetn"]

    set ibuf [tapasco::ip::create_util_buf ibuf]
    set_property -dict [ list CONFIG.C_BUF_TYPE {IBUFDS}  ] $ibuf

    connect_bd_intf_net $port [get_bd_intf_pins $ibuf/CLK_IN_D]

    set clk_wiz [tapasco::ip::create_clk_wiz clk_wiz]
    set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT6_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT7_REQUESTED_OUT_FREQ {450} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT4_USED {true} CONFIG.CLKOUT5_USED {true} CONFIG.CLKOUT6_USED {true} CONFIG.CLKOUT7_USED {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.NUM_OUT_CLKS {7} CONFIG.RESET_PORT {resetn}] $clk_wiz

    connect_bd_net [get_bd_pins $ibuf/IBUF_OUT] [get_bd_pins $clk_wiz/clk_in1] $hbm_ref_clk

    connect_bd_net $mem_peripheral_aresetn [get_bd_pins $clk_wiz/resetn]

    set reset_generator [tapasco::ip::create_logic_vector reset_generator]
    set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {and} CONFIG.LOGO_FILE {data/sym_andgate.png}] $reset_generator

    connect_bd_net $mem_peripheral_aresetn [get_bd_pins $reset_generator/Op1]
    connect_bd_net [get_bd_pins $clk_wiz/locked] [get_bd_pins $reset_generator/Op2]

    for {set i 0} {$i < 7} {incr i} {
      set incr [expr $i + 1]
      connect_bd_net [get_bd_pins axi_clk_${i}] [get_bd_pins $clk_wiz/clk_out${incr}]
    }

    connect_bd_net $axi_reset [get_bd_pins $reset_generator/Res]

    current_bd_instance $instance
    connect_bd_net [get_bd_pins mem_peripheral_aresetn] $mem_peripheral_aresetn
    puts "clocking"
    return $group
  }

  proc connect_clocking {clocking hbm startInterface numInterfaces} {
    puts "connect"
    for {set i 0} {$i < $numInterfaces} {incr i} {
        set hbm_index [format %02s [expr $i + $startInterface]]
        set block_index [expr $i < 16 ? 0 : 1]
        set clk_index [expr ($i % 16) / 2]
        set clk_index [expr $clk_index < 7 ? $clk_index : 6]
        connect_bd_net [get_bd_pins $clocking/axi_reset] [get_bd_pins $hbm/AXI_${hbm_index}_ARESET_N]
        connect_bd_net [get_bd_pins $clocking/axi_clk_${clk_index}] [get_bd_pins $hbm/AXI_${hbm_index}_ACLK]
      }
      puts "connect"
  }

  proc generate_hbm_core {hbmInterfaces} {
    if {[tapasco::is_feature_enabled "HBM"]} {
      puts "Generating HBM Core"
      set numInterfaces [llength $hbmInterfaces]
      set bothStacks [expr ($numInterfaces > 16)]

      set hbm_properties [create_hbm_properties $numInterfaces]

      set hbm [ create_bd_cell -type ip -vlnv xilinx.com:ip:hbm:1.0 "hbm_0" ]
      set_property -dict $hbm_properties $hbm

      set clocking_0 [create_clocking "clocking_0" [get_bd_intf_ports /hbm_ref_clk_0]]
      connect_clocking $clocking_0 $hbm 0 [expr min($numInterfaces,16)]
      connect_bd_net [get_bd_pins $clocking_0/hbm_ref_clk] [get_bd_pins $hbm/HBM_REF_CLK_0]
      set bufg [tapasco::ip::create_util_buf bufg_apb_pclk]
      set_property -dict [ list CONFIG.C_BUF_TYPE {BUFG}  ] $bufg
      connect_bd_net [get_bd_pins $clocking_0/hbm_ref_clk] [get_bd_pins $bufg/BUFG_I]
      connect_bd_net [get_bd_pins $bufg/BUFG_O] [get_bd_pins $hbm/APB_0_PCLK]
      connect_bd_net [get_bd_pins /host/axi_pcie3_0/user_lnk_up] [get_bd_pins $hbm/APB_0_PRESET_N]

      if {$bothStacks} {
        set clocking_1 [create_clocking "clocking_1" [get_bd_intf_ports /hbm_ref_clk_1]]
        connect_clocking $clocking_1 $hbm 16 [expr $numInterfaces - 16]
      }

      # disconnect mem_interconnect
      delete_bd_objs [get_bd_cells /arch/out_*]
      delete_bd_objs [get_bd_intf_pins /arch/M_MEM_*]

      for {set i 0} {$i < $numInterfaces} {incr i} {
        variable master [lindex $hbmInterfaces $i]
        set converter [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_${i}]
        set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_CLKS {2} CONFIG.HAS_ARESETN {0}] $converter
        set regslice [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 regslice_${i}]
        set_property -dict [list CONFIG.REG_AW {15} CONFIG.REG_AR {15} CONFIG.REG_W {15} CONFIG.REG_R {15} CONFIG.REG_B {15} CONFIG.USE_AUTOPIPELINING {1}] $regslice

        #disconnect_bd_intf_net [get_bd_intf_nets -of_objects $master] $master
        #set num_mi_old [get_property CONFIG.NUM_MI [get_bd_cells /host/out_ic]]
        #set num_mi [expr "$num_mi_old - 1"]
        #set_property -dict [list CONFIG.NUM_MI $num_mi] [get_bd_cells /host/out_ic]

        set pin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 /arch/M_AXI_HBM_${i}]
        connect_bd_intf_net $pin $master
        connect_bd_intf_net [get_bd_intf_pins $converter/S00_AXI] $pin
        set hbm_index [format %02s $i]
        connect_bd_intf_net [get_bd_intf_pins $converter/M00_AXI] [get_bd_intf_pins $regslice/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins $regslice/M_AXI] [get_bd_intf_pins $hbm/SAXI_${hbm_index}]
        connect_bd_net [get_bd_pins design_clk] [get_bd_pins $converter/aclk]
        connect_bd_net [get_bd_pins $hbm/AXI_${hbm_index}_ACLK] [get_bd_pins $converter/aclk1] [get_bd_pins $regslice/aclk]
        connect_bd_net [get_bd_pins $hbm/AXI_${hbm_index}_ARESET_N] [get_bd_pins $regslice/aresetn]

        assign_bd_address [get_bd_addr_segs $hbm/SAXI_${hbm_index}/HBM_MEM${hbm_index}]
      }
      save_bd_design
      # recreate mem_interconnect
      current_bd_instance /arch
      set mgroups [platform::max_masters]
      set masters [ldiff [lsort -dictionary [tapasco::get_aximm_interfaces [get_bd_cells /arch/target_ip_*]]] $hbmInterfaces]
      set arch_mem_ics [arch::arch_create_mem_interconnects $mgroups [llength $masters]]
      arch::arch_connect_mem $arch_mem_ics $masters
      catch {arch::arch_connect_clocks} issue
      catch {arch::arch_connect_resets} issue
      current_bd_instance /hbm

      set constraints_fn "$::env(TAPASCO_HOME_TCL)/platform/xupvvh/plugins/hbm.xdc"
      read_xdc $constraints_fn
      set_property PROCESSING_ORDER LATE [get_files $constraints_fn]


    }
  }

  proc addressmap {{args {}}} {
    if {[tapasco::is_feature_enabled "HBM"]} {
      set interfaces  {}
      set hbm [tapasco::get_feature "HBM"]

      dict with hbm {
        set hbmInterfaces [lindex $interfaces 0]
        for {set i 0} {$i < [llength $hbmInterfaces]} {incr i} {
          set args [lappend args M_AXI_HBM_${i} [list 0 0 -1 ""]]
        }
      }
    }
    save_bd_design
    return $args
  }

  proc ldiff {a b} {
    lmap elem $a {
        expr {[lsearch -exact $b $elem] > -1 ? [continue] : $elem}
    }
  }

  proc lmap {varname listval body} {
    upvar 1 $varname var
    set temp [list]
    foreach var $listval {
        lappend temp [uplevel 1 $body]
    }
    set temp
  }


}

tapasco::register_plugin "platform::hbm::addressmap" "post-address-map"