# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================

# ==============================================================================
# Parameters Assignments
# ==============================================================================
set FRAMEWORK_ID      "pocket"
set FRAMEWORK_NAME    "Analogue Pocket"
set DEVICE_FAMILY     [get_global_assignment -name FAMILY]
set DEVICE_ID         [get_parameter -name NSX_DEVICE_ID]

set BUILD_ROOT        "../.build"
set PKG_ROOT          "../pkg"
set RTL_ROOT          "../rtl"
set PLATFORM_ROOT     "../platform/$FRAMEWORK_ID"
set TARGET_ROOT       "../target/$FRAMEWORK_ID"
set BSP_ROOT          "$PLATFORM_ROOT/bsp/$DEVICE_ID"

# ==============================================================================
# System and Core Top Level, Pinout and Constrains
# ==============================================================================
set_global_assignment -name SYSTEMVERILOG_FILE      "$BSP_ROOT/apf_top.sv"
set_global_assignment -name SDC_FILE                "$BSP_ROOT/sys_constr.sdc"
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE  "$PLATFORM_ROOT/pkgIndex.tcl"
set_global_assignment -name QIP_FILE                "$TARGET_ROOT/core.qip"
set BOARD_PINS [glob -nocomplain -types f [file join $BSP_ROOT/pinouts *.tcl]]
foreach pinout $BOARD_PINS {
    set_global_assignment -name SOURCE_TCL_SCRIPT_FILE \"$pinout\"
}

# Check if build_id.vh exists
checkBuildID

# ==============================================================================
# Framework Assignments
# ==============================================================================

# ==============================================================================
# Classic Timing Assignments
# ==============================================================================
set QUARTUS_VERSION    [lindex $quartus(version) 1]
set VERSION_COMPONENTS [split $QUARTUS_VERSION "."]
set VERSION_MAJOR      [lindex $VERSION_COMPONENTS 0]

if {$VERSION_MAJOR > 17} {
    set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON
    set_global_assignment -name TIMING_ANALYZER_REPORT_WORST_CASE_TIMING_PATHS OFF
    set_global_assignment -name DISABLE_LEGACY_TIMING_ANALYZER OFF
} else {
    set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
    set_global_assignment -name TIMEQUEST_REPORT_WORST_CASE_TIMING_PATHS OFF
}
