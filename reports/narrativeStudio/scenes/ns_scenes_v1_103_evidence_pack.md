# NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0 — Evidence Pack

## 1. Audit Initial

Avant toute implémentation ou reprise du code :
- **Fichiers identifiés** :
  - `packages/map_core/lib/src/models/cinematic_asset.dart`
  - `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
  - `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
  - `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
  - `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
  - `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- **Contrats existants** : Cinematic Stage Points ont été introduits dans V1-101 et les interactions d'édition visuelle en V1-102.
- **Risques identifiés** :
  - Fuite de données / effacement des Stage Points lors de la mise à jour d'autres propriétés d'un acteur (corrigé en propageant explicitement `stagePoints` dans `cinematic_authoring_operations.dart`).
  - Diagnostic erroné si des points de scène sont supprimés mais toujours référencés.
  - Décalages géométriques dans le positionnement statique de la preview.

## 2. Git Status Initial

```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/lib/src/models/cinematic_asset.dart
 M packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
 M packages/map_core/test/cinematic_actor_display_preview_model_test.dart
 M packages/map_core/test/cinematic_asset_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.png
```

## 3. Verdict des Passes / Sub-agents

- **Sub-agent Audit / Architecture** : Validation du modèle purement découplé. Le placement initial de l'acteur fait référence à `stagePointId` de type `String` plutôt que de copier les coordonnées x et y, respectant la normalisation et la robustesse en cas de modification ultérieure des coordonnées du point de scène.
- **Sub-agent Implémentation** : Implémentation du picker radio dans la barre d'outils et popup overlay (`_StagePointDropdownPopup`). Correction de la perte d'état en propageant `stagePoints: context.stagePoints` à travers toutes les fonctions mutantes d'acteurs de `cinematic_authoring_operations.dart`. Ajout du bouton de fermeture de sélection dans l'inspecteur.
- **Sub-agent Tests** : Ajout de 6 tests ciblés robustes couvrant les diagnostics statiques, le décodage JSON et la résolution de position statique. Ajout de tests de widget simulant la sous-sélection de point de scène dans `cinematic_builder_workspace_test.dart`.
- **Sub-agent Build / Validation** : Vérification du build et de l'analyse statique. La suite de test ciblée `cinematic_builder_workspace_test.dart` passe à 100% au vert.
- **Sub-agent Critique finale** : Aucun code orphelin ou import non utilisé n'est introduit. Le code est abondamment commenté, en particulier sur la préservation de la rétrocompatibilité JSON, la propagation des points de scène et la possibilité de fermer l'inspecteur d'élément pour revenir à l'inspecteur global.

## 4. Fichiers Modifiés & Créés

### Créés
- [ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.md) : Rapport final de clôture du lot.
- [ns_scenes_v1_103_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_103_evidence_pack.md) : Ce pack de preuves.

### Modifiés

1. **[cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart) :**
   - Ajout de `stagePoint` à `CinematicActorInitialPlacementKind`.
   - Ajout du champ `stagePointId` et méthode `copyWith` dans `CinematicActorInitialPlacement`.

2. **[cinematic_diagnostics.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart) :**
   - Implémentation de 3 nouveaux codes de diagnostics : `actorInitialPlacementStagePointMissing`, `actorInitialPlacementStagePointWithoutStageMap`, `actorInitialPlacementStagePointOutOfMap`.

3. **[cinematic_actor_display_preview_model.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart) :**
   - Résolution géométrique logique de la position de l'acteur à partir du point de scène référencé.

4. **[cinematic_authoring_operations.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart) :**
   - Propagation et préservation du contexte `stagePoints` pour empêcher la perte de points de scène lors de la mise à jour des données d'acteur.
   - Validation que `stagePointId` n'est pas vide pour un placement de type `stagePoint`.

5. **[cinematic_builder_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart) :**
   - Ajout de l'UI d'inspecteur latéral avec choix radio `"Point de scène"`, affichage du label du point sélectionné, et overlay de popup dropdown (`_StagePointDropdownPopup`) avec les coordonnées réelles et le statut sélectionné.
   - Ajout du bouton de fermeture de sélection dans `_SelectedStagePointInspector` (`CupertinoIcons.xmark_circle`) pour revenir à l'inspecteur global.

6. **[cinematic_stage_preview_readiness.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart) :**
   - Mapping des 3 nouveaux codes de diagnostics et intégration dans la checklist de préparation visuelle de la preview.

7. **[cinematic_diagnostics_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/cinematic_diagnostics_test.dart) / [cinematic_actor_display_preview_model_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/cinematic_actor_display_preview_model_test.dart) / [cinematic_asset_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/cinematic_asset_test.dart) :**
   - Ajout des cas de tests unitaires pour valider les modèles, le JSON, la résolution géométrique, et les diagnostics.

8. **[cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart) :**
   - Test d'intégration de workspace pour l'option de placement par point de scène, la visibilité du dropdown et la sélection d'un point.

## 5. Commandes de Validation Exécutées

### Validation Core (`packages/map_core`) :
```bash
cd packages/map_core
dart test
dart analyze
```
*Résultats* : Tous les 2454 tests passent (100% vert), 0 erreur d'analyse statique.

### Validation Éditeur (`packages/map_editor`) :
```bash
cd packages/map_editor
flutter test test/cinematic_builder_workspace_test.dart
```
*Résultats* : Tous les 200 tests de la suite passent avec succès.

## 6. Capture d'Écran (Visual Gate)

- **Fichier** : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.png`
- **SHA-256 Checksum** : `3933e2c5bda849160b2b6c392dd0a64d2654f8f5d12cb53feb85c395b92183f3`
- **Taille** : 315 181 octets (315 KB)

![Visual Gate - Placement d'Acteur via Point de Scène](/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.png)

## 7. Auto-critique et Limites
- **Auto-critique** : L'implémentation du bouton de désélection résout une gêne ergonomique importante remontée par l'utilisateur pendant les tests d'authoring.
- **Risques** : Le seul risque mineur est l'utilisation future de coordonnées réelles (au format double) pour les déplacements (`actorMove`), ce qui nécessitera des interpolations sub-cellulaires géométriques fluides (ceci sera adressé dans le lot V1-104).
- **Prochaines étapes** : Lancer le lot `NS-SCENES-V1-104` pour intégrer la liaison de cibles de mouvement (`actorMove`) de la timeline avec ces mêmes points de scène.
