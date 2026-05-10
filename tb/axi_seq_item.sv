// AXI4 transaction object
// Covers both write (AW+W+B channels) and read (AR+R channels)
// Saras Chandra Kannam

class axi_seq_item extends uvm_sequence_item;
    `uvm_object_utils(axi_seq_item)

    typedef enum logic { READ = 0, WRITE = 1 } direction_t;

    rand direction_t        dir;
    rand logic [31:0]       addr;
    rand logic [7:0]        data[];   // variable-length burst
    rand logic [7:0]        len;      // AWLEN/ARLEN: 0 = 1 beat, 255 = 256 beats
    rand logic [2:0]        size;     // AWSIZE/ARSIZE: bytes per beat (0=1B, 2=4B)
    rand logic [1:0]        burst;    // INCR=01, WRAP=10, FIXED=00

    // response fields (filled on completion)
    logic [1:0]  bresp;   // write response: OKAY=00, SLVERR=10
    logic [1:0]  rresp;   // read response per beat

    // constraints
    constraint c_size   { size inside {3'b000, 3'b001, 3'b010}; }  // 1/2/4 bytes
    constraint c_burst  { burst inside {2'b01, 2'b10}; }  // INCR or WRAP only
    constraint c_align  { addr[1:0] == 2'b00; }  // word-aligned
    constraint c_len    { len inside {[0:15]}; }  // keep bursts short for now
    constraint c_data_size { data.size() == (len + 1); }

    // WRAP burst: length must be 2, 4, 8 or 16 beats
    constraint c_wrap_len {
        if (burst == 2'b10)
            len inside {1, 3, 7, 15};
    }

    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s ADDR=%08h LEN=%0d SIZE=%0d BURST=%0b",
                         dir.name(), addr, len, size, burst);
    endfunction
endclass
