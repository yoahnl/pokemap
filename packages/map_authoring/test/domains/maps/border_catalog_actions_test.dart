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
        anchorPx: const BorderPixelPos(x: 16, y: 16),
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
          anchorPx: const BorderPixelPos(x: 16, y: 16),
        ),
        _primitive(
          id: 'span',
          role: BorderPrimitiveRole.lineStraight,
          metrics: preparation.metrics,
          anchorPx: const BorderPixelPos(x: 16, y: 16),
        ),
        _primitive(
          id: 'corner',
          role: BorderPrimitiveRole.lineCorner,
          metrics: preparation.metrics,
          anchorPx: const BorderPixelPos(x: 16, y: 16),
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
              'border.publication.coverage_overlap_exceeded',
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

    test(
      'rejects disconnected network anchors then publishes their centered draft',
      () async {
        const roles = <BorderPrimitiveRole>[
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
          BorderPrimitiveRole.lineCorner,
        ];
        const oldAnchors = <BorderPrimitiveRole, BorderPixelPos>{
          BorderPrimitiveRole.lineCap: BorderPixelPos(x: 22, y: 30),
          BorderPrimitiveRole.lineStraight: BorderPixelPos(x: 16, y: 31),
          BorderPrimitiveRole.lineCorner: BorderPixelPos(x: 11, y: 31),
        };
        const centeredAnchor = BorderPixelPos(x: 16, y: 16);
        final sourceBytes = <BorderPrimitiveRole, List<int>>{
          for (final role in roles) role: _networkPngBytes(role),
        };
        List<BorderPrimitiveDraft> primitivesFor(
                BorderPixelPos Function(
                  BorderPrimitiveRole role,
                ) anchorFor) =>
            <BorderPrimitiveDraft>[
              for (final role in roles)
                _primitive(
                  id: role.name,
                  role: role,
                  sourceElementId: 'element-${role.name}',
                  anchorPx: anchorFor(role),
                  metrics: const CanonicalBorderSnapshotCompiler().prepare(
                    sourceElementId: 'element-${role.name}',
                    anchorPx: anchorFor(role),
                    frames: <CanonicalBorderSourceFrame>[
                      CanonicalBorderSourceFrame(
                        sourceProjectRelativePath:
                            'assets/tilesets/${role.name}.png',
                        encodedImageBytes: sourceBytes[role]!,
                      ),
                    ],
                  ).metrics,
                ),
            ];

        final disconnected = primitivesFor((role) => oldAnchors[role]!);
        final rejectedFixture = _fixture(
          records: <BorderBlueprintRecord>[
            _record(
              primitives: disconnected,
              gapTolerancePx: 1,
              variationPermille: 1000,
              previewSeed: BorderSignedInt64.fromInt(23),
            ),
          ],
          elements: <ProjectElementEntry>[
            for (final role in roles)
              ProjectElementEntry(
                id: 'element-${role.name}',
                name: role.name,
                tilesetId: 'tileset',
                categoryId: 'border',
                frames: const <TilesetVisualFrame>[
                  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                ],
              ),
          ],
        );
        final rejectedArtifacts = <BorderPrimitiveRole, String>{};
        for (final role in roles) {
          final artifact = await rejectedFixture.artifacts.put(
            sourceBytes[role]!,
            declaredMediaType: 'image/png',
          );
          rejectedArtifacts[role] = artifact.reference.handle;
        }

        try {
          await rejectedFixture.actions.build(
            _context(
              rejectedFixture.snapshot,
              actionId: 'border.blueprint.publish',
              parameters: _publishParameters(
                roles: roles,
                artifactHandles: rejectedArtifacts,
              ),
            ),
          );
          fail('Disconnected connected-line anchors must be rejected');
        } on MapAuthoringException catch (error) {
          expect(error.code, 'border.blueprint.publication_invalid');
          final diagnostics = error.details['diagnostics']! as List<Object?>;
          expect(
            diagnostics.whereType<Map>().map((entry) => entry['code']),
            contains('border.publication.connected_line_disconnected'),
          );
        }

        final centered = primitivesFor((_) => centeredAnchor);
        final upsert = await rejectedFixture.actions.build(
          _context(
            rejectedFixture.snapshot,
            actionId: 'border.blueprint.draft.upsert',
            parameters: <String, Object?>{
              'record': encodeBorderBlueprintRecordJson(
                _record(
                  primitives: centered,
                  gapTolerancePx: 1,
                  variationPermille: 1000,
                  previewSeed: BorderSignedInt64.fromInt(23),
                ),
                formatVersion:
                    ProjectBorderCatalog.latestSupportedFormatVersion,
              ),
            },
          ),
        );
        expect(
          _manifestFrom(upsert)
              .borderCatalog
              .records
              .single
              .draft
              .definition
              .primitives
              .map((primitive) => primitive.anchorPx),
          everyElement(centeredAnchor),
        );

        final acceptedFixture = _fixture(
          records: <BorderBlueprintRecord>[
            _record(
              primitives: centered,
              gapTolerancePx: 1,
              variationPermille: 1000,
              previewSeed: BorderSignedInt64.fromInt(23),
            ),
          ],
          elements: <ProjectElementEntry>[
            for (final role in roles)
              ProjectElementEntry(
                id: 'element-${role.name}',
                name: role.name,
                tilesetId: 'tileset',
                categoryId: 'border',
                frames: const <TilesetVisualFrame>[
                  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                ],
              ),
          ],
        );
        final acceptedArtifacts = <BorderPrimitiveRole, String>{};
        for (final role in roles) {
          final artifact = await acceptedFixture.artifacts.put(
            sourceBytes[role]!,
            declaredMediaType: 'image/png',
          );
          acceptedArtifacts[role] = artifact.reference.handle;
        }
        final published = await acceptedFixture.actions.build(
          _context(
            acceptedFixture.snapshot,
            actionId: 'border.blueprint.publish',
            parameters: _publishParameters(
              roles: roles,
              artifactHandles: acceptedArtifacts,
            ),
          ),
        );
        final projected = _manifestFrom(published);
        final revision =
            projected.borderCatalog.records.single.latestPublished!;
        expect(revision.revision, 1);
        expect(
          revision.definition.primitives.map((primitive) => primitive.anchorPx),
          everyElement(centeredAnchor),
        );
        expect(
          published.preview['projectWidePreflight'],
          'passed',
        );
        final gallery = resolveBorderCanonicalGallery(
          blueprintId: 'fence',
          blueprintRevision: revision,
          visualSnapshots: projected.borderCatalog.visualSnapshots,
          tileSizePx: GridSize(
            width: projected.settings.tileWidth,
            height: projected.settings.tileHeight,
          ),
        );
        final sBend = gallery.report.samples.singleWhere(
          (sample) => sample.galleryCase == BorderCanonicalGalleryCase.sBend,
        );
        expect(
          sBend.coverageChecks.map(
            (check) => check.longestContiguousGapPx,
          ),
          everyElement(lessThanOrEqualTo(1)),
        );
      },
    );
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
  int gapTolerancePx = 0,
  int variationPermille = 0,
  BorderSignedInt64? previewSeed,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
}) {
  final definition = BorderBlueprintDraftDefinition(
    name: name,
    previewSeed: previewSeed ?? BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.connectedLine,
    primitives: primitives,
    defaults: BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: variationPermille,
      maxOverlapPx: 8,
      gapTolerancePx: gapTolerancePx,
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
  String sourceElementId = 'fence-element',
  BorderPixelPos anchorPx = const BorderPixelPos(x: 0, y: 0),
}) =>
    BorderPrimitiveDraft(
      id: id,
      sourceElementId: sourceElementId,
      role: role,
      weight: 1000,
      anchorPx: anchorPx,
      transforms: BorderTransformPolicy(
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
        allowFlipX: true,
      ),
      currentMetrics: metrics,
    );

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==',
);

Map<String, Object?> _publishParameters({
  required List<BorderPrimitiveRole> roles,
  required Map<BorderPrimitiveRole, String> artifactHandles,
}) =>
    <String, Object?>{
      'blueprintId': 'fence',
      'acceptedWarningCodes': const <String>[
        'border.publication.coverage_gap_exceeded',
        'border.publication.coverage_overlap_exceeded',
      ],
      'primitiveSources': <Object?>[
        for (final role in roles)
          <String, Object?>{
            'primitiveId': role.name,
            'frames': <Object?>[
              <String, Object?>{
                'artifactHandle': artifactHandles[role]!,
                'sourceProjectRelativePath': 'assets/tilesets/${role.name}.png',
              },
            ],
          },
      ],
    };

List<int> _networkPngBytes(BorderPrimitiveRole role) {
  return base64Decode(
    switch (role) {
      BorderPrimitiveRole.lineCap =>
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAI0lEQVR4nO3WAREAAAQEMPp39k4OW4rVJCkA4LP2AQB47SqwWugL866rJOcAAAAASUVORK5CYII=',
      BorderPrimitiveRole.lineStraight =>
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAI0lEQVR4nO3WAQ0AAAgDoNs/9J05hBSkbQMAfDY+AACvXQUWcxoL9n1OGtMAAAAASUVORK5CYII=',
      BorderPrimitiveRole.lineCorner =>
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR4nO2WsQkAMAzDXP//s0tv8GAK0h4QKJAoSVTQzte0AtYYIyASjDECIsEYI6AxZ37PW/gHvl9CIyASjDECIsGYaYJ3SS+xeRgizvP++gAAAABJRU5ErkJggg==',
      _ => throw StateError('Unexpected connected-line role'),
    },
  );
}
