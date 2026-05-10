# Questa simulation script for axi-protocol-dv
# Usage: vsim -do sim/run_questa.do
# Or:    cd sim && make questa TEST=axi_rand_test

quietly set ROOT [file normalize [file dirname [info script]]/..]

# Create work library
vlib work
vmap work work

# Compile UVM (Questa has it built-in)
vlog -sv -work work +incdir+$::env(QUESTA_HOME)/verilog_src/uvm-1.2/src \
     $::env(QUESTA_HOME)/verilog_src/uvm-1.2/src/uvm_pkg.sv

# Compile RTL
vlog -sv -work work \
    $ROOT/rtl/axi4_slave.sv

# Compile TB files (order matters — pkg before users)
vlog -sv -work work +incdir+$::env(QUESTA_HOME)/verilog_src/uvm-1.2/src \
    $ROOT/tb/axi_if.sv       \
    $ROOT/tb/axi_seq_item.sv \
    $ROOT/tb/axi_driver.sv   \
    $ROOT/tb/axi_monitor.sv  \
    $ROOT/tb/axi_scoreboard.sv \
    $ROOT/tb/axi_env.sv      \
    $ROOT/tb/axi_tests.sv    \
    $ROOT/tb/axi_assertions.sv \
    $ROOT/tb/tb_top.sv

# Run simulation
set TEST [expr {[info exists ::env(TEST)] ? $::env(TEST) : "axi_rand_test"}]

vsim -sv_seed random \
     +UVM_TESTNAME=$TEST \
     +UVM_VERBOSITY=UVM_MEDIUM \
     work.tb_top

# Run and log results
log -r /*
run -all

# Print pass/fail
set status [examine -radix symbolic sim:/tb_top/dut/ARESETn]
quit -f
