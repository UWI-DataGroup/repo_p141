** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name          2_clean_deaths.do
    //  project:                BNR
    //  analysts:               Jacqueline CAMPBELL
    //  date first created      05-SEP-2019
    // 	date last modified      05-SEP-2019
    //  algorithm task          Clean death data
    //  status                  Completed
    //  objectve                To have one dataset with cleaned 2018 death data.
    //  note 1                  Duplicate 2017 deaths checked using 2018 dataset against 2008-2017 dataset 
    //                          (see '2017 deaths_combined_20190828.xlsx')
    //  note 2                  Duplicates within 2018 deaths checked and identified using conditioinal formatting and 
    //                          field 'namematch' in 2018 dataset (see 'BNRDeathData2018_DATA_2019-08-28_1101_excel.xlsx')
    //  note 3                  Cleaned 2018 dataset to be merged with 2008-2017 death dataset; 
    //                          Redcap database with ALL cleaned deaths to be created.

    
    ** General algorithm set-up
    version 15
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
    log using "`logpath'\2_clean_deaths.smcl", replace
** HEADER -----------------------------------------------------

***************
** LOAD DATASET  
***************
use "`datapath'\version01\2-working\2018_deaths_prepped_dp"

count //3,343


*****************
** DATA QUALITY  
*****************
** Create quality report - corrections per DA
gen corr_AH=0 //DA code=25
gen corr_KG=0 //DA code=04
gen corr_NR=0 //DA code=20
gen corr_TH=0 //DA code=14
gen corr_intern=0 //DA code=98


*****************
** DATA CLEANING  
*****************
** CLEAN each variable according to below consistency checks and the quality rules in DeathData REDCap database

** Corrections found manually in excel input file prior to import to Stata as some dates were not valid for inclusion in 2019 Redcap deathdb
replace dod=d(09mar2018) if record_id==382 //1 change
replace corr_intern=+1 if record_id==382 //1 change
replace dod=d(31dec2018) if record_id==600 //1 change
replace corr_NR=+1 if record_id==600 //1 change
replace dod=d(19jan2018) if record_id==1909 //1 change
replace corr_intern=+1 if record_id==1909 //1 change
replace dod=d(12aug2018) if record_id==2963 //1 change
replace corr_AH=+1 if record_id==2963 //1 change

************************
**  DEATH CERTIFICATE **
**        FORM        **
************************
sort record_id
** record_id (auto-generated by REDCap)
** (1) missing
count if record_id==. //0

** event (auto-generated by REDCap)
** (2) missing
count if event==. //0

** dddoa: Y-M-D H:M, readonly
** (3) missing
count if event==1 & dddoa==. //0

** ddda
** (4) missing
count if event==1 & ddda==. //0

** odda
** (5) missing
count if ddda==98 & odda=="" //0
** (6) invalid
count if ddda!=98 & odda!="" //8
//list record_id event dddoa ddda odda if ddda!=98 & odda!=""
replace ddda=25 if ddda!=98 & odda!="" //8 changes; no quality assessment as this field initially didn't have AH's code
replace odda="" if ddda!=98 & odda!="" //8 changes

** certtype: 1=MEDICAL 2=POST MORTEM 3=CORONER 99=ND, required
** (7) missing
count if event==1 & certtype==. //1
//list record_id event dddoa ddda certtype if event==1 & certtype==.
replace certtype=1 if record_id==659 //1 change
replace corr_AH=+1 if record_id==659 //1 change

** regnum: Text, if missing=9999
** (8) missing
count if event==1 & regnum==.|event==1 & regnum==0 //0
** (9) invalid
count if event==1 & regnum>9999 //0

** district: 1=A 2=B 3=C 4=D 5=E 6=F
** (10) missing
count if event==1 & district==. //0

** pname: Text, if missing=99
** (11) missing
count if event==1 & pname=="" //0
** (12) invalid
count if event==1 & regexm(pname, "[a-z]") //3
//list record_id event ddda pname if event==1 & regexm(pname, "[a-z]")
replace pname= subinstr(pname,"Suspected to be ","",.) if record_id==2766
replace corr_intern=+1 if record_id==2766 //1 change
replace pname=upper(pname) //2 changes
replace corr_KG=+1 if record_id==360 //1 change
replace corr_AH=+1 if record_id==1122 //1 change
** (13) duplicate
sort pname
quietly by pname:  gen dup = cond(_N==1,0,_n)
sort pname
count if event==1 & dup>0  //90 - some are exact replicas as AH seem to import data twice from Redcap BNRDeathData db into BNRDeathData_2018 db
sort pname record_id
STOPPED HERE//list record_id dddoa ddda pname regnum district nrn if event==1 & dup>0
replace namematch=1 if record_id==1807|record_id==2489|record_id==2876|record_id==3015|record_id==2147|record_id==2811 ///
					   |record_id==909|record_id==2003|record_id==272|record_id==1544|record_id==1046|record_id==3078 ///
					   |record_id==437|record_id==2936|record_id==2004|record_id==2910 // changes

drop if record_id==420|record_id==822|record_id==1027|record_id==404|record_id==421|record_id==416|record_id==457 // changes
drop dup



** (10) address: Text, if missing=99
label var address "Deceased's Address"

** (11) parish
label var parish "Deceased's Parish"
label define parish_lab 1 "Christ Church" 2 "St. Andrew" 3 "St. George" 4 "St. James" 5 "St. John" 6 "St. Joseph" ///
						7 "St. Lucy" 8 "St. Michael" 9 "St. Peter" 10 "St. Philip" 11 "St. Thomas" 99 "ND", modify
label values parish parish_lab

** (12) sex:	1=Male 2=Female 99=ND
label var sex "Sex"
label define sex_lab 1 "Male" 2 "Female" 99 "ND", modify
label values sex sex_lab

** (13) age: Integer - min=0, max=999
label var age "Age"

** (14) agetxt
label var agetxt "Age Qualifier"
label define agetxt_lab 1 "Minutes" 2 "Hours" 3 "Days" 4 "Weeks" 5 "Months" 6 "Years" 99 "ND", modify
label values agetxt agetxt_lab

** (15) nrnnd: 1=Yes 2=No
label var nrnnd "Is National ID # documented?"

** (16) nrn: dob-####, partial missing=dob-9999, if missing=.
label var nrn "National ID #"
format nrn %12.0g

** (17) mstatus: 1=Single 2=Married 3=Separated/Divorced 4=Widowed/Widow/Widower 9=ND
label var mstatus "Marital Status"
label define mstatus_lab 1 "Single" 2 "Married" 3 "Separated/Divorced" 4 "Widowed/Widow/Widower" 99 "ND", modify
label values mstatus mstatus_lab

** (18) occu: Text, if missing=99
label var occu "Occupation"

** (19) durationnum: Integer - min=0, max=99, if missing=99
label var durationnum "Duration of Illness"

** (20) durationtxt
label var durationtxt "Duration Qualifier"
label define durationtxt_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values durationtxt durationtxt_lab

** (21) dod: Y-M-D
format dod %tdCCYY-NN-DD
label var dod "Date of Death"

** (22) dodyear (not included in single year Redcap db but done for multi-year Redcap db)
gen int dodyear=year(dod)
label var dodyear "Year of Death"

** (23) cod1a: Text, if missing=99
label var cod1a "COD 1a"

** (24) onsetnumcod1a: Integer - min=0, max=99, if missing=99
label var onsetnumcod1a "Onset Death Interval-COD 1a"

** (25) onsettxtcod1a: 1=DAYS 2=WEEKS 3=MONTHS 4=YEARS
label var onsettxtcod1a "Onset Qualifier-COD 1a"
label define onsettxtcod1a_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values onsettxtcod1a onsettxtcod1a_lab

** (26) cod1b: Text, if missing=99
label var cod1b "COD 1b"

** (27) onsetnumcod1b: Integer - min=0, max=99, if missing=99
label var onsetnumcod1b "Onset Death Interval-COD 1b"

** (28) onsettxtcod1b: 1=DAYS 2=WEEKS 3=MONTHS 4=YEARS
label var onsettxtcod1b "Onset Qualifier-COD 1b"
label define onsettxtcod1b_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values onsettxtcod1b onsettxtcod1b_lab

** (29) cod1c: Text, if missing=99
label var cod1c "COD 1c"

** (30) onsetnumcod1c: Integer - min=0, max=99, if missing=99
label var onsetnumcod1c "Onset Death Interval-COD 1c"

** (31) onsettxtcod1c: 1=DAYS 2=WEEKS 3=MONTHS 4=YEARS
label var onsettxtcod1c "Onset Qualifier-COD 1c"
label define onsettxtcod1c_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values onsettxtcod1c onsettxtcod1c_lab

** (32) cod1d: Text, if missing=99
label var cod1d "COD 1d"

** (33) onsetnumcod1d: Integer - min=0, max=99, if missing=99
label var onsetnumcod1d "Onset Death Interval-COD 1d"

** (34) onsettxtcod1d: 1=DAYS 2=WEEKS 3=MONTHS 4=YEARS
label var onsettxtcod1d "Onset Qualifier-COD 1d"
label define onsettxtcod1d_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values onsettxtcod1d onsettxtcod1d_lab

** (35) cod2a: Text, if missing=99
label var cod2a "COD 2a"

** (36) onsetnumcod2a: Integer - min=0, max=99, if missing=99
label var onsetnumcod2a "Onset Death Interval-COD 2a"

** (37) onsettxtcod2a: 1=DAYS 2=WEEKS 3=MONTHS 4=YEARS
label var onsettxtcod2a "Onset Qualifier-COD 2a"
label define onsettxtcod2a_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values onsettxtcod2a onsettxtcod2a_lab

** (38) cod2b: Text, if missing=99
label var cod2b "COD 2b"

** (39) onsetnumcod2b: Integer - min=0, max=99, if missing=99
label var onsetnumcod2b "Onset Death Interval-COD 2b"

** (40) onsettxtcod2b: 1=DAYS 2=WEEKS 3=MONTHS 4=YEARS
label var onsettxtcod2b "Onset Qualifier-COD 2b"
label define onsettxtcod2b_lab 1 "Days" 2 "Weeks" 3 "Months" 4 "Years" 99 "ND", modify
label values onsettxtcod2b onsettxtcod2b_lab

** (41) pod: Text, if missing=99
label var pod "Place of Death"

** (42) deathparish
label var deathparish "Death Parish"
label define deathparish_lab 1 "Christ Church" 2 "St. Andrew" 3 "St. George" 4 "St. James" 5 "St. John" 6 "St. Joseph" ///
						7 "St. Lucy" 8 "St. Michael" 9 "St. Peter" 10 "St. Philip" 11 "St. Thomas" 99 "ND", modify
label values deathparish deathparish_lab

** (43) regdate: Y-M-D
label var regdate "Date of Registration"
format regdate %tdCCYY-NN-DD

** (44) certifier: Text, if missing=99
label var certifier "Name of Certifier"

** (45) certifieraddr: Text, if missing=99
label var certifieraddr "Address of Certifier"

** (46) namematch: readonly
label var namematch "Name Match"
label define namematch_lab 1 "names match but different person" 2 "no name match", modify
label values namematch namematch_lab

** (47) death_certificate_complete (auto-generated by REDCap): 0=Incomplete 1=Unverified 2=Complete
rename death_certificate_complete recstatdc
label var recstatdc "Record Status-DC Form"
label define recstatdc_lab 0 "Incomplete" 1 "Unverified" 2 "Complete", modify
label values recstatdc recstatdc_lab


*******************
** TRACKING FORM **
*******************

** (48) tfdddoa: Y-M-D H:M, readonly
format tfdddoa %tcCCYY-NN-DD_HH:MM:SS
label var tfdddoa "TF DateTime"

** (49) tfddda: readonly, user logged into redcap
gen tfddda1=.
replace tfddda1=25 if tfddda=="ashley.henry" //using codebook tfddda to see all possible entries in this field
replace tfddda1=25 if tfddda=="ashleyhenry"
replace tfddda1=4 if tfddda=="karen.greene"
replace tfddda1=13 if tfddda=="kirt.gill"
replace tfddda1=20 if tfddda=="nicolette.roachford"
replace tfddda1=14 if tfddda=="tamisha.hunte"
replace tfddda1=98 if tfddda=="t.g"
drop tfddda
rename tfddda1 tfddda

label var tfddda "TF DA"
label define tfddda_lab 4 "KG" 13 "KWG" 14 "TH" 20 "NR" 25 "AH" 98 "intern", modify
label values tfddda tfddda_lab

** (50) tfregnumstart: integer
label var tfregnumstart "Registry #-Start"

** (51) tfdistrictstart: letters only
label var tfdistrictstart "District-Start"

** (52) tfregnumend: integer
label var tfregnumend "Registry #-End"

** (53) tfdistrictend: letters only
label var tfdistrictend "District-End"

** (53) tfddtxt
label var tfddtxt "TF Comments"

** (54) tracking_complete (auto-generated by REDCap): 0=Incomplete 1=Unverified 2=Complete
rename tracking_complete recstattf
label var recstattf "Record Status-TF Form"
label define recstattf_lab 0 "Incomplete" 1 "Unverified" 2 "Complete", modify
label values recstattf recstattf_lab

************************
** CONSISTENCY CHECKS **
************************
** (1) DOD-missing
** (2) DOD-invalid (future date)

** (1) Age=missing - reassign as '999'
sort dod record_id
count if age==0 //108
count if age==0 & nrn=="" //82
list record_id age agetxt dod nrn if age==0 & nrn=="" //only 8 are "true" missing
replace age=999 if age==0 & nrn=="" & agetxt=="0" //8 real changes made


** (2) Age=0/missing but NRN not missing
count if age==0 & nrn!="" //26 - some are correct as these are '...months' old in age
list record_id age agetxt dod nrn if age==0 & nrn!=""
count if age==0 & nrn!="" & !(strmatch(strupper(agetxt), "*MON*")) //17 - create dob to assign age and for below check (3)
list record_id age agetxt dod nrn if age==0 & nrn!="" & !(strmatch(strupper(agetxt), "*MON*"))
split nrn, p("-") gen(dob)
gen dobyr=substr(dob1, 1, 2) //21,886 changes made
gen dobmon=substr(dob1, 3, 2) //21,886 changes made
gen dobday=substr(dob1, 5, 2) //21,886 changes made
list record_id age agetxt dod nrn dobyr dobmon dobday if age==0 & nrn!="" & !(strmatch(strupper(agetxt), "*MON*"))
** I checked COD and Occupation and all are senior in age so birth year=19...
gen birthdate="19" + dobyr + dobmon + dobday if age==0 & nrn!="" & !(strmatch(strupper(agetxt), "*MON*")) //17 changes made
gen dob=date(birthdate, "YMD")
format dob %tdCCYY-NN-DD
gen age2=int((dod - dob)/365.25) //now use this to assign missing age
replace age=age2 if age==0 & nrn!="" & !(strmatch(strupper(agetxt), "*MON*")) //17 real changes made


** (3) Age vs NRN(DOB)
** Need to check which should have dob=19... or dob=20... using "age" and "deathyear"

** For deathyear=2009, NB: case where age=21 but dobyr=2007 so not flagged using the
** "OLD CODE" method below so used below method instead for this check:
 
** First, check for records that have same deathyear and birthyear and correct age and birthdate
sort deathyear record_id
gen dodyr=substr(string(deathyear), -2, 2)
count if dobyr==dodyr & age!=0 & age<50 //11
list record_id age age2 agetxt dod nrn dobyr deathyear if dobyr==dodyr & age!=0 & age<50
replace birthdate="20" + dobyr + dobmon + dobday if dobyr==dodyr & age!=0 & age<50 //11 changes made
replace agetxt="25 DAYS" if record_id==1800
replace agetxt="2 MONTHS" if record_id==13927
replace agetxt="8 WEEKS" if record_id==11941
replace agetxt="2 MONTHS" if record_id==11947
replace agetxt="3 MONTHS" if record_id==19363
replace agetxt="2 MONTHS" if record_id==5214
replace agetxt="5 MONTHS" if record_id==8034
replace agetxt="6 MONTHS" if record_id==18000
replace agetxt="3 MONTHS" if record_id==10421
replace agetxt="2 MONTHS" if record_id==252
replace agetxt="23 DAYS" if record_id==21835
replace age2=0 if dobyr==dodyr & age!=0 & age<50 //11 changes made
replace age=age2 if age!=age2 & dobyr==dodyr & age!=0 & age<50 //11 changes made

** Second, check for records that have first digit of dobyr as '0' to correct birthdate
gen first_digit_dobyr=substr(dobyr, 1, 1)
count if first_digit_dobyr=="0" & age<50 & age!=0 & birthdate=="" //59
list record_id age age2 agetxt dod nrn dobyr deathyear if first_digit_dobyr=="0" & age<50 & age!=0 & birthdate==""
replace birthdate="20" + dobyr + dobmon + dobday if first_digit_dobyr=="0" & age<50 & age!=0 & birthdate=="" //59 changes made
list record_id age agetxt dod nrn dobyr birthdate if first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!=""
replace dob=date(birthdate, "YMD") if first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!=""
replace age2=int((dod - dob)/365.25) if first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!="" //59 changes made
count if age!=age2 & first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!="" //3 do not match
list record_id age age2 agetxt dod dob nrn if age!=age2 & first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!=""
replace agetxt="22 MONTHS" if record_id==2395
replace agetxt="21 MONTHS" if record_id==11918
replace agetxt="17 MONTHS" if record_id==20604
replace age2=0 if age!=age2 & first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!="" //3 changes made
replace age=age2 if age!=age2 & first_digit_dobyr=="0" & age<50 & age!=0 & birthdate!="" //3 changes made

** Once assigned all death years for dob=20... then change all other dob!=20... to dob=19...
count if dob!=. //76 - correct
count if dob==. & nrn!="" //21,810
list record_id age agetxt dod nrn dobyr if dob==. & nrn!=""
replace birthdate="19" + dobyr + dobmon + dobday if dob==. & nrn!="" //21,810 real changes made
replace dob=date(birthdate, "YMD") if dob==. & nrn!="" //21,777 real changes made - 33 didn't change
** Need to check these 33 that didn't change against the electoral list as have incorrect values in nrn
list record_id pname age agetxt dod nrn dobyr birthdate if dob==. & nrn!=""
replace nrn="650528-0104" if record_id==926
replace nrn="480109-0012" if record_id==1107
replace nrn="261211-0045" if record_id==2755
replace nrn="160424-0083" if record_id==2948
replace nrn="131221-0048" if record_id==3898
replace nrn="641118-0133" if record_id==3919
replace nrn="301017-8014" if record_id==4310
replace nrn="330710-0036" if record_id==6504
replace nrn="400711-0069" if record_id==6693
replace nrn="380802-0022" if record_id==16910
replace nrn="221105-0022" if record_id==21782
replace nrn="170218-0066" if record_id==1841
replace nrn="330516-0016" if record_id==18583
replace nrn="191020-0060" if record_id==7343
replace nrn="611003-0027" if record_id==20565
replace nrn="190730-0030" if record_id==23526
replace nrn="301219-0025" if record_id==4602
replace nrn="260626-0046" if record_id==10386
replace nrn="250508-0065" if record_id==13375
replace nrn="280501-0085" if record_id==15269
replace nrn="341221-0076" if record_id==1972
replace nrn="321009-0118" if record_id==3890
replace nrn="311217-0034" if record_id==4424
replace nrn="341125-0024" if record_id==9778
replace nrn="450921-0919" if record_id==12936
replace nrn="491020-0056" if record_id==18319
replace nrn="570419-0130" if record_id==22143
replace nrn="180223-0084" if record_id==2119
replace nrn="741001-0073" if record_id==2321
replace nrn="330318-0107" if record_id==10403
replace nrn="330318-0107" if record_id==16307
replace nrn="470910-0111" if record_id==19308
replace nrn="340506-0066" if record_id==22596
replace pname= subinstr(pname,"N","RN",.) if record_id==22596
split nrn, p("-") gen(dob_dob)
replace dobyr=substr(dob_dob1, 1, 2) if dob==. & birthdate!="" //6 changes made
replace dobmon=substr(dob_dob1, 3, 2) if dob==. & birthdate!="" //25 changes made
replace dobday=substr(dob_dob1, 5, 2) if dob==. & birthdate!="" //22 changes made
replace birthdate="19" + dobyr + dobmon + dobday if dob==. & birthdate!="" //33 changes made
replace dob=date(birthdate, "YMD") if dob==. & birthdate!="" //33 real changes made
** Now assign age2 so that you can check if age(from excel death file) and age2(from Stata code) match
list record_id age age2 agetxt dod nrn dob birthdate if dob!=. & nrn!="" & age2==.
replace age2=int((dod - dob)/365.25) if dob!=. & nrn!="" & age2==. //21,799 real changes made

** Now check that Age vs NRN(DOB) match
count if age!=age2 & nrn!="" & dob!=. //784 do not match
list record_id age age2 agetxt dod dob nrn if age!=age2 & nrn!=""
replace age=age2 if age!=age2 & nrn!="" & dob!=. //784 changes made

** Now check that Age vs NRN(DOB) match
count if age!=age2 & nrn!="" //0


** (4) Length check for all standardized length variables
/*
		regnum
		nrn
*/
count if length(regnum)!=4 //0 - all correct
count if nrn!="" & length(nrn)!=11 //0


** (5) First name and Sex - CHECK AGAINST ELECTORAL LIST
label define sex_lab 1 "male" 2 "female", modify
label values sex sex_lab
sort record_id
** MALES
** COD: females should not have prostate cancer
tab sex if regexm(cod1a, "PROSTAT") //11
list record_id pname nrn sex if regexm(cod1a, "PROSTAT") & sex==2
list cod1a if regexm(cod1a, "PROSTAT") & sex==2
recode sex 2=1 if record_id==1559|record_id==3955|record_id==4064|record_id==6652 ///
				  |record_id==8178|record_id==12948|record_id==14393|record_id==18994 ///
				  |record_id==19581|record_id==21068|record_id==23394
** NRN: penultimate digit in 'nrn' can sometimes indicate if male/female (odd #=male; eve #=female)
count if sex==2 & regex(substr(nrn,-2,1), "[1,3,5,7,9]") & !(strmatch(strupper(nrn), "*-9999*")) //75
list record_id pname nrn sex if sex==2 & regex(substr(nrn,-2,1), "[1,3,5,7,9]") & !(strmatch(strupper(nrn), "*-9999*"))
list cod1a if sex==2 & regex(substr(nrn,-2,1), "[1,3,5,7,9]") & !(strmatch(strupper(nrn), "*-9999*"))
recode sex 2=1 if record_id==286|record_id==3493|record_id==4382|record_id==5186 ///
				  |record_id==6196|record_id==6596|record_id==6932|record_id==7766 ///
				  |record_id==7832|record_id==9212|record_id==9913|record_id==11229 ///
				  |record_id==12588|record_id==13655|record_id==15423|record_id==17224 ///
				  |record_id==17273|record_id==17660|record_id==19026|record_id==19784 ///
				  |record_id==19856|record_id==20619|record_id==20684|record_id==21056 ///
				  |record_id==21057|record_id==22750|record_id==23334|record_id==23346 ///
				  |record_id==23572|record_id==23833|record_id==23837

** Visual check for name & sex check for those missing nrn - MALES
count if sex==1 & nrn=="" //1,133 - check if there is a stata check for this e.g. soundex,etc
list record_id pname sex if sex==1 & nrn==""


** FEMALES
** COD: males more unlikely to have breast cancer
tab sex if regexm(cod1a, "BREAST") //17
list record_id pname nrn sex if regexm(cod1a, "BREAST") & sex==1
list cod1a if regexm(cod1a, "BREAST") & sex==1
recode sex 1=2 if record_id==4756|record_id==12513|record_id==12992 ///
				  |record_id==13088|record_id==13334|record_id==21187

** COD: males should not have cervical,uterine,vaginal cancer
tab sex if (regexm(cod1a, "UTER") | regexm(cod1a, "OMA OF THE VULVA") | ///
			regexm(cod1a, "CHORIOCARCIN") | regexm(cod1a, "ENDOMETRIAL CARCINOMA") | ///
			regexm(cod1a, "ENDOMETRIAL CANC") | regexm(cod1a, "OF ENDOMETRIUM") | ///
			regexm(cod1a, "OF THE ENDOMETRIUM") | regexm(cod1a, "VULVA CARCINOMA") | ///
			regexm(cod1a, "VULVAL CANCER") | regexm(cod1a, "VAGINAL CARCINOMA"))
** 6=male, 1=99
list record_id pname nrn sex if (regexm(cod1a, "UTER") | regexm(cod1a, "OMA OF THE VULVA") | ///
			regexm(cod1a, "CHORIOCARCIN") | regexm(cod1a, "ENDOMETRIAL CARCINOMA") | ///
			regexm(cod1a, "ENDOMETRIAL CANC") | regexm(cod1a, "OF ENDOMETRIUM") | ///
			regexm(cod1a, "OF THE ENDOMETRIUM") | regexm(cod1a, "VULVA CARCINOMA") | ///
			regexm(cod1a, "VULVAL CANCER") | regexm(cod1a, "VAGINAL CARCINOMA")) & sex==1
list cod1a if (regexm(cod1a, "UTER") | regexm(cod1a, "OMA OF THE VULVA") | ///
			regexm(cod1a, "CHORIOCARCIN") | regexm(cod1a, "ENDOMETRIAL CARCINOMA") | ///
			regexm(cod1a, "ENDOMETRIAL CANC") | regexm(cod1a, "OF ENDOMETRIUM") | ///
			regexm(cod1a, "OF THE ENDOMETRIUM") | regexm(cod1a, "VULVA CARCINOMA") | ///
			regexm(cod1a, "VULVAL CANCER") | regexm(cod1a, "VAGINAL CARCINOMA")) & sex==1

recode sex 1=2 if record_id==6599|record_id==15662|record_id==15668|record_id==17409

** NRN: penultimate digit in 'nrn' can sometimes indicate if male/female (odd #=male; eve #=female)
count if sex==1 & regex(substr(nrn,-2,1), "[0,2,4,6,8]") //90
list record_id pname nrn sex if sex==1 & regex(substr(nrn,-2,1), "[0,2,4,6,8]")
list cod1a if sex==1 & regex(substr(nrn,-2,1), "[0,2,4,6,8]")
recode sex 1=2 if record_id==49|record_id==70|record_id==995|record_id==1612 ///
				  |record_id==2763|record_id==3919|record_id==6041|record_id==7003 ///
				  |record_id==7540|record_id==7651|record_id==8218|record_id==8896 ///
				  |record_id==11396|record_id==12518|record_id==15151|record_id==15463 ///
				  |record_id==15648|record_id==16203|record_id==16437|record_id==17041 ///
				  |record_id==17653|record_id==18303|record_id==20578|record_id==21718 ///
				  |record_id==22411|record_id==22508|record_id==24054

** Visual check for name & sex check for those missing nrn - FEMALES
count if sex==2 & nrn=="" //1,149 - check if there is a stata check for this e.g. soundex,etc
list record_id pname sex if sex==2 & nrn==""


** (6) District - see district demarcations noted below:
/*	Districts are assigned based on death parish
		District A - anything below top rock christ church and st. michael 
		District B - anything above top rock christ church and st. george
		District C - st. philip and st. john
		District D - st. thomas
		District E - st. james, st. peter, st. lucy
		District F - st. joseph, st. andrew
*/
label define deathparish_lab 1 "ch.ch." 2 "st andrew" 3 "st george" 4 "st james" ///
							 5 "st john" 6 "st joseph" 7 "st lucy" 8 "st michael" ///
							 9 "st peter" 10 "st philip" 11 "st thomas" 99 "ND" , modify
label values deathparish deathparish_lab		
label define district_lab 1 "A" 2 "B" 3 "C" 4 "D" 5 "E" 6 "F" , modify
label values district district_lab

** Christ Church
count if deathparish==1 & district!=1 //1,599 - need a list of district allotments by address/village
list record_id district pod if deathparish==1 & district!=1
** St Andrew
count if deathparish==2 & district!=6 //4
list record_id deathparish district pod if deathparish==2 & district!=6
replace deathparish=8 if record_id==1601
replace district=6 if record_id==6714
replace deathparish=11 if record_id==23917
replace deathparish=4 if record_id==24029
** St George
count if deathparish==3 & district!=2 //13
list record_id deathparish district pod if deathparish==3 & district!=2
replace deathparish=10 if record_id==3676
replace district=2 if record_id==8049|record_id==10243|record_id==16536|record_id==16983 ///
					  |record_id==18377|record_id==22105|record_id==23009
replace deathparish=1 if record_id==12395
replace deathparish=2 if record_id==15567 
replace deathparish=8 if record_id==18605
replace deathparish=9 if record_id==20617
replace deathparish=6 if record_id==23455
** St James
count if deathparish==4 & district!=5 //18
list record_id deathparish district pod if deathparish==4 & district!=5
replace deathparish=11 if record_id==2129|record_id==20447
replace deathparish=8 if record_id==4082|record_id==5093|record_id==9813 ///
						 |record_id==15477|record_id==19870|record_id==20857 ///
						 |record_id==22307|record_id==23080|record_id==23589
replace deathparish=1 if record_id==5201|record_id==5914|record_id==18401
replace deathparish=2 if record_id==7436|record_id==12541
replace district=5 if record_id==11652|record_id==24038
** St John
count if deathparish==5 & district!=3 //5
list record_id deathparish district pod if deathparish==5 & district!=3
replace deathparish=6 if record_id==810
replace deathparish=3 if record_id==2599
replace deathparish=1 if record_id==3698|record_id==21156|record_id==22964
** St Joseph
count if deathparish==6 & district!=6 //4
list record_id deathparish district pod if deathparish==6 & district!=6
replace deathparish=8 if record_id==5457|record_id==7163|record_id==8504|record_id==9951
** St Joseph
count if deathparish==7 & district!=5 //7
list record_id deathparish district pod if deathparish==7 & district!=5
replace deathparish=1 if record_id==1053|record_id==20052
replace deathparish=8 if record_id==2808|record_id==10115|record_id==20869|record_id==21006
replace district=5 if record_id==8002
** St Michael
count if deathparish==8 & district!=1 //58
list record_id deathparish district pod if deathparish==8 & district!=1
replace deathparish=4 if record_id==194|record_id==2400|record_id==4569|record_id==6670 ///
						 |record_id==6888|record_id==7559|record_id==8434|record_id==8999 ///
						 |record_id==9341|record_id==9468|record_id==9785|record_id==16275 ///
						 |record_id==18887|record_id==19873
replace deathparish=9 if record_id==715|record_id==9054
replace district=1 if record_id==861|record_id==1122|record_id==1821|record_id==1919 ///
					  |record_id==3014|record_id==13196|record_id==15072|record_id==15416 ///
					  |record_id==18278|record_id==23495
replace deathparish=1 if record_id==1339|record_id==4529|record_id==6482|record_id==7140 ///
						 |record_id==13473|record_id==16078|record_id==16778|record_id==17481 ///
						 |record_id==21075|record_id==21286
replace deathparish=11 if record_id==2607|record_id==4565|record_id==7589|record_id==19216 ///
						  |record_id==19767
replace deathparish=10 if record_id==5065|record_id==6788|record_id==7113|record_id==8270 ///
						  |record_id==8619|record_id==9088|record_id==10002|record_id==14593 ///
						  |record_id==18396|record_id==19398|record_id==21157|record_id==23115
replace deathparish=2 if record_id==12213
replace deathparish=5 if record_id==13731|record_id==23275
replace deathparish=3 if record_id==20421|record_id==22361
** St Peter
count if deathparish==9 & district!=5 //5
list record_id deathparish district pod if deathparish==9 & district!=5
replace deathparish=10 if record_id==5161|record_id==19611|record_id==23107
replace deathparish=8 if record_id==11277|record_id==17252
** St Philip
count if deathparish==10 & district!=3 //13
list record_id deathparish district pod if deathparish==10 & district!=3
replace deathparish=8 if record_id==870|record_id==15192|record_id==20357 ///
						 |record_id==20746|record_id==20755|record_id==23430
replace district=3 if record_id==1957
replace deathparish=1 if record_id==8464|record_id==12184|record_id==12927 ///
						 |record_id==13990|record_id==16837
replace deathparish=11 if record_id==17609
** St Thomas
count if deathparish==11 & district!=4 //19
list record_id deathparish district pod if deathparish==11 & district!=4
replace district=4 if record_id==796|record_id==6963|record_id==7738|record_id==14731 ///
					  |record_id==16329|record_id==18311|record_id==18846
replace pod="99" if record_id==18311
replace deathparish=10 if record_id==3149
replace deathparish=4 if record_id==3703|record_id==4858|record_id==11959
replace deathparish=1 if record_id==6204|record_id==18879
replace deathparish=9 if record_id==10824
replace deathparish=8 if record_id==13157|record_id==16590|record_id==21027|record_id==22902
replace deathparish=7 if record_id==16110


***************************
** REDCAP QUALITY CHECKS **
***************************

** #1 Invalid entry: Registry # - This should be between 0001 and 9999.
count if regnum=="0000" //0

** #2 Invalid entry: Duration of illness (number) = 99 but Duration of illness (time period) is NOT blank.
count if durationnum==99 & durationtxt!=. //0

** #3 Invalid entry: Date of death - this date cannot be a future date.
gen currentd=c(current_date)
gen double today=date(currentd, "DMY")
drop currentd
format today %tdCCYY-NN-DD
count if dod > today //0

** #4 Invalid entry: Year of death - this does not match year in 'Date of death' field.
count if year(dod)!=deathyear //0 - deathyear was generated from dod but will keep for future data cleaning

** #5 Invalid entry: Date of registration - this date cannot be a future date.
count if regdate > today //7
list record_id dod regdate if regdate > today
replace regdate=regdate-32871 if regdate > today
** 2016 was leap year so one day added in error
replace regdate=regdate-1 if record_id==20266

** #6 Invalid entry: COD I (a) is BLANK but Onset Death Interval COD I (a) is NOT blank.
count if cod1a=="" & onsetnumcod1a!=. //0

** #7 Invalid entry: COD I (a) - Onset Death Interval (number) is BLANK but Onset Death Interval (time period) is NOT blank.
count if (onsetnumcod1a==.|onsetnumcod1a==99) & onsettxtcod1a!=. //0

** #8 Invalid entry: COD I (b) is BLANK but Onset Death Interval COD I (b) is NOT blank.
count if cod1b=="" & onsetnumcod1b!=. //0

** #9 Invalid entry: COD I (b) - Onset Death Interval (number) is BLANK but Onset Death Interval (time period) is NOT blank.
count if (onsetnumcod1b==.|onsetnumcod1b==99) & onsettxtcod1b!=. //0

** #10 Invalid entry: COD I (c) is BLANK but Onset Death Interval COD I (c) is NOT blank.
count if cod1c=="" & onsetnumcod1c!=. //0

** #11 Invalid entry: COD I (c) - Onset Death Interval (number) is BLANK but Onset Death Interval (time period) is NOT blank.
count if (onsetnumcod1c==.|onsetnumcod1c==99) & onsettxtcod1c!=. //0

** #12 Invalid entry: COD I (d) is BLANK but Onset Death Interval COD I (d) is NOT blank.
count if cod1d=="" & onsetnumcod1d!=. //0

** #13 Invalid entry: COD I (d) - Onset Death Interval (number) is BLANK but Onset Death Interval (time period) is NOT blank.
count if (onsetnumcod1d==.|onsetnumcod1d==99) & onsettxtcod1d!=. //0

** #14 Invalid entry: COD II (a) is BLANK but Onset Death Interval COD II (a) is NOT blank.
count if cod2a=="" & onsetnumcod2a!=. //0

** #15 Invalid entry: COD II (a) - Onset Death Interval (number) is BLANK but Onset Death Interval (time period) is NOT blank.
count if (onsetnumcod2a==.|onsetnumcod2a==99) & onsettxtcod2a!=. //0

** #16 Invalid entry: COD II (b) is BLANK but Onset Death Interval COD II (b) is NOT blank.
count if cod2b=="" & onsetnumcod2b!=. //0

** #17 Invalid entry: COD II (b) - Onset Death Interval (number) is BLANK but Onset Death Interval (time period) is NOT blank.
count if (onsetnumcod2b==.|onsetnumcod2b==99) & onsettxtcod2b!=. //0


******************************
** REMOVING 'TRUE' DUPLICATES  
******************************

** In excel data preparation, duplicates were checked and either (a) identified using the 'namematch' variable or 
** (b) removed from the excel raw data file
** Check duplicates one more time in conjunction with the namematch variable
** 'True' duplicate = same person, same death registration

** METHOD 1
duplicates report nrn if nrn!="" & !(strmatch(strupper(nrn), "*-9999*")) & namematch!=1
duplicates list nrn if nrn!="" & !(strmatch(strupper(nrn), "*-9999*")) & namematch!=1 //0 obs
duplicates report pname if namematch!=1
duplicates list pname if namematch!=1 //0

** METHOD 2
sort pname
quietly by pname:  gen dup = cond(_N==1,0,_n)
count if dup>0 & namematch!=1 //2
list record_id pname if dup>0 & namematch!=1
replace namematch=1 if record_id==12848
replace namematch=1 if record_id==16261

sort nrn
quietly by nrn: gen dupnrn = cond(_N==1,0,_n)
count if dupnrn>0 & nrn!="" & !(strmatch(strupper(nrn), "*-9999*")) & namematch!=1 //0
list record_id nrn if dupnrn>0 & nrn!="" & !(strmatch(strupper(nrn), "*-9999*")) & namematch!=1

** METHOD 3
sort pname
bysort pname: gen dup2 = _n
count if dup2>1 & namematch!=1 //0
list record_id pname if dup2>1 & namematch!=1

sort nrn
bysort nrn: gen dupnrn2 = _n
count if dupnrn2>1 & nrn!="" & !(strmatch(strupper(nrn), "*-9999*")) & namematch!=1 //0
list record_id nrn if dupnrn2>1 & nrn!="" & !(strmatch(strupper(nrn), "*-9999*")) & namematch!=1

** For future reference, method 2 works best for identifying duplicate names!


** ORDER variables according to position in DeathData REDCap database
order record_id cfdate cfda certtype regnum district pname address parish sex age ///
	  nrnnd nrn mstatus occu durationnum durationtxt dod deathyear cod1a ///
	  onsetnumcod1a onsettxtcod1a cod1b onsetnumcod1b onsettxtcod1b cod1c ///
	  onsetnumcod1c onsettxtcod1c cod1d onsetnumcod1d onsettxtcod1d cod2a ///
	  onsetnumcod2a onsettxtcod2a cod2b onsetnumcod2b onsettxtcod2b pod ///
	  deathparish regdate certifier certifieraddr namematch death_certificate_complete


** REMOVE variables not needed in DeathData REDCap database;
** ORDER variables according to position in DeathData REDCap database
drop deathid dbid regno natregno casefindingdate cftime regnumtemp durtxt2 onsettxt2
order record_id cfdate cfda certtype regnum district pname address parish sex ///
	  age nrnnd nrn mstatus occu durationnum durationtxt dod deathyear cod1a ///
	  onsetnumcod1a onsettxtcod1a cod1b onsetnumcod1b onsettxtcod1b cod1c ///
	  onsetnumcod1c onsettxtcod1c cod1d onsetnumcod1d onsettxtcod1d cod2a ///
	  onsetnumcod2a onsettxtcod2a cod2b onsetnumcod2b onsettxtcod2b pod ///
	  deathparish regdate certifier certifieraddr namematch death_certificate_complete

	  
count //24,188

** QUALITY REPORT
gen corr_TOT=sum(corr_AH corr_KG corr_NR corr_TH)


label data "BNR MORTALITY data 2008-2017"
notes _dta :These data prepared from BB national death register & BNR (MS Access) deathdata database
save "`datapath'\version01\2-working\2018_deaths_cleaned_dc" ,replace

