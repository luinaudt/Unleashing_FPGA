set_property SRC_FILE_INFO {cfile:/home/thomas/Documents/p4_fpga_plugin/rtl/constraint/times500.xdc rfile:../../rtl/constraint/times500.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:2 export:INPUT save:INPUT read:READ} [current_design]
create_clock -add -name clk_lookup -period 2.0 -waveform {0 1.0} [get_ports {clk_lookup}];
set_property src_info {type:XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
create_clock -add -name clk_control -period 10.0 -waveform {0 5} [get_ports {clk_control}];
