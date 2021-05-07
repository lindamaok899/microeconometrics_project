
clear all
cap log close
set matsize 11000

cd"../../Volumes/SDExtension/claud/00_promo/Kurse/micrometric methods (ASP)/microeconometrics_project"


log using "/stata_files/take_home.log", replace
use "../Datasets and do files/FDI_project.dta", clear

label variable RD2015 "R\&D dummy in 2015"
label variable RD2017 "R\&D dummy in 2017"

 
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
	

 log close
 
