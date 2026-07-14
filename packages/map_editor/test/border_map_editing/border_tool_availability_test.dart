import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_tool_availability.dart';

void main() {
  group('assessBorderToolAvailability', () {
    test('requires an active Border layer and active feature', () {
      final result = assessBorderToolAvailability(
        manifest: _manifest(BorderBlueprintTemplate.organicEdge),
        map: _map(),
        activeLayerId: null,
        activeFeatureId: null,
      );

      expect(result.isEnabled, isFalse);
      expect(result.disabledReason, isNotEmpty);
      expect(
        result.permanentSafetyMessage,
        'Visuel uniquement — aucune collision',
      );
    });

    test('enables a published blueprint with matching region geometry', () {
      final result = assessBorderToolAvailability(
        manifest: _manifest(BorderBlueprintTemplate.organicEdge),
        map: _map(),
        activeLayerId: 'borders',
        activeFeatureId: 'coast',
      );

      expect(result.isEnabled, isTrue);
      expect(result.disabledReason, isNull);
      expect(result.blueprintRevision, 1);
    });

    test('rejects missing publication and geometry-family mismatch', () {
      final unpublished = _manifest(
        BorderBlueprintTemplate.organicEdge,
        published: false,
      );
      expect(
        assessBorderToolAvailability(
          manifest: unpublished,
          map: _map(),
          activeLayerId: 'borders',
          activeFeatureId: 'coast',
        ).isEnabled,
        isFalse,
      );

      final line = assessBorderToolAvailability(
        manifest: _manifest(BorderBlueprintTemplate.masonryLine),
        map: _map(),
        activeLayerId: 'borders',
        activeFeatureId: 'coast',
      );
      expect(line.isEnabled, isFalse);
      expect(line.disabledReason, contains('géométrie'));
    });
  });
}

ProjectManifest _manifest(
  BorderBlueprintTemplate template, {
  bool published = true,
}) {
  final draftDefinition = BorderBlueprintDraftDefinition(
    name: 'Coast',
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: const <BorderPrimitiveDraft>[],
    defaults: _params(),
    sortOrder: 0,
  );
  return ProjectManifest(
    name: 'Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: 'blueprint',
          draft: BorderBlueprintDraft(
            baseRevision: published ? 1 : 0,
            definition: draftDefinition,
          ),
          latestPublished: published
              ? BorderBlueprintRevision(
                  revision: 1,
                  definition: BorderBlueprintPublishedDefinition(
                    name: 'Coast',
                    previewSeed: BorderSignedInt64.zero,
                    template: template,
                    primitives: const <BorderPublishedPrimitive>[],
                    defaults: _params(),
                    sortOrder: 0,
                  ),
                )
              : null,
        ),
      ],
    ),
  );
}

MapData _map() => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Coast',
                blueprintId: 'blueprint',
                seed: BorderSignedInt64.zero,
                geometry: BorderRegionGeometry(
                  width: 3,
                  height: 3,
                  cells: List<bool>.filled(9, false),
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
    );

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );
