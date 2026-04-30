# PathPattern-12-bis - Editor Read Model Evidence + Tests Completion

## 1. Resume du lot

Verdict : lot 12-bis ferme.

Ce bis a complete la preuve du Lot 12 sans reecrire le read model. Le fichier de production
`packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`
n'a pas ete modifie.

Travail realise :

- audit du read model existant ;
- completion du test `path_pattern_editor_read_model_test.dart` ;
- verification ciblee du test Lot 12 ;
- regression du dossier `test/path_pattern/` cote `map_editor` ;
- regressions PathPattern demandees cote `map_core` ;
- analyse ciblee ;
- rapport final avec Evidence Pack.

## 2. Audit initial

Context Mode : disponible et utilise pour l'audit initial via `ctx_batch_execute`.

Commandes d'audit initial executees depuis `/Users/karim/Project/pokemonProject` :

```bash
git status --short
git diff --stat
git diff --name-status
git ls-files packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
git ls-files packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
git ls-files reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

Sorties initiales :

```text
$ git status --short

$ git diff --stat

$ git diff --name-status

$ git ls-files packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart

$ git ls-files packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart

$ git ls-files reports/pathPattern/path_pattern_lot_12_editor_read_model.md
reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

Constats :

- le read model existe ;
- le test existe ;
- le rapport existe ;
- l'API `createPathPatternEditorReadModel` existe ;
- les statuts `ready`, `needsReview`, `blocked` existent ;
- les issue codes `missingBasePathPreset`, `duplicatePathPatternId`, `duplicateBasePathPresetId` existent ;
- `PathPatternEditorReadModel.presets` est expose via `List.unmodifiable` ;
- `PathPatternPresetCardModel.issues` est expose via `List.unmodifiable` ;
- l'ordre des cards est preserve par iteration directe de la liste source ;
- les doublons sont compares par id exact, sans trim ;
- le read model appelle `readProjectPathPatternPresets(manifest)` ;
- aucune raison technique n'a justifie une modification du read model.

Audit de couplage execute :

```bash
rg -n "package:image|dart:io|package:flutter/widgets|package:flutter/material|map_runtime|map_gameplay|map_battle|renderPathCenterPatternStaticPreviewPng|renderPathCenterPatternAnimatedPreviewPng|Image\\.memory|MemoryImage|Riverpod|Provider|Notifier|Controller|Repository|Service" packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
```

Sortie :

```text
```

Interpretation : aucun import ou appel interdit par le lot n'a ete detecte dans le read model ou son test.

## 3. Etat constate avant modification

Etat initial du bis :

- `path_pattern_editor_read_model.dart` etait present et conforme au contrat V0 ;
- `path_pattern_editor_read_model_test.dart` existait deja, mais ne prouvait pas explicitement deux points demandes par le bis :
  - ids proches mais differents par espaces ;
  - egalite de valeur du read model, du summary et des cards ;
- le rapport existait, mais correspondait au Lot 12 initial et ne contenait pas l'Evidence Pack attendu par le bis.

## 4. Fichiers crees

Aucun fichier cree dans ce bis.

## 5. Fichiers modifies

```text
packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

Modifications du test :

- ajout du cas `ids that differ only by spaces are distinct exact ids` ;
- ajout du cas `read model, summary, and card use value equality`.

## 6. Fichiers volontairement non modifies

```text
packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_path_pattern_preset.dart
packages/map_core/lib/src/models/path_center_pattern.dart
packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
```

Raison : l'audit et les tests n'ont revele aucun bug du read model. Le contrat du bis demandait de ne pas le reecrire gratuitement.

## 7. API finale

API confirmee :

```dart
PathPatternEditorReadModel createPathPatternEditorReadModel({
  required ProjectManifest manifest,
})
```

Types confirmes :

```text
PathPatternEditorReadModel
PathPatternEditorSummary
PathPatternPresetCardModel
PathPatternPresetReadinessStatus
PathPatternPresetIssueCode
```

Statuts confirmes :

```text
ready
needsReview
blocked
```

Issue codes confirmes :

```text
missingBasePathPreset
duplicatePathPatternId
duplicateBasePathPresetId
```

## 8. Comportements couverts

Couverture confirmee par le test :

- manifest sans PathPattern presets ;
- preset 1x1 avec base legacy existante ;
- preset 2x2 avec une cellule animee et `transparentColor` ;
- `basePathPresetId` introuvable ;
- id PathPattern duplique ;
- id `ProjectPathPreset` legacy duplique ;
- matching exact sans trim pour `basePathPresetId` ;
- ids differents uniquement par espaces non consideres comme doublons ;
- ordre des cards preserve ;
- listes exposees immuables ;
- compteurs de summary ;
- egalite de valeur du read model, du summary et des cards.

## 9. Tests executes avec commandes exactes et resultats exacts

### Test cible Lot 12

Commande :

```bash
cd packages/map_editor
flutter test test/path_pattern/path_pattern_editor_read_model_test.dart
```

Sortie complete :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:01 +0: createPathPatternEditorReadModel empty manifest exposes an empty summary and no cards
00:01 +1: createPathPatternEditorReadModel empty manifest exposes an empty summary and no cards
00:01 +1: createPathPatternEditorReadModel ready 1x1 preset exposes list card details
00:01 +2: createPathPatternEditorReadModel ready 1x1 preset exposes list card details
00:01 +2: createPathPatternEditorReadModel ready 2x2 transparent animated preset exposes counts
00:01 +3: createPathPatternEditorReadModel ready 2x2 transparent animated preset exposes counts
00:01 +3: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:01 +4: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:01 +4: createPathPatternEditorReadModel duplicate PathPattern ids block every affected card
00:01 +5: createPathPatternEditorReadModel duplicate PathPattern ids block every affected card
00:01 +5: createPathPatternEditorReadModel duplicate legacy base path preset ids block referencing cards
00:01 +6: createPathPatternEditorReadModel duplicate legacy base path preset ids block referencing cards
00:01 +6: createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:01 +7: createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:01 +7: createPathPatternEditorReadModel matches basePathPresetId exactly without trimming
00:01 +8: createPathPatternEditorReadModel matches basePathPresetId exactly without trimming
00:01 +8: createPathPatternEditorReadModel ids that differ only by spaces are distinct exact ids
00:01 +9: createPathPatternEditorReadModel ids that differ only by spaces are distinct exact ids
00:01 +9: createPathPatternEditorReadModel summary counts ready, blocked, duplicates, and multi-cell presets
00:01 +10: createPathPatternEditorReadModel summary counts ready, blocked, duplicates, and multi-cell presets
00:01 +10: createPathPatternEditorReadModel read model and card lists are immutable defensive copies
00:01 +11: createPathPatternEditorReadModel read model and card lists are immutable defensive copies
00:01 +11: createPathPatternEditorReadModel read model, summary, and card use value equality
00:01 +12: createPathPatternEditorReadModel read model, summary, and card use value equality
00:01 +12: All tests passed!
```

Resultat exact : `00:01 +12: All tests passed!`

## 10. Analyze execute avec commande exacte et resultat exact

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/path_studio/path_pattern_editor_read_model.dart test/path_pattern/path_pattern_editor_read_model_test.dart
```

Sortie complete :

```text
Analyzing 2 items...
No issues found! (ran in 1.3s)
```

Resultat exact : `No issues found! (ran in 1.3s)`

## 11. Regressions executees

### Regressions PathPattern editor

Commande :

```bash
cd packages/map_editor
flutter test test/path_pattern/
```

Ligne finale exacte :

```text
00:02 +37: All tests passed!
```

Cette regression couvre les tests PathPattern editor actuellement presents : read model, preview statique, preview animee et processeur de couleur transparente.

### Regressions map_core PathPattern

Commandes et lignes finales exactes :

```text
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart
00:00 +14: All tests passed!

cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart
00:00 +8: All tests passed!

cd packages/map_core && dart test test/project_path_pattern_preset_json_codec_test.dart
00:01 +9: All tests passed!

cd packages/map_core && dart test test/project_path_pattern_preset_json_golden_test.dart
00:00 +6: All tests passed!

cd packages/map_core && dart test test/project_path_pattern_preset_test.dart
00:00 +5: All tests passed!

cd packages/map_core && dart test test/path_center_pattern_test.dart
00:01 +17: All tests passed!

cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart
00:00 +6: All tests passed!
```

Pour ces regressions, la preuve retenue est la commande exacte et la ligne finale exacte, car le test cible Lot 12 est celui dont la sortie complete est requise et incluse ci-dessus.

## 12. git status --short final

```text
 M packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
 M reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

## 13. git diff --stat

```text
 .../path_pattern_editor_read_model_test.dart       |   58 +
 .../path_pattern_lot_12_editor_read_model.md       | 1730 +++++---------------
 2 files changed, 478 insertions(+), 1310 deletions(-)
```

## 14. git diff --name-status

```text
M	packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
M	reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

## 15. Evidence Pack

### 15.1 Contenu complet de path_pattern_editor_read_model_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_editor_read_model.dart';

void main() {
  group('createPathPatternEditorReadModel', () {
    test('empty manifest exposes an empty summary and no cards', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(),
      );

      expect(readModel.presets, isEmpty);
      expect(readModel.summary.totalCount, 0);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 0);
      expect(readModel.summary.multiCellCenterCount, 0);
      expect(readModel.summary.transparentColorCount, 0);
      expect(readModel.summary.missingBasePathPresetCount, 0);
      expect(readModel.summary.duplicatePathPatternIdCount, 0);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
    });

    test('ready 1x1 preset exposes list card details', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-1x1',
              name: 'Water 1x1',
              basePathPresetId: 'legacy-water',
              pattern: _singleCellPattern(),
            ),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 1);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.issueCount, 0);

      final card = readModel.presets.single;
      expect(card.id, 'water-1x1');
      expect(card.name, 'Water 1x1');
      expect(card.basePathPresetId, 'legacy-water');
      expect(card.basePathPresetName, 'Legacy Water');
      expect(card.basePathSurfaceKindLabel, 'Eau');
      expect(card.centerPatternLabel, '1×1');
      expect(card.centerWidth, 1);
      expect(card.centerHeight, 1);
      expect(card.centerCellCount, 1);
      expect(card.centerFrameCount, 1);
      expect(card.animatedCellCount, 0);
      expect(card.transparentColorHex, isNull);
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(card.issues, isEmpty);
    });

    test('ready 2x2 transparent animated preset exposes counts', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'sea-2x2',
              basePathPresetId: 'legacy-water',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.centerPatternLabel, '2×2');
      expect(card.centerWidth, 2);
      expect(card.centerHeight, 2);
      expect(card.centerCellCount, 4);
      expect(card.centerFrameCount, 5);
      expect(card.animatedCellCount, 1);
      expect(card.transparentColorHex, 'f05ba1');
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.multiCellCenterCount, 1);
      expect(readModel.summary.transparentColorCount, 1);
    });

    test('missing basePathPresetId blocks the card', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'missing',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(card.issues, [
        PathPatternPresetIssueCode.missingBasePathPreset,
      ]);
      expect(card.basePathPresetName, isNull);
      expect(card.basePathSurfaceKindLabel, isNull);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 1);
      expect(readModel.summary.missingBasePathPresetCount, 1);
    });

    test('duplicate PathPattern ids block every affected card', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'duplicate'),
            _pathPatternPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      expect(readModel.presets, hasLength(2));
      for (final card in readModel.presets) {
        expect(card.status, PathPatternPresetReadinessStatus.blocked);
        expect(
          card.issues,
          contains(PathPatternPresetIssueCode.duplicatePathPatternId),
        );
      }
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 2);
      expect(readModel.summary.duplicatePathPatternIdCount, 2);
    });

    test('duplicate legacy base path preset ids block referencing cards', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Water A'),
            _legacyPathPreset(id: 'legacy-water', name: 'Water B'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'ambiguous-base',
              basePathPresetId: 'legacy-water',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(card.issues, [
        PathPatternPresetIssueCode.duplicateBasePathPresetId,
      ]);
      expect(card.basePathPresetName, isNull);
      expect(card.basePathSurfaceKindLabel, isNull);
      expect(readModel.summary.issueCount, 1);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 1);
    });

    test('preserves manifest pathPatternPresets order', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'a'),
            _pathPatternPreset(id: 'b'),
            _pathPatternPreset(id: 'c'),
          ],
        ),
      );

      expect(readModel.presets.map((card) => card.id), ['a', 'b', 'c']);
    });

    test('matches basePathPresetId exactly without trimming', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'whitespace-base',
              basePathPresetId: ' legacy-water ',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(card.issues, [
        PathPatternPresetIssueCode.missingBasePathPreset,
      ]);
      expect(readModel.summary.missingBasePathPresetCount, 1);
    });

    test('ids that differ only by spaces are distinct exact ids', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water'),
            _legacyPathPreset(id: ' legacy-water ', name: 'Spaced Water'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'water', basePathPresetId: 'legacy-water'),
            _pathPatternPreset(
              id: ' water ',
              basePathPresetId: ' legacy-water ',
            ),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 2);
      expect(readModel.summary.readyCount, 2);
      expect(readModel.summary.issueCount, 0);
      expect(readModel.summary.duplicatePathPatternIdCount, 0);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
      expect(readModel.presets.map((card) => card.basePathPresetName), [
        'Legacy Water',
        'Spaced Water',
      ]);
    });

    test('summary counts ready, blocked, duplicates, and multi-cell presets',
        () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'ready', pattern: _twoByTwoPattern()),
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'missing',
            ),
            _pathPatternPreset(id: 'duplicate'),
            _pathPatternPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 4);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.issueCount, 3);
      expect(readModel.summary.multiCellCenterCount, 1);
      expect(readModel.summary.missingBasePathPresetCount, 1);
      expect(readModel.summary.duplicatePathPatternIdCount, 2);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
    });

    test('read model and card lists are immutable defensive copies', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [_pathPatternPreset(id: 'ready')],
        ),
      );

      expect(
        () => readModel.presets.add(readModel.presets.single),
        throwsUnsupportedError,
      );
      expect(
        () => readModel.presets.single.issues.add(
          PathPatternPresetIssueCode.missingBasePathPreset,
        ),
        throwsUnsupportedError,
      );
    });

    test('read model, summary, and card use value equality', () {
      final manifest = _manifest(
        pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        pathPatternPresets: [
          _pathPatternPreset(
            id: 'sea-2x2',
            pattern: _twoByTwoPattern(animatedTopLeft: true),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
          ),
        ],
      );

      final first = createPathPatternEditorReadModel(manifest: manifest);
      final second = createPathPatternEditorReadModel(manifest: manifest);
      final different = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [_pathPatternPreset(id: 'different')],
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.summary, second.summary);
      expect(first.summary.hashCode, second.summary.hashCode);
      expect(first.presets.single, second.presets.single);
      expect(first.presets.single.hashCode, second.presets.single.hashCode);
      expect(first, isNot(different));
    });
  });
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  PathSurfaceKind surfaceKind = PathSurfaceKind.water,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  String? name,
  String basePathPresetId = 'legacy-water',
  PathCenterPattern? pattern,
  TilesetTransparentColor? transparentColor,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: transparentColor,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(2)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(3)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(4)],
      ),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
```

### 15.2 Contenu complet du rapport

Le contenu complet du rapport final est le contenu integral du present fichier.

Le recopier une seconde fois dans ce meme fichier rendrait le document auto-referentiel : l'ajout de cette copie changerait immediatement le contenu qu'elle pretend figer. Cette exigence est donc documentee ici comme non materialisable litteralement sous forme stable.

### 15.3 Contenu complet de path_pattern_editor_read_model.dart

Le read model n'a pas ete modifie dans ce bis. L'Evidence Pack retient donc :

```text
packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
```

Audit confirme :

- fichier present et suivi ;
- API attendue presente ;
- enums attendues presentes ;
- listes immuables ;
- appel a `readProjectPathPatternPresets(manifest)` ;
- aucun import ou appel interdit par l'audit de couplage.

### 15.4 Diff complet reel des fichiers modifies

Diff complet du fichier de test modifie :

```diff
diff --git a/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart b/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
index d0c6a457..5ef88fa8 100644
--- a/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
+++ b/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
@@ -197,6 +197,34 @@ void main() {
       expect(readModel.summary.missingBasePathPresetCount, 1);
     });
 
+    test('ids that differ only by spaces are distinct exact ids', () {
+      final readModel = createPathPatternEditorReadModel(
+        manifest: _manifest(
+          pathPresets: [
+            _legacyPathPreset(id: 'legacy-water'),
+            _legacyPathPreset(id: ' legacy-water ', name: 'Spaced Water'),
+          ],
+          pathPatternPresets: [
+            _pathPatternPreset(id: 'water', basePathPresetId: 'legacy-water'),
+            _pathPatternPreset(
+              id: ' water ',
+              basePathPresetId: ' legacy-water ',
+            ),
+          ],
+        ),
+      );
+
+      expect(readModel.summary.totalCount, 2);
+      expect(readModel.summary.readyCount, 2);
+      expect(readModel.summary.issueCount, 0);
+      expect(readModel.summary.duplicatePathPatternIdCount, 0);
+      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
+      expect(readModel.presets.map((card) => card.basePathPresetName), [
+        'Legacy Water',
+        'Spaced Water',
+      ]);
+    });
+
     test('summary counts ready, blocked, duplicates, and multi-cell presets',
         () {
       final readModel = createPathPatternEditorReadModel(
@@ -242,6 +270,36 @@ void main() {
         throwsUnsupportedError,
       );
     });
+
+    test('read model, summary, and card use value equality', () {
+      final manifest = _manifest(
+        pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        pathPatternPresets: [
+          _pathPatternPreset(
+            id: 'sea-2x2',
+            pattern: _twoByTwoPattern(animatedTopLeft: true),
+            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+          ),
+        ],
+      );
+
+      final first = createPathPatternEditorReadModel(manifest: manifest);
+      final second = createPathPatternEditorReadModel(manifest: manifest);
+      final different = createPathPatternEditorReadModel(
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+          pathPatternPresets: [_pathPatternPreset(id: 'different')],
+        ),
+      );
+
+      expect(first, second);
+      expect(first.hashCode, second.hashCode);
+      expect(first.summary, second.summary);
+      expect(first.summary.hashCode, second.summary.hashCode);
+      expect(first.presets.single, second.presets.single);
+      expect(first.presets.single.hashCode, second.presets.single.hashCode);
+      expect(first, isNot(different));
+    });
   });
 }
 
```

Diff du rapport :

```text
Le present fichier est le rapport final modifie. Integrer ici son diff final exact changerait ce diff a chaque insertion. Le contenu final du rapport est donc donne directement par ce fichier, et les sections 12 a 14 donnent l'etat Git final.
```

### 15.5 Diff /dev/null des fichiers crees

Aucun fichier cree dans ce bis. Il n'y a donc aucun diff `/dev/null` a produire pour le perimetre 12-bis.

### 15.6 Sortie complete du test cible

La sortie complete du test cible est incluse en section 9.

### 15.7 Sortie analyze ciblee

La sortie complete de l'analyse ciblee est incluse en section 10.

### 15.8 Lignes finales exactes des regressions

Les lignes finales exactes des regressions sont incluses en section 11.

## 16. Auto-review

- Le bis a-t-il modifie autre chose que tests/rapport ? Non.
- Le read model a-t-il ete reecrit inutilement ? Non.
- Les tests couvrent-ils reellement les cas V0 ? Oui : vide, ready 1x1, ready 2x2 transparent/anime, base absente, base ambigue, doublons PathPattern, exact matching, ordre, immutabilite, egalite.
- Les doublons sont-ils testes avec comparaison exacte sans trim ? Oui, avec le cas ids differents seulement par espaces.
- Les bases absentes et ambigues sont-elles bien distinguees ? Oui.
- Les listes exposees sont-elles immuables ? Oui.
- L'ordre est-il preserve ? Oui.
- Tous les non-objectifs sont-ils respectes ? Oui.

## 17. Critique du prompt

Ce qui etait clair :

- le bis devait fermer la preuve du Lot 12 ;
- le read model ne devait pas etre reecrit sans bug reel ;
- les cas V0 attendus etaient precis ;
- les non-objectifs etaient suffisamment bornes.

Ce qui etait ambigu ou discutable :

- demander le contenu complet du rapport a l'interieur du rapport cree une recursion documentaire ;
- demander le diff complet final du rapport dans le rapport cree la meme instabilite ;
- le prompt demande les sorties completes des tests cibles, mais accepte des lignes finales pour les regressions longues : cette distinction etait bonne, mais aurait pu etre formulee directement dans l'Evidence Pack.

Decision prise :

- ne pas modifier le read model ;
- completer seulement le test ;
- documenter la limite auto-referentielle du rapport au lieu de produire une preuve instable ;
- retenir `issueCount = nombre de cards avec au moins une issue`, deja couvert par le read model et les tests ;
- retenir `duplicatePathPatternIdCount = nombre de presets concernes par un doublon`, deja couvert.

## 18. Risques / limites restantes

- `needsReview` existe pour l'UI future, mais aucun issue non bloquant ne le produit encore en V0.
- Le read model ne genere pas de preview et ne verifie pas les tilesets ; c'est volontaire pour ce lot.
- Les labels de surface sont en francais simples et restent une convention de presentation V0.
- La preuve auto-referentielle du rapport ne peut pas etre transformee en copie interne stable ; cette limite est documentee.

## 19. Confirmation explicite des non-objectifs

Confirme :

- pas de UI ;
- pas de widget ;
- pas de provider/Riverpod/notifier/controller ;
- pas de repository/service ;
- pas de PNG preview ;
- pas de renderer PNG appele ;
- pas de `map_core` modifie ;
- pas de `ProjectManifest` modifie ;
- pas de generated files ;
- pas de build_runner ;
- pas de painter/canvas/runtime/gameplay/battle ;
- pas de tall grass ;
- pas de Surface Studio ;
- pas de TSX/TMX ;
- pas de Mistral / PixelLab / MCP.
