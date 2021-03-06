** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name          4_quality_deaths.do
    //  project:                BNR
    //  analysts:               Jacqueline CAMPBELL
    //  date first created      19-SEP-2019
    // 	date last modified      19-SEP-2019
    //  algorithm task          Report on data entry quality
    //  status                  Completed

    
    ** General algorithm set-up
    version 16
    clear all
    macro drop _all
    set more off

    ** Initialising the STATA log and allow automatic page scrolling
    capture {
            program drop _all
    	drop _all
    	log close
    	}

    ** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "X:/The University of the West Indies/DataGroup - repo_data/data_p141"
    ** LOGFILES to unencrypted OneDrive folder (.gitignore set to IGNORE log files on PUSH to GitHub)
    local logpath X:/OneDrive - The University of the West Indies/repo_datagroup/repo_p141

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\4_quality_deaths.smcl", replace
** HEADER -----------------------------------------------------

***************
** LOAD DATASET  
***************
use "`datapath'\version01\3-output\2018_deaths_cleaned_dqi_dc"

count //2,719


*****************
** DATA QUALITY  
*****************
** Create quality report - per DA
** TOTAL records entered
//gen fieldtot=44 per record
gen abstot=_N
egen abstot_AH=count(ddda) if ddda==25
egen abstot_KG=count(ddda) if ddda==4
egen abstot_NR=count(ddda) if ddda==20
egen abstot_KWG=count(ddda) if ddda==13
egen abstot_TH=count(ddda) if ddda==14
egen abstot_intern=count(ddda) if ddda==98

** PERCENTAGE records entered
gen absper_AH=abstot_AH/abstot*100
gen absper_KG=abstot_KG/abstot*100
gen absper_NR=abstot_NR/abstot*100
gen absper_KWG=abstot_KWG/abstot*100
gen absper_TH=abstot_TH/abstot*100
gen absper_intern=abstot_intern/abstot*100

** TOTAL corrections
/*
egen corrtot_AH=total(corr_AH)
egen corrtot_KG=total(corr_KG)
egen corrtot_NR=total(corr_NR)
egen corrtot_KWG=total(corr_KWG)
egen corrtot_TH=total(corr_TH)
egen corrtot_intern=total(corr_intern)
gen corr_tot=corrtot_AH + corrtot_KG + corrtot_NR + corrtot_KWG + corrtot_TH + corrtot_intern
*/
egen rowtot=rowtotal(flag*) 
egen corrtot=total(rowtot) //224
egen rowtot_AH=rowtotal(flag*) if ddda==25 | tfddda==25
egen corrtot_AH=total(rowtot_AH) //105
egen rowtot_KG=rowtotal(flag*) if ddda==4 | tfddda==4
egen corrtot_KG=total(rowtot_KG) //60
egen rowtot_NR=rowtotal(flag*) if ddda==20 | tfddda==20
egen corrtot_NR=total(rowtot_NR) //22
egen rowtot_KWG=rowtotal(flag*) if ddda==13 | tfddda==13
egen corrtot_KWG=total(rowtot_KWG) //3
egen rowtot_TH=rowtotal(flag*) if ddda==14 | tfddda==14
egen corrtot_TH=total(rowtot_TH) //12
egen rowtot_intern=rowtotal(flag*) if ddda==98 | tfddda==98
egen corrtot_intern=total(rowtot_intern) //22

** PERCENTAGE corrections
gen corrper_AH=corrtot_AH/corrtot*100
gen corrper_KG=corrtot_KG/corrtot*100
gen corrper_NR=corrtot_NR/corrtot*100
gen corrper_KWG=corrtot_KWG/corrtot*100
gen corrper_TH=corrtot_TH/corrtot*100
gen corrper_intern=corrtot_intern/corrtot*100

** TOTAL records with corrections
egen corrrectot=count(rowtot) if rowtot!=0 & rowtot!=.
egen corrrectot_AH=count(rowtot_AH) if rowtot_AH!=0 & rowtot_AH!=.
egen corrrectot_KG=count(rowtot_KG) if rowtot_KG!=0 & rowtot_KG!=.
egen corrrectot_NR=count(rowtot_NR) if rowtot_NR!=0 & rowtot_NR!=.
egen corrrectot_KWG=count(rowtot_KWG) if rowtot_KWG!=0 & rowtot_KWG!=.
egen corrrectot_TH=count(rowtot_TH) if rowtot_TH!=0 & rowtot_TH!=.
egen corrrectot_intern=count(rowtot_intern) if rowtot_intern!=0 & rowtot_intern!=.

** PERCENTAGE records with corrections
gen corrrecper_AH=corrrectot_AH/corrrectot*100
gen corrrecper_KG=corrrectot_KG/corrrectot*100
gen corrrecper_NR=corrrectot_NR/corrrectot*100
gen corrrecper_KWG=corrrectot_KWG/corrrectot*100
gen corrrecper_TH=corrrectot_TH/corrrectot*100
gen corrrecper_intern=corrrectot_intern/corrrectot*100

** TOTAL records with no corrections
egen nocorrrectot=count(rowtot) if rowtot==0|rowtot==.
egen nocorrrectot_AH=count(rowtot_AH) if rowtot_AH==0|rowtot_AH==.
egen nocorrrectot_KG=count(rowtot_KG) if rowtot_KG==0|rowtot_KG==.
egen nocorrrectot_NR=count(rowtot_NR) if rowtot_NR==0|rowtot_NR==.
egen nocorrrectot_KWG=count(rowtot_KWG) if rowtot_KWG==0|rowtot_KWG==.
egen nocorrrectot_TH=count(rowtot_TH) if rowtot_TH==0|rowtot_TH==.
egen nocorrrectot_intern=count(rowtot_intern) if rowtot_intern==0|rowtot_intern==.

** PERCENTAGE records with no errors
gen nocorrrecper_AH=nocorrrectot_AH/nocorrrectot*100
gen nocorrrecper_KG=nocorrrectot_KG/nocorrrectot*100
gen nocorrrecper_NR=nocorrrectot_NR/nocorrrectot*100
gen nocorrrecper_KWG=nocorrrectot_KWG/nocorrrectot*100
gen nocorrrecper_TH=nocorrrectot_TH/nocorrrectot*100
gen nocorrrecper_intern=nocorrrectot_intern/nocorrrectot*100

** PERCENTAGE accuracy rate
gen accuracy_AH=(abstot_AH-corrtot_AH)/abstot_AH*100
gen accuracy_KG=(abstot_KG-corrtot_KG)/abstot_KG*100
gen accuracy_NR=(abstot_NR-corrtot_NR)/abstot_NR*100
gen accuracy_KWG=(abstot_KWG-corrtot_KWG)/abstot_KWG*100
gen accuracy_TH=(abstot_TH-corrtot_TH)/abstot_TH*100
gen accuracy_intern=(abstot_intern-corrtot_intern)/abstot_intern*100

** CREATE dataset with results to be used in pdf report
collapse abstot* absper* corrtot* corrper* corrrectot* corrrecper* nocorrrectot* nocorrrecper* accuracy*
format absper* corrper* corrrecper* nocorrrecper* accuracy* %9.0f
save "`datapath'\version01\3-output\2018_deaths_dqi_da" ,replace


				****************************
				*	    PDF REPORT  	   *
				*  QUANTITY & QUALITY: AH  *
				****************************

putpdf clear
putpdf begin

//Create a paragraph
putpdf paragraph
putpdf text ("Quantity & Quality Report"), bold
putpdf paragraph
putpdf text ("Death Data: 2018"), font(Helvetica,10)
putpdf paragraph
putpdf text ("Date Prepared: 23-Sep-2019"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Prepared by: JC using Stata & Redcap"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("AH"), bgcolor("pink") font(Helvetica,10)
putpdf paragraph, halign(center)
putpdf text ("QUANTITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum abstot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered: `sum'")
putpdf paragraph
qui sum abstot_AH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered by AH: `sum'")
putpdf paragraph
qui sum absper_AH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records entered by AH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph, halign(center)
putpdf text ("QUALITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum corrtot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections: `sum'")
putpdf paragraph
qui sum corrtot_AH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections for AH: `sum'")
putpdf paragraph
qui sum corrper_AH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL corrections for AH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum corrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections: `sum'")
putpdf paragraph
qui sum corrrectot_AH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections for AH: `sum'")
putpdf paragraph
qui sum corrrecper_AH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with corrections for AH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum nocorrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections: `sum'")
putpdf paragraph
qui sum nocorrrectot_AH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for AH: `sum'")
putpdf paragraph
qui sum nocorrrecper_AH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for AH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum accuracy_AH
local sum : display %2.0f `r(sum)'
putpdf text ("ACCURACY RATE for AH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
putpdf image  "`datapath'\version01\2-working\accuracy rate formula.png"
putpdf paragraph

putpdf save "`datapath'\version01\3-output\2019-09-23_quality_report_AH.pdf", replace
putpdf clear


				****************************
				*	    PDF REPORT  	   *
				*  QUANTITY & QUALITY: KG  *
				****************************

putpdf clear
putpdf begin

//Create a paragraph
putpdf paragraph
putpdf text ("Quantity & Quality Report"), bold
putpdf paragraph
putpdf text ("Death Data: 2018"), font(Helvetica,10)
putpdf paragraph
putpdf text ("Date Prepared: 23-Sep-2019"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Prepared by: JC using Stata & Redcap"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("KG"), bgcolor("pink") font(Helvetica,10)
putpdf paragraph, halign(center)
putpdf text ("QUANTITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum abstot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered: `sum'")
putpdf paragraph
qui sum abstot_KG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered by KG: `sum'")
putpdf paragraph
qui sum absper_KG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records entered by KG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph, halign(center)
putpdf text ("QUALITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum corrtot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections: `sum'")
putpdf paragraph
qui sum corrtot_KG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections for KG: `sum'")
putpdf paragraph
qui sum corrper_KG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL corrections for KG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum corrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections: `sum'")
putpdf paragraph
qui sum corrrectot_KG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections for KG: `sum'")
putpdf paragraph
qui sum corrrecper_KG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with corrections for KG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum nocorrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections: `sum'")
putpdf paragraph
qui sum nocorrrectot_KG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for KG: `sum'")
putpdf paragraph
qui sum nocorrrecper_KG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for KG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum accuracy_KG
local sum : display %2.0f `r(sum)'
putpdf text ("ACCURACY RATE for KG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
putpdf image  "`datapath'\version01\2-working\accuracy rate formula.png"
putpdf paragraph

putpdf save "`datapath'\version01\3-output\2019-09-23_quality_report_KG.pdf", replace
putpdf clear


				****************************
				*	    PDF REPORT  	   *
				*  QUANTITY & QUALITY: NR  *
				****************************

putpdf clear
putpdf begin

//Create a paragraph
putpdf paragraph
putpdf text ("Quantity & Quality Report"), bold
putpdf paragraph
putpdf text ("Death Data: 2018"), font(Helvetica,10)
putpdf paragraph
putpdf text ("Date Prepared: 23-Sep-2019"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Prepared by: JC using Stata & Redcap"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("NR"), bgcolor("pink") font(Helvetica,10)
putpdf paragraph, halign(center)
putpdf text ("QUANTITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum abstot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered: `sum'")
putpdf paragraph
qui sum abstot_NR
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered by NR: `sum'")
putpdf paragraph
qui sum absper_NR
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records entered by NR: `sum'%"), bold bgcolor("yellow")
putpdf paragraph, halign(center)
putpdf text ("QUALITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum corrtot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections: `sum'")
putpdf paragraph
qui sum corrtot_NR
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections for NR: `sum'")
putpdf paragraph
qui sum corrper_NR
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL corrections for NR: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum corrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections: `sum'")
putpdf paragraph
qui sum corrrectot_NR
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections for NR: `sum'")
putpdf paragraph
qui sum corrrecper_NR
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with corrections for NR: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum nocorrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections: `sum'")
putpdf paragraph
qui sum nocorrrectot_NR
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for NR: `sum'")
putpdf paragraph
qui sum nocorrrecper_NR
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for NR: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum accuracy_NR
local sum : display %2.0f `r(sum)'
putpdf text ("ACCURACY RATE for NR: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
putpdf image  "`datapath'\version01\2-working\accuracy rate formula.png"
putpdf paragraph

putpdf save "`datapath'\version01\3-output\2019-09-23_quality_report_NR.pdf", replace
putpdf clear


				****************************
				*	    PDF REPORT  	   *
				*  QUANTITY & QUALITY: KWG *
				****************************

putpdf clear
putpdf begin

//Create a paragraph
putpdf paragraph
putpdf text ("Quantity & Quality Report"), bold
putpdf paragraph
putpdf text ("Death Data: 2018"), font(Helvetica,10)
putpdf paragraph
putpdf text ("Date Prepared: 23-Sep-2019"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Prepared by: JC using Stata & Redcap"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("KWG"), bgcolor("pink") font(Helvetica,10)
putpdf paragraph, halign(center)
putpdf text ("QUANTITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum abstot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered: `sum'")
putpdf paragraph
qui sum abstot_KWG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered by KWG: `sum'")
putpdf paragraph
qui sum absper_KWG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records entered by KWG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph, halign(center)
putpdf text ("QUALITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum corrtot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections: `sum'")
putpdf paragraph
qui sum corrtot_KWG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections for KWG: `sum'")
putpdf paragraph
qui sum corrper_KWG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL corrections for KWG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum corrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections: `sum'")
putpdf paragraph
qui sum corrrectot_KWG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections for KWG: `sum'")
putpdf paragraph
qui sum corrrecper_KWG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with corrections for KWG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum nocorrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections: `sum'")
putpdf paragraph
qui sum nocorrrectot_KWG
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for KWG: `sum'")
putpdf paragraph
qui sum nocorrrecper_KWG
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for KWG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum accuracy_KWG
local sum : display %2.0f `r(sum)'
putpdf text ("ACCURACY RATE for KWG: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
putpdf image  "`datapath'\version01\2-working\accuracy rate formula.png"
putpdf paragraph

putpdf save "`datapath'\version01\3-output\2019-09-23_quality_report_KWG.pdf", replace
putpdf clear


				****************************
				*	    PDF REPORT  	   *
				*  QUANTITY & QUALITY: TH  *
				****************************

putpdf clear
putpdf begin

//Create a paragraph
putpdf paragraph
putpdf text ("Quantity & Quality Report"), bold
putpdf paragraph
putpdf text ("Death Data: 2018"), font(Helvetica,10)
putpdf paragraph
putpdf text ("Date Prepared: 23-Sep-2019"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Prepared by: JC using Stata & Redcap"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("TH"), bgcolor("pink") font(Helvetica,10)
putpdf paragraph, halign(center)
putpdf text ("QUANTITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum abstot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered: `sum'")
putpdf paragraph
qui sum abstot_TH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered by TH: `sum'")
putpdf paragraph
qui sum absper_TH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records entered by TH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph, halign(center)
putpdf text ("QUALITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum corrtot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections: `sum'")
putpdf paragraph
qui sum corrtot_TH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections for TH: `sum'")
putpdf paragraph
qui sum corrper_TH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL corrections for TH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum corrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections: `sum'")
putpdf paragraph
qui sum corrrectot_TH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections for TH: `sum'")
putpdf paragraph
qui sum corrrecper_TH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with corrections for TH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum nocorrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections: `sum'")
putpdf paragraph
qui sum nocorrrectot_TH
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for TH: `sum'")
putpdf paragraph
qui sum nocorrrecper_TH
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for TH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum accuracy_TH
local sum : display %2.0f `r(sum)'
putpdf text ("ACCURACY RATE for TH: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
putpdf image  "`datapath'\version01\2-working\accuracy rate formula.png"
putpdf paragraph

putpdf save "`datapath'\version01\3-output\2019-09-23_quality_report_TH.pdf", replace
putpdf clear


				*************************
				*	    PDF REPORT  	*
				*  QUANTITY & QUALITY:  *
                *         intern        *
				*************************

putpdf clear
putpdf begin

//Create a paragraph
putpdf paragraph
putpdf text ("Quantity & Quality Report"), bold
putpdf paragraph
putpdf text ("Death Data: 2018"), font(Helvetica,10)
putpdf paragraph
putpdf text ("Date Prepared: 23-Sep-2019"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Prepared by: JC using Stata & Redcap"),  font(Helvetica,10)
putpdf paragraph
putpdf text ("Intern"), bgcolor("pink") font(Helvetica,10)
putpdf paragraph, halign(center)
putpdf text ("QUANTITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum abstot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered: `sum'")
putpdf paragraph
qui sum abstot_intern
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records entered by intern: `sum'")
putpdf paragraph
qui sum absper_intern
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records entered by intern: `sum'%"), bold bgcolor("yellow")
putpdf paragraph, halign(center)
putpdf text ("QUALITY"), bold font(Helvetica,20,"blue")
putpdf paragraph
qui sum corrtot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections: `sum'")
putpdf paragraph
qui sum corrtot_intern
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL corrections for intern: `sum'")
putpdf paragraph
qui sum corrper_intern
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL corrections for intern: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum corrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections: `sum'")
putpdf paragraph
qui sum corrrectot_intern
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with corrections for intern: `sum'")
putpdf paragraph
qui sum corrrecper_intern
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with corrections for intern: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum nocorrrectot
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections: `sum'")
putpdf paragraph
qui sum nocorrrectot_intern
local sum : display %3.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for intern: `sum'")
putpdf paragraph
qui sum nocorrrecper_intern
local sum : display %2.0f `r(sum)'
putpdf text ("TOTAL records with no corrections for intern: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
qui sum accuracy_intern
local sum : display %2.0f `r(sum)'
putpdf text ("ACCURACY RATE for intern: `sum'%"), bold bgcolor("yellow")
putpdf paragraph
putpdf image  "`datapath'\version01\2-working\accuracy rate formula.png"
putpdf paragraph

putpdf save "`datapath'\version01\3-output\2019-09-23_quality_report_intern.pdf", replace
putpdf clear


save "`datapath'\version01\3-output\2018_deaths_report_dqi_da" ,replace
notes _dta :These data prepared from BB national death register & BNR (Redcap) deathdata database
label data "BNR Death Data Quality Report"
