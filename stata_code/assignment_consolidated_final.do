clear all
cap log close
set matsize 11000

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
	esttab using "latex_code/figures_and_tables/sumstats.tex", replace cells("mean(fmt(3) label(Mean)) sd(fmt(3) label(Std. Dev.))	min(fmt(3) label(Min.)) max(fmt(3) label(Max.)) count(fmt(0) label(Obs.))") label nonumber noobs  
	
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

	esttab 	using "latex_code/figures_and_tables/sumstats_bytreatment.tex", replace cells("mean0(fmt(3) label(Mean)) mean1(fmt(3) label(Mean)) b(label(Diff.) star) p(label(p-value))" ///
	"sd0(label(SD) par fmt(3)) sd1(label(SD) par fmt(3))")  label collabels("FDI=0: Mean(SD)" "FDI=1: Mean(SD)" "Mean diff." "P-value") unstack nonumber 


* Summary statistics by type of treatment
	
	estpost tabstat $Pre, by(FDITYPE2016) statistics(mean sd count) columns(statistics) nototal 
	esttab using "latex_code/figures_and_tables/sumstats_pre_bytreatmentgroup.tex", replace cells("mean(fmt(3) label(Mean))"  "sd(fmt(3) par label(SD))") label unstack nonumber 
	*In main text
				
	estpost tabstat $Post, by(FDITYPE2016) statistics(mean sd count) columns(statistics) nototal 
	esttab  using "latex_code/figures_and_tables/sumstats_post_bytreatmentgroup.tex", replace cells("mean(fmt(3) label(Mean))"  "sd(fmt(3) par label(SD))") label unstack nonumber 
	*In Appendix
				
	tab TECH FDI2016 , row
	tabout FDI2016 `var' using "latex_code/figures_and_tables/sum_stat_frequ_`var'_new.tex",  c(freq col)  ////
	f(0c 1) style(tex) font(italic) replace
	}		
			
			
* Frequency Tables			
	foreach var in $T {
	tab `var' FDI2016 , col
	tabout  `var' FDI2016 using "latex_code/figures_and_tables/sum_stat_frequ_`var'_new.tex",  c(freq col)  ////
	f(0c 1) style(tex) font(italic) replace
	}
	 
	foreach var in $T {
	tab `var' FDITYPE2016 , col
	tabout  `var' FDITYPE2016 using "latex_code/figures_and_tables/sum_stat_frequ_`var'_FDI_type.tex",  c(freq col)  ///
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
	
	
 * Task 3: use outcome vars loemp and logwages

***Generate categorical variable with export intensity before treatment
	gen EXP2015_CAT = .
	replace EXP2015_CAT = 0 if EXP2015==0
	replace EXP2015_CAT = 1 if EXP2015>0 & EXP2015<0.25
	replace EXP2015_CAT = 2 if EXP2015<0.5 & EXP2015>=0.25
	label var EXP2015_CAT "Export intensity 2015, category"
	label define EXP2015_CAT 0 "no exports" 1 "<25%" 2 ">25%" 

	 global D "RD2015 TECH OWN PORT"
	 global C "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015"
	 global c "logwages2015 TFP2015 logemp2015 DEBTS2015"
	 global cat "RD2015 TECH OWN PORT EXP2015_CAT"
	 
  
	 * show imbalance across treatment
	 logit FDI2016 c.($C) i.($D) , robust
		eststo T1
		esttab T1 using "latex_code/figures_and_tables/3_selection.tex", replace ///
		title(Logit estimation results of FDI on pre-treatment observables \label{selection_logit}) ///
		cells("b(star fmt(%9.4f)) se(par fmt(%9.3f))") compress ///
		starlevels (* 0.1 ** 0.05 *** 0.01) ///
		label
		
	 * EMPLOYMENT:  
	 * psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit )
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_linearlogit1o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match") label
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_linearlogit1o1.pdf", replace
	 
	 * psmatch with logit and interactions to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , logit )
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_intlogit1o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_intlogit1o1.pdf", replace
	 		* overlap improves slightly, balance improves also. both still not convincing
	 
	 * psmatch with probit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , probit ),  osample(o1)
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , probit ) if o1 == 0
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_intprobit1o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_intprobit1o1.pdf", replace
		* balancenednes test still shows large differences here and there, 		
		
	 * psmatch with logit to estimate propensity score on reduced sample
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) , logit )
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_linearlogit1o1_reduced.pdf", replace
	 
	 * usign EXP2015_CAT, logit, 
	 teffects psmatch (logemp2017 )(FDI2016 c.($c)#i.($cat) , logit )
	 eststo ate_emp_ps
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_intcatlogit1o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_intcatlogit1o1.pdf", replace
		* I found best balancedness for just taking the nearest neighbour instead of the four nearest, or four nearest and a caliper
		* overlap is insensitive to this manipulation (obviously)
	 
	 * usign EXP2015_CAT, logit, nn(2)
	 teffects psmatch (logemp2017 )(FDI2016 c.($c)#i.($cat) , logit ), nneighbor(2)
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_intcatlogit2o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_intcatlogit2o1.pdf", replace
		* no change in overlap, but balancedness worsens
	 
	 * usign EXP2015_CAT, logit, nn(4) caliper
	 teffects psmatch (logemp2017 )(FDI2016 c.($c)#i.($cat) , logit ), nneighbor(4) caliper(.1)
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_intcatlogit4o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_linearlogit4o1.pdf", replace 
		* no change in overlap, but balancedness worsens
	    
		
	* Robustness checks for functional specification
	* source: https://www.stata.com/stata-news/news29-1/double-robust-treatment-effects/
	
	*RA
	teffects ra (logemp2017 c.($c)#i.($cat) )(FDI2016)
	eststo ate_emp_ra
	tebalance summarize
	 *the propensity scoring model is probably not correctly specified as seen with the high standard errors
	
	* ipw
	teffects ipw  (logemp2017 )(FDI2016 c.($c)#i.($cat) )
	eststo ate_emp_ipw
	tebalance summarize
	
	*aipw
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	eststo ate_emp_aipw
	tebalance summarize
	estout r(table) using "latex_code/figures_and_tables/3_balance_aipw.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	
	* ipwra
	teffects ipwra (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	eststo ate_emp_ipwra
	  
	** Output results: employment effects
	esttab ate_emp_ps ate_emp_ra ate_emp_ipw ate_emp_aipw ate_emp_ipwra using "latex_code/figures_and_tables/3_ate_emp.tex", replace ///
		cells(b(star fmt(%9.4f)) se(par fmt(%9.3f))) compress ///
		legend label mtitle  starlevels (* 0.1 ** 0.05 *** 0.01) ///
		title(Impact of FDI on Employment in 2017 (logs) \label{ates_emp}) ///
		keep(r1vs0.FDI2016) coef(r1vs0.FDI2016 "ATE") mtitle("psmatch" "RA" "IPW" "AIPW" "IPWRA")
	  
	  
	* WAGES
	*--------
	teffects psmatch (logwages2017 )(FDI2016 c.($c)#i.($cat) , logit )
	eststo ate_wag_ps
	 
	*RA
	teffects ra (logwages2017 c.($c)#i.($cat) )(FDI2016)
	eststo ate_wag_ra
	 *the propensity scoring model is probably not correctly specified as seen with the high standard errors
	
	* ipw
	teffects ipw  (logwages2017 )(FDI2016 c.($c)#i.($cat) )
	eststo ate_wag_ipw
	tebalance summarize
	
	*aipw
	teffects aipw (logwages2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	eststo ate_wag_aipw
	tebalance summarize
	
	* ipwra
	teffects ipwra (logwages2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	eststo ate_wag_ipwra  
	  
	** Output results: wages
	esttab ate_wag_ps ate_wag_ra ate_wag_ipw ate_wag_aipw ate_wag_ipwra using "latex_code/figures_and_tables/3_ate_wag.tex", replace ///
		cells(b(star fmt(%9.4f)) se(par fmt(%9.3f))) compress ///
		legend label mtitle  starlevels (* 0.1 ** 0.05 *** 0.01) ///
		title(Impact of FDI on Wages in 2017 (logs) \label{ates_wag}) ///
		keep(r1vs0.FDI2016) coef(r1vs0.FDI2016 "ATE") mtitle("psmatch" "RA" "IPW" "AIPW" "IPWRA")

* Task 4: use FDITYPE2016 variable to re-estimate FDI by type
	
	* ipw: estimates effects on the treatement model
	** no interactions
	teffects ipw  (logemp2017 )(FDITYPE2016 c.($c) i.($cat) )
	tebalance summarize	
	
	** interactions
	teffects ipw  (logemp2017 )(FDITYPE2016 c.($c)#i.($cat) ),  osample(o5)
	teffects ipw (logemp2017)(FDITYPE2016 c.($c)#i.($cat) ) if o5==0
	tebalance summarize	
	teffects overlap, ptlevel(1)

	* aipw: estimates effects on the treatement and outcome models
	** interactions
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat) ) , osample(o6)
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat)) if o6==0 
	tebalance summarize
	teffects overlap, ptlevel(1)
	
	
	
	* Wages regression using AIPW
	teffects aipw (logwages2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat) ) , osample(o7)
	teffects aipw (logwages2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat) ) if o7==0 
	tebalance summarize
	
	
	
	
 log close
