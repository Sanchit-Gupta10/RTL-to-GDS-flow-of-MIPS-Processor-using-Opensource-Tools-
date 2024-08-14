#read modules from verilog file
read_verilog ./yosys_codes/mips_top.v

hierarchy -check -top mips_top
flatten
# the high-level stuff
proc; opt; fsm; opt; memory; opt

#remove unused cells and wires
clean

#resource sharing optimization
share -aggressive

# mapping to internal cell library
techmap; opt

#mapping d flip-flops to cell library
dfflibmap -liberty ./yosys_codes/NangateOpenCellLibrary_typical.lib

#mapping logic to cell library
abc -liberty ./yosys_codes/NangateOpenCellLibrary_typical.lib

opt; clean

opt_clean

#remove unused cells and wires
clean

#report design statistics
stat -liberty ./yosys_codes/NangateOpenCellLibrary_typical.lib

#write the current design into verilog file
write_verilog -noattr -noexpr -nohex -nodec ./yosys_codes/mips_netlist_01.v



