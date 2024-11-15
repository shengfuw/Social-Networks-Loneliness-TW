

* Start logging
cd "$log"
log using "c_ego_level_statistics", text replace


cd "$workdata"
use "alter_data.dta", clear
save "ego_level_statistics_stata.dta", replace

************** Network Size (Degree) **************


************** Multiplexity **************
/* the number of ways that ego and alter are related */
/* This measure cannot be calucaluted because each tie can only be ONE kind of relatiohsip. */


************** Tie strength **************
egen tie_strength_mean = mean(tie_strength), by(ego_id)
egen tie_strength_sd = sd(tie_strength), by(ego_id)
 
 
************** Composition **************
** Relationship type
* Has spouse
gen has_spouse_temp = rel_raw == 1 if rel_raw != .
egen has_spouse = max(has_spouse_temp), by(ego_id)
lab var has_spouse "Whether spouse in ego's discussion network"
drop has_spouse_temp

* Has parent
gen has_parent_temp = rel_raw == 2 if rel_raw != .
egen has_parent = max(has_parent_temp), by(ego_id)
lab var has_parent "Whether own parents in ego's discussion network"
drop has_parent_temp

* Has child
gen has_child_temp = rel_raw == 4 if rel_raw != .
egen has_child = max(has_child_temp), by(ego_id)
lab var has_child "Whether child in ego's discussion network"
drop has_child_temp

* Has close friend
gen has_close_friend_temp = rel_raw == 20 if rel_raw != .
egen has_close_friend = max(has_close_friend_temp), by(ego_id)
lab var has_close_friend "Whether close friend in ego's discussion network"
drop has_close_friend_temp

* Has friend (close or ordinary)
gen has_friend_temp = (rel_raw == 20 | rel_raw == 21) if rel_raw != .
egen has_friend = max(has_friend_temp), by(ego_id)
lab var has_friend "Whether friend in ego's discussion network"
drop has_friend_temp

* Kin and Non-kin
recode rel (1=1)(2/5=0)(24=0), gen(kin_temp) // Other?
egen kin_percent = mean(kin_temp), by(ego_id)
lab var kin_percent "The proportion of kin tie"
drop kin_temp

** Gender
egen female_percent = mean(female), by(ego_id)
lab var female_percent "The proportion of female"

** Age
egen age_mean = mean(age), by(ego_id)
lab var age_mean "The mean of altes' age"

** Martial 
gen married_temp = marital == 2 if marital != .
egen married_percent = mean(married_temp), by(ego_id)
lab var married_percent "The proportion of married"
drop married_temp

** Ethnicity: pass

** Education
egen eduyear_mean = mean(eduyear), by(ego_id)
lab var eduyear_mean "The mean of alter's education year"

** Subjective Social Status
egen subjective_status_mean = mean(subjective_status), by(ego_id)
lab var subjective_status_mean "The mean of ego's subjective social status toward alter"

egen subjective_status_max = max(subjective_status), by(ego_id)
lab var subjective_status_max "The max of ego's subjective social status toward alter"


************** Heterogeneity (Diversity) **************
** Kin
gen kin_IQV = kin_percent * (1 - kin_percent) * 4

** Gender
gen female_IQV = female_percent * (1 - female_percent) * 4

** Martial
gen married_IQV = married_percent * (1 - married_percent) * 4

** Age
egen age_sd = sd(age), by(ego_id)
lab var age_sd "The sd of altes' age"
 
** Education
egen eduyear_sd = sd(eduyear), by(ego_id)
lab var eduyear_sd "The mean of alter's education year"

** Subjective Social Status
egen subjective_status_sd = sd(subjective_status), by(ego_id)
lab var subjective_status_sd "The sd of ego's subjective social status toward alter"

drop alter_id pernet_size tie_strength-eduyear
bysort ego_id: keep if _n==1
save "ego_level_statistics_stata.dta", replace


/* The following information needs to be calucaluted in R */
/* Go to Run "c_ego_level_statistics.R" 			      */

************** Ego-Alter Similarity **************

************** Density **************

************** Componenets and Fragmentation **************

************** Structrual Hole Measure **************

************** Ego Betweeness **************

************** Brokerage **************

************** Alter Centrality **************

log close
