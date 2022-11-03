Verilog generation
------------------

Running ``make sky130hd_temp`` (temp for "temperature sensor") executes the [temp-sense-gen.py](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/tools/temp-sense-gen.py) script from temp-sense-gen/tools/. 
This file takes the input specifications from [test.json](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/test.json) and outputs Verilog files containing the description of the circuit.
