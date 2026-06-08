# NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0

Statut : **DONE**

## Description

Ce lot implémente le modèle de données de base (`CinematicStagePoint`) sous la structure cinématique existante (`CinematicStageContext`), sa désérialisation/sérialisation JSON descendante rétrocompatible, les opérations pures d'édition associées et les 6 codes de diagnostics statiques correspondants.

Ce modèle prépare l'édition spatiale au sein de la preview du Cinematic Builder de manière découplée (sans affecter la structure `MapData` ni créer d'entités physiques de jeu superflues).

## Scope Réalisé

1. **Modèle de données (`map_core`) :**
   - Création de la classe immuable `CinematicStagePoint` avec les champs : `id` (String non vide), `label` (String non vide), `x` (`double`), `y` (`double`) et `description` (`String?` optionnel).
   - Intégration de `List<CinematicStagePoint> stagePoints` dans `CinematicStageContext`.
   - Rétrocompatibilité JSON : les anciens JSON n'ayant pas de clé `stagePoints` se désérialisent proprement avec une liste vide par défaut. L'ordre des points, les valeurs à virgule flottante (`double`) et les descriptions nulles sont préservés lors des cycles de sérialisation bidirectionnelle.
   - Les coordonnées `x` et `y` acceptent des valeurs non finies dans le constructeur et la désérialisation pour permettre aux diagnostics statiques de repérer les formats cassés au lieu de crasher le chargeur JSON principal.

2. **Opérations d'auteur pures (`map_core`) :**
   - Implémentation de `addCinematicStagePoint`, `updateCinematicStagePoint` et `removeCinematicStagePoint` dans `cinematic_authoring_operations.dart`.
   - Levée systématique d'exception `ArgumentError` lors des opérations d'auteur interactives en cas d'identifiant en doublon, vide ou de coordonnées non finies.

3. **Diagnostics statiques (`map_core`) :**
   - Intégration de 6 codes de validation sous `CinematicDiagnosticCode` :
     - `stagePointDuplicateId` (Error) : doublon d'identifiant de point dans le contexte.
     - `stagePointEmptyId` (Error) : identifiant vide.
     - `stagePointEmptyLabel` (Error) : label de point vide.
     - `stagePointInvalidCoordinate` (Error) : coordonnées non finies (NaN / Infinity).
     - `stagePointOutOfMap` (Error) : point positionné en dehors des dimensions de la carte (`mapWidth` / `mapHeight`), si ces dernières sont fournies.
     - `stagePointWithoutStageMap` (Warning) : points déclarés alors qu'aucun `mapId` n'est attaché à la cinématique.
   - Signature backward-compatible de `diagnoseCinematicAsset` via les arguments nommés optionnels `int? mapWidth` et `int? mapHeight`.

## Preuves et Validation

### Tests Automatisés
Tous les tests de la suite de `packages/map_core` passent à 100% au vert. Les tests spécifiques écrits pour ce lot couvrent :
- Rétrocompatibilité des anciens JSON et roundtrip JSON complet.
- Préservation de l'ordre et des valeurs `double` des coordonnées.
- Opérations pures de modification d'auteur et validations d'arguments associés.
- Diagnostics d'erreur sur doublons, valeurs hors limites, coordonnées infinies et absence de map de scène.

### Commandes exécutées
```bash
cd packages/map_core
dart test test/cinematic_asset_test.dart
dart test test/cinematic_authoring_operations_test.dart
dart test test/cinematic_diagnostics_test.dart
dart analyze
```

Résultats :
- **Tests :** 2450 tests unitaires passés avec succès.
- **Analyse :** 0 avertissements / 0 erreurs de compilation détectées.

## Limites

- Ce lot ne contient aucun composant UI ni interaction de drag-and-drop / clic sur le canvas de la preview.
- Il n'affecte pas l'exécution de la cinématique ou le playback dans le runtime / Flame.

## Prochain lot recommandé

`NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0`
