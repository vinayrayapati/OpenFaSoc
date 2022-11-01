# OpenFaSoc
Fully Open-Source Autonomous SoC Synthesis using Customizable Cell-Based Synthesizable Analog Circuits
The FASoC Program is focused on developing a complete system-on-chip (SoC) synthesis tool from user specification to GDSII with fully open-sourced tools.

# Prerequisites

Please build the following tools:

  Magic <https://github.com/RTimothyEdwards/magic>

  Netgen <https://github.com/RTimothyEdwards/netgen>

  Klayout <https://github.com/KLayout/klayout>
        Please use this command to build preferably: `./build.sh -option '-j8' -noruby -without-qt-multimedia -without-qt-xml -without-qt-svg`


  Yosys <https://github.com/The-OpenROAD-Project/yosys>

  OpenROAD <https://github.com/The-OpenROAD-Project/OpenROAD> (commid id: 7ff7171)

  open_pdks <https://github.com/RTimothyEdwards/open_pdks>

   - open_pdks is required to run drc/lvs check and the simulations
   - After open_pdks is installed, please update the **open_pdks** key in `common/platform_config.json` with the installed path, down to the sky130A folder

  Other notice:

   - Python 3.7 is used in this generator.
   - All the required tools need to be loaded into the environment before running this generator.
   # Design Generation
   Temperature Sensor Generator
=============================

This page gives an overview of how the Temperature Sensor Generator (temp-sense-gen) works internally in OpenFASoC.

Circuit
-------
This generator creates a compact mixed-signal temperature sensor based on the topology from this paper `<https://ieeexplore.ieee.org/document/9816083>`. 

It consists of a ring oscillator whose frequency is controlled by the voltage drop over a MOSFET operating in subthreshold regime, where its dependency on temperature is exponential.

![tempsense_ckt](https://user-images.githubusercontent.com/110079631/199317479-67f157c5-6934-470b-8552-5451b1361b9c.png)

  Block diagram of the temperature sensor’s circuit

The physical implementation of the analog blocks in the circuit is done using two manually designed standard cells:

* HEADER cell, containing the transistors in subthreshold operation;
* SLC cell, containing the Split-Control Level Converter.

The gds and lef files of HEADER and SLC cells are pre-created before the start of the Generator flow.
The layout of the HEADER cell is shown below:

<img width="1512" alt="Screenshot 2022-11-02 at 3 26 02 AM" src="https://user-images.githubusercontent.com/110079631/199349855-247c9aeb-3ca8-4cd0-863a-cb629778ee2a.png">

The layout of the SLC cell is shown below:

<img width="1512" alt="Screenshot 2022-11-02 at 3 26 13 AM" src="https://user-images.githubusercontent.com/110079631/199349926-63135ad7-fd85-42bc-998a-dac48b1ad5f1.png">

Generator Flow
--------------

To configure circuit specifications, modify the [test.json](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/test.json) : specfile in the generators/temp-sense-gen/ folder.

To run the default generator, ``cd`` into [openfasoc/generators/temp-sense-gen/](https://github.com/idea-fasoc/OpenFASOC/tree/main/openfasoc/generators/temp-sense-gen) :and execute the following command:

```

  make sky130hd_temp

```
  For other generator options, use `make help`.

The default circuit's physical design generation can be divided into three parts:

- Verilog generation
- RTL-to-GDS flow
- Post-layout verification

Verilog generation
------------------

Running ``make sky130hd_temp`` (temp for "temperature sensor") executes the [temp-sense-gen.py](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/tools/temp-sense-gen.py) script from temp-sense-gen/tools/. 
This file takes the input specifications from [test.json](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/test.json) and outputs Verilog files containing the description of the circuit.

 **Note:**
    - temp-sense-gen.py calls other modules from temp-sense-gen/tools/ during execution. For example, [readparamgen.py](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/tools/readparamgen.py) is in charge of reading test.json, checking for correct user input and choosing the correct circuit elements.

The generator starts from a Verilog template of the temperature sensor circuit, located in [temp-sense-gen/src/](https://github.com/idea-fasoc/OpenFASOC/tree/main/openfasoc/generators/temp-sense-gen/src). The ``.v`` template files have lines marked with ``@@``, which are replaced according to the specifications.

Example: [counter_generic.v line 31](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/src/counter_generic.v#L31) is replaced during Verilog generation.

```
  assign done_sens = WAKE_pre &&  doneb;
	assign done_ref = WAKE && doneb;
  @@ @np Buf_DONE(.A(done_pre), .nbout(DONE));

  always @ (*) begin
    case (done_pre)
      1'd0:	DOUT = 0;
      1'd1:	DOUT = div_s;
    endcase
  end
 ```

To replace these lines with the correct circuit elements, temp-sense-gen takes cells from the selected technology. The number of inverters in the ring oscillator and of HEADER cells in parallel are optimized using a nearest-neighbor approach with experimental data from [models/modelfile.csv](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/models/modelfile.csv>)

**Note:**
  Currently, the only supported technology in temp-sense-gen is sky130hd (hd for “high density”).
  
 RTL-to-GDS flow
 ---------------

The `compilation` from the Verilog description to a physical circuit is made using a fork of [OpenROAD Flow](http://github.com/the-OpenROAD-Project/openroAD-flow-scripts/), which is an RTS-to-GDS flow based on the [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) tool. The fork is in the [temp-sense-gen/flow/](https://github.com/idea-fasoc/OpenFASOC/tree/main/openfasoc/generators/temp-sense-gen/flow) directory.

OpenROAD Flow takes a design from the temp-sense-gen/flow/design/ directory and runs it through its flow, generating a DEF and a GDS at the end. The design is specified by using the generated Verilog files and a `config.mk` file that configures OpenROAD Flow to the temperature sensor design.

```

  temp-sense-gen
  ├── blocks
  └── flow
      └── design
          ├── sky130hd
          │   └── tempsense
          │       ├── config.mk             <--
          │       └── constraint.sdc
          └── src
              └── tempsense
                  ├── counter.v             <--
                  ├── TEMP_ANALOG_hv.nl.v   <--
                  ├── TEMP_ANALOG_lv.nl.v   <--
                  ├── TEMP_AUTO_def.v       <--
                  └── tempsenseInst_error.v <--
```

For more information on OpenROAD Flow, check their [docs](https://openroad.readthedocs.io/en/latest/user/GettingStarted.html)

**Note:-**
  OpenROAD Flow also creates intermediary files in the temp-sense-gen/flow/results/ folder, where each file is named according to the step in the flow it was created.

  For example, `2_floorplan.odb` is the file created after step 2 of OpenROAD Flow Scripts, which is floorplan generation.

The steps from the RTL-to-GDS flow look like this, usual in a digital flow:

![tempsense_digflow_diagram](https://user-images.githubusercontent.com/110079631/199325657-1322e2c3-84ea-4f66-943d-6775b3b5cb24.png)


Since OpenROAD was developed with digital designs in mind, some features do not natively support analog or mixed-signal designs for now. Hence, in the temperature sensor, the physical implementation does not get successfully generated with the original flow.

Some changes are then made to customize the OpenROAD Flow repo and generate a working physical design, summarized in the diagram below:


  
Synthesis
---------
The OpenROAD Flow starts with a flow configuration file [config.mk](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/design/sky130hd/tempsense/config.mk), the chosen platform (sky130hd, for example) and the Verilog files generated from the previous part.

From them, synthesis is run using Yosys to find the appropriate circuit implementation from the available cells in the platform.

Floorplan
---------


Then, the floorplan for the physical design is generated with OpenROAD, which requires a description of the power delivery network in [pdn.cfg](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/blocks/sky130hd/pdn.cfg).

This temperature sensor design implements two voltage domains: one for the VDD that powers most of the circuit, and another for the VIN that powers the ring oscillator and is an output of the HEADER cells. Such voltage domains are created within the [floorplan.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/floorplan.tcl#L34) script, with the following lines of code:

```

  # Initialize floorplan using DIE_AREA/CORE_AREA
  # ----------------------------------------------------------------------------
  } else {
    create_voltage_domain TEMP_ANALOG -area $::env(VD1_AREA)

    initialize_floorplan -die_area $::env(DIE_AREA) \
                         -core_area $::env(CORE_AREA) \
                         -site $::env(PLACE_SITE)

     if {[info exist ::env(DOMAIN_INSTS_LIST)]} {
      source $::env(SCRIPTS_DIR)/openfasoc/read_domain_instances.tcl
      read_domain_instances TEMP_ANALOG $::env(DOMAIN_INSTS_LIST)
    }
  }
```
In the image, line #34 will create a voltage domain named TEMP_ANALOG with area coordinates as defined in config.mk.

Lines #36 to #38 will initialize the floorplan, as default in OpenROAD Flow, from the die area, core area and place site coordinates from config.mk.

And finally, lines #40 to #42 will source [read_domain_instances.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/read_domain_instances.tcl), a script that assigns the corresponding instances to the TEMP_ANALOG domain group. It gets the wanted instances from the DOMAIN_INSTS_LIST variable, set to [tempsenseInst_domain_insts.txt](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/blocks/sky130hd/tempsenseInst_domain_insts.txt) in config.mk. This will ensure the cells are placed in the correct voltage domain during the detailed placement phase.

The tempsenseInst_domain_insts.txt file contains all instances to be placed in the TEMP_ANALOG domain (VIN voltage tracks). These cells are the components of the ring oscillator, including the inverters whose quantity may vary according to the optimization results. Thus, this file actually gets generated during temp-sense-gen.py.

Placement
---------

Placement *takes place* after the floorplan is ready and has two phases: global placement and detailed placement. The output of this phase will have all instances placed in their corresponding voltage domain, ready for routing.

Routing
-------

Routing is also divided into two phases: global routing and detailed routing. Right before global routing, OpenFASoC calls [pre_global_route.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/pre_global_route.tcl):

```
  # NDR rules
  source $::env(SCRIPTS_DIR)/openfasoc/add_ndr_rules.tcl

  # Custom connections
  source $::env(SCRIPTS_DIR)/openfasoc/create_custom_connections.tcl
  if {[info exist ::env(CUSTOM_CONNECTION)]} {
    create_custom_connections $::env(CUSTOM_CONNECTION)
  }
```

This script sources two other files: [add_ndr_rules.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/add_ndr_rules.tcl), which adds an NDR rule to the VIN net to improve routes that connect both voltage domains, and [create_custom_connections.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/create_custom_connections.tcl), which creates the connection between the VIN net and the HEADER instances.

 **Final layout after routing:**
 
 <img width="1512" alt="Screenshot 2022-10-29 at 11 39 37 AM" src="https://user-images.githubusercontent.com/110079631/199332534-5951cad9-c38c-4d2d-bf93-e37be27c67b0.png">

At the end, OpenROAD Flow will output its logs under flow/reports/, and its results under flow/results/.

Here's an overview of all changes made from OpenROAD Flow to OpenFASoC’s temp-sense-gen (the reference directory taken is [temp-sense-gen/flow/](https://github.com/idea-fasoc/OpenFASOC/tree/main/openfasoc/generators/temp-sense-gen/flow):

Design files (needed for configuring OpenROAD Flow Scripts)
| Design files | Flow |
| --- | --- |
| [design/sky130hd/tempsense/config.mk](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/design/sky130hd/tempsense/config.mk) | OpenROAD Flow Scripts configuration |
|[design/src/tempsense/*.v ](https://github.com/idea-fasoc/OpenFASOC/tree/main/openfasoc/generators/temp-sense-gen/flow/design/src/tempsense>)|Circuit Verilog description|
|[../blocks/*/pdn.cfg](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/blocks/sky130hd/pdn.cfg)|Power Delivery Network setup|

Additional or modified files (make OpenROAD Flow Scripts support this analog design)

| Additional files | Flow |
| --- | --- |
| [scripts/floorplan.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/floorplan.tcl)(modified)
[scripts/openfasoc/read_domain_instances.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/read_domain_instances.tcl) | Create a voltage domain for the output voltage VIN from the header cells, assigns its instances |
| [scripts/openfasoc/pre_global_route.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/pre_global_route.tcl)
[scripts/openfasoc/add_ndr_rules.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/add_ndr_rules.tcl)
[scripts/openfasoc/create_custom_connections.tcl](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/scripts/openfasoc/create_custom_connections.tcl) | Scripts run before global routing to setup the connection between the header cells and the VIN voltage domain ring |
| [Makefile](https://github.com/idea-fasoc/OpenFASOC/blob/main/openfasoc/generators/temp-sense-gen/flow/Makefile) (modified) | Set flow directories from the fork, jump the CTS part (not needed for the temp-sense-gen since there's no clock), add DRC w/ Magic, add LVS w/ Netgen |

The other files are unchanged from OpenROAD Flow.

**Note:-**
  For debugging purposes, it's also possible to generate only part of the flow, visualize the results in OpenROAD GUI or generate DEF files of all intermediary results. For doing so, the Makefile in temp-sense-gen/flow/ contains special targets.

  After running ``make sky130hd_temp`` in temp-sense-gen/ once, ``cd`` into the [flow/](https://github.com/idea-fasoc/OpenFASOC/tree/main/openfasoc/generators/temp-sense-gen/flow) directory and use one of the commands from the following table:

| Commands | Description |
| --- | --- |
|``make synth``| Stops the flow after synthesis |
|``make floorplan``| Stops the flow after floorplan |
|``make place``| Stops the flow after placement |
|``make route``| Stops the flow after routing |
|``make finish``| Runs the whole RTL-to-GDS flow |
|``make gui_floorplan``| Opens the design after floorplan in OpenROAD GUI |
|``make gui_place``| Opens the design after placement in OpenROAD GUI |
|``make gui_route``| Opens the design after routing in OpenROAD GUI |
|``make gui_final``| Opens the finished design in OpenROAD GUI |
|``make all_defs``| Creates DEF files in flow/results/ of every step in the flow |
|``make print-ENV_VARIABLE_NAME``| Prints the value of an env variable recognized by OpenROAD Flow|
