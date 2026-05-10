// AXI4 Master Driver — drives write and read transactions
class axi_driver extends uvm_driver #(axi_seq_item);
    `uvm_component_utils(axi_driver)

    virtual axi4_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "axi_driver: no interface")
    endfunction

    task run_phase(uvm_phase phase);
        axi_seq_item txn;
        idle_bus();
        @(posedge vif.ARESETn);
        repeat(2) @(posedge vif.ACLK);

        forever begin
            seq_item_port.get_next_item(txn);
            if (txn.dir == axi_seq_item::WRITE)
                do_write(txn);
            else
                do_read(txn);
            seq_item_port.item_done();
        end
    endtask

    task idle_bus();
        vif.master_cb.AWVALID <= 0;
        vif.master_cb.WVALID  <= 0;
        vif.master_cb.BREADY  <= 1;
        vif.master_cb.ARVALID <= 0;
        vif.master_cb.RREADY  <= 1;
    endtask

    task do_write(axi_seq_item txn);
        // Write address channel
        @(vif.master_cb);
        vif.master_cb.AWID    <= 4'h0;
        vif.master_cb.AWADDR  <= txn.addr;
        vif.master_cb.AWLEN   <= txn.len;
        vif.master_cb.AWSIZE  <= txn.size;
        vif.master_cb.AWBURST <= txn.burst;
        vif.master_cb.AWVALID <= 1;
        @(vif.master_cb iff vif.master_cb.AWREADY);
        vif.master_cb.AWVALID <= 0;

        // Write data channel — one beat per transfer
        foreach (txn.data[i]) begin
            @(vif.master_cb);
            vif.master_cb.WDATA  <= txn.data[i];
            vif.master_cb.WSTRB  <= '1;
            vif.master_cb.WLAST  <= (i == txn.data.size()-1);
            vif.master_cb.WVALID <= 1;
            @(vif.master_cb iff vif.master_cb.WREADY);
        end
        vif.master_cb.WVALID <= 0;
        vif.master_cb.WLAST  <= 0;

        // Wait for write response
        @(vif.master_cb iff vif.master_cb.BVALID);
        txn.bresp = vif.master_cb.BRESP;
    endtask

    task do_read(axi_seq_item txn);
        // Read address channel
        @(vif.master_cb);
        vif.master_cb.ARID    <= 4'h0;
        vif.master_cb.ARADDR  <= txn.addr;
        vif.master_cb.ARLEN   <= txn.len;
        vif.master_cb.ARSIZE  <= txn.size;
        vif.master_cb.ARBURST <= txn.burst;
        vif.master_cb.ARVALID <= 1;
        @(vif.master_cb iff vif.master_cb.ARREADY);
        vif.master_cb.ARVALID <= 0;

        // Collect read data beats
        txn.data = new[txn.len + 1];
        for (int i = 0; i <= txn.len; i++) begin
            @(vif.master_cb iff vif.master_cb.RVALID);
            txn.data[i] = vif.master_cb.RDATA;
            txn.rresp   = vif.master_cb.RRESP;
        end
    endtask
endclass
