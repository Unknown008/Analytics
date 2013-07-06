set data [open "file.txt" r]
set data1 [open "fileoutput.txt" w]

while {[gets $data line] != -1} {
	set newline [split $line "|"]
	if {[string range $line 0 5] eq "BUKRS" || $line eq ""} {
		continue
	} else {
		set bldat [lindex $newline 31]
		set cpudat [lindex $newline 32]
		set budat [lindex $newline 34]
		regsub -all {\.} $bldat "/" bldat
		regsub -all {\.} $cpudat "/" cpudat
		regsub -all {\.} $budat "/" budat
		set newline [lreplace $newline 31 31 $bldat]
		set newline [lreplace $newline 32 32 $cpudat]
		set newline [lreplace $newline 34 34 $budat]
		set DCInd [lindex $newline 50]
		set amt [lindex $newline 51]
		regsub -all {\.} $amt "" amt
		regsub -all {\,} $amt "\." amt
		if {$DCInd == "H"} {
			set amt "-$amt"
		}
		set newline [linsert $newline 52 $amt]
		set desc [lindex $newline 28]
		regsub -all {\"} $desc "" desc
		set newline [lreplace $newline 28 28 $desc]
	}
	puts $data1 [join $newline "\t"]
}

close $data
close $data1