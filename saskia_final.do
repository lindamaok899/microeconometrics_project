
clear all
cap log close
set matsize 11000

cd "C:\Users\Moesle\Documents\ASP Kurse\Sourafel Girma\ASP Applied Microeconometric Methods\Datasets and do files\write-up\microeconometrics_project-master\stata_code"

log using take_home, replace
use FDI_project.dta, clear

* Adjust labels
label var logwages2015 "Wages in 2015 (logs)"
label var logwages2017 "Wages in 2017 (logs)"
label var logemp2015 "Employment in 2015 (logs)"
label var logemp2017 "Emplyoment in 2017 (logs)"
label var DEBTS2015 "Debt in 2015 (logs)"
label var RD2015 "RD in 2015 (dummy)"
label var RD2017 "RD in 2017 (dummy)"
label var EXP2015 "Export intensity in 2015"
label var EXP2017 "Export intensity in 2017"
label var TECH "Industry technology intensity"
label define mFDI2016 0 "No FDI" 1 "FDI" 
label value FDI2016 mFDI2016
label define mFDI2016TYPE 0 "No FDI" 1 "Exports FDI" 2 "Tech. FDI" 3 "Domestic FDI"
label value FDITYPE2016 mFDI2016TYPE
label define mTECH 1 "Low-tech" 2 "Medium low" 3 "Medium high" 4 "High-tech"
label value TECH mTECH

*******************************************************************
* Task 2: descriptives ********************************************
*******************************************************************

 global T "TECH OWN PORT"
 global Pre "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015 RD2015"
 global Post "logwages2017 TFP2017 logemp2017 EXP2017 RD2017"
	
* Summary statistics of full dataset
	estpost sum logwages2015-RD2017
	esttab using "../tables/sumstats.tex", replace cells("mean(fmt(3) label(Mean)) sd(fmt(3) label(Std. Dev.))	min(fmt(3) label(Min.)) max(fmt(3) label(Max.)) count(fmt(0) label(Obs.))") label nonumber noobs  
	
* Some additional statistics
	tab TECH 
	tab PORT
	tab OWN
	
* Summary statistics by treated vs. non-trated group
	estpost sum $Pre $Post if FDI2016==0
	matrix mean0=e(mean)
	matrix list mean0
	matrix sd0=e(sd)
	matrix count0=e(count)
	
	estpost sum $Pre $Post if FDI2016==1
	matrix mean1=e(mean)
	matrix sd1=e(sd)
	matrix count1=e(count)

	estpost ttest $Pre $Post, by(FDI2016)
	estadd matrix mean0
	estadd matrix sd0 
	estadd matrix count0

	estadd matrix mean1 
	estadd matrix sd1 
	estadd matrix count1 

	esttab 	using "../tables/sumstats_bytreatment.tex", replace cells("mean0(fmt(3) label(Mean)) mean1(fmt(3) label(Mean)) b(label(Diff.) star) p(label(p-value))" ///
	"sd0(label(SD) par fmt(3)) sd1(label(SD) par fmt(3))")  label collabels("FDI=0: Mean(SD)" "FDI=1: Mean(SD)" "Mean diff." "P-value") unstack nonumber 


* Summary statistics by type of treatment
	
	estpost tabstat $Pre, by(FDITYPE2016) statistics(mean sd count) columns(statistics) nototal 
	esttab using "../tables/sumstats_pre_bytreatmentgroup.tex", replace cells("mean(fmt(3) label(Mean))"  "sd(fmt(3) par label(SD))") label unstack nonumber 
	*In main text
				
	estpost tabstat $Post, by(FDITYPE2016) statistics(mean sd count) columns(statistics) nototal 
	esttab  using "../tables/sumstats_post_bytreatmentgroup.tex", replace cells("mean(fmt(3) label(Mean))"  "sd(fmt(3) par label(SD))") label unstack nonumber 
	*In Appendix
				
	tab TECH FDI2016 , row
	tabout FDI2016 `var' using "../tables/sum_stat_frequ_`var'_new.tex",  c(freq col)  ////
	f(0c 1) style(tex) font(italic) replace
	}		
			
			
* Frequency Tables			
	foreach var in $T {
	tab `var' FDI2016 , col
	tabout  `var' FDI2016 using "../tables/sum_stat_frequ_`var'_new.tex",  c(freq col)  ////
	f(0c 1) style(tex) font(italic) replace
	}
	 
	foreach var in $T {
	tab `var' FDITYPE2016 , col
	tabout  `var' FDITYPE2016 using "../tables/sum_stat_frequ_`var'_FDI_type.tex",  c(freq col)  ///
	f(0c 1) style(tex) font(italic) replace
	}

		
* Figure of main variables by type of treatment (2015 vs. 2017)

	capture graph drop _all
	graph bar (mean) logwages2015 logwages2017, over(FDITYPE2016, nolabel) name(bar_wages) title("Wages, logs") legend(label(1 "Mean 2015") label(2 "Mean 2017"))
	graph bar (mean) logemp2015 logemp2017, over(FDITYPE2016, nolabel) name(bar_emp) title("Employment, logs")
	graph bar (mean) TFP2015 TFP2017, over(FDITYPE2016, nolabel) name(bar_tfp) title("TFP")
	graph bar (mean) EXP2015 EXP2017, over(FDITYPE2016, nolabel) name(barexp) title("Export intensity")
	graph bar (mean) RD2015 RD2017, over(FDITYPE2016, nolabel) name(bar_rd) title("R&D")
	graph bar (mean) DEBTS2015, over(FDITYPE2016, nolabel) name(bar_debt) title("Debt")
	grc1leg bar_wages bar_emp bar_tfp barexp bar_rd bar_debt, title("Pre- and post-treatment variables by treatment categories", size(small)) legendfrom(bar_wages)
	graph export write-up/graphs/bar_pre_post.eps
	graph drop _all
	

	