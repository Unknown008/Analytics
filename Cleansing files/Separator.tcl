set data [open "Files.txt" r]

fconfigure $data -eofchar {}

set data1 [open "File Part1.txt" w]
set data2 [open "File Part2.txt" w]
set data3 [open "File Part3.txt" w]
set data4 [open "File Part4.txt" w]
set data5 [open "File Part5.txt" w]
set output [open "output.txt" w]

set count 0

while {[gets $data line] != -1} {
	if {$count > 8000000} {
		puts $data5 $line
	} elseif {$count > 6000000} {
		puts $data4 $line
	} elseif {$count > 4000000} {
		puts $data3 $line
	} elseif {$count > 2000000} {
		puts $data2 $line
	} else {
		puts $data1 $line
	}	
	incr count
}
puts $output $count

close $data
close $data1
close $data2
close $data3
close $data4
close $data5