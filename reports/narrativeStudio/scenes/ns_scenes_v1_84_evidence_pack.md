# NS-SCENES-V1-84 — Evidence Pack

## Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 15
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
```

## Fichiers lus

```text
AGENTS.md
agent_rules.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_83_cinematic_map_backdrop_preview_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_83_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_82_cinematic_map_backdrop_preview_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## Sub-agents / passes spécialisées

Sub-agent A — Renderer / UI Contract : `_PreviewSandbox` est le bon point d'insertion ; préserver la géométrie existante preview/timeline ; ne pas rendre les transports actifs.

Sub-agent B — Read Model Integration : V1-83 expose assez de données pour V0 structurel (`layers`, `sizeSummary`, `viewportRecommendation`, `diagnostics`) ; ne pas ajouter d'extension core.

Sub-agent C — Editor Snapshot / Wiring : réutiliser la snapshot déjà chargée dans `CinematicsLibraryWorkspace`; stocker `_stageMapSnapshot` et `_stageMapSnapshotMapId`; construire le modèle côté editor.

Sub-agent D — Tests / Anti-scope : corriger le test rouge connu par assertion ciblée ; ajouter tests non-mutation, disabled transports, no actors, fallbacks.

## RED préflight

Commande :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'lists timeline steps in order with read-only details'
```

Sortie :

```text
Expected: no matching candidates
Actual: found CupertinoTextField placeholder "Nom de l’acteur" under cinematic-builder-inspector-placeholder
Test failed: lists timeline steps in order with read-only details
```

Correction GREEN :

```text
00:02 +1: All tests passed!
```

## RED V1-84

Test ajouté avant implémentation :

```text
renders static map backdrop preview when backdrop model is available
```

Sortie RED :

```text
test/cinematic_builder_workspace_test.dart:7723:15: Error: No named parameter with the name 'backdropPreviewModel'.
lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:233:9: Context: Found this candidate, but the arguments don't match.
```

## Code généré — nouveau panel

Nouveau fichier source :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
```

Taille :

```text
548 packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
```

Extrait contractuel du code généré :

```dart
class CinematicMapBackdropPreviewPanel extends StatelessWidget {
  const CinematicMapBackdropPreviewPanel({
    super.key,
    required this.model,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropHeader(model: model, compact: compact),
        SizedBox(height: compact ? 8 : 12),
        Expanded(
          child: model.isAvailable
              ? _BackdropMapFrame(model: model, compact: compact)
              : _BackdropFallback(model: model, compact: compact),
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          _BackdropDiagnostics(model: model),
        ],
      ],
    );
  }
}
```

Messages de fallback générés :

```dart
String _fallbackMessage(CinematicMapBackdropPreviewModel model) {
  return switch (model.status) {
    CinematicMapBackdropPreviewStatus.backdropDisabled =>
      'Décor de map désactivé pour cette cinématique.',
    CinematicMapBackdropPreviewStatus.missingStageMap =>
      'Choisis une map de scène pour afficher le décor.',
    CinematicMapBackdropPreviewStatus.stageMapUnknown =>
      'La map de scène n’existe plus dans le projet.',
    CinematicMapBackdropPreviewStatus.mapDataUnavailable =>
      'Les données de cette map ne sont pas disponibles pour la preview.',
    CinematicMapBackdropPreviewStatus.mapDataMismatch =>
      'La map chargée ne correspond pas à la map de scène.',
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      'Le tileset de cette map n’est pas disponible pour la preview.',
    CinematicMapBackdropPreviewStatus.available =>
      'V1-84 affiche enfin un décor de map statique dans le Builder.',
  };
}
```

## Hunk principal — Builder

```diff
+import 'cinematic_map_backdrop_preview_panel.dart';
+  final CinematicMapBackdropPreviewModel? backdropPreviewModel;
+                                backdropPreviewModel:
+                                    widget.backdropPreviewModel,
+          if (backdropPreviewModel != null) {
+            return Column(
+              children: [
+                Expanded(
+                  child: CinematicMapBackdropPreviewPanel(
+                    model: backdropPreviewModel,
+                    compact: compact,
+                  ),
+                ),
+              ],
+            );
+          }
```

## Hunk principal — Library

```diff
+  MapData? _stageMapSnapshot;
+  String? _stageMapSnapshotMapId;
+      final backdropPreviewModel = _buildBackdropPreviewModel(builderAsset);
+        backdropPreviewModel: backdropPreviewModel,
+  CinematicMapBackdropPreviewModel? _buildBackdropPreviewModel(
+    CinematicAsset asset,
+  ) {
+    if (asset.stageContext?.backdropMode !=
+        CinematicStageBackdropMode.projectMap) {
+      return null;
+    }
+    return buildCinematicMapBackdropPreviewModel(
+      asset: asset,
+      stageMap: stageMap,
+      mapData: mapData,
+      availableTilesetIds: _availableTilesetIds(widget.project),
+    );
+  }
```

## Tests ajoutés / modifiés

```text
renders static map backdrop preview when backdrop model is available
shows human fallbacks for every non available backdrop status
shows human fallback when static map backdrop data is unavailable
keeps duration resize and mouse probe working with map backdrop visible
keeps map-aware pickers working with map backdrop visible
keeps Character Library picker working with map backdrop visible
wires loaded stage map snapshot into static backdrop preview
lists timeline steps in order with read-only details (assertions corrigées)
```

## Commandes GREEN ciblées

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
00:02 +1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows human fallbacks for every non available backdrop status'
00:02 +1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'keeps duration resize and mouse probe working with map backdrop visible'
00:02 +1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'keeps map-aware pickers working with map backdrop visible'
00:02 +1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'keeps Character Library picker working with map backdrop visible'
00:02 +1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart --plain-name 'wires loaded stage map snapshot into static backdrop preview'
00:02 +1: All tests passed!
```

## Commandes core

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
00:00 +15: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
00:00 +7: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
00:00 +14: All tests passed!

cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:00 +9: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

## Commandes editor

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:18 +148: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:03 +15: All tests passed!

cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_84_CAPTURE_CINEMATIC_MAP_BACKDROP_PREVIEW=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:18 +148: All tests passed!
```

## Analyze

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 6 items...
No issues found! (ran in 1.9s)
```

Analyse globale editor :

```text
cd packages/map_editor && flutter analyze
344 issues found. (ran in 2.1s)
```

Premières erreurs hors lot :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart: undefined named parameters dbSymbol, battleEngineAimedTarget, battleEngineMethod...
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart: undefined method fetchPokemonSdkStudioProjectPayload
```

## Visual Gate

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
-rw-r--r--  1 karim  staff   253K Jun  6 02:09 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
c005528da38d6af1766c949749528154323ef4e5cc896919bb141631915d1e81  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
```

## Checks anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<vide>
```

Scans sur fichiers modifiés : les sorties globales incluent uniquement des faux positifs existants ou des assertions négatives :

```text
test/cinematic_builder_workspace_test.dart:3789: expect(find.text('seek'), findsNothing);
test/cinematic_builder_workspace_test.dart:3790: expect(find.text('scrub'), findsNothing);
cinematic_builder_workspace.dart:8615: CharacterAnimationState.idle
cinematic_builder_workspace.dart:4178 et autres : couleurs hardcodées préexistantes
```

Scans sur les lignes ajoutées du diff :

```text
runtime/Flame : <vide>
playback/timer : <vide>
actor rendering UI : <vide>
couleurs hardcodées UI : <vide>
Selbrume/image IA : <vide>
stageContext.mapId : seuls deux helpers de test mapId null/map_missing pour fallbacks
```

## Commandes finales git

```text
git diff --check
<vide>

git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |  39 ++
 .../cinematics/cinematics_library_workspace.dart   |  63 ++-
 .../test/cinematic_builder_workspace_test.dart     | 616 ++++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  57 ++
 4 files changed, 762 insertions(+), 13 deletions(-)

git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart

git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
```

Note : après création des rapports et mise à jour roadmaps, le statut final contient aussi les deux fichiers de rapport et les deux roadmaps.

## Auto-review critique

Le lot reste dans le périmètre editor/UI et ne touche pas `map_core`, `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.

Le point faible assumé est visuel : V1-84 donne une perception structurelle de la map, pas encore un rendu final de tiles/assets. Le prochain lot doit améliorer les primitives visuelles sans passer par le runtime.
