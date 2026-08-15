import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('scene.upsert preserves formId through direct API and JSONL', () async {
    final direct = await _ScenePokemonFormHarness.create('direct');
    final jsonl = await _ScenePokemonFormHarness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directReceipt = await direct.executeDirect();
    final jsonlReceipt = await jsonl.executeJsonl();

    expect(directReceipt['actionId'], 'scene.upsert');
    expect(jsonlReceipt['actionId'], 'scene.upsert');
    expect(directReceipt['status'], 'applied');
    expect(jsonlReceipt['status'], 'applied');
    expect(await direct.authoredFormId(), 'sunny');
    expect(await jsonl.authoredFormId(), 'sunny');
  });
}

final class _ScenePokemonFormHarness {
  _ScenePokemonFormHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_ScenePokemonFormHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'scene-pokemon-form-$suffix-',
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        const ProjectManifest(
          name: 'Scene Pokemon form fixture',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ).toJson(),
      ),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
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
    return _ScenePokemonFormHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<Map<String, Object?>> executeDirect() async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      _request(
        workspaceHandle: opened.workspaceHandle.value,
        revision: snapshot.revision,
        suffix: 'direct',
      ),
    );
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'scene-pokemon-form-direct',
    );
    return Map<String, Object?>.from(applied['receipt']! as Map);
  }

  Future<Map<String, Object?>> executeJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final planned = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _request(
        workspaceHandle: workspaceHandle,
        revision: snapshot.revision,
        suffix: 'jsonl',
      ).toJson(),
    });
    final applied = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned.data['planId'],
      'operationId': 'scene-pokemon-form-jsonl',
    });
    return Map<String, Object?>.from(applied.data['receipt']! as Map);
  }

  AuthoringRequest _request({
    required String workspaceHandle,
    required String revision,
    required String suffix,
  }) {
    return AuthoringRequest(
      requestId: 'scene-pokemon-form-$suffix',
      actionId: 'scene.upsert',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: <String, Object?>{'scene': _scene().toJson()},
      expectedRevision: revision,
      idempotencyKey: 'scene-pokemon-form-$suffix',
      dryRun: false,
    );
  }

  Future<AuthoringResult> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    return AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'scene-pokemon-form-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
  }

  Future<String> authoredFormId() async {
    final project = ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    final payload = project.scenes.single.graph.nodes
        .singleWhere((node) => node.id == 'gift')
        .payload as SceneActionPayload;
    return (payload.consequence! as SceneGivePokemonConsequence).formId;
  }

  Future<void> dispose() async {
    await root.delete(recursive: true);
  }
}

SceneAsset _scene() => SceneAsset(
      id: 'gift-scene',
      name: 'Gift Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'gift',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.givePokemon(
                speciesId: 'sproutle',
                formId: 'sunny',
                level: 7,
                currentHp: 24,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start-gift',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'gift',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'gift-end',
            fromNodeId: 'gift',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );
