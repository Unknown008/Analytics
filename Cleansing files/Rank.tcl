# "." is the name of the current widget o_0
wm title . "Rank Group"

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
pack [ttk::button $f.c -text "Start" -command "clean \$fname 1 \$company"] -side left -anchor w -padx 2 -pady 5


# create close button
set g [frame .g]
pack $g -fill x -side bottom -anchor s
pack [label $g.lab -text "Company No.:"] -side left -anchor w -padx 1
pack [entry $g.ent -width 5 -textvariable company] -side left -anchor s
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
		set newline [list [string range $line 0 11] \
			[string range $line 13 24] \
			[string range $line 26 37] \
			[string range $line 39 49] \
			[string range $line 51 56] \
			[string range $line 58 80] \
			[string range $line 82 93] \
			[string range $line 95 166] \
			[string range $line 168 239] \
			[string range $line 241 312] \
			[string range $line 314 385] \
			[string range $line 387 458] \
			[string range $line 460 531] \
			[string range $line 533 604] \
			[string range $line 606 677] \
			[string range $line 679 701] \
			[string range $line 703 725] \
			[string range $line 727 747] \
			[string range $line 749 760] \
			[string range $line 762 782] \
			[string range $line 784 794] \
			[string range $line 796 816] \
			[string range $line 818 838] \
			[string range $line 840 851] \
			[string range $line 853 873] \
			[string range $line 875 882] \
			[string range $line 884 894] \
			[string range $line 896 902] \
			[string range $line 904 914] \
			[string range $line 916 922] \
			[string range $line 924 934] \
			[string range $line 936 971] \
			[string range $line 973 1004] \
			[string range $line 1006 1037] \
			[string range $line 1039 1070] \
			[string range $line 1072 1079] \
			[string range $line 1081 1092] \
			[string range $line 1094 1105] \
			[string range $line 1107 1127] \
			[string range $line 1129 1141] \
			[string range $line 1143 1163] \
			[string range $line 1165 1178] \
			[string range $line 1180 1200] \
			[string range $line 1202 1213] \
			[string range $line 1215 1235] \
			[string range $line 1237 1249] \
			[string range $line 1251 1258] \
			[string range $line 1260 1282] \
			[string range $line 1284 1290] \
			[string range $line 1292 1314] \
			[string range $line 1316 1323] \
			[string range $line 1325 1333] \
			[string range $line 1335 1344] \
			[string range $line 1346 1356] \
			[string range $line 1358 1389] \
			[string range $line 1391 1422] \
			[string range $line 1424 1455] \
			[string range $line 1457 1467] \
			[string range $line 1469 1476] \
			[string range $line 1478 1486] \
			[string range $line 1488 1499] \
			[string range $line 1501 1511] \
			[string range $line 1513 1524] \
			[string range $line 1526 1536] \
			[string range $line 1538 1549] \
			[string range $line 1551 1561] \
			[string range $line 1563 1574] \
			[string range $line 1576 1586] \
			[string range $line 1588 1593] \
			[string range $line 1595 1617] \
			[string range $line 1619 1630] \
			[string range $line 1632 1637] \
			[string range $line 1639 1649] \
			[string range $line 1651 1661] \
			[string range $line 1663 1668] \
			[string range $line 1670 1680] \
			[string range $line 1682 1687] \
			[string range $line 1689 1699] \
			[string range $line 1701 1712] \
			[string range $line 1714 1724] \
			[string range $line 1726 1748] \
			[string range $line 1750 1772] \
			[string range $line 1774 1796] \
			[string range $line 1798 1869] \
			[string range $line 1871 1882] \
			[string range $line 1884 1906] \
			[string range $line 1908 1915] \
			[string range $line 1917 1922] \
			[string range $line 1924 1934] \
			[string range $line 1936 1971] \
			[string range $line 1973 1984] \
			[string range $line 1986 1997] \
			[string range $line 1999 2010] \
			[string range $line 2012 2023] \
			[string range $line 2025 2036] \
			[string range $line 2038 2287] \
			[string range $line 2289 2301] \
			[string range $line 2303 2341] \
			[string range $line 2343 2360] \
			[string range $line 2362 2373] \
			[string range $line 2375 2386]
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

proc formatdate {date} {
	if {[regexp {^([0-9]{4})-([0-9]{2})-([0-9]{2})} $date - y m d]} {
		return "$d/$m/$y"
	} else {
		return $date
	}
}

proc addNewEntries {} {
	global entries
	if {$entries > 6} {
		showMessageBox 4
		return
	}
	set f [frame ".fr$entries"]
	pack $f -fill x -padx 1c -pady 2
	pack [label $f.lab -text "Browse for the file to cleanse:"] -side left -padx 1 -pady 5
	pack [entry $f.ent -width 20 -textvariable "fname$entries"] -side left -expand yes -fill x -padx 2 -pady 5
	pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side left -padx 2 -pady 5
	pack [ttk::button $f.c -text "Start" -command "clean \$fname$entries 1 \$company"] -side right -padx 2 -pady 5

	incr entries
}

proc cleanAll {} {
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