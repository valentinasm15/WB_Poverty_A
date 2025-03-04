*===============================================================================
* Project:       	Labor diversification
* Author:        	Valentina
* Creation Date:    Feb 2025  
*===============================================================================
	local survey_hh 	"2.- BASE DE DATOS DE VIVIENDA REFORMAS Y RECURSOS.dta"


*===============================================================================
	* Salary-related Income - Monthly income from wages main job
*===============================================================================	

use "${gdData_7L}/7Labor_base1-0.dta", clear // created in cleaning_7.do

	keep if q1_03_edad>=16 & q1_03_edad<=64 // edad trabajar
	keep if PO==1 //ocupados

foreach var in q10_01_salarioPrincipal q10_03_boniPrincipal q10_05_beneficios q10_08_salarioSecundaria q10_10_boniSecundaria q10_12_beneficios {
    replace `var' = 0 if missing(`var')
}


    						* Main job
*===============================================================================

** Monthly Income - main job   

	foreach var in salarioPrincipal boniPrincipal beneficios {
		local code = "q10_01_"
		if "`var'" == "boniPrincipal" local code = "q10_03_"
		if "`var'" == "beneficios" local code = "q10_05_"

		gen `var'_m = `code'`var'
		replace `var'_m = `var'_m * 4 if `code'frecuencia == "Semanal" 
		replace `var'_m = `var'_m * 1 if `code'frecuencia == "Mensual"
		replace `var'_m = `var'_m / 3 if `code'frecuencia == "Trimestral" 
		replace `var'_m = `var'_m / 6 if `code'frecuencia == "Semestral"
	}


	rename beneficios_m beneficios_m_mj
	egen wage_mj_m=rowtotal(salarioPrincipal_m boniPrincipal_m beneficios_m_mj) , missing
	replace wage_mj_m = 0 if wage_mj_m==.

	lab var wage_mj_m "Wage of main job (monthly)" 	
	sum wage_mj_m


    						* Secondary job
*===============================================================================

**  Monthly Income - secondary job  

	foreach var in salarioSecundaria boniSecundaria beneficios {
		local code = "q10_08_"
		if "`var'" == "boniSecundaria" local code = "q10_10_"
		if "`var'" == "beneficios" local code = "q10_12_"

		gen `var'_m = `code'`var'
		replace `var'_m = `var'_m * 4 if `code'frecuencia == "Semanal"  // Weekly wage
		replace `var'_m = `var'_m * 1 if `code'frecuencia == "Mensual" // Monthly wage
		replace `var'_m = `var'_m / 3  if `code'frecuencia == "Trimestral"  // Quarterly wage
		replace `var'_m = `var'_m / 6  if `code'frecuencia == "Semestral" // Semi-annual wage
	}


	rename beneficios_m beneficios_m_sj
	egen wage_sj_m=rowtotal(salarioSecundaria_m boniSecundaria_m beneficios_m_sj ), missing
	replace wage_sj_m = 0 if wage_sj_m==.
	lab var wage_sj_m "Wage of secondary job (monthly)" 


** Total income in main and secondary job monthly 
	egen wage_m = 	rowtotal( wage_mj_m  wage_sj_m) , missing
	
	gen wagemj_m_ppp = wage_mj_m/(ppp/12)

	foreach var in wage_m wage_sj_m wage_mj_m {
		replace `var' = 0 if missing(`var')
	}

	save "${gdData_7L}/7Labor_wage1-1.dta", replace 
	

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
	gen agri_income = (q11_13_ventaTotal - q11_30_gastos)/12

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
	gen livestock_income = (q11_21_valorVenta - q11_31_gastos)/12

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
	gen deriva_income = (q11_28_valorVenta - q11_31_gastos)/12

	save `deriva_income'
restore

**** Negocios - No agro 


	use "${gdData}/Household surveys/ENH2/25.- BASE DE DATOS DE LAS ACTIVIDADES NO AGRO Y NEGOCIOS.dta", clear 
	drop region

	gen sector_biz_noagro = 1 if r_actividades_no_agro__id==1 | r_actividades_no_agro__id==2
	replace sector_biz_noagro = 2 if r_actividades_no_agro__id==3 // Manufacture
	replace sector_biz_noagro = 3 if r_actividades_no_agro__id==4 // Commerce
	replace sector_biz_noagro = 4 if r_actividades_no_agro__id==5 // Services 

	label define sector_biz_noagro_en 1 "Agro?" 2 "Manufacture" 3 "Commerce" 4 "Services"
	label define sector_biz_noagro_sp 1 "Agro?" 2 "Manufactura" 3 "Comercio" 4 "Servicios"
	label values sector_biz_noagro sector_biz_noagro_en

	bysort interview__key  (interview__key ): gen dup_count = _N

	keep if dup_count > 1
	drop dup_count
	bysort interview__key (q12_03_responsable): gen resp_count = sum(q12_03_responsable != q12_03_responsable[_n-1])

	bysort interview__key (q12_03_responsable): keep if resp_count[_N] > 1
	drop resp_count

/* br interview__key r_actividades_no_agro__id q12_03_responsable q12_08_gananciaMensual q12_01_tipoNegocio */

** Sum income from all non-agro businesses
	preserve
		gen biz_income_m = q12_04_ventaMensual - q12_06_costoMensual						
		gen biz_income_y = biz_income_m*q12_09_mesesRecibio 									// Annual profit
		collapse (sum) biz_income*, by(interview__key q12_03_responsable)

		tempfile biz_income
		save `biz_income'
	restore

** Identifying main business by individual as the one with the highest monthly income and the highest number of months
	
	bysort interview__key q12_03_responsable (q12_08_gananciaMensual q12_09_mesesRecibio): gen main_biz = (q12_08_gananciaMensual == q12_08_gananciaMensual[_N]) & (q12_09_mesesRecibio == q12_09_mesesRecibio[_N])

** Dropping other business by individual to simplify

	drop if main_biz==0

	bysort interview__key q12_03_responsable (q12_01_tipoNegocio): drop if strtrim(q12_01_tipoNegocio) == ""
	bysort interview__key q12_03_responsable q12_08_gananciaMensual (interview__key): drop if _n > 1

** Merge with the income from non-agro businesses

	merge 1:1 interview__key q12_03_responsable using `biz_income', keep(matched)  force
	rename q12_03_responsable codigoMiembro2
	duplicates tag interview__key codigoMiembro2, generate(dup_key2)
	gen dup_flag2 = dup_key2 > 0
	tab dup_flag2


		tempfile biz_income_m
		save `biz_income_m'
		

	use "${gdData_7L}/7Labor_wage1-1.dta", clear

	/* use "${gdData_7L}/7Labor_wage1-1.dta", clear */

	merge m:1 interview__key using `agri_income', nogen 
	merge m:1 interview__key using `livestock_income', nogen 
	merge m:1 interview__key using `deriva_income', nogen
	merge m:1 interview__key codigoMiembro2 using `biz_income_m',nogen 

	drop if codigoMiembro2 & codigoMiembro3 ==.

	foreach var in agri_income livestock_income deriva_income biz_income_m  {
		replace `var' = 0 if missing(`var')
	}

** Sum of non-salary income
	egen nonsalary_m = rowtotal(agri_income livestock_income deriva_income biz_income_m)
	replace nonsalary_m=0 if nonsalary_m==.


*===============================================================================
									* Total income 
*===============================================================================

	/* gen is_worker2=1 if q5_05_trabajo1hora=="Sí" | q5_01_trabajo1horaCampo=="Sí" | q5_02_trabajo1horaHogar=="Sí" |q5_03_trabajo1horaJefe=="Sí" | q5_04_trabajo1horaAprendiz=="Sí" | q5_18_ocupacionPrincipal!="" | q5_41_ocupacionSecundaria!=.
	bys interview__key: egen nworker=total(is_worker2) */


	* Sum of Total Income - FCFA and USD 2017 ppp
	gen total_income_m = wage_m + nonsalary_m

	* Sum of Total Income - FCFA and USD 2017 ppp withouth petrol income
	/* gen total_income_m_nopetro = wage_m + nonsalary_m */


*===============================================================================
							* Shares by type of income 
*===============================================================================
	gen nonsalary_share = .
	replace nonsalary_share = (nonsalary_m / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, nonsalary_m)

** Share of income for wage
	gen wage_share = .
	replace wage_share = (wage_m / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, wage_m)

	** Share of income by sector for business income  // ******* Should I compute wage for main job or total wage income? 
	gen agro_inc_w = wage_m if sector==1
	gen agri_share_w = (agro_inc_w / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, agro_inc_w)

	gen manu_inc_w = wage_m if sector==2
	gen manu_share_w = (manu_inc_w / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, manu_inc_w)
	
	gen serv1_inc_w = wage_m if sector==3
	gen serv1_share_w = (serv1_inc_w / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, serv1_inc_w)

	gen serv2_inc_w = wage_m if sector==4
	gen serv2_share_w = (serv2_inc_w / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, serv2_inc_w)

	** Count number of workers by sector
	bysort sector: gen worker_count = _N


** Share of income for business 
	gen biz_share = .
	replace biz_share = (biz_income_m / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, biz_income_m)

	** Share of income by sector for business income 
	gen agro_inc_b = agri_income 
	replace agro_inc_b= agri_income + biz_income_m if sector_biz_noagro==1
	gen agri_share_b = (agro_inc_b / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, agro_inc_b)

	gen manu_inc_b = biz_income_m if sector_biz_noagro==2
	gen manu_share_b = (manu_inc_b / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, manu_inc_b)
	
	gen serv1_inc_b = biz_income_m if sector_biz_noagro==3
	gen serv1_share_b = (serv1_inc_b / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, serv1_inc_b)

	gen serv2_inc_b = biz_income_m if sector_biz_noagro==4
	gen serv2_share_b = (serv2_inc_b / total_income_m) * 100 if total_income_m > 0 & !missing(total_income_m, serv2_inc_b)

	** Count number of workers by sector
	bysort sector_biz_noagro: gen worker_count_b = _N
	

* labor income de persona 
* ingreso de negocios de persona 
* proporción de trabajadores 10 columnas



