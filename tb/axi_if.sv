// AXI4 Interface — bundles all signals for DUT connection and virtual interface
`timescale 1ns/1ps

interface axi4_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input logic ACLK, ARESETn
);
    // Write address
    logic [3:0]              AWID;
    logic [ADDR_WIDTH-1:0]   AWADDR;
    logic [7:0]              AWLEN;
    logic [2:0]              AWSIZE;
    logic [1:0]              AWBURST;
    logic                    AWVALID;
    logic                    AWREADY;
    // Write data
    logic [DATA_WIDTH-1:0]   WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic                    WLAST;
    logic                    WVALID;
    logic                    WREADY;
    // Write response
    logic [3:0]              BID;
    logic [1:0]              BRESP;
    logic                    BVALID;
    logic                    BREADY;
    // Read address
    logic [3:0]              ARID;
    logic [ADDR_WIDTH-1:0]   ARADDR;
    logic [7:0]              ARLEN;
    logic [2:0]              ARSIZE;
    logic [1:0]              ARBURST;
    logic                    ARVALID;
    logic                    ARREADY;
    // Read data
    logic [3:0]              RID;
    logic [DATA_WIDTH-1:0]   RDATA;
    logic [1:0]              RRESP;
    logic                    RLAST;
    logic                    RVALID;
    logic                    RREADY;

    // Master clocking block — driven by testbench
    clocking master_cb @(posedge ACLK);
        default input #1 output #1;
        output AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWVALID;
        input  AWREADY;
        output WDATA, WSTRB, WLAST, WVALID;
        input  WREADY;
        input  BID, BRESP, BVALID;
        output BREADY;
        output ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID;
        input  ARREADY;
        input  RID, RDATA, RRESP, RLAST, RVALID;
        output RREADY;
    endclocking

    // Monitor clocking block — passive
    clocking monitor_cb @(posedge ACLK);
        default input #1;
        input AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWVALID, AWREADY;
        input WDATA, WSTRB, WLAST, WVALID, WREADY;
        input BID, BRESP, BVALID, BREADY;
        input ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARVALID, ARREADY;
        input RID, RDATA, RRESP, RLAST, RVALID, RREADY;
    endclocking

    modport master  (clocking master_cb,  input ACLK, ARESETn);
    modport monitor (clocking monitor_cb, input ACLK, ARESETn);
endinterface
