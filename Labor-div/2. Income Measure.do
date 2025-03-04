*===============================================================================
* Project:       	Labor diversification
* Author:        	Valentina
* Creation Date:    Jan 2025  
*===============================================================================

	                        * Labor diversification
*===============================================================================
	
	* Locals	
	local survey_hh 	"2.- BASE DE DATOS DE VIVIENDA REFORMAS Y RECURSOS.dta"
    local survey_ind 	"Auxiliary/Nov_11_2024/inege_nov.dta"	 	
	local survey_ind_old "1.- BASE DE DATOS DE MIEMBROS PROFESIONALES Y HORAS TRABAJADAS.dta"	 
	local id_vars 		"cod_region cod_provincia cod_distrito cod_MU_DU interview__key"


*===============================================================================
	* Salary-related Income - Annualizing income from wages main job
*===============================================================================	


    						* Main job
*===============================================================================

use "${gdData_7L}/7Labor_base1-0.dta", clear 

	/* keep if q1_03_edad>=16 & q1_03_edad<=64 // edad trabajar
	keep if PO==1 //ocupados */

foreach var in q10_01_salarioPrincipal q10_03_boniPrincipal q10_05_beneficios q10_08_salarioSecundaria q10_10_boniSecundaria q10_12_beneficios {
    replace `var' = 0 if missing(`var')
}

** Annualizing income related main job  

	foreach var in salarioPrincipal boniPrincipal beneficios {
		local code = "q10_01_"
		if "`var'" == "boniPrincipal" local code = "q10_03_"
		if "`var'" == "beneficios" local code = "q10_05_"

		gen `var' = `code'`var'
		replace `var' = `var' * 52 if `code'frecuencia == "Semanal" 
		replace `var' = `var' * 12 if `code'frecuencia == "Mensual"
		replace `var' = `var' * 4  if `code'frecuencia == "Trimestral" 
		replace `var' = `var' * 2  if `code'frecuencia == "Semestral"
	}

** Income classification in salaried y non-salaried for secondary job

	rename beneficios beneficios_mj
	egen wage_mj=rowtotal(salarioPrincipal boniPrincipal beneficios_mj) , missing
	replace wage_mj = 0 if wage_mj==.

	lab var wage_mj "Wage of main job" 	
	sum wage_mj

	g wage_mj_h = wage_mj/(totalHorasPrincipal*52)   // Divided by hours a week 


    						* Secondary job
*===============================================================================

** Annualizing income related secondary job  

	foreach var in salarioSecundaria boniSecundaria beneficios {
		local code = "q10_08_"
		if "`var'" == "boniSecundaria" local code = "q10_10_"
		if "`var'" == "beneficios" local code = "q10_12_"

		gen `var' = `code'`var'
		replace `var' = `var' * 52 if `code'frecuencia == "Semanal"  // Weekly wage
		replace `var' = `var' * 12 if `code'frecuencia == "Mensual" // Monthly wage
		replace `var' = `var' * 4  if `code'frecuencia == "Trimestral"  // Quarterly wage
		replace `var' = `var' * 2  if `code'frecuencia == "Semestral" // Semi-annual wage
	}


** Income classification in salaried y non-salaried for secondary job
	rename beneficios beneficios_sj
	egen wage_sj=rowtotal(salarioSecundaria boniSecundaria beneficios_sj ), missing
	replace wage_sj = 0 if wage_sj==.
	lab var wage_sj "Wage of secondary job" 

	gen wage_sj_h = wage_sj/(totalHorasSecundaria*52)   // Divided by hours a week
	replace wage_sj_h = 0 if wage_sj_h==.


** Suma de total horas trabajadas la semana pasada en actividades principales y secundarias 
	egen wage_y = 	rowtotal( wage_mj  wage_sj) , missing
	egen wage_h	= 	rowtotal( wage_mj_h  wage_sj_h) , missing
	
	gen wagemj_y_ppp = wage_mj/ppp
	gen wage_y_ppp= wage_y/ppp
	gen wage_h_ppp= wage_h/ppp 

	foreach var in wage_y wage_h wage_sj wage_mj {
		replace `var' = 0 if missing(`var')
	}

	/* save "${gdData_7L}/7Labor_wage1-1.dta", replace //  used in 2-3.regressions_and_stats.do */

*===============================================================================
								* Non-salary income 
*===============================================================================	
* Agro
preserve
	tempfile agri_gasto agri_income

	use "${gdData}/Household surveys/ENH2/20.- BASE DE DATOS DE CULTIVOS.dta", clear
	collapse (sum) q11_13_ventaTotal, by(interview__key)
	save `agri_gasto'

	use "${gdData}/Household surveys/ENH2/23.- BASE DE DATOS DE GASTOS 1.dta", clear								// Annual
	collapse (sum) q11_30_gastos, by(interview__key)

	merge 1:1 interview__key using `agri_gasto'
	gen agri_income = q11_13_ventaTotal - q11_30_gastos

	save `agri_income'
restore

* Pecuario
preserve
	tempfile livestock_gasto livestock_income

	use "${gdData}/Household surveys/ENH2/24.- BASE DE DATOS DE GASTOS PECUARIOS.dta", clear
	drop if r_gastos_pecuaria__id ==6
	collapse (sum) q11_31_gastos, by(interview__key)

	save `livestock_gasto'

	use "${gdData}/Household surveys/ENH2/21.- BASE DE DATOS DE ANIMALES.dta", clear 								// Last 12 months
	collapse (sum) q11_21_valorVenta, by(interview__key)

	merge 1:1 interview__key using `livestock_gasto'
	gen livestock_income = q11_21_valorVenta - q11_31_gastos

	save `livestock_income'
restore

* Derivados
preserve
	tempfile deriva_gasto deriva_income

	use "${gdData}/Household surveys/ENH2/24.- BASE DE DATOS DE GASTOS PECUARIOS.dta", clear
	keep if r_gastos_pecuaria__id ==6
	collapse (sum) q11_31_gastos, by(interview__key)

	save `deriva_gasto'

	use "${gdData}/Household surveys/ENH2/22.- BASE DE DATOS DE DERIVADOS.dta", clear 							// Annual production
	collapse (sum) q11_28_valorVenta, by(interview__key)

	merge 1:1 interview__key using `deriva_gasto'
	gen deriva_income = q11_28_valorVenta - q11_31_gastos

	save `deriva_income'
restore

* Negocios - No agro 
preserve
	use "${gdData}/Household surveys/ENH2/25.- BASE DE DATOS DE LAS ACTIVIDADES NO AGRO Y NEGOCIOS.dta", clear 	// Actividad independiente no agro - no data by hour 

	gen ganancia_m = q12_04_ventaMensual - q12_06_costoMensual
	gen noagro_business_income = ganancia_m*q12_09_mesesRecibio 									// Annual profit
	collapse (sum) noagro_business_income, by(interview__key)

	tempfile noagro_business_income
	save `noagro_business_income'

restore

	/* use "${gdData_7L}/7Labor_wage1-1.dta", clear */

	merge m:1 interview__key using `agri_income', nogen 
	merge m:1 interview__key using `livestock_income', nogen 
	merge m:1 interview__key using `deriva_income', nogen
	merge m:1 interview__key using `noagro_business_income',nogen 

	drop if codigoMiembro2 & codigoMiembro3 ==.

	foreach var in agri_income livestock_income deriva_income noagro_business_income  {
		replace `var' = 0 if missing(`var')
	}

** Sum of non-salary income
	egen nonsalary_y = rowtotal(agri_income livestock_income deriva_income noagro_business_income)
	replace nonsalary_y=0 if nonsalary_y==.

	gen nonsalary_w=1 if agri_income>0 | livestock_income>0 | deriva_income>0 | noagro_business_income>0
	replace nonsalary_w=0 if nonsalary_w==.

*===============================================================================
									* Salary Income
*===============================================================================	

** Salaried / Nonsalaried workers

	gen salary_w = 1 if inlist(q5_18_ocupacionPrincipal_, 1,2,3,4,5,7,8) // Empleado público y privado// Empresario, miembro de cooperativa, independiente, servicio domes, destajista
	replace salary_w = 0 if inlist(q5_18_ocupacionPrincipal_, 6,9)  	// trabajador familiar, otro
	lab val salary_w salary_w


** Employment status

	gen empstat_=1 if inlist(q5_18_ocupacionPrincipal_, 1,2,4,7,8) 	// Empleado público y privado , miembro de cooperativa, servicio domes, destajista
	replace empstat_=2 if inlist(q5_18_ocupacionPrincipal_, 3,5) 	// Empresario (Propietario) e Independiente/Autónomo // 
	replace empstat_=3 if inlist(q5_18_ocupacionPrincipal_, 6,9) 	// trabajador familiar, otro
	tab empstat_,gen(empstat_)

	lab var empstat_1 "Salaried workers"
	lab var empstat_2 "Self-employee/own boss"
	lab var empstat_3 "Other workers"

tab salary_w nonsalary_w, missing

*===============================================================================
									* Total income 
*===============================================================================


gen is_worker2=1 if q5_05_trabajo1hora=="Sí" | q5_01_trabajo1horaCampo=="Sí" | q5_02_trabajo1horaHogar=="Sí" |q5_03_trabajo1horaJefe=="Sí" | q5_04_trabajo1horaAprendiz=="Sí" | q5_18_ocupacionPrincipal!="" | q5_41_ocupacionSecundaria!=.
bys interview__key: egen nworker=total(is_worker2)


* Sum of Total Income - FCFA and USD 2017 ppp
gen total_income_y = wage_y + nonsalary_y
gen total_income_y_ppp = total_income_y/ppp

gen total_income_h = total_income_y / $total_hr	// Total hours
gen total_income_h_ppp= total_income_y_ppp / $total_hr

* Productivity - Yearly and hourly
gen produc_y = wage_y + (nonsalary_y / nworker) //(wage_y_ij + (nonsalary_y_j/nworker_j)) 
gen produc_y_ppp = produc_y / ppp

gen produc_h = produc_y / $total_hr
gen produc_h_ppp = produc_y_ppp / $total_hr
sum produc_y_ppp

gen min_wage_y_ppp = 117304 / ppp // Minimum wage in 2022
gen min_wage_h_ppp = min_wage_y_ppp / 173.2 // 40horas/semana×4,33semanas/mes=173,2horas/mes.

global min_wage_y_ppp = ln(min_wage_y_ppp) // Minimum wage in 2022
global min_wage_h_ppp = ln(min_wage_h_ppp) // Minimum wage in 2022
/* gen min_wage_ppp=ln(117304 / ppp) // Minimum wage in 2022 */

cap drop _m


*===============================================================================
	* 		Regression analysis and graphs 
*===============================================================================
cap drop _merge


merge m:1 interview__key using "${gdData}/Household surveys/ENH2/Welfare-measurement/GNQ_enh2_welfare.dta", keep(matched) keepusing(interview__key weight_hh)

foreach var in total_income_y_ppp total_income_h_ppp produc_y_ppp produc_h_ppp wage_y_ppp wage_h_ppp {
	drop if `var'<0
	gen ad_`var' = `var'
	sum `var', d
	replace ad_`var' = . if `var'<r(p1)
	replace ad_`var' = . if `var'>r(p99)
	sum ad_`var', d
	loc mino=r(min)

	gen ad_`var'_2= ad_`var'-`mino'+1
	gen log_`var'=ln(ad_`var'_2)
	replace log_`var' = . if log_`var'==0
}
	gen lnwage_h=ln(wage_h+1)


	save "${gdData_7L}/7Labor_est1-1.dta", replace


/* 
	global ind total_hr female age agesq educy sector_* empstat_* 
	global hh  cod_provincia 
	global ind_hh_vars $ind $hh 

	sum $ind_hh_vars
	sum lnLx weight_hh nworker

	//  a. regression
	eststo Mincer : regress lnLx $Xs [pw=weight_hh*nworker]	
	ereturn list
	*putexcel V28 = `e(r2)'
	predict res if e(sample) , res
	gen eresid = exp(res) 
	sum eresid [aw=weight_hh*nworker]
	local duan = r(mean) */



/*
	//  c. estimation table
	//esttab Mincer using "$temp\Mincer_${iso3}.tex", ar2 b(3) se(3) replace /*label*/ order ($Xs) keep($Xs) nobaselevels longtable booktabs star(* 0.10 ** 0.05 *** 0.01) title("Mincer equation for labor incomes per employed in $iso3")
			
	//  d. estimation plot
	qui coefplot Mincer, keep(`id_vars' hours female age agesq educy sector_1 sector_2 sector_3 empstat_1 empstat_2 empstat_3 empstat_4) xline(0) title("Mincer regression results") byopts(xrescale) graphregion(col(white)) bgcol(white) eqlabels("labor incomes based", asequations)
*/

*===============================================================================
	* 		Regression analysis and graphs 
*===============================================================================

/*
---- 1. Predict individual labor income ----------------------------------  
	//  a. indvidual data
	use "${results}/total_income_pre.dta", clear

	//  b. impute missing values of Xs
	sum $Xind

	//  d. predict individual level labor income
	estimates restore Mincer
	predict double li    		// predict individual labor self-income for each individual based on their 
								//characteristics and the coefficients from the average worker regression
	replace li = exp(li)*`duan' // Duan's smearing estimator, see https://people.stat.sc.edu/hoyen/STAT704/Notes/Smearing.pdf

	g ln_li = ln(li+wage_h) // for the graphs only
	replace li = li + `mino'-1 // Restore the scale
	sum $Xind li

*/











