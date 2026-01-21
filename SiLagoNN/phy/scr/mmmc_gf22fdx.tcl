create_library_set -name LIBSET_BC -timing [list $LIB_FILES_BC]
create_library_set -name LIBSET_TC -timing [list $LIB_FILES_TC]
create_library_set -name LIBSET_WC -timing [list $LIB_FILES_WC]

create_rc_corner -name rc_best -pre_route_res 1 -post_route_res 1 -pre_route_cap 1 -post_route_cap 1 -post_route_cross_cap 1 -post_route_clock_res 0 -post_route_clock_cap 0 -qrc_tech $QRC_FILE_BC
create_rc_corner -name rc_typ -pre_route_res 1 -post_route_res 1 -pre_route_cap 1 -post_route_cap 1 -post_route_cross_cap 1 -post_route_clock_res 0 -post_route_clock_cap 0 -qrc_tech $QRC_FILE_TC
create_rc_corner -name rc_worst -pre_route_res 1 -post_route_res 1 -pre_route_cap 1 -post_route_cap 1 -post_route_cross_cap 1 -post_route_clock_res 0 -post_route_clock_cap 0 -qrc_tech $QRC_FILE_WC

create_timing_condition -name cond_best -library_set LIBSET_BC -opcond $OP_COD_BC -opcond_library $OP_COD_LIB_BC
create_timing_condition -name cond_typ -library_set LIBSET_TC -opcond $OP_COD_TC -opcond_library $OP_COD_LIB_TC
create_timing_condition -name cond_worst -library_set LIBSET_WC -opcond $OP_COD_WC -opcond_library $OP_COD_LIB_WC

create_delay_corner -name WC_dc -rc_corner rc_worst -timing_condition {cond_worst}
create_delay_corner -name TC_dc -rc_corner rc_typ -timing_condition {cond_typ}
create_delay_corner -name BC_dc -rc_corner rc_best -timing_condition {cond_best}

create_constraint_mode -name functional -sdc_files $SDC_FILES

create_analysis_view -name AVF_RCWORST -constraint_mode functional -delay_corner WC_dc
create_analysis_view -name AVF_RCBEST -constraint_mode functional -delay_corner BC_dc
create_analysis_view -name AVF_RCTYP -constraint_mode functional -delay_corner TC_dc

set_analysis_view -setup "AVF_RCWORST" -hold "AVF_RCBEST AVF_RCTYP"
