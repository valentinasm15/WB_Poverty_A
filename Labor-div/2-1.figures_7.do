*===============================================================================
* Project:       	Labor diversification
* Author:        	Valentina
* Creation Date:    Jan 2025  
*===============================================================================
clear all

   set scheme sj
    grstyle init
    grstyle set plain, horizontal grid
    grstyle set legend 6, nobox klength(small) 


** Define language to produce the graphs

       local language = "english" // english / spanish


*                        Education - Scatter
*===============================================================================
** Returns to education

       ** Collecting crosscountry data 

       use "${gdData}/Cross country/WDI/WDI.dta", clear 
       rename (country_name country_code BC BN BP) (countryname countrycode GDPpc_2010 GDPpc_2021 GDPpc_2023)
       keep if indicator == "GDP per capita, PPP (constant 2021 international $)"
       keep countryname countrycode GDPpc_2010 GDPpc_2021 GDPpc_2023

              tempfile GDPpc       
              save `GDPpc', replace

       import excel using "${gdData}/Cross country/WPS7020.xlsx", sheet(Table 7) first  clear
       rename (A B C) (countryname year agg_return_schooling)
       drop if year=="Year"
       keep if year=="2010" | year=="2023"

       destring year, replace
       keep countryname year agg_return_schooling
       destring agg_return_schooling, replace
       destring year, replace


merge m:1 countryname using `GDPpc' 

       drop if GDPpc_2023>80000
 
       export excel using "${gdData}/Cross country/edu_returns.xlsx", sheet(cleaned) sheetreplace first(variable) 

       gen highlight = 0
       replace highlight = 1 if inlist(countrycode, "GNQ", "ZAF", "RWA", "UGA", "MDG", "IDN", "MYS", "ZMB", "NPL")

       if "`language'" == "spanish" {
              local xtitle "PIB per cápita PPP - 2021 USD"
              local ytitle "Retornos por un año adicional de educación"
       } 
         else if "`language'" == "english" {
              local xtitle "GDP per capita PPP - 2021 USD"
              local ytitle "Returns to another year of schooling"
       }
        

       twoway scatter agg_return_schooling GDPpc_2023 if highlight == 0, msymbol(o) mcolor("166 166 166") ///
       || scatter agg_return_schooling GDPpc_2023 if highlight == 1, msymbol(o) mcolor("63 160 255") ///
       || scatter agg_return_schooling GDPpc_2023 if highlight == 1, mlab(countryname) mlabsize(small) msymbol(o)  mcolor("63 160 255")  ///
       || scatter agg_return_schooling GDPpc_2023 if highlight == 1 & countrycode=="GNQ", mlab(countryname) mlabsize(small) msymbol(triangle)  mcolor("231 76 60")  /// 
       xscale(range(1000 70000)) xlabel(0(15000)70000, format(%10.0gc)) ///
       legend(off) ///
       xtitle("`xtitle'", size(medsmall)) ytitle("`ytitle'", size(medsmall))

       graph export "${gdFig_7L}/`language'/`title'returns_edu.png", as(png) name("Graph") replace
asd
/*a
"GNQ", 
       || scatter agg_return_schooling GDPpc_2023 if highlight == 1 & countrycode=="GNQ", mlab(countryname) mlabsize(small) msymbol(triangle)  mcolor("231 76 60")  /// */

*                        Education - line graph
*===============================================================================

       use "${gdData_7L}/7Labor_est1-1.dta", clear
	keep if q1_03_edad>=20 & q1_03_edad<=64 // edad trabajar
	keep if oci==1 //ocupados
	
       collapse (mean) log_produc_h_ppp log_produc_y_ppp, by(q1_03_edad educc_agg1 educc_agg2 educc_agg3)


       if "`language'" == "spanish" {
              twoway    line log_produc_h_ppp q1_03_edad       if educc_agg1 == 1, lcolor("63 160 255") lpattern(solid) xline(24, lp(dots) lcolor("231 76 60")) ///
                     || line log_produc_h_ppp q1_03_edad       if educc_agg2 == 1, lcolor("166 166 166") lpattern(solid) ///
                     || line log_produc_h_ppp q1_03_edad       if educc_agg3 == 1, lcolor("85 182 72") lpattern(solid) ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg1 == 1, mcolor("63 160 255") msymbol(circle) msize(vsmall)  ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg2 == 1, mcolor("166 166 166") msymbol(circle) msize(vsmall)  ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg3 == 1, mcolor("85 182 72") msymbol(circle) msize(vsmall) ///
                     ||, legend(order(1 "Primaria o menos" 2 "Secundaria o menos" 3 "Terciaria") ///
                     region(lstyle(none))) ///
                     xtitle("Edad", size(medsmall)) ///
                     ytitle("Productividad media por nivel educativo", size(medsmall)) ///
                     xlabel(,grid  ) ylabel(,grid) ///
                            scheme(ggplot2) ///
                     graphregion(color(white))
              
              graph export "${gdFig_7L}/`language'/`title'age_educ.png", as(png) name("Graph") replace

       } 
         else if "`language'" == "english" {
              twoway line log_produc_h_ppp q1_03_edad          if educc_agg1 == 1, lcolor("63 160 255") lpattern(solid) xline(24, lp(dots) lcolor("231 76 60")) ///
                     || line log_produc_h_ppp q1_03_edad       if educc_agg2 == 1, lcolor("166 166 166") lpattern(solid) ///
                     || line log_produc_h_ppp q1_03_edad       if educc_agg3 == 1, lcolor("85 182 72") lpattern(solid) ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg1 == 1, mcolor("63 160 255") msymbol(circle) msize(vsmall)  ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg2 == 1, mcolor("166 166 166") msymbol(circle) msize(vsmall)  ///
                     || scatter log_produc_h_ppp q1_03_edad    if educc_agg3 == 1, mcolor("85 182 72") msymbol(circle) msize(vsmall) ///
              ||, legend(order(1 "Primary or lower" 2 "Secondary or lower" 3 "Tertiary") ///
                     region(lstyle(none))) ///
              xtitle("Age") ///
              ytitle("Mean productivity by education level") ///
              xlabel(,grid  ) ylabel(,grid) ///
                            scheme(ggplot2) ///
                     graphregion(color(white))

              graph export "${gdFig_7L}/`language'/`title'age_educ.png", as(png) name("Graph") replace
       }
     
*===============================================================================
*                                  Density Graphs
*===============================================================================

use "${gdData_7L}/7Labor_est1-1.dta", clear

** Locals to customize graphs 

       ** Uncomment the variable desired
       /* local income_var "log_total_income_y_ppp"     // Log yearly total income PPP */
       /* local income_var "log_total_income_h_ppp"     // Log hourly total income PPP */
       /* local income_var "log_produc_y_ppp"           // Log yearly Productivity PPP */
       local income_var "log_produc_h_ppp"              // Log hourly Productivity PPP

       local bw = 0.1

       if "`language'" == "spanish" {
       
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
       else if "`language'" == "english" {
   
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
       }


*                           Working activity 
*===============================================================================
** Working activity

       if "`language'" == "spanish" {
              local legend "1 "Trabajadores asalariados" 2 "Empresarios/Independientes" 3 "Otros trabajadores""
       } 
         else if "`language'" == "english" {
              local legend "1 "Salaried workers" 2 "Self-employed/Own boss" 3 "Other workers""
       }

       twoway 	kdensity `income_var' 	if empstat_1 == 1, bwidth(`bw') lpattern(solid) lcolor("63 160 255") lwidth(medthick)  ///
              || 	kdensity `income_var'       if empstat_2 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("166 166 166") lwidth(medthick) ///
              || 	kdensity `income_var' 	if empstat_3 == 1, bwidth(`bw') lpattern(dash) lcolor("85 182 72") lwidth(medthick) ///
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("231 76 60") lwidth(medthick) ///  // Fake line for xline
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject1'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend)  ///
              legend(order(`legend')  nobox size(*0.9) region(lstyle(none)))


       graph export "${gdFig_7L}/`language'/`title'`subject1'.png", as(png) name("Graph") replace

*                             Employment sector  
*===============================================================================
** General employment sector

       if "`language'" == "spanish" {
              local legend "1 "Agricultura" 2 "Industria" 3 "Servicios Transables" 4 "Servicios No Transables""
       } 
         else if "`language'" == "english" {
              local legend "1 "Agriculture" 2 "Industry" 3 "Tradable Services" 4 "Non-Tradable Services""

       }

       twoway 	kdensity `income_var' 	if sector1 == 1, bwidth(`bw') lpattern(solid) lcolor("85 182 72") lwidth(medthick)  ///
              || 	kdensity `income_var' 	if sector2 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("0 113 192") lwidth(medthick) ///
              || 	kdensity `income_var'       if sector3 == 1, bwidth(`bw') lpattern(dash) lcolor("166 166 166") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector4 == 1, bwidth(`bw') lpattern(solid) lcolor("63 160 255") lwidth(medthick) ///
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("231 76 60") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none))) ///
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject2'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend) 

       graph export "${gdFig_7L}/`language'/`title'`subject2'_tr.png", as(png) name("Graph") replace

** New sectors of economy

       if "`language'" == "spanish" {
              local legend "1 "Economía Azul" 2 "Economía Verde" 3 "Economía Amarrilla" 4 "Economía digital" 5 "Turismo" 6 "Salario mínimo (PPP, USD-2017)""
       } 
         else if "`language'" == "english" {
              local legend "1 "Blue Economy" 2 "Green Economy" 3 "Yellow Economy" 4 "Digital Economy" 5 "Tourism" 6 "Minimum Wage (PPP, USD-2017)""
       }

       twoway  	kdensity `income_var'       if sector_n1 == 1, bwidth(`bw') lpattern(solid) lcolor("63 160 255") lwidth(medthick)  ///
              || 	kdensity `income_var'       if sector_n2 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("85 182 72") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector_n3 == 1, bwidth(`bw') lpattern(dash) lcolor("63 160 255") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector_n4 == 1, bwidth(`bw') lpattern(longdash dot) lcolor("231 76 60") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector_n5 == 1, bwidth(`bw') lpattern(solid) lcolor("130 130 212") lwidth(medthick) /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("231 76 60") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none)))  ///
              xtitle("`xtitle'", size(medsmall)) ///
                     ytitle("Density", size(medsmall)) ///
              title("`title'`subject2'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend)  

       graph export "${gdFig_7L}/`language'/`title'`subject2'_n.png", as(png) name("Graph") replace

** Skills
       if "`language'" == "spanish" {
              local legend "1 "Agricultura" 2 "Manufactura" 3 "Servicios transables" 4 "Servicios de bajas habilidades" 5 "Servicios de altas habilidades" 6 "Salario mínimo (PPP, USD-2017)""
       } 
         else if "`language'" == "english" {
              local legend "1 "Agriculture" 2 "Manufacture" 3 "Tradable services" 4 "Low-skilled services" 5 "High-skilled services" 6 "Minimum Wage (PPP, USD-2017)""       
       }

       twoway  	kdensity `income_var'       if sector2_1 == 1, bwidth(`bw') lpattern(solid) lcolor("85 182 72") lwidth(medthick)  ///
              || 	kdensity `income_var'       if sector2_2 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("0 113 192") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector2_3 == 1, bwidth(`bw') lpattern(dash) lcolor("166 166 166") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector2_4 == 1, bwidth(`bw') lpattern(solid) lcolor("63 160 255") lwidth(medthick) ///
              || 	kdensity `income_var' 	if sector2_5 == 1, bwidth(`bw') lpattern(solid) lcolor("130 130 212") lwidth(medthick) /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("231 76 60") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend')  nobox size(*0.9) region(lstyle(none))) ///
              xtitle("`xtitle'", size(medsmall)) ///
                     ytitle("Density", size(medsmall)) ///
              title("`title'`subject2'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend)  

       graph export "${gdFig_7L}/`language'/`title'`subject2'_n.png", as(png) name("Graph") replace


 *                              Education level
 *=============================================================================== 
       if "`language'" == "spanish" {
              local legend "1 "Ninguna" 2 "Primaria" 3 "Secundaria" 4 "Formación técnica" 5 "Terciaria" 6 "Salario mínimo (PPP, USD-2017)""

       } 
         else if "`language'" == "english" {
              local legend "1 "None" 2 "Primary" 3 "High School" 4 "Technical Training" 5 "Undergraduate/Postgraduate" 6 "Minimum Wage (PPP, USD-2017)""
       }

       twoway 	kdensity `income_var' 	if educc1 == 1, bwidth(`bw') lpattern(solid) lcolor("85 182 72") lwidth(medthick)  ///
              || 	kdensity `income_var'       if educc2 == 1, bwidth(`bw') lpattern(dash) lcolor("166 166 166") lwidth(medthick) ///
              || 	kdensity `income_var' 	if educc3 == 1, bwidth(`bw') lpattern(shortdash dot) lcolor("231 76 60") lwidth(medthick) ///
              || 	kdensity `income_var' 	if educc4 == 1, bwidth(`bw') lpattern(dash dot) lcolor("130 130 212") lwidth(medthick) /// 
              || 	kdensity `income_var' 	if educc5 == 1, bwidth(`bw') lpattern(solid) lcolor("63 160 255") lwidth(medthick)  /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("231 76 60") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none)) ) ///
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject3'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend)  


       graph export "${gdFig_7L}/`language'/`title'`subject3'.png", as(png) name("Graph") replace


 *                              Companies size
 *=============================================================================== 
      if "`language'" == "spanish" {
              local legend "1 "Empresario/Independiente" 2 "Firmas 2-10 empleados" 3 "Firmas 11-50 empleados" 4 "Firmas 50+ empleados" 5 "Salario mínimo (PPP, USD-2017)""
       } 
         else if "`language'" == "english" {
              local legend "1 "Owner/Self-employed" 2 "Firms 2-10 employees" 3 "Firms 11-50 employees" 4 "Firms 50+ employees" 5 "Minimum Wage (PPP, USD-2017)""
       }

       twoway 	kdensity `income_var' 	if firm == 1, bwidth(`bw') lpattern(solid) lcolor("85 182 72") lwidth(medthick)  ///
              || 	kdensity `income_var'       if firm == 2, bwidth(`bw') lpattern(shortdash dot) lcolor("231 76 60") lwidth(medthick)  ///
              || 	kdensity `income_var' 	if firm == 3, bwidth(`bw') lpattern(solid) lcolor("63 160 255") lwidth(medthick)  ///
              || 	kdensity `income_var' 	if firm == 4, bwidth(`bw') lpattern(dash dot) lcolor("166 166 166")lwidth(medthick)   /// 
              || 	function y = 0, range(`min_wage_ppp' `min_wage_ppp') lpattern(dots) lcolor("231 76 60") lwidth(medthick) ///  // Fake line for xline
              legend(order(`legend') nobox size(*0.9) region(lstyle(none))) ///
              xtitle("`xtitle'", size(medsmall)) ///
              ytitle("Density", size(medsmall)) ///
              title("`title'`subject4'", size(medsmall)) ///
              scheme(ggplot2) ///
              graphregion(color(white)) ///
              xline(`min_wage_ppp', lp(dots) lcolor("231 76 60") noextend) 


       graph export "${gdFig_7L}/`language'/`title'`subject4'.png", as(png) name("Graph") replace

lines 184 figure do

              *                      Bar Graph
*===============================================================================
* Define colors for categories
replace q1_08_etnia = "Other" if q1_08_etnia != "Fang" & q1_08_etnia != "Bubi" & !missing(q1_08_etnia)
local lang "en"

*Indicators

	foreach var in q1_08_etnia Región q1_02_sexo {
		preserve
		keep if q1_03_edad >= 15 & q1_03_edad <= 64
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
		restore
	}

*Append

	preserve
	use `etnia', clear
	append using `region'
	append using `sexo'
	
*Color for general category

	gen color_group = ""
	replace color_group = "85 182 72" if indicador_es == "Etnia"
	replace color_group = "63 160 255" if indicador_es == "Región"
	replace color_group = "166 166 166" if indicador_es == "Sexo"
	separate `income_var', by(color_group)

*Loop for graphs

	
	local ytitle "Average hourly productivity in PPP USD - 2017"
	local indicador_col "indicador_en"
	replace subcategoria = "Female" if subcategoria == "Femenino"
	replace subcategoria = "Male" if subcategoria == "Masculino"
	
    
              * Generate the graph
              graph hbar (mean) `income_var'?,  ///
              over(subcategoria, label(labsize(small) angle(h)) sort(n))  ///
              over(`indicador_col', label(labsize(small))) ///
              nofill ytitle("`ytitle'") ///
              blabel(bar, pos(inside) format(%3.1f) size(small) ) ///
              legend(off)

        graph export "graph_`lang'_subcategoria_`sub'.png", replace
	   

** COLORS
/* "63 160 255"   // #3FA0FF
"255 224 153"  // #FFE099
"247 109 94"   // #F76D5E
"231 76 60"    // #E74C3C
"130 130 212"  // #8282D4
"0 113 192"    //rgb(0, 113, 192)  */

