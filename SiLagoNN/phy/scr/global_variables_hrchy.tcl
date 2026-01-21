set NUM_CPUS 8
set TOP_NAME drra_wrapper
set OUTPUT_DIR "../phy/db"
set RPT_DIR    "../phy/rpt"
set SCR_DIR    "../phy/scr"
set PART_DIR   "../phy/db/part"

if {[file exists "../syn/db/flat_20ns"]} {
    set SRC_DIR "../syn/db/flat_20ns"
} elseif {[file exists "../syn/db/task3"]} {
    set SRC_DIR "../syn/db/task3"
} else {
    # Fallback to a known location so SRC_DIR is always defined
    set SRC_DIR "../syn/db"
}

set STDC_CCS_DIR "/opt/pdk/gfip/22FDX-EXT/GF22FDX_SC8T_104CPP_BASE_CSC28L_FDK_RELV06R60/model/timing/ccs"
set TECH_LEF_DIR  "/opt/pdk/gf22/V1.0_4.1/PlaceRoute/Innovus/Techfiles/10M_2Mx_4Cx_2Bx_2Jx_LB"
set STDC_LEF_DIR  "/opt/pdk/gfip/22FDX-EXT/GF22FDX_SC8T_104CPP_BASE_CSC28L_FDK_RELV06R60/lef"
set STDC_QRC_DIR  "/opt/pdk/gf22/V1.0_4.1/PEX/QRC/10M_2Mx_4Cx_2Bx_2Jx_LBthick"

set OP_COD_LIB_BC "GF22FDX_SC8T_104CPP_BASE_CSC28L_FFG_0P72V_0P00V_0P00V_0P00V_M40C"
set OP_COD_LIB_TC "GF22FDX_SC8T_104CPP_BASE_CSC28L_TT_0P80V_0P00V_0P00V_0P00V_25C"
set OP_COD_LIB_WC "GF22FDX_SC8T_104CPP_BASE_CSC28L_SSG_0P72V_0P00V_0P00V_0P00V_125C"

set LIB_FILES_BC "${STDC_CCS_DIR}/${OP_COD_LIB_BC}_ccs.lib.gz"
set LIB_FILES_TC "${STDC_CCS_DIR}/${OP_COD_LIB_TC}_ccs.lib.gz"
set LIB_FILES_WC "${STDC_CCS_DIR}/${OP_COD_LIB_WC}_ccs.lib.gz"

set OP_COD_BC "FFG_0P72V_0P00V_0P00V_0P00V_M40C"
set OP_COD_TC "TT_0P80V_0P00V_0P00V_0P00V_25C"
set OP_COD_WC "SSG_0P72V_0P00V_0P00V_0P00V_125C"

set QRC_FILE_BC "${STDC_QRC_DIR}/FuncRCminDP/qrcTechFile"
set QRC_FILE_TC "${STDC_QRC_DIR}/nominal/qrcTechFile"
set QRC_FILE_WC "${STDC_QRC_DIR}/FuncRCmaxDP/qrcTechFile"

set LEF_FILE "${TECH_LEF_DIR}/22FDSOI_10M_2Mx_4Cx_2Bx_2Jx_LB_104cpp_tech.lef ${STDC_LEF_DIR}/GF22FDX_SC8T_104CPP_BASE_CSC28L.lef"
set MMMC_FILE "${SCR_DIR}/mmmc_gf22fdx.tcl"
set NETLIST_FILE "${SRC_DIR}/${TOP_NAME}.v"

if {[file exists "${SRC_DIR}/${TOP_NAME}.sdc"]} {
    set SDC_FILES "${SRC_DIR}/${TOP_NAME}.sdc"
} else {
    set SDC_FILES "../syn/constraints.sdc"
}

