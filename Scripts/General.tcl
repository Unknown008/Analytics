# Title of widget
wm title . "File cleansing"

# Notebook widget
ttk::notebook .note
pack .note -fill both -expand 1 -padx 2 -pady 3
ttk::notebook::enableTraversal .note

# Create label of widget
grid [label .msg -justify left -text "Pick the different parameters for the file to cleanse:"] -row 0 -column 0

set f [frame .note.fr]
pack [label $f.dellab -text "Delimiter"] -side left
pack [entry $f.delent -width 5 -textvariable delimiter] -side right
grid $f -row 2 -column 0 -sticky w -pady 0.5c

set g [frame .note.fr0]
pack [label $g.lab -text "Browse for the file to cleanse:"] -side left -anchor w -padx 1
pack [entry $g.ent -width 20 -textvariable fname] -side left -expand yes -fill x -anchor w -padx 2
pack [ttk::button $g.b -text "Browse" -command "fileDialog $g.ent"] -side left -anchor w -padx 2 -pady 5
pack [ttk::button $g.c -text "Import Sample" -command "import \$fname"] -side left -anchor w -padx 2 -pady 5
grid $g -row 1 -column 0 -sticky w

# Close button
grid [ttk::button .exit -text "Close" -command {exit}] -row 10 -column 10 -sticky se

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
	lappend fentries $file
	
	# enter file path into entry box. Don't understand this one completely yet
	if {[string compare $file ""]} {
		$ent delete 0 end
		$ent insert 0 $file
		$ent xview end
	}
	
	#creates an error without this one earlier on. Not sure if still applicable. To test
	unset file
}

proc import {file} {
	global delimiter
	if {$delimiter eq ""} {
		showMessageBox 1
		return
	}



}

proc showMessageBox {level} {
	global msgboxIcon msgboxType
	switch $level {
		1 {set button [tk_messageBox -title Warning -message "Specify a delimiter!"]}
		2 {set button [tk_messageBox -title Warning -message "No file was selected!"]}
		3 {set button [tk_messageBox -title Warning -message "File name invalid!"]}
		4 {set button [tk_messageBox -title Warning -message "Cannot add more files!"]}
		5 {set button [tk_messageBox -title Bug -message "All right here..."]}
		default {}
	}
}