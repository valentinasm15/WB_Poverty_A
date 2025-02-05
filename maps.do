*===============================================================================
*Author: 	
*Date: 		
*===============================================================================
	*Maps generator
*===============================================================================
	
/* foreach package in spmap geo2xy palettes colrspace bimap  {
	capture which `package'
	if _rc==111 ssc install `package', replace
}
set scheme white_tableau */


/* ssc install schemepack, replace */
    
*--------------------------------------------------------------------------------
* Preparing vectors for maps of climate events vs poverty
*-------------------------------------------------------------------------------		

     *------ Fetching poverty data from Household Survey 2015

     * Poverty
     local vuln_vars poor vulnerable_etotal poverty_induced risk_induced vulnerable_eij vulnerable_uj
     
     foreach var of local vuln_vars {
          use "$data/est_vuln_${year}", clear 

          tab concelho `var'  [aw=hhsize*hhweight], nofreq row
          collapse (mean) `var' [aw=hhsize*hhweight], by(cod_concel concelho)
          replace `var'=`var'*100
          tempfile c_`var'
          save `c_`var''
     }

     foreach var of local vuln_vars {
	     merge 1:1 cod_concel using `c_`var'', nogen
     }
     tempfile all_vuln_vars
     save `all_vuln_vars'

     save "$maps_data/vuln_vars_maps", replace

     import excel using "$xls_tool", sheet(results) first clear
     keep if subc_group=="__all"
     keep if variable=="poor" | variable=="vulnerable_etotal" | variable=="poverty_induced" | variable=="risk_induced" | variable=="vulnerable_eij" | variable=="vulnerable_uj"
     tempfile national_cuts
     save `national_cuts'


     *------ Crosswalk of admin IDs of Household Survey 2015 vs admin IDs CPV shapefiles
    
    import excel using  "${maps_data}/crosswalk_shp", sheet(concelhos) first clear
    save "${maps_data}/crosswalk_shp", replace

    import excel using "$data/climate_shocks/climate_shocks.xlsx" , sheet(extreme_events) first clear 
    merge 1:1 cod_concel using  "${maps_data}/crosswalk_shp.dta", nogen

    save "$data/climate_shocks/climate_vars_maps.xlsx" , replace
    import excel using  "$data/climate_shocks/food_security", first clear

    save "$data/climate_shocks/food_security", replace 
    *------ Merging data

    * Producing shapes at concelhos level

    clear all
    cd "${maps_data}/chelo_shps"

    spshape2dta concelhos, replace

     * Merging shapes at concelhos level with vulnerability and poverty vars 

    use "${maps_data}/chelo_shps/concelhos"

    merge 1:1 admin1Pcod using  "$data/climate_shocks/climate_vars_maps.xlsx", nogen
    merge 1:1 cod_concel using  "$maps_data/vuln_vars_maps",nogen
    merge 1:1 cod_concel using "$data/climate_shocks/food_security",nogen
    merge 1:1 cod_concel using "$data/climate_shocks/water_scarcity"

    tempfile data_maps
    save `data_maps', replace

    *------------------------------- Producing maps ------------------------------------

* Poverty - Food Security and Water Scarcity maps
     use `data_maps', clear
     
     /* bimap poor food_security using concelhos_shp,  cuty(0 35 100) cutx(0 1.6 3) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) ///
          palette(purpleyellow0) bins(2) values percent ///	
		textx("IFSPC") texty("Poverty rate") texts(3) textlabs(3) 
          graph export "$maps_img/img_maps/pov_food_security.png", replace wid(2000)
 /* cuty(0 35 100) cutx(0 1.5 3) */

     bimap vulnerable_etotal food_security using concelhos_shp, formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) ///
          palette(purpleyellow0) bins(2) values percent ///	
		textx("IFSPC") texty("Vulnerability rate") texts(3) textlabs(3) 
          graph export "$maps_img/img_maps/vul_food_security.png", replace wid(2000) */
 /* cuty(0 49 100) cutx(0 1.6 3) */
 
     bimap poor water_scar_mean using concelhos_shp, cut(pctile) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) ///
          palette(bluered) bins(2) values percent ///	
		textx("Water scarcity") texty("Poverty rate") texts(3) textlabs(3) 
          graph export "$maps_img/img_maps/pov_water_scar.png", replace wid(2000)
/* cuty(0 35 100) cutx(0 1.9 3) */

     bimap vulnerable_etotal water_scar_mean using concelhos_shp, cut(pctile) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) ///
          palette(bluered) bins(3) values percent ///	
		textx("Water scarcity") texty("Vulnerability rate") texts(3) textlabs(3) 
          graph export "$maps_img/img_maps/vul_water_scar.png", replace wid(2000)
/* cuty(0 49 100) cutx(0 1.9 3)  */
STOP maps 

* Poverty - Droughts map
     use `data_maps', clear

     gen dum_pov=(poor>35)
     tab dum_pov drou_cond 

     bimap poor drou_cond using concelhos_shp,  cuty(0 35 100) cutx(0 0.5 1) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) ///
          palette(orangeblue0) bins(2) values percent  ///	
		textx("Droughts") texty("Poverty rate") texts(3) textlabs(3) 
          graph export "${maps_img}/img_maps/pov_drou_vals.png", replace wid(2000)

     bimap poor drou_cond using concelhos_shp,  cuty(0 35 100) cutx(0 0.5 1) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) ///
          vallabsize(3) palette(orangeblue0)  percent bins(2) ///	
		textx("Droughts in 2014") texty("Poverty rate") texts(3) textlabs(3) labxgap(-0.1) labygap(-0.1) 
          graph export "${maps_img}/img_maps/pov_drou_novals.png", replace wid(2000)



* Poverty - Vulnerability rates map  
     use `data_maps', clear 

     gen dum_pov=(poor>35)
     gen dum_vul=(vulnerable_etotal>49)
     tab dum_pov dum_vul

     bimap poor vulnerable_etotal using concelhos_shp,  cuty(0 35 100) cutx(0 49 100) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(bluered) values percent bins(2) ///
		textx("Vulnerability rate") texty("Poverty rate") texts(3) textlabs(3) 
           graph export "${maps_img}/img_maps/pov_vul_vals.png", replace wid(2000)	

     bimap poor vulnerable_etotal using concelhos_shp,  cuty(0 35 100) cutx(0 49 100) formatx(%3.0f) formaty(%3.0f)formatval(%2.0f) vallabsize(3) palette(bluered) percent bins(2) ///
		textx("Vulnerability rate") texty("Poverty rate") texts(3) textlabs(3) labxgap(-0.1) labygap(-0.1) 
           graph export "${maps_img}/img_maps/pov_vul_novals.png", replace wid(2000)	


* Poverty Induced - Risk Induced map  

     use `data_maps', clear

     gen dum_pov_ind=(poverty_induced>30)
     gen dum_risk_ind=(risk_induced>19)
     tab dum_pov_ind dum_risk_ind


		textx("Risk Induced") texty("Poverty Induced") texts(3) textlabs(3)
          graph export "${maps_img}/img_maps/pov_risk_induc_vals.png", replace wid(2000)
     
          bimap poverty_induced risk_induced using concelhos_shp,  cuty(0 30 100) cutx(0 19 100) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(purpleyellow0) percent bins(2) ///
		textx("Risk Induced") texty("Poverty Induced") texts(3) textlabs(3) labxgap(-0.1) labygap(-0.1) 
          graph export "${maps_img}/img_maps/pov_risk_induc_novals.png", replace wid(2000)	


* Idiosyncratic - Covariate Risk map  PENDING

     use `data_maps', clear
     gen dum_idiosy=(vulnerable_eij>49)
     gen dum_covari=(vulnerable_uj>30)
     tab dum_idiosy dum_covari


     bimap vulnerable_eij vulnerable_uj using concelhos_shp,  cuty(0 49 100) cutx(0 30 100) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(bluered0) values percent bins(2) ///
		textx("Idiosyncratic") texty("Covariate") texts(3) textlabs(3)
          graph export "${maps_img}/img_maps/idiosy_covar_vals.png", replace wid(2000)	
     
     bimap vulnerable_eij vulnerable_uj using concelhos_shp,  cuty(0 49 100) cutx(0 30 100) formatx(%3.0f) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(bluered0) percent bins(2) ///
		textx("Idiosyncratic") texty("Covariate") texts(3) textlabs(3) labxgap(-0.1) labygap(-0.1) 
          graph export "${maps_img}/img_maps/idiosy_covar_novals.png", replace wid(2000)


* Poverty - Floods map
     use `data_maps', clear

     gen dum_pov=(poor>35)
     tab dum_pov d_fl_s 
     tab dum_pov d_pl_s 




































     /* bimap poor d_fl_s using concelhos_shp, cuty(0 35 100) cutx(0 .5 1) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(yellowblue0) values percent bins(2) ///
		 textx("Fluvial floods") texty("Poverty rate") texts(3) textlabs(3) 
           graph export "${maps_path}/img_maps/pov_fl_vals.png", replace wid(2000)

     bimap poor fl_cond using concelhos_shp, cuty(0 35 100) cutx(0 .5 1) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(yellowblue0) percent bins(2) ///
		 textx("Fluvial floods") texty("Poverty rate") texts(3) textlabs(3) labxgap(-0.1) labygap(-0.1) 
           graph export "${maps_path}/img_maps/pov_fl_cond_novals.png", replace wid(2000)	 */
/* 
     bimap poor d_pl_s using concelhos_shp, cuty(0 35 100) cutx(0 .5 1) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(yellowblue0) percent bins(2) ///
		 textx("Pluvial floods") texty("Poverty rate") texts(3) textlabs(3) labxgap(-0.1) labygap(-0.1) 
           graph export "${maps_path}/img_maps/pov_pl_novals.png", replace wid(2000)	

     bimap poor pl_cond using concelhos_shp, cuty(0 35 100) cutx(0 .5 1) formaty(%3.0f) formatval(%2.0f) vallabsize(3) palette(yellowblue0)  percent bins(2) ///
		 textx("Pluvial floods") texty("Poverty rate") texts(3) textlabs(3)  labxgap(-0.1) labygap(-0.1) 
           graph export "${maps_path}/img_maps/pov_pl_cond_novals.png", replace wid(2000)	

     
   */


          	/* cap drop cod_concel 
	cap drop cod_fregue
	cap drop concelho
	cap drop freguesia
	
    rename concelho cod_concel
    rename freguesi cod_fregue
    decode cod_concel, gen(concelho)
    decode cod_fregue, gen(freguesia)
    label values cod_concel cod_fregue .