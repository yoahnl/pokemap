import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('party recording is discoverable on semantic scene mutations', () {
    for (final id in [
      'scene.upsert',
      'scene.upsert_batch',
      'scene.graph.patch'
    ]) {
      final contract = SceneActions.descriptors
          .singleWhere((entry) => entry.id == id)
          .extensions['finishGame'] as Map;
      expect(contract['contractVersion'], 1);
      expect(contract['recordParty'], {
        'type': 'boolean',
        'default': false,
        'requiredCapability': 'game.completion-party-journal@1',
        'persistentField': 'completionPartyJournal',
        'snapshot': 'immutableCurrentPartyInOrder',
        'deduplication': 'saveIdAndEndingId',
        'commit': 'sameVerifiedFinalCheckpointBeforePresentation',
      });
    }
  });

  for (final jsonl in [false, true]) {
    final mode = jsonl ? 'JSONL' : 'API';
    test('$mode records the option through single batch patch and cold reopen',
        () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(() => f.root.delete(recursive: true));
      await f.apply(
          await f.plan('scene.upsert', {'scene': _scene('first', true)}));
      expect((await f.snapshot()).scenes.single.graph.nodes[1].payload,
          SceneActionPayload.fromJson({'consequence': _finish(true)}));
      final batch = await f.plan('scene.upsert_batch', {
        'scenes': [
          _scene('first', false),
          _scene('second', true),
        ]
      });
      final before = await f.file.readAsBytes();
      final applied = await f.apply(batch);
      final after = await f.file.readAsBytes();
      expect(await f.apply(batch), applied);
      await f.reopen();
      final loaded = await f.snapshot();
      expect(loaded.scenes, hasLength(2));
      expect(_stored(loaded, 'first').containsKey('recordParty'), isFalse);
      expect(_stored(loaded, 'second')['recordParty'], isTrue);
      final undo =
          await f.undo((applied['receipt'] as Map)['receiptId'] as String);
      expect(await f.file.readAsBytes(), before);
      await f.undo((undo['receipt'] as Map)['receiptId'] as String);
      expect(await f.file.readAsBytes(), after);
      final patch = await f.plan('scene.graph.patch', {
        'sceneId': 'second',
        'upsertNodes': [_node(false)],
      });
      await f.apply(patch);
      await f.reopen();
      expect(_stored(await f.snapshot(), 'second').containsKey('recordParty'),
          isFalse);
      expect(_stored(await f.snapshot(), 'second')['result'],
          _finish(false)['result']);
    });

    test('$mode malformed flags and invalid last batch entry are atomic',
        () async {
      final f = await _Fixture.create(jsonl);
      addTearDown(() => f.root.delete(recursive: true));
      final before = await f.file.readAsBytes();
      for (final flag in [null, 'true', 1, [], {}]) {
        final invalid = _scene('bad', true);
        final node = ((invalid['graph'] as Map)['nodes'] as List)[1] as Map;
        ((node['payload'] as Map)['consequence'] as Map)['recordParty'] = flag;
        await expectLater(
          f.plan('scene.upsert_batch', {
            'scenes': [_scene('valid', true), invalid]
          }),
          throwsA(anything),
        );
        expect(await f.file.readAsBytes(), before);
        expect(await f.historyCount(), 0);
      }
    });
  }
}

Map<String, dynamic> _finish(bool recordParty) => {
      'kind': 'finishGame',
      'contractVersion': 1,
      'endingId': 'ending.victory',
      'outcome': 'victory',
      'commitPolicy': 'persistBeforePresentation',
      'result': {
        'title': {
          'fallback': 'Bravo',
          'translations': {'en': 'Victory'}
        },
        'summary': {'fallback': 'Parcours terminé'},
        'details': [
          {'fallback': 'Équipe conservée'}
        ]
      },
      'postGamePolicy': 'continueGame',
      'label': 'Fin conservée',
      'notes': 'Notes conservées',
      if (recordParty) 'recordParty': true,
    };

Map<String, Object?> _node(bool recordParty) => {
      'id': 'finish',
      'kind': 'action',
      'payload': {'consequence': _finish(recordParty)},
    };

Map<String, Object?> _scene(String id, bool recordParty) => {
      'id': id,
      'name': id,
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          _node(recordParty),
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': [
          {
            'id': 'enter',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'finish',
            'kind': 'default'
          },
          {
            'id': 'leave',
            'fromNodeId': 'finish',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'actionCompleted'
          },
        ]
      },
    };

Map<String, dynamic> _stored(ProjectManifest manifest, String id) =>
    (manifest.scenes
            .singleWhere((scene) => scene.id == id)
            .graph
            .nodes[1]
            .payload as SceneActionPayload)
        .consequence!
        .toJson();

final class _Fixture {
  _Fixture(this.root, this.api, this.mutations, this.loader, this.jsonl)
      : worker = JsonlWorker(api: api, mutations: mutations);
  final Directory root;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader loader;
  final JsonlWorker worker;
  final bool jsonl;
  late OpenedProject opened;
  var sequence = 0;
  File get file => File('${root.path}/project.json');

  static Future<_Fixture> create(bool jsonl) async {
    final root = await Directory.systemTemp.createTemp('completion-party-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(name: 'Completion', maps: [], tilesets: [])
            .toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    final fixture = _Fixture(root, api, mutations, loader, jsonl);
    await fixture.reopen();
    return fixture;
  }

  Future<void> reopen() async {
    opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<ProjectManifest> snapshot() async =>
      (await loader.load(opened.projectHandle)).manifest;

  Future<Map<String, Object?>> plan(
      String action, Map<String, Object?> parameters) async {
    final snapshot = await loader.load(opened.projectHandle);
    final request = AuthoringRequest(
        requestId: 'completion-${++sequence}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'completion-$sequence',
        parameters: parameters);
    if (!jsonl) return mutations.plan(opened.projectHandle, request);
    return _line('plan', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson()
    });
  }

  Future<Map<String, Object?>> apply(Map<String, Object?> plan) async {
    final args = {
      'projectHandle': opened.projectHandle.value,
      'planId': plan['planId'],
      'operationId': 'completion-apply-${plan['planId']}'
    };
    return jsonl
        ? _line('apply', args)
        : mutations.apply(opened.projectHandle,
            planId: plan['planId'] as String,
            operationId: args['operationId'] as String);
  }

  Future<Map<String, Object?>> undo(String receiptId) => jsonl
      ? _line('undo', {
          'projectHandle': opened.projectHandle.value,
          'entryId': receiptId,
          'idempotencyKey': 'completion-undo-${++sequence}'
        })
      : mutations.undo(opened.projectHandle,
          entryId: receiptId, idempotencyKey: 'completion-undo-${++sequence}');

  Future<Map<String, Object?>> _line(
      String command, Map<String, Object?> args) async {
    final response = AuthoringResult.fromJson(jsonDecode(
        await worker.processLine(jsonEncode({
      'id': 'completion-$command-$sequence',
      'command': command,
      'args': args
    }))) as Map<String, dynamic>);
    if (response.status != AuthoringResultStatus.success) throw response.error!;
    return response.data;
  }

  Future<int> historyCount() async {
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    return await history.exists()
        ? (await history.readAsLines()).where((line) => line.isNotEmpty).length
        : 0;
  }
}
