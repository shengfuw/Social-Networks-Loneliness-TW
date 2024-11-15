
* Start logging
cd "$log"
cap log close
log using "c_ego_level_statistics", text replace


cd "$workdata"

use "ego_data_full.dta", clear
merge 1:1 ego_id using "ego_level_statistics_stata.dta"
drop _merge

merge 1:1 ego_id using "ego_level_statistics_R.dta"
drop _merge

gen lnindependence = log(independence+0.01)

// Network size
recode pernet_size (0=1)(1/6=0), gen(isolated) 
replace pernet_size = degree if pernet_size == .
recode pernet_size (6=6.5) // Follow Marsden (1987)
gen pernet_size2 = pernet_size*pernet_size

save "ego_data_final.dta", replace

/************** Missing Values **************/
mdesc
mdesc if !isolated

qui reg loneliness female c.age##c.age eduyear lnrincome subjective_status i.employment_short i.marital i.ethnic i.residence_type i.religion i.isolated
gen complete = 1 if e(sample)
// Only keep complete case !!! //
drop if !complete

/***************** Estimation & Plotting *****************/
global demographic "female c.age##c.age eduyear lnrincome subjective_status i.employment_short i.marital i.ethnic i.residence_type i.religion"
global personality "trust outgoing lnindependence"

set scheme white_tableau // stcolor; white_tableau; gg_tableau (Stata 18+, or https://github.com/asjadnaqvi/stata-schemepack)
cd "$output"

/* PART I: Demographic variables */ 
// Model 1: demographic (all sample) //
reg loneliness $demographic [iw=wsel]
est store model_1
regress, coeflegend noheader
coefplot (., if(@ll<0 & @ul>0))  (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	groups(?.marital = `""{bf:Marital status}" "(ref. Single)""' ///
		   ?.religion = `""{bf:Religion}" "(ref. No religion)""' ///
		   ?.employment_short = `""{bf:Employment status}" "(ref. Unemployed)""' ///
		   ?.ethnic = `""{bf:Ethnicity}" "(ref. Minan)""' ///
		   ?.residence_type = `""{bf:Residential type}" "(ref. Metropolitan)""', labsize(*0.8)) ///
	coeflabels(female = "Female" age = "Age" c.age#c.age = "Age{superscript:2}" ///
			   eduyear = "Years of education" lnrincome = "Personal income (logged)" subjective_status = "Subjective social status" ///
			   2.employment_short = "Employer" 3.employment_short = "Self-employed or Part-timer" 4.employment_short = "Employed" ///
			   2.marital = "Married or cohabiting" 3.marital = "Separaed, divorced, or widowed" ///
			   2.residence_type = "Suburban or town" 3.residence_type = "Rural or farm" ///
			   2.ethnic = " Hakka" 3.ethnic = "Mainlander" 4.ethnic = "Aboriginal or other" ///
			   1.religion = "Buddism" 2.religion = "Daoism" 3.religion = "Folk Religion" 4.religion = "Catholic" 5.religion = "Christian") ///
	 p1(pstyle(p5)) p2(pstyle(p3)) ciopts(lwidth(*0.95)) msize(*1.035) ylabel( ,labsize(*0.75)) legend(off) offset(0) ///
	 note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig1-1.jpg", replace

/* marginsplot
margins, at(age=(18(5)85)) 
marginsplot
*/


// Model 2: demographic (male sample) //
reg loneliness $demographic [iw=wsel] if !female 
est store model_2
// Model 3: demographic (female sample) //
reg loneliness $demographic [iw=wsel] if female
est store model_3
coefplot model_2 model_3, drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	groups(?.marital = `""{bf:Marital status}" "(ref. Single)""' ///
		   ?.religion = `""{bf:Religion}" "(ref. No religion)""' ///
		   ?.employment_short = `""{bf:Employment status}" "(ref. Unemployed)""' ///
		   ?.ethnic = `""{bf:Ethnicity}" "(ref. Minan)""' ///
		   ?.residence_type = `""{bf:Residential type}" "(ref. Metropolitan)""', labsize(*0.8)) ///
	coeflabels(female = "Female" age = "Age" c.age#c.age = "Age{superscript:2}" 1.urban = "Living in urban" ///
			   eduyear = "Years of education" lnrincome = "Personal income (logged)" subjective_status = "Subjective social status" ///
			   2.employment_short = "Employer" 3.employment_short = "Self-employed or Part-timer" 4.employment_short = "Employed " ///
			   2.marital = "Married or cohabiting" 3.marital = "Separated, divorced, or widowed" ///
			   2.residence_type = "Suburban or town" 3.residence_type = "Rural or farm" ///
			   2.ethnic = " Hakka" 3.ethnic = "Mainlander " 4.ethnic = "Aboriginal or other" ///
			   1.religion = "Buddism" 2.religion = "Daoism" 3.religion = "Folk Religion" 4.religion = "Catholic" 5.religion = "Christian") ///
	 p1(label(Male)) p2(label(Female)) ciopts(lwidth(*0.6)) msize(*0.6) ylabel( ,labsize(*0.75)) legend(size(*0.85)) ///
	 note("{it:Note:}" "(1) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig1-2.jpg", replace

// Margins plot: Gender x Marital status //
reg loneliness $demographic i.female##i.marital [iw=wsel] 
qui margins female#marital
marginsplot, recast(scatter) title("") ///
	xtitle("{bf:Gender}") ytitle("{bf:Predicted loneliness}") ///
	xlabel(0"Male" 1"Female") xsc(r(-0.25 1.25)) ysc(r(1.14 2.02)) ///
	legend(subtitle("{bf:Marital status}"))
// 	legend(subtitle("") position(6) rows(1) region(lcolor("black") lwidth(0.15) margin(medsmall)))  
graph export "Fig1-3.jpg", replace

/* PART II: Social isolation */ 
// Model 4: isolation //
reg loneliness $demographic i.isolated [iw=wsel] 
est store model_4
margins isolated
marginsplot, recast(scatter) title("") xtitle("{bf:Social isolation}") ytitle("{bf:Predicted loneliness}") ///
	xsc(r(-0.35 1.35)) ysc(r(1.21 1.6)) ylabel(1.23[0.05]1.59) xlabel(1"Isolated" 0"Not isolated") xsize(1.25) ysize(1) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig2-1.jpg", replace

// Margins plot: Gender x Isolation //
reg loneliness $demographic i.female##i.isolated [iw=wsel] 
qui margins female#isolated 
marginsplot, recast(scatter) title("") xtitle("{bf:Gender}") ytitle("{bf:Predicted loneliness}") ///
	xsc(r(-0.35 1.35)) ysc(r(1.08 1.55)) ylabel(1.1[0.07]1.62) xlabel(1"Female" 0"Male") ///
	plot(, label("Not isolated" "Isolated")) xsize(1.4) ysize(1) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig2-2.jpg", replace

// Margins plot: Education x Isolation //
reg loneliness $demographic c.eduyear##i.isolated [iw=wsel] 
qui margins, at(eduyear=(2(2)16)) over(isolated) 
marginsplot, title("") xtitle("{bf:Years of education}") ytitle("{bf:Predicted loneliness}") ///
	xsc(r(1.55 16.35)) ysc(r(1.12 1.65)) ylabel(1.15[0.07]1.65) ///
	plot( , label("Not isolated" "Isolated")) xsize(1.6) ysize(1) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig2-3.jpg", replace

/* Part III */
// Model 5: social integration //
reg loneliness $demographic c.pernet_size##c.pernet_size c.tie_strength_mean if !isolated  [iw=wsel] 
est store model_5
coefplot (., if(@ll<0 & @ul>0))  (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(pernet_size c.pernet_size#c.pernet_size tie_strength_mean) ///
	coeflabels(pernet_size = "Network size" c.pernet_size#c.pernet_size = "Network size{superscript:2}" ///
	tie_strength_mean = "Mean of tie strength") /// 
	p1(pstyle(p5)) p2(pstyle(p3))legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.4)) msize(*1.35) ylabel( ,labsize(*1)) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig3-1.jpg", replace


// qui margins, at(pernet_size=(1(1)6)) 
// marginsplot 

// Model 6-8: Network structure //
reg loneliness $demographic c.pernet_size density if !isolated  [iw=wsel] 
est store model_6

reg loneliness $demographic c.pernet_size component_ratio if !isolated  [iw=wsel] 
est store model_7

reg loneliness $demographic c.pernet_size betweenness if !isolated  [iw=wsel] 
est store model_8

coefplot (model_6 model_7 model_8, if(@ll<0 & @ul>0)) (model_6 model_7 model_8, if(@ll>0 | @ul<0)),  drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(density  component_ratio betweenness) ///
	coeflabels(density = "Density" component_ratio = "Component ratio" betweenness = "Ego betweenness") ///
	p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.4)) msize(*1.35) ylabel( ,labsize(*1)) offset(0) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Each model includes only one measure of network structure. Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig3-2.jpg", replace 

// Model 9 Functional content - Quality //
reg loneliness $demographic c.pernet_size##c.network_pressure if !isolated  [iw=wsel] 
est store model_9
qui margins, at(network_pressure=(1(0.5)5) pernet_size=(1(2)5)) 
marginsplot, title("") xtitle("{bf:Pressure of Social Network (Negative Relationship)}") ytitle("{bf:Predicted loneliness}") ///
	plot( , label("Network size = 1" "Network size = 3" "Network size = 5")) note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.")
graph export "Fig3-3.jpg", replace

reg loneliness $demographic c.density##c.network_pressure if !isolated  [iw=wsel] 
qui margins, at(network_pressure=(1(0.5)5) density=(0.1(0.4)1)) 
marginsplot, title("") xtitle("{bf:Pressure of Social Network (Negative Relationship)}") ytitle("{bf:Predicted loneliness}") ///
	 note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.")


// Model 10 Functional content - Composition //
reg loneliness $demographic c.pernet_size kin_percent female_percent married_percent age_mean eduyear_mean subjective_status_mean subjective_status_max if !isolated  [iw=wsel] 
est store model_10
coefplot (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(has* pernet_size kin_percent female_percent age_mean married_percent eduyear_mean subjective_status_mean subjective_status_max) ///
	coeflabels(pernet_size = "Network size" kin_percent = "% of kin ties" female_percent = "% of female alters" /// 
	age_mean = "μ of alters' age" married_percent = "% of married alters" eduyear_mean = "μ of alters' years of education" ///
	subjective_status_mean = "μ of alters' social status" subjective_status_max = "Max of alters' social status") ///
	p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.4)) msize(*1.35) ylabel( ,labsize(*0.9)) offset(0) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig3-4.jpg", replace

// Model 11 Functional content - Heterogeneity //
reg loneliness $demographic c.pernet_size kin_IQV female_IQV married_IQV age_sd eduyear_sd subjective_status_sd if !isolated  [iw=wsel] 
est store model_11
coefplot  (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(pernet_size kin_IQV female_IQV married_IQV age_sd eduyear_sd subjective_status_sd) ///
	coeflabels(pernet_size = "Network size" kin_IQV = "IQV of kin ties" female_IQV = "IQV of alters' gender" /// 
	age_sd = "SD of alters' age" married_IQV = "IQV of marital status" eduyear_sd = "SD of alters' years of education" ///
	subjective_status_sd = "SD of alters' social status") ///
	p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.4)) msize(*1.35) ylabel( ,labsize(*0.9)) offset(0) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig3-5.jpg", replace

// Model 12 Functional content - Heterogeneity with interaction //
reg loneliness $demographic c.pernet_size kin_IQV i.female##c.female_IQV i.marital##c.married_IQV c.age##c.age_sd c.eduyear##c.eduyear_sd c.subjective_status##c.subjective_status_sd if !isolated  [iw=wsel] 
est store model_12
coefplot (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small))  ///
	keep(pernet_size kin_IQV female_IQV married_IQV age_sd eduyear_sd subjective_status_sd 1.female#c.female_IQV 2.marital#c.married_IQV 3.marital#c.married_IQV c.age#c.age_sd c.eduyear#c.eduyear_sd c.subjective_status#c.subjective_status_sd) ///
	order(pernet_size kin_IQV female_IQV married_IQV age_sd eduyear_sd subjective_status_sd *#*) ///
	headings(1.female#c.female_IQV = `"{bf:Interaction term}"' , labsize(*0.9)) ///
	coeflabels(pernet_size = "Network size" kin_IQV = "IQV of kin ties" female_IQV = "IQV of alters' gender" /// 
	age_sd = "SD of alters' age" married_IQV = "IQV of marital status" eduyear_sd = "SD of alters' years of education" ///
	subjective_status_sd = "SD of alters' social status" 1.female#c.female_IQV = "Female * IQV of alters' gender" ///
	2.marital#c.married_IQV = "Married or cohabiting * IQV of marital status" ///
	3.marital#c.married_IQV = "Separated, divorced, or widowed * IQV of marital status" ///
	c.age#c.age_sd = "Age * SD of alters' age" c.eduyear#c.eduyear_sd = "Year of education * SD of alters' years of education" ///
	c.subjective_status#c.subjective_status_sd = "Subjective social status * SD of alters' social status") ///
	p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.)) msize(*1.) ylabel( ,labsize(*0.8)) offset(0) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig3-6.jpg", replace

// Model 13 Functional content - Ego-alter similarity //
reg loneliness $demographic c.pernet_size gender_EI_index married_EI_index age_distance eduyear_distance subjective_status_distance if !isolated  [iw=wsel] 
est store model_13
coefplot (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(pernet_size gender_EI_index age_distance married_EI_index eduyear_distance subjective_status_distance) ///
	coeflabels(pernet_size = "Network size"  gender_EI_index = "EI index of gender" /// 
	age_distance = "Distance of age" married_EI_index = "EI index of marital status" eduyear_distance = "Distacnce of years of education" ///
	subjective_status_distance = "Distacnce of social status") ///
	p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.4)) msize(*1.35) ylabel( ,labsize(*0.9)) offset(0) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig3-7.jpg", replace

// Model 14 Functional content - Ego-alter similarity with interactoin //
reg loneliness $demographic c.pernet_size i.female##c.gender_EI_index i.marital##c.married_EI_index c.age##c.age_distance c.eduyear##c.eduyear_distance c.subjective_status##c.subjective_status_distance if !isolated  [iw=wsel] 
est store model_14
coefplot (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(pernet_size gender_EI_index age_distance married_EI_index eduyear_distance subjective_status_distance 1.female#c.gender_EI_index 2.marital#c.married_EI_index 3.marital#c.married_EI_index c.age#c.age_distance c.eduyear#c.eduyear_distance c.subjective_status#c.subjective_status_distance) ///
	order(pernet_size gender_EI_index married_EI_index age_distance eduyear_distance subjective_status_distance *#*) ///
	headings(1.female#c.gender_EI_index = `"{bf:Interaction term}"', labsize(*0.9)) ///
	coeflabels(pernet_size = "Network size"  gender_EI_index = "EI index of gender" /// 
	age_distance = "Distance of age" married_EI_index = "EI index of marital status" eduyear_distance = "Distacnce of years of education" ///
	subjective_status_distance = "Distacnce of social status" 1.female#c.gender_EI_index = "Female * EI index of gender" ///
	2.marital#c.married_EI_index = "Married or cohabiting * EI index of marital status"  ///
	3.marital#c.married_EI_index = "Separated, divorced, or widowed * EI index of marital status" /// 
	c.age#c.age_distance = "Age * distance of age" c.eduyear#c.eduyear_distance = "Years of education * distacnce of years of education" ///
	c.subjective_status#c.subjective_status_distance= "Subjective social status * distacnce of social status") ///
	p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*1.)) msize(*1.) ylabel( ,labsize(*0.8)) offset(0) ///
	note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig3-8.jpg", replace
	
// Margins plot: Marital status x EI index of marital status //	
reg loneliness $demographic c.pernet_size c.married_EI_index##i.marital if !isolated [iw=wsel] 
margins, at(married_EI_index=(-1(0.25)0.75) marital=(1 2)) 
marginsplot, title("") xtitle("{bf:EI index of marital}" "(higher values indicate greater dissimilarity)") ytitle("{bf:Predicted loneliness}") note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Model also contains all demographic variables." "(3) Results are adjusted based on the sampling weight.")
graph export "Fig3-9.jpg", replace

/* Sensitivity anlysis */
// isolation + personality 
reg loneliness $demographic $personality i.isolated [iw=wsel] 
est store model_15
coefplot (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	groups(?.marital = `""{bf:Marital status}" "(ref. Single)""' ///
		   ?.religion = `""{bf:Religion}" "(ref. No religion)""' ///
		   ?.employment_short = `""{bf:Employment status}" "(ref. Unemployed)""' ///
		   ?.ethnic = `""{bf:Ethnicity}" "(ref. Minan)""' ///
		   ?.residence_type = `""{bf:Residential type}" "(ref. Metropolitan)""',labsize(*0.6)) ///
	headings(trust = `"{bf:Perseonalilty}"' 1.isolated = `"{bf:}"',labsize(*0.6)) ///	
	coeflabels(female = "Female" age = "Age" c.age#c.age = "Age{superscript:2}" 1.urban = "Living in urban" ///
			   eduyear = "Years of education" lnrincome = "Personal income (logged)" subjective_status = "Subjective social status" ///
			   2.employment_short = "Employer" 3.employment_short = "Self-employed or Part-timer" 4.employment_short = "Employed " ///
			   2.marital = "Married or cohabiting" 3.marital = "Separated, divorced, or widowed" ///
			   2.residence_type = "Suburban or town" 3.residence_type = "Rural or farm" ///
			   2.ethnic = " Hakka" 3.ethnic = "Mainlander " 4.ethnic = "Aboriginal or other" ///
			   1.religion = "Buddism" 2.religion = "Daoism" 3.religion = "Folk Religion" 4.religion = "Catholic" 5.religion = "Christian" ///
			   trust = "Trust" outgoing = "Outgoing" lnindependence = "Independence" 1.isolated = "Isolated") ///
	 p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*0.7)) msize(*0.8) ylabel( ,labsize(*0.53)) offset(0) ///
	 note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig4-1.jpg", replace 

coefplot model_4 model_15, ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	keep(trust outgoing lnindependence 1.isolated) ///
	order(trust outgoing lnindependence . 1.isolated) /// 
	coeflabels(trust = "Trust" outgoing = "Outgoing" lnindependence = "Independence" 1.isolated = "Isolated") ///
	p1(pstyle(p1)) p2(pstyle(p2)) legend(off) xsize(1.35) ysize(1) ciopts(lwidth(*1.4)) msize(*1.35) ylabel( ,labsize(*1)) ///
	note("{it:Note:}" "(1) Model also contains all demographic variables." "(2) Results are adjusted based on the sampling weight.", size(vsmall)) 
graph export "Fig4-2.jpg", replace

reg loneliness $demographic $personality c.pernet_size##c.pernet_size if !isolated [iw=wsel] 
est store model_16
coefplot (., if(@ll<0 & @ul>0)) (., if(@ll>0 | @ul<0)), drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	groups(?.marital = `""{bf:Marital status}" "(ref. Single)""' ///
		   ?.religion = `""{bf:Religion}" "(ref. No religion)""' ///
		   ?.employment_short = `""{bf:Employment status}" "(ref. Unemployed)""' ///
		   ?.ethnic = `""{bf:Ethnicity}" "(ref. Minan)""' ///
		   ?.residence_type = `""{bf:Residential type}" "(ref. Metropolitan)""', labsize(*0.6)) ///
	headings(trust = `"{bf:Perseonalilty}"' pernet_size = `"{bf:}"', labsize(*0.6)) ///	
	coeflabels(female = "Female" age = "Age" c.age#c.age = "Age{superscript:2}" 1.urban = "Living in urban" ///
			   eduyear = "Years of education" lnrincome = "Personal income (logged)" subjective_status = "Subjective social status" ///
			   2.employment_short = "Employer" 3.employment_short = "Self-employed or Part-timer" 4.employment_short = "Employed " ///
			   2.marital = "Married or cohabiting" 3.marital = "Separated, divorced, or widowed" ///
			   2.residence_type = "Suburban or town" 3.residence_type = "Rural or farm" ///
			   2.ethnic = " Hakka" 3.ethnic = "Mainlander " 4.ethnic = "Aboriginal or other" ///
			   1.religion = "Buddism" 2.religion = "Daoism" 3.religion = "Folk Religion" 4.religion = "Catholic/Christian" ///
			   pernet_size = "Network size" c.pernet_size#c.pernet_size = "Network size{superscript:2}" /// 
			   trust = "Trust" outgoing = "Outgoing" lnindependence = "Independence" 4.religion = "Catholic" 5.religion = "Christian") ///
	 p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.55) ysize(1) ciopts(lwidth(*0.7)) msize(*0.8) ylabel( ,labsize(*0.53)) offset(0) ///
	 note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Results are adjusted based on the sampling weight.", size(vsmall))
graph export "Fig4-3.jpg", replace

// three sclae of loneliness 
reg lack_companionship  $demographic i.isolated [iw=wsel] 
est store lack_companionship
reg lonely  $demographic i.isolated [iw=wsel] 
est store lonely
reg excluded  $demographic i.isolated [iw=wsel] 
est store excluded
coefplot (lack_companionship, if(@ll<0 & @ul>0) ) (lack_companionship, if(@ll>0 | @ul<0)), bylabel(lack companionship) || ///
		 (lonely, if(@ll<0 & @ul>0)) (lonely, if(@ll>0 | @ul<0)), bylabel(lonely) || ///
		 (excluded, if(@ll<0 & @ul>0)) (excluded, if(@ll>0 | @ul<0)), bylabel(excluded) ||, ///
	drop(_cons) xline(0) nolabels ///
	groups(?.marital = `""{bf:Marital status}" "(ref. Single)""' ///
		   ?.religion = `""{bf:Religion}" "(ref. No religion)""' ///
		   ?.employment_short = `""{bf:Employment status}" "(ref. Unemployed)""' ///
		   ?.ethnic = `""{bf:Ethnicity}" "(ref. Minan)""' ///
		   ?.residence_type = `""{bf:Residential type}" "(ref. Metropolitan)""',labsize(*0.7)) ///
	headings(trust = `"{bf:Perseonalilty}"' 1.isolated = `"{bf:}"',labsize(*0.7)) ///	
	coeflabels(female = "Female" age = "Age" c.age#c.age = "Age{superscript:2}" 1.urban = "Living in urban" ///
			   eduyear = "Years of education" lnrincome = "Personal income (logged)" subjective_status = "Subjective social status" ///
			   2.employment_short = "Employer" 3.employment_short = "Self-employed or Part-timer" 4.employment_short = "Employed " ///
			   2.marital = "Married or cohabiting" 3.marital = "Separated, divorced, or widowed" ///
			   2.residence_type = "Suburban or town" 3.residence_type = "Rural or farm" ///
			   2.ethnic = " Hakka" 3.ethnic = "Mainlander " 4.ethnic = "Aboriginal or other" ///
			   1.religion = "Buddism" 2.religion = "Daoism" 3.religion = "Folk Religion" 4.religion = "Catholic" 5.religion = "Christian" ///
			   trust = "Trust" outgoing = "Outgoing" lnindependence = "Independence" 1.isolated = "Isolated") ///
	 p1(pstyle(p5)) p2(pstyle(p3)) legend(off) xsize(1.5) ysize(1) ciopts(lwidth(*0.7)) msize(*0.8) ylabel( ,labsize(*0.65)) offset(0) ///
	 byopts(compact cols(3))
graph export "Fig4-4.jpg", replace

// standardized coefficients
preserve
center age eduyear lnrincome subjective_status, inplace standardize
reg loneliness $demographic [iw=wsel]
coefplot (., if(@ll<0 & @ul>0))  (., if(@ll>0 | @ul<0)), ///
	drop(_cons) xline(0) nolabels subtitle("{bf: Coefficients (DV: Loneliness)}", size(small)) ///
	groups(?.marital = `""{bf:Marital status}" "(ref. Single)""' ///
		   ?.religion = `""{bf:Religion}" "(ref. No religion)""' ///
		   ?.employment_short = `""{bf:Employment status}" "(ref. Unemployed)""' ///
		   ?.ethnic = `""{bf:Ethnicity}" "(ref. Minan)""' ///
		   ?.residence_type = `""{bf:Residential type}" "(ref. Metropolitan)""', labsize(*0.8)) ///
	coeflabels(female = "Female" age = "Age" c.age#c.age = "Age{superscript:2}" ///
			   eduyear = "Years of education" lnrincome = "Personal income (logged)" subjective_status = "Subjective social status" ///
			   2.employment_short = "Employer" 3.employment_short = "Self-employed or Part-timer" 4.employment_short = "Employed" ///
			   2.marital = "Married or cohabiting" 3.marital = "Separaed, divorced, or widowed" ///
			   2.residence_type = "Suburban or town" 3.residence_type = "Rural or farm" ///
			   2.ethnic = " Hakka" 3.ethnic = "Mainlander" 4.ethnic = "Aboriginal or other" ///
			   1.religion = "Buddism" 2.religion = "Daoism" 3.religion = "Folk Religion" 4.religion = "Catholic" 5.religion = "Christian") ///
	 p1(pstyle(p5)) p2(pstyle(p3)) ciopts(lwidth(*0.95)) msize(*1.035) ylabel( ,labsize(*0.75)) legend(off) offset(0) ///
	 note("{it:Note:}" "(1) Number of observations = `e(N)'." "(2) Results are adjusted based on the sampling weight.", size(vsmall)) 
restore

/***************** Tables *****************/

lab var female "Gender"
lab define gender 0"Male" 1"Female" 
lab value female gender
lab var age "Age" 
lab var eduyear "Years of education"
lab var lnrincome "Personal income (logged)" 
lab var subjective_status "Subjective social status" 
lab var employment_short "Employment status"
lab var marital "Marital status"
lab var ethnic "Ethnicity"
lab var residence_type "Residential type"
lab var religion "Religion"
lab var loneliness "Loneliness"
lab var isolated "Social isolation"
lab define isolated 0"Not isolated" 1"Isolated" 
lab value isolated isolated

/* Table 1: Descriptive statistics */
// Continous: loneliness age eduyear lnrincome subjective_status
// Catergorical: female employment_short marital i.ethnic i.residence_type i.religion
dtable loneliness i.female age eduyear lnrincome subjective_status i.employment_short i.marital i.ethnic i.residence_type i.religion [iw=wsel], ///
	by(isolated) sample(Sample, statistic(frequency) place(seplabels) font(, nobold)) sformat("(n = %s)" frequency) ///
	nformat(%9.2g mean sd) nformat(%9.1g fvpercent) column(summary(M(SD) / n(%))) ///
	define(rangei = min max, delimiter("-")) sformat("[%s]" rangei) nformat(%16.0fc rangei) continuous(, statistic(mean sd)) ///
	factor(, font(, nobold)) ///
	title("") note("Note: Mean (SD) or N (%)") 
collect export table1.xlsx, replace // table1.tex

/* Table 2: Model 1-3 */
collect clear
collect create table2
collect _r_b _r_se: est restore model_1
collect _r_b _r_se: est restore model_2
collect _r_b _r_se: est restore model_3
collect layout (colname#result result[r2 r2_a N p_d]) (cmdset)
// collect style showbase off
collect style cell border_block, border(right, pattern(nil))
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b N], nformat(%9.3g)
collect style cell result[_r_se], nformat(%9.2g)
collect style cell result[r2 r2_a], nformat(%9.4f)
collect style header result, level(hide)
collect style showempty on
// collect style column, extraspace(1)  dups(center)
collect style row stack, spacer delimiter(" x ")
collect style header result[r2 r2_a N p_d], level(label)
collect style cell result[p_d], nformat(%5.2g) minimum(0.001)
collect stars _r_p 0.01 "***"  0.05 "** " 0.1 "*  ", attach(_r_b) shownote
collect label levels result r2 "R-squared" r2_a "Adjusted R-squared", modify
collect label values cmdset 1 "Model 1 (Full sample)" 2 "Model 2 (Male sample)" 3 "Model 3 (Female sample)"
// collect style header colname, level(value) title(label)
collect preview
collect export table1A.xlsx, replace

// esttab model_1 model_2 model_3 using "table2.csv", cells(b(star fmt(3)) se(par fmt(2))) stats(r2 r2_a N, fmt(a4 a4 a) labels("R-squared" "Adj R-squared")) nobase nomtitle label replace

// Table 3: Model 4
// Table 4: Model 5
// Table 5: Model 6-8
// Table 6: Model 9
//          Model 10
// Table 7: Model 11-12 
// Table 8: Model 13-14 

log close
