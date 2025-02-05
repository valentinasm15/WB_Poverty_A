*===============================================================================
*Author: 	Jia Gao 
*Date: 		7/1/2021
*===============================================================================
	*Vulnerability Tool
*===============================================================================
   	*Local directory to the shared folder

    global chapter = "3_Economic_Insecurity"
	global n "" // Cambiar tambien en oupout.do
	/* global n "n" */
*===============================================================================
	*DO NOT MODIFY BEYOND THIS POINT
*===============================================================================		
	global year 		"2022" 
	local language 		 "ENG"


	** Results directory
    global gdData_3EI 		"${gdOutput}/$chapter/Data" 
    global gdDatatemp_3EI 	"${gdOutput}/$chapter/Data/temp"
    global gdExcel_3EI 		"${gdOutput}/$chapter/Excel"
    global gdFig_3EI 	 	"${gdOutput}/$chapter/Figures"


if "`language'" == "ESP" {
	putexcel set "${gdExcel_3EI}/Multidimensional_QNG_SPA.xlsx", sheet("Int. comparison", replace) modify
}
else if "`language'" == "ENG" {
	putexcel set "${gdExcel_3EI}/Multidimensional_QNG_ENG.xlsx", sheet("Int. comparison", replace) modify
}	


if ("$gdDo" == "") {
	di as error "Configure work environment in 01-init.do before running the code."
	error 1
}



*If needed, create directories, and sub-directories used in the process 
foreach d in "${gdData_3EI}" "${gdDatatemp_3EI}" "${gdExcel_3EI}" "${gdFig_3EI}"  {
	confirmdir "`d'" 
	if _rc!=0 mkdir "`d'" 
}

*===============================================================================
	*Run necessary ado files
*===============================================================================	2
	
	local files : dir "$gdDo/$chapter/ados/" files "*.ado"
	foreach f of local files {
		dis in yellow "`f'"
		qui: run "$gdDo/$chapter/ados/`f'"
	}
	

*===============================================================================
	*Run do files to produce outcome
*===============================================================================
	

*            						Cleaning 
*===============================================================================	
do "$gdDo/$chapter/cleaning/1-0.cleaning_3$n.do" // 


*           	          			Estimation
*===============================================================================	

do "$gdDo/$chapter/estimation.do"

*           	                  Outputs
*===============================================================================	

do "$gdDo/$chapter/output.do"

80 master
*           	                  Maps
*===============================================================================	

/* do "$gdDo/`chapter'/maps.do" */

*           	                 Figures
*===============================================================================	

/* quietly do "$gdDo/`chapter'/" */





exit