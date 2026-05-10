// AXI4 Slave — simple memory-mapped register file
// 256 x 32-bit words, supports INCR and WRAP bursts
// Saras Chandra Kannam — personal portfolio

`timescale 1ns/1ps

module axi4_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 256
)(
    input  logic                    ACLK, ARESETn,
    // Write Address Channel
    input  logic [3:0]              AWID,
    input  logic [ADDR_WIDTH-1:0]   AWADDR,
    input  logic [7:0]              AWLEN,
    input  logic [2:0]              AWSIZE,
    input  logic [1:0]              AWBURST,
    input  logic                    AWVALID,
    output logic                    AWREADY,
    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]   WDATA,
    input  logic [DATA_WIDTH/8-1:0] WSTRB,
    input  logic                    WLAST,
    input  logic                    WVALID,
    output logic                    WREADY,
    // Write Response Channel
    output logic [3:0]              BID,
    output logic [1:0]              BRESP,
    output logic                    BVALID,
    input  logic                    BREADY,
    // Read Address Channel
    input  logic [3:0]              ARID,
    input  logic [ADDR_WIDTH-1:0]   ARADDR,
    input  logic [7:0]              ARLEN,
    input  logic [2:0]              ARSIZE,
    input  logic [1:0]              ARBURST,
    input  logic                    ARVALID,
    output logic                    ARREADY,
    // Read Data Channel
    output logic [3:0]              RID,
    output logic [DATA_WIDTH-1:0]   RDATA,
    output logic [1:0]              RRESP,
    output logic                    RLAST,
    output logic                    RVALID,
    input  logic                    RREADY
);

    // Memory
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // Write FSM
    typedef enum logic [1:0] { W_IDLE, W_ADDR, W_DATA, W_RESP } w_state_t;
    w_state_t w_state;

    logic [ADDR_WIDTH-1:0] w_addr;
    logic [7:0]            w_len, w_beat;
    logic [3:0]            w_id;
    logic [1:0]            w_burst;
    logic [2:0]            w_size;

    function automatic logic [ADDR_WIDTH-1:0] next_addr(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [1:0]            burst,
        input logic [7:0]            len,
        input logic [2:0]            size
    );
        logic [ADDR_WIDTH-1:0] stride = (1 << size);
        logic [ADDR_WIDTH-1:0] wrap_mask = (stride * (len + 1)) - 1;
        if (burst == 2'b01) // INCR
            return addr + stride;
        else if (burst == 2'b10) // WRAP
            return (addr & ~wrap_mask) | ((addr + stride) & wrap_mask);
        else // FIXED
            return addr;
    endfunction

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_state  <= W_IDLE;
            AWREADY  <= 1'b0;
            WREADY   <= 1'b0;
            BVALID   <= 1'b0;
            BID      <= '0;
            BRESP    <= 2'b00;
        end else begin
            case (w_state)
                W_IDLE: begin
                    AWREADY <= 1'b1;
                    w_state <= W_ADDR;
                end
                W_ADDR: begin
                    if (AWVALID && AWREADY) begin
                        w_addr  <= AWADDR;
                        w_len   <= AWLEN;
                        w_beat  <= 8'h0;
                        w_id    <= AWID;
                        w_burst <= AWBURST;
                        w_size  <= AWSIZE;
                        AWREADY <= 1'b0;
                        WREADY  <= 1'b1;
                        w_state <= W_DATA;
                    end
                end
                W_DATA: begin
                    if (WVALID && WREADY) begin
                        // write with byte strobes
                        for (int i = 0; i < DATA_WIDTH/8; i++) begin
                            if (WSTRB[i])
                                mem[w_addr[9:2]][i*8 +: 8] <= WDATA[i*8 +: 8];
                        end
                        if (WLAST) begin
                            WREADY  <= 1'b0;
                            BVALID  <= 1'b1;
                            BID     <= w_id;
                            BRESP   <= 2'b00; // OKAY
                            w_state <= W_RESP;
                        end else begin
                            w_addr  <= next_addr(w_addr, w_burst, w_len, w_size);
                            w_beat  <= w_beat + 1;
                        end
                    end
                end
                W_RESP: begin
                    if (BVALID && BREADY) begin
                        BVALID  <= 1'b0;
                        AWREADY <= 1'b1;
                        w_state <= W_ADDR;
                    end
                end
            endcase
        end
    end

    // Read FSM
    typedef enum logic [1:0] { R_IDLE, R_ADDR, R_DATA } r_state_t;
    r_state_t r_state;

    logic [ADDR_WIDTH-1:0] r_addr;
    logic [7:0]            r_len, r_beat;
    logic [3:0]            r_id;
    logic [1:0]            r_burst;
    logic [2:0]            r_size;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            r_state  <= R_IDLE;
            ARREADY  <= 1'b0;
            RVALID   <= 1'b0;
            RLAST    <= 1'b0;
            RID      <= '0;
            RDATA    <= '0;
            RRESP    <= 2'b00;
        end else begin
            case (r_state)
                R_IDLE: begin
                    ARREADY <= 1'b1;
                    r_state <= R_ADDR;
                end
                R_ADDR: begin
                    if (ARVALID && ARREADY) begin
                        r_addr  <= ARADDR;
                        r_len   <= ARLEN;
                        r_beat  <= 8'h0;
                        r_id    <= ARID;
                        r_burst <= ARBURST;
                        r_size  <= ARSIZE;
                        ARREADY <= 1'b0;
                        RVALID  <= 1'b1;
                        RDATA   <= mem[ARADDR[9:2]];
                        RID     <= ARID;
                        RRESP   <= 2'b00;
                        RLAST   <= (ARLEN == 8'h0);
                        r_state <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (RVALID && RREADY) begin
                        if (RLAST) begin
                            RVALID  <= 1'b0;
                            RLAST   <= 1'b0;
                            ARREADY <= 1'b1;
                            r_state <= R_ADDR;
                        end else begin
                            r_addr  <= next_addr(r_addr, r_burst, r_len, r_size);
                            r_beat  <= r_beat + 1;
                            RDATA   <= mem[next_addr(r_addr, r_burst, r_len, r_size)[9:2]];
                            RLAST   <= (r_beat + 1 == r_len);
                        end
                    end
                end
            endcase
        end
    end

endmodule
