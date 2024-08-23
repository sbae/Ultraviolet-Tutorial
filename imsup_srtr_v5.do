
** This do-file transforms the SRTR immunosuppression dataset so that it can be linked to tx_ki dataset using trr_id.

/** v5 update
- separated MMF/MPA
- added bela
- added generoc sirolimus to mtor
- removed ALG from nratg
*/

/* Classification of the drugs:
1. Induction: OKT3, thymoglobulin (rabbit only), non-rabbit anti-thymocyte glubline (ALG, Atgam, NRATG/NRATS), Daclizumab, Basiliximab, Alemtuzumab, Rituximab.
2. Maintanence
	1) Steroids (Istedoid)
	2) CNI (Icni): Cyclosporin(including Neoral), Tacrolimus
	3) Anti-metabolites (Iantimeta): MMF/MPA, mTOR(Sirolimus and Everolimus), Azathioprine  
3. Everything else is dumped. 	  */

local ver="2405"
global srtrdir "/gpfs/data/massielab/data/srtr/srtr2405/saf2/stata"
	
set more off
use $srtrdir/immuno.dta, clear
	
// Generate indicators
gen Iokt3=inlist(rec_drug_cd, 16)
gen Ithymo=inlist(rec_drug_cd, 41)
gen Inratg=inlist(rec_drug_cd, 14, 15)
gen Idaclizumab=inlist(rec_drug_cd, 42)
gen Ibasiliximab=inlist(rec_drug_cd, 43)
gen Irituximab=inlist(rec_drug_cd, 52)
gen Ialemtuzumab=inlist(rec_drug_cd,50)
gen Isteroid=inlist(rec_drug_cd,1,2,49)
gen Icyclosporin=inlist(rec_drug_cd,3,4,-2,44,46,48)
gen Itacro=inlist(rec_drug_cd,5,53,54,59)
gen Immf=inlist(rec_drug_cd,9,55)
gen Impa=inlist(rec_drug_cd,47,57)
gen Imtor=inlist(rec_drug_cd,6,45,58)
gen Iaza=inlist(rec_drug_cd,8)
gen Ibela=inlist(rec_drug_cd, 56)

gen Iinduction=(Iokt3+ Ithymo+ Inratg+Idaclizumab+ Ibasiliximab+ Irituximab+ Ialemtuzumab)>0
gen Icni=(Icyclosporin+Itacro)>0
gen Iantimeta=(Immf+Impa+Imtor+Iaza)>0
gen Imyco=(Immf+Impa)>0
gen Iil2ra=(Idaclizumab+Ibasiliximab)>0

// Create a list of trr_ids that has any information on this dataset
preserve
keep trr_id
duplicates drop
save "imsup_all_`ver'", replace
restore

** But IS data for the most recent cohort is NOT comprehensive. Consider censoring everyone in the last year or something.

// See if they make clinical sense
drop if rec_drug_induction + rec_drug_maint + rec_drug_anti_rej ==0
drop if Iinduction & (rec_drug_induction + rec_drug_anti_rej) == 0

// Export
preserve
collapse (max) I* if rec_drug_induction, by(trr_id)
tempfile imsup_ind
save `imsup_ind', replace
restore

preserve
collapse (max) I* if rec_drug_maint, by(trr_id)
tempfile imsup_maint
save `imsup_maint', replace
restore

preserve
collapse (max) I* if rec_drug_anti_rej, by(trr_id)
tempfile imsup_anti_rej
save `imsup_anti_rej', replace
restore

*** Also get the number of days for induction
preserve
keep if inlist(rec_drug_cd,16,-1,14,41,15,42,43,52,50)
keep if rec_drug_induction
replace rec_drug_cd=100 if rec_drug_cd==-1

* trr_id and rec_drug_cd should be unique. But there seems to be a data entry error?
bys trr_id rec_drug_cd: gen N=_N
list if N!=1
bys trr_id rec_drug_cd: keep if _n==1

keep trr_id rec_drug_cd rec_drug_days
reshape wide rec_drug_days, i(trr_id) j(rec_drug_cd)
mvencode _all, mv(0) override

gen days_atg=rec_drug_days41
gen days_nratg=rec_drug_days100+rec_drug_days14+rec_drug_days15
gen days_il2=rec_drug_days42+rec_drug_days43
gen days_alm=rec_drug_days50
gen days_ritux=rec_drug_days52
gen days_okt3=rec_drug_days16

drop rec_drug_days*
compress
tempfile imsup_days
save `imsup_days', replace
restore


foreach c in ind maint anti_rej {
	use `imsup_`c'', clear
	foreach v of varlist I* {
		rename `v' `v'_`c'
	}
	save `imsup_`c'', replace
}

// Lump all of them up into "imsup_all_`ver'" dataset
use "imsup_all_`ver'", clear
merge 1:1 trr_id using `imsup_ind', nogen
merge 1:1 trr_id using `imsup_maint', nogen
merge 1:1 trr_id using `imsup_anti_rej', nogen
merge 1:1 trr_id using `imsup_days', nogen

mvencode _all, mv(0) override
save "imsup_all_`ver'", replace

// If _ever indicators are needed:  
/*
foreach drugname in Iokt3 Ithymo Inratg Idaclizumab Ibasiliximab Irituximab Ialemtuzumab Isteroid Icyclosporin Itacro Immf Imtor Iaza Iinduction Icni Iantimeta {
	egen `drugname'_ever=rowmax(`drugname'*)
}
save "imsup_all_`ver'", replace
*/
