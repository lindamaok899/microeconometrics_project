
clear all
cap log close
set matsize 11000


*cd "SDExtension:\claud\00_promo\Kurse\micrometric methods (ASP)\Datasets and do files"

log using take_home, replace
use FDI_project.dta, clear

* Task 2: descriptives
 global T "TECH OWN PORT"
 global Pre "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015 RD2015"
 global Post "logwages2017 TFP2017 logemp2017 EXP2017 RD2017"
	
	* full dataset
	summarize 
	ssc install sutex2
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
	
	***Generate categorical variable with export intensity before treatment
	gen EXP2015_CAT = .
	replace EXP2015_CAT = 0 if EXP2015==0
	replace EXP2015_CAT = 1 if EXP2015>0 & EXP2015<0.25
	replace EXP2015_CAT = 2 if EXP2015<0.5 & EXP2015>=0.25
	label var EXP2015_CAT "Export intensity 2015, category"
	label define EXP2015_CAT 0 "no exports" 1 "<25%" 2 ">25%"
 
* Task 3: use outcome vars loemp and logwages
 global D "RD2015 TECH OWN PORT"
 global C "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015"
 global c "logwages2015 TFP2015 logemp2015 DEBTS2015"
 global cat "RD2015 TECH OWN PORT EXP2015_CAT"
 
	 * show imbalance across treatment
	 logit FDI2016 c.($C)#i.($D)
 
	 * EMPLOYMENT: 
	 * psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit )
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 
	 * NNM(2) psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit ) , nneighbor(2)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 
	 * NNM(4) caliper .1 psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D), logit), nneighbor(4) caliper(.1)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
	 
	  * NNM(2) psmatch with probit 
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , probit), nneighbor(2) osample(o1)
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , probit) if o1 == 0, nneighbor(2)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_3.pdf, replace
	 
	 * NNM(4) caliper .1 psmatch with logit and interaction effects to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , logit), nneighbor(4) caliper(.1)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
	 
	 * NNM(4) caliper .1 psmatch with probit and interaction effects to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , probit), nneighbor(4) caliper(.1) osample(o1)
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , probit) if o1 == 0, nneighbor(4) caliper(.1)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
	 
	 
	 * usign EXP2015_CAT, logit, 
	 teffects psmatch (logemp2017 )(FDI2016 c.($c)#i.($cat) , logit )
	 tebalance summarize 
	 teffects overlap, ptlevel(1) 
		* I found best balancedness for just taking the nearest neighbour instead of the four nearest, or four nearest and a caliper
		* overlap is insensitive to this manipulation (obviously)
		
		
	* Robustness checks for our estimation above
	* source: https://www.stata.com/stata-news/news29-1/double-robust-treatment-effects/
	
	*RA
	teffects ra (logemp2017 c.($c)#i.($cat) )(FDI2016)
	tebalance summarize
	 *the propensity scoring model is probably not correctly specified as seen with the high standard errors
	
	* ipw
	teffects ipw  (logemp2017 )(FDI2016 c.($c)#i.($cat) )
	tebalance summarize
	
	*aipw
	teffects aipw (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	tebalance summarize
	
	* ipwra
	teffects ipwra (logemp2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	 
	 * WAGES 
	 *estimate this with the estomator of choice later after discussion on Thursday
	  teffects aipw (logwages2017 c.($c)#i.($cat) )(FDI2016 c.($c)#i.($cat) )
	 tebalance summarize

	 
	 
	 graph export  th_t3_2.pdf, replace
 

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
 

N = 11.323
Nvars = 17


identifiers: 
firm
OWN
TECH
PORT

Treatment vars: 
FDI2016
FDITYPE2016

potential outcome vars: 
logwages2017  out1
TFP2017
logemp2017	out2
EXP2017
RD2017


pre-treatment indicators:
logwages2015
TFP2015
logemp2015
DEBTS2015
EXP2015
RD2015
