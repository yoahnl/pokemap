import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../assets/resource_information_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show context, spatialBorderAuthoringFixture;

const _prefix = 'border_layer.feature_';
const _ids = {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'};

void main() {
  test('five closed semantic override contracts are discoverable', () {
    final descriptors = BorderActions.descriptors;
    for (final entry in {
      'set_replacement': 'primitiveId',
      'set_offset': 'offsetDeltaPx',
      'set_transform': 'transformOverride',
      'set_suppressed': 'suppressed',
      'clear_slot_override': null
    }.entries) {
      final descriptor = descriptors
          .singleWhere((value) => value.id == '$_prefix${entry.key}');
      expect(descriptor.extensions['visualKinds'],
          entry.key == 'set_offset' ? ['element'] : ['element', 'model3d']);
      final schema = descriptor.extensions['inputSchema'] as Map;
      expect(schema['additionalProperties'], false);
      expect(
          schema['required'],
          containsAll(
              [..._ids.keys, 'slotKey', if (entry.value != null) entry.value]));
    }
  });

  test(
      'setters preserve neighbors and stale output until canonical materialization',
      () async {
    final fixture = borderSlotOverrideFixture();
    final base = borderSlotFeature(fixture.map);
    final slot = base.materialization!.placements
        .singleWhere((p) => p.anchorCell.x == 3)
        .slotKey;
    var map = await _build(fixture, fixture.map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': 'alternate'});
    map = await _build(fixture, map, 'set_offset', {
      'slotKey': slot,
      'offsetDeltaPx': {'x': 1, 'y': 0}
    });
    map = await _build(fixture, map, 'set_transform', {
      'slotKey': slot,
      'transformOverride': {'quarterTurns': 0, 'flipX': false}
    });
    final changed = borderSlotFeature(map);
    expect(changed.materialization, base.materialization);
    final override = changed.overrides.single;
    expect(override.replacementPrimitiveId, 'alternate');
    expect(override.offsetDeltaPx, const BorderPixelOffset(x: 1, y: 0));
    expect(override.transformOverride,
        BorderSpriteTransform(quarterTurns: 0, flipX: false));
    expect(map.layers.first, fixture.map.layers.first);
    expect(_freshness(fixture.project, map).reasons,
        contains(BorderStalenessReason.overridesChanged));
    map = await _build(fixture, map, 'clear_slot_override', {'slotKey': slot});
    expect(borderSlotFeature(map).overrides, isEmpty);
    map = await _materialize(fixture, map);
    expect(borderSlotFeature(map).materialization!.placements,
        base.materialization!.placements);
    expect(_freshness(fixture.project, map).state,
        BorderMaterializationState.fresh);
  });

  test('suppression clears corrections and can restore the generated slot',
      () async {
    final fixture = borderSlotOverrideFixture();
    final base = borderSlotFeature(fixture.map);
    final slot = base.materialization!.placements[2].slotKey;
    var map = await _build(fixture, fixture.map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': 'alternate'});
    map = await _build(
        fixture, map, 'set_suppressed', {'slotKey': slot, 'suppressed': true});
    final hidden = borderSlotFeature(map).overrides.single;
    expect(hidden.suppressed, true);
    expect(hidden.replacementPrimitiveId, isNull);
    expect(hidden.offsetDeltaPx, isNull);
    expect(hidden.transformOverride, isNull);
    map = await _materialize(fixture, map);
    expect(
        borderSlotFeature(map)
            .materialization!
            .placements
            .any((p) => p.slotKey == slot),
        false);
    map = await _build(
        fixture, map, 'set_suppressed', {'slotKey': slot, 'suppressed': false});
    map = await _materialize(fixture, map);
    expect(borderSlotFeature(map).materialization!.placements,
        base.materialization!.placements);
  });

  test(
      'targeted validators reject invalid corrections without global continuity gate',
      () async {
    final fixture = borderSlotOverrideFixture();
    final slot =
        borderSlotFeature(fixture.map).materialization!.placements[2].slotKey;
    for (final entry in [
      (
        'set_replacement',
        {'slotKey': 'missing', 'primitiveId': 'alternate'},
        'border.slot_missing'
      ),
      (
        'set_replacement',
        {'slotKey': slot, 'primitiveId': 'missing'},
        'border.resolution.override_primitive_missing'
      ),
      (
        'set_replacement',
        {'slotKey': slot, 'primitiveId': 'lineCap'},
        'border.resolution.override_primitive_role_mismatch'
      ),
      (
        'set_offset',
        {
          'slotKey': slot,
          'offsetDeltaPx': {'x': 10000, 'y': 0}
        },
        'border.resolution.override_outside_corridor'
      ),
      (
        'set_offset',
        {
          'slotKey': slot,
          'offsetDeltaPx': {'x': 1.5, 'y': 0}
        },
        'map.request_invalid'
      ),
      (
        'set_transform',
        {
          'slotKey': slot,
          'transformOverride': {'quarterTurns': 4, 'flipX': false}
        },
        'map.request_invalid'
      ),
      (
        'set_transform',
        {
          'slotKey': slot,
          'transformOverride': {
            'quarterTurns': 0,
            'flipX': false,
            'other': true
          }
        },
        'map.request_invalid'
      ),
      (
        'set_suppressed',
        {'slotKey': 'missing', 'suppressed': true},
        'border.slot_missing'
      ),
      ('clear_slot_override', {'slotKey': 'missing'}, 'border.slot_missing'),
    ]) {
      await expectLater(
          _build(fixture, fixture.map, entry.$1, entry.$2),
          throwsA(isA<MapAuthoringException>()
              .having((e) => e.code, 'code', entry.$3)));
    }
    final changed = await _build(fixture, fixture.map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': 'alternate'});
    await expectLater(
        _build(fixture, changed, 'set_transform', {
          'slotKey': slot,
          'transformOverride': {'quarterTurns': 1, 'flipX': false}
        }),
        throwsA(isA<MapAuthoringException>().having((e) => e.code, 'code',
            'border.resolution.override_transform_not_allowed')));
    final locked = updateBorderFeatureOverrides(fixture.map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
              slotKey: slot,
              variationSalt: BorderSignedInt64.zero,
              suppressed: false,
              locked: true,
              lockedPlacement:
                  borderSlotFeature(fixture.map).materialization!.placements[2])
        ]);
    for (final entry in {
      'clear_slot_override': <String, Object?>{},
      'set_replacement': <String, Object?>{'primitiveId': null},
      'set_offset': <String, Object?>{'offsetDeltaPx': null},
      'set_transform': <String, Object?>{'transformOverride': null},
      'set_suppressed': <String, Object?>{'suppressed': true}
    }.entries) {
      await expectLater(
          _build(fixture, locked, entry.key, {'slotKey': slot, ...entry.value}),
          throwsA(isA<MapAuthoringException>()
              .having((e) => e.code, 'code', 'border.slot_locked')));
    }
  });

  test(
      'editing can restore an unmaterializable draft without bypassing materialization validation',
      () async {
    final fixture = borderSlotOverrideFixture();
    final placements =
        borderSlotFeature(fixture.map).materialization!.placements;
    var map = fixture.map;
    for (final placement in placements) {
      map = await _build(fixture, map, 'set_suppressed',
          {'slotKey': placement.slotKey, 'suppressed': true});
    }
    expect(
        resolveBorderFeature(borderSlotRequest(fixture.project, map)).canApply,
        false);
    await expectLater(
        _materialize(fixture, map),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.materialization_failed')));
    map = await _build(fixture, map, 'clear_slot_override',
        {'slotKey': placements.first.slotKey});
    map = await _materialize(fixture, map);
    expect(borderSlotFeature(map).materialization!.placements.single,
        placements.first);
  });

  test(
      'nullable setters clear only their field and preserve other slot corrections',
      () async {
    final fixture = borderSlotOverrideFixture();
    final placements =
        borderSlotFeature(fixture.map).materialization!.placements;
    final slot = placements[2].slotKey;
    final neighbor = BorderSlotOverride(
        slotKey: placements[3].slotKey,
        variationSalt: BorderSignedInt64.fromInt(9),
        suppressed: false,
        locked: false);
    var map = updateBorderFeatureOverrides(fixture.map,
        layerId: 'border', featureId: 'fence', overrides: [neighbor]);
    map = await _build(fixture, map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': 'alternate'});
    map = await _build(fixture, map, 'set_offset', {
      'slotKey': slot,
      'offsetDeltaPx': {'x': 1, 'y': 0}
    });
    map = await _build(fixture, map, 'set_transform', {
      'slotKey': slot,
      'transformOverride': {'quarterTurns': 0, 'flipX': false}
    });
    map = await _build(fixture, map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': null});
    var correction =
        borderSlotFeature(map).overrides.singleWhere((v) => v.slotKey == slot);
    expect(correction.replacementPrimitiveId, isNull);
    expect(correction.offsetDeltaPx, isNotNull);
    expect(correction.transformOverride, isNotNull);
    map = await _build(
        fixture, map, 'set_offset', {'slotKey': slot, 'offsetDeltaPx': null});
    map = await _build(fixture, map, 'set_transform',
        {'slotKey': slot, 'transformOverride': null});
    correction =
        borderSlotFeature(map).overrides.singleWhere((v) => v.slotKey == slot);
    expect(correction.offsetDeltaPx, isNull);
    expect(correction.transformOverride, isNull);
    expect(borderSlotFeature(map).overrides.first, neighbor);
    for (final entry in {
      'set_replacement': 'primitiveId',
      'set_offset': 'offsetDeltaPx',
      'set_transform': 'transformOverride'
    }.entries) {
      await expectLater(
          _build(fixture, map, entry.key, {'slotKey': slot}),
          throwsA(isA<MapAuthoringException>()
              .having((e) => e.code, 'code', 'map.request_invalid')));
    }
    map = await _build(
        fixture, map, 'set_suppressed', {'slotKey': slot, 'suppressed': true});
    await expectLater(
        _build(fixture, map, 'set_replacement',
            {'slotKey': slot, 'primitiveId': 'alternate'}),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.slot_suppressed')));
    expect(borderSlotFeature(map).overrides.first, neighbor);
  });

  test('base slot evidence survives invalid organic continuity', () async {
    final seed = borderSlotOverrideFixture();
    final primitive = BorderPublishedPrimitive(
        id: 'rock',
        sourceElementId: 'sprite',
        visualSnapshotId: seed.project.borderCatalog.visualSnapshots.single.id,
        role: BorderPrimitiveRole.structureLarge,
        weight: 1,
        anchorPx: const BorderPixelPos(x: 8, y: 8),
        transforms: BorderTransformPolicy(
            allowedQuarterTurns: const [0, 1, 2, 3], allowFlipX: true),
        publishedMetrics: BorderPrimitiveAssetMetrics(
            assetFingerprint: 'sparse',
            pixelSize: const GridSize(width: 16, height: 16),
            opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
            defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
            occupancyMaskRle:
                encodeBorderRleMask([for (var i = 0; i < 256; i++) i == 136])));
    final defaults = BorderGenerationParams(
        irregularityPermille: 0,
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1);
    final record = BorderBlueprintRecord(
        id: 'fence',
        draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: BorderBlueprintDraftDefinition(
                name: 'Coast',
                previewSeed: BorderSignedInt64.zero,
                template: BorderBlueprintTemplate.organicEdge,
                primitives: const [],
                defaults: defaults,
                sortOrder: 0)),
        latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
                name: 'Coast',
                previewSeed: BorderSignedInt64.zero,
                template: BorderBlueprintTemplate.organicEdge,
                primitives: [primitive],
                defaults: defaults,
                sortOrder: 0)));
    final project = seed.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            records: [record],
            visualSnapshots: seed.project.borderCatalog.visualSnapshots));
    final map = MapData(
        id: 'map',
        name: 'Coast',
        size: const GridSize(width: 5, height: 5),
        layers: [
          MapLayer.border(
              id: 'border',
              name: 'Border',
              content: BorderLayerContent(features: [
                BorderFeature(
                    id: 'fence',
                    name: 'Coast',
                    blueprintId: 'fence',
                    seed: BorderSignedInt64.zero,
                    geometry: BorderRegionGeometry(width: 5, height: 5, cells: [
                      for (var y = 0; y < 5; y++)
                        for (var x = 0; x < 5; x++)
                          x >= 1 && x <= 3 && y >= 1 && y <= 3
                    ]),
                    overrides: const [],
                    keepOutRegions: const [])
              ]))
        ]);
    final request = borderSlotRequest(project, map);
    final failed = resolveBorderFeature(request);
    expect(failed.canApply, false);
    expect(failed.diagnostics.map((d) => d.code),
        contains('border.resolution.coverage_gap'));
    final slots = resolveBorderFeatureBaseSlotKeys(request);
    expect(slots, isNotEmpty);
    final fixture = (project: project, map: map);
    await expectLater(
        _build(fixture, map, 'set_replacement',
            {'slotKey': 'unknown', 'primitiveId': 'rock'}),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.slot_missing')));
    final corrected = await _build(fixture, map, 'set_replacement',
        {'slotKey': slots.first, 'primitiveId': 'rock'});
    expect(borderSlotFeature(corrected).overrides.single.slotKey, slots.first);
    await expectLater(
        _materialize(fixture, corrected),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.materialization_failed')));
  });

  test('pixel offsets reject spatial features explicitly',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    for (final entry in {
      'set_offset': <String, Object?>{'offsetDeltaPx': null},
    }.entries) {
      await expectLater(
          _build(fixture, fixture.map, entry.key,
              {'slotKey': 'any', ...entry.value}),
          throwsA(isA<MapAuthoringException>().having((e) => e.code, 'code',
              'border.spatial.sprite_override_unsupported')));
    }
  });

  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'API'} plans and applies semantic overrides without manifest writes',
        () async {
      final fixture = borderSlotOverrideFixture();
      final host = await ResourceInformationFixture.create(
          fixture.project.copyWith(maps: const []));
      addTearDown(host.dispose);
      final file = File('${host.root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(fixture.map.toJson()));
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(fixture.project.toJson()));
      final manifest =
          await File('${host.root.path}/project.json').readAsBytes();
      final slot =
          borderSlotFeature(fixture.map).materialization!.placements[2].slotKey;
      final actions = <(String, Map<String, Object?>)>[
        ('set_replacement', {'primitiveId': 'alternate'}),
        (
          'set_offset',
          {
            'offsetDeltaPx': {'x': 1, 'y': 0}
          }
        ),
        (
          'set_transform',
          {
            'transformOverride': {'quarterTurns': 0, 'flipX': false}
          }
        ),
        ('set_suppressed', {'suppressed': true}),
        ('set_suppressed', {'suppressed': false}),
        ('clear_slot_override', {}),
      ];
      for (var index = 0; index < actions.length; index++) {
        final (action, parameters) = actions[index];
        final original = await file.readAsBytes();
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final operationId = 'override-$index';
        final request = AuthoringRequest(
            requestId: operationId,
            actionId: '$_prefix$action',
            actionVersion: 1,
            workspaceHandle: host.workspace,
            parameters: {..._ids, 'slotKey': slot, ...parameters},
            expectedRevision: snapshot.revision,
            idempotencyKey: operationId);
        final planId = jsonl
            ? (await host.command('plan', {
                'projectHandle': host.project,
                'request': request.toJson()
              }))
                .data['planId'] as String
            : (await host.mutations
                    .planMutation(ProjectHandle(host.project), request))
                .planId;
        expect(await file.readAsBytes(), original);
        if (jsonl) {
          final result = await host.command('apply', {
            'projectHandle': host.project,
            'planId': planId,
            'operationId': operationId
          });
          expect(result.status, AuthoringResultStatus.success,
              reason: jsonEncode(result.toJson()));
        } else {
          final result = await host.mutations.applyMutation(
              ProjectHandle(host.project),
              planId: planId,
              operationId: operationId);
          expect(result.receipt.status, AuthoringReceiptStatus.applied);
        }
        final after = MapData.fromJson(jsonDecode(await file.readAsString()));
        final overrides = borderSlotFeature(after).overrides;
        if (index == 0) {
          expect(overrides.single.replacementPrimitiveId, 'alternate');
        } else if (index == 1) {
          expect(overrides.single.replacementPrimitiveId, 'alternate');
          expect(overrides.single.offsetDeltaPx,
              const BorderPixelOffset(x: 1, y: 0));
        } else if (index == 2) {
          expect(overrides.single.transformOverride,
              BorderSpriteTransform(quarterTurns: 0, flipX: false));
        } else if (index == 3) {
          expect(overrides.single.suppressed, true);
          expect(overrides.single.replacementPrimitiveId, isNull);
          expect(overrides.single.offsetDeltaPx, isNull);
          expect(overrides.single.transformOverride, isNull);
        } else if (index == 4) {
          expect(overrides.single.suppressed, false);
        } else {
          expect(overrides, isEmpty);
          expect(borderSlotFeature(after).materialization,
              borderSlotFeature(fixture.map).materialization);
        }
        expect(await File('${host.root.path}/project.json').readAsBytes(),
            manifest);
        if (index < 5) {
          expect(_freshness(fixture.project, after).reasons,
              contains(BorderStalenessReason.overridesChanged));
        }
      }
    });
  }
}

Future<MapData> _build(({ProjectManifest project, MapData map}) fixture,
    MapData map, String action, Map<String, Object?> parameters) async {
  final draft = await MapMutationDispatcher.canonical().build(context(
      librarySnapshot([map], project: fixture.project),
      '$_prefix$action',
      {..._ids, ...parameters}));
  return MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
}

Future<MapData> _materialize(
    ({ProjectManifest project, MapData map}) fixture, MapData map) async {
  final draft = await MapMutationDispatcher.canonical().build(context(
      librarySnapshot([map], project: fixture.project),
      'border_layer.materialize_apply', {
    ..._ids,
    'tileWidthPx': 16,
    'tileHeightPx': 16,
    'resolverVersion': borderResolverVersion
  }));
  return MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
}

BorderFeature borderSlotFeature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

BorderResolutionRequest borderSlotRequest(
        ProjectManifest project, MapData map) =>
    BorderResolutionRequest(
        mapSize: map.size,
        tileSizePx: const GridSize(width: 16, height: 16),
        blueprintId: 'fence',
        blueprintRevision:
            project.borderCatalog.recordById('fence')!.latestPublished!,
        feature: borderSlotFeature(map),
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion);

BorderMaterializationFreshness _freshness(
        ProjectManifest project, MapData map) =>
    assessBorderMaterializationFreshness(borderSlotRequest(project, map),
        materialization: borderSlotFeature(map).materialization,
        snapshotIntegrity: {
          for (final snapshot in project.borderCatalog.visualSnapshots)
            snapshot.id: BorderVisualSnapshotIntegrity(
                snapshotId: snapshot.id,
                metadataValid: true,
                filesPresent: true,
                contentFingerprintMatches: true)
        });

({ProjectManifest project, MapData map}) borderSlotOverrideFixture(
    {int gapTolerancePx = 0,
    int maxOverlapPx = 0,
    bool permissiveAlternateTransforms = false}) {
  final defaults = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: 1);
  final primitives = [
    for (final role in [
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.lineStraight,
      BorderPrimitiveRole.lineCorner
    ])
      BorderPublishedPrimitive(
          id: role.name,
          sourceElementId: 'sprite',
          visualSnapshotId: 'border-snapshot-sha256:${'a' * 64}',
          role: role,
          weight: 1,
          anchorPx: const BorderPixelPos(x: 7, y: 7),
          transforms: BorderTransformPolicy(
              allowedQuarterTurns: const [0, 1, 2, 3], allowFlipX: true),
          publishedMetrics: BorderPrimitiveAssetMetrics(
              assetFingerprint: 'sprite',
              pixelSize: const GridSize(width: 16, height: 16),
              opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
              defaultAnchorPx: const BorderPixelPos(x: 7, y: 7),
              occupancyMaskRle: encodeBorderRleMask(List.filled(256, true))))
  ];
  primitives.add(BorderPublishedPrimitive(
      id: 'alternate',
      sourceElementId: 'sprite',
      visualSnapshotId: 'border-snapshot-sha256:${'a' * 64}',
      role: BorderPrimitiveRole.lineStraight,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 7, y: 7),
      transforms: BorderTransformPolicy(
          allowedQuarterTurns:
              permissiveAlternateTransforms ? const [0, 1, 2, 3] : const [0],
          allowFlipX: permissiveAlternateTransforms),
      publishedMetrics: primitives[1].publishedMetrics));
  final project = ProjectManifest(
      name: 'Planar border',
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      tilesets: const [
        ProjectTilesetEntry(
            id: 'atlas', name: 'Atlas', relativePath: 'atlas.png')
      ],
      elements: const [
        ProjectElementEntry(
            id: 'sprite',
            name: 'Sprite',
            tilesetId: 'atlas',
            categoryId: 'decor',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16))
            ])
      ],
      borderCatalog: ProjectBorderCatalog(formatVersion: 2, records: [
        BorderBlueprintRecord(
            id: 'fence',
            draft: BorderBlueprintDraft(
                baseRevision: 1,
                definition: BorderBlueprintDraftDefinition(
                    name: 'Fence',
                    previewSeed: BorderSignedInt64.zero,
                    template: BorderBlueprintTemplate.connectedLine,
                    primitives: const [],
                    defaults: defaults,
                    sortOrder: 0)),
            latestPublished: BorderBlueprintRevision(
                revision: 1,
                definition: BorderBlueprintPublishedDefinition(
                    name: 'Fence',
                    previewSeed: BorderSignedInt64.zero,
                    template: BorderBlueprintTemplate.connectedLine,
                    primitives: primitives,
                    defaults: defaults,
                    sortOrder: 0)))
      ], visualSnapshots: [
        BorderVisualSnapshot(
            id: 'border-snapshot-sha256:${'a' * 64}',
            contentFingerprint: 'a' * 64,
            frames: [
              BorderVisualFrameSnapshot(
                  relativeAssetPath: 'assets/borders/snapshots/${'a' * 64}.png',
                  sourceRectPx:
                      BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
                  durationMs: 100)
            ])
      ]));
  final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 10, height: 6),
      layers: [
        MapLayer.tile(
            id: 'foreign',
            name: 'Foreign',
            palette: const [
              TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0)
            ],
            cells: List.filled(60, 0)),
        MapLayer.border(
            id: 'border',
            name: 'Border',
            content: BorderLayerContent(formatVersion: 2, features: [
              BorderFeature(
                  id: 'fence',
                  name: 'Fence',
                  blueprintId: 'fence',
                  seed: BorderSignedInt64.fromInt(17),
                  overrides: const [],
                  keepOutRegions: const [],
                  geometry: BorderStrokeGeometry(strokes: [
                    BorderStroke(id: 'line', closed: false, points: [
                      for (var x = 1; x <= 7; x++) GridPos(x: x, y: 1)
                    ])
                  ]))
            ]))
      ]);
  final feature = borderSlotFeature(map);
  final request = borderSlotRequest(project, map);
  final result = resolveBorderFeature(request);
  if (!result.canApply) throw StateError('${result.diagnostics}');
  final materialized = applyBorderFeaturePreview(map,
      expectedMapId: map.id,
      layerId: 'border',
      featureId: 'fence',
      expectedBaseFeatureFingerprint:
          computeBorderFeatureEditFingerprint(feature),
      proposedRequest: request,
      proposedResult: result);
  return (project: project, map: materialized);
}
