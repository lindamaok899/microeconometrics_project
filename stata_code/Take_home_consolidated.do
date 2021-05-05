
clear all
cap log close
set matsize 11000

cd"../../Volumes/SDExtension/claud/00_promo/Kurse/micrometric methods (ASP)/microeconometrics_project"


log using "/stata_files/take_home.log", replace
use "../Datasets and do files/FDI_project.dta", clear

label variable RD2015 "R\&D dummy in 2015"
label variable RD2017 "R\&D dummy in 2017"

* Task 2: descriptives
 global T "TECH OWN PORT"
 global Pre "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015 RD2015"
 global Post "logwages2017 TFP2017 logemp2017 EXP2017 RD2017"
	
	* full dataset
	summarize 
	sutex2 FDI2016-RD2017, saving("write-up/tables/sum_stat.tex") replace ///
	caption(Summary statistics) minmax varlab
	
	* treated vs non-treated
	tabstat $Pre, by(FDI2016) statistics(mean semean) 
			* in text
	tabstat $Post, by(FDI2016) statistics(mean semean)
			* in Appendix
	
	foreach var in $char {
	tab FDI2016 `var', column
	tabout FDI2016 `var' using write-up/tables/sum_stat_frequ_`var'_new.tex, c(freq col) ///
	f(0c 1) style(tex) font(italic) replace
	}
		* port potentially in Appendix
	 
	* by treatment type
	tabstat $Pre, by(FDITYPE2016) statistics(mean semean)
		* in text 
	tabstat $Post, by(FDITYPE2016) statistics(mean semean)
		* Appendix
		
	foreach var in $char {
	tab FDITYPE2016 `var', column
	tabout FDITYPE2016 `var' using write-up/tables/sum_stat_frequ_`var'_new.tex, c(freq col) ///
	f(0c 1) style(tex) font(italic) replace
	}
		* Appendix
		
	* figure 2015 vs 2017
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
	 
	 * psmatch with proobit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , probit ),  osample(o1)
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , probit ) if o1 == 0
	 tebalance summarize
	 estout r(table) using "latex_code/figures_and_tables/3_balance_intprobit1o1.tex", style(tex) replace ///
	 substitute(_ \_) collabels("Diff:Raw" "Diff:Match" "Ratio:Raw" "Ratio:Match")
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_intprobit1o1.pdf", replace
		* balancenednes test still shows large differences here and there, 		
		
	 * psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) , logit )
	 teffects overlap, ptlevel(1) 
	 graph export  "latex_code/figures_and_tables/3_overlap_linearlogit1o1_reduced.pdf", replace
	 
	 * usign EXP2015_CAT, logit, 
	 teffects psmatch (logemp2017 )(FDI2016 c.($c)#i.($cat) , logit )
	 eststo ate_emp
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
	  
	 * WAGES 
	 teffects psmatch (logwages2017 )(FDI2016 c.($c)#i.($cat) , logit )
	 eststo ate_wage
	 
	 * construct Wages and employment effects output table
		esttab ate_emp ate_wage using "latex_code/figures_and_tables/3_ate.tex", replace ///
		cells(b(star fmt(%9.4f)) se(par fmt(%9.3f))) compress ///
		legend label mtitle  starlevels (* 0.1 ** 0.05 *** 0.01) ///
		title(Impact of FDI on Wages and Employment \label{ates}) ///
		coef(r1vs0.FDI2016 "ATE") mtitle("Log Employment" "Log Wages" )
	
* Task 4: use FDIType
	
	* look at doubly robust estimation results
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat))
	tebalance summarize
	teffects overlap, ptlevel(1)  
		* blancing is slightly worse, overlap still good, but potentially large bias due to large number of firms with score close to 0
	
	
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat) ) , osample(o6)
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat)) if o6==0 
	tebalance summarize
  
	teffects aipw (logwages2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat) ) ,  osample(o7)
	teffects aipw (logwages2017 c.($c)#i.($cat) )(FDITYPE2016 c.($c)#i.($cat) ) if o7==0 
	tebalance summarize
	
	
* Task 5: limitations
	
	logit FDI2016 c.($c)#i.($cat), robust
	predict pscore_doubly
	lab var pscore_doubly "Propensity score: doubly"
	
	drop if pscore_doubly > 0.9
	drop if pscore_doubly < 0.1
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat))
	
	drop if pscore_doubly > 0.6
	drop if pscore_doubly < 0.2
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat))
	
	
 log close
 

