# put the title
wm title . "Retain"

# create label of widget named ".msg" and put in widget
pack [label .msg -justify left -text "Select the two files to be cleansed" -anchor e] -side top

# Create frame within widget, add label and set position of frame
set f [frame .fr0]
set f1 [frame .fr1]
pack $f -fill x -padx 1c -pady 3
pack $f1 -fill x -padx 1c
pack [label $f.lab -text "Browse for the retain file to cleanse:" -width 40 -anchor w] -side left -anchor w -padx 1
pack [label $f1.lab -text "Browse for the available retain file to cleanse:" -width 40 -anchor w] -side left -anchor w -padx 1 -pady 5

# create and place buttons in widget
pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side right -anchor w -padx 2 -pady 5
pack [ttk::button $f1.b -text "Browse" -command "fileDialog $f1.ent"] -side right -anchor w -padx 2 -pady 5

# place input box in widget
pack [entry $f.ent -width 20 -textvariable fname] -side right -expand yes -fill x -anchor w -padx 2
pack [entry $f1.ent -width 20 -textvariable f1name] -side right -expand yes -fill x -anchor w -padx 2 -pady 5

# create close button
set g [frame .g]
pack $g -fill x -side bottom -anchor s
pack [ttk::button $g.exit -text "Close" -command {exit}] -side right -anchor s
pack [ttk::button $g.all -text "Start cleaning" -command "cleanAll \$fname \$f1name"] -side right -anchor s

# proc to open file dialog box and fill in entry box for file path/name
proc fileDialog {ent} {
	global fentries
	# main file types we'll use
	set types {
		{"Text files"		.txt}
		{"CSV files"		.csv}
		{"Web files"		{.html .htm .xml}}
		{"All files"		*}
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
		$ent delete 0 end
		$ent insert 0 $file
		$ent xview end
	}
	
	#creates an error without this one earlier on. Not sure if still applicable. To test
	unset file
}

# message box alerts
proc showMessageBox {level} {
	switch $level {
		1 {set button [tk_messageBox -title Complete -message "Operation complete!"]}
		2 {set button [tk_messageBox -title Warning -message "No file was selected!"]}
		3 {set button [tk_messageBox -title Warning -message "File name invalid!"]}
		4 {set button [tk_messageBox -title Bug -message "All right here..."]}
		default {}
	}
}

proc cleanAll {retainfile availablefile} {
	if {$retainfile == "" || $availablefile == ""} {
		showMessageBox 2
		return
	}
	if {[catch {open $retainfile r} fid]} {
		showMessageBox 3
		return
	}
	
	regexp {.*\/([\w\s]+\.\w+)$} $retainfile - rfilename
	regexp {.*\/([\w\s]+\.\w+)$} $availablefile - afilename
	
	set rfile [open $rfilename r]
	set afile [open $afilename r]
	set output [open "Consolidated retain.txt" w]
	
	# Skip title lines (3)
	set count 3
	while {[gets $rfile line] != -1} {
		gets $afile aline
		incr count -1
		if {$count == 0} {break}
	}
	
	while {[gets $rfile line] != -1} {
		if {$line == ""} {continue}
		set nline [split $line "\t"]
		if {[lindex $nline 0] != ""} {break}
		set hours [lrange $nline 24 49]
		set pass 0
		foreach n $hours {
			if {[string range $n 0 3] eq {Time}} {set pass 1; break}
			if {$n != 0} {
				set pass 1
				break
			}
		}
		if {$pass} {
			set nline [lreplace $nline 51 51]
			set nline [lreplace $nline 15 16]
			set nline [lreplace $nline 0 0]
			if {[lindex $nline 0] == ""} {
				set nline [lreplace $nline 0 0 "0"]
			}
			set nline [lreplace $nline 6 6 [regsub -all {''} [lindex $nline 6] "'"]]
			puts $output [join $nline "\t"]
		}
	}
	
	while {[gets $afile line] != -1} {
		if {$line == ""} {continue}
		set nline [split $line "\t"]
		if {[lindex $nline 0] != ""} {break}
		set hours [lrange $nline 18 43]
		set pass 0
		foreach n $hours {
			if {[string range $n 0 3] eq {Avai}} {break}
			if {$n != 0} {
				set pass 1
				break
			}
		}
		if {$pass} {
			set nline [linsert $nline 18 "" "" "" "" "" "Available"]
			set nline [lreplace $nline 15 16]
			set nline [lreplace $nline 0 0]
			if {[lindex $nline 0] == ""} {
				set nline [lreplace $nline 0 0 "0"]
			}
			set nline [lreplace $nline 6 6 [regsub -all {''} [lindex $nline 6] "'"]]
			set nline [lreplace $nline 15 15 [regsub -all {^([0-9]+)$} [lindex $nline 15] {'\1}]]
			puts $output [join $nline "\t"]
		}
	}
	
	close $output
	close $afile
	close $rfile
	showMessageBox 1
}