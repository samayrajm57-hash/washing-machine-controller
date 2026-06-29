# Washing Machine Controller (Verilog HDL)

![Language](https://img.shields.io/badge/HDL-Verilog-blue)
![Type](https://img.shields.io/badge/Design-FSM%20%2B%20Datapath-green)
![Simulation](https://img.shields.io/badge/Sim-Icarus%20Verilog-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A synthesizable **finite-state-machine controller** for an automatic washing
machine, written in Verilog HDL. The design sequences a full wash cycle —
*fill → wash → drain → rinse → spin* — driving the water valve, wash/spin
motors and drain pump, with a door-closed safety interlock and a clean
control/datapath split.

---

## Highlights

- **7-state Moore FSM** (`IDLE, FILL_WATER, WASH, DRAIN, RINSE, SPIN, COMPLETE`)
- **Control/datapath separation** — FSM decides *what & how long*; a reusable
  parameterized timer measures the time
- **Fully parameterized** phase durations → same RTL for simulation and silicon
- **Synchronous, single-clock** design with active-high reset
- **Self-checking testbench** (safety interlock, full cycle, mid-cycle reset)
- 100% **synthesizable** — no delays or `initial` blocks in the RTL

---

## State Machine

```
              start & door_closed
   IDLE  ───────────────────────►  FILL_WATER   (water_valve)
    ▲                                   │ timer_done
    │                                   ▼
    │                                 WASH        (motor_wash)
    │                                   │ timer_done
    │                                   ▼
    │                                 DRAIN       (drain_pump)
    │                                   │ timer_done
    │                                   ▼
    │                                 RINSE       (water_valve + motor_wash)
    │                                   │ timer_done
    │                                   ▼
    │                                 SPIN        (motor_spin + drain_pump)
    │            timer_done             │ timer_done
    └──────────────────────────────  COMPLETE    (done)
```

---

## Repository Structure

```
washing-machine-controller/
├── rtl/
│   ├── timer.v                 # reusable down-counter (datapath)
│   ├── wm_fsm.v                # Moore control FSM
│   └── washing_machine_top.v   # top level (FSM + timer)
├── tb/
│   └── tb_washing_machine.v    # self-checking testbench
├── docs/
│   └── washing_machine_controller_guide.md   # full design + interview guide
├── .gitignore
├── LICENSE
└── README.md
```

---

## How to Run

### Option A — Online (no install)
1. Open [EDA Playground](https://www.edaplayground.com).
2. Paste all four `.v` files (from `rtl/` and `tb/`).
3. Tools & Simulators → **Icarus Verilog**; tick **Open EPWave after run**.
4. Set top to `tb_washing_machine` and click **Run**.

### Option B — Local (Icarus Verilog)
```bash
iverilog -o wm_sim rtl/timer.v rtl/wm_fsm.v rtl/washing_machine_top.v tb/tb_washing_machine.v
vvp wm_sim          # prints PASS messages + state trace
gtkwave wm.vcd      # optional waveform
```

---

## Sample Output

```
TEST1 PASS: stayed IDLE with door open.
 65000  FILL_WATER    1     0    0     0    0
 95000  WASH          0     1    0     0    0
135000  DRAIN         0     0    1     0    0
165000  RINSE         1     1    0     0    0
195000  SPIN          0     0    1     1    0
235000  COMPLETE      0     0    0     0    1
TEST2 PASS: returned to IDLE
TEST3 PASS: reset forced IDLE.
```

---

## I/O Summary

| Inputs | | Outputs | |
|---|---|---|---|
| `clk` | system clock | `water_valve` | inlet valve |
| `rst` | sync, active-high | `motor_wash` | wash-speed motor |
| `start` | begin cycle | `drain_pump` | drain pump |
| `door_closed` | safety interlock | `motor_spin` | spin-speed motor |
| | | `done` | cycle complete |
| | | `state_out[2:0]` | current state (debug) |

---

## Possible Extensions

Pause/resume, multiple wash modes, water-level sensor, fault detection,
child lock, door lock during run, buzzer, LCD display, and power-failure
recovery — design notes for each are in [`docs/`](docs/washing_machine_controller_guide.md).

---

## Author

*Your Name* — Electrical Engineering · [GitHub](https://github.com/your-username)

## License

Released under the MIT License — see [LICENSE](LICENSE).
