import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final action in <ProjectPauseActionId>[
    ProjectPauseActionId.quests,
    ProjectPauseActionId.profile,
  ]) {
    test('${action.name} visibility executes through direct API and JSONL',
        () async {
      final direct =
          await _PauseMenuVisibilityHarness.create('direct-${action.name}');
      final jsonl =
          await _PauseMenuVisibilityHarness.create('jsonl-${action.name}');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);
      await direct.executeDirect(action: action);
      await jsonl.executeJsonl(action: action);
      final expected = SceneConsequence.setPauseMenuEntryVisibility(
          actionId: action, visible: false);
      expect(await direct.consequence(), expected);
      expect(await jsonl.consequence(), expected);
    });
  }

  test('pause menu visibility executes through direct API and JSONL', () async {
    final direct = await _PauseMenuVisibilityHarness.create('direct');
    final jsonl = await _PauseMenuVisibilityHarness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directReceipt = await direct.executeDirect();
    final jsonlReceipt = await jsonl.executeJsonl();

    expect(directReceipt['actionId'], 'scene.pause_menu_visibility.set');
    expect(jsonlReceipt['actionId'], 'scene.pause_menu_visibility.set');
    expect(directReceipt['status'], 'applied');
    expect(jsonlReceipt['status'], 'applied');
    expect(await direct.consequence(), _expectedConsequence);
    expect(await jsonl.consequence(), _expectedConsequence);
  });
}

final class _PauseMenuVisibilityHarness {
  _PauseMenuVisibilityHarness({
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

  static Future<_PauseMenuVisibilityHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pause-menu-visibility-authoring-$suffix-',
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(_project.toJson()),
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
    return _PauseMenuVisibilityHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<Map<String, Object?>> executeDirect(
      {ProjectPauseActionId action = ProjectPauseActionId.pokedex}) async {
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
        action: action,
      ),
    );
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'pause-menu-visibility-direct',
    );
    return Map<String, Object?>.from(applied['receipt']! as Map);
  }

  Future<Map<String, Object?>> executeJsonl(
      {ProjectPauseActionId action = ProjectPauseActionId.pokedex}) async {
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
        action: action,
      ).toJson(),
    });
    final applied = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned.data['planId'],
      'operationId': 'pause-menu-visibility-jsonl',
    });
    return Map<String, Object?>.from(applied.data['receipt']! as Map);
  }

  AuthoringRequest _request({
    required String workspaceHandle,
    required String revision,
    required String suffix,
    required ProjectPauseActionId action,
  }) =>
      AuthoringRequest(
        requestId: 'pause-menu-visibility-$suffix',
        actionId: 'scene.pause_menu_visibility.set',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: <String, Object?>{
          'sceneId': 'intro_scene',
          'nodeId': 'action',
          'actionId': action.name,
          'visible': false,
        },
        expectedRevision: revision,
        idempotencyKey: 'pause-menu-visibility-$suffix',
        dryRun: false,
      );

  Future<AuthoringResult> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async =>
      AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode(<String, Object?>{
              'id': 'pause-menu-visibility-$command',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map<String, dynamic>,
      );

  Future<SceneConsequence?> consequence() async {
    final project = ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    return (project.scenes.single.graph.nodes
            .singleWhere((node) => node.id == 'action')
            .payload as SceneActionPayload)
        .consequence;
  }

  Future<void> dispose() => root.delete(recursive: true);
}

final _expectedConsequence = SceneConsequence.setPauseMenuEntryVisibility(
  actionId: ProjectPauseActionId.pokedex,
  visible: false,
);

final _project = ProjectManifest(
  name: 'Pause menu visibility transport fixture',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  scenes: <SceneAsset>[
    SceneAsset(
      id: 'intro_scene',
      name: 'Intro scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'action',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openPc(),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_action',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'action',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'action_end',
            fromNodeId: 'action',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    ),
  ],
);
