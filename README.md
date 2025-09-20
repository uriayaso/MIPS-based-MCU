# MIPS-Based MCU

## Introduction
A **MIPS-based microcontroller** implemented in **VHDL** on the DE10-Standard FPGA board.  
The design features a **single-cycle MIPS CPU core** with Harvard architecture, **memory-mapped I/O**, and **interrupt support**.  
Additional peripherals include a **Timer**, **FIR accelerator**, and **UART** for PC communication.  
The system was simulated in ModelSim and synthesized in Quartus for FPGA deployment.

## Features
- **MIPS Single-Cycle CPU**: Executes the simple MIPS ISA instruction set.  
- **Memory-Mapped I/O**: Controls LEDs, switches, and seven-segment displays.  
- **Interrupt Controller**: Supports multiple interrupt sources with defined service protocol.  
- **Timer Peripheral**: Provides output compare and timing functions.  
- **FIR Accelerator**: Hardware module with FIFO for signal processing.  
- **UART**: RS-232 communication with PC.  
- **FPGA Implementation**: Verified in simulation and deployed on DE10-Standard.  

## Hardware Components
- **FPGA Board**: Intel/Altera DE10-Standard (Cyclone V SoC).  
- **Inputs**: 10 switches, 4 pushbuttons (KEY3–KEY0).  
- **Outputs**: 10 LEDs (LEDR9–0), 6 seven-segment displays (HEX5–0).  

## Software Components
- **VHDL Sources**: CPU core, memory (ITCM/DTCM), GPIO, Timer, FIR, UART, Interrupt Controller, Top module.  
- **Testbench (VHDL)**: Functional verification using ModelSim with waveform analysis.  
- **Assembly Test Programs**: Compiled in MARS simulator and executed on the CPU.  
- **Quartus Project Files**: Timing constraints, pin assignments, and FPGA synthesis.  
