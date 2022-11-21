# Get tap and endcap cells
set block [ord::get_db_block]
set all_insts [$block getInsts]
set region [$block findRegion "PLL"]
set boundary [$region getBoundaries]
set caps_pll {}
set caps_core {}
foreach inst $all_insts {
  if {[[$inst getMaster] getName] eq "sky130_fd_sc_hd__tapvpwrvgnd_1" || \
      [[$inst getMaster] getName] eq "sky130_fd_sc_hd__decap_4"} {
    set box [$inst getBBox]

    # Select cells from PLL region
    if { [$box xMin] >= [$boundary xMin] && [$box xMax] <= [$boundary xMax] \
      && [$box yMin] >= [$boundary yMin] && [$box yMax] <= [$boundary yMax]} {
        lappend caps_pll $inst
      } else {
        lappend caps_core $inst
      }
  }
}

# Add global connections
add_global_connection -net VDD -inst_pattern {.*} -pin_pattern {VPWR|VDD} -power ;# default: VDD as power
add_global_connection -net VSS -inst_pattern {.*} -pin_pattern {VGND|VSS} -ground

# Manually add connections for tap and encap cells
foreach inst $caps_core {
  add_global_connection -net VDD -inst_pattern [$inst getName] -pin_pattern {VPWR|VDD} -power
}

global_connect

# Set voltage domains
# PLL region created with the create_voltage_domain command
set_voltage_domain -name CORE -power VDD -ground VSS
set_voltage_domain -region PLL -power VDD -ground VSS

# Standard cell grids
# VDD / GND
define_pdn_grid -name stdcell -pins met5 -starts_with POWER -voltage_domains CORE

add_pdn_stripe -grid stdcell -layer met1 -width 0.49 -pitch 6.66 -offset 0 -extend_to_core_ring -followpins
add_pdn_ring -grid stdcell -layer {met4 met5} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {2.0 2.0}
add_pdn_stripe -grid stdcell -layer met4 -width 1.2 -pitch 56.0 -offset 2 -extend_to_core_ring

# Straps to connect the two domains together
add_pdn_stripe -grid stdcell -layer met5 -width 1.6 -offset 80.0 -pitch 56.0 -extend_to_core_ring -starts_with GROUND
add_pdn_stripe -grid stdcell -layer met5 -width 1.6 -pitch 15.0 -extend_to_core_ring -starts_with GROUND -number_of_straps 4 -nets VSS

add_pdn_connect -grid stdcell -layers {met4 met5}
add_pdn_connect -grid stdcell -layers {met1 met4}

# VIN / GND
define_pdn_grid -name stdcell_analog -pins met3 -starts_with POWER -voltage_domains PLL

add_pdn_stripe -grid stdcell_pll -layer met1 -width 0.49 -pitch 6.66 -offset 0 -extend_to_core_ring -followpins
add_pdn_ring -grid stdcell_pll -layer {met4 met3} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {2.0 2.0}
add_pdn_stripe -grid stdcell_pll -layer met4 -width 1.2 -pitch 56.0 -offset 2 -extend_to_core_ring

add_pdn_connect -grid stdcell_pll -layers {met4 met3}
add_pdn_connect -grid stdcell_pll -layers {met1 met4}
add_pdn_connect -grid stdcell_pll -layers {met4 met5}
