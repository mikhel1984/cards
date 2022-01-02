#!/usr/bin/wish

# Correction for characters that are not available in the current keyboard.
# For example, use 'x' to denote the Esperanto-specific symbols.
#
#  2021, Stanislav Mikhel

# characters for mapping
set special {
  Cx Ĉ Gx Ĝ Hx Ĥ Jx Ĵ Sx Ŝ Ux Ǔ
  cx ĉ gx ĝ hx ĥ jx ĵ sx ŝ ux ǔ
}
set lang "Esperanto"

# translate
array set nm [list convert "Замена" \
  convto "Преобразовать символы в" choose "Выберите файл"
]

# make window
wm title . $nm(convert)
image create photo icn -file "card.gif"
wm iconphoto . icn

label .map -text "$nm(convto)\n-= $lang =-" -padx 10 -pady 10
button .open -text $nm(choose) -command Convert
grid .map -sticky news
grid .open

# key binding
bind . <Return> Convert
bind . <Escape> exit

# Read file and convert characters
proc Convert {} {
  global special
  set types {
    {"Cards" ".card"}
    {"All" "*"}
  }
  set fname [tk_getOpenFile -filetypes $types]
  if {$fname ne ""} {
    # read 
    set fid [open $fname]
    set txt [read $fid]
    close $fid
    # convert and save
    set fid [open $fname w]
    puts $fid [string map $special $txt]
    close $fid
  }
}
