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
