# Set title of widget
wm title . "Interest recomputation"

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
pack [ttk::button $f.c -text "Start" -default active -command "clean \$fname 1"] -side left -anchor w -padx 2 -pady 5


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
	
	# Enter file path into entry box after file has been browsed. Change the file when another file is browsed.
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
	# check for empty entry box
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

# Hard coded part for financial year of Afrasia. Might need to find more elegant way to generate end of months
proc bemonth {id} {
	switch $id {
		0 {set eom "30/06/2012"}
		1 {set eom "31/07/2012"}
		2 {set eom "31/08/2012"}
		3 {set eom "30/09/2012"}
		4 {set eom "31/10/2012"}
		5 {set eom "30/11/2012"}
		6 {set eom "31/12/2012"}
		7 {set eom "31/01/2013"}
		8 {set eom "28/02/2013"}
		9 {set eom "31/03/2013"}
		10 {set eom "30/04/2013"}
		11 {set eom "31/05/2013"}
		12 {set eom "30/06/2013"}
	}
	return $eom
}

proc monthly_AM {group} {
	# structure of file input
	lassign $group ref bkdate customer curr type origamt balfcy freq rate1 rate2 rate3 rate4 rate5 rate6 rate7 rate8 rate9 rate10 rate11 rate12 matdate
	set months [lrange $group 8 19]
	
	# Beginning of financial year date
	set startdate [clock scan {30/06/2012} -format %d/%m/%Y]
	
	# Different currencies, different days-in-a-year basis to calculate interest
	if {$curr eq "EUR" || $curr eq "USD" || $curr eq "GBP"} {
		set yeardays 360.0
	} else {
		set yeardays 365.0
	}
	
	##################################################################
	# Don't change anything below unless you know what you are doing #
	##################################################################
	if {[regexp {^\s*-?\s*$} $balfcy]} {set balfcy $origamt}
	set count 0                           ;# Basis to assess whether payment is to be issued or not
	set netint 0                          ;# To store total interest accrued during year
	regsub -all {[, ]} $balfcy "" balfcy  ;# Remove commas from amount and spaces if any from opening balance on loan
	set periods 1                         ;# Number of periods to maturity. Used to end calculation if matured within year
	set index 0                           ;# Basis for elements of list of rates
	set skip 0                            ;# Used for instances where loan not taken on 1st day of month
	set offsetpmt 0                       ;# With instances of `$skip`, accrue insterest for days to periodic payments
	set remain 0                          ;# Used in calculating periodic payment and periods left to maturity
	set cumint 0                          ;# Interest accrued before payment issued for each period
	
	switch [string trim $freq] {
		"M" {set period 1}       # Monthly installments
		"Q" {set period 3}       # Quarterly installments
		"Y" {set period 12}      # Yearly installments
		"H" {set period 6}       # Half-yearly installments
		default {set period 1}
	}

	foreach int $months {
		incr index
		# Check if blank or no more payment to be done (i.e maturity date reached)
		if {$int == "" || $periods <= 0} {continue}
	
		# Check whether started before year
		if {[clock scan $bkdate -format %d/%m/%Y] < $startdate} {
			set bkdate1 $startdate
		} else {
			set bkdate1 [clock scan $bkdate -format %d/%m/%Y]
		}
		
		# Get last day of month for current month
		set eom [bemonth $index]
		set eom [clock scan $eom -format %d/%m/%Y]
		
		# Find offset with first day of month
		set bom [bemonth [expr {$index-1}]]
		set bom [clock scan $bom -format %d/%m/%Y]
		if {$bkdate1 > $bom} {
			# 86400.0 is the number of seconds in a day.
			set chrgdays [expr {(($eom-$bkdate1)/86400.0)+1}]
			set skip 1
		} else {
			set chrgdays [expr {($eom-$bom)/86400.0}]
		}
		
		if {$index == 12 && [lindex $months 10] != ""} {
			set matdate1 [clock scan $matdate -format %d/%m/%Y]
			# 2628000.0 is the number of seconds in a month.
			set periods [expr {int((($matdate1-$bkdate1)/(2628000.0*$period)))-$remain}]
			incr count
			if {$periods == 0} {set periods 1}
			# Payment formula for period ending
			set pmt [expr {($rate+($rate/((1.0+$rate)**$periods-1.0)))*$balfcy}]
			set prevint [lindex $months 10]
			set rate1 [expr {($prevint/100.0)*(21/$yeardays)}]
			set rate2 [expr {($int/100.0)*(9/$yeardays)}]
			set interest [expr {($balfcy*$rate1)+($balfcy*$rate2)}]
			if {$count % $period == 0} {
				set balfcy [expr {$balfcy+$interest-$pmt}]
				set netint [expr {$netint+$interest}]
			}
			break
		}
		
		# Find rate
		set rate [expr {($int/100.0)*($chrgdays/$yeardays)}]
		set interest [expr {$balfcy*$rate}]
		set rate [expr {($int/100.0)/(12.0/$period)}]
		if {$skip} {
			# Account interest for partial month at beginning
			set netint $interest
			set offsetpmt $interest
			set skip 0
			continue
		}

		set matdate1 [clock scan $matdate -format %d/%m/%Y]
		set periods [expr {int((($matdate1-$bkdate1)/(2628000.0*$period)))-$remain}]
		if {$periods < 0} {break}
		incr count
		if {$periods == 0} {set periods 1}
		set pmt [expr {(($rate+($rate/((1.0+$rate)**$periods-1.0)))*$balfcy)}]
		set pmt [expr {$pmt+$offsetpmt}]
		set netint [expr {$netint+$interest}]
		set cumint [expr {$cumint+$interest}]
		if {$count % $period == 0} {
			set balfcy [expr {$balfcy+$cumint-$pmt}]
			set cumint 0
			set offsetpmt 0
			incr remain
		}
		set pmt 0
	}

	lappend group $netint $balfcy
	return [join $group "\t"]
}

# No payment loans removed from scope...
if {0} {
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
