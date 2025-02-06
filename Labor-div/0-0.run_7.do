*===============================================================================
* Project:       Labor diversification
* Author:        Valentina
* Creation Date:     Jan 2025  
*===============================================================================

    local language = "ENG"
    global chapter = "7_Labor_diversification"
	global total_hr	"total_hr" // total_hr_impu

    global gdData_7L = "${gdOutput}/$chapter/Data"
    global gdDatatemp_7L = "${gdOutput}/$chapter/Data/temp"
    global gdExcel_7L = "${gdOutput}/$chapter/Excel"
    global gdFig_7L = "${gdOutput}/$chapter/Figures"


if "`language'" == "ESP" {
	putexcel set "${gdExcel_4M}/Multidimensional_QNG_SPA.xlsx", sheet("Int. comparison", replace) modify
}
else if "`language'" == "ENG" {
	putexcel set "${gdExcel_4M}/Multidimensional_QNG_ENG.xlsx", sheet("Int. comparison", replace) modify
}	


if ("$gdDo" == "") {
	di as error "Configure work environment in 01-init.do before running the code."
	error 1
}



*If needed, create directories, and sub-directories used in the process 
foreach d in "${gdData_7L}" "${gdDatatemp_7L}" "${gdExcel_7L}" "${gdFig_7L}"  {
	confirmdir "`d'" 
	if _rc!=0 mkdir "`d'" 
}


*            Cleaning Labor diversificarion and Human Capital datasets
*===============================================================================	
do "$gdDo/$chapter/1-0.cleaning_7.do" // 

*           	          Income Measure Analysis
*===============================================================================	

do "$gdDo/$chapter/1-1.income_measure_7.do"
*           	                  
*===============================================================================	

do "$gdDo/$chapter/2-1.figures_7.do"

33 run master
*           	                  Complete dataset
*===============================================================================	


*           	                 Figures
*===============================================================================	


*           	                 Data set maps
*===============================================================================	


*           	                Poverty note
*===============================================================================	





exit