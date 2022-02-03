#!/usr/bin/wish

# Use "cards" for learning foreign words and phrases.
#
#  2021, Stanislav Mikhel

# translate
array set nm [list cards Карточки next Далее add Добавить del Удалить open Открыть \
  fst {Для добавления новых слов} \
  snd {Нажмите 'Добавить'} \
]
# environment
global env

# window title
wm title . $nm(cards)
wm geometry . +0+20
image create photo icn -file "card.gif"
wm iconphoto . icn

# labels 
label .status -textvariable env(varState) -relief raised
label .q -textvariable env(varQ) \
  -font "Arial 16" -fg "red" -bg "white"
set env(ans) [ttk::combobox .a -textvariable env(varA) \
  -font "Arial 14" -foreground "blue" -background "white" \
  -values "" -justify center -postcommand {focus .q}]

# buttons
button .next -text $nm(next) -width 15 -command NextString
button .wadd -text $nm(add) -width 15 -command AddWord
button .del -text $nm(del) -width 15 -command DelWord
button .open -text $nm(open) -width 15 -command OpenCard

grid .q -columnspan 4 -sticky news
grid .a -columnspan 4 -sticky news
grid .next .wadd .del .open -sticky news
grid .status -columnspan 4 -sticky news

# key bindings 
bind .q <Control-r> ChangeOrder
bind .q <Control-o> OpenCard
bind .q <space> NextString
bind .q <Control-q> exit
bind .q <Control-n> AddWord
bind .q <Control-g> MakeGroup
bind .q <Delete> DelWord
focus .q

# global variables
set env(varQ) "Question"   ;# top text line
set env(varA) "Answer"     ;# bottom text line
set env(varState) ""       ;# status line
set env(varTime) 0         ;# number of seconds
set env(cardName) ""       ;# current card
set env(cardList) ""       ;# list of questions - answers
set env(currentList) ""    ;# list of current entries
set env(currentLine) ""    ;# current element of base
set env(directOrder) 0     ;# order or Q/A
set env(currentInd) -1     ;# list index

# Load base from the .card file
proc ReadCard {fname} {
  global env
  set pos [string last / $fname ]   ;# get substring
  set env(cardName) [string range $fname [expr $pos+1] end]
  set env(cardList) ""              ;# clear
  set env(varTime) 0
  set infile [open $fname r]
  while { [gets $infile line] >= 0 } {
    # only lines that can be splitted
    if { [regexp {\-\-} $line] } {
      lappend env(cardList) $line
    }
  }
  close $infile
}

# Choose random entry
proc GetRandom {} {
  global env
  # ranom string
  set env(currentLine) [lindex $env(cardList) [expr {
    int(rand()*[llength $env(cardList)])
  }]]
  # values 
  set env(currentList) {}
  set ln [split [string map {"--" \uffff} $env(currentLine)] \uffff]
  foreach x $ln {
    lappend env(currentList) [string trim $x]
  }
}

# Swap question and answer
proc ChangeOrder {} {
  global env
  set env(directOrder) [expr !$env(directOrder)]
  GetRandom
  set env(varTime) 0
  # clear lines
  set env(varA) ""
  set env(varQ) ""
}

# Show next element of card
proc NextString {} {
  global env nm
  if { $env(currentInd) == 0 } {
    # show question
    set env(varA) ""
    set env(varQ) [lindex $env(currentList) $env(directOrder)]
    incr env(currentInd)
  } elseif { $env(currentInd) == 1 } {
    # show answer
    set env(varA) [lindex $env(currentList) [expr !$env(directOrder)]]
    $env(ans) config -values [lrange $env(currentList) 2 end]
    incr env(currentInd)
  } else {
    # unexpected index
    if {[llength $env(cardList)] == 0} { ;# no words
      set env(varQ) $nm(fst)
      set env(varA) $nm(snd)
    } else {                       ;# get next Q/A
      GetRandom
      set env(currentInd) 0
      NextString
    }
  }
}

# Update the status line information
proc UpdateStatus {} {
  global env
  set tm [format "%d:%02d" [expr $env(varTime)/60] [expr $env(varTime)%60]]
  set ord {Dir Rev}
  set sep "   |   "
  set env(varState) "$env(cardName) $sep #[llength $env(cardList)] $sep $tm $sep [lindex $ord $env(directOrder)]"  
  incr env(varTime)
  after 1000 UpdateStatus
}

# Load card, update view
proc OpenCard {} {
  global env
  set types {
    {"Cards" ".card"}
    {"All" "*"}
  }
  set filename [tk_getOpenFile -filetypes $types]
  if {$filename ne ""} {
    ReadCard $filename 
    GetRandom
    set env(currentInd) 0
    NextString
  }
}

# Delete current word
proc DelWord {} {
  global env
  set answer [tk_messageBox -message "Delete" \
    -detail $env(currentLine) -type yesno -icon question]
  if {$answer} {
    # remove line
    set n [lsearch $env(cardList) $env(currentLine)] 
    set env(cardList) [lreplace $env(cardList) $n $n]
    if {$env(cardName) ne "GROUP"} {
      # make backup
      set fid [open "stock.card" a]
      puts $fid $env(currentLine)
      close $fid
      # save updated base
      UpdateFile
    }
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
  global env
  set res ""      ;# TODO fix it
  set answer [EntryDialog]
  if { [regexp {\-\-} $answer] } {
    # update list
    lappend env(cardList) $answer
    # save
    if {$env(cardName) ne "GROUP"} {
      UpdateFile
    }
  }
}

# Save changes of the base into the file
proc UpdateFile {} {
  global env
  set outfile [open $env(cardName) w]
  foreach ln $env(cardList) {
    puts $outfile $ln
  }
  close $outfile
}

# Prepare group of 7 elements
proc MakeGroup {} {
  global env
  set base $env(cardList) 
  # remove random lines
  while {[llength $base] > 7} {
    set n [expr { int(rand()*[llength $base]) }]
    set base [lreplace $base $n $n]
  }
  # update base
  set env(varTime) 0
  set env(cardName) "GROUP"
  set env(cardList) $base
  GetRandom
  set env(currentInd) 0
  NextString
}

#### Execute ####

# open card 
catch {ReadCard "default.card"}
# set values
NextString
# timer 
UpdateStatus
