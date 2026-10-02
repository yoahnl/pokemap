import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_catalog_fixture.dart';
import 'resource_usage_projection_test.dart' show decor, planche, noPokemon;

void main() {
  test('published and draft borders retain their unplaced source element', () {
    final metrics = BorderPrimitiveAssetMetrics(
      assetFingerprint: 'pixel-metrics',
      pixelSize: const GridSize(width: 32, height: 32),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
      defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
      occupancyMaskRle: encodeBorderRleMask(List.filled(32 * 32, true)),
    );
    final transforms = BorderTransformPolicy(
        allowedQuarterTurns: const [0], allowFlipX: false);
    final defaults = BorderGenerationParams(
        irregularityPermille: 0,
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1,
        allowAutoRotation: false);
    final draft = BorderBlueprintDraftDefinition(
        name: 'Haie',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        primitives: [
          BorderPrimitiveDraft(
              id: 'piece',
              sourceElementId: decor.id,
              role: BorderPrimitiveRole.lineStraight,
              weight: 1000,
              anchorPx: const BorderPixelPos(x: 0, y: 0),
              transforms: transforms,
              currentMetrics: metrics)
        ],
        defaults: defaults,
        sortOrder: 0);
    final published = BorderBlueprintPublishedDefinition(
        name: 'Haie publiée',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        primitives: [
          BorderPublishedPrimitive(
              id: 'piece',
              sourceElementId: decor.id,
              visualSnapshotId: 'frozen-snapshot',
              role: BorderPrimitiveRole.lineStraight,
              weight: 1000,
              anchorPx: const BorderPixelPos(x: 0, y: 0),
              transforms: transforms,
              publishedMetrics: metrics)
        ],
        defaults: defaults,
        sortOrder: 0);
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        pokemon: noPokemon,
        tilesets: [planche],
        elements: [decor],
        borderCatalog: ProjectBorderCatalog(formatVersion: 4, records: [
          BorderBlueprintRecord(
              id: 'hedge',
              draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
              latestPublished:
                  BorderBlueprintRevision(revision: 1, definition: published)),
        ]));
    final report = const ResourceUsageProjection().analyze(
        catalogSnapshot([], project: manifest),
        const ResourceUsageTarget(family: 'images', id: 'shared'));
    final borders =
        report.entries.where((entry) => entry.ownerKind == 'border');
    expect(borders, hasLength(2));
    expect(
        borders.any((entry) =>
            entry.location.contains('latestPublished') &&
            entry.relation == ResourceUsageRelation.indirect),
        isTrue);
    expect(
        borders.any((entry) =>
            entry.location.contains('draft') &&
            entry.relation == ResourceUsageRelation.technical),
        isTrue);
  });

  test('frozen border visual retains its own exact copied image path', () {
    final hash = List.filled(64, 'a').join();
    const path = 'assets/borders/snapshots/image.png';
    final snapshot = BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$hash',
      contentFingerprint: hash,
      frames: [
        BorderVisualFrameSnapshot(
            relativeAssetPath: path,
            sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
            durationMs: 120)
      ],
    );
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        pokemon: noPokemon,
        tilesets: [planche.copyWith(relativePath: path)],
        borderCatalog: ProjectBorderCatalog(
            formatVersion: 4, visualSnapshots: [snapshot]));
    final report = const ResourceUsageProjection().analyze(
        catalogSnapshot([], project: manifest),
        const ResourceUsageTarget(family: 'images', id: 'shared'));
    final retained = report.entries
        .singleWhere((entry) => entry.ownerKind == 'borderSnapshot');
    expect(retained.ownerId, snapshot.id);
    expect(retained.relation, ResourceUsageRelation.technical);
    expect(retained.location.endsWith('frames[0].relativeAssetPath'), isTrue);
    final original = const ResourceUsageProjection().analyze(
        catalogSnapshot([], project: manifest.copyWith(tilesets: [planche])),
        const ResourceUsageTarget(family: 'images', id: 'shared'));
    expect(original.entries.any((entry) => entry.ownerKind == 'borderSnapshot'),
        isFalse);
  });
}
