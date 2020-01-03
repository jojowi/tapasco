if {[tapasco::is_feature_enabled "SFPPLUS"]} {
proc create_custom_subsystem_network {{args {}}} {

  variable data [tapasco::get_feature "SFPPLUS"]
  variable ports [sfpplus::get_portlist $data]

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_NETWORK
  sfpplus::makeMaster "M_NETWORK"
  puts "Creating Network Interfaces for Ports: $ports"
  sfpplus::generate_cores $ports

  current_bd_instance /arch
  create_bd_pin -type clk -dir I sfp_tx_clock
  create_bd_pin -type clk -dir I sfp_rx_clock
  create_bd_pin -type rst -dir I sfp_tx_reset
  create_bd_pin -type rst -dir I sfp_tx_resetn
  create_bd_pin -type rst -dir I sfp_rx_reset
  create_bd_pin -type rst -dir I sfp_rx_resetn

  variable value [dict values [dict remove $data enabled]]
  foreach port $value {
    sfpplus::generate_port $port
  }
  puts "Network Connection done"
  current_bd_instance /network
}
}

namespace eval sfpplus {
  variable available_ports 16
  if {[tapasco::get_board_preset] == "ZC706"} {
    variable available_ports 1
    variable rx_ports       {"Y6"}
    variable tx_ports       {"W4"}
    variable disable_pins   {"AA18"}
    variable refclk_pins    {"AC8"}
    variable disable_pins_voltages {"LVCMOS25"}
  }
  if {[tapasco::get_board_preset] == "VC709"} {
    variable available_ports 4
    variable rx_ports              {"AN6" "AM8" "AL6" "AJ6"}
    variable tx_ports              {"AP4" "AN2" "AM4" "AL2"}
    variable disable_pins          {"AB41" "Y42" "AC38" "AC40"}
    variable fault_pins            {"Y38" "AA39" "AA41" "AE38"}
    variable disable_pins_voltages {"LVCMOS18" "LVCMOS18" "LVCMOS18" "LVCMOS18"}
    variable refclk_pins           {"AH8"}
    variable iic_scl               {"AT35" "TRUE" "16" "SLOW" "LVCMOS18"}
    variable iic_sda               {"AU32" "TRUE" "16" "SLOW" "LVCMOS18"}
    variable iic_rst               {"AY42" "16" "SLOW" "LVCMOS18"}
    variable si5324_rst            {"AT36" "16" "SLOW" "LVCMOS18"}
  }

proc find_ID {input} {
    variable composition
    for {variable o 0} {$o < [llength $composition] -1} {incr o} {
      if {[regexp ".*:$input:.*" [dict get $composition $o vlnv]]} {
        return $o
      }
    }
    return -1
  }

proc countKernels {kernels} {
    variable counter 0

    foreach kernel $kernels {
      variable counter [expr {$counter + [dict get $kernel Count]}]
    }
    return $counter
  }

proc get_portlist {input} {
    variable counter [list]
    variable value [dict values [dict remove $input enabled]]
    foreach kernel $value {
      variable counter [lappend counter [dict get $kernel PORT]]
    }
    return $counter
  }

proc makeInverter {name} {
    variable ret [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 $name]
    set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells $name]
    return $ret
  }

# Start: Validating Configuration
proc validate_sfp_ports {{args {}}} {
    if {[tapasco::is_feature_enabled "SFPPLUS"]} {
      variable available_ports
      variable composition [tapasco::get_composition]
      set f [tapasco::get_feature "SFPPLUS"]
      variable ky [dict keys $f]
      variable used_ports [list]

      puts "Checking SFP-Network for palausability:"
      # Check if Board supports enough SFP-Ports
      if { [llength $ky]-1 > $available_ports} {
        puts "To many SFP-Ports specified (Max: $available_ports)"
        exit
      }

      #Check if Port Config is valid
      for {variable i 0} {$i < [llength $ky]-1} {incr i} {
        variable port [dict get $f [lindex $ky $i]]
        lappend used_ports [dict get $port PORT]
        variable mode [dict get $port mode]
        puts "Port: [dict get $port PORT]"
        puts "  Mode: $mode"
        dict set [lindex [dict get $port kernel] 0] vlnv " "
        switch $mode {
          singular   { validate_singular $port }
          broadcast  { validate_broadcast $port }
          roundrobin { validate_roundrobin $port }
          default {
            puts "Mode $mode not supported"
            exit
          }
        }
        variable unique_ports [lsort -unique $used_ports]
        if { [llength $used_ports] > [llength $unique_ports]} {
          puts "Port-specification not Unique (Ports Specified: [lsort $used_ports])"
          exit
        }
      }
      puts "SFP-Config OK"

    }
    return {}
}

  # validate Port for singular mode
proc validate_singular {config} {
    variable kern [dict get $config kernel]
    variable composition
    if {[llength $kern] == 1} {
      puts "  Kernel:"
      variable x [lindex $kern 0]
      dict set $x "vlnv" " "
      dict with  x {
        puts "    ID: $ID"
        puts "    Count: $Count"
        puts "    Recieve:  $interface_rx"
        puts "    Transmit: $interface_tx"
        variable kernelID [find_ID $ID]
        if { $kernelID != -1 } {
          variable newCount [expr {[dict get $composition $kernelID count] - $Count}]
          set vlnv [dict get $composition $kernelID vlnv]
          if { $newCount < 0} {
            puts "Not Enough Instances of Kernel $ID"
            exit
          }
          [dict set composition $kernelID count $newCount]
        } else {
          puts "Kernel not found"
          exit
        }
      }
    } else {
      puts "Only one Kernel allowed in Singular mode"
      exit
    }
}

  # validate Port for broadcast mode
proc validate_broadcast {config} {
    variable composition
    variable kern [dict get $config kernel]
    for {variable c 0} {$c < [llength $kern]} {incr c} {
      puts "  Kernel_$c:"
      variable x [lindex $kern $c]
      dict set $x "vlnv" " "
      dict with  x {
        puts "    ID: $ID"
        puts "    Count: $Count"
        puts "    Recieve:  $interface_rx"
        puts "    Transmit: $interface_tx"
        variable kernelID [find_ID $ID]
        if { $kernelID != -1 } {
          variable newCount [expr {[dict get $composition $kernelID count] - $Count}]
          set vlnv [dict get $composition $kernelID vlnv]
          if { $newCount < 0} {
            puts "Not Enough Instances of Kernel $ID"
            exit
          }
          [dict set composition $kernelID count $newCount]
        } else {
          puts "Kernel not found"
          exit
        }
      }
    }
  }

# validate Port for roundrobin mode
proc validate_roundrobin {config} {
    variable composition
    variable kern [dict get $config kernel]
    for {variable c 0} {$c < [llength $kern]} {incr c} {
      puts "  Kernel_$c:"
      variable x [lindex $kern $c]
      dict set $x "vlnv" " "
      dict with  x {
        puts "    ID: $ID"
        puts "    Count: $Count"
        puts "    Recieve:  $interface_rx"
        puts "    Transmit: $interface_tx"
        variable kernelID [find_ID $ID]
        if { $kernelID != -1 } {
          variable newCount [expr {[dict get $composition $kernelID count] - $Count}]
          set vlnv [dict get $composition $kernelID vlnv]
          puts "VLNV: $vlnv"
          if { $newCount < 0} {
            puts "Not Enough Instances of Kernel $ID"
          [dict set composition $kernelID count $newCount]
          exit
        }
        } else {
          puts "Kernel not found"
          exit
        }
      }
    }
  }
# END: Validating Configuration

# Generate Network Setup
proc generate_cores {ports} {

  set sfp_tx_clock [create_bd_pin -type clk -dir O sfp_tx_clock]
  set sfp_tx_clock [create_bd_pin -type rst -dir O sfp_tx_resetn]
  set sfp_tx_clock [create_bd_pin -type rst -dir O sfp_tx_reset]
  set sfp_tx_clock [create_bd_pin -type clk -dir O sfp_rx_clock]
  set sfp_tx_clock [create_bd_pin -type rst -dir O sfp_rx_resetn]
  set sfp_tx_clock [create_bd_pin -type rst -dir O sfp_rx_reset]

  #Setup CLK-Ports for Ethernet-Subsystem
  set gt_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk_0 ]
  set_property CONFIG.FREQ_HZ 156250000 $gt_refclk

  # AXI Interconnect for Configuration
  set AXI_Config [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 AXI_Config]
  set_property CONFIG.NUM_SI 1 $AXI_Config
  set_property CONFIG.NUM_MI [llength $ports] $AXI_Config

  set dclk_wiz [tapasco::ip::create_clk_wiz dclk_wiz]
  set_property -dict [list CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 100 CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false}] $dclk_wiz

  set dclk_reset [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 dclk_reset]

  connect_bd_net [get_bd_pins $dclk_wiz/clk_out1] [get_bd_pins $dclk_reset/slowest_sync_clk]
  connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins $dclk_reset/ext_reset_in]
  connect_bd_net [get_bd_pins design_clk] [get_bd_pins $dclk_wiz/clk_in1]
  connect_bd_net [get_bd_pins $AXI_Config/M*_ACLK] [get_bd_pins $dclk_wiz/clk_out1]
  connect_bd_net [get_bd_pins $AXI_Config/M*_ARESETN] [get_bd_pins $dclk_reset/peripheral_aresetn]

  connect_bd_intf_net [get_bd_intf_pins $AXI_Config/S00_AXI] [get_bd_intf_pins S_NETWORK]
  connect_bd_net [get_bd_pins $AXI_Config/S00_ACLK] [get_bd_pins design_clk]
  connect_bd_net [get_bd_pins $AXI_Config/S00_ARESETN] [get_bd_pins design_interconnect_aresetn]
  connect_bd_net [get_bd_pins $AXI_Config/ACLK] [get_bd_pins design_clk]
  connect_bd_net [get_bd_pins $AXI_Config/ARESETN] [get_bd_pins design_interconnect_aresetn]

  set gty_txp [create_bd_port -dir O -from 15 -to 0 gty_txp_o]
  set gty_txn [create_bd_port -dir O -from 15 -to 0 gty_txn_o]
  set gty_rxp [create_bd_port -dir I -from 15 -to 0 gty_rxp_i]
  set gty_rxn [create_bd_port -dir I -from 15 -to 0 gty_rxn_i]

  set txp_concat [tapasco::ip::create_xlconcat txp_concat]
  set txn_concat [tapasco::ip::create_xlconcat txn_concat]
  connect_bd_net [get_bd_pins $txp_concat/dout] $gty_txp
  connect_bd_net [get_bd_pins $txn_concat/dout] $gty_txn

  for {set i 0} {$i < [llength $ports]} {incr i} {
    variable port [lindex $ports $i]

    # Local Pins (Network-Hierarchie)
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX_$port
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX_$port
    # Create Hierachie for the Port
    variable group [create_bd_cell -type hier "PORT_$port"]
    current_bd_instance $group
    # Local Pins (Port-Hierarchie)
    set design_clk [create_bd_pin -dir I design_clk
    set design_interconnect_aresetn [create_bd_pin -dir I design_interconnect_aresetn]
    set design_peripheral_aresetn [create_bd_pin -dir I design_peripheral_aresetn]
    set AXIS_RX [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX]
    set AXIS_TX [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX]
    set S_AXI_Config [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_Config]
    # Connect Port Hierachie to Network Hierarchie
    connect_bd_intf_net $S_AXI_Config [get_bd_intf_pins /Network/AXI_Config/M[format %02d $i]_AXI]
    
    connect_bd_net [get_bd_pins $dclk_wiz/clk_out1] [get_bd_pins design_clk]
    connect_bd_net [get_bd_pins /network/dclk_reset/interconnect_aresetn] $design_interconnect_aresetn
    connect_bd_net [get_bd_pins /network/dclk_reset/peripheral_aresetn] $design_peripheral_aresetn
    connect_bd_intf_net $AXIS_RX [get_bd_intf_pins /Network/AXIS_RX_$port]
    connect_bd_intf_net $AXIS_TX [get_bd_intf_pins /Network/AXIS_TX_$port]

    set rxp_slice [tapasco::ip::create_xlslice rxp_slice]
    set_property -dict [list CONFIG.DIN_WIDTH{16} CONFIG.DIN_FROM{$port} CONFIG.DIN_TO{$port}] $rxp_slice
    set rxn_slice [tapasco::ip::create_xlslice rxn_slice]
    set_property -dict [list CONFIG.DIN_WIDTH{16} CONFIG.DIN_FROM{$port} CONFIG.DIN_TO{$port}] $rxn_slice
    connect_bd_net $gty_rxp [get_bd_pins $rxp_slice/Din]
    connect_bd_net $gty_rxn [get_bd_pins $rxn_slice/Din]

    set ethernet [tapasco::ip::create_xxv_ethernet ethernet]
    set_property -dict [list CONFIG.LINE_RATE {10} CONFIG.BASE_R_KR {BASE-R} CONFIG.INCLUDE_AXI4_INTERFACE {1} CONFIG.INCLUDE_STATISTICS_COUNTERS {0} CONFIG.GT_REF_CLK_FREQ {156.25}] $ethernet


    connect_bd_intf_net $gt_refclk [get_bd_intf_pins $ethernet/gt_ref_clk]
    connect_bd_net [get_bd_pins $rxp_slice/Dout] [get_bd_pins $ethernet/gt_rxp_in_0]
    connect_bd_net [get_bd_pins $rxn_slice/Dout] [get_bd_pins $ethernet/gt_rxn_in_0]
    connect_bd_intf_net $S_AXI_Config [get_bd_intf_pins $ethernet/s_axi_0]
    connect_bd_intf_net $AXIS_TX [get_bd_intf_pins $ethernet/axis_tx_0]
    connect_bd_net [get_bd_pins $ethernet/tx_clk_out_0] [get_bd_pins $ethernet/rx_core_clk_0]
    connect_bd_net [get_bd_pins /Network/design_peripheral_areset] [get_bd_pins $ethernet/sys_reset]
    connect_bd_net $design_clk [get_bd_pins $ethernet/dclk]
    connect_bd_net $design_clk [get_bd_pins $ethernet/s_axi_aclk_0]
    connect_bd_net $design_peripheral_aresetn [get_bd_pins $ethernet/s_axi_aresetn_0]

    connect_bd_net [get_bd_pins $ethernet/gt_txn_out_0] [get_bd_pins $txn_concat/In${port}]
    connect_bd_net [get_bd_pins $ethernet/gt_txp_out_0] [get_bd_pins $txp_concat/In${port}]
    connect_bd_intf_net [get_bd_intf_pins $ethernet/axis_rx_0] $AXIS_RX
    connect_bd_net [get_bd_pins $ethernet/tx_clk_out] $sfp_tx_clock
    connect_bd_net [get_bd_pins $ethernet/rx_clk_out] $sfp_rx_clock
    connect_bd_net [get_bd_pins $ethernet/user_rx_reset] $sfp_rx_reset
    connect_bd_net [get_bd_pins $ethernet/user_tx_reset] $sfp_tx_reset

    current_bd_instance /Network
  }
}

# Build A Port Mode Setups
proc generate_port {input} {
  dict with input {
    variable kernelc [countKernels $kernel]
    puts "Creating Port $PORT"
    puts "  with mode -> $mode"
    puts "  with sync -> $sync"
    puts "  with $kernelc PEs"
    foreach k $kernel {
      puts "    [dict get $k Count] of type [dict get $k ID]"
    }

    create_bd_intf_pin -mode Slave  -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX_$PORT
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX_$PORT
    # Create Hierarchie-Cell
    create_bd_cell -type hier Port_$PORT
    variable ret [current_bd_instance .]
    current_bd_instance Port_$PORT
    # Create Ports for the Hierarchie
    create_bd_pin -dir I design_clk
    create_bd_pin -dir I design_interconnect_aresetn
    create_bd_pin -dir I design_peripheral_aresetn
    create_bd_pin -dir I design_peripheral_areset
    create_bd_pin -dir I sfp_tx_clock
    create_bd_pin -dir I sfp_tx_reset
    create_bd_pin -dir I sfp_tx_resetn
    create_bd_pin -dir I sfp_rx_clock
    create_bd_pin -dir I sfp_rx_reset
    create_bd_pin -dir I sfp_rx_resetn
    create_bd_intf_pin -mode Slave  -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX
    # Connect Hierarchie to the Upper Layer
    connect_bd_net [get_bd_pins sfp_tx_clock]  [get_bd_pins /arch/sfp_tx_clock]
    connect_bd_net [get_bd_pins sfp_tx_reset]  [get_bd_pins /arch/sfp_tx_reset]
    connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins /arch/sfp_tx_resetn]
    connect_bd_net [get_bd_pins sfp_rx_clock]  [get_bd_pins /arch/sfp_rx_clock]
    connect_bd_net [get_bd_pins sfp_rx_reset]  [get_bd_pins /arch/sfp_rx_reset]
    connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins /arch/sfp_rx_resetn]
    connect_bd_net [get_bd_pins design_clk] [get_bd_pins /arch/design_clk]
    connect_bd_net [get_bd_pins design_peripheral_aresetn]     [get_bd_pins /arch/design_peripheral_aresetn]
    connect_bd_net [get_bd_pins design_peripheral_areset]      [get_bd_pins /arch/design_peripheral_areset]
    connect_bd_net [get_bd_pins design_interconnect_aresetn]   [get_bd_pins /arch/design_interconnect_aresetn]
    connect_bd_intf_net [get_bd_intf_pins /arch/AXIS_TX_$PORT] [get_bd_intf_pins AXIS_TX]
    connect_bd_intf_net [get_bd_intf_pins /arch/AXIS_RX_$PORT] [get_bd_intf_pins AXIS_RX]
    # Create Port infrastructure depending on mode
    switch $mode {
      singular   {
        generate_singular [lindex $kernel 0] $PORT $sync
      }
      broadcast  {
        generate_broadcast $kernelc $sync
        connect_PEs $kernel $PORT $sync
      }
      roundrobin {
        generate_roundrobin $kernelc $sync
        connect_PEs $kernel $PORT $sync
      }
    }
    current_bd_instance $ret
  }
}

# Create A Broadcast-Config
proc generate_broadcast {kernelc sync} {
  # Create Reciever Interconnect
      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1  reciever
      set_property CONFIG.NUM_MI $kernelc [get_bd_cells reciever]
      set_property -dict [list CONFIG.M_TDATA_NUM_BYTES {8} CONFIG.S_TDATA_NUM_BYTES {8}] [get_bd_cells reciever]

      for {variable i 0} {$i < $kernelc} {incr i} {
          set_property CONFIG.M[format "%02d" $i]_TDATA_REMAP tdata[63:0]  [get_bd_cells reciever]
      }

  # If not Syncronized insert Interconnect to Sync the Clocks
      if {$sync} {
        connect_bd_intf_net [get_bd_intf_pins reciever/S_AXIS] [get_bd_intf_pins AXIS_RX]
        connect_bd_net [get_bd_pins sfp_rx_clock] [get_bd_pins reciever/aclk]
        connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever/aresetn]
      } else {
        connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever/aclk]
        connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins reciever/aresetn]

        create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 reciever_sync
        set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.S00_FIFO_DEPTH {2048} CONFIG.M00_FIFO_DEPTH {2048} CONFIG.S00_FIFO_MODE {0} CONFIG.M00_FIFO_MODE {0} ] [get_bd_cells reciever_sync]
        connect_bd_net [get_bd_pins sfp_rx_clock]  [get_bd_pins reciever_sync/ACLK]
        connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever_sync/ARESETN]
        connect_bd_net [get_bd_pins sfp_rx_clock]  [get_bd_pins reciever_sync/S*_ACLK]
        connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever_sync/S*_ARESETN]
        connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever_sync/M*_ACLK]
        connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins reciever_sync/M*_ARESETN]

        connect_bd_intf_net [get_bd_intf_pins reciever/S_AXIS] [get_bd_intf_pins reciever_sync/M*_AXIS]
        connect_bd_intf_net [get_bd_intf_pins reciever_sync/S00_AXIS] [get_bd_intf_pins AXIS_RX]
      }

  # Create Transmitter Interconnect
      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 transmitter
      set_property -dict [list CONFIG.NUM_MI {1} CONFIG.ARB_ON_TLAST {1}] [get_bd_cells transmitter]
      set_property -dict [list CONFIG.M00_FIFO_MODE {1} CONFIG.M00_FIFO_DEPTH {2048}] [get_bd_cells transmitter]
      set_property CONFIG.NUM_SI $kernelc [get_bd_cells transmitter]
      set_property -dict [list CONFIG.ARB_ALGORITHM {3} CONFIG.ARB_ON_MAX_XFERS {0}] [get_bd_cells transmitter]


      for {variable i 0} {$i < $kernelc} {incr i} {
          set_property CONFIG.[format "S%02d" $i]_FIFO_DEPTH 2048 [get_bd_cells transmitter]
          set_property CONFIG.[format "S%02d" $i]_FIFO_MODE 0 [get_bd_cells transmitter]
      }

      connect_bd_intf_net [get_bd_intf_pins transmitter/M*_AXIS] [get_bd_intf_pins AXIS_TX]
      connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter/M*_ACLK]
      connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter/M*_ARESETN]

      if {$sync} {
        connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter/ACLK]
        connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter/ARESETN]
        connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter/S*_ACLK]
        connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter/S*_ARESETN]
      } else {
        connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/ACLK]
        connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins transmitter/ARESETN]
        connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/S*_ACLK]
        connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins transmitter/S*_ARESETN]
      }
}

# Create A Roundrobin-Config
proc generate_roundrobin {kernelc sync} {
  # Create Reciever Interconnect
  create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 reciever
  set_property -dict [list CONFIG.NUM_SI {1} CONFIG.S00_FIFO_MODE {0} CONFIG.S00_FIFO_DEPTH {2048}] [get_bd_cells reciever]
  set_property CONFIG.NUM_MI $kernelc [get_bd_cells reciever]

  for {variable i 0} {$i < $kernelc} {incr i} {
      set_property CONFIG.[format "M%02d" $i]_FIFO_DEPTH 2048 [get_bd_cells reciever]
      set_property CONFIG.[format "M%02d" $i]_FIFO_MODE 0 [get_bd_cells reciever]
  }

  connect_bd_net [get_bd_pins sfp_rx_clock] [get_bd_pins reciever/ACLK]
  connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever/ARESETN]

  connect_bd_net [get_bd_pins sfp_rx_clock] [get_bd_pins reciever/S*_ACLK]
  connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever/S*_ARESETN]

  if {$sync} {
    connect_bd_net [get_bd_pins sfp_rx_clock] [get_bd_pins reciever/M*_ACLK]
    connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever/M*_ARESETN]
  } else {
    connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever/M*_ACLK]
    connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins reciever/M*_ARESETN]
  }

  tapasco::ip::create_axis_arbiter "arbiter"
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roundrobin_turnover
  set_property CONFIG.CONST_WIDTH 5 [get_bd_cells roundrobin_turnover]
  set_property CONFIG.CONST_VAL $kernelc [get_bd_cells roundrobin_turnover]

  connect_bd_net [get_bd_pins arbiter/maxClients] [get_bd_pins roundrobin_turnover/dout]
  connect_bd_net [get_bd_pins arbiter/CLK] [get_bd_pins sfp_rx_clock]
  connect_bd_net [get_bd_pins arbiter/RST_N] [get_bd_pins sfp_rx_resetn]
  connect_bd_intf_net [get_bd_intf_pins arbiter/axis_S] [get_bd_intf_pins AXIS_RX]
  connect_bd_intf_net [get_bd_intf_pins arbiter/axis_M] [get_bd_intf_pins reciever/S*_AXIS]

  # Create Transmitter Interconnect
  create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 transmitter
  set_property -dict [list CONFIG.NUM_MI {1} CONFIG.ARB_ON_TLAST {1}] [get_bd_cells transmitter]
  set_property -dict [list CONFIG.M00_FIFO_MODE {1} CONFIG.M00_FIFO_DEPTH {2048}] [get_bd_cells transmitter]
  set_property CONFIG.NUM_SI $kernelc [get_bd_cells transmitter]
  set_property -dict [list CONFIG.ARB_ALGORITHM {3} CONFIG.ARB_ON_MAX_XFERS {0}] [get_bd_cells transmitter]


  for {variable i 0} {$i < $kernelc} {incr i} {
    set_property CONFIG.[format "S%02d" $i]_FIFO_DEPTH 2048 [get_bd_cells transmitter]
    set_property CONFIG.[format "S%02d" $i]_FIFO_MODE 0 [get_bd_cells transmitter]
  }

  connect_bd_intf_net [get_bd_intf_pins transmitter/M*_AXIS] [get_bd_intf_pins AXIS_TX]
  connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter/M*_ACLK]
  connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter/M*_ARESETN]
  if {$sync} {
    connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter/ACLK]
    connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter/ARESETN]
    connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter/S*_ACLK]
    connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter/S*_ARESETN]
  } else {
    connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/ACLK]
    connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins transmitter/ARESETN]
    connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/S*_ACLK]
    connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins transmitter/S*_ARESETN]
  }
}

# Create A Solo-Config
proc generate_singular {kernel PORT sync} {
  dict with kernel {
    variable kern [find_ID $ID]
    variable pes [lrange [get_bd_cells /arch/target_ip_[format %02d $kern]_*] 0 $Count-1]
    move_bd_cells [get_bd_cells Port_$PORT] $pes

    if {$sync} {
      puts "Connecting [get_bd_intf_pins AXIS_RX] to [get_bd_intf_pins [lindex $pes 0]/$interface_rx]"
      connect_bd_intf_net [get_bd_intf_pins AXIS_RX] [get_bd_intf_pins [lindex $pes 0]/$interface_rx]
      puts "Connecting [get_bd_intf_pins AXIS_TX] to [get_bd_intf_pins [lindex $pes 0]/$interface_tx]"
      connect_bd_intf_net [get_bd_intf_pins AXIS_TX] [get_bd_intf_pins [lindex $pes 0]/$interface_tx]

      variable clks [get_bd_pins -of_objects [lindex $pes 0] -filter {type == clk}]
      if {[llength $clks] > 1} {
        foreach clk $clks {
          variable interfaces [get_property CONFIG.ASSOCIATED_BUSIF $clk]
          if {[regexp $interface_rx $interfaces]} {
              disconnect_bd_net [get_bd_nets -of_objects $clk]    $clk
              connect_bd_net [get_bd_pins sfp_clock] $clk

              variable rst [get_bd_pins [lindex $pes 0]/[get_property CONFIG.ASSOCIATED_RESET $clk]]
              disconnect_bd_net [get_bd_nets -of_objects $rst]  $rst
              connect_bd_net [get_bd_pins /arch/sfp_rx_resetn] $rst
            } elseif {[regexp $interface_tx $interfaces]} {
              disconnect_bd_net [get_bd_nets -of_objects $clk]    $clk
              connect_bd_net [get_bd_pins sfp_rx_clock] $clk

              variable rst [get_bd_pins [lindex $pes 0]/[get_property CONFIG.ASSOCIATED_RESET $clk]]
              disconnect_bd_net [get_bd_nets -of_objects $rst]  $rst
              connect_bd_net [get_bd_pins /arch/sfp_rx_resetn] $rst
            }
          }
      } else {
        variable axi [find_AXI_Connection [lindex $pes 0]]
        variable axiclk [get_bd_pins ${axi}_ACLK]
        variable axireset [get_bd_pins ${axi}_ARESETN]

        disconnect_bd_net [get_bd_nets -of_objects $axiclk]    $axiclk
        disconnect_bd_net [get_bd_nets -of_objects $axireset]  $axireset
        connect_bd_net [get_bd_pins /arch/sfp_tx_clock] $axiclk
        connect_bd_net [get_bd_pins /arch/sfp_tx_resetn] $axireset

        variable rst [get_bd_pins [lindex $pes 0]/[get_property CONFIG.ASSOCIATED_RESET $clks]]
        disconnect_bd_net [get_bd_nets -of_objects $clks]  $clks
        connect_bd_net [get_bd_pins /arch/sfp_tx_clock] $clks
        disconnect_bd_net [get_bd_nets -of_objects $rst]  $rst
        connect_bd_net [get_bd_pins /arch/sfp_tx_resetn] $rst
      }
    } else {
      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 reciever_sync
      set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.S00_FIFO_DEPTH {2048} CONFIG.M00_FIFO_DEPTH {2048} CONFIG.S00_FIFO_MODE {0} CONFIG.M00_FIFO_MODE {0} ] [get_bd_cells reciever_sync]
      connect_bd_net [get_bd_pins sfp_rx_clock]  [get_bd_pins reciever_sync/ACLK]
      connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever_sync/ARESETN]
      connect_bd_net [get_bd_pins sfp_rx_clock]  [get_bd_pins reciever_sync/S*_ACLK]
      connect_bd_net [get_bd_pins sfp_rx_resetn] [get_bd_pins reciever_sync/S*_ARESETN]
      connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever_sync/M*_ACLK]
      connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins reciever_sync/M*_ARESETN]
      puts "Connecting [get_bd_intf_pins reciever_sync/M00_AXIS] to [get_bd_intf_pins [lindex $pes 0]/$interface_rx]"
      connect_bd_intf_net [get_bd_intf_pins reciever_sync/M00_AXIS] [get_bd_intf_pins [lindex $pes 0]/$interface_rx]
      connect_bd_intf_net [get_bd_intf_pins reciever_sync/S00_AXIS] [get_bd_intf_pins AXIS_RX]

      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 transmitter_sync
      set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.S00_FIFO_DEPTH {2048} CONFIG.M00_FIFO_DEPTH {2048} CONFIG.S00_FIFO_MODE {0} CONFIG.M00_FIFO_MODE {1} ] [get_bd_cells transmitter_sync]
      connect_bd_net [get_bd_pins design_clk]  [get_bd_pins transmitter_sync/ACLK]
      connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins transmitter_sync/ARESETN]
      connect_bd_net [get_bd_pins design_clk]  [get_bd_pins transmitter_sync/S*_ACLK]
      connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins transmitter_sync/S*_ARESETN]
      connect_bd_net [get_bd_pins sfp_tx_clock] [get_bd_pins transmitter_sync/M*_ACLK]
      connect_bd_net [get_bd_pins sfp_tx_resetn] [get_bd_pins transmitter_sync/M*_ARESETN]
      puts "Connecting [get_bd_intf_pins transmitter_sync/S00_AXIS] to [get_bd_intf_pins [lindex $pes 0]/$interface_tx]"
      connect_bd_intf_net [get_bd_intf_pins transmitter_sync/S00_AXIS] [get_bd_intf_pins [lindex $pes 0]/$interface_tx]
      connect_bd_intf_net [get_bd_intf_pins transmitter_sync/M00_AXIS] [get_bd_intf_pins AXIS_TX]
    }
  }
}

# Group PEs and Connect them to transmitter and reciever
proc connect_PEs {kernels PORT sync} {
  variable counter 0
  foreach kernel $kernels {
    dict with kernel {
      variable kern [find_ID $ID]
      variable pes [lrange [get_bd_cells /arch/target_ip_[format %02d $kern]_*] 0 $Count-1]
      move_bd_cells [get_bd_cells Port_$PORT] $pes
      for {variable i 0} {$i < $Count} {incr i} {
        puts "Using PE [lindex $pes $i] for Port $PORT"
        puts "Connecting [get_bd_intf_pins reciever/M[format %02d $counter]_AXIS] to [get_bd_intf_pins [lindex $pes $i]/$interface_rx]"
        connect_bd_intf_net [get_bd_intf_pins reciever/M[format %02d $counter]_AXIS] [get_bd_intf_pins [lindex $pes $i]/$interface_rx]
        puts "Connecting [get_bd_intf_pins transmitter/S[format %02d $counter]_AXIS] to [get_bd_intf_pins [lindex $pes $i]/$interface_tx]"
        connect_bd_intf_net [get_bd_intf_pins transmitter/S[format %02d $counter]_AXIS] [get_bd_intf_pins [lindex $pes $i]/$interface_tx]

        if {$sync} {
          variable clks [get_bd_pins -of_objects [lindex $pes $i] -filter {type == clk}]
          if {[llength $clks] > 1} {
            foreach clk $clks {
              variable interfaces [get_property CONFIG.ASSOCIATED_BUSIF $clk]
              if {[regexp $interface_rx $interfaces]} {
                puts "Connecting $clk to SFP-Clock  for $interface_rx"
                disconnect_bd_net [get_bd_nets -of_objects $clk] $clk
                connect_bd_net [get_bd_pins sfp_rx_clock] $clk
                variable reset [get_bd_pins [lindex $pes $i]/[get_property CONFIG.ASSOCIATED_RESET $clk]]
                disconnect_bd_net [get_bd_nets -of_objects $reset] $reset
                connect_bd_net [get_bd_pins sfp_rx_resetn] $reset
              } elseif {[regexp $interface_tx $interfaces]} {
                puts "Connecting $clk to SFP-Clock for $interface_tx"
                disconnect_bd_net [get_bd_nets -of_objects $clk] $clk
                connect_bd_net [get_bd_pins sfp_tx_clock] $clk
                variable reset [get_bd_pins [lindex $pes $i]/[get_property CONFIG.ASSOCIATED_RESET $clk]]
                disconnect_bd_net [get_bd_nets -of_objects $reset] $reset
                connect_bd_net [get_bd_pins sfp_tx_resetn] $reset
              }
            }
          } else {
            #Only one Clock-present
            variable axi [find_AXI_Connection [lindex $pes $i]]
            variable axiclk [get_bd_pins ${axi}_ACLK]
            variable axireset [get_bd_pins ${axi}_ARESETN]

            disconnect_bd_net [get_bd_nets -of_objects $axiclk]    $axiclk
            disconnect_bd_net [get_bd_nets -of_objects $axireset]  $axireset
            connect_bd_net [get_bd_pins /arch/sfp_rx_clock] $axiclk
            connect_bd_net [get_bd_pins /arch/sfp_rx_resetn] $axireset

            variable rst [get_bd_pins [lindex $pes $i]/[get_property CONFIG.ASSOCIATED_RESET $clks]]
            puts $rst
            puts [get_bd_pins [lindex $pes $i]/[get_property CONFIG.ASSOCIATED_RESET $clks]]
            puts $clks
            puts [get_property CONFIG.ASSOCIATED_RESET $clks]
            disconnect_bd_net [get_bd_nets -of_objects $clks]  $clks
            connect_bd_net [get_bd_pins /arch/sfp_tx_clock] $clks
            disconnect_bd_net [get_bd_nets -of_objects $rst]  $rst
            connect_bd_net [get_bd_pins /arch/sfp_tx_resetn] $rst
          }
        }
        variable counter [expr {$counter+1}]
      }
    }
  }
}

#Find the Masterinterface for a given Slaveinterface
proc find_AXI_Connection {input} {
  variable pin [get_bd_intf_pins -of_objects $input -filter {vlnv == xilinx.com:interface:aximm_rtl:1.0}]
  variable net ""
  while {![regexp "(.*M[0-9][0-9])_AXI" $pin -> port]} {
    variable nets [get_bd_intf_nets -boundary_type both -of_objects $pin]
    variable id [lsearch $nets $net]
    variable net [lreplace $nets $id $id]

    variable pins [get_bd_intf_pins -of_objects $net]
    variable id [lsearch $pins $pin]
    variable pin [lreplace $pins $id $id]
  }
  return $port
}

proc makeMaster {name} {
  set m_si [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 /host/$name]
  set num_mi_old [get_property CONFIG.NUM_MI [get_bd_cells /host/out_ic]]
  set num_mi [expr "$num_mi_old + 1"]
  set_property -dict [list CONFIG.NUM_MI $num_mi] [get_bd_cells /host/out_ic]
  connect_bd_intf_net $m_si [get_bd_intf_pins /host/out_ic/[format "M%02d_AXI" $num_mi_old]]
}

proc write_SI5324_Constraints {} {
  variable iic_scl
  variable iic_sda
  variable iic_rst
  variable si5324_rst

  set constraints_fn  "[get_property DIRECTORY [current_project]]/si5324.xdc]"
  set constraints_file [open $constraints_fn w+]

  puts $constraints_file {# I2C Clock}
  puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports IIC_scl_io]} [lindex $iic_scl 0]]
  puts $constraints_file [format {set_property PULLUP %s [get_ports IIC_scl_io]}      [lindex $iic_scl 1]]
  puts $constraints_file [format {set_property DRIVE  %s [get_ports IIC_scl_io]}      [lindex $iic_scl 2]]
  puts $constraints_file [format {set_property SLEW   %s [get_ports IIC_scl_io]}      [lindex $iic_scl 3]]
  puts $constraints_file [format {set_property IOSTANDARD %s [get_ports IIC_scl_io]}  [lindex $iic_scl 4]]

  puts $constraints_file {# I2C Data}
  puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports IIC_sda_io]} [lindex $iic_sda 0]]
  puts $constraints_file [format {set_property PULLUP %s [get_ports IIC_sda_io]}      [lindex $iic_sda 1]]
  puts $constraints_file [format {set_property DRIVE %s [get_ports IIC_sda_io]}       [lindex $iic_sda 2]]
  puts $constraints_file [format {set_property SLEW  %s [get_ports IIC_sda_io]}       [lindex $iic_sda 3]]
  puts $constraints_file [format {set_property IOSTANDARD %s [get_ports IIC_sda_io]}  [lindex $iic_sda 4]]

  puts $constraints_file {# I2C Reset}
  puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports i2c_reset[0]]} [lindex $iic_rst 0]]
  puts $constraints_file [format {set_property DRIVE %s [get_ports i2c_reset[0]]}       [lindex $iic_rst 1]]
  puts $constraints_file [format {set_property SLEW  %s [get_ports i2c_reset[0]]}       [lindex $iic_rst 2]]
  puts $constraints_file [format {set_property IOSTANDARD %s [get_ports i2c_reset[0]]}  [lindex $iic_rst 3]]

  puts $constraints_file {# SI5324 Reset}
  puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports i2c_reset[1]]} [lindex $si5324_rst 0]]
  puts $constraints_file [format {set_property DRIVE %s [get_ports i2c_reset[1]]}       [lindex $si5324_rst 1]]
  puts $constraints_file [format {set_property SLEW  %s [get_ports i2c_reset[1]]}       [lindex $si5324_rst 2]]
  puts $constraints_file [format {set_property IOSTANDARD  %s [get_ports i2c_reset[1]]} [lindex $si5324_rst 3]]

  close $constraints_file
  read_xdc $constraints_fn
  set_property PROCESSING_ORDER EARLY [get_files $constraints_fn]
}


proc addressmap {{args {}}} {
  if {[tapasco::is_feature_enabled "SFPPLUS"]} {
        set args [lappend args "M_SI5324"  [list 0x22ff000 0 0 ""]]
        set args [lappend args "M_NETWORK" [list 0x2500000 0 0 ""]]
        puts $args
    }
    save_bd_design
    return $args
  }

}

tapasco::register_plugin "platform::sfpplus::validate_sfp_ports" "pre-arch"
tapasco::register_plugin "platform::sfpplus::addressmap" "post-address-map"
