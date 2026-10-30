import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> command({String output = 'ball'}) =>
    SceneInteractiveCommand.openCrafting(
        definition: DeferredCraftingDefinition(
            serviceId: 'artisan',
            label: 'Artisan',
            recipes: [
          DeferredCraftingRecipe(
              recipeId: 'fruit-ball',
              label: 'Ball',
              inputItemId: 'fruit',
              inputQuantity: 2,
              outputItemId: output,
              outputQuantity: 1)
        ])).toJson();
Map<String, dynamic> scene() => {
      'id': 'crafting',
      'name': 'Artisan',
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {
            'id': 'crafting-node',
            'kind': 'action',
            'payload': {'interactiveCommand': command()}
          },
          {'id': 'end', 'kind': 'end'}
        ],
        'edges': [
          {
            'id': 'enter',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'crafting-node',
            'kind': 'default'
          },
          for (final port in ['completed', 'cancelled'])
            {
              'id': 'leave-$port',
              'fromNodeId': 'crafting-node',
              'fromPortId': port,
              'toNodeId': 'end',
              'kind': 'actionCompleted'
            }
        ]
      }
    };

void main() {
  test('crafting semantics are discoverable on all canonical Scene actions',
      () {
    for (final id in [
      'scene.upsert',
      'scene.graph.patch',
      'scene.interactive_command.set'
    ]) {
      final contract = SceneActions.descriptors
          .singleWhere((action) => action.id == id)
          .extensions['openCrafting'] as Map;
      expect(contract['calendar'], 'nextObservedHostCivilDayNotElapsed24Hours');
      expect(contract['bagFull'], 'pendingOrderPreserved');
      expect(contract['outputPorts'], ['completed', 'cancelled']);
    }
  });
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} authors inline recipes and rejects broken item refs without writing',
        () async {
      final fixture = await _CraftingFixture.create(jsonl: jsonl);
      addTearDown(fixture.dispose);
      final original = await fixture.bytes();
      final plan = await fixture.plan('scene.upsert', {'scene': scene()});
      expect(await fixture.bytes(), original);
      await fixture.apply(plan);
      expect(await fixture.storedCommand(), command());
      final before = await fixture.bytes();
      await fixture.expectRefusal('scene.interactive_command.set', {
        'sceneId': 'crafting',
        'nodeId': 'crafting-node',
        'command': command(output: 'missing')
      });
      expect(await fixture.bytes(), before);
      await fixture.reopen();
      expect(await fixture.storedCommand(), command());
    });
  }
}

final class _CraftingFixture {
  _CraftingFixture(
      this.root, this.api, this.mutations, this.snapshots, this.jsonl)
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

  static Future<_CraftingFixture> create({required bool jsonl}) async {
    final qaRoot = Directory(Platform.environment['AVELUNE_QA_ROOT'] ??
        '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/crafting');
    await qaRoot.create(recursive: true);
    final root = await qaRoot.createTemp('deferred-crafting-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      const ProjectManifest(
          name: 'Crafting',
          maps: [],
          tilesets: [],
          pokemon: ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
              catalogFiles: {'items': 'items.json'})).toJson(),
    ));
    await File('${root.path}/items.json').writeAsString(jsonEncode(
        encodeProjectItemCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(
          id: 'fruit', displayName: 'Fruit', pocketId: 'materials'),
      ProjectItemDefinition(id: 'ball', displayName: 'Ball', pocketId: 'balls')
    ]))));
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
    final fixture = _CraftingFixture(root, api, mutations, snapshots, jsonl);
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
      requestId: 'crafting-${++sequence}',
      actionId: action,
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'crafting-$sequence',
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
        'operationId': 'crafting-apply-$sequence',
      });
      expect(response.status, AuthoringResultStatus.success,
          reason: jsonEncode(response.toJson()));
      result = response.data;
    } else {
      result = await mutations.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'crafting-apply-$sequence',
      );
    }
    expect((result['receipt']! as Map)['status'], 'applied');
  }

  Future<AuthoringResult> _jsonl(
      String command, Map<String, Object?> args) async {
    final encoded = await worker.processLine(jsonEncode({
      'id': 'crafting-$command-$sequence',
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
          (node) => node['id'] == 'crafting-node',
        );
    return Map<String, dynamic>.from(
        (gift['payload'] as Map)['interactiveCommand'] as Map);
  }

  Future<void> dispose() => root.delete(recursive: true);
}
