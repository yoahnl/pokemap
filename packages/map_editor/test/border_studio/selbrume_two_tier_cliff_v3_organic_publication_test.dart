import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Selbrume V3 organic cliff passes every canonical publication case',
      () async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    final projectFile = File(p.join(projectRoot, 'project.json'));
    final projectBytesBefore = await projectFile.readAsBytes();
    var manifest = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(projectBytesBefore)) as Map<String, Object?>,
    );
    var record = manifest.borderCatalog.recordById('border-blueprint-5');
    expect(record, isNotNull);

    const assetService = BorderProjectElementAssetService();
    final refreshedPrimitives = <BorderPrimitiveDraft>[];
    for (final primitive in record!.draft.definition.primitives) {
      final refreshed = await assetService.reanalyze(
        manifest: manifest,
        projectRootPath: projectRoot,
        primitive: primitive,
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
          defaults: definition.defaults,
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
      publishRequest: (_) => throw UnsupportedError('prepare only'),
    );
    final preview = await coordinator.prepare(
      manifest: manifest,
      projectRootPath: projectRoot,
      draftRecord: record,
    );
    final diagnostics = preview.diagnostics.diagnostics
        .map(
          (item) => '${item.severity.name}: ${item.code} '
              '${item.parameters}',
        )
        .join('\n');

    expect(preview.canonicalGalleryCases, hasLength(5));
    expect(preview.diagnostics.hasErrors, isFalse, reason: diagnostics);
    for (final galleryCase in preview.canonicalGalleryCases) {
      expect(
        galleryCase.resolution.canApply,
        isTrue,
        reason: '${galleryCase.galleryCase.name} primary\n$diagnostics',
      );
      expect(
        galleryCase.invertedResolution?.canApply,
        isTrue,
        reason: '${galleryCase.galleryCase.name} inverted\n$diagnostics',
      );
      for (final evidence in <BorderPublicationStoneChainEvidence?>[
        galleryCase.publicationSample.primaryStoneChainEvidence,
        galleryCase.publicationSample.invertedStoneChainEvidence,
      ]) {
        expect(evidence, isNotNull, reason: galleryCase.galleryCase.name);
        expect(
            evidence!.minimumCrossRowInterlockPixels, greaterThanOrEqualTo(8));
        expect(evidence.minimumVisibleFaceDepthPx, greaterThanOrEqualTo(12));
      }
    }

    final candidateManifest = preview.candidate.nextManifest;
    final candidateRevision =
        candidateManifest.borderCatalog.recordById(record.id)!.latestPublished!;
    for (final seed in <int>[7, 19072026]) {
      final resolution = resolveStoneChainLineBorder(
        BorderResolutionRequest(
          mapSize: const GridSize(width: 40, height: 40),
          tileSizePx: const GridSize(width: 32, height: 32),
          blueprintId: record.id,
          blueprintRevision: candidateRevision,
          feature: BorderFeature(
            id: 'production-diversity-$seed',
            name: 'Production diversity $seed',
            blueprintId: record.id,
            seed: BorderSignedInt64.fromInt(seed),
            geometry: BorderStrokeGeometry(
              strokes: <BorderStroke>[
                BorderStroke(
                  id: 'production-straight',
                  points: <GridPos>[
                    for (var x = 2; x <= 32; x += 1) GridPos(x: x, y: 20),
                  ],
                  closed: false,
                ),
              ],
              alignment: BorderStrokeAlignment.gridEdges,
            ),
            lineSide: BorderLineSide.primary,
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
          visualSnapshots: candidateManifest.borderCatalog.visualSnapshots,
          resolverVersion: borderResolverVersion,
        ),
      );
      expect(resolution.canApply, isTrue, reason: diagnostics);
      final roleByPrimitiveId = <String, BorderPrimitiveRole>{
        for (final primitive in candidateRevision.definition.primitives)
          primitive.id: primitive.role,
      };
      for (final role in <BorderPrimitiveRole>[
        BorderPrimitiveRole.structureLarge,
        BorderPrimitiveRole.structureMedium,
      ]) {
        final ordered = resolution.materialization!.placements
            .where(
                (placement) => roleByPrimitiveId[placement.primitiveId] == role)
            .toList(growable: false)
          ..sort((left, right) {
            final byX = left.opaqueWorldBoundsPx.x
                .compareTo(right.opaqueWorldBoundsPx.x);
            return byX != 0 ? byX : left.slotKey.compareTo(right.slotKey);
          });
        final primitiveIds = ordered
            .map((placement) => placement.primitiveId)
            .toList(growable: false);
        expect(primitiveIds.toSet().length, greaterThanOrEqualTo(4));
        _expectNoRepeatedShortBlocks(
          primitiveIds,
          reason: 'seed $seed, ${role.name}',
        );
      }
    }

    final primitiveById = <String, BorderPublishedPrimitive>{
      for (final primitive in candidateRevision.definition.primitives)
        primitive.id: primitive,
    };
    final topologyVariantsByRole = <BorderPrimitiveRole, Set<String>>{
      BorderPrimitiveRole.structureLarge: <String>{},
      BorderPrimitiveRole.structureMedium: <String>{},
    };
    var topologyTopCount = 0;
    var topologyTop06Count = 0;
    for (final seed in <int>[7, 19072026]) {
      final request = BorderResolutionRequest(
        mapSize: const GridSize(width: 32, height: 32),
        tileSizePx: const GridSize(width: 32, height: 32),
        blueprintId: record.id,
        blueprintRevision: candidateRevision,
        feature: BorderFeature(
          id: 'production-topology-diversity-$seed',
          name: 'Production topology diversity $seed',
          blueprintId: record.id,
          seed: BorderSignedInt64.fromInt(seed),
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[
              BorderStroke(
                id: 'production-long-l',
                points: <GridPos>[
                  for (var x = 4; x <= 18; x += 1) GridPos(x: x, y: 8),
                  for (var y = 9; y <= 23; y += 1) GridPos(x: 18, y: y),
                ],
                closed: false,
              ),
            ],
            alignment: BorderStrokeAlignment.gridEdges,
          ),
          lineSide: BorderLineSide.primary,
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
        visualSnapshots: candidateManifest.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      final resolution = resolveStoneChainLineBorder(request);
      final repeated = seed == 7 ? resolveStoneChainLineBorder(request) : null;
      final resolutionDiagnostics = resolution.diagnostics
          .map(
            (item) => '${item.severity.name}: ${item.code} '
                '${item.parameters}',
          )
          .join('\n');

      expect(
        resolution.diagnosticReport.hasErrors,
        isFalse,
        reason: 'seed $seed\n$resolutionDiagnostics',
      );
      expect(
        resolution.canApply,
        isTrue,
        reason: 'seed $seed\n$resolutionDiagnostics',
      );
      if (repeated != null) {
        expect(repeated, resolution, reason: 'seed $seed determinism');
      }

      for (final role in <BorderPrimitiveRole>[
        BorderPrimitiveRole.structureLarge,
        BorderPrimitiveRole.structureMedium,
      ]) {
        final runsByOrientation =
            <BorderPrimitiveOrientation, List<BorderResolvedPlacement>>{};
        for (final placement in resolution.materialization!.placements) {
          final primitive = primitiveById[placement.primitiveId]!;
          if (primitive.role != role) continue;
          runsByOrientation
              .putIfAbsent(
                primitive.authoredOrientation,
                () => <BorderResolvedPlacement>[],
              )
              .add(placement);
          topologyVariantsByRole[role]!.add(
            _variantSuffix(placement.primitiveId),
          );
          if (role == BorderPrimitiveRole.structureLarge) {
            topologyTopCount += 1;
            if (_variantSuffix(placement.primitiveId) == '06') {
              topologyTop06Count += 1;
            }
          }
        }

        expect(
          runsByOrientation,
          hasLength(2),
          reason: 'seed $seed, ${role.name}: the L must exercise two runs',
        );
        for (final entry in runsByOrientation.entries) {
          final ordered = entry.value
            ..sort(
              (left, right) => _compareAlongAuthoredRun(
                entry.key,
                left,
                right,
              ),
            );
          final primitiveIds = ordered
              .map((placement) => placement.primitiveId)
              .toList(growable: false);
          expect(
            primitiveIds,
            hasLength(greaterThanOrEqualTo(8)),
            reason: 'seed $seed, ${role.name}, ${entry.key.name}',
          );
          _expectNoRepeatedShortBlocks(
            primitiveIds,
            reason: 'seed $seed, ${role.name}, ${entry.key.name}',
          );
        }
      }
    }

    const expectedVariants = <String>{'01', '02', '03', '04', '05', '06'};
    expect(
      topologyVariantsByRole[BorderPrimitiveRole.structureLarge],
      expectedVariants,
      reason: 'the real topological lip must cumulatively exercise every '
          'published top-stone variant',
    );
    expect(
      topologyVariantsByRole[BorderPrimitiveRole.structureMedium],
      expectedVariants,
      reason: 'the real topological face must cumulatively exercise every '
          'published face-stone variant',
    );
    expect(topologyTopCount, greaterThan(0));
    expect(
      topologyTop06Count * 8,
      lessThanOrEqualTo(topologyTopCount),
      reason: 'top-06 is the wide bridge fallback and must remain at or below '
          '12.5% of topological lip placements '
          '($topologyTop06Count / $topologyTopCount)',
    );

    final staircaseResolution = resolveStoneChainLineBorder(
      BorderResolutionRequest(
        mapSize: const GridSize(width: 32, height: 32),
        tileSizePx: const GridSize(width: 32, height: 32),
        blueprintId: record.id,
        blueprintRevision: candidateRevision,
        feature: BorderFeature(
          id: 'production-staircase-diversity',
          name: 'Production staircase diversity',
          blueprintId: record.id,
          seed: BorderSignedInt64.fromInt(19072026),
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[
              BorderStroke(
                id: 'production-staircase',
                points: <GridPos>[
                  const GridPos(x: 4, y: 4),
                  for (var step = 1; step <= 18; step += 1)
                    GridPos(
                      x: 4 + step ~/ 2,
                      y: 4 + (step + 1) ~/ 2,
                    ),
                ],
                closed: false,
              ),
            ],
            alignment: BorderStrokeAlignment.gridEdges,
          ),
          lineSide: BorderLineSide.primary,
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
        visualSnapshots: candidateManifest.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      ),
    );
    final staircaseDiagnostics = staircaseResolution.diagnostics
        .map((item) => '${item.severity.name}: ${item.code}')
        .join('\n');
    expect(
      staircaseResolution.canApply,
      isTrue,
      reason: staircaseDiagnostics,
    );
    final cornerVariants = <String, int>{};
    for (final placement in staircaseResolution.materialization!.placements) {
      final primitive = primitiveById[placement.primitiveId]!;
      if (primitive.role != BorderPrimitiveRole.lineCorner) continue;
      final variant = _variantSuffix(placement.primitiveId);
      cornerVariants[variant] = (cornerVariants[variant] ?? 0) + 1;
    }
    expect(
      cornerVariants.keys,
      unorderedEquals(const <String>['01', '02', '03', '04', '05', '06']),
      reason: 'micro-turns must vary the individual corner stone instead of '
          'repeating one complete staircase module: $cornerVariants',
    );
    final cornerCount = cornerVariants.values.fold<int>(0, (sum, n) => sum + n);
    expect(
      cornerVariants.values
              .reduce((left, right) => left > right ? left : right) *
          3,
      lessThanOrEqualTo(cornerCount),
      reason: 'no corner variant may own more than one third of the staircase: '
          '$cornerVariants',
    );
    expect(await projectFile.readAsBytes(), projectBytesBefore);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

String _variantSuffix(String primitiveId) {
  final match = RegExp(r'-(\d{2})$').firstMatch(primitiveId);
  if (match == null) {
    throw StateError('Expected a two-digit variant suffix in $primitiveId');
  }
  return match.group(1)!;
}

int _compareAlongAuthoredRun(
  BorderPrimitiveOrientation orientation,
  BorderResolvedPlacement left,
  BorderResolvedPlacement right,
) {
  final leftBounds = left.opaqueWorldBoundsPx;
  final rightBounds = right.opaqueWorldBoundsPx;
  if (orientation == BorderPrimitiveOrientation.north ||
      orientation == BorderPrimitiveOrientation.south) {
    final byX = leftBounds.x.compareTo(rightBounds.x);
    if (byX != 0) return byX;
    final byY = leftBounds.y.compareTo(rightBounds.y);
    if (byY != 0) return byY;
  } else {
    final byY = leftBounds.y.compareTo(rightBounds.y);
    if (byY != 0) return byY;
    final byX = leftBounds.x.compareTo(rightBounds.x);
    if (byX != 0) return byX;
  }
  return left.slotKey.compareTo(right.slotKey);
}

void _expectNoRepeatedShortBlocks(
  List<String> primitiveIds, {
  required String reason,
}) {
  for (var blockLength = 2; blockLength <= 4; blockLength += 1) {
    for (var end = blockLength * 2; end <= primitiveIds.length; end += 1) {
      final first = primitiveIds.sublist(
        end - blockLength * 2,
        end - blockLength,
      );
      final second = primitiveIds.sublist(end - blockLength, end);
      expect(
        second,
        isNot(orderedEquals(first)),
        reason: '$reason repeats $first at row index $end',
      );
    }
  }
}
