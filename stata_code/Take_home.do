
set more 1
clear 
cap log close
log using computer_class_2, replace
use FDI_project.dta, clear

* Task 2: descriptives
 global T "TECH OWN PORT"
 global Pre "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015 RD2015"
 global Post "logwages2017 TFP2017 logemp2017 EXP2017 RD2017"
	
	* full dataset
	summarize 
	
	* treated vs non-treated
	tabstat $Pre, by(FDI2016) statistics(mean semean) 
	tabstat $Post, by(FDI2016) statistics(mean semean)
 
	tab TECH FDI2016, col
	tab OWN FDI2016, col
		* also needed? tab PORT FDI2016, col 
	
	* by treatment type
	tabstat $Pre, by(FDITYPE2016) statistics(mean semean)
	tabstat $Post, by(FDITYPE2016) statistics(mean semean)
	
	tab TECH FDITYPE2016, col
	tab OWN FDITYPE2016, col
	tab PORT FDITYPE2016, col

 
* Task 3: use outcome vars loemp and logwages
 global D "RD2015 TECH OWN PORT"
 global C "logwages2015 TFP2015 logemp2015 EXP2015 DEBTS2015"
 
	 * EMPLOYMENT: 
	 * NNM(2) psmatch with  logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit ), nneighbor(2)
	 tebalance summarize
		* we want differences matched to be low otimall below 5% but for sure below 20%
		* if these numbers are good then look at coefficient for treatment effect size (exp(coef-1)*100% 
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_1.pdf, replace

	 * NNM(4) caliper .1 psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit), nneighbor(4) caliper(.1)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
	 
	 * NNM(4) caliper .1 psmatch with logit and interaction effects to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C)#i.($D) , logit), nneighbor(4) caliper(.1)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
	 
	 
	 * NNM(4) caliper .05 psmatch with logit to estimate propensity score
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit), nneighbor(4) caliper(.05) osample(o2)
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , logit) if o2 == 0, nneighbor(4) caliper(.05)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
	 
	 * NNM(2) psmatch with probit 
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , probit), nneighbor(2) osample(o1)
	 teffects psmatch (logemp2017 )(FDI2016 c.($C) i.($D) , probit) if o1 == 0, nneighbor(2)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_3.pdf, replace

	 
	 * WAGES 
	 * NNM(2) psmatch with  logit to estimate propensity score
	 teffects psmatch (logwages2017 )(FDI2016 c.($C)#i.($D) , logit), nneighbor(4) caliper(.1)
	 tebalance summarize
	 teffects overlap, ptlevel(1)  
	 graph export  th_t3_2.pdf, replace
 

* Task 4: use FDIType

	teffects aipw (logemp2017 c.($C)#i.($D) )(FDITYPE2016 c.($C)#i.($D) ) ,  osample(o5)
	teffects aipw (logemp2017 c.($C)#i.($D) )(FDITYPE2016 c.($C)#i.($D) ) if o5==0 
	tebalance summarize
  
	teffects aipw (logemp2017 c.($C) i.($D) )(FDITYPE2016 c.($C) i.($D) ) , osample(o6)
	teffects aipw (logemp2017 c.($C) i.($D) )(FDITYPE2016 c.($C) i.($D) ) if o6==0 
	tebalance summarize
  
	teffects aipw (logwages2017 c.($C) i.($D) )(FDITYPE2016 c.($C) i.($D) ) ,  osample(o7)
	teffects aipw (logwages2017 c.($C) i.($D) )(FDITYPE2016 c.($C) i.($D) ) if o7==0 
	tebalance summarize
	
	teffects aipw (logwages2017 c.($C)#i.($D) )(FDITYPE2016 c.($C)#i.($D) ) ,  osample(o8)
	teffects aipw (logwages2017 c.($C)#i.($D) )(FDITYPE2016 c.($C)#i.($D) ) if o8==0 
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
