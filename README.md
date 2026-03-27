# RISC-V Processor (Verilog Implementation)

## 📌 Overview

This project implements a **basic RISC-V processor** in Verilog HDL. It supports a subset of the **RV32I instruction set** and includes instruction fetch, execution, memory access, and write-back stages using a finite state machine (FSM).

The design is simple, modular, and suitable for learning purposes, simulation, and further extensions.

---

## ⚙️ Features

* 32-bit RISC-V processor (RV32I subset)
* 32 general-purpose registers
* FSM-based control unit
* Supports:

  * Arithmetic & Logic Instructions (R-type, I-type)
  * Load Instructions (LB, LH, LW, LBU, LHU)
  * Store Instructions (SB, SH, SW)
  * Branch Instructions (BEQ, BNE, BLT, BGE, etc.)
  * Jump Instructions (JAL, JALR)
  * Upper Immediate Instructions (LUI, AUIPC)
* Memory interface with read/write handshake signals
* Byte and halfword memory access support

---

## 🧠 Architecture

The processor operates using a **Finite State Machine (FSM)** with the following states:

| State              | Description                         |
| ------------------ | ----------------------------------- |
| `S_fetch_wait`     | Waits for instruction fetch         |
| `S_execute`        | Decodes and executes instruction    |
| `S_mem_read_wait`  | Waits for memory read completion    |
| `S_mem_wb`         | Writes loaded data back to register |
| `S_mem_write_wait` | Waits for memory write completion   |

---

## 📂 Module Interface

### Inputs

* `clk` : Clock signal
* `reset` : Active-low reset
* `mem_rdata` : Data read from memory
* `mem_rbusy` : Memory read busy signal
* `mem_wbusy` : Memory write busy signal

### Outputs

* `mem_addr` : Memory address
* `mem_wdata` : Data to write to memory
* `mem_wmask` : Write mask (byte-level control)
* `mem_rstrb` : Read strobe signal

---

## 🔄 Instruction Flow

1. **Fetch**

   * Instruction is fetched from memory using `program_counter`.

2. **Decode & Execute**

   * Instruction fields (opcode, funct3, funct7) are decoded.
   * ALU performs the required operation.

3. **Memory Access**

   * Load/store instructions interact with memory.

4. **Write Back**

   * Results are written back to the register file.

---

## 🧮 Supported Instructions

### R-Type

* ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

### I-Type

* ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI

### Load

* LB, LH, LW, LBU, LHU

### Store

* SB, SH, SW

### Branch

* BEQ, BNE, BLT, BGE, BLTU, BGEU

### Jump

* JAL, JALR

### Upper Immediate

* LUI, AUIPC

---

## 🧾 Register File

* 32 registers (`x0` to `x31`)
* `x0` is always hardwired to 0

---

## 💾 Memory Interface

* Uses a simple handshake mechanism:

  * `mem_rstrb` initiates a read
  * `mem_rbusy` indicates ongoing read
  * `mem_wbusy` indicates ongoing write
* Supports:

  * Byte-level writes using `mem_wmask`
  * Unaligned accesses (handled via offset logic)

---

## ▶️ How to Use

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/riscv-processor.git
cd riscv-processor
```

### 2. Simulate

Use any Verilog simulator like:

* ModelSim
* Vivado Simulator
* Icarus Verilog

Example (Icarus Verilog):

```bash
iverilog -o riscv.out riscv_processor.v testbench.v
vvp riscv.out
```

### 3. Test

* Provide a memory model or testbench
* Load instructions into memory
* Observe register and memory outputs

---

## 🧪 Testing

You can test the processor using:

* Custom testbench
* RISC-V assembly programs (converted to machine code)
* Memory preload files

---

## 🚀 Future Improvements

* Pipeline implementation (5-stage pipeline)
* Hazard detection and forwarding
* Cache support
* CSR (Control and Status Registers)
* Interrupt handling
* Full RV32I compliance

---

## 📚 Learning Goals

This project helps in understanding:

* RISC-V ISA basics
* Processor design
* FSM-based control logic
* Memory interfacing
* Verilog HDL design practices

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

* Add new instructions
* Optimize performance
* Improve documentation
* Add test cases

---


