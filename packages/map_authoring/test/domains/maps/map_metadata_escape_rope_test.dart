import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'map_metadata_fixture.dart';

Future<MapMetadataFixture> fixture() async {
  final f = await MapMetadataFixture.create();
  final manifest = await f.manifest();
  await File('${f.root.path}/project.json').writeAsString(jsonEncode(manifest
      .copyWith(groups: const [
    ProjectMapGroup(id: 'cave', name: 'Grotte', type: MapGroupType.dungeon)
  ]).toJson()));
  return f;
}

void main() {
  test(
      'library preserves explicit membership and refuses empty referenced group removal',
      () async {
    final f = await fixture();
    addTearDown(f.dispose);
    await f.apply(await f
        .plan(parameters: {'mapId': 'town', 'escapeRopeDungeonId': 'cave'}));
    final before = await f.map();
    Future<Map<String, Object?>> library(
        Map<String, Object?> parameters) async {
      final snapshot = await f.snapshots.load(f.opened.projectHandle);
      f.sequence++;
      return f.api.plan(
          f.opened.projectHandle,
          AuthoringRequest(
              requestId: 'library-${f.sequence}',
              actionId: 'map.library.reorganize',
              actionVersion: 1,
              workspaceHandle: f.opened.workspaceHandle.value,
              parameters: parameters,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'library-${f.sequence}'));
    }

    expect((await f.manifest()).maps.single.groupId, isNull);
    await expectLater(() => library({'groups': [], 'assignments': []}),
        throwsA(isA<Exception>()));
    expect(await f.map(), before);
    await f.apply(await library({
      'assignments': [
        {'mapId': 'town', 'groupId': 'cave'}
      ]
    }));
    expect((await f.manifest()).maps.single.groupId, 'cave');
    expect(await f.map(), before);
    await f.apply(await library({
      'assignments': [
        {'mapId': 'town', 'groupId': null}
      ]
    }));
    expect((await f.manifest()).maps.single.groupId, isNull);
    expect(await f.map(), before);
  });
  test('missing map blocks only actual group removal, never folder renaming',
      () async {
    final f = await fixture();
    addTearDown(f.dispose);
    final snapshot = await f.snapshots.load(f.opened.projectHandle);
    final partial = ProjectSnapshot(
        projectHandle: snapshot.projectHandle,
        revision: snapshot.revision,
        manifest: snapshot.manifest,
        maps: [],
        resourceFingerprints: snapshot.resourceFingerprints,
        resourceBytes: {'project': snapshot.resourceBytes('project')});
    AuthoringPlanningContext context(List<Map<String, Object?>> groups) =>
        AuthoringPlanningContext(
            snapshot: partial,
            planId: 'library-test',
            seed: 0,
            request: AuthoringRequest(
                requestId: 'library-partial',
                actionId: 'map.library.reorganize',
                actionVersion: 1,
                workspaceHandle: f.opened.workspaceHandle.value,
                parameters: {'groups': groups, 'assignments': []},
                expectedRevision: snapshot.revision,
                idempotencyKey: 'library-partial'));
    expect(() => const MapLibraryActions().build(context([])),
        throwsA(isA<Exception>()));
    final draft = const MapLibraryActions().build(context(
        [snapshot.manifest.groups.single.copyWith(name: 'Renommée').toJson()]));
    expect(draft.referenceImpact['mapContentUnchanged'], isTrue);
  });

  test(
      'explicit dungeon and restriction apply, survive JSONL and undo without organization changes',
      () async {
    final f = await fixture();
    addTearDown(f.dispose);
    final before = await f.map(), manifest = await f.manifest();
    final result = await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'escapeRopeDungeonId': 'cave',
      'allowEscapeRope': false
    }));
    expect((await f.map()).mapMetadata.escapeRopeDungeonId, 'cave');
    expect((await f.map()).mapMetadata.allowEscapeRope, isFalse);
    expect(await f.manifest(), manifest);
    final descriptor =
        (await f.wire('describe', {})).data['mutationActions'] as List;
    final metadata = descriptor
        .cast<Map>()
        .singleWhere((a) => a['id'] == 'map.update_metadata');
    final properties = ((metadata['extensions'] as Map)['inputSchema']
        as Map)['properties'] as Map;
    expect(properties, contains('escapeRopeDungeonId'));
    expect(properties, contains('allowEscapeRope'));
    await f.api.undo(f.opened.projectHandle,
        entryId: (result['receipt'] as Map)['receiptId'] as String,
        idempotencyKey: 'rope-undo');
    expect(await f.map(), before);
    final request = await f
        .request(parameters: {'mapId': 'town', 'escapeRopeDungeonId': 'cave'});
    final plan = await f.wire('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson()
    });
    expect(plan.status, AuthoringResultStatus.success,
        reason: plan.toJson().toString());
    final applied = await f.wire('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': plan.data['planId'],
      'operationId': 'rope-wire'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    expect((await f.map()).mapMetadata.escapeRopeDungeonId, 'cave');
    await f.apply(await f
        .plan(parameters: {'mapId': 'town', 'escapeRopeDungeonId': null}));
    expect((await f.map()).mapMetadata.escapeRopeDungeonId, isNull);
  });
  for (final invalid in [
    {'mapId': 'town', 'escapeRopeDungeonId': 'unknown'},
    {'mapId': 'town', 'escapeRopeDungeonId': ' '},
    {'mapId': 'town', 'allowEscapeRope': 'yes'}
  ]) {
    test('invalid escape metadata never changes files: $invalid', () async {
      final f = await fixture();
      addTearDown(f.dispose);
      final before = await f.map();
      await expectLater(() => f.plan(parameters: invalid),
          throwsA(isA<MapAuthoringException>()));
      expect(await f.map(), before);
    });
  }
}
