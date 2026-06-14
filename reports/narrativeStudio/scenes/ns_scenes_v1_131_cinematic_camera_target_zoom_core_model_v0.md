# NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0

## 1. Résumé exécutif

Statut : `DONE`.

V1-131 implémente le modèle core authoring Camera Target / Zoom issu de V1-130 :

- mode caméra `focus` ajouté aux modes historiques `reset` et `hold` ;
- cibles caméra typées `sceneCenter`, `actor`, `stagePoint` ;
- presets de zoom typés `wide`, `medium`, `close` ;
- bindings typés pour cible + zoom ;
- helpers metadata pour éviter l'usage direct des strings côté consommateurs ;
- opérations pures pour créer et mettre à jour des blocs Camera focus ;
- diagnostics core pour target/zoom/mode invalides ;
- lecture JSON backward-compatible des anciens blocs Camera `reset` / `hold`.

Aucune UI d'authoring complète Camera Target / Zoom n'a été créée. Aucune preview caméra réelle, géométrie caméra, runtime, Flame, GameState ou mutation du viewport editor n'a été ajoutée.

## 2. Rappel du contrat V1-130

V1-130 retenait `Option D + Option G` :

- Camera Target V0 : `Centre de la scène`, `Acteur`, `Repère` ;
- Camera Zoom V0 : `Plan large`, `Plan moyen`, `Gros plan` ;
- Camera Mode : `Réinitialiser le cadrage`, `Maintenir le cadrage`, `Cadrer une cible`.

V1-131 traduit ce contrat en modèle core, pas en UI ni en géométrie.

## 3. Audit initial

État initial Git : propre.

Le code existant stockait déjà les blocs Camera dans `CinematicTimelineStepKind.camera`, avec metadata `camera.mode = reset | hold`. Le choix le plus sûr était donc d'étendre ce stockage existant, pas de créer un nouveau modèle parallèle.

Fichiers audités :

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- tests cinematic authoring, diagnostics, asset JSON et preview playback.

## 4. Décisions d'implémentation

Décision principale : conserver le JSON backward-compatible via metadata de step Camera.

Metadata V1-131 :

```text
camera.mode = reset | hold | focus
camera.targetKind = sceneCenter | actor | stagePoint
camera.targetActorId = <actor id>
camera.targetStagePointId = <stage point id>
camera.zoomPreset = wide | medium | close
```

Les opérations pures nettoient les metadata inutiles :

- `reset` / `hold` suppriment target + zoom ;
- `focus sceneCenter` ne stocke aucun ID ;
- `focus actor` stocke seulement `targetActorId` ;
- `focus stagePoint` stocke seulement `targetStagePointId`.

Le read model playback reconnaît `focus` comme intention symbolique, mais le marque non supporté pour ne pas prétendre qu'une géométrie caméra existe déjà.

Correction editor : uniquement exhaustiveness/compile-only. Le bouton `focus` n'est pas exposé dans les contrôles Camera existants afin de ne pas démarrer V1-132.

## 5. Fichiers modifiés

Code core :

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`

Tests core :

- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`

Correction editor compile-only :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Documentation :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_131_cinematic_camera_target_zoom_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_131_evidence_pack.md`

## 6. Modèle ajouté

Ajouts principaux :

```dart
enum CinematicTimelineCameraMode {
  reset,
  hold,
  focus,
}

enum CinematicCameraTargetKind {
  sceneCenter,
  actor,
  stagePoint,
}

enum CinematicCameraZoomPreset {
  wide,
  medium,
  close,
}
```

Bindings typés :

```text
CinematicCameraTargetBinding
- kind
- actorId
- stagePointId
- label
- factories sceneCenter / actor / stagePoint

CinematicTimelineCameraFocusBinding
- target
- zoomPreset
```

Helpers publics :

```dart
cinematicTimelineCameraModeOf(step)
cinematicTimelineCameraTargetKindOf(step)
cinematicTimelineCameraZoomPresetOf(step)
cinematicTimelineCameraTargetBindingOf(step)
cinematicTimelineCameraFocusBindingOf(step)
```

## 7. Opérations pures ajoutées

Ajout :

```text
addCinematicTimelineCameraFocusStep
```

Extension :

```text
addCinematicTimelineBasicBlockStep + cameraFocusBinding
updateCinematicTimelineBasicBlockStep + cameraFocusBinding
```

Les validations vérifient :

- acteur focus présent dans `requiredActors` ;
- Stage Point focus présent dans `stageContext.stagePoints` ;
- `focus` sans binding refusé ;
- steps non-camera refusent les bindings caméra.

## 8. Diagnostics ajoutés

Codes ajoutés :

```text
cameraTargetMissing
cameraTargetKindUnsupported
cameraTargetActorMissing
cameraTargetActorUnknown
cameraTargetActorWithoutPosition
cameraTargetStagePointMissing
cameraTargetStagePointUnknown
cameraTargetStagePointOutOfMap
cameraTargetStageMapMissing
cameraZoomPresetMissing
cameraZoomPresetUnsupported
cameraModeUnsupported
cameraGeometryUnavailable
```

`cameraGeometryUnavailable` est réservé au futur lot de géométrie/playback caméra réelle. V1-131 ne l'émet pas comme faux signal core systématique.

## 9. Backward compatibility JSON

Les anciens blocs Camera restent lisibles :

- `camera.mode = reset` donne `CinematicTimelineCameraMode.reset` ;
- `camera.mode = hold` donne `CinematicTimelineCameraMode.hold` ;
- absence de target/zoom sur reset/hold reste valide.

Le modèle `CinematicTimelineStep` n'a pas été modifié : les nouveaux champs restent dans `metadata`.

## 10. Tests exécutés

Tests RED ciblés V1-131 exécutés avant implémentation : échec attendu par types/helpers absents.

Tests GREEN :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart --name "V1-131"
```

Résultat : `All tests passed!`

Régressions core :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_asset_test.dart test/cinematic_preview_playback_plan_test.dart
```

Résultat : `+175`, `All tests passed!`

Analyse core :

```bash
cd packages/map_core
dart analyze lib/src/authoring/cinematic_authoring_operations.dart lib/src/diagnostics/cinematic_diagnostics.dart lib/src/read_models/cinematic_preview_playback_plan.dart test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart
```

Résultat : `No issues found!`

Régression editor ciblée :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Résultat : `All tests passed!`

Analyse editor ciblée :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Résultat : exit code `0`, avec 35 infos `prefer_const_*` préexistantes/non bloquantes.

## 11. Limites restantes

- Pas d'UI d'authoring complète cible/zoom.
- Pas de picker acteur/repère pour Camera focus.
- Pas de géométrie caméra.
- Pas de `centerX`, `centerY`, zoom numérique, pan, interpolation ou bounds.
- Pas de preview caméra réelle.
- Pas de runtime, Flame, GameState ou mutation viewport editor.

## 12. Prochain lot recommandé

`NS-SCENES-V1-132 — Cinematic Camera Target / Zoom Editor UI V0`

Objectif recommandé : brancher le modèle V1-131 dans l'inspecteur Camera du Cinematic Builder avec contrôles no-code cible/zoom, sans géométrie caméra réelle.

## 13. Auto-critique finale

Points solides :

- Le modèle reste petit et compatible avec le stockage existant.
- Les opérations nettoient les états contradictoires.
- Les diagnostics couvrent les cas invalides importants sans inventer de géométrie.
- `focus` est reconnu par le read model, mais reste unsupported pour ne pas mentir à l'UI.

Risques :

- `cameraTargetActorWithoutPosition` dépend des initial placements disponibles ; il reste un warning authoring, pas une garantie de rendu.
- V1-132 devra transformer les IDs acteur/repère en workflow no-code avec labels, sinon l'UX pourrait redevenir trop technique.
- Le diagnostic `cameraGeometryUnavailable` est seulement réservé dans V1-131 ; son émission devra être cadrée par le futur lot de géométrie.
