# ED-ALIF Neuron Model

## 1. Introduction

The **ED-ALIF (Event-Driven Adaptive Leaky Integrate-and-Fire) neuron** is an advanced spiking neuron model designed for digital hardware (FPGA/ASIC).  

It extends the classical LIF neuron by including:

- **Spike-triggered adaptation** (adaptive threshold)  
- **Input-event-driven decay** of adaptation  
- **Refractory gating** to prevent rapid consecutive spikes  
- **Saturating arithmetic** to prevent voltage overflow  

The neuron operates in an **event-driven manner**, updating only when scheduled (`enable` signal is high), reducing switching activity and power consumption.

---

## 2. Membrane Potential Dynamics

The membrane potential evolves according to:

$$
V(t+1) = V(t) + I_\text{syn} - \frac{V(t)}{2^k} - W(t)
$$

Where:

- $V(t)$ = Membrane voltage  
- $I_\text{syn}$ = Synaptic input current  
- $k$ = Leak factor (implemented as `V >> LEAK_SHIFT`)  
- $W(t)$ = Adaptation variable  

**Drawbacks in classical LIF:**

- No adaptation → neuron fires at a constant rate  
- Strong input currents may overflow membrane voltage  

**ED-ALIF Improvements:**

- **Spike-triggered adaptation $W(t)$** prevents overfiring  
- **Wide accumulator + saturation logic** avoids overflow

---

## 3. Adaptive Threshold

The effective threshold is:

$$
\theta_\text{eff}(t) = V_\text{th} + W(t)
$$

Where:

- $V_\text{th}$ = Base threshold  
- $W(t)$ = Adaptation variable  

**Functionality:**

- Threshold increases after spikes to reduce firing probability  
- Threshold recovers gradually via adaptation decay  

---
## 4. Spike Generation

A spike occurs when:

spike = 1, if V_int >= theta_eff and refract_cnt = 0
spike = 0, otherwise

Where `refract_cnt` is the refractory counter preventing immediate consecutive spikes.
 

**Improvement:** Prevents high-frequency spike bursts seen in classical LIF/ALIF neurons.

---

## 5. Post-Spike Updates

On spike occurrence:

$$
\begin{aligned}
V(t+1) &= V_\text{reset} \\
W(t+1) &= \min(W(t) + B, W_\text{max})
\end{aligned}
$$

Where:

- `V_reset` = Membrane reset voltage after spike  
- $B$ = Spike-triggered adaptation increment  
- $W_\text{max}$ = Maximum allowed adaptation (saturation)  

**Purpose:**  

- Resets membrane voltage to prevent immediate re-spike  
- Increases adaptation threshold to avoid overfiring  

---

## 6. Input-Driven Adaptation Decay

On receiving an external spike (input event) without neuron spiking:

$$
W(t+1) = \max(W(t) - D, 0)
$$

Where $D$ = Adaptation decay constant  

**Purpose:**  

- Gradual recovery from adaptation  
- Prevents permanent high threshold  

---

## 7. State Update Algorithm (Code Mapping)

1. **Leak calculation:** `leak = V_reg >>> LEAK_SHIFT`  
2. **Membrane update:** `V_int = V_reg + I_syn - leak - W_reg`  
3. **Saturation:** Clamp `V_int` within `[-2^(V_WIDTH-1), 2^(V_WIDTH-1)-1]`  
4. **Adaptive threshold:** `thresh_eff = V_th + W_reg`  
5. **Spike generation:** `spike = enable && (V_int >= thresh_eff) && (refract_cnt == 0)`  
6. **Next-state logic:**  
    - If spike: `V_next = V_reset`, `W_next = min(W_reg + B, W_max)`  
    - Else: `V_next = V_int`  
        - On `input_event`: `W_next = max(W_reg - D, 0)`  
7. **Register update:** Synchronous on `clk`  
    - `V_reg <= V_next`  
    - `W_reg <= W_next`  

**This mapping corresponds exactly to the RTL code in `rtl/ed_alif_neuron.sv`.**

---

## 8. Drawbacks of Prior Designs and ED-ALIF Solutions

| Limitation | ED-ALIF Solution |
|------------|----------------|
| Voltage overflow with strong input | Wide accumulator + saturating arithmetic |
| Fixed threshold → excessive spikes | Adaptive threshold using `W_reg` |
| No adaptation decay | Decay implemented on `input_event` |
| Continuous firing | Refractory counter gating |
| High switching activity | Event-driven enable-controlled updates |

---

## 9. Newly Added Features

1. **Saturating arithmetic** to prevent overflow  
2. **Event-driven operation** → update only when scheduled  
3. **Spike-triggered adaptation** → dynamically increases threshold  
4. **Input-event adaptation decay** → allows recovery  
5. **Refractory gating** → prevents burst spikes  
6. **Parameterizable design** → `V_WIDTH`, `W_WIDTH`, `LEAK_SHIFT`, `B`, `D`, `V_RESET`  

---

## 10. Summary

The ED-ALIF neuron:

- Implements biologically inspired spike-frequency adaptation  
- Prevents voltage overflow and rapid firing  
- Recovers gradually after input events  
- Fully parameterizable and synthesizable  
- Ideal for FPGA and neuromorphic systems  

This model directly **replicates the functionality in `rtl/ed_alif_neuron.sv`** and documents **all improvements and design decisions**.
