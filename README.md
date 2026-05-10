# axi-protocol-dv

AXI4 protocol verification environment — full UVM testbench with constrained-random
sequences and SystemVerilog assertions for protocol compliance checking.

AXI4 is everywhere in ASIC design — interconnects, memory controllers,
accelerator interfaces — so understanding how to verify it properly felt essential.

> **Simulator:** Requires Questa or VCS. Uses clocking blocks, interface modports,
> and full UVM — not supported by iverilog.

---

## What's here

Full UVM TB targeting a memory-mapped AXI4 slave:

| File | What it does |
|------|-------------|
| `rtl/axi4_slave.sv` | AXI4 slave DUT — 256×32-bit memory, INCR + WRAP bursts, byte strobes |
| `tb/axi_if.sv` | Interface with master/monitor clocking blocks |
| `tb/axi_seq_item.sv` | Transaction object — burst constraints (INCR, WRAP, length/size alignment) |
| `tb/axi_driver.sv` | Drives AW+W+B (write) and AR+R (read) channels |
| `tb/axi_monitor.sv` | Passive observer for both channels |
| `tb/axi_scoreboard.sv` | Shadow memory write-then-read-back checker |
| `tb/axi_env.sv` | Agent + env class hierarchy |
| `tb/axi_tests.sv` | `axi_rand_test` (100 txns) + `axi_burst_test` (WRAP bursts) |
| `tb/axi_assertions.sv` | 9 SVA assertions bound to DUT |
| `tb/tb_top.sv` | UVM top — `run_test()`, interface, bind |
| `sim/Makefile` | `make questa TEST=axi_rand_test` |
| `sim/run_questa.do` | Questa compile + run script |

---

## AXI4 channels verified

```
Write path:  AW (address) → W (data) → B (response)
Read path:   AR (address) → R (data + response)
```

The tricky part with AXI4 is that all 5 channels are independent — a
master can have multiple outstanding transactions, and the slave can
respond out-of-order (with IDs). This testbench handles single-ID
in-order transactions; out-of-order is on the TODO list.

---

## SVA assertions

| Assertion | What it checks |
|-----------|----------------|
| `a_awvalid_stable` | AWVALID stays high until AWREADY (no early drop) |
| `a_arvalid_stable` | Same for read address channel |
| `a_awaddr_stable` | AWADDR doesn't change while waiting for AWREADY |
| `a_araddr_stable` | Same for ARADDR |
| `a_rresp_valid` | RRESP is OKAY or SLVERR only (no reserved codes) |
| `a_bresp_valid` | Same for BRESP |
| `a_awburst_valid` | AWBURST not RESERVED (2'b11) |
| `a_bvalid_after_wlast` | Write response only after WLAST |
| `a_reset` | All VALID signals deasserted after reset |

The VALID stability assertions catch a common DUT bug where the master
drops VALID before handshake completes — AXI4 spec explicitly forbids this.

---

## Constraints in `axi_seq_item`

```systemverilog
constraint c_size     { size inside {3'b000, 3'b001, 3'b010}; }  // 1/2/4 bytes
constraint c_burst    { burst inside {2'b01, 2'b10}; }           // INCR or WRAP
constraint c_align    { addr[1:0] == 2'b00; }                    // word-aligned
constraint c_len      { len inside {[0:15]}; }                   // short bursts
constraint c_wrap_len { if (burst == 2'b10) len inside {1,3,7,15}; }
```

---

## Running the simulation

```bash
# Requires Questa (free edition from intel.com/questa)

# Default test — 100 random read/write transactions
cd sim && make questa

# Burst test — 50 WRAP burst transactions
cd sim && make burst_test

# Or with vsim directly
vsim -do sim/run_questa.do
```

---

## Project structure

```
axi-protocol-dv/
├── rtl/
│   └── axi4_slave.sv      -- AXI4 slave DUT
├── tb/
│   ├── axi_if.sv           -- clocking block interface
│   ├── axi_seq_item.sv     -- transaction + constraints
│   ├── axi_driver.sv       -- master driver
│   ├── axi_monitor.sv      -- passive monitor
│   ├── axi_scoreboard.sv   -- shadow memory checker
│   ├── axi_env.sv          -- agent + env
│   ├── axi_tests.sv        -- rand_test + burst_test
│   ├── axi_assertions.sv   -- 9 SVA assertions (bind)
│   └── tb_top.sv           -- UVM top
└── sim/
    ├── Makefile
    └── run_questa.do
```

---

## Known limitations / future work

- Single outstanding transaction (no out-of-order IDs yet)
- AXI4-Lite variant not implemented — common for CSR interfaces
- Formal verification of VALID stability assertions using JasperGold
  (assertions already written, just need the formal tool flow)
- Questa required — clocking blocks + UVM not supported by iverilog
