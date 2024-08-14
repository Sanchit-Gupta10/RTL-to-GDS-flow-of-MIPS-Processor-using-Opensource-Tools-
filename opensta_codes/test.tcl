read_liberty ./opensta_codes/NangateOpenCellLibrary_typical.lib
read_verilog ./opensta_codes/mips_netlist_01.v
link_design mips_top
read_sdc ./opensta_codes/top.sdc

# Verify design constraints
report_checks -path_delay max -format full
report_checks -path_delay min -format full

#for power analysis
set_power_activity -global -activity 0.1

report_power

