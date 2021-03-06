** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name          0_master_deaths.do
    //  project:                BNR
    //  analysts:               Jacqueline CAMPBELL
    //  date first created      28-AUG-2019
    // 	date last modified      28-AUG-2019
    //  algorithm task          Import death data and run associated dofiles
    //  status                  Completed
    //  objectve                To have one dataset with cleaned 2018 death data.
    //  note 1                  Duplicate 2017 deaths checked using 2018 dataset against 2008-2017 dataset 
    //                          (see '2017 deaths_combined_20190828.xlsx')
    //  note 2                  Duplicates within 2018 deaths checked and identified using conditioinal formatting and 
    //                          field 'namematch' in 2018 dataset (see 'BNRDeathData2018_DATA_2019-08-28_1101_excel.xlsx')
    //  note 3                  Cleaned 2018 dataset to be merged with 2008-2017 death dataset; 
    //                          Redcap database with ALL cleaned deaths to be created.

    
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
    log using "`logpath'\0_master_deaths.smcl", replace
** HEADER -----------------------------------------------------

***************
** DATA IMPORT  
***************
** LOAD the national registry deaths 2008-2017 excel dataset
import excel using "`datapath'\version01\1-input\BNRDeathData2018_DATA_2019-09-16_1113_excel.xlsx" , firstrow case(lower)

save "`datapath'\version01\2-working\2018_deaths_imported_dp" ,replace

count //3,344 (2017, 2018, 2019 deaths)

***************
** RUN DOFILES  
***************
** NB: Excel raw data file underwent a basic cleaning prior to import to Stata
** Basic cleaning included checking the GA-CDRC electoral list for mismatched National ID #s (nrn)
** 1st dofile: to rename and format variables to match variables in DeathData REDCap database
do "`logpath'\1_prep_deaths.do"
** Dataset = 2018_deaths_prepped_dp.dta

** 2nd dofile: to clean death dataset removing invalid values and creating variables for export
do "`logpath'\2_clean_deaths.do"
** Dataset = 2018_deaths_cleaned_dc.dta

** 3rd dofile: to export data as excel sheet in preparation for import to DeathData REDCap database
do "`logpath'\3_export_deaths.do"
** Dataset = 2018_deaths_exported_dc.dta 

** 4th dofile: to create report on quality of death data per DA
do "`logpath'\4_quality_deaths.do"
** Dataset = 2018_deaths_report_dqi_da.dta

**********************************************************
/*
	- Includes formatting, cleaning, exporting data
	- Used in conjunction with electoral data

           *******************
           * Cleaning Checks *
           *******************
	___________________________________________

	Field		Check(s)
	___________________________________________

	NAMES		• duplicate identification
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
		
    DA	        • missing
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
		
    OTHER DA	• missing (ddda=98)
				• invalid (ddda=98 but initials has DA code)
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
		
    DOD			• missing
				• invalid (future date)
				• invalid (after regdate)
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
	
    REGDATE		• missing
				• invalid (future date)
				• invalid (before dod)
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

	AGE			• missing
				• invalid (with NRN)
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

	NRN			• length
        		• duplicate identification
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

	REG. ID		• length
				• invalid (range: 0001-9999)
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

	SEX			• invalid (with COD site)
				• invalid (with NRN)
	_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

	DEATH       • invalid (with District)
    PARISH	    
	___________________________________________

*/