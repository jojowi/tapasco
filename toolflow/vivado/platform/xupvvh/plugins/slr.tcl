namespace eval singleslr {
  proc create_constraints {} {
    if {[tapasco::is_feature_enabled "SingleSLR"]} {
      set constraints_fn "[get_property DIRECTORY [current_project]]/singleslr.xdc"
      set constraints_file [open $constraints_fn w+]
      set data [tapasco::get_feature "SingleSLR"]
      set value [dict values [dict remove $data enabled]]
      foreach IDs $value {
        puts [format "Creating Single SLR constraints for PEs: %s" $IDs] 
        foreach ID $IDs {
          set core [find_ID $ID]
          set PEs [get_bd_cells /arch/target_ip_[format %02d $core]_*]
          foreach PE $PEs {
            puts $constraints_file [format {set_property USER_SLR_ASSIGNMENT slr_group_%s [get_cells system_i%s]} $PE $PE]
          }
        }
      }
      close $constraints_file
      read_xdc $constraints_fn
      set_property PROCESSING_ORDER NORMAL [get_files $constraints_fn] 
    }
  }

  proc find_ID {input} {
    set composition [tapasco::get_composition]
    for {set o 0} {$o < [llength $composition] -1} {incr o} {
      if {[regexp ".*:$input:.*" [dict get $composition $o vlnv]]} {
        return $o
      }
    }
    return -1
  }
}

tapasco::register_plugin "platform::singleslr::create_constraints" "post-platform"