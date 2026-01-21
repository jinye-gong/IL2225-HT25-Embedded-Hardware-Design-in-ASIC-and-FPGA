source ../phy/scr/global_variables_hrchy.tcl
source ../phy/scr/design_variables.tcl

cd ../phy/db/part

# Try to enable AAE (Advanced Analysis Engine) for better timing analysis
# AAE provides more accurate timing analysis but may have stability issues
# If crashes occur, we can revert to 'static' engine
# set_db timing_analysis_engine static  # Disabled to try AAE

read_db ${TOP_NAME}

# Check current timing engine setting
set current_engine [get_db root:timing_analysis_engine]
puts "Current timing analysis engine: $current_engine"

# Optionally set AAE explicitly (default should be AAE if available)
# Uncomment the following line to force AAE:
# set_db timing_analysis_engine statistical

# Check if clocks are available in the database
# read_db should restore MMMC configuration including constraints
set clocks [get_clocks -quiet]
puts "Found [llength $clocks] clock(s) in database"

# If no clocks found, try to update constraint mode with SDC file
# Note: read_mmmc cannot be called after init_design, but we can update constraint mode
if {[llength $clocks] == 0} {
    puts "Warning: No clocks found in database. Attempting to reload SDC constraints..."
    
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

# Map master module names to actual partition instance directories
# Based on master_partition_hinst_list: 
#   Silago_top_inst_6_0 -> Silago_top_5, Silago_bot_inst_6_1 -> Silago_bot_5
set master_module_to_instance {
	{Silago_top Silago_top_5}
	{Silago_bot Silago_bot_5}
	{Silago_top_left_corner Silago_top_left_corner}
	{Silago_bot_left_corner Silago_bot_left_corner}
	{Silago_top_right_corner Silago_top_right_corner}
	{Silago_bot_right_corner Silago_bot_right_corner}
}

foreach module $master_partition_module_list {
	# Find the corresponding instance directory
	set instance_dir ""
	foreach mapping $master_module_to_instance {
		if {[lindex $mapping 0] == $module} {
			set instance_dir [lindex $mapping 1]
			break
		}
	}
	
	# If no mapping found, try the module name directly
	if {$instance_dir == ""} {
		set instance_dir $module
	}
	
	# Check if ILM directory exists
	set ilm_dir "${instance_dir}/ilm"
	if {[file exists $ilm_dir]} {
		puts "Reading ILM for module $module (instance $instance_dir) from ${ilm_dir}"
		# Use instance_dir as cell name since that's what exists in the design
		# The ILM was written with the instance name, so we need to read it with instance name
		read_ilm -cell $instance_dir -dir $ilm_dir
	} else {
		puts "Warning: ILM directory not found for $module at $ilm_dir"
		puts "This partition may not have completed P&R. Skipping ILM read."
	}
}
#2. flatten ilms
flatten_ilm

#3. place 
# Note: Clock constraints should be in the database from MMMC configuration
# Removed -no_pre_place_opt to allow AAE-based pre-placement optimization
# If AAE crashes occur, add -no_pre_place_opt back
place_design

#4. ccopt (clock tree synthesis)
# Check if clocks exist before running ccopt
set clocks [get_clocks -quiet]
if {[llength $clocks] > 0} {
    puts "Found [llength $clocks] clock(s). Running ccopt_design..."
    ccopt_design
} else {
    puts "Warning: No clocks found. Skipping ccopt_design."
    puts "This may cause timing issues in the final design."
}
#5. route
route_design

#6. write the place and routed db
# Write to ${TOP_NAME}.enc.dat/pnr to match assemble_design.tcl expectation
write_db ${TOP_NAME}.enc.dat/pnr