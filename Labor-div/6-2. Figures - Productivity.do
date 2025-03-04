*===============================================================================
* Project:       	Labor diversification
* Author:        	Valentina
* Creation Date:     Jan 2025  
*===============================================================================


   set scheme sj
    grstyle init
    grstyle set plain, horizontal grid
    grstyle set legend 6, nobox klength(small) 

*===============================================================================
	                     * Data
*===============================================================================	

       use "${gdData_7L}/7Labor_est1-1.dta", clear


*===============================================================================
	                     * Locals - Parameters
*===============================================================================	

** Define language to produce the graphs

       global language = "english" // english / spanish

       global publ_emplo = "yes"

       ** Locals to customize graphs 

       ** Uncomment the variable desired
       /* local income_var "log_total_income_y_ppp"     // Log yearly total income PPP */
       /* local income_var "log_total_income_h_ppp"     // Log hourly total income PPP */
       /* local income_var "log_produc_y_ppp"           // Log yearly Productivity PPP */
       local income_var "log_produc_h_ppp"              // Log hourly Productivity PPP

       local bw = 0.1

       if "$language" == "spanish" {
       
              if "`income_var'" == "log_produc_y_ppp" {
              local title "Productividad anual por"
              local xtitle "Ingreso total anual (PPA, USD-2017) sobre total de trabajadores en el hogar"
              local min_wage_ppp = ln(min_wage_y_ppp) 
              }
              else if "`income_var'" == "log_total_income_y_ppp" {
              local title "Ingreso total anual por"        
              local xtitle "Ingreso total anual, PPA (USD-2017)"
              local min_wage_ppp = ln(min_wage_y_ppp) 

              }
              else if "`income_var'" == "log_produc_h_ppp" {
              local title "Productividad por hora por"
              local xtitle "Ingreso total por hora (PPA, USD-2017) sobre total de trabajadores en el hogar"
              local min_wage_ppp = ln(min_wage_h_ppp) 
              }
              else if "`income_var'" == "log_total_income_h_ppp" {
              local title "Ingreso total por hora por"        
              local xtitle "Ingreso total por hora, PPA (USD-2017)"
              local min_wage_ppp = ln(min_wage_h_ppp) 
              }

              local subject1 " tipo de actividad laboral"
              local subject2 " sector de ocupación"
              local subject3 " nivel educativo"
              local subject4 " tamaño de empresa"
              local subject5 " étnia"
              local subject6 " región"
              local subject7 " sexo"
       } 
       else if "$language" == "english" {
   
              if "`income_var'" == "log_produc_y_ppp" {
              local title "Annual productivity by"
              local xtitle "Yearly total income (PPP, USD-2017) over total household workers"
              local min_wage_ppp = ln(min_wage_y_ppp) 
              }
              else if "`income_var'" == "log_total_income_y_ppp" {
              local title "Yearly total income by"        
              local xtitle "Annual total income, PPP (USD-2017)"
              local min_wage_ppp = ln(min_wage_y_ppp) 

              }
              else if "`income_var'" == "log_produc_h_ppp" {
              local title "Hourly productivity by"
              local xtitle "Hourly total income (PPP, USD-2017) over total household workers"
              local min_wage_ppp = ln(min_wage_h_ppp) // Minimum wage in 2022
              }
              else if "`income_var'" == "log_total_income_h_ppp" {
              local title "Hourly total income by"        
              local xtitle "Hourly total income, PPP (USD-2017)"
              local min_wage_ppp = ln(min_wage_h_ppp) // Minimum wage in 2022
              }

              local subject1 " type of working activity"
              local subject2 " employment sector"
              local subject3 " education level"
              local subject4 " company size"
              local subject5 " ethnicity"
              local subject6 " region"
              local subject7 " sex"
              local subject8 " skills level"

       }

       local blueD   "64 137 201"      //rgb(64, 137, 201)
       local blue    "75 188 223"      //rgb(75, 188, 223)
       local green   "94 183 91"       //rgb(94, 183, 91)
       local grey    "166 166 166"     //  #A6A6A6
       local orange  "253 167 3"       //rgb(253, 167, 3)
       local red     "221 91 97"       //rgb(221, 91, 97)
       local purple  "130 130 212"     //  #8282D4
       local yellow  "255 212 0"       //rgb(255, 212, 0)
       /* local "0 113 192"            //rgb(0, 113, 192)  */ */

	label define grado_es 0 "General" 1 "Ninguno" 2 "Primaria" 3 "Secundaria" 4 "Formación Técnica" 5 "Universitaria/Posgrado"
	label define grado_en 0 "General" 1 "None" 2 "Primary" 3 "High School" 4 "Technical Training" 5 "Undergraduate/Postgraduate"
	
	label define sector_lbl_es 1 "Agricultura" 2 "Industria" 3 " Servicios Transables" 4 "Servicios No Transables"
	label define sector_lbl_en 1 "Agriculture" 2 "Industry" 3 "Tradable Services" 4 "Non-Tradable Services"
	
	label define firm_es 0 "General" 1 "Cuenta Propia" 2 "Firma 2-10 empleados" 3 "Firma 11-50 empleados" 4 "Firma 50+ empleados"
	label define firm_en 0 "General" 1 "Self-employed" 2 "Firm 2-10 employees" 3 "Firm 11-50 employees" 4 "Firm 50+ employees"
	
	label define sector2_es 1 "Agricultura" 2 "Manufactura" 3 "Serv. transables" 4 "Serv. bajas habilidades" 5 "Serv. altas habilidades"
	label define sector2_en 1 "Agriculture" 2 "Manufacture" 3 "Trade services" 4 "Low-skilled serv." 5 "High-skilled serv."
	
	label define employee_es 0 "General" 1 "Empleado público" 2 "Empleado privado" 3 "Cuenta Propia"
	label define employee_en 0 "General" 1 "Public employee" 2 "Private employee" 3 "Self-employed"
	
	label define quintil_es 1 "Más pobre (quintil=1)" 2 "Quintil 2" 3 "Quintil 3" 4 "Quintil 4" 5 "Más rico (quintil=5)"
	label define quintil_en 1 "Poorest (quintile=1)" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Richest (quintile=5)"



*===============================================================================
*                                  Density Graphs
*===============================================================================

******************************************************************************* 
*                           Working activity 
******************************************************************************* 
** Working activity

       if "$language" == "spanish" {
              local legend "1 "Trabajadores asalariados" 2 "Empresarios/Independientes" 3 "Otros trabajadores""
       } 
         else if "$language" == "english" {
              local legend "1 "Salaried workers" 2 "Self-employed/Own boss" 3 "Other workers""
       }


       twoway 	kdensity `income_var' 	if empstat_1 == 1, bwidth(`bw') lpattern(solid) lcolor("`red'") lwidth(medthick)  ///
              || 	kdensity `income_var'       if empstat_2 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("`blue'") lwidth(medthick) ///
              || 	kdensity `income_var' 	if empstat_3 == 1, bwidth(`bw') lpattern(dash) lcolor("`green'") lwidth(medthick) ///
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("`grey'") lwidth(medthick) ///  // Fake line for xline
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject1'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend)  ///
              legend(order(`legend')  nobox size(*0.9) region(lstyle(none)))

       graph export "${gdFig_7L}/$language/`title'`subject1'.png", as(png) name("Graph") replace

******************************************************************************* 
*                             Employment sector  
******************************************************************************* 

****   General employment sector for private employees

       gen public_employee = 1 if q5_18_ocupacionPrincipal== "Empleado público"

       preserve

       if "$language" == "spanish" {
              local legend "1 "Agricultura" 2 "Industria" 3 "Servicios Transables" 4 "Servicios No Transables" 5 "Salario mínimo (PPP, USD-2017)""  
       } 
         else if "$language" == "english" {
              local legend "1 "Agriculture" 2 "Industry" 3 "Tradable Services" 4 "Non-Tradable Services" 5 "Minimum Wage (PPP, USD-2017)""

       }
       
       
       replace sector1=. if public_employee == 1
       replace sector2=. if public_employee == 1
       replace sector3=. if public_employee == 1
       replace sector4=. if public_employee == 1

       twoway 	kdensity `income_var' 	if sector1 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("`red'") lwidth(medthick)  /// "85 182 72"
              || 	kdensity `income_var' 	if sector2 == 1, bwidth(`bw') lpattern(solid) lcolor("`blue'") lwidth(medthick) ///
              || 	kdensity `income_var'       if sector3 == 1, bwidth(`bw') lpattern(dash) lcolor("`green'") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector4 == 1, bwidth(`bw') lpattern(solid) lcolor("`orange'") lwidth(medthick) ///
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("`grey'") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none))) ///
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject2'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("`grey'") noextend) 

       graph export "${gdFig_7L}/$language/`title'`subject2'_tr.png", as(png) name("Graph") replace
       restore 

****   General employment sectors private vs public employees


       if "$language" == "spanish" {
              local sector1 "Agricultura"
              local sector2 "Industria"
              local sector3 "Servicios Transables"
              local sector4 "Servicios_No_Transables"       
       } 
         else if "$language" == "english" {
              local sector1 "Agriculture"
              local sector2 "Industry"
              local sector3 "Tradable_Services"
              local sector4 "Non_tradable_Services"
         }

       foreach sector in 1 2 3 4 {

       gen pe_sector`sector' = sector`sector' if public_employee == 1
       replace sector`sector' = 0 if public_employee == 1

       local sector_name = "`sector`sector''"

       graph twoway (kdensity `income_var' if sector`sector' == 1, bwidth(`bw') lpattern(solid) lcolor("`blue'") lwidth(medium)) ///
                     (kdensity `income_var' if pe_sector`sector' == 1, bwidth(`bw') lpattern(solid) lcolor("`green'") lwidth(medium)), ///
              title("`sector_name'") ///
              legend(order(1 "Private employees" 2 "Public employees")) ///
              ytitle("Density", size(medsmall)) ///
              xtitle("Hourly productivity (PPP, USD-2017)", size(medsmall)) ///
              name("`sector_name'", replace)
       
       drop pe_sector`sector'
       }

       graph combine `sector1' `sector2' `sector3' `sector4', ///
       title("`title'`subject2'", size(medsmall)) ///

       

****   New sectors of economy

       if "$language" == "spanish" {
              local legend "1 "Economía Azul" 2 "Economía Verde" 3 "Economía Amarrilla" 4 "Economía digital" 5 "Turismo" 6 "Salario mínimo (PPP, USD-2017)""
       } 
         else if "$language" == "english" {
              local legend "1 "Blue Economy" 2 "Green Economy" 3 "Yellow Economy" 4 "Digital Economy" 5 "Tourism" 6 "Minimum Wage (PPP, USD-2017)""
       }

       twoway  	kdensity `income_var'       if sector_n1 == 1, bwidth(`bw') ///
                     lpattern(solid) lcolor("`blue'") lwidth(medthick)           ///
              || 	kdensity `income_var'       if sector_n2 == 1, bwidth(`bw') ///
                     lpattern(shortdash dot) lcolor("`green'") lwidth(medthick)  ///
              || 	kdensity `income_var' 	if sector_n3 == 1, bwidth(`bw') ///
                     lpattern(dash) lcolor("`yellow'") lwidth(medthick)          ///
              || 	kdensity `income_var' 	if sector_n4 == 1, bwidth(`bw') ///
                     lpattern(longdash dot) lcolor("`red'") lwidth(medthick)     ///
              || 	kdensity `income_var' 	if sector_n5 == 1, bwidth(`bw') ///
                     lpattern(solid) lcolor("`orange'") lwidth(medthick) /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') ///
                     lpattern(dots) lcolor("`grey'") lwidth(medthick) ///  // Fake line for xline
                     legend(order(`legend') nobox size(*0.9) region(lstyle(none)))  ///
                     xtitle("`xtitle'", size(medsmall)) ///
                            ytitle("Density", size(medsmall)) ///
                     title("`title'`subject2'", size(medsmall)) ///
                     scheme(ggplot2) ///
                     graphregion(color(white)) ///
                     xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend)  

       /* graph export "${gdFig_7L}/$language/`title'`subject2'_n.png", as(png) name("Graph") replace */

****   Skills

       if "$language" == "spanish" {
              local legend "1 "Agricultura" 2 "Manufactura" 3 "Servicios transables" 4 "Servicios de bajas habilidades" 5 "Servicios de altas habilidades" 6 "Salario mínimo (PPP, USD-2017)""
       } 
         else if "$language" == "english" {
              local legend "1 "Agriculture" 2 "Manufacture" 3 "Trade services" 4 "Low-skilled services" 5 "High-skilled services" 6 "Minimum Wage (PPP, USD-2017)""       
       }

** Figura 15: Panel B
       twoway  	kdensity `income_var'       if sector2_1 == 1, bwidth(`bw') ///
                     lpattern(shortdash dot) lcolor("`red'") lwidth(medthick)  ///
              || 	kdensity `income_var'       if sector2_2 == 1, bwidth(`bw') ///
                     lpattern(solid) lcolor("`blue'") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector2_3 == 1, bwidth(`bw') ///
                     lpattern(dash) lcolor("`green'") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector2_4 == 1, bwidth(`bw') ///
                     lpattern(solid) lcolor("`orange'") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector2_5 == 1, bwidth(`bw') ///
                     lpattern(shortdash dot) lcolor("`blueD'") lwidth(medthick) /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') ///
                     lpattern(dots) lcolor("`grey'") lwidth(medthick) ///  // Fake line for xline
                     legend(order(`legend')  nobox size(*0.9) region(lstyle(none))) ///
                     xtitle("`xtitle'", size(medsmall)) ///
                            ytitle("Density", size(medsmall)) ///
                     title("`title'`subject8'", size(medsmall)) ///
                     scheme(ggplot2) ///
                     graphregion(color(white)) ///
                     xline(`min_wage_ppp', lp(dots) lcolor("`grey'") noextend)  

       graph export "${gdFig_7L}/$language/`title'`subject8'_skills.png", as(png) name("Graph") replace

 /* restore */

 **** Skills - Private vs Public employees

       if "$language" == "spanish" {
              local sector2_1 "Agricultura"
              local sector2_2 "Manufactura"
              local sector2_3 "Servicios_Transables"
              local sector2_4 "Servicios_Bajas_Habilidades"       
              local sector2_5 "Servicios_Altas_Habilidades"       
       } 
         else if "$language" == "english" {
              local sector2_1 "Agriculture"
              local sector2_2 "Manufacture"
              local sector2_3 "Tradable_Services"
              local sector2_4 "Low_skilled_Services"       
              local sector2_5 "High_skilled_Services"    
         }

       foreach sector in 1 2 3 4 5 {

              gen pe_sector2_`sector' = sector2_`sector' if public_employee == 1
              replace sector2_`sector' = 0 if public_employee == 1

              local sector2_name = "`sector2_`sector''"

              graph twoway (kdensity `income_var' if sector2_`sector' == 1, bwidth(`bw') lpattern(solid) lcolor("`blue'") lwidth(medium)) ///
                            (kdensity `income_var' if pe_sector2_`sector' == 1, bwidth(`bw') lpattern(solid) lcolor("`green'") lwidth(medium)), ///
                     title("`sector2_name'") ///
                     legend(order(1 "Private employees" 2 "Public employees")) ///
                     ytitle("Density", size(small)) ///
                     xtitle("Hourly productivity (PPP, USD-2017)", size(small)) ///
                     name("`sector2_name'", replace)
              
              drop pe_sector2_`sector'
       }

       graph combine `sector2_1' `sector2_2' `sector2_3' `sector2_4' `sector2_5', ///
       title("`title'`subject8'", size(medsmall)) ///


******************************************************************************* 
 *                              Education level
******************************************************************************* 

       if "$language" == "spanish" {
              local legend "1 "Ninguna" 2 "Primaria" 3 "Secundaria" 4 "Formación técnica" 5 "Terciaria" 6 "Salario mínimo (PPP, USD-2017)""

       } 
         else if "$language" == "english" {
              local legend "1 "None" 2 "Primary" 3 "High School" 4 "Technical Training" 5 "Undergraduate/Postgraduate" 6 "Minimum Wage (PPP, USD-2017)""
       }

       twoway 	kdensity `income_var' if educc1 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("`red'") lwidth(medthick)  ///
              || 	kdensity `income_var' if educc2 == 1, bwidth(`bw') lpattern(solid) lcolor("`blue'") lwidth(medthick) ///
              || 	kdensity `income_var' if educc3 == 1, bwidth(`bw') lpattern(solid) lcolor("`green'") lwidth(medthick) ///
              || 	kdensity `income_var' if educc4 == 1, bwidth(`bw') lpattern(solid) lcolor("`orange'") lwidth(medthick) /// 
              || 	kdensity `income_var' if educc5 == 1, bwidth(`bw') lpattern(dash dot) lcolor("`blueD'") lwidth(medthick)  /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("`grey'") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none)) ) ///
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject3'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("`grey'") noextend)  

       graph export "${gdFig_7L}/$language/`title'`subject3'.png", as(png) name("Graph") replace


******************************************************************************* 
 *                              Company size
 *******************************************************************************  

      if "$language" == "spanish" {
              local legend "1 "Empresario/Independiente" 2 "Firmas 2-10 empleados" 3 "Firmas 11-50 empleados" 4 "Firmas 50+ empleados" 5 "Salario mínimo (PPP, USD-2017)""
       } 
         else if "$language" == "english" {
              local legend "1 "Owner/Self-employed" 2 "Firms 2-10 employees" 3 "Firms 11-50 employees" 4 "Firms 50+ employees" 5 "Minimum Wage (PPP, USD-2017)""
       }

       twoway 	kdensity `income_var' 	if firm == 1, bwidth(`bw') lpattern(solid) lcolor("`red'") lwidth(medthick)  ///
              || 	kdensity `income_var'       if firm == 2, bwidth(`bw') lpattern(shortdash dot) lcolor("`blue'") lwidth(medthick)  ///
              || 	kdensity `income_var' 	if firm == 3, bwidth(`bw') lpattern(solid) lcolor("`green'") lwidth(medthick)  ///
              || 	kdensity `income_var' 	if firm == 4, bwidth(`bw') lpattern(dash dot) lcolor("`orange'")lwidth(medthick)   /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("`grey'") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none))) ///
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject4'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("`grey'") noextend) 

       graph export "${gdFig_7L}/$language/`title'`subject4'.png", as(png) name("Graph") replace



******************************************************************************* 
*                        Education - line graph
******************************************************************************* 

              keep if q1_03_edad>=20 & q1_03_edad<=64 // edad trabajar
              keep if PO==1 //ocupados

              drop if log_total_income_y_ppp<4
              drop if log_produc_y_ppp<4

	preserve
              collapse (mean) log_produc_h_ppp log_produc_y_ppp, by(q1_03_edad educc_agg1 educc_agg2 educc_agg3)

              if "$language" == "spanish" {
                     local legend "1 "Primaria o menos" 2 "Secundaria o menos" 3 "Terciaria""
                     local xtitle "Edad"
                     local ytitle "Productividad media por nivel educativo"
              } 
              else if "$language" == "english" {
                     local legend "1 "Primary or lower" 2 "High school or lower" 3 "Tertiary""
                     local xtitle "Age"
                     local ytitle "Mean productivity by education level"
              }

              twoway    line log_produc_h_ppp q1_03_edad       if educc_agg1 == 1, lcolor("`blue'") lpattern(solid) xline(24, lp(dots) lcolor("`grey'")) ///
                     || line log_produc_h_ppp q1_03_edad       if educc_agg2 == 1, lcolor("`green'") lpattern(solid) ///
                     || line log_produc_h_ppp q1_03_edad       if educc_agg3 == 1, lcolor("`orange'") lpattern(solid) ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg1 == 1, mcolor("`blue'") msymbol(circle) msize(vsmall)  ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg2 == 1, mcolor("`green'") msymbol(circle) msize(vsmall)  ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg3 == 1, mcolor("`orange'") msymbol(circle) msize(vsmall) ///
                     ||, legend(order(`legend') nobox size(*0.9) region(lstyle(none))) /// 
                     xtitle("`xtitle'", size(medsmall)) ///
                     ytitle("`ytitle'", size(medsmall)) ///
                     xlabel(,grid  ) ylabel(,grid) ///
                            scheme(ggplot2) ///
                     graphregion(color(white))
                     
                     graph export "${gdFig_7L}/$language/`title'age_educ.png", as(png) name("Graph") replace
       restore



*******************************************************************************
              *               Bar Graph by subcategories
*******************************************************************************
* Define colors for categories
/* use "${gdData_7L}/7Labor_est1-1.dta", clear */

	foreach var in q1_08_etnia Región q1_02_sexo pquintil {
		preserve
		keep if PO == 1
              collapse (mean) `income_var' [aw = weight_hh], by(`var')

		*Categories
		if "`var'" == "q1_08_etnia" {
			gen indicador_es = "Etnia"
			gen indicador_en = "Ethnicity"
			rename q1_08_etnia subcategoria
			tempfile etnia
			save `etnia'
		}
		else if "`var'" == "Región" {
			gen indicador_es = "Región"
			gen indicador_en = "Region"
			rename Región subcategoria
			tempfile region
			save `region'
		}
		else if "`var'" == "q1_02_sexo" {
			gen indicador_es = "Sexo"
			gen indicador_en = "Gender"
			rename q1_02_sexo subcategoria
			tempfile sexo
			save `sexo'
		}
		else if "`var'" == "pquintil" {
			gen indicador_es = "Quintil"
			gen indicador_en = "Quintile"
			rename pquintil subcategoria
			tostring subcategoria, replace
			tempfile quintil
			save `quintil'
		}
		restore
	}

*Append

	preserve
	use `etnia', clear
	append using `region'
	append using `sexo'
	append using `quintil'

	
*Color for general category

	gen color_group = 0
	replace color_group = 1 if indicador_es == "Etnia"
	replace color_group = 2 if indicador_es == "Región"
	replace color_group = 3 if indicador_es == "Sexo"
	replace color_group = 4 if indicador_es == "Quintil"
	separate `income_var', by(color_group)

*Loop for graphs

	foreach language in en {
		if "`language'" == "es" {
			local ytitle "Productividad promedio por hora en PPP USD - 2017"
			local indicador_col "indicador_es"
		}
		else {
			local ytitle "Average hourly productivity in PPP USD - 2017"
			local indicador_col "indicador_en"
			replace subcategoria = "Female" if subcategoria == "Femenino"
			replace subcategoria = "Male" if subcategoria == "Masculino"
		}

		*Graph
		graph hbar (mean) `income_var'?, ///
			over(subcategoria, label(labsize(small) angle(h)) sort(n)) ///
			over(`indicador_col', label(labsize(small))) ///
			nofill ytitle("`ytitle'") ///
			blabel(bar, pos(inside) format(%3.1f) ///
			size(small) color(white)) legend(off) ///
			bar(1, color("217 83 79")) ///
			bar(2, color("91 192 222")) ///
                     bar(3, color("92 184 92"))

		
			graph export "$gdFig_7L/`language'/F12_Vulnerability.png", as(png) replace

	}
        

** END 2-1.figures_7.do


