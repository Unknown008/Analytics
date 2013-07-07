# "." is the name of the current widget o_0
wm title . "Dischem cleansing"

# create label of widget named ".msg"
label .msg -wraplength 4i -justify left -text "Click on \"Browse\" to select a file name using the file selection dialog for cleansing." -anchor e

# put label in widget
pack .msg -side top

# Number of entries. Default 1
set entries 1

# Create frame within widget, add label and set position of frame
set f [frame .fr]
pack $f -fill x -padx 1c -pady 3
label $f.lab -text "Browse for the file to cleanse: "
pack $f.lab -side left -anchor w -padx 1

# create input box named ".ent"
entry $f.ent -width 20 -textvariable fname

# place input box in widget
pack $f.ent -side left -expand yes -fill x -anchor w -padx 1

# create and place buttons in widget (combination of above steps)
pack [ttk::button $f.c -text "Start" -command "clean \$fname"] -side left -anchor w -padx 1
pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side left -anchor w -padx 1

# create close button
set g [frame .g]
pack $g -fill x -side bottom -anchor s
pack [ttk::button $g.exit -text "Close" -command {exit}] -side right -anchor s
pack [ttk::button $g.more -text "More files..." -command "addNewEntries"] -side right -anchor s

# proc to open file dialog box and fill in entry box for file path/name
proc fileDialog {ent} {
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
		default {}
	}
}

# core proc to clean file. Pretty messy atm
proc clean {file} {
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
	set debug [open "debug.txt" w]
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
	close $debug
	close $data
	showMessageBox 1
}

proc addNewEntries {} {
	global entries
	if {$entries > 4} {
		showMessageBox 4
		return
	}
	set f [frame ".f$entries"]
	pack $f -fill x -padx 1c -pady 2
	pack [label $f.lab -text "Browse for the file to cleanse: "] -side left -padx 1 -pady 5
	pack [entry $f.ent -width 20 -textvariable "fname$entries"] -side left -expand yes -fill x -padx 1 -pady 5
	pack [ttk::button $f.c -text "Start" -command "clean \$fname$entries"] -side left -padx 1 -pady 5
	pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent$entries"] -side left -padx 1 -pady 5
	incr entries
}