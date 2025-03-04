/******************************************************************************* 
	Title: Laboral
	World Bank - Guinea Ecuatorial
									
*******************************************************************************/

use "${gdData_7L}/7Labor_est1-1.dta", clear 


*===============================================================================
	* 							Quality of job
*==============================================================================	

*Income-----------------------------------
*Divided by CPI 2017, PPP 2017 and 365 days
	
	gen total_2017 = total_income_y/cpi/ppp/365
	gen log_totales = log(total_2017)

*International Extreme Poverty Line (2.15/day)

	gen threshold_17 = (2.15*4)/1.5    // Includes dependency ratio across countries: 4 is average hh size and 1.5 the avr number of full-time workers per hh
	gen out_poverty = total_2017 > threshold_17

*Benefits----------------------------------
*Health Insurance: Job provides health insurance

	gen health = q5_29_segSalud == "Sí"

*Social security: Job associated with any type of social security

	gen social_s = q5_28_segSocial == "Sí"

*Annual paid leave: Job offers paid holiday leave

	gen holiday = q5_30_vacaciones == "Sí"

*Paid sick leave: Job offers paid sick leave

	gen sick = q5_31_pagadaEnfermidad == "Sí"

*Stability----------------------------------
*Tenure: 3+ years of tenure in job for workers ages 25–64, 1+ years of tenure in job for workers ages 15–24

	gen tenure = (q5_24_anos>3 & q1_03_edad >= 25 & q1_03_edad<65) 
	replace tenure = 1 if (q5_24_anos>1 & q1_03_edad >= 15 & q1_03_edad<25) 

*Written contract: Employment is bound by written contract

	gen written = q5_25_tipoContrato == "Contrato escrito"

*Working conditions--------------------------
*Excessive working hours: Individual does not exceed 48 weekly hours
	gen hour = totalHorasPrincipal < 49

*Second paid job: Individual does not work a second paid job
	gen second = q5_38_otroEmpleo == 2

*Direct question: would you like to work more?: Individual responds "no"
	gen work_more = q5_70_deseaMasHoras == 2

*Quality index-------------------------------
	gen income = out_poverty == 1
	gen benefits = (health == 1) | (social_s == 1) | (sick == 1) | (holiday == 1)
	gen stability = (tenure == 1) | (written == 1)
	gen work_cond = (hour == 1) & (second == 1) & (work_more == 1)
	

	egen job_qual = rowtotal(income benefits stability work_cond), m
	tab job_qual, m
	sum job_qual

	/* replace job_qual = . if Asal !=1 
	tab job_qual, m
	sum job_qual

	replace job_qual = . if Asal !=1 & cuenta_p==1
	tab job_qual, m
	sum job_qual */

*===============================================================================
	* 						The precariously employed
*==============================================================================

*Unstable jobs: limited number of months. It has maximum 45 percent of potential working time and those who report no work activity but report being employed at the time of the interview
	
	gen unstable = inlist(dur_contrato, 1, 2, 3, 8)
	replace unstable = 1 if q5_05_trabajo1hora == "Sí" & total_hr == 0

*Restricted working hours: less than 20 hours of work a week. Excluded people in the school or because the number of hours is full-time in their job
	
	gen restricted = totalHorasPrincipal < 20
	replace restricted = 0 if q3_08_asistio == "Sí"

*Labor incomes: reporting some work but negative, zero, or near-zero earnings. Lower than the minimum wage
	
	gen comp_wage = wage_y_ppp - min_wage_y_ppp
	gen low_incomes = comp_wage == 0 | comp_wage < 500
	

*===============================================================================
	* 				2011 PPP for cross country comparison 
*==============================================================================

    *** Inflation from 2017 to 2011 to make it comparable to other countries 
	preserve 
    import excel using "${gdData_7L}/API_FP.CPI.TOTL_DS2_en_excel_v2_76325.xls", sheet("Data") first clear
      
      drop if DataSource== "Last Updated Date" | DataSource == ""
      rename DataSource countryname
      keep if countryname == "Equatorial Guinea" 

      keep countryname WorldDevelopmentIndicators C D BC BD BE BF BG BH BI BJ BK BL BM BN BO BP 
      rename (BC BD BE BF BG BH BI BJ BK BL BM BN BO BP) (cpi_2010 cpi_2011 cpi_2012 cpi_2013 cpi_2014 cpi_2015 cpi_2016 cpi_2017 cpi_2018 cpi_2019 cpi_2020 cpi_2021 cpi_2022 cpi_2023)
      destring (cpi_2017 cpi_2011 cpi_2022), replace


      gen cpi_11_17 = cpi_2017/cpi_2011
      gen cpi_11_22 = cpi_2022/cpi_2011

		sum cpi_11_17
		scalar cpi_11_17 = r(mean) 
		local cpi_11_17 = scalar(cpi_11_17)

	restore 
*Income-----------------------------------
*Divided by CPI 2011, PPP 2011 and 365 days
	
	gen total_2011 = total_2017 / `cpi_11_17' // Cross country analysis is in PPP 2011 
	gen log_totales_2011 = log(total_2011)

	*International Extreme Poverty Line (2.15/day)

	gen threshold_11 = (1.90*4)/1.5    // 1.90 is used in methodology. Includes dependency ratio across countries: 4 is average hh size and 1.5 the avr number of full-time workers per hh
	gen out_poverty_11 = total_2011 > threshold_11

*Quality index-------------------------------
	gen income_11 = out_poverty_11 == 1

	egen job_qual_11 = rowtotal(income_11 benefits stability work_cond), m
	egen median_17= mean(job_qual)
	egen median_11= mean(job_qual_11)
	tab job_qual, m
	sum job_qual

	tab job_qual_11, m
	sum job_qual_11


save "${gdData_7L}/7Labor_est1-1.dta", replace 