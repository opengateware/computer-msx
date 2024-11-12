# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# 
# Platform Global/Location/Instance Assignments
# 
# ==============================================================================
# Hardware Information
# ==============================================================================
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CEBA4F23C8
set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 484
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 8

# ==============================================================================
# Hardware Parameters
# ==============================================================================
set_parameter -name NSX_DEVICE_ID "pocket"
set_parameter -name NSX_DEVICE_NAME "Analogue Pocket"
set_parameter -name NSX_DEVICE_PLATFORM "Intel"
set_parameter -name NSX_DEVICE_MAKER "Analogue"
set_parameter -name NSX_DEVICE_USE_HPS OFF

# ==============================================================================
# Setup BSP
# ==============================================================================
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE "../platform/pocket/bsp/setup.tcl"

# ==============================================================================
# Classic Timing Assignments
# ==============================================================================
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85

# ==============================================================================
# Assembler Assignments
# ==============================================================================
set_global_assignment -name GENERATE_RBF_FILE ON
set_global_assignment -name USE_CONFIGURATION_DEVICE ON
set_global_assignment -name ENABLE_OCT_DONE OFF

# ==============================================================================
# Fitter Assignments
# ==============================================================================
set_global_assignment -name ENABLE_CONFIGURATION_PINS OFF
set_global_assignment -name ENABLE_BOOT_SEL_PIN OFF
set_global_assignment -name STRATIXV_CONFIGURATION_SCHEME "PASSIVE SERIAL"
set_global_assignment -name ACTIVE_SERIAL_CLOCK FREQ_100MHZ

# ==============================================================================
# Power Estimation Assignments
# ==============================================================================
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"

# ==============================================================================
# Advanced I/O Timing Assignments
# ==============================================================================
set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -rise
set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -fall
set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -rise
set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -fall

# ==============================================================================
# Scripts
# ==============================================================================
set_global_assignment -name PRE_FLOW_SCRIPT_FILE    "quartus_sh:$PLATFORM_ROOT/scripts/pre_flow.tcl"
set_global_assignment -name POST_FLOW_SCRIPT_FILE   "quartus_sh:$PLATFORM_ROOT/scripts/post_flow.tcl"
