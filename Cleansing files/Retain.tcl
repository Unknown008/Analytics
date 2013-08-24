# put the title
wm title . "Retain"

# create label of widget named ".msg" and put in widget
lpack [abel .msg -justify left -text "Select the two files to be cleansed" -anchor e] -side top

# Create frame within widget, add label and set position of frame
set f [frame .fr0]
set f1 [frame .fr1]
pack $f -fill x -padx 1c -pady 3
pack $f -fill x -padx 1c -pady 2
pack [label $f.lab -text "Browse for the retain file to cleanse:"] -side left -anchor w -padx 1
pack [label $f1.lab -text "Browse for the available retain file to cleanse:"] -side left -anchor w -padx 1 -pady 5

# place input box in widget
pack [entry $f.ent -width 20 -textvariable fname] -side left -expand yes -fill x -anchor w -padx 2
pack [entry $f1.ent -width 20 -textvariable f1name] -side left -expand yes -fill x -anchor w -padx 2 -pady 5

# create and place buttons in widget
pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side left -anchor w -padx 2 -pady 5
pack [ttk::button $f1.b -text "Browse" -command "fileDialog $f1.ent"] -side left -anchor w -padx 2 -pady 5


# create close button
set g [frame .g]
pack $g -fill x -side bottom -anchor s
pack [label $g.lab -text "Company No.:"] -side left -anchor w -padx 1
pack [entry $g.ent -width 5 -textvariable company] -side left -anchor s
pack [ttk::button $g.exit -text "Close" -command {exit}] -side right -anchor s
pack [ttk::button $g.more -text "More files..." -command "addNewEntries"] -side right -anchor s
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

# core proc to clean file. Pretty messy atm
proc clean {file mode company} {
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
	regexp {.*\/([\w\s]+)\.\w+$} $file - filename
	
	# open read and write files and debug file
	set data [open $file r]
	set newfilename "$filename cleansed"
	set output [open "$newfilename.txt" w]
	while {[gets $data line] != -1} {
		if {[regexp {^-} $line]} {continue}
		regsub {^[﻿]{0,3}} $line "" line
		]
		if {[string trim [lindex $newline 7]] != $company} {
			if {[string trim [lindex $newline 7]] != "el1"} {continue}
		}
		set final [list]
		set count 0
		foreach n $newline {
			set new [string trim $n]
			if {$count == 5 || $count == 15 || $count == 16 || $count == 47 || $count == 49 || $count == 69 || $count == 80 || $count == 81 || $count == 85} {
				set new [formatdate $new]
			}
			lappend final $new
			incr count
		}
		puts $output [join $final "\t"]
	}
	close $output
	close $data
	if {$mode} {showMessageBox 1}
}

proc cleanAll {retainfile availablefile} {
	if {$retainfile == "" || $availablefile == ""} {
		showMessageBox 2
		return
	}
	if {[catch {open $retainfile r} fid] || [catch {open $availablefile r} fid]} {
		showMessageBox 3
		return
	}

	regexp {.*\/([\w\s]+)\.\w+$} $retainfile - rfilename
	regexp {.*\/([\w\s]+)\.\w+$} $availablefile - afilename
	
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
		
	}

	global fentries company
	set errors [list "One or more files failed to be cleansed:"]
	foreach i $fentries {
		if {![catch {clean $i 0 $company} fid]} {
			clean $i 0 $company
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