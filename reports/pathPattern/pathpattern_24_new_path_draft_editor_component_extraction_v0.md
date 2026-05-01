# Lot PathPattern-24 — New Path Draft Editor Component Extraction V0

## 1. Résumé exécutif

Le flux UI **Nouveau chemin** a été extrait de `path_studio_panel.dart` vers `path_studio_new_path_editor.dart` sans ajout de feature ni changement de comportement utilisateur.  
L’orchestration globale (état panel, sélection globale, callbacks save legacy, coordination draft/preset) reste dans `path_studio_panel.dart`.

## 2. Audit initial

Commandes exécutées:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_23_saved_pathpattern_detail_component_extraction_v0.md
```

Sortie audit:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_23_saved_pathpattern_detail_component_extraction_v0.md
```

Inspection ciblée réalisée:

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart`

Constats:

- Le bloc Nouveau chemin encore présent dans `path_studio_panel.dart` comprenait:
  - workspace center (`_NewPathCenterWorkspace`),
  - grille/cellules/thumbnail,
  - picker image-backed + fallback logique,
  - diagnostics + carte de statut save non disponible,
  - inspector Nouveau chemin + selector tileset.
- Les helpers UI dédiés au draft Nouveau chemin (`_selectedTileset*`, `_newPathDraftIssue*`, `_hasSelectedTileset`) étaient aussi dans le panel.
- Les méthodes d’état global (`_createNewPathDraft`, `_renameNewPathDraft`, `_resizeNewPathDraft`, `_selectNewPathDraftTileset`, `_assignNewPathDraftTile`, etc.) doivent rester dans le panel.
- Les tests existants couvrent déjà les comportements à préserver.

## 3. Problème de maintenabilité constaté

`path_studio_panel.dart` combinait orchestration globale et implémentation détaillée du flow Nouveau chemin, ce qui alourdissait fortement la lecture et l’évolution locale.

## 4. Décisions d’extraction

- Extraction ciblée des composants Nouveau chemin vers un fichier dédié.
- Conservation de toutes les clés de widgets, labels et comportements existants.
- Aucune modification de logique métier (`PathStudioNewPathDraft`, save plans, `map_core` inchangés).

## 5. Choix part/part of ou import classique

Choix retenu: **part / part of**.

Justification:

- Le bloc extrait dépend de nombreux symboles privés internes déjà présents dans `path_studio_panel.dart` (`_SectionCard`, `_StatusChip`, `_InspectorRow`, `_SaveIssueList`, etc.).
- `part/part of` permet une extraction massive sans rendre publics des symboles internes ni créer une API artificielle.
- C’est cohérent avec l’approche du Lot 23.

## 6. Fichiers créés

- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`
- `reports/pathPattern/pathpattern_24_new_path_draft_editor_component_extraction_v0.md`

## 7. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

## 8. Fichiers supprimés

- Aucun.

## 9. Comportements préservés

- Bouton `Nouveau chemin` inchangé.
- Création d’un brouillon sans base legacy inchangée.
- Flux utilisable sans path legacy inchangé.
- Sélection de tileset inchangée.
- Cas “aucun tileset” inchangé.
- Picker image-backed inchangé.
- Fallback logique image absente inchangé.
- Assignation cellule 1×1 inchangée.
- Assignation cellules 2×2 inchangée.
- Remplacement/clear de cellule inchangés.
- Changement de tileset purge des cellules inchangé.
- Resize 1×1→2×2 et 2×2→1×1 (conservation A) inchangé.
- Thumbnail carrée inchangée.
- Wording “Configuration des bords à venir” inchangé.
- Nouveau chemin non sauvegardable inchangé.
- Aucun callback save appelé pour Nouveau chemin.
- Save legacy post-Lot 21 inchangé.
- Détail read-only sauvegardé post-Lot 23 inchangé.

## 10. Tests exécutés

Depuis `packages/map_editor`:

```bash
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
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

## 11. Résultats des validations

- Tous les tests ciblés passent.
- Régressions `map_editor` demandées passent.
- Régressions `map_core` demandées passent.
- `flutter analyze lib/src/features/path_studio test/path_pattern` passe.

Lignes finales de référence:

- `test/path_pattern/path_studio_panel_test.dart`: `All tests passed!`
- `test/path_pattern/path_studio_new_path_draft_test.dart`: `All tests passed!`
- `test/path_pattern/path_studio_tileset_image_picker_test.dart`: `All tests passed!`
- `test/path_pattern/path_studio_save_plan_test.dart`: `All tests passed!`
- `test/path_pattern/`: `All tests passed!`
- `test/editor_shell_page_smoke_test.dart`: `All tests passed!`
- `test/top_toolbar_test.dart`: `All tests passed!`
- `test/editor_selectors_test.dart`: `All tests passed!`
- `map_core` (7 commandes ciblées): `All tests passed!` pour chaque commande.
- Analyze: `No issues found!`

## 12. Couverture des comportements surveillés explicitement

- `new path draft can select a project tileset`  
  couvert par test: `PathStudioPanel new path draft can select a project tileset`
- `image-backed tileset picker assigns the active cell`  
  couvert par test: `PathStudioPanel image-backed tileset picker assigns the active cell`
- `image-backed picker fills all 2x2 cells and supports clear`  
  couvert par test: `PathStudioPanel image-backed picker fills all 2x2 cells and supports clear`
- `changing tileset clears configured center cells`  
  couvert par test: `PathStudioPanel changing tileset clears configured center cells`
- `new path save status explains future border/corner/junction step`  
  couvert par test: `PathStudioPanel new path save status explains missing path variant mapping`
- `new path with complete center stays blocked for save`  
  couvert par test: `PathStudioPanel new path with complete center stays blocked for save`
- `legacy save flow still works`  
  couvert par test: `PathStudioPanel legacy save updates parent manifest and panel exits draft state`
- `saved preset detail still works`  
  couvert par tests:
  - `PathStudioPanel selected saved preset shows read-only center and inspector detail`
  - `PathStudioPanel saved preset uses image-backed thumbnail when tileset exists`
  - `PathStudioPanel saved preset missing image falls back to readable source label`
  - `PathStudioPanel saved preset with missing base path shows diagnostic`

## 13. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
```

## 14. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 1174 +-------------------
 1 file changed, 1 insertion(+), 1173 deletions(-)
```

## 15. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
```

## 16. Evidence Pack

### 16.1 git status initial

```text
(aucune modification listée)
```

### 16.2 git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
```

### 16.3 git diff --stat final

```text
 .../features/path_studio/path_studio_panel.dart    | 1174 +-------------------
 1 file changed, 1 insertion(+), 1173 deletions(-)
```

### 16.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
```

### 16.5 Contenu complet des fichiers créés

#### `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`

```dart
part of 'path_studio_panel.dart';

class _NewPathCenterWorkspace extends StatelessWidget {
  const _NewPathCenterWorkspace({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.savePlan,
    required this.onSizeChanged,
    required this.onCellSelected,
    required this.onTileSelected,
    required this.onCellCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final PathStudioNewPathSavePlan savePlan;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NewPathBanner(),
          const SizedBox(height: 14),
          _NewPathWorkflowSteps(hasTileset: _hasSelectedTileset(draft)),
          const SizedBox(height: 14),
          _NewPathSummary(tilesets: tilesets, draft: draft),
          const SizedBox(height: 14),
          _NewPathCenterPatternEditor(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onSizeChanged: onSizeChanged,
            onCellSelected: onCellSelected,
            onTileSelected: onTileSelected,
            onCellCleared: onCellCleared,
          ),
          const SizedBox(height: 14),
          _NewPathDiagnosticsCard(draft: draft),
          const SizedBox(height: 14),
          _NewPathSaveStatusCard(plan: savePlan),
        ],
      ),
    );
  }
}

class _NewPathBanner extends StatelessWidget {
  const _NewPathBanner();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Brouillon nouveau chemin',
      icon: CupertinoIcons.pencil_outline,
      trailing: _StatusChip(
        label: 'Non sauvegardé',
        color: PathStudioTheme.warning,
      ),
      child: Text(
        'Ce brouillon représente un nouveau chemin complet. La sélection du tileset et la configuration des bords arriveront dans un lot futur.',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NewPathWorkflowSteps extends StatelessWidget {
  const _NewPathWorkflowSteps({required this.hasTileset});

  final bool hasTileset;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Création guidée',
      icon: CupertinoIcons.list_bullet,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          const _StepPill(index: 1, label: 'Nouveau chemin', active: true),
          const _StepArrow(),
          const _StepPill(index: 2, label: 'Motif du centre', active: true),
          const _StepArrow(),
          _StepPill(
            index: 3,
            label: 'Tileset',
            active: false,
            complete: hasTileset,
          ),
        ],
      ),
    );
  }
}

class _NewPathSummary extends StatelessWidget {
  const _NewPathSummary({
    required this.tilesets,
    required this.draft,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;

  @override
  Widget build(BuildContext context) {
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId) ??
            'À choisir';
    return _SectionCard(
      title: 'Résumé du nouveau chemin',
      icon: CupertinoIcons.doc_text,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: draft.name),
          _InfoTile(label: 'Tileset', value: tilesetLabel),
          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
          _InfoTile(
            label: 'Configurées',
            value: '${draft.configuredCellCount}/${draft.centerCellCount}',
          ),
          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
        ],
      ),
    );
  }
}

class _NewPathCenterPatternEditor extends StatelessWidget {
  const _NewPathCenterPatternEditor({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
    required this.onTileSelected,
    required this.onCellCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chaque cellule existe déjà dans le futur motif, mais son contenu visuel n’est pas encore choisi.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoSlidingSegmentedControl<String>(
            key: const Key('path-studio-new-path-size-control'),
            groupValue: draft.centerPatternLabel,
            onValueChanged: (value) {
              if (value == '1×1') {
                onSizeChanged(1, 1);
              } else if (value == '2×2') {
                onSizeChanged(2, 2);
              }
            },
            children: const {
              '1×1': Padding(
                key: Key('path-studio-new-path-size-1x1'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('1×1'),
              ),
              '2×2': Padding(
                key: Key('path-studio-new-path-size-2x2'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('2×2'),
              ),
            },
          ),
          const SizedBox(height: 18),
          _NewPathPatternGrid(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _NewPathSelectedCellDetails(
            draft: draft,
            onCellCleared: onCellCleared,
          ),
          const SizedBox(height: 14),
          _NewPathTilePickerPanel(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onTileSelected: onTileSelected,
          ),
        ],
      ),
    );
  }
}

class _NewPathPatternGrid extends StatelessWidget {
  const _NewPathPatternGrid({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onCellSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var y = 0; y < draft.centerHeight; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < draft.centerWidth; x += 1) {
        final cell = draft.cells.firstWhere(
          (candidate) => candidate.localX == x && candidate.localY == y,
        );
        cells.add(
          _NewPathPatternCell(
            key: Key('path-studio-new-path-cell-$x-$y'),
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            cell: cell,
            selected: draft.selectedCellX == x && draft.selectedCellY == y,
            onTap: () => onCellSelected(x, y),
          ),
        );
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _NewPathPatternCell extends StatelessWidget {
  const _NewPathPatternCell({
    super.key,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraftCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = cell.tile;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 136,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.lerp(
            PathStudioTheme.surfaceStrong,
            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
            selected ? 0.32 : 0.16,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cell.label,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (tile != null)
              _TilePreviewBadge(
                cellLabel: cell.label,
                tilesets: tilesets,
                settings: settings,
                projectRootPath: projectRootPath,
                tile: tile,
              )
            else
              _EmptyTileBadge(cellLabel: cell.label),
            const SizedBox(height: 6),
            Text(
              tile == null ? 'À configurer' : 'Configurée',
              style: TextStyle(
                color: tile == null
                    ? PathStudioTheme.textSecondary
                    : PathStudioTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              tile == null ? 'Aucune tuile' : 'Tuile ${tile.coordinateLabel}',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPathSelectedCellDetails extends StatelessWidget {
  const _NewPathSelectedCellDetails({
    required this.draft,
    required this.onCellCleared,
  });

  final PathStudioNewPathDraft draft;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    final cell = draft.selectedCell;
    final tile = cell.tile;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cellule ${cell.label}',
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Position ${cell.localX},${cell.localY}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tile == null
                ? 'Aucune tuile configurée pour cette cellule.'
                : 'Tuile ${tile.coordinateLabel} assignée depuis ${tile.tilesetId}.',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (tile != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                key: const Key('path-studio-new-path-clear-selected-cell'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                color: PathStudioTheme.error.withValues(alpha: 0.16),
                onPressed: () => onCellCleared(cell.localX, cell.localY),
                child: const Text(
                  'Effacer la cellule',
                  style: TextStyle(
                    color: PathStudioTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TilePreviewBadge extends StatelessWidget {
  const _TilePreviewBadge({
    required this.cellLabel,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.tile,
  });

  final String cellLabel;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraftTile tile;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        color: PathStudioTheme.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: PathStudioTheme.success.withValues(alpha: 0.5)),
      ),
    );
    return SizedBox(
      key: Key('path-studio-cell-thumbnail-$cellLabel'),
      width: 46,
      height: 46,
      child: Stack(
        children: [
          Positioned.fill(
            child: PathStudioTileSpritePreview(
              projectRootPath: projectRootPath,
              tilesets: tilesets,
              settings: settings,
              tile: tile,
              fallback: fallback,
              thumbnailKey: Key('path-studio-cell-thumbnail-image-$cellLabel'),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              key: Key('path-studio-cell-thumbnail-label-$cellLabel'),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: PathStudioTheme.background.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tile.coordinateLabel,
                style: const TextStyle(
                  color: PathStudioTheme.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTileBadge extends StatelessWidget {
  const _EmptyTileBadge({required this.cellLabel});

  final String cellLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('path-studio-cell-thumbnail-$cellLabel'),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: PathStudioTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PathStudioTheme.borderStrong.withValues(alpha: 0.65),
        ),
      ),
      alignment: Alignment.center,
      child: const MacosIcon(
        CupertinoIcons.square,
        color: PathStudioTheme.textMuted,
        size: 14,
      ),
    );
  }
}

class _NewPathTilePickerPanel extends StatelessWidget {
  const _NewPathTilePickerPanel({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onTileSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int sourceX, int sourceY) onTileSelected;

  @override
  Widget build(BuildContext context) {
    final selectedTileset = _selectedTileset(
      tilesets: tilesets,
      tilesetId: draft.tilesetId,
    );
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
    if (tilesetLabel == null || selectedTileset == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: PathStudioTheme.subtleDecoration(
          color: PathStudioTheme.backgroundAlt,
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MacosIcon(
              CupertinoIcons.square_grid_2x2,
              color: PathStudioTheme.textMuted,
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez d’abord un tileset',
                    style: TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Le picker de tuiles s’activera ensuite pour la cellule sélectionnée.',
                    style: TextStyle(
                      color: PathStudioTheme.textSecondary,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final selectedCell = draft.selectedCell;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MacosIcon(
                CupertinoIcons.square_grid_3x2,
                color: PathStudioTheme.accentCyan,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Tileset: $tilesetLabel',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sélectionnez une tuile pour la cellule ${selectedCell.label}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          PathStudioImageBackedTilesetPicker(
            projectRootPath: projectRootPath,
            tileset: selectedTileset,
            settings: settings,
            activeCell: selectedCell,
            onTileSelected: (source) => onTileSelected(source.x, source.y),
            fallbackBuilder: (context, result) {
              return _LogicalNewPathTileGrid(
                draft: draft,
                selectedCell: selectedCell,
                onTileSelected: onTileSelected,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogicalNewPathTileGrid extends StatelessWidget {
  const _LogicalNewPathTileGrid({
    required this.draft,
    required this.selectedCell,
    required this.onTileSelected,
  });

  final PathStudioNewPathDraft draft;
  final PathStudioNewPathDraftCell selectedCell;
  final void Function(int sourceX, int sourceY) onTileSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var y = 0; y < 4; y += 1)
              for (var x = 0; x < 8; x += 1)
                _NewPathTileButton(
                  key: Key('path-studio-new-path-tile-$x-$y'),
                  sourceX: x,
                  sourceY: y,
                  selected: selectedCell.tile?.sourceX == x &&
                      selectedCell.tile?.sourceY == y &&
                      selectedCell.tile?.tilesetId == draft.tilesetId,
                  onTap: () => onTileSelected(x, y),
                ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Fallback V0 : les coordonnées sont enregistrées dans le brouillon quand l’image tileset ne peut pas être chargée.',
          style: TextStyle(
            color: PathStudioTheme.textMuted,
            fontSize: 10.5,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NewPathTileButton extends StatelessWidget {
  const _NewPathTileButton({
    super.key,
    required this.sourceX,
    required this.sourceY,
    required this.selected,
    required this.onTap,
  });

  final int sourceX;
  final int sourceY;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? PathStudioTheme.accentHover : PathStudioTheme.border;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                PathStudioTheme.surfaceStrong,
                PathStudioTheme.accentCyan,
                selected ? 0.3 : 0.12,
              )!,
              Color.lerp(
                PathStudioTheme.backgroundAlt,
                PathStudioTheme.accent,
                selected ? 0.26 : 0.08,
              )!,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: selected ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '$sourceX,$sourceY',
          style: TextStyle(
            color: selected
                ? PathStudioTheme.textPrimary
                : PathStudioTheme.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NewPathDiagnosticsCard extends StatelessWidget {
  const _NewPathDiagnosticsCard({required this.draft});

  final PathStudioNewPathDraft draft;

  @override
  Widget build(BuildContext context) {
    final issues = draft.issues;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur',
              message: 'Toutes les cellules requises ont une tuile V0.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.info_circle_fill,
                        color: issue ==
                                PathStudioNewPathDraftIssueCode.nameRequired
                            ? PathStudioTheme.warning
                            : PathStudioTheme.accentCyan,
                        title: _newPathDraftIssueLabel(issue),
                        message: _newPathDraftIssueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _NewPathSaveStatusCard extends StatelessWidget {
  const _NewPathSaveStatusCard({required this.plan});

  final PathStudioNewPathSavePlan plan;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const Key('path-studio-save-status-card'),
      title: 'Sauvegarde',
      icon: CupertinoIcons.floppy_disk,
      trailing: const _StatusChip(
        label: 'Non sauvegardable',
        color: PathStudioTheme.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _InfoTile(
                label: 'État',
                value: 'Brouillon de nouveau chemin',
              ),
              _InfoTile(
                label: 'Centre',
                value: plan.isCenterReady ? 'Centre prêt' : 'Centre incomplet',
              ),
              const _InfoTile(
                label: 'Sauvegarde',
                value: 'Sauvegarde non disponible dans ce lot',
              ),
              _InfoTile(
                label: 'Pattern proposé',
                value: plan.proposedPathPatternPresetId,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Configuration des bords à venir',
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Le centre du chemin est prêt.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'La configuration des bords, coins et jonctions arrivera dans un prochain lot.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Pour l’instant, seul le flux "Depuis un path existant" peut être sauvegardé.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SaveIssueList(issues: plan.issues),
        ],
      ),
    );
  }
}

class _NewPathInspector extends StatelessWidget {
  const _NewPathInspector({
    required this.tilesets,
    required this.draft,
    required this.onNameChanged,
    required this.onTilesetChanged,
    required this.onSizeChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onTilesetChanged;
  final void Function(int width, int height) onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId) ??
            'À choisir';
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Propriétés du nouveau chemin',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _StatusChip(
              label: 'Brouillon non sauvegardé',
              color: PathStudioTheme.warning,
            ),
            const SizedBox(height: 14),
            const _InspectorLabel('Nom'),
            CupertinoTextField(
              key: const Key('path-studio-new-path-name-field'),
              placeholder: draft.name,
              onChanged: onNameChanged,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              placeholderStyle: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: PathStudioTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PathStudioTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Tileset'),
            _NewPathTilesetSelector(
              tilesets: tilesets,
              draft: draft,
              onTilesetChanged: onTilesetChanged,
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Taille du centre'),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: draft.centerPatternLabel,
              onValueChanged: (value) {
                if (value == '1×1') {
                  onSizeChanged(1, 1);
                } else if (value == '2×2') {
                  onSizeChanged(2, 2);
                }
              },
              children: const {
                '1×1': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('1×1'),
                ),
                '2×2': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('2×2'),
                ),
              },
            ),
            const SizedBox(height: 14),
            _InspectorRow(label: 'ID temporaire', value: draft.id),
            _InspectorRow(label: 'Tileset', value: tilesetLabel),
            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
            _InspectorRow(
              label: 'Cellules configurées',
              value: '${draft.configuredCellCount}/${draft.centerCellCount}',
            ),
            _InspectorRow(
              label: 'Cellule sélectionnée',
              value: 'Cellule ${draft.selectedCell.label}',
            ),
            _InspectorRow(
              label: 'Tuile sélectionnée',
              value: draft.selectedCell.tile == null
                  ? 'Aucune tuile'
                  : 'Tuile ${draft.selectedCell.tile!.coordinateLabel}',
            ),
            const _InspectorRow(
              label: 'État',
              value: 'Brouillon non sauvegardé',
            ),
            const _InspectorRow(
              label: 'Sauvegarde',
              value: 'Non disponible dans ce lot',
            ),
            const _InspectorRow(
              label: 'Prochaine étape',
              value: 'Choisir un tileset et définir les tuiles',
            ),
            const SizedBox(height: 14),
            _NewPathDiagnosticsCard(draft: draft),
          ],
        ),
      ),
    );
  }
}

class _NewPathTilesetSelector extends StatelessWidget {
  const _NewPathTilesetSelector({
    required this.tilesets,
    required this.draft,
    required this.onTilesetChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;
  final ValueChanged<String> onTilesetChanged;

  @override
  Widget build(BuildContext context) {
    if (tilesets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PathStudioTheme.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À choisir',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Aucun tileset disponible dans le projet',
              style: TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final selectedId = tilesets.any((tileset) => tileset.id == draft.tilesetId)
        ? draft.tilesetId!
        : '';
    return MacosPopupButton<String>(
      key: const Key('path-studio-new-path-tileset-popup'),
      value: selectedId,
      onChanged: (value) {
        if (value != null) {
          onTilesetChanged(value);
        }
      },
      items: [
        const MacosPopupMenuItem<String>(
          value: '',
          child: Text('À choisir'),
        ),
        for (final tileset in tilesets)
          MacosPopupMenuItem<String>(
            value: tileset.id,
            child: SizedBox(
              width: 220,
              child: Text(
                _tilesetLabel(tileset),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

bool _hasSelectedTileset(PathStudioNewPathDraft draft) {
  return draft.tilesetId != null && draft.tilesetId!.isNotEmpty;
}

String _tilesetLabel(ProjectTilesetEntry tileset) {
  return '${tileset.name} (${tileset.id})';
}

String? _selectedTilesetLabel({
  required List<ProjectTilesetEntry> tilesets,
  required String? tilesetId,
}) {
  if (tilesetId == null || tilesetId.isEmpty) {
    return null;
  }
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return _tilesetLabel(tileset);
    }
  }
  return tilesetId;
}

ProjectTilesetEntry? _selectedTileset({
  required List<ProjectTilesetEntry> tilesets,
  required String? tilesetId,
}) {
  if (tilesetId == null || tilesetId.isEmpty) {
    return null;
  }
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return tileset;
    }
  }
  return null;
}

String _newPathDraftIssueLabel(PathStudioNewPathDraftIssueCode issue) {
  return switch (issue) {
    PathStudioNewPathDraftIssueCode.nameRequired => 'Nom requis',
    PathStudioNewPathDraftIssueCode.tilesetNotConfigured => 'Tileset à choisir',
    PathStudioNewPathDraftIssueCode.cellsNotConfigured =>
      'Cellules à configurer',
  };
}

String _newPathDraftIssueDescription(PathStudioNewPathDraftIssueCode issue) {
  return switch (issue) {
    PathStudioNewPathDraftIssueCode.nameRequired =>
      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
    PathStudioNewPathDraftIssueCode.tilesetNotConfigured =>
      'Sélectionnez un tileset du projet pour continuer le brouillon.',
    PathStudioNewPathDraftIssueCode.cellsNotConfigured =>
      'Les cellules existent déjà mais aucune tuile n’est encore choisie.',
  };
}
```

### 16.6 Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index 5862348a..fc133f10 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -14,6 +14,7 @@ import 'path_studio_theme.dart';
 import 'path_studio_tileset_image_picker.dart';
 
 part 'path_studio_saved_preset_detail.dart';
+part 'path_studio_new_path_editor.dart';
```

```text
Le diff complet de `path_studio_panel.dart` correspond au retrait des blocs Nouveau chemin déplacés (1173 suppressions) et à l’ajout d’une ligne `part` (1 insertion).
```

### 16.7 Sorties complètes des tests ciblés principaux

```text
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
...
00:05 +28: All tests passed!

flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
...
00:00 +12: All tests passed!

flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
...
00:00 +5: All tests passed!

flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart
...
00:00 +7: All tests passed!
```

### 16.8 Ligne finale exacte des grosses régressions

```text
flutter test test/path_pattern/ --reporter expanded
...
00:06 +105: All tests passed!

flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
...
00:02 +7: All tests passed!

flutter test test/top_toolbar_test.dart --reporter expanded
...
00:00 +5: All tests passed!

flutter test test/editor_selectors_test.dart --reporter expanded
...
00:00 +8: All tests passed!
```

### 16.9 Sortie analyze ciblée

```text
Analyzing 2 items...
No issues found! (ran in 2.2s)
```

## 17. Auto-review

- Scope respecté: extraction maintenance only.
- Risque de régression principal: wiring UI Nouveau chemin; mitigé par tests widget existants couvrant tileset/picker/2x2/save blocked.
- Aucun changement map_core, ProjectManifest, codec, persistence.

## 18. Critique du prompt

Prompt clair, borné, et aligné avec les lots précédents.  
La contrainte “evidence pack exhaustif” est exigeante pour les gros diffs; l’approche la plus robuste reste de fournir le fichier créé complet et les commandes/outputs de validation exacts.

## 19. Conclusion

Le Lot 24 est terminé: le flux Nouveau chemin est extrait hors du panel dans `path_studio_new_path_editor.dart`, `path_studio_panel.dart` est allégé, aucun comportement n’a été modifié, et l’ensemble des validations demandées est vert.

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
- [x] Le flux Nouveau chemin a été extrait.
- [x] path_studio_panel.dart a été allégé.
- [x] Aucun comportement utilisateur n’a changé.
- [x] Le bouton Nouveau chemin fonctionne encore.
- [x] La sélection tileset fonctionne encore.
- [x] Le picker image-backed fonctionne encore.
- [x] Le fallback logique fonctionne encore.
- [x] Les cellules 1×1 / 2×2 fonctionnent encore.
- [x] Les thumbnails du nouveau chemin fonctionnent encore.
- [x] Nouveau chemin reste non sauvegardable.
- [x] Save legacy post-Lot 21 reste intact.
- [x] Détail read-only sauvegardé post-Lot 23 reste intact.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
