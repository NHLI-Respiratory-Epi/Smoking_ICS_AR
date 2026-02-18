********************************************************************************
* Merging in master codelist 
********************************************************************************
clear all
set more off, perm
macro drop _all

global extract "X:\raw_data\asthma_2023\orig_dta\"
*unzipped raw data

global data "X:\Hannah\Asthma_reviews\Working_data\"

global codelist "X:\Hannah\Asthma_reviews\Codelists\"


*Notes: 
*OUTCOMES: asthma annual review visit, inhaler technique, spirometry, rcp3q, ICS 
*COVARIATES: Smoking, ethnicity, BMI, IMD, anxiety, depression, lung cancer, CVD
**************************************************************************

*1) Check and clean up existing code lists

*ICS 
use ${codelist}all_medications_raw, clear
keep if final==1
keep if ics_0302!=. | icslaba_0302!=. | triple_0302!=. 
keep prodcodeid termfromemis productname category ics_0302 icslaba_0302 triple_0302  
rename ics_0302 ics 
rename icslaba_0302 icslaba
rename triple_0302 triple
save ${codelist}all_ics, replace 

*inhaler technique 
import delimited "Y:\CPRD_Research_Data\Code_Browsers\CPRD_CodeBrowser_202309_Aurum\CPRDAurumMedical.txt", stringcols(1) clear 
merge 1:1 medcodeid using  ${codelist}inhaler_technique 
keep if _m==3 
drop _m

*rcp3q  
import delimited "Y:\CPRD_Research_Data\Code_Browsers\CPRD_CodeBrowser_202309_Aurum\CPRDAurumMedical.txt", stringcols(1) clear 
merge 1:1 medcodeid using ${codelist}rcp3q
keep if _m==3 
drop _m


*asthma review
import excel "Z:\Group_work\Hannah\Asthma_reviews\Codelists\asthma_annual_reviews.xls", sheet("Sheet1") firstrow allstring clear

preserve 
keep medcodeid ar_type asthma_review
save ${data}asthma_review, replace 
restore 

gen qof_ar=1 if snomedctconceptid=="270442000" | snomedctconceptid=="390872009" | snomedctconceptid=="390877003" | snomedctconceptid=="390878008" | snomedctconceptid=="394701000" | snomedctconceptid=="394720003" | snomedctconceptid=="401182001" | snomedctconceptid=="401183006" | snomedctconceptid=="754061000000100"| snomedctconceptid=="394700004"

keep if qof_ar==1
keep medcodeid ar_type asthma_review qof_ar term
save ${data}asthma_review_qof, replace 


*SABA/SAMA 
use ${codelist}all_medications_raw, clear
keep if final==1
keep if saba_030101!=. |  sama_030102!=. | sabasama_30104!=.
keep prodcodeid termfromemis productname category saba_030101 sama_030102 sabasama_30104  
rename saba_030101 saba 
rename sama_030102 sama
rename sabasama_30104 sabasama
save ${codelist}all_sama_saba, replace 

*smoking - have already from Zak's cohort
use "Z:\Group_work\Zak\Cohort\PHD\Merged_data\smoking_all_adults.dta", clear
keep patid smokstatus vapestatus
save ${data}smoking, replace 

*ethnicity - have already from Zak's cohort
use "Z:\Group_work\Zak\Cohort\PHD\Merged_data\ethnicity_all_adults.dta", clear
keep patid ethnicity_source eth5 eth11 eth16
save ${data}ethnicity, replace 

*BMI - from Zak's cohort
use "Z:\Group_work\Zak\Cohort\PHD\Merged_data\bmi_adults_all.dta",clear 
keep patid bmi_final bmi_cat_4 bmi_cat_normal
save ${data}bmi, replace

*IMD - from Zak's cohort 
use "Z:\Group_work\Zak\Cohort\PhD\Working_data\base_cohort_adults_esa.dta", clear
replace e2019_imd_5=6 if e2019_imd_5==.
label define imd5 6 "Missing"
label values e2019_imd_5 imd5
label variable e2019_imd_5 "IMD composite (quintiles)"
keep patid e2019_imd_5
save ${data}imd, replace 

*Depression
use ${codelist}depression_202309_raw_JKQ, clear 
keep if JKQ=="1"
keep medcodeid term depression
save ${codelist}depression, replace 

*Anxiety
use ${codelist}anxiety_202309_raw_JKQ, clear 
keep medcodeid anxiety 
save ${codelist}anxiety, replace 


*spirometry 
use ${codelist}lungfunction_comprehensive_raw_JKQ, clear 
drop if observations==.
keep medcodeid term expiratory_all forced_fev1_fvc residual tidal inspiratory_other reversibility_test_fev1_indic
keep if expiratory_all==1 | forced_fev1_fvc==1 | residual==1 | tidal==1 | inspiratory_other==1 | reversibility_test_fev1_indic==1 
keep if expiratory_all==1
save ${codelist}lungfunction, replace


*Create master codelist (observation)
use ${codelist}inhaler_technique, clear 
merge 1:1 medcodeid using ${codelist}rcp3qeos
drop _m
merge 1:1 medcodeid using ${codelist}asthma_review 
drop _m
merge 1:1 medcodeid using ${codelist}depression 
drop _m
merge 1:1 medcodeid using ${codelist}anxiety 
drop _m
merge 1:1 medcodeid using ${codelist}lungfunction
drop _m
drop forced_fev1_fvc residual tidal inspiratory_other reversibility_test_fev1_indic term
save ${codelist}master_codelist, replace 

*Create master codelist (drug issue)
use ${codelist}all_sama_saba, clear  
merge 1:1 prodcodeid using ${codelist}all_ics
drop _m termfromemis productname 
save ${codelist}master_codelist_drugs, replace 

*2) Merging master codelist through observation files 
forvalues i=1/240{
	use ${extract}Observation_`i', clear 
	merge m:1 medcodeid using ${codelist}master_codelist
	keep if _m==3 
	drop _m
save ${data}Observation_merged_`i', replace 
}

use ${data}Observation_merged_1, clear 
forvalues i=2/240{
	append using ${data}Observation_merged_`i'
}
save ${data}Observation_merged_all, replace

use ${data}incident_base_cohort, clear 
merge 1:m patid using ${data}Observation_merged_all 
keep if _m==3
drop _merge
save ${data}Observation_merged_all, replace 



*3) Merging master codelist through drug issue files 
forvalues i=1/193{
	use ${extract}DrugIssue_`i', clear 
	merge m:1 prodcodeid using ${codelist}master_codelist_drugs
	keep if _m==3 
	drop _m
save ${data}DrugIssue_merged_`i', replace 
}

use ${data}DrugIssue_merged_1, clear 
forvalues i=2/193{
	append using ${data}DrugIssue_merged_`i'
}
save ${data}DrugIssue_merged_all, replace


use ${data}incident_base_cohort, clear 
merge 1:m patid using ${data}DrugIssue_merged_all 
keep if _m==3
drop _merge
save ${data}DrugIssue_merged_all, replace



*4) Merging through consultation files 
forvalues i=1/66{
use ${extract}Consultation_`i', clear 
merge m:1 patid using ${data}incident_base_cohort
keep if _m==3 
drop _m
merge m:1 conssourceid using ${codelist}GP_visits_final
keep if _m==3 
drop _merge
save ${data}GP_visits_`i', replace 
}


use ${data}GP_visits_1, clear
forvalues i=2/66{
	append using ${data}GP_visits_`i'
}

keep patid consdate startid endid 
gen gp_visit=1 if consdate!=.
duplicates drop
save ${data}gp_visits_all, replace 



*5) Merging through asthma action plan and observation files (forgot to do this before)
import excel "X:\Hannah\Code_lists\Asthma_action_plan\Copy of asthma_action_plan_jkq_2.xls", sheet("Sheet1") firstrow allstring clear
keep if keep=="1" | keep=="2"
keep medcodeid term keep 
gen action_plan=1 if keep=="1"
replace action_plan=2 if keep=="2"
label define lab1 1"action plan" 2"action plan declined"
label values action_plan lab1
drop keep
duplicates drop
save ${data}action_plan, replace 
 
forvalues i=1/240{
	use ${extract}Observation_`i', clear 
	merge m:1 medcodeid using ${data}action_plan
	keep if _m==3 
	drop _m
	merge m:1 patid using ${data}incident_base_cohort
	keep if _m==3
	drop _m
save ${data}Observation_action_plan_`i', replace 
}

use ${data}Observation_action_plan_1, clear 
forvalues i=2/240{
	append using ${data}Observation_action_plan_`i'
}
save ${data}Observation_action_plan_all, replace


*eosinophisl for baseline table-review 
forvalues i=1/240{
	use ${extract}Observation_`i', clear 
	merge m:1 medcodeid using "X:\Mathias\Code_lists\Code_lists_removed_0s\Clean\eosinophil.dta"
	keep if _m==3 
	drop _m
	merge m:1 patid using "Y:\Summer_projects_2025\Rutao\Cohort_data_new_smoking_breathless.dta"
	keep if _m==3
	drop _m
save ${data}Observation_eos_`i', replace 
}

use ${data}Observation_eos_1, clear 
forvalues i=2/240{
	append using  ${data}Observation_eos_`i'
}


keep patid obsdate startid eosinophil value term numunitid
keep if obsdate<startid & obsdate>=startid-(365.25*2)
sort patid obsdate 
by patid: gen litn=_n 
by patid: gen bign=_N 
keep if litn==bign 
tostring numunitid, replace 
merge m:1 numunitid using "X:\Mathias\Code_lists\Code_lists_removed_0s\Clean\numunitid.dta"
keep if _m==3 | _m==1
drop _merge
tab numunitid, sort // all but  1, 1094, 334, 1199, 64, 67, 347, 74, 3376, 986, 1428, 2691, 160, 246, 368, 1029 
drop eosinophil 
gen eosinophil=value 
replace eosinophil=. if numunitid=="1" | numunitid=="1094" | numunitid=="334" | numunitid=="1199" | numunitid=="64" | numunitid=="67" | numunitid=="347" | numunitid=="74" | numunitid=="3376" | numunitid=="986" | numunitid=="1428" | numunitid=="2691" | numunitid=="160" | numunitid=="246" | numunitid=="368" | numunitid=="1029" 
sum eosinophil, d
drop if eosinophil==.
drop if eosinophil>=10
keep patid eosinophil
replace eosinophil=eosinophil*1000
merge 1:1 patid using "Y:\Summer_projects_2025\Rutao\Cohort_data_new_smoking_breathless.dta"
drop _m 
save "Y:\Summer_projects_2025\Rutao\Cohort_data_new_smoking_breathless.dta", replace 












