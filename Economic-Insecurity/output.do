*===============================================================================  
* Author: Jia Gao
* Date: 07/01/2021
* Title: Output: report poverty and vulnerability
* version: * ORIGINAL plus some changes
*===============================================================================
	
*export subgroup values to excel
local id_vars "cod_region cod_provincia cod_distrito cod_MU_DU interview__key"
/* global n "" */
/* global n "n" */

import excel using "$gdExcel_3EI/VUL TOOL_${year}$n.xlsx", sheet(Parameter2) first clear 
 
	levelsof variable, local(myvariable)	

	foreach x of local myvariable {
		levelsof value if variable=="`x'", local(_xx) clean 
		/* local `x'= `_xx' */
		local `x'= `"`_xx'"'
	}
	
	
	
tempname subgroups
tempfile subgroups_value
postfile `subgroups' str30 groupvalue using "`subgroups_value'", replace

use "$gdData_3EI/est_vuln_${year}$n", clear	

	foreach i of local subcategory {
		dis "`i'"
		levelsof `i', local(levels) 


		foreach y of  local levels {
			post `subgroups' ("`y'")
		}
	}

	postclose `subgroups'

use `subgroups_value', clear
	drop if groupvalue == "."

/* Another way to index match 
export excel "$xls_tool", sheet(All) cell(C7) sheetmodify first(variable) keepcellfm
export excel "$xls_tool", sheet("Risk_Vulnerable Pop") cell(C7) sheetmodify first(variable) keepcellfm 
*/


*===============================================================================
loc outcome  ln_pl yhat etotal_sq_hat* eij_sq_hat* u${const}_sq_hat poor prob_etotal vulnerable_etotal* vulnerable_eij* vulnerable_uj poverty_induced risk_induced pov_cat1 pov_cat2 pov_cat3 pov_cat4
*===============================================================================
*Outcome for subgroups
/* run "$theado/sp_groupfunction.ado"
run "$theado/groupfunction.ado" */

foreach i of local subcategory {
	dis "`i'"
 use "$gdData_3EI/est_vuln_${year}$n", clear	

	sort `id_vars'
	sp_groupfunction [aw=`wt'], mean(`outcome') by (`i')
	rename `i' group
	gen subcategory="`i'"
	
	tempfile data_`i'
	save `data_`i''
}


*Outcome for the whole sample 

use "$gdData_3EI/est_vuln_${year}$n", clear	

	gen group = "all"

	sp_groupfunction [aw=`wt'], mean(`outcome') by (group) 


foreach i of local subcategory {
	append using `data_`i''
}

	gen const = $const
	gen concat = variable +"_"+ subcategory+"_"+group
	gen subc_group="_"+subcategory+"_"+group
	order concat value group measure _population variable subcategory subc_group const

	export excel "$gdExcel_3EI/VUL TOOL_${year}$n.xlsx", sheet(results) sheetreplace first(variable) locale(C)
	

*===============================================================================
*Outcome among risk-vulnerable people by subgroups	
foreach i of local subcategory {

 use "$gdData_3EI/est_vuln_${year}$n", clear
 dis "$gdData_3EI/est_vuln_${year}$n"

	keep if risk_vul == 1
	sp_groupfunction [aw=`wt'], mean(`outcome') by (`i')
	rename `i' group
	gen subcategory="`i'"
		
	tempfile data_`i'
	save `data_`i''
}

*Outcome for risk-vulnerable people
use "$gdData_3EI/est_vuln_${year}$n", clear	
	keep if risk_vul == 1
	gen group = "all"
	
	sp_groupfunction [aw=`wt'], mean(`outcome') by (group) 

	foreach i of local subcategory {	
		append using `data_`i'', force
	}

	gen const = $const
	gen concat = variable +"_"+ subcategory+"_"+group
	gen subc_group="_"+subcategory+"_"+group
	order concat value group measure _population variable subcategory const
	
export excel "$gdExcel_3EI/VUL TOOL_${year}$n.xlsx", sheet(results_riskvul) sheetreplace first(variable) locale(C)

*===============================================================================	
*Draw the figure to show vulnerable to poverty based on probability threshold 
use "$gdData_3EI/est_vuln_${year}$n", clear	

	
	local PL0 = ln_pl
	local PL1 = ln(1.25)+ln_pl
	local PL2 = ln(1.5)+ln_pl
	disp `PL1' `PL0' `PL2'


	twoway histogram yhat if yhat < ln_pl, bcolor(black) fcolor(blue)  freq width(0.05) xline(`PL0', lcolor(red)) ||  histogram yhat if yhat >= ln_pl & vulnerable_etotal == 1, bcolor(black) fcolor(red) freq  width(0.05) xline(`PL1', lcolor(yellow)) || histogram yhat if yhat >= ln_pl & vulnerable_etotal == 0, bcolor(black) fcolor(white) freq width(0.05) legend(order(1 "chronic poverty" 2 "vulnerable to poverty" 3 "non-poor, non-vulnerable")) xtitle("predicted log per capita consumption") title(Vulnerable to poverty based on `vul_th' probability threshold)  xline(`PL2', lcolor(green)) note("Note: red vertical line is the poverty line(PL), yellow line is 1.25*PL, and green line is 1.5*PL")
	graph export "$gdFig_3EI/vulnerability.pdf", replace 
	graph export "$gdFig_3EI/vulnerability.png", replace
 

*===============================================================================

******************************END

