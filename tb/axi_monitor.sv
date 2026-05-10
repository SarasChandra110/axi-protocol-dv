// AXI4 Monitor — observes both write and read channels, broadcasts to scoreboard
class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    virtual axi4_if                   vif;
    uvm_analysis_port #(axi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi4_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "axi_monitor: no interface")
    endfunction

    task run_phase(uvm_phase phase);
        @(posedge vif.ARESETn);
        fork
            monitor_writes();
            monitor_reads();
        join
    endtask

    task monitor_writes();
        axi_seq_item txn;
        forever begin
            // Wait for write address handshake
            @(vif.monitor_cb iff (vif.monitor_cb.AWVALID && vif.monitor_cb.AWREADY));
            txn = axi_seq_item::type_id::create("txn");
            txn.dir   = axi_seq_item::WRITE;
            txn.addr  = vif.monitor_cb.AWADDR;
            txn.len   = vif.monitor_cb.AWLEN;
            txn.size  = vif.monitor_cb.AWSIZE;
            txn.burst = vif.monitor_cb.AWBURST;
            txn.data  = new[txn.len + 1];

            // Collect write data beats
            for (int i = 0; i <= txn.len; i++) begin
                @(vif.monitor_cb iff (vif.monitor_cb.WVALID && vif.monitor_cb.WREADY));
                txn.data[i] = vif.monitor_cb.WDATA;
            end

            // Capture write response
            @(vif.monitor_cb iff vif.monitor_cb.BVALID);
            txn.bresp = vif.monitor_cb.BRESP;

            ap.write(txn);
        end
    endtask

    task monitor_reads();
        axi_seq_item txn;
        forever begin
            @(vif.monitor_cb iff (vif.monitor_cb.ARVALID && vif.monitor_cb.ARREADY));
            txn = axi_seq_item::type_id::create("txn");
            txn.dir   = axi_seq_item::READ;
            txn.addr  = vif.monitor_cb.ARADDR;
            txn.len   = vif.monitor_cb.ARLEN;
            txn.size  = vif.monitor_cb.ARSIZE;
            txn.burst = vif.monitor_cb.ARBURST;
            txn.data  = new[txn.len + 1];

            for (int i = 0; i <= txn.len; i++) begin
                @(vif.monitor_cb iff vif.monitor_cb.RVALID);
                txn.data[i] = vif.monitor_cb.RDATA;
                txn.rresp   = vif.monitor_cb.RRESP;
            end
            ap.write(txn);
        end
    endtask
endclass
