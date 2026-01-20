# Baseline vs Event-Driven ED-ALIF Neuron

## 1. Introduction

This document compares a conventional clock-driven (baseline) Leaky Integrate-and-Fire (LIF) neuron implementation with the proposed Event-Driven Adaptive LIF (ED-ALIF) neuron hardware. The comparison highlights architectural, functional, and energy-efficiency differences relevant to FPGA and ASIC neuromorphic systems.

---
## 2. Baseline Clock-Driven LIF Neuron

### 2.1 Characteristics

A baseline LIF neuron updates its internal membrane voltage at every clock cycle, regardless of whether meaningful activity is present.

Key properties:
- Continuous-time approximation via fixed time-step updates
- Constant firing threshold
- No intrinsic adaptation
- No refractory gating (or fixed simple refractory)
- No event-awareness

### 2.2 Discrete-Time Model

V[t+1] = V[t] + I_syn[t] - (V[t] >> L)

Spike rule:

spike[t] = (V[t] >= V_th)

Reset on spike:

V[t+1] = V_reset

### 2.3 Hardware Implications

- Arithmetic units toggle every cycle
- High dynamic power consumption
- Unnecessary switching when I_syn = 0
- Poor scalability for large neuron arrays

---
## 3. Event-Driven Adaptive LIF (ED-ALIF) Neuron

The ED-ALIF neuron extends the classical LIF model with three major features:

1. Event-driven state updates
2. Spike-triggered adaptation
3. Refractory gating

### 3.1 State Variables

- V[t] : membrane voltage
- W[t] : adaptation variable

### 3.2 Discrete-Time Dynamics

Membrane update:

V_int = V[t] + I_syn[t] - (V[t] >> L) - W[t]

Adaptive threshold:

thresh_eff = V_th + W[t]

Spike rule with refractory:

spike[t] = enable · (V_int >= thresh_eff) · (refract_cnt == 0)

Voltage reset on spike:

V[t+1] = V_reset

Adaptation update:

If spike:
    W[t+1] = sat(W[t] + B)
Else if input_event:
    W[t+1] = max(W[t] - D, 0)
Else:
    W[t+1] = W[t]

---
## 4. Event-Driven Execution Model

### 4.1 Baseline Execution

In a clock-driven design:

- V and W are updated at every clock edge
- Computation occurs even when no synaptic input is present

### 4.2 ED-ALIF Execution

In the ED-ALIF design:

- State updates occur only when enable = 1
- enable is asserted only when the neuron is scheduled or receives an event

Result:

- Zero switching when idle
- Reduced dynamic power
- Increased scalability

---
## 5. Adaptation vs No Adaptation

| Feature              | Baseline LIF | ED-ALIF |
|----------------------|--------------|---------|
| Threshold            | Constant     | Adaptive (V_th + W) |
| Spike fatigue        | No           | Yes |
| Firing rate control  | External     | Intrinsic |
| Burst suppression    | No           | Yes |

---
## 6. Refractory Handling

| Feature              | Baseline LIF | ED-ALIF |
|----------------------|--------------|---------|
| Refractory           | Optional / fixed | External programmable |
| Spike gating         | No           | Yes |
| High-frequency spikes| Allowed      | Prevented |

---
## 7. Saturation and Numerical Safety

| Feature           | Baseline LIF | ED-ALIF |
|-------------------|--------------|---------|
| Overflow handling | Wrap-around  | Saturation |
| Voltage clamp     | No           | Yes |
| Adaptation clamp  | No           | Yes |

---
## 8. Hardware Cost vs Efficiency

| Metric              | Baseline LIF | ED-ALIF |
|---------------------|--------------|---------|
| Adders              | 1–2          | 2–3 |
| Registers           | 1            | 2 |
| Power consumption   | High         | Low |
| Scalability         | Limited      | High |

---
## 9. System-Level Impact

| Dimension        | Baseline LIF | ED-ALIF |
|------------------|--------------|---------|
| Biological realism | Low          | High |
| Stability         | Medium       | High |
| Energy efficiency | Low          | High |
| SNN suitability   | Basic        | Advanced |

---
## 10. Summary

The Event-Driven Adaptive LIF (ED-ALIF) neuron provides a strict superset of the classical LIF model:

- Reduces switching activity via event-driven updates
- Prevents pathological spiking using refractory gating
- Enables spike-frequency adaptation via W[t]
- Improves numerical robustness via saturating arithmetic
- Enables scalable neuromorphic hardware

As a result, ED-ALIF is significantly more suitable for:

- FPGA-based SNN accelerators
- Low-power neuromorphic SoCs
- Large-scale event-driven neural arrays

---
## 11. References

1. Gerstner, W., Kistler, W.M., Naud, R., & Paninski, L. *Neuronal Dynamics*. Cambridge University Press, 2014.
2. Pfeil, T., et al. *Six networks on a universal neuromorphic computing substrate*. Frontiers in Neuroscience, 2013.

