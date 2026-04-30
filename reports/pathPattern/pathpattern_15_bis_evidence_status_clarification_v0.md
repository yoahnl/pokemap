# Lot PathPattern-15-bis — Evidence / Git Status Clarification V0

## 1. Résumé exécutif

Verdict : clarification livrée, sans changement fonctionnel.

Le Lot 15-bis a vérifié l’incohérence documentaire signalée dans le rapport Lot 15. Au démarrage réel du 15-bis, le worktree était propre : `git status --short`, `git diff --stat` et `git diff --name-status` ne produisaient aucune sortie.

Les fichiers qui étaient listés comme non suivis dans l’audit initial du rapport Lot 15 sont maintenant suivis par Git, prouvé par `git ls-files` et `git ls-files -s` :

```text
packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
reports/pathPattern/pathpattern_15_tileset_selection_v0.md
```

Conclusion factuelle : cas B du prompt. Ces fichiers sont maintenant suivis. Le 15-bis n’a exécuté aucune commande Git d’écriture et n’a pas modifié le code produit. Les commandes autorisées ne permettent pas d’attribuer quand ni par qui ces fichiers sont passés au suivi Git ; elles permettent seulement d’établir que cette transition a eu lieu avant l’audit initial du 15-bis.

Le Lot 15 reste fermable sur le fond : les tests ciblés, la régression `test/path_pattern/`, les régressions `map_core` demandées et l’analyze ciblé passent.

Context Mode était disponible et utilisé. Stats MCP relevées :

```text
1.8M tokens saved · 82.2% reduction · 30h 2m
197 calls
v1.0.103
```

## 2. Audit initial

Commandes exécutées avant toute modification :

```bash
pwd
git status --short
git diff --stat
git diff --name-status
git ls-files packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
git ls-files packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
git ls-files packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
git ls-files packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
git ls-files reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
git ls-files reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
git ls-files reports/pathPattern/pathpattern_15_tileset_selection_v0.md
```

Sortie `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Sortie `git status --short` :

```text
```

Sortie `git diff --stat` :

```text
```

Sortie `git diff --name-status` :

```text
```

Sorties `git ls-files` :

```text
$ git ls-files packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart

$ git ls-files packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart

$ git ls-files packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
packages/map_editor/test/path_pattern/path_pattern_draft_test.dart

$ git ls-files packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart

$ git ls-files reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
reports/pathPattern/pathpattern_14_draft_editor_state_v0.md

$ git ls-files reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md

$ git ls-files reports/pathPattern/pathpattern_15_tileset_selection_v0.md
reports/pathPattern/pathpattern_15_tileset_selection_v0.md
```

## 3. État Git initial réel

État initial réel du 15-bis :

```text
git status --short : aucune sortie
git diff --stat : aucune sortie
git diff --name-status : aucune sortie
```

Interprétation limitée aux preuves :

- aucun fichier modifié non commit au démarrage du 15-bis ;
- aucun fichier non suivi visible au démarrage du 15-bis ;
- aucun diff de fichiers suivis au démarrage du 15-bis.

## 4. Clarification Git / worktree

Incohérence à clarifier :

Le rapport Lot 15 contenait un audit initial avec plusieurs fichiers `??`, puis un statut final attendu qui ne les listait plus.

Clarification prouvée par le Lot 15-bis :

- les fichiers `path_pattern_draft.dart`, `path_studio_new_path_draft.dart`, leurs tests, et les rapports 14 / 14-bis / 15 sont maintenant suivis par Git ;
- ils ne sont pas supprimés, car `wc -l`, `shasum -a 256` et `cat` les lisent ;
- ils ne sont pas ignorés comme fichiers non suivis, car `git status --short --ignored -- <paths>` ne produit aucune sortie ;
- ils ne sont pas en diff, car `git diff --stat` et `git diff --name-status` ne produisent aucune sortie ;
- le 15-bis n’a fait aucun `git add`, `git commit`, `git restore`, `git reset`, `git stash`, `git checkout`, `git switch`, `git merge`, `git rebase`, `git rm` ou `git push`.

Réponse au cas demandé :

```text
Cas B — Les fichiers sont maintenant suivis.
```

Les commandes autorisées ne permettent pas d’établir l’événement exact qui a changé leur suivi. Le constat honnête est donc :

```text
Les fichiers étaient présentés comme non suivis dans le rapport Lot 15, mais ils sont suivis au démarrage du Lot 15-bis. Cette transition a eu lieu avant le 15-bis et hors intervention du 15-bis.
```

## 5. Fichiers suivis vs non suivis

Sortie `git ls-files -s` :

```text
100644 c9717cb9b3decd3805a53005064284fa9ceadbdd 0	packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
100644 d287ca879ae61250155478edc28094973d1cc4db 0	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
100644 7ad8ea659bab572d55e6c13afabbb98b7d2a7399 0	packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
100644 4a155d94c87e021cabfe66cf7e0d77b8bc97a67f 0	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
100644 f581de2cd5010db5ea8c040ad830eeb521c2cae3 0	reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
100644 8cde760bae01a8abd74f931178bc7075a530bef2 0	reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
100644 da1a705e20f7533c9546196061727326341da878 0	reports/pathPattern/pathpattern_15_tileset_selection_v0.md
```

Tailles et SHA-256 :

```text
packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
230 lines
1a62b8532817896b8c262bd79ad871e3b9c0febe64b9d654f2b5d25029439cf4

packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
203 lines
eba6f8da2e0abf0898f187a3048633c1d7f1eabbe63c33e47bda7a98e277b135

packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
145 lines
bd2ab1940b9d088f0ed710ff9c176d225cd8af325e60eae4e30f1e65cbc7d661

packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
145 lines
bc1294f4e5e1f3f3231b90ef370e403aa5e4757a0a5b23545ea7f1d1bc597f39

reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
5121 lines
ec6636eddff3719967285151876e20f087b4277d36b5bb938a7cd8089a8ebf97

reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
3167 lines
0d853391d08b48e055f66992d7e1678e77b8cf854a61f29ffb2ccc71031a4ea7

reports/pathPattern/pathpattern_15_tileset_selection_v0.md
862 lines
d7a2464048794f29543d0094f0ef639a503536cecd27653480c0eb6b81d06c62
```

## 6. État réel de PathStudioNewPathDraft

Preuves par inspection :

```text
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:35: this.tilesetId,
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:48: final String? tilesetId;
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:88: if (tilesetId == null || tilesetId!.isEmpty) {
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:89: result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:91: result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:181: PathStudioNewPathDraft selectPathStudioNewPathDraftTileset(
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart:185: return draft.copyWith(tilesetId: tilesetId, isDirty: true);
```

Preuves par tests :

```text
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:15: expect(draft.tilesetId, isNull);
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:21: PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:22: PathStudioNewPathDraftIssueCode.cellsNotConfigured,
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:29: final selected = selectPathStudioNewPathDraftTileset(
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:34: expect(selected.tilesetId, 'tileset-main');
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:36: PathStudioNewPathDraftIssueCode.cellsNotConfigured,
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:122: PathStudioNewPathDraftIssueCode.nameRequired,
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart:123: PathStudioNewPathDraftIssueCode.cellsNotConfigured,
```

Conclusion :

- `PathStudioNewPathDraft` contient bien `tilesetId`.
- `selectPathStudioNewPathDraftTileset(...)` existe.
- `tilesetNotConfigured` disparaît quand `tilesetId` est renseigné.
- `cellsNotConfigured` reste présent.

## 7. État réel des tests Lot 15

Tests ciblés relancés :

```text
flutter test test/path_pattern/path_studio_new_path_draft_test.dart -> 00:03 +7: All tests passed!
flutter test test/path_pattern/path_pattern_draft_test.dart -> 00:03 +6: All tests passed!
flutter test test/path_pattern/path_studio_panel_test.dart -> 00:05 +12: All tests passed!
flutter test test/path_pattern/ -> 00:04 +62: All tests passed!
```

Analyze relancé :

```text
flutter analyze lib/src/features/path_studio test/path_pattern -> No issues found! (ran in 2.3s)
```

## 8. Tests exécutés

### 8.1 `path_studio_new_path_draft_test.dart`

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_studio_new_path_draft_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
00:03 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
00:03 +0: PathStudioNewPathDraft creates an initial draft without a legacy ProjectPathPreset
00:03 +1: PathStudioNewPathDraft creates an initial draft without a legacy ProjectPathPreset
00:03 +1: PathStudioNewPathDraft selects a tileset while preserving center size and selection
00:03 +2: PathStudioNewPathDraft selects a tileset while preserving center size and selection
00:03 +2: PathStudioNewPathDraft resizes a 1x1 draft to 2x2 placeholder cells
00:03 +3: PathStudioNewPathDraft resizes a 1x1 draft to 2x2 placeholder cells
00:03 +3: PathStudioNewPathDraft resizes a 2x2 draft back to 1x1 and clamps selection
00:03 +4: PathStudioNewPathDraft resizes a 2x2 draft back to 1x1 and clamps selection
00:03 +4: PathStudioNewPathDraft renames the draft locally
00:03 +5: PathStudioNewPathDraft renames the draft locally
00:03 +5: PathStudioNewPathDraft empty name after tileset selection exposes only remaining issues
00:03 +6: PathStudioNewPathDraft empty name after tileset selection exposes only remaining issues
00:03 +6: PathStudioNewPathDraft selects a placeholder cell by exact local coordinates
00:03 +7: PathStudioNewPathDraft selects a placeholder cell by exact local coordinates
00:03 +7: All tests passed!
```

### 8.2 `path_pattern_draft_test.dart`

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_pattern_draft_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:03 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:03 +0: PathPatternDraft creates an initial draft from the legacy cross center
00:03 +1: PathPatternDraft creates an initial draft from the legacy cross center
00:03 +1: PathPatternDraft returns null when a manifest has no legacy base path preset
00:03 +2: PathPatternDraft returns null when a manifest has no legacy base path preset
00:03 +2: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames
00:03 +3: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames
00:03 +3: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center
00:03 +4: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center
00:03 +4: PathPatternDraft changes base while preserving name and current size
00:03 +5: PathPatternDraft changes base while preserving name and current size
00:03 +5: PathPatternDraft empty draft name exposes a local nameRequired issue
00:03 +6: PathPatternDraft empty draft name exposes a local nameRequired issue
00:03 +6: All tests passed!
```

### 8.3 `path_studio_panel_test.dart`

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_studio_panel_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:03 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:03 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:04 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:04 +1: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:04 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:04 +2: PathStudioPanel lists presets and updates summary and inspector selection
00:04 +2: PathStudioPanel filters presets locally and clears selection on no result
00:04 +3: PathStudioPanel filters presets locally and clears selection on no result
00:04 +3: PathStudioPanel creates a new path draft without legacy base presets
00:04 +4: PathStudioPanel creates a new path draft without legacy base presets
00:04 +4: PathStudioPanel new path draft does not force existing legacy path choices
00:04 +5: PathStudioPanel new path draft does not force existing legacy path choices
00:04 +5: PathStudioPanel new path draft can select a project tileset
00:04 +6: PathStudioPanel new path draft can select a project tileset
00:04 +6: PathStudioPanel new path draft stays usable when the project has no tileset
00:05 +6: PathStudioPanel new path draft stays usable when the project has no tileset
00:05 +7: PathStudioPanel new path draft stays usable when the project has no tileset
00:05 +7: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:05 +8: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:05 +8: PathStudioPanel edits new path draft name and keeps save disabled
00:05 +9: PathStudioPanel edits new path draft name and keeps save disabled
00:05 +9: PathStudioPanel secondary legacy flow changes inherited structure locally
00:05 +10: PathStudioPanel secondary legacy flow changes inherited structure locally
00:05 +10: PathStudioPanel empty new path name shows a local diagnostic
00:05 +11: PathStudioPanel empty new path name shows a local diagnostic
00:05 +11: PathStudioPanel secondary legacy flow reports missing existing paths
00:05 +12: PathStudioPanel secondary legacy flow reports missing existing paths
00:05 +12: All tests passed!
```

## 9. Analyze exécuté

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/features/path_studio test/path_pattern
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 2.3s)
```

## 10. Régressions exécutées

Régressions exécutées :

```text
cd packages/map_editor && flutter test test/path_pattern/
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart
cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart
cd packages/map_core && dart test test/project_path_pattern_preset_json_codec_test.dart
cd packages/map_core && dart test test/project_path_pattern_preset_json_golden_test.dart
cd packages/map_core && dart test test/project_path_pattern_preset_test.dart
cd packages/map_core && dart test test/path_center_pattern_test.dart
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart
```

Lignes finales exactes :

```text
flutter test test/path_pattern/ -> 00:04 +62: All tests passed!
dart test test/project_manifest_path_pattern_preset_operations_test.dart -> 00:00 +14: All tests passed!
dart test test/project_manifest_path_pattern_presets_test.dart -> 00:00 +8: All tests passed!
dart test test/project_path_pattern_preset_json_codec_test.dart -> 00:00 +9: All tests passed!
dart test test/project_path_pattern_preset_json_golden_test.dart -> 00:00 +6: All tests passed!
dart test test/project_path_pattern_preset_test.dart -> 00:00 +5: All tests passed!
dart test test/path_center_pattern_test.dart -> 00:00 +17: All tests passed!
dart test test/path_center_pattern_resolver_test.dart -> 00:00 +6: All tests passed!
```

Régressions shell :

Elles n’ont pas été relancées dans le 15-bis parce que `git status --short`, `git diff --stat` et `git diff --name-status` ne montrent aucun fichier shell modifié au démarrage du 15-bis.

## 11. git status final réel

Avant création du présent rapport, `git status --short` ne produisait aucune sortie.

Après création du présent rapport, statut attendu et réel du 15-bis :

```text
?? reports/pathPattern/pathpattern_15_bis_evidence_status_clarification_v0.md
```

## 12. git diff --stat final réel

Avant création du présent rapport, `git diff --stat` ne produisait aucune sortie.

Après création du présent rapport, `git diff --stat` ne produit pas de sortie, car le seul changement du 15-bis est le présent rapport non suivi.

```text
```

## 13. git diff --name-status final réel

Avant création du présent rapport, `git diff --name-status` ne produisait aucune sortie.

Après création du présent rapport, `git diff --name-status` ne produit pas de sortie, car le seul changement du 15-bis est le présent rapport non suivi.

```text
```

## 14. Evidence Pack

### 14.1 Contenu complet de `path_studio_new_path_draft.dart`

```dart
enum PathStudioNewPathDraftIssueCode {
  nameRequired,
  tilesetNotConfigured,
  cellsNotConfigured,
}

final class PathStudioNewPathDraftCell {
  const PathStudioNewPathDraftCell({
    required this.localX,
    required this.localY,
    required this.label,
  });

  final int localX;
  final int localY;
  final String label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftCell &&
            localX == other.localX &&
            localY == other.localY &&
            label == other.label;
  }

  @override
  int get hashCode => Object.hash(localX, localY, label);
}

final class PathStudioNewPathDraft {
  PathStudioNewPathDraft({
    required this.id,
    required this.name,
    this.tilesetId,
    required this.centerWidth,
    required this.centerHeight,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.isDirty,
  })  : assert(centerWidth > 0),
        assert(centerHeight > 0),
        assert(selectedCellX >= 0 && selectedCellX < centerWidth),
        assert(selectedCellY >= 0 && selectedCellY < centerHeight);

  final String id;
  final String name;
  final String? tilesetId;
  final int centerWidth;
  final int centerHeight;
  final int selectedCellX;
  final int selectedCellY;
  final bool isDirty;

  String get centerPatternLabel => '$centerWidth×$centerHeight';

  int get centerCellCount => centerWidth * centerHeight;

  List<PathStudioNewPathDraftCell> get cells {
    final result = <PathStudioNewPathDraftCell>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < centerHeight; y += 1) {
      for (var x = 0; x < centerWidth; x += 1) {
        result.add(
          PathStudioNewPathDraftCell(
            localX: x,
            localY: y,
            label: String.fromCharCode(labelCode),
          ),
        );
        labelCode += 1;
      }
    }
    return List<PathStudioNewPathDraftCell>.unmodifiable(result);
  }

  PathStudioNewPathDraftCell get selectedCell {
    return cells.firstWhere(
      (cell) => cell.localX == selectedCellX && cell.localY == selectedCellY,
    );
  }

  List<PathStudioNewPathDraftIssueCode> get issues {
    final result = <PathStudioNewPathDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.nameRequired);
    }
    if (tilesetId == null || tilesetId!.isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
    }
    result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
    return List<PathStudioNewPathDraftIssueCode>.unmodifiable(result);
  }

  PathStudioNewPathDraft copyWith({
    String? id,
    String? name,
    Object? tilesetId = _sentinel,
    int? centerWidth,
    int? centerHeight,
    int? selectedCellX,
    int? selectedCellY,
    bool? isDirty,
  }) {
    return PathStudioNewPathDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      tilesetId: identical(tilesetId, _sentinel)
          ? this.tilesetId
          : tilesetId as String?,
      centerWidth: centerWidth ?? this.centerWidth,
      centerHeight: centerHeight ?? this.centerHeight,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraft &&
            id == other.id &&
            name == other.name &&
            tilesetId == other.tilesetId &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            isDirty == other.isDirty;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        tilesetId,
        centerWidth,
        centerHeight,
        selectedCellX,
        selectedCellY,
        isDirty,
      );
}

const _sentinel = Object();

PathStudioNewPathDraft createInitialPathStudioNewPathDraft() {
  return PathStudioNewPathDraft(
    id: 'draft-new-path',
    name: 'Nouveau chemin',
    centerWidth: 1,
    centerHeight: 1,
    selectedCellX: 0,
    selectedCellY: 0,
    isDirty: true,
  );
}

PathStudioNewPathDraft resizePathStudioNewPathDraftCenter({
  required PathStudioNewPathDraft draft,
  required int width,
  required int height,
}) {
  return draft.copyWith(
    centerWidth: width,
    centerHeight: height,
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
  );
}

PathStudioNewPathDraft renamePathStudioNewPathDraft(
  PathStudioNewPathDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftTileset(
  PathStudioNewPathDraft draft,
  String tilesetId,
) {
  return draft.copyWith(tilesetId: tilesetId, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  if (localX < 0 ||
      localY < 0 ||
      localX >= draft.centerWidth ||
      localY >= draft.centerHeight) {
    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
  }
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
  );
}
```

### 14.2 Contenu complet de `path_studio_new_path_draft_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';

void main() {
  group('PathStudioNewPathDraft', () {
    test('creates an initial draft without a legacy ProjectPathPreset', () {
      final draft = createInitialPathStudioNewPathDraft();

      expect(draft.id, 'draft-new-path');
      expect(draft.name, 'Nouveau chemin');
      expect(draft.centerWidth, 1);
      expect(draft.centerHeight, 1);
      expect(draft.centerPatternLabel, '1×1');
      expect(draft.centerCellCount, 1);
      expect(draft.tilesetId, isNull);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.isDirty, isTrue);
      expect(draft.cells.map((cell) => cell.label), ['A']);
      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a tileset while preserving center size and selection', () {
      final draft = createInitialPathStudioNewPathDraft();

      final selected = selectPathStudioNewPathDraftTileset(
        draft,
        'tileset-main',
      );

      expect(selected.tilesetId, 'tileset-main');
      expect(selected.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
      expect(selected.centerPatternLabel, '1×1');
      expect(selected.selectedCellX, 0);
      expect(selected.selectedCellY, 0);
      expect(selected.isDirty, isTrue);
    });

    test('resizes a 1x1 draft to 2x2 placeholder cells', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: 2,
        height: 2,
      );

      expect(resized.tilesetId, 'tileset-main');
      expect(resized.centerPatternLabel, '2×2');
      expect(resized.centerCellCount, 4);
      expect(
        resized.cells.map((cell) => (cell.localX, cell.localY, cell.label)),
        [
          (0, 0, 'A'),
          (1, 0, 'B'),
          (0, 1, 'C'),
          (1, 1, 'D'),
        ],
      );
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('resizes a 2x2 draft back to 1x1 and clamps selection', () {
      final twoByTwo = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );
      final selected = selectPathStudioNewPathDraftCell(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: selected,
        width: 1,
        height: 1,
      );

      expect(resized.centerWidth, 1);
      expect(resized.centerHeight, 1);
      expect(resized.centerCellCount, 1);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('renames the draft locally', () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        'Route claire',
      );

      expect(draft.name, 'Route claire');
      expect(draft.tilesetId, 'tileset-main');
      expect(draft.isDirty, isTrue);
    });

    test('empty name after tileset selection exposes only remaining issues',
        () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        '   ',
      );

      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.nameRequired,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a placeholder cell by exact local coordinates', () {
      final draft = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );

      final selected = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: 1,
        localY: 0,
      );

      expect(selected.selectedCellX, 1);
      expect(selected.selectedCellY, 0);
      expect(selected.selectedCell.label, 'B');
    });
  });
}
```

### 14.3 Contenu complet de `path_pattern_draft.dart`

```dart
import 'package:map_core/map_core.dart';

/// Issues locales propres au brouillon Path Studio.
///
/// Elles ne sont pas des erreurs de manifest : le brouillon n'est pas encore
/// persistant. Le but est seulement de guider l'utilisateur pendant l'édition
/// locale V0.
enum PathPatternDraftIssueCode {
  nameRequired,
}

/// Brouillon local et non sauvegardé d'un `ProjectPathPatternPreset`.
///
/// Ce modèle vit côté `map_editor` parce qu'il décrit un état d'édition UI,
/// pas un contrat projet. Il ne mute jamais le `ProjectManifest`.
final class PathPatternDraft {
  PathPatternDraft({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.centerPattern,
    this.transparentColor,
    this.categoryId,
    required this.sortOrder,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.isDirty,
  });

  final String id;
  final String name;
  final String basePathPresetId;
  final PathCenterPattern centerPattern;
  final TilesetTransparentColor? transparentColor;
  final String? categoryId;
  final int sortOrder;
  final int selectedCellX;
  final int selectedCellY;
  final bool isDirty;

  String get centerPatternLabel =>
      '${centerPattern.size.width}×${centerPattern.size.height}';

  int get centerCellCount => centerPattern.cells.length;

  int get centerFrameCount => centerPattern.cells.fold(
        0,
        (total, cell) => total + cell.frames.length,
      );

  int get animatedCellCount =>
      centerPattern.cells.where((cell) => cell.frames.length > 1).length;

  PathCenterPatternCell get selectedCell =>
      centerPattern.cellAt(selectedCellX, selectedCellY);

  List<PathPatternDraftIssueCode> get issues {
    final result = <PathPatternDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathPatternDraftIssueCode.nameRequired);
    }
    return List<PathPatternDraftIssueCode>.unmodifiable(result);
  }

  PathPatternDraft copyWith({
    String? id,
    String? name,
    String? basePathPresetId,
    PathCenterPattern? centerPattern,
    TilesetTransparentColor? transparentColor,
    String? categoryId,
    int? sortOrder,
    int? selectedCellX,
    int? selectedCellY,
    bool? isDirty,
  }) {
    return PathPatternDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      basePathPresetId: basePathPresetId ?? this.basePathPresetId,
      centerPattern: centerPattern ?? this.centerPattern,
      transparentColor: transparentColor ?? this.transparentColor,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternDraft &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            centerPattern == other.centerPattern &&
            transparentColor == other.transparentColor &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            isDirty == other.isDirty;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        basePathPresetId,
        centerPattern,
        transparentColor,
        categoryId,
        sortOrder,
        selectedCellX,
        selectedCellY,
        isDirty,
      );
}

PathPatternDraft? createInitialPathPatternDraftFromManifest({
  required ProjectManifest manifest,
}) {
  if (manifest.pathPresets.isEmpty) {
    return null;
  }
  return createInitialPathPatternDraft(
    basePathPreset: manifest.pathPresets.first,
    sortOrder: manifest.pathPatternPresets.length,
  );
}

PathPatternDraft createInitialPathPatternDraft({
  required ProjectPathPreset basePathPreset,
  int sortOrder = 0,
}) {
  return PathPatternDraft(
    id: 'draft-path-pattern',
    name: 'Nouveau motif de chemin',
    basePathPresetId: basePathPreset.id,
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: PathCenterPatternSize(width: 1, height: 1),
    ),
    categoryId: null,
    sortOrder: sortOrder,
    selectedCellX: 0,
    selectedCellY: 0,
    isDirty: true,
  );
}

PathCenterPattern rebuildDraftCenterPattern({
  required ProjectPathPreset basePathPreset,
  required PathCenterPatternSize size,
}) {
  final centerView = createLegacyProjectPathPresetCenterPatternView(
    preset: basePathPreset,
    centerVariant: TerrainPathVariant.cross,
  );
  final frames = centerView.centerPattern.cellAt(0, 0).frames;
  final cells = <PathCenterPatternCell>[];
  for (var y = 0; y < size.height; y += 1) {
    for (var x = 0; x < size.width; x += 1) {
      cells.add(
        PathCenterPatternCell(
          localX: x,
          localY: y,
          frames: frames,
        ),
      );
    }
  }
  return PathCenterPattern(size: size, cells: cells);
}

PathPatternDraft resizePathPatternDraftCenter({
  required PathPatternDraft draft,
  required ProjectPathPreset basePathPreset,
  required int width,
  required int height,
}) {
  final size = PathCenterPatternSize(width: width, height: height);
  return draft.copyWith(
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: size,
    ),
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
  );
}

PathPatternDraft changePathPatternDraftBase({
  required PathPatternDraft draft,
  required ProjectPathPreset basePathPreset,
}) {
  return draft.copyWith(
    basePathPresetId: basePathPreset.id,
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: draft.centerPattern.size,
    ),
    isDirty: true,
  );
}

PathPatternDraft renamePathPatternDraft(
  PathPatternDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathPatternDraft selectPathPatternDraftCell({
  required PathPatternDraft draft,
  required int localX,
  required int localY,
}) {
  // `cellAt` intentionally performs the bounds validation for this local
  // editor state. A failing caller should surface during tests rather than
  // silently selecting a different cell.
  draft.centerPattern.cellAt(localX, localY);
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
  );
}
```

### 14.4 Contenu complet de `path_pattern_draft_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_draft.dart';

void main() {
  group('PathPatternDraft', () {
    test('creates an initial draft from the legacy cross center', () {
      final draft = createInitialPathPatternDraft(
        basePathPreset: _legacyPathPreset(id: 'legacy-water', crossSourceX: 7),
      );

      expect(draft.id, 'draft-path-pattern');
      expect(draft.name, 'Nouveau motif de chemin');
      expect(draft.basePathPresetId, 'legacy-water');
      expect(
          draft.centerPattern.size, PathCenterPatternSize(width: 1, height: 1));
      expect(draft.centerPattern.cellAt(0, 0).frames, [_frame(7)]);
      expect(draft.isDirty, isTrue);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.issues, isEmpty);
    });

    test('returns null when a manifest has no legacy base path preset', () {
      final draft = createInitialPathPatternDraftFromManifest(
        manifest: ProjectManifest(
          name: 'Project',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      expect(draft, isNull);
    });

    test('resizes a 1x1 draft to a 2x2 center with copied cross frames', () {
      final base = _legacyPathPreset(id: 'legacy-water', crossSourceX: 3);
      final draft = createInitialPathPatternDraft(basePathPreset: base);

      final resized = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: 2,
        height: 2,
      );

      expect(resized.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(
          resized.centerPattern.cells.map((cell) => (cell.localX, cell.localY)),
          [
            (0, 0),
            (1, 0),
            (0, 1),
            (1, 1),
          ]);
      for (final cell in resized.centerPattern.cells) {
        expect(cell.frames, [_frame(3)]);
      }
    });

    test('resizes a 2x2 draft back to a valid 1x1 center', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = resizePathPatternDraftCenter(
        draft: createInitialPathPatternDraft(basePathPreset: base),
        basePathPreset: base,
        width: 2,
        height: 2,
      );

      final resized = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: 1,
        height: 1,
      );

      expect(resized.centerPattern.size,
          PathCenterPatternSize(width: 1, height: 1));
      expect(resized.centerPattern.cells, hasLength(1));
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('changes base while preserving name and current size', () {
      final water = _legacyPathPreset(id: 'legacy-water', crossSourceX: 1);
      final sand = _legacyPathPreset(id: 'legacy-sand', crossSourceX: 9);
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: water),
        'Nom conservé',
      );
      final twoByTwo = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: water,
        width: 2,
        height: 2,
      );

      final changed = changePathPatternDraftBase(
        draft: twoByTwo,
        basePathPreset: sand,
      );

      expect(changed.name, 'Nom conservé');
      expect(changed.basePathPresetId, 'legacy-sand');
      expect(changed.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(changed.centerPattern.cellAt(1, 1).frames, [_frame(9)]);
    });

    test('empty draft name exposes a local nameRequired issue', () {
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(
            basePathPreset: _legacyPathPreset(id: 'legacy-water')),
        '   ',
      );

      expect(draft.issues, [PathPatternDraftIssueCode.nameRequired]);
    });
  });
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  int crossSourceX = 0,
}) {
  return ProjectPathPreset(
    id: id,
    name: id,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(crossSourceX)],
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

### 14.5 Extraits rapports volumineux avec preuves

Rapport 14 :

```text
path: reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
status: tracked
lines: 5121
sha256: ec6636eddff3719967285151876e20f087b4277d36b5bb938a7cd8089a8ebf97
head:
# Lot PathPattern-14 — PathPattern Draft Editor State V0

Date: 2026-04-30

Verdict: implémenté et vérifié. Path Studio permet maintenant de créer un brouillon local non sauvegardé, de modifier son nom, de changer sa base legacy, de basculer son centre entre 1×1 et 2×2, de sélectionner une cellule, et de voir inspector/diagnostics se mettre à jour. Aucune persistance manifest n’a été ajoutée.
tail:
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
```

Rapport 14-bis :

```text
path: reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
status: tracked
lines: 3167
sha256: 0d853391d08b48e055f66992d7e1678e77b8cf854a61f29ffb2ccc71031a4ea7
head:
# Lot PathPattern-14-bis — Path Studio Creation UX Correction V0

## 1. Résumé exécutif
Verdict : lot terminé. Le geste principal du Path Studio est maintenant `Nouveau chemin`, avec un brouillon local indépendant de tout `ProjectPathPreset` legacy.
tail:
- Pas de modification `map_core`, `ProjectManifest`, codecs PathPattern, generated files ou build_runner.
- Pas de painter, canvas render, runtime render, gameplay, battle, tall grass, Surface Studio, TSX/TMX, Mistral, PixelLab ou MCP ajouté.
- Pas de tile picker, frame picker, drag and drop, preview PNG réelle, preview animée réelle, duplication persistée ou suppression.
```

Rapport 15 :

```text
path: reports/pathPattern/pathpattern_15_tileset_selection_v0.md
status: tracked
lines: 862
sha256: d7a2464048794f29543d0094f0ef639a503536cecd27653480c0eb6b81d06c62
head:
# Lot PathPattern-15 — Path Studio Tileset Selection V0

## 1. Résumé exécutif

Verdict : livré et vérifié.
tail:
- [x] Les régressions pertinentes passent.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
```

## 15. Auto-review

- Ai-je modifié du code fonctionnel ? Non.
- Ai-je utilisé une commande Git interdite ? Non.
- Ai-je stage, commit, restore, reset ou supprimé un fichier ? Non.
- Ai-je clarifié pourquoi les fichiers non suivis apparaissent / disparaissent ? Oui : ils sont maintenant suivis avant 15-bis ; la transition exacte n’est pas attribuable avec les commandes autorisées.
- Ai-je prouvé l’état réel de `path_studio_new_path_draft.dart` ? Oui, par contenu complet, `rg`, tests et SHA-256.
- Ai-je relancé les tests ciblés Lot 15 ? Oui.
- Ai-je relancé l’analyze ciblé ? Oui.
- Ai-je documenté les éventuelles incohérences restantes ? Oui : impossibilité d’attribuer l’auteur ou le moment du changement de suivi avec les commandes autorisées.

## 16. Review séparée si disponible

Review séparée effectuée par sub-agent `Plato`.

Synthèse :

```text
Git status clean: `git status --short --untracked-files=all` returned no output. `git diff --stat` and `git diff --name-status` also no output.
Lot 14/14-bis/15 files checked with `git ls-files`; all listed source, test, and report files are tracked.
`PathStudioNewPathDraft` has `String? tilesetId` and `selectPathStudioNewPathDraftTileset(...)`.
Panel uses `manifest.tilesets`: `widget.manifest.tilesets` into `_CenterWorkspace`, then `manifest.tilesets` into `_NewPathInspector`, then the popup options.
No current blocking doc conclusion found.
No files edited. No git write commands run.
```

## 17. Critique du prompt

Ce qui était clair :

- la mission était strictement documentaire ;
- la question Git à résoudre était bien formulée ;
- les commandes autorisées / interdites étaient explicites ;
- les tests à relancer étaient précis.

Ce qui était ambigu :

- le prompt demande d’expliquer “pourquoi” les fichiers ont disparu du statut, mais interdit les commandes qui pourraient aider à dater l’événement, comme l’historique Git. La réponse honnête ne peut donc pas dépasser le constat : ils sont suivis maintenant, et le 15-bis ne les a pas ajoutés.
- la demande d’inclure le contenu complet de fichiers non suivis ne s’applique plus au cas réel, car les fichiers sont suivis ; j’ai quand même inclus le contenu complet des sources/tests Path Studio pour lever le doute.

Poids documentaire :

- le lot est lourd pour une clarification, surtout parce que les rapports précédents font plusieurs milliers de lignes. Le compromis `taille + SHA-256 + début/fin` pour les rapports volumineux est plus utile qu’une reproduction intégrale.

Meilleure stratégie documentaire possible :

- dès le Lot 15, distinguer explicitement `statut initial`, `statut final réel`, et `statut final attendu après création du rapport` aurait évité l’ambiguïté.

## 18. Risques / limites

- Les commandes autorisées prouvent l’état courant, mais ne permettent pas de dater ni attribuer le passage des fichiers au suivi Git.
- Le présent rapport est le seul fichier ajouté par le 15-bis ; il rend le worktree non propre jusqu’à prise en compte par le flux Git humain.
- Les rapports 14 et 14-bis sont volumineux ; leurs contenus complets ne sont pas reproduits ici, mais leur suivi, taille, hash, début et fin sont fournis.

## 19. Conclusion : Lot 15 fermable ou non

Conclusion : le Lot 15 est fermable.

Justification :

- l’incohérence de statut est clarifiée par le cas B : les fichiers sont maintenant suivis ;
- le 15-bis n’a pas utilisé de commande Git d’écriture ;
- aucun comportement produit n’a été modifié ;
- le modèle `PathStudioNewPathDraft` contient `tilesetId` ;
- `selectPathStudioNewPathDraftTileset(...)` existe ;
- `tilesetNotConfigured` disparaît après sélection ;
- `cellsNotConfigured` reste présent ;
- le panneau Path Studio lit `manifest.tilesets` ;
- les tests ciblés Lot 15 passent ;
- l’analyze ciblé passe ;
- les régressions demandées passent.

