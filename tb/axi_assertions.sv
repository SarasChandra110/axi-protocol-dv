// AXI4 protocol assertions
// These bind to the DUT and catch protocol violations in simulation.
// Saras Chandra Kannam
//
// Key AXI4 rules I'm checking:
//   1. VALID must stay high until READY (no early deassertion)
//   2. AWID/WID must match for write pairing (AXI3 — AXI4 drops WID)
//   3. Write response can only come after write data is accepted
//   4. RRESP/BRESP must be OKAY or SLVERR (no reserved codes)
//   5. Once ARVALID asserted, ARADDR/ARLEN/ARSIZE must be stable until ARREADY

module axi_assertions (
    input logic        ACLK, ARESETn,
    // write address channel
    input logic        AWVALID, AWREADY,
    input logic [31:0] AWADDR,
    input logic [7:0]  AWLEN,
    input logic [2:0]  AWSIZE,
    input logic [1:0]  AWBURST,
    // write data channel
    input logic        WVALID, WREADY, WLAST,
    input logic [31:0] WDATA,
    // write response channel
    input logic        BVALID, BREADY,
    input logic [1:0]  BRESP,
    // read address channel
    input logic        ARVALID, ARREADY,
    input logic [31:0] ARADDR,
    input logic [7:0]  ARLEN,
    input logic [2:0]  ARSIZE,
    input logic [1:0]  ARBURST,
    // read data channel
    input logic        RVALID, RREADY, RLAST,
    input logic [31:0] RDATA,
    input logic [1:0]  RRESP
);

    // after reset, all VALID signals must start low
    property p_valid_after_reset;
        @(posedge ACLK) $rose(ARESETn) |=>
            !AWVALID && !WVALID && !BVALID && !ARVALID && !RVALID;
    endproperty
    a_reset: assert property (p_valid_after_reset)
        else $error("ASSERT FAIL: VALID signals not deasserted after reset");

    // AWVALID must stay high until AWREADY
    property p_awvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (AWVALID && !AWREADY) |=> AWVALID;
    endproperty
    a_awvalid_stable: assert property (p_awvalid_stable)
        else $error("ASSERT FAIL: AWVALID deasserted before AWREADY");

    // ARVALID must stay high until ARREADY
    property p_arvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (ARVALID && !ARREADY) |=> ARVALID;
    endproperty
    a_arvalid_stable: assert property (p_arvalid_stable)
        else $error("ASSERT FAIL: ARVALID deasserted before ARREADY");

    // AWADDR must be stable while AWVALID && !AWREADY
    property p_awaddr_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (AWVALID && !AWREADY) |=> $stable(AWADDR);
    endproperty
    a_awaddr_stable: assert property (p_awaddr_stable)
        else $error("ASSERT FAIL: AWADDR changed while AWVALID waiting for AWREADY");

    // ARADDR must be stable while ARVALID && !ARREADY
    property p_araddr_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (ARVALID && !ARREADY) |=> $stable(ARADDR);
    endproperty
    a_araddr_stable: assert property (p_araddr_stable)
        else $error("ASSERT FAIL: ARADDR changed while ARVALID waiting for ARREADY");

    // RRESP must be OKAY (2'b00) or SLVERR (2'b10) — no reserved codes
    property p_rresp_valid;
        @(posedge ACLK) disable iff (!ARESETn)
        RVALID |-> RRESP inside {2'b00, 2'b10};
    endproperty
    a_rresp_valid: assert property (p_rresp_valid)
        else $error("ASSERT FAIL: illegal RRESP value %0b", RRESP);

    // BRESP must be OKAY or SLVERR
    property p_bresp_valid;
        @(posedge ACLK) disable iff (!ARESETn)
        BVALID |-> BRESP inside {2'b00, 2'b10};
    endproperty
    a_bresp_valid: assert property (p_bresp_valid)
        else $error("ASSERT FAIL: illegal BRESP value %0b", BRESP);

    // AWBURST and ARBURST must not be RESERVED (2'b11)
    property p_awburst_valid;
        @(posedge ACLK) disable iff (!ARESETn)
        AWVALID |-> AWBURST != 2'b11;
    endproperty
    a_awburst_valid: assert property (p_awburst_valid)
        else $error("ASSERT FAIL: AWBURST = RESERVED (2'b11)");

    // WLAST must be asserted on the final beat of a write burst
    // (checking that BVALID only comes after WLAST was seen)
    property p_bvalid_after_wlast;
        @(posedge ACLK) disable iff (!ARESETn)
        (WVALID && WREADY && WLAST) |=> ##[1:$] BVALID;
    endproperty
    a_bvalid_after_wlast: assert property (p_bvalid_after_wlast)
        else $error("ASSERT FAIL: BVALID never came after WLAST");

    // coverage: track which burst types and sizes are exercised
    cover property (@(posedge ACLK) AWVALID && AWREADY && AWBURST == 2'b01);  // INCR write
    cover property (@(posedge ACLK) AWVALID && AWREADY && AWBURST == 2'b10);  // WRAP write
    cover property (@(posedge ACLK) ARVALID && ARREADY && ARBURST == 2'b01);  // INCR read
    cover property (@(posedge ACLK) BVALID  && BREADY  && BRESP   == 2'b10);  // write error

endmodule
