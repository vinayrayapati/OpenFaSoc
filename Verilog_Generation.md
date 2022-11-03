Verilog generation
------------------

Running ``make sky130hd_temp`` (temp for "temperature sensor") executes the [temp-sense-gen.py](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/tools/temp-sense-gen.py) script from temp-sense-gen/tools/. 
`temp-sense-gen.py` calls other modules from temp-sense-gen/tools/ during execution

```
  temp-sense-gen.py
    |-- readparamgen.py-----------------> 1.loads the json file
    |       └── simulation.py             2.Identifies the platforms
    |                                     3.Running checks on user inputs
    |                                     4.Choosing the correct circuit elements
    |-- TEMP_netlist.py-----------------> 1.Reads the verilog templates and required specs.
            └── function.py               2.Modify the verilog templates according to the specs.
                                          3.Write the output verilog files.
```
**Steps happening in readparamgen.py:-**
  1. Identifies the path to the json spec file and the Identifies the platforms.Only sky130hd and sky130hs platforms are supported as of now
  2. Load json spec file:- Runs checks on the json file and following errors are produced on mismatches.
            ```
            Error occurred opening or loading json file.
            Error: Generator specification must be "temp-sense-gen.
            Error: Bad Input Specfile. 'module_name' variable is missing.
            ```
  3. Loads the model file `modelfile.csv` and runs checks on it. If the model file is not valid a default model file in repo`.model_tempsense` is used.
  4. Load the Design specs and parameters from the spec file amd following errors are created on mismatch.
            ```
            Error: Supported temperature sensing must be inside the following range [-20 to 100] Celcius
            Error: Please enter a supported optmization strategy [error or power]
            ```
  5. Search starts for min power,min error and extract the number of inverters and headers.
  
  **Steps happening in TEMP_netlist.py:-**
  1. Reads the verilog templates(TEMP_ANALOG_lv.v,TEMP_ANALOG_hv.v,counter_generic.v).
  2. Reads the result parameter specs from the readparamgen.py(ninv,nhead).
  3. The lines marked with @@  are replaced according to the specifications.SLC replaced with SLC a_lc_0(.IN(out), .INB(outb), .VOUT(lc_0).nbout replaced with port(X).
  4. Writes the output verilog files(TEMP_ANALOG_lv.nl.v,TEMP_ANALOG_hv.nl.v,counter.v).
  
  **Steps happening in tempsense-gen.py:-**
  1.Invokes readparamgen.py to get the resultant specs and platform.
  2.Sets the aux cells.
          ```
            aux1 = "sky130_fd_sc_hd__nand2_1"
            aux2 = "sky130_fd_sc_hd__inv_1"
            aux3 = "sky130_fd_sc_hd__buf_1"
            aux4 = "sky130_fd_sc_hd__buf_1"
            aux5 = "HEADER"
            aux6 = "SLC"
          ```
  3. Invokes TEMP_netlist.py to make a changes regarding SLC and port(X) in verilog templates.
  4. Read verilog templates and Make changes regarding the HEADER cell in verilog templates.
  5. Write the output verilog files.
  
