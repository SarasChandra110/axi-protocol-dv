// Simulation top — instantiates DUT, interface, and starts UVM test
`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic ACLK, ARESETn;

    // Interface instance
    axi4_if #(.DATA_WIDTH(32), .ADDR_WIDTH(32)) axi_bus (.ACLK(ACLK), .ARESETn(ARESETn));

    // DUT
    axi4_slave #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .MEM_DEPTH(256)) dut (
        .ACLK     (ACLK),
        .ARESETn  (ARESETn),
        .AWID     (axi_bus.AWID),
        .AWADDR   (axi_bus.AWADDR),
        .AWLEN    (axi_bus.AWLEN),
        .AWSIZE   (axi_bus.AWSIZE),
        .AWBURST  (axi_bus.AWBURST),
        .AWVALID  (axi_bus.AWVALID),
        .AWREADY  (axi_bus.AWREADY),
        .WDATA    (axi_bus.WDATA),
        .WSTRB    (axi_bus.WSTRB),
        .WLAST    (axi_bus.WLAST),
        .WVALID   (axi_bus.WVALID),
        .WREADY   (axi_bus.WREADY),
        .BID      (axi_bus.BID),
        .BRESP    (axi_bus.BRESP),
        .BVALID   (axi_bus.BVALID),
        .BREADY   (axi_bus.BREADY),
        .ARID     (axi_bus.ARID),
        .ARADDR   (axi_bus.ARADDR),
        .ARLEN    (axi_bus.ARLEN),
        .ARSIZE   (axi_bus.ARSIZE),
        .ARBURST  (axi_bus.ARBURST),
        .ARVALID  (axi_bus.ARVALID),
        .ARREADY  (axi_bus.ARREADY),
        .RID      (axi_bus.RID),
        .RDATA    (axi_bus.RDATA),
        .RRESP    (axi_bus.RRESP),
        .RLAST    (axi_bus.RLAST),
        .RVALID   (axi_bus.RVALID),
        .RREADY   (axi_bus.RREADY)
    );

    // Bind SVA assertions
    bind axi4_slave axi_assertions u_assert (
        .ACLK(ACLK), .ARESETn(ARESETn),
        .AWVALID(AWVALID), .AWREADY(AWREADY), .AWADDR(AWADDR),
        .AWLEN(AWLEN), .AWSIZE(AWSIZE), .AWBURST(AWBURST),
        .WVALID(WVALID), .WREADY(WREADY), .WLAST(WLAST), .WDATA(WDATA),
        .BVALID(BVALID), .BREADY(BREADY), .BRESP(BRESP),
        .ARVALID(ARVALID), .ARREADY(ARREADY), .ARADDR(ARADDR),
        .ARLEN(ARLEN), .ARSIZE(ARSIZE), .ARBURST(ARBURST),
        .RVALID(RVALID), .RREADY(RREADY), .RLAST(RLAST),
        .RDATA(RDATA), .RRESP(RRESP)
    );

    // 200 MHz clock
    initial ACLK = 0;
    always #2.5 ACLK = ~ACLK;

    // Reset
    initial begin
        ARESETn = 0;
        repeat(5) @(posedge ACLK);
        ARESETn = 1;
    end

    // Pass interface to UVM config_db and start test
    initial begin
        uvm_config_db #(virtual axi4_if)::set(null, "uvm_test_top.*", "vif", axi_bus);
        run_test();
    end

    // Waveform dump
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
    end
endmodule
