# Shadow-53 — Auto Shadow Policy Reconciliation / Selbrume Audit Plan

## Objectif

Réconcilier la politique d’ombre automatique entre `map_core` et les tests éditeur, puis auditer pourquoi le rendu Selbrume reste incohérent côté projet réel.

Le symptôme visible n’est plus principalement une absence de pipeline : le runtime et l’éditeur savent consommer les footprints, les projections et les réglages globaux. Le problème restant observé est que les règles automatiques, les tests wrappers éditeur et les données persistées de Selbrume peuvent encore diverger.

## Hypothèse vérifiée avant correction

`map_core` contient déjà une politique plus sobre pour les familles automatiques :

- `tallThin` : empreinte plus fine, opacité plus basse ;
- `buildingLarge` : footprint beaucoup moins haut et moins large ;
- `wideLow` : footprint réduit.

Les tests éditeur `element_auto_shadow_suggestion_test.dart` et `element_auto_shadow_backfill_test.dart` attendent encore d’anciennes valeurs larges. Cela masque la vraie prochaine étape : appliquer ou auditer ces configs sur les données Selbrume persistées.

## Périmètre Shadow-53

### Autorisé

- Mettre à jour les tests éditeur d’auto-shadow pour les aligner sur la source de vérité `map_core`.
- Ajouter une garde de parité entre le wrapper éditeur et l’opération core de backfill.
- Auditer le projet Selbrume externe en lecture seule.
- Créer un rapport Shadow-53.

### Interdit

- Modifier le renderer.
- Modifier Flame ou `map_runtime`.
- Modifier la preview canvas.
- Modifier les modèles persistants ou codecs JSON.
- Modifier `/Users/karim/Desktop/selbrume/project.json`.
- Commit/push sans demande explicite.

## Étapes

1. Reproduire les tests rouges éditeur ciblés.
2. Aligner les attentes obsolètes sur la politique core actuelle.
3. Ajouter un test de parité backfill wrapper éditeur vs core.
4. Auditer Selbrume en lecture seule pour compter les shadows persistées et les signatures legacy.
5. Lancer les tests ciblés éditeur et core.
6. Créer un rapport factuel distinguant Shadow-52 préexistant, Shadow-53 et données Selbrume non modifiées.

## Critère de sortie

- Les tests d’auto-shadow éditeur ciblés passent.
- Le test `test/application/shadow` éditeur ne bloque plus sur les attentes obsolètes.
- Le rapport explique clairement pourquoi les captures peuvent encore rester mauvaises tant que les données Selbrume persistées n’ont pas été réconciliées ou backfillées.
