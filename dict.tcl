#!/usr/bin/wish

# Make dictionary from the "cards".
#
#  2021, Stanislav Mikhel

array set nm [list dictionary "Словарь" \
  fwd " -> рус " bwd " рус -> "
]
# environment
global env
set env(hgt) 10

# title
wm title . $nm(dictionary)

# list of words
ttk::notebook .n
.n add [frame .n.f] -text $nm(fwd)
.n add [frame .n.r] -text $nm(bwd)

set env(wrd) [listbox .n.f.w -height $env(hgt) -yscrollcommand [list .n.f.ws set]]
scrollbar .n.f.ws -orient vertical -command [list .n.f.w yview]
grid .n.f.w  .n.f.ws -sticky news

set env(wrd1) [listbox .n.r.w -height $env(hgt) -yscrollcommand [list .n.r.ws set]]
scrollbar .n.r.ws -orient vertical -command [list .n.r.w yview]
grid .n.r.w  .n.r.ws -sticky news

# translation
set env(txt) [text .t -width 40 -height $env(hgt) -yscrollcommand [list .ts set]]
scrollbar .ts -orient vertical -command [list .t yview]

# current status
label .stat -textvariable env(nextState)

grid .n .t .ts -sticky news
grid .stat -columnspan 2 -sticky news

# Choose word
bind $env(wrd) <<ListboxSelect>> UpdateTxt
bind $env(wrd1) <<ListboxSelect>> UpdateTxt1

# Forward translatoin
proc UpdateTxt {} {
  global env
  # clear
  $env(txt) delete 0.0 end
  # new text
  set n [$env(wrd) curselection]
  if {$n ne ""} {               ;# TODO fix it
    set lst [lindex $env(words) $n]
    $env(txt) insert 1.0 "[lindex $lst 0]\n\n"
    $env(txt) insert end [join [lrange $lst 1 end-1] "\n"]
    set env(nextState) "[lindex $lst end]  |  #$env(len)"
  }
}

# Backward translation
proc UpdateTxt1 {} {
  global env
  # clear
  $env(txt) delete 0.0 end
  # new text
  set n [$env(wrd1) curselection]
  if {$n ne ""} {               ;# TODO fix it
    set lst [lindex $env(words1) $n]
    $env(txt) insert 1.0 "[lindex $lst 0]\n\n"
    $env(txt) insert end [join [lrange $lst 1 end-1] "\n"]
    set env(nextState) "[lindex $lst end]  |  #$env(len)"
  }
}

### Collect words ###

set env(words) ""

foreach f [glob *.card] {
  # read card
  set card [open $f]
  while { [gets $card line] >= 0 } {
    # check format
    if { [regexp {\-\-} $line] } {
      # prepare list
      set lst ""
      foreach x [split [string map {"--" \uffff} $line] \uffff] {
        lappend lst [string trim $x]
      }
      lappend lst "$f"
      # add
      lappend env(words) $lst
    }
  }
}
set env(len) [llength $env(words)]

set env(words1) [lsort -index 1 $env(words)]   ;# use second element
foreach w $env(words1) {
  $env(wrd1) insert end [lindex $w 1]
}

set env(words) [lsort $env(words)]             ;# use first element
foreach w $env(words) {
  $env(wrd) insert end [lindex $w 0]
}