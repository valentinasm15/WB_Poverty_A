*===============================================================================  
* Author: 
* Date: Oct, 2024
* Title: Estimation
*===============================================================================

*Bring parameters from excel
import excel using "$gdExcel_3EI/VUL TOOL_${year}${n}.xlsx", sheet(Parameter2) first clear 
/* import excel using "$gdExcel_3EI/VUL TOOL_${year}n.xlsx", sheet(Parameter2) first clear  */

	levelsof variable, local(myvariable)	

	foreach x of local myvariable {
		levelsof value if variable=="`x'", local(_xx) clean 
		/* local `x'= `_xx' */
		local `x'= `"`_xx'"'

	}


if (`newmodel' == 1) {
*===============================================================================
* 		Multiple-level	Estimation
* Source of vulnerability: idiosyncratic and covariance
*===============================================================================
use "$gdData_3EI/prep_data_${year}${n}", clear //This is a cleaned dataset

	gen ln_con_pc 	=	ln(`con_pc')

*Step 1: select only the significant interactions by using a multilevel model with random intercepts

*Define a full set of interactions between community controls and household level controls	
loc covar_inter 

	foreach var of varlist `covar_community' {
		foreach covar of varlist `covar_hh' {
			gen `var'_`covar' = `var'*`covar'
			local covar_inter `var'_`covar' `covar_inter'
		}	
	}


	mixed ln_con_pc `covar_community'  `covar_hh' `covar_inter' ||  `comm_id':
	
local covar_inter_II  //redefine interactions by selecting those that are significant
	foreach var of local covar_inter {
		if (2*ttail( e(N)-e(rank) , abs(_b[ln_con_pc:`var'] /_se[ln_con_pc:`var'] )) <= 0.01) {
			local covar_inter_II `covar_inter_II' `var'
		}
	}

	*repeat the above process 
	mixed ln_con_pc `covar_community'  `covar_hh' `covar_inter_II' || `comm_id':
	
local covar_inter_III //redefine interactions
	foreach var of local covar_inter_II {
		if (2*ttail( e(N)-e(rank) , abs(_b[ln_con_pc:`var'] /_se[ln_con_pc:`var'] )) <= 0.01) {
			local covar_inter_III `covar_inter_III' `var'
		}
	}	

	global covar_inter `covar_inter_III'

*===============================================================================	
*Step 2: select certain HH level variables to have a random slope	 
	
	local j = 1
	foreach i of local slope { 
		global var_`j'  `i'
		local j = `j'+ 1  //j is total # of hh level variables
	}

	local k = int(`j'/4) 

local covar_hh_slope  
	forvalues i = 0/ `k' {
		local m = 4*`i' + 1
		local n = 4*`i' + 2
		local t = 4*`i' + 3 
		local s = 4*`i' + 4
		mixed ln_con_pc  `covar_hh' || `comm_id':  ${var_`m'} ${var_`n'} ${var_`t'} ${var_`s'}  //In order to reduce computation time, each time we only consider 4 variables having the random slope
		
*Use _diparm to calculate random effects parameter's variance and its Std. Err. after "mixed estimation"	
*See the link: https://stats.idre.ucla.edu/stata/faq/how-can-i-access-the-random-effects-after-xtmixed-using-_diparm/
	

		if ( e(k_r) >= 3 ) { 
		
			_diparm lns1_1_1, f(exp(@)^2) d(2*exp(@)^2)  
			if (r(se) >= 0.002 & r(se) !=.) {   //r(se) is Std. Err of the random effects parameter's variance 
				local covar_hh_slope  `covar_hh_slope' ${var_`m'} 
			}
			
		}
		
		if ( e(k_r) >= 4 ) {
		
			_diparm lns1_1_2, f(exp(@)^2) d(2*exp(@)^2)
			if (r(se) >= 0.002 & r(se) !=.) {
				local covar_hh_slope  `covar_hh_slope'  ${var_`n'} 
			}
		
		}
				
		if ( e(k_r) >= 5 ) {
			
			_diparm lns1_1_3, f(exp(@)^2) d(2*exp(@)^2)
			if (r(se) >= 0.002 & r(se) !=.) {
				local covar_hh_slope   `covar_hh_slope' ${var_`t'} 
			}
			
		}
		
		if ( e(k_r) >= 6 ) { 
		
			_diparm lns1_1_4, f(exp(@)^2) d(2*exp(@)^2)  
			if (r(se) >= 0.002 & r(se) !=.) {   //r(se) is Std. Err of the random effects parameter's variance 
				local covar_hh_slope  `covar_hh_slope'  ${var_`s'} 
			}
			
		}
		
	}


	
	disp "`covar_hh_slope'" 	
	global covar_hh_slope `covar_hh_slope' // 2022: drinking_water hh_boat hh_commerce hh_fan hh_iron hh_otherland hh_safe_flooding hh_stove imp_san_rec rural



	*count # of variables in covar_hh_slope
	local const = 1   //the place of constant = number of variables in covar_hh_slope + 1
	foreach i of global covar_hh_slope {
		local const = `const' + 1   
	}
	
	global const `const'


*===============================================================================	
*Step 3: run a full mixed model with random intercept and slope
*Weight is not used because of computation time; once it's used, it is difficult to converge

	
	mixed ln_con_pc `covar_community'  `covar_hh' $covar_inter || `comm_id': $covar_hh_slope , mle variance  
 
	outreg2 using  "$gdDatatemp_3EI/mixed.txt", dec(3) dta label replace

*===============================================================================	
*Step 4: Variance Analysis

*Expected mean of log consumption 
		predict yhat, xb
	
*Produce error terms that capture household-specific and community-specific shocks		

		predict eij, residuals 				//household shock
		predict u*, reffects  				//we're interested in the errors of the intercept u`const', community shock 
		gen eij_sq		=	eij^2  			//variance of consumption due to household shock 
		gen u`const'_sq	=	u`const'^2 		//variance of consumption due to community shock
		gen etotal	=	eij + u`const'  	//total shock
		gen etotal_sq	=	etotal^2 		//total variance of consumption


*Estimate the expected variance of consumption 
	regress eij_sq `covar_community' `covar_hh' `covar_inter' 
		predict eij_sq_hat, xb 
	sort `comm_id' 
	egen pickone = tag(`comm_id')
	regress u`const'_sq `covar_community' if pickone==1  
		predict u`const'_sq_hat, xb
		sum u${const}_sq_hat

	regress etotal_sq `covar_community' `covar_hh'   `covar_inter'  
		predict etotal_sq_hat, xb
		
*Prepare for robustness check  
*Assuming measurement error is 25%, 50%, and 75% of the estimated idiosyncratic and total variance

	foreach i of numlist 0 25 50 75 {
		gen eij_sq_`i' = eij_sq*(1-`i'*0.01)
		gen eij_`i' = sqrt(eij_sq_`i')
		gen etotal_sq_`i' = (eij_`i'+u`const')^2
		regress eij_sq_`i' `covar_community' `covar_hh' `covar_inter' 
		predict eij_sq_hat_`i', xb 
		
		regress etotal_sq_`i' `covar_community' `covar_hh'   `covar_inter' 
		predict etotal_sq_hat_`i', xb
	}


save "$gdData_3EI/est_vuln_${year}${n}", replace	

*===============================================================================	
*Step 5: Export multilevel model results; delete dataset of no use
	use "$gdDatatemp_3EI/mixed_dta.dta", clear
		export excel using "$gdExcel_3EI/VUL TOOL_${year}$n.xlsx" , sheet(mixed) sheetreplace first(variable) locale(C)

	erase "$gdDatatemp_3EI/mixed_dta.dta"
	erase "$gdDatatemp_3EI/mixed.txt"	


}	

else if (`newmodel' == 0)  {

	global const `oldconst'
}
*===============================================================================
* 		Vulnerability Analysis
*===============================================================================	
	
use "$gdData_3EI/est_vuln_${year}${n}", clear	


local varlist poor ln_pl prob_eij* prob_uj* prob_etotal* vulnerable_eij* vulnerable_uj* vulnerable_etotal* risk_induced poverty_induced poverty_cat risk_vul

	foreach i in `varlist' {
		cap drop `i'
	}

	gen ln_pl =	ln(`pline') 
	gen poor = (`con_pc' < `pline')  // dummy variable indicating whether the HH is poor 
	tab poor [aw=hhsize*hhweight]

	gen poor_hat=(yhat<ln_pl) if yhat!=.

*The probability of a household i in community j to fall below a poverty line


	gen prob_eij	= normal((ln_pl - yhat) / (eij_sq_hat)^0.5) 
	gen prob_uj		= normal((ln_pl - yhat) / (u${const}_sq_hat)^0.5) 
	gen prob_etotal	= normal((ln_pl - yhat) / (etotal_sq_hat)^0.5)  
	
*The mean of vulnerability, should be approximate to the poverty rate
	sum prob_etotal	
	
	dis "`vul_th'"

	*Compare the probability of falling below the poverty line with the vulnerability threshold to calculate vulnerablity rate
	recode prob_eij (`vul_th'/1=1) (0/ `vul_th' = 0), gen(vulnerable_eij)  //Source of vulnerability: Idiosyncratic
	recode prob_uj (`vul_th'/1=1) (0/ `vul_th'= 0), gen(vulnerable_uj)  //Source of vulnerability: covariate
	recode prob_etotal (`vul_th'/1=1) (0/ `vul_th'= 0), gen(vulnerable_etotal)  //total vulnerability rate

*robustness check: vulnerability  
foreach i of numlist 0 25 50 75 {
	gen prob_eij_`i'	= normal((ln_pl - yhat) / (eij_sq_hat_`i')^0.5) 
	gen prob_etotal_`i'	= normal((ln_pl - yhat) / (etotal_sq_hat_`i')^0.5)  
	
	*Compare the probability of falling below the poverty line with the vulnerability threshold to calculate vulnerablity rate
	recode prob_eij_`i' (`vul_th'/1=1) (0/ `vul_th' = 0), gen(vulnerable_eij_`i')  //Source of vulnerability: Idiosyncratic
	recode prob_etotal_`i' (`vul_th'/1=1) (0/ `vul_th'= 0), gen(vulnerable_etotal_`i')  //total vulnerability rate
}
*===============================================================================
* Decompose vulnerability to risk induced and poverty induced vulnerability
*===============================================================================	

	gen risk_induced	=	(yhat >= ln_pl & vulnerable_etotal == 1)  if yhat != .
	gen poverty_induced	= (yhat < ln_pl) if yhat != .
	
	gen risk_vul = (yhat >= ln_pl & vulnerable_etotal == 1) if yhat != . //rsik vulnerable people: those with mean consumption above poverty but still vulnerable to poverty

	gen poverty_cat=1 if poor==1 & vulnerable_etotal==1 // poor and vulnerable
	replace poverty_cat=2 if poor==0 & vulnerable_etotal==1 // non poor and vulnerable
	replace poverty_cat=3 if poor==0 & vulnerable_etotal==0 // non poor, non vulnerable
	replace poverty_cat=4 if poor==1 & vulnerable_etotal==0 // poor and non vulnerable

	lab def povcat  1 "Poor and vulnerable" 2 "Non poor and vulnerable" 3 "Non poor and non vulnerable" 4 "Poor and non vulnerable"
	lab val poverty_cat povcat 

	tab poverty_cat [aw=hhweight*hhsize]
	bys milieu: tab poverty_cat [aw=hhweight*hhsize]
	tab poverty_cat, gen(pov_cat)

	tab poor if head_edu==3

foreach i of local subcategory {	
	
	capture confirm numeric variable `i'  //check whether group(subcategory) is numeric or string; if it is numeric, change to string
    if !_rc {
         tostring `i', replace  force
                }

	else {
	}
}	


save "$gdData_3EI/est_vuln_${year}${n}", replace


 


