package require Tk
package require tablelist
package require Ttk
package require sqlite3
package require Img

catch {destroy [winfo children .]}
set defDir [file join [pwd] [file dirname [info script]]]

wm title . "Nou Zenfan Nou Lavenir"
wm geometry . +100+50
wm iconname . NZNL

set menu .menu
menu $menu -tearoff 0

set m $menu.file
menu $m -tearoff 0
$menu add cascade -label "File" -menu $m -underline 0
$m add command -label "New Student" -command {student_form} -accelerator Ctrl+N
$m add separator
$m add command -label "Close" -command {exit} -accelerator Ctrl+Q

set m $menu.search
menu $m -tearoff 0
$menu add cascade -label "Search" -command sql_query -underline 0

bind . <Control-KeyPress-n> {student_form}
bind . <Control-KeyPress-f> {sql_query}
bind . <Control-KeyPress-q> {exit}

. configure -menu $menu

set f .f
pack [ttk::frame $f] -anchor n -fill both -expand 1
scrollbar $f.s -command "$f.t yview"
tablelist::tablelist $f.t -columns {
  5 "Open"
  10 "First Name"
  20 "Last Name"
  20 "School Name"
  10 "Class"
} -stretch all -background white -yscrollcommand "$f.s set" \
  -arrowstyle sunken8x7 -showarrow 1 -resizablecolumns 1 \
  -labelcommand tablelist::sortByColumn -selecttype cell -showeditcursor 0 \
  -showseparators 1 -stripebackground "#C4D1DF"

$f.t configcolumnlist {
  0 -editable no
  1 -editable no
  2 -editable no
  3 -editable no
  4 -editable no
  0 -labelalign center
  1 -labelalign center
  2 -labelalign center
  3 -labelalign center
  4 -labelalign center
  0 -foreground blue
  0 -font {"Segeo UI" 9 underline}
  1 -sortmode command
  2 -sortmode command
  3 -sortmode command
  4 -sortmode command
  1 -sortcommand stud_sort
  2 -sortcommand stud_sort
  3 -sortcommand stud_sort
  4 -sortcommand stud_sort
}
 
pack $f.t -fill both -expand 1 -side left
pack $f.s -fill y -side left
  
proc stud_sort {a b} {
  set w .f.t
  switch [$w sortorderlist] {
    increasing {set empty -1}
    decreasing {set empty 1}
  }
  if {[string compare $a $b] == 0} {return 0}
  lassign {0 0} inta intb
  if {[regexp {^[0-9]+$} $a]} {set inta 1}
  if {[regexp {^[0-9]+$} $b]} {set intb 2}
  
  switch [expr {$inta+$intb}] {
    0 {return [expr {$b == "" ? $empty : [string compare $a $b]}]}
    1 {return 1}
    2 {return -1}
    3 {return [expr {$a > $b ? 1 : -1}]}
  }
}
  
wm minsize . 800 100
  
sqlite3 nz nznl_files/nznldatabase
  
nz eval {
  CREATE TABLE IF NOT EXISTS students(
    id int PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
    first_name text,
    last_name text,
    date_of_birth text,
    principal_address text,
    school_name text,
    class text,
    main_contact text,
    contact_id int,
    other_details text
  )
}

nz eval {
  CREATE TABLE IF NOT EXISTS guardians(
    guardian_id int PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
    guardian_name text,
    home_phone text,
    mobile_phone text,
    salary int,
    social_aid int,
    social_aid_details text,
    registered_to_other int,
    details text,
    position text,
    address text,
    occupation text,
    workplace text,
    workplace_address text,
    employment_length text,
    previous_employment text,
    sponsors text,
    children text,
    siblings_details text,
    siblings_academic_details text,
    grades_comments text
  )
}
  
nz eval {
  CREATE TABLE IF NOT EXISTS results(
    student_id int,
    period_of_grade text,
    subject text,
    grade text  
  )
}
  
$f.t insert end [list New {} {} {} {} {}]
  
bind [$f.t bodytag] <Button-1> {table_clicked %W %x %y}

proc table_clicked {W x y} {
  set t [winfo parent $W]
  foreach {a b c} [tablelist::convEventFields $W $x $y] {}
  lassign [split [$t containingcell $b $c] ","] x y
  if {$y != 0} {return}
  set type [lindex [$t cellconfigure $x,0 -text] 4]
  switch $type {
    Open {open_student [lindex [$t rowconfigure $x -text] 4]}
    New {student_form}
  }
}

proc student_form {} {
  set w .stdform
  catch {destroy [winfo children $w]}
  catch {destroy $w}
  
  toplevel $w
  wm geometry $w +100+50
  wm title $w "Student Form"
  pack [label $w.l -text "New Student" -font {"Segeo UI" 15 bold}] -padx 20 \
    -pady 20 -anchor nw -side top
  
  ttk::notebook $w.note
  set n $w.note
  pack $n -fill both -expand 1 -side top
  ttk::notebook::enableTraversal $n
  
  ### General tab
  ttk::frame $n.fgeneral -padding "10 10"
  $n add $n.fgeneral -text " General "
  ttk::frame $n.fgeneral.photo -borderwidth 5 -relief raised
  label $n.fgeneral.lfirstname   -text "First Name:"
  label $n.fgeneral.llastname    -text "Last Name:"
  label $n.fgeneral.lschoolname  -text "School Name:"
  label $n.fgeneral.lclass       -text "Class:"
  label $n.fgeneral.ldob         -text "Date of Birth (dd/mm/yyyy):"
  label $n.fgeneral.laddress     -text "Address:"
  label $n.fgeneral.lnotes       -text "Notes:"
  label $n.fgeneral.lfiles       -text "Attachments:"
  
  set imgFile "DatePicker.png"
  set path [file join [pwd] $imgFile]
  if {![file exists $path]} {
    set exec [lindex [file split $::argv0] end-1]
    set path [file join [pwd] $exec $imgFile]
    file copy $path [pwd]
    set image [image create photo -format png -file $imgFile]
    file delete DatePicker.png
  } else {
    set image [image create photo -format png -file $imgFile]
  }

  entry $n.fgeneral.efirstname -validate all -validatecommand {label_update %W %d %v %P %i}
  entry $n.fgeneral.elastname -validate all -validatecommand {label_update %W %d %v %P %i}
  entry $n.fgeneral.eschoolname 
  entry $n.fgeneral.eclass      
  entry $n.fgeneral.edob      
  button $n.fgeneral.edobbutt -image $image -command {calendar %W}
  text  $n.fgeneral.eaddress -font TkDefaultFont -width 10 -height 2 -wrap word
  text  $n.fgeneral.enotes   -font TkDefaultFont -width 10 -height 3 -wrap word
  ttk::button $n.fgeneral.efiles -text "Manage attachments" \
    -command [list attch $w student]
  
  grid $n.fgeneral.photo       -row 0 -column 0 -sticky nsew -rowspan 5
  grid $n.fgeneral.lfirstname  -row 0 -column 1 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.llastname   -row 1 -column 1 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.lschoolname -row 2 -column 1 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.lclass      -row 3 -column 1 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.ldob        -row 4 -column 1 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.laddress    -row 6 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.lnotes      -row 5 -column 2 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.lfiles      -row 7 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fgeneral.efirstname  -row 0 -column 2 -sticky new -pady 2 -padx 10 \
    -columnspan 2
  grid $n.fgeneral.elastname   -row 1 -column 2 -sticky new -pady 2 -padx 10 \
    -columnspan 2
  grid $n.fgeneral.eschoolname -row 2 -column 2 -sticky new -pady 2 -padx 10 \
    -columnspan 2
  grid $n.fgeneral.eclass      -row 3 -column 2 -sticky new -pady 2 -padx 10 \
    -columnspan 2
  grid $n.fgeneral.edob        -row 4 -column 2 -sticky new -pady 2 -padx 10
  grid $n.fgeneral.edobbutt    -row 4 -column 3 -sticky new -pady 2 -padx 2
  grid $n.fgeneral.eaddress    -row 6 -column 1 -sticky nsew -pady 2 -padx 10
  grid $n.fgeneral.enotes      -row 6 -column 2 -sticky nsew -pady 2 -padx 10 \
    -rowspan 2 -columnspan 2
  grid $n.fgeneral.efiles      -row 7 -column 1 -sticky nw -pady 2 -padx 10
  
  grid columnconfigure $n.fgeneral 0 -minsize 120
  grid columnconfigure $n.fgeneral 2 -weight 1
  grid columnconfigure $n.fgeneral 1 -weight 1
  grid rowconfigure $n.fgeneral 6 -weight 1
  grid rowconfigure $n.fgeneral 8 -weight 1
  
  bind $n.fgeneral.photo <Button-1> {profile_pic %W}
  
  proc profile_pic {w} {
    set photo [winfo children $w]
    set types {
      {"Images"    {.png .gif .jpeg .jpe .jpg}}
      {"All files"                           *}
    }
    set fin [tk_getOpenFile -filetypes $types -parent $w -initialdir [pwd]]
    if {$fin == ""} {return}
    regexp -nocase -- {\.([^.]+)$} $fin - ext
    if {[string tolower $ext] ni {jpg jpeg jpe png gif}} {
      tk_messageBox -title Error -icon error -message "Unsupported picture format!"
      return
    }
    image create photo sel_img -file $fin
    image create photo fin_img
    image_resize sel_img 120 150 fin_img

    if {$photo == ""} {
      pack [label $w.l -image fin_img] -fill both -expand 0 -anchor center
    } else {
      $w.l configure -image fin_img
    }
    bind $w <Button-1> {}
    bind $w.l <Button-1> [list profile_pic $w]
    focus $w
  }
  
  proc attch {w tab} {
    set fname [$w.note.fgeneral.efirstname get]
    set lname [$w.note.fgeneral.elastname get]
    if {$fname == "" || $lname == ""} {
      tk_messageBox -title "Error" -icon error \
        -message "Please ensure the First Name and Last Name fields are not empty before managing attachments."
      focus $w
      return
    }
    
    set t $w.attach
    catch {destroy $t}
    
    toplevel $t
    wm title $t "Manage Attachments"
    
    label $t.l -text "Below are the attachments related to this $tab."
    set files [glob -nocomplain \
      -directory [file join nznl_files ${fname}_$lname $tab] *]
    set files [lmap x $files {set x [file tail $x]}]
    
    listbox $t.list -yscrollcommand "$t.scroll set" \
      -activestyle dotbox -selectmode multiple -listvariable $files \
      -height 10
    $t.list delete 0 end
    $t.list insert 0 {*}$files
    
    scrollbar $t.scroll -command "$t.list yview"
    frame $t.sideframe
    ttk::button $t.sideframe.add -text "Add" -command [list attch_add $t $tab]
    ttk::button $t.sideframe.del -text "Delete" -command [list attch_del $t $tab] \
      -state disabled
    
    grid $t.l -row 0 -column 0 -columnspan 3 -sticky nsew
    grid $t.list -row 1 -column 0 -sticky nsew -padx 5 -pady 5
    grid $t.scroll -row 1 -column 1 -sticky nsew
    grid $t.sideframe -row 1 -column 2 -sticky nsew
    pack $t.sideframe.add -side top -padx 5 -pady 5
    pack $t.sideframe.del -side top -padx 5 -pady 5
    
    grid columnconfigure $t 0 -weight 1
    grid rowconfigure $t 1 -weight 1
    
    bind $t.list <<ListboxSelect>> {
      set pwin [winfo parent %W]
      if {[llength [%W curselection]] > 0} {
        $pwin.sideframe.del configure -state active
      } else {
        $pwin.sideframe.del configure -state disabled
      }
    }
    
    bind $t.list <Double-ButtonPress-1> [list attch_open $t $tab]
    
    proc attch_add {w tab} {
      set f [tk_getOpenFile -filetypes {{"All files" *}} -initialdir [pwd]]
      if {$f == ""} {return}
      set pwin [winfo parent $w]
      set fname [$pwin.note.fgeneral.efirstname get]
      set lname [$pwin.note.fgeneral.elastname get]
      set filename [file tail $f]
      if {[file exists [file join nznl_files ${fname}_$lname $f]]} {
        set response [tk_messageBox -title Warning -icon warning -message "A file with the same name already exists. Do you want to replace it?"]
        if {$response eq "no"} {return}
      } else {
        $w.list insert end $filename
      }
      if {![file exists [file join nznl_files ${fname}_$lname]]} {
        file mkdir [file join nznl_files ${fname}_$lname]
      }
      if {![file exists [file join nznl_files ${fname}_$lname $tab]]} {
        file mkdir [file join nznl_files ${fname}_$lname $tab]
      }
      file copy -force $f [file join nznl_files ${fname}_$lname $tab]
      focus $w.list
    }
    
    proc attch_del {w tab} {
      set pwin [winfo parent $w]
      set fname [$pwin.note.fgeneral.efirstname get]
      set lname [$pwin.note.fgeneral.elastname get]
      set response [tk_messageBox -icon question -title "Delete attachment" \
        -message "Are you sure you want to delete the selected attachment(s) from the database?" -type yesno]
      if {$response eq "no"} {return}
      set selection [lsort -integer -decreasing [$w.list curselection]]
      foreach id $selection {
        set filename [$w.list get $id]
        file delete -force [file join nznl_files ${fname}_$lname $tab $filename]
        $w.list delete $id
      }
      $w.sideframe.del configure -state disabled
      focus $w
    }
    focus $w
  }
  
  proc attch_open {w tab} {
    set id [$w.list curselection]
    if {[llength $id] > 1} {
      tk_messageBox -icon error -title Error \
        -message "Only one file can be opened at a time. Please review your selection."
      return
    }
    set filename [$w.list get [lindex $id 0]]
    set pwin [winfo parent $w]
    set fname [$pwin.note.fgeneral.efirstname get]
    set lname [$pwin.note.fgeneral.elastname get]
    exec {*}[auto_execok start] "" [file join nznl_files ${fname}_$lname $tab $filename]
  }
  
  ### Guardian Information tab
  ttk::frame $n.fginfo -padding "10 10"
  $n add $n.fginfo -text " Guardian Information "
  
  label $n.fginfo.lguardian    -text "Guardian name and position:"
  label $n.fginfo.lhomphone    -text "Home Phone:"
  label $n.fginfo.lmobphone    -text "Mobile Phone:"
  label $n.fginfo.laddress     -text "Address & proof of address:"
  label $n.fginfo.lsocaid      -text "Social Aid:"
  label $n.fginfo.lsocaiddet   -text "Details:"
  label $n.fginfo.lothorg      -justify left \
    -text "Registered to other scholarship support\nfrom other organisation:" 
  label $n.fginfo.lothorgdet   -text "Details:"
  label $n.fginfo.lsalary      -text "Monthly Salary & proof of income level:"
  label $n.fginfo.loccupation  -text "Occupation:"
  label $n.fginfo.lworkplace   -text "Guardian's place of work:"
  label $n.fginfo.lworkadd     -text "Address of work place:"
  label $n.fginfo.lemplength   -text "Length of employment:"
  label $n.fginfo.lprevemp     -text "Previous employment:"
  label $n.fginfo.lsponsors    -text "Sponsors (at least 2 required):"
  label $n.fginfo.lchildren    -text "Total number of children including sponsored:"
  label $n.fginfo.lsibdetails  -text "Details on other siblings:"
  label $n.fginfo.lsibacadet   -text "Details on their academic grades:"
  label $n.fginfo.lfiles       -text "Files:"
  
  entry $n.fginfo.eguardian
  ttk::combobox $n.fginfo.cguardian -values {Father Mother Guardian}
  entry $n.fginfo.ehomphone   
  entry $n.fginfo.emobphone 
  text $n.fginfo.eaddress -font TkDefaultFont -width 10 -height 2 -wrap word
  checkbutton $n.fginfo.esocaid -variable esocaid
  text $n.fginfo.esocaiddet -font TkDefaultFont -width 10 -height 2 -wrap word
  checkbutton $n.fginfo.eothorg -variable eothorg
  text $n.fginfo.eothorgdet -font TkDefaultFont -width 10 -height 2 -wrap word
  entry $n.fginfo.esalary
  entry $n.fginfo.eoccupation
  entry $n.fginfo.eworkplace
  entry $n.fginfo.eworkadd
  entry $n.fginfo.eemplength
  entry $n.fginfo.eprevemp
  entry $n.fginfo.esponsors
  ttk::combobox $n.fginfo.echildren -values {1 2 3 4 "More than 4"}
  text $n.fginfo.esibdetails  -font TkDefaultFont -width 10 -height 2 -wrap word
  text $n.fginfo.esibacadet   -font TkDefaultFont -width 10 -height 2 -wrap word
  ttk::button $n.fginfo.efiles -text "Manage attachments" \
    -command [list attch $w guardian]

  grid $n.fginfo.lguardian   -row 0 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lhomphone   -row 1 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lmobphone   -row 2 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.laddress    -row 3 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lsocaid     -row 4 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lsocaiddet  -row 5 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lothorg     -row 7 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lothorgdet  -row 8 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lsalary     -row 10 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.loccupation -row 11 -column 0 -sticky nw -pady 2 -padx 10  
  grid $n.fginfo.lworkplace  -row 12 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lworkadd    -row 13 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lemplength  -row 14 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lprevemp    -row 15 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lsponsors   -row 16 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lchildren   -row 17 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lsibdetails -row 18 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lsibacadet  -row 20 -column 0 -sticky nw -pady 2 -padx 10
  grid $n.fginfo.lfiles      -row 22 -column 0 -sticky nw -pady 2 -padx 10
  
  grid $n.fginfo.eguardian   -row 0 -column 1 -sticky new -pady 2 -padx 10
  grid $n.fginfo.cguardian   -row 0 -column 2 -sticky new -pady 2 -padx 10
  grid $n.fginfo.ehomphone   -row 1 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.emobphone   -row 2 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.eaddress    -row 3 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.esocaid     -row 4 -column 1 -sticky nw -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.esocaiddet  -row 5 -column 1 -sticky nsew -pady 2 -padx 10 \
    -columnspan 2 -rowspan 2 
  grid $n.fginfo.eothorg     -row 7 -column 1 -sticky nw -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.eothorgdet  -row 8 -column 1 -sticky nsew -pady 2 -padx 10 \
    -columnspan 2 -rowspan 2 
  grid $n.fginfo.esalary     -row 10 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2
  grid $n.fginfo.eoccupation -row 11 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2
  grid $n.fginfo.eworkplace  -row 12 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2 
  grid $n.fginfo.eworkadd    -row 13 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2    
  grid $n.fginfo.eemplength  -row 14 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.eprevemp    -row 15 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.esponsors   -row 16 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.echildren   -row 17 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.esibdetails -row 18 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2            
  grid $n.fginfo.esibacadet  -row 20 -column 1 -sticky new -pady 2 -padx 10 \
    -columnspan 2             
  grid $n.fginfo.efiles      -row 22 -column 1 -sticky nw -pady 2 -padx 10 \
    -columnspan 2
  
  grid rowconfigure $n.fginfo {5 8 18 20} -minsize 50 -weight 1
  grid columnconfigure $n.fginfo 1 -weight 1
  
  ### Grades tab
  ttk::frame $n.fgrades -padding "10 10"
  $n add $n.fgrades -text " Grades "
  
  scrollbar $n.fgrades.s -command "$n.fgrades.t yview"
  tablelist::tablelist $n.fgrades.t -columns {
    10 "Month-Year"
    10 "Subject"
    10 "Grade"
  } -stretch all -background white -yscrollcommand "$n.fgrades.s set" \
    -arrowstyle sunken8x7 -showarrow 1 -resizablecolumns 1 \
    -labelcommand tablelist::sortByColumn -selecttype cell -showeditcursor 0 \
    -showseparators 1 -stripebackground "#C4D1DF"
  
  $n.fgrades.t configcolumnlist {
    0 -editable yes
    1 -editable yes
    2 -editable yes
    0 -labelalign center
    1 -labelalign center
    2 -labelalign center
  }
  
  label $n.fgrades.lab -text "Any comments on the pupil by teacher/head teacher:"
  text $n.fgrades.text -font TkDefaultFont -height 6 -wrap word
  
  grid $n.fgrades.t -row 0 -column 0 -sticky nsew
  grid $n.fgrades.s -row 0 -column 1 -sticky nsew
  grid $n.fgrades.lab -row 1 -column 0 -sticky nsw -columnspan 2 -pady 5
  grid $n.fgrades.text -row 2 -column 0 -sticky nsew -columnspan 2
  
  grid rowconfigure $n.fgrades 0 -weight 1
  grid columnconfigure $n.fgrades 0 -weight 1
  new_row $n.fgrades.t grades
  
  bind $n.fgrades.t <<TablelistCellUpdated>> {
    lassign %d x y
    if {
      [expr {$x+1}] == [%W size] && 
      [lindex [%W cellconfigure [join %d ,] -text] 4] ne ""
    } {
      new_row %W grades
    }
  }
  
  ### Buttons at the bottom of window  
  ttk::button $w.save -text "Save & Exit" -command {save_student}
  ttk::button $w.rest -text "Reset all" -command {form_clear 1}
  ttk::button $w.clos -text "Cancel & Close" -command {
    catch {destroy .stdform}
    clean_folder
  }
  ttk::button $w.dele -text "Delete" -command {delete_stud}
  
  pack $w.clos -anchor s -side right
  pack $w.rest -anchor s -side right
  pack $w.save -anchor s -side right
  pack $w.dele -anchor s -side right
  
  update idletasks
  wm minsize $w [winfo width $w] [winfo height $w]
  form_clear
}

proc form_clear {args} {
  if {$args == {1}} {
    set response [tk_messageBox -icon question -title "Clear all information" \
      -message "Are you sure you want to reset all information for this student?" -type yesno]
    if {$response eq "no"} {return}
  }
  
  set n .stdform.note
  set fname [$n.fgeneral.efirstname get]
  set lname [$n.fgeneral.elastname get]
  
  $n.fgeneral.efirstname  delete 0 end
  $n.fgeneral.elastname   delete 0 end
  $n.fgeneral.eschoolname delete 0 end
  $n.fgeneral.eclass      delete 0 end
  $n.fgeneral.edob        delete 0 end
  $n.fgeneral.eaddress    delete 1.0 end
  $n.fgeneral.enotes      delete 1.0 end
  $n.fginfo.eguardian     delete 0 end
  $n.fginfo.cguardian     delete 0 end
  $n.fginfo.ehomphone     delete 0 end
  $n.fginfo.emobphone     delete 0 end
  $n.fginfo.eaddress      delete 1.0 end
  if {$::esocaid} {$n.fginfo.esocaid deselect}
  $n.fginfo.esocaiddet    delete 1.0 end
  if {$::eothorg} {$n.fginfo.eothorg deselect}
  $n.fginfo.eothorgdet    delete 1.0 end
  $n.fginfo.esalary       delete 0 end
  $n.fginfo.eoccupation   delete 0 end
  $n.fginfo.eworkplace    delete 0 end
  $n.fginfo.eworkadd      delete 0 end
  $n.fginfo.eemplength    delete 0 end
  $n.fginfo.eprevemp      delete 0 end
  $n.fginfo.esponsors     delete 0 end
  $n.fginfo.echildren     delete 0 end
  $n.fginfo.esibdetails   delete 1.0 end
  $n.fginfo.esibacadet    delete 1.0 end
  $n.fgrades.text         delete 1.0 end

  $n select 2
  update idletasks
  $n.fgrades.t delete top bottom
  $n select 0
  new_row $n.fgrades.t grades
  
  if {[file exists [file join nznl_files ${fname}_$lname]]} {
    file delete -force [file join nznl_files ${fname}_$lname]
  }
  focus $n
}

proc open_student {details} {
  student_form
  set n .stdform.note
  form_clear
  
  lassign $details - fname lname schoolname class
  set fullDetails [nz eval {
    SELECT * FROM students
    WHERE
      first_name = $fname
    AND
      last_name = $lname
    AND
      school_name = $schoolname
    AND
      class = $class
  }]
  
  lassign $fullDetails sid - - dob address - - contact contactid oth
  
  set guardianDetails [nz eval {
    SELECT * FROM guardians
    WHERE
      guardian_id = $contactid
  }]
  
  lassign $guardianDetails - gname hphone mphone salary socaid socaiddet \
    othreg othregdet position gaddress occupation workplace workadd \
    emplen prevemp sponsors children sibdet sibacadet gradcomm
  
  $n.fgeneral.efirstname configure -validate none
  $n.fgeneral.elastname configure -validate none
  
  $n.fgeneral.efirstname  insert 0 $fname
  $n.fgeneral.elastname   insert 0 $lname
  
  $n.fgeneral.efirstname configure -validate all
  $n.fgeneral.elastname configure -validate all
  
  .stdform.l configure -text "$fname $lname"
  
  $n.fgeneral.eschoolname insert 0 $schoolname
  $n.fgeneral.eclass      insert 0 $class
  $n.fgeneral.edob        insert 0 $dob
  $n.fgeneral.eaddress    insert 1.0 $address
  $n.fgeneral.enotes      insert 1.0 $oth
  
  $n.fginfo.eguardian     insert 0 $gname
  $n.fginfo.cguardian     insert 0 $position
  $n.fginfo.ehomphone     insert 0 $hphone
  $n.fginfo.emobphone     insert 0 $mphone
  $n.fginfo.eaddress      insert 1.0 $gaddress
  if {$socaid} {$n.fginfo.esocaid select}
  $n.fginfo.esocaiddet    insert 1.0 $socaiddet
  if {$othreg} {$n.fginfo.eothorg select}
  $n.fginfo.eothorgdet    insert 1.0 $othregdet
  $n.fginfo.esalary       insert 0 $salary
  $n.fginfo.eoccupation   insert 0 $occupation
  $n.fginfo.eworkplace    insert 0 $workplace
  $n.fginfo.eworkadd      insert 0 $workadd
  $n.fginfo.eemplength    insert 0 $emplen
  $n.fginfo.eprevemp      insert 0 $prevemp
  $n.fginfo.esponsors     insert 0 $sponsors
  $n.fginfo.echildren     insert 0 $children
  $n.fginfo.esibdetails   insert 1.0 $sibdet
  $n.fginfo.esibacadet    insert 1.0 $sibacadet
  $n.fgrades.text         insert 1.0 $gradcomm
  
  set t $n.fgrades.t
  set details [nz eval {SELECT * FROM results WHERE student_id = $sid}]
  $t delete top bottom
  if {$details != ""} {
    set row [expr {[$t size]-1}]
    foreach {id per sub grade} $details {
      $t insert end [list $per $sub $grade]
    }
  }
  
  if {[file exists [file join nznl_files ${fname}_$lname]]} {
    set imgFile [lindex [glob -nocomplain \
      -type f -directory [file join nznl_files ${fname}_$lname] *] 0]
    if {$imgFile == ""} {return}
    image create photo sel_img -file $imgFile
    image create photo fin_img
    image_resize sel_img 120 150 fin_img
    pack [label $n.fgeneral.photo.l -image fin_img] -fill both -expand 0 \
      -anchor center
    bind $n.fgeneral.photo.l <Button-1> [list profile_pic $n.fgeneral.photo]
  }
  clean_folder
}

proc save_student {} {
  set n .stdform.note
  set blanks {}
  set fname      [check $n.fgeneral.efirstname  entry]
  set lname      [check $n.fgeneral.elastname   entry]
  set schoolname [check $n.fgeneral.eschoolname entry]
  set class      [check $n.fgeneral.eclass      entry]
  set dob        [check $n.fgeneral.edob        entry]
  set address    [check $n.fgeneral.eaddress    text]
  set oth        [check $n.fgeneral.enotes      text]
  set gname      [check $n.fginfo.eguardian     entry]
  set gpos       [check $n.fginfo.cguardian     entry]
  set hphone     [check $n.fginfo.ehomphone     entry]
  set mphone     [check $n.fginfo.emobphone     entry]
  set gaddress   [check $n.fginfo.eaddress      text]
  set socaid     $::esocaid
  set socaiddet  [check $n.fginfo.esocaiddet    text]
  set othreg     $::eothorg
  set othregdet  [check $n.fginfo.eothorgdet    text]
  set salary     [check $n.fginfo.esalary       entry]
  set occupation [check $n.fginfo.eoccupation   entry]
  set workplace  [check $n.fginfo.eworkplace    entry]
  set workadd    [check $n.fginfo.eworkadd      entry]
  set emplen     [check $n.fginfo.eemplength    entry]
  set prevemp    [check $n.fginfo.eprevemp      entry]
  set sponsors   [check $n.fginfo.esponsors     entry]
  set children   [check $n.fginfo.echildren     entry]
  set sibdet     [check $n.fginfo.esibdetails   text]
  set sibacadet  [check $n.fginfo.esibacadet    text]
  set gradcomm   [check $n.fgrades.text text]
  
  if {[llength $blanks] > 0} {
    tk_messageBox -icon error -title Error \
      -message "The fields [join $blanks ", "] were not filled!"
    return
  }
  
  if {![regexp -- {\d\d/\d\d/\d{4}} $dob]} {
    tk_messageBox -icon error -title Error -message "Please follow the date format for the date of birth."
    return
  }
  
  set stud [nz eval {
    SELECT * FROM students
    WHERE
      first_name = $fname
    AND
      last_name = $lname
    AND
      school_name = $schoolname
  }]
  
  if {$stud == ""} {
    set sid [lindex [nz eval {SELECT ID FROM students ORDER BY ID DESC}] 0]
    if {$sid == ""} {set sid 0}
    incr sid
  } else {
    set sid [lindex $stud 0]
  }
  
  set guard [nz eval {
    SELECT * FROM guardians
    WHERE
      guardian_name = $gname
  }]
  if {$guard == ""} {
    set gid [lindex [nz eval {SELECT guardian_id FROM guardians ORDER BY guardian_id DESC}] 0]
    if {$gid == ""} {set gid 0}
    incr gid
  } else {
    set gid [lindex $guard 0]
  }
  
  nz eval {DELETE FROM students WHERE ID = $sid}
  nz eval {INSERT INTO students VALUES(
    $sid,
    $fname,
    $lname,
    $dob,
    $address,
    $schoolname,
    $class,
    $gname,
    $gid,
    $oth
  )}
  
  nz eval {DELETE FROM guardians WHERE guardian_id = $gid}
  nz eval {INSERT INTO guardians VALUES(
    $gid,
    $gname,
    $hphone,
    $mphone,
    $salary,
    $socaid,
    $socaiddet,
    $othreg,
    $othregdet,
    $gpos,
    $gaddress,
    $occupation,
    $workplace,
    $workadd,
    $emplen,
    $prevemp,
    $sponsors,
    $children,
    $sibdet,
    $sibacadet,
    $gradcomm
  )}
  
  nz eval {DELETE FROM results WHERE student_id = $sid}
  
  # Write the temp text into the table
  if {[$n.fgrades.t entrypath] != ""} {
    $n.fgrades.t cellconfigure [$n.fgrades.t cellindex active] \
      -text [[$n.fgrades.t entrypath] get]
  }
    
  for {set i 0} {$i < [$n.fgrades.t size]} {incr i} {
    set grades [lindex [$n.fgrades.t rowconfigure $i -text] 4]
    if {$grades == ""} {continue}
    nz eval "
      INSERT INTO results VALUES('$sid',[join [lmap x $grades {set x '$x'}] {,}])
    "
  }
  
  if {[winfo exists $n.fgeneral.photo.l]} {
    set imgFile [lindex [sel_img configure -file] 4]
    regexp -nocase -- {\.([^.]+)$} $imgFile - ext
    if {![file exists [file join nznl_files ${fname}_$lname]]} {
      file mkdir [file join nznl_files ${fname}_$lname]
    }
    file copy -force $imgFile [file join [pwd] nznl_files ${fname}_$lname \
      ${fname}_$lname.$ext]
    image delete sel_img
    image delete fin_img
  }

  tablelist_populate
  catch {destroy [winfo children $n]}
  catch {destroy .stdform}
  clean_folder
}

proc clean_folder {} {
  set folders [glob -nocomplain -directory nznl_files *]
  foreach folder $folders {
    lassign [split $folder "_"] fname lname
    set results [nz eval {
      SELECT 1 FROM students
      WHERE first_name = $fname AND last_name = $lname
    }]
    if {[llength $results] < 1} {
      file delete -force [file join nznl_files $folder]
    }
  }
}

proc new_row {tab type} {
  switch $type {
    grades {$tab insert end [lrepeat 3 {}]}
    main   {$tab insert end [list "New" {*}[lrepeat 4 {}]]}
  }
}

proc tablelist_populate {} {
  set t .f.t
  set details [nz eval {
    SELECT first_name, last_name, school_name, class FROM students
  }]
  $t delete top bottom
  if {$details != ""} {
    foreach {fname lname schoolname class} $details {
      $t insert end [list "Open" $fname $lname $schoolname $class]
    }
  }
  new_row $t main
}

proc check {w type} {
  switch $type {
    entry {set val [$w get]}
    text  {set val [$w get 1.0 end]}
  }
  set val [string trim [regsub -all -- {\s+} $val { }]]
  
  set checklist [list efirstname elastname eschoolname eclass \
    edob eguardian]
  regexp -- {\.[^.]+$} $w win
  if {$val == "" && $win in $checklist} {
    set label [regsub {\.e} $w {.l}]
    set field "\"[string trim [lindex [$label configure -text] 4] {:}]\""
    uplevel {lappend blanks $field}
    return {}
  }
  return $val
}

proc label_update {entry action validation value idx} {
  set w .stdform
  set lab [lindex [$w.l configure -text] 4]
  if {$action > -1} {
    $entry delete 0 end
    $entry insert end $value
    if {$action > 0} {
      $entry icursor [expr {$idx+1}]
    } else {
      $entry icursor $idx
    }
  }
  set lab "[$w.note.fgeneral.efirstname get] [$w.note.fgeneral.elastname get]"
  if {$lab eq " "} {
    set lab "New Student"
  }
  if {$action > -1} {
    $w.l configure -text $lab
  }
  update idletasks
  after idle [list $entry configure -validate $validation]
  return 1
}

proc delete_stud {} {
  set n .stdform.note

  set fname [$n.fgeneral.efirstname get]
  set lname [$n.fgeneral.elastname get]
  set dob [$n.fgeneral.edob get]
  
  set response [tk_messageBox -icon question -title "Delete student" \
    -message "Are you sure you want to delete the student $fname $lname from the database?" -type yesno]
  if {$response eq "no"} {return}
  
  if {[regexp {[{};\[\]$]} $fname]} {
    return
  }
    
  set gid [nz eval {
    SELECT contact_id FROM students
    WHERE first_name = $fname AND last_name = $lname
  }]
  
  set count [nz eval {SELECT contact_id FROM students WHERE contact_id = $gid}]
  
  nz eval {
    DELETE FROM students
    WHERE
    first_name = $fname AND
    last_name = $lname AND
    date_of_birth = $dob
  }
  
  if {$count == 1} {
    nz eval {DELETE FROM guardians WHERE guardian_id = $gid}
  }
  
  if {[winfo exists $n.fgeneral.photo.l]} {
    image delete sel_img
    image delete fin_img
  }
  
  if {[file exists [file join nznl_files ${fname}_$lname]]} {
    file delete -force [file join nznl_files ${fname}_$lname]
  }
  
  tablelist_populate
  catch {destroy [winfo children $n]}
  catch {destroy .stdform}
  clean_folder
}

proc sql_query {} {
  set results [nz eval {SELECT 1 FROM students}]
  if {[llength $results] < 1} {
    tk_messageBox -icon error -title Error -message "No data inserted yet!"
    return
  }
  set w .query
  catch {destroy $w}
  toplevel $w
  wm title .query "SQLite Query"
  wm geometry . +100+50
  set menu $w.menu
  menu $menu -tearoff 0
  $menu add command -label "Run" -command [list run_query $w]
  $menu add command -label "Export" -command [list export_results $w]
  
  bind $w <KeyPress-F5> [list run_query $w]
  
  $w configure -menu $menu
  
  
  ttk::notebook $w.note
  set n $w.note
  grid $n -row 0 -column 0 -sticky nsew
  
  ttk::notebook::enableTraversal $n
  
  ttk::frame $n.tableview -height 300 -width 300 -padding "5 5"
  $n add $n.tableview -text " Tableview "
  
  ttk::frame $n.sqlview -height 300 -width 300 -padding "5 5"
  $n add $n.sqlview -text " SQL "
  
  label $n.tableview.tablelab -text "Table:"
  ttk::combobox $n.tableview.tablecbox -values {students guardians results}
  
  grid $n.tableview.tablelab -row 0 -column 0 -padx 5 -pady 5
  grid $n.tableview.tablecbox -row 0 -column 1 -padx 5 -pady 5
  
  bind $n.tableview.tablecbox <<ComboboxSelected>> {update_tableview %W 1}
  
  pack [text $n.sqlview.text -yscrollcommand "$n.sqlview.s set"] -side left \
    -anchor ne -fill both -expand 1
  pack [scrollbar $n.sqlview.s -command "$n.sqlview.text yview"] -fill y -side left
  
  frame $w.sidepane -height 500 -width 10
  grid $w.sidepane -row 0 -column 1 -sticky nsew
  
  
  ttk::treeview $w.sidepane.tree -columns table -yscroll "$w.sidepane.vs set"
  $w.sidepane.tree heading \#0 -text "Tables"
  ttk::scrollbar $w.sidepane.vs -command "$w.sidepane.tree yview"
  
  $w.sidepane.tree column table -stretch 0 -width 10
  
  proc populate_tree {tree} {
    set tables [nz eval {SELECT name FROM sqlite_master WHERE type = 'table'}]
    foreach table $tables {
      set node [$tree insert {} end -text $table]
      set fields [nz eval {
        SELECT sql FROM sqlite_master
        WHERE type = 'table' AND name = $table
      }]
      regexp -- {\(([^()]+)\)} $fields - m
      set l [split $m ","]
      set fields [lmap x $l {set x "\[[lindex $x 0]\] ([lindex $x 1])"}]
      foreach field $fields {
        set id [$tree insert $node end -text $field]
      }
    } 
  }
   
  grid $w.sidepane.tree -row 0 -column 0 -sticky nsew
  grid $w.sidepane.vs   -row 0 -column 1 -sticky nsew
  
  frame $w.fdown -height 300 -width 500 -pady 5 -padx 5 -relief sunken
  grid $w.fdown -row 1 -column 0 -columnspan 2 -sticky nsew
  
  grid rowconfigure $w.sidepane 0 -weight 1
  grid rowconfigure $w 0 -weight 1
  grid columnconfigure $w 0 -weight 1
  
  populate_tree $w.sidepane.tree
  
  proc run_query {w} {
    upvar columns columns
    
    set tid [$w.note select]
    
    catch {destroy $w.fdown.s}
    catch {destroy $w.fdown.text}
    catch {destroy $w.fdown.t}
    catch {destroy $w.fdown.hs}
    
    if {[lindex [split $tid "."] end] == "sqlview"} {
      set query [$w.note.sqlview.text get 1.0 end]
      
      if {[regexp -all -nocase -- {\yFROM\y} $query] > 1} {
        pack [text $w.fdown.text] -side top -anchor ne -fill both
        $w.fdown.text insert end "Subqueries/multiple queries not allowed."
        return
      } elseif {[regexp -all -nocase -- {\yINTO\y} $query]} {
        pack [text $w.fdown.text] -side top -anchor ne -fill both
        $w.fdown.text insert end "Creation of tables not allowed."
        return
      }
      
      if {[catch {set results [nz eval $query]} err]} {
        pack [text $w.fdown.text] -side top -anchor ne -fill both
        $w.fdown.text insert end "$err"
        return
      } else {
        if {[regexp -nocase -- {select } $query]} {
          regexp -nocase -- {select\s+(.+)from} $query - fields
          set colnames [lmap {f s} [regexp -inline -all -nocase {(\[[^\]]+\]|[^, \n]+)(?:,|$)} [string trim $fields]] {set s "10 $s"}]
          scrollbar $w.fdown.s -command "$w.fdown.t yview"
          scrollbar $w.fdown.hs -command "$w.fdown.t xview" -orient horizontal
          if {[set sidx [lsearch $colnames "*\**"]] > -1} {
            set cols {}
            nz eval $query values {lappend cols $values(*); break}
            set colnames [lmap x [lindex $cols 0] {set x "10 $x"}]
          }
          set columns [lindex $cols 0]
          tablelist::tablelist $w.fdown.t -columns [join $colnames " "] \
            -stretch all -background white -yscrollcommand "$w.fdown.s set" \
            -resizablecolumns 1 -selecttype cell -showeditcursor 0 \
            -showseparators 1 -xscrollcommand "$w.fdown.hs set"
          grid $w.fdown.t -row 0 -column 0 -sticky nsew
          grid $w.fdown.s -row 0 -column 1 -sticky nsew
          grid $w.fdown.hs -row 1 -column 0 -sticky nsew
          
          foreach $columns $results {
            set vars [lmap x $columns {set $x}]
            $w.fdown.t insert end $vars
          }
        } else {
          pack [text $w.fdown.text] -side top -anchor ne -fill both
          $w.fdown.text insert end "Query successfully executed!"
        }
      }
    } else {
      set table [$w.note.tableview.tablecbox get]
      
      set ws [winfo children $w.note.tableview]
      set columns {}
      set param {}
      foreach field $ws {
        if {[regexp -- {fieldscbox\d+} $field]} {
          set toadd [$field get]
          if {$toadd == "*"} {
            set all [lindex [$field configure -values] 4]
            set all [lreplace $all 0 0]
            foreach item $all {lappend columns $item}
          } elseif {$toadd != ""} {
            lappend columns $toadd
          } else {
            continue
          }
        }
        set f [winfo parent $field]
        if {[regexp -- {fieldccond(\d+)} $field - s] &&
            [$field get] != "" &&
            [$f.fieldpcond$s get] != ""
        } {
          if {$param != ""} {
            set i $s
            while {$i > 0} {
              incr i -1
              if {[$f.fieldscbox$i get] != ""} {break}
            }
            append param " [$f.fieldcomp$i get] "
          }
          append param [$f.fieldscbox$s get] " [$field get] "  "'[string map {' ''} [$f.fieldpcond$s get]]'"
        }
        
      }

      set colnames [lmap x $columns {set x "10 $x"}]
      scrollbar $w.fdown.s -command "$w.fdown.t yview"
      scrollbar $w.fdown.hs -command "$w.fdown.t xview" -orient horizontal
      
      set code "SELECT [join $columns ","] FROM $table"
      
      if {$param != ""} {
        append code " WHERE $param"
      }
      if {[catch {set results [nz eval $code]} err]} {
        pack [text $w.fdown.text] -side top -anchor ne -fill both
        $w.fdown.text insert end "Please ensure that a table and at least 1 field have been selected."
        return
      }
      
      tablelist::tablelist $w.fdown.t -columns [join $colnames " "] \
        -stretch all -background white -yscrollcommand "$w.fdown.s set" \
        -resizablecolumns 1 -selecttype cell -showeditcursor 0 \
        -showseparators 1 -xscrollcommand "$w.fdown.hs set"
      grid $w.fdown.t -row 0 -column 0 -sticky nsew
      grid $w.fdown.s -row 0 -column 1 -sticky nsew
      grid $w.fdown.hs -row 1 -column 0 -sticky nsew
      
      grid columnconfigure $w.fdown 0 -weight 1
      grid rowconfigure $w.fdown 0 -weight 1
      
      foreach $columns $results {
        set vars [lmap x $columns {set $x}]
        $w.fdown.t insert end $vars
      }
      
    }
    return
  }
  
  proc update_tableview {w stat} {
    set n [winfo parent $w]
    set ws [winfo children $n]
    set table [$n.tablecbox get]
    foreach w $ws {
      if {[regexp -- {field} $w] && $stat} {
        destroy $w
      }
    }
    set ws [winfo children $n]
    set fields [lsearch -all -regexp -nocase -inline $ws {fieldlab\d+}]
    if {$fields == {}} {
      set num 1
    } else {
      set fields [lmap m $fields {regexp -inline -- {\d+} $m}]
      set num [lindex [lsort -integer $fields] end]
      if {[$n.fieldscbox$num get] == "" || $num == 10} {return}
      incr num
    }
    label $n.fieldlab$num -text "Field $num:"
    grid $n.fieldlab$num -row $num -column 0 -pady 5 -padx 5
    
    set cols {}
    nz eval "SELECT * FROM $table" values {lappend cols $values(*); break}
    ttk::combobox $n.fieldscbox$num -values [list * {*}[lindex $cols 0]]
    grid $n.fieldscbox$num -row $num -column 1
    
    label $n.fieldlcond$num -text "where"
    grid $n.fieldlcond$num -row $num -column 2 -pady 5 -padx 5
    ttk::combobox $n.fieldccond$num -values {= > >= < <= LIKE}
    grid $n.fieldccond$num -row $num -column 3 -pady 5 -padx 5
    entry $n.fieldpcond$num
    grid $n.fieldpcond$num -row $num -column 4 -pady 5 -padx 5
    
    if {$num > 1} {
      set prev [expr {$num-1}]
      ttk::combobox $n.fieldcomp$prev -values {AND OR}
      $n.fieldcomp$prev set "AND"
      grid $n.fieldcomp$prev -row $prev -column 5 -pady 5 -padx 5
    }
    
    bind $n.fieldscbox$num <<ComboboxSelected>> {update_tableview %W 0}
  }
  
  set columns {}
  proc export_results {w} {
    upvar columns columns
    if {![winfo exists $w.fdown.t]} {
      tk_messageBox -icon error -title Error -message "No query has been run yet!"
      return
    }
    
    set types {{"Text files"   .txt}}
    set files [glob -nocomplain Query*.txt]
    if {[llength $files] == 0} {
      set number 1
    } else {
      regexp -- {Query(\d+)\.txt} [lindex $files end] - number
      incr number
    }
    set file [tk_getSaveFile -filetypes $types -parent $w \
      -initialfile "Query$number.txt" -initialdir [pwd] \
      -defaultextension .txt]
    if {$file == ""} {return}
    set f [open $file w]
    puts $f [join $columns \t]
    for {set i 0} {$i < [$w.fdown.t size]} {incr i} {
      set results [lindex [$w.fdown.t rowconfigure $i -text] 4]
      puts $f [join $results \t]
    }
    close $f
    exec {*}[auto_execok start] "Excel.exe" $file
    return
  }
}

proc calendar {w} {
  set cal .stdform.cal
  catch {destroy $cal}
  toplevel $cal
  
  wm title $cal "Choose date"
  
  # proc to change the layout when month or year are changed
  proc date_adjust {cal dir {monthlist ""}} {
    set m [$cal.f.s1 get]
    if {$monthlist != "" && $m ni $monthlist} {
      tk_messageBox -title Error -message "Please insert a valid month."
      focus $cal
      return
    }
    set cmonth [lindex [split [date_format "01-$m-[$cal.f.s2 get]"] "/"] 1]
    set cyear [$cal.f.s2 get]
    if {$cyear < 1900 || $cyear > 9999} {
      tk_messageBox -title Error -message "Please insert a year between 1900 and 9999."
      focus $cal
      return
    }
    set cmonth [string trimleft $cmonth 0]
    incr cmonth $dir
    if {($cmonth == 0 && $dir == "-1") || ($cmonth == 13 && $dir == "+1")} {
      incr cyear $dir
      set cmonth [expr {$cmonth == 0 ? 12 : 1}]
      $cal.f.s2 set $cyear
    }
    cal_display $cal $cmonth $cyear
  }
  
  # proc to display the calendar layout
  proc cal_display {cal month year} {
    set canvas $cal.c
    $canvas delete all
    lassign [list 20 20 20 20 20] x0 x y dx dy
    set xmax [expr {$x0+$dx*6}]
    
    $canvas create rectangle 10 0 30 150 -outline "" -tag wkd
    $canvas create rectangle 130 0 150 150 -outline "" -tag wkd
    
    foreach i {S M T W T F S} {
      $canvas create text $x $y -text $i -fill blue
      incr x $dx
    }
    scan [clock format [clock scan $month/01/$year] -format %w] %d weekday
    set x [expr {$x0+$weekday*$dx}]
    incr y $dy
    set month [string trimleft $month 0]
    set nmax [number_of_days $month $year]

    for {set d 1} {$d <= $nmax} {incr d} {
      set id [$canvas create text $x $y -text $d -tag day]
      if {[format %02d $d] == [clock format [clock scan now] -format %d]
        && [format %02d $month] == [clock format [clock scan now] -format %m]
        && $year == [clock format [clock scan now] -format %Y]
      } {
        $canvas itemconfigure $id -fill red -tags {day cday}
      }
      incr x $dx
      if {$x > $xmax} {
        set x $x0
        incr y $dy
      }
    }
    $canvas itemconfigure wkd -fill #C4D1DF
    
    $canvas bind day <ButtonPress-1> {
      set item [%W find withtag current]
      set day [%W itemcget $item -text]
      if {$day eq ""} {break}
      if {[%W find withtag clicked] == ""} {
        if {"cday" ni [%W gettags $item]} {
          %W itemconfigure $item -fill green -tags {day clicked}
        } else {
          %W itemconfigure $item -fill green -tags {day clicked cday}
        }  
      } else {
        if {[%W find withtag clicked] == [%W find withtag cday]} {
          if {$item == [%W find withtag cday]} {
            break
          } else {
            %W itemconfigure $item -fill green -tags {day clicked}
            %W itemconfigure cday -fill red -tags {day cday}
          }
        } else {
          if {$item == [%W find withtag cday]} {
            %W itemconfigure clicked -fill black -tags {day}
            %W itemconfigure $item -fill green -tags {day cday clicked}
          } else {
            %W itemconfigure clicked -fill black -tags {day}
            %W itemconfigure $item -fill green -tags {day clicked}
          }
        }
      }
      set cal [winfo parent %W]
      $cal.f2.e delete 0 end
      $cal.f2.e insert end [date_format "$day-[$cal.f.s1 get]-[$cal.f.s2 get]"]
    }    
    
    $canvas bind day <Double-ButtonPress-1> {
      set item [%W find withtag clicked]
      set day [%W itemcget $item -text]
      if {$day eq ""} {break}
      set cal [winfo parent %W]
      pick_date $cal [date_format "$day-[$cal.f.s1 get]-[$cal.f.s2 get]"]
    }
  }
  
  # proc to convert alphabetic date to numeric
  proc date_format {date} {
    return [clock format [clock scan $date -format {%d-%B-%Y}] -format {%d/%m/%Y}]
  }
  
  # proc to insert chosen date (through entry or double-click) to main window
  proc pick_date {cal {cdate ""}} {
    if {$cdate eq ""} {
      set cdate [$cal.f2.e get]
    }
    puts $cal
    if {$cal == ".cal"} {
      set cdate [clock scan $cdate -format {%d/%m/%Y}]
      set fdate [get_friday $cdate]
      .stdform.note.fgeneral.edob configure -text $fdate
      down_update
    } else {
      set e [winfo parent $cal]
      $e.note.fgeneral.edob delete 0 end
      $e.note.fgeneral.edob insert end $cdate
    }
    cal_exit $cal
  }
  
  # proc to close calender
  proc cal_exit {cal} {
    focus [winfo parent $cal]
    destroy $cal   
  }
  
  proc number_of_days {month year} {
    if {$month == 12} {
      set month 1
      incr year
    }
    clock format [clock scan "[incr month]/01/$year 1 day ago"] -format %d
  }
  
  lassign [split [clock format [clock scan now] -format "%d-%m-%Y"] "-"] d m y
  
  array set months {
    01 January
    02 February
    03 March
    04 April
    05 May
    06 June
    07 July
    08 August
    09 September
    10 October
    11 November
    12 December
  }
  set monthlist [lmap {a b} [array get months] {set b}]
  pack [frame $cal.f]
  ttk::spinbox $cal.f.s1 -values $monthlist -width 10 -wrap 1
  ttk::spinbox $cal.f.s2 -from 1900 -to 9999 -validate key \
    -validatecommand {string is integer %P} -command [list date_adjust $cal 0]
  bind $cal.f.s1 <<Decrement>> [list date_adjust $cal -1 $monthlist]
  bind $cal.f.s1 <<Increment>> [list date_adjust $cal +1 $monthlist]
  bind $cal.f.s1 <KeyPress-Return> [list date_adjust $cal 0 $monthlist]
  bind $cal.f.s2 <KeyPress-Return> [list date_adjust $cal 0 $monthlist]
  $cal.f.s1 set $months($m)
  $cal.f.s2 set $y
  pack $cal.f.s1 -side left -fill both -padx 10 -pady 10
  pack $cal.f.s2 -side left -fill both -padx 10 -pady 10
  
  set canvas [canvas $cal.c -width 160 -height 160 -background #F0F0F0]
  pack $cal.c
  pack [frame $cal.f2] -side left -padx 10 -pady 10
  ttk::entry $cal.f2.e -textvariable fulldate -width 20 -justify center
  pack $cal.f2.e -padx 10 -pady 10
  bind $cal.f2.e <KeyPress-Return> [list pick_date $cal]
  $cal.f2.e delete 0 end
  $cal.f2.e insert end "$d/$m/$y"
  pack [ttk::button $cal.f2.b1 -text "OK" -command [list pick_date $cal]] -side left \
    -padx 20
  pack [ttk::button $cal.f2.b2 -text "Cancel" -command [list cal_exit $cal]] -side left \
    -padx 20
  cal_display $cal $m $y
}

# http://wiki.tcl.tk/11196 shortened a bit
proc image_resize {src newx newy {dest ""}} {
  set mx [image width $src]
  set my [image height $src]

  if {$dest == ""} {set dest [image create photo]}
  $dest configure -width $newx -height $newy

  # Check if we can just zoom using -zoom option on copy
  if { $newx % $mx == 0 && $newy % $my == 0} {
     set ix [expr {$newx / $mx}]
     set iy [expr {$newy / $my}]
     $dest copy $src -zoom $ix $iy
     return $dest
  }

  set ny 0
  set ytot $my

  for {set y 0} {$y < $my} {incr y} {
    # Do horizontal resize
    foreach {pr pg pb} [$src get 0 $y] {break}

    set row [list]
    set thisrow [list]

    set nx 0
    set xtot $mx

    for {set x 1} {$x < $mx} {incr x} {
      # Add whole pixels as necessary
      while { $xtot <= $newx } {
        lappend row [format "#%02x%02x%02x" $pr $pg $pb]
        lappend thisrow $pr $pg $pb
        incr xtot $mx
        incr nx
      }
      # Now add mixed pixels
      foreach {r g b} [$src get $x $y] {break}

      # Calculate ratios to use
      set xtot [expr {$xtot - $newx}]
      set rn $xtot
      set rp [expr {$mx - $xtot}]

      # This section covers shrinking an image where
      # more than 1 source pixel may be required to
      # define the destination pixel

      set xr 0
      set xg 0
      set xb 0

      while { $xtot > $newx } {
        incr xr $r
        incr xg $g
        incr xb $b

        set xtot [expr {$xtot - $newx}]
        incr x
        foreach {r g b} [$src get $x $y] {break}
      }

      # Work out the new pixel colours
      set tr [expr {int( ($rn*$r + $xr + $rp*$pr) / $mx)}]
      set tg [expr {int( ($rn*$g + $xg + $rp*$pg) / $mx)}]
      set tb [expr {int( ($rn*$b + $xb + $rp*$pb) / $mx)}]
      if {$tr > 255} {set tr 255}
      if {$tg > 255} {set tg 255}
      if {$tb > 255} {set tb 255}

      # Output the pixel
      lappend row [format "#%02x%02x%02x" $tr $tg $tb]
      lappend thisrow $tr $tg $tb
      incr xtot $mx
      incr nx
      set pr $r
      set pg $g
      set pb $b
    }

    # Finish off pixels on this row
    while { $nx < $newx } {
      lappend row [format "#%02x%02x%02x" $r $g $b]
      lappend thisrow $r $g $b
      incr nx
    }

    # Do vertical resize
    if {[info exists prevrow]} {
      set nrow [list]
      # Add whole lines as necessary
      while { $ytot <= $newy } {
        $dest put -to 0 $ny [list $prow]
        incr ytot $my
        incr ny
      }

      # Now add mixed line
      # Calculate ratios to use

      set ytot [expr {$ytot - $newy}]
      set rn $ytot
      set rp [expr {$my - $rn}]

      # This section covers shrinking an image
      # where a single pixel is made from more than
      # 2 others.  Actually we cheat and just remove 
      # a line of pixels which is not as good as it should be

      while { $ytot > $newy } {
        set ytot [expr {$ytot - $newy}]
        incr y
        continue
      }

      # Calculate new row

      foreach {pr pg pb} $prevrow {r g b} $thisrow {
        set tr [expr {int( ($rn*$r + $rp*$pr) / $my)}]
        set tg [expr {int( ($rn*$g + $rp*$pg) / $my)}]
        set tb [expr {int( ($rn*$b + $rp*$pb) / $my)}]
        lappend nrow [format "#%02x%02x%02x" $tr $tg $tb]
      }

      $dest put -to 0 $ny [list $nrow]

      incr ytot $my
      incr ny
    }

    set prevrow $thisrow
    set prow $row

    update idletasks
  }

  # Finish off last rows
  while { $ny < $newy } {
     $dest put -to 0 $ny [list $row]
     incr ny
  }
  update idletasks

  return $dest
}
 
tablelist_populate
