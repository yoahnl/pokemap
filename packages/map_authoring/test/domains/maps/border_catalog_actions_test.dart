import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderCatalogActions', () {
    test('advertises the complete canonical blueprint lifecycle', () {
      expect(
        BorderCatalogActions.descriptors.map((descriptor) => descriptor.id),
        <String>[
          'border.blueprint.delete',
          'border.blueprint.draft.upsert',
          'border.blueprint.publish',
          'border.blueprint.set_deprecated',
        ],
      );
      for (final descriptor in BorderCatalogActions.descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
        expect(
          descriptor.guarantees,
          contains(AuthoringGuarantee.revisionChecked),
        );
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      }
    });

    test('upserts a draft while preserving immutable publication state',
        () async {
      final existing = _record(name: 'Before', publishedRevision: 1);
      final incoming = _record(name: 'After', baseRevision: 1);
      final fixture = _fixture(records: <BorderBlueprintRecord>[existing]);

      final mutation = await fixture.actions.build(
        _context(
          fixture.snapshot,
          actionId: 'border.blueprint.draft.upsert',
          parameters: <String, Object?>{
            'record': encodeBorderBlueprintRecordJson(
              incoming,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            ),
          },
        ),
      );

      final projected = _manifestFrom(mutation);
      final record = projected.borderCatalog.records.single;
      expect(record.draft.definition.name, 'After');
      expect(record.latestPublished, existing.latestPublished);
      expect(record.draft.baseRevision, 1);
      expect(mutation.changeSet.changes, hasLength(1));
      expect(mutation.changeSet.changes.single.resource.kind, 'project');
    });

    test('rejects a stale draft without producing a mutation', () async {
      final fixture = _fixture(
        records: <BorderBlueprintRecord>[
          _record(publishedRevision: 2),
        ],
      );

      await expectLater(
        fixture.actions.build(
          _context(
            fixture.snapshot,
            actionId: 'border.blueprint.draft.upsert',
            parameters: <String, Object?>{
              'record': encodeBorderBlueprintRecordJson(
                _record(baseRevision: 1),
                formatVersion:
                    ProjectBorderCatalog.latestSupportedFormatVersion,
              ),
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'border.blueprint.draft_stale',
          ),
        ),
      );
    });

    test('deprecates a published blueprint without altering its revision',
        () async {
      final existing = _record(publishedRevision: 1);
      final fixture = _fixture(records: <BorderBlueprintRecord>[existing]);

      final mutation = await fixture.actions.build(
        _context(
          fixture.snapshot,
          actionId: 'border.blueprint.set_deprecated',
          parameters: const <String, Object?>{
            'blueprintId': 'fence',
            'isDeprecated': true,
          },
        ),
      );

      final record = _manifestFrom(mutation).borderCatalog.records.single;
      expect(record.isDeprecated, isTrue);
      expect(record.latestPublished, existing.latestPublished);
    });

    test('deletes only a never-published blueprint', () async {
      final fixture = _fixture(records: <BorderBlueprintRecord>[_record()]);

      final mutation = await fixture.actions.build(
        _context(
          fixture.snapshot,
          actionId: 'border.blueprint.delete',
          parameters: const <String, Object?>{'blueprintId': 'fence'},
        ),
      );

      expect(_manifestFrom(mutation).borderCatalog.records, isEmpty);
    });

    test('publishes normalized artifact snapshots atomically', () async {
      final preparation = const CanonicalBorderSnapshotCompiler().prepare(
        sourceElementId: 'fence-element',
        anchorPx: const BorderPixelPos(x: 0, y: 0),
        frames: <CanonicalBorderSourceFrame>[
          CanonicalBorderSourceFrame(
            sourceProjectRelativePath: 'assets/tilesets/fence.png',
            encodedImageBytes: _pngBytes,
          ),
        ],
      );
      final primitives = <BorderPrimitiveDraft>[
        _primitive(
          id: 'cap',
          role: BorderPrimitiveRole.lineCap,
          metrics: preparation.metrics,
        ),
        _primitive(
          id: 'span',
          role: BorderPrimitiveRole.lineStraight,
          metrics: preparation.metrics,
        ),
        _primitive(
          id: 'corner',
          role: BorderPrimitiveRole.lineCorner,
          metrics: preparation.metrics,
        ),
      ];
      final fixture = _fixture(
        records: <BorderBlueprintRecord>[
          _record(primitives: primitives),
        ],
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'fence-element',
            name: 'Fence element',
            tilesetId: 'tileset',
            categoryId: 'border',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      final artifact = await fixture.artifacts.put(
        _pngBytes,
        declaredMediaType: 'image/png',
      );

      final mutation = await fixture.actions.build(
        _context(
          fixture.snapshot,
          actionId: 'border.blueprint.publish',
          parameters: <String, Object?>{
            'blueprintId': 'fence',
            'acceptedWarningCodes': const <String>[
              'border.publication.coverage_gap_exceeded',
            ],
            'primitiveSources': <Object?>[
              for (final primitive in primitives)
                <String, Object?>{
                  'primitiveId': primitive.id,
                  'frames': <Object?>[
                    <String, Object?>{
                      'artifactHandle': artifact.reference.handle,
                      'sourceProjectRelativePath': 'assets/tilesets/fence.png',
                    },
                  ],
                },
            ],
          },
        ),
      );

      final projected = _manifestFrom(mutation);
      final published = projected.borderCatalog.records.single.latestPublished;
      expect(published?.revision, 1);
      expect(projected.borderCatalog.visualSnapshots, hasLength(1));
      expect(
        mutation.changeSet.changes.map((change) => change.resource.kind),
        containsAll(<String>['borderSnapshot', 'project']),
      );
      expect(
        mutation.preview,
        containsPair('primitiveSnapshotIdsByPrimitiveId', isNotEmpty),
      );
    });
  });
}

({
  BorderCatalogActions actions,
  MemoryArtifactStore artifacts,
  ProjectSnapshot snapshot,
}) _fixture({
  List<BorderBlueprintRecord> records = const <BorderBlueprintRecord>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
  final manifest = ProjectManifest(
    name: 'Border catalog fixture',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    elements: elements,
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: records,
    ),
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  const storageKey = 'project.json';
  return (
    actions: BorderCatalogActions(artifactStore: artifacts),
    artifacts: artifacts,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project_border_catalog'),
      revision: computeAuthoringBytesFingerprint(
        utf8.encode('border-catalog-snapshot'),
        logicalName: 'snapshot',
      ),
      manifest: manifest,
      maps: const <MapData>[],
      resourceFingerprints: <String, String>{
        'project': computeAuthoringBytesFingerprint(
          bytes,
          logicalName: storageKey,
        ),
      },
      resourceBytes: <String, List<int>>{'project': bytes},
      resourceStorageKeys: const <String, String>{
        'project': storageKey,
      },
    ),
  );
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request-$actionId',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace:border-catalog',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idempotency-$actionId',
      ),
      planId: 'plan-border-catalog',
      seed: 7,
    );

ProjectManifest _manifestFrom(AuthoringMutationDraft mutation) =>
    ProjectManifest.fromJson(
      jsonDecode(
        utf8.decode(
          mutation.changeSet.changes
              .singleWhere((change) => change.resource.kind == 'project')
              .afterBytes!,
        ),
      ) as Map<String, dynamic>,
    );

BorderBlueprintRecord _record({
  String name = 'Fence',
  int baseRevision = 0,
  int? publishedRevision,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
}) {
  final definition = BorderBlueprintDraftDefinition(
    name: name,
    previewSeed: BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.connectedLine,
    primitives: primitives,
    defaults: BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 8,
      gapTolerancePx: 0,
      depthRows: 1,
      allowAutoRotation: false,
    ),
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: 'fence',
    draft: BorderBlueprintDraft(
      baseRevision: baseRevision,
      definition: definition,
    ),
    latestPublished: publishedRevision == null
        ? null
        : BorderBlueprintRevision(
            revision: publishedRevision,
            definition: BorderBlueprintPublishedDefinition(
              name: name,
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.connectedLine,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: definition.defaults,
              sortOrder: 0,
            ),
          ),
  );
}

BorderPrimitiveDraft _primitive({
  required String id,
  required BorderPrimitiveRole role,
  required BorderPrimitiveAssetMetrics metrics,
}) =>
    BorderPrimitiveDraft(
      id: id,
      sourceElementId: 'fence-element',
      role: role,
      weight: 1000,
      anchorPx: const BorderPixelPos(x: 0, y: 0),
      transforms: BorderTransformPolicy(
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
        allowFlipX: true,
      ),
      currentMetrics: metrics,
    );

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
