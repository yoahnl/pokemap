import 'package:map_core/map_core.dart';

final class SmartTilePublicationResult {
  const SmartTilePublicationResult({
    required this.published,
    required this.manifest,
    required this.diagnostics,
  });

  final bool published;
  final ProjectManifest manifest;
  final List<SmartTileDiagnostic> diagnostics;
}

/// Validates and publishes one Smart Tile preset as a single immutable change.
///
/// No partial catalog mutation is returned when a blocking diagnostic exists.
class SmartTilePublicationService {
  const SmartTilePublicationService();

  SmartTilePublicationResult publish({
    required ProjectManifest manifest,
    required String presetId,
  }) {
    final catalog = manifest.smartTileCatalog;
    final presetIndex =
        catalog.presets.indexWhere((preset) => preset.id == presetId);
    if (presetIndex < 0) {
      return SmartTilePublicationResult(
        published: false,
        manifest: manifest,
        diagnostics: <SmartTileDiagnostic>[
          SmartTileDiagnostic(
            code: 'smart_tiles.reference.preset_missing',
            severity: SmartTileDiagnosticSeverity.error,
            path: r'$.smartTileCatalog.presets',
            message: 'Missing Smart Tile preset "$presetId".',
            presetId: presetId,
          ),
        ],
      );
    }

    final presets = List<ProjectSmartTilePreset>.from(catalog.presets);
    presets[presetIndex] = presets[presetIndex].copyWith(
      status: SmartTilePresetStatus.published,
    );
    final publishedCatalog = ProjectSmartTileCatalog(
      formatVersion: catalog.formatVersion,
      categories: catalog.categories,
      atlases: catalog.atlases,
      materials: catalog.materials,
      animations: catalog.animations,
      presets: presets,
    );
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: publishedCatalog,
      projectTilesetIds: manifest.tilesets.map((tileset) => tileset.id),
    );
    if (diagnostics.any((item) => item.isError)) {
      return SmartTilePublicationResult(
        published: false,
        manifest: manifest,
        diagnostics: diagnostics,
      );
    }

    return SmartTilePublicationResult(
      published: true,
      manifest: manifest.copyWith(
        version: ProjectVersion.v4,
        smartTileCatalog: publishedCatalog,
      ),
      diagnostics: diagnostics,
    );
  }
}
