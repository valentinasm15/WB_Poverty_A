*===============================================================================  
* Author: 
* Date: 
* Title: 
*===============================================================================

*--------------------------------------------------------------------------------
*                           Climate Change shocks computing
*-------------------------------------------------------------------------------


//---------------------------------------- Droughts (2014 2015) ---------------------------------------- //
clear
insheet using "$weather_data/concelho_cv_2010_monthly_drought_vars.csv", comma

drop gdm_* cruts405_*

* Keeping data for 2014 and 2015

local drought_var "cruts406_scpdsi_"
local years_to_drop "2016 2017 2018 2019 2020 2021 2022"

gen thr=-1.5 // Mid dry spell. Severe drought from -3 to -3.9. Extreme drought from -4 and below. A value for moderate drought is -2. From -1.5 values vary */

foreach m in jan feb mar apr may jun jul aug sep oct nov dec {
    foreach y of local years_to_drop {
    cap drop `drought_var'`m'`y'
    }
}

foreach y in 2014 2015 {
    cap des cruts406_scpdsi_*`y', varlist
    local vars_`y' `r(varlist)'
    dis "**********     `vars_`y''    ************" 

    foreach var of local vars_`y' {
        gen dr_`var'`y' = (`var' < thr)
    }
}

egen dr_2014 = rowtotal(dr_cruts406_scpdsi_*2014)
egen dr_2015 = rowtotal(dr_cruts406_scpdsi_*2015)
egen drou=rowtotal(dr_2014 dr_2015)
sum drou, detail

gen drou_cond=(drou>3)

keep cod_concel concelho dr_2014 dr_2015 drou_cond
sort cod_concel 

tempfile PDSI_drought
save `PDSI_drought', replace 



//-------------------------------------------- Floods  ------------------------------------------- //


local pluvial_var p_1in20_cons
local fluvial_var fu_1in20_cons

import delimited using  "$flood_data/CPV_pop2020UNAdjusted_pt_floodAdmin.csv",  delimiter(",") clear 

rename nome_conce concelho
tab concelho
tab cod_concel

gen fl_s=`fluvial_var'
replace fl_s=0 if `fluvial_var'==. 
gen pl_s=`pluvial_var'
replace pl_s=0 if `pluvial_var'==. 
gen pop_weather=1
collapse (max) fl_s pl_s (sum) pop_weather [iw=population], by (cod_concel concelho)
tempfile data_floods
save `data_floods', replace 

use "$data/IDRF_2015/IDRF_2015_individuo_final_recode.dta", clear 
keep poor pond_af_calibrado concelho freguesia dr vuln

ren concelho cod_concel
decode cod_concel, gen(concelho)
cap label values cod_concel .

/* merge m:1 cod_concel concelho using `data_floods', keep(matched) */
merge m:1 cod_concel using `data_floods'

gen d_fl_s=fl_s>0.5 & fl_s!=.
gen d_pl_s=pl_s>0.5 & pl_s!=.


ta vuln d_fl_s [aw=pond_af_calibrado], col nofreq
ta vuln d_pl_s [aw=pond_af_calibrado], col nofreq
/* by cod_concel, sort: egen d_fl_std = sd(d_fl_s)
by cod_concel, sort: egen d_pl_std = sd(d_pl_s)
by cod_concel, sort: egen fl_std = sd(fl_s)
by cod_concel, sort: egen pl_std = sd(pl_s) */

sum pl_s, detail
sum fl_s, detail
collapse (mean) vuln d_pl_s d_fl_s fl_s pl_s [aw=pond_af_calibrado], by(cod_concel)


gen pl_cond=(pl_s>=1.8) // 50% 
gen fl_cond=(fl_s>.79) // 75% 

tempfile floods_events
save `floods_events', replace 


merge 1:1 cod_concel  using `PDSI_drought', nogen

tempfile weather_shocks_m
save `weather_shocks_m', replace

export excel using "$data/climate_shocks/climate_shocks.xlsx", sheet("extreme_events") sheetreplace first(variables) locale(C)
save "$data/climate_shocks/climate_shocks", replace



*--------------------------------------------------------------------------------
*             Merging household survey with Climate Change shocks
*-------------------------------------------------------------------------------
*----- Getting Concelhos codes in Household survey for merge ----- *

use "$data/prep_data_${year}", clear 

cap rename concelho cod_concel
cap rename freguesia cod_fregue
cap decode cod_concel, gen(concelho)
cap decode cod_fregue, gen(freguesia)

cap label values cod_concel cod_fregue .

sort  cod_concel dr id_menage
order  concelho cod_concel freguesia cod_fregue id_menage

merge m:1 cod_concel using `weather_shocks_m', nogen

label var drou_cond "No. months index was below the median of n. of droughts 2014/15"

save  "$data/prep_data_${year}", replace
export excel using "$data/climate_shocks/climate_shocks.xlsx", sheet("data") sheetreplace first(variables) locale(C)


/* cf3 _all using "$data/prep_data_2015_cc", id(id_menage)  */

