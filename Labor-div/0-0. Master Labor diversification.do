*===============================================================================
* Project:       Labor diversification
* Author:        Valentina and Catalina
* Creation Date:     Jan 2025  
*===============================================================================
clear all 
set more off

    global language = "english"
    global chapter = "7_Labor_diversification"
	global total_hr	"total_hr" // total_hr_impu

    global gdData_7L = "${gdOutput}/$chapter/Data"
    global gdDatatemp_7L = "${gdOutput}/$chapter/Data/temp"
    global gdExcel_7L = "${gdOutput}/$chapter/Excel"
    global gdFig_7L = "${gdOutput}/$chapter/Figures"



if ("$gdDo" == "") {
	di as error "Configure work environment in 01-init.do before running the code."
	error 1
}



*If needed, create directories, and sub-directories used in the process 
foreach d in "${gdData_7L}" "${gdDatatemp_7L}" "${gdExcel_7L}" "${gdFig_7L}"  {
	confirmdir "`d'" 
	if _rc!=0 mkdir "`d'" 
}
	global data         "${gdData}/Household surveys/ENH2"  



*            Cleaning Labor diversificarion and Human Capital datasets
*===============================================================================	

do "$gdDo/$chapter/1. Cleaning 7.do" // 

*           	          Income Analysis
*===============================================================================	

do "$gdDo/$chapter/2. Income Measure.do"

do "$gdDo/$chapter/3. Income Shares.do"

do "$gdDo/$chapter/4. Job Quality.do"

*           	          Stats Analysis
*===============================================================================	

/* do "$gdDo/$chapter/5. Regressions & Stats.do" */



*           	               Figures   
*===============================================================================	

do "$gdDo/$chapter/6-0. Figures - Labor force.do"

/* do "$gdDo/$chapter/6-2. Figures - Productivity.do" */
/* do "$gdDo/$chapter/6-5. Figures - Returns to education.do" */
/* do "$gdDo/$chapter/6-6. Figures - JQM.do" */
/* do "$gdDo/$chapter/6-x. Figures - Employm - Unemploym - Vuln.do" */
/* do "$gdDo/$chapter/6-x. Figures - Informality.do" */
/* do "$gdDo/$chapter/6-x. Figures - Sectors.do" */

/* do "$gdDo/$chapter/6.Boxplot.do" */

/* do "$gdDo/$chapter/7.Figure_scatters.do" */


******** END of Master Labor Diversification chapter


exit