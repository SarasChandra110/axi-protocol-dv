// AXI4 Scoreboard — write then read-back check
// Maintains a shadow memory; verifies RDATA == last written value
class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_seq_item, axi_scoreboard) ap;

    // shadow memory: addr -> data queue (supports bursts)
    logic [31:0] shadow_mem [logic [31:0]];

    int pass_cnt, fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    function void write(axi_seq_item txn);
        logic [31:0] addr = txn.addr;

        if (txn.dir == axi_seq_item::WRITE) begin
            // Update shadow memory
            if (txn.bresp != 2'b00) begin
                `uvm_error("SB", $sformatf("WRITE ERROR response: BRESP=%0b addr=%08h", txn.bresp, addr))
                fail_cnt++;
                return;
            end
            foreach (txn.data[i]) begin
                shadow_mem[addr] = txn.data[i];
                addr = addr + 4; // simplified: always INCR word-aligned
            end
            pass_cnt++;

        end else begin
            // Check read data against shadow
            if (txn.rresp != 2'b00) begin
                `uvm_error("SB", $sformatf("READ ERROR response: RRESP=%0b addr=%08h", txn.rresp, addr))
                fail_cnt++;
                return;
            end
            foreach (txn.data[i]) begin
                if (shadow_mem.exists(addr)) begin
                    if (txn.data[i] !== shadow_mem[addr]) begin
                        `uvm_error("SB", $sformatf(
                            "RDATA MISMATCH addr=%08h: got %08h expected %08h",
                            addr, txn.data[i], shadow_mem[addr]))
                        fail_cnt++;
                    end else begin
                        pass_cnt++;
                    end
                end
                addr = addr + 4;
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("SCOREBOARD: %0d passed, %0d failed", pass_cnt, fail_cnt), UVM_LOW)
        if (fail_cnt > 0)
            `uvm_error("SB", "TEST FAILED")
        else
            `uvm_info("SB", "TEST PASSED", UVM_LOW)
    endfunction
endclass
