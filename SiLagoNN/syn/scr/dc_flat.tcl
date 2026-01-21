# ============================================================================
# Task2: Flat Logic Synthesis for drra_wrapper (GF22)
# Clock is FIXED and taken ONLY from syn/constraints.sdc
# Run directory: syn/exe_flat_pXX/
# ============================================================================

# --------------------------
# 0) Directory variables
# --------------------------
set SOURCE_DIR ../../rtl
set SYN_DIR    ..
set OUT_DIR    ${SYN_DIR}/db
set RPT_DIR    ${SYN_DIR}/rpt

file mkdir $OUT_DIR
file mkdir $RPT_DIR

# --------------------------
# 1) Load library setup (GF22)
# --------------------------
source ${SYN_DIR}/synopsys_dc.setup

# Optional: print library settings into log for evidence/debug
puts "=== LIB SETTINGS ==="
puts "search_path    = $search_path"
puts "target_library = $target_library"
puts "link_library   = $link_library"
puts "synthetic_lib  = $synthetic_library"
puts "===================="

# --------------------------
# 2) Design variables
# --------------------------
set TOP_NAME drra_wrapper

# --------------------------
# 3) Read RTL in hierarchy order
# --------------------------
set hier_txt "${SOURCE_DIR}/${TOP_NAME}_hierarchy.txt"
if {![file exists $hier_txt]} {
  puts "ERROR: hierarchy file not found: $hier_txt"
  quit -f
}

set hierarchy_files [split [read [open $hier_txt r]] "\n"]

foreach filename [lrange $hierarchy_files 0 end-1] {
  set f "${SOURCE_DIR}/${filename}"

  if {![file exists $f]} {
    puts "ERROR: RTL file not found: $f"
    quit -f
  }

  puts "Analyzing $f"

  if {[string match "*.vhd" $f] || [string match "*.vhdl" $f]} {
    analyze -format vhdl -lib WORK $f
  } elseif {[string match "*.v" $f]} {
    analyze -format verilog -lib WORK $f
  } else {
    puts "WARNING: unknown extension (skipped): $f"
  }
}

# --------------------------
# 4) Elaborate + Link
# --------------------------
elaborate $TOP_NAME
current_design $TOP_NAME
link

# Safety: ensure we are on the expected design
puts "Current design: [current_design]"

# --------------------------
# 5) Constraints (clock comes ONLY from constraints.sdc)
# --------------------------
set sdc_file "${SYN_DIR}/constraints.sdc"
if {![file exists $sdc_file]} {
  puts "ERROR: constraints file not found: $sdc_file"
  quit -f
}

source $sdc_file

# Optional: dump clocks/constraints for proof
report_clocks       > ${RPT_DIR}/${TOP_NAME}_clocks.rpt
report_constraints  > ${RPT_DIR}/${TOP_NAME}_constraints.rpt

# --------------------------
# 6) Compile (Flat)
# --------------------------
compile -map_effort medium

# --------------------------
# 7) Reports (PPA)
# --------------------------
report_qor                  > ${RPT_DIR}/${TOP_NAME}_qor.rpt
report_timing -max_paths 20 > ${RPT_DIR}/${TOP_NAME}_timing.rpt
report_area                 > ${RPT_DIR}/${TOP_NAME}_area.rpt
report_power                > ${RPT_DIR}/${TOP_NAME}_power.rpt
report_cell                 > ${RPT_DIR}/${TOP_NAME}_cells.rpt

# --------------------------
# 8) Outputs (netlist, ddc, sdc)
# --------------------------
write -hierarchy -format ddc     -output ${OUT_DIR}/${TOP_NAME}.ddc
write -hierarchy -format verilog -output ${OUT_DIR}/${TOP_NAME}.v
write_sdc ${OUT_DIR}/${TOP_NAME}.sdc

puts "=== Task2 Flat Synthesis Done ==="
quit

