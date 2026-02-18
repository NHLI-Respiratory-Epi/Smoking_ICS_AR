1.Create new_endid variable: This is the startid + 365.25
2.If the endid is earlier than the new_endid then replace the new_endid with the old endid.简而言之就是合并这两列保留日期早的，并命名新的列为new_endid
3.Create new_ics_date variable: This will be the first_ics_date if this date falls new_endid
between the startid and the new_endid variable. Make sure that the new_ics_date variable
is set to missing (or NA) if they did not have an ICS date between the startid and the new_endid.如果本来就为NA的则继续保留

# 1. Create new_endid variable: This is the startid + 365.25
Cohort_data_new_smoking_breathless$new_endid <- Cohort_data_new_smoking_breathless$startid + 365.25

# 2. If the endid is earlier than the new_endid then replace the new_endid with the old endid
Cohort_data_new_smoking_breathless$new_endid <- pmin(Cohort_data_new_smoking_breathless$endid, Cohort_data_new_smoking_breathless$new_endid)

# 3. Create new_ics_date variable: This will be the first_ics_date if this date falls between startid and new_endid
# Make sure that the new_ics_date variable is set to NA if the ICS date is not between startid and new_endid
Cohort_data_new_smoking_breathless$new_ics_date <- ifelse(
  !is.na(Cohort_data_new_smoking_breathless$first_ics_date) &
    Cohort_data_new_smoking_breathless$first_ics_date >= Cohort_data_new_smoking_breathless$startid &
    Cohort_data_new_smoking_breathless$first_ics_date <= Cohort_data_new_smoking_breathless$new_endid,
  Cohort_data_new_smoking_breathless$first_ics_date,
  NA
)
Cohort_data_new_smoking_breathless$new_ics_date <- as.Date(Cohort_data_new_smoking_breathless$new_ics_date, origin="1970-01-01")

# Create a new column 'new_ics' where 1 means there's a date in 'new_ics_date', and 0 means it's NA
Cohort_data_new_smoking_breathless$new_ics <- ifelse(
  !is.na(Cohort_data_new_smoking_breathless$new_ics_date), 1, 0
)

write.csv(Cohort_data_new_smoking_breathless, "Cohort_updated.csv", row.names = FALSE)
getwd()
