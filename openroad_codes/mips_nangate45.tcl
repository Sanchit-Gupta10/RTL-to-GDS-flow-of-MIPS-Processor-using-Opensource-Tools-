# gcd flow pipe cleaner
source "helpers.tcl"
source "flow_helpers.tcl"
source "Nangate45/Nangate45.vars"

set design "mips_top"
set top_module "mips_top"
set synth_verilog "./openroad_codes/mips_netlist.v"
set sdc_file "gcd_nangate45.sdc"
set die_area {0 0 100.13 100.8}
set core_area {10.07 11.2 90.25 91}

source -echo "flow_floorplan.tcl"
#source -echo "flow_pdn.tcl"
#source -echo "flow_global_placement.tcl"
#source -echo "flow_detailed_placement.tcl"
