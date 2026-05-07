# Environment-42-bis — TileLayer Regenerate / Shuffle Readiness Gate Fix V0

## 1. Résumé

Ce mini-lot corrige le gate TileLayer-centric de `Régénérer` et `Shuffle`.

Avant correction, une area prête à générer mais jamais générée pouvait exposer `canShuffle == true` dans le read model TileLayer-centric. Le wrapper de shuffle refusait ensuite correctement `generatedPlacementIds` vide, mais l’UI pouvait présenter une action activable qui finissait en erreur évitable.

La correction aligne le read model et le callback wiring :

- `canShuffle == false` en état `ready` sans `generatedPlacementIds` ;
- `canRegenerate == false` reste inchangé sans `generatedPlacementIds` ;
- `MapInspectorPanel` exige aussi `hasGeneratedPlacements` avant de fournir les callbacks `Régénérer` et `Shuffle`.

## 2. Problème corrigé

Le Lot 42 avait bien protégé les wrappers TileLayer-centric : `RegenerateTileLayerEnvironmentAreaPlacementsUseCase` et `ShuffleTileLayerEnvironmentAreaPlacementsUseCase` refusent une area dont `generatedPlacementIds` est vide.

L’incohérence était plus haut :

- dans `tile_layer_environment_attachment_read_model_builder.dart`, l’état `ready` avait `canGenerate: true`, `canRegenerate: false`, mais `canShuffle: true` ;
- dans `MapInspectorPanel`, les callbacks regenerate/shuffle étaient transmis sur la base de `readModel.canRegenerate` / `readModel.canShuffle`, sans garde explicite sur `hasGeneratedPlacements`.

Résultat possible :

```text
Area prête jamais générée
→ Générer dans ce layer actif
→ Shuffle activable
→ clic
→ wrapper refuse generatedPlacementIds vide
```

Ce lot supprime ce mismatch.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart`

Commande d’audit :

```bash
rg -n "canRegenerate|canShuffle|hasGeneratedPlacements|generatedPlacementCount|generatedPlacementIds|canClearGeneratedPlacements|canGenerate|Régénérer|Shuffle|onRegenerateEnvironment|onShuffleEnvironment" packages/map_editor/lib/src packages/map_editor/test/environment_studio
```

Constats :

- `TileLayerEnvironmentAttachmentReadModel` expose déjà `hasGeneratedPlacements`, `generatedPlacementCount`, `canRegenerate`, `canShuffle`.
- Le builder TileLayer-centric calcule `generatedPlacementCount` depuis `area.generatedPlacementIds.length`.
- L’état `generated` exposait déjà `canRegenerate: true` et `canShuffle: true`.
- L’état `ready` exposait `canGenerate: true`, `canRegenerate: false`, `canShuffle: true`.
- `TileLayerEnvironmentInspectorSection` désactive un bouton si `readModel.canX == false`.
- `MapInspectorPanel` passait `onShuffleEnvironment` si `readModel.canShuffle == true`, sans `hasGeneratedPlacements`.
- Les tests du Lot 42 couvraient le refus wrapper/notifier quand `generatedPlacementIds` est vide, mais pas le gate UI/read model de l’état prêt jamais généré.

## 4. Correction read model / readiness

Nouvelle règle TileLayer-centric :

```text
generatedPlacementCount == 0
→ canRegenerate == false
→ canShuffle == false
```

La correction appliquée dans l’état `ready` du builder :

```dart
canGenerate: true,
canClearGeneratedPlacements: false,
canRegenerate: false,
canShuffle: false,
```

L’état `generated` reste inchangé :

```text
generatedPlacementCount > 0
+ preset valide
+ mask non vide
→ canGenerate == false
→ canClearGeneratedPlacements == true
→ canRegenerate == true
→ canShuffle == true
```

Les états `missingPreset` et `emptyMask` restent non générables et non shuffle/regenerate.

## 5. Correction UI / callbacks

`MapInspectorPanel` ajoute une garde défensive :

```dart
tileLayerEnvironmentReadModel.canRegenerate &&
tileLayerEnvironmentReadModel.hasGeneratedPlacements
```

et :

```dart
tileLayerEnvironmentReadModel.canShuffle &&
tileLayerEnvironmentReadModel.hasGeneratedPlacements
```

Impact attendu :

- area prête jamais générée : `Générer dans ce layer` actif si callback fourni, `Régénérer` et `Shuffle` désactivés ;
- area générée : `Générer dans ce layer` désactivé, `Effacer les placements générés`, `Régénérer` et `Shuffle` actifs si callbacks fournis ;
- références mortes : si `generatedPlacementIds` est non vide, `hasGeneratedPlacements == true`; clear/regenerate/shuffle restent compatibles avec le nettoyage des références mortes.

`TileLayerEnvironmentInspectorSection` n’a pas eu besoin de logique métier supplémentaire : elle suit les booléens du read model et les callbacks fournis.

## 6. Tests

Commandes lancées :

```bash
dart format packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart && cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

Résultat RED observé avant correction :

```text
Expected: false
  Actual: <true>
test/environment_studio/tile_layer_environment_attachment_read_model_test.dart 87
```

et :

```text
Expected: null
  Actual: <Closure: () => void from Function 'shuffleEnvironmentAreaPlacementsForActiveTileLayer':.>
test/environment_studio/environment_generate_button_wiring_test.dart line 721
```

Commande relancée après correction :

```bash
dart format packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart && cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

Résultat :

```text
Formatted 5 files (0 changed) in 0.03 seconds.
00:02 +81: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart test/environment_studio/environment_regenerate_shuffle_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat :

```text
00:01 +25: All tests passed!
```

Cas couverts :

- area prête sans `generatedPlacementIds` : `canGenerate == true`, `canClearGeneratedPlacements == false`, `canRegenerate == false`, `canShuffle == false` ;
- area generated avec `generatedPlacementIds` : `canGenerate == false`, `canClearGeneratedPlacements == true`, `canRegenerate == true`, `canShuffle == true` ;
- area avec `generatedPlacementIds` et placements manquants : clear/regenerate/shuffle restent actifs ;
- preset manquant : regenerate/shuffle false ;
- masque vide : regenerate/shuffle false ;
- `MapInspectorPanel` ne fournit pas regenerate/shuffle sans placements générés ;
- widget section garde regenerate/shuffle désactivés sans placements générés même si callbacks fournis ;
- wrappers Lot 42 et legacy regenerate/shuffle restent verts.

## 7. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor && flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

Résultat :

```text
Analyzing 7 items...
No issues found! (ran in 2.4s)
```

Dette préexistante hors lot :

- `packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart` conserve un cas legacy où `canShuffle` peut être vrai sans placements générés. Ce lot ne change pas le legacy `EnvironmentLayerInspectorPanel`, conformément au prompt.

## 8. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant Environment-42-bis :

```text
M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
M packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
M packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
M packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
M packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
?? reports/environment_studio/environment_42_tile_layer_environment_regenerate_shuffle.md
```

Fichiers modifiés par Environment-42-bis :

```text
packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Fichiers créés par Environment-42-bis :

```text
reports/environment_studio/environment_42_bis_tile_layer_regenerate_shuffle_readiness_gate_fix.md
```

Fichiers préexistants dans le worktree non touchés par Environment-42-bis :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
reports/environment_studio/environment_42_tile_layer_environment_regenerate_shuffle.md
```

Fichiers préexistants dans le worktree touchés aussi par Environment-42-bis :

```text
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

## 9. Non-objectifs respectés

- Pas de changement des use cases regenerate/shuffle.
- Pas de changement du legacy `EnvironmentLayerInspectorPanel`.
- Pas de preview.
- Pas de génération initiale via shuffle.
- Pas de modification de `map_core`.
- Pas de modification runtime/gameplay/battle.
- Pas de build_runner.
- Pas de generated files.
- Pas de modification du mask.
- Pas de modification des params locaux.
- Pas de modification du preset global.
- Pas de création/suppression/renommage d’area.

## 10. Evidence pack

### git status initial

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
?? reports/environment_studio/environment_42_tile_layer_environment_regenerate_shuffle.md
```

### git status final

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
?? reports/environment_studio/environment_42_bis_tile_layer_regenerate_shuffle_readiness_gate_fix.md
?? reports/environment_studio/environment_42_tile_layer_environment_regenerate_shuffle.md
```

### git diff --stat

```bash
git diff --stat
```

```text
 ..._environment_attachment_read_model_builder.dart |   2 +-
 .../src/features/editor/state/editor_notifier.dart | 148 +++++++++++++++-
 .../lib/src/ui/panels/map_inspector_panel.dart     |  34 +++-
 .../tile_layer_environment_inspector_section.dart  |  34 ++++
 .../environment_generate_button_wiring_test.dart   | 145 +++++++++++++++
 ...yer_environment_attachment_read_model_test.dart |   9 +
 ...le_layer_environment_brush_mode_entry_test.dart |  54 +++++-
 ...tile_layer_environment_clear_notifier_test.dart |  37 +++-
 ...e_layer_environment_generate_notifier_test.dart |  59 ++++++-
 ...e_layer_environment_inspector_section_test.dart | 194 ++++++++++++++++++++-
 10 files changed, 700 insertions(+), 16 deletions(-)
```

### git diff --name-only

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

### git diff --check

```bash
git diff --check
```

```text
```

### Commandes principales

```bash
rg -n "canRegenerate|canShuffle|hasGeneratedPlacements|generatedPlacementCount|generatedPlacementIds|canClearGeneratedPlacements|canGenerate|Régénérer|Shuffle|onRegenerateEnvironment|onShuffleEnvironment" packages/map_editor/lib/src packages/map_editor/test/environment_studio
```

```bash
dart format packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart && cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

```bash
dart format packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart && cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart test/environment_studio/environment_regenerate_shuffle_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart
```

```bash
cd packages/map_editor && flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

Résultats principaux :

```text
RED: 2 échecs attendus avant correction.
GREEN ciblé: 00:02 +81: All tests passed!
Non-régressions: 00:01 +25: All tests passed!
Analyze ciblé: No issues found! (ran in 2.4s)
```

## 11. Diff pertinent

### `tile_layer_environment_attachment_read_model_builder.dart`

```diff
@@ -470,7 +470,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
     canGenerate: true,
     canClearGeneratedPlacements: false,
     canRegenerate: false,
-    canShuffle: true,
+    canShuffle: false,
     emptyStateTitle: 'Prêt à générer',
     emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
     primaryActionLabel: 'Générer',
```

### `map_inspector_panel.dart`

Hunk Environment-42-bis :

```diff
@@
     final canRegenerateTileLayerEnvironment = activeLayer is TileLayer &&
         tileLayerEnvironmentReadModel != null &&
         tileLayerEnvironmentReadModel.canRegenerate &&
+        tileLayerEnvironmentReadModel.hasGeneratedPlacements &&
         !tileLayerEnvironmentReadModel.hasErrors &&
         effectiveTileLayerEnvironmentAreaId != null;
     final canShuffleTileLayerEnvironment = activeLayer is TileLayer &&
         tileLayerEnvironmentReadModel != null &&
         tileLayerEnvironmentReadModel.canShuffle &&
+        tileLayerEnvironmentReadModel.hasGeneratedPlacements &&
         !tileLayerEnvironmentReadModel.hasErrors &&
         effectiveTileLayerEnvironmentAreaId != null;
```

Le même fichier avait déjà des modifications Environment-42 / correctif précédent dans le worktree, notamment autour de `effectiveTileLayerEnvironmentAreaId` et du wiring callbacks regenerate/shuffle. Le hunk ci-dessus isole les lignes ajoutées par ce mini-lot.

### `tile_layer_environment_attachment_read_model_test.dart`

```diff
@@
       expect(model.canPaintMask, isTrue);
       expect(model.canGenerate, isTrue);
+      expect(model.canClearGeneratedPlacements, isFalse);
+      expect(model.canRegenerate, isFalse);
+      expect(model.canShuffle, isFalse);
@@
       expect(model.canPaintMask, isTrue);
       expect(model.canGenerate, isFalse);
+      expect(model.canRegenerate, isFalse);
+      expect(model.canShuffle, isFalse);
@@
       expect(model.canClearGeneratedPlacements, isTrue);
       expect(model.canGenerate, isFalse);
+      expect(model.canRegenerate, isTrue);
+      expect(model.canShuffle, isTrue);
```

### `environment_generate_button_wiring_test.dart`

Test ajouté par Environment-42-bis :

```dart
testWidgets(
    'TileLayer inspector désactive Régénérer et Shuffle sans placements générés',
    (tester) async {
  final area = _area(id: 'area1', w: 2, h: 2);
  final tile = TileLayer(
    id: 'tiles',
    name: 'T',
    tiles: List<int>.filled(4, 0),
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: [area],
    ),
  );
  final map = MapData(
    id: 'm1',
    name: 'M1',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'tsA',
    layers: [tile, env],
  );
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: '/r',
    project: _manifest(),
    activeMap: map,
    activeMapPath: 'maps/x.json',
    activeLayerId: 'tiles',
    savedMapSnapshot: map,
  );
  await tester.binding.setSurfaceSize(const Size(520, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 440,
              height: 1100,
              child: MapInspectorPanel(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(_cupertinoButtonFor(tester, 'Générer dans ce layer').onPressed,
      isNotNull);
  expect(_cupertinoButtonFor(tester, 'Régénérer').onPressed, isNull);
  expect(_cupertinoButtonFor(tester, 'Shuffle').onPressed, isNull);
});
```

Helper ajouté :

```dart
CupertinoButton _cupertinoButtonFor(WidgetTester tester, String label) {
  return tester.widget<CupertinoButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(CupertinoButton),
    ),
  );
}
```

### `tile_layer_environment_inspector_section_test.dart`

Tests ajoutés par Environment-42-bis :

```dart
testWidgets(
    'Régénérer reste désactivé sans generatedPlacementIds même avec callback',
    (tester) async {
  var regenerated = 0;
  await _pump(
    tester,
    const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.ready,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
      hasAttachment: true,
      hasValidTargetTileLayer: true,
      selectedEnvironmentAreaName: 'Bosquet nord',
      selectedPresetName: 'Forêt',
      maskActiveCellCount: 42,
      hasMask: true,
      canPaintMask: true,
      canGenerate: true,
      canRegenerate: false,
      emptyStateTitle: 'Prêt à générer',
      emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
    ),
    onRegenerateEnvironment: () {
      regenerated++;
    },
  );

  expect(find.text('Régénérer'), findsOneWidget);
  expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);

  await tester.tap(find.text('Régénérer'));
  await tester.pump();

  expect(regenerated, 0);
});
```

```dart
testWidgets(
    'Shuffle reste désactivé sans generatedPlacementIds même avec callback',
    (tester) async {
  var shuffled = 0;
  await _pump(
    tester,
    const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.ready,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
      hasAttachment: true,
      hasValidTargetTileLayer: true,
      selectedEnvironmentAreaName: 'Bosquet nord',
      selectedPresetName: 'Forêt',
      maskActiveCellCount: 42,
      hasMask: true,
      canPaintMask: true,
      canGenerate: true,
      canShuffle: false,
      emptyStateTitle: 'Prêt à générer',
      emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
    ),
    onShuffleEnvironment: () {
      shuffled++;
    },
  );

  expect(find.text('Shuffle'), findsOneWidget);
  expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);

  await tester.tap(find.text('Shuffle'));
  await tester.pump();

  expect(shuffled, 0);
});
```

Le fichier avait déjà des ajouts Environment-42 autour des boutons regenerate/shuffle. Les snippets ci-dessus correspondent aux cas spécifiques 42-bis.

## 12. Auto-review

- Régénérer est-il désactivé sans generatedPlacementIds ? Oui.
- Shuffle est-il désactivé sans generatedPlacementIds ? Oui.
- Générer reste-t-il actif pour une area prête jamais générée ? Oui.
- Régénérer/Shuffle restent-ils actifs pour une area générée ? Oui.
- Les références mortes restent-elles compatibles avec clear/regenerate/shuffle ? Oui, le gate utilise `generatedPlacementIds.length` via `hasGeneratedPlacements`, pas le nombre de placements réellement présents.
- Le flow legacy reste-t-il intact ? Oui, les fichiers legacy et `EnvironmentAreaGenerationReadiness` n’ont pas été modifiés.
- Les use cases Lot 42 restent-ils inchangés ? Oui.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 13. Critique du prompt et du lot

Clair :

- Le problème était précisément un mismatch readiness/UI, pas un défaut des wrappers.
- La règle métier V0 était explicite : regenerate/shuffle nécessitent `generatedPlacementIds.isNotEmpty`.
- Le legacy pouvait rester différent.

Ambigu :

- La section UI peut soit afficher les boutons désactivés, soit les masquer. Le code existant affiche les actions quand `canPaintMask` est vrai, donc le mini-lot conserve cet affichage désactivé.
- Le terme `generatedPlacementCount` compte les références dans l’area, pas seulement les placements présents. Cette convention est cohérente avec clear/regenerate qui nettoient aussi les références mortes, mais elle mérite un libellé UX plus clair au prochain lot.

À trancher avant Environment-43 :

- Clarifier les messages utilisateur pour distinguer “jamais généré”, “déjà généré”, “références générées manquantes” et “prêt à regénérer”.
- Décider si Régénérer/Shuffle doivent être visibles désactivés en état prêt, ou masqués jusqu’à la première génération.

## 14. Verdict

```text
Environment-42-bis livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-43 — TileLayer Environment Generation Feedback / Readiness Polish V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai corrigé uniquement le gate regenerate/shuffle.
- [x] Je n’ai pas changé la sémantique regenerate/shuffle.
- [x] Je n’ai pas changé le flow legacy.
- [x] Régénérer est désactivé sans generatedPlacementIds.
- [x] Shuffle est désactivé sans generatedPlacementIds.
- [x] Générer reste actif pour une area prête jamais générée.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
