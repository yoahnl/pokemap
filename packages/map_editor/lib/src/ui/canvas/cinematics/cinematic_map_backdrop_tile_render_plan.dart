import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

enum CinematicResolvedTilesetAssetStatus {
  available,
  missingTilesetEntry,
  missingFile,
  decodeFailed,
  invalidTileSize,
  emptyImage,
}

enum CinematicMapBackdropTileDiagnosticSeverity {
  info,
  warning,
  error,
}

final class CinematicMapBackdropTileDiagnostic {
  const CinematicMapBackdropTileDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    this.layerId,
    this.tilesetId,
  });

  final String code;
  final String message;
  final CinematicMapBackdropTileDiagnosticSeverity severity;
  final String? layerId;
  final String? tilesetId;
}

final class CinematicResolvedTilesetAsset {
  const CinematicResolvedTilesetAsset._({
    required this.tilesetId,
    required this.status,
    required this.diagnosticMessage,
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
  });

  factory CinematicResolvedTilesetAsset.available({
    required String tilesetId,
    required ui.Image image,
    required int tileWidth,
    required int tileHeight,
  }) {
    if (tileWidth <= 0 || tileHeight <= 0) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.invalidTileSize,
        message: 'Taille de tuile invalide pour le tileset $tilesetId.',
      );
    }
    if (image.width <= 0 || image.height <= 0) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.emptyImage,
        message: 'Image de tileset vide pour $tilesetId.',
      );
    }
    final columns = image.width ~/ tileWidth;
    final rows = image.height ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.invalidTileSize,
        message: 'Le tileset $tilesetId ne contient aucune tuile complete.',
      );
    }
    return CinematicResolvedTilesetAsset._(
      tilesetId: tilesetId,
      status: CinematicResolvedTilesetAssetStatus.available,
      diagnosticMessage: null,
      image: image,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columns: columns,
      rows: rows,
    );
  }

  factory CinematicResolvedTilesetAsset.diagnostic({
    required String tilesetId,
    required CinematicResolvedTilesetAssetStatus status,
    required String message,
  }) {
    return CinematicResolvedTilesetAsset._(
      tilesetId: tilesetId,
      status: status,
      diagnosticMessage: message,
      image: null,
      tileWidth: 0,
      tileHeight: 0,
      columns: 0,
      rows: 0,
    );
  }

  final String tilesetId;
  final CinematicResolvedTilesetAssetStatus status;
  final String? diagnosticMessage;
  final ui.Image? image;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;

  bool get isAvailable =>
      status == CinematicResolvedTilesetAssetStatus.available && image != null;
}

final class CinematicMapBackdropBitmapInstruction {
  const CinematicMapBackdropBitmapInstruction({
    required this.id,
    required this.layerId,
    required this.layerLabel,
    required this.layerKind,
    required this.zOrder,
    required this.tilesetId,
    required this.sourceRect,
    required this.destinationRect,
    required this.opacity,
    required this.tileId,
    this.quarterTurns = 0,
    this.flipX = false,
  });

  final String id;
  final String layerId;
  final String layerLabel;
  final CinematicMapBackdropLayerKind layerKind;
  final int zOrder;
  final String tilesetId;
  final ui.Rect sourceRect;
  final ui.Rect destinationRect;
  final double opacity;
  final int tileId;
  final int quarterTurns;
  final bool flipX;
}

final class CinematicMapBackdropTileRenderPlan {
  const CinematicMapBackdropTileRenderPlan({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesets,
    required this.instructions,
    required this.diagnostics,
  });

  final int mapWidth;
  final int mapHeight;
  final int tileWidth;
  final int tileHeight;
  final Map<String, CinematicResolvedTilesetAsset> tilesets;
  final List<CinematicMapBackdropBitmapInstruction> instructions;
  final List<CinematicMapBackdropTileDiagnostic> diagnostics;

  bool get hasBitmapInstructions => instructions.isNotEmpty;
  double get pixelWidth => mapWidth * tileWidth.toDouble();
  double get pixelHeight => mapHeight * tileHeight.toDouble();
}

CinematicMapBackdropTileRenderPlan buildCinematicMapBackdropTileRenderPlan({
  required MapData mapData,
  required ProjectManifest manifest,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
}) {
  final tileWidth = manifest.settings.tileWidth;
  final tileHeight = manifest.settings.tileHeight;
  final diagnostics = <CinematicMapBackdropTileDiagnostic>[];
  final diagnosticKeys = <String>{};
  final instructions = <CinematicMapBackdropBitmapInstruction>[];
  final manifestTilesetIds = {
    for (final tileset in manifest.tilesets) tileset.id.trim(),
  }..remove('');

  void addDiagnostic(CinematicMapBackdropTileDiagnostic diagnostic) {
    final key = '${diagnostic.code}|${diagnostic.layerId ?? ''}|'
        '${diagnostic.tilesetId ?? ''}|${diagnostic.message}';
    if (diagnosticKeys.add(key)) {
      diagnostics.add(diagnostic);
    }
  }

  if (tileWidth <= 0 || tileHeight <= 0) {
    diagnostics.add(
      const CinematicMapBackdropTileDiagnostic(
        code: 'invalidTileSize',
        message: 'Taille de tuile du projet invalide.',
        severity: CinematicMapBackdropTileDiagnosticSeverity.error,
      ),
    );
    return CinematicMapBackdropTileRenderPlan(
      mapWidth: mapData.size.width,
      mapHeight: mapData.size.height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tilesets: tilesets,
      instructions: const <CinematicMapBackdropBitmapInstruction>[],
      diagnostics: diagnostics,
    );
  }

  var zOrder = 0;
  for (final layer in mapData.layers) {
    if (layer is! TileLayer) {
      continue;
    }
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }

    for (var y = 0; y < mapData.size.height; y += 1) {
      final rowStart = y * mapData.size.width;
      for (var x = 0; x < mapData.size.width; x += 1) {
        final tileIndex = rowStart + x;
        final entry = resolveTileLayerCell(layer, tileIndex);
        if (entry == null) continue;
        if (!manifestTilesetIds.contains(entry.tilesetId)) {
          addDiagnostic(
            CinematicMapBackdropTileDiagnostic(
              code: 'missingTilesetEntry',
              message: 'Tileset ${entry.tilesetId} absent du manifeste.',
              severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
              layerId: layer.id,
              tilesetId: entry.tilesetId,
            ),
          );
          continue;
        }
        final manifestTileset = manifest.tilesets
            .where((candidate) => candidate.id == entry.tilesetId)
            .first;
        final source = manifestTileset.source;
        if (source == null) {
          final asset = tilesets[entry.tilesetId];
          if (asset == null || !asset.isAvailable) {
            addDiagnostic(
              CinematicMapBackdropTileDiagnostic(
                code: asset?.status.name ?? 'missingResolvedTileset',
                message: asset?.diagnosticMessage ??
                    'Image de tileset indisponible pour ${entry.tilesetId}.',
                severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
                layerId: layer.id,
                tilesetId: entry.tilesetId,
              ),
            );
            continue;
          }
          if (asset.tileWidth != tileWidth || asset.tileHeight != tileHeight) {
            addDiagnostic(
              CinematicMapBackdropTileDiagnostic(
                code: 'tileMetricMismatch',
                message:
                    'Métriques de tileset incompatibles pour ${entry.tilesetId}.',
                severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
                layerId: layer.id,
                tilesetId: entry.tilesetId,
              ),
            );
            continue;
          }
          final sourceX = (entry.localTileId % asset.columns) * tileWidth;
          final sourceY = (entry.localTileId ~/ asset.columns) * tileHeight;
          final image = asset.image!;
          if (sourceX + tileWidth > image.width ||
              sourceY + tileHeight > image.height) {
            addDiagnostic(
              CinematicMapBackdropTileDiagnostic(
                code: 'sourceRectOutOfBounds',
                message: 'Tuile ${entry.localTileId} hors atlas pour '
                    '${entry.tilesetId}.',
                severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
                layerId: layer.id,
                tilesetId: entry.tilesetId,
              ),
            );
            continue;
          }
          instructions.add(
            CinematicMapBackdropBitmapInstruction(
              id: '${layer.id}:$tileIndex',
              layerId: layer.id,
              layerLabel: layer.name,
              layerKind: CinematicMapBackdropLayerKind.tile,
              zOrder: zOrder++,
              tilesetId: entry.tilesetId,
              sourceRect: ui.Rect.fromLTWH(
                sourceX.toDouble(),
                sourceY.toDouble(),
                tileWidth.toDouble(),
                tileHeight.toDouble(),
              ),
              destinationRect: ui.Rect.fromLTWH(
                x * tileWidth.toDouble(),
                y * tileHeight.toDouble(),
                tileWidth.toDouble(),
                tileHeight.toDouble(),
              ),
              opacity: layer.opacity.clamp(0.0, 1.0).toDouble(),
              tileId: entry.localTileId,
              quarterTurns: entry.transform.quarterTurns,
              flipX: entry.transform.flipX,
            ),
          );
          continue;
        }
        final selection = switch (source) {
          ProjectRegularAtlasTilesetSource atlas =>
            entry.localTileId < atlas.tileCount
                ? ProjectTilesetVisualSelection.regularAtlas(
                    source: TilesetSourceRect(
                      x: entry.localTileId % atlas.columns,
                      y: entry.localTileId ~/ atlas.columns,
                    ),
                  )
                : null,
          ProjectImageCollectionTilesetSource() =>
            ProjectTilesetVisualSelection.imageCollection(
              tileId: entry.localTileId,
            ),
        };
        if (selection == null) {
          addDiagnostic(
            CinematicMapBackdropTileDiagnostic(
              code: 'sourceRectOutOfBounds',
              message: 'Tuile ${entry.localTileId} hors atlas pour '
                  '${entry.tilesetId}.',
              severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
              layerId: layer.id,
              tilesetId: entry.tilesetId,
            ),
          );
          continue;
        }
        ProjectTilesetVisualResolution visual;
        try {
          visual = const ProjectTilesetVisualResolver().resolve(
            source: source,
            selection: selection,
            cellWidth: tileWidth,
            cellHeight: tileHeight,
          );
        } on ProjectTilesetVisualResolutionException {
          addDiagnostic(
            CinematicMapBackdropTileDiagnostic(
              code: 'sourceRectOutOfBounds',
              message: 'Tuile ${entry.localTileId} non résolue pour '
                  '${entry.tilesetId}.',
              severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
              layerId: layer.id,
              tilesetId: entry.tilesetId,
            ),
          );
          continue;
        }
        for (final slice in visual.frames.first.slices) {
          final asset = tilesets[slice.assetId] ?? tilesets[entry.tilesetId];
          if (asset == null || !asset.isAvailable) {
            addDiagnostic(
              CinematicMapBackdropTileDiagnostic(
                code: asset?.status.name ?? 'missingResolvedTileset',
                message: asset?.diagnosticMessage ??
                    'Image de tileset indisponible pour ${slice.assetId}.',
                severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
                layerId: layer.id,
                tilesetId: entry.tilesetId,
              ),
            );
            continue;
          }
          if (asset.tileWidth != tileWidth || asset.tileHeight != tileHeight) {
            addDiagnostic(
              CinematicMapBackdropTileDiagnostic(
                code: 'tileMetricMismatch',
                message:
                    'Métriques de tileset incompatibles pour ${entry.tilesetId}.',
                severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
                layerId: layer.id,
                tilesetId: entry.tilesetId,
              ),
            );
            continue;
          }
          final image = asset.image!;
          final sourceRect = slice.sourceRect;
          if (sourceRect.x < 0 ||
              sourceRect.y < 0 ||
              sourceRect.x + sourceRect.width > image.width ||
              sourceRect.y + sourceRect.height > image.height) {
            addDiagnostic(
              CinematicMapBackdropTileDiagnostic(
                code: 'sourceRectOutOfBounds',
                message: 'Tuile ${entry.localTileId} hors atlas pour '
                    '${entry.tilesetId}.',
                severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
                layerId: layer.id,
                tilesetId: entry.tilesetId,
              ),
            );
            continue;
          }
          instructions.add(
            CinematicMapBackdropBitmapInstruction(
              id: '${layer.id}:$tileIndex:${slice.assetId}',
              layerId: layer.id,
              layerLabel: layer.name,
              layerKind: CinematicMapBackdropLayerKind.tile,
              zOrder: zOrder++,
              tilesetId: slice.assetId,
              sourceRect: ui.Rect.fromLTWH(
                slice.sourceRect.x.toDouble(),
                slice.sourceRect.y.toDouble(),
                slice.sourceRect.width.toDouble(),
                slice.sourceRect.height.toDouble(),
              ),
              destinationRect: ui.Rect.fromLTWH(
                x * tileWidth + slice.destinationRect.x.toDouble(),
                y * tileHeight + slice.destinationRect.y.toDouble(),
                slice.destinationRect.width.toDouble(),
                slice.destinationRect.height.toDouble(),
              ),
              opacity: layer.opacity.clamp(0.0, 1.0).toDouble(),
              tileId: entry.localTileId,
              quarterTurns: entry.transform.quarterTurns,
              flipX: entry.transform.flipX,
            ),
          );
        }
      }
    }
  }

  instructions.sort((a, b) => a.zOrder.compareTo(b.zOrder));
  if (instructions.isEmpty && diagnostics.isEmpty) {
    diagnostics.add(
      const CinematicMapBackdropTileDiagnostic(
        code: 'noBitmapInstructions',
        message: 'Aucune tuile bitmap à rendre.',
        severity: CinematicMapBackdropTileDiagnosticSeverity.info,
      ),
    );
  }
  return CinematicMapBackdropTileRenderPlan(
    mapWidth: mapData.size.width,
    mapHeight: mapData.size.height,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    tilesets: Map<String, CinematicResolvedTilesetAsset>.unmodifiable(tilesets),
    instructions:
        List<CinematicMapBackdropBitmapInstruction>.unmodifiable(instructions),
    diagnostics:
        List<CinematicMapBackdropTileDiagnostic>.unmodifiable(diagnostics),
  );
}
