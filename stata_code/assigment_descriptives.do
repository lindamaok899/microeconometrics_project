********************************************************************************
* Project A: Impact of FDI on firm level outcomes

*firm identifier: firm
*treatment variables: FDI2016, FDITYPE2016
*pre-treatment variables: logwages2015, TFP2015, logemp2015, DEBTS2015, EXP2015, RD2015
*outcome variables: logwages2017, TFP2017, logemp2017, EXP2017, RD2017
*others variables (time-invariant firm characteristics): OWN, TECH, PORT

*goal: achieve maximum balance on the baseline covariates
//1) Estimate propensity score (logit, probit)
//2) Choose matching algorithm that will use the estimated effect to match ntreated units to treated units
//3) Estimate the impact of the intervention with the matched sample (usually as mean differences) and calculate standard errors

*Post-matching
//there should be no statistically significant differences between covariate means of the treated and comparison units.
//Test the common support condition
********************************************************************************


cap log close
clear all

cd "C:\Users\Moesle\Documents\ASP Kurse\Sourafel Girma\ASP Applied Microeconometric Methods\Datasets and do files"

log using project_A_ASP, replace // open log file
use "FDI_project.dta", clear // use data


***Label vars
label var TECH "Industry technology intensity"

***Generate categorical variable with export intensity before treatment
gen EXP2015_CAT = .
replace EXP2015_CAT = 0 if EXP2015==0
replace EXP2015_CAT = 1 if EXP2015>0 & EXP2015<0.25
replace EXP2015_CAT = 2 if EXP2015>=0.25  //max is 0.45
label var EXP2015_CAT "Export intensity 2015, category"
label define EXP2015_CAT 0 "no exports" 1 "<25%" 2 ">25%"


***Define globals
global pre "logwages2015 TFP2015 logemp2015 DEBTS2015 EXP2015 RD2015"
global post "logwages2017 TFP2017 logemp2017 EXP2017 RD2017"
global char "OWN TECH PORT"

********************************************************************************
* Part I: Descriptive statistics
********************************************************************************

***Get an overview of the data
describe
sum //same number of observations for all variables
label list // 3 types of FDI (0=no FDI)
		   // 4 categories of ownership and technology level
		   // dummy for close access to port 

***Summary statistics of the complete dataset
sutex2 FDI2016-RD2017, saving("write-up/tables/sum_stat.tex") replace ///
	caption(Summary statistics) minmax varlab
	
***Summary statistics by FDI type
bysort FDITYPE2016: sum logwages2015-RD2017
bysort FDITYPE2016: sutex2 FDITYPE2016 logwages2015-RD2017, saving("write-up/tables/sum_stat_byFDItype.tex") replace ///
	caption(Summary statistics by type of FDI received in 2016) minmax varlab 

***Frequency table by FDI type
foreach var in $char EXP2015_CAT{
tab FDITYPE2016 `var', column
tabout FDITYPE2016 `var' using write-up/tables/sum_stat_frequ_`var'_new.tex, c(freq col) ///
	f(0c 1) style(tex) font(italic) replace
}
	
/*	
*** Quantitative observations by 
	* FDI-type
	use "FDI_project.dta", clear // use data
	keep FDITYPE2016 logwages2015 TFP2015 logemp2015 DEBTS2015 EXP2015 ///
		RD2015 logwages2017 TFP2017 logemp2017 EXP2017 RD2017
	collapse (mean) logwages2015 - RD2017, by(FDITYPE2016)
	gen str_fdi="No FDI" if FDITYPE2016==0
	replace str_fdi="Exports" if FDITYPE2016==1
	replace str_fdi="Technology" if FDITYPE2016==2
	replace str_fdi="Dom. market" if FDITYPE2016==3
	order str_fdi, first
	label var str_fdi "FDI type"
	reshape long logwages TFP logemp DEBTS EXP RD, i(str_fdi) j(year)
	sort FDITYPE2016 year
	drop FDITYPE2016
	foreach var of varlist logwages - DEBTS {
	replace `var' = round(`var', 0.01)
	}
	texsave str_fdi - DEBTS using "tab/fditype_sumstat.tex", replace frag ///
	loc(htb) marker(tab:fditype_sumstat) width(\linewidth) ///
	title(Mean values statistics by types of FDI)	
*/	
/*
histogram FDITYPE2016, percent by(TECH) addlabels saving(write-up/graphs/hist1_tech.png)
histogram FDITYPE2016, percent by(PORT) addlabels saving(write-up/graphs/hist2_port.png)
histogram FDITYPE2016, percent by(EXP2015_CAT) addlabels saving(write-up/graphs/hist3_exp.png)
histogram FDITYPE2016, percent by(OWN) addlabels saving(write-up/graphs/hist4_own.png)
*/

foreach i in $pre {
graph hbox `i', over(FDITYPE2016)
graph export write-up/graphs/`i'.eps, replace
}

capture graph drop _all
graph bar (mean) logwages2015 logwages2017, over(FDITYPE2016, nolabel)  name(bar_wages) title("Wages, logs")  legend(label(1 "Mean 2015") label(2 "Mean 2017"))
graph bar (mean) logemp2015 logemp2017, over(FDITYPE2016, nolabel)  name(bar_emp) title("Employment, logs")
graph bar (mean) TFP2015 TFP2017, over(FDITYPE2016, nolabel)  name(bar_tfp) title("TFP")
graph bar (mean) EXP2015 EXP2017, over(FDITYPE2016, nolabel) name(barexp) title("Export intensity")
graph bar (mean) RD2015 RD2017, over(FDITYPE2016, nolabel) name(bar_rd) title("R&D")
graph bar (mean) DEBTS2015, over(FDITYPE2016, nolabel) name(bar_debt) title("Debt")
grc1leg bar_wages bar_emp bar_tfp barexp bar_rd bar_debt, title("Pre- and post-treatment variables by treatment categories", size(small)) legendfrom(bar_wages)
graph export write-up/graphs/bar_pre_post.eps
graph drop _all
