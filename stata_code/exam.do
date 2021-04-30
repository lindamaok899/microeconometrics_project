
set more 1
clear 
cap log close
log using exam_project, replace
use FDI_project.dta, clear

*Section 3:

** The effect of FDI on employment

global D " OWN TECH PORT RD2015"
global Z " TFP2015 logemp2015 EXP2015 DEBTS2015"
global X " logwages2015 TFP2015 logemp2015 DEBTS2015 EXP2015 RD2015 i.OWN i.PORT i.TECH i.RD2015"

* Estimate a logit model on pre-treatement variables to get a a sense of the balance
logit FDI2016 $X

* Estimate logit without interactions to immprove estimation 
teffects psmatch (logemp2017 )(FDI2016 $X , logit )
tebalance summarize
teffects overlap, ptlevel(1)  
graph export  balance_1.pdf, replace


* Estimate logit with interactions to  further improve estimation
teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) , logit )
tebalance summarize
teffects overlap, ptlevel(1)  
graph export  balance_2.pdf, replace


* Estimate NNM(2) psmatch with  logit to estimate propensity score
teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) , logit ), nneighbor(2)
tebalance summarize
teffects overlap, ptlevel(1)  
graph export  balance_3.pdf, replace

* Estimate NNM(2) psmatch with probit to estimate propensity score
teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) ,  probit), nneighbor(2)

* use osample() option to identify observations outside overlap region
teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) ,  probit), nneighbor(2) osample(o1) 
teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) ,  probit) if o1 == 0 , ///
nneighbor(2)  
tebalance summarize
teffects overlap, ptlevel(1)  
graph export  balance_4.pdf, replace


 * Now, we extend our NNM specification to 4, and add a calipher to mitigate matching 
 ** too dissimilar pairs:
 
 * NNM(4) psmatch with  logit and caliper = 0.10
 teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) ,  logit ),  ///
           nneighbor(4) caliper(.10) 
 tebalance summarize
 teffects overlap, ptlevel(1)  
 graph export  balance_5.pdf, replace

	   
* NNM(4) psmatch with  logit and caliper = 0.05
 teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) ,  logit ),  ///
           nneighbor(4) caliper(.05) osample(o2)

teffects psmatch (logemp2017 )(FDI2016 c.($Z)#i.($D) ,  logit ) if o2== 0,  ///
           nneighbor(4) caliper(.05)
tebalance summarize
		   
******* START HERE TOMORROW *********
		   * LEFT OFF AT TRYING TO FIGURE OUT WHY A CALIPHER OF 0.05 DOES NOT YILED A GOOD ESTIMATION FOR THE MODEL???
		   * TRY AIPW
	   

	   
	   
* Section 4

gen Demp = logemp2017 - logemp2015

teffects aipw (Demp c.($Z)#i.($D) ) (FDI2016 c.($Z)#i.($D) ) , aequations  // display auxiliary-equation results
tebalance summarize
teffects overlap, ptlevel(1)  
graph export  balance_6.pdf, replace


* Task 4 :  AIPW
* generate nonnegative log variable

teffects aipw (logemp2017 c.($Z)#i.($D) , flogit)(FDI2016 c.($Z)#i.($D) ) 

teffects aipw (EXP2009 c.($Z)#i.($D), flogit)(SUB2008 c.($Z)#i.($D)  ) 

* Task 5

teffects aipw (TFP2009 c.($Z)#i.($D) )(SUBTYPE c.($Z)#i.($D) ) ,  osample(o5)

teffects aipw (TFP2009 c.($Z)#i.($D) )(SUBTYPE c.($Z)#i.($D) ) if o5==0 

tebalance summarize
  
  log close
 
 
 
 
 
 