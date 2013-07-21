# "." is the name of the current widget o_0
wm title . "Afrasia recomputation"

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
		set group [split $line "\t"]
		if {!$header} {
			set group [lappend group "Interest" "Closing balance"]
			puts $output [join $group "\t"]
			set header 1
			continue
		}
		lassign $group - - - - type
		switch [string range $type 0 1] {
			"AM" {set results [monthly_AM $group]}
			"NO" {set results [monthly_NO $group]}
		}
		puts $output $results
	}
	close $output
	close $data
	if {$mode} {showMessageBox 1}
}

proc monthly_AM {group} {
	lassign $group ref bkdate customer curr type origamt balfcy freq rate1 rate2 rate3 rate4 rate5 rate6 rate7 rate8 rate9 rate10 rate11 rate12 matdate
	set months [lrange $group 8 19]
	
	if {[regexp {^\s*-?\s*$} $balfcy]} {set balfcy $origamt}
	set count 0
	set netint 0
	regsub -all {[, ]} $balfcy "" balfcy
	set pmt 0
	set month 1
	set quarter 0
		
	foreach int $months {
		if {$int == "" || $month <= 0} {continue}
		if {$quarter % 3 != 0} {
			if {$quarter == 0} {
				switch $count {
					0 {set startdate "31/07/2012"}
					1 {set startdate "31/08/2012"}
					2 {set startdate "30/09/2012"}
					3 {set startdate "31/10/2012"}
					4 {set startdate "30/11/2012"}
					5 {set startdate "31/12/2012"}
					6 {set startdate "31/01/2013"}
					7 {set startdate "28/02/2013"}
					8 {set startdate "31/03/2013"}
					9 {set startdate "30/04/2013"}
					10 {set startdate "31/05/2013"}
					11 {set startdate "30/06/2013"}
				}
			
			
			}
			incr quarter
			continue
		}
		set matdate1 [clock scan $matdate -format %d/%m/%Y]
		if {[clock scan $bkdate -format %d/%m/%Y] < [clock scan {30/06/2012} -format %d/%m/%Y]} {
			set bkdate1 [clock scan {30/06/2012} -format %d/%m/%Y]
		} else {
			set bkdate1 [clock scan $bkdate -format %d/%m/%Y]
		}
		set month [expr {round((($matdate1-$bkdate1)/2628000.0))-$count}]
		if {$month == 0} {set month 1}
		set rate [expr {$int/1200.0}]
		set pmt [expr {($rate+($rate/((1.0+$rate)**$month-1.0)))*$balfcy}]
		set interest [expr {$balfcy*$rate}]
		set netint [expr {$netint+$interest}]
		set balfcy [expr {$balfcy+$interest-$pmt}]
		incr count
		if {$freq == "Q"} {incr quarter}
	}
	lappend group $netint $balfcy
	return [join $group "\t"]
}

proc monthly_NO {group} {
	lassign $group ref bkdate customer curr type origamt balfcy freq rate1 rate2 rate3 rate4 rate5 rate6 rate7 rate8 rate9 rate10 rate11 rate12 matdate
	set months [lrange $group 8 19]
	
	if {[regexp {^\s*-?\s*$} $balfcy]} {set balfcy $origamt}
	set count 0
	set netint 0
	regsub -all {[, ]} $balfcy "" balfcy
	set pmt 0
	set month 1
	set quarter 0
		
	foreach int $months {
		if {$int == "" || $month <= 0} {continue}
		set matdate1 [clock scan $matdate -format %d/%m/%Y]
		if {[clock scan $bkdate -format %d/%m/%Y] < [clock scan {30/06/2012} -format %d/%m/%Y]} {
			set bkdate1 [clock scan {30/06/2012} -format %d/%m/%Y]
		} else {
			set bkdate1 [clock scan $bkdate -format %d/%m/%Y]
		}
		set month [expr {round((($matdate1-$bkdate1)/2628000.0))-$count}]
		if {$month == 0} {set month 1}
		set rate [expr {$int/1200.0}]
		set interest [expr {$balfcy*$rate}]
		set netint [expr {$netint+$interest}]
		incr count
	}
	lappend group $netint $balfcy
	return [join $group "\t"]
}

proc addNewEntries {} {
	global entries
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
}

proc cleanAll {} {
	global fentries
	set errors [list "One or more files failed to be cleansed:"]
	foreach i $fentries {
		if {![catch {clean $i 0} fid]} {
			clean $i 0
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