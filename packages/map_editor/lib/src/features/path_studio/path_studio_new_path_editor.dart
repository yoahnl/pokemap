part of 'path_studio_panel.dart';

class _NewPathCenterWorkspace extends StatelessWidget {
  const _NewPathCenterWorkspace({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.savePlan,
    required this.hasSaveCallback,
    required this.onSizeChanged,
    required this.onSurfaceKindChanged,
    required this.onCellSelected,
    required this.onVariantSelected,
    required this.onTileSelected,
    required this.onCenterFrameSelected,
    required this.onCenterFrameAdded,
    required this.onCenterFrameRemoved,
    required this.onCenterFrameDurationChanged,
    required this.onCellCleared,
    required this.onVariantCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final PathStudioNewPathBuildPlan savePlan;
  final bool hasSaveCallback;
  final void Function(int width, int height) onSizeChanged;
  final ValueChanged<PathSurfaceKind> onSurfaceKindChanged;
  final void Function(int localX, int localY) onCellSelected;
  final ValueChanged<TerrainPathVariant> onVariantSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final ValueChanged<int> onCenterFrameSelected;
  final VoidCallback onCenterFrameAdded;
  final ValueChanged<int> onCenterFrameRemoved;
  final void Function(int frameIndex, int durationMs) onCenterFrameDurationChanged;
  final void Function(int localX, int localY) onCellCleared;
  final ValueChanged<TerrainPathVariant> onVariantCleared;

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
          _NewPathSurfaceKindSection(
            draft: draft,
            onSurfaceKindChanged: onSurfaceKindChanged,
          ),
          const SizedBox(height: 14),
          _NewPathCenterPatternEditor(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onSizeChanged: onSizeChanged,
            onCellSelected: onCellSelected,
            onVariantSelected: onVariantSelected,
            onTileSelected: onTileSelected,
            onCenterFrameSelected: onCenterFrameSelected,
            onCenterFrameAdded: onCenterFrameAdded,
            onCenterFrameRemoved: onCenterFrameRemoved,
            onCenterFrameDurationChanged: onCenterFrameDurationChanged,
            onCellCleared: onCellCleared,
            onVariantCleared: onVariantCleared,
          ),
          const SizedBox(height: 14),
          _NewPathDiagnosticsCard(plan: savePlan),
          const SizedBox(height: 14),
          _NewPathSaveStatusCard(
            plan: savePlan,
            hasSaveCallback: hasSaveCallback,
          ),
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
          _InfoTile(
            label: 'Frames du centre',
            value: '${draft.totalCenterFrameCount}',
          ),
          _InfoTile(
            label: 'Cellules animées',
            value: '${draft.animatedCenterCellCount}',
          ),
          _InfoTile(
            label: 'Variants',
            value:
                '${draft.configuredVariantCount}/${draft.requiredVariantCount}',
          ),
          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
        ],
      ),
    );
  }
}

class _NewPathSurfaceKindSection extends StatelessWidget {
  const _NewPathSurfaceKindSection({
    required this.draft,
    required this.onSurfaceKindChanged,
  });

  final PathStudioNewPathDraft draft;
  final ValueChanged<PathSurfaceKind> onSurfaceKindChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Type de surface',
      icon: CupertinoIcons.square_stack_3d_down_right,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valeur locale utilisée pour construire le ProjectPathPreset proposé.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          MacosPopupButton<PathSurfaceKind>(
            key: const Key('path-studio-new-path-surface-kind-popup'),
            value: draft.surfaceKind,
            onChanged: (value) {
              if (value != null) {
                onSurfaceKindChanged(value);
              }
            },
            items: [
              for (final value in PathSurfaceKind.values)
                MacosPopupMenuItem<PathSurfaceKind>(
                  value: value,
                  child: Text(value.name),
                ),
            ],
          ),
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
    required this.onVariantSelected,
    required this.onTileSelected,
    required this.onCenterFrameSelected,
    required this.onCenterFrameAdded,
    required this.onCenterFrameRemoved,
    required this.onCenterFrameDurationChanged,
    required this.onCellCleared,
    required this.onVariantCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;
  final ValueChanged<TerrainPathVariant> onVariantSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final ValueChanged<int> onCenterFrameSelected;
  final VoidCallback onCenterFrameAdded;
  final ValueChanged<int> onCenterFrameRemoved;
  final void Function(int frameIndex, int durationMs) onCenterFrameDurationChanged;
  final void Function(int localX, int localY) onCellCleared;
  final ValueChanged<TerrainPathVariant> onVariantCleared;

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
            onCenterFrameSelected: onCenterFrameSelected,
            onCenterFrameAdded: onCenterFrameAdded,
            onCenterFrameRemoved: onCenterFrameRemoved,
            onCenterFrameDurationChanged: onCenterFrameDurationChanged,
            onCellCleared: onCellCleared,
          ),
          const SizedBox(height: 14),
          _NewPathVariantMappingSection(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onVariantSelected: onVariantSelected,
            onVariantCleared: onVariantCleared,
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
              tile == null
                  ? 'À configurer'
                  : (cell.frames.length > 1
                      ? 'Animée — ${cell.frames.length} frames'
                      : 'Statique — 1 frame'),
              style: TextStyle(
                color: tile == null
                    ? PathStudioTheme.textSecondary
                    : PathStudioTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w800,
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
    required this.onCenterFrameSelected,
    required this.onCenterFrameAdded,
    required this.onCenterFrameRemoved,
    required this.onCenterFrameDurationChanged,
    required this.onCellCleared,
  });

  final PathStudioNewPathDraft draft;
  final ValueChanged<int> onCenterFrameSelected;
  final VoidCallback onCenterFrameAdded;
  final ValueChanged<int> onCenterFrameRemoved;
  final void Function(int frameIndex, int durationMs) onCenterFrameDurationChanged;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    final cell = draft.selectedCell;
    final selectedFrame = cell.selectedFrame;
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
            selectedFrame == null
                ? 'Aucune tuile configurée pour cette cellule.'
                : 'Tuile ${selectedFrame.tile.coordinateLabel} assignée depuis ${selectedFrame.tile.tilesetId}.',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cell.frames.length > 1
                ? 'Animée — ${cell.frames.length} frames'
                : 'Statique — ${cell.frames.length} frame',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (cell.frames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Animation de la cellule ${cell.label}',
              key: Key('path-studio-new-path-animation-title-${cell.label}'),
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < cell.frames.length; index += 1)
                  _CenterFrameChip(
                    key: Key('path-studio-new-path-frame-chip-$index'),
                    frameIndex: index,
                    frame: cell.frames[index],
                    selected: index == cell.selectedFrameIndex,
                    canRemove: cell.frames.length > 1,
                    onSelect: () => onCenterFrameSelected(index),
                    onRemove: () => onCenterFrameRemoved(index),
                    onDurationChanged: (duration) {
                      onCenterFrameDurationChanged(index, duration);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                key: const Key('path-studio-new-path-add-frame'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                color: PathStudioTheme.accentCyan.withValues(alpha: 0.2),
                onPressed: onCenterFrameAdded,
                child: const Text(
                  'Ajouter une frame',
                  style: TextStyle(
                    color: PathStudioTheme.accentCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          if (selectedFrame != null) ...[
            const SizedBox(height: 10),
            Text(
              'Frame active: ${cell.selectedFrameIndex + 1} • Tuile ${selectedFrame.tile.coordinateLabel} • ${selectedFrame.durationMs} ms',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (selectedFrame != null) ...[
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

class _CenterFrameChip extends StatelessWidget {
  const _CenterFrameChip({
    super.key,
    required this.frameIndex,
    required this.frame,
    required this.selected,
    required this.canRemove,
    required this.onSelect,
    required this.onRemove,
    required this.onDurationChanged,
  });

  final int frameIndex;
  final PathStudioNewPathDraftCenterFrame frame;
  final bool selected;
  final bool canRemove;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final ValueChanged<int> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 188,
        decoration: BoxDecoration(
          color: selected
              ? PathStudioTheme.accent.withValues(alpha: 0.18)
              : PathStudioTheme.backgroundAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : PathStudioTheme.borderStrong.withValues(alpha: 0.6),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frame ${frameIndex + 1}',
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tuile ${frame.tile.coordinateLabel}',
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key('path-studio-new-path-frame-duration-$frameIndex'),
              controller: TextEditingController(text: '${frame.durationMs}'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed != null && parsed > 0) {
                  onDurationChanged(parsed);
                }
              },
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: PathStudioTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PathStudioTheme.border),
              ),
            ),
            if (canRemove) ...[
              const SizedBox(height: 6),
              CupertinoButton(
                key: Key('path-studio-new-path-remove-frame-$frameIndex'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                color: PathStudioTheme.error.withValues(alpha: 0.16),
                onPressed: onRemove,
                child: const Text(
                  'Supprimer',
                  style: TextStyle(
                    color: PathStudioTheme.error,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewPathVariantMappingSection extends StatelessWidget {
  const _NewPathVariantMappingSection({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onVariantSelected,
    required this.onVariantCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final ValueChanged<TerrainPathVariant> onVariantSelected;
  final ValueChanged<TerrainPathVariant> onVariantCleared;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bords, coins et jonctions',
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Progression variants: ${draft.configuredVariantCount}/${draft.requiredVariantCount} configurés',
            key: const Key('path-studio-new-path-variant-progress'),
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ces tuiles permettront de créer les bords, coins, extrémités et jonctions du futur chemin.',
            style: TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Le centre reste géré séparément par le motif multi-cases.',
            style: TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final variant in PathStudioNewPathDraft.requiredVariants)
                _NewPathVariantTileCard(
                  tilesets: tilesets,
                  settings: settings,
                  projectRootPath: projectRootPath,
                  variant: variant,
                  tile: draft.variantTiles[variant],
                  selected: draft.selectedTarget ==
                          PathStudioNewPathDraftSelectionTarget.variant &&
                      draft.selectedVariant == variant,
                  onTap: () => onVariantSelected(variant),
                  onClear: () => onVariantCleared(variant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewPathVariantTileCard extends StatelessWidget {
  const _NewPathVariantTileCard({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.variant,
    required this.tile,
    required this.selected,
    required this.onTap,
    required this.onClear,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final TerrainPathVariant variant;
  final PathStudioNewPathDraftTile? tile;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final configured = tile != null;
    final variantName = _variantLabel(variant);
    final cardColor = selected
        ? PathStudioTheme.accentCyan.withValues(alpha: 0.22)
        : PathStudioTheme.backgroundAlt;
    final borderColor = selected
        ? PathStudioTheme.accentHover
        : PathStudioTheme.borderStrong.withValues(alpha: 0.6);
    return GestureDetector(
      key: Key('path-studio-new-path-variant-$variantName'),
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variantName,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (tile != null)
                  _TilePreviewBadge(
                    cellLabel: variantName,
                    tilesets: tilesets,
                    settings: settings,
                    projectRootPath: projectRootPath,
                    tile: tile!,
                  )
                else
                  _EmptyTileBadge(cellLabel: variantName),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        configured ? 'Configuré' : 'À configurer',
                        style: TextStyle(
                          color: configured
                              ? PathStudioTheme.success
                              : PathStudioTheme.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        configured
                            ? 'Tuile ${tile!.coordinateLabel}'
                            : 'Aucune tuile',
                        style: const TextStyle(
                          color: PathStudioTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (configured) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: Key('path-studio-new-path-clear-variant-$variantName'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                color: PathStudioTheme.error.withValues(alpha: 0.16),
                onPressed: onClear,
                child: const Text(
                  'Effacer',
                  style: TextStyle(
                    color: PathStudioTheme.error,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
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
    final selectedVariant = draft.selectedVariant;
    final selectedVariantTile = draft.selectedVariantTile;
    final isVariantTarget =
        draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.variant;
    final activeCell = isVariantTarget
        ? PathStudioNewPathDraftCell(
            localX: -1,
            localY: -1,
            label: _variantLabel(selectedVariant),
            frames: selectedVariantTile == null
                ? const []
                : [
                    PathStudioNewPathDraftCenterFrame(
                      tile: selectedVariantTile,
                      durationMs: defaultPlacedElementAnimationFrameDurationMs,
                    ),
                  ],
          )
        : selectedCell;
    final targetLabel = isVariantTarget
        ? 'le variant ${_variantLabel(selectedVariant)}'
        : 'la cellule ${selectedCell.label}';
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
            'Sélectionnez une tuile pour $targetLabel',
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
            activeCell: activeCell,
            onTileSelected: (source) => onTileSelected(source.x, source.y),
            fallbackBuilder: (context, result) {
              return _LogicalNewPathTileGrid(
                draft: draft,
                activeTile: activeCell.tile,
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
    required this.activeTile,
    required this.onTileSelected,
  });

  final PathStudioNewPathDraft draft;
  final PathStudioNewPathDraftTile? activeTile;
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
                  selected: activeTile?.sourceX == x &&
                      activeTile?.sourceY == y &&
                      activeTile?.tilesetId == draft.tilesetId,
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
  const _NewPathDiagnosticsCard({required this.plan});

  final PathStudioNewPathBuildPlan plan;

  @override
  Widget build(BuildContext context) {
    final blocking = plan.blockingIssues;
    final warnings = plan.warnings;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blocking.isEmpty)
            const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur bloquante',
              message:
                  'Le brouillon peut être préparé localement, avec warnings.',
            ),
          for (final issue in blocking)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _DiagnosticRow(
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                color: PathStudioTheme.error,
                title: issue.title,
                message: issue.description,
              ),
            ),
          for (final issue in warnings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _DiagnosticRow(
                icon: CupertinoIcons.info_circle_fill,
                color: PathStudioTheme.warning,
                title: issue.title,
                message: issue.description,
              ),
            ),
        ],
      ),
    );
  }
}

class _NewPathSaveStatusCard extends StatelessWidget {
  const _NewPathSaveStatusCard({
    required this.plan,
    required this.hasSaveCallback,
  });

  final PathStudioNewPathBuildPlan plan;
  final bool hasSaveCallback;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const Key('path-studio-save-status-card'),
      title: 'Plan de création local',
      icon: CupertinoIcons.floppy_disk,
      trailing: _StatusChip(
        label: plan.canBuildRequest && hasSaveCallback
            ? 'Requête prête'
            : 'Non sauvegardable',
        color: plan.canBuildRequest && hasSaveCallback
            ? PathStudioTheme.success
            : PathStudioTheme.warning,
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
                label: 'Base path id',
                value: plan.proposedBasePathPresetId,
              ),
              _InfoTile(
                label: 'Path pattern id',
                value: plan.proposedPathPatternPresetId,
              ),
              _InfoTile(
                label: 'Type de surface',
                value: plan.surfaceKind.name,
              ),
              _InfoTile(
                label: 'Centre',
                value: plan.centerReady ? 'prêt' : 'incomplet',
              ),
              _InfoTile(
                label: 'Variants',
                value:
                    '${plan.configuredVariantCount}/${plan.requiredVariantCount} configurés',
              ),
              _InfoTile(
                label: 'Couverture',
                value: plan.variantsCoverageLabel,
              ),
              const _InfoTile(
                label: 'Sauvegarde persistée',
                value: 'prochain lot',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            !plan.canBuildRequest
                ? 'Requête locale bloquée'
                : hasSaveCallback
                    ? 'Requête locale prête'
                    : 'Callback de sauvegarde absent',
            style: TextStyle(
              color: plan.canBuildRequest && hasSaveCallback
                  ? PathStudioTheme.success
                  : PathStudioTheme.warning,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            !plan.canBuildRequest
                ? 'Corrigez les erreurs bloquantes pour préparer la création en mémoire.'
                : hasSaveCallback
                    ? 'Warnings présents, mais création en mémoire possible.'
                    : 'La requête locale est prête, mais aucun callback ne l’applique au manifest.',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    required this.onSurfaceKindChanged,
    required this.onSizeChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onTilesetChanged;
  final ValueChanged<PathSurfaceKind> onSurfaceKindChanged;
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
            const _InspectorLabel('Type de surface'),
            MacosPopupButton<PathSurfaceKind>(
              key: const Key(
                  'path-studio-new-path-inspector-surface-kind-popup'),
              value: draft.surfaceKind,
              onChanged: (value) {
                if (value != null) {
                  onSurfaceKindChanged(value);
                }
              },
              items: [
                for (final value in PathSurfaceKind.values)
                  MacosPopupMenuItem<PathSurfaceKind>(
                    value: value,
                    child: Text(value.name),
                  ),
              ],
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
              label: 'Variants configurés',
              value:
                  '${draft.configuredVariantCount}/${draft.requiredVariantCount}',
            ),
            _InspectorRow(
              label: 'Type de surface',
              value: draft.surfaceKind.name,
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
              value:
                  'Préparer la requête locale puis attendre le lot de sauvegarde',
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Diagnostics brouillon',
              icon: CupertinoIcons.info_circle,
              child: Text(
                draft.issues.isEmpty
                    ? 'Aucune erreur locale sur le brouillon.'
                    : 'Des erreurs locales restent à corriger avant la préparation de la requête.',
                style: const TextStyle(
                  color: PathStudioTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
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

String _variantLabel(TerrainPathVariant variant) {
  return variant.name;
}
