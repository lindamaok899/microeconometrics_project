********************************************************************************
* Title: ASP_assignment.do

*treatment: FDI2016, FDITYPE2016
*Baseline covariates: logwages2015, TFP2015, logemp2015, DEBTS2015, EXP2015, RD2015
*outcome: TFP2017, logwages2017, logemp2017, EXP2017, RD2017
*others: OWN, TECH 

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
set more 1

* Assign directories: user-specific
if "`c(username)'"=="[Anna]"{
cd "C:\Users\Anna\Dropbox\Projekt"
}
else if "`c(username)'"=="[suprunenko]"{
global root `r(db)'
cd $root/MyDocs/Courses/20182019Kiel/8.Girma2018Microeconometrics/Projekt
}

log using AssignmentASP, replace // open log file
use "projectB.dta", clear // use data

********************************************************************************
* Part I: Descriptive statistics
********************************************************************************
desc
sum // variables FDITYPE2016 OWN TECH PORT have numeric values: in browser 
	// displayed in blue, i.e. by value label 
	// All have the same No of obs. equal to the No of obs in the data set, thus
	// no missings. Additional check:
mdesc // no missing values
sutex2 FDI2016-RD2017, saving("tab/sum_stat.tex") replace ///
	caption(Summary statistics) min varlab
label list // 4 categories of ownership and technologies, dummy for access to
	// port and no FDI vs 3 types

*** Number of observations by groups
	* Ownership by industry
		gen i=1
		keep OWN TECH i
		collapse (sum) i, by(OWN TECH)
		reshape wide i, i(OWN) j(TECH)
		label var i1 "Low-tech"
		label var i2 "Medium low"
		label var i3 "Medium high"
		label var i4 "High-tech"
		preserve 
		collapse (sum) i*
		save "data/own_by_ind_tot.dta", replace
		restore
		append using "data/own_by_ind_tot.dta"
		gen str_own="Listed companies" if OWN==1
		replace str_own="Subsidiaries" if OWN==2
		replace str_own="Independent" if OWN==3
		replace str_own="State" if OWN==4
		replace str_own="Total" if OWN==.
		egen sum_total=rowtotal(i1-i4)
		label var sum_total "Total"
		drop OWN
		order str_own, first
		label var str_own "Ownership"
		texsave str_own - sum_total using "tab/own_by_ind.tex", replace frag loc(htb) ///
			marker(tab:own_by_ind) varlabels width(\linewidth) ///
			title (Number of observations: ownership by industry)
	* FDI_type by industry
	use "projectB.dta", clear // use data
		gen i=1
		keep FDITYPE TECH i
		collapse (sum) i, by(FDITYPE TECH)
		reshape wide i, i(FDITYPE) j(TECH)
		label var i1 "Low-tech"
		label var i2 "Medium low"
		label var i3 "Medium high"
		label var i4 "High-tech"
		preserve 
		collapse (sum) i*
		save "data/fdi_by_ind_tot.dta", replace
		restore
		append using "data/fdi_by_ind_tot.dta"
		gen str_fdi="No FDI" if FDITYPE2016==0
		replace str_fdi="Exports-oriented FDI" if FDITYPE2016==1
		replace str_fdi="Technology intensive FDI" if FDITYPE2016==2
		replace str_fdi="Domestic market seeking FDI" if FDITYPE2016==3
		replace str_fdi="Total" if FDITYPE==.
		egen sum_total=rowtotal(i1-i4)
		label var sum_total "Total"
		drop FDITYPE2016
		order str_fdi, first
		label var str_fdi "FDI type"
		texsave str_fdi - sum_total using "tab/fdi_by_ind.tex", replace frag loc(htb) ///
			marker(tab:fdi_by_ind) varlabels width(\linewidth) ///
			title (Number of observations: FDI by industry)

	
*** Quantitative observations by 
	* FDI-type
	use "projectB.dta", clear // use data
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

	
********************************************************************************
* Part II: Propensity scores
********************************************************************************

**propensity scores

global D "logwages2015 TFP2015 logemp2015 DEBTS2015 EXP2015 RD2015"
logit FDI2016 $D , robust //without interactions
*help eststo - update
eststo L
esttab L using logit.rtf, replace wide se scalars( r2_p bic aic) label
predict pscore
lab var pscore "Propensity score"
*ssc install bihist, replace
bihist pscore , by(FDI2016)  tw1(color(black)) tw(color(red)) percent 
*pscore overlap check 
kdensity pscore if FDI2016==0 , plot (kdensity pscore if FDI2016==1) legend ( label(1 "Non-subsidised") label(2 "Subsidised") )

**Nearest Neighbour Matching
teffects nnmatch (logwages2015 TFP2015 logemp2015 DEBTS2015 EXP2015) (FDI2016), ematch(RD2015 OWN TECH PORT) biasadj(TFP2015 logemp2015 DEBTS2015 EXP2015) osample(violation)



*from lecture
teffects psmatch (TFP2017)(FDI2016 $D ), osample(var_osa)
 drop if var_osa == 1 
drop var_osa
tebalance summarize
drop var_osa
tebalance box logemp2007 , saving(emp1_balance.gph, replace)
cap drop var_osa
tebalance box , saving(ps_balance0.gph, replace)  //propensity score balance

