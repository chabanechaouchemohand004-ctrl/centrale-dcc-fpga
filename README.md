# DCC command station on FPGA (Basys 3): VHDL core, AXI4-Lite IP, MicroBlaze in C

A DCC command station (NMRA S-9.1 / S-9.2) for model trains on a Digilent Basys 3 (Artix-7 XC7A35T, 100 MHz). Master 1 SYSCOM project, Sorbonne Université, UE FPGA1 (MU4IN108), March to May 2026.

- **Tools:** Vivado 2020.2 (synthesis, implementation, IP Integrator), Vitis (bare-metal C), GHDL 4.1 (testbenches), gcc (C unit tests).
- **Flow:** Phase 1, pure VHDL with frames selected on the switches. Phase 2, the same core wrapped as an AXI4-Lite IP in a MicroBlaze SoC, with C software building the frames.
- **Result:** locomotive driven on the lab layout in both phases (horn, speed up, slow down, 2-byte F13 frame). Phase 1: WNS +6.342 ns, 104 LUTs. Phase 2: WNS +1.843 ns, 1 656 LUTs.

The original version ran on the board. This repo holds the code after post-delivery fixes, checked by 6 GHDL testbenches and 18 C unit tests: exact 58/100 µs bit timing, edge-triggered AXI validation, NMRA speed-step encoding, reverse-direction byte.

## 1. DCC signal

A bit is coded by its duration: `1` = 58 µs low + 58 µs high, `0` = 100 µs low + 100 µs high. Frames of 51 bits (preamble, address, 1 or 2 command bytes, XOR checksum, stop bit) repeat every 6 ms. A booster amplifies the signal to the rails.

![DCC bit timing](docs/img/fig01_chronogrammes_bits.png)

![Frame structure, 1 and 2 command bytes](docs/img/fig06_structure_trames.png)

![Basys 3 connections](docs/img/fig00_carte_basys3.png)

| Signal | Pin | Board element |
| --- | --- | --- |
| `CLK_100MHz` | W5 | 100 MHz clock |
| `Reset` | U18 | BTNC |
| `Interrupteur[7:0]` | W13, W14, V15, W15, W17, W16, V16, V17 | SW7 to SW0 |
| `Sortie_DCC` | B16 | PMOD JB, pin 4 |

## 2. Phase 1: VHDL core

![Core architecture](docs/img/fig10_architecture_top_dcc.png)

| Module | Role |
| --- | --- |
| `DCC_Bit_0`, `DCC_Bit_1` | Bit generators: 4-state Moore FSM + µs counter, `Go`/`Fin` handshake |
| `Registre_DCC` | 51-bit shift register, parallel load, MSB first |
| `MAE_DCC` | Global 7-state FSM: LOAD → READ_BIT → GEN → RELACHE → SHIFT (×50) → TEMPO 6 ms |
| `Clk_Div`, `Compteur_Tempo` | 1 µs tick and inter-frame delay |
| `Generateur_Trames` | Phase 1 only: 9 precomputed frames selected by SW7..SW0 |

![Bit generator FSM](docs/img/fig02_mae_bits.png)

![Global FSM](docs/img/fig09_mae_globale.png)

Phase 1 frames, locomotive address 3:

| Switch | Command | Command byte(s) | Checksum | Frame (51 bits, hex) |
| --- | --- | --- | --- | --- |
| SW7 | Forward, step 10 | `01110110` | `01110101` | `7FFFFF019D8EB` |
| SW6 | Reverse, step 10 | `01010110` | `01010101` | `7FFFFF01958AB` |
| SW5 | Lights ON (F0) | `10010000` | `10010011` | `7FFFFF01A4127` |
| SW4 | Lights OFF (F0) | `10000000` | `10000011` | `7FFFFF01A0107` |
| SW3 | Horn ON (F11) | `10100100` | `10100111` | `7FFFFF01A914F` |
| SW2 | Horn OFF (F11) | `10100000` | `10100011` | `7FFFFF01A8147` |
| SW1 | F13 ON | `11011110` `00000001` | `11011100` | `7FFE036F005B9` |
| SW0 | F13 OFF | `11011110` `00000000` | `11011101` | `7FFE036F001BB` |
| none | Stop (default) | `01100000` | `01100011` | `7FFFFF01980C7` |

## 3. Phase 2: AXI4-Lite IP and MicroBlaze SoC

![Phase 2 architecture](docs/img/fig12_architecture_phase2.png)

![AXI4-Lite wrapper](docs/img/fig13_wrapper_axi.png)

| Register | Offset | Role |
| --- | --- | --- |
| `REG0` | `0x00` | frame bits 31..0 |
| `REG1` | `0x04` | frame bits 50..32 |
| `REG2` | `0x08` | bit 0: validation (rising edge) |

![MicroBlaze system](docs/img/fig15_systeme_microblaze.png)

**Block design in Vivado IP Integrator**

![Block design after connection automation](docs/img/fig15c_connection_automation.png)

| Peripheral | Base address | Range |
| --- | --- | --- |
| `Centrale_DCC_0` | `0x44A0_0000` | 64 KB |
| `gpio_led` | `0x4000_0000` | 64 KB |
| `gpio_btn` | `0x4001_0000` | 64 KB |
| `gpio_sw` | `0x4002_0000` | 64 KB |
| Local memory | `0x0000_0000` | 32 KB |

![Address Editor](docs/img/fig17_address_editor.png)

**Software** (`sw/`): reads SW[7:0] (command) and SW[12:8] (speed step 0-28), builds the frame, sends it on a BTNU rising edge, prints the command on the UART console.

![main.c flowchart](docs/img/fig19_organigramme_main.png)

| Step | C call | Effect in the IP |
| --- | --- | --- |
| 1 | `CENTRALE_DCC_mWriteReg(base, REG0, trame_low)` | bits 31..0 |
| 2 | `CENTRALE_DCC_mWriteReg(base, REG1, trame_high)` | bits 50..32 |
| 3 | `CENTRALE_DCC_mWriteReg(base, REG2, 1)` | rising edge: frame latched |
| 4 | `CENTRALE_DCC_mWriteReg(base, REG2, 0)` | validation re-armed |

## 4. Design choices

- **Single 100 MHz clock domain.** The 1 MHz signal is only an edge-detected enable tick. Counters clocked at 1 MHz missed resets coming from the 100 MHz FSM.
- **Edge-triggered validation.** The core takes a new frame only on the rising edge of `REG2(0)` and keeps sending the old one meanwhile, so a half-written frame never goes out.
- **Stop frame at reset.** The IP sends a stop frame for address 3 until the software validates a first frame.

## 5. Verification

| Testbench | What it checks |
| --- | --- |
| `TB_DCC_Bit_0`, `TB_DCC_Bit_1` | Idle after reset, phase levels, `Go`/`Fin` handshake (assertions) |
| `TB_Registre_DCC` | Load, 51 shifts, MSB-first order |
| `TB_Generateur_Trames` | All 9 frames, bit by bit |
| `TB_Top_DCC_Auto` | **Full system, self-checking:** decodes `Sortie_DCC`, checks NMRA S-9.1 half-period timing, compares each frame with an independently computed one |
| `TB_Centrale_DCC_AXI` | **Full IP through real AXI4-Lite transactions:** stop frame at reset, no effect without validation, edge validation, flag held at 1 |
| `sw/test/test_dcc_frame.c` | C frame builder produces exactly the Phase 1 frames (18 tests) |

GHDL measures **58.00 µs / 100.00 µs** half-periods (NMRA S-9.1 transmitter window: 55-61 µs / 95-9 900 µs).

**Vivado simulations** (original version, constants 57/99):

![TB_DCC_BIT_0](docs/img/sim_tb_dcc_bit_0.png)

![TB_DCC_BIT_1](docs/img/fig04_sim_tb_dcc_bit_1.png)

![TB_Generateur_Trames](docs/img/fig07_sim_tb_generateur_trames.png)

![TB_Registre_DCC: 51 shifts of 7FFFFF019D8EB](docs/img/fig08_sim_tb_registre_dcc.png)

## 6. Implementation results (Vivado 2020.2, 100 MHz)

| Metric | Phase 1 (`TOP_DCC`) | Phase 2 (`systeme_dcc_wrapper`) |
| --- | --- | --- |
| Worst negative slack | **+6.342 ns** | **+1.843 ns** |
| Worst hold slack | +0.147 ns | +0.056 ns |
| Slice LUTs | 104 (0.50 %) | 1 656 (7.96 %) |
| Slice registers | 101 (0.24 %) | 1 881 (4.52 %) |
| Block RAM | 0 | 8 tiles (16 %) |
| Latches | 0 | 0 |

Report extracts in `docs/reports/`.

## Run the checks

```bash
./sim/run_sim.sh                       # GHDL, all 6 testbenches
cd sw/test && gcc -Wall -Wextra -I.. test_dcc_frame.c ../dcc_frame.c -o test && ./test
```

## Repository layout

```text
rtl/core/          DCC core shared by both phases
rtl/phase1/        Phase 1 top and frame generator
ip/Centrale_DCC/   AXI4-Lite wrapper
sim/               testbenches and GHDL script
constraints/       Phase 1 and Phase 2 XDC (Basys 3)
sw/                MicroBlaze application and frame builder (portable C)
sw/test/           C unit tests on PC
docs/img/          figures
docs/reports/      Vivado timing and utilization extracts
build_phase1.tcl   Phase 1 Vivado batch script
```

## Credits

Project done alone (VHDL, MicroBlaze integration, C, simulation, board tests); the report was handed in as a pair. The course provided the interfaces, the structure and two modules (`Clk_Div`, `Compteur_Tempo`); the repo has my own versions with the same ports.
