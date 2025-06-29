# Sipeed Tang Primer 20K – Dual‑UART Data Exchange

## Overview
The long‑term goal is to build a **bidirectional bridge** that moves framed data between two UART links and, eventually, to experiment with a **custom application‑level protocol** riding over those UARTs.  

* **UART0** – the built‑in FTDI serial port – stays as the primary console.  
* **UART1** – currently a **virtual HDL UART** (`hdl/uartprompt.v`) – lets us debug framing/forwarding logic without extra wiring.

Once the firmware logic is proven, we plan to expose real GW2A pins for the second UART and test the protocol on physical wires.

---

## What has been done

| Stage | Result |
|-------|--------|
| ✔ LiteX SoC built for Tang Primer 20K | 48 MHz system clock, DDR3 enabled, VexRiscv CPU |
| ✔ Kept default console UART (UART0) | still used for printf output |
| ✔ Added **virtual UART1** | pure internal signals, no real pins |
| ✔ Custom Verilog module | `hdl/uartprompt.v` transmits a test byte stream |
| ✔ Software bridge demo | reads frames from UART1, prints hex dump on UART0 |

---

## Attempts & lessons learnt

* **Tried to use spare BL702 pins** on the dock as a second UART.  
  – Could not find an exposed pair mapped to `BL702_UART1_TX/RX`.  
  – Windows saw only one COM port; Linux showed two TTYs but the second belonged to the debug MCU, not GW2A GPIOs.  
* After several wiring/CST iterations we decided to **emulate UART1 in logic**.  
  *Result:* rapid progress on firmware framing without hardware blocks.

---

## Repository layout
```text
sipeed_tang_primer_20k.py  # LiteX target script (root)
hdl/uartprompt.v           # HDL “virtual UART1” generator
firmware/                  # C sources + Makefile (bridge firmware)
```

---

## Build & Flash workflow
ROM size is fixed to **8 KiB (0x8000)**; LiteX must know it twice: first when it generates the linker script, then when it pre‑loads the compiled firmware.

```bash
# 1. Generate gateware + blank 8 KiB ROM (creates regions.ld)
python3 sipeed_tang_primer_20k.py         --integrated-rom-size=0x8000         --build

# 2. Build the C firmware (uses regions.ld from step 1)
make -C firmware            # produces firmware/main.bin

# 3. Build final bitstream with ROM initialised + flash it
python3 sipeed_tang_primer_20k.py         --integrated-rom-size=0x8000         --integrated-rom-init=firmware/main.bin         --build --flash
```

---

## Console access
Use any standard serial‑terminal program with **115200 8‑N‑1, no flow control**:

* **PuTTY** / KiTTY (Windows)
* **minicom** / **screen** (Linux/macOS)

Example session output:

```
frame len = 64
01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10
11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20
21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30
31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F 40
```

---

## Roadmap / Next steps
* **Expose real pins for UART1** – update the constraint file and wire the dock headers.  
* **Full‑duplex bridge** – implement transmission from CPU to UART1.  
* **Custom framing protocol** – add CRC, channel ID, etc.; benchmark throughput and latency.  
* **Ethernet‑over‑UART experiment** – encapsulate minimal UDP/IP frames and benchmark.  
* **CI pipeline** – automatic gateware + firmware builds via GitHub Actions.

## Credits
* *LiteX* and *Migen* – Enjoy‑Digital  
* *VexRiscv* soft‑CPU – Charles Papon  
* *Tang Primer 20K* board – Sipeed  
* Project maintained by **yellow_emperor**
