# PLL Generator
This page gives an overview of how the PLL Generator (PLL-gen) works internally in OpenFASoC.

## Working and Block diagram
-----------------------------
A Phase locked loop(PLL) mainly consists of the following four blocks:-
```
1. Phase Detector(PD)
2. Charge Pump (CP)
3. Voltage Controlled Oscillator (VCO)
4. Frequency Divider (FD)
```
**1.Phase Detector:-**
