# Flat Physical Synthesis Script
source ../scr/global_variables.tcl
source ../scr/read_design.tcl

# Floorplan
create_floorplan -site SC8T_104CPP_CMOS22FDX -core_density_size 0.971659919028 0.699853 10.088 10.0 10.088 10.0

# Power planning
source ../scr/powerplan.tcl

# Placement
place_design
assign_io_pins

# Clock Tree Synthesis
ccopt_design

# Routing
assign_io_pins
route_design

# Write outputs
exec mkdir -p ${OUTPUT_DIR}/flat
write_db ${OUTPUT_DIR}/flat/${TOP_NAME}.dat
write_netlist ${OUTPUT_DIR}/flat/${TOP_NAME}.v

# Generate reports
exec mkdir -p ${RPT_DIR}/flat
report_timing -max_paths 10 > ${RPT_DIR}/flat/${TOP_NAME}_timing_setup.rpt
report_timing -max_paths 10 -delay_type min > ${RPT_DIR}/flat/${TOP_NAME}_timing_hold.rpt
report_area > ${RPT_DIR}/flat/${TOP_NAME}_area.rpt
report_power > ${RPT_DIR}/flat/${TOP_NAME}_power.rpt
report_drc > ${RPT_DIR}/flat/${TOP_NAME}_drc.rpt
