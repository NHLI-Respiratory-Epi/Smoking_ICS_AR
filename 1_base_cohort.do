********************************************************************************
* Creating patient base cohort from Zak's cohort
********************************************************************************
clear all
set more off, perm
macro drop _all


**************************************************************************

use ${data}base_cohort_hes, clear
codebook patid // 877,028
codebook patid if first_asthma==startid // 420,909 
save ${data}prevalent_base_cohort, replace 


use ${data}base_cohort_hes, clear
keep if first_asthma==startid 
codebook patid // 420,909 
save ${data}incident_base_cohort, replace 




