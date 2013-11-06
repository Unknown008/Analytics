# "." is the name of the current widget o_0
wm title . "Handicare"

# create label of widget named ".msg"
label .msg -justify left -text "Click on \"Browse\" to select a file name using the file selection dialog for cleansing." -anchor e

# put label in widget
pack .msg -side top

# Create frame within widget, add label and set position of frame
set f [frame .fr0]
pack $f -fill x -padx 1c -pady 3
pack [label $f.lab -text "Browse for the file to cleanse:"] -side left -anchor w -padx 1

# Number of entries. Default 1. Frame list
set entries 1
set fentries ""

# place input box in widget
pack [entry $f.ent -width 20 -textvariable fname] -side left -expand yes -fill x -anchor w -padx 2

# create and place buttons in widget (combination of above steps)
pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side left -anchor w -padx 2 -pady 5
pack [ttk::button $f.c -text "Start" -command "clean \$fname 1"] -side left -anchor w -padx 2 -pady 5


# create close button
set g [frame .g]
pack $g -fill x -side bottom -anchor s
pack [ttk::button $g.exit -text "Close" -command {exit}] -side right -anchor s
pack [ttk::button $g.more -text "More files..." -command "addNewEntries"] -side right -anchor s
pack [ttk::button $g.all -text "Clean all" -command "cleanAll"] -side right -anchor s

# proc to open file dialog box and fill in entry box for file path/name
proc fileDialog {ent} {
	global fentries
	# main file types we'll use
	set types {
		{"All files"		*}
		{"Text files"		.txt}
		{"CSV files"		.csv}
		{"Web files"		{.html .htm .xml}}
	}
	
	# not sure what this one does
	global selected_type
	if {![info exists selected_type]} {
		set selected_type "Tcl Scripts"
	}
	
	# file dialog command
	set file [tk_getOpenFile -filetypes $types -typevariable selected_type]
	
	# enter file path into entry box. Don't understand this one completely yet
	if {[string compare $file ""]} {
		if {[$ent select range 0 end] != ""} {
			set oldfile [$ent select range 0 end]
			set id [lsearch $fentries $oldfile]
			set fentries [lreplace $fentries $id $id $file]
		} else {
			lappend fentries $file
		}
		$ent delete 0 end
		$ent insert 0 $file
		$ent xview end
	}
	
	#creates an error without this one earlier on. Not sure if still applicable. To test
	unset file
}

# general proc to convert dd.mm.yyyy to dd/mm/yyyy
proc dates {group id} {
	set group [lreplace $group $id $id [regsub -all {\.} [lindex $group $id] "/"]]
	return $group
}

# general proc to convert ###.###.###,## to ###,###,###.## and apply debit/credit indicator
proc amount {group id} {
	set value [regsub {,} [regsub -all {\.} [lindex $group $id] ""] "."]
	set sign [lindex $group 17]
	if {$sign eq "H" || $sign eq "C" || $sign eq "Cr"} {set value "-$value"}
	return [linsert $group [incr id] $value]
}

# message box alerts
proc showMessageBox {level} {
	switch $level {
		1 {set button [tk_messageBox -title Complete -message "Operation complete!"]}
		2 {set button [tk_messageBox -title Warning -message "No file was selected!"]}
		3 {set button [tk_messageBox -title Warning -message "File name invalid!"]}
		4 {set button [tk_messageBox -title Warning -message "Cannot add more files!"]}
		5 {set button [tk_messageBox -title Bug -message "All right here..."]}
		default {}
	}
}

# core proc to clean file. Pretty messy atm
proc clean {file mode} {
	global frames
	# check for empty emtry box
	if {$file eq ""} {
		showMessageBox 2
		return
	}
	# check for valid file
	if {[catch {open $file r} fid]} {
		showMessageBox 3
		return
	}
	
	# extract file name from path
	regexp {/([^/]+(\.[^.]+))$} $file - filename ext
	
	# part number
	set part 1
	
	# open read and write files and debug file
	set data [open $file r]
	set output [open "$filename Cleansed.txt" w]
	
	set accno ""
	set trap 0
	set accdesc ""
	set tr 0
	set l 0
	set dtrap 0
	set result [list]
	puts $output "Account\tAcc Desc\tPosting Date\tDocument No.\tDescription\tSource No.\tVAT Amount\tDebit\tCredit\tBalance\tEntry No."
	
	while {[gets $data line] != -1} {
		if {[string range $line 0 73] == {<TD WIDTH="8%" Align=Right VAlign=Middle><B><FONT SIZE=1 FACE="Helvetica">} || [string range $line 0 62] == {<TD Align=Right VAlign=Middle><B><FONT SIZE=1 FACE="Helvetica">}} {
			set accno ""
			regexp {([0-9]+)<} $line -> accno
			set trap 1
			if {[info exist info]} {set info ""}
			continue
		}
		if {[string range $line 0 62] == {<TD WIDTH="25%" VAlign=Middle><B><FONT SIZE=1 FACE="Helvetica">} || [string range $line 0 50] == {<TD VAlign=Middle><B><FONT SIZE=1 FACE="Helvetica">}} {
			set accdesc ""
			regexp {([^<>]+)<} $line -> accdesc
			continue
		}
		if {$trap == 0} {continue}
		if {$line == "<TR>"} {
			set tr 1
			continue
		} elseif {$line == "</TR>"} {
			set tr 0
			set l 0
			continue
		}
		if {$tr} {
			if {$l % 2 == 1} {
				incr l
				set info ""
				continue
			}
			if {![regexp {([^<>]+)<} $line -> info]} {
				set result [list]
				set tr 0
				set info ""
				continue
			}
			if {$info == "&nbsp"} {set info ""}
			if {$info == "Posting Date"} {
				set info ""
				set tr 0
				continue
			}
			lappend result $info
			if {$l == 16} {
				puts $output "$accno\t$accdesc\t[join $result \t]"
				set result [list]
			}
			incr l
		}
	}
	close $output
	close $data
	if {$mode} {showMessageBox 1}
}

proc addNewEntries {} {
	global entries
	if {$entries > 3} {
		showMessageBox 4
		return
	}
	set f [frame ".fr$entries"]
	pack $f -fill x -padx 1c -pady 2
	pack [label $f.lab -text "Browse for the file to cleanse:"] -side left -padx 1 -pady 5
	pack [entry $f.ent -width 20 -textvariable "fname$entries"] -side left -expand yes -fill x -padx 2 -pady 5
	pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side left -padx 2 -pady 5
	pack [ttk::button $f.c -text "Start" -command "clean \$fname$entries 1"] -side right -padx 2 -pady 5

	incr entries
}

proc cleanAll {} {
	global fentries
	set errors [list "One or more files failed to be cleansed:"]
	foreach i $fentries {
		if {![catch {clean $i 0} fid]} {
			continue
		} else {
			lappend errors "- $i could not be cleaned because $fid."
		}
	}
	if {[llength $errors] == 1} {
		showMessageBox 1
	} else {
		set button [tk_messageBox -title Warning -message [join $errors "\n"]]
	}
}