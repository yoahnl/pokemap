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
  final instructions = <CinematicMapBackdropBitmapInstruction>[];
  final manifestTilesetIds = {
    for (final tileset in manifest.tilesets) tileset.id.trim(),
  }..remove('');

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

    final tilesetId = (layer.tilesetId ?? mapData.tilesetId).trim();
    if (tilesetId.isEmpty) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: 'missingTilesetId',
          message: 'Le calque ${layer.name} n’a pas de tileset.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
        ),
      );
      continue;
    }

    if (!manifestTilesetIds.contains(tilesetId)) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: 'missingTilesetEntry',
          message: 'Tileset $tilesetId absent du manifeste.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
          tilesetId: tilesetId,
        ),
      );
      continue;
    }

    final tileset = tilesets[tilesetId];
    if (tileset == null || !tileset.isAvailable) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: tileset?.status.name ?? 'missingResolvedTileset',
          message: tileset?.diagnosticMessage ??
              'Image de tileset indisponible pour $tilesetId.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
          tilesetId: tilesetId,
        ),
      );
      continue;
    }
    if (tileset.tileWidth != tileWidth || tileset.tileHeight != tileHeight) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: 'tileMetricMismatch',
          message: 'Métriques de tileset incompatibles pour $tilesetId.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
          tilesetId: tilesetId,
        ),
      );
      continue;
    }

    final image = tileset.image!;
    for (var y = 0; y < mapData.size.height; y += 1) {
      final rowStart = y * mapData.size.width;
      for (var x = 0; x < mapData.size.width; x += 1) {
        final tileIndex = rowStart + x;
        if (tileIndex >= layer.tiles.length) {
          continue;
        }
        final tileId = layer.tiles[tileIndex];
        if (tileId <= 0) {
          continue;
        }

        final sourceIndex = tileId - 1;
        final sourceX = (sourceIndex % tileset.columns) * tileWidth;
        final sourceY = (sourceIndex ~/ tileset.columns) * tileHeight;
        if (sourceX + tileWidth > image.width ||
            sourceY + tileHeight > image.height) {
          diagnostics.add(
            CinematicMapBackdropTileDiagnostic(
              code: 'sourceRectOutOfBounds',
              message: 'Tuile $tileId hors atlas pour $tilesetId.',
              severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
              layerId: layer.id,
              tilesetId: tilesetId,
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
            zOrder: zOrder,
            tilesetId: tilesetId,
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
            tileId: tileId,
          ),
        );
        zOrder += 1;
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
