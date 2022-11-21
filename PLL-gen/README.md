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
**1. Phase Detector:-**
                Phase detector produces two DC voltages namely UP and DOWN, which is proportional to the phase difference between the input signal(Vref) and feedback (output) signal(Vout). If the Vref phase is lagging with respect to Vout then UP signal remains high to the duration of their phase difference and the DOWN signal remains low. If the Vref phase is leading with respect to Vout then DOWN signal remains high to the duration of their phase difference and the UP signal remains low.
                The Phase detector is constructed using two negative edge triggered D Flip-Flops and a AND gate, which makes it a digital block.
                
<img width="445" alt="Screenshot 2022-11-21 at 7 25 32 PM" src="https://user-images.githubusercontent.com/110079631/203073018-1c06be90-d496-4347-851c-4c3b80aae57c.png">

- Lagging Condition shown below:-

<img width="589" alt="Screenshot 2022-11-21 at 7 26 24 PM" src="https://user-images.githubusercontent.com/110079631/203073555-9091d92f-1198-4d12-86f2-4ea532928ddf.png">

**2. Charge Pump:-**
                Charge Pump is used to convert the digital measure of the phase difference done in the Phase Detector into a analog control signal, which is used to control the Voltage Controlled Oscillator in the next stage.
                In the construction of the Charge Pump we use a current steering model which makes it a Analog block. Here when the UP signal is high the current flows from Vdd to output which charges the load capacitance. When the DOWN signal is high the current flows from load capacitance to ground which is discharging of the current.

<img width="336" alt="Screenshot 2022-11-21 at 5 43 39 PM" src="https://user-images.githubusercontent.com/110079631/203073124-c2d463ae-6064-4208-9792-2ce74ebab4af.png">

```
Avg Active time of UP   > Avg Active time of DOWN = Charging of Capacitance     [0-->1]--> Speeds up the VCO
Avg Active time of DOWN > Avg Active time of UP   = Dis-Charging of Capacitance [1-->0]--> Slows down the VCO
```

<img width="346" alt="Screenshot 2022-11-21 at 5 41 39 PM" src="https://user-images.githubusercontent.com/110079631/203073306-3ec3e940-5bbc-4895-82d6-011fe26713cf.png">

**3. Voltage Controlled Oscillator:-**
                  The Output of the Charge Pump acts as a Control signal to the Voltage Controlled Oscillator.The VCO generates a DC signal, the amplitude of which is proportional to the amplitude of output of Charge Pump Control Signal. Here the adjustment in the output frequency/phase of VCO is made until it shows equivalency with the input signal frequency/phase. 
                  The VCO is contructed using two current mirrors and a ring Oscillator which makes it a Analog block. The control signal is used as an input to these current source(mirrors) to control the current supply which in turn control the delay of the circuit. By controlling the delay we are basically controlling the frequency of the Oscillator which makes it frequency flexible.
    
<img width="568" alt="Screenshot 2022-11-21 at 7 30 50 PM" src="https://user-images.githubusercontent.com/110079631/203073888-bce2a8db-3aff-4842-a218-147715ec789a.png">

**4. Frequency Divider:-**
                  Frequency Divider is used to divide the frequency which is otherwise a multiplier in time of the Output voltage from the Voltage Controlled Oscillator and is feedback as an input to the Phase Detector, which is then compared with the Vref input signal in the Phase Detector stage.
                  The Frequency Divider is constructed using a series of Toggle Flip-Flops, which makes it a complete Digital block.

<img width="394" alt="Screenshot 2022-11-21 at 7 26 57 PM" src="https://user-images.githubusercontent.com/110079631/203073982-c36fa793-bf28-4de6-9e77-74e61333a34f.png">

