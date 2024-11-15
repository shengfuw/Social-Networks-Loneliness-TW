
clear *
drop _all
cap: log close
set more off

/* ############ Set file path of directory ############ */
global DirectoryPath = ""
/* #################################################### */

cd "$DirectoryPath"

* Create subdirectories
quietly{
capture mkdir code
capture mkdir rawdata
capture mkdir workdata 
capture mkdir log
capture mkdir output

* Set global variables of subdirectories
global code = "$DirectoryPath/code"
global rawdata = "$DirectoryPath/rawdata"
global workdata = "$DirectoryPath/workdata"
global log = "$DirectoryPath/log"
global output = "$DirectoryPath/output"
}


cd "$rawdata"
ls *.dta, wide

// use "TEST.dta, clear"
// codebook, compact
