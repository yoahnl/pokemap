import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'environment_spatial_actions_test.dart'
    show spatialEnvironmentFixture, environmentModelGlb;

void main() {
  test(
      'spatial reversal preserves alternating visual phases on an even open contour',
      () async {
    final base = spatialBorderAuthoringFixture(
        published: true, straightOnly: true, includeCorner: false);
    final raw = encodeBorderBlueprintRecordJson(
        base.project.borderCatalog.records.single,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    for (final section in ['draft', 'latestPublished']) {
      final definition = (raw[section] as Map)['definition'] as Map;
      definition['followContourDirection'] = true;
      definition['sequenceLength'] = 2;
      definition['primitives'] = [
        for (final p in definition['primitives'] as List)
          for (var phase = 0; phase < 2; phase++)
            {...p as Map, 'id': '${p['id']}-$phase', 'sequenceIndex': phase}
      ];
    }
    final source = decodeBorderBlueprintRecordJson(raw,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    raw['id'] = 'replacement';
    final target = decodeBorderBlueprintRecordJson(raw,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    final project = base.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [source, target]));
    final map = updateBorderFeatureGeometry(base.map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(strokes: [
          BorderStroke(id: 'line', closed: false, points: const [
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
            GridPos(x: 3, y: 1),
            GridPos(x: 4, y: 1)
          ])
        ]));
    final before = resolveSpatialBorderFeature(
        manifest: project, map: map, layerId: 'border', featureId: 'fence');
    final after = relinkSpatialBorderFeature(map,
        manifest: project,
        layerId: 'border',
        featureId: 'fence',
        targetBlueprintId: 'replacement',
        reverseStrokes: true);
    final feature =
        (after.layers.single as BorderLayer).content.features.single;
    expect({
      for (final p in feature.materialization!.spatialPlacements)
        p.slotKey: p.primitiveId
    }, {
      for (final p in before.result.materialization!.spatialPlacements)
        p.slotKey: p.primitiveId
    });
    final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
    final edit = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([after], project: project),
        'border_layer.stroke_update', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'strokeId': stroke.id,
      'points': stroke.points.skip(1).map((p) => {'x': p.x, 'y': p.y}).toList(),
    }));
    final edited = MapData.fromJson(
        jsonDecode(utf8.decode(edit.changeSet.changes.single.afterBytes!)));
    expect(
        resolveSpatialBorderFeature(
                manifest: project,
                map: edited,
                layerId: 'border',
                featureId: 'fence')
            .result
            .canApply,
        isTrue);
  });
  for (final action in [
    'border_layer.relink_apply',
    'border_layer.feature_set_blueprint'
  ]) {
    test(
        '$action atomically reverses spatial contours and retains authored corrections',
        () async {
      final base = spatialBorderAuthoringFixture(published: true);
      final record = encodeBorderBlueprintRecordJson(
          base.project.borderCatalog.records.single,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
      record['id'] = 'replacement';
      final target = decodeBorderBlueprintRecordJson(record,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
      final project = base.project.copyWith(
          borderCatalog: ProjectBorderCatalog(
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
              records: [...base.project.borderCatalog.records, target]));
      var map = applySpatialBorderFeaturePreview(base.map,
          manifest: project,
          proposedResult: resolveSpatialBorderFeature(
              manifest: project,
              map: base.map,
              layerId: 'border',
              featureId: 'fence'));
      final layer = map.layers.single as BorderLayer;
      final source = layer.content.features.single;
      final placements = source.materialization!.spatialPlacements;
      final overrides = [
        BorderSlotOverride(
            slotKey: placements.first.slotKey,
            variationSalt: BorderSignedInt64.fromInt(5),
            suppressed: true,
            locked: false),
        BorderSlotOverride(
            slotKey: placements[1].slotKey,
            variationSalt: BorderSignedInt64.fromInt(8),
            suppressed: false,
            locked: false,
            replacementPrimitiveId: placements[1].primitiveId),
      ];
      final authored = BorderFeature(
          id: source.id,
          name: source.name,
          blueprintId: source.blueprintId,
          seed: source.seed,
          geometry: source.geometry,
          lineSide: source.lineSide,
          spatialOffsetWorld: Model3dVector3(x: .01, y: 2, z: -.01),
          paramsOverride: source.paramsOverride,
          overrides: overrides,
          keepOutRegions: [
            BorderKeepOutRegion(
                id: 'retained-opening',
                region: BorderRegionGeometry(
                    width: map.size.width,
                    height: map.size.height,
                    cells: List.generate(
                        map.size.width * map.size.height,
                        (index) =>
                            index == map.size.width * map.size.height - 1)))
          ],
          materialization: source.materialization);
      map = upsertBorderFeature(map, layerId: 'border', feature: authored);
      final sentinel = SpatialModelInstance(
          id: 'unrelated-tree',
          modelId: 'tree',
          position: Model3dVector3(x: 0, y: 0, z: 0));
      map = map.copyWith(
          spatialScene: map.spatialScene!
              .copyWith(instances: [...map.spatialScene!.instances, sentinel]));
      final before = jsonEncode(map.toJson());
      final mutation = await MapMutationDispatcher.canonical()
          .build(context(librarySnapshot([map], project: project), action, {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence',
        'targetBlueprintId': 'replacement',
        'reverseStrokes': true,
        'clearVerticalOffset': true,
        'replacementPrimitiveIdsBySlot': {
          placements[1].slotKey: placements[1].primitiveId
        },
      }));
      expect(jsonEncode(map.toJson()), before);
      final after = MapData.fromJson(jsonDecode(
          utf8.decode(mutation.changeSet.changes.single.afterBytes!)));
      final feature =
          (after.layers.single as BorderLayer).content.features.single;
      expect(feature.id, authored.id);
      expect(feature.name, authored.name);
      expect(feature.seed, authored.seed);
      expect(feature.keepOutRegions, authored.keepOutRegions);
      expect(feature.overrides, overrides);
      expect(feature.blueprintId, 'replacement');
      expect(feature.spatialOffsetWorld, Model3dVector3(x: .01, y: 0, z: -.01));
      expect(
          (feature.geometry as BorderStrokeGeometry).strokes.single.points,
          (source.geometry as BorderStrokeGeometry)
              .strokes
              .single
              .points
              .reversed
              .toList());
      expect(feature.materialization!.spatialPlacements, hasLength(2));
      expect(after.spatialScene!.instances.map((i) => i.id).toSet(),
          {...feature.generatedPlacementIds, sentinel.id});
      expect(
          after.spatialScene!.instances.firstWhere((i) => i.id == sentinel.id),
          sentinel);
      expect(
          diagnoseSpatialBorderFeature(
                  manifest: project,
                  map: after,
                  layerId: 'border',
                  featureId: 'fence')
              .hasErrors,
          isFalse);
    });
  }

  test(
      'spatial relink refuses missing and foreign override mappings without mutation',
      () async {
    final base = spatialBorderAuthoringFixture(published: true);
    final record = encodeBorderBlueprintRecordJson(
        base.project.borderCatalog.records.single,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    record['id'] = 'replacement';
    final project = base.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [
          ...base.project.borderCatalog.records,
          decodeBorderBlueprintRecordJson(record,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion)
        ]));
    final resolved = resolveSpatialBorderFeature(
        manifest: project,
        map: base.map,
        layerId: 'border',
        featureId: 'fence');
    final placement = resolved.result.materialization!.spatialPlacements[1];
    final map = updateBorderFeatureOverrides(base.map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
              slotKey: placement.slotKey,
              variationSalt: BorderSignedInt64.fromInt(0),
              suppressed: false,
              locked: false,
              replacementPrimitiveId: placement.primitiveId)
        ]);
    final before = jsonEncode(map.toJson());
    for (final mapping in <Map<String, String>>[
      {},
      {'foreign-slot': placement.primitiveId},
      {placement.slotKey: 'missing-primitive'},
    ]) {
      await expectLater(
          () => MapMutationDispatcher.canonical().build(context(
                  librarySnapshot([map], project: project),
                  'border_layer.relink_apply', {
                'mapId': 'map',
                'layerId': 'border',
                'featureId': 'fence',
                'targetBlueprintId': 'replacement',
                'reverseStrokes': true,
                'clearVerticalOffset': true,
                'replacementPrimitiveIdsBySlot': mapping,
              })),
          throwsA(
              anyOf(isA<MapAuthoringException>(), isA<ValidationException>())));
      expect(jsonEncode(map.toJson()), before);
    }
  });

  test(
      'spatial relink reverses a closed contour while retaining its first vertex',
      () {
    final base = spatialBorderAuthoringFixture(published: true);
    final record = encodeBorderBlueprintRecordJson(
        base.project.borderCatalog.records.single,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    record['id'] = 'replacement';
    final project = base.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [
          ...base.project.borderCatalog.records,
          decodeBorderBlueprintRecordJson(record,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion)
        ]));
    final points = const [
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
      GridPos(x: 3, y: 2),
      GridPos(x: 3, y: 3),
      GridPos(x: 2, y: 3),
      GridPos(x: 1, y: 3),
      GridPos(x: 1, y: 2)
    ];
    final map = updateBorderFeatureGeometry(base.map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(strokes: [
          BorderStroke(id: 'closed', points: points, closed: true)
        ]));
    final before = jsonEncode(map.toJson());
    final after = relinkSpatialBorderFeature(map,
        manifest: project,
        layerId: 'border',
        featureId: 'fence',
        targetBlueprintId: 'replacement',
        reverseStrokes: true);
    final feature =
        (after.layers.single as BorderLayer).content.features.single;
    final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
    expect(stroke.closed, isTrue);
    expect(stroke.points, [points.first, ...points.skip(1).toList().reversed]);
    expect(feature.id, 'fence');
    expect(feature.materialization!.spatialPlacements, isNotEmpty);
    expect(jsonEncode(map.toJson()), before);
    expect(
        diagnoseSpatialBorderFeature(
                manifest: project,
                map: after,
                layerId: 'border',
                featureId: 'fence')
            .hasErrors,
        isFalse);
  });

  for (final correction in ['locked', 'transform', 'offset']) {
    test('spatial relink refuses a $correction correction without mutation',
        () {
      final base = spatialBorderAuthoringFixture(published: true);
      final record = encodeBorderBlueprintRecordJson(
          base.project.borderCatalog.records.single,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
      record['id'] = 'replacement';
      final project = base.project.copyWith(
          borderCatalog: ProjectBorderCatalog(
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
              records: [
            ...base.project.borderCatalog.records,
            decodeBorderBlueprintRecordJson(record,
                formatVersion:
                    ProjectBorderCatalog.latestSupportedFormatVersion)
          ]));
      final resolved = resolveSpatialBorderFeature(
          manifest: project,
          map: base.map,
          layerId: 'border',
          featureId: 'fence');
      final slot =
          resolved.result.materialization!.spatialPlacements.first.slotKey;
      final map = updateBorderFeatureOverrides(base.map,
          layerId: 'border',
          featureId: 'fence',
          overrides: [
            BorderSlotOverride(
                slotKey: slot,
                variationSalt: BorderSignedInt64.fromInt(0),
                suppressed: false,
                locked: correction == 'locked',
                lockedInstanceId:
                    correction == 'locked' ? 'locked-native-instance' : null,
                transformOverride: correction == 'transform'
                    ? BorderSpriteTransform(quarterTurns: 1, flipX: false)
                    : null,
                offsetDeltaPx: correction == 'offset'
                    ? const BorderPixelOffset(x: 1, y: 0)
                    : null)
          ]);
      final before = jsonEncode(map.toJson());
      expect(
          () => relinkSpatialBorderFeature(map,
              manifest: project,
              layerId: 'border',
              featureId: 'fence',
              targetBlueprintId: 'replacement',
              reverseStrokes: true),
          throwsA(isA<ValidationException>().having((error) => error.message,
              'message', contains('Locked or transformed'))));
      expect(jsonEncode(map.toJson()), before);
    });
  }

  for (final jsonl in [false, true]) {
    test(
        'inverted repeated native Border persists through ${jsonl ? 'JSONL' : 'direct API'} and rejects turns without writes',
        () async {
      final fixture = spatialBorderAuthoringFixture(
          published: true,
          straightOnly: true,
          includeCorner: false,
          repeatedUnit: true);
      final host = await ResourceInformationFixture.create(fixture.project
          .copyWith(
              maps: [],
              models3d: [],
              borderCatalog: const ProjectBorderCatalog.empty()));
      addTearDown(host.dispose);
      final mapFile = File('${host.root.path}/maps/map.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(fixture.map.toJson()));
      final model = fixture.project.models3d.single;
      final bytes = environmentModelGlb();
      final source = File('${host.root.path}/${model.relativePath}');
      await source.parent.create(recursive: true);
      await source.writeAsBytes(bytes);
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
      final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      await File('${host.root.path}/assets/.pokemap-assets.json')
          .writeAsString(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: model.sourceAssetId,
            logicalPath: model.relativePath,
            artifact: artifact)
      ]).toJson()));
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(fixture.project.toJson()));
      final parameters = <String, Object?>{
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence'
      };
      await host.mutate('border_layer.feature_update',
          {...parameters, 'lineSide': 'inverted'});
      final before = await mapFile.readAsBytes();
      final snapshot = await host.snapshots.load(ProjectHandle(host.project));
      final request = AuthoringRequest(
          requestId: 'inverse',
          actionId: 'border_layer.materialize_apply',
          actionVersion: 1,
          workspaceHandle: host.workspace,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'inverse');
      late String planId;
      if (jsonl) {
        final plan = await host.command('plan',
            {'projectHandle': host.project, 'request': request.toJson()});
        expect(plan.status, AuthoringResultStatus.success,
            reason: jsonEncode(plan.toJson()));
        expect(jsonEncode(plan.toJson()), contains('modelInstances'));
        planId = plan.data['planId'] as String;
      } else {
        final plan = await host.mutations
            .planMutation(ProjectHandle(host.project), request);
        expect(jsonEncode(plan.toJson()), contains('modelInstances'));
        planId = plan.planId;
      }
      expect(await mapFile.readAsBytes(), before);
      if (jsonl) {
        final result = await host.command('apply', {
          'projectHandle': host.project,
          'planId': planId,
          'operationId': 'inverse'
        });
        expect(result.status, AuthoringResultStatus.success,
            reason: jsonEncode(result.toJson()));
      } else {
        final receipt = await host.mutations.applyMutation(
            ProjectHandle(host.project),
            planId: planId,
            operationId: 'inverse');
        expect(receipt.receipt.status, AuthoringReceiptStatus.applied);
      }
      final saved = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(saved.spatialScene!.instances, hasLength(3));
      expect(
          saved.spatialScene!.instances.map((value) => value.rotationDegrees),
          everyElement(-90.0));
      expect(
          (saved.layers.single as BorderLayer).content.features.single.lineSide,
          BorderLineSide.inverted);
      final retained = await mapFile.readAsBytes();
      final badParameters = {
        ...parameters,
        'strokeId': 'line',
        'points': [
          {'x': 1, 'y': 1},
          {'x': 2, 'y': 1},
          {'x': 2, 'y': 2}
        ],
        'closed': false
      };
      if (jsonl) {
        final rejected =
            await host.plan('border_layer.stroke_update', badParameters);
        expect(rejected.status, AuthoringResultStatus.failure);
        expect(jsonEncode(rejected.toJson()),
            contains('border.spatial.straight_only_geometry_required'));
      } else {
        final current = await host.snapshots.load(ProjectHandle(host.project));
        await expectLater(
            host.mutations.planMutation(
                ProjectHandle(host.project),
                AuthoringRequest(
                    requestId: 'bad-turn',
                    actionId: 'border_layer.stroke_update',
                    actionVersion: 1,
                    workspaceHandle: host.workspace,
                    parameters: badParameters,
                    expectedRevision: current.revision,
                    idempotencyKey: 'bad-turn')),
            throwsA(isA<MapAuthoringException>()));
      }
      expect(await mapFile.readAsBytes(), retained);
      await host.command('close', {'projectHandle': host.project});
      final reopened =
          await host.command('open', {'projectRoot': host.root.path});
      expect(reopened.status, AuthoringResultStatus.success);
      final restored = await host.snapshots
          .load(ProjectHandle(reopened.data['projectHandle'] as String));
      expect(restored.maps.single, saved);
      expect(
          diagnoseSpatialBorderFeature(
                  manifest: restored.manifest,
                  map: restored.maps.single,
                  layerId: 'border',
                  featureId: 'fence')
              .hasErrors,
          isFalse);
      await host
          .command('close', {'projectHandle': restored.projectHandle.value});
    });
  }

  test(
      'canonical feature offsets preserve omitted values clear with null and reject invalid targets',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final snapshot = librarySnapshot([fixture.map], project: fixture.project);
    final mutation = await MapMutationDispatcher.canonical()
        .build(context(snapshot, 'border_layer.feature_update', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'spatialOffsetWorld': {'x': -.5, 'y': -1.25, 'z': -.5}
    }));
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(mutation.changeSet.changes.single.afterBytes!)));
    final feature = (map.layers.single as BorderLayer).content.features.single;
    expect(
        feature.spatialOffsetWorld, Model3dVector3(x: -.5, y: -1.25, z: -.5));
    final updatedSnapshot = librarySnapshot([map], project: fixture.project);
    for (final values in [
      <String, Object?>{'name': 'Rename'},
      <String, Object?>{'spatialOffsetWorld': null}
    ]) {
      final change = await MapMutationDispatcher.canonical().build(context(
          updatedSnapshot, 'border_layer.feature_update', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence',
        ...values
      }));
      final changed = MapData.fromJson(
          jsonDecode(utf8.decode(change.changeSet.changes.single.afterBytes!)));
      expect(
          (changed.layers.single as BorderLayer)
              .content
              .features
              .single
              .spatialOffsetWorld,
          values.containsKey('spatialOffsetWorld')
              ? isNull
              : feature.spatialOffsetWorld);
    }
    for (final value in [
      {'x': -1000, 'y': 0, 'z': 0},
      {'x': 1, 'y': 0, 'z': 0, 'hidden': 1},
      {'x': 0, 'y': 'zero', 'z': 0},
    ]) {
      await expectLater(
          Future<AuthoringMutationDraft>.sync(() =>
              MapMutationDispatcher.canonical()
                  .build(context(snapshot, 'border_layer.feature_update', {
                'mapId': 'map',
                'layerId': 'border',
                'featureId': 'fence',
                'spatialOffsetWorld': value
              }))),
          throwsA(isA<MapAuthoringException>()));
    }
    final twoD =
        fixture.map.copyWith(version: ProjectVersion.v8, spatialScene: null);
    await expectLater(
        Future<AuthoringMutationDraft>.sync(() =>
            MapMutationDispatcher.canonical().build(context(
                librarySnapshot([twoD], project: fixture.project),
                'border_layer.feature_update', {
              'mapId': 'map',
              'layerId': 'border',
              'featureId': 'fence',
              'spatialOffsetWorld': null
            }))),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'border.spatial.map_required')));
    expect(snapshot.maps.single, fixture.map);
  });

  test(
      'feature creation exposes and validates the initial line side canonically',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final snapshot = librarySnapshot([fixture.map], project: fixture.project);
    final parameters = <String, Object?>{
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'new',
      'blueprintId': 'fence',
      'name': 'New',
      'seed': '17',
      'geometry': {
        'kind': 'stroke',
        'strokes': [
          {
            'id': 'line',
            'closed': false,
            'points': [
              {'x': 1, 'y': 2},
              {'x': 2, 'y': 2},
              {'x': 3, 'y': 2}
            ]
          }
        ]
      },
    };
    final descriptor = BorderActions.descriptors
        .firstWhere((value) => value.id == 'border_layer.feature_create');
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(schema['required'], isNot(contains('lineSide')));
    expect((schema['properties'] as Map)['lineSide'], {
      'type': 'string',
      'enum': ['primary', 'inverted'],
      'default': 'primary'
    });
    for (final side in [null, 'primary', 'inverted']) {
      final mutation = await MapMutationDispatcher.canonical().build(context(
          snapshot,
          'border_layer.feature_create',
          {...parameters, if (side != null) 'lineSide': side}));
      final map = MapData.fromJson(jsonDecode(
          utf8.decode(mutation.changeSet.changes.single.afterBytes!)));
      final feature =
          (map.layers.single as BorderLayer).content.featureById('new')!;
      expect(
          feature.lineSide,
          side == 'inverted'
              ? BorderLineSide.inverted
              : BorderLineSide.primary);
    }
    await expectLater(
        Future<AuthoringMutationDraft>.sync(() =>
            MapMutationDispatcher.canonical().build(context(
                snapshot,
                'border_layer.feature_create',
                {...parameters, 'lineSide': 'sideways'}))),
        throwsA(isA<MapAuthoringException>()));
    expect(snapshot.maps.single, fixture.map);
  });

  test('inverted native border query and plan preserve prior materialization',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final host = await ResourceInformationFixture.create(fixture.project
        .copyWith(
            maps: [],
            models3d: [],
            borderCatalog: const ProjectBorderCatalog.empty()));
    addTearDown(host.dispose);
    final mapFile = File('${host.root.path}/maps/map.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(fixture.map.toJson()));
    final model = fixture.project.models3d.single;
    final source = File('${host.root.path}/${model.relativePath}');
    await source.parent.create(recursive: true);
    final bytes = environmentModelGlb();
    await source.writeAsBytes(bytes);
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    await File('${host.root.path}/assets/.pokemap-assets.json')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact)
    ]).toJson()));
    await File('${host.root.path}/project.json')
        .writeAsString(jsonEncode(fixture.project.toJson()));
    await host.mutate('border_layer.stroke_update', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'strokeId': 'line',
      'points': [
        {'x': 1, 'y': 1},
        {'x': 2, 'y': 1},
        {'x': 3, 'y': 1},
        {'x': 3, 'y': 2},
        {'x': 3, 'y': 3}
      ],
      'closed': false
    });
    final parameters = <String, Object?>{
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence'
    };
    await host.mutate('border_layer.materialize_apply', parameters);
    final primary = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(primary.spatialScene!.instances, hasLength(5));
    await host.mutate(
        'border_layer.feature_update', {...parameters, 'lineSide': 'inverted'});
    final before = await mapFile.readAsBytes();
    final snapshot = await host.snapshots.load(ProjectHandle(host.project));
    final diagnostics = const BorderActions().diagnostics(
        manifest: snapshot.manifest,
        map: snapshot.maps.single,
        layerId: 'border',
        featureId: 'fence',
        projectRevision: snapshot.revision,
        tileSizePx: const GridSize(width: 16, height: 16),
        resolverVersion: borderResolverVersion);
    expect(diagnostics.hasErrors, isTrue);
    expect(diagnostics.diagnostics.single.code,
        'border.spatial.line_side_inversion_unsupported');
    expect(diagnostics.diagnostics.single.suggestedAction,
        'border.action.use_primary_line_side');
    final planned =
        await host.plan('border_layer.materialize_apply', parameters);
    expect(planned.status, AuthoringResultStatus.failure);
    expect(
        planned.error!.details['domainCode'], 'border.materialization_failed');
    expect(planned.error!.details['diagnostics'], [
      {
        'code': 'border.spatial.line_side_inversion_unsupported',
        'severity': 'error',
        'blueprintId': 'fence',
        'featureId': 'fence',
        'suggestedAction': 'border.action.use_primary_line_side'
      }
    ]);
    expect(await mapFile.readAsBytes(), before);
    final queried = await host.command('query', {
      'projectHandle': host.project,
      'request': AuthoringQueryRequest(
              resourceKind: 'map',
              operation: AuthoringQueryOperation.get,
              ids: ['map'],
              view: AuthoringQueryView.detail)
          .toJson()
    });
    expect(queried.status, AuthoringResultStatus.success);
    final data =
        Map<String, dynamic>.from((queried.data['items'] as List).single);
    data.remove('resourceKind');
    final stored = MapData.fromJson(data);
    expect(stored.spatialScene, primary.spatialScene);
    expect(
        (stored.layers.single as BorderLayer).content.features.single.lineSide,
        BorderLineSide.inverted);
    expect(await mapFile.readAsBytes(), before);
  });

  test(
      'straight-only canonical draft publication and JSONL materialization reject turns atomically',
      () async {
    final fixture =
        spatialBorderAuthoringFixture(straightOnly: true, includeCorner: false);
    final snapshot = librarySnapshot([fixture.map],
        project: fixture.project
            .copyWith(borderCatalog: const ProjectBorderCatalog.empty()));
    final record = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5);
    final draftMutation = await MapMutationDispatcher.canonical().build(
        context(snapshot, 'border.blueprint.draft.upsert', {'record': record}));
    final drafted = ProjectManifest.fromJson(jsonDecode(
        utf8.decode(draftMutation.changeSet.changes.single.afterBytes!)));
    expect(drafted.borderCatalog.records.single.draft.definition.straightOnly,
        isTrue);
    final publication = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([fixture.map], project: drafted),
        'border.blueprint.publish',
        {'blueprintId': 'fence'}));
    final published = ProjectManifest.fromJson(jsonDecode(
        utf8.decode(publication.changeSet.changes.single.afterBytes!)));
    expect(
        published.borderCatalog.records.single.latestPublished!.definition
            .straightOnly,
        isTrue);
    expect(
        published.borderCatalog.records.single.latestPublished!.definition
            .primitives,
        hasLength(2));
    final host = await ResourceInformationFixture.create(fixture.project
        .copyWith(
            maps: [],
            models3d: [],
            borderCatalog: const ProjectBorderCatalog.empty()));
    addTearDown(host.dispose);
    final mapFile = File('${host.root.path}/maps/map.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(fixture.map.copyWith(
        layers: [MapLayer.border(id: 'border', name: 'Fence')]).toJson()));
    final model = fixture.project.models3d.single;
    final source = File('${host.root.path}/${model.relativePath}');
    await source.parent.create(recursive: true);
    final modelBytes = environmentModelGlb();
    await source.writeAsBytes(modelBytes);
    final artifact = ContentArtifactRef.fromBytes(modelBytes,
        mediaType: 'model/gltf-binary');
    final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(modelBytes);
    await File('${host.root.path}/assets/.pokemap-assets.json')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact)
    ]).toJson()));
    await File('${host.root.path}/project.json').writeAsString(jsonEncode(
        fixture.project
            .copyWith(borderCatalog: const ProjectBorderCatalog.empty())
            .toJson()));
    await host.mutate('border.blueprint.draft.upsert', {'record': record});
    await host.mutate('border.blueprint.publish', {'blueprintId': 'fence'});
    await host.mutate('border_layer.feature_create', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'blueprintId': 'fence',
      'name': 'Fence',
      'seed': '17',
      'lineSide': 'primary',
      'spatialOffsetWorld': {'x': .25, 'y': -.5, 'z': -.25},
      'geometry': {
        'kind': 'stroke',
        'strokes': [
          {
            'id': 'line',
            'closed': false,
            'points': [
              {'x': 1, 'y': 1},
              {'x': 2, 'y': 1},
              {'x': 3, 'y': 1}
            ]
          }
        ]
      },
    });
    await host.mutate('border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
    final applied = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(
        (applied.layers.single as BorderLayer).content.features.single.lineSide,
        BorderLineSide.primary);
    expect(applied.spatialScene!.instances, hasLength(3));
    expect(
        (applied.layers.single as BorderLayer)
            .content
            .features
            .single
            .spatialOffsetWorld,
        Model3dVector3(x: .25, y: -.5, z: -.25));
    final offsetPlan = await host.plan('border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
    final ownedIds = (applied.layers.single as BorderLayer)
        .content
        .features
        .single
        .generatedPlacementIds;
    await host.mutate('border_layer.feature_update', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'spatialOffsetWorld': {'x': .5, 'y': -1, 'z': -.5}
    });
    expect(
        (await host.apply(offsetPlan)).status, AuthoringResultStatus.failure);
    final intent = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(intent.spatialScene, applied.spatialScene);
    await host.mutate('border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
    final regenerated =
        MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(
        (regenerated.layers.single as BorderLayer)
            .content
            .features
            .single
            .generatedPlacementIds,
        ownedIds);
    for (var i = 0; i < applied.spatialScene!.instances.length; i++) {
      final originalPosition = applied.spatialScene!.instances[i].position;
      final updatedPosition = regenerated.spatialScene!.instances[i].position;
      expect(updatedPosition.x, closeTo(originalPosition.x + .25, 1e-10));
      expect(updatedPosition.y, closeTo(originalPosition.y - .5, 1e-10));
      expect(updatedPosition.z, closeTo(originalPosition.z - .25, 1e-10));
    }
    final before = await mapFile.readAsBytes();
    final failed = await host.plan('border_layer.stroke_add', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'strokeId': 'turn',
      'points': [
        {'x': 1, 'y': 2},
        {'x': 2, 'y': 2},
        {'x': 2, 'y': 3}
      ],
    });
    expect(failed.status, AuthoringResultStatus.failure);
    expect(jsonEncode(failed.toJson()),
        contains('border.spatial.straight_only_geometry_required'));
    expect(await mapFile.readAsBytes(), before);
    final createTurn = await host.plan('border_layer.feature_create', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'turn',
      'blueprintId': 'fence',
      'name': 'Turn',
      'seed': '17',
      'geometry': {
        'kind': 'stroke',
        'strokes': [
          {
            'id': 'turn',
            'closed': false,
            'points': [
              {'x': 1, 'y': 2},
              {'x': 2, 'y': 2},
              {'x': 2, 'y': 3}
            ]
          }
        ]
      },
    });
    expect(createTurn.status, AuthoringResultStatus.failure);
    expect(jsonEncode(createTurn.toJson()),
        contains('border.spatial.straight_only_geometry_required'));
    expect(await mapFile.readAsBytes(), before);
    await host.command('close', {'projectHandle': host.project});
    final reopened =
        await host.command('open', {'projectRoot': host.root.path});
    final saved = await host.snapshots
        .load(ProjectHandle(reopened.data['projectHandle'] as String));
    expect(
        saved.manifest.borderCatalog.records.single.latestPublished!.definition
            .straightOnly,
        isTrue);
    expect(saved.maps.single.spatialScene!.instances,
        regenerated.spatialScene!.instances);
    final reopenedHost = await host.command('plan', {
      'projectHandle': saved.projectHandle.value,
      'request': AuthoringRequest(
              requestId: 'clear-offset',
              actionId: 'border_layer.feature_update',
              actionVersion: 1,
              workspaceHandle: reopened.data['workspaceHandle'] as String,
              expectedRevision: saved.revision,
              parameters: {
                'mapId': 'map',
                'layerId': 'border',
                'featureId': 'fence',
                'spatialOffsetWorld': null
              },
              idempotencyKey: 'clear-offset')
          .toJson()
    });
    expect(reopenedHost.status, AuthoringResultStatus.success,
        reason: jsonEncode(reopenedHost.toJson()));
    final cleared = await host.command('apply', {
      'projectHandle': saved.projectHandle.value,
      'planId': reopenedHost.data['planId'],
      'operationId': 'clear-offset'
    });
    expect(cleared.status, AuthoringResultStatus.success);
    final clearedMap =
        MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(
        (clearedMap.layers.single as BorderLayer)
            .content
            .features
            .single
            .spatialOffsetWorld,
        isNull);
    expect(clearedMap.spatialScene, regenerated.spatialScene);
  });

  test(
      'canonical feature update preserves native ownership until explicit regeneration',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final preview = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence');
    final generated = applySpatialBorderFeaturePreview(fixture.map,
        manifest: fixture.project, proposedResult: preview);
    final snapshot = librarySnapshot([generated], project: fixture.project);
    final mutation = await MapMutationDispatcher.canonical().build(context(
        snapshot, 'border_layer.feature_update', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'name': 'Updated'
    }));
    final updated = MapData.fromJson(
        jsonDecode(utf8.decode(mutation.changeSet.changes.single.afterBytes!)));
    final previous =
        (generated.layers.single as BorderLayer).content.features.single;
    final feature =
        (updated.layers.single as BorderLayer).content.features.single;
    expect(feature.generatedPlacementIds, previous.generatedPlacementIds);
    expect(feature.name, 'Updated');
    expect(updated.spatialScene!.instances, generated.spatialScene!.instances);
    final result = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: updated,
        layerId: 'border',
        featureId: 'fence');
    expect(result.result.canApply, isTrue);
    expect(
        applySpatialBorderFeaturePreview(updated,
                manifest: fixture.project, proposedResult: result)
            .spatialScene,
        generated.spatialScene);
  });
  test(
      'canonical native publication stores live typed references without artifacts',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final snapshot = librarySnapshot([fixture.map], project: fixture.project);
    final mutation = await MapMutationDispatcher.canonical().build(context(
        snapshot, 'border.blueprint.publish', {'blueprintId': 'fence'}));
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(mutation.changeSet.changes.single.afterBytes!)));
    expect(mutation.changeSet.changes.single.storageKey, 'project.json');
    expect(project.borderCatalog.visualSnapshots, isEmpty);
    final published = project.borderCatalog.records.single.latestPublished!;
    expect(published.definition.isSpatial, isTrue);
    expect(
        published.definition.primitives
            .map((primitive) => primitive.sourceModelId),
        ['tree', 'tree', 'tree']);
    expect(
        encodeBorderBlueprintRecordJson(project.borderCatalog.records.single,
                formatVersion: 5)
            .toString(),
        isNot(contains('visualSnapshotId')));
  });

  test(
      'native border definitions guard model deletion and transitive map-local scope',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final project = fixture.project.copyWith(maps: [
      ...fixture.project.maps,
      const ProjectMapEntry(
          id: 'other', name: 'Other', relativePath: 'maps/other.json')
    ]);
    final other = fixture.map.copyWith(id: 'other', layers: const []);
    final snapshot = librarySnapshot([fixture.map, other], project: project);
    await expectLater(
        Future<AuthoringMutationDraft>.sync(() =>
            MapMutationDispatcher.canonical()
                .build(context(snapshot, 'resource.classify', {
              'resourceKind': 'model3d',
              'resourceId': 'tree',
              'familyId': null,
              'mapId': 'other',
            }))),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
    final noModel =
        librarySnapshot([fixture.map], project: project.copyWith(models3d: []));
    await expectLater(
        Future<AuthoringMutationDraft>.sync(() =>
            MapMutationDispatcher.canonical().build(context(noModel,
                'border.blueprint.publish', {'blueprintId': 'fence'}))),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'border.blueprint.publication_invalid')));
  });

  test(
      'native JSONL publish preview apply stale save reopen undo and export preserve unit models',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final host = await ResourceInformationFixture.create(fixture.project
        .copyWith(
            maps: [],
            models3d: [],
            borderCatalog: const ProjectBorderCatalog.empty()));
    addTearDown(host.dispose);
    final mapFile = File('${host.root.path}/maps/map.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(fixture.map.copyWith(
        layers: [MapLayer.border(id: 'border', name: 'Fence')]).toJson()));
    final model = fixture.project.models3d.single;
    final bytes = environmentModelGlb();
    final modelArtifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final source = File('${host.root.path}/${model.relativePath}');
    await source.parent.create(recursive: true);
    await source.writeAsBytes(bytes);
    final blob =
        File('${host.root.path}/${assetBlobStorageKey(modelArtifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    final heroBytes = img.encodePng(img.Image(width: 1, height: 1));
    final heroArtifact =
        ContentArtifactRef.fromBytes(heroBytes, mediaType: 'image/png');
    await File('${host.root.path}/assets/hero.png').writeAsBytes(heroBytes);
    await File('${host.root.path}/${assetBlobStorageKey(heroArtifact)}')
        .writeAsBytes(heroBytes);
    await File('${host.root.path}/assets/.pokemap-assets.json')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: modelArtifact),
      AssetRecord(
          id: 'hero-sprite',
          logicalPath: 'assets/hero.png',
          artifact: heroArtifact),
    ]).toJson()));
    final project = fixture.project.copyWith(
        settings: fixture.project.settings.copyWith(
            defaultPlayerCharacterId: 'hero', tileWidth: 1, tileHeight: 1),
        tilesets: [
          const ProjectTilesetEntry(
              id: 'hero-sheet',
              name: 'Hero',
              relativePath: 'assets/hero.png',
              source: ProjectRegularAtlasTilesetSource(
                  assetId: 'hero-sprite',
                  pixelWidth: 1,
                  pixelHeight: 1,
                  tileWidth: 1,
                  tileHeight: 1))
        ],
        characters: [
          ProjectCharacterEntry(
              id: 'hero',
              name: 'Hero',
              tilesetId: 'hero-sheet',
              frameHeight: 1,
              animations: [
                for (final direction in [
                  EntityFacing.north,
                  EntityFacing.south,
                  EntityFacing.east,
                  EntityFacing.west
                ])
                  CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: direction,
                      sourceAssetId: 'hero-sprite',
                      frames: [
                        const CharacterAnimationFrame(
                            source: TilesetSourceRect(x: 0, y: 0))
                      ]),
              ])
        ]);
    await File('${host.root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await host.mutate('border.blueprint.publish', {'blueprintId': 'fence'});
    await host.mutate('border_layer.feature_create', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'blueprintId': 'fence',
      'name': 'Fence',
      'seed': '17',
      'geometry': {
        'kind': 'stroke',
        'strokes': [
          {
            'id': 'line',
            'closed': false,
            'points': [
              {'x': 1, 'y': 1},
              {'x': 2, 'y': 1},
              {'x': 3, 'y': 1},
              {'x': 3, 'y': 2}
            ]
          }
        ]
      }
    });
    final firstPlan = await host.plan('border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
    expect(firstPlan.status, AuthoringResultStatus.success,
        reason: jsonEncode(firstPlan.toJson()));
    expect(firstPlan.toJson().toString(), contains('modelInstances'));
    await host.mutate(
        'model3d.configure', {'modelId': 'tree', 'name': 'Unit fence renamed'});
    final stale = await host.apply(firstPlan);
    expect(stale.status, AuthoringResultStatus.failure);
    final before = await mapFile.readAsBytes();
    await host.mutate('border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
    final saved = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(saved.spatialScene!.instances, hasLength(4));
    expect(saved.placedElements, isEmpty);
    expect(
        (saved.layers.single as BorderLayer)
            .content
            .features
            .single
            .generatedPlacementIds,
        saved.spatialScene!.instances.map((instance) => instance.id));
    final deletion = await host.plan('model3d.delete', {'modelId': 'tree'});
    expect(deletion.status, AuthoringResultStatus.failure);
    final profile = GamePackageExportProfile(
        gameId: 'games.example.border',
        gameVersion: '0.1.0',
        title: 'Fence',
        authorName: 'Yoahn',
        defaultLocale: 'fr',
        supportedLocales: ['fr']);
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: host.root, profile: profile);
    final exported = MapData.fromJson(jsonDecode(
        utf8.decode(projection.payloadFiles['project/maps/map.json']!)));
    expect(exported.spatialScene, saved.spatialScene);
    expect(projection.payloadFiles['project/${model.relativePath}'], bytes);
    await host.command('close', {'projectHandle': host.project});
    final opened = await host.command('open', {'projectRoot': host.root.path});
    expect(opened.status, AuthoringResultStatus.success);
    final handle = ProjectHandle(opened.data['projectHandle'] as String);
    final snapshot = await host.snapshots.load(handle);
    expect(snapshot.maps.single, saved);
    final history = await host.mutations.history(handle, limit: 1);
    await host.mutations.undo(handle,
        entryId: (history['entries'] as List).first['entryId'] as String,
        idempotencyKey: 'undo-border');
    expect(await mapFile.readAsBytes(), before);
    await host.command('close', {'projectHandle': handle.value});
  });
}

AuthoringPlanningContext context(ProjectSnapshot snapshot, String actionId,
        Map<String, Object?> parameters) =>
    AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
            requestId: 'border-test',
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: 'workspace:test',
            parameters: parameters,
            expectedRevision: snapshot.revision,
            idempotencyKey: actionId),
        planId: 'border-test-plan',
        seed: 17);

({ProjectManifest project, MapData map}) spatialBorderAuthoringFixture(
    {bool published = false,
    bool straightOnly = false,
    bool includeCorner = true,
    bool repeatedUnit = false}) {
  final base = spatialEnvironmentFixture();
  final defaults = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 1000,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1);
  final roles = [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    if (repeatedUnit) BorderPrimitiveRole.lineCap,
    if (includeCorner) BorderPrimitiveRole.lineCorner
  ];
  final transforms = BorderTransformPolicy(
      allowFlipX: false, allowedQuarterTurns: const [0, 1, 2, 3]);
  final draft = BorderBlueprintDraftDefinition(
      name: 'Fence',
      previewSeed: BorderSignedInt64.fromInt(17),
      template: BorderBlueprintTemplate.connectedLine,
      straightOnly: straightOnly,
      primitives: [
        for (final (index, role) in roles.indexed)
          BorderPrimitiveDraft(
              id: repeatedUnit ? '${role.name}-$index' : role.name,
              sourceModelId: 'tree',
              role: role,
              weight: 1,
              authoredOrientation: repeatedUnit
                  ? index == 2
                      ? BorderPrimitiveOrientation.north
                      : BorderPrimitiveOrientation.south
                  : BorderPrimitiveOrientation.legacyAxis,
              anchorWorld:
                  repeatedUnit ? Model3dVector3(x: 0, y: .25, z: 0) : null,
              transforms: repeatedUnit && role == BorderPrimitiveRole.lineCap
                  ? BorderTransformPolicy(
                      allowFlipX: false, allowedQuarterTurns: [1, 2])
                  : transforms)
      ],
      defaults: defaults,
      sortOrder: 0);
  final record = BorderBlueprintRecord(
      id: 'fence',
      draft: BorderBlueprintDraft(
          baseRevision: published ? 1 : 0, definition: draft),
      latestPublished: published
          ? BorderBlueprintRevision(
              revision: 1,
              definition: BorderBlueprintPublishedDefinition(
                  name: draft.name,
                  previewSeed: draft.previewSeed,
                  template: draft.template,
                  straightOnly: draft.straightOnly,
                  primitives: [
                    for (final primitive in draft.primitives)
                      BorderPublishedPrimitive(
                          id: primitive.id,
                          sourceModelId: primitive.sourceModelId,
                          role: primitive.role,
                          weight: primitive.weight,
                          authoredOrientation: primitive.authoredOrientation,
                          anchorWorld: primitive.anchorWorld,
                          transforms: primitive.transforms)
                  ],
                  defaults: defaults,
                  sortOrder: 0))
          : null);
  final feature = BorderFeature(
      id: 'fence',
      name: 'Fence',
      blueprintId: 'fence',
      seed: BorderSignedInt64.fromInt(17),
      geometry: BorderStrokeGeometry(strokes: [
        BorderStroke(
            id: 'line',
            points: const [
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
              GridPos(x: 3, y: 1)
            ],
            closed: false)
      ]),
      overrides: const [],
      keepOutRegions: const []);
  return (
    project: base.project.copyWith(
        environmentPresets: [],
        borderCatalog:
            ProjectBorderCatalog(formatVersion: 5, records: [record])),
    map: base.map.copyWith(layers: [
      MapLayer.border(
          id: 'border',
          name: 'Fence',
          content: BorderLayerContent(features: [feature]))
    ])
  );
}
