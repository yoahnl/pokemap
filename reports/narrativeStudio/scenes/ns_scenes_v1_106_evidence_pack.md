# NS-SCENES-V1-106 — Evidence Pack

## Lot

`NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract`

## Gate 0 complet

Commande :

```text
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
73be9440 feat: cinematic builder UX simplification et rapports
d93136a5 refactor: UI cinematic builder workspace et tests
1444a60f update selbrume
50c1bba6 update selbrume
4523a1e0 update selbrume
530bbc33 build(macos): add BUILD-MACOS-01 documentation and roadmap
97509364 doc(narrativeStudio): split V1-104-bis Xcode modifications to BUILD-MACOS-01
fc0b2d74 doc(narrativeStudio): close NS-SCENES-V1-104 and compile evidence pack
9fc7bc5c build(macos): bump minimum macOS deployment target to 12.0
dc9859c1 feat(narrative_studio): implement V1-104 - Cinematic ActorMove Target from Stage Points
```

Interprétation des sorties vides dans cette commande groupée :

- `git status --short --untracked-files=all` : `Sortie : <vide>` ;
- `git diff --stat` : `Sortie : <vide>` ;
- `git diff --name-only` : `Sortie : <vide>`.

## Règles lues

```text
AGENTS.md : présent et lu
agent_rules.md : présent et lu
codex_rule.md : présent et lu
codex_rules.md : MISSING
```

## Fichiers lus

Rapports / roadmaps :

```text
OK reports/narrativeStudio/scenes/ns_scenes_v1_100_evidence_pack.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability_evidence_repair.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_103_bis_actor_initial_placement_stage_point_evidence_visual_truth_closure.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_scope_repair.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_105_evidence_pack.md
OK reports/narrativeStudio/scenes/road_map_scenes.md
OK reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Code et tests :

```text
OK packages/map_core/lib/src/models/cinematic_asset.dart
OK packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
OK packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
OK packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
OK packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
OK packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
OK packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
OK packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart
OK packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
OK packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
OK packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
OK packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
OK packages/map_editor/test/cinematic_builder_workspace_test.dart
OK packages/map_editor/test/cinematics_library_workspace_test.dart
OK packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
OK packages/map_core/test/cinematic_asset_test.dart
OK packages/map_core/test/cinematic_authoring_operations_test.dart
OK packages/map_core/test/cinematic_diagnostics_test.dart
OK packages/map_core/test/cinematic_actor_display_preview_model_test.dart
OK packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
OK packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
```

## Résumé des recherches

Recherche modèle :

```text
`CinematicStageContext` contient actorBindings, actorAppearanceBindings, initialPlacements, movementTargetBindings, stagePoints.
`CinematicStagePoint` contient id, label, x, y, description?.
`CinematicMovementTargetBindingKind` contient abstractPoint, mapEntity, mapEvent, stagePoint.
```

Recherche actorMove :

```text
`CinematicTimelineActorPathMode` contient seulement direct.
`_buildActorMoveStep` écrit actor.pathMode = direct.
`isCinematicTimelineActorMoveStep` exige pathMode direct.
`updateCinematicTimelineActorMoveStep` remet pathMode direct.
```

Recherche diagnostics :

```text
Les diagnostics existants couvrent déjà stagePoint manquant/hors map et actorMove sans actor/target/duration/mode/pathMode direct.
Tout pathMode non direct est aujourd'hui error.
```

Recherche UX V1-105 :

```text
Le Builder expose Destination, Repère de scène, Repère, Marqueur temps, Timeline cinématique.
Le contrat V1-106 ne doit pas remettre Cible / Point abstrait / Point de scène comme UX principale.
```

## Décision vérifiée

```text
Option retenue : C + D.
Stockage : CinematicStageContext.manualPaths.
Composition V0 : liste ordonnée de Repères de scène.
Ownership V0 : actorMove propriétaire.
Destination finale : reste séparée du chemin.
Runtime/playback : hors scope.
```

## Tests / analyse / build

Tests Dart :

```text
Aucun test Dart lancé : lot documentaire, aucun fichier Dart modifié.
```

Tests Flutter :

```text
Aucun test Flutter lancé : lot documentaire, aucune UI Flutter modifiée.
```

Analyse :

```text
Aucune analyse Dart/Flutter lancée : lot documentaire limité à Markdown sous reports/narrativeStudio/scenes.
```

Build :

```text
Aucun build lancé : lot documentaire, aucun package produit modifié.
```

## Confirmations anti-scope

Commande :

```text
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

Sortie :

```text
Sortie : <vide>
```

Conclusion : aucun package Dart/Flutter, aucun runtime, aucun gameplay, aucun battle et aucun exemple n'a été modifié par V1-106.

Commande :

```text
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie :

```text
Sortie : <vide>
```

Conclusion : aucun fichier Xcode n'a été modifié.

Autres confirmations :

```text
Aucun screenshot / Visual Gate créé.
Aucun travail V1-107 produit.
Aucun runtime / playback / Flame touché.
```

## Sorties finales

Commande :

```text
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```text
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md        | 15 ++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md     | 19 ++++++++++++++++---
 2 files changed, 30 insertions(+), 4 deletions(-)
```

Commande :

```text
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_106_evidence_pack.md
```

## Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_106_evidence_pack.md
```

Le contenu complet de cet Evidence Pack est le présent fichier. Le contenu complet du rapport principal est dans `reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md`.
