import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('catalog Pokemon gifts are discoverable on both Scene mutations', () {
    for (final id in ['scene.upsert', 'scene.graph.patch']) {
      final descriptor = SceneActions.descriptors.singleWhere(
        (action) => action.id == id,
      );
      expect(descriptor.extensions['givePokemonFromCatalog'], {
        'consequenceKind': 'givePokemonFromCatalog',
        'parameters': ['speciesId', 'formId', 'level'],
        'levelRange': [1, 100],
        'catalog': 'activeProjectPokemonCatalog',
        'generation': 'activeNativeRuleset',
        'initialHealth': 'fullHpAndPp',
        'moves': 'nativeLevelLearnset',
        'destination': 'partyThenStorage',
        'storageFull': 'atomicRefusalWithoutConsumingOperation',
        'pokedex': 'seenAndCaughtOnSuccessfulGrant',
        'idempotency': 'saveIdAndSceneGrantOperationId',
      });
    }
  });

  for (final jsonl in [false, true]) {
    test('${jsonl ? 'JSONL' : 'direct API'} authors and reopens catalog gifts',
        () async {
      final fixture = await _GiftFixture.create(jsonl: jsonl);
      addTearDown(fixture.dispose);
      final original = await fixture.bytes();
      final upsert = await fixture.plan('scene.upsert', {'scene': _scene()});
      expect(await fixture.bytes(), original);
      await fixture.apply(upsert);
      expect(await fixture.storedGift(), _gift(5));
      final beforePatch = await fixture.bytes();
      final patch = await fixture.plan('scene.graph.patch', {
        'sceneId': 'catalog-gift',
        'upsertNodes': [_giftNode(_gift(8))],
      });
      expect(await fixture.bytes(), beforePatch);
      await fixture.apply(patch);
      expect(await fixture.storedGift(), _gift(8));
      final authored = await fixture.bytes();
      for (final invalid in [
        {..._gift(8), 'currentHp': 8},
        {..._gift(8), 'abilityId': 'unknown'},
        _gift(0),
      ]) {
        await fixture.expectRefusal('scene.graph.patch', {
          'sceneId': 'catalog-gift',
          'upsertNodes': [_giftNode(invalid)],
        });
        expect(await fixture.bytes(), authored);
      }
      await fixture.reopen();
      expect(await fixture.storedGift(), _gift(8));
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await fixture.file.readAsString()) as Map<String, dynamic>,
      );
      expect(manifest.scenes.single.metadata, {'kept': 'yes'});
      expect(manifest.scenes.single.layout.nodeLayouts.single.x, 21);
      final consequence = (manifest.scenes.single.graph.nodes
              .singleWhere((node) => node.id == 'gift')
              .payload as SceneActionPayload)
          .consequence;
      expect(consequence, isA<SceneGivePokemonFromCatalogConsequence>());
      expect(buildSceneRuntimePlan(manifest.scenes.single).canBuild, isTrue);
    });
  }
}

Map<String, Object?> _gift(int level) => {
      'kind': 'givePokemonFromCatalog',
      'speciesId': 'sproutle',
      'formId': 'sunny',
      'level': level,
    };

Map<String, Object?> _giftNode(Map<String, Object?> consequence) => {
      'id': 'gift',
      'kind': 'action',
      'title': 'Un compagnon',
      'payload': {'consequence': consequence},
    };

Map<String, Object?> _scene() => {
      'id': 'catalog-gift',
      'name': 'Cadeau du catalogue',
      'metadata': {'kept': 'yes'},
      'layout': {
        'nodeLayouts': [
          {'nodeId': 'gift', 'x': 21, 'y': 34},
        ],
      },
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          _giftNode(_gift(5)),
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': [
          {
            'id': 'enter',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'gift',
            'kind': 'default',
          },
          {
            'id': 'leave',
            'fromNodeId': 'gift',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'actionCompleted',
          },
        ],
      },
    };

final class _GiftFixture {
  _GiftFixture(this.root, this.api, this.mutations, this.snapshots, this.jsonl)
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

  static Future<_GiftFixture> create({required bool jsonl}) async {
    final root = await Directory.systemTemp.createTemp('catalog-pokemon-gift-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      const ProjectManifest(name: 'Catalog gift', maps: [], tilesets: [])
          .toJson(),
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
    final fixture = _GiftFixture(root, api, mutations, snapshots, jsonl);
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
      requestId: 'catalog-gift-${++sequence}',
      actionId: action,
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'catalog-gift-$sequence',
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
              'scene.graph.invalid_patch',
            )
          : isA<NarrativeAuthoringException>().having(
              (error) => error.code,
              'code',
              'scene.graph.invalid_patch',
            )),
    );
  }

  Future<void> apply(Map<String, Object?> plan) async {
    final Map<String, Object?> result;
    if (jsonl) {
      final response = await _jsonl('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': 'catalog-gift-apply-$sequence',
      });
      expect(response.status, AuthoringResultStatus.success,
          reason: jsonEncode(response.toJson()));
      result = response.data;
    } else {
      result = await mutations.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'catalog-gift-apply-$sequence',
      );
    }
    expect((result['receipt']! as Map)['status'], 'applied');
  }

  Future<AuthoringResult> _jsonl(
      String command, Map<String, Object?> args) async {
    final encoded = await worker.processLine(jsonEncode({
      'id': 'catalog-gift-$command-$sequence',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> storedGift() async {
    final manifest = jsonDecode(await file.readAsString()) as Map;
    final scene = (manifest['scenes'] as List).single as Map;
    final graph = scene['graph'] as Map;
    final gift = (graph['nodes'] as List).cast<Map>().singleWhere(
          (node) => node['id'] == 'gift',
        );
    return Map<String, dynamic>.from(
        (gift['payload'] as Map)['consequence'] as Map);
  }

  Future<void> dispose() => root.delete(recursive: true);
}
