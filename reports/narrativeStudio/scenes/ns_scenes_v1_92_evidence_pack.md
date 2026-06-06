# NS-SCENES-V1-92 — Evidence Pack

Lot : `NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`

Demande : prompt fourni par Karim.

## 1. Gate 0

Commande :

```bash
pwd
git status --short --untracked-files=all
git log --oneline -n 15
```

Résultat utile :

```text
/Users/karim/Project/pokemonProject
main
Working tree initialement propre.
Dernier commit observe : eb05d109 feat(narrative): auto-commit changes
```

## 2. RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static actor placeholders over the cinematic map backdrop'
```

Résultat RED initial :

```text
Error: Method not found: '_actorDisplayPreviewCinematic'.
Error: Method not found: '_stageMapDataWithActorDisplayFixtures'.
Error: No named parameter with the name 'actorDisplayPreviewModel'.
Some tests failed.
```

Interprétation : le test exigeait le nouveau wiring V1-92 avant implementation.

## 3. Tests Editor

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static actor placeholders over the cinematic map backdrop'
```

Résultat final :

```text
+1: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'aligns actor placeholders with the backdrop viewport transform'
```

Résultat :

```text
+1: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Résultat utile :

```text
+158: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart --plain-name 'wires actor display preview model into builder'
```

Résultat final :

```text
+1: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Résultat :

```text
+21: All tests passed!
```

## 4. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_92_CAPTURE_CINEMATIC_ACTOR_DISPLAY_PREVIEW=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-92 cinematic actor display preview renderer when requested'
```

Résultat :

```text
+1: All tests passed!
```

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png
```

Fichier :

```text
-rw-r--r--  1 karim  staff   287K Jun  7 00:53 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256 431d9555fcf0ea36c5929af660adcf7720fb1b76c0802c6ebe0feabcc14df8c3
```

Contrôle visuel : décor bitmap réel visible, placeholders Joueur/Garde/Lysa visibles, Silhouette et acteur sans entrée non inventés sur la map, diagnostics à compléter visibles, timeline préservée, transports disabled.

## 5. Tests Core Non-régression

Commandes :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
cd packages/map_core && dart analyze
```

Résultats :

```text
cinematic_actor_display_preview_model_test.dart : +25 All tests passed
cinematic_map_backdrop_preview_model_test.dart : +19 All tests passed
cinematic_stage_map_source_catalog_test.dart : +7 All tests passed
cinematic_asset_test.dart : +14 All tests passed
project_manifest_cinematics_test.dart : +9 All tests passed
dart analyze : No issues found
```

## 6. Analyse Editor

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/design_system/pokemap_badge.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Résultat :

```text
Analyzing 9 items...
No issues found!
```

## 7. Anti-scope

Commandes :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples packages/map_core
rg -n "package:flame|FlameGame|GameWidget|PlayableMapGame|RuntimeMapGame|GameState|map_runtime" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
rg -n "AnimationController|Ticker|Timer\(|startPlayback|stopPlayback|isPlaying|playbackTimeMs|currentTimeMs|seek\(|scrub\(" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
rg -n "actorMove.*(execute|interpol|progress|lerp)|pathfinding|collision" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
rg -n "Sprite|CharacterSprite|ImageProvider|AssetImage|rootBundle|ui\.Image|drawImageRect" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
rg -n "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
```

Résultats :

```text
Aucune modification dans packages/map_runtime, packages/map_gameplay, packages/map_battle, examples ou packages/map_core.
Aucune occurrence runtime/Flame/GameState/map_runtime.
Aucune occurrence playback/timer/ticker/seek/scrub.
Aucune occurrence actorMove execution/interpolation/pathfinding/collision dans les fichiers V1-92.
Aucune occurrence sprite/image loading dans l'overlay actor display.
Aucune couleur hardcodée Color(0x...) ou Colors.* dans les fichiers UI V1-92.
```

Notes : les mentions historiques `gpt-image-2` restent dans d'anciens rapports/roadmaps, sans lien avec V1-92 ni utilisation d'image IA.

## 8. Fichiers

Fichiers produit/tests :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

Artefacts :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_92_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 9. Git status final attendu

Le lot laisse uniquement les fichiers V1-92 modifies/ajoutes. Aucun git write n'a ete execute.
