import 'dart:convert';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../maps/map_catalog_fixture.dart';
import 'resource_information_actions_test.dart' show informationFixture;

final elementPixels = image.encodePng(image.Image(width: 64, height: 64));
final elementArtifact =
    ContentArtifactRef.fromBytes(elementPixels, mediaType: 'image/png');
final elementCatalog = AssetCatalog(records: [
  AssetRecord(
      id: 'image', logicalPath: 'assets/source.png', artifact: elementArtifact)
]);

ProjectManifest elementDefinitionFixture({bool animated = false}) {
  final original = informationFixture();
  return original.copyWith(
    pokemon: original.pokemon.copyWith(enabled: false),
    elements: [
      original.elements.single.copyWith(
        frames: [
          const TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0), durationMs: 140),
          if (animated)
            const TilesetVisualFrame(
                source: TilesetSourceRect(x: 1, y: 0), durationMs: 260),
        ],
        collisionProfile: const ElementCollisionProfile(
          source: ElementCollisionProfileSource.manual,
          shapeCells: [GridPos(x: 0, y: 0)],
          cells: [GridPos(x: 0, y: 0)],
          manualAddedCells: [GridPos(x: 0, y: 0)],
        ),
        shadow: ProjectElementShadowConfig(
            castsShadow: true, shadowProfileId: 'shadow', offsetX: 2),
        recommendedLayerId: 'objects',
        sortOrder: 7,
      )
    ],
  );
}

ProjectSnapshot elementSnapshot(ProjectManifest manifest,
    {List<MapData> maps = const [],
    Map<String, Object?> additionalDocuments = const {},
    Map<String, Object?>? originalProject}) {
  final base = catalogSnapshot(maps, project: manifest);
  final bytes = {
    'project': originalProject == null
        ? base.resourceBytes('project')
        : utf8.encode(jsonEncode(originalProject)),
    for (final map in maps)
      'map:${map.id}': base.resourceBytes('map:${map.id}'),
    assetCatalogResourceIdentity:
        utf8.encode(jsonEncode(elementCatalog.toJson())),
    assetBlobResourceIdentity(elementArtifact.digest): elementPixels,
    'assetLogical:image': elementPixels,
    for (final entry in additionalDocuments.entries)
      entry.key: utf8.encode(jsonEncode(entry.value)),
  };
  return ProjectSnapshot(
    projectHandle: base.projectHandle,
    revision: base.revision,
    manifest: manifest,
    maps: maps,
    pokemonInventoryComplete: true,
    resourceFingerprints: {
      for (final entry in bytes.entries)
        entry.key: computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
              relativePath: entry.key == 'project' ? 'project.json' : entry.key,
              bytes: entry.value),
        ]),
    },
    resourceBytes: bytes,
  );
}

Map<String, Object?> duplicateParameters({String newId = 'copy'}) => {
      'sourceElementId': 'decor',
      'newElementId': newId,
      'name': '  Décor — copie  ',
      'categoryId': 'shared',
    };

ProjectBorderCatalog retainedElementBorder() => ProjectBorderCatalog(
      formatVersion: 4,
      records: [
        BorderBlueprintRecord(
          id: 'border',
          draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: BorderBlueprintDraftDefinition(
              name: 'Bordure préparée',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.connectedLine,
              primitives: [
                BorderPrimitiveDraft(
                  id: 'piece',
                  sourceElementId: 'decor',
                  role: BorderPrimitiveRole.lineStraight,
                  weight: 1000,
                  anchorPx: const BorderPixelPos(x: 0, y: 0),
                  transforms: BorderTransformPolicy(
                      allowedQuarterTurns: [0], allowFlipX: false),
                  currentMetrics: BorderPrimitiveAssetMetrics(
                      assetFingerprint: 'fixture',
                      pixelSize: const GridSize(width: 32, height: 32),
                      opaqueBounds:
                          BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
                      defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
                      occupancyMaskRle:
                          encodeBorderRleMask(List.filled(32 * 32, true))),
                ),
              ],
              defaults: BorderGenerationParams(
                  irregularityPermille: 0,
                  detailDensityPermille: 0,
                  variationPermille: 0,
                  maxOverlapPx: 0,
                  gapTolerancePx: 0,
                  depthRows: 1,
                  allowAutoRotation: false),
              sortOrder: 0,
            ),
          ),
        ),
      ],
    );
