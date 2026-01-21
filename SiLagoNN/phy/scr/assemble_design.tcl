source ../phy/scr/global_variables_hrchy.tcl
source ../phy/scr/design_variables.tcl

#1. read the top place-and-routed top partition
read_db ../phy/db/part/${TOP_NAME}.enc.dat/pnr

# Check if clocks are available in the database
# read_db should restore MMMC configuration including constraints
set clocks [get_clocks -quiet]
puts "Found [llength $clocks] clock(s) in assembled design"

# If no clocks found, try to update constraint mode with SDC file
# Note: read_mmmc cannot be called after init_design, but we can update constraint mode
if {[llength $clocks] == 0} {
    puts "Warning: No clocks found in assembled design. Attempting to reload SDC constraints..."
    
    # Get SDC file path from global variables
    if {![info exists SDC_FILES]} {
        # Try to find SDC file
        if {[file exists "../syn/db/flat_20ns/${TOP_NAME}.sdc"]} {
            set SDC_FILES "../syn/db/flat_20ns/${TOP_NAME}.sdc"
        } elseif {[file exists "../syn/constraints.sdc"]} {
            set SDC_FILES "../syn/constraints.sdc"
        }
    }
    
    if {[info exists SDC_FILES] && [file exists $SDC_FILES]} {
        puts "Updating constraint mode with SDC file: $SDC_FILES"
        # Try to update the existing constraint mode
        if {[catch {update_constraint_mode -name functional -sdc_files $SDC_FILES} err]} {
            puts "Warning: Could not update constraint mode: $err"
            puts "Constraints may need to be loaded during create_partitions step."
        } else {
            # Re-check clocks after updating constraint mode
            set clocks [get_clocks -quiet]
            puts "Found [llength $clocks] clock(s) after updating constraint mode"
        }
    } else {
        puts "Warning: SDC file not found. Clock constraints may be missing."
        puts "Please ensure SDC constraints are loaded during create_partitions step."
    }
}

#2. assemble the design from the constituent place and routed partitions
foreach part [glob ../phy/db/part/*.enc.dat/pnr] {
    if {[file normalize $part] == [file normalize "../phy/db/part/drra_wrapper.enc.dat/pnr"]} {
        continue
    }
    assemble_design -encounter_format -block_dir $part
}

#3. Write the final assembled design
exec mkdir -p ${OUTPUT_DIR}/hierarchical
write_db ${OUTPUT_DIR}/hierarchical/${TOP_NAME}.dat
write_netlist ${OUTPUT_DIR}/hierarchical/${TOP_NAME}.v

#4. Generate reports
exec mkdir -p ${RPT_DIR}/hierarchical
report_timing -max_paths 10 > ${RPT_DIR}/hierarchical/${TOP_NAME}_timing_setup.rpt
report_timing -max_paths 10 -delay_type min > ${RPT_DIR}/hierarchical/${TOP_NAME}_timing_hold.rpt
report_area > ${RPT_DIR}/hierarchical/${TOP_NAME}_area.rpt
report_power > ${RPT_DIR}/hierarchical/${TOP_NAME}_power.rpt
report_drc > ${RPT_DIR}/hierarchical/${TOP_NAME}_drc.rpt

puts "Final assembled design saved to: ${OUTPUT_DIR}/hierarchical/${TOP_NAME}.dat"
puts "Netlist saved to: ${OUTPUT_DIR}/hierarchical/${TOP_NAME}.v"
puts "Reports saved to: ${RPT_DIR}/hierarchical/"