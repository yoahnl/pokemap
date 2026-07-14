import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';

void main() {
  group('BorderPublicationCandidateBuilder', () {
    test(
      'publishes positive primitives at the next revision without disturbing the project',
      () {
        final first = _preparation('a');
        final disabled = _preparation('b');
        final target = _record(
          id: 'coast',
          baseRevision: 2,
          latestRevision: 2,
          isDeprecated: true,
          primitives: <BorderPrimitiveDraft>[
            _draftPrimitive(id: 'large', sourceElementId: 'element-large'),
            _draftPrimitive(
              id: 'disabled',
              sourceElementId: 'element-disabled',
              weight: 0,
            ),
          ],
        );
        final manifest = _manifest(
          records: <BorderBlueprintRecord>[
            _record(id: 'before'),
            target,
            _record(id: 'after'),
          ],
          elements: <ProjectElementEntry>[
            _element('element-large'),
            _element('element-disabled'),
          ],
        );

        final result = const BorderPublicationCandidateBuilder().build(
          manifest: manifest,
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: <String,
              BorderAssetSnapshotPreparation>{
            'large': first,
            'disabled': disabled,
          },
        );

        final records = result.nextManifest.borderCatalog.records;
        expect(records.map((record) => record.id), <String>[
          'before',
          'coast',
          'after',
        ]);
        expect(records.first, same(manifest.borderCatalog.records.first));
        expect(records.last, same(manifest.borderCatalog.records.last));
        final published = records[1];
        expect(published.isDeprecated, isTrue);
        expect(published.latestPublished!.revision, 3);
        expect(published.draft.baseRevision, 3);
        expect(published.draft.definition, target.draft.definition);
        expect(published.latestPublished!.definition.primitives, hasLength(1));
        final primitive =
            published.latestPublished!.definition.primitives.single;
        expect(primitive.id, 'large');
        expect(primitive.sourceElementId, 'element-large');
        expect(primitive.visualSnapshotId, first.snapshot.id);
        expect(primitive.publishedMetrics, first.metrics);
        expect(result.nextManifest.name, manifest.name);
        expect(result.nextManifest.maps, manifest.maps);
        expect(result.nextManifest.surfaceCatalog, manifest.surfaceCatalog);
        expect(result.nextManifest.version, ProjectVersion.v2);
        expect(result.files, first.files);
        expect(
          result.primitiveSnapshotIdsByPrimitiveId,
          <String, String>{'large': first.snapshot.id},
        );
        expect(result.groundSnapshotIdsByRole, isEmpty);
        expect(result.snapshotIntegrity[first.snapshot.id]!.isValid, isTrue);
        expect(
          result.nextManifest.borderCatalog.visualSnapshots,
          <BorderVisualSnapshot>[first.snapshot],
        );
      },
    );

    test('validates every draft source element including disabled entries', () {
      final target = _record(
        id: 'coast',
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(
            id: 'disabled',
            sourceElementId: 'missing-element',
            weight: 0,
          ),
        ],
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(records: <BorderBlueprintRecord>[target]),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
        ),
        throwsA(
          isA<BorderPublicationCandidateException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationCandidateErrorCode.sourceElementMissing,
              )
              .having(
                (error) => error.primitiveId,
                'primitiveId',
                'disabled',
              ),
        ),
      );
    });

    test('requires one preparation for every positive primitive', () {
      final target = _record(
        id: 'coast',
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(id: 'large', sourceElementId: 'element-large'),
        ],
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[target],
            elements: <ProjectElementEntry>[_element('element-large')],
          ),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
        ),
        throwsA(
          isA<BorderPublicationCandidateException>().having(
            (error) => error.code,
            'code',
            BorderPublicationCandidateErrorCode.primitiveSnapshotMissing,
          ),
        ),
      );
    });

    test('deduplicates prior and new snapshots while preserving prior order',
        () {
      final retainedA = _preparation('a');
      final retainedB = _preparation('b');
      final appended = _preparation('c');
      final target = _record(
        id: 'coast',
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(id: 'one', sourceElementId: 'element-one'),
          _draftPrimitive(id: 'two', sourceElementId: 'element-two'),
          _draftPrimitive(id: 'three', sourceElementId: 'element-three'),
        ],
      );
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[target],
        snapshots: <BorderVisualSnapshot>[
          retainedA.snapshot,
          retainedB.snapshot,
        ],
        elements: <ProjectElementEntry>[
          _element('element-one'),
          _element('element-two'),
          _element('element-three'),
        ],
      );

      final result = const BorderPublicationCandidateBuilder().build(
        manifest: manifest,
        draftRecord: target,
        primitiveSnapshotsByPrimitiveId: <String,
            BorderAssetSnapshotPreparation>{
          'one': retainedA,
          'two': appended,
          'three': appended,
        },
      );

      expect(
        result.nextManifest.borderCatalog.visualSnapshots,
        <BorderVisualSnapshot>[
          retainedA.snapshot,
          retainedB.snapshot,
          appended.snapshot,
        ],
      );
      expect(result.files, appended.files);
      expect(result.snapshotIntegrity.keys, <String>{
        retainedA.snapshot.id,
        appended.snapshot.id,
      });
      expect(
        result.primitiveSnapshotIdsByPrimitiveId,
        <String, String>{
          'one': retainedA.snapshot.id,
          'two': appended.snapshot.id,
          'three': appended.snapshot.id,
        },
      );
    });

    test('rejects a ground draft that references an absent Surface preset', () {
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSurfacePresetId: 'missing-surface',
          edgeBandCells: 2,
        ),
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(records: <BorderBlueprintRecord>[target]),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
          groundSnapshotsByRole: const <SurfaceVariantRole,
              BorderAssetSnapshotPreparation>{},
        ),
        throwsA(
          isA<BorderPublicationCandidateException>().having(
            (error) => error.code,
            'code',
            BorderPublicationCandidateErrorCode.sourceSurfacePresetMissing,
          ),
        ),
      );
    });

    test('requires every standard Surface role for published ground', () {
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSurfacePresetId: 'shore',
          edgeBandCells: 2,
        ),
      );
      final onlyIsolated = <SurfaceVariantRole, BorderAssetSnapshotPreparation>{
        SurfaceVariantRole.isolated: _preparation('a'),
      };

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[target],
            surfacePreset: _surfacePreset('shore'),
          ),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
          groundSnapshotsByRole: onlyIsolated,
        ),
        throwsA(
          isA<BorderPublicationCandidateException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationCandidateErrorCode.groundSnapshotRoleMissing,
              )
              .having(
                (error) => error.surfaceRole,
                'surfaceRole',
                SurfaceVariantRole.endNorth,
              ),
        ),
      );
    });

    test('publishes complete ground snapshots in stable Surface role order',
        () {
      final shared = _preparation('d');
      final byRole = <SurfaceVariantRole, BorderAssetSnapshotPreparation>{
        for (final role in standardSurfaceVariantRoleOrder) role: shared,
      };
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSurfacePresetId: 'shore',
          edgeBandCells: 3,
        ),
      );

      final result = const BorderPublicationCandidateBuilder().build(
        manifest: _manifest(
          records: <BorderBlueprintRecord>[target],
          surfacePreset: _surfacePreset('shore'),
        ),
        draftRecord: target,
        primitiveSnapshotsByPrimitiveId: const <String,
            BorderAssetSnapshotPreparation>{},
        groundSnapshotsByRole: byRole,
      );

      final ground = result.nextManifest.borderCatalog.records.single
          .latestPublished!.definition.ground!;
      expect(ground.sourceSurfacePresetId, 'shore');
      expect(ground.edgeBandCells, 3);
      expect(
        ground.visualSnapshotIdsByRole.keys,
        standardSurfaceVariantRoleOrder,
      );
      expect(
        ground.visualSnapshotIdsByRole.values.toSet(),
        <String>{shared.snapshot.id},
      );
      expect(
          result.groundSnapshotIdsByRole.keys, standardSurfaceVariantRoleOrder);
      expect(result.files, shared.files);
      expect(
        result.nextManifest.borderCatalog.visualSnapshots,
        <BorderVisualSnapshot>[shared.snapshot],
      );
    });

    test('rejects ground snapshot inputs when the draft has no ground', () {
      final target = _record(id: 'coast');

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(records: <BorderBlueprintRecord>[target]),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
          groundSnapshotsByRole: <SurfaceVariantRole,
              BorderAssetSnapshotPreparation>{
            SurfaceVariantRole.isolated: _preparation('a'),
          },
        ),
        throwsA(
          isA<BorderPublicationCandidateException>().having(
            (error) => error.code,
            'code',
            BorderPublicationCandidateErrorCode.unexpectedGroundSnapshots,
          ),
        ),
      );
    });

    test('rejects a stale draft base revision', () {
      final manifestRecord = _record(
        id: 'coast',
        baseRevision: 2,
        latestRevision: 2,
      );
      final staleDraft = _record(
        id: 'coast',
        baseRevision: 1,
        latestRevision: 2,
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[manifestRecord],
          ),
          draftRecord: staleDraft,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
        ),
        throwsA(
          isA<BorderPublicationCandidateException>().having(
            (error) => error.code,
            'code',
            BorderPublicationCandidateErrorCode.staleDraftRevision,
          ),
        ),
      );
    });
  });
}

ProjectManifest _manifest({
  required List<BorderBlueprintRecord> records,
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
  List<BorderVisualSnapshot> snapshots = const <BorderVisualSnapshot>[],
  ProjectSurfacePreset? surfacePreset,
}) {
  return ProjectManifest(
    name: 'Candidate project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    elements: elements,
    globalProperties: const <String, Object?>{'untouched': true},
    surfaceCatalog: surfacePreset == null
        ? const ProjectSurfaceCatalog.empty()
        : ProjectSurfaceCatalog(presets: <ProjectSurfacePreset>[surfacePreset]),
    borderCatalog: ProjectBorderCatalog(
      records: records,
      visualSnapshots: snapshots,
    ),
  );
}

BorderBlueprintRecord _record({
  required String id,
  int baseRevision = 0,
  int? latestRevision,
  bool isDeprecated = false,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
  BorderGroundDraft? ground,
}) {
  final definition = BorderBlueprintDraftDefinition(
    name: 'Blueprint $id',
    previewSeed: BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.organicEdge,
    primitives: primitives,
    defaults: _params(),
    ground: ground,
    categoryId: 'coasts',
    sortOrder: 7,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: baseRevision,
      definition: definition,
    ),
    latestPublished: latestRevision == null
        ? null
        : BorderBlueprintRevision(
            revision: latestRevision,
            definition: BorderBlueprintPublishedDefinition(
              name: definition.name,
              previewSeed: definition.previewSeed,
              template: definition.template,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: definition.defaults,
              categoryId: definition.categoryId,
              sortOrder: definition.sortOrder,
            ),
          ),
    isDeprecated: isDeprecated,
  );
}

BorderPrimitiveDraft _draftPrimitive({
  required String id,
  required String sourceElementId,
  int weight = 100,
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: sourceElementId,
    role: BorderPrimitiveRole.structureLarge,
    weight: weight,
    anchorPx: const BorderPixelPos(x: 1, y: 1),
    transforms: _transforms(),
    currentMetrics: _metrics('draft-$id'),
  );
}

ProjectElementEntry _element(String id) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset',
    categoryId: 'border',
    frames: const <TilesetVisualFrame>[
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}

ProjectSurfacePreset _surfacePreset(String id) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: <SurfaceVariantAnimationRef>[
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'surface-animation',
        ),
      ],
    ),
  );
}

BorderAssetSnapshotPreparation _preparation(String digit) {
  final fingerprint = digit * 64;
  final relativePath = 'assets/borders/snapshots/$fingerprint/frame_0000.png';
  return BorderAssetSnapshotPreparation(
    snapshot: BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$fingerprint',
      contentFingerprint: fingerprint,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: relativePath,
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 100,
        ),
      ],
    ),
    metrics: _metrics('source-$digit'),
    files: <BorderSnapshotFilePayload>[
      BorderSnapshotFilePayload(
        relativePath: relativePath,
        bytes: Uint8List.fromList(<int>[digit.codeUnitAt(0)]),
      ),
    ],
  );
}

BorderPrimitiveAssetMetrics _metrics(String fingerprint) {
  return BorderPrimitiveAssetMetrics(
    assetFingerprint: fingerprint,
    pixelSize: const GridSize(width: 2, height: 2),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
    defaultAnchorPx: const BorderPixelPos(x: 1, y: 1),
    occupancyMaskRle: '2:0-2;2:0-2',
  );
}

BorderTransformPolicy _transforms() => BorderTransformPolicy(
      allowFlipX: false,
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
    );

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 500,
      detailDensityPermille: 500,
      variationPermille: 500,
      maxOverlapPx: 2,
      gapTolerancePx: 2,
      depthRows: 2,
    );
