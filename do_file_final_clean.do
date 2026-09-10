* ================================================================
* PREPARATION DES DONNEES
* ================================================================

* Charge la base Banque mondiale
use "C:/Users/LENOVO/Desktop/LinkedIn/Poste 2/banque_mondial.dta", replace

*Verifie si c'est un id
isid pays annee

* Fusionne avec la base "bonheur"
merge 1:1 pays annee using "C:/Users/LENOVO/Desktop/LinkedIn/Poste 2/bonheur.dta"

* Verifie la qualite de la fusion
tab _merge

* Restreint l'echantillon a 2022 et inspecte la base
keep if annee <= 2022
describe
count
summarize

* Sauvegarde la base fusionnee et nettoyee
save "C:/Users/LENOVO/Desktop/LinkedIn/Poste 2/base_final.dta", replace


* ================================================================
* TEST DE TRANSFORMATION LOG (skewness avant/apres) - PIB, chomage, homicide
* ================================================================

* --- PIB : skewness avant/apres log ---
quietly summarize pib_par_habitant_ppa, detail
display r(skewness)
quietly gen log_pib = log(pib_par_habitant_ppa)
quietly summarize log_pib, detail
display r(skewness)

* --- Taux de chomage : skewness avant/apres log ---
quietly summarize taux_chomage, detail
display r(skewness)
quietly gen log_taux_chomage = log(taux_chomage)
quietly summarize log_taux_chomage, detail
display r(skewness)

* --- Taux d'homicide : skewness avant/apres log ---
quietly summarize taux_homicide, detail
display r(skewness)
quietly gen log_taux_homicide = log(taux_homicide)
quietly summarize log_taux_homicide, detail
display r(skewness)


* ================================================================
* DIAGNOSTIC DE MULTICOLINEARITE
* ================================================================

* Correlations entre les variables explicatives (versions log)
pwcorr log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide efficacite_gouvernementale controle_corruption, sig

* Regression complete + VIF pour verifier la colinearite globale
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption
estat vif

* Regression restreinte aux variables completes sur toutes les observations + VIF
regress bonheur log_pib esperance_vie depenses_sante taux_emploi log_taux_chomage utilisateurs_internet controle_corruption
estat vif

* Regression simple : PIB seul, pour comparaison avec les modeles enrichis
regress bonheur log_pib


* ================================================================
* MODELES OLS (COUPE TRANSVERSALE) - M0 A M4b
* ================================================================

*BLOC M0: Modele avec PIB uniquement
regress bonheur log_pib, vce(robust)

*BLOC M1: Modele economique et sanitaire de base
regress bonheur log_pib esperance_vie, vce(robust)

*BLOC M2: Capital humain et marche du travail
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage, vce(robust)

*BLOC M3: Conditions sociales et numeriques (+ VIF)
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide, vce(robust)
estat vif

* Reestime M2 sur le meme echantillon que M3 (isole effet echantillon vs nouvelles variables)
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage if e(sample), vce(robust)

*BLOC M4a: Modele complet (avec soutien_social) + VIF
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption soutien_social, vce(robust)
estat vif

*BLOC M4b: Modele de robustesse (sans soutien_social, evite la circularite avec la decomposition WHR du bonheur) + VIF
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption, vce(robust)
estat vif


* ================================================================
* ROBUSTESSE OLS : M1, M2, M3, M4b SUR LE MEME ECHANTILLON (celui de M4b)
* ================================================================

* Lance M4b pour capturer son echantillon
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption, vce(robust)

* Sauvegarde cet echantillon dans une variable reutilisable
gen echantillon_commun = e(sample)

* Reestime M1, M2, M3 sur ce meme echantillon fixe
regress bonheur log_pib esperance_vie if echantillon_commun==1, vce(robust)
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage if echantillon_commun==1, vce(robust)
regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide if echantillon_commun==1, vce(robust)


* ================================================================================
* MODELE PANEL - PREPARATION
* ================================================================================

*Encode pays et declare la base comme panel
encode pays, generate(id_pays)
xtset id_pays annee


* ================================================================
* MODELES EN PANEL - EFFETS FIXES PAYS - M0 A M4b
* ================================================================

* PANEL M0 : PIB seul
xtreg bonheur log_pib, fe vce(robust)

* PANEL M1 : + esperance de vie
xtreg bonheur log_pib esperance_vie, fe vce(robust)

* PANEL M2 : + education, sante, emploi, chomage
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage, fe vce(robust)

* PANEL M3 : + internet, gini, homicide
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide, fe vce(robust)

* Identifie le(s) pays avec une seule observation dans l'echantillon M3 (singletons)
gen byte in_m3 = e(sample)
bysort id_pays: egen n_obs_m3 = total(in_m3)
list pays annee if in_m3==1 & n_obs_m3==1
drop in_m3 n_obs_m3

* Verification de robustesse : reestime M3 en excluant les pays singletons
preserve
gen byte in_m3 = e(sample)
bysort id_pays: egen n_obs_m3 = total(in_m3)
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide if n_obs_m3>1, fe vce(robust)
restore

* PANEL M4a : modele complet (avec soutien_social)
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption soutien_social, fe vce(robust)

* Verifie les singletons dans l'echantillon M4a
gen byte in_m4a = e(sample)
bysort id_pays: egen n_obs_m4a = total(in_m4a)
list pays annee if in_m4a==1 & n_obs_m4a==1
drop in_m4a n_obs_m4a

* PANEL M4b : + controle_corruption, sans soutien_social
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption, fe vce(robust)

* Verifie les singletons dans l'echantillon M4b et sauvegarde cet echantillon pour la robustesse FE
gen byte in_m4b = e(sample)
bysort id_pays: egen n_obs_m4b = total(in_m4b)
list pays annee if in_m4b==1 & n_obs_m4b==1
gen echantillon_commun_fe = in_m4b
drop in_m4b n_obs_m4b


* ================================================================
* ROBUSTESSE FE : M1, M2, M3 SUR L'ECHANTILLON FIXE DE M4b
* ================================================================

xtreg bonheur log_pib esperance_vie if echantillon_commun_fe==1, fe vce(robust)
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage if echantillon_commun_fe==1, fe vce(robust)
xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide if echantillon_commun_fe==1, fe vce(robust)


* ================================================================
* TABLEAU FINAL : COEFFICIENT log_pib, OLS vs FE (M0 A M4b)
* ================================================================

* Installe le package necessaire a la construction du tableau (une seule fois, necessite internet)
ssc install estout, replace

* Reinitialise le stockage des resultats d'estimation
eststo clear

* --- OLS (entre pays) : stocke les 5 modeles pour le tableau ---
eststo M0_ols: regress bonheur log_pib, vce(robust)
eststo M1_ols: regress bonheur log_pib esperance_vie, vce(robust)
eststo M2_ols: regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage, vce(robust)
eststo M3_ols: regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide, vce(robust)
eststo M4b_ols: regress bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption, vce(robust)

* --- FE (dans le temps) : stocke les 5 modeles pour le tableau ---
eststo M0_fe: xtreg bonheur log_pib, fe vce(robust)
eststo M1_fe: xtreg bonheur log_pib esperance_vie, fe vce(robust)
eststo M2_fe: xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage, fe vce(robust)
eststo M3_fe: xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide, fe vce(robust)
eststo M4b_fe: xtreg bonheur log_pib esperance_vie depenses_education depenses_sante taux_emploi log_taux_chomage utilisateurs_internet indice_gini log_taux_homicide controle_corruption, fe vce(robust)

* Construit le tableau final : coefficient log_pib, 10 modeles cote a cote (OLS vs FE)
esttab M0_ols M1_ols M2_ols M3_ols M4b_ols M0_fe M1_fe M2_fe M3_fe M4b_fe, ///
    keep(log_pib) ///
    mtitles("M0" "M1" "M2" "M3" "M4b" "M0" "M1" "M2" "M3" "M4b") ///
    title("Coefficient log_pib : OLS (entre pays) vs FE (dans le temps)") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Observations" "R2"))
