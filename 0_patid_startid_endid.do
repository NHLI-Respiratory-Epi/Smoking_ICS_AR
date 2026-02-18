********************************************************************************
* BASE COHORT: PHD 
********************************************************************************
clear all
set more off, perm
macro drop _all

global extract "Z:\Group_work\raw_data\asthma_2023\orig_dta\"
*unzipped raw data

global data "Z:\Group_work\Zak\Cohort\PHD\Working_data\"

global code "Z:\Group_work\Zak\Cohort\PHD\Codelists\"

global hes "Z:\Group_work\Zak\Cohort\PHD\HES\"

//==============================================================================

//Open log file
capture log close
log using "Z:\Group_work\Zak\Cohort\PHD\Working_data\1_patid_startid_endid_.smcl", text replace

********************************************************************************
* 1) Merge patient with practice files 
********************************************************************************
use ${extract}Patient_1, clear
forvalues i=2/3{
	append using ${extract}Patient_`i'
}
codebook patid // 2,917,322

merge m:1 pracid using ${extract}Practice_1
drop _m

merge m:1 pracid using ${extract}Practice_2
drop _m

merge m:1 pracid using ${extract}Practice_3
drop _m

codebook patid // 2,917,322

** apply minimum eligibilty criteria

keep if acceptable == 1 & patienttype == 3

tab acceptable patienttype

** check everyone is acceptable and regular 
assert acceptable
assert patienttype
codebook patid // 2,830,512

/* Restrict gender options
	- In this case I only keep those persons identified as 'Male' or 'Female' */
keep if gender == 1 | gender == 2  
codebook patid // 2,830,369

** drop uneccessary variables
drop emis_ddate acceptable patienttype usualgpstaffid uts

save ${data}patient_practice, replace 

****************************************************************************************************************************
* 2) Use the patient_practice file and merge with obs files and asthma codelist to find people with asthma (first diagnosis)
****************************************************************************************************************************
use ${data}patient_practice, clear 

forvalues i=1/240 {   

use ${data}patient_practice, clear 
merge 1:m patid using ${extract}Observation_`i'
keep if _merge==3
drop _merge 

merge m:1 medcodeid using ${code}Asthma_Sept23
keep if _merge==3
drop _merge

save ${data}asthma_aurum_patid_`i', replace
}

use ${data}asthma_aurum_patid_1
forvalues i=2/240{
append using ${data}asthma_aurum_patid_`i'
}

sort patid obsdate
keep if obsdate!=.
by patid: gen litn=_n
keep if litn==1
keep patid obsdate
duplicates drop
gen first_asthma=obsdate

format first_asthma %td
keep patid first_asthma

*This file contains the date of FIRST Asthma diagnosis
save ${data}first_asthma_aurum, replace

********************************************************************************
* 3) Patid, startid, endid
********************************************************************************
*use patient_practice file and merge with first Asthma file just created
use ${data}patient_practice, clear 
merge m:1 patid using ${data}first_asthma_aurum
keep if _m==3
drop _m
codebook patid // 2,830,369 have asthma diagnosis

*change these to your study start and end dates - they are macros, so you need to run these lines and the startid/endid lines all at once.
local startdate = date("01/01/2010", "DMY") 
display %td (`startdate')
local enddate = date("31/03/2021", "DMY") 
display %td (`enddate')

* gen start and end dates for each patient
gen startid = max(regstartdate, first_asthma, `startdate')
gen endid = min(regenddate, lcd, cprd_ddate, `enddate')
format startid endid %td

codebook patid // 2,830,369

bro if startid>=endid
drop if startid>=endid
codebook patid // 2,505,251

keep patid pracid gender dob yob regstartdate regenddate cprd_ddate lcd first_asthma startid endid
save ${data}patid_startid_endid, replace

********************************************************************************
* 4) 1 year min of CPRD registration before Asthma diagnosis 
********************************************************************************
use ${data}patid_startid_endid, clear

gen one_year=startid-365.25
format one_year %td
codebook patid if regstartdate<one_year
gen flag=1 if regstartdate<one_year
keep if flag==1
drop one_year flag
codebook patid // 1,404,831
save ${data}patid_startid_endid_1_year_pre, replace

********************************************************************************
* 5) 1 year min of pre-disease consultation in their CPRD history
********************************************************************************

forvalues i=1/66 {   
use patid consdate using ${extract}Consultation_`i', clear

merge m:1 patid using ${data}patid_startid_endid_1_year_pre
keep if _m==3
drop _m

save ${data}consultation_preasthma_`i', replace
}

use ${data}consultation_preasthma_1, clear
forvalues i=1/66 {   
append using ${data}consultation_preasthma_`i'
}

gen flag=1 if consdate<first_asthma
keep if flag==1
drop consdate flag
duplicates drop 
codebook patid // 1,062,556
save ${data}base_cohort_1_year_pre_consultation_before, replace

********************************************************************************
* 6) HES linkage
********************************************************************************
import delimited "Z:\Group_work\Zak\Cohort\PHD\Working_data\Aurum_enhanced_eligibility_January_2022.txt", clear 
save ${hes}HES_elig, replace

*Use file with startid and endid already defined
use ${data}base_cohort_1_year_pre_consultation_before, clear 
merge 1:1 patid using ${hes}HES_elig
gen keep=1 if hes_apc_e==1 & ons_death_e==1 & lsoa_e==1 & _m==3 & hes_ae_e==1
count if keep==1 
codebook patid if keep==1 // 877,028
keep if keep==1
drop _m

keep patid pracid gender dob yob regstartdate regenddate cprd_ddate lcd startid endid first_asthma hes_apc_e ons_death_e lsoa_e hes_ae_e
codebook patid // 877,028
save ${data}base_cohort_hes, replace 
