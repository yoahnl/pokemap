import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Selbrume stone-chain V1 publishes from its 16 real sprites', () async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    final projectFile = File(p.join(projectRoot, 'project.json'));
    final projectBytesBefore = await projectFile.readAsBytes();
    final projectJson =
        jsonDecode(utf8.decode(projectBytesBefore)) as Map<String, Object?>;
    var manifest = ProjectManifest.fromJson(projectJson);

    expect(
      manifest.borderCatalog.formatVersion,
      ProjectBorderCatalog.formatVersionV4,
    );
    final initialSnapshotCount = manifest.borderCatalog.visualSnapshots.length;
    expect(initialSnapshotCount, greaterThanOrEqualTo(16));
    expect(
      manifest.borderCatalog.records.map((record) => record.id),
      containsAll(<String>['border-blueprint-1', 'border-blueprint-2']),
    );
    final historical = manifest.borderCatalog.recordById('border-blueprint-2');
    expect(historical, isNotNull);
    expect(historical!.latestPublished!.revision, 5);

    final tileset = manifest.tilesets.singleWhere(
      (entry) => entry.id == 'ts_selbrume_cliff_stone_chain_v1',
    );
    expect(
      tileset.relativePath,
      'assets/tilesets/falaises_selbrume_pierres_chaine_v1.png',
    );
    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    for (var index = 0; index < _elementIds.length; index += 1) {
      final element = elementsById[_elementIds[index]];
      expect(element, isNotNull, reason: _elementIds[index]);
      expect(element!.tilesetId, tileset.id);
      expect(element.collisionProfile, isNull);
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source.width, 1);
      expect(element.frames.single.source.height, 1);
      expect(element.frames.single.source.x, index % 4);
      expect(element.frames.single.source.y, index ~/ 4);
    }

    var record = manifest.borderCatalog.recordById('border-blueprint-3');
    expect(record, isNotNull);
    final initialPublishedRevision = record!.latestPublished?.revision ?? 0;
    expect(record.draft.baseRevision, initialPublishedRevision);
    expect(
      record.draft.definition.name,
      'Falaises Selbrume — chaîne de pierres',
    );
    expect(
      record.draft.definition.template,
      BorderBlueprintTemplate.stoneChainLine,
    );
    expect(record.draft.definition.defaults, _stoneChainDefaults());
    expect(record.draft.definition.primitives, hasLength(16));
    final activeDraftPrimitiveCount = record.draft.definition.primitives
        .where((primitive) => primitive.weight > 0)
        .length;
    expect(activeDraftPrimitiveCount, 13);
    expect(
      _roleCounts(record.draft.definition.primitives),
      <BorderPrimitiveRole, int>{
        BorderPrimitiveRole.structureLarge: 5,
        BorderPrimitiveRole.structureMedium: 4,
        BorderPrimitiveRole.filler: 3,
        BorderPrimitiveRole.lineCorner: 2,
        BorderPrimitiveRole.lineCap: 2,
      },
    );
    expect(
      record.draft.definition.primitives.map(
        (primitive) => primitive.sourceElementId,
      ),
      orderedEquals(_elementIds),
    );

    const assetService = BorderProjectElementAssetService();
    final refreshedPrimitives = <BorderPrimitiveDraft>[];
    for (final primitive in record.draft.definition.primitives) {
      final refreshed = await assetService.reanalyze(
        manifest: manifest,
        projectRootPath: projectRoot,
        primitive: primitive,
      );
      expect(
        refreshed.primitive.currentMetrics,
        primitive.currentMetrics,
        reason: '${primitive.id} must be saved with current source metrics.',
      );
      refreshedPrimitives.add(refreshed.primitive);
    }
    final definition = record.draft.definition;
    record = BorderBlueprintRecord(
      id: record.id,
      draft: BorderBlueprintDraft(
        baseRevision: record.draft.baseRevision,
        definition: BorderBlueprintDraftDefinition(
          name: definition.name,
          previewSeed: definition.previewSeed,
          template: definition.template,
          primitives: refreshedPrimitives,
          defaults: _stoneChainDefaults(depthRows: 1),
          ground: definition.ground,
          categoryId: definition.categoryId,
          sortOrder: definition.sortOrder,
        ),
      ),
      latestPublished: record.latestPublished,
      isDeprecated: record.isDeprecated,
    );
    manifest = replaceProjectBorderCatalog(
      manifest,
      ProjectBorderCatalog(
        formatVersion: manifest.borderCatalog.formatVersion,
        records: <BorderBlueprintRecord>[
          for (final candidate in manifest.borderCatalog.records)
            if (candidate.id == record.id) record else candidate,
        ],
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
      ),
    );

    BorderPublicationRequest? publicationRequest;
    final coordinator = BorderStudioPublicationCoordinator(
      prepareProjectElementAsset: assetService.prepare,
      buildCandidate: const BorderPublicationCandidateBuilder().build,
      resolveCanonicalGallery: ({
        required blueprintId,
        required blueprintRevision,
        required visualSnapshots,
        required tileSizePx,
        required resolverVersion,
      }) =>
          BorderStudioCanonicalGalleryResolution.fromCore(
        resolveBorderCanonicalGallery(
          blueprintId: blueprintId,
          blueprintRevision: blueprintRevision,
          visualSnapshots: visualSnapshots,
          tileSizePx: tileSizePx,
          resolverVersion: resolverVersion,
        ),
      ),
      publishRequest: (request) async {
        publicationRequest = request;
        return BorderPublicationResult(
          manifest: request.nextManifest,
          diagnostics: const BorderDiagnosticsReport.empty(),
          snapshotFinalize: BorderAssetSnapshotFinalizeResult(
            createdRelativePaths: <String>[
              for (final file in request.files) file.relativePath,
            ],
            deduplicatedRelativePaths: const <String>[],
          ),
        );
      },
    );

    final historicalSnapshotIds = <String>{
      for (final snapshot in manifest.borderCatalog.visualSnapshots)
        snapshot.id,
    };
    final preview = await coordinator.prepare(
      manifest: manifest,
      projectRootPath: projectRoot,
      draftRecord: record,
    );
    final diagnostics = _diagnostics(preview.diagnostics);
    final closedLoopCoverage = preview.canonicalGalleryCases
        .singleWhere(
          (galleryCase) =>
              galleryCase.galleryCase == BorderCanonicalGalleryCase.closedLoop,
        )
        .publicationSample
        .coverageChecks;
    for (final coverage in closedLoopCoverage) {
      expect(
        coverage.longestContiguousGapPx,
        lessThanOrEqualTo(coverage.gapTolerancePx),
        reason: 'The real Selbrume closed-loop lattice must cover every leg.',
      );
    }
    expect(
      preview.canonicalGalleryCases.map(
        (galleryCase) => galleryCase.galleryCase.name,
      ),
      orderedEquals(<String>[
        'longEdge',
        'sharpCorner',
        'endpoint',
        'sBend',
        'closedLoop',
      ]),
    );
    for (final galleryCase in preview.canonicalGalleryCases) {
      expect(
        galleryCase.resolution.canApply,
        isTrue,
        reason: '${galleryCase.galleryCase.name} primary:\n'
            '${_diagnostics(galleryCase.resolution.diagnosticReport)}',
      );
      expect(galleryCase.invertedResolution, isNotNull, reason: diagnostics);
      expect(
        galleryCase.invertedResolution!.canApply,
        isTrue,
        reason: '${galleryCase.galleryCase.name} inverted:\n'
            '${_diagnostics(galleryCase.invertedResolution!.diagnosticReport)}',
      );
    }
    expect(preview.diagnostics.hasErrors, isFalse, reason: diagnostics);

    final candidate = preview.candidate;
    final candidateSnapshots =
        candidate.nextManifest.borderCatalog.visualSnapshots;
    final newSnapshots = candidateSnapshots
        .where((snapshot) => !historicalSnapshotIds.contains(snapshot.id))
        .toList(growable: false);
    expect(
      candidateSnapshots.length,
      inInclusiveRange(
        initialSnapshotCount,
        initialSnapshotCount + activeDraftPrimitiveCount,
      ),
    );
    expect(newSnapshots.length, lessThanOrEqualTo(activeDraftPrimitiveCount));
    expect(
      newSnapshots.map((snapshot) => snapshot.id).toSet(),
      hasLength(newSnapshots.length),
    );
    expect(
        candidate.files.length, lessThanOrEqualTo(activeDraftPrimitiveCount));
    expect(
      candidate.files.map((file) => file.relativePath).toSet(),
      hasLength(candidate.files.length),
    );
    final candidateSnapshotIds = <String>{
      for (final snapshot in candidateSnapshots) snapshot.id,
    };
    final candidateRecord = candidate.nextManifest.borderCatalog.recordById(
      'border-blueprint-3',
    )!;
    expect(
      candidateRecord.latestPublished!.definition.primitives.map(
        (primitive) => primitive.visualSnapshotId,
      ),
      everyElement(isIn(candidateSnapshotIds)),
    );
    for (final snapshot in newSnapshots) {
      expect(snapshot.frames, hasLength(1));
      expect(snapshot.frames.single.sourceRectPx.width, 32);
      expect(snapshot.frames.single.sourceRectPx.height, 32);
    }
    for (final file in candidate.files) {
      final image = img.decodePng(file.bytes);
      expect(image, isNotNull, reason: file.relativePath);
      expect((image!.width, image.height), (32, 32));
    }

    final publication = await coordinator.publish(
      preview: preview,
      currentManifest: manifest,
      currentDraftRecord: record,
      acknowledgedWarningCodes: preview.warningCodes,
    );
    expect(publicationRequest, isNotNull);
    expect(
      publication.snapshotFinalize.createdRelativePaths,
      hasLength(candidate.files.length),
    );
    expect(publication.snapshotFinalize.deduplicatedRelativePaths, isEmpty);
    final publishedRecord = publication.manifest.borderCatalog.recordById(
      'border-blueprint-3',
    )!;
    expect(
      publishedRecord.latestPublished!.revision,
      initialPublishedRevision + 1,
    );
    expect(publishedRecord.draft.baseRevision, initialPublishedRevision + 1);
    expect(
      publishedRecord.latestPublished!.definition.defaults.allowAutoRotation,
      isFalse,
    );

    final publishedRevision = publishedRecord.latestPublished!;
    final benchFeatures = _visualBenchFeatures();
    expect(benchFeatures, hasLength(8));
    for (var index = 0; index < benchFeatures.length; index += 1) {
      final result = resolveBorderFeature(
        BorderResolutionRequest(
          mapSize: const GridSize(width: 16, height: 12),
          tileSizePx: const GridSize(width: 32, height: 32),
          blueprintId: publishedRecord.id,
          blueprintRevision: publishedRevision,
          feature: benchFeatures[index],
          visualSnapshots: publication.manifest.borderCatalog.visualSnapshots,
          resolverVersion: borderResolverVersion,
        ),
      );
      expect(
        result.canApply,
        isTrue,
        reason: 'bench ${index + 1}: ${_diagnostics(result.diagnosticReport)}',
      );
      expect(result.materialization!.placements, isNotEmpty);
      if (index < 7) {
        expect(
          result.materialization!.placements.map(
            (placement) => placement.transform.quarterTurns,
          ),
          everyElement(0),
        );
      }
    }

    expect(await projectFile.readAsBytes(), orderedEquals(projectBytesBefore));
  });
}

const _elementIds = <String>[
  'el_selbrume_cliff_chain_primary_01',
  'el_selbrume_cliff_chain_primary_02',
  'el_selbrume_cliff_chain_primary_03',
  'el_selbrume_cliff_chain_primary_04',
  'el_selbrume_cliff_chain_primary_05',
  'el_selbrume_cliff_chain_secondary_01',
  'el_selbrume_cliff_chain_secondary_02',
  'el_selbrume_cliff_chain_secondary_03',
  'el_selbrume_cliff_chain_secondary_04',
  'el_selbrume_cliff_chain_filler_01',
  'el_selbrume_cliff_chain_filler_02',
  'el_selbrume_cliff_chain_filler_03',
  'el_selbrume_cliff_chain_corner_01',
  'el_selbrume_cliff_chain_corner_02',
  'el_selbrume_cliff_chain_cap_01',
  'el_selbrume_cliff_chain_cap_02',
];

BorderGenerationParams _stoneChainDefaults({
  bool allowAutoRotation = false,
  int depthRows = 2,
}) =>
    BorderGenerationParams(
      irregularityPermille: 280,
      detailDensityPermille: 300,
      variationPermille: 900,
      maxOverlapPx: 3,
      gapTolerancePx: 4,
      depthRows: depthRows,
      allowAutoRotation: allowAutoRotation,
    );

Map<BorderPrimitiveRole, int> _roleCounts(
  List<BorderPrimitiveDraft> primitives,
) {
  final counts = <BorderPrimitiveRole, int>{};
  for (final primitive in primitives) {
    counts.update(primitive.role, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

String _diagnostics(BorderDiagnosticsReport report) => report.diagnostics
    .map(
      (diagnostic) => '${diagnostic.severity.name}: ${diagnostic.code} '
          '${diagnostic.parameters}',
    )
    .join('\n');

List<BorderFeature> _visualBenchFeatures() {
  final horizontal = _stroke('horizontal', const <GridPos>[
    GridPos(x: 2, y: 6),
    GridPos(x: 3, y: 6),
    GridPos(x: 4, y: 6),
    GridPos(x: 5, y: 6),
    GridPos(x: 6, y: 6),
    GridPos(x: 7, y: 6),
    GridPos(x: 8, y: 6),
    GridPos(x: 9, y: 6),
    GridPos(x: 10, y: 6),
    GridPos(x: 11, y: 6),
    GridPos(x: 12, y: 6),
    GridPos(x: 13, y: 6),
  ]);
  final vertical = _stroke('vertical', const <GridPos>[
    GridPos(x: 8, y: 1),
    GridPos(x: 8, y: 2),
    GridPos(x: 8, y: 3),
    GridPos(x: 8, y: 4),
    GridPos(x: 8, y: 5),
    GridPos(x: 8, y: 6),
    GridPos(x: 8, y: 7),
    GridPos(x: 8, y: 8),
    GridPos(x: 8, y: 9),
    GridPos(x: 8, y: 10),
  ]);
  final corner = _stroke('corner', const <GridPos>[
    GridPos(x: 2, y: 2),
    GridPos(x: 3, y: 2),
    GridPos(x: 4, y: 2),
    GridPos(x: 5, y: 2),
    GridPos(x: 6, y: 2),
    GridPos(x: 7, y: 2),
    GridPos(x: 8, y: 2),
    GridPos(x: 9, y: 2),
    GridPos(x: 10, y: 2),
    GridPos(x: 10, y: 3),
    GridPos(x: 10, y: 4),
    GridPos(x: 10, y: 5),
    GridPos(x: 10, y: 6),
    GridPos(x: 10, y: 7),
    GridPos(x: 10, y: 8),
    GridPos(x: 10, y: 9),
  ]);
  final sBend = _stroke('s-bend', const <GridPos>[
    GridPos(x: 2, y: 2),
    GridPos(x: 3, y: 2),
    GridPos(x: 4, y: 2),
    GridPos(x: 5, y: 2),
    GridPos(x: 6, y: 2),
    GridPos(x: 7, y: 2),
    GridPos(x: 7, y: 3),
    GridPos(x: 7, y: 4),
    GridPos(x: 7, y: 5),
    GridPos(x: 7, y: 6),
    GridPos(x: 7, y: 7),
    GridPos(x: 8, y: 7),
    GridPos(x: 9, y: 7),
    GridPos(x: 10, y: 7),
    GridPos(x: 11, y: 7),
    GridPos(x: 12, y: 7),
    GridPos(x: 13, y: 7),
  ]);
  final loop = BorderStroke(
    id: 'loop',
    points: const <GridPos>[
      GridPos(x: 4, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 6, y: 3),
      GridPos(x: 7, y: 3),
      GridPos(x: 8, y: 3),
      GridPos(x: 9, y: 3),
      GridPos(x: 10, y: 3),
      GridPos(x: 11, y: 3),
      GridPos(x: 11, y: 4),
      GridPos(x: 11, y: 5),
      GridPos(x: 11, y: 6),
      GridPos(x: 11, y: 7),
      GridPos(x: 11, y: 8),
      GridPos(x: 10, y: 8),
      GridPos(x: 9, y: 8),
      GridPos(x: 8, y: 8),
      GridPos(x: 7, y: 8),
      GridPos(x: 6, y: 8),
      GridPos(x: 5, y: 8),
      GridPos(x: 4, y: 8),
      GridPos(x: 4, y: 7),
      GridPos(x: 4, y: 6),
      GridPos(x: 4, y: 5),
      GridPos(x: 4, y: 4),
    ],
    closed: true,
  );
  return <BorderFeature>[
    _feature('horizontal', horizontal),
    _feature('vertical', vertical),
    _feature('corner-primary', corner),
    _feature('corner-inverted', corner, side: BorderLineSide.inverted),
    _feature('s-primary', sBend),
    _feature('loop', loop),
    _feature('s-inverted', sBend, side: BorderLineSide.inverted),
    _feature(
      'corner-rotation',
      corner,
      parameters: _stoneChainDefaults(
        allowAutoRotation: true,
        depthRows: 1,
      ),
    ),
  ];
}

BorderStroke _stroke(String id, List<GridPos> points) => BorderStroke(
      id: id,
      points: points,
      closed: false,
    );

BorderFeature _feature(
  String id,
  BorderStroke stroke, {
  BorderLineSide side = BorderLineSide.primary,
  BorderGenerationParams? parameters,
}) =>
    BorderFeature(
      id: 'stone-chain-$id',
      name: id,
      blueprintId: 'border-blueprint-3',
      seed: BorderSignedInt64.fromInt(71),
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[stroke],
        alignment: BorderStrokeAlignment.gridEdges,
      ),
      lineSide: side,
      paramsOverride: parameters,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
