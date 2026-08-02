import 'package:map_core/map_core.dart';

import 'smart_tile_authoring_controller.dart'
    show smartTileStudioAuthoringRequiresStn04Code;

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
    // Canonical publication is owned by map_authoring. The private Studio
    // draft service remains non-persistent until STN-04 wires that API into
    // the guided no-code flow.
    return SmartTilePublicationResult(
      published: false,
      manifest: manifest,
      diagnostics: <SmartTileDiagnostic>[
        SmartTileDiagnostic(
          code: smartTileStudioAuthoringRequiresStn04Code,
          severity: SmartTileDiagnosticSeverity.error,
          path: r'$.smartTileCatalog.presets',
          message: 'Smart Tiles Studio publication requires the STN-04 '
              'no-code adapter. Use the canonical smart_tile.preset.publish '
              'action until that UI wiring is available.',
          presetId: presetId,
        ),
      ],
    );
  }
}
