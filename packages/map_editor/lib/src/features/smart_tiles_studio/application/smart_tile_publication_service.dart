import 'package:map_core/map_core.dart';

import 'smart_tile_authoring_controller.dart'
    show smartTileNativeCatalogAuthoringRequiresStn03Code;

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
    // STN-01 can compile and validate in-memory drafts, but publication must
    // remain atomic with the map/catalog transition introduced by STN-03.
    // Returning the original object makes accidental persistence observable
    // and guarantees that no partial v4/v5 manifest can escape this service.
    return SmartTilePublicationResult(
      published: false,
      manifest: manifest,
      diagnostics: <SmartTileDiagnostic>[
        SmartTileDiagnostic(
          code: smartTileNativeCatalogAuthoringRequiresStn03Code,
          severity: SmartTileDiagnosticSeverity.error,
          path: r'$.smartTileCatalog.presets',
          message: 'Native Smart Tile catalog publication is deferred until '
              'STN-03 can update the manifest and maps atomically.',
          presetId: presetId,
        ),
      ],
    );
  }
}
