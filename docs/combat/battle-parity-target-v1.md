# Battle Parity Target V1

Date : 2026-07-26
Profil : `pokemap-mainline-hybrid-v1`
Contrat machine :
`packages/map_battle/lib/src/data/battle_parity_target.dart`

## Décision

PokeMap vise les règles modernes de la neuvième génération pour les mécaniques
résolues au sein du moteur de combat : dégâts, égalités de vitesse, statuts
majeurs et critiques.

L'expérience et la capture conservent deux règles PokeMap V1 documentées.
Elles ne sont pas présentées comme une parité exacte avec une génération
mainline :

- EXP sauvage : `level × baseExperience / 7` ;
- EXP trainer : même base avec multiplicateur `1,5` ;
- capture : formule entière HP/catch-rate/statut, une Poké Ball canonique et
  consommation RNG déterministe.

Cette cible hybride évite deux erreurs :

1. prétendre que toutes les mécaniques actuelles appartiennent à une génération
   unique alors que l'EXP et la capture sont volontairement bornées ;
2. laisser chaque bridge ou UI choisir implicitement sa propre interprétation.

## Axes

| Axe | Règle cible | État au 2026-07-26 | Écart restant |
|---|---|---|---|
| dégâts | `mainline-gen9-damage` | `partial` | consolider la preuve bridge/runtime et les deux moteurs historiques |
| égalités de vitesse | `mainline-gen9-seeded-random` | `gap` | remplacer l'ordre déterministe par banque par un tirage seedé |
| statuts majeurs | `mainline-gen9-status-core` | `partial` | fermer la matrice immunités/lifecycle exposée au joueur |
| critiques | `mainline-gen9-critical` | `aligned` | maintenir la preuve 1/16, 1/8, 1/2, garanti et multiplicateur 1,5 |
| expérience | `pokemap-simple-exp-v1` | `intentionalVariant` | aucune revendication Gen 9 ; garder la règle versionnée |
| capture | `pokemap-capture-mvp-v1` | `intentionalVariant` | familles de Balls différées ; garder la règle versionnée |

## Sémantique des compteurs PSDK

Les compteurs `attacks`, `methods` et `effects` mesurent la convergence du
moteur PSDK :

- présence d'une méthode connue ;
- niveau de portage de son comportement ;
- inventaire des effets et hooks couverts.

Ils ne prouvent pas à eux seuls :

- que le bridge runtime transporte toutes les données nécessaires ;
- que le joueur peut sélectionner et résoudre la capacité ;
- que le write-back gameplay est atomique ;
- que l'Editor expose un réglage réellement consommé ;
- qu'un parcours Golden E2E passe.

Toute promotion joueur exige donc trois preuves compagnes :

```text
runtimeBridge
playerSurface
goldenE2E
```

Le statut PSDK `partiel` signifie « exécutable mais non strictement paritaire ».
Il ne peut jamais être transformé silencieusement en support produit complet.

## Consommateurs

| Consommateur | Usage |
|---|---|
| `PsdkFightParityAudit.toJson()` | cible lisible par machine et future capability gate |
| `PsdkFightParityAudit.toMarkdown()` | cible et limitations visibles dans les rapports |
| `RM-021` | difficulté trainer et policies IA alignées |
| `RM-022` | décisions et égalités de vitesse canoniques |
| `RM-026` | gate MVP combinant moteur, bridge, surface et goldens |
| `RM-053` | gate complète incluant objets tenus, stats et Struggle |

## Non-objectifs V1

- déclarer tous les mouvements PSDK strictement paritaires ;
- changer la formule d'EXP ou de capture dans RM-020 ;
- corriger l'égalité de vitesse dans le lot de décision ;
- supprimer immédiatement le moteur legacy ;
- ouvrir doubles, targeting riche ou toutes les familles de Balls.
