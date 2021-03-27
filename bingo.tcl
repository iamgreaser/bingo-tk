#!/usr/bin/env tclsh
# bingo.tcl - Bingo!
# by Ben "GreaseMonkey" Russell, 2021.
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

package require Tk

set bingo_square_pool {}
set grid_w 5
set grid_h 5

proc init_main_window {} {
    wm title . "Bingo!"

    foreach child [winfo children .] { destroy $child }

    menu .menubar -tearoff 0 -type menubar
        menu .menubar.file -tearoff 0 -type normal
            .menubar add cascade -menu .menubar.file -label "File"
            .menubar.file add command -label "Reroll" -command reroll_squares
            .menubar.file add separator
            .menubar.file add command -label "Load" -command load_from_file_chooser
            .menubar.file add separator
            .menubar.file add command -label "Quit" -command { exit 0 }
        #menu .menubar.help -tearoff 0 -type normal
        #    .menubar add cascade -menu .menubar.help -label "Help"
        #    .menubar.help add command -label "Instructions" -command show_help
        .menubar add command -label "Help" -command show_help
    . configure -menu .menubar

    global grid_w grid_h

    grid [ttk::frame .squares] -row 5 -column 5 -sticky nswe
    grid rowconfigure . 5 -weight 1
    grid columnconfigure . 5 -weight 1
    for {set y 0} {$y < $grid_h} {incr y} {
        grid rowconfigure .squares $y -weight 1 -minsize 130
        for {set x 0} {$x < $grid_w} {incr x} {
            grid columnconfigure .squares $x -weight 1 -minsize 130 ;# Lazy, but it works --GM
            set sq .squares.x${x}y${y}
            set tname "bingo_square_x${x}y${y}_label"
            set vname "bingo_square_x${x}y${y}_value"
            global $tname $vname
            set $tname "($x, $y)"
            set $vname 0
            grid [checkbutton $sq \
                -borderwidth 5 \
                -indicatoron false \
                -font {-family TkDefaultFont -size 10 -weight bold} \
                -anchor c \
                -wraplength 110 \
                -background #000000 \
                -foreground #FFFFFF \
                -activebackground #00AA00 \
                -activeforeground #FFFFFF \
                -selectcolor #00AA00 \
                -variable $vname \
                -textvar $tname \
            ] -column $x -row $y -sticky nswe
        }
    }
}

proc load_from_filename {fname} {
    set fp [open $fname r]
    try {
        set new_lines [list]
        while {[gets $fp line] >= 0} {
            set line [string trim $line]
            if {$line ne ""} {
                lappend new_lines $line
            }
        }
        puts "Line count: [llength $new_lines]"

        global bingo_square_pool
        set bingo_square_pool $new_lines
        reroll_squares
    } finally {
        close $fp
    }

    return
}

proc load_from_file_chooser {} {
    set fname [tk_getOpenFile -filetypes {
        {{Bingo Lists} .bingo}
        {{All Files} *}
    }]
    if {$fname eq ""} { return }

    load_from_filename $fname
}

proc reroll_squares {} {
    global grid_w grid_h
    global bingo_square_pool

    set square_count [expr {$grid_w*$grid_h}]
    set subpool $bingo_square_pool

    # If the pool is too small, then add extras.
    set i 0
    while {[llength $subpool] < $square_count} {
        incr i
        lappend subpool "ADD $i MORE"
    }

    # Shuffle the new pool.
    set len [llength $subpool]
    for {set i 0} {($i+1) < $len} {incr i} {
        set j [expr {int(floor(rand()*($len-($i))))+($i)}]
        set t [lindex $subpool $i]
        lset subpool $i [lindex $subpool $j]
        lset subpool $j $t
    }

    # Draw the first W x H squares.
    set i 0
    for {set y 0} {$y < $grid_h} {incr y} {
        for {set x 0} {$x < $grid_w} {incr x} {
            #set sq .squares.x${x}y${y}
            set tname "bingo_square_x${x}y${y}_label"
            set vname "bingo_square_x${x}y${y}_value"
            global $tname $vname
            set $vname 0
            set $tname [lindex $subpool $i]
            incr i
        }
    }
}

proc show_help {} {
    if {[catch {.help configure}]} {
        toplevel .help
        grid [text .help.text] -row 0 -column 0 -sticky nswe
        grid [ttk::button .help.ok_button -text "OK" -command { destroy .help }] -row 1 -column 0
        grid rowconfigure .help 0 -weight 1
        grid columnconfigure .help 0 -weight 1
    }
    .help.text configure -state normal
    .help.text delete 1.0 end
    set lines {
        {}
        {{Bingo!} title}
        {{by Ben "GreaseMonkey" Russell, 2021} author}
        {}
        {{Instructions} h1}
        {{Load a *.bingo file and enjoy some bingo.}}
        {{Click on a square to mark or unmark it.}}
        {}
        {{Make your own!} h1}
        {{1. Put some lines into a text editor, one line per square.}}
        {{   Lines containing nothing but whitespace are ignored.}}
        {{2. Save it as a *.bingo file.}}
        {{3. Load it into bingo.tcl.}}
        {{The format is handled by the load_from_filename proc,}}
        {{so if you want to know exactly how it works, read that.}}
        {}
    }
    .help.text tag configure title -font {-family monospace -size 20}
    .help.text tag configure author -foreground #CC0000
    .help.text tag configure h1 -font {-family monospace -size 16}
    foreach line $lines {
        if {$line eq ""} {
            .help.text insert end "\n"
        } else {
            set tag ""
            lassign $line text tag
            if {$tag eq ""} {
                .help.text insert end "  $text\n"
            } else {
                .help.text insert end "  " {} "$text\n" [list $tag]
            }
        }
    }
    .help.text configure -state disabled
    wm attributes .help -topmost true
    wm manage .help
}

init_main_window
if {[llength $argv] >= 1} {
    load_from_filename [lindex $argv 0]
} else {
    load_from_file_chooser
}
