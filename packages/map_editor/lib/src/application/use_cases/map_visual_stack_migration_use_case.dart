import 'dart:collection';

import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

import '../models/path_autotile_set.dart';

/// Inclusive bounds, in rendered RGBA pixels, changed by the migration.
@immutable
final class MapVisualStackPixelBounds {
  const MapVisualStackPixelBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;
}

/// Exact comparison of two images produced by the editor's map painter.
///
/// [width] and [height] are rendered image dimensions, not map-cell counts.
/// [limitations] describes deliberately excluded or static-only editor state.
@immutable
final class MapVisualStackPixelComparison {
  MapVisualStackPixelComparison({
    required this.width,
    required this.height,
    required this.changedPixelCount,
    required this.changedBounds,
    required this.beforeFingerprint,
    required this.afterFingerprint,
    required List<String> limitations,
  }) : limitations = UnmodifiableListView(limitations);

  final int width;
  final int height;
  final int changedPixelCount;
  final MapVisualStackPixelBounds? changedBounds;
  final String beforeFingerprint;
  final String afterFingerprint;
  final UnmodifiableListView<String> limitations;

  bool get hasChanges => changedPixelCount > 0;
}

/// Immutable project snapshot required by the real editor-painter comparison.
///
/// The notifier resolves disk paths while it owns the active workspace. The
/// UI renderer then loads those exact assets without coupling this use case to
/// `dart:ui` or to [MapGridPainter].
@immutable
final class MapVisualStackMigrationRenderInputs {
  MapVisualStackMigrationRenderInputs({
    required this.project,
    required this.projectRootPath,
    required Map<String, String> assetPathsById,
    required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
    required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
  })  : assetPathsById =
            UnmodifiableMapView(Map<String, String>.of(assetPathsById)),
        pathAutotileSetsByPresetId =
            UnmodifiableMapView(Map.of(pathAutotileSetsByPresetId)),
        terrainPresetsByType =
            UnmodifiableMapView(Map.of(terrainPresetsByType));

  final ProjectManifest? project;
  final String? projectRootPath;
  final UnmodifiableMapView<String, String> assetPathsById;
  final UnmodifiableMapView<String, PathAutotileSet> pathAutotileSetsByPresetId;
  final UnmodifiableMapView<TerrainType, ProjectTerrainPreset>
      terrainPresetsByType;

  ProjectSettings get settings => project?.settings ?? const ProjectSettings();
}

typedef MapVisualStackRenderedPixelComparator
    = Future<MapVisualStackPixelComparison> Function({
  required MapData before,
  required MapData after,
});

@immutable
final class EditorMapVisualStackMigrationPreview {
  const EditorMapVisualStackMigrationPreview({
    required this.migration,
    required this.pixelComparison,
    required this.pixelComparisonError,
  });

  final MapVisualStackMigrationPreview migration;
  final MapVisualStackPixelComparison? pixelComparison;
  final String? pixelComparisonError;

  bool get canApply =>
      migration.canApply &&
      pixelComparison != null &&
      pixelComparisonError == null;
}

/// Editor seam for explicit legacy-to-canonical visual-stack migration.
///
/// Preview never mutates or saves. Its required comparator is implemented by
/// the UI renderer so the acceptance gate is based on real RGBA output rather
/// than a synthetic ownership raster.
final class MapVisualStackMigrationUseCase {
  const MapVisualStackMigrationUseCase();

  Future<EditorMapVisualStackMigrationPreview> preview(
    MapData map, {
    required MapVisualStackRenderedPixelComparator compareRenderedPixels,
  }) async {
    final migration = previewMapVisualStackMigration(map);
    final beforePlan = migration.beforePlan;
    final afterPlan = migration.afterPlan;
    MapVisualStackPixelComparison? comparison;
    String? comparisonError;
    if (beforePlan != null && afterPlan != null) {
      try {
        comparison = await compareRenderedPixels(
          before: migration.before,
          after: migration.after,
        );
      } on Object catch (error) {
        comparisonError = 'Comparaison des pixels rendus indisponible : $error';
      }
    }
    return EditorMapVisualStackMigrationPreview(
      migration: migration,
      pixelComparison: comparison,
      pixelComparisonError: comparisonError,
    );
  }

  MapData apply({
    required MapData map,
    required EditorMapVisualStackMigrationPreview preview,
  }) {
    if (preview.migration.status == MapVisualStackMigrationStatus.ready &&
        !preview.canApply) {
      throw StateError(
        'Visual stack migration requires a completed rendered-pixel '
        'comparison.',
      );
    }
    return applyMapVisualStackMigration(
      map: map,
      preview: preview.migration,
    );
  }
}
