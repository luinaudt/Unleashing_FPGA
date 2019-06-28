set_property SRC_FILE_INFO {cfile:/home/thomas/Documents/p4_fpga_plugin/rtl/constraint/times500.xdc rfile:../../../../rtl/constraint/times500.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:1 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 2.000 -name clk_line -waveform {0.000 1.000} -add [get_ports clk_line]
