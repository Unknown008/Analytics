# put the title
wm title . "Update moves"

# create label of widget named ".msg" and put in widget
pack [label .msg -justify left -text "Select the files to be compared" -anchor e] -side top

# Create frame within widget, add label and set position of frame
set f [frame .fr0]
set f1 [frame .fr1]
pack $f -fill x -padx 1c -pady 3
pack $f1 -fill x -padx 1c
pack [label $f.lab -text "Browse for the original file:" -width 40 -anchor w] -side left -anchor w -padx 1
pack [label $f1.lab -text "Browse for the file to be updated:" -width 40 -anchor w] -side left -anchor w -padx 1 -pady 5

# create and place buttons in widget
pack [ttk::button $f.b -text "Browse" -command "fileDialog $f.ent"] -side right -anchor w -padx 2 -pady 5
pack [ttk::button $f1.b -text "Browse" -command "fileDialog $f1.ent"] -side right -anchor w -padx 2 -pady 5

# place input box in widget
pack [entry $f.ent -width 20 -textvariable fname] -side right -expand yes -fill x -anchor w -padx 2
pack [entry $f1.ent -width 20 -textvariable f1name] -side right -expand yes -fill x -anchor w -padx 2 -pady 5

# create close button
set g [frame .g]
pack $g -fill x -side bottom -anchor s
pack [label $g.lab -text "Move ID: "] -side left -anchor w -padx 1
pack [entry $g.ent -width 5 -textvariable moveid] -side left -anchor s
pack [ttk::button $g.exit -text "Close" -command {exit}] -side right -anchor s
pack [ttk::button $g.all -text "Start the magic" -command "cleanAll \$fname \$f1name"] -side right -anchor s

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

proc cleanAll {orig pufile} {
  global moveid
  
  # Check if entry boxes empty
	if {$orig == "" || $pufile == ""} {
		showMessageBox 2
		return
	}
  
  # Check any errors in opening files
	if {[catch {set ofile [open $orig r]} fid1] || [catch {set pfile [open $pufile r]} fid2]} {
		showMessageBox 3
		return
	}
  # Close this file for the time being
	close $ofile
  
  # Extract file name
	regexp {.*\/([\w\s]+)\.\w+$} $orig - filename
	
  # Open output file, and append "_updated"
	set output [open "${filename}_updated.txt" w]
	
  # Read line by line
	while {[gets $pfile line] != -1} {
    # Get Pokemon ID
    set pid [lindex [split $line ":"] 0]
    
    # Get move IDs
    set moveset [split [lindex [split $line ":"] 1]]
    
    # Check in orig file
    set ofile [open $orig r]
    while {[gets $ofile poke] != -1} {
      # Look for matching Pokemon ID
      if {$pid != [lindex [split $poke ":"] 0]} {
        continue
      }
      set omoves [split [lindex [split $poke ":"] 1]]
      set newmoves [list]
      # Take only moves above specified moveid and which aren't in current moveset
      foreach n $omoves {
        if {$n >= $moveid && [lsearch $moveset $n] == -1} {
          lappend newmoves $n
        }
      }
      break
    }
    close $ofile
    # If no new moves, continue with next Pokemon
    if {[llength $newmoves] == 0} {
      puts $output $line
      continue
    }
    
    # Merge moves and write to updated file
    set finalmoves [concat $moveset $newmoves]
    puts $output "$pid:[join $finalmoves " "]"
	}
	close $output
	close $pfile
	showMessageBox 1
}
