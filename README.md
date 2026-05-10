# axi-protocol-dv

AXI4 protocol verification environment — constrained-random testbench
with SystemVerilog assertions for protocol compliance checking.

AXI4 is everywhere in ASIC design — interconnects, memory controllers,
accelerator interfaces — so understanding how to verify it properly felt essential.

---

## What's here

- `axi_seq_item.sv` — AXI4 transaction object covering both read and write
  channels, with proper burst constraints (INCR, WRAP, length/size alignment)
- `axi_assertions.sv` — SVA assertions that bind to the DUT and catch
  protocol violations (VALID stability, response code legality, WLAST→BVALID ordering)

---

## AXI4 channels verified

```
Write path:  AW (address) → W (data) → B (response)
Read path:   AR (address) → R (data + response)
```

The tricky part with AXI4 is that all 5 channels are independent — a
master can have multiple outstanding transactions, and the slave can
respond out-of-order (with IDs). My testbench handles single-ID
in-order transactions for now.

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
constraint c_size   { size inside {3'b000, 3'b001, 3'b010}; }  // 1/2/4 bytes
constraint c_burst  { burst inside {2'b01, 2'b10}; }           // INCR or WRAP
constraint c_align  { addr[1:0] == 2'b00; }                    // word-aligned
constraint c_len    { len inside {[0:15]}; }                    // short bursts
// WRAP burst length must be power of 2
constraint c_wrap_len {
    if (burst == 2'b10) len inside {1, 3, 7, 15};
}
```

---

## What I want to add next

- Full AXI4 slave model (memory-mapped register file) to verify against
- Out-of-order response support with multiple IDs
- AXI4-Lite variant (simpler, no burst — common for CSR interfaces)
- Formal verification of the VALID stability properties using JasperGold
  (the SVA assertions are already written, just need the formal tool flow)
