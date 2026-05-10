ROOT    := $(CURDIR)/..
TEST    ?= axi_rand_test
SEED    ?= random

# Questa paths — adjust if Questa is not in PATH
VLOG    := vlog
VSIM    := vsim

.PHONY: questa clean

questa:
	vlib work
	vmap work work
	$(VLOG) -sv -work work \
	    +incdir+$(QUESTA_HOME)/verilog_src/uvm-1.2/src \
	    $(QUESTA_HOME)/verilog_src/uvm-1.2/src/uvm_pkg.sv \
	    $(ROOT)/rtl/axi4_slave.sv \
	    $(ROOT)/tb/axi_if.sv \
	    $(ROOT)/tb/axi_seq_item.sv \
	    $(ROOT)/tb/axi_driver.sv \
	    $(ROOT)/tb/axi_monitor.sv \
	    $(ROOT)/tb/axi_scoreboard.sv \
	    $(ROOT)/tb/axi_env.sv \
	    $(ROOT)/tb/axi_tests.sv \
	    $(ROOT)/tb/axi_assertions.sv \
	    $(ROOT)/tb/tb_top.sv
	$(VSIM) -batch -sv_seed $(SEED) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=UVM_MEDIUM \
	    -do "run -all; quit -f" \
	    work.tb_top

burst_test:
	$(MAKE) questa TEST=axi_burst_test

clean:
	rm -rf work transcript vsim.wlf *.vcd
