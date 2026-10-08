import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_metadata_fixture.dart';

void main() {
  test('updates native spatial maps while preserving their scene and warps',
      () async {
    final f =
        await MapMetadataFixture.create(dimension: ProjectDimension.threeD);
    addTearDown(f.dispose);
    final before = await f.map();
    expect(before.spatialScene, isNotNull);
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'role': 'interior',
      'isIndoor': true,
    }));
    final after = await f.map();
    expect(after.version, ProjectVersion.v9);
    expect(after.spatialScene?.toJson(), before.spatialScene?.toJson());
    expect(after.warps, before.warps);
    expect(after.mapMetadata.isIndoor, isTrue);
    expect((await f.manifest()).settings.dimension, ProjectDimension.threeD);
    expect((await f.manifest()).maps.single.role, MapRole.interior);
  });

  test('title-only edits preserve independently stored environment metadata',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.map();
    await File('${f.root.path}/documents/unusual.json').writeAsBytes(
        encodeMapAuthoringDocument(before.copyWith(
            mapMetadata: before.mapMetadata.copyWith(isIndoor: true))));
    await f.apply(await f.plan(name: 'Updated'));
    expect((await f.map()).name, 'Updated');
    expect((await f.map()).mapMetadata.isIndoor, isTrue);
    expect((await f.manifest()).maps.single.role, MapRole.exterior);
  });

  test('updates indoor role and map metadata without renaming or losing data',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final beforeMap = await f.map();
    final beforeManifest = await f.manifest();
    final planned = await f.plan(parameters: {
      'mapId': 'town',
      'role': 'interior',
      'isIndoor': true,
    });
    expect(await f.map(), beforeMap);
    expect(await f.manifest(), beforeManifest);
    final result = await f.apply(planned);
    final map = await f.map();
    final manifest = await f.manifest();
    expect(map.mapMetadata.isIndoor, isTrue);
    expect(manifest.maps.single.role, MapRole.interior);
    expect(map.copyWith(mapMetadata: beforeMap.mapMetadata), beforeMap);
    expect(manifest.copyWith(maps: beforeManifest.maps), beforeManifest);
    expect(manifest.maps.single.copyWith(role: MapRole.exterior),
        beforeManifest.maps.single);
    final receipt = result['receipt']! as Map;
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-environment');
    expect(await f.map(), beforeMap);
    expect(await f.manifest(), beforeManifest);
  });

  test('role alone synchronizes interior and exterior environment', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'role': 'interior',
    }));
    expect((await f.map()).mapMetadata.isIndoor, isTrue);
    expect((await f.manifest()).maps.single.role, MapRole.interior);
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'role': 'exterior',
    }));
    expect((await f.map()).mapMetadata.isIndoor, isFalse);
    expect((await f.manifest()).maps.single.role, MapRole.exterior);
  });

  test('environment alone synchronizes a binary map role', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    for (final indoor in [true, false]) {
      await f.apply(await f.plan(parameters: {
        'mapId': 'town',
        'isIndoor': indoor,
      }));
      expect((await f.map()).mapMetadata.isIndoor, indoor);
      expect((await f.manifest()).maps.single.role,
          indoor ? MapRole.interior : MapRole.exterior);
    }
  });

  test('organizational roles preserve the separately authored environment',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'role': 'connector',
      'isIndoor': true,
    }));
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'role': 'gate',
    }));
    expect((await f.map()).mapMetadata.isIndoor, isTrue);
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'isIndoor': false,
    }));
    expect((await f.manifest()).maps.single.role, MapRole.gate);
    expect((await f.map()).mapMetadata.isIndoor, isFalse);
  });

  test('recovers coherent indoor metadata after a partial promotion', () async {
    var crash = true;
    final f = await MapMetadataFixture.create(faultInjector: (context) {
      if (crash &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.promotionIndex == 0) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(f.dispose);
    final planned = await f.plan(parameters: {
      'mapId': 'town',
      'role': 'interior',
      'isIndoor': true,
    });
    await expectLater(() => f.apply(planned),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    expect((await f.map()).mapMetadata.isIndoor, isTrue);
    expect((await f.manifest()).maps.single.role, MapRole.exterior);
    crash = false;
    await f.api.recover(f.opened.projectHandle,
        operationId: 'metadata-apply-${f.sequence}');
    expect((await f.map()).mapMetadata.isIndoor, isTrue);
    expect((await f.manifest()).maps.single.role, MapRole.interior);
  });

  test('JSONL exposes and applies role and indoor metadata without a title',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final described = await f.wire('describe', {});
    final descriptor = (described.data['mutationActions']! as List)
        .cast<Map>()
        .singleWhere((action) => action['id'] == 'map.update_metadata');
    final schema = (descriptor['extensions']! as Map)['inputSchema']! as Map;
    expect(schema['required'], ['mapId']);
    final properties = schema['properties']! as Map;
    expect((properties['role']! as Map)['enum'],
        MapRole.values.map((role) => role.name).toList());
    expect((properties['isIndoor']! as Map)['type'], 'boolean');
    final request = await f.request(parameters: {
      'mapId': 'town',
      'role': 'interior',
      'isIndoor': true,
    });
    final planned = await f.wire('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson(),
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: planned.toJson().toString());
    final applied = await f.wire('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'wire-indoor',
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    expect((await f.map()).mapMetadata.isIndoor, isTrue);
    expect((await f.manifest()).maps.single.role, MapRole.interior);
  });

  for (final (parameters, code) in <(Map<String, Object?>, String)>[
    ({'mapId': 'town'}, 'map.metadata_empty'),
    ({'mapId': 'town', 'role': 'outdoors'}, 'map.role_invalid'),
    ({'mapId': 'town', 'role': null}, 'map.role_invalid'),
    ({'mapId': 'town', 'isIndoor': 'true'}, 'map.indoor_invalid'),
    ({'mapId': 'town', 'isIndoor': null}, 'map.indoor_invalid'),
    (
      {'mapId': 'town', 'role': 'interior', 'isIndoor': false},
      'map.metadata_inconsistent'
    ),
    (
      {'mapId': 'town', 'role': 'exterior', 'isIndoor': true},
      'map.metadata_inconsistent'
    ),
    ({'mapId': 'town', 'role': 'exterior'}, 'map.no_change'),
    ({'mapId': 'town', 'isIndoor': false}, 'map.no_change'),
  ]) {
    test('rejects invalid or unchanged metadata: $parameters', () async {
      final f = await MapMetadataFixture.create();
      addTearDown(f.dispose);
      final mapFile = File('${f.root.path}/documents/unusual.json');
      final projectFile = File('${f.root.path}/project.json');
      final mapBytes = await mapFile.readAsBytes();
      final projectBytes = await projectFile.readAsBytes();
      final revision =
          (await f.snapshots.load(f.opened.projectHandle)).revision;
      await expectLater(
          () => f.plan(parameters: parameters),
          throwsA(isA<MapAuthoringException>()
              .having((error) => error.code, 'code', code)));
      expect(await mapFile.readAsBytes(), mapBytes);
      expect(await projectFile.readAsBytes(), projectBytes);
      expect(
          (await f.snapshots.load(f.opened.projectHandle)).revision, revision);
    });
  }
}
