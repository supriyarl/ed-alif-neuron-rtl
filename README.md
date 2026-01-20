# Event-Driven Adaptive LIF (ALIF) Neuron – Hardware Implementation

## Overview

This repository contains a parameterizable, event-driven hardware implementation of an **Adaptive Leaky Integrate-and-Fire (ALIF)** neuron. The design targets neuromorphic accelerators and spiking neural network (SNN) systems, with a focus on low-power, sparse-activity operation and hardware efficiency.

The neuron extends the standard LIF model with a dynamic **adaptation state (W)** that implements spike-frequency adaptation. This introduces biologically inspired negative feedback, improving temporal coding, stability, and representational capacity in SNNs.

---

## Key Features

* **Event-Driven Operation**
  Internal state updates occur only when `enable = 1` (i.e., when an input spike or event is present). This reduces unnecessary switching activity and power consumption.

* **Adaptive Threshold / Fatigue Mechanism**
  Implements a dynamic adaptation variable `W[t]` that increases on each output spike and decays otherwise. This raises the effective firing threshold and subtracts from membrane potential.

* **Saturating Arithmetic**
  Prevents overflow and underflow in both membrane voltage and adaptation state using min/max clamps.

* **Fully Parameterizable**

  * Membrane voltage bit width
  * Adaptation state bit width
  * Leakage factor
  * Threshold and reset values
  * Adaptation increment `B` and decay `D`
  * Maximum adaptation `W_max`

* **Refractory Support**
  A refractory counter disables spiking for a programmable number of cycles after a spike.

---

## Neuron Model

The hardware implements the following discrete-time ALIF equations:

### Membrane Update

V[t+1] = V[t] + I_syn[t] − leak[t] − W[t]

Where:

* `V[t]` is the membrane voltage
* `I_syn[t]` is the synaptic input current
* `leak[t]` is the leakage term
* `W[t]` is the adaptation state

---

### Adaptation State Update

W[t+1] =

* min(W[t] + B, W_max)       if spike
* max(W[t] − D, 0)           if input_event and no spike
* W[t]                       otherwise

Where:

* `B` is the adaptation increment on spike
* `D` is the decay amount per input event
* `W_max` is the saturation limit

---

### Spike Generation

spike[t] = (V[t] ≥ V_th + W[t]) AND (refract_cnt == 0)

Where:

* `V_th` is the base threshold
* `refract_cnt` is the refractory counter

---

## Interpretation of the Adaptation Variable (W)

The adaptation variable `W[t]` models spike-frequency adaptation:

* Each time the neuron fires, `W[t]` increases by `B`.
* This raises the effective firing threshold and subtracts from membrane voltage.
* As a result, rapid repeated firing becomes progressively harder.
* When no spike occurs, `W[t]` decays by `D` toward zero.

This creates a biologically inspired negative feedback loop that stabilizes firing rates and enhances temporal selectivity.

---

## Design Philosophy

This implementation is optimized for neuromorphic and edge-AI hardware:

* Sparse computation through event-driven updates
* Minimal control logic
* Deterministic, clocked behavior
* Bit-accurate fixed-point arithmetic
* Clean separation between datapath and control

The design is suitable for:

* FPGA prototyping
* ASIC integration
* Large-scale neuromorphic cores

---

## Repository Structure

```
.
├── rtl/
│   ├── alif_neuron.sv        # Top-level ALIF neuron module
│   ├── membrane_update.sv   # Membrane voltage datapath
│   ├── adaptation_update.sv # W[t] update logic
│   ├── spike_logic.sv       # Threshold and spike generation
│   └── refractory.sv        # Refractory counter
│
├── tb/
│   ├── alif_tb.sv            # Testbench
│   └── stimuli.mem          # Input stimulus file
│
├── docs/
│   ├── neuron_model.md      # Mathematical model description
│   ├── rtl_architecture.md  # RTL block-level architecture
│   └── baseline_vs_event_driven.md
│
└── README.md
```

---

## Typical Parameter Set (Example)

| Parameter | Description                   | Example |
| --------- | ----------------------------- | ------- |
| V_WIDTH   | Membrane voltage width        | 16 bits |
| W_WIDTH   | Adaptation state width        | 12 bits |
| V_th      | Base threshold                | 1024    |
| V_reset   | Reset voltage                 | 0       |
| B         | Adaptation increment on spike | 16      |
| D         | Adaptation decay per event    | 1       |
| W_max     | Maximum adaptation value      | 1023    |
| leak      | Leak per timestep             | 2       |
| T_ref     | Refractory period (cycles)    | 4       |

---

## Applications

* Spiking Neural Networks (SNNs)
* Event-based vision processing
* Neuromorphic SoCs
* Low-power temporal inference
* Brain-inspired accelerators

---

## Future Work

* Multi-neuron vectorized core
* On-chip learning support (STDP / e-prop)
* AXI / SPI configuration interface
* Sparse synapse memory integration
* Mixed-precision support

---

## License

This project is released under the MIT License.

---

## Citation

If you use this design in academic or research work, please cite this repository.

---

## Author

Supriya R L
Bachelor of Engineering – Electronics and Communication Engineering

---

## Contact

* Email: [supriyarl.ece2023@citchennai.net](mailto:supriyarl.ece2023@citchennai.net)
* GitHub: [https://github.com/supriyarl](https://github.com/supriyarl)
* LinkedIn: [https://www.linkedin.com/in/supriya-rl-408119291](https://www.linkedin.com/in/supriya-rl-408119291)
