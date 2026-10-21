import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> command({String fact = 'rival', int maximum = 7}) => {
      'kind': 'inputTextToFact',
      'factId': fact,
      'prompt': {'localizationKey': 'rival.name', 'fallbackText': 'Son nom ?'},
      'confirmationPrompt': {
        'localizationKey': 'rival.confirm',
        'fallbackText': 'Confirmer {value} ?'
      },
      'constraints': {'minGraphemes': 1, 'maxGraphemes': maximum},
      'presetValues': ['Blue', 'Gary', 'Michael'],
      'customChoiceLabel': 'Custom',
      'presetChoicePrompt': {
        'localizationKey': 'rival.choice',
        'fallbackText': 'Quel nom ?'
      },
    };
Map<String, Object?> node(Map<String, Object?> value) => {
      'id': 'input',
      'kind': 'action',
      'payload': {'interactiveCommand': value}
    };
Map<String, Object?> scene() => {
      'id': 'text-fact',
      'name': 'Rival',
      'metadata': {'kept': 'yes'},
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          node(command()),
          {'id': 'end', 'kind': 'end'}
        ],
        'edges': [
          {
            'id': 'enter',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'input',
            'kind': 'default'
          },
          for (final port in ['completed', 'cancelled'])
            {
              'id': port,
              'fromNodeId': 'input',
              'fromPortId': port,
              'toNodeId': 'end',
              'kind': 'actionCompleted'
            }
        ],
      }
    };
void main() {
  test('text Fact workflow has a discoverable semantic contract', () {
    for (final id in [
      'scene.upsert',
      'scene.graph.patch',
      'scene.interactive_command.set'
    ]) {
      final action =
          SceneActions.descriptors.singleWhere((value) => value.id == id);
      final contract = action.extensions['inputTextToFact'] as Map;
      expect(contract['factReference'], 'knownUniqueStringFact');
      expect(contract['atomicity'], 'orderedSceneConsequenceBuffer');
      expect(contract['outputPorts'], ['completed', 'cancelled']);
      expect(contract['persistentField'], 'narrativeFactRuntimeState');
    }
  });
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} authors text Fact input and rejects nontext targets',
        () async {
      final fixture = await _TextFixture.create(jsonl: jsonl);
      addTearDown(fixture.dispose);
      final before = await fixture.bytes();
      final upsert = await fixture.plan('scene.upsert', {'scene': scene()});
      expect(await fixture.bytes(), before);
      await fixture.apply(upsert);
      expect(await fixture.storedCommand(), command());
      final update = await fixture.plan('scene.interactive_command.set', {
        'sceneId': 'text-fact',
        'nodeId': 'input',
        'command': command(maximum: 8)
      });
      await fixture.apply(update);
      expect(await fixture.storedCommand(), command(maximum: 8));
      final authored = await fixture.bytes();
      for (final fact in ['flag', 'missing']) {
        await fixture.expectRefusal('scene.graph.patch', {
          'sceneId': 'text-fact',
          'upsertNodes': [node(command(fact: fact))]
        });
        expect(await fixture.bytes(), authored);
      }
      await fixture.reopen();
      expect(await fixture.storedCommand(), command(maximum: 8));
      final manifest = ProjectManifest.fromJson(
          jsonDecode(await fixture.file.readAsString())
              as Map<String, dynamic>);
      expect(manifest.scenes.single.metadata, {'kept': 'yes'});
      expect(
          manifest.facts.singleWhere((fact) => fact.id == 'rival').initialValue,
          NarrativeValue.string('Old'));
    });
  }
}

final class _TextFixture {
  _TextFixture(this.root, this.api, this.mutations, this.snapshots, this.jsonl)
      : worker = JsonlWorker(api: api, mutations: mutations);

  final Directory root;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final bool jsonl;
  final JsonlWorker worker;
  late OpenedProject opened;
  var sequence = 0;

  File get file => File('${root.path}/project.json');

  static Future<_TextFixture> create({required bool jsonl}) async {
    final root = await Directory.systemTemp.createTemp('scene-text-fact-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      ProjectManifest(name: 'Text Fact', maps: [], tilesets: [], facts: [
        NarrativeFactDefinition(
            id: 'rival',
            label: 'Nom',
            initialValue: NarrativeValue.string('Old')),
        NarrativeFactDefinition(id: 'flag', label: 'Flag')
      ]).toJson(),
    ));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final fixture = _TextFixture(root, api, mutations, snapshots, jsonl);
    await fixture.reopen();
    return fixture;
  }

  Future<void> reopen() async {
    opened = await api.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
  }

  Future<List<int>> bytes() => file.readAsBytes();

  Future<Map<String, Object?>> plan(
    String action,
    Map<String, Object?> parameters,
  ) async {
    final snapshot = await snapshots.load(opened.projectHandle);
    final request = AuthoringRequest(
      requestId: 'text-fact-${++sequence}',
      actionId: action,
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'text-fact-$sequence',
      parameters: parameters,
    );
    if (!jsonl) return mutations.plan(opened.projectHandle, request);
    final response = await _jsonl('plan', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson(),
    });
    if (response.status != AuthoringResultStatus.success) {
      throw response.error!;
    }
    return response.data;
  }

  Future<void> expectRefusal(
    String action,
    Map<String, Object?> parameters,
  ) async {
    await expectLater(
      () => plan(action, parameters),
      throwsA(jsonl
          ? isA<AuthoringError>().having(
              (error) => error.details['domainCode'],
              'domainCode',
              'scene.publication_blocked',
            )
          : isA<NarrativeAuthoringException>().having(
              (error) => error.code,
              'code',
              'scene.publication_blocked',
            )),
    );
  }

  Future<void> apply(Map<String, Object?> plan) async {
    final Map<String, Object?> result;
    if (jsonl) {
      final response = await _jsonl('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': 'text-fact-apply-$sequence',
      });
      expect(response.status, AuthoringResultStatus.success,
          reason: jsonEncode(response.toJson()));
      result = response.data;
    } else {
      result = await mutations.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'text-fact-apply-$sequence',
      );
    }
    expect((result['receipt']! as Map)['status'], 'applied');
  }

  Future<AuthoringResult> _jsonl(
      String command, Map<String, Object?> args) async {
    final encoded = await worker.processLine(jsonEncode({
      'id': 'text-fact-$command-$sequence',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> storedCommand() async {
    final manifest = jsonDecode(await file.readAsString()) as Map;
    final scene = (manifest['scenes'] as List).single as Map;
    final graph = scene['graph'] as Map;
    final gift = (graph['nodes'] as List).cast<Map>().singleWhere(
          (node) => node['id'] == 'input',
        );
    return Map<String, dynamic>.from(
        (gift['payload'] as Map)['interactiveCommand'] as Map);
  }

  Future<void> dispose() => root.delete(recursive: true);
}
