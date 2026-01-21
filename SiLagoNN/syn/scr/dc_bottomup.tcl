################################################################################
# Task3 Bottom-up synthesis (tutorial style) for drra_wrapper (GF22)
# Run from:  .../SiLagoNN/syn/exe_bu_5ns
# Command :  dc_shell -f ../scr/dc_bottomup_tutorial_style.tcl | tee dc_task3_tutorial.log
################################################################################

remove_design -all

# -----------------------------
# Directories (for syn/exe_bu_5ns)
# -----------------------------
set SYN_DIR    ".."          ;# -> .../SiLagoNN/syn
set SOURCE_DIR "../../rtl"   ;# -> .../SiLagoNN/rtl

set TOP_NAME   "drra_wrapper"

set REPORT_DIR "${SYN_DIR}/rpt/task3_tutorial_style"
set OUT_DIR    "${SYN_DIR}/db/task3_tutorial_style"
set WSCR_DIR   "${OUT_DIR}/wscr"

file mkdir $REPORT_DIR
file mkdir $OUT_DIR
file mkdir $WSCR_DIR

# -----------------------------
# Load GF22 libs
# -----------------------------
if {[file exists "${SYN_DIR}/synopsys_dc.setup"]} {
  source "${SYN_DIR}/synopsys_dc.setup"
} elseif {[file exists "${SYN_DIR}/scr/synopsys_dc.setup"]} {
  source "${SYN_DIR}/scr/synopsys_dc.setup"
} else {
  puts "ERROR: cannot find synopsys_dc.setup under ${SYN_DIR}"
  quit
}

# Make link_library explicit (robust)
if {[info exists target_library] && [info exists synthetic_library]} {
  set link_library "* ${target_library} ${synthetic_library}"
}

puts "\n=== LIB SETTINGS ==="
puts "target_library = $target_library"
puts "link_library   = $link_library"
puts "search_path    = $search_path"
puts "====================\n"

# -----------------------------
# Constraints
# -----------------------------
set SDC_FILE "${SYN_DIR}/constraints.sdc"
if {![file exists $SDC_FILE]} {
  puts "ERROR: constraints file not found: $SDC_FILE"
  quit
}

# -----------------------------
# Helpers
# -----------------------------
proc analyze_vhdl {f} {
  if {![file exists $f]} { puts "ERROR: missing RTL file: $f"; quit }
  analyze -format vhdl -lib WORK $f
}

proc analyze_list {listfile source_dir} {
  if {![file exists $listfile]} { puts "ERROR: missing listfile: $listfile"; quit }
  set lines [split [read [open $listfile r]] "\n"]
  foreach l $lines {
    set t [string trim $l]
    if {$t ne ""} {
      analyze_vhdl "${source_dir}/${t}"
    }
  }
}

proc safe_source {f} {
  if {[file exists $f]} {
    puts "Sourcing: $f"
    source $f
    return 1
  } else {
    puts "WARNING: file not found, skip: $f"
    return 0
  }
}

proc set_design_dont_touch {design_name} {
  set d [get_designs -quiet $design_name]
  if {[sizeof_collection $d] > 0} {
    set_dont_touch $d true
    puts "dont_touch (design) set on: $design_name"
  } else {
    puts "WARNING: design not found for dont_touch: $design_name"
  }
}

# Optional: simple output load, only if ports exist
proc apply_io_load {} {
  set outs [all_outputs]
  if {[llength $outs] > 0} {
    set_load 0.13 $outs
  }
}

# Pick one instance under TOP by ref_name pattern (for characterize)
proc pick_one_inst {refpat} {
  set c [get_cells -hier -filter "ref_name =~ $refpat"]
  if {[sizeof_collection $c] > 0} {
    return [lindex [get_object_name $c] 0]
  }
  return ""
}

# -----------------------------
# Subblocks you want bottom-up
# (tutorial style: keep this list small)
# -----------------------------
set SUBBLOCKS [list divider_pipe silego]

# -----------------------------
# One pass
# -----------------------------
proc nth_pass {n} {
  global SOURCE_DIR SYN_DIR OUT_DIR WSCR_DIR REPORT_DIR TOP_NAME SDC_FILE SUBBLOCKS

  set prev [expr {$n - 1}]
  set pass_dir "${OUT_DIR}/pass${n}"
  if {[file exists $pass_dir]} { file delete -force $pass_dir }
  file mkdir $pass_dir

  puts "\n============================================================"
  puts "                 Tutorial-style Bottom-up Pass $n"
  puts "============================================================\n"

  remove_design -all

  # 0) Analyze packages / constants (if present)
  set pkg_list "${SOURCE_DIR}/pkg_hierarchy.txt"
  if {[file exists $pkg_list]} {
    analyze_list $pkg_list $SOURCE_DIR
  } else {
    puts "WARNING: ${pkg_list} not found, continuing."
  }

  # ----------------------------------------------------------
  # 1) Compile each subblock independently (bottom-up)
  # ----------------------------------------------------------
  foreach blk $SUBBLOCKS {
    puts "\n--- Compile subblock $blk (pass $n) ---"

    if {$blk eq "divider_pipe"} {
      analyze_vhdl "${SOURCE_DIR}/mtrf/DPU/divider_pipe.vhd"
      elaborate divider_pipe
      current_design divider_pipe
    } elseif {$blk eq "silego"} {
      # Use hierarchy list for silego
      set silego_list "${SOURCE_DIR}/silagonn_hierarchy.txt"
      analyze_list $silego_list $SOURCE_DIR
      elaborate silego
      current_design silego
    } else {
      puts "ERROR: unknown subblock: $blk"
      quit
    }

    link
    uniquify
    source $SDC_FILE
    apply_io_load

    # reuse previous wscr if available
    if {$n > 1} {
      safe_source "${WSCR_DIR}/${blk}_${prev}.wscr"
    }

    compile -map_effort medium
    apply_io_load

    # write wscr snapshot for this subblock for next pass
    write_script > "${WSCR_DIR}/${blk}_${n}.wscr"
  }

  # ----------------------------------------------------------
  # 2) Compile TOP (light locking like tutorial)
  #    - Only lock subblock designs, NOT all tiles.
  # ----------------------------------------------------------
  puts "\n--- Compile TOP ${TOP_NAME} (pass $n) ---"
  analyze_vhdl "${SOURCE_DIR}/mtrf/drra_wrapper.vhd"
  elaborate $TOP_NAME
  current_design $TOP_NAME
  link
  uniquify
  source $SDC_FILE
  apply_io_load

  # Lock ONLY the subblock designs (tutorial style)
  foreach blk $SUBBLOCKS {
    set_design_dont_touch $blk
  }

  # Compile top (drra_wrapper likely has logic)
  compile -map_effort medium
  apply_io_load

  # Reports for this pass
  report_qor                  > "${pass_dir}/${TOP_NAME}_qor.rpt"
  report_timing -max_paths 20 > "${pass_dir}/${TOP_NAME}_timing.rpt"
  report_area                 > "${pass_dir}/${TOP_NAME}_area.rpt"
  report_power                > "${pass_dir}/${TOP_NAME}_power.rpt"
  report_constraints          > "${pass_dir}/${TOP_NAME}_constraints.rpt"

  # ----------------------------------------------------------
  # 3) Characterize (tutorial style: feed back top environment)
  #    We automatically pick one instance of each subblock under TOP.
  # ----------------------------------------------------------
  set insts {}
  set div_i [pick_one_inst "*divider_pipe*"]
  if {$div_i ne ""} { lappend insts $div_i }
  set sil_i [pick_one_inst "*silego*"]
  if {$sil_i ne ""} { lappend insts $sil_i }

  if {[llength $insts] > 0} {
    puts "Characterize instances: $insts"
    characterize -constraint $insts
  } else {
    puts "WARNING: No instances found for characterize; skipping."
  }

  # Write a wscr for TOP too (optional but useful)
  write_script > "${WSCR_DIR}/${TOP_NAME}_${n}.wscr"

  # Also dump a pass netlist/ddc for debugging
  write_file -hierarchy -format ddc     -output "${pass_dir}/${TOP_NAME}.ddc"
  write_file -hierarchy -format verilog -output "${pass_dir}/${TOP_NAME}.v"

  puts "\n=== End of pass $n ===\n"
}

# -----------------------------
# Run passes (tutorial usually does 2)
# -----------------------------
set NUM_PASSES 2
for {set i 1} {$i <= $NUM_PASSES} {incr i} {
  nth_pass $i
}

# -----------------------------
# Final outputs (from last pass)
# -----------------------------
current_design $TOP_NAME

report_area        > "${REPORT_DIR}/${TOP_NAME}_area.txt"
report_timing      > "${REPORT_DIR}/${TOP_NAME}_timing.txt"
report_power       > "${REPORT_DIR}/${TOP_NAME}_power.txt"
report_constraints > "${REPORT_DIR}/${TOP_NAME}_constraints.txt"
report_cell        > "${REPORT_DIR}/${TOP_NAME}_cell.txt"

write_file -hierarchy -format ddc     -output "${OUT_DIR}/${TOP_NAME}.ddc"
write_file -hierarchy -format verilog -output "${OUT_DIR}/${TOP_NAME}.v"
write_sdc  "${OUT_DIR}/${TOP_NAME}.sdc"
write_sdf  "${OUT_DIR}/${TOP_NAME}.sdf"

puts "\n=========================================="
puts "Tutorial-style bottom-up complete!"
puts "Reports: ${REPORT_DIR}"
puts "Outputs: ${OUT_DIR}"
puts "WSCR   : ${WSCR_DIR}"
puts "==========================================\n"

quit

