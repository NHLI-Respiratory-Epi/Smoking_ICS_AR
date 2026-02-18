********************************************************************************
* Creating outcomes
********************************************************************************
clear all
set more off, perm
macro drop _all

global extract "X:\raw_data\asthma_2023\orig_dta\"
*unzipped raw data

global data "X:\Hannah\Asthma_reviews\Working_data\"

global codelist "X:\Hannah\Asthma_reviews\Codelists\"


**************************************************************************
*Outcomes: ARs, GP visits, rc3p, spirom, inhaler tehcnique 
**************************************************************************

*Asthma annual reviews 
use ${data}incident_base_cohort, clear 
merge 1:m patid using ${data}Observation_merged_all 
keep if _m==3
drop _merge
keep if asthma_review==1
keep if obsdate>startid & obsdate<=endid 
keep patid medcodeid obsdate asthma_review  startid endid 
sort patid obsdate
preserve 
sort patid obsdate
by patid obsdate: gen litn=_n
keep if litn==1
drop litn
by patid: gen n_asthma_reviews=_N 
drop obsdate 
duplicates drop
keep patid n_asthma_reviews
save ${data}n_asthma_reviews_outcome, replace 
restore 
merge m:1 medcodeid using ${data}asthma_review, force
keep if _m==3
drop _m
save ${data}all_asthma_reviews, replace

*QOF asthma annual reviews 
use ${data}incident_base_cohort, clear 
merge 1:m patid using ${data}Observation_merged_all 
keep if _m==3
drop _merge
keep if asthma_review==1
keep if obsdate>startid & obsdate<=endid 
keep patid medcodeid obsdate   startid endid 
merge m:1 medcodeid using ${data}asthma_review_qof
keep if _m==3 
drop _m
sort patid obsdate
by patid obsdate: gen litn=_n
keep if litn==1
drop litn
by patid: gen n_asthma_reviews=_N 
drop obsdate 
duplicates drop
keep patid n_asthma_reviews
duplicates drop
save ${data}n_asthma_reviews_outcome_qof, replace 

*First annual review 
use  ${data}Observation_merged_all, clear 
keep if asthma_review==1
keep if obsdate>startid & obsdate<=endid 
keep patid obsdate asthma_review startid endid 
sort patid obsdate
by patid: gen first_asthma_review=_n
keep if first_asthma_review==1
keep patid obsdate first_asthma_review
rename obsdate first_asthma_review_date
duplicates drop
save ${data}first_asthma_review_outcome, replace 

* GP visits //////
import delimited "Y:\CPRD_Research_Data\Lookup_Files\202309_Lookups_CPRDAurum\ConsSource.txt", stringcols(1) clear 
drop if description == "Awaiting review"

*death (as a test)
import delimited "Z:\Group_work\Hannah\Asthma_reviews\Working_data\death_patient_24_003707_DM.txt", clear 
keep patid dod cause cause1
gen dod2=date(dod, "DMY")
format dod2 %td
drop dod 
rename dod2 dod
format patid %18.0g
save ${data}dod_hes, replace 

*spirometry during AR
use ${data}Observation_merged_all, clear
keep if expiratory_all==1
keep patid obsdate expiratory_all startid endid
keep if obsdate>startid & obsdate<=endid
duplicates drop
sort patid obsdate
by patid obsdate: gen bign=_N
tempfile spirom 
save `spirom'

use ${data}all_asthma_reviews, clear
keep if ar_type=="1" 
drop medcodeid
duplicates drop
sort patid obsdate
by patid obsdate: gen bign=_N

merge 1:1 patid obsdate using `spirom'
keep if _m==3 // spirom recorded on same day as asthma review date
drop _merge
keep patid obsdate expiratory_all
sort patid 
by patid: gen tot_spirom=_N
keep patid tot_spirom
duplicates drop
save ${data}spirom_during_ar, replace 

*rcp during AR
use ${data}Observation_merged_all, clear
keep if rcp3q==1
keep patid obsdate rcp3q startid endid
keep if obsdate>startid & obsdate<=endid
duplicates drop
sort patid obsdate
tempfile rc3pq 
save `rc3pq'

use ${data}ar_nurse_gp, clear
keep if job_cat_ar==1 
duplicates drop
sort patid obsdate

merge 1:1 patid obsdate using `rc3pq'
keep if _m==3 // rc3pq recorded on same day as asthma review date
drop _merge
keep patid obsdate rcp3q
sort patid
by patid: gen tot_rcp3q=_N
keep patid tot_rcp3q
duplicates drop
save ${data}rcp3q_during_ar, replace 

*inhaler technique
use ${data}Observation_merged_all, clear
keep if inhaler_technique==1
keep patid obsdate inhaler_technique startid endid
keep if obsdate>startid & obsdate<=endid
duplicates drop
sort patid obsdate
tempfile inhaler_technique 
save `inhaler_technique'

use ${data}ar_nurse_gp, clear
keep if job_cat_ar==1 
duplicates drop
sort patid obsdate

merge 1:1 patid obsdate using `inhaler_technique'
keep if _m==3 // inhaler_technique recorded on same day as asthma review date
drop _merge
keep patid obsdate inhaler_technique
sort patid 
by patid: gen tot_inhaler_technique=_N
keep patid tot_inhaler_technique
duplicates drop
save ${data}inhaler_technique_during_ar, replace 

*Asthma management plan - accepted/done
use ${data}Observation_action_plan_all, clear
keep if action_plan==1
keep patid obsdate action_plan startid endid
keep if obsdate>startid & obsdate<=endid
duplicates drop
sort patid obsdate
tempfile asthma_plan 
save `asthma_plan'

use ${data}ar_nurse_gp, clear
keep if job_cat_ar==1 
duplicates drop
sort patid obsdate

merge 1:1 patid obsdate using `asthma_plan'
keep if _m==3 // inhaler_technique recorded on same day as asthma review date
drop _merge
keep patid obsdate action_plan
sort patid 
by patid: gen tot_action_plan=_N
keep patid tot_action_plan
duplicates drop
save ${data}asthma_management_plan_during_ar, replace 



*First ICS prescription
use ${data}DrugIssue_merged_all, clear
keep if ics==1 | icslaba==1 | triple==1
keep patid issuedate startid endid
gen ics=1
keep if issuedate>startid & issuedate<=endid
sort patid issuedate
by patid: gen litn=_n
keep if litn==1
keep patid ics issuedate
rename issuedate first_ics_date
save ${data}first_ics, replace 

*GP visits 
use ${data}gp_visits_all, clear 
keep if consdate>startid & consdate<=endid 
sort patid consdate 
duplicates drop
by patid: gen n_gp_visits=_N 
keep patid n_gp_visits 
duplicates drop
save ${data}gp_visits_outcome, replace 

use ${data}gp_visits_all, clear 
keep if consdate<startid & consdate>=(startid-365.25)
sort patid consdate 
duplicates drop
by patid consdate:gen litn=_n
keep if litn==1
by patid: gen hx_gp_visits=_N 
keep patid hx_gp_visits 
duplicates drop
save ${data}gp_visits_hx, replace 



*Asthma action plan 
use ${data}Observation_action_plan_all, clear 
keep if obsdate>startid & obsdate<=endid
keep patid obsdate action_plan startid endid
duplicates drop
sort patid obsdate
by patid obsdate: gen bign=_N
by patid obsdate: gen litn=_n
keep if litn==bign
drop litn bign
tempfile action_plan 
save `action_plan'

use ${data}all_asthma_reviews, clear
keep if ar_type=="1" 
drop medcodeid
duplicates drop
sort patid obsdate
by patid obsdate: gen bign=_N

merge 1:1 patid obsdate using `action_plan'
keep if _m==3 // rc3pq recorded on same day as asthma review date
drop _merge
keep patid obsdate action_plan
sort patid
by patid: gen tot_action_plan=_N
keep patid tot_action_plan
duplicates drop
save ${data}action_plan_during_ar, replace 



****************************
*covariates 
*************************
*Depression in year prior
use ${data}Observation_merged_all, clear
keep if depression==1
keep patid obsdate depression startid endid
keep if obsdate<=startid & obsdate>startid-365.25
keep patid depression 
duplicates drop
save ${data}depression_year_before, replace 

*Anxiety in year prior
use ${data}Observation_merged_all, clear
keep if anxiety==1
keep patid obsdate anxiety startid endid
keep if obsdate<=startid & obsdate>startid-365.25
keep patid anxiety 
duplicates drop
save ${data}anxiety_year_before, replace 


*previous GP visits (test)
use ${data}gp_visits_all, clear 
keep if consdate<startid & consdate>=(startid-1095.75)
sort patid consdate
by patid: gen hx_gp_visits=_N 
keep patid hx_gp_visits
duplicates drop
save ${data}gp_visits_covar, replace 

*****************************
*Merge together
***************************
use  ${data}incident_base_cohort, clear 
*asthma annual reviews
merge 1:1 patid using ${data}first_asthma_review_outcome
drop _merge
merge 1:1 patid using ${data}n_asthma_reviews_outcome
drop _merge
gen sex=1 if gender==2 // sex=1 for females 
replace sex=0 if gender==1 // sex=0 for males 
*mortality (just in case)
merge 1:1 patid using ${data}dod_hes
keep if _m==3 | _m==1
drop _m
*ics 
merge 1:1 patid using ${data}first_ics
drop _m
*rcp3q_during_ar
merge 1:1 patid using ${data}rcp3q_during_ar
drop _m
*inhaler_technique_during_ar
merge 1:1 patid using ${data}inhaler_technique_during_ar
drop _m
*spirom_during_ar
merge 1:1 patid using ${data}spirom_during_ar
drop _m
*action plan during ar
merge 1:1 patid using ${data}action_plan_during_ar 
drop _merge
*depression 
merge 1:1 patid using ${data}depression_year_before
drop _m
*anxiety
merge 1:1 patid using ${data}anxiety_year_before
drop _m
*smoking 
merge 1:1 patid using ${data}smoking
keep if _m==3 | _m==1
drop _merge
*bmi
merge 1:1 patid using ${data}bmi
keep if _m==3 | _m==1
drop _m
*imd
merge 1:1 patid using ${data}imd
keep if _m==3 | _m==1
drop _m
*ethnicity
merge 1:1 patid using ${data}ethnicity
keep if _m==3 | _m==1 
drop _m
*previous gp visits 
merge 1:1 patid using ${data}gp_visits_covar
keep if _m==3 | _m==1 
drop _m
*gp outcome 
merge 1:1 patid using ${data}gp_visits_outcome
keep if _m==3 | _m==1
drop _merge

drop hes_apc_e ons_death_e lsoa_e hes_ae_e
rename eth5 ethnicity 
rename e2019_imd_5 imd
drop ethnicity_source eth11 eth16
gen age=startid-dob
replace age=age/365.25
recode depression .=0
recode anxiety .=0
recode n_gp_visits .=0
recode hx_gp_visits .=0
recode tot_action_plan .=0
save ${data}final_analysis_cohort, replace 

use ${data}final_analysis_cohort, clear
drop n_asthma_reviews_qof 

merge 1:1 patid using ${data}n_asthma_reviews_outcome_qof
drop _merge

rename n_asthma_reviews n_asthma_reviews_qof
recode n_asthma_reviews_qof .=0
save ${data}final_analysis_cohort, replace 










