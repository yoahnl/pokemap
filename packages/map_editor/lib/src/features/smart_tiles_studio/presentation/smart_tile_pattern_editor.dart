import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_atlas_image_loader.dart';
import '../application/smart_tile_pattern_authoring.dart';

enum _PatternAtlasInputMode { selection, anchor }

class SmartTilePatternEditor extends StatefulWidget {
  const SmartTilePatternEditor({
    super.key,
    required this.manifest,
    required this.projectRootPath,
    required this.patternId,
    required this.imageLoader,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
    this.initialPattern,
    this.externalError,
  });

  final ProjectManifest manifest;
  final String? projectRootPath;
  final String patternId;
  final SmartTileAtlasImageLoader imageLoader;
  final ProjectSmartTilePattern? initialPattern;
  final bool isSaving;
  final String? externalError;
  final VoidCallback onCancel;
  final Future<void> Function(ProjectSmartTilePattern pattern) onSave;

  @override
  State<SmartTilePatternEditor> createState() => _SmartTilePatternEditorState();
}

class _SmartTilePatternEditorState extends State<SmartTilePatternEditor> {
  late final TextEditingController _nameController;
  late SmartTileUsage _usage;
  late SmartTilePatternRepeatMode _repeatMode;
  String? _atlasId;
  SmartTilePatternAtlasSelection? _selection;
  int? _anchorColumn;
  int? _anchorRow;
  _PatternAtlasInputMode _inputMode = _PatternAtlasInputMode.selection;
  bool _awaitingOppositeCorner = false;
  SmartTileAtlasImageLoadResult? _imageResult;
  int _loadRevision = 0;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPattern;
    final projection =
        initial == null ? null : projectSmartTilePatternAtlasSelection(initial);
    _nameController = TextEditingController(text: initial?.name ?? '');
    _usage = initial?.usage ?? SmartTileUsage.terrain;
    _repeatMode = initial?.repeatMode ?? SmartTilePatternRepeatMode.stamp;
    final atlases = widget.manifest.smartTileCatalog.atlases;
    _atlasId = projection != null &&
            atlases.any((atlas) => atlas.id == projection.atlasId)
        ? projection.atlasId
        : atlases.firstOrNull?.id;
    _selection = projection?.selection ??
        (_atlasId == null
            ? null
            : const SmartTilePatternAtlasSelection(
                startColumn: 0,
                startRow: 0,
                endColumn: 0,
                endRow: 0,
              ));
    _anchorColumn = projection?.anchorColumn ?? (_atlasId == null ? null : 0);
    _anchorRow = projection?.anchorRow ?? (_atlasId == null ? null : 0);
    unawaited(_loadAtlasImage());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ProjectSmartTileAtlas? get _atlas => widget.manifest.smartTileCatalog.atlases
      .where((atlas) => atlas.id == _atlasId)
      .firstOrNull;

  ProjectTilesetEntry? get _tileset {
    final tilesetId = _atlas?.tilesetId;
    return widget.manifest.tilesets
        .where((tileset) => tileset.id == tilesetId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final atlas = _atlas;
    final selection = _selection;
    final error = _localError ?? widget.externalError;
    final canSave = !widget.isSaving &&
        atlas != null &&
        selection != null &&
        _anchorColumn != null &&
        _anchorRow != null &&
        _nameController.text.trim().isNotEmpty;

    return ListView(
      key: const Key('smart-tiles-pattern-editor'),
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        PokeMapSectionHeader(
          title: widget.initialPattern == null
              ? 'Nouveau motif réutilisable'
              : 'Modifier le motif',
          description:
              'Sélectionnez directement les cellules de l’atlas. Le Studio construit le motif sans JSON.',
          trailing: PokeMapBadge(
            label: selection == null
                ? 'Zone à choisir'
                : '${selection.width} × ${selection.height} cellules',
            variant: selection == null
                ? PokeMapBadgeVariant.warning
                : PokeMapBadgeVariant.info,
          ),
        ),
        const SizedBox(height: 16),
        PokeMapTextField(
          label: 'Nom du motif',
          controller: _nameController,
          fieldKey: const Key('smart-tiles-pattern-name'),
          placeholder: 'Ex. Chemin compacté clair',
          autofocus: widget.initialPattern == null,
          onChanged: (_) => setState(() => _localError = null),
        ),
        const SizedBox(height: 16),
        const PokeMapSectionHeader(
          title: 'Usage',
          description:
              'Le motif sera proposé uniquement sur les couches compatibles.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final usage in SmartTileUsage.values)
              PokeMapButton(
                key: Key('smart-tiles-pattern-usage-${usage.name}'),
                onPressed: widget.isSaving
                    ? null
                    : () => setState(() => _usage = usage),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: _usage == usage,
                child: Text(_usageLabel(usage)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.manifest.smartTileCatalog.atlases.isEmpty)
          const PokeMapEmptyState(
            key: Key('smart-tiles-pattern-missing-atlas'),
            title: 'Aucun atlas disponible',
            description:
                'Créez ou importez d’abord une source dans Smart Tiles Studio.',
            icon: Icon(CupertinoIcons.photo),
          )
        else ...[
          PokeMapDropdownField<String>(
            key: const Key('smart-tiles-pattern-atlas'),
            label: 'Atlas source',
            value: _atlasId!,
            items: <PokeMapDropdownItem<String>>[
              for (final candidate in widget.manifest.smartTileCatalog.atlases)
                PokeMapDropdownItem<String>(
                  value: candidate.id,
                  label: candidate.name,
                ),
            ],
            onChanged: _selectAtlas,
            enabled: !widget.isSaving,
          ),
          const SizedBox(height: 12),
          PokeMapSectionHeader(
            title: 'Zone et ancrage',
            description: _inputMode == _PatternAtlasInputMode.selection
                ? _awaitingOppositeCorner
                    ? 'Cliquez maintenant le coin opposé de la zone.'
                    : 'Cliquez un premier coin, puis le coin opposé.'
                : 'Cliquez dans la zone pour choisir le point posé sous le curseur.',
            trailing: Wrap(
              spacing: 6,
              children: <Widget>[
                PokeMapButton(
                  key: const Key('smart-tiles-pattern-mode-selection'),
                  onPressed: widget.isSaving
                      ? null
                      : () => setState(() {
                            _inputMode = _PatternAtlasInputMode.selection;
                            _awaitingOppositeCorner = false;
                          }),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: _inputMode == _PatternAtlasInputMode.selection,
                  child: const Text('Définir la zone'),
                ),
                PokeMapButton(
                  key: const Key('smart-tiles-pattern-mode-anchor'),
                  onPressed: selection == null || widget.isSaving
                      ? null
                      : () => setState(() {
                            _inputMode = _PatternAtlasInputMode.anchor;
                            _awaitingOppositeCorner = false;
                          }),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: _inputMode == _PatternAtlasInputMode.anchor,
                  child: const Text('Placer l’ancrage'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SmartTilePatternAtlasPicker(
            atlas: atlas!,
            image: _imageResult?.image,
            selection: selection,
            anchorColumn: _anchorColumn,
            anchorRow: _anchorRow,
            enabled: !widget.isSaving,
            onCellSelected: _selectAtlasCell,
          ),
          if (_imageResult != null && !_imageResult!.isLoaded) ...[
            const SizedBox(height: 8),
            PokeMapBadge(
              label: _imageResult!.message,
              variant: PokeMapBadgeVariant.warning,
            ),
          ],
          const SizedBox(height: 16),
          const PokeMapSectionHeader(
            title: 'Comportement du pinceau',
            description:
                'Un tampon est posé une fois. Un motif répétable remplit lignes et rectangles.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: const Key('smart-tiles-pattern-repeat-stamp'),
                onPressed: widget.isSaving
                    ? null
                    : () => setState(
                        () => _repeatMode = SmartTilePatternRepeatMode.stamp),
                variant: PokeMapButtonVariant.ghost,
                isSelected: _repeatMode == SmartTilePatternRepeatMode.stamp,
                child: const Text('Tampon unique'),
              ),
              PokeMapButton(
                key: const Key('smart-tiles-pattern-repeat-tiled'),
                onPressed: widget.isSaving
                    ? null
                    : () => setState(
                        () => _repeatMode = SmartTilePatternRepeatMode.tiled),
                variant: PokeMapButtonVariant.ghost,
                isSelected: _repeatMode == SmartTilePatternRepeatMode.tiled,
                child: const Text('Répéter dans la zone'),
              ),
            ],
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          PokeMapBadge(
            key: const Key('smart-tiles-pattern-error'),
            label: error,
            variant: PokeMapBadgeVariant.error,
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapButton(
              key: const Key('smart-tiles-pattern-cancel'),
              onPressed: widget.isSaving ? null : widget.onCancel,
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const Key('smart-tiles-pattern-save'),
              onPressed: canSave ? _save : null,
              isLoading: widget.isSaving,
              leading: const Icon(CupertinoIcons.checkmark_alt, size: 15),
              child: const Text('Enregistrer le motif'),
            ),
          ],
        ),
      ],
    );
  }

  void _selectAtlas(String atlasId) {
    setState(() {
      _atlasId = atlasId;
      _selection = const SmartTilePatternAtlasSelection(
        startColumn: 0,
        startRow: 0,
        endColumn: 0,
        endRow: 0,
      );
      _anchorColumn = 0;
      _anchorRow = 0;
      _inputMode = _PatternAtlasInputMode.selection;
      _awaitingOppositeCorner = false;
      _imageResult = null;
      _localError = null;
    });
    unawaited(_loadAtlasImage());
  }

  void _selectAtlasCell(({int column, int row}) cell) {
    if (_inputMode == _PatternAtlasInputMode.anchor) {
      final selection = _selection;
      if (selection == null ||
          !selection.contains(column: cell.column, row: cell.row)) {
        setState(() =>
            _localError = 'L’ancrage doit rester à l’intérieur de la zone.');
        return;
      }
      setState(() {
        _anchorColumn = cell.column;
        _anchorRow = cell.row;
        _localError = null;
      });
      return;
    }
    setState(() {
      if (!_awaitingOppositeCorner) {
        _selection = SmartTilePatternAtlasSelection(
          startColumn: cell.column,
          startRow: cell.row,
          endColumn: cell.column,
          endRow: cell.row,
        );
        _anchorColumn = cell.column;
        _anchorRow = cell.row;
        _awaitingOppositeCorner = true;
      } else {
        final start = _selection!;
        _selection = SmartTilePatternAtlasSelection(
          startColumn: start.startColumn,
          startRow: start.startRow,
          endColumn: cell.column,
          endRow: cell.row,
        );
        _anchorColumn = _selection!.left;
        _anchorRow = _selection!.top;
        _awaitingOppositeCorner = false;
      }
      _localError = null;
    });
  }

  Future<void> _loadAtlasImage() async {
    final tileset = _tileset;
    if (tileset == null) return;
    final revision = ++_loadRevision;
    final result = await widget.imageLoader.load(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
    );
    if (!mounted || revision != _loadRevision) return;
    setState(() => _imageResult = result);
  }

  Future<void> _save() async {
    final atlas = _atlas;
    final selection = _selection;
    final anchorColumn = _anchorColumn;
    final anchorRow = _anchorRow;
    if (atlas == null ||
        selection == null ||
        anchorColumn == null ||
        anchorRow == null) {
      return;
    }
    try {
      final initial = widget.initialPattern;
      final pattern = compileSmartTileAtlasPattern(
        id: widget.patternId,
        name: _nameController.text,
        usage: _usage,
        atlas: atlas,
        selection: selection,
        anchorColumn: anchorColumn,
        anchorRow: anchorRow,
        repeatMode: _repeatMode,
        categoryId: initial?.categoryId ?? '',
        drawOrder: initial?.drawOrder ?? 0,
        tags: initial?.tags ?? const <String>[],
        sortOrder: initial?.sortOrder ?? 0,
      );
      setState(() => _localError = null);
      await widget.onSave(pattern);
    } on SmartTilePatternAuthoringException catch (error) {
      if (mounted) setState(() => _localError = error.message);
    }
  }
}

class SmartTilePatternAtlasPicker extends StatelessWidget {
  const SmartTilePatternAtlasPicker({
    super.key,
    required this.atlas,
    required this.image,
    required this.selection,
    required this.anchorColumn,
    required this.anchorRow,
    required this.enabled,
    required this.onCellSelected,
  });

  final ProjectSmartTileAtlas atlas;
  final SmartTileAtlasImage? image;
  final SmartTilePatternAtlasSelection? selection;
  final int? anchorColumn;
  final int? anchorRow;
  final bool enabled;
  final ValueChanged<({int column, int row})> onCellSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final lastRect = atlas.sourceRectFor(
      column: atlas.columns - 1,
      row: atlas.rows - 1,
    );
    final sourceWidth =
        math.max(image?.width ?? 0, lastRect.x + lastRect.width);
    final sourceHeight =
        math.max(image?.height ?? 0, lastRect.y + lastRect.height);
    return LayoutBuilder(
      builder: (context, constraints) {
        const viewportHeight = 360.0;
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 720.0;
        final scale = math.min(
          availableWidth / sourceWidth,
          viewportHeight / sourceHeight,
        );
        final displayWidth = math.max(1.0, sourceWidth * scale);
        final displayHeight = math.max(1.0, sourceHeight * scale);
        return Container(
          height: viewportHeight,
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            constrained: false,
            alignment: Alignment.center,
            minScale: 0.5,
            maxScale: 16,
            boundaryMargin: const EdgeInsets.all(160),
            child: GestureDetector(
              key: const Key('smart-tiles-pattern-atlas-viewport'),
              behavior: HitTestBehavior.opaque,
              onTapDown: enabled
                  ? (details) {
                      final cell = _patternAtlasCellAt(
                        localPosition: details.localPosition,
                        displaySize: Size(displayWidth, displayHeight),
                        sourceWidth: sourceWidth,
                        sourceHeight: sourceHeight,
                        atlas: atlas,
                      );
                      if (cell != null) onCellSelected(cell);
                    }
                  : null,
              child: SizedBox(
                width: displayWidth,
                height: displayHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (image != null)
                      Image.memory(
                        image!.bytes,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: colors.surfaceSubtle),
                      )
                    else
                      ColoredBox(color: colors.surfaceSubtle),
                    CustomPaint(
                      painter: _SmartTilePatternAtlasPainter(
                        atlas: atlas,
                        sourceWidth: sourceWidth,
                        sourceHeight: sourceHeight,
                        selection: selection,
                        anchorColumn: anchorColumn,
                        anchorRow: anchorRow,
                        gridColor: colors.borderStrong.withValues(alpha: 0.62),
                        selectionColor:
                            colors.brandPrimary.withValues(alpha: 0.24),
                        selectionBorderColor: colors.brandPrimary,
                        anchorColor: colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

({int column, int row})? _patternAtlasCellAt({
  required Offset localPosition,
  required Size displaySize,
  required int sourceWidth,
  required int sourceHeight,
  required ProjectSmartTileAtlas atlas,
}) {
  if (displaySize.width <= 0 || displaySize.height <= 0) return null;
  final pixelX = localPosition.dx / displaySize.width * sourceWidth;
  final pixelY = localPosition.dy / displaySize.height * sourceHeight;
  final relativeX = pixelX - atlas.originX - atlas.marginX;
  final relativeY = pixelY - atlas.originY - atlas.marginY;
  if (relativeX < 0 || relativeY < 0) return null;
  final stepX = atlas.cellWidth + atlas.spacingX;
  final stepY = atlas.cellHeight + atlas.spacingY;
  final column = relativeX ~/ stepX;
  final row = relativeY ~/ stepY;
  if (column < 0 || row < 0 || column >= atlas.columns || row >= atlas.rows) {
    return null;
  }
  if (relativeX - column * stepX >= atlas.cellWidth ||
      relativeY - row * stepY >= atlas.cellHeight) {
    return null;
  }
  return (column: column, row: row);
}

class _SmartTilePatternAtlasPainter extends CustomPainter {
  const _SmartTilePatternAtlasPainter({
    required this.atlas,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.selection,
    required this.anchorColumn,
    required this.anchorRow,
    required this.gridColor,
    required this.selectionColor,
    required this.selectionBorderColor,
    required this.anchorColor,
  });

  final ProjectSmartTileAtlas atlas;
  final int sourceWidth;
  final int sourceHeight;
  final SmartTilePatternAtlasSelection? selection;
  final int? anchorColumn;
  final int? anchorRow;
  final Color gridColor;
  final Color selectionColor;
  final Color selectionBorderColor;
  final Color anchorColor;

  @override
  void paint(Canvas canvas, Size size) {
    Rect cellRect(int column, int row) {
      final source = atlas.sourceRectFor(column: column, row: row);
      return Rect.fromLTWH(
        source.x / sourceWidth * size.width,
        source.y / sourceHeight * size.height,
        source.width / sourceWidth * size.width,
        source.height / sourceHeight * size.height,
      );
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < atlas.rows; row++) {
      for (var column = 0; column < atlas.columns; column++) {
        canvas.drawRect(cellRect(column, row), gridPaint);
      }
    }
    final selected = selection;
    if (selected != null) {
      final first = cellRect(selected.left, selected.top);
      final last = cellRect(selected.right, selected.bottom);
      final rect =
          Rect.fromLTRB(first.left, first.top, last.right, last.bottom);
      canvas.drawRect(
        rect,
        Paint()
          ..color = selectionColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = selectionBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (anchorColumn != null && anchorRow != null) {
      final rect = cellRect(anchorColumn!, anchorRow!);
      canvas.drawCircle(
        rect.center,
        math.max(3, math.min(rect.width, rect.height) * 0.2),
        Paint()..color = anchorColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmartTilePatternAtlasPainter oldDelegate) =>
      oldDelegate.atlas != atlas ||
      oldDelegate.sourceWidth != sourceWidth ||
      oldDelegate.sourceHeight != sourceHeight ||
      oldDelegate.selection != selection ||
      oldDelegate.anchorColumn != anchorColumn ||
      oldDelegate.anchorRow != anchorRow ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.selectionColor != selectionColor ||
      oldDelegate.selectionBorderColor != selectionBorderColor ||
      oldDelegate.anchorColor != anchorColor;
}

String _usageLabel(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'Terrain',
      SmartTileUsage.path => 'Chemin',
      SmartTileUsage.forestSurface => 'Surface forestière',
    };

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
