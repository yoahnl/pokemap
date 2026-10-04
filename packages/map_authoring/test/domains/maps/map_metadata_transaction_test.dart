import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'map_metadata_fixture.dart';

void main() {
  test('recovers both names after a crash between promotions', () async {
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
    final planned = await f.plan();
    await expectLater(() => f.apply(planned),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    expect((await f.map()).name, 'Village été');
    expect((await f.manifest()).maps.single.name, 'Town');
    crash = false;
    final recovered = await f.api.recover(f.opened.projectHandle,
        operationId: 'metadata-apply-${f.sequence}');
    expect((recovered['receipt']! as Map)['status'], 'recovered');
    expect((await f.map()).name, 'Village été');
    expect((await f.manifest()).maps.single.name, 'Village été');
  });

  test('different stored names are repaired rather than treated as a no-op',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    await File('${f.root.path}/documents/unusual.json').writeAsBytes(
        encodeMapAuthoringDocument((await f.map()).copyWith(name: 'Old')));
    await f.apply(await f.plan(name: 'Town'));
    expect((await f.map()).name, 'Town');
    expect((await f.manifest()).maps.single.name, 'Town');
  });

  test('JSONL discovers, plans and applies stable title metadata', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final described = await f.wire('describe', {});
    expect(
        (described.data['mutationActions']! as List).cast<Map>().any(
            (descriptor) =>
                descriptor['id'] == 'map.update_metadata' &&
                descriptor['inputSchemaId'] ==
                    'schema.map.update_metadata.input.v1'),
        isTrue);
    final request = await f.request();
    final plan = await f.wire('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson()
    });
    expect(plan.status, AuthoringResultStatus.success,
        reason: plan.toJson().toString());
    final applied = await f.wire('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': plan.data['planId'],
      'operationId': 'wire-rename'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    expect((await f.map()).name, 'Village été');
    expect((await f.manifest()).maps.single.name, 'Village été');
  });
  test('stable title updates both documents and preserves referenced identity',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final beforeMap = await f.map();
    final beforeManifest = await f.manifest();
    final planned = await f.plan();
    expect((await f.map()).name, 'Town');
    final result = await f.apply(planned);
    expect((result['receipt']! as Map)['status'], 'applied');
    final afterMap = await f.map();
    final afterManifest = await f.manifest();
    expect(afterMap.name, 'Village été');
    expect(afterManifest.maps.single.name, 'Village été');
    expect(afterMap.copyWith(name: beforeMap.name), beforeMap);
    expect(afterManifest.copyWith(maps: beforeManifest.maps), beforeManifest);
    expect(
        afterManifest.maps.single
            .copyWith(name: beforeManifest.maps.single.name),
        beforeManifest.maps.single);
    expect(await File('${f.root.path}/maps/town.json').exists(), isFalse);
    final receipt = result['receipt']! as Map;
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String, idempotencyKey: 'undo-title');
    expect(await f.map(), beforeMap);
    expect(await f.manifest(), beforeManifest);
  });

  test('normalized unchanged title publishes neither documents nor history',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final mapFile = File('${f.root.path}/documents/unusual.json');
    final manifestFile = File('${f.root.path}/project.json');
    final mapBytes = await mapFile.readAsBytes();
    final manifestBytes = await manifestFile.readAsBytes();
    final revision = (await f.snapshots.load(f.opened.projectHandle)).revision;
    final history = await f.api.history(f.opened.projectHandle, limit: 20);
    await expectLater(
        () => f.plan(name: '  Town  '),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'map.no_change')));
    expect(await mapFile.readAsBytes(), mapBytes);
    expect(await manifestFile.readAsBytes(), manifestBytes);
    expect((await f.snapshots.load(f.opened.projectHandle)).revision, revision);
    expect(await f.api.history(f.opened.projectHandle, limit: 20), history);
  });

  test('stored whitespace-equivalent titles remain a no-op', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final mapFile = File('${f.root.path}/documents/unusual.json');
    final manifestFile = File('${f.root.path}/project.json');
    await mapFile.writeAsBytes(
        encodeMapAuthoringDocument((await f.map()).copyWith(name: ' Town ')));
    final before = await f.manifest();
    await manifestFile.writeAsString(jsonEncode(before.copyWith(maps: [
      before.maps.single.copyWith(name: ' Town '),
    ]).toJson()));
    final bytes = await mapFile.readAsBytes();
    await expectLater(
        () => f.plan(name: 'Town'),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'map.no_change')));
    expect(await mapFile.readAsBytes(), bytes);
  });

  test('stale source prevents title publication', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final planned = await f.plan();
    final external = (await f.map()).copyWith(name: 'External');
    await File('${f.root.path}/documents/unusual.json')
        .writeAsBytes(encodeMapAuthoringDocument(external));
    await expectLater(() => f.apply(planned), throwsA(isA<Exception>()));
    expect(await f.map(), external);
    expect((await f.manifest()).maps.single.name, 'Town');
  });

  for (final params in [
    {'mapId': 'town', 'name': ''},
    {'mapId': 'absent', 'name': 'Name'},
    {'mapId': 'town', 'name': 'Name', 'newMapId': 'other'},
  ]) {
    test('invalid metadata request preserves source: $params', () async {
      final f = await MapMetadataFixture.create();
      addTearDown(f.dispose);
      final before = await f.map();
      await expectLater(
          () => f.plan(parameters: params), throwsA(isA<Exception>()));
      expect(await f.map(), before);
    });
  }
}
