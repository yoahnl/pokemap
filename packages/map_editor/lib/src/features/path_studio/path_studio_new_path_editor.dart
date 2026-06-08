part of 'path_studio_panel.dart';

class _NewPathCenterWorkspace extends StatelessWidget {
  const _NewPathCenterWorkspace({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.savePlan,
    required this.editSavePlan,
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
    this.centerSequenceFeedback,
    required this.onCenterAnimationSequenceRequested,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final PathStudioNewPathBuildPlan savePlan;
  final PathStudioEditPathBuildPlan? editSavePlan;
  final bool hasSaveCallback;
  final void Function(int width, int height) onSizeChanged;
  final ValueChanged<PathSurfaceKind> onSurfaceKindChanged;
  final void Function(int localX, int localY) onCellSelected;
  final ValueChanged<TerrainPathVariant> onVariantSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final ValueChanged<int> onCenterFrameSelected;
  final VoidCallback onCenterFrameAdded;
  final ValueChanged<int> onCenterFrameRemoved;
  final void Function(int frameIndex, int durationMs)
      onCenterFrameDurationChanged;
  final void Function(int localX, int localY) onCellCleared;
  final ValueChanged<TerrainPathVariant> onVariantCleared;
  final String? centerSequenceFeedback;
  final void Function(
    PathStudioCenterAnimationSequenceTarget target,
    int frameCount,
    int stepX,
    int stepY,
    int durationMs,
  ) onCenterAnimationSequenceRequested;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NewPathBanner(isEditMode: draft.isEditMode),
          const SizedBox(height: 14),
          _NewPathWorkflowSteps(
            hasTileset: _hasSelectedTileset(draft),
            isEditMode: draft.isEditMode,
          ),
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
            sequenceFeedbackMessage: centerSequenceFeedback,
            onCenterAnimationSequenceRequested:
                onCenterAnimationSequenceRequested,
          ),
          const SizedBox(height: 14),
          _NewPathDiagnosticsCard(plan: savePlan),
          const SizedBox(height: 14),
          _NewPathSaveStatusCard(
            plan: savePlan,
            editPlan: editSavePlan,
            draft: draft,
            hasSaveCallback: hasSaveCallback,
          ),
        ],
      ),
    );
  }
}

class _NewPathBanner extends StatelessWidget {
  const _NewPathBanner({required this.isEditMode});

  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const Key('path-studio-new-path-context-banner'),
      title: isEditMode ? 'Modification du chemin' : 'Nouveau chemin',
      icon: CupertinoIcons.pencil_outline,
      trailing: const _StatusChip(
        label: 'Modifié en mémoire',
        color: PathStudioTheme.warning,
      ),
      child: Text(
        isEditMode
            ? 'Les changements s’appliquent au projet en mémoire via « Appliquer les modifications ». Pour écrire project.json, utilisez Save Project (icône disquette).'
            : 'Les changements s’appliquent au projet en mémoire via « Appliquer au projet ». Pour écrire project.json, utilisez Save Project (icône disquette).',
        style: const TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NewPathWorkflowSteps extends StatelessWidget {
  const _NewPathWorkflowSteps({
    required this.hasTileset,
    required this.isEditMode,
  });

  final bool hasTileset;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: isEditMode ? 'Modification guidée' : 'Création guidée',
      icon: CupertinoIcons.list_bullet,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StepPill(
            index: 1,
            label: isEditMode ? 'Modification' : 'Nouveau chemin',
            active: true,
          ),
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
      title: 'Résumé',
      icon: CupertinoIcons.doc_text,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: draft.name),
          _InfoTile(
            label: 'Mode',
            value:
                draft.isEditMode ? 'Modification du chemin' : 'Nouveau chemin',
          ),
          _InfoTile(label: 'Tileset', value: tilesetLabel),
          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
          _InfoTile(
            label: 'Cellules',
            value: pluralizeFr(
              draft.centerCellCount,
              'cellule',
              'cellules',
            ),
          ),
          _InfoTile(
            label: 'Configurées',
            value: '${draft.configuredCellCount}/${draft.centerCellCount}',
          ),
          _InfoTile(
            label: 'Frames du centre',
            value: pluralizeFr(
              draft.totalCenterFrameCount,
              'frame',
              'frames',
            ),
          ),
          _InfoTile(
            label: 'Cellules animées',
            value: pluralizeFr(
              draft.animatedCenterCellCount,
              'cellule animée',
              'cellules animées',
            ),
          ),
          _InfoTile(
            label: 'Variants',
            value:
                '${draft.configuredVariantCount}/${draft.requiredVariantCount}',
          ),
          const _InfoTile(label: 'État', value: 'Modifié en mémoire'),
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
    this.sequenceFeedbackMessage,
    required this.onCenterAnimationSequenceRequested,
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
  final void Function(int frameIndex, int durationMs)
      onCenterFrameDurationChanged;
  final void Function(int localX, int localY) onCellCleared;
  final ValueChanged<TerrainPathVariant> onVariantCleared;
  final String? sequenceFeedbackMessage;
  final void Function(
    PathStudioCenterAnimationSequenceTarget target,
    int frameCount,
    int stepX,
    int stepY,
    int durationMs,
  ) onCenterAnimationSequenceRequested;

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
            onVariantSelected: onVariantSelected,
          ),
          const SizedBox(height: 14),
          _NewPathSelectedCellDetails(
            draft: draft,
            onCenterFrameSelected: onCenterFrameSelected,
            onCenterFrameAdded: onCenterFrameAdded,
            onCenterFrameRemoved: onCenterFrameRemoved,
            onCenterFrameDurationChanged: onCenterFrameDurationChanged,
            onCellCleared: onCellCleared,
            onVariantCleared: onVariantCleared,
            sequenceFeedbackMessage: sequenceFeedbackMessage,
            onCenterAnimationSequenceRequested:
                onCenterAnimationSequenceRequested,
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

String _variantShortLabel(TerrainPathVariant variant) {
  return switch (variant) {
    TerrainPathVariant.isolated => 'Isolé',
    TerrainPathVariant.endNorth => 'Bout N',
    TerrainPathVariant.endEast => 'Bout E',
    TerrainPathVariant.endSouth => 'Bout S',
    TerrainPathVariant.endWest => 'Bout O',
    TerrainPathVariant.horizontal => 'Ligne H',
    TerrainPathVariant.vertical => 'Ligne V',
    TerrainPathVariant.cornerNE => 'Coin NE',
    TerrainPathVariant.cornerSE => 'Coin SE',
    TerrainPathVariant.cornerSW => 'Coin SO',
    TerrainPathVariant.cornerNW => 'Coin NO',
    TerrainPathVariant.innerCornerNE => 'Intér. NE',
    TerrainPathVariant.innerCornerSE => 'Intér. SE',
    TerrainPathVariant.innerCornerSW => 'Intér. SO',
    TerrainPathVariant.innerCornerNW => 'Intér. NO',
    TerrainPathVariant.teeNorth => 'Bord B',
    TerrainPathVariant.teeEast => 'Bord G',
    TerrainPathVariant.teeSouth => 'Bord H',
    TerrainPathVariant.teeWest => 'Bord D',
    TerrainPathVariant.cross => 'Croix',
  };
}

class _GridSpacer extends StatelessWidget {
  const _GridSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(4),
      child: SizedBox(
        width: 88,
        height: 128,
      ),
    );
  }
}

class _NewPathSpatialCell extends StatelessWidget {
  const _NewPathSpatialCell({
    super.key,
    required this.label,
    required this.cellKeyLabel,
    required this.selected,
    required this.tile,
    required this.onTap,
    this.isCenterCell = false,
    this.centerFramesCount = 0,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
  });

  final String label;
  final String cellKeyLabel;
  final bool selected;
  final PathStudioNewPathDraftTile? tile;
  final VoidCallback onTap;
  final bool isCenterCell;
  final int centerFramesCount;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 128,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color.lerp(
            isCenterCell ? PathStudioTheme.surface : PathStudioTheme.surfaceStrong,
            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
            selected ? 0.32 : (isCenterCell ? 0.12 : 0.08),
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : (isCenterCell
                    ? PathStudioTheme.accent.withValues(alpha: 0.3)
                    : PathStudioTheme.borderStrong.withValues(alpha: 0.45)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? PathStudioTheme.textPrimary : PathStudioTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.center,
              child: tile != null
                  ? _TilePreviewBadge(
                      cellLabel: cellKeyLabel,
                      tilesets: tilesets,
                      settings: settings,
                      projectRootPath: projectRootPath,
                      tile: tile!,
                    )
                  : _EmptyTileBadge(cellLabel: cellKeyLabel),
            ),
            const Spacer(),
            if (tile == null) ...[
              if (!isCenterCell) ...[
                const Text(
                  'Aucune tuile',
                  style: TextStyle(
                    color: PathStudioTheme.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'À configurer',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else ...[
                const Text(
                  'Absent',
                  style: TextStyle(
                    color: PathStudioTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]
            ] else ...[
              Text(
                isCenterCell
                    ? (centerFramesCount > 1 ? 'Animé ($centerFramesCount)' : 'Statique')
                    : 'Configuré',
                style: const TextStyle(
                  color: PathStudioTheme.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
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
    required this.onVariantSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int localX, int localY) onCellSelected;
  final ValueChanged<TerrainPathVariant> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    final centerWidth = draft.centerWidth;
    final centerHeight = draft.centerHeight;
    final gridWidth = centerWidth + 2;
    final gridHeight = centerHeight + 2;

    final rows = <Widget>[];
    for (var y = 0; y < gridHeight; y += 1) {
      final rowCells = <Widget>[];
      for (var x = 0; x < gridWidth; x += 1) {
        final isCorner = (x == 0 || x == gridWidth - 1) && (y == 0 || y == gridHeight - 1);
        final isEdge = !isCorner && (x == 0 || x == gridWidth - 1 || y == 0 || y == gridHeight - 1);

        if (isCorner) {
          final variant = (x == 0 && y == 0)
              ? TerrainPathVariant.cornerNW
              : (x == gridWidth - 1 && y == 0)
                  ? TerrainPathVariant.cornerNE
                  : (x == 0 && y == gridHeight - 1)
                      ? TerrainPathVariant.cornerSW
                      : TerrainPathVariant.cornerSE;
          rowCells.add(_buildVariantGridCell(variant, _variantShortLabel(variant), x, y));
        } else if (isEdge) {
          final variant = (y == 0)
              ? TerrainPathVariant.teeSouth
              : (y == gridHeight - 1)
                  ? TerrainPathVariant.teeNorth
                  : (x == 0)
                      ? TerrainPathVariant.teeEast
                      : TerrainPathVariant.teeWest;
          rowCells.add(_buildVariantGridCell(variant, _variantShortLabel(variant), x, y));
        } else {
          final cellX = x - 1;
          final cellY = y - 1;
          final cell = draft.cells.firstWhere(
            (c) => c.localX == cellX && c.localY == cellY,
          );
          rowCells.add(_buildCenterGridCell(cell));
        }
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: rowCells));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  Widget _buildCenterGridCell(PathStudioNewPathDraftCell cell) {
    final selected = draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell &&
        draft.selectedCellX == cell.localX &&
        draft.selectedCellY == cell.localY;

    return _NewPathSpatialCell(
      key: Key('path-studio-new-path-cell-${cell.localX}-${cell.localY}'),
      label: cell.label,
      cellKeyLabel: cell.label,
      selected: selected,
      tile: cell.tile,
      isCenterCell: true,
      centerFramesCount: cell.frames.length,
      tilesets: tilesets,
      settings: settings,
      projectRootPath: projectRootPath,
      onTap: () => onCellSelected(cell.localX, cell.localY),
    );
  }

  Widget _buildVariantGridCell(
    TerrainPathVariant variant,
    String label,
    int x,
    int y,
  ) {
    final frames = draft.variantCellFrames[variant] ?? const [];
    final isSelected = draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.variant &&
        draft.selectedVariant == variant;
    final selectedIndex = (isSelected && frames.isNotEmpty)
        ? draft.selectedCenterFrameIndex.clamp(0, frames.length - 1)
        : 0;
    final tile = frames.isEmpty ? null : frames[selectedIndex].tile;
    final selected = isSelected;

    final gridWidth = draft.centerWidth + 2;
    final gridHeight = draft.centerHeight + 2;

    final bool isPrimary;
    if (variant == TerrainPathVariant.teeSouth) {
      isPrimary = (x == 1 && y == 0);
    } else if (variant == TerrainPathVariant.teeNorth) {
      isPrimary = (x == 1 && y == gridHeight - 1);
    } else if (variant == TerrainPathVariant.teeEast) {
      isPrimary = (x == 0 && y == 1);
    } else if (variant == TerrainPathVariant.teeWest) {
      isPrimary = (x == gridWidth - 1 && y == 1);
    } else {
      isPrimary = true;
    }

    final key = isPrimary
        ? Key('path-studio-new-path-variant-${variant.name}')
        : Key('path-studio-new-path-variant-${variant.name}-extra-$x-$y');

    return _NewPathSpatialCell(
      key: key,
      label: label,
      cellKeyLabel: variant.name,
      selected: selected,
      tile: tile,
      isCenterCell: false,
      tilesets: tilesets,
      settings: settings,
      projectRootPath: projectRootPath,
      onTap: () => onVariantSelected(variant),
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
    required this.onVariantCleared,
    this.sequenceFeedbackMessage,
    required this.onCenterAnimationSequenceRequested,
  });

  final PathStudioNewPathDraft draft;
  final ValueChanged<int> onCenterFrameSelected;
  final VoidCallback onCenterFrameAdded;
  final ValueChanged<int> onCenterFrameRemoved;
  final void Function(int frameIndex, int durationMs)
      onCenterFrameDurationChanged;
  final void Function(int localX, int localY) onCellCleared;
  final ValueChanged<TerrainPathVariant> onVariantCleared;
  final String? sequenceFeedbackMessage;
  final void Function(
    PathStudioCenterAnimationSequenceTarget target,
    int frameCount,
    int stepX,
    int stepY,
    int durationMs,
  ) onCenterAnimationSequenceRequested;

  @override
  Widget build(BuildContext context) {
    final isVariantTarget = draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.variant;

    final String titleText;
    final String subtitleText;
    final VoidCallback? onClearPressed;
    final String clearButtonText;

    final frames = draft.selectedTargetFrames;
    final selectedFrame = draft.selectedTargetFrame;
    final isAnimated = frames.length > 1;

    if (isVariantTarget) {
      final variant = draft.selectedVariant;
      titleText = 'Variant : ${_variantLabel(variant)}';
      subtitleText = 'Bordure / Coin';
      onClearPressed = () => onVariantCleared(variant);
      clearButtonText = 'Effacer le variant';
    } else {
      final cell = draft.selectedCell;
      titleText = 'Cellule ${cell.label}';
      subtitleText = 'Position ${cell.localX},${cell.localY}';
      onClearPressed = () => onCellCleared(cell.localX, cell.localY);
      clearButtonText = 'Effacer la cellule';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitleText,
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selectedFrame == null
                ? (isVariantTarget
                    ? 'Aucune tuile configurée.'
                    : 'Aucune tuile configurée pour cette cellule.')
                : 'Tuile ${selectedFrame.tile.coordinateLabel} assignée depuis ${selectedFrame.tile.tilesetId}.',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAnimated
                ? 'Animé — ${pluralizeFr(frames.length, 'frame', 'frames')}'
                : 'Statique — ${pluralizeFr(frames.length, 'frame', 'frames')}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (!isVariantTarget)
            Text(
              'Centre : ${pluralizeFr(draft.centerCellCount, 'cellule', 'cellules')} · '
              '${pluralizeFr(draft.totalCenterFrameCount, 'frame', 'frames')} · '
              '${pluralizeFr(draft.animatedCenterCellCount, 'cellule animée', 'cellules animées')}',
              key: const Key('path-studio-new-path-center-animation-summary'),
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              'Couverture: ${draft.configuredVariantCount}/${draft.requiredVariantCount} variants',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (frames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              isVariantTarget ? 'Animation du variant' : 'Animation du centre — Cellule ${draft.selectedCell.label}',
              key: isVariantTarget 
                  ? const Key('path-studio-new-path-animation-title-variant')
                  : Key('path-studio-new-path-animation-title-${draft.selectedCell.label}'),
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chaque frame correspond à une tuile du tileset.\nLe runtime joue les frames dans l’ordre avec la durée indiquée.\nAvec une seule frame, la cellule reste statique.',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < frames.length; index += 1)
                  _CenterFrameChip(
                    key: Key('path-studio-new-path-frame-chip-$index'),
                    frameIndex: index,
                    frame: frames[index],
                    selected: index == draft.selectedCenterFrameIndex,
                    canRemove: frames.length > 1,
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
                  'Ajouter une frame dupliquée',
                  style: TextStyle(
                    color: PathStudioTheme.accentCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'La nouvelle frame copie la frame active. Sélectionnez ensuite une tuile pour la remplacer.',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (draft.tilesetId != null) ...[
              const SizedBox(height: 14),
              _NewPathCenterSequenceAssistant(
                key: const Key('path-studio-new-path-seq-section'),
                draft: draft,
                feedbackMessage: sequenceFeedbackMessage,
                onGenerateRequested: onCenterAnimationSequenceRequested,
              ),
            ],
          ],
          if (selectedFrame != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Frame active',
              key: Key('path-studio-new-path-active-frame-title'),
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Frame ${draft.selectedCenterFrameIndex + 1} / ${frames.length}',
              key: const Key('path-studio-new-path-active-frame-index'),
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tuile ${selectedFrame.tile.coordinateLabel}',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Durée ${selectedFrame.durationMs} ms',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (selectedFrame != null && onClearPressed != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                key: isVariantTarget
                    ? Key('path-studio-new-path-clear-variant-${draft.selectedVariant.name}')
                    : const Key('path-studio-new-path-clear-selected-cell'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                color: PathStudioTheme.error.withValues(alpha: 0.16),
                onPressed: onClearPressed,
                child: Text(
                  clearButtonText,
                  style: const TextStyle(
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

class _NewPathVariantMappingSection extends StatefulWidget {
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
  State<_NewPathVariantMappingSection> createState() =>
      _NewPathVariantMappingSectionState();
}

class _NewPathVariantMappingSectionState
    extends State<_NewPathVariantMappingSection> {
  bool _expanded = true;

  Widget _buildVariantGridCell(TerrainPathVariant variant, String label) {
    final frames = widget.draft.variantCellFrames[variant] ?? const [];
    final isSelected = widget.draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.variant &&
        widget.draft.selectedVariant == variant;
    final selectedIndex = (isSelected && frames.isNotEmpty)
        ? widget.draft.selectedCenterFrameIndex.clamp(0, frames.length - 1)
        : 0;
    final tile = frames.isEmpty ? null : frames[selectedIndex].tile;
    final selected = isSelected;

    return _NewPathSpatialCell(
      key: Key('path-studio-new-path-variant-${variant.name}'),
      label: label,
      cellKeyLabel: variant.name,
      selected: selected,
      tile: tile,
      isCenterCell: false,
      tilesets: widget.tilesets,
      settings: widget.settings,
      projectRootPath: widget.projectRootPath,
      onTap: () => widget.onVariantSelected(variant),
    );
  }

  Widget _buildEndsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extrémités & Isolé',
          style: TextStyle(
            color: PathStudioTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: PathStudioTheme.subtleDecoration(color: PathStudioTheme.backgroundAlt),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GridSpacer(),
                  _buildVariantGridCell(TerrainPathVariant.endNorth, 'Fin N'),
                  const _GridSpacer(),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVariantGridCell(TerrainPathVariant.endWest, 'Fin O'),
                  _buildVariantGridCell(TerrainPathVariant.isolated, 'Isolé'),
                  _buildVariantGridCell(TerrainPathVariant.endEast, 'Fin E'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GridSpacer(),
                  _buildVariantGridCell(TerrainPathVariant.endSouth, 'Fin S'),
                  const _GridSpacer(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInnerCornersGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coins intérieurs',
          style: TextStyle(
            color: PathStudioTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: PathStudioTheme.subtleDecoration(color: PathStudioTheme.backgroundAlt),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVariantGridCell(TerrainPathVariant.innerCornerNW, 'Intér. NO'),
                  _buildVariantGridCell(TerrainPathVariant.innerCornerNE, 'Intér. NE'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVariantGridCell(TerrainPathVariant.innerCornerSW, 'Intér. SO'),
                  _buildVariantGridCell(TerrainPathVariant.innerCornerSE, 'Intér. SE'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleLinesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lignes 1-tuile',
          style: TextStyle(
            color: PathStudioTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: PathStudioTheme.subtleDecoration(color: PathStudioTheme.backgroundAlt),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVariantGridCell(TerrainPathVariant.horizontal, 'Ligne H'),
                  _buildVariantGridCell(TerrainPathVariant.vertical, 'Ligne V'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: const Key('path-studio-new-path-variants-accordion-toggle'),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bords, coins et jonctions',
                    style: TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _expanded ? 'Replier' : 'Déplier',
                  style: const TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: PathStudioTheme.textSecondary,
                  size: 13,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Progression variants: ${widget.draft.configuredVariantCount}/${widget.draft.requiredVariantCount} configurés',
            key: const Key('path-studio-new-path-variant-progress'),
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
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
              'Le centre reste géré séparément par le motif principal.',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.start,
              children: [
                _buildEndsGrid(context),
                _buildInnerCornersGrid(context),
                _buildSimpleLinesGrid(context),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NewPathCenterSequenceAssistant extends StatefulWidget {
  const _NewPathCenterSequenceAssistant({
    super.key,
    required this.draft,
    this.feedbackMessage,
    required this.onGenerateRequested,
  });

  final PathStudioNewPathDraft draft;
  final String? feedbackMessage;
  final void Function(
    PathStudioCenterAnimationSequenceTarget target,
    int frameCount,
    int stepX,
    int stepY,
    int durationMs,
  ) onGenerateRequested;

  @override
  State<_NewPathCenterSequenceAssistant> createState() =>
      _NewPathCenterSequenceAssistantState();
}

class _NewPathCenterSequenceAssistantState
    extends State<_NewPathCenterSequenceAssistant> {
  late final TextEditingController _frameCount;
  late final TextEditingController _stepX;
  late final TextEditingController _stepY;
  late final TextEditingController _durationMs;
  String _targetKey = 'selected';
  String? _localFeedback;

  @override
  void initState() {
    super.initState();
    _frameCount = TextEditingController(text: '4');
    _stepX = TextEditingController(text: '3');
    _stepY = TextEditingController(text: '0');
    _durationMs = TextEditingController(text: '200');
  }

  @override
  void dispose() {
    _frameCount.dispose();
    _stepX.dispose();
    _stepY.dispose();
    _durationMs.dispose();
    super.dispose();
  }

  String? get _displayedFeedback =>
      _localFeedback ?? widget.feedbackMessage;

  void _submit() {
    setState(() => _localFeedback = null);
    final frameCountParsed = int.tryParse(_frameCount.text.trim());
    final stepXParsed = int.tryParse(_stepX.text.trim());
    final stepYParsed = int.tryParse(_stepY.text.trim());
    final durationParsed = int.tryParse(_durationMs.text.trim());
    if (frameCountParsed == null ||
        stepXParsed == null ||
        stepYParsed == null ||
        durationParsed == null) {
      setState(() {
        _localFeedback =
            'Impossible de générer l’animation : valeurs numériques invalides.';
      });
      return;
    }
    final target = switch (_targetKey) {
      'selected' => PathStudioCenterAnimationSequenceTarget.selectedCell,
      'allCenter' => PathStudioCenterAnimationSequenceTarget.allCenterCells,
      _ => PathStudioCenterAnimationSequenceTarget.allCells,
    };
    widget.onGenerateRequested(
      target,
      frameCountParsed,
      stepXParsed,
      stepYParsed,
      durationParsed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('path-studio-new-path-seq-inner'),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Générer une séquence',
            key: Key('path-studio-new-path-seq-heading'),
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Génère une timeline à partir de la première frame de chaque '
            'cellule ciblée (y compris le centre et les variants configurés).',
            style: TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cible',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          CupertinoSlidingSegmentedControl<String>(
            key: const Key('path-studio-new-path-seq-target-control'),
            groupValue: _targetKey,
            onValueChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _targetKey = value);
            },
            children: const {
              'selected': Padding(
                key: Key('path-studio-new-path-seq-target-selected'),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  'Cellule active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              'allCenter': Padding(
                key: Key('path-studio-new-path-seq-target-all-center'),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  'Centre uniquement',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              'all': Padding(
                key: Key('path-studio-new-path-seq-target-all'),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  'Toutes les cellules',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Nombre de frames',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('path-studio-new-path-seq-frame-count'),
            controller: _frameCount,
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pas',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  key: const Key('path-studio-new-path-seq-step-x'),
                  controller: _stepX,
                  placeholder: 'Pas X',
                  keyboardType: TextInputType.number,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  key: const Key('path-studio-new-path-seq-step-y'),
                  controller: _stepY,
                  placeholder: 'Pas Y',
                  keyboardType: TextInputType.number,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Durée par frame (ms)',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('path-studio-new-path-seq-duration'),
            controller: _durationMs,
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              key: const Key('path-studio-new-path-seq-generate'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              color: PathStudioTheme.accent.withValues(alpha: 0.2),
              onPressed: _submit,
              child: const Text(
                'Générer l’animation',
                style: TextStyle(
                  color: PathStudioTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (_displayedFeedback != null) ...[
            const SizedBox(height: 10),
            Text(
              _displayedFeedback!,
              key: const Key('path-studio-new-path-seq-feedback'),
              style: TextStyle(
                color: _displayedFeedback!.startsWith('Impossible')
                    ? PathStudioTheme.warning
                    : PathStudioTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.35,
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
              selected
                  ? 'Frame ${frameIndex + 1} (active)'
                  : 'Frame ${frameIndex + 1}',
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
            const Text(
              'Durée de la frame (ms)',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
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
                  'Supprimer cette frame',
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
    required this.editPlan,
    required this.draft,
    required this.hasSaveCallback,
  });

  final PathStudioNewPathBuildPlan plan;
  final PathStudioEditPathBuildPlan? editPlan;
  final PathStudioNewPathDraft draft;
  final bool hasSaveCallback;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const Key('path-studio-save-status-card'),
      title: 'Application au projet (mémoire)',
      icon: CupertinoIcons.floppy_disk,
      trailing: _StatusChip(
        label: (draft.isEditMode
                    ? editPlan?.canBuildRequest == true
                    : plan.canBuildRequest) &&
                hasSaveCallback
            ? 'Requête prête'
            : 'Incomplet',
        color: ((draft.isEditMode
                    ? editPlan?.canBuildRequest == true
                    : plan.canBuildRequest) &&
                hasSaveCallback)
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
              _InfoTile(
                label: 'État',
                value: draft.isEditMode
                    ? 'Modification du chemin'
                    : 'Nouveau chemin',
              ),
              _InfoTile(
                label: 'Base path id',
                value: draft.isEditMode
                    ? draft.basePathPresetId
                    : plan.proposedBasePathPresetId,
              ),
              _InfoTile(
                label: 'Path pattern id',
                value: draft.isEditMode
                    ? draft.pathPatternPresetId
                    : plan.proposedPathPatternPresetId,
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
              _InfoTile(
                label: 'Action',
                value: draft.isEditMode
                    ? 'Remplacement en mémoire'
                    : 'Création en mémoire',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            !(draft.isEditMode
                    ? editPlan?.canBuildRequest == true
                    : plan.canBuildRequest)
                ? 'Requête bloquée (corrections requises)'
                : hasSaveCallback
                    ? 'Prêt à appliquer en mémoire'
                    : 'Callback d’application absent',
            style: TextStyle(
              color: !(draft.isEditMode
                          ? editPlan?.canBuildRequest == true
                          : plan.canBuildRequest) ||
                      !hasSaveCallback
                  ? PathStudioTheme.warning
                  : PathStudioTheme.success,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            !(draft.isEditMode
                    ? editPlan?.canBuildRequest == true
                    : plan.canBuildRequest)
                ? 'Corrigez les blocages pour pouvoir appliquer le chemin en mémoire, puis enregistrez le projet (disquette) vers project.json.'
                : hasSaveCallback
                    ? 'Warnings possibles, mais application en mémoire autorisée.'
                    : 'Requête prête, mais aucun chemin d’application vers le manifest.',
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
            Text(
              draft.isEditMode
                  ? 'Propriétés de la modification'
                  : 'Propriétés du nouveau chemin',
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _StatusChip(
              label: 'Modifié en mémoire',
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
            _InspectorRow(
              label: draft.isEditMode ? 'ID base path' : 'ID temporaire',
              value: draft.id,
            ),
            if (draft.isEditMode)
              _InspectorRow(
                label: 'ID path pattern',
                value: draft.pathPatternPresetId,
              ),
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
              value: 'Modifié en mémoire',
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
