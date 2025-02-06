*===============================================================================
* Project:       	Labor diversification
* Author:        	Valentina
* Creation Date:    Jan 2025  
*===============================================================================

	                        * Labor diversification
*===============================================================================
	* Globals / Locals 	

	
					  
	global results 		"${ldAnalysis}/3-Results/`c(username)'/7_Labor_diversification"	  

	local survey_hh 	"2.- BASE DE DATOS DE VIVIENDA REFORMAS Y RECURSOS.dta"
    local survey_ind 	"Auxiliary/Nov_11_2024/inege_nov.dta"	 
    local survey_ind_old "1.- BASE DE DATOS DE MIEMBROS PROFESIONALES Y HORAS TRABAJADAS.dta"	 
	local id_vars 		"cod_region cod_provincia cod_distrito cod_MU_DU interview__key codigoMiembro2"

*===============================================================================
	* 				Merging complete database
*===============================================================================	

	use "${gdData}/Household surveys/ENH2/`survey_ind_old'", clear

	replace q1_03_edad = q1_03_edad_anos if q1_03_edad==0
	gen edad = q1_03_edad
	drop q1_03_edad
	rename edad q1_03_edad
		order q1_03_edad, b(q1_03_edad_anos)
	keep q1_03_edad `id_vars'
	tab q1_03_edad, missing

	
	tempfile age
	save `age', replace 


	use "${gdData}/Household surveys/ENH2/Welfare-measurement/GNQ_enh2_welfare.dta", clear 

	keep  interview__key hhsize weight_hh zref welfare cpi ppp hhw
	gen pcexp_ppp = welfare /cpi/ppp/365
		label var pcexp_ppp "Per capita consumption, daily and 2017 uSD PPP"
	
	tempfile data
	save `data', replace 

	use "${gdData}/Household surveys/ENH2/`survey_ind'" , clear  // base personas

	drop interview__key q1_03_edad

	cap rename (B q5_16_codigo q5_17_codigo q5_39_codigo q5_40_codigo Sección_activ Sección_activ1  Sección_actividad HN ) (interview__key q5_16_codigo_nuevo q5_17_codigo_nuevo q5_39_codigo_nuevo q5_40_codigo_nuevo Sector_empleo1 Sector_empleo1_detalle Sector_empleo2 Sector_empleo2_detalle )

		save "$gdDatatemp_7L/CIIU_code.dta", replace
		tempfile CIIU
		save `CIIU', replace	


	merge m:1 interview__key using "${gdData}/Household surveys/ENH2/`survey_hh'", nogen keep(matched) // base hogares	

	merge m:1 interview__key using `data', nogen assert (master matched) keep(matched) // base pobreza
	merge 1:1 interview__key codigoMiembro2 using `age', nogen keep(matched) 

	label def urban 1 "Urban" 2 "Rural"
	label val cod_CV_CP urban	
	gen rural = (cod_CV_CP==2)
	gen female = (q1_02_sexo=="Femenino") //female

	save "${gdData_7L}/CleanDataBase_nov2024.dta", replace

*===============================================================================
	* 			Type of occupation - salaried, non-salaried
*===============================================================================

	use "${gdData_7L}/CleanDataBase_nov2024.dta", clear //base with merge of individual, household and monetary
		merge 1:1 interview__key codigoMiembro2 codigoMiembro3 codigoMiembro4 using `CIIU', gen(merge_CIIU) keep(1 3)

** 
	gen check_ocupados = (q5_01_trabajo1horaCampo=="Sí, por cuenta ajena" | q5_01A_trabajo1horaCazando=="Sí, por cuenta ajena" | q5_01_trabajo1horaCampo=="Sí, por cuenta propia" | q5_01A_trabajo1horaCazando=="Sí, por cuenta propia" | q5_02_trabajo1horaHogar=="Sí" | q5_03_trabajo1horaJefe=="Sí" | q5_04_trabajo1horaAprendiz=="Sí" )
	replace check_ocupados = . if q1_03_edad<12

	gen oci = (check_ocupados==1) if q1_03_edad>=12
	replace oci = 1 if q5_06_trabajo_a_volver=="Sí" & q1_03_edad>=12

	gen     PD = 0 if check_ocupados!=.
	replace PD = 1 if (q5_10_buscoTrabajoRemunerado=="Si, en los últimos 30 dias" | q5_10_buscoTrabajoRemunerado=="Si, en los últimos 3 meses") & q5_12_disponible == "Sí"
	*replace PD = 1 if q5_11_porqueNo=="Espera una respuesta a una solicitud de empleo"
	replace PD = 0 if check_ocupados == 1 


** Filter by age to work and occupation is at the end so a unified database is created for chapter 3

** Identifying workers and non-workers and Employment status
	local vars q5_18_ocupacionPrincipal

		foreach var of local vars {
			gen `var'_ =0
			replace `var'_ = 1 if `var' == "Empleado público"
			replace `var'_ = 2 if `var' == "Empleado privado"
			replace `var'_ = 3 if `var' == "Empresario (Propietario)"
			replace `var'_ = 4 if `var' == "Miembro de cooperativas"
			replace `var'_ = 5 if `var' == "Independiente/Autónomo"
			replace `var'_ = 6 if `var' == "Trabajador familiar auxiliar"
			replace `var'_ = 7 if `var' == "Servicio doméstico"
			replace `var'_ = 8 if `var' == "Destajista"
			replace `var'_ = 9 if `var' == "Otro"
		}
	


*===============================================================================
	* 							Sector of activity 
*==============================================================================

** Identifying the sector of activity

	gen CIIU_trabajo_prin = substr(q5_17_codigo_nuevo,1,2)
	destring CIIU_trabajo_prin , gen(CIIU_trabajo_num_prin)

	gen CIIU_trabajo_sec = substr(q5_40_codigo_nuevo,1,2)
	destring CIIU_trabajo_sec , gen(CIIU_trabajo_num_sec)

	foreach x in "prin" "sec"{
	gen Section_job_`x' = ""
		replace Section_job_`x'="A. Agriculture" if inlist(CIIU_trabajo_`x', "01", "02", "03") 
		replace Section_job_`x'="B. Mining" if inlist(CIIU_trabajo_`x', "05", "06", "07", "08", "09")
		replace Section_job_`x'="C. Manufacturing" if CIIU_trabajo_num_`x'>=10 & CIIU_trabajo_num_`x'<=33
		replace Section_job_`x'="D. Electricity, gas supply" if CIIU_trabajo_num_`x'==35
		replace Section_job_`x'="E. Water supply" if CIIU_trabajo_num_`x'>=36 & CIIU_trabajo_num_`x'<=39
		replace Section_job_`x'="F. Construction" if CIIU_trabajo_num_`x'>=41 & CIIU_trabajo_num_`x'<=43
		replace Section_job_`x'="G. Wholesale and retail trade" if CIIU_trabajo_num_`x'>=45 & CIIU_trabajo_num_`x'<=47
		replace Section_job_`x'="H. Transportation and storage" if CIIU_trabajo_num_`x'>=49 & CIIU_trabajo_num_`x'<=53
		replace Section_job_`x'="I. Accomodation and food service" if CIIU_trabajo_num_`x'>=55 & CIIU_trabajo_num_`x'<=56
		replace Section_job_`x'="J. Information and communciation" if CIIU_trabajo_num_`x'>=58 & CIIU_trabajo_num_`x'<=63
		replace Section_job_`x'="K. Financial and insurance activities" if CIIU_trabajo_num_`x'>=64 & CIIU_trabajo_num_`x'<=66
		replace Section_job_`x'="L. Real State Services" if CIIU_trabajo_num_`x'==68
		replace Section_job_`x'="M. Professional, scientific and technical" if CIIU_trabajo_num_`x'>=69 & CIIU_trabajo_num_`x'<=75
		replace Section_job_`x'="N. Administrative and support" if CIIU_trabajo_num_`x'>=77 & CIIU_trabajo_num_`x'<=82
		replace Section_job_`x'="O. Public administration and defence" if CIIU_trabajo_num_`x'==84
		replace Section_job_`x'="P. Education" if CIIU_trabajo_num_`x'==85
		replace Section_job_`x'="Q. Human health and social work" if CIIU_trabajo_num_`x'>=86  & CIIU_trabajo_num_`x'<=88
		replace Section_job_`x'="R. Arts, entertainment and recreation" if CIIU_trabajo_num_`x'>=90  & CIIU_trabajo_num_`x'<=93
		replace Section_job_`x'="S. Other services activities" if CIIU_trabajo_num_`x'>=94  & CIIU_trabajo_num_`x'<=96
		replace Section_job_`x'="T. Activities of households as employers" if CIIU_trabajo_num_`x'>=97  & CIIU_trabajo_num_`x'<=98
		replace Section_job_`x'="U. Activities of extraterritorial organizations" if CIIU_trabajo_num_`x'==99
		
	gen Agg_Economic_`x' = "Agriculture" if Section_job_`x'=="A. Agriculture"
		replace Agg_Economic_`x' = "Manufacturing" if Section_job_`x'=="C. Manufacturing"
		replace Agg_Economic_`x' = "Construction" if Section_job_`x'=="F. Construction"
		replace Agg_Economic_`x' = "Mining, electricity, gas, water" if inlist(Section_job_`x', "B. Mining", "D. Electricity, gas supply", "E. Water supply")
		replace Agg_Economic_`x' = "Market Services" if inlist(Section_job_`x', "G. Wholesale and retail trade", "H. Transportation and storage", "I. Accomodation and food service", "J. Information and communciation", "K. Financial and insurance activities", "L. Real State Services", "M. Professional, scientific and technical", "N. Administrative and support")
		replace Agg_Economic_`x' = "Non-market Services" if inlist(Section_job_`x', "O. Public administration and defence", "P. Education", "Q. Human health and social work", "R. Arts, entertainment and recreation", "S. Other services activities", "T. Activities of households as employers", "U. Activities of extraterritorial organizations")
	}


	/* keep if q1_03_edad>=16 & q1_03_edad<=64 // edad trabajar
	keep if oci==1 //ocupados */
	bysort interview__key: gen idi = _n // idi, different from the id in the whole hh, just enumerating the individuald that fulfill the criteria of age and job

	gen agesq = q1_03_edad^2 //agesq

** 1. General sectors of activity

	gen gsector = 1 if (Agg_Economic_prin=="Agriculture") 
	replace gsector = 2 if (inlist(Agg_Economic_prin,"Manufacturing", "Construction", "Mining, electricity, gas, water")) // sector 2 (Industry)
	replace gsector = 3 if (inlist(Agg_Economic_prin, "Market Services", "Non-market Services")) // sector 3 (Services)

	gen sector_1 = (Agg_Economic_prin=="Agriculture") // sector 1 (Agriculture)
	gen sector_2 = (inlist(Agg_Economic_prin,"Manufacturing", "Construction", "Mining, electricity, gas, water")) // sector 2 (Industry)
	gen sector_3 = (inlist(Agg_Economic_prin, "Market Services", "Non-market Services")) // sector 3 (Services)


	recode q5_18_ocupacionPrincipal_ (1=1) (2=2) (3=3) (5=3) (6=4) (7=4) (4=5) (8=5) (9=5), gen(empstat_monetary)
	recode q5_41_ocupacionSecundaria (1=1) (2=2) (3=3) (5=3) (6=4) (7=4) (4=5) (8=5) (9=5), gen(empstat_monetary2)
	label define ocup 1 "Empleado público" 2 "Empleado privado" 3 "Independiente/Empresario" 4 "Servicio doméstico/Trabajo familiar auxiliar" 5 "Otros"
	label val empstat_monetary ocup
	label val empstat_monetary2 ocup
	


** 2. General Sectors but services divided in Tradable and Non-tradable

	gen actividad = substr(q5_17_codigo_nuevo, 1, 2)

	destring actividad, replace
	gen sector = .
	replace sector = 1 if inlist(actividad, 1, 2, 3) 			// Agriculture
	replace sector = 2 if actividad >= 5 & actividad <= 43 		// Industry 
	replace sector = 3 if (actividad >= 45 & actividad <= 47) 	///
		| (actividad >= 49 & actividad <= 53) 					/// 
		| (actividad >= 58 & actividad <= 63) 					/// 
		| (actividad >= 64 & actividad <= 66) 					/// 
		| (actividad == 68) 									// Tradable
	replace sector = 4 if (actividad >= 55 & actividad <= 56) 	///
		| (actividad >= 69 & actividad <= 75) 					/// 
		| (actividad >= 77 & actividad <= 82) 					/// 
		| (actividad == 84) 									/// 
		| (actividad == 85) 									/// 
		| (actividad >= 86 & actividad <= 88) 					/// 
		| (actividad >= 90 & actividad <= 93) 					/// 
		| (actividad >= 94 & actividad <= 96) 					/// 
		| (actividad >= 97 & actividad <= 98) 					/// 
		| (actividad == 99) 									// Non-Tradable

	tabulate sector, generate(sector)

	label define sector_lbl_es 1 "Agricultura" 2 "Industria" 3 " Servicios Transables" 4 "Servicios No Transables"
	label define sector_lbl_en 1 "Agriculture" 2 "Industry" 3 "Tradable Services" 4 "Non-Tradable Services"
	

** 3. Classification of sectors - Type of economy
	
	destring q5_17_codigo, replace
	gen sector_n = 1 if actividad == 3 | actividad == 50 | q5_17_codigo == 301 		// Blue economy
	replace sector_n = 2 if inlist(actividad, 1, 2, 37, 38, 39) 					// Green economy
	replace sector_n = 3 if inlist(actividad, 5, 6, 19, 35) | q5_17_codigo == 351 	// Yellow economy
	replace sector_n = 4 if inlist(actividad, 61, 62, 63,  55, 56, 79, 90, 93) 							// Digital economy
	replace sector_n = 5 if inlist(actividad, 55, 56, 79, 90, 93)				 	// Tourism
	tabulate sector_n, generate(sector_n)

	replace sector_n = 0 if sector_n ==.
	replace sector_n1 = 0 if sector_n1 ==.
	replace sector_n2 = 0 if sector_n2 ==.
	replace sector_n3 = 0 if sector_n3 ==.
	replace sector_n4 = 0 if sector_n4 ==.
	replace sector_n5 = 0 if sector_n5 ==.

	label define other_sector_es 1 "Blue Economy" 2 "Green Economy" 3 "Yellow Economy" 4 "Digital Economy" 5 "Tourism"
	label define other_sector_en 1 "Economía Azul" 2 "Economía Verde" 3 "Economía Amarilla" 4 "Economía Digital" 5 "Turismo"

*Other classification of sectors (1-2-4 same than previous classification)	

	gen sector2_ = sector
	replace sector2_ = 4 if sector2_ == 3 // bef tradable now low-skilled 
	replace sector2_ = 3 if inlist(actividad, 45, 46, 47) ///
		& sector2_ == 4 // tradable
	replace sector2_ = 5 if inlist(actividad, 64, 65, ///
		66, 68, 69, 70, 71, 72) | inlist(actividad, 73, 74, ///
		75, 58, 59, 60, 61, 62) | inlist(63, 78, 80, 82, 84, ///
		85, 86, 87, 88) & sector2_ == 4 // before tradable now high-skilled
		
	tabulate sector2_, generate(sector2_)

*===============================================================================
	* 							Education level
*==============================================================================

** General education level 

    /* gen educ = .
    replace educ = 0 if q3_04_escuela=="No y es mayor de 20 años" | q3_04_escuela=="No y tiene 20 años o menos de edad" | q3_04_escuela=="" | q3_05_grado=="Ninguno" // Never studied
    replace educ = 1 if q3_05_grado== "Pre-escolar" | q3_05_grado== "Grado 1 (primaria ciclo 1)" ///
	| q3_05_grado== "Grado 2 (primaria ciclo 1)" | q3_05_grado== "Grado 3 (primaria ciclo 1)" 	///
	| q3_05_grado== "Grado 4 (primaria ciclo 2)"| q3_05_grado== "Grado 5 (primaria ciclo 2)" ///
	| q3_05_grado== "Grado 6 (primaria ciclo 2)" 			// preschool or incomplete primary 0,1,2,3,4,5,6
    replace educ = 2 if q3_05_grado== "ESBA 1 (Educacion Secundaria Basica)" 										///
	| q3_05_grado== "ESBA 2 (Educacion Secundaria Basica)" 										///
	| q3_05_grado== "ESBA 3 (Educacion Secundaria Basica)" 										///
	| q3_05_grado== "ESBA 4 (Educacion Secundaria Basica)"											///
	| q3_05_grado== "Bach 1 (Bachillerato)" | q3_05_grado== "Bach 2 (Bachillerato)" 	/// 11,12,13
	/* replace edu = 3 if q3_05_grado== "Bach 1 (Bachillerato)" | q3_05_grado== "Bach 2 (Bachillerato)" 	/// 11,12,13 */

    replace educ = 3 if q3_05_grado== "Formación técnica y profesional básica" 					///
	| q3_05_grado== "Formación técnica y profesional avanzada" 									///complete primary or incomplete secondary
	| q3_05_grado== "Formación Universitaria (no egresado)" 										// 14 15 16 
    replace educ = 4 if q3_05_grado== "Diplomado No universitario" 								///
	| q3_05_grado== "Graduado Universitario (Licenciado, Ingeniero, otro)" 						///
	| q3_05_grado== "Post grado (Maestria, PhD/ Doctorado)" 									// 17 18 19 Post-secondary: diploma, undergraduate or postgraduate


	label define grado_es 99 "No reporta" 0 "Ninguno" 1 "Primaria" 2 "Secundaria Básica" 3 "Bachillerato" 4  "Formación Técnica" 5 "Pregrado/postgrado"
	label define grado_en 99 "No report" 0 "None" 1 "Primary" 2 "Basic Secondary" 3 "High School" 4 "Technical Training" 5 "Undergraduate/Postgraduate"
	tab q1_03_edad if educ==99, missing
	tab educ,gen(educc) */

	gen educ = .
    replace educ = 0 if q3_04_escuela=="No y es mayor de 20 años" | q3_04_escuela=="No y tiene 20 años o menos de edad" | q3_04_escuela=="" | q3_05_grado=="Ninguno" // Never studied
    replace educ = 1 if q3_05_grado== "Pre-escolar" | q3_05_grado== "Grado 1 (primaria ciclo 1)" ///
	| q3_05_grado== "Grado 2 (primaria ciclo 1)" | q3_05_grado== "Grado 3 (primaria ciclo 1)" 	///
	| q3_05_grado== "Grado 4 (primaria ciclo 2)"| q3_05_grado== "Grado 5 (primaria ciclo 2)" 	// preschool or incomplete primary 0,1,2,3,4,5,6
    replace educ = 2 if q3_05_grado== "Grado 6 (primaria ciclo 2)" 								///
	| q3_05_grado== "ESBA 1 (Educacion Secundaria Basica)" 										///
	| q3_05_grado== "ESBA 2 (Educacion Secundaria Basica)" 										///
	| q3_05_grado== "ESBA 3 (Educacion Secundaria Basica)" 										///
	| q3_05_grado== "ESBA 4 (Educacion Secundaria Basica)"											///
	| q3_05_grado== "Bach 1 (Bachillerato)" | q3_05_grado== "Bach 2 (Bachillerato)" 	/// 11,12,13
	/* replace edu = 3 if q3_05_grado== "Bach 1 (Bachillerato)" | q3_05_grado== "Bach 2 (Bachillerato)" 	/// 11,12,13 */

    replace educ = 3 if q3_05_grado== "Formación técnica y profesional básica" 					///
	| q3_05_grado== "Formación técnica y profesional avanzada" 									///complete primary or incomplete secondary
	| q3_05_grado== "Formación Universitaria (no egresado)" 										// 14 15 16 
    replace educ = 4 if q3_05_grado== "Diplomado No universitario" 								///
	| q3_05_grado== "Graduado Universitario (Licenciado, Ingeniero, otro)" 						///
	| q3_05_grado== "Post grado (Maestria, PhD/ Doctorado)" 									// 17 18 19 Post-secondary: diploma, undergraduate or postgraduate


	label define grado_es 99 "No reporta" 0 "Ninguno" 1 "Primaria" 2 "Secundaria Básica" 3 "Bachillerato" 4  "Formación Técnica" 5 "Pregrado/postgrado"
	label define grado_en 99 "No report" 0 "None" 1 "Primary" 2 "Basic Secondary" 3 "High School" 4 "Technical Training" 5 "Undergraduate/Postgraduate"
	tab q1_03_edad if educ==99, missing
	tab educ,gen(educc)

** Education level aggregated

	gen educc_agg = .
    replace educc_agg = 1 if educc1 == 1 | educc2 == 1 // Primaria o inferior
    replace educc_agg = 2 if educc3 == 1 // Secundaria o inferior
    replace educc_agg = 3 if educc4 == 1 | educc5 ==1 // Terciaria
    tab educc_agg, gen(educc_agg)


** Years of schooling 

	gen anos_educacion = 0

	replace anos_educacion = 3 if q3_05_grado == "Pre-escolar" // = 3 años
	replace anos_educacion = 4 if q3_05_grado == "Grado 1 (primaria ciclo 1)" //  4 años
	replace anos_educacion = 5 if q3_05_grado == "Grado 2 (primaria ciclo 1)"   // 5 años
	replace anos_educacion = 6 if q3_05_grado == "Grado 3 (primaria ciclo 1)"   // 6 años
	replace anos_educacion = 7 if q3_05_grado == "Grado 4 (primaria ciclo 2)"   // 7 años
	replace anos_educacion = 8 if q3_05_grado == "Grado 5 (primaria ciclo 2)"   //  8 años
	replace anos_educacion = 9 if q3_05_grado == "Grado 6 (primaria ciclo 2)"   // 9 años
	replace anos_educacion = 10 if q3_05_grado == "ESBA 1 (Educacion Secundaria Basica)"  // 10 años
	replace anos_educacion = 11 if q3_05_grado == "ESBA 2 (Educacion Secundaria Basica)"  // 11 años
	replace anos_educacion = 12 if q3_05_grado == "ESBA 3 (Educacion Secundaria Basica)" // 12 años
	replace anos_educacion = 13 if q3_05_grado == "ESBA 4 (Educacion Secundaria Basica)" // 13 años
	replace anos_educacion = 14 if q3_05_grado == "Bach 1 (Bachillerato)" // 14 años
	replace anos_educacion = 15 if q3_05_grado == "Bach 2 (Bachillerato)" // 15 años
	replace anos_educacion = 17 if q3_05_grado == "Formación técnica y profesional básica" // 17 años
	replace anos_educacion = 19 if q3_05_grado == "Formación técnica y profesional avanzada" // 19 años
	replace anos_educacion = 17 if q3_05_grado == "Formación Universitaria (no egresado)" // 17 años
	replace anos_educacion = 18 if q3_05_grado == "Diplomado No universitario" // 18 años
	replace anos_educacion = 19 if q3_05_grado == "Graduado Universitario (Licenciado, Ingeniero, otro)" // 19 años
	replace anos_educacion = 21 if q3_05_grado == "Post grado (Maestria, PhD/ Doctorado)" // 21 años



*===============================================================================
	* 							Size of company 
*==============================================================================

** Tamaño de empresa para Empresario y Trabajadores Autónomos para ocupaciones principal y secundaria

	gen cuenta_p = q5_18_ocupacionPrincipal == "Independiente/Autónomo" | q5_18_ocupacionPrincipal == "Empresario (Propietario)"
	gen t1_10 = q5_23_nombrePersonas == 1 | q5_23_nombrePersonas == 2
	replace t1_10 = 0 if q5_18_ocupacionPrincipal == "Independiente/Autónomo" | q5_18_ocupacionPrincipal == "Empresario (Propietario)"
	gen t11_50 = q5_23_nombrePersonas == 3 | q5_23_nombrePersonas == 4
	gen t51_mas = inlist(q5_23_nombrePersonas, 5, 6, 7)

	gen firm = 0
	replace firm = 1 if cuenta_p == 1
	replace firm = 2 if t1_10 == 1
	replace firm = 3 if t11_50 == 1
	replace firm = 4 if t51_mas == 1

	label define firm_es 0 "General" 1 "Cuenta Propia" 2 "Firma 2-10 empleados" 3 "Firma 11-50 empleados" 4 "Firma 50+ empleados"
	label define firm_en 0 "General" 1 "Self-employed" 2 "Firm 2-10 employees" 3 "Firm 11-50 employees" 4 "Firm 50+ employees"
		
	save "${gdOutput}/ENH2_base.dta", replace

	/* keep if q1_03_edad>=16 & q1_03_edad<=64 // edad trabajar
	keep if oci==1 //ocupados */

*===============================================================================
	* 							Hours worked
*==============================================================================

/* expand 2, gen(dup)
sort interview__key idi dup

gen idj = 1 if dup==0
replace idj = 2 if dup==1
order interview__key idi idj dup */

** Correccion de horas semanales mal sumadas
	egen check_horas_prin = rowtotal(princ_hrs_trab_Lunes princ_hrs_trab_Martes princ_hrs_trab_Miercoles princ_hrs_trab_Jueves princ_hrs_trab_Viernes princ_hrs_trab_Sabado princ_hrs_trab_Domingo)
	replace totalHorasPrincipal= check_horas_prin if princ_hrs_trab_Lunes!=. & check_horas_prin!=0 & totalHorasPrincipal!= check_horas_prin 

	egen check_horas_secu = rowtotal(secund_hrs_trab_Lunes secund_hrs_trab_Martes secund_hrs_trab_Miercoles secund_hrs_trab_Jueves secund_hrs_trab_Viernes secund_hrs_trab_Sabado secund_hrs_trab_Domingo)
	replace totalHorasSecundaria= check_horas_secu if secund_hrs_trab_Lunes!=. & check_horas_secu!=0 & totalHorasSecundaria!= check_horas_secu

** Si horas trabajadas la semana pasada en ocupaciones principal y secundaria==., se usa variable horas habituales trabajadas
	replace totalHorasPrincipal = q5_66_horasHabituales if q5_65_trabajoHorasHabituales==2 & q5_38_otroEmpleo==2 & q5_66_horasHabituales>0
	
	
** Calculo de horas (mediana) para imputar valores faltantes
preserve
	keep if q5_17_codigo_nuevo!=.
	collapse (median)  totalHorasPrincipal, by(Section_job_prin)
	rename (totalHorasPrincipal) (horas_prin_impu)
		tempfile HorasPrin
		save `HorasPrin', replace	
restore


preserve
	keep if q5_40_codigo_nuevo!="" & q5_38_otroEmpleo==1
	collapse (median)  totalHorasSecundaria, by(Section_job_sec)
	rename (totalHorasSecundaria) (horas_sec_impu)
		tempfile HorasSecund
		save `HorasSecund', replace	
restore

	merge m:1 Section_job_prin  using `HorasPrin', gen(merge_input1)
	merge m:1 Section_job_sec  using `HorasSecund', gen(merge_input2)

** Corrigiendo valor máximo de horas. Para act princiiapl no mayor a 112 y secundaria no mayor a 60
	replace totalHorasPrincipal = 112 if totalHorasPrincipal>112 & Section_job_prin!=""
	replace totalHorasSecundaria = 60 if totalHorasSecundaria>60 & Section_job_sec!=""

** Corrigiendo valores que estaban en cero, se cambian por la mediana del sector y tipo de cargo -Trabajo Principal y secundario

	** Variable con valores imputados 
		replace horas_prin_impu = totalHorasPrincipal if totalHorasPrincipal!=0
		replace horas_sec_impu = totalHorasSecundaria if totalHorasSecundaria!=0
		egen total_hr_impu = rowtotal(horas_prin_impu horas_sec_impu)  

	** Variable sin imputados 
		egen total_hr = rowtotal(totalHorasPrincipal totalHorasSecundaria)


** Calculando valor anual	
	replace total_hr_impu = total_hr_impu*52
	replace total_hr = total_hr*52
	/* drop if q5_38_otroEmpleo==2 & idj ==2 */
	/* drop if q5_38_otroEmpleo==1 & totalHorasSecundaria==0 & idj ==2 // 9743  */


** La base de datos pide que el valor máximo sean 5840 horas, aprox 16 horas diarias = 121.3 horas semanales
** Los casos que sobrepasan estas horas se llevan al valor de 5840. Para ellos se resta la diferencia, manteniendeo en cuenta la proporción de horas 
* por trabajo principal y secundario

replace total_hr =  5840 if total_hr>5840 & total_hr!=.
replace total_hr = round(total_hr) 


lab var female 		"Share of female worker"
lab var age 		"Mean age of workers"
lab var agesq 		"Mean age squared of workers"
lab var educ 		"Level of education of workers"
lab var sector_1 	"Share of workers in Agriculture"
lab var sector_2 	"Share of workers in Manufacture"
lab var sector_3 	"Share of workers in Services"

/* lab var rural 		"Live in rural areas" */


	cap keep `id_vars' codigoMiembro2 codigoMiembro3 codigoMiembro4 q5_17_codigo q5_40_codigo q5_39_codigo q5_16_codigo Sección_actividad HN Sección_activ1 Sección_activ q5_38_otroEmpleo q5_01A_trabajo1horaCazando q5_01_trabajo1horaCampo q5_02_trabajo1horaHogar q5_03_trabajo1horaJefe q5_04_trabajo1horaAprendiz q5_06_trabajo_a_volver q5_18_ocupacionPrincipal q5_41_ocupacionSecundaria q1_02_sexo q3_04_escuela q3_05_grado princ_hrs_trab_Lunes princ_hrs_trab_Martes princ_hrs_trab_Miercoles princ_hrs_trab_Jueves princ_hrs_trab_Viernes princ_hrs_trab_Sabado princ_hrs_trab_Domingo totalHorasPrincipal secund_hrs_trab_Lunes secund_hrs_trab_Martes secund_hrs_trab_Miercoles secund_hrs_trab_Jueves secund_hrs_trab_Viernes secund_hrs_trab_Sabado secund_hrs_trab_Domingo q5_65_trabajoHorasHabituales q5_66_horasHabituales q5_38_otroEmpleo totalHorasSecundaria q10_01_salarioPrincipal q10_03_boniPrincipal q10_05_beneficios q10_08_salarioSecundaria q10_10_boniSecundaria q10_12_beneficios q10_01_frecuencia q10_03_frecuencia q10_05_frecuencia q10_08_frecuencia q10_10_frecuencia q10_12_frecuencia q5_05_trabajo1hora q5_01_trabajo1horaCampo q5_02_trabajo1horaHogar q5_03_trabajo1horaJefe q5_04_trabajo1horaAprendiz q5_23_nombrePersonas q5_46_nombrePersonas

save "${gdData_7L}/7Labor_base1-0.dta", replace // base ocupados 






