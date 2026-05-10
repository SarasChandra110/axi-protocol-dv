// AXI4 Verification Environment
class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)
    axi_driver    driver;
    axi_monitor   monitor;
    uvm_sequencer #(axi_seq_item) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = axi_driver::type_id::create("driver", this);
        monitor   = axi_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer #(axi_seq_item)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass


class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)
    axi_agent      agent;
    axi_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = axi_agent::type_id::create("agent", this);
        sb    = axi_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(sb.ap);
    endfunction
endclass
