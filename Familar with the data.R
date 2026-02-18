# What is the earliest date of asthma diagnosis in this study cohort#

min_date <- min(Cohort_data$first_asthma, na.rm = TRUE)
print(min_date)

#"2010-01-01"

# What is the min date between GP registration date and asthma diagnosis date

colnames(Cohort_data)
gap <- abs(difftime(Cohort_data$regstartdate, Cohort_data$first_asthma, units = "days"))
Cohort_data[which.min(gap), ]
min(gap, na.rm = TRUE)

# 366 days

# What is the last date of asthma diagnosis in this study cohort#
max_date <- max(Cohort_data$first_asthma, na.rm = TRUE)
print(max_date)

#"2021-03-30"

#Let us make Table 1#
library(dplyr)
library(skimr)
skim(Cohort_data)

#Change the variable type to categorical
Cohort_data <- Cohort_data %>% 
  mutate(sex.cat=factor(sex, levels = c(0,1), labels = c("male", "female")),
         imd.cat=factor(imd),
         ethnicity.cat=factor(ethnicity, levels = c(1,2,3,4,5), labels = c("White","Black", "South Asian","Mixed","Other")),
         depression.cat=factor(depression, levels = c(0,1), labels = c("No", "Yes")),
         anxiety.cat=factor(anxiety, levels = c(0,1), labels = c("No", "Yes")),
         smokstatus_old.cat=factor(smokstatus_old, levels = c(0,1,2), labels = c("never smokers", "ex-smokers","current smokers" )),
         ics.cat = factor(ics, levels = c(1), labels = c("Yes")),
         first_asthma_review.cat = factor(first_asthma_review, levels = c(1), labels = c("Yes")))
         
#Using gtsummary
library(gtsummary)
summary(Cohort_data$smokstatus_old.cat)

Cohort_data %>% 
  filter(!is.na(smokstatus_old.cat)) %>%
  select(age, sex.cat, bmi_cont, imd.cat, ethnicity.cat, depression.cat, anxiety.cat, smokstatus_old.cat, ics.cat, first_asthma_review.cat) %>%
  tbl_summary(
    by = smokstatus_old.cat,
    type = list(age ~ "continuous2",
                bmi_cont ~ "continuous2"),
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",  
      all_categorical() ~ "{n} ({p}%)"     
    ),
    digits = list(
      all_continuous() ~ c(2, 2),        
      all_categorical() ~ c(0, 2)         
    ),
    missing = "ifany",
    missing_text = "Unknown"
  ) %>%
  add_overall(last = TRUE) %>%
  bold_labels() %>%
  modify_caption("**Table 1. Patient Characteristics by Smoking Status**") %>% 
  as_gt() %>% 
  gt::gtsave(file = "Y:/Summer_projects_2025/Rutao/Table 1.docx")


#Cox regression model#
#time to first ics prescription
 Cohort_data  <- Cohort_data %>%
  mutate(time_ics = if_else(!is.na(first_ics_date),
                            as.integer(first_ics_date - startid),
                            as.integer(endid - startid)))

Cohort_data <- Cohort_data %>%
  mutate(ics = replace_na(ics, 0)) 

#Crude model
crude_model <- coxph(Surv(time_ics,ics) ~ smokstatus_old.cat,data = Cohort_data)
summary(crude_model)

#test the Proportional Hazards Assumption
test_cox <- cox.zph(crude_model)
plot(test_cox)

# Survival curve 
fit <- survfit(Surv(time_ics,ics)~smokstatus_old.cat,data = Cohort_data)
ggsurvplot(survfit(Surv(time_ics,ics)~smokstatus_old.cat,data = Cohort_data ), 
           surv.median.line = "hv", 
           pval = T, 
           xlab = "Time(days)",
           ylab = "ICS Prescription-free Probability", 
           legend.title = "Smoking status", 
           legend.labs = c("never smokers", "ex-smokers", "current smokers"),  
           ggtheme = theme_minimal(),  
           break.x.by = 500, 
           palette = c("#bc5148", "#3090a1","#ffd700")) 

summary(fit)$table


#Fully adjusted model
Cohort_data$ethnicity.cat <- factor(Cohort_data$ethnicity.cat, levels = c(levels(Cohort_data$ethnicity.cat), "Unknown"))
Cohort_data$ethnicity.cat[is.na(Cohort_data$ethnicity.cat)] <- "Unknown"
table(Cohort_data$ethnicity.cat) 
library(mice)

#multiple imputation
Cohort_data[] <- lapply(Cohort_data, function(x) {
  if (inherits(x, "haven_labelled")) {  
    if (all(is.na(as.numeric(x, errors = "quiet")))) {  
      return(as_factor(x))  
    } else {
      return(as.numeric(x))  
    }
  } else {
    return(x)  # Make sure R could handle this type of data
  }
})

imp_methods <- make.method(Cohort_data)
imp_methods[] <- ""
imp_methods["bmi_cont"] <- "pmm" 
imputed_data <- mice(Cohort_data, method = imp_methods, m = 5, seed = 123)
fitted_models <- with(data = imputed_data, exp = {
  model <- coxph(Surv(time_ics, ics) ~ age + sex.cat + bmi_cont + imd.cat + ethnicity.cat + depression.cat + anxiety.cat + smokstatus_old.cat)
})

pooled_results <- pool(fitted_models)
summary(pooled_results)

# HR
results_df <- tidy(pooled_results)
results_df$HR <- exp(results_df$estimate)
results_df <- results_df[, c("term", "HR",  "p.value")]
print(results_df)


#Without multiple imputation
fully_adjusted_model <- coxph(Surv(time_ics,ics) ~ age +sex.cat + bmi_cont + imd.cat + ethnicity.cat + depression.cat + anxiety.cat + smokstatus_old.cat,data = Cohort_data)
summary(fully_adjusted_model)


#time to first asthma review
Cohort_data  <- Cohort_data %>%
  mutate(time_review = if_else(!is.na(first_asthma_review_date),
                            as.integer(first_asthma_review_date - startid),
                            as.integer(endid - startid)))

Cohort_data <- Cohort_data %>%
  mutate(first_asthma_review = replace_na(first_asthma_review, 0))

#Crude model
crude_model <- coxph(Surv(time_review,first_asthma_review) ~ smokstatus_old.cat,data = Cohort_data)
summary(crude_model)

#test the Proportional Hazards Assumption
test_cox <- cox.zph(crude_model)
plot(test_cox)

# Survival curve 
fit <- survfit(Surv(time_review,first_asthma_review)~smokstatus_old.cat,data = Cohort_data)
ggsurvplot(survfit(Surv(time_review,first_asthma_review)~smokstatus_old.cat,data = Cohort_data ), 
           surv.median.line = "hv", 
           pval = T, 
           xlab = "Time(days)",
           ylab = "First asthma review-free Probability", 
           legend.title = "Smoking status", 
           legend.labs = c("never smokers", "ex-smokers", "current smokers"),  
           ggtheme = theme_minimal(),  
           break.x.by = 500, 
           palette = c("#bc5148", "#3090a1","#ffd700")) 

summary(fit)$table


