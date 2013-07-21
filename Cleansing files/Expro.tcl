set data [open "File.txt" r]
set header ""
set count 0
set currBU 0
set sum 0
set control [open "Control.txt" w]

while {[gets $data line] != -1 || $count > 100} {
	if {[string range $line 0 1] != "|"} {continue}
	set group [split $line "|"]
	if {[lindex $group 1] == "CoCd"} {
		set header $group
		lappend header "JE Amt"
		continue
	}
	set BU [lindex $group 1]
	if {$currBU == 0 || $currBU != $BU} {
		if {$currBU != 0} {
			puts $control "$BU $sum"
			close $output
		}
		set output [open "$BU.txt" w]
		set currBU $BU
		puts $output $header
	}
	set psdate [lindex $group 5]
	set endate [lindex $group 6]
	set dodate [lindex $group 12]
	set dc [string trim [lindex $group 15]]
	set amt [lindex $group 18]
	switch $dc {
		"H" {set $amt [expr {$amt*-1}]}
		"S" {set $amt [expr {$amt*1}]}
	}
	set sum [expr {$sum+$amt}]
	set npsdate "[string range $psdate 3 4]\"[string range $psdate 0 1]\"[string range $psdate 6 9]"
	set nendate "[string range $endate 3 4]\"[string range $endate 0 1]\"[string range $endate 6 9]"
	set ndodate "[string range $dodate 3 4]\"[string range $dodate 0 1]\"[string range $dodate 6 9]"
	set group [lreplace $group 5 6 $npsdate $nendate]
	set group [lreplace $group 12 12 $ndodate]
	lappend group $amt
	incr count
}

close $output
close $data
close $control
	