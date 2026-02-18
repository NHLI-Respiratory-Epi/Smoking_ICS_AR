#Let us make Table 1#
library(dplyr)
library(skimr)
skim(Cohort_data_new_smoking_breathless)

#Change the variable type to categorical
Cohort_data_new_smoking_breathless <- Cohort_data_new_smoking_breathless %>% 
  mutate(sex.cat=factor(sex, levels = c(0,1), labels = c("male", "female")),
         imd.cat=factor(imd),
         ethnicity.cat=factor(ethnicity, levels = c(1,2,3,4,5), labels = c("White","Black", "South Asian","Mixed","Other")),
         depression.cat=factor(depression, levels = c(0,1), labels = c("No", "Yes")),
         anxiety.cat=factor(anxiety, levels = c(0,1), labels = c("No", "Yes")),
         breathlessness.cat=factor(breathlessness, levels = c(0,1), labels = c("No", "Yes")),
         smokstatus.cat=factor(smokstatus, levels = c(0,1,2), labels = c("never smokers", "ex-smokers","current smokers" )),
         ics.cat = factor(ics, levels = c(1), labels = c("Yes")),
         first_asthma_review.cat = factor(first_asthma_review, levels = c(1), labels = c("Yes")))

#Using gtsummary
library(gtsummary)
summary(Cohort_data_new_smoking_breathless$smokstatus.cat)

Cohort_data_new_smoking_breathless %>% 
  filter(!is.na(smokstatus.cat)) %>%
  select(age, sex.cat, bmi_cont, imd.cat, ethnicity.cat, depression.cat, anxiety.cat, breathlessness.cat, smokstatus.cat, ics.cat, first_asthma_review.cat) %>%
  tbl_summary(
    by = smokstatus.cat,
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
  gt::gtsave(file = "Y:/Summer_projects_2025/Rutao/NewTable 1.docx")


#Cox regression model#
#time to first ics prescription
Cohort_data_new_smoking_breathless  <-  Cohort_data_new_smoking_breathless %>%
  mutate(time_ics = if_else(!is.na(first_ics_date),
                            as.integer(first_ics_date - startid),
                            as.integer(endid - startid)))

Cohort_data_new_smoking_breathless <-  Cohort_data_new_smoking_breathless %>%
  mutate(ics = replace_na(ics, 0)) 

#Crude model
crude_model <- coxph(Surv(time_ics,ics) ~ smokstatus.cat,data = Cohort_data_new_smoking_breathless)
summary(crude_model)

#test the Proportional Hazards Assumption
cox.zph(crude_model)
test_cox <- cox.zph(crude_model)
plot(test_cox, xlab = "Follow-Up time (days)", ylab = "Schoenfeld residuals")

# Estimated Survival curve 
fit <- survfit(Surv(time_ics,ics)~smokstatus.cat,data = Cohort_data_new_smoking_breathless)
ggsurvplot(survfit(Surv(time_ics,ics)~smokstatus.cat,data = Cohort_data_new_smoking_breathless ), 
           surv.median.line = "hv", 
           pval = T, 
           xlab = "Time(days)",
           ylab = "First ICS Prescription-free Probability", 
           legend.title = "Smoking status", 
           legend.labs = c("Never smokers", "Ex-smokers", "Current smokers"),  
           ggtheme = theme_minimal(),  
           break.x.by = 500, 
           palette = c("#bc5148", "#3090a1","#ffd700")) 

summary(fit)$table


#Fully adjusted model
fully_adjusted_model <- coxph(Surv(time_ics,ics) ~ age +sex.cat + bmi_cont + imd.cat + ethnicity.cat + depression.cat + anxiety.cat + breathlessness.cat + smokstatus.cat,data = Cohort_data_new_smoking_breathless)
summary(fully_adjusted_model)

#test the Proportional Hazards Assumption
test_cox2 <- cox.zph(fully_adjusted_model)
plot(test_cox2, xlab = "Follow-Up time (days)", ylab = "Schoenfeld residuals")

#Forestplot
selected_data <- select(Cohort_data_new_smoking_breathless, time_ics, ics, age, sex.cat, bmi_cont, imd.cat, ethnicity.cat, depression.cat, anxiety.cat, breathlessness.cat, smokstatus.cat)
head(selected_data)
selected_data <- rename(selected_data,
                        time = time_ics,
                        event = ics,
                        Age = age,
                        Sex = sex.cat,
                        BMI = bmi_cont,
                        IMD = imd.cat,
                        Ethnicity = ethnicity.cat,
                        Depression = depression.cat,
                        Anxiety = anxiety.cat,
                        Breathlessness = breathlessness.cat,
                        Smokstatus = smokstatus.cat)
write.csv(selected_data, "Y:/Summer_projects_2025/Rutao/Forest1.csv", row.names = FALSE)

Forest1$IMD <- factor(Forest1$IMD, levels = 1:6)
Forest1$Ethnicity <- factor(Forest1$Ethnicity, levels = c("White", "Black", "Mixed", "South Asian", "Other"))
Forest1$Smokstatus <- factor(Forest1$Smokstatus, levels = c("never smokers", "current smokers", "ex-smokers"))
Forest123 <- coxph(Surv(Time,Event) ~ Age +Sex + BMI + IMD + Ethnicity + Depression + Anxiety + Breathlessness + Smokstatus,data = Forest1)
summary(Forest123)
ggforest(model = Forest123, data = Forest1, 
         cpositions = c(0.23, 0.3, 0.4),
         refLabel = "Ref", 
         fontsize = 0.8, 
         noDigits = 2, 
         main = "Hazard Ratios")

#Fully adjusted model without BMI
fully_adjusted_model_withoutBMI <- coxph(Surv(time_ics,ics) ~ age +sex.cat + imd.cat + ethnicity.cat + depression.cat + anxiety.cat + breathlessness.cat + smokstatus.cat,data = Cohort_data_new_smoking_breathless)
summary(fully_adjusted_model_withoutBMI)

#Breathlessness model
breathlessness_model <- coxph(Surv(time_ics,ics) ~ breathlessness.cat,data = Cohort_data_new_smoking_breathless)
summary(breathlessness_model)








#time to first asthma review
Cohort_data_new_smoking_breathless <- Cohort_data_new_smoking_breathless %>%
  mutate(time_review = if_else(!is.na(first_asthma_review_date),
                               as.integer(first_asthma_review_date - startid),
                               as.integer(endid - startid)))

Cohort_data_new_smoking_breathless <- Cohort_data_new_smoking_breathless %>%
  mutate(first_asthma_review = replace_na(first_asthma_review, 0))

#Crude model
crude_model <- coxph(Surv(time_review,first_asthma_review) ~ smokstatus.cat,data = Cohort_data_new_smoking_breathless)
summary(crude_model)

#test the Proportional Hazards Assumption
test_cox <- cox.zph(crude_model)
plot(test_cox,xlab = "Follow-Up time (days)", ylab = "Schoenfeld residuals")

# Survival curve 
fit <- survfit(Surv(time_review,first_asthma_review)~smokstatus.cat,data = Cohort_data_new_smoking_breathless)
ggsurvplot(survfit(Surv(time_review,first_asthma_review)~smokstatus.cat,data = Cohort_data_new_smoking_breathless ), 
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

#Fully adjusted model and Forestplot
selected_data2 <- select(Cohort_data_new_smoking_breathless, time_review, first_asthma_review, age, sex.cat, bmi_cont, imd.cat, ethnicity.cat, depression.cat, anxiety.cat, breathlessness.cat, smokstatus.cat)
head(selected_data2)
selected_data2 <- rename(selected_data2,
                        time = time_review,
                        event = first_asthma_review,
                        Age = age,
                        Sex = sex.cat,
                        BMI = bmi_cont,
                        IMD = imd.cat,
                        Ethnicity = ethnicity.cat,
                        Depression = depression.cat,
                        Anxiety = anxiety.cat,
                        Breathlessness = breathlessness.cat,
                        Smokstatus = smokstatus.cat)
write.csv(selected_data2, "Y:/Summer_projects_2025/Rutao/Forest2.csv", row.names = FALSE)

Forest2$IMD <- factor(Forest2$IMD, levels = 1:6)
Forest2$Ethnicity <- factor(Forest2$Ethnicity, levels = c("White", "Black", "Mixed", "South Asian", "Other"))
Forest2$Smokstatus <- factor(Forest2$Smokstatus, levels = c("never smokers", "current smokers", "ex-smokers"))
Forest_model <- coxph(Surv(time,event) ~ Age +Sex + BMI + IMD + Ethnicity + Depression + Anxiety + Breathlessness + Smokstatus,data = Forest2)
summary(Forest_model)
ggforest(model = Forest_model, data = Forest2, 
         cpositions = c(0.23, 0.3, 0.4),
         refLabel = "Ref", 
         fontsize = 0.8, 
         noDigits = 2, 
         main = "Hazard Ratios")

#test the Proportional Hazards Assumption
test_cox <- cox.zph(Forest_model)
plot(test_cox, xlab = "Follow-Up time (days)", ylab = "Schoenfeld residuals")

#Fully adjusted model without BMI
Forest_model_withoutBMI <- coxph(Surv(time,event) ~ Age +Sex + IMD + Ethnicity + Depression + Anxiety + Breathlessness + Smokstatus,data = Forest2)
summary(Forest_model_withoutBMI)

#Fully adjusted model without Ethnicity
Forest_model_withoutEthnicity <- coxph(Surv(time,event) ~ Age +Sex + IMD + BMI + Depression + Anxiety + Breathlessness + Smokstatus,data = Forest2)
summary(Forest_model_withoutEthnicity)

write.csv(Cohort_data_new_smoking_breathless, file = "Cohort_data_new_smoking_breathless.csv", row.names = FALSE)


