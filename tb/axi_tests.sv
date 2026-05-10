// AXI4 Test sequences and test classes

// Single write + read-back sequence
class axi_single_rw_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_single_rw_seq)
    int unsigned num_txns = 100;

    task body();
        axi_seq_item wr, rd;
        // Write 100 random locations
        repeat (num_txns) begin
            wr = axi_seq_item::type_id::create("wr");
            start_item(wr);
            assert(wr.randomize() with { dir == axi_seq_item::WRITE; len inside {[0:7]}; });
            finish_item(wr);

            // Read back same address + length
            rd = axi_seq_item::type_id::create("rd");
            start_item(rd);
            assert(rd.randomize() with {
                dir   == axi_seq_item::READ;
                addr  == wr.addr;
                len   == wr.len;
                size  == wr.size;
                burst == wr.burst;
            });
            finish_item(rd);
        end
    endtask
endclass


// Burst-only stress test
class axi_burst_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_burst_seq)

    task body();
        axi_seq_item txn;
        repeat (50) begin
            txn = axi_seq_item::type_id::create("txn");
            start_item(txn);
            assert(txn.randomize() with {
                len inside {3, 7, 15};        // WRAP-legal lengths
                burst == 2'b10;               // WRAP bursts only
            });
            finish_item(txn);
        end
    endtask
endclass


// Base test
class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)
    axi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_env::type_id::create("env", this);
    endfunction
endclass


// Single RW test
class axi_rand_test extends axi_base_test;
    `uvm_component_utils(axi_rand_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi_single_rw_seq seq;
        phase.raise_objection(this);
        seq = axi_single_rw_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #200;
        phase.drop_objection(this);
    endtask
endclass


// Burst test
class axi_burst_test extends axi_base_test;
    `uvm_component_utils(axi_burst_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi_burst_seq seq;
        phase.raise_objection(this);
        seq = axi_burst_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #200;
        phase.drop_objection(this);
    endtask
endclass
