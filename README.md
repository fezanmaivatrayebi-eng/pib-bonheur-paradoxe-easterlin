# Le PIB rend-il heureux ? Une analyse en panel du paradoxe d'Easterlin

## Contexte
Cette étude cherche à répondre à une question simple : le revenu d'un pays
est-il associé au bonheur de ses habitants ? Et la réponse est-elle la même
selon qu'on compare des pays entre eux à un instant donné, ou qu'on suit un
même pays au fil du temps.

## Données
Base panel pays-année combinant des indicateurs de développement (Banque
mondiale) et un indice de bonheur (Gallup World Poll), sur 23 pays entre
2014 et 2022.

## Méthodologie
- Transformation logarithmique des variables les plus asymétriques (PIB,
  chômage, taux d'homicide), avec vérification de l'amélioration obtenue
- Diagnostic de multicolinéarité (corrélations par paires et VIF)
- Deux approches complémentaires : comparaison entre pays (OLS, 5 modèles
  emboîtés) et évolution dans le temps (panel à effets fixes)
- Tests de robustesse sur échantillon fixe et exclusion des singletons

## Résultats clés
- Le PIB par habitant explique fortement les différences de bonheur entre
  pays, mais n'explique pas l'évolution du bonheur d'un même pays dans le
  temps (paradoxe d'Easterlin)
- Le contrôle de la corruption est le seul facteur qui reste significatif à
  la fois entre pays et dans le temps
- Les résultats tiennent après plusieurs vérifications de robustesse

## Outils utilisés
Stata (do-file), régressions OLS et panel à effets fixes

## Fichiers
- `faire_fichier_nettoyage_final.do` : script de nettoyage et de préparation
  des données
- `rapport_bonheur_pib.pdf` : note méthodologique complète et résultats
- `PIB_et_bonheur_paradoxe_easterlin_final.pptx` : présentation de synthèse
