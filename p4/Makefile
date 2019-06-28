# Compile p4 to sdnet
# author : Thomas Luinaud, Jeferson Santiago Da Silva

.SUFFIXES:
.SUFFIXES: .p4 .vhdl .sdnet .synth

DEVICE=xcvu9p-flga2577-3-e #xc7z045ffg900-2
BUS_SIZE=2048
BUS_TYPE=axi		# lbus or axi
LINE_CLOCK_RATE=500 #333 #156.25
CTRL_CLOCK_RATE=100
LOOKUP_CLOCK_RATE=100
P4_APP=kaloom_forward
XILINX_SWITCH_ARCH=XilinxSwitch
CLOCK_CONSTRAINTS=times500.xdc
SINGLE_CONTROL_PLANE_PORT= #-singleControlPort	# uncomment for single control plane interface (does not work for external loopuk engine)
SET_IMPL=

%.vhdl: %.sdnet
	rm -rf ../rtl/$*.P4.HDL
	sdnet -busType $(BUS_TYPE) -busWidth $(BUS_SIZE) $*.sdnet -workDir ../rtl/$*.P4.HDL -lineClock $(LINE_CLOCK_RATE) $(SINGLE_CONTROL_PLANE_PORT)
	python ../scripts/update_sdnet_tcl.py $(XILINX_SWITCH_ARCH) ../rtl/$*.P4.HDL/$(XILINX_SWITCH_ARCH)/ $(DEVICE) $(CLOCK_CONSTRAINTS) $(SET_IMPL)

%.synth: %.vhdl
	vivado -mode tcl -source ../rtl/$*.P4.HDL/$(XILINX_SWITCH_ARCH)/$(XILINX_SWITCH_ARCH)_vivado_packager_out.tcl 
	rm -rf *.jou *.log
	echo "read_checkpoint ../../$*.P4.HDL/$(XILINX_SWITCH_ARCH)/$(XILINX_SWITCH_ARCH).dcp" >> ../rtl/sdnet_switch.tcl

%.sdnet: %.p4
	p4c-sdnet $*.p4 -o $*.sdnet --sdnet_info $*_sdnet_switch_info.dat

clean:
	rm -rf *.sdnet ../rtl/*.P4.HDL *.vhdl
