
* Start logging
cd "$log"
log using "b_prepareData", text replace

cd "$rawdata"
use "tscs2017q2.dta", clear

/*
describe
codebook, compact
*/

**#**************** Ego data ******************

cd "$workdata"
save ego_data.dta, replace

** Gender
recode a1 (2=1)(1=0), gen(female)

** Date of Birth
recode a2y (96/99=.), gen(byear)
replace byear = byear + 1911
recode a2m (96/99=.), gen(bmonth)
gen bdate = mdy(bmonth, 15, byear)
format bdate %td

gen syear = 2017
gen sdate = date(string(sdt1, "%8.0f"), "YMD")
format sdate %td

** Age
gen age = age(bdate, sdate) 
gen age_conti = age_frac(bdate, sdate)
replace age = a2r if age == . & a2r < 996
replace age_conti = a2r if age_conti == . & a2r < 996

gen age2 = age_conti^2

recode age (1/30=1)(31/40=2)(41/50=3)(51/60=4)(61/70=5)(71/120=6)(94/99=.), gen(agecat)
lab define agecat 1"30 years old and below" 2"31 ~ 40 years old" 3"41 ~ 50 years old" 4"51 ~ 60 years old" 5"61 ~ 70 years old" 6"71 and above"
lab value agecat agecat

** Education
recode a13 (1 2 3=1)(4 5=2)(6/9=3)(10/17=4)(18 19=5)(20/21=6)(22 96/99=.), gen(educat)
label define educat 1"Elementary or less" 2"Junior high" 3"High school" 4"Junior college" 5"University" 6"Graduate school"
lab value educat educat

recode a13 (1=0)(2=2)(3=6)(4 5=9)(6/9=12)(10/17=14)(18 19=16)(20=18)(21=23)(22 96/99=.), gen(eduyear)
replace eduyear = a14 if eduyear == . & a14 < 96

recode a14 (96/99=.), gen(eduyear_self) 
replace eduyear_self = eduyear if eduyear_self == . 
lab var eduyear_self "self-reported education year"

replace educat = 6 if eduyear_self >= 18
replace educat = 3 if eduyear_self == 12
replace educat = 1 if eduyear_self <= 6

** Urbab or Rural
recode a5 (1=1)(2 3=2)(4 5=3)(96/99=.), gen(residence_type)
lab define residence_type 1"Metropolitan" 2"Suburban or town" 3"Rural or farm"
lab value residence_type residence_type

recode residence_type (1=1)(2 3=0), gen(urban)

** Region 

** Religion
recode a11 (1=1)(2 4=2)(3=3)(6=4)(7=5)(8=0)(5 9 96/99=.), gen(religion)
label define religion 0"No religion" 1"Buddism" 2 "Daoism" 3"Folk" 4"Catholic" 5"Christian" 
label values religion religion
replace religion = 3 if id == 239803 | id == 304814
replace religion = 5 if id == 831807

recode a12 (7 8=0)(5 6=1)(3 4=2)(1 2=3), gen(religion_freq)
lab define religion_freq 0"Never or almost never" 1"Rarely (once or a few times a year)" 2"Occasionally (once or a few times a month)" 3"Regularly (at least once a week)"
lab value religion_freq religion_freq

** Ethincity
recode a10 (1=1)(2=2)(4=3)(3 5=4)(96/99=.), gen(ethnic)
label define ethnic 1"Minan"  2"Hakka" 3"Mainlander" 4"Aboriginal or other"
label values ethnic ethnic
replace ethnic = 1 if ka10 == "台灣人" | ka10 == "台灣人" | id == 100802  | id == 320705 | id ==  320735 | id == 320818 | id == 813810
replace ethnic = 3 if id == 974705 | id == 239803

** Marital
recode a15 (1=1)(2 3 4=2)(5 6 7=3)(8 96/99=.), gen(marital)
label define marital 1"Single" 2"Married or cohabiting" 3"Separated, divorced, or widowed" 
label value marital marital

** Number of People Living Together 
recode f2a (0 96/99=.), gen(living_member_size)
gen living_alone = living_member_size == 1 if living_member_size != .
recode f2c (96=0)(97/99=.), gen(living_preschooler_num)
recode f2b (96=0)(97/99=.), gen(living_child_num)

** Employment
recode f7 (6 7=1)(3 4 5 8 9 10=2)(1 2=3)(96/99=.), gen(employment)
replace employment = 4 if f3 == 3 
replace employment = 5 if f3 == 6 
replace employment = 6 if f3 == 7 | f3 == 8 | f3 == 13 | f3 == 14
replace employment = 7 if f3 == 10 
replace employment = 8 if f3 == 11 
replace employment = 9 if f3 == 12 | f3 == 15 // Sickness Sickness leave, or Unpaid Parental leave

label define employment 1"Government" 2"Private business" 3"Employer or self-employed" 4"Part-timer" 5"Unemployed" 6"Student/military" 7"Retire" 8"Homemaker" 9"Sickness/unpaid or parental leave"
label value employment employment

replace employment = 2 if employment == . & f3 == 1
replace employment = 4 if employment == . & f3 == 2
replace employment = 6 if id == 805821

recode employment (3 4=3)(1 2 4=4)(5/9=1), gen(employment_short)
replace employment_short = 2 if employment_short == 3 & f7 == 1
label define employment_short 1"Unemployed"  2"Employer" 3"Self-employed or Part-timer" 4"Employed"
label value employment_short employment_short

gen employed = employment <= 4 if employment != .

** Income
recode f16 (1=0)(2=.5)(3=1.5)(4=2.5)(5=3.5)(6=4.5)(7=5.5)(8=6.5)(9=7.5)(10=8.5)(11=9.5)(12=10.5)(13=11.5)(14=12.5)(15=13.5)(16=14.5)(17=15.5)(18=16.5)(19=17.5)(20=18.5)(21=19.5)(22=25)(23=35)(96/99=.), gen(rincome)
lab var rincome "Personal monthly income (unit: ten housand NTD)"

gen lnrincome = log(rincome+1)

recode f17 (1=0)(2=.5)(3=1.5)(4=2.5)(5=3.5)(6=4.5)(7=5.5)(8=6.5)(9=7.5)(10=8.5)(11=9.5)(12=10.5)(13=11.5)(14=12.5)(15=13.5)(16=14.5)(17=15.5)(18=16.5)(19=17.5)(20=18.5)(21=19.5)(22=25)(23=35)(24=45)(25=75)(26=125)(96/99=.), gen(hincome)
lab var hincome "Household monthly income (unit: ten housand NTD)" // 452 respondents unkown! Too may missing values!

** Subjective Social Status
recode a17n (97/99=.), gen(subjective_status)

** Happiness
recode b27n1 (1=4)(2=3)(3=2)(4=1)(96/99=.), gen(happiness)
label define happiness 1"Very unhappy" 2"Somewhat unhappy" 3"Somewhat happy" 4"Very happy"
label value happiness happiness

gen happy = happiness >= 3 if happiness != .

** Health
recode b27 (1=5)(2=1)(3=3)(4=2)(5=1), gen(healthness)
label define healthness 1"Poor" 2"Fair" 3"Good" 4"Very good" 5"Excellent"
label value healthness healthness

recode b28a (94/99=.), gen(depress1)
recode b28b (94/99=.), gen(depress2)
recode b28c (94/99=.), gen(depress3)
alpha depress*
egen depression = rowmean(depress*)

** Loneliness
/*  In the past four weeks, how often have you felt...
A. lack companionship?
B. left out?
C. excluded?
D. that your family and friends are doing better than you?
*/
recode b9a (94/99=.), gen(lack_companionship)
recode b9b (94/99=.), gen(lonely)
recode b9c (94/99=.), gen(excluded)
recode b9d (94/99=.), gen(less_than_others)
tabm lack_companionship lonely excluded less_than_others
alpha lack_companionship lonely excluded, std item detail
egen loneliness = rowmean(lack_companionship lonely excluded)
lab var loneliness "3 items loneliness scale"

** Daily Contact
recode b19 (0 1=1)(94/99=.), gen(contact6)
lab define contact6 1"0~4" 2"5~9" 3"10~19" 4"20~49" 5"50~99" 6"100 and above"
lab value contact6 contact6

recode b19 (0 1 2=1)(3=2)(4=3)(5 6=4)(94/99=.), gen(contact4)
lab define contact4 1"below 10" 2"10~19" 3"20~49" 4"50 and above"
lab value contact4 contact4

** Internet (f22-f26)
gen online_time = f22h + (f22m / 60)
replace online_time = . if f22h > 90 | f22m > 90
replace online_time = 0 if f22h == 96 & f22m == 96 // unable to use the Internet or computers
lab var online_time "how much time do you spend online per day? (unit: hour)"

** Network Size
recode c1 (94/99=.), gen(pernet_size)
recode d1 (94/99=.), gen(emonet_size)

** Network Pressure (b14-b16)
recode b14 (94/99=.), gen(family_stress)
recode b15 (94/99=.), gen(family_demand)
recode b16 (94/99=.), gen(others_mood)
recode b16n1 (1=5)(2=4)(3=3)(4=2)(5=1)(94/99=.), gen(relation_burden)
tabm family_stress family_demand others_mood relation_burden, m
alpha family_stress family_demand others_mood relation_burden, std item detail
egen relation_pressure = rowmean(family_stress family_demand others_mood relation_burden)
egen network_pressure = rowmean(others_mood relation_burden)

** Contact Frequency (with thec closest friends)
recode b25 (90=0)(91=8)(1=9)(2=7)(3=6)(4=5)(5=4)(6=3)(7=2)(8=1)(96/98=.), gen(friend_contact_freq)
lab define friend_contact_freq 0"I have no close friends" 1"Never contact" 2"Once a year or less" 3"Several times a year" 4"Once a month" 5"Two to three times a month" 6"Once a week" 7"Several times a week" 8"The closest friend I regularly contact lives with me" 9"Every day" 
lab value friend_contact_freq friend_contact_freq

** Personality
* Independence
foreach i in b7a b7b b7c b7d b7e b8a b8b b8c b8d b8e {
	gen `i'_no = `i' == 7 if `i' < 90 
}
egen independence = rowmean(b7a_no-b8e_no)
drop b7*_no b8*_no

* Socializing Frequency
recode b17 (1 2=4)(3 4=3)(5 6=2)(7 8=1)(94/99=.), gen(socializing_freq)
lab define socializing_freq 1"Rare (Once a year or less, or never)" 2"Infrequent (once a month or several times a year)" 3"Frequent (once a week or two to three times a month)" 4"Very frequent (overy day or several times a week)"
lab value socializing_freq socializing_freq

* Outgoing
recode f18a (94/99=.), gen(talkative)
recode f18b (1=5)(2=4)(3=3)(4=2)(5=1)(94/99=.), gen(extravert)
tabm talkative extravert
egen outgoing = rowmean(talkative extravert)
lab var outgoing "Talkative and extravert"

* Trust
recode b11 (1=4)(2=3)(3=2)(4=1)(94/99=.), gen(trust)
 
tab socializing_freq outgoing, chi
tab trust outgoing, chi

// des, simple

rename id ego_id

/********************/
// Run only for Network size >= 1
preserve
drop if pernet_size == 0
drop if pernet_size == 0
keep ego_id region female-trust wsel
save ego_data.dta, replace
restore
/********************/

/********************/
// Run for All
preserve
keep ego_id region female-trust wsel
save ego_data_full.dta, replace
restore
/********************/

mdesc

**#**************** Alter data ******************

///// Personal Social Network /////

** Relationship with ego
#delimit ;
lab define alter_rel_raw
1"Spouse"
2"Own parent"
3"Parent-in-law"
4"Children"
5"Sibling"
6"Daughter-in-law"
7"Son-in-law" 
8"Other relative"
9"Former neighbor"
10"Current neighbor"
11"Classmate"
12"Teacher"
13"Student"
14"Former colleague"
15"Current colleague"
16"Supervisor"
17"Subordinate"
18"Fellow members of social group"
19"Fellow members of religious group"
20"Close friend"
21"Ordinary friend"
22"Customer"
23"Fellow villager"
24"Other" ;
#delimit cr

lab define alter_rel 1"Family members" 2"Friends" 3"Educational connections" 4"Professional connections" 5"Social-religious group and neighbors"

#delimit ;
lab define alter_rel2
1"Spouse"
2"Own parent"
3"Children"
4"Sibling"
5"In-laws"
6"Other relative"
7"Friends" 
8"Educational connections" 
9"Professional connections" 
10"Social-religious group and neighbors" ;
#delimit cr

forvalues i = 1(1)5 {
	recode c2`i'a (94/99=.), gen(alter`i'_rel_raw)
	lab value alter`i'_rel_raw alter_rel_raw
	
	recode c2`i'a (1 2 3 4 5 6 7 8=1)(20 21=2)(11 12 13=3)(14 15 16 17 22=4)(9 10 18 19 23=5)(94/99=.), gen(alter`i'_rel)
	lab value alter`i'_rel alter_rel
	
	recode c2`i'a (1=1)(2=2)(4=3)(5=4)(3 6 7=5)(8=6)(20 21=7)(11 12 13=8)(14 15 16 17 22=9)(9 10 18 19 23=10)(94/99=.), gen(alter`i'_rel2)
	lab value alter`i'_rel2 alter_rel2
}

** How did they meet
#delimit ;
lab define alter_meet_raw
1"Blood relatives"
2"In-laws"
3"Neighbors"
4"Elementary school classmates"
5"Junior high/middle school classmates"
6"High school/vocational school classmates"
7"College/university classmates"
8"Teachers and students relationship"
9"Workplace"
10"Club members"
11"Religious groups"
12"Introduced by others"
13"Participating in common activities"
14"Other" ;
#delimit cr

lab define alter_meet 1"Family" 2"School" 3"Workplace" 4"Social/Religious group and Neighbors" 5"Introduced by others"

forvalues i = 1(1)5 {
	recode c2`i'b (94/99=.), gen(alter`i'_meet_raw)
	lab value alter`i'_meet_raw alter_meet_raw
	
	recode c2`i'b (1 2=1)(4/8=2)(9=3)(3 10 11 13=4)(12=5)(94/99=.), gen(alter`i'_meet)
	lab value alter`i'_meet alter_meet
}

** Gender
forvalues i = 1(1)5 {
	recode c2`i'c (2=1)(1=0)(94/99=.), gen(alter`i'_female)
}

** Age
forvalues i = 1(1)5 {
	recode c2`i'd (94/99=.), gen(alter`i'_age)
	
	recode c2`i'd (1/30=1)(31/40=2)(41/50=3)(51/60=4)(61/70=5)(71/95=6)(94/99=.), gen(alter`i'_agecat)
	lab value alter`i'_agecat agecat
}

** Marital
forvalues i = 1(1)5 {
	recode c2`i'e (1=1)(2=2)(3 4=3)(5 94/99=.), gen(alter`i'_marital)
	label value alter`i'_marital marital
}

** Ethincity
forvalues i = 1(1)5 {
	recode c2`i'f (1=1)(2=2)(3=3)(4=4)(5 94/99=.), gen(alter`i'_ethnicity)
	lab value alter`i'_ethnicity ethnic 
}

** Education
forvalues i = 1(1)5 {
	recode c2`i'g (1=1)(2=2)(3=3)(4=4)(5=5)(6=6)(7 94/99=.), gen(alter`i'_educat)
	lab value alter`i'_educat educat
}

** Subjective Social Status
forvalues i = 1(1)5 {
	recode c2`i'hn (94/99=.), gen(alter`i'_subjective_status)
}

** Tie Strength: c2@i
lab define tie_strength 1"Neutral and below (& Refuse to answer)" 2"Close" 3"Very close"

forvalues i = 1(1)5 {
	recode c2`i'i (3 4 5 98=1)(2=2)(1=3)(94/97 99=.), gen(alter`i'_tie_strength)	
	lab value alter`i'_tie_strength tie_strength
}


///// Reshape to Long Format /////

preserve
keep ego_id alter* pernet_size
reshape long alter@_rel_raw alter@_rel alter@_rel2 alter@_meet_raw alter@_meet alter@_female alter@_age alter@_agecat alter@_marital alter@_ethnicity alter@_educat alter@_subjective_status alter@_tie_strength, i(ego_id) j(alter_id)

drop if alter_id > pernet_size

replace alter_id = ego_id*10 + alter_id
order alter_tie_strength, after(pernet_size)

rename alter_* *
rename id alter_id

recode educat (1=6)(2=9)(3=12)(4=14)(5=16)(6=20), gen(eduyear)

egen degree = count(alter_id), by(ego_id) // Max = 5
order degree, after(pernet_size)

save alter_data.dta, replace
restore


**#**************** Alter-Alter data ******************
local alter_alter "c312 c313 c314 c315 c323 c324 c325 c334 c335 c345"

lab define alter_alter_tie 0"(Refuse to answer)" 1"weak" 2"strong"
foreach x in `alter_alter'{
	recode `x' (98=0)(1=2)(2=1)(3 94/97 99=.)
	lab value `x' alter_alter_tie
}

preserve
keep ego `alter_alter'

reshape long c3, i(ego_id) j(alter_id)

gen from = ego_id*10 + floor(alter_id/10)
gen to = ego_id*10 + mod(alter_id, 10)

rename c3 weight
order weight, last
drop if weight == .
drop alter_id

save aatie.dta, replace
restore

log close
