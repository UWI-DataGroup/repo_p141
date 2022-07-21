** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name          2b_clean_all_deaths.do
    //  project:                BNR
    //  analysts:               Jacqueline CAMPBELL
    //  date first created      29-JUN-2022
    //  date last modified      21-JUL-2022
    //  algorithm task          Unduplication of death data
    //  status                  Completed
    //  objectve                To have one dataset with unduplicated death data.
    //  note                    To combine with multi-year death dataset for unduplication purposes;
	//							Cleaned 2021 + any other deaths to be imported into multi-year (2008-2020) death database; 
    //                          REDCap database with ALL cleaned deaths to be updated.

    
    ** General algorithm set-up
    version 17.0
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
    log using "`logpath'\2b_clean_all_deaths.smcl", replace
** HEADER -----------------------------------------------------

** JC 30jun2022+11jul2022+14jul2022+20jul2022+21jul2022: This dofile was re-run to include record_id 3232 - 3245 added by KG after completion of 2021 cleaning; Included in this process in prep for cancer annual report process

***************
** DATA IMPORT  
***************
** LOAD the national registry deaths 2008-2020 excel dataset
import excel using "`datapath'\version07\1-input\BNRDeathData20082020_DATA_2022-06-29_1617_excel.xlsx" , firstrow case(lower)

//save "`datapath'\version07\2-working\2021_deaths_imported_dp" ,replace

count //

*******************
** DATA FORMATTING  
*******************
** PREPARE each variable according to the format and order in which they appear in DeathData REDCap database

************************
**  DEATH CERTIFICATE **
**        FORM        **
************************

** (1) record_id (auto-generated by REDCap)
label var record_id "DeathID"

** (2) redcap_event_name (auto-generated by REDCap)
gen event=.
replace event=1 if redcap_event_name=="death_data_collect_arm_1"
replace event=2 if redcap_event_name=="tracking_arm_2"

label var event "Redcap Event Name"
label define event_lab 1 "DC arm 1" 2 "TF arm 2", modify
label values event event_lab

** (3) dddoa: Y-M-D H:M, readonly
gen double dddoa2 = clock(dddoa, "YMDhm")
format dddoa2 %tcCCYY-NN-DD_HH:MM
drop dddoa
rename dddoa2 dddoa
label var dddoa "ABS DateTime"

** (4) ddda
label var ddda "ABS DA"
label define ddda_lab 4 "KG" 13 "KWG" 14 "TH" 20 "NR" 25 "AH" 98 "intern", modify
label values ddda ddda_lab

** (5) odda
//if odda==. tostring odda ,replace
//replace odda="" if odda=="."
label var odda "ABS Other DA"

** (6) certtype: 1=MEDICAL 2=POST MORTEM 3=CORONER 99=ND, required
label var certtype "Certificate Type"
label define certtype_lab 1 "Medical" 2 "Post Mortem" 3 "Coroner" 99 "ND", modify
label values certtype certtype_lab

** (7) regnum: integer, if missing=9999
label var regnum "Registry Dept #"

** (8) district: 1=A 2=B 3=C 4=D 5=E 6=F
/* Districts are assigned based on death parish
	District A - anything below top rock christ church and st. michael 
	District B - anything above top rock christ church and st. george
	District C - st. philip and st. john
	District D - st. thomas
	District E - st. james, st. peter, st. lucy
	District F - st. joseph, st. andrew
*/
label var district "District"
label define district_lab 1 "A" 2 "B" 3 "C" 4 "D" 5 "E" 6 "F", modify
label values district district_lab

** (9) pname: Text, if missing=99
label var pname "Deceased's Name"
replace pname = rtrim(ltrim(itrim(pname))) //5 changes

** (10) address: Text, if missing=99
label var address "Deceased's Address"
replace address = rtrim(ltrim(itrim(address))) //20 changes

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
label define nrnnd_lab 1 "Yes" 2 "No", modify
label values nrnnd nrnnd_lab
label var nrnnd "Is National ID # documented?"

** (16) nrn: dob-####, partial missing=dob-9999, if missing=.
rename nrn natregno
label var natregno "National ID #"
format natregno %15.0g

** (17) mstatus: 1=Single 2=Married 3=Separated/Divorced 4=Widowed/Widow/Widower 99=ND
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
drop dodyear
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


order record_id event dddoa ddda odda certtype regnum district pname address parish sex ///
      age agetxt nrnnd natregno mstatus occu durationnum durationtxt dod dodyear ///
      cod1a onsetnumcod1a onsettxtcod1a cod1b onsetnumcod1b onsettxtcod1b ///
      cod1c onsetnumcod1c onsettxtcod1c cod1d onsetnumcod1d onsettxtcod1d ///
      cod2a onsetnumcod2a onsettxtcod2a cod2b onsetnumcod2b onsettxtcod2b ///
      pod deathparish regdate certifier certifieraddr namematch cleaned recstatdc
      

count //32,465
drop tfdddoa tfdddoatstart tfddda tfregnumstart tfdistrictstart tfregnumend tfdistrictend tfddelapsedh tfddelapsedm tfdddoaend tfdddoatend tfddtxt tracking_complete
drop if event!=1 //255 deleted
count //32,210
append using "`datapath'\version07\3-output\2021_deaths_cleaned_matching_dc"
count //35,438

** (13) duplicate
sort pname
quietly by pname:  gen dup = cond(_N==1,0,_n)
sort pname
count if event==1 & dup>0  //3,686
sort pname record_id
//list record_id dddoa ddda odda pname regnum district nrn if event==1 & dup>0
//list record_id pname namematch regnum district certtype nrn dod if event==1 & dup>0, nolabel sepby(pname)
order record_id pname namematch dodyear dod nrn natregno

gen tempvarn=1 if dup>0 & namematch!=1
replace namematch=1 if dup>0 & namematch!=1 //451 changes
drop dup

gen natregno2=nrn
destring natregno2, replace
replace natregno=natregno2 if natregno2!=. //3045 changes
drop natregno2

gen unique_id=record_id
tostring unique_id ,replace
gen dodyr=dodyear
tostring dodyr ,replace
replace unique_id=unique_id+"_"+dodyr
drop dodyr

preserve
drop if natregno==.
sort natregno 
quietly by natregno : gen dupnrn = cond(_N==1,0,_n)
sort natregno record_id pname
count if dupnrn>0 //24
list record_id unique_id namematch pname natregno dod sex age address if dupnrn>0, sepby(natregno)
restore

order record_id unique_id pname namematch dodyear dod nrn natregno

replace tempvarn=1 if record_id==16489|record_id==27685|record_id==16327|record_id==16342|record_id==16356 ///
					  |record_id==16317|record_id==15989|record_id==16349|record_id==16259|record_id==25997 ///
					  |record_id==7618|record_id==16399

** Corrections from above NRN dup check
replace natregno=. if record_id==27685|unique_id=="3219_2021"
replace sex=1 if record_id==16342
replace sex=2 if record_id==16349
replace namematch=1 if unique_id=="3159_2021"
gen place=pod if record_id==25530
fillmissing place
replace pod=place if record_id==25997
drop place
drop if record_id==25530 //duplicate of record_id 25997; JC updated pod for record_id 25997 then deleted 25530 from multi-yr REDCap db on 29jun2022.
drop if record_id==28415 //duplicate of record_id 32639; JC deleted 28415 from multi-yr REDCap db on 29jun2022.

preserve
clear
import excel using "`datapath'\version07\2-working\Corrections_mort_20220629.xlsx" , firstrow case(lower)
save "`datapath'\version07\2-working\corrections" ,replace
restore

merge 1:1 unique_id using "`datapath'\version07\2-working\corrections" ,force
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        35,331
        from master                    35,331  (_merge==1)
        from using                          0  (_merge==2)

    Matched                                 8  (_merge==3)
    -----------------------------------------
*/
replace nrn=elec_nrn if _merge==3 //8 changes
replace sex=elec_sex if _merge==3 //1 change
replace age=elec_age if _merge==3 //8 changes
replace elecmatch=elec_match if _merge==3 //8 changes
drop elec_* _merge
erase "`datapath'\version07\2-working\corrections.dta"

/* 
Check below list for cases where namematch=no match but 
there is a pt with same name then:
 (1) check if same pt and remove duplicate pt;
 (2) check if same name but different pt and
	 update namematch variable to reflect this, i.e.
	 namematch=1
*/
gen dod2=dod
format dod2 %tdCCYY-NN-DD
tostring dod2 ,replace

sort pname dod2 record_id
quietly by pname dod2 : gen dupnmdod2 = cond(_N==1,0,_n)
sort pname dod2 record_id
count if event==1 & dupnmdod2>0 //0
drop dod2 dupnmdod2

/* JC 29jun2022: disabled code as import already performed.
** Export records to be updated in multi-year database (NRN only updates)
preserve
gen exported=1 if tempvarn==1 & dodyear!=2021 & nrn!=""
export_delimited record_id redcap_event_name nrn sex age namematch elecmatch if tempvarn==1 & dodyear!=2021 & nrn!="" ///
using "`datapath'\version07\3-output\2022-06-29_Cleaned_multi-yr_DeathData_REDCap_JC_NRN.csv", nolabel replace
//8 exported

** Export records to be updated in multi-year database (NRN only updates)
export_delimited record_id redcap_event_name sex namematch elecmatch if tempvarn==1 & data_2021!=1 & exported!=1 ///
using "`datapath'\version07\3-output\2022-06-29_Cleaned_multi-yr_DeathData_REDCap_JC_NAMES.csv", nolabel replace
restore
//192 exported
//REDCap multi-year database updated on 29jun2022 using above exports
*/

** REMOVE multi-year data
count //35,450
drop if data_2021!=1 //32,208 deleted
count //3228; 3229; 3230; 3233; 3239; 3240; 3242

drop corr_AH corr_KG corr_NR corr_KWG corr_TH corr_intern data_2021 tempvarn
//drop tfddda2 - don't remove as needed in 3_export_deaths.do

** ORDER variables according to position in DeathData REDCap database
order record_id redcap_event_name event dddoa ddda odda certtype regnum district pname address parish ///
	  sex age agetxt nrnnd nrn mstatus occu durationnum durationtxt dod dodyear ///
	  cod1a onsetnumcod1a onsettxtcod1a cod1b onsetnumcod1b onsettxtcod1b ///
	  cod1c onsetnumcod1c onsettxtcod1c cod1d onsetnumcod1d onsettxtcod1d ///
	  cod2a onsetnumcod2a onsettxtcod2a cod2b onsetnumcod2b onsettxtcod2b ///
	  pod deathparish regdate certifier certifieraddr namematch cleaned recstatdc ///
	  tfdddoa tfdddoatstart tfddda tfregnumstart tfdistrictstart tfregnumend tfdistrictend ///
      tfddelapsedh tfddelapsedm tfdddoaend tfdddoatend tfddtxt recstattf

** REMOVE variables and labels not needed in DeathData REDCap database
label drop _all

** REDCap will not import H:M:S format so had to change cfdate from %tcCCYY-NN-DD_HH:MM:SS to below format
format dddoa %tcCCYY-NN-DD_HH:MM
	  
count //3228; 3229; 3230; 3233; 3239; 3240; 3242

label data "BNR MORTALITY data 2021"
notes _dta :These data prepared from BB national death register & BNR (Redcap) deathdata database
save "`datapath'\version07\3-output\2021_deaths_cleaned_export_dc" ,replace

