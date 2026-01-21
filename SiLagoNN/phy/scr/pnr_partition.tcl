# Partition P&R Script
# This script is run from within each partition directory

# Get script directory to find global variables
set SCRIPT_DIR [file dirname [file normalize [info script]]]
set PROJECT_ROOT [file dirname [file dirname $SCRIPT_DIR]]

# Source global variables to get SDC path
source ${SCRIPT_DIR}/global_variables_hrchy.tcl

#1. Read the partition database
read_db .

# Check if clocks are available in the database
# read_db should restore MMMC configuration including constraints
set clocks [get_clocks -quiet]
puts "Found [llength $clocks] clock(s) in partition database"

# If no clocks found, create clock definition directly
# Partitions have partition pins, not top-level ports, so SDC [get_ports clk] doesn't work
# We need to create clock on the partition pin instead
if {[llength $clocks] == 0} {
    puts "Warning: No clocks found in partition database. Creating clock definition..."
    
    # Check if clk pin exists (partition pin, not port)
    set clk_pins [get_db [get_pins -quiet -hierarchical clk] .name]
    if {[llength $clk_pins] == 0} {
        # Try to find clock pin with different names
        set clk_pins [get_db [get_pins -quiet -hierarchical -filter ".name=~*clk*"] .name]
    }
    
    if {[llength $clk_pins] > 0} {
        puts "Found clock pin(s): $clk_pins"
        # Create clock on the first clock pin found
        # Clock period: 10ns (10000ps) from constraints.sdc
        set clk_pin [lindex $clk_pins 0]
        puts "Creating clock 'clk' on pin $clk_pin with period 10ns"
        
        if {[catch {
            create_clock -name "clk" -period 10000 -waveform {0 5000} [get_pins $clk_pin]
            set_clock_uncertainty -setup 30 [get_clocks clk]
            set_clock_uncertainty -hold 10 [get_clocks clk]
            puts "Clock 'clk' created successfully"
        } err]} {
            puts "Warning: Could not create clock: $err"
            puts "Trying alternative method: create clock on all clk pins..."
            # Try creating clock on all clk pins
            foreach pin $clk_pins {
                if {[catch {
                    create_clock -name "clk" -period 10000 -waveform {0 5000} [get_pins $pin]
                    set_clock_uncertainty -setup 30 [get_clocks clk]
                    set_clock_uncertainty -hold 10 [get_clocks clk]
                    puts "Clock 'clk' created on pin $pin"
                    break
                } err2]} {
                    puts "Warning: Could not create clock on $pin: $err2"
                }
            }
        }
        
        # Re-check clocks after creation
        set clocks [get_clocks -quiet]
        puts "Found [llength $clocks] clock(s) after creating clock definition"
    } else {
        puts "Warning: No clock pins found in partition."
        puts "This partition may not have clock signals."
        puts "Checking for any pins..."
        set all_pins [get_db [get_pins -quiet -hierarchical] .name]
        if {[llength $all_pins] > 0} {
            puts "Available pins (first 10): [lrange $all_pins 0 9]"
        }
    }
}

#2. Place design
place_design

#3. Clock tree synthesis (ccopt)
# Check if clocks exist before running ccopt
set clocks [get_clocks -quiet]
if {[llength $clocks] > 0} {
    puts "Found [llength $clocks] clock(s). Running ccopt_design..."
    ccopt_design
} else {
    puts "Warning: No clocks found. Skipping ccopt_design."
    puts "This partition may not contain clocked logic."
}

#4. Route design
route_design

#5. Write the partition database
write_db ./pnr/

#6. Write ILM (Interface Logic Model)
write_ilm