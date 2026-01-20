# ED-ALIF Neuron Hardware Architecture

This document describes the register-transfer level (RTL) architecture of the Event-Driven Adaptive Leaky Integrate-and-Fire (ED-ALIF) neuron implemented in `ed_alif_neuron.sv`. It maps the biological neuron model and discrete-time equations to concrete digital hardware blocks suitable for FPGA and ASIC implementations.

---

## 1. High-Level Overview

The ED-ALIF neuron consists of four major functional subsystems:

1. **State Registers**

   * Membrane potential register (`V_reg`)
   * Adaptation register (`W_reg`)

2. **Combinational Datapath**

   * Leak computation
   * Effective threshold computation
   * Membrane integration logic

3. **Spike Generation Logic**

   * Threshold comparator
   * Refractory gating

4. **Next-State Update Logic**

   * Reset on spike
   * Adaptation increment and decay
   * Event-driven enable gating

---

## 2. Top-Level Interface

### Inputs

| Signal        | Width   | Description                                    |
| ------------- | ------- | ---------------------------------------------- |
| `clk`         | 1       | System clock                                   |
| `rst`         | 1       | Synchronous reset                              |
| `enable`      | 1       | Neuron update enable (event-driven scheduling) |
| `I_syn`       | V_WIDTH | Signed synaptic input current                  |
| `V_th`        | V_WIDTH | Base firing threshold                          |
| `V_reset`     | V_WIDTH | Reset voltage after spike                      |
| `B`           | W_WIDTH | Adaptation increment on spike                  |
| `D`           | W_WIDTH | Adaptation decay on input event                |
| `input_event` | 1       | Indicates presynaptic activity                 |
| `refract_cnt` | 4       | External refractory counter                    |

### Outputs

| Signal  | Width   | Description              |
| ------- | ------- | ------------------------ |
| `spike` | 1       | Output spike event       |
| `V_out` | V_WIDTH | Current membrane voltage |
| `W_out` | W_WIDTH | Current adaptation state |

---

## 3. Internal State Registers

### 3.1 Membrane Potential Register (`V_reg`)

* Type: Signed
* Width: `V_WIDTH`
* Function:

  * Stores the current membrane potential V[t]
  * Updated on each scheduled neuron cycle (`enable = 1`)
  * Reset to `V_INIT` on synchronous reset

### 3.2 Adaptation Register (`W_reg`)

* Type: Unsigned
* Width: `W_WIDTH`
* Function:

  * Stores the adaptive threshold offset W[t]
  * Increased on spike by B
  * Decreased on input events by D
  * Saturated to prevent overflow
  * Reset to `W_INIT` on synchronous reset

---

## 4. Combinational Datapath

### 4.1 Leak Computation

The leak term implements exponential decay using a shift operation:

```
leak = V_reg >>> LEAK_SHIFT
```

* Arithmetic right shift preserves sign
* `LEAK_SHIFT` controls the decay constant
* Avoids multipliers and dividers

---

### 4.2 Effective Threshold Generation

The firing threshold is dynamically modulated using adaptation:

```
thresh_eff = V_th + W_reg
```

* Implemented using sign extension and addition
* Extra MSB used to avoid overflow

---

### 4.3 Membrane Integration Logic

The membrane voltage integrator computes:

```
V_int = V_reg + I_syn - leak - W_reg
```

* Adds synaptic input
* Subtracts leak
* Subtracts adaptation current
* Produces the candidate next voltage

---

## 5. Spike Generation Logic

A spike is generated only when all conditions are met:

```
spike = enable && (V_int >= thresh_eff) && (refract_cnt == 0)
```

### Components

1. Comparator: `V_int >= thresh_eff`
2. Refractory gate: `refract_cnt == 0`
3. Scheduler gate: `enable == 1`

---

## 6. Next-State Update Logic

### 6.1 Voltage Update

| Condition | V_next       |
| --------- | ------------ |
| Spike     | `V_reset`    |
| No spike  | `V_int`      |
| enable=0  | Hold `V_reg` |

---

### 6.2 Adaptation Update

| Condition              | W_next                  |
| ---------------------- | ----------------------- |
| Spike                  | `min(W_reg + B, W_max)` |
| input_event & no spike | `max(W_reg - D, 0)`     |
| Otherwise              | Hold `W_reg`            |

* Saturation prevents overflow
* Decay only occurs when an input arrives

---

## 7. Event-Driven Enable Gating

All state updates are gated by the `enable` signal:

* When `enable = 0`:

  * `V_reg` and `W_reg` hold their values
  * No switching activity

* When `enable = 1`:

  * Full neuron update is performed

This supports sparse, event-driven neuromorphic scheduling.

---

## 8. Saturating Arithmetic

### 8.1 Adaptation Saturation

```
W_next = (W_reg + B > W_max) ? W_max : (W_reg + B)
```

* Prevents wrap-around on repeated spiking

### 8.2 Membrane Range

* `V_reg` and `V_int` are limited by `V_WIDTH`
* Natural two’s-complement truncation
* Prevents unrealistic growth under large synaptic input

---

## 9. External Refractory Counter Interface

The refractory logic is externally managed:

* `refract_cnt` is decremented by an external controller
* Neuron checks only:

```
refract_cnt == 0
```

This allows flexible refractory policies at the network level.

---

## 10. Mapping to Biological Interpretation

| Hardware Block | Biological Meaning         |
| -------------- | -------------------------- |
| `V_reg`        | Membrane potential         |
| `leak`         | Passive ion leakage        |
| `I_syn`        | Synaptic current           |
| `W_reg`        | Spike-frequency adaptation |
| `thresh_eff`   | Dynamic firing threshold   |
| `spike`        | Action potential           |
| `refract_cnt`  | Absolute refractory period |

---

## 11. Scalability and Integration

* Parameterizable bit-widths
* Fully synthesizable
* Suitable for:

  * Large neuron arrays
  * SNN accelerators
  * Neuromorphic SoCs

---

## 12. Summary

The ED-ALIF neuron RTL architecture:

* Implements biologically realistic adaptive spiking
* Uses only adders, shifters, and comparators
* Supports event-driven execution
* Provides clean separation of datapath and control
* Enables scalable FPGA and ASIC integration

---

## 13. References

* Gerstner, W., Kistler, W. M., Naud, R., & Paninski, L. (2014). *Neuronal Dynamics*. Cambridge University Press.
* Pfeil, T., et al. (2013). Six networks on a universal neuromorphic computing substrate. *Frontiers in Neuroscience*.
