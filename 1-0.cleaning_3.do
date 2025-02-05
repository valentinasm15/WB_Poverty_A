*===============================================================================  
* Author: Valentina S
* Date: 	
* Title: Adjusted cleaning from CPV 
*===============================================================================

local survey_hh "2.- BASE DE DATOS DE VIVIENDA REFORMAS Y RECURSOS.dta"
local survey_ind "1.- BASE DE DATOS DE MIEMBROS PROFESIONALES Y HORAS TRABAJADAS.dta"
/* local survey_ind "Auxiliary/Nov_11_2024/inege_nov.dta" */
local id_vars "cod_region cod_provincia cod_distrito cod_MU_DU interview__key"

*===============================================================================
						* Household Information Prep
*===============================================================================

	use "${gdData}/Household surveys/ENH2/`survey_hh'", clear

	merge 1:1 interview__key using "${gdData}/Household surveys/ENH2/Welfare-measurement/GNQ_enh2_welfare.dta", keep(matched) nogen // adding poverty variables and weights 
	order `id_vars'
	sort `id_vars'

** Weights
	clonevar hhweight=weight_h

** Poverty line
	gen zref2=810000 // so poverty is 50.7%

** Consumption
	clonevar consumo_pc=welfare 

	xtile quintile = consumo_pc [aw = hhsize*hhweight], nq(5) // 
	label def quintile 1 "Quintile 1" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Quintile 5", replace
	label val quintile quintile
	
** Urban - Rural
	label def urban 1 "Urban" 2 "Rural"
	label val cod_CV_CP urban	

	rename cod_CV_CP milieu

	tempfile welfare_prep
	save `welfare_prep'

*===============================================================================
						* Individual information 
*===============================================================================

** Head of household
	use "${gdData}/Household surveys/ENH2/`survey_ind'", clear

	clonevar hgender = q1_02_sexo
	gen head_male = (hgender == 1 & q1_04_parentesco==1)
	label var head_male "Head is male" 

	gen head_female = (hgender == 2 & q1_04_parentesco==1)
	label var head_female "Head is female"	

** Education - Head of household

	gen head_secondary = (q3_05_grado  >= 11) // Basic Secondary
	label var head_secondary "Head has at least Basic Secondary education level"

	gen heduc = q3_05_grado
	replace heduc = 0 if heduc ==.

	recode heduc (0 = 0) (1/7 = 1) (8/13 = 2) (14/19= 3), gen(education)
	label define education 0 "None" 1 "Primary" 2 " Secondary" 3 "Tertiary", replace
	label val education education

	keep if q1_04_parentesco==1

	merge 1:1 interview__key using `welfare_prep', nogen // Head info at household level 

	keep `id_vars' hhsize codigoMiembro1 hhweight milieu region quintile  zref2 hgender head_male head_female head_secondary heduc education milieu consumo_pc 

	tempfile welfare
	save `welfare'

*===============================================================================
						* Occupation - Sector of household
*===============================================================================

/* import excel using "$data_p/Clasificador de ocupaciones de la ENH2 _CEGOC.xls", sheet(codes) first clear 
save "$data_p/Clasificador de ocupaciones de la ENH2 _CEGOC", replace */

	use "${gdData}/Household surveys/ENH2/CIIU_code.dta",clear 

** Identifying the sector of main activity

	gen hhsector_ind = substr(q5_16_codigo_nuevo, 1, 1)
	replace hhsector_ind = "" if hhsector_ind=="X"

	destring hhsector_ind, replace
	replace hhsector_ind=99 if hhsector_ind==.

	keep if codigoMiembro4==1
	duplicates report interview__key codigoMiembro4
	
	recode hhsector_ind (6=1)(7 8 9=2) (1 2 3 4 5 = 3) (99 =99), gen(sector_three_ind)

	bysort interview__key: egen sector_three = max(sector_three_ind)

	replace sector_three= 3 if hhsector_ind ==0 // Military forces
	tab sector_three, gen(sector_three_)
	label var sector_three_1 "Agriculture"
	label var sector_three_2 "Industry"
	label var sector_three_3 "Services"
	/* label var sector_three_4 "Other" */



	label def sector_three 1 "Agriculture"  2 "Industry" 3 "Services" 4 "Other", replace
	label val sector_three sector_three

	rename codigoMiembro4 codigoMiembro1
	duplicates report interview__key codigoMiembro1
	sort interview__key codigoMiembro1
	duplicates tag interview__key codigoMiembro1, generate(dup_flag)
	drop if dup_flag > 0
	duplicates report interview__key codigoMiembro1
/* keep if q1_04_parentesco==1 */

/* keep `id_vars' q5_16_codigo codigoMiembro1  hhsector sector_three sector_three_*  */

tempfile sector
save `sector'


*===============================================================================
						* Education - Sector of household
*===============================================================================

use "${gdData}/Household surveys/ENH2/`survey_ind'", clear

gen hheducyrs = q3_05_grado
label var hheducyrs "Year of schooling of head"

replace hheducyrs=0 if hheducyrs==./* missing values are 0 | tab q3_04_escuela if hheducyrs==. */


gen qhheducyrs = hheducyrs*hheducyrs
label var qhheducyrs "Squared of year of schooling of head"


/* keep `id_vars' q3_05_grado hheducyrs qhheducyrs q1_03_edad codigoMiembro1 q1_04_parentesco q5_41_ocupacionSecundaria q5_38_otroEmpleo q5_18_ocupacionPrincipal q5_10_buscoTrabajoRemunerado q5_06_trabajo_a_volver q5_21_lugar q5_44_lugar q4_14_seguro */

tempfile educ
save `educ'

gen age = q1_03_edad

****  Dependancy ratio by household
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

/* keep if q1_04_parentesco==1 */

tempfile indiv
save `indiv'

merge 1:1 interview__key codigoMiembro1 using `sector'
drop _m


gen agri = (hhsector_ind == 6)
label define agri 1 "Agriculture" 0 "Not in agriculture", replace
label values agri agri
label var agri "Household head in agriculture"

merge m:1 interview__key using "${gdData}/Household surveys/ENH2/`survey_hh'"
save "$gdTemp/hh_survey.dta", replace
drop _m


*===============================================================================
						* Household assets and conditions
*===============================================================================

**** Assets 

gen hh_internet = (q9_11_gastos3__318 == 1) // pay for internet doesn't necessarily mean 
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

gen hh_commerce = (q5_21_lugar == 2 ) 
label var hh_commerce "Household owns space for commerce(shop) or workshop" 

merge m:1 interview__key using "${gdData}/Household surveys/ENH2/19.- BASE DE DATOS DE EXPLOTACIONES Y PARCELAS_hh.dta",nogen

recode q4_14_seguro (1/3=1) (nonmissing = 0), gen(hh_health_prep) 
bysort interview__key : egen hh_health_ins = max(hh_health_prep)
label define hh_health_ins 1 "HH covered health insurance" 0 "HH doesn't have health insurance", replace


merge m:1 interview__key using "${gdData}/Household surveys/ENH2/`survey_hh'", nogen

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


order `id_vars'
sort `id_vars'
duplicates report interview__key codigoMiembro1

merge m:1 interview__key codigoMiembro1 using `welfare'
drop _m

gen n_surp=hhsize/q2_20_numDormitorios
gen dep_surp = (n_surp > 3)
label var dep_surp "More than 3 individual per room"	

gen hhhead_unemployed = (q5_06_trabajo_a_volver == 2 & q5_10_buscoTrabajoRemunerado ==1 | q5_10_buscoTrabajoRemunerado ==2)
label var hhhead_unemployed "HH. head is unemployed"

gen hhhead_biz_owner = (q5_18_ocupacionPrincipal == 3 | q5_38_otroEmpleo == 11 & q5_41_ocupacionSecundaria ==3)
label var hhhead_biz_owner "HH. head is a business owner"

keep if q1_04_parentesco==1

merge m:1 interview__key codigoMiembro1 using `educ', nogen
keep if q1_04_parentesco==1

/* tab hhsector, gen(sector_) */
	
tab quintile, gen(quintile_)
	
label var quintile_1 "Poorest 20"
label var quintile_2 "Q2"
label var quintile_3 "Q3"
label var quintile_4 "Q4"
label var quintile_5 "Richest 20"
	
gen poorest = (quintile_1 == 1 | quintile_2 == 1)
label var poorest "bottom 40 (poorest)"

/* keep `id_vars' codigoMiembro1 num_under_15 hhhead_unemployed hhhead_biz_owner hh_livestock  q2_20_numDormitorios  hh_internet hh_car hh_motobike hh_stove hh_fridge hh_freezer hh_microwave hh_washer hh_heater hh_aircond hh_fan hh_vacuum hh_iron hh_boat hh_otherland hh_land hh_commerce hh_health_ins drinking_water electricity imp_san_rec hh_flooding hh_landslide_danger log hh_fragil_infra */
keep `id_vars' codigoMiembro1 num_under_15 hhhead_unemployed hhhead_biz_owner   q2_20_numDormitorios  hh_internet hh_car hh_motobike hh_stove hh_fridge hh_freezer hh_microwave hh_washer hh_heater hh_aircond hh_fan hh_vacuum hh_iron hh_boat hh_otherland hh_land hh_commerce hh_health_ins drinking_water electricity imp_san_rec hh_safe_landslide hh_safe_flooding log

merge m:1 interview__key codigoMiembro1 using `educ', nogen
keep if q1_04_parentesco==1
merge 1:1 interview__key using `welfare', nogen
merge 1:1 interview__key codigoMiembro1 using `sector',nogen

tempfile household_level
save `household_level'


*===============================================================================
						* Community level information
*===============================================================================

use "${gdData}/Household surveys/ENH2/`survey_hh'" , clear 
merge 1:m interview__key  using "${gdData}/Household surveys/ENH2/`survey_ind'"

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

gen c_transport = ( q5_32_transporte ==4 | q5_55_transporte ==4 | q9_01_gastos2__211==1 | q3_15B_medioTransporte==4)
label var c_transport "Community has access to public transport"

recode q3_05_grado (1/13= 1) (nonmissing = 0), gen(c_edu)
label var c_edu "Community has access to education"

recode q4_14_seguro (1/3= 1) (nonmissing = 0), gen(c_health)
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

	rename zref2 pline

	gen hhweight_v=hhweight*hhsize

	gen rural = (milieu==2)

	cap rename sector_three head_branch

	decode cod_provincia, gen(provincia_)

	rename region region_str
	gen region ="1" 
	replace region="2" if region_str=="Continental"

	recode heduc (0 = 0) (1/7 = 1) (8/13 = 2) (14/19= 3), gen(head_edu)
	label define head_edu 0 "None" 1 "Primary" 2 " Secondary" 3 "Tertiary", replace
	label val head_edu head_edu

keep if q1_04_parentesco==1
 
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



local hh_vars milieu quintile head_edu cod_provincia head_branch hhsize rural num_under_15 head_female hheducyrs hhhead_biz_owner hhhead_unemployed drinking_water sector_three_1 sector_three_2 sector_three_3 hh_internet  hh_fan hh_otherland hh_safe_flooding hh_aircond hh_iron hh_boat hh_commerce imp_san_rec hh_stove hh_health_ins hh_safe_landslide 

drop if hhsize==.
drop if milieu==.
drop if head_branch==.
replace sector_three_1=0 if sector_three_1==.
replace sector_three_2=0 if sector_three_2==.
replace sector_three_3=0 if sector_three_3==.
replace head_branch=99 if head_branch==.
drop if hh_health_ins==.

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



save "$gdData_3EI/prep_data_${year}$n", replace









