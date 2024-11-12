# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: functions.tcl
# @brief: Collection of TCL Functions for the Framework
# ==============================================================================
package require Tcl
package require json
package require fileutil

puts "Functions Loaded!"

# @brief: Make an HTTP Request
# Note: HTTP/TLS package is outdated use cURL instead
# Example:
#   set http_data "[httpGet https://example.com]"
proc httpGet {url} {
    set command "curl -s $url"
    set http_data [exec {*}$command]
    return $http_data
}

# @brief: Get a JSON response via HTTP
# Example:
#   set json_data "[httpGetJSON https://www.howsmyssl.com/a/check]"
#   set tls_version [dict get $json_data tls_version]
proc httpGetJSON {url} {
    set http_data "[httpGet $url]"
    set json_data [json::json2dict $http_data]
    return $json_data
}

# @brief: Get a JSON response via HTTP
# Example:
#   set tag_name "[gitLatestReleaseTag "opengateware" "arcade-congo"]"
proc gitLatestReleaseTag {owner repo} {
    set json_data "[httpGetJSON https://api.github.com/repos/$owner/$repo/releases/latest]"
    set tag_name [dict get $json_data tag_name]
    return $tag_name
}

# @brief: Get HDL Files (SV, V, VHD and QIP)
proc getHDLFiles {folder} {
    set file_list [glob -nocomplain -types f [file join $folder *.{sv,v,vhd,qip}]]
    if {[llength $file_list] == 0} {
        puts "No files found with the specified extensions in directory: $PLATFORM_ROOT"
    } else {
        set result {}
        foreach file $file_list {
            lappend result $file
        }
        return $result
    }
}

# @brief: Get the current date in the format YYYYMMDD
# (see: https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-examples/quartus/tcl-date-time-stamp.html)
proc getDate {} {
    set buildDate [ clock format [ clock seconds ] -format %Y%m%d ]
    return $buildDate
}

# @brief: Get the current date in the format YYYY-MM-DD
proc getDateDashed {} {
    set buildDate [ clock format [ clock seconds ] -format %Y-%m-%d ]
    return $buildDate
}

# @brief: Get the current time in the format HHMMSS
proc getTime {} {
    set buildTime [ clock format [ clock seconds ] -format %H%M%S ]
    return $buildTime
}

# @brief: Get the git hashtag for this project
proc getDigest {} {
    set buildHash ""
    if {[catch {exec git rev-parse --short=8 HEAD}]} {
        puts "No git version control in the project"
        set buildHash FEEDC0DE
    } else {
        set buildHash [exec git rev-parse --short=8 HEAD]
    }
    return $buildHash
}

# @brief: Get the git hashtag for this project
proc getLastTag {} {
    set buildTag ""
    if {[catch {exec git describe --abbrev=0 --tags}]} {
        puts "No git tag in the project"
        set buildTag "0.0.0"
    } else {
        set buildTag [exec git describe --abbrev=0 --tags]
    }
    return $buildTag
}

# @brief: Creates a folder if it doesn't already exist
proc createFolder {folder_path} {
    if {![file isdirectory $folder_path]} {
        file mkdir $folder_path
    }
}

# @brief: Search and Replace a string
# Example:
#   set my_string "hello world"
#   set new_string [searchReplace $my_string "world" "TCL"]
proc searchReplace {string pattern replacement} {
    set result [::tcl::string::map [list $pattern $replacement] $string]
    return $result
}

# @brief: Copies the input file to the output file
proc copyFile {input_path output_path} {
    file copy -force $input_file $output_file
}

# @brief: Generate a Build ID
# Create a build_id.vh file containing build date and git commit digest
proc generateBuildID {} {
    # Set the metadata for this project
    set buildDate [getDate]
    set buildHash [getDigest]

    # Create a Verilog Header file for output
    set outputFileName "../target/pocket/build_id.vh"
    set outputFile [open $outputFileName "w"]

    # Output the Verilog source
    puts $outputFile "// Build ID Verilog Module"
    puts $outputFile "`define BUILD_DATE \"$buildDate\""
    puts $outputFile "`define BUILD_HASH \"$buildHash\""
    close $outputFile

    # Send confirmation message to the Messages window
    post_message "Build ID Verilog Header File generated: [pwd]/$outputFileName"
}

# @brief: Generate a JTAG Chain Description File.
# Create a .cdf file to be used with Quartus Prime Programmer
proc generateCDF {revision outpath device use_hps} {
    set outputFileName "$revision.cdf"
    set outputFile [open $outputFileName "w"]

    puts $outputFile "JedecChain;"
    puts $outputFile "  FileRevision(JESD32A);"
    puts $outputFile "  DefaultMfr(6E);"
    puts $outputFile ""
    if {$use_hps} {
        puts $outputFile "  P ActionCode(Ign)"
        puts $outputFile "    Device PartName(SOCVHPS) MfrSpec(OpMask(0));"
    }
    puts $outputFile "  P ActionCode(Cfg)"
    puts $outputFile "    Device PartName($device) Path(\"$outpath/\") File(\"$revision.sof\") MfrSpec(OpMask(1));"
    puts $outputFile "ChainEnd;"
    puts $outputFile ""
    puts $outputFile "AlteraBegin;"
    puts $outputFile "  ChainType(JTAG);"
    puts $outputFile "AlteraEnd;"
    close $outputFile

    # Send confirmation message to the Messages window
    post_message "JTAG Chain Description File generated: [pwd]/$outputFileName"
}

# @brief: Generate a Build ID
# Create a build_id.mif file containing build date, time and unique id
proc generateBuildID_MIF {} {
    set buildDate [getDate]
    set buildTime [getTime]
    set buildUnique [expr {int(rand()*(4294967295))}]

    set buildDateNoLeadingZeros [string trimleft $buildDate "0"]
    set buildTimeNoLeadingZeros [string trimleft $buildTime "0"]
    set buildDate4Byte          [format "%08d" $buildDateNoLeadingZeros]
    set buildTime4Byte          [format "%08d" $buildTimeNoLeadingZeros]
    set buildUnique4Byte        [format "%08x" $buildUnique]

    # Create a Memory Initialization File for output
    set outputFileName "../target/pocket/build_id.mif"
    set outputFile [open $outputFileName "w"]

    # Output the MIF file
    puts $outputFile "-- begin_signature"
    puts $outputFile "-- Build_ID"
    puts $outputFile "-- end_signature"
    puts $outputFile "DEPTH=256;"
    puts $outputFile "WIDTH=32;"
    puts $outputFile ""
    puts $outputFile "ADDRESS_RADIX=HEX;"
    puts $outputFile "DATA_RADIX=HEX;"
    puts $outputFile ""
    puts $outputFile "CONTENT"
    puts $outputFile "BEGIN"
    puts $outputFile "\t0E0 :\t$buildDate4Byte;"
    puts $outputFile "\t0E1 :\t$buildTime4Byte;"
    puts $outputFile "\t0E2 :\t$buildUnique4Byte;"
    puts $outputFile "END;"

    # Close file to complete write
    close $outputFile

    # Send confirmation message to the Messages window
    post_message "Build ID Memory Initialization File generated: [pwd]/$outputFileName"
}

# @brief: Generate build_id.vh if doesn't exists (avoid having to start compilation to execute pre-flow)
proc checkBuildID {} {
    # set outputVerilog "../target/pocket/build_id.vh"
    # if {![file exists $outputVerilog]} { generateBuildID }
    set outputMIF "../target/pocket/build_id.mif"
    if {![file exists $outputMIF]} { generateBuildID_MIF }
}

# @brief: Open binary file and load into a Hex value string
proc readBinaryFile {file_path} {
    set file [open $file_path rb]
    set content [read $file]
    close $file

    set bytes [list]
    foreach byte [split $content ""] {
        lappend bytes [format "%02X" [scan $byte %c]]
    }

    return $bytes
}

# @brief: Reverse bytes required for the Analogue Pocket
proc reverseBits {bytes} {
    set reversed_values [list]
    foreach byte $bytes {
        set decimal_value [scan $byte %x]
        set reversed_decimal_value 0
        for {set i 0} {$i < 8} {incr i} {
            set bit [expr {($decimal_value >> $i) & 1}]
            set reversed_decimal_value [expr {($reversed_decimal_value << 1) | $bit}]
        }
        lappend reversed_values [format "%02X" $reversed_decimal_value]
    }
    return $reversed_values
}

# @brief: Convert hex values to binary and save into a file
proc saveBinaryFile {bytes output_file} {
    set file [open $output_file wb]
    foreach byte $bytes {
        set byte [binary format c [scan $byte %x]]
        puts -nonewline $file $byte
    }
    close $file
    post_message "Reversed Bitstream File generated: [pwd]/$output_file."
}

# @brief: Create a reversed RBF required for the Analogue Pocket
proc reverseRBF {revision outpath} {
    global BUILD_ROOT
    global DEVICE_ID
    createFolder $BUILD_ROOT
    set bytes      [readBinaryFile "$outpath/$revision.rbf"]
    set bytes_r    [reverseBits $bytes]
    set rbf_name   [searchReplace $revision "_$DEVICE_ID" ""]
    set target_dir [getCoreFolderName]
    if {[string equal "" $target_dir]} {
        saveBinaryFile $bytes_r "$BUILD_ROOT/$rbf_name.rbf_r"
    } else {
        saveBinaryFile $bytes_r "$BUILD_ROOT/Cores/$target_dir/$rbf_name.rbf_r"
    }
}

# @brief: Check if file contains a file extension that should be ignored
proc isExtIgnored {file_path} {
    set ignore_extensions {.gitkeep .png .rom}
    set file_extension [string tolower [file extension $file_path]]
    if {[lsearch -exact $ignore_extensions $file_extension] != -1} {
        return 1;# File is ignored
    } else {
        return 0;# File is not ignored
    }
}

# @brief: Create a reversed RBF required for the Analogue Pocket
proc getRelativePath {base_path path} {
    set base_parts [split $base_path "/"]
    set path_parts [split $path "/"]

    while {[llength $base_parts] > 0 && [llength $path_parts] > 0 && [lindex $base_parts 0] eq [lindex $path_parts 0]} {
        set base_parts [lrange $base_parts 1 end]
        set path_parts [lrange $path_parts 1 end]
    }

    set relative_path [concat [lrepeat [llength $base_parts] ".."] $path_parts]
    return [join $relative_path "/"]
}

# @brief: Copy the entire directory structure and files from the source
# to the target directory recursively, creating any necessary folders
# along the way
proc copyDirectory {source_dir target_dir} {
    if {![file isdirectory $target_dir]} {
        file mkdir $target_dir
    }

    set files [glob -nocomplain -directory $source_dir -type f *]
    foreach file $files {
        set relative_path [getRelativePath $source_dir $file]
        set target_path [file join $target_dir $relative_path]
        set target_dir_path [file dirname $target_path]

        if {![file isdirectory $target_dir_path]} {
            file mkdir $target_dir_path
        }

        if {[isExtIgnored $file]} {
            puts "File ignored: $file"
            continue
        } else {
            file copy -force $file $target_path
        }
    }

    set subdirs [glob -nocomplain -directory $source_dir -type d *]
    foreach subdir $subdirs {
        set relative_path [getRelativePath $source_dir $subdir]
        set target_path [file join $target_dir $relative_path]

        copyDirectory $subdir $target_path
    }
}

# @brief: Get the <Author.Corename> folder from BUILD_ROOT/Cores
proc getCoreFolderName {} {
    global BUILD_ROOT
    set cores_path "$BUILD_ROOT/Cores"
    set cores_folders [glob -nocomplain -directory $cores_path -type d *]
    set num_cores [llength $cores_folders]

    if {$num_cores == 1} {
        set folder_name [file tail [lindex $cores_folders 0]]
        return $folder_name
    } elseif {$num_cores == 0} {
        post_message "No folder found inside $cores_path"
        return ""
    } else {
        post_message "Multiple folders found inside $cores_path"
        return ""
    }
}

# @brief: Update the core.json file with Version and Release Date
# Example:
#   updateVersionReleaseDate "1.0.0"
proc updateVersionReleaseDate {version} {
    set file_path "core.json"
    set release_date [getDateDashed]

    if {[file exists $file_path]} {
        set file_handle [open $file_path "r+"]
        set file_content [read $file_handle]

        set updated_content [string map [list "<%- VERSION %>" $version "<%- RELEASE_DATE %>" $release_date] $file_content]

        seek $file_handle 0
        puts -nonewline $file_handle $updated_content
        close $file_handle

        puts "Updated $file_path with version: $version and release date: $release_date."
    } else {
        puts "File $file_path does not exist."
    }
}
