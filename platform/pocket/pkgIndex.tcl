# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: pkgIndex.tcl
# @brief: Collection of TCL Functions for the Framework
# ==============================================================================

source $PLATFORM_ROOT/scripts/functions.tcl

set ignore_list {}
set pkg_proms {}
set pkg_modules [list    \
    "audio"              \
    "audio/filters"      \
    "video"              \
    "interface"          \
    "interface/keyboard" \
    "megafunctions"      \
    "memory"             \
    "peripherals"        \
    "support"            \
    "helpers"
]

switch $DEVICE_FAMILY {
    "Cyclone V" {
        puts "Cyclone V"
    }
    default {
        puts "Unknown Device Family"
    }
}

switch $DEVICE_ID {
    "pocket" {
        puts "This is an Analogue Pocket - $PLATFORM_ROOT"
    }
    default {
        puts "Unknown Device"
    }
}

foreach folder $pkg_modules {
    set platform_files [getHDLFiles "$PLATFORM_ROOT/$folder"]
    foreach file $platform_files {
        if {$file in $ignore_list} {
            continue
        } else {
            set ext [file extension $file]
            set is_pll [string match "pll*"  $file]
            if {$is_pll && $ext eq ".v"} {
                continue
            }
            set is_mf [string match "mf*"  $file]
            if {$is_mf && $ext eq ".v"} {
                continue
            }
            switch $ext {
                ".sv"  { set_global_assignment -name SYSTEMVERILOG_FILE \"$file\" }
                ".v"   { set_global_assignment -name VERILOG_FILE       \"$file\" }
                ".vhd" { set_global_assignment -name VHDL_FILE          \"$file\" }
                ".qip" { set_global_assignment -name QIP_FILE           \"$file\" }
            }
        }
    }
}
