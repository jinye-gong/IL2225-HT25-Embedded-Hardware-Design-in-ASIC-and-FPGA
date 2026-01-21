set NUM_CPUS 8
#set the top name of the design
set TOP_NAME drra_wrapper

# Directories
set OUTPUT_DIR "../phy/db"
set RPT_DIR    "../phy/rpt"
set SCR_DIR    "../phy/scr"
#we need a part directory where partitions are created
set PART_DIR   "../phy/db/part"
set SRC_DIR    "../syn/db/task2"

set LEF_FILE "${TECH_LEF_DIR}/22FDSOI_10M_2Mx_4Cx_2Bx_2Jx_LB_104cpp_tech.lef ${STDC_LEF_DIR}/GF22FDX_SC8T_104CPP_BASE_CSC28L.lef"
set MMMC_FILE "${SCR_DIR}/mmmc_gf22fdx.tcl"
set NETLIST_FILE "${SRC_DIR}/${TOP_NAME}.v"
if {[file exists "${SRC_DIR}/${TOP_NAME}.sdc"]} {
    set SDC_FILES "${SRC_DIR}/${TOP_NAME}.sdc"
} else {
    set SDC_FILES "../syn/constraints.sdc"
}

