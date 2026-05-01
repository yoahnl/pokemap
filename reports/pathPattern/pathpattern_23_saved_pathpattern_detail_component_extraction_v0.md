# Lot PathPattern-23 — Saved PathPattern Detail Component Extraction V0

## 1. Résumé exécutif

Le détail read-only des `ProjectPathPatternPreset` sauvegardés a été extrait de `path_studio_panel.dart` vers un fichier dédié `path_studio_saved_preset_detail.dart` via un découpage `part/part of`, sans introduire de nouvelle feature ni modifier la logique métier.  
Le comportement utilisateur du Lot 22 est conservé (détail centre, thumbnails/fallback, diagnostic base manquante, inspector enrichi), et les validations demandées passent.

## 2. Audit initial

Commandes exécutées avant modification:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
```

Sortie:

```text
/Users/karim/Project/pokemonProject
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
 .../features/path_studio/path_studio_panel.dart    | 478 +++++++++++++++++----
 .../test/path_pattern/path_studio_panel_test.dart  | 143 ++++++
 2 files changed, 547 insertions(+), 74 deletions(-)
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
agent_rules.md
```

Constats d’audit:

- Le bloc read-only ajouté au Lot 22 est localisé dans `path_studio_panel.dart` (modèles `_SavedPathPatternDetail`, `_SavedPathPatternCellDetail`, helpers et widgets `_SavedPreset*`).
- Ces éléments sont dédiés au rendu read-only sauvegardé et extractibles sans toucher les flows `Nouveau chemin`/save legacy.
- Les tests de `path_studio_panel_test.dart` couvrent déjà les comportements à préserver (détail sélectionné, thumbnail image/fallback, base path manquante, save legacy post-Lot 21, blocage Nouveau chemin).

## 3. Problème de maintenabilité constaté

Le fichier `path_studio_panel.dart` concentrait à la fois orchestration du panel et implémentation détaillée du rendu read-only sauvegardé, ce qui augmentait sa taille et réduisait sa lisibilité.

## 4. Décisions d’extraction

- Extraction ciblée dans `packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart`.
- Utilisation de `part 'path_studio_saved_preset_detail.dart';` dans `path_studio_panel.dart` pour conserver les symboles privés existants et éviter un refactor API inutile.
- Aucune modification des règles de rendu, des clés de tests, ou de la logique de résolution base path/tileset/frame.

## 5. Fichiers créés

- `packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart`
- `reports/pathPattern/pathpattern_23_saved_pathpattern_detail_component_extraction_v0.md`

## 6. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

Note: `packages/map_editor/test/path_pattern/path_studio_panel_test.dart` et `reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md` étaient déjà modifiés/non trackés avant ce lot (état de départ conservé).

## 7. Fichiers supprimés

- Aucun.

## 8. Comportements préservés

- Sélection d’un `ProjectPathPatternPreset` => détail read-only affiché.
- Résumé preset, base path, métriques centre, cellules et frames conservés.
- Diagnostic `Preset de base introuvable` conservé.
- Thumbnails carrées image-backed conservées si image disponible.
- Fallback carré lisible conservé si image absente.
- Signalement des cellules animées conservé.
- Inspector enrichi du Lot 22 conservé.
- `Nouveau chemin` reste non sauvegardable.
- Save legacy post-Lot 21 intact.

## 9. Tests exécutés

Depuis `packages/map_editor`:

```bash
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
```

Depuis `packages/map_core`:

```bash
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

Analyze:

```bash
cd packages/map_editor
flutter analyze lib/src/features/path_studio test/path_pattern
```

## 10. Résultats des validations

- Tous les tests ciblés exécutés passent.
- Ligne finale `test/path_pattern/`: `All tests passed!`
- Ligne finale `editor_shell_page_smoke_test.dart`: `All tests passed!`
- Ligne finale `top_toolbar_test.dart`: `All tests passed!`
- Ligne finale `editor_selectors_test.dart`: `All tests passed!`
- Tous les tests ciblés `map_core` passent.
- `flutter analyze lib/src/features/path_studio test/path_pattern` => `No issues found!`

## 11. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
?? reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
?? reports/pathPattern/pathpattern_23_saved_pathpattern_detail_component_extraction_v0.md
```

## 12. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 195 ++++++++-------------
 .../test/path_pattern/path_studio_panel_test.dart  | 143 +++++++++++++++
 2 files changed, 218 insertions(+), 120 deletions(-)
```

## 13. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 14. Evidence Pack

### 14.1 git status initial

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
```

### 14.2 git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
?? reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
?? reports/pathPattern/pathpattern_23_saved_pathpattern_detail_component_extraction_v0.md
```

### 14.3 git diff --stat final

```text
 .../features/path_studio/path_studio_panel.dart    | 195 ++++++++-------------
 .../test/path_pattern/path_studio_panel_test.dart  | 143 +++++++++++++++
 2 files changed, 218 insertions(+), 120 deletions(-)
```

### 14.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### 14.5 Contenu complet des fichiers créés

#### `packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart`

```dart
part of 'path_studio_panel.dart';

final class _SavedPathPatternDetail {
  const _SavedPathPatternDetail({
    required this.preset,
    required this.basePathPreset,
    required this.cells,
    required this.centerFrameCount,
    required this.animatedCellCount,
  });

  final ProjectPathPatternPreset preset;
  final ProjectPathPreset? basePathPreset;
  final List<_SavedPathPatternCellDetail> cells;
  final int centerFrameCount;
  final int animatedCellCount;
}

final class _SavedPathPatternCellDetail {
  const _SavedPathPatternCellDetail({
    required this.label,
    required this.localX,
    required this.localY,
    required this.frameCount,
    required this.primarySourceLabel,
    required this.primaryTile,
  });

  final String label;
  final int localX;
  final int localY;
  final int frameCount;
  final String primarySourceLabel;
  final PathStudioNewPathDraftTile? primaryTile;

  bool get isAnimated => frameCount > 1;
}

_SavedPathPatternDetail _createSavedPathPatternDetail({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
}) {
  final basePathPreset = _resolveBasePathPreset(
    manifest: manifest,
    basePathPresetId: preset.basePathPresetId,
  );
  final cells = List<PathCenterPatternCell>.from(preset.centerPattern.cells)
    ..sort((a, b) {
      final byY = a.localY.compareTo(b.localY);
      return byY != 0 ? byY : a.localX.compareTo(b.localX);
    });
  final details = <_SavedPathPatternCellDetail>[];
  for (var index = 0; index < cells.length; index += 1) {
    final cell = cells[index];
    final frame = cell.frames.first;
    final frameTilesetId = frame.tilesetId.trim();
    final baseTilesetId = basePathPreset?.tilesetId.trim() ?? '';
    final effectiveTilesetId =
        frameTilesetId.isNotEmpty ? frameTilesetId : baseTilesetId;
    final tile = effectiveTilesetId.isEmpty
        ? null
        : PathStudioNewPathDraftTile(
            tilesetId: effectiveTilesetId,
            sourceX: frame.source.x,
            sourceY: frame.source.y,
          );
    details.add(
      _SavedPathPatternCellDetail(
        label: _savedCellLabel(index),
        localX: cell.localX,
        localY: cell.localY,
        frameCount: cell.frames.length,
        primarySourceLabel: '${frame.source.x},${frame.source.y}',
        primaryTile: tile,
      ),
    );
  }
  return _SavedPathPatternDetail(
    preset: preset,
    basePathPreset: basePathPreset,
    cells: details,
    centerFrameCount: details.fold(0, (total, cell) => total + cell.frameCount),
    animatedCellCount: details.where((cell) => cell.isAnimated).length,
  );
}

ProjectPathPreset? _resolveBasePathPreset({
  required ProjectManifest manifest,
  required String basePathPresetId,
}) {
  final matches = manifest.pathPresets
      .where((preset) => preset.id == basePathPresetId)
      .toList(growable: false);
  if (matches.length != 1) {
    return null;
  }
  return matches.single;
}

String _savedCellLabel(int index) {
  return String.fromCharCode('A'.codeUnitAt(0) + index);
}

class _SavedPresetCenterDetail extends StatelessWidget {
  const _SavedPresetCenterDetail({
    required this.detail,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
  });

  final _SavedPathPatternDetail detail;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;

  @override
  Widget build(BuildContext context) {
    final preset = detail.preset;
    final baseName = detail.basePathPreset?.name ?? 'Introuvable';
    final baseTilesetId = detail.basePathPreset?.tilesetId.trim();
    final baseTilesetLabel = baseTilesetId == null || baseTilesetId.isEmpty
        ? 'Non disponible'
        : baseTilesetId;
    return _SectionCard(
      title: 'PathPattern sauvegardé',
      icon: CupertinoIcons.eye,
      trailing: const _StatusChip(
        label: 'Présent dans le projet',
        color: PathStudioTheme.success,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoTile(label: 'Nom', value: preset.name),
              _InfoTile(label: 'ID', value: preset.id),
              _InfoTile(label: 'Base path', value: baseName),
              _InfoTile(
                label: 'Taille du centre',
                value:
                    '${preset.centerPattern.size.width}×${preset.centerPattern.size.height}',
              ),
              _InfoTile(label: 'Cellules', value: '${detail.cells.length}'),
              _InfoTile(label: 'Frames', value: '${detail.centerFrameCount}'),
              _InfoTile(
                label: 'Cellules animées',
                value: '${detail.animatedCellCount}',
              ),
              _InfoTile(
                label: 'Transparent color',
                value: preset.transparentColor?.toHexRgb() ?? 'Aucune',
              ),
              _InfoTile(label: 'Tileset de base', value: baseTilesetLabel),
            ],
          ),
          const SizedBox(height: 14),
          _SavedPresetCellGrid(
            detail: detail,
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
          ),
        ],
      ),
    );
  }
}

class _SavedPresetCellGrid extends StatelessWidget {
  const _SavedPresetCellGrid({
    required this.detail,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
  });

  final _SavedPathPatternDetail detail;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;

  @override
  Widget build(BuildContext context) {
    final byCoord = <String, _SavedPathPatternCellDetail>{};
    for (final cell in detail.cells) {
      byCoord['${cell.localX},${cell.localY}'] = cell;
    }
    final rows = <Widget>[];
    for (var y = 0; y < detail.preset.centerPattern.size.height; y += 1) {
      final rowCells = <Widget>[];
      for (var x = 0; x < detail.preset.centerPattern.size.width; x += 1) {
        final cell = byCoord['$x,$y'];
        if (cell != null) {
          rowCells.add(
            _SavedPresetCellCard(
              detail: cell,
              tilesets: tilesets,
              settings: settings,
              projectRootPath: projectRootPath,
            ),
          );
        }
      }
      rows.add(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: rowCells),
        ),
      );
      rows.add(const SizedBox(height: 8));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class _SavedPresetCellCard extends StatelessWidget {
  const _SavedPresetCellCard({
    required this.detail,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
  });

  final _SavedPathPatternCellDetail detail;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PathStudioTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PathStudioTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.label,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pos ${detail.localX},${detail.localY}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _SavedPresetCellThumbnail(
            detail: detail,
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
          ),
          const SizedBox(height: 8),
          Text(
            detail.isAnimated
                ? 'Anime - ${detail.frameCount} frames'
                : 'Statique - ${detail.frameCount} frame',
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Tuile ${detail.primarySourceLabel}',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPresetCellThumbnail extends StatelessWidget {
  const _SavedPresetCellThumbnail({
    required this.detail,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
  });

  final _SavedPathPatternCellDetail detail;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;

  @override
  Widget build(BuildContext context) {
    final keyLabel = Key('path-studio-saved-cell-thumbnail-${detail.label}');
    final tile = detail.primaryTile;
    if (tile == null) {
      return _SavedPresetThumbnailFallback(
        key: keyLabel,
        sourceLabel: detail.primarySourceLabel,
      );
    }
    final fallback = _SavedPresetThumbnailFallback(
      sourceLabel: detail.primarySourceLabel,
    );
    return SizedBox(
      key: keyLabel,
      width: 46,
      height: 46,
      child: PathStudioTileSpritePreview(
        projectRootPath: projectRootPath,
        tilesets: tilesets,
        settings: settings,
        tile: tile,
        fallback: fallback,
        thumbnailKey:
            Key('path-studio-saved-cell-thumbnail-image-${detail.label}'),
      ),
    );
  }
}

class _SavedPresetThumbnailFallback extends StatelessWidget {
  const _SavedPresetThumbnailFallback({
    super.key,
    required this.sourceLabel,
  });

  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: PathStudioTheme.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: PathStudioTheme.success.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        sourceLabel,
        style: const TextStyle(
          color: PathStudioTheme.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
```

### 14.6 Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index 5a694d4e..5862348a 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -13,6 +13,8 @@ import 'path_studio_save_plan.dart';
 import 'path_studio_theme.dart';
 import 'path_studio_tileset_image_picker.dart';
 
+part 'path_studio_saved_preset_detail.dart';
+
 /// Workspace branché au shell global de l'éditeur.
@@ -3144,112 +3177,6 @@ class _SelectedSummary extends StatelessWidget {
   }
 }
 
-class _CenterPatternPlaceholder extends StatelessWidget {
-  const _CenterPatternPlaceholder({required this.card});
-
-  final PathPatternPresetCardModel card;
-
-  @override
-  Widget build(BuildContext context) {
-    return _SectionCard(
-      title: 'Motif du centre',
-      icon: CupertinoIcons.square_grid_2x2,
-      child: Row(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          _MiniPatternGrid(card: card),
-          const SizedBox(width: 18),
-          const Expanded(
-            child: Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Text(
-                  'Éditeur read-only',
-                  style: TextStyle(
-                    color: PathStudioTheme.textPrimary,
-                    fontSize: 15,
-                    fontWeight: FontWeight.w800,
-                  ),
-                ),
-                SizedBox(height: 8),
-                Text(
-                  'L’édition 1×1 / 2×2 arrivera au lot 14. Cette zone pose seulement la structure du futur espace de travail, sans drag & drop ni génération PNG.',
-                  style: TextStyle(
-                    color: PathStudioTheme.textSecondary,
-                    fontSize: 13,
-                    height: 1.4,
-                  ),
-                ),
-              ],
-            ),
-          ),
-        ],
-      ),
-    );
-  }
-}
-
-class _MiniPatternGrid extends StatelessWidget {
-  const _MiniPatternGrid({required this.card});
-
-  final PathPatternPresetCardModel card;
-
-  @override
-  Widget build(BuildContext context) {
-    final rows = <Widget>[];
-    var labelCode = 'A'.codeUnitAt(0);
-    for (var y = 0; y < card.centerHeight; y += 1) {
-      final cells = <Widget>[];
-      for (var x = 0; x < card.centerWidth; x += 1) {
-        cells.add(_PatternCell(label: String.fromCharCode(labelCode)));
-        labelCode += 1;
-      }
-      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
-    }
-    return Container(
-      padding: const EdgeInsets.all(10),
-      decoration: PathStudioTheme.subtleDecoration(
-        color: PathStudioTheme.backgroundAlt,
-      ),
-      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
-    );
-  }
-}
-
-class _PatternCell extends StatelessWidget {
-  const _PatternCell({required this.label});
-
-  final String label;
-
-  @override
-  Widget build(BuildContext context) {
-    return Container(
-      width: 54,
-      height: 54,
-      margin: const EdgeInsets.all(4),
-      decoration: BoxDecoration(
-        color: Color.lerp(
-          PathStudioTheme.surfaceStrong,
-          PathStudioTheme.accentCyan,
-          0.18,
-        ),
-        borderRadius: BorderRadius.circular(12),
-        border: Border.all(
-            color: PathStudioTheme.accentCyan.withValues(alpha: 0.5)),
-      ),
-      alignment: Alignment.center,
-      child: Text(
-        label,
-        style: const TextStyle(
-          color: PathStudioTheme.textPrimary,
-          fontSize: 16,
-          fontWeight: FontWeight.w900,
-        ),
-      ),
-    );
-  }
-}
-
 class _DiagnosticsCard extends StatelessWidget {
   const _DiagnosticsCard({required this.card});
```

### 14.7 Sorties tests (extraits consolidés des commandes exécutées)

```text
PathStudioPanel: 28 tests passés (ligne finale: All tests passed!)
PathStudioTilesetImagePicker: 5 tests passés (ligne finale: All tests passed!)
PathStudioNewPathDraft: 12 tests passés (ligne finale: All tests passed!)
PathStudioSavePlan: 7 tests passés (ligne finale: All tests passed!)
Suite test/path_pattern/: ligne finale exacte "All tests passed!"
EditorShellPage smoke: 7 tests passés (ligne finale: All tests passed!)
TopToolbar: 5 tests passés (ligne finale: All tests passed!)
Editor selectors: 8 tests passés (ligne finale: All tests passed!)
map_core ciblé: 14 + 8 + 9 + 6 + 5 + 17 + 6 tests passés (lignes finales: All tests passed!)
```

### 14.8 Sortie analyze ciblée

```text
Analyzing 2 items...
No issues found! (ran in 2.5s)
```

## 15. Auto-review

- Objectif respecté: extraction maintenance uniquement, sans nouvelle feature.
- Risque principal: régression visuelle liée au découpage; couvert par les tests widget existants du Lot 22.
- Limite: le dépôt contient encore des changements pré-existants du Lot 22 non inclus dans ce lot (conservés tels quels).

## 16. Critique du prompt

Le prompt est cohérent et borné.  
Point sensible: exigence de preuve exhaustive très volumineuse alors que le dépôt était déjà dirty avant Lot 23; la séparation “diff du lot courant” vs “diff global du working tree” doit être explicitée pour éviter l’ambiguïté.

## 17. Conclusion

Le Lot 23 est implémenté: le détail read-only sauvegardé est extrait hors de `path_studio_panel.dart` dans un fichier dédié, le panel est allégé, et les comportements utilisateur du Lot 22 sont conservés avec validations vertes.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun map_core modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Le détail read-only sauvegardé a été extrait.
- [x] path_studio_panel.dart a été allégé.
- [x] Aucun comportement utilisateur n’a changé.
- [x] Les thumbnails sauvegardées fonctionnent encore.
- [x] Le fallback image absente fonctionne encore.
- [x] Le diagnostic base manquante fonctionne encore.
- [x] Nouveau chemin reste non sauvegardable.
- [x] Save legacy post-Lot 21 reste intact.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
