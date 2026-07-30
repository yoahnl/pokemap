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
import '../../element_preset_label.dart';
import '../browser/map_palette_asset_browser.dart';

typedef MapLayerElementActionsBuilder = Widget Function(
  BuildContext context,
  ProjectElementEntry element,
);

abstract final class MapLayerAssetPaletteKeys {
  static const root = ValueKey<String>('world-map-layer-asset-palette');
  static const scroll = ValueKey<String>('world-map-layer-asset-scroll');

  static ValueKey<String> elementCard(String elementId) =>
      ValueKey<String>('world-map-layer-asset-element-$elementId');
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
    this.presentation = MapPaletteAssetBrowserPresentation.inspector,
    this.sourceId,
    this.visibleElementIds,
    this.elementActionsBuilder,
    super.key,
  });

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
          return _ElementAssetList(
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
          );
        },
      ),
    );
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
    final sourceElements = project.elements
        .where((element) => element.tilesetId == source.id)
        .toList(growable: false);
    final elements = sourceElements
        .where(
          (element) =>
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
              ? PokeMapEmptyState(
                  icon: const Icon(Icons.category_outlined),
                  title: sourceElements.isEmpty
                      ? 'Aucun objet à placer'
                      : 'Aucun objet ne correspond aux filtres actifs',
                  description: sourceElements.isEmpty
                      ? 'Définissez des objets dans la Tileset Library, '
                          'section « Éléments à placer », pour cette source.'
                      : 'Modifiez ou réinitialisez les filtres actifs pour '
                          'afficher les objets.',
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
                    final presetLabel = elementPresetLabel(element.presetKind);
                    final collisionCellCount =
                        element.collisionProfile?.cells.length ?? 0;
                    final metadataStyle = TextStyle(
                      color: context.pokeMapColors.textMuted,
                      fontSize: 10,
                    );
                    final card = PokeMapAssetCard(
                      key: MapLayerAssetPaletteKeys.elementCard(element.id),
                      semanticLabel: '${element.name}, '
                          '${_categoryPath(project, element.categoryId)}, '
                          'Type : $presetLabel, '
                          'Collision : $collisionCellCount',
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
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      'Type : $presetLabel',
                                      style: metadataStyle,
                                    ),
                                    Text(
                                      'Collision : $collisionCellCount',
                                      style: metadataStyle,
                                    ),
                                  ],
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
