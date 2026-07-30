import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

import '../../../../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../../../../app/providers/use_case_providers.dart';
import '../../../../../application/models/map_palette_asset_browser.dart';
import '../../../../../application/services/map_palette_asset_browser_projector.dart';
import '../../../../../features/editor/state/editor_notifier.dart';
import '../../../../../features/editor/state/editor_selectors.dart';
import '../../../../../features/editor/state/editor_state.dart';
import '../../../../../features/editor/tools/editor_tool.dart';
import '../../../../assets/editor_image_cache.dart';
import '../../../../design_system/design_system.dart';
import '../../../../../theme/theme.dart';
import '../browser/map_palette_asset_browser.dart';

enum MapLayerAssetPaletteMode { tiles, elements }

typedef MapLayerElementActionsBuilder = Widget Function(
  BuildContext context,
  ProjectElementEntry element,
);

abstract final class MapLayerAssetPaletteKeys {
  static const root = ValueKey<String>('world-map-layer-asset-palette');
  static const scroll = ValueKey<String>('world-map-layer-asset-scroll');

  static ValueKey<String> tileCell(String tilesetId, int tileId) =>
      ValueKey<String>('world-map-layer-asset-tile-$tilesetId-$tileId');

  static ValueKey<String> elementCard(String elementId) =>
      ValueKey<String>('world-map-layer-asset-element-$elementId');
}

class MapLayerTileAssetPresentation {
  const MapLayerTileAssetPresentation({
    required this.tilesetId,
    required this.tileId,
    required this.selected,
    required this.enabled,
    required this.disabledReason,
  });

  final String tilesetId;
  final int tileId;
  final bool selected;
  final bool enabled;
  final String? disabledReason;
}

class MapLayerElementAssetPresentation {
  const MapLayerElementAssetPresentation({
    required this.element,
    required this.selected,
    required this.enabled,
    required this.disabledReason,
  });

  final ProjectElementEntry element;
  final bool selected;
  final bool enabled;
  final String? disabledReason;
}

class MapLayerAssetPalette extends ConsumerStatefulWidget {
  const MapLayerAssetPalette({
    required this.mode,
    this.presentation = MapPaletteAssetBrowserPresentation.inspector,
    this.sourceId,
    this.visibleElementIds,
    this.elementActionsBuilder,
    super.key,
  });

  final MapLayerAssetPaletteMode mode;
  final MapPaletteAssetBrowserPresentation presentation;
  final String? sourceId;
  final Set<String>? visibleElementIds;
  final MapLayerElementActionsBuilder? elementActionsBuilder;

  @override
  ConsumerState<MapLayerAssetPalette> createState() =>
      _MapLayerAssetPaletteState();
}

class _MapLayerAssetPaletteState extends ConsumerState<MapLayerAssetPalette> {
  EditorImageCache? _lastImageCache;
  String? _lastImagePath;
  Future<EditorImageLoadResult>? _imageFuture;

  @override
  void dispose() {
    _releaseImageFuture(_imageFuture);
    _imageFuture = null;
    super.dispose();
  }

  Future<EditorImageLoadResult> _resolveImageFuture(
    EditorImageCache imageCache,
    String imagePath,
  ) {
    if (_imageFuture != null &&
        identical(_lastImageCache, imageCache) &&
        _lastImagePath == imagePath) {
      return _imageFuture!;
    }
    final previousFuture = _imageFuture;
    _lastImageCache = imageCache;
    _lastImagePath = imagePath;
    final nextFuture = imageCache.load(imagePath);
    _imageFuture = nextFuture;
    _releaseImageFuture(previousFuture);
    return nextFuture;
  }

  void _releaseImageFuture(Future<EditorImageLoadResult>? future) {
    if (future == null) return;
    unawaited(
      future.then<void>(
        (result) {
          final binding = WidgetsBinding.instance;
          binding.addPostFrameCallback((_) => result.dispose());
          binding.ensureVisualUpdate();
        },
        onError: (Object _, StackTrace __) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final browserSnapshot =
        ref.watch(editorMapPaletteAssetBrowserSnapshotProvider);
    final paletteSnapshot = ref.watch(editorTilesetPaletteSnapshotProvider);
    final projector = MapPaletteAssetBrowserProjector(
      ref.watch(resolveAssignableTilesetsForMapUseCaseProvider),
      ref.watch(resolveVisibleProjectElementsUseCaseProvider),
    );
    final projection = projector.project(
      project: browserSnapshot.project,
      map: browserSnapshot.activeMap,
      activeLayerId: browserSnapshot.activeLayerId,
      selectedTilesetId: browserSnapshot.context.selectedTilesetId,
      query: '',
      folderId: null,
      elementCategoryId: null,
      collection: EditorPaletteAssetCollection.all,
      showIncompatible: true,
      recentTilesetIds: browserSnapshot.recentTilesetIds,
      favoriteTilesetIds: browserSnapshot.favoriteTilesetIds,
    );
    final sourceId = widget.sourceId ??
        browserSnapshot.context.selectedTilesetId ??
        browserSnapshot.assignedTilesetId;
    final project = browserSnapshot.project;
    final source = _findTileset(project, sourceId);
    final sourceProjection = _findSourceProjection(
      projection.items,
      sourceId,
    );
    final availability = _availabilityFor(
      projection: projection,
      source: source,
      sourceProjection: sourceProjection,
    );
    final projectRootPath = paletteSnapshot.projectRootPath?.trim();

    if (project == null ||
        source == null ||
        projectRootPath == null ||
        projectRootPath.isEmpty) {
      return KeyedSubtree(
        key: MapLayerAssetPaletteKeys.root,
        child: PokeMapEmptyState(
          icon: const Icon(Icons.grid_off_rounded),
          title: 'Aucune source à afficher',
          description: projection.diagnostic ??
              'Choisissez une source déclarée pour le calque actif.',
        ),
      );
    }

    final imageCache = ref.watch(editorImageCacheProvider(projectRootPath));
    final imagePath = path.join(projectRootPath, source.relativePath);
    final imageFuture = _resolveImageFuture(imageCache, imagePath);
    return KeyedSubtree(
      key: MapLayerAssetPaletteKeys.root,
      child: FutureBuilder<EditorImageLoadResult>(
        key: ValueKey<Object>((imageCache, imagePath)),
        future: imageFuture,
        builder: (context, imageSnapshot) {
          final result = imageSnapshot.data;
          final image = result?.image;
          if (image == null) {
            if (result?.failure case final failure?) {
              return PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.error,
                title: 'Image de source indisponible',
                message: failure.message,
              );
            }
            return const PokeMapEmptyState(
              icon: Icon(Icons.hourglass_top_rounded),
              title: 'Chargement de la source',
              description: 'La palette sera disponible dans un instant.',
            );
          }
          return switch (widget.mode) {
            MapLayerAssetPaletteMode.tiles => _TileAssetGrid(
                source: source,
                image: image,
                settings: paletteSnapshot.settings,
                selectedBrush: paletteSnapshot.activeBrush,
                availability: availability,
                categoryFilter: browserSnapshot.context.paletteCategoryFilter,
                onSelected: _selectTile,
              ),
            MapLayerAssetPaletteMode.elements => _ElementAssetList(
                source: source,
                image: image,
                project: project,
                settings: paletteSnapshot.settings,
                selectedBrush: paletteSnapshot.activeBrush,
                availability: availability,
                categoryId: widget.visibleElementIds == null
                    ? browserSnapshot.context.projectElementCategoryId
                    : null,
                visibleElementIds: widget.visibleElementIds,
                elementActionsBuilder: widget.elementActionsBuilder,
                onSelected: _selectElement,
              ),
          };
        },
      ),
    );
  }

  void _selectTile(MapLayerTileAssetPresentation tile) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    notifier.selectPaletteTile(tile.tileId);
    notifier.selectTool(EditorToolType.tilePaint);
  }

  void _selectElement(MapLayerElementAssetPresentation asset) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final recommendedLayerId = asset.element.recommendedLayerId;
    final map =
        ref.read(editorMapPaletteAssetBrowserSnapshotProvider).activeMap;
    if (recommendedLayerId != null &&
        map != null &&
        map.layers.any(
          (layer) => layer is TileLayer && layer.id == recommendedLayerId,
        )) {
      notifier.setActiveLayer(recommendedLayerId);
    }
    notifier.selectProjectElement(asset.element.id);
    notifier.selectTool(EditorToolType.tilePaint);
  }
}

class _MapLayerAssetAvailability {
  const _MapLayerAssetAvailability({
    required this.enabled,
    required this.disabledReason,
  });

  final bool enabled;
  final String? disabledReason;
}

_MapLayerAssetAvailability _availabilityFor({
  required MapPaletteAssetBrowserProjection projection,
  required ProjectTilesetEntry? source,
  required MapPaletteAssetBrowserItem? sourceProjection,
}) {
  if (source == null) {
    return _MapLayerAssetAvailability(
      enabled: false,
      disabledReason:
          projection.diagnostic ?? 'Cette source n’existe plus dans le projet.',
    );
  }
  if (sourceProjection == null) {
    return _MapLayerAssetAvailability(
      enabled: false,
      disabledReason: projection.diagnostic ??
          'Cette source n’est pas disponible dans ce contexte.',
    );
  }
  if (!sourceProjection.isCompatible) {
    return _MapLayerAssetAvailability(
      enabled: false,
      disabledReason: sourceProjection.disabledReason ??
          'Cette source n’est pas compatible avec le calque actif.',
    );
  }
  if (!sourceProjection.isAssigned) {
    return const _MapLayerAssetAvailability(
      enabled: false,
      disabledReason:
          'Assignez cette source au calque actif avant d’utiliser ses assets.',
    );
  }
  return const _MapLayerAssetAvailability(
    enabled: true,
    disabledReason: null,
  );
}

ProjectTilesetEntry? _findTileset(
  ProjectManifest? project,
  String? sourceId,
) {
  if (project == null || sourceId == null) return null;
  for (final source in project.tilesets) {
    if (source.id == sourceId) return source;
  }
  return null;
}

MapPaletteAssetBrowserItem? _findSourceProjection(
  List<MapPaletteAssetBrowserItem> items,
  String? sourceId,
) {
  if (sourceId == null) return null;
  for (final item in items) {
    if (item.tileset.id == sourceId) return item;
  }
  return null;
}

class _TileAssetGrid extends StatelessWidget {
  const _TileAssetGrid({
    required this.source,
    required this.image,
    required this.settings,
    required this.selectedBrush,
    required this.availability,
    required this.categoryFilter,
    required this.onSelected,
  });

  final ProjectTilesetEntry source;
  final ui.Image image;
  final ProjectSettings settings;
  final EditorBrush selectedBrush;
  final _MapLayerAssetAvailability availability;
  final PaletteCategory? categoryFilter;
  final ValueChanged<MapLayerTileAssetPresentation> onSelected;

  @override
  Widget build(BuildContext context) {
    final columns =
        settings.tileWidth <= 0 ? 0 : image.width ~/ settings.tileWidth;
    final rows =
        settings.tileHeight <= 0 ? 0 : image.height ~/ settings.tileHeight;
    if (columns <= 0 || rows <= 0) {
      return const PokeMapEmptyState(
        icon: Icon(Icons.broken_image_outlined),
        title: 'Dimensions de tuiles invalides',
        description:
            'La source ne contient aucune tuile aux dimensions du projet.',
      );
    }
    final entriesByTileId = <int, TilesetPaletteEntry>{};
    for (final entry in source.paletteEntries) {
      final frame = entry.frames.primarySource;
      if (frame.width != 1 || frame.height != 1) continue;
      final tileId = frame.y * columns + frame.x + 1;
      if (tileId > 0 && tileId <= columns * rows) {
        entriesByTileId[tileId] = entry;
      }
    }
    final tileIds = <int>[
      for (var tileId = 1; tileId <= columns * rows; tileId++)
        if (_matchesTileCategory(
          entriesByTileId[tileId],
          categoryFilter,
        ))
          tileId,
    ];
    final selectedTileId = selectedBrush.maybeMap(
      tile: (brush) => brush.tilesetId == source.id ? brush.tileId : null,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AssetPaletteFixedHeader(
          sourceName: source.name,
          count: tileIds.length,
          disabledReason: availability.disabledReason,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                key: MapLayerAssetPaletteKeys.scroll,
                padding: EdgeInsets.zero,
                itemCount: tileIds.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: constraints.maxWidth < 280 ? 58 : 72,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final tileId = tileIds[index];
                  final presentation = MapLayerTileAssetPresentation(
                    tilesetId: source.id,
                    tileId: tileId,
                    selected: selectedTileId == tileId,
                    enabled: availability.enabled,
                    disabledReason: availability.disabledReason,
                  );
                  return PokeMapAssetCard(
                    key: MapLayerAssetPaletteKeys.tileCell(
                      source.id,
                      tileId,
                    ),
                    semanticLabel: 'Tuile $tileId de ${source.name}',
                    selected: presentation.selected,
                    disabledReason: presentation.disabledReason,
                    onPressed: presentation.enabled
                        ? () => onSelected(presentation)
                        : null,
                    padding: const EdgeInsets.all(4),
                    child: _TilePreview(
                      image: image,
                      tileId: tileId,
                      tileWidth: settings.tileWidth,
                      tileHeight: settings.tileHeight,
                      columns: columns,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

bool _matchesTileCategory(
  TilesetPaletteEntry? entry,
  PaletteCategory? category,
) {
  if (category == null) return true;
  if (entry == null) return category == PaletteCategory.uncategorized;
  return entry.category == category;
}

class _ElementAssetList extends StatelessWidget {
  const _ElementAssetList({
    required this.source,
    required this.image,
    required this.project,
    required this.settings,
    required this.selectedBrush,
    required this.availability,
    required this.categoryId,
    required this.visibleElementIds,
    required this.elementActionsBuilder,
    required this.onSelected,
  });

  final ProjectTilesetEntry source;
  final ui.Image image;
  final ProjectManifest project;
  final ProjectSettings settings;
  final EditorBrush selectedBrush;
  final _MapLayerAssetAvailability availability;
  final String? categoryId;
  final Set<String>? visibleElementIds;
  final MapLayerElementActionsBuilder? elementActionsBuilder;
  final ValueChanged<MapLayerElementAssetPresentation> onSelected;

  @override
  Widget build(BuildContext context) {
    final elements = project.elements
        .where(
          (element) =>
              element.tilesetId == source.id &&
              (visibleElementIds == null ||
                  visibleElementIds!.contains(element.id)) &&
              (categoryId == null || element.categoryId == categoryId),
        )
        .toList(growable: false);
    final selectedElementId = selectedBrush.maybeMap(
      projectElement: (brush) => brush.elementId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AssetPaletteFixedHeader(
          sourceName: source.name,
          count: elements.length,
          disabledReason: availability.disabledReason,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: elements.isEmpty
              ? const PokeMapEmptyState(
                  icon: Icon(Icons.category_outlined),
                  title: 'Aucun élément',
                  description:
                      'Cette source ne contient aucun élément pour ce filtre.',
                )
              : ListView.separated(
                  key: MapLayerAssetPaletteKeys.scroll,
                  padding: EdgeInsets.zero,
                  itemCount: elements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final element = elements[index];
                    final presentation = MapLayerElementAssetPresentation(
                      element: element,
                      selected: selectedElementId == element.id,
                      enabled: availability.enabled,
                      disabledReason: availability.disabledReason,
                    );
                    final card = PokeMapAssetCard(
                      key: MapLayerAssetPaletteKeys.elementCard(element.id),
                      semanticLabel:
                          '${element.name}, ${_categoryPath(project, element.categoryId)}',
                      selected: presentation.selected,
                      disabledReason: presentation.disabledReason,
                      onPressed: presentation.enabled
                          ? () => onSelected(presentation)
                          : null,
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 48,
                            child: _ElementPreview(
                              image: image,
                              source: element.frames.primarySource,
                              tileWidth: settings.tileWidth,
                              tileHeight: settings.tileHeight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  element.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.pokeMapColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _categoryPath(
                                    project,
                                    element.categoryId,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.pokeMapColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    final actionsBuilder = elementActionsBuilder;
                    if (actionsBuilder == null) return card;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: card),
                        const SizedBox(width: 4),
                        actionsBuilder(context, element),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AssetPaletteFixedHeader extends StatelessWidget {
  const _AssetPaletteFixedHeader({
    required this.sourceName,
    required this.count,
    required this.disabledReason,
  });

  final String sourceName;
  final int count;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PokeMapBadge(
              label: '$count',
              variant: PokeMapBadgeVariant.neutral,
            ),
          ],
        ),
        if (disabledReason case final reason?) ...[
          const SizedBox(height: 6),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            message: reason,
          ),
        ],
      ],
    );
  }
}

String _categoryPath(ProjectManifest project, String categoryId) {
  final categories = <String, ProjectElementCategory>{
    for (final category in project.elementCategories) category.id: category,
  };
  final labels = <String>[];
  final visited = <String>{};
  String? currentId = categoryId;
  while (currentId != null && visited.add(currentId)) {
    final category = categories[currentId];
    if (category == null) break;
    labels.add(category.name);
    currentId = category.parentCategoryId;
  }
  return labels.isEmpty ? 'Sans catégorie' : labels.reversed.join(' / ');
}

class _TilePreview extends StatelessWidget {
  const _TilePreview({
    required this.image,
    required this.tileId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
  });

  final ui.Image image;
  final int tileId;
  final int tileWidth;
  final int tileHeight;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TilePreviewPainter(
        image: image,
        tileId: tileId,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        columns: columns,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TilePreviewPainter extends CustomPainter {
  const _TilePreviewPainter({
    required this.image,
    required this.tileId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
  });

  final ui.Image image;
  final int tileId;
  final int tileWidth;
  final int tileHeight;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final index = tileId - 1;
    final sourceRect = Rect.fromLTWH(
      (index % columns) * tileWidth.toDouble(),
      (index ~/ columns) * tileHeight.toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    canvas.drawImageRect(
      image,
      sourceRect,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _TilePreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.tileId != tileId ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.columns != columns;
  }
}

class _ElementPreview extends StatelessWidget {
  const _ElementPreview({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ElementPreviewPainter(
        image: image,
        source: source,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ElementPreviewPainter extends CustomPainter {
  const _ElementPreviewPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right > image.width || sourceRect.bottom > image.height) {
      return;
    }
    final scale = (size.width / sourceRect.width)
        .clamp(0.0, size.height / sourceRect.height);
    final destinationSize = Size(
      sourceRect.width * scale,
      sourceRect.height * scale,
    );
    final destinationRect = Alignment.center.inscribe(
      destinationSize,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _ElementPreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight;
  }
}
