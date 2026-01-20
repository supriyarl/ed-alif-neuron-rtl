# Neuron Model – Event-Driven Adaptive LIF (ED-ALIF)

## 1. Overview

This document describes the mathematical and conceptual neuron model implemented by the `ed_alif_neuron` hardware module. The design is an **event-driven Adaptive Leaky Integrate-and-Fire (ALIF)** neuron optimized for FPGA and ASIC implementations.

The model extends the classical LIF neuron by introducing:

* Spike-triggered adaptation
* Input-event-driven decay
* Refractory gating
* Saturating arithmetic
* Event-driven state updates

These mechanisms improve biological realism and hardware efficiency.

---

## 2. State Variables

The neuron maintains two internal state variables:

* **Membrane potential**:
  [ V[t] ]
  Stored in hardware as `V_reg` (signed, `V_WIDTH` bits)

* **Adaptation variable**:
  [ W[t] ]
  Stored in hardware as `W_reg` (unsigned, `W_WIDTH` bits)

The adaptation variable represents spike-frequency adaptation or neuronal fatigue.

---

## 3. Discrete-Time Dynamics

The neuron evolves in discrete time steps when `enable = 1`.

### 3.1 Membrane Potential Update

[
V[t+1] = V[t] + I_{syn}[t] - leak[t] - W[t]
]


This equation integrates synaptic input, subtracts leakage, and applies adaptive negative feedback.

---

### 3.2 Spike Generation Rule


spike[t] = (V[t] \ge V_{th} + W[t]) \land (refract_cnt = 0)


where:

* ( V_{th} ): base firing threshold
* ( W[t] ): adaptive threshold offset
* `refract_cnt`: external refractory counter

The effective firing threshold is:


thresh_{eff}[t] = V_{th} + W[t]


---

### 3.3 Adaptation Update Rule

The adaptation variable evolves according to:

[
W[t+1] =
\begin{cases}
\min(W[t] + B,; W_{max}) & \text{if spike} \
\max(W[t] - D,; 0) & \text{if input_event and no spike} \
W[t] & \text{otherwise}
\end{cases}
]

where:

* ( B ): spike-triggered adaptation increment
* ( D ): decay step on input event
* ( W_{max} = 2^{W_{WIDTH}} - 1 ): saturation limit

This rule models spike-frequency adaptation and recovery.

---

## 4. Refractory Mechanism

The neuron is prevented from firing during a refractory period.

[
spike[t] = (V[t] \ge thresh_{eff}[t]) \land (refract_cnt = 0)
]

The refractory counter is managed externally, allowing flexible refractory durations per neuron or per network.

---

## 5. Event-Driven Operation

State updates occur only when:

```
enable = 1
```

If `enable = 0`, both ( V[t] ) and ( W[t] ) retain their previous values.

This reduces unnecessary switching activity and lowers power consumption in large neuromorphic arrays.

---

## 6. Saturating Arithmetic

To ensure numerical stability and hardware safety:

* ( V[t] ) is clamped implicitly by fixed-width signed arithmetic
* ( W[t] ) is explicitly saturated:

  * Upper bound: ( W_{max} )
  * Lower bound: 0

This prevents overflow under strong excitation or repeated spiking.

---

## 7. Relationship to Classical LIF

| Feature     | Classical LIF    | ED-ALIF                     |
| ----------- | ---------------- | --------------------------- |
| Threshold   | Constant         | Adaptive: ( V_{th} + W[t] ) |
| Adaptation  | None             | Spike-triggered + decay     |
| Refractory  | Optional         | Mandatory gating            |
| Update Mode | Clock-driven     | Event-driven (`enable`)     |
| Arithmetic  | Wrap-around risk | Saturating                  |

---

## 8. Interpretation of the Adaptation Variable W[t]

The adaptation variable can be interpreted as:

* A slow potassium current
* A dynamic threshold offset
* A fatigue or refractoriness memory

Functional role:

* Increases after each spike
* Raises firing threshold
* Reduces membrane potential
* Decays slowly back to zero

This enforces realistic firing patterns such as:

* Spike-frequency adaptation
* Burst suppression
* Regularized firing rates

---

## 9. Summary

The ED-ALIF neuron model implements a biologically inspired, hardware-friendly spiking neuron with:

* Adaptive firing behavior
* Event-driven efficiency
* Configurable leakage and thresholds
* External refractory control
* Robust fixed-point arithmetic

This model is well suited for:

* Neuromorphic computing
* Spiking neural network accelerators
* FPGA prototyping
* Low-power AI hardware

---

## 10. References

* Gerstner, W., Kistler, W. M., Naud, R., & Paninski, L. (2014). *Neuronal Dynamics: From Single Neurons to Networks and Models of Cognition*. Cambridge University Press.

* Pfeil, T., et al. (2013). *Six networks on a universal neuromorphic computing substrate*. Frontiers in Neuroscience.
