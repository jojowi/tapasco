set_property DONT_TOUCH TRUE [get_cells -hierarchical clkout1_buf_uplus]
set_property CLOCK_DELAY_GROUP group_bufgce [get_nets -hierarchical *clkout1_buf_uplus/BUFGCE_O[0]]
set_property USER_CLOCK_ROOT X4Y11 [get_nets -hierarchical clkout1_buf_uplus/U0/BUFGCE_O[0]]