# NS-SCENES-V1-105 — Evidence Pack

## Lot

`NS-SCENES-V1-105 — Cinematic Builder UX Simplification / Destination Vocabulary V0`

## Synthèse

Karim a demandé de simplifier le vocabulaire visible du Cinematic Builder avant de poursuivre vers Manual Path. Le lot applique ce changement dans `map_editor`, met à jour les tests et documente le décalage du Manual Path vers V1-106.

## Etat git initial

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all -> <vide>
git diff --stat -> <vide>
git diff --name-only -> <vide>
```

## TDD / Red

Test ajouté : `uses simplified no-code destination vocabulary in builder`.

Premier échec utile avant implémentation :

```text
Expected: at least one matching candidate
  Actual: _TextContainingWidgetFinder:<Found 0 widgets with text containing Personnage ou objet de la map: []>
```

Interprétation : le Builder exposait encore l'ancien vocabulaire pour une destination map entity.

## Commandes exécutées

### Test vocabulaire ciblé

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses simplified no-code destination vocabulary in builder'
00:04 +1: All tests passed!
```

### Test probe timeline ciblé

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'snaps local timeline time probe to block boundaries without changing selection'
00:02 +1: All tests passed!
```

### Visual Gate V1-105

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_105_CAPTURE_CINEMATIC_BUILDER_UX_SIMPLIFICATION=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-105 cinematic builder ux simplification destination vocabulary visual gate when requested'
00:03 +1: All tests passed!
```

### Suite Builder

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:35 +204: All tests passed!
```

### Suite Library + overlay

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:08 +26: All tests passed!
```

### Analyse ciblée

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie exacte retenue :

```text
Analyzing 7 items...
48 issues found. (ran in 1.6s)
```

Code de sortie : `0`. Les 48 issues sont des infos non fatales, pas des warnings fatals.

### Format

```text
cd packages/map_editor && dart format lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
Formatted lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart
Formatted lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
Formatted test/cinematic_stage_point_preview_overlay_test.dart
Formatted 7 files (3 changed) in 0.19 seconds.
```

### Visual Gate metadata

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
-rw-r--r--  1 karim  staff   159K Jun 11 21:48 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
5835676297cb96e8084f8f8c16bec56cb8c47ea25dbf2c010fedde77bc184336  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
```

### Anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
Sortie : <vide>
```

```text
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
Sortie : <vide>
```

```text
rg -n "Ajouter un point|Point abstrait|Point de scène|Cibles de déplacement|Aucun diagnostic|Effacer le repère|Aide repère|Repère :" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
Sortie : <vide>
```

## Inventaire des fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_105_evidence_pack.md
```

## Code / zones générées ou modifiées

### Vocabulaire Builder

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
6190: 'Personnage ou objet de la map'
8498: label: 'Position libre'
8539: label: 'Personnage ou objet de la map'
8556: label: 'Déclencheur de map'
10484: final baseLabel = 'Marqueur : ${_shortTimeLabel(timeMs)}';
11208: 'Repères de scène'
11225: 'Aucun repère de scène.\nClique sur « Ajouter un repère » puis sur la carte pour en poser un.'
```

### Vocabulaire Library

```diff
- title: 'Diagnostics',
+ title: 'Problèmes',
- ? 'Aucun diagnostic'
+ ? 'Aucun problème'
- subtitle: 'Read-only V0',
+ subtitle: 'Déroulé',
- _KeyValue(label: 'Steps', value: '${timeline.stepCount} step(s)'),
+ _KeyValue(label: 'Actions', value: '${timeline.stepCount} action(s)'),
```

### Test principal ajouté

```dart
testWidgets('uses simplified no-code destination vocabulary in builder',
    (tester) async {
  await tester.pumpWidget(
    _extendedBackdropFixture(asset: _v1_105VocabularyFixture()),
  );
  await tester.pumpAndSettle();

  expect(find.text('Ajouter un repère'), findsWidgets);
  expect(find.text('Destination'), findsWidgets);
  expect(find.text('Repère de scène'), findsWidgets);
  expect(find.text('Position libre'), findsWidgets);
  expect(find.textContaining('Personnage ou objet de la map'), findsWidgets);
  expect(find.textContaining('Déclencheur de map'), findsWidgets);
  expect(find.text('Timeline cinématique'), findsOneWidget);

  expect(find.textContaining('Ajouter un point'), findsNothing);
  expect(find.textContaining('Point abstrait'), findsNothing);
  expect(find.textContaining('Point de scène'), findsNothing);
  expect(find.textContaining('Cibles de déplacement'), findsNothing);
});
```

## Build

Aucun build complet lancé.

Raison : lot UI/editor limité et couvert par tests widget ciblés + analyse ciblée + Visual Gate. Les packages runtime/gameplay/battle/core ne sont pas modifiés.

Commande de build recommandée si besoin de validation desktop complète :

```text
cd packages/map_editor && flutter build macos
```

## Limites et risques

- Les identifiants internes restent techniques dans le code et les modèles.
- Les infos analyzer non fatales ne sont pas toutes nettoyées.
- La Visual Gate est une preuve d'interface, pas une mesure automatique pixel-perfect.
- Manual Path est explicitement repoussé à V1-106.

## Critique finale

Verdict : lot conforme au prompt et au repo.

Points surveillés :

- aucun changement dans `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host` ;
- aucune modification Xcode ;
- anciens libellés visibles scannés absents ;
- roadmaps alignées avec le décalage V1-106.

## Etat git final

```text
git diff --check
Sortie : <vide>
```

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_105_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
```
