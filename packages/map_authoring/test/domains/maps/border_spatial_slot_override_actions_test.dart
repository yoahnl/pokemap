import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show context, spatialBorderAuthoringFixture;
import 'environment_spatial_actions_test.dart' show environmentModelGlb;

const ids = {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'};

BorderFeature feature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

SpatialModelInstance middle(MapData map) => map.spatialScene!.instances
    .singleWhere((value) => value.position.x == 2.5 && value.position.z == 1.5);

String middleSlot(MapData map) => feature(map)
    .materialization!
    .spatialPlacements
    .singleWhere((value) => value.instanceId == middle(map).id)
    .slotKey;

({ProjectManifest project, MapData map}) fixture() {
  final base = spatialBorderAuthoringFixture(published: true);
  final data =
      jsonDecode(jsonEncode(base.project.toJson())) as Map<String, dynamic>;
  final model = (data['models3d'] as List).single as Map;
  (data['models3d'] as List).add({
    ...model,
    'id': 'alternate-model',
    'sourceAssetId': 'alternate-asset',
    'relativePath': 'assets/models3d/alternate-model.glb'
  });
  final record = (data['borderCatalog']['records'] as List).single as Map;
  for (final definition in [
    record['draft']['definition'],
    record['latestPublished']['definition']
  ]) {
    definition['defaults']['variationPermille'] = 0;
    final straight = (definition['primitives'] as List)
        .singleWhere((value) => value['id'] == 'lineStraight') as Map;
    (definition['primitives'] as List).add(
        {...straight, 'id': 'z-alternate', 'sourceModelId': 'alternate-model'});
  }
  final project = ProjectManifest.fromJson(jsonDecode(jsonEncode(data)));
  var map = base.map.copyWith(
      spatialScene: base.map.spatialScene!.copyWith(instances: [
    SpatialModelInstance(
        id: 'foreign',
        modelId: 'tree',
        position: Model3dVector3(x: .5, y: 0, z: .5))
  ]));
  map = applySpatialBorderFeaturePreview(map,
      manifest: project,
      proposedResult: resolveSpatialBorderFeature(
          manifest: project, map: map, layerId: 'border', featureId: 'fence'));
  expect(middle(map).modelId, 'tree');
  return (project: project, map: map);
}

Future<MapData> build(({ProjectManifest project, MapData map}) fixture,
    MapData map, String suffix, Map<String, Object?> parameters) async {
  final draft = await MapMutationDispatcher.canonical().build(context(
      librarySnapshot([map], project: fixture.project),
      'border_layer.feature_$suffix',
      {...ids, ...parameters}));
  return MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
}

Future<MapData> materialize(
    ({ProjectManifest project, MapData map}) fixture, MapData map) async {
  final draft = await MapMutationDispatcher.canonical().build(context(
      librarySnapshot([map], project: fixture.project),
      'border_layer.materialize_apply',
      ids));
  return MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
}

void main() {
  test(
      'spatial replacement preserves neighbors until materialization and clears exactly',
      () async {
    final f = fixture();
    final slot = middleSlot(f.map);
    var map = await build(f, f.map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': 'z-alternate'});
    expect(map.spatialScene, f.map.spatialScene);
    expect(feature(map).overrides.single.replacementPrimitiveId, 'z-alternate');
    map = await materialize(f, map);
    expect(middle(map).modelId, 'alternate-model');
    expect(middle(map).id, middle(f.map).id);
    expect(
        map.spatialScene!.instances
            .where((value) => value.id != middle(map).id),
        f.map.spatialScene!.instances
            .where((value) => value.id != middle(f.map).id));
    expect(map.spatialScene!.heightLevels, f.map.spatialScene!.heightLevels);
    expect(map.spatialScene!.navigation, f.map.spatialScene!.navigation);
    map = await build(f, map, 'clear_slot_override', {'slotKey': slot});
    expect(feature(map).overrides, isEmpty);
    map = await materialize(f, map);
    expect(map.spatialScene!.instances, f.map.spatialScene!.instances);
  });

  test('spatial suppression removes only the selected instance and restores it',
      () async {
    final f = fixture();
    final slot = middleSlot(f.map);
    var map = await build(f, f.map, 'set_replacement',
        {'slotKey': slot, 'primitiveId': 'z-alternate'});
    map = await build(
        f, map, 'set_suppressed', {'slotKey': slot, 'suppressed': true});
    expect(feature(map).overrides.single.suppressed, true);
    expect(feature(map).overrides.single.replacementPrimitiveId, isNull);
    map = await materialize(f, map);
    expect(map.spatialScene!.instances,
        f.map.spatialScene!.instances.where((i) => i.id != middle(f.map).id));
    map = await build(
        f, map, 'set_suppressed', {'slotKey': slot, 'suppressed': false});
    map = await materialize(f, map);
    expect(map.spatialScene!.instances, f.map.spatialScene!.instances);
  });

  test(
      'spatial quarter turns preserve position and clear to the authored transform',
      () async {
    final f = fixture();
    final slot = middleSlot(f.map);
    var map = await build(f, f.map, 'set_transform', {
      'slotKey': slot,
      'transformOverride': {'quarterTurns': 1, 'flipX': false}
    });
    map = await materialize(f, map);
    expect(middle(map).rotationDegrees, -90);
    expect(middle(map).position, middle(f.map).position);
    map = await build(
        f, map, 'set_transform', {'slotKey': slot, 'transformOverride': null});
    map = await materialize(f, map);
    expect(map.spatialScene!.instances, f.map.spatialScene!.instances);
  });

  test(
      'spatial corrections reject missing slots, invalid variants, mirrors and pixel offsets',
      () async {
    final f = fixture();
    final slot = middleSlot(f.map);
    for (final (suffix, parameters, code)
        in <(String, Map<String, Object?>, String)>[
      (
        'set_replacement',
        {'slotKey': 'unknown', 'primitiveId': 'z-alternate'},
        'border.slot_missing'
      ),
      (
        'set_replacement',
        {'slotKey': slot, 'primitiveId': 'unknown'},
        'border.spatial.orientation_missing'
      ),
      (
        'set_replacement',
        {'slotKey': slot, 'primitiveId': 'lineCap'},
        'border.spatial.orientation_missing'
      ),
      (
        'set_transform',
        {
          'slotKey': slot,
          'transformOverride': {'quarterTurns': 0, 'flipX': true}
        },
        'border.spatial.sprite_override_unsupported'
      ),
      (
        'set_offset',
        {'slotKey': slot, 'offsetDeltaPx': null},
        'border.spatial.sprite_override_unsupported'
      ),
    ]) {
      await expectLater(
          build(f, f.map, suffix, parameters),
          throwsA(isA<MapAuthoringException>()
              .having((e) => e.code, 'code', code)));
    }
    expect(feature(f.map).overrides, isEmpty);
  });

  test('spatial corrections respect locks and suppression', () async {
    final f = fixture();
    final slot = middleSlot(f.map);
    final locked = await build(f, f.map, 'lock', {'slotKey': slot});
    await expectLater(
        build(f, locked, 'set_replacement',
            {'slotKey': slot, 'primitiveId': 'z-alternate'}),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.slot_locked')));
    final hidden = await build(
        f, f.map, 'set_suppressed', {'slotKey': slot, 'suppressed': true});
    await expectLater(
        build(f, hidden, 'set_replacement',
            {'slotKey': slot, 'primitiveId': 'z-alternate'}),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.slot_suppressed')));
  });

  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} persists spatial variants without changing other content',
        () async {
      final f = fixture();
      final host = await ResourceInformationFixture.create(f.project.copyWith(
          maps: [],
          models3d: [],
          borderCatalog: const ProjectBorderCatalog.empty()));
      addTearDown(host.dispose);
      final mapFile = File('${host.root.path}/maps/map.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(f.map.toJson()));
      final bytes = environmentModelGlb();
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
      final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      for (final model in f.project.models3d) {
        final file = File('${host.root.path}/${model.relativePath}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
      await File('${host.root.path}/assets/.pokemap-assets.json')
          .writeAsString(jsonEncode(AssetCatalog(records: [
        for (final model in f.project.models3d)
          AssetRecord(
              id: model.sourceAssetId,
              logicalPath: model.relativePath,
              artifact: artifact)
      ]).toJson()));
      final projectFile = File('${host.root.path}/project.json');
      await projectFile.writeAsString(jsonEncode(f.project.toJson()));
      final manifestBytes = await projectFile.readAsBytes();
      final slot = middleSlot(f.map);
      final actions = <(String, Map<String, Object?>)>[
        (
          'feature_set_replacement',
          {'slotKey': slot, 'primitiveId': 'z-alternate'}
        ),
        ('materialize_apply', {}),
        ('feature_set_suppressed', {'slotKey': slot, 'suppressed': true}),
        ('materialize_apply', {}),
        ('feature_clear_slot_override', {'slotKey': slot}),
        ('materialize_apply', {}),
      ];
      for (final (index, (action, parameters)) in actions.indexed) {
        final before = await mapFile.readAsBytes();
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final id = 'spatial-slot-$index';
        final request = AuthoringRequest(
            requestId: id,
            actionId: 'border_layer.$action',
            actionVersion: 1,
            workspaceHandle: host.workspace,
            parameters: {...ids, ...parameters},
            expectedRevision: snapshot.revision,
            idempotencyKey: id);
        final planId = jsonl
            ? (await host.command('plan', {
                'projectHandle': host.project,
                'request': request.toJson()
              }))
                .data['planId'] as String
            : (await host.mutations
                    .planMutation(ProjectHandle(host.project), request))
                .planId;
        expect(await mapFile.readAsBytes(), before);
        if (jsonl) {
          final result = await host.command('apply', {
            'projectHandle': host.project,
            'planId': planId,
            'operationId': id
          });
          expect(result.status, AuthoringResultStatus.success,
              reason: jsonEncode(result.toJson()));
        } else {
          final result = await host.mutations.applyMutation(
              ProjectHandle(host.project),
              planId: planId,
              operationId: id);
          expect(result.receipt.status, AuthoringReceiptStatus.applied);
        }
        expect(await projectFile.readAsBytes(), manifestBytes);
        final current =
            MapData.fromJson(jsonDecode(await mapFile.readAsString()));
        if (index == 1) {
          expect(middle(current).modelId, 'alternate-model');
        }
        if (index == 3) {
          expect(
              current.spatialScene!.instances
                  .any((i) => i.id == middle(f.map).id),
              false);
        }
        if (index == 5) {
          expect(current.toJson(), f.map.toJson());
        }
      }
    });
  }
}
