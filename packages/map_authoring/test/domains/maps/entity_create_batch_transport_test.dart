import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

Map<String, Object?> _entity(String id, {int x = 1}) => {
      'id': id,
      'kind': 'custom',
      'pos': {'x': x, 'y': 1},
      'properties': {'authored': 'preserved'},
    };

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';
    test('$transport batch applies once reopens and reverses both directions',
        () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(f.dispose);
      final before = await f.map.readAsBytes();
      final manifestBefore = await f.manifest.readAsBytes();
      final request =
          await f.request([_entity('first'), _entity('last', x: 2)]);
      final planned = await f.plan(request);
      expect(await f.map.readAsBytes(), before);
      final applied = await f.apply(planned['planId'] as String);
      final after = await f.map.readAsBytes();
      final receipt = applied['receipt'] as Map;
      expect(receipt['actionId'], 'entity.create_batch');
      expect((await f.apply(planned['planId'] as String))['receipt'], receipt);
      expect(await f.map.readAsBytes(), after);
      await f.reopen();
      final reloaded = (await f.snapshots.load(f.project)).maps.single;
      expect(reloaded.entities.map((entity) => entity.id),
          ['old', 'first', 'last']);
      expect(reloaded.entities.last.properties, {'authored': 'preserved'});
      expect(await f.manifest.readAsBytes(), manifestBefore);
      final undone = await f.undo(receipt['receiptId'] as String);
      expect(await f.map.readAsBytes(), before);
      expect(await f.manifest.readAsBytes(), manifestBefore);
      final restored =
          await f.undo((undone['receipt'] as Map)['receiptId'] as String);
      expect((restored['receipt'] as Map)['actionId'], 'history.undo');
      expect(await f.map.readAsBytes(), after);
      expect(await f.manifest.readAsBytes(), manifestBefore);
      await f.reopen();
      expect((await f.snapshots.load(f.project)).maps.single, reloaded);
    });

    test('$transport dry-run batch cannot mutate files', () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(f.dispose);
      final before = await f.map.readAsBytes();
      final planned =
          await f.plan(await f.request([_entity('preview')], dryRun: true));
      expect(planned['applicable'], isFalse);
      await expectLater(
          f.apply(planned['planId'] as String), throwsA(anything));
      expect(await f.map.readAsBytes(), before);
    });

    test('$transport publishes the 128 member boundary as one receipt',
        () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(f.dispose);
      final planned = await f.plan(await f.request([
        for (var index = 0; index < 128; index++) _entity('batch-$index'),
      ]));
      final applied = await f.apply(planned['planId'] as String);
      expect((applied['receipt'] as Map)['actionId'], 'entity.create_batch');
      expect((await f.snapshots.load(f.project)).maps.single.entities,
          hasLength(129));
      expect(await f.historyCount(), 1);
    });

    test('$transport malformed duplicate and invalid final members are atomic',
        () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(f.dispose);
      final mapBefore = await f.map.readAsBytes();
      final manifestBefore = await f.manifest.readAsBytes();
      final revision = (await f.snapshots.load(f.project)).revision;
      for (final entities in <Object?>[
        null,
        [],
        {},
        List.generate(129, (index) => _entity('n$index')),
        [_entity('first'), _entity('first')],
        [_entity('first'), _entity('old')],
        [_entity('first'), 42],
        [_entity('first'), _entity('outside', x: 99)],
        [
          _entity('first'),
          {
            ..._entity('bad'),
            'item': {'gameItemId': 'potion'}
          }
        ],
      ]) {
        final request = await f.request(entities);
        await expectLater(
            f.plan(request),
            throwsA(jsonl
                ? isA<AuthoringError>()
                    .having((error) => error.code, 'code',
                        isNot(AuthoringErrorCode.internal))
                    .having((error) => error.details['domainCode'],
                        'domainCode', isNot('worker.internal'))
                : isA<MapAuthoringException>()));
        expect(await f.map.readAsBytes(), mapBefore);
        expect(await f.manifest.readAsBytes(), manifestBefore);
        expect((await f.snapshots.load(f.project)).revision, revision);
      }
      expect(await f.historyCount(), 0);
    });

    test('$transport stale planned batch refuses every member at apply',
        () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(f.dispose);
      final stale = await f
          .plan(await f.request([_entity('stale-a'), _entity('stale-b')]));
      final current = await f.plan(await f.request([_entity('current')]));
      await f.apply(current['planId'] as String);
      final before = await f.map.readAsBytes();
      await expectLater(f.apply(stale['planId'] as String), throwsA(anything));
      expect(await f.map.readAsBytes(), before);
      expect(
          (await f.snapshots.load(f.project))
              .maps
              .single
              .entities
              .map((e) => e.id),
          ['old', 'current']);
      expect(await f.historyCount(), 1);
    });
  }
}

final class _Fixture {
  _Fixture(this.root, this.jsonl, this.api, this.mutations, this.snapshots,
      this.worker);

  final Directory root;
  final bool jsonl;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  late ProjectHandle project;
  late WorkspaceHandle workspace;
  var sequence = 0;
  File get manifest => File('${root.path}/project.json');
  File get map => File('${root.path}/maps/route.json');

  static Future<_Fixture> create(bool jsonl) async {
    final root =
        await Directory.systemTemp.createTemp('entity-batch-transport-');
    final map = catalogMap('route').copyWith(entities: [
      MapEntity.fromJson(_entity('old')),
    ]);
    final project = catalogSnapshot([map]).manifest;
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    final file = File('${root.path}/maps/route.json');
    await file.parent.create();
    await file.writeAsString(jsonEncode(map.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final fixture = _Fixture(root, jsonl, api, mutations, snapshots,
        JsonlWorker(api: api, mutations: mutations));
    await fixture.open();
    return fixture;
  }

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode({
      'id': 'entity-${++sequence}',
      'command': command,
      'args': args
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) throw result.error!;
    return result.data;
  }

  Future<void> open() async {
    if (jsonl) {
      final opened = await wire('open', {'projectRoot': root.path});
      project = ProjectHandle(opened['projectHandle'] as String);
      workspace = WorkspaceHandle(opened['workspaceHandle'] as String);
    } else {
      final opened = await api.openProject(root.path);
      project = opened.projectHandle;
      workspace = opened.workspaceHandle;
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: workspace,
          projectHandle: project);
    }
  }

  Future<void> close() async {
    if (jsonl) {
      await wire('close', {'workspaceHandle': workspace.value});
    } else {
      await mutations.detachWorkspace(workspace);
      await api.closeWorkspace(workspace);
    }
  }

  Future<void> reopen() async {
    await close();
    await open();
  }

  Future<AuthoringRequest> request(Object? entities,
      {bool dryRun = false}) async {
    final id = 'entity-batch-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: 'entity.create_batch',
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: {'mapId': 'route', 'entities': entities},
        dryRun: dryRun);
  }

  Future<Map<String, Object?>> plan(AuthoringRequest request) => jsonl
      ? wire(
          'plan', {'projectHandle': project.value, 'request': request.toJson()})
      : mutations.plan(project, request);

  Future<Map<String, Object?>> apply(String planId) => jsonl
      ? wire('apply', {
          'projectHandle': project.value,
          'planId': planId,
          'operationId': 'apply-$planId'
        })
      : mutations.apply(project, planId: planId, operationId: 'apply-$planId');

  Future<Map<String, Object?>> undo(String entryId) {
    final id = 'undo-entity-${++sequence}';
    return jsonl
        ? wire('undo', {
            'projectHandle': project.value,
            'entryId': entryId,
            'idempotencyKey': id
          })
        : mutations.undo(project, entryId: entryId, idempotencyKey: id);
  }

  Future<int> historyCount() async {
    final file = File('${root.path}/.pokemap/authoring/history.jsonl');
    if (!await file.exists()) return 0;
    return (await file.readAsLines()).where((line) => line.isNotEmpty).length;
  }

  Future<void> dispose() async {
    await close();
    await root.delete(recursive: true);
  }
}
