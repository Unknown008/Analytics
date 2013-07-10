# "." is the name of the current widget o_0
wm title . "Dischem cleansing"

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
set frames [list $f]
set fentries [list]

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
		if {[$ent select range 0 end] != ""} {
			set oldfile [$ent select range 0 end]
			set id [lsearch $fentries $oldfile]
			set fentries [lreplace $fentries $id $id $file]
		} else {
			lappend $fentries $file
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
	global msgboxIcon msgboxType
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
	regexp {.*\/([\w\s]+)\.txt} $file - filename
	
	# open read and write files and debug file
	set data [open $file r]
	set newfilename "$filename cleansed"
	set output [open "$newfilename.txt" w]
	
	set header 0
	set separator 0
	set count 0

	while {[gets $data line] != -1} {
		# Skip empty lines and separator lines
		if {[string range $line 0 0] eq "-" || $line eq ""} {continue}
		set res ""
		set group [split $line "|"]
		set group [lreplace $group 76 78]
		set group [lreplace $group 73 74]
		set group [lreplace $group 71 71]
		set group [lreplace $group 51 69]
		set group [lreplace $group 40 49]
		set group [lreplace $group 33 38]
		set group [lreplace $group 26 31]
		set group [lreplace $group 23 24]
		set group [lreplace $group 18 20]
		foreach n $group {lappend res [string trim $n]}
		if {!$header} {
			set res [lreplace $res 0 0 "Source"]
			set res [linsert $res 19 "JE Amt"]
			set res [linsert $res 21 "JE Amt2"]
			set res [linsert $res 25 "LC Amt"]
			puts $output [join $res "\t"]
			set header 1
			continue
		}
		set res [dates $res 4]
		set res [dates $res 10]
		set res [dates $res 11]
		set res [dates $res 21]
		set res [amount $res 18]
		set res [amount $res 20]
		set res [amount $res 24]
		set res [lreplace $res 0 0 $filename]
		regsub -all {\"} $res "" res
		puts $output [join $res "\t"]
		incr count
	}
	close $output
	close $data
	if {$mode} {showMessageBox 1}
}

proc addNewEntries {} {
	global entries frames
	if {$entries > 4} {
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
	lappend $frames $f
}

proc cleanAll {} {
	global fentries
	set errors [list "One or more files failed to be cleansed:"]
	foreach i $fentries {
		if {![catch {clean $i 0} fid]} {
			clean $i 0
		} else {
			lappend $errors "- $i could not be cleaned because $fid."
			set button [tk_messageBox -title Warning -message "Passed"]
		}
	}
	if {[llength $errors] == 1} {
		showMessageBox 1
	} else {
		set button [tk_messageBox -title Warning -message [join $errors "\n"]]
	}
}