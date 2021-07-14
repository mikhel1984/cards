#!/usr/bin/tclsh

# Correction for characters that are not available in the current keyboard.
# For example, use 'x' to denote the Esperanto-specific symbols. 
# Usage: ./correct.tcl filename
#
# 2021, Stanislav Mikhel

# characters for mapping
set special {
  Cx Ĉ Gx Ĝ Hx Ĥ Jx Ĵ Sx Ŝ Ux Ǔ
  cx ĉ gx ĝ hx ĥ jx ĵ sx ŝ ux ǔ
}

# global variables
set txt ""
set fname [lindex $argv 0]

# read file
if { [catch {open $fname} fid] } {
  puts "Cannot read file: $fname" 
  exit 1
} else {
  set txt [read $fid]
  close $fid
}

# convert and save
set fid [open $fname w]
puts $fid [string map $special $txt]
close $fid

puts Done!
