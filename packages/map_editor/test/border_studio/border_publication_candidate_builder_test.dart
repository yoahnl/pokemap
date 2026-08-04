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
        final first = _preparation(
          'a',
          sourceElementId: 'element-large',
        );
        final disabled = _preparation(
          'b',
          sourceElementId: 'element-disabled',
        );
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
        expect(
          result.nextManifest.smartTileCatalog,
          manifest.smartTileCatalog,
        );
        expect(result.nextManifest.version, ProjectVersion.v6);
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

    test('publishes connected-line slots while preserving the V5 manifest', () {
      final preparations = <String, BorderAssetSnapshotPreparation>{
        'cap-a': _preparation('a', sourceElementId: 'element-cap-a'),
        'cap-b': _preparation('b', sourceElementId: 'element-cap-b'),
        'straight': _preparation('c', sourceElementId: 'element-straight'),
        'corner': _preparation('d', sourceElementId: 'element-corner'),
      };
      final target = _record(
        id: 'cliff',
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(
            id: 'cap-a',
            sourceElementId: 'element-cap-a',
            role: BorderPrimitiveRole.lineCap,
          ),
          _draftPrimitive(
            id: 'cap-b',
            sourceElementId: 'element-cap-b',
            role: BorderPrimitiveRole.lineCap,
          ),
          _draftPrimitive(
            id: 'straight',
            sourceElementId: 'element-straight',
            role: BorderPrimitiveRole.lineStraight,
          ),
          _draftPrimitive(
            id: 'corner',
            sourceElementId: 'element-corner',
            role: BorderPrimitiveRole.lineCorner,
          ),
        ],
      );
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[target],
        elements: <ProjectElementEntry>[
          for (final preparation in preparations.values)
            _element(preparation.sourceElementId),
        ],
      );

      final result = const BorderPublicationCandidateBuilder().build(
        manifest: manifest,
        draftRecord: target,
        primitiveSnapshotsByPrimitiveId: preparations,
      );

      expect(
        result.nextManifest.borderCatalog.formatVersion,
        ProjectBorderCatalog.formatVersionV2,
      );
      expect(
        result.nextManifest.borderCatalog.records.single.latestPublished!
            .definition.primitives
            .map((primitive) => primitive.role),
        <BorderPrimitiveRole>[
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
          BorderPrimitiveRole.lineCorner,
        ],
      );
    });

    test('publishes one main stone and promotes the catalog to V3', () {
      final preparation =
          _preparation('e', sourceElementId: 'element-main-stone');
      final target = _record(
        id: 'stone-chain',
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(
            id: 'main-stone',
            sourceElementId: 'element-main-stone',
            role: BorderPrimitiveRole.structureLarge,
          ),
        ],
      );
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[target],
        elements: <ProjectElementEntry>[_element('element-main-stone')],
      );

      final result = const BorderPublicationCandidateBuilder().build(
        manifest: manifest,
        draftRecord: target,
        primitiveSnapshotsByPrimitiveId: <String,
            BorderAssetSnapshotPreparation>{
          'main-stone': preparation,
        },
      );

      expect(
        result.nextManifest.borderCatalog.formatVersion,
        ProjectBorderCatalog.formatVersionV3,
      );
      expect(
        result.nextManifest.borderCatalog.records.single.latestPublished!
            .definition.primitives.single.role,
        BorderPrimitiveRole.structureLarge,
      );
    });

    test('publishes cardinal orientation and promotes the catalog to V4', () {
      final preparation =
          _preparation('f', sourceElementId: 'element-oriented');
      final target = _record(
        id: 'oriented-coast',
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(
            id: 'oriented',
            sourceElementId: 'element-oriented',
            authoredOrientation: BorderPrimitiveOrientation.west,
          ),
        ],
      );
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[target],
        elements: <ProjectElementEntry>[_element('element-oriented')],
      );

      final result = const BorderPublicationCandidateBuilder().build(
        manifest: manifest,
        draftRecord: target,
        primitiveSnapshotsByPrimitiveId: <String,
            BorderAssetSnapshotPreparation>{
          'oriented': preparation,
        },
      );

      expect(
        result.nextManifest.borderCatalog.records.single.latestPublished!
            .definition.primitives.single.authoredOrientation,
        BorderPrimitiveOrientation.west,
      );
      expect(
        result.nextManifest.borderCatalog.formatVersion,
        ProjectBorderCatalog.formatVersionV4,
      );
    });

    test('candidate fingerprint includes cardinal and omits legacy orientation',
        () {
      BorderBlueprintPublishedDefinition publish(
        BorderPrimitiveOrientation orientation,
      ) {
        final preparation = _preparation(
          'f',
          sourceElementId: 'element-oriented',
        );
        final target = _record(
          id: 'fingerprinted-coast',
          primitives: <BorderPrimitiveDraft>[
            _draftPrimitive(
              id: 'oriented',
              sourceElementId: 'element-oriented',
              authoredOrientation: orientation,
            ),
          ],
        );
        final result = const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[target],
            elements: <ProjectElementEntry>[_element('element-oriented')],
          ),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: <String,
              BorderAssetSnapshotPreparation>{
            'oriented': preparation,
          },
        );
        return result.nextManifest.borderCatalog.records.single.latestPublished!
            .definition;
      }

      String fingerprint(BorderPrimitiveOrientation orientation) =>
          computeBorderPublicationCandidateFingerprint(
            blueprintId: 'fingerprinted-coast',
            definition: publish(orientation),
            resolverVersion: borderResolverVersion,
            canonicalGalleryVersion: 1,
          );

      final legacy = fingerprint(BorderPrimitiveOrientation.legacyAxis);
      final east = fingerprint(BorderPrimitiveOrientation.east);
      final west = fingerprint(BorderPrimitiveOrientation.west);

      expect(
        legacy,
        'sha256:f9dd002dfd0e8a48a3005e9bf51ceb28a21805ee6b9276fca75363e98dec794a',
      );
      expect(east, isNot(legacy));
      expect(west, isNot(legacy));
      expect(east, isNot(west));
    });

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

    test('rejects a preparation from a different project element', () {
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
          primitiveSnapshotsByPrimitiveId: <String,
              BorderAssetSnapshotPreparation>{
            'large': _preparation(
              'a',
              sourceElementId: 'another-element',
            ),
          },
        ),
        throwsA(
          isA<BorderPublicationCandidateException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationCandidateErrorCode
                    .primitiveSnapshotSourceMismatch,
              )
              .having(
                (error) => error.primitiveId,
                'primitiveId',
                'large',
              )
              .having(
                (error) => error.sourceElementId,
                'sourceElementId',
                'another-element',
              ),
        ),
      );
    });

    test('deduplicates prior and new snapshots while preserving prior order',
        () {
      final retainedA = _preparation(
        'a',
        sourceElementId: 'element-one',
      );
      final retainedB = _preparation('b');
      final appendedForTwo = _preparation(
        'c',
        sourceElementId: 'element-two',
      );
      final appendedForThree = _preparation(
        'c',
        sourceElementId: 'element-three',
      );
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
          'two': appendedForTwo,
          'three': appendedForThree,
        },
      );

      expect(
        result.nextManifest.borderCatalog.visualSnapshots,
        <BorderVisualSnapshot>[
          retainedA.snapshot,
          retainedB.snapshot,
          appendedForTwo.snapshot,
        ],
      );
      expect(
        result.files,
        <BorderSnapshotFilePayload>[
          ...retainedA.files,
          ...appendedForTwo.files,
        ],
      );
      expect(result.snapshotIntegrity.keys, <String>{
        retainedA.snapshot.id,
        appendedForTwo.snapshot.id,
      });
      expect(
        result.primitiveSnapshotIdsByPrimitiveId,
        <String, String>{
          'one': retainedA.snapshot.id,
          'two': appendedForTwo.snapshot.id,
          'three': appendedForThree.snapshot.id,
        },
      );
    });

    test('rejects conflicting bytes for an otherwise shared payload path', () {
      final shared = _preparation(
        'c',
        sourceElementId: 'element-one',
      );
      final conflicting = BorderAssetSnapshotPreparation(
        sourceElementId: 'element-two',
        snapshot: shared.snapshot,
        metrics: _metrics('conflicting-source'),
        files: <BorderSnapshotFilePayload>[
          BorderSnapshotFilePayload(
            relativePath: shared.files.single.relativePath,
            bytes: Uint8List.fromList(<int>[255]),
          ),
        ],
      );
      final target = _record(
        id: 'coast',
        primitives: <BorderPrimitiveDraft>[
          _draftPrimitive(id: 'one', sourceElementId: 'element-one'),
          _draftPrimitive(id: 'two', sourceElementId: 'element-two'),
        ],
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[target],
            elements: <ProjectElementEntry>[
              _element('element-one'),
              _element('element-two'),
            ],
          ),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: <String,
              BorderAssetSnapshotPreparation>{
            'one': shared,
            'two': conflicting,
          },
        ),
        throwsA(
          isA<BorderPublicationCandidateException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationCandidateErrorCode.snapshotPayloadConflict,
              )
              .having(
                (error) => error.relativePath,
                'relativePath',
                shared.files.single.relativePath,
              ),
        ),
      );
    });

    test('rejects a ground draft that references an absent Smart Tile preset',
        () {
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSmartTilePresetId: 'missing-surface',
          edgeBandCells: 2,
        ),
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(records: <BorderBlueprintRecord>[target]),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
          groundSnapshotsByRole: const <BorderGroundVariantRole,
              BorderAssetSnapshotPreparation>{},
        ),
        throwsA(
          isA<BorderPublicationCandidateException>().having(
            (error) => error.code,
            'code',
            BorderPublicationCandidateErrorCode.sourceSmartTilePresetMissing,
          ),
        ),
      );
    });

    test('requires every standard Smart Tile role for published ground', () {
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSmartTilePresetId: 'shore',
          edgeBandCells: 2,
        ),
      );
      final onlyIsolated =
          <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{
        BorderGroundVariantRole.isolated:
            _preparation('a', sourceElementId: 'shore'),
      };

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[target],
            smartTilePreset: _smartTilePreset('shore'),
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
                (error) => error.groundRole,
                'groundRole',
                BorderGroundVariantRole.endNorth,
              ),
        ),
      );
    });

    test('publishes complete ground snapshots in stable Smart Tile role order',
        () {
      final shared = _preparation('d', sourceElementId: 'shore');
      final byRole = <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{
        for (final role in standardBorderGroundVariantRoleOrder) role: shared,
      };
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSmartTilePresetId: 'shore',
          edgeBandCells: 3,
        ),
      );

      final result = const BorderPublicationCandidateBuilder().build(
        manifest: _manifest(
          records: <BorderBlueprintRecord>[target],
          smartTilePreset: _smartTilePreset('shore'),
        ),
        draftRecord: target,
        primitiveSnapshotsByPrimitiveId: const <String,
            BorderAssetSnapshotPreparation>{},
        groundSnapshotsByRole: byRole,
      );

      final ground = result.nextManifest.borderCatalog.records.single
          .latestPublished!.definition.ground!;
      expect(ground.sourceSmartTilePresetId, 'shore');
      expect(ground.edgeBandCells, 3);
      expect(
        ground.visualSnapshotIdsByRole.keys,
        standardBorderGroundVariantRoleOrder,
      );
      expect(
        ground.visualSnapshotIdsByRole.values.toSet(),
        <String>{shared.snapshot.id},
      );
      expect(result.groundSnapshotIdsByRole.keys,
          standardBorderGroundVariantRoleOrder);
      expect(result.files, shared.files);
      expect(
        result.nextManifest.borderCatalog.visualSnapshots,
        <BorderVisualSnapshot>[shared.snapshot],
      );
    });

    test('rejects ground snapshots prepared from another Smart Tile preset',
        () {
      final target = _record(
        id: 'coast',
        ground: BorderGroundDraft(
          sourceSmartTilePresetId: 'shore',
          edgeBandCells: 2,
        ),
      );
      final wrongSource = _preparation(
        'e',
        sourceElementId: 'other-surface',
      );

      expect(
        () => const BorderPublicationCandidateBuilder().build(
          manifest: _manifest(
            records: <BorderBlueprintRecord>[target],
            smartTilePreset: _smartTilePreset('shore'),
          ),
          draftRecord: target,
          primitiveSnapshotsByPrimitiveId: const <String,
              BorderAssetSnapshotPreparation>{},
          groundSnapshotsByRole: <BorderGroundVariantRole,
              BorderAssetSnapshotPreparation>{
            for (final role in standardBorderGroundVariantRoleOrder)
              role: wrongSource,
          },
        ),
        throwsA(
          isA<BorderPublicationCandidateException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationCandidateErrorCode
                    .groundSnapshotSourceMismatch,
              )
              .having(
                (error) => error.groundRole,
                'groundRole',
                BorderGroundVariantRole.isolated,
              )
              .having(
                (error) => error.sourceSmartTilePresetId,
                'sourceSmartTilePresetId',
                'shore',
              )
              .having(
                (error) => error.sourceElementId,
                'sourceElementId',
                'other-surface',
              ),
        ),
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
          groundSnapshotsByRole: <BorderGroundVariantRole,
              BorderAssetSnapshotPreparation>{
            BorderGroundVariantRole.isolated: _preparation('a'),
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
  ProjectSmartTilePreset? smartTilePreset,
}) {
  return ProjectManifest(
    name: 'Candidate project',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    elements: elements,
    globalProperties: const <String, Object?>{'untouched': true},
    smartTileCatalog: smartTilePreset == null
        ? const ProjectSmartTileCatalog.empty()
        : ProjectSmartTileCatalog(
            materials: const <ProjectSmartTileMaterial>[
              ProjectSmartTileMaterial(
                id: 'ground',
                name: 'Ground',
                connectionGroupId: 'ground',
              ),
            ],
            presets: <ProjectSmartTilePreset>[smartTilePreset],
          ),
    borderCatalog: ProjectBorderCatalog(
      records: records,
      visualSnapshots: snapshots,
    ),
  );
}

BorderBlueprintRecord _record({
  required String id,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  int baseRevision = 0,
  int? latestRevision,
  bool isDeprecated = false,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
  BorderGroundDraft? ground,
}) {
  final definition = BorderBlueprintDraftDefinition(
    name: 'Blueprint $id',
    previewSeed: BorderSignedInt64.zero,
    template: template,
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
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
  BorderPrimitiveOrientation authoredOrientation =
      BorderPrimitiveOrientation.legacyAxis,
  int weight = 100,
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: sourceElementId,
    role: role,
    authoredOrientation: authoredOrientation,
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

ProjectSmartTilePreset _smartTilePreset(String id) {
  return ProjectSmartTilePreset(
    id: id,
    name: id,
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.uniform,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'ground',
    allowedMaterialIds: const <String>['ground'],
  );
}

BorderAssetSnapshotPreparation _preparation(
  String digit, {
  String? sourceElementId,
}) {
  final fingerprint = digit * 64;
  final relativePath = 'assets/borders/snapshots/$fingerprint/frame_0000.png';
  return BorderAssetSnapshotPreparation(
    sourceElementId: sourceElementId ?? 'element-$digit',
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
