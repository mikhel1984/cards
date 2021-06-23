#!/usr/bin/wish

# Use "cards" for learning foreign words and phrases.
#
#  2021, Stanislav Mikhel

# window title
wm title . Cards 
wm geometry . +0+20
image create photo icn -file "card.gif"
wm iconphoto . icn

# main window
frame .root 
pack .root -side top -fill x

# labels 
label .root.status -textvariable varState ;# -relief ridge
label .root.q -textvariable varQ \
  -font "Arial 16" -fg "blue" -bg "white"
label .root.a -textvariable varA \
  -font "Arial 14" -fg "red" -bg "white" 
pack .root.q -side top -fill x -expand true
pack .root.a -side top -fill x -expand true
pack .root.status -side top -fill x -expand true

# buttons
frame .btn
button .btn.next -text "Далее" -width 15 -command NextString
button .btn.add -text "Добавить" -width 15 -command AddWord
button .btn.del -text "Удалить" -width 15 -command DelWord
button .btn.open -text "Открыть" -width 15 -command OpenCard
pack .btn.next -side left
pack .btn.add -side left
pack .btn.del -side left
pack .btn.open -side left
pack .btn -side bottom -fill x -expand true

# key bindings 
bind .root <Control-r> ChangeOrder
bind .root <Control-o> OpenCard
bind .root <space> NextString
bind .root <Control-q> exit
bind .root <Control-n> AddWord
bind .root <Delete> DelWord
focus .root

# global variables 
set varQ "Question"   ;# top text line
set varA "Answer"     ;# bottom text line
set varState ""       ;# status line
set varTime 0         ;# number of seconds
set cardName ""       ;# current card
set cardList ""       ;# list of questions - answers
set currentList ""    ;# list of current entries
set currentLine ""    ;# current element of base
set directOrder 1     ;# order or Q/A
set currentInd -1     ;# list index

# Load base from the .card file
proc ReadCard {fname} {
  global cardName cardList varTime 
  set pos [string last / $fname ]   ;# get substring
  set cardName [string range $fname [expr $pos+1] end]
  set cardList ""                   ;# clear
  set varTime 0
  set infile [open $fname r]
  while { [gets $infile line] >= 0 } {
    # only lines that can be splitted
    if { [regexp {\-\-} $line] } {
      lappend cardList $line
    }
  }
  close $infile
}

# Choose random entry
proc GetRandom {} {
  global cardList currentList directOrder currentLine
  # ranom string
  set currentLine [lindex $cardList [expr {
    int(rand()*[llength $cardList])
  }]]
  # values 
  set currentList [split [string map {"--" \uffff} $currentLine] \uffff]
  if { !$directOrder } {
    set currentList [lreverse $currentList]
  }
}

# Swap question and answer
proc ChangeOrder {} {
  global directOrder varTime
  set directOrder [expr !$directOrder]
  GetRandom
  set varTime 0
}

# Show next element of card
proc NextString {} {
  global currentList varQ varA cardList currentInd
  if { $currentInd == 0 } {        ;# show question
    set varA ""
    set varQ [string trim [lindex $currentList $currentInd]]
    incr currentInd
  } elseif { $currentInd == 1 } {  ;# show answer
    set varA [string trim [lindex $currentList $currentInd]]
    incr currentInd
  } else {
    if {[llength $cardList] == 0} { ;# no words
      set varQ "Для добавления новых слов"
      set varA "нажмите 'Добавить'"
    } else {                       ;# get next Q/A
      GetRandom
      set currentInd 0
      NextString
    }
  }
}

# Update the status line information
proc UpdateStatus {} {
  global cardList cardName varTime varState directOrder
  set tm [format "%d:%02d" [expr $varTime/60] [expr $varTime%60]]
  set ord "R D"
  set sep "   |   "
  set varState "$cardName $sep #[llength $cardList] $sep $tm $sep [lindex $ord $directOrder]"  
  incr varTime
  after 1000 UpdateStatus
}

# Load card, update view
proc OpenCard {} {
  global cardName currentInd
  set types {
    {{Cards} {.card}}
  }
  set filename [tk_getOpenFile -filetypes $types]
  if {$filename ne ""} {
    ReadCard $filename 
    GetRandom
    set currentInd 0
    NextString
  }
}

# Delete current word
proc DelWord {} {
  global currentLine cardList
  set answer [tk_messageBox -message "Delete" \
    -detail $currentLine -type yesno -icon question]
  if {$answer} {
    # remove line
    set n [lsearch $cardList $currentLine] 
    set cardList [lreplace $cardList $n $n]
    # save
    UpdateFile
  }
}

# Entry dialog window
proc EntryDialog {} {
  global res
  set q ""
  toplevel .add     ;# TODO rename
  label .add.lbl -width 40 -text "Q -- A"
  entry .add.q -width 40 -relief sunken 
  button .add.yes -text Yes -width 10 \
    -command { set res [ .add.q get ]}
  button .add.no -text No -width 10 \
    -command { set res "" }
  pack .add.lbl .add.q -side top -fill x
  pack .add.no .add.yes -side right
  focus .add.q
  set q ""
  wm protocol .add WM_DELETE_WINDOW { set res "" }
  vwait res
  destroy .add
  return $res
}

# Add new word to the card
proc AddWord {} {
  global cardList
  set res ""      ;# TODO fix it
  set answer [EntryDialog]
  puts $answer
  if { [regexp {\-\-} $answer] } {
    # update list
    lappend cardList $answer
    # save
    UpdateFile
  }
}

# Save changes of the base into the file
proc UpdateFile {} {
  global cardName cardList
  set outfile [open $cardName w]
  foreach ln $cardList {
    puts $outfile $ln
  }
  close $outfile
}

#### Execute ####

# open card 
catch {ReadCard "default.card"}
# set values
NextString
# timer 
UpdateStatus
