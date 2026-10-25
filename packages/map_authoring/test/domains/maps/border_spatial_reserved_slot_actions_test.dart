import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import '../assets/resource_information_fixture.dart';
import 'environment_spatial_actions_test.dart' show environmentModelGlb;
import 'border_spatial_actions_test.dart'
    show context, spatialBorderAuthoringFixture;

const target = {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'};

({ProjectManifest project, MapData map, Map<String, String> slots}) fixture() {
  final base = spatialBorderAuthoringFixture(published: true);
  final raw = encodeBorderBlueprintRecordJson(
      base.project.borderCatalog.records.single,
      formatVersion: 13);
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    (definition['defaults'] as Map)['variationPermille'] = 0;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['authoredOrientation'] = 'east';
    }
    final corner = Map<String, Object?>.from(primitives
        .singleWhere((value) => value['role'] == 'lineCorner') as Map);
    primitives.removeWhere((value) => value['role'] == 'lineCorner');
    primitives.addAll([
      {...corner, 'id': 'corner-right', 'cornerTurn': 'right'},
      {
        ...corner,
        'id': 'corner-left',
        'cornerTurn': 'left',
        'cornerJoinCells': 1
      },
    ]);
  }
  ProjectManifest projectFor(Map<String, Object?> record) =>
      base.project.copyWith(
          borderCatalog: ProjectBorderCatalog(formatVersion: 13, records: [
        decodeBorderBlueprintRecordJson(record, formatVersion: 13)
      ]));
  final project = projectFor(raw);
  var map = updateBorderFeatureGeometry(base.map,
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderStrokeGeometry(strokes: [
        BorderStroke(
            id: 'main',
            points: const [
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
              GridPos(x: 3, y: 1),
              GridPos(x: 3, y: 2),
              GridPos(x: 3, y: 3),
              GridPos(x: 4, y: 3),
              GridPos(x: 5, y: 3)
            ],
            closed: false)
      ]));
  final noReservations = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  for (final key in ['draft', 'latestPublished']) {
    for (final primitive in ((noReservations[key] as Map)['definition']
        as Map)['primitives'] as List) {
      (primitive as Map).remove('cornerJoinCells');
    }
  }
  final logical = resolveSpatialBorderFeature(
      manifest: projectFor(noReservations),
      map: map,
      layerId: 'border',
      featureId: 'fence');
  expect(logical.result.canApply, true);
  final byId = {
    for (final instance in logical.modelInstances) instance.id: instance
  };
  final slots = {
    for (final placement in logical.result.materialization!.spatialPlacements)
      '${byId[placement.instanceId]!.position.x.floor()},${byId[placement.instanceId]!.position.z.floor()}':
          placement.slotKey
  };
  final resolved = resolveSpatialBorderFeature(
      manifest: project, map: map, layerId: 'border', featureId: 'fence');
  expect(resolved.result.canApply, true);
  map = applySpatialBorderFeaturePreview(map,
      manifest: project, proposedResult: resolved);
  expect(map.spatialScene!.instances.length, 5);
  return (project: project, map: map, slots: slots);
}

Future<MapData> mutate(ProjectManifest project, MapData map, String suffix,
    Map<String, Object?> parameters) async {
  final result = await MapMutationDispatcher.canonical().build(context(
      librarySnapshot([map], project: project),
      'border_layer.$suffix',
      {...target, ...parameters}));
  return MapData.fromJson(
      jsonDecode(utf8.decode(result.changeSet.changes.single.afterBytes!)));
}

BorderFeature currentFeature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

void main() {
  test('suppresses logical neighbors released by a suppressed wide corner',
      () async {
    final f = fixture();
    var map = await mutate(f.project, f.map, 'feature_set_suppressed',
        {'slotKey': f.slots['3,3'], 'suppressed': true});
    for (final point in ['3,2', '4,3']) {
      map = await mutate(f.project, map, 'feature_set_suppressed',
          {'slotKey': f.slots[point], 'suppressed': true});
    }
    map = await mutate(f.project, map, 'materialize_apply', {});
    expect(map.spatialScene!.instances.length, 4);
    expect(currentFeature(map).overrides.length, 3);
    expect(
        currentFeature(map).overrides.every((override) => override.suppressed),
        true);
    expect(map.spatialScene!.navigation, f.map.spatialScene!.navigation);
  });

  test(
      'validates a released slot replacement with the current corner suppression',
      () async {
    final f = fixture();
    var map = await mutate(f.project, f.map, 'feature_set_suppressed',
        {'slotKey': f.slots['3,3'], 'suppressed': true});
    map = await mutate(f.project, map, 'feature_set_replacement',
        {'slotKey': f.slots['3,2'], 'primitiveId': 'lineStraight'});
    map = await mutate(f.project, map, 'materialize_apply', {});
    expect(map.spatialScene!.instances.length, 6);
    expect(currentFeature(map).overrides.length, 2);
  });

  test(
      'accepts suppression of a reserved logical slot while rejecting invented slots',
      () async {
    final f = fixture();
    var map = await mutate(f.project, f.map, 'feature_set_suppressed',
        {'slotKey': f.slots['3,2'], 'suppressed': true});
    map = await mutate(f.project, map, 'materialize_apply', {});
    expect(map.spatialScene!.instances.length, 5);
    await expectLater(
        mutate(f.project, map, 'feature_set_suppressed',
            {'slotKey': 'invented-slot', 'suppressed': true}),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', 'border.slot_missing')));
    await expectLater(
        mutate(f.project, f.map, 'feature_set_replacement',
            {'slotKey': f.slots['3,2'], 'primitiveId': 'lineStraight'}),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'border.spatial.corner_join_override_conflict')));
  });
  for (final restore in [
    'feature_clear_slot_override',
    'feature_set_suppressed'
  ]) {
    test(
        '$restore rejects reactivating a wide corner over a corrected neighbor',
        () async {
      final f = fixture();
      var map = await mutate(f.project, f.map, 'feature_set_suppressed',
          {'slotKey': f.slots['3,3'], 'suppressed': true});
      map = await mutate(f.project, map, 'feature_set_replacement',
          {'slotKey': f.slots['3,2'], 'primitiveId': 'lineStraight'});
      final before = jsonEncode(map.toJson());
      await expectLater(
          mutate(f.project, map, restore, {
            'slotKey': f.slots['3,3'],
            if (restore == 'feature_set_suppressed') 'suppressed': false
          }),
          throwsA(isA<MapAuthoringException>().having((error) => error.code,
              'code', 'border.spatial.corner_join_override_conflict')));
      expect(jsonEncode(map.toJson()), before);
      expect(
          resolveSpatialBorderFeature(
                  manifest: f.project,
                  map: map,
                  layerId: 'border',
                  featureId: 'fence')
              .result
              .canApply,
          true);
    });
  }
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} persists suppressions of released logical slots',
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
      final actions = <(String, Map<String, Object?>)>[
        for (final point in ['3,3', '3,2', '4,3'])
          (
            'feature_set_suppressed',
            {'slotKey': f.slots[point], 'suppressed': true}
          ),
        ('materialize_apply', {}),
        ('feature_clear_slot_override', {'slotKey': f.slots['3,2']}),
        (
          'feature_set_replacement',
          {'slotKey': f.slots['3,2'], 'primitiveId': 'lineStraight'}
        ),
        ('materialize_apply', {}),
      ];
      for (final (index, (action, parameters)) in actions.indexed) {
        final before = await mapFile.readAsBytes();
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final request = AuthoringRequest(
            requestId: 'reserved-$index',
            actionId: 'border_layer.$action',
            actionVersion: 1,
            workspaceHandle: host.workspace,
            parameters: {...target, ...parameters},
            expectedRevision: snapshot.revision,
            idempotencyKey: 'reserved-$index');
        late final String planId;
        if (jsonl) {
          final plan = await host.command('plan',
              {'projectHandle': host.project, 'request': request.toJson()});
          expect(plan.status, AuthoringResultStatus.success,
              reason: jsonEncode(plan.toJson()));
          planId = plan.data['planId'] as String;
        } else {
          planId = (await host.mutations
                  .planMutation(ProjectHandle(host.project), request))
              .planId;
        }
        expect(await mapFile.readAsBytes(), before);
        if (jsonl) {
          final result = await host.command('apply', {
            'projectHandle': host.project,
            'planId': planId,
            'operationId': 'reserved-$index'
          });
          expect(result.status, AuthoringResultStatus.success,
              reason: jsonEncode(result.toJson()));
        } else {
          final result = await host.mutations.applyMutation(
              ProjectHandle(host.project),
              planId: planId,
              operationId: 'reserved-$index');
          expect(result.receipt.status, AuthoringReceiptStatus.applied);
        }
        expect(await projectFile.readAsBytes(), manifestBytes);
      }
      final saved = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(saved.spatialScene!.instances.length, 5);
      expect(
          currentFeature(saved)
              .overrides
              .where((override) => override.suppressed),
          hasLength(2));
      expect(saved.spatialScene!.navigation, f.map.spatialScene!.navigation);
      expect(saved.entities, f.map.entities);
      expect(saved.events, f.map.events);
      for (final restore in [
        'feature_clear_slot_override',
        'feature_set_suppressed'
      ]) {
        final before = await mapFile.readAsBytes();
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final request = AuthoringRequest(
            requestId: 'reserved-restore-$restore',
            actionId: 'border_layer.$restore',
            actionVersion: 1,
            workspaceHandle: host.workspace,
            parameters: {
              ...target,
              'slotKey': f.slots['3,3'],
              if (restore == 'feature_set_suppressed') 'suppressed': false
            },
            expectedRevision: snapshot.revision,
            idempotencyKey: 'reserved-restore-$restore');
        if (jsonl) {
          final result = await host.command('plan',
              {'projectHandle': host.project, 'request': request.toJson()});
          expect(result.status, AuthoringResultStatus.failure);
          expect(jsonEncode(result.toJson()),
              contains('border.spatial.corner_join_override_conflict'));
        } else {
          await expectLater(
              host.mutations.planMutation(ProjectHandle(host.project), request),
              throwsA(isA<MapAuthoringException>().having((error) => error.code,
                  'code', 'border.spatial.corner_join_override_conflict')));
        }
        expect(await mapFile.readAsBytes(), before);
        expect(await projectFile.readAsBytes(), manifestBytes);
      }
    });
  }
}
