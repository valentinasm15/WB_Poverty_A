*===============================================================================  
* Author: Valentina S
* Date: 	
* Title: 
*===============================================================================

/* local survey_hh "2.- BASE DE DATOS DE VIVIENDA REFORMAS Y RECURSOS.dta"
local survey_ind "1.- BASE DE DATOS DE MIEMBROS PROFESIONALES Y HORAS TRABAJADAS.dta */
/* local survey_ind "Auxiliary/Nov_11_2024/inege_nov.dta" */
local id_vars "cod_region cod_provincia cod_distrito cod_MU_DU interview__key"

*===============================================================================
						* Household Information Prep
*===============================================================================

	use "${gdOutput}/ENH2_base.dta", clear // created in 1-0.cleaning_7.do. It uses data from Nov - Inege

** Weights
	clonevar hhweight=weight_h	
	gen hhweight_v=hhweight*hhsize

** Poverty line
	gen zref2=810000 // so poverty is 50.7%
	rename zref2 pline

** Consumption
	clonevar consumo_pc=welfare 

	xtile quintile = consumo_pc [aw = hhsize*hhweight_v], nq(5) // 
	label def quintile 1 "Quintile 1" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Quintile 5", replace
	label val quintile quintile

    tab quintile, gen(quintile_)
	
    label var quintile_1 "Poorest 20"
    label var quintile_2 "Q2"
    label var quintile_3 "Q3"
    label var quintile_4 "Q4"
    label var quintile_5 "Richest 20"
        
    gen poorest = (quintile_1 == 1 | quintile_2 == 1)
    label var poorest "bottom 40 (poorest)"
	
** Urban - Rural
	rename cod_CV_CP milieu

	decode cod_provincia, gen(provincia_)

	rename region region_str
	gen region ="1" 
	replace region="2" if region_str=="Continental"

	tempfile welfare_prep
	save `welfare_prep'


*===============================================================================
					* Demographic information + other
*===============================================================================

** Dependancy ratio by household
    gen num = (age < 15 | age > 64) if !missing(age)
    gen deno = (age >= 15 & age <= 64) if !missing(age)
        
    bysort interview__key : egen hh_num = total(num),m
    bysort interview__key : egen hh_deno = total(deno),m


    gen under_5 = (age < 5)
    bysort interview__key : egen num_children = total(under_5)
    label var num_children "Number of children under 5"	

    gen dep_ratio = hh_num / hh_deno
    label var dep_ratio "Dependancy ratio" 
            
    gen under_15 = (age < 15)
    bysort interview__key : egen num_under_15 = total(under_15)
    label var num_under_15 "Number of children under 15"		

    gen over_65 = (age >= 65)
    bysort interview__key : egen num_over_65 = total(over_65)
    label var num_over_65 "Number of individual 65 and over"	
            
    gen dependant = (age < 15 | age > 64)
            
    bysort interview__key : egen num_dependant = total(dependant)
    label var num_dependant "Number of dependants in the household"

    gen n_surp=hhsize/q2_20_numDormitorios
    gen dep_surp = (n_surp > 3)
    label var dep_surp "More than 3 individual per room"

** Head of household	

    gen unemployed = 1 if PD==1 & q1_04_parentesco=="Jefe/a del Hogar"
    bysort interview__key : egen hhhead_unemployed = max(unemployed)
    label var hhhead_unemployed "HH. head is unemployed"
	replace hhhead_unemployed=0 if hhhead_unemployed==. 

    gen biz_owner = (q5_18_ocupacionPrincipal_ == 3 | q5_41_ocupacionSecundaria ==3 & q1_04_parentesco=="Jefe/a del Hogar") 
    bysort interview__key : egen hhhead_biz_owner = max(biz_owner)
    label var hhhead_biz_owner "HH. head is a business owner"
	replace hhhead_biz_owner=0 if hhhead_biz_owner==.

	clonevar hgender = q1_02_sexo
	gen hmale = (hgender == "Masculino" & q1_04_parentesco=="Jefe/a del Hogar")
    bysort interview__key : egen head_male = max(hmale)
	label var head_male "Head is male" 

	gen hfemale = (hgender == "Femenino" & q1_04_parentesco=="Jefe/a del Hogar")
    bysort interview__key : egen head_female = max(hfemale)
	label var head_female "Head is female"	

*===============================================================================
				* Occupation - Sector of employment household
*===============================================================================

	bysort interview__key: egen sector_three = max(gsector)
	tab sector_three, gen(sector_three_)


	label var sector_three_1 "Agriculture"
	label var sector_three_2 "Industry"
	label var sector_three_3 "Services"

	replace sector_three = 0 if sector_three==.
	replace sector_three_1 = 0 if sector_three_1==.
	replace sector_three_2 = 0 if sector_three_2==.
	replace sector_three_3 = 0 if sector_three_3==.

    gen agri = (gsector == 1)
    label define agri 1 "Agriculture" 0 "Not in agriculture", replace
    label values agri agri
    label var agri "Household head in agriculture"


*===============================================================================
						* Education - Sector of household
*===============================================================================
	gen heduc = q3_05_grado

    gen hh_edu = educ 
    replace hh_edu = 3 if educ==4
	bysort interview__key : egen head_edu = max(hh_edu)

	label define head_edu 0 "None" 1 "Primary" 2 " Secondary" 3 "Tertiary", replace
	label val head_edu head_edu


	gen head_secondary = 0 
    replace head_secondary = 1 if inlist(educ, 2,3,4) 					    // at least basic secondary
	label var head_secondary "Head has at least Basic Secondary education level"

	/* replace heduc = 0 if heduc ==. */

    gen education = educ

    /* label define education 0 "None" 1 "Primary" 2 "Basic Secondary" 3 "High School" 4 "Technical Training" 5 "Undergraduate/Postgraduate" */

	/* recode heduc (0 = 0) (1 = 1) (2/3 =  = 2) (4 = 3), gen(education) */

    gen educyrs = anos_educacion
	bysort interview__key : egen hheducyrs = max(educyrs)
    label var hheducyrs "Year of schooling of head"

    replace hheducyrs=0 if hheducyrs==.

    gen qhheducyrs = hheducyrs*hheducyrs
    label var qhheducyrs "Squared of year of schooling of head"

/* keep if q1_04_parentesco==1 */

*===============================================================================
						* Household assets and conditions
*===============================================================================

**** Assets 

gen hh_internet = (q9_11_gastos3__318 == 1) // pay for internet doesn't necessarily mean access
label var hh_internet "Household has access to internet"

gen hh_car = (q6_01_bienesDurables__126 == 1) 
label var hh_car "Household owns a car" 

gen hh_motobike = (q6_01_bienesDurables__127 == 1) 
label var hh_motobike "Household owns a motobike" 

gen hh_stove = (q6_01_bienesDurables__109 == 1) 
label var hh_car "Household owns a stove"

gen hh_fridge = (q6_01_bienesDurables__114 == 1) 
label var hh_fridge "Household owns a fridge"

gen hh_freezer = (q6_01_bienesDurables__115 == 1) 
label var hh_freezer "Household owns a freezer"

gen hh_microwave = (q6_01_bienesDurables__111 == 1) 
label var hh_microwave "Household owns a microwave"

gen hh_washer = (q6_01_bienesDurables__123 == 1) 
label var hh_washer "Household owns a washing machine"

gen hh_heater = (q6_01_bienesDurables__144 == 1) 
label var hh_heater "Household owns a water heater"

gen hh_aircond = (q6_01_bienesDurables__125 == 1) 
label var hh_aircond "Household owns an air conditioner"

gen hh_fan = (q6_01_bienesDurables__116 == 1) 
label var hh_fan "Household owns a fan"

gen hh_vacuum = (q6_01_bienesDurables__124 == 1) 
label var hh_vacuum "Household owns a vacuum cleaner"

gen hh_iron = (q6_01_bienesDurables__107 == 1) 
label var hh_iron "Household owns an iron"

gen hh_boat = (q6_01_bienesDurables__143 == 1) 
label var hh_boat "Household owns a small boat" 

gen hh_otherland = (q6_01_bienesDurables__142 == 1) 
label var hh_otherland "Household owns Other type of land"  

recode  q2_01_tenencia (1/3= 1) (nonmissing = 0), gen(hh_land)
label var hh_land "Household owns Housing land"

gen commerce = (q5_21_lugar == "En local propio o arrendado" ) 
bysort interview__key : egen hh_commerce = max(commerce)
label var hh_commerce "Household owns space for commerce(shop) or workshop" 

merge m:1 interview__key using "${gdData}/Household surveys/ENH2/19.- BASE DE DATOS DE EXPLOTACIONES Y PARCELAS_hh.dta", nogen

gen hh_health_prep=0
replace hh_health_prep= 1 if q4_14_seguro =="Sí, ambos" | q4_14_seguro =="Sí, privado" | q4_14_seguro =="Sí, público"
bysort interview__key : egen hh_health_ins = max(hh_health_prep)
label define hh_health_ins 1 "HH covered health insurance" 0 "HH doesn't have health insurance", replace


**** Services

recode q2_25_aguaTomar (1 2 3 4 6 7 = 1) (nonmissing = 0), gen(drinking_water)
label var drinking_water "Household has access to drinking water"

recode q2_31_energiaLuz (1 2 = 1) (nonmissing = 0) , gen(electricity) 
label var electricity "Household has access to electricity"

recode q2_28_aseo (1/2 = 1 ) (nonmissing = 0), gen(imp_san_rec)
label var imp_san_rec "Household has improved sanitation"

**** Household conditions 

gen hh_safe_flooding = (q2_16_problemas__1 == 0 | q2_16_problemas__5 == 0 | q2_16_problemas__6 == 0 | q2_16_problemas__9 == 0) 
label var hh_safe_flooding "Low danger of flooding when it rains due to household infra"

gen hh_safe_landslide = (q2_16_problemas__10 == 0) 
label var hh_safe_landslide "Low danger of landslide"

gen log = 1
egen sum_house_quality=rowtotal(q2_16_problemas__*)
replace log=0 if sum_house_quality >= 3
bysort interview__key: egen logement = max(log)
label var logement "Good quality of housing"



tempfile household_level
save `household_level'

*===============================================================================
						* Community level information
*===============================================================================

/* use "${gdData}/Household surveys/ENH2/`survey_hh'" , clear 
merge 1:m interview__key  using "${gdData}/Household surveys/ENH2/`survey_ind'" */

recode q2_34_basura (5 8= 1) (nonmissing = 0), gen(c_dumpsite)
label var c_dumpsite "Community is near a dump" 

recode q2_17_acceso (1= 1) (nonmissing = 0), gen(c_pavstr)
replace c_pavstr=1 if q2_18_distCarreteraM <100
label var c_pavstr "Community is near a paved street" 

recode q2_16_problemas__10 (1= 1) (2 = 0), gen(c_landslide)
label var c_landslide "Community is near a Landside"

recode q2_25_aguaTomar (1 2 3 4 6 7 = 1) (nonmissing = 0), gen(c_water)
replace c_water=0 if  q2_26_distAguaMinutos > 10
label var c_water "Community has access to water"

recode q2_31_energiaLuz (1/2= 1) (nonmissing = 0), gen(c_elec)
label var c_elec "Community has access to a reliable elec source"

recode q2_34_basura (1/2= 1) (nonmissing = 0), gen(c_garbage)
label var c_garbage "Community has access to Gabbage collection"

gen c_transport = ( q5_32_transporte =="Autobús público" | q5_55_transporte ==2  | q9_01_gastos2__211==1 | q3_15B_medioTransporte==4)
label var c_transport "Community has access to public transport"

recode educ (1/2= 1) (nonmissing = 0), gen(c_edu)
label var c_edu "Community has access to education"

recode hh_health_ins (1= 1) (nonmissing = 0), gen(c_health)
label var c_health "Community has access to health services"

local community_vars  c_dumpsite c_pavstr c_landslide c_water c_elec  c_garbage c_transport c_edu c_health


** without weights
	collapse (mean) `community_vars', by(cod_MU_DU)

	tempfile community
	save `community'

	merge 1:m cod_MU_DU using `household_level'
	drop _m

	sort `id_vars'

*===============================================================================
						* Poverty Lines definition
*===============================================================================

	cap rename sector_three head_branch
	keep if q1_04_parentesco=="Jefe/a del Hogar"
 
	drop region 
	clonevar region = cod_region

 foreach var of varlist quintile milieu region hgender education {
		gen `var'_string=""
		qui levelsof `var', local(lev)
		foreach cc of local lev {
			cap loc la_`cc': label(`var') `cc'
			if !_rc {
				replace `var'_string ="`cc'-`la_`cc''" if `var' ==`cc'
			}
		}  
	 }


local hh_vars milieu quintile head_edu cod_provincia head_branch hhsize rural num_under_15 head_female hheducyrs hhhead_biz_owner hhhead_unemployed drinking_water sector_three_1 sector_three_2 sector_three_3 hh_internet  hh_fan hh_otherland hh_safe_flooding hh_aircond hh_iron hh_boat hh_commerce imp_san_rec hh_stove hh_health_ins hh_safe_landslide logement

foreach var of local hh_vars {
    // Check for missing values
    capture assert !missing(`var')
    if _rc {
        di as error "`var' has missing values."
    }
    
    egen min_`var' = min(`var'), by(interview__key)
    egen max_`var' = max(`var'), by(interview__key)
    capture assert min_`var' == max_`var'
    if _rc {
        di as error "`var' is not consistent within households."
        /* list interview__key `var' if min_`var' != max_`var', sepby(interview__key) */
    }
    
    // Drop temporary variables
    drop min_`var' max_`var'
}



drop if hhsize==.
replace sector_three_1=0 if sector_three_1==.
replace head_branch=99 if head_branch==.
drop if hh_health_ins==.

save "$gdData_3EI/prep_data_${year}$n", replace









