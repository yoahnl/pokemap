import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Border catalog operations', () {
    test('find returns the existing record instance or null', () {
      final record = _record('coast');
      final catalog = ProjectBorderCatalog(records: <BorderBlueprintRecord>[
        record,
      ]);

      expect(
        identical(findBorderBlueprintRecordById(catalog, 'coast'), record),
        isTrue,
      );
      expect(findBorderBlueprintRecordById(catalog, 'missing'), isNull);
      expect(findBorderBlueprintRecordById(catalog, ' coast '), isNull);
    });

    test('add appends without mutating input or changing snapshots', () {
      final snapshot = _snapshot('a');
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('first')],
        visualSnapshots: <BorderVisualSnapshot>[snapshot],
      );
      final addedRecord = _record('second');

      final result = addBorderBlueprintRecord(catalog, addedRecord);

      expect(catalog.records.map((record) => record.id), <String>['first']);
      expect(result.records.map((record) => record.id), <String>[
        'first',
        'second',
      ]);
      expect(result.visualSnapshots, catalog.visualSnapshots);
      expect(result.formatVersion, catalog.formatVersion);
    });

    test('add rejects an existing record id', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('same')],
      );

      expect(
        () => addBorderBlueprintRecord(catalog, _record('same')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('add rejects an already-published record before publication exists',
        () {
      expect(
        () => addBorderBlueprintRecord(
          const ProjectBorderCatalog.empty(),
          _record('published', published: true),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('unpublished draft'),
          ),
        ),
      );
    });

    test('add rejects a record already marked deprecated', () {
      expect(
        () => addBorderBlueprintRecord(
          const ProjectBorderCatalog.empty(),
          _record('deprecated', isDeprecated: true),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('active'),
          ),
        ),
      );
    });

    test('replace keeps the record index and preserves snapshots', () {
      final snapshot = _snapshot('b');
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record('first'),
          _record('target', sortOrder: 1),
          _record('last'),
        ],
        visualSnapshots: <BorderVisualSnapshot>[snapshot],
      );
      final replacement = _record('target', sortOrder: 99);

      final result = replaceBorderBlueprintRecord(catalog, replacement);

      expect(result.records.map((record) => record.id), <String>[
        'first',
        'target',
        'last',
      ]);
      expect(result.records[1], replacement);
      expect(catalog.records[1].draft.definition.sortOrder, 1);
      expect(result.visualSnapshots, catalog.visualSnapshots);
    });

    test('replace rejects a missing record id', () {
      expect(
        () => replaceBorderBlueprintRecord(
          ProjectBorderCatalog(records: <BorderBlueprintRecord>[
            _record('present'),
          ]),
          _record('missing'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('replace cannot erase or downgrade immutable published state', () {
      final published = _record(
        'published',
        published: true,
        publishedRevision: 2,
        publishedSortOrder: 7,
      );
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[published],
      );

      expect(
        () => replaceBorderBlueprintRecord(
          catalog,
          _record('published'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => replaceBorderBlueprintRecord(
          catalog,
          _record(
            'published',
            published: true,
            publishedRevision: 1,
            publishedSortOrder: 7,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('replace cannot mutate an existing published revision', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record(
            'published',
            published: true,
            publishedRevision: 2,
            publishedSortOrder: 7,
          ),
        ],
      );

      expect(
        () => replaceBorderBlueprintRecord(
          catalog,
          _record(
            'published',
            published: true,
            publishedRevision: 2,
            publishedSortOrder: 8,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('replace may update only the draft beside unchanged published state',
        () {
      final existing = _record(
        'published',
        sortOrder: 1,
        published: true,
        publishedRevision: 2,
        publishedSortOrder: 7,
      );
      final replacement = _record(
        'published',
        sortOrder: 99,
        published: true,
        publishedRevision: 2,
        publishedSortOrder: 7,
      );
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[existing],
      );

      final result = replaceBorderBlueprintRecord(catalog, replacement);

      expect(result.records.single.draft.definition.sortOrder, 99);
      expect(
        result.records.single.latestPublished,
        existing.latestPublished,
      );
      expect(catalog.records.single, existing);
    });

    test('replace cannot act as an arbitrary publication boundary', () {
      final existing = _record(
        'published',
        published: true,
        publishedRevision: 2,
        publishedSortOrder: 7,
      );
      final replacement = _record(
        'published',
        published: true,
        publishedRevision: 3,
        publishedSortOrder: 8,
      );

      expect(
        () => replaceBorderBlueprintRecord(
          ProjectBorderCatalog(records: <BorderBlueprintRecord>[existing]),
          replacement,
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('Publication requires the publication transaction'),
          ),
        ),
      );
    });

    test('replace cannot publish a previously-unpublished draft', () {
      final existing = _record('draft');

      expect(
        () => replaceBorderBlueprintRecord(
          ProjectBorderCatalog(records: <BorderBlueprintRecord>[existing]),
          _record('draft', published: true),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('Publication requires the publication transaction'),
          ),
        ),
      );
    });

    test('replace cannot bypass the explicit deprecation operation', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('coast')],
      );

      expect(
        () => replaceBorderBlueprintRecord(
          catalog,
          _record('coast', isDeprecated: true),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('deprecation operation'),
          ),
        ),
      );
    });

    test('deprecate and reactivate preserve identity, content, and order', () {
      final snapshot = _snapshot('d');
      final target = _record('target', published: true, sortOrder: 7);
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record('first'),
          target,
          _record('last'),
        ],
        visualSnapshots: <BorderVisualSnapshot>[snapshot],
      );

      final deprecated = setBorderBlueprintRecordDeprecated(
        catalog,
        'target',
        isDeprecated: true,
      );
      final deprecatedRecord = deprecated.records[1];

      expect(deprecated.records.map((record) => record.id), <String>[
        'first',
        'target',
        'last',
      ]);
      expect(deprecatedRecord.isDeprecated, isTrue);
      expect(identical(deprecatedRecord.draft, target.draft), isTrue);
      expect(
        identical(deprecatedRecord.latestPublished, target.latestPublished),
        isTrue,
      );
      expect(deprecated.visualSnapshots, catalog.visualSnapshots);
      expect(identical(deprecated.visualSnapshots.single, snapshot), isTrue);

      final idempotent = setBorderBlueprintRecordDeprecated(
        deprecated,
        'target',
        isDeprecated: true,
      );
      expect(identical(idempotent, deprecated), isTrue);

      final reactivated = setBorderBlueprintRecordDeprecated(
        deprecated,
        'target',
        isDeprecated: false,
      );
      expect(reactivated.records[1].isDeprecated, isFalse);
      expect(identical(reactivated.records[1].draft, target.draft), isTrue);
      expect(
        identical(
          reactivated.records[1].latestPublished,
          target.latestPublished,
        ),
        isTrue,
      );
      expect(reactivated.visualSnapshots, catalog.visualSnapshots);
      expect(identical(reactivated.visualSnapshots.single, snapshot), isTrue);
    });

    test('deprecation rejects missing and unstable record IDs', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('coast')],
      );

      expect(
        () => setBorderBlueprintRecordDeprecated(
          catalog,
          'missing',
          isDeprecated: true,
        ),
        throwsA(isA<ValidationException>()),
      );
      for (final id in <String>[' ', ' coast', 'coast ']) {
        expect(
          () => setBorderBlueprintRecordDeprecated(
            catalog,
            id,
            isDeprecated: true,
          ),
          throwsA(isA<ValidationException>()),
          reason: '"$id"',
        );
      }
    });

    test('remove deletes an unpublished draft and preserves order', () {
      final snapshot = _snapshot('c');
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record('first'),
          _record('draft'),
          _record('last'),
        ],
        visualSnapshots: <BorderVisualSnapshot>[snapshot],
      );

      final result = removeBorderBlueprintRecord(catalog, 'draft');

      expect(result.records.map((record) => record.id), <String>[
        'first',
        'last',
      ]);
      expect(catalog.recordCount, 3);
      expect(result.visualSnapshots, catalog.visualSnapshots);
    });

    test('remove rejects missing and previously published records', () {
      final published = _record('published', published: true);
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record('draft'),
          published,
        ],
      );

      expect(
        () => removeBorderBlueprintRecord(catalog, 'missing'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => removeBorderBlueprintRecord(catalog, 'published'),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('published'),
          ),
        ),
      );
      expect(catalog.records, <BorderBlueprintRecord>[
        _record('draft'),
        published,
      ]);
    });

    test('remove rejects nonblank but non-trimmed record IDs', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('coast')],
      );

      for (final id in <String>[' ', ' coast', 'coast ']) {
        expect(
          () => removeBorderBlueprintRecord(catalog, id),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              contains('nonblank and already trimmed'),
            ),
          ),
          reason: '"$id"',
        );
      }
    });

    group('visual snapshot retention', () {
      test('partial manifest returns candidates without deleting metadata', () {
        final setup = _retentionSetup();

        final result = cleanupUnreferencedBorderVisualSnapshots(
          manifest: setup.manifest,
          loadedMaps: setup.maps,
          isManifestExhaustive: false,
        );

        expect(result.hasExhaustiveReferences, isFalse);
        expect(result.candidateSnapshotIds, <String>[_snapshotId('f')]);
        expect(result.deletedSnapshotIds, isEmpty);
        expect(result.catalog, same(setup.manifest.borderCatalog));
        expect(
          result.catalog.visualSnapshots,
          same(setup.manifest.borderCatalog.visualSnapshots),
        );
      });

      test('missing manifest map returns unsafe candidates without deletion',
          () {
        final setup = _retentionSetup();

        final result = cleanupUnreferencedBorderVisualSnapshots(
          manifest: setup.manifest,
          loadedMaps: <MapData>[setup.maps.first],
          isManifestExhaustive: true,
        );

        expect(result.hasExhaustiveReferences, isFalse);
        expect(
          result.candidateSnapshotIds,
          <String>[_snapshotId('e'), _snapshotId('f')],
        );
        expect(result.deletedSnapshotIds, isEmpty);
        expect(result.catalog, same(setup.manifest.borderCatalog));
      });

      test('exhaustive manifest and maps delete only unreferenced snapshots',
          () {
        final setup = _retentionSetup();

        final result = cleanupUnreferencedBorderVisualSnapshots(
          manifest: setup.manifest,
          loadedMaps: setup.maps,
          isManifestExhaustive: true,
        );

        expect(result.hasExhaustiveReferences, isTrue);
        expect(result.candidateSnapshotIds, <String>[_snapshotId('f')]);
        expect(result.deletedSnapshotIds, <String>[_snapshotId('f')]);
        expect(
          result.catalog.visualSnapshots.map((snapshot) => snapshot.id),
          <String>[
            _snapshotId('a'),
            _snapshotId('b'),
            _snapshotId('c'),
            _snapshotId('d'),
            _snapshotId('e'),
          ],
        );
        expect(
          result.catalog.records,
          orderedEquals(setup.manifest.borderCatalog.records),
        );
        expect(
          result.catalog.records.single,
          same(setup.manifest.borderCatalog.records.single),
        );
        for (var index = 0;
            index < result.catalog.visualSnapshots.length;
            index += 1) {
          expect(
            result.catalog.visualSnapshots[index],
            same(setup.manifest.borderCatalog.visualSnapshots[index]),
          );
        }
      });
    });
  });
}

BorderBlueprintRecord _record(
  String id, {
  int sortOrder = 0,
  bool published = false,
  int publishedRevision = 1,
  int? publishedSortOrder,
  bool isDeprecated = false,
  String? publishedSnapshotId,
}) {
  final hasPublished = published || publishedSnapshotId != null;
  return BorderBlueprintRecord(
    id: id,
    isDeprecated: isDeprecated,
    draft: BorderBlueprintDraft(
      baseRevision: hasPublished ? publishedRevision : 0,
      definition:
          BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
        name: 'Border $id',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPrimitiveDraft>[],
        defaults: _params(),
        sortOrder: sortOrder,
      ),
    ),
    latestPublished: hasPublished
        ? BorderBlueprintRevision(
            revision: publishedRevision,
            definition: BorderBlueprintDefinition<BorderPublishedPrimitive,
                BorderPublishedGround>(
              name: 'Border $id',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.organicEdge,
              primitives: <BorderPublishedPrimitive>[
                if (publishedSnapshotId != null)
                  _publishedPrimitive(publishedSnapshotId),
              ],
              defaults: _params(),
              sortOrder: publishedSortOrder ?? sortOrder,
            ),
          )
        : null,
  );
}

BorderPublishedPrimitive _publishedPrimitive(String snapshotId) =>
    BorderPublishedPrimitive(
      id: 'published-primitive',
      sourceElementId: 'source-element',
      visualSnapshotId: snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 0, y: 0),
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: const <int>[0],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-fingerprint',
        pixelSize: const GridSize(width: 1, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: encodeBorderRleMask(const <bool>[true]),
      ),
    );

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );

BorderVisualSnapshot _snapshot(String digit) {
  final fingerprint = digit * 64;
  return BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$fingerprint',
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$digit.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 8, height: 8),
        durationMs: 100,
      ),
    ],
  );
}

String _snapshotId(String digit) => 'border-snapshot-sha256:${digit * 64}';

({ProjectManifest manifest, List<MapData> maps}) _retentionSetup() {
  final snapshots = <BorderVisualSnapshot>[
    for (final digit in <String>['a', 'b', 'c', 'd', 'e', 'f'])
      _snapshot(digit),
  ];
  final catalog = ProjectBorderCatalog(
    records: <BorderBlueprintRecord>[
      _record('published', publishedSnapshotId: _snapshotId('a')),
    ],
    visualSnapshots: snapshots,
  );
  final maps = <MapData>[
    _mapWithSnapshotReferences(
      id: 'map-one',
      groundSnapshotId: _snapshotId('b'),
      placementSnapshotId: _snapshotId('c'),
      lockedSnapshotId: _snapshotId('d'),
    ),
    _mapWithSnapshotReferences(
      id: 'map-two',
      groundSnapshotId: _snapshotId('e'),
    ),
  ];
  return (
    manifest: ProjectManifest(
      name: 'Retention project',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[
        for (final map in maps)
          ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: catalog,
    ),
    maps: maps,
  );
}

MapData _mapWithSnapshotReferences({
  required String id,
  required String groundSnapshotId,
  String? placementSnapshotId,
  String? lockedSnapshotId,
}) {
  final placements = <BorderResolvedPlacement>[
    if (placementSnapshotId != null)
      _resolvedPlacement(
        id: '$id-placement',
        slotKey: '$id-placement-slot',
        snapshotId: placementSnapshotId,
      ),
  ];
  final ground = <BorderResolvedGroundCell>[
    BorderResolvedGroundCell(
      x: 0,
      y: 0,
      visualSnapshotId: groundSnapshotId,
      resolvedRole: SurfaceVariantRole.isolated,
    ),
  ];
  final materialization = BorderMaterialization(
    receipt: _receiptForRetention(ground: ground, placements: placements),
    ground: ground,
    placements: placements,
  );
  final lockedPlacement = lockedSnapshotId == null
      ? null
      : _resolvedPlacement(
          id: '$id-locked',
          slotKey: '$id-locked-slot',
          snapshotId: lockedSnapshotId,
        );
  final feature = BorderFeature(
    id: '$id-feature',
    name: '$id feature',
    blueprintId: 'published',
    seed: BorderSignedInt64.zero,
    geometry: BorderRegionGeometry(
      width: 1,
      height: 1,
      cells: const <bool>[true],
    ),
    overrides: <BorderSlotOverride>[
      if (lockedPlacement != null)
        BorderSlotOverride(
          slotKey: lockedPlacement.slotKey,
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: true,
          lockedPlacement: lockedPlacement,
        ),
    ],
    keepOutRegions: const <BorderKeepOutRegion>[],
    materialization: materialization,
  );
  return MapData(
    id: id,
    name: id,
    version: ProjectVersion.v2,
    size: const GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      MapLayer.border(
        id: '$id-border',
        name: 'Border',
        content: BorderLayerContent(features: <BorderFeature>[feature]),
      ),
    ],
  );
}

BorderResolvedPlacement _resolvedPlacement({
  required String id,
  required String slotKey,
  required String snapshotId,
}) =>
    BorderResolvedPlacement(
      id: id,
      slotKey: slotKey,
      primitiveId: 'published-primitive',
      visualSnapshotId: snapshotId,
      anchorCell: const GridPos(x: 0, y: 0),
      topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
      opaqueWorldBoundsPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: 1,
        anchorRowMajor: 0,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: slotKey,
      ),
    );

BorderResolutionReceipt _receiptForRetention({
  required List<BorderResolvedGroundCell> ground,
  required List<BorderResolvedPlacement> placements,
}) {
  const hash =
      'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  return BorderResolutionReceipt(
    resolverVersion: 1,
    blueprintRevision: 1,
    components: BorderInputFingerprints(
      blueprint: hash,
      geometryAndSeed: hash,
      parameters: hash,
      overrides: hash,
      keepOutRegions: hash,
      mapContext: hash,
      visualSnapshots: hash,
    ),
    inputFingerprint: hash,
    outputFingerprint: computeBorderOutputFingerprint(
      ground: ground,
      placements: placements,
    ),
  );
}
