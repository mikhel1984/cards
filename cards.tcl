#!/usr/bin/wish

# Use "cards" for learning foreign words and phrases.
#
#  2021, Stanislav Mikhel

array set nm [list cards Карточки next Далее add Добавить del Удалить open Открыть \
  fst {Для добавления новых слов} \
  snd {Нажмите 'Добавить'} \
]
# environment
global dct

# window title
wm title . $nm(cards)
wm geometry . +0+20
image create photo icn -file "card.gif"
wm iconphoto . icn

# main window
frame .root 
pack .root -side top -fill x

# labels 
label .root.status -textvariable dct(varState) -relief raised
label .root.q -textvariable dct(varQ) \
  -font "Arial 16" -fg "red" -bg "white"
set dct(ans) [ttk::combobox .root.a -textvariable dct(varA) \
  -font "Arial 14" -foreground "blue" -background "white" \
  -values "" -justify center -postcommand {focus .root}]
pack .root.q -side top -fill x -expand true
pack .root.a -side top -fill x -expand true
pack .root.status -side top -fill x -expand true

# buttons
frame .btn
button .btn.next -text $nm(next) -width 15 -command NextString
button .btn.add -text $nm(add) -width 15 -command AddWord
button .btn.del -text $nm(del) -width 15 -command DelWord
button .btn.open -text $nm(open) -width 15 -command OpenCard
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
set dct(varQ) "Question"   ;# top text line
set dct(varA) "Answer"     ;# bottom text line
set dct(varState) ""       ;# status line
set dct(varTime) 0         ;# number of seconds
set dct(cardName) ""       ;# current card
set dct(cardList) ""       ;# list of questions - answers
set dct(currentList) ""    ;# list of current entries
set dct(currentLine) ""    ;# current element of base
set dct(directOrder) 0     ;# order or Q/A
set dct(currentInd) -1     ;# list index

# Load base from the .card file
proc ReadCard {fname} {
  global dct
  set pos [string last / $fname ]   ;# get substring
  set dct(cardName) [string range $fname [expr $pos+1] end]
  set dct(cardList) ""              ;# clear
  set dct(varTime) 0
  set infile [open $fname r]
  while { [gets $infile line] >= 0 } {
    # only lines that can be splitted
    if { [regexp {\-\-} $line] } {
      lappend dct(cardList) $line
    }
  }
  close $infile
}

# Choose random entry
proc GetRandom {} {
  global dct
  # ranom string
  set dct(currentLine) [lindex $dct(cardList) [expr {
    int(rand()*[llength $dct(cardList)])
  }]]
  # values 
  set dct(currentList) {}
  set ln [split [string map {"--" \uffff} $dct(currentLine)] \uffff]
  foreach x $ln {
    lappend dct(currentList) [string trim $x]
  }
}

# Swap question and answer
proc ChangeOrder {} {
  global dct
  set dct(directOrder) [expr !$dct(directOrder)]
  GetRandom
  set dct(varTime) 0
}

# Show next element of card
proc NextString {} {
  global dct nm
  if { $dct(currentInd) == 0 } {
    # show question
    set dct(varA) ""
    set dct(varQ) [lindex $dct(currentList) $dct(directOrder)]
    incr dct(currentInd)
  } elseif { $dct(currentInd) == 1 } {
    # show answer
    set dct(varA) [lindex $dct(currentList) [expr !$dct(directOrder)]]
    $dct(ans) config -values [lrange $dct(currentList) 2 end]
    incr dct(currentInd)
  } else {
    # unexpected index
    if {[llength $dct(cardList)] == 0} { ;# no words
      set dct(varQ) $nm(fst)
      set dct(varA) $nm(snd)
    } else {                       ;# get next Q/A
      GetRandom
      set dct(currentInd) 0
      NextString
    }
  }
}

# Update the status line information
proc UpdateStatus {} {
  global dct
  set tm [format "%d:%02d" [expr $dct(varTime)/60] [expr $dct(varTime)%60]]
  set ord {Dir Rev}
  set sep "   |   "
  set dct(varState) "$dct(cardName) $sep #[llength $dct(cardList)] $sep $tm $sep [lindex $ord $dct(directOrder)]"  
  incr dct(varTime)
  after 1000 UpdateStatus
}

# Load card, update view
proc OpenCard {} {
  global dct
  set types {
    {{Cards} {.card}}
  }
  set filename [tk_getOpenFile -filetypes $types]
  if {$filename ne ""} {
    ReadCard $filename 
    GetRandom
    set dct(currentInd) 0
    NextString
  }
}

# Delete current word
proc DelWord {} {
  global dct
  set answer [tk_messageBox -message "Delete" \
    -detail $dct(currentLine) -type yesno -icon question]
  if {$answer} {
    # remove line
    set n [lsearch $dct(cardList) $dct(currentLine)] 
    set dct(cardList) [lreplace $dct(cardList) $n $n]
    # make backup
    set fid [open "stock.card" a]
    puts $fid $dct(currentLine)
    close $fid
    # save updated base
    UpdateFile
  }
}

# Entry dialog window
proc EntryDialog {} {
  global res
  toplevel .add 
  label .add.lbl -width 40 -text "Q -- A"
  entry .add.q -width 40 -relief sunken 
  button .add.yes -text Yes -width 10 \
    -command { set res [ .add.q get ]}
  button .add.no -text No -width 10 \
    -command { set res "" }
  pack .add.lbl .add.q -side top -fill x
  pack .add.no .add.yes -side right
  bind .add.q <Return> [ .add.yes cget -command ]
  bind .add.q <Escape> [ .add.no cget -command ]
  focus .add.q
  set q ""
  wm title .add "Add"
  wm protocol .add WM_DELETE_WINDOW [ .add.no cget -command ]
  vwait res
  destroy .add
  return $res
}

# Add new word to the card
proc AddWord {} {
  global dct
  set res ""      ;# TODO fix it
  set answer [EntryDialog]
  if { [regexp {\-\-} $answer] } {
    # update list
    lappend dct(cardList) $answer
    # save
    UpdateFile
  }
}

# Save changes of the base into the file
proc UpdateFile {} {
  global dct
  set outfile [open $dct(cardName) w]
  foreach ln $dct(cardList) {
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
