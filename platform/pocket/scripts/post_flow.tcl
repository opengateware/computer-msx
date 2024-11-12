# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: post-flow.tcl
# @brief: POST_FLOW_SCRIPT_FILE - Runs after a flow finishes
# ==============================================================================

source ../platform/pocket/scripts/functions.tcl

set project_name [lindex $quartus(args) 1]
set revision [lindex $quartus(args) 2]

if {[project_exists $project_name]} {
    if {[string equal "" $revision]} {
        project_open $project_name -revision [get_current_revision $project_name]
    } else {
        project_open $project_name -revision $revision
    }
} else {
    post_message -type error "Project $project_name does not exist"
    exit
}

set device     [get_global_assignment -name DEVICE]
set outpath    [get_global_assignment -name PROJECT_OUTPUT_DIRECTORY]
set device_hps [get_parameter -name NSX_DEVICE_USE_HPS]
set use_hps    [expr {$device_hps eq "ON" ? 1 : 0}]

if [is_project_open] {
    project_close
}

generateCDF $revision $outpath $device $use_hps
reverseRBF  $revision $outpath