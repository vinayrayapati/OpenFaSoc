# Verilog generation
------------------

Running ``make sky130hd_temp`` (temp for "temperature sensor") executes the [temp-sense-gen.py](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/tools/temp-sense-gen.py) script from temp-sense-gen/tools/. 
`temp-sense-gen.py` calls other modules from temp-sense-gen/tools/ during execution

```
  temp-sense-gen.py---------------------> Integration of the aux cells and verilog templates.
    |
    |-- readparamgen.py-----------------> 1.loads the json file
    |       └── simulation.py             2.Identifies the platforms
    |                                     3.Running checks on user inputs
    |                                     4.Choosing the correct circuit elements
    |                                     5.Final Parameter Extraction
    |-- TEMP_netlist.py-----------------> 1.Reads the verilog templates and required specs.
            └── function.py               2.Modify the verilog templates according to the specs.
                                          3.Write the output verilog files.
```

<img width="722" alt="Screenshot 2022-11-02 at 10 38 32 AM" src="https://user-images.githubusercontent.com/110079631/199403946-b3878cfe-c8ca-48b0-aac2-fea51340a56d.png">

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
  5. Search starts for min power,min error and extract the number of inverters and headers. The search done and the resultant parameters(specs) is shown in the image below:-
  
  <img width="718" alt="Screenshot 2022-11-02 at 10 38 48 AM" src="https://user-images.githubusercontent.com/110079631/199404067-67245698-3411-425b-981b-64e63f8a7224.png">
  
  **Steps happening in TEMP_netlist.py:-**
  1. Reads the verilog templates(TEMP_ANALOG_lv.v,TEMP_ANALOG_hv.v,counter_generic.v).
  2. Reads the result parameter specs from the readparamgen.py(ninv,nhead).
  3. The lines marked with @@  are replaced according to the specifications.SLC replaced with SLC a_lc_0(.IN(out), .INB(outb), .VOUT(lc_0).nbout replaced with port(X).
```
BEFORE MODIFICATION:
@@ wire n@nn;
wire nx1, nx2, nx3, nb1, nb2;
@@ @na a_nand_0 ( .A(EN), .B(n@n0), .Y(n1));
@@ @nb a_inv_@ni ( .A(n@n1), .Y(n@n2));
@@ @ng a_inv_m1 ( .A(n@n3), .Y(nx1));
@@ @nk a_inv_m2 ( .A(n@n4), .Y(nx2));
@@ @nm a_inv_m3 ( .A(nx2), .Y(nx3));
@@ @np a_buf_3 ( .A(nx3), .nbout(nb2));
@@ @nc a_buf_0 ( .A(nx1), .nbout(nb1));
@@ @nd a_buf_1 ( .A(nb1), .nbout(OUT));
@@ @ne a_buf_2 ( .A(nb2), .nbout(OUTB));
```
```
AFTER MODIFICATION:
wire nx1, nx2, nx3, nb1, nb2;
sky130_fd_sc_hd__nand2_1 a_nand_0 ( .A(EN), .B(n7), .Y(n1));
sky130_fd_sc_hd__inv_1 a_inv_0 ( .A(n1), .Y(n2));
sky130_fd_sc_hd__inv_1 a_inv_1 ( .A(n2), .Y(n3));
sky130_fd_sc_hd__inv_1 a_inv_2 ( .A(n3), .Y(n4));
sky130_fd_sc_hd__inv_1 a_inv_3 ( .A(n4), .Y(n5));
sky130_fd_sc_hd__inv_1 a_inv_4 ( .A(n5), .Y(n6));
sky130_fd_sc_hd__inv_1 a_inv_5 ( .A(n6), .Y(n7));
sky130_fd_sc_hd__inv_1 a_inv_m1 ( .A(n7), .Y(nx1));
sky130_fd_sc_hd__inv_1 a_inv_m2 ( .A(n7), .Y(nx2));
sky130_fd_sc_hd__inv_1 a_inv_m3 ( .A(nx2), .Y(nx3));
sky130_fd_sc_hd__buf_1 a_buf_3 ( .A(nx3), .X(nb2));
sky130_fd_sc_hd__buf_1 a_buf_0 ( .A(nx1), .X(nb1));
sky130_fd_sc_hd__buf_1 a_buf_1 ( .A(nb1), .X(OUT));
sky130_fd_sc_hd__buf_1 a_buf_2 ( .A(nb2), .X(OUTB));
```
  5. Writes the output verilog files(TEMP_ANALOG_lv.nl.v,TEMP_ANALOG_hv.nl.v,counter.v).
  
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
```
BEFORE MODIFICATION:
(* keep *)
@@ @nf a_header_@nh(.VIN(VIN));
SLC
@@ @no a_buffer_0 (.A(lc_0), .nbout(lc_out));
```
```
AFTER MODIFICATION:
(* keep *)
HEADER a_header_0(.VIN(VIN));
HEADER a_header_1(.VIN(VIN));
HEADER a_header_2(.VIN(VIN));
SLC a_lc_0(.IN(out), .INB(outb), .VOUT(lc_0));
sky130_fd_sc_hd__buf_1 a_buffer_0 (.A(lc_0), .X(lc_out));
```
  6. Write the output verilog files to the [src](https://github.com/idea-fasoc/OpenFASOC/tree/cbfe054c6e918b567b98ef8f70a79769747a37a8/openfasoc/generators/temp-sense-gen/flow/design/src/tempsense) folder .
  
# Expected inputs for a new design:
-----------------------------------

```
-> 1. Verilog Templates --> Consists of the auxcell connections and instantiations according to the design schematic.
-> 2. model file
-> 3. Parameter Extraction
-> 4. gds,lef files of aux cells
-> 5. Final modification of the python scripts according to the above four inputs.
```
**1. Verilog Templates:**
- The Verilog Templates are verilog files where all the digital blocks of the circuit are written directly either in behavioural or structural verilog format. 
- Now, for the Analog blocks of the circuit, it is subdivided into a number of aux cells in the previous step of aux cell generation. The instantiations and the connections among these aux cells and then to the digital block is needed. 
- Each aux cell is considered as a seperate module and instantiations and connections are made by referencing the Schematic of the required Circuit.
- The place where these module instantiations for the aux cells are needed we represent them by @@ in the verilog template with the appropriate port connections.
- The Examples of the Verilog templates before and after modification can be seen above.

**2. Model file:**
- The [model_file](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/models/modelfile.csv) is required to extract the parameters for the aux cell integration and verilog generation depending on the user input requirements for the Analog Circuit design.
- The [model_file](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/models/modelfile.csv) should consist of the design specifications which vary for the different user requirement functions, from which the iterations for the best parameter selection is done to meet the user required design specifications.
**Example:**
- For the tempsense-generator in which the [model_file](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/models/modelfile.csv) consists of the following parameters:
```
Temp	 Frequency	 Power	 Error	 inv	 header
```
<img width="1168" alt="Screenshot 2022-11-10 at 1 35 32 PM" src="https://user-images.githubusercontent.com/110079631/201035257-fd516799-24a9-4c69-86f8-f72ee0873f1c.png">

- The user requirement of the min and max temperature range is given in the [test.json](https://github.com/idea-fasoc/OpenFASOC/blob/cbfe054c6e918b567b98ef8f70a79769747a37a8/openfasoc/generators/temp-sense-gen/test.json) file. 
```
{
    "module_name": "tempsenseInst_error",
    "generator": "temp-sense-gen",
    "specifications": {
    	"temperature": { "min": -20, "max": 100 }, 
    	"power": "",
    	"error": "",
    	"area": "",
    	"optimization":"error",
    	"model" :"modelfile.csv"
	}
}
```

**3. Parameter Extraction**
- The iterations for the search of the best parameters are done which gives the least Error and min power considering the above tempsense-gen model file as example. The corresponding parameters satisfying this requirements is extracted which gives the number of inverter cells and the header aux cells required for the design of this Analog circuit.
- Reference: Checkout out the steps happening in the [readparamgen.py](https://github.com/idea-fasoc/OpenFASOC/blob/cbfe054c6e918b567b98ef8f70a79769747a37a8/openfasoc/generators/temp-sense-gen/tools/readparamgen.py) python script explained above.

**4. GDS, LEF files for aux cells**
- The Design circuit is broke down into analog and digital blocks first before the aux cell generation stage. The digital blocks are directly incorporated in the Verilog templates and the analog blocks are taken to the aux cell generation stage.
- Then the analog blocks are further broke down into aux cells each not containing more than 10 to 12 transistors. Each aux cell is then seperately ran to generate lef and gds layout files.These files are added in the [config.mk](https://github.com/idea-fasoc/OpenFASOC/blob/cbfe054c6e918b567b98ef8f70a79769747a37a8/openfasoc/generators/temp-sense-gen/flow/design/sky130hd/tempsense/config.mk) file as ADDITIONAL LEF and ADDITIONAL GDS files.
```
export ADDITIONAL_LEFS  	= ../blocks/$(PLATFORM)/lef/HEADER.lef \
                        	  ../blocks/$(PLATFORM)/lef/SLC.lef

export ADDITIONAL_GDS_FILES 	= ../blocks/$(PLATFORM)/gds/HEADER.gds \
			      	  ../blocks/$(PLATFORM)/gds/SLC.gds
```
- And also a BLACK_BOX verilog template [tempsenseInst.blackbox.v](https://github.com/idea-fasoc/OpenFASOC/blob/cbfe054c6e918b567b98ef8f70a79769747a37a8/openfasoc/generators/temp-sense-gen/blocks/sky130hd/tempsenseInst.blackbox.v) is created to call these aux cell modules and incorporate them in the verilog generation process.
```
(* blackbox *) module SLC(
  output VOUT,
  input IN,
  input INB
);
endmodule
(* keep_hierarchy *)
(* blackbox *) module HEADER(
  inout VIN
);
parameter dont_touch = "on";
endmodule
```

**5. Final modification of the python scripts according to the above four inputs**
- This is the Actual Verilog generation stage where the above four inputs are taken into consideration and a pyhton script exclusive to the present design is created.
- The python scripts for the example of tempsense-gen are [temp-sense-gen.py](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/tools/temp-sense-gen.py) and [TEMP_netlist.py](https://github.com/idea-fasoc/OpenFASOC/blob/cbfe054c6e918b567b98ef8f70a79769747a37a8/openfasoc/generators/temp-sense-gen/tools/TEMP_netlist.py), for which the steps happening are clearly described above.

## INPUT LINKS
- **For details on the GDS and LEF file generation for the aux cells [CLICK HERE](https://github.com/sanampudig/OpenFASoC/tree/main/AUXCELL)**

### Author
 - **Vinay Rayapati**

### Contributors
 - Vinay Rayapati
 - Kunal Ghosh

### Acknowledgments
 - Kunal Ghosh, Director, VSD Corp. Pvt. Ltd.
 - Dr.Madhav Rao, ECE Department, IIIT Bangalore.
 - Dr.Murali, Co-ordinator(M.Tech), IIIT Bangalore.

### References
 - OpenFASOC https://github.com/idea-fasoc/OpenFASOC.git

### Contact Information
 - Vinay Rayapati,Post-Graduate student,International Institute of Information Technology Bangalore,vinayrayapati@outlook.com
 - Kunal Ghosh, Director, VSD Corp. Pvt. Ltd.,kunalghosh@gmail.com
 - Dr.Madhav Rao, ECE Department, IIIT Bangalore,mr@iiitb.ac.in
 - Dr.Murali, Co-ordinator(M.Tech), IIIT Bangalore,coordinator-mtech@iiitb.ac.in
