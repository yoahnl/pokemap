import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('item context distinguishes unavailable empty and known catalogs', () {
    final scene = _itemScene();
    final project = _project([scene]);
    final ids = {'potion'};
    final known = SceneProjectDiagnosticsContext(
      project,
      availableItemIds: ids,
    );
    ids.clear();
    expect(known.diagnose(scene).hasErrors, isFalse);
    expect(
      known
          .diagnose(scene)
          .byCode(SceneDiagnosticCode.consequenceItemCatalogUnavailable),
      isEmpty,
    );
    final unavailable = SceneProjectDiagnosticsContext(project).diagnose(scene);
    expect(
      unavailable
          .byCode(SceneDiagnosticCode.consequenceItemCatalogUnavailable)
          .single
          .severity,
      SceneDiagnosticSeverity.warning,
    );
    final empty = SceneProjectDiagnosticsContext(
      project,
      availableItemIds: {},
    ).diagnose(scene);
    expect(
      empty.byCode(SceneDiagnosticCode.consequenceUnknownItem).single.severity,
      SceneDiagnosticSeverity.error,
    );
    for (final available in [
      null,
      <String>{},
      {'potion'},
    ]) {
      expect(
        SceneProjectDiagnosticsContext(
          project,
          availableItemIds: available,
        ).diagnose(scene).diagnostics,
        diagnoseSceneAgainstProject(
          scene,
          project,
          availableItemIds: available,
        ).diagnostics,
      );
    }
  });

  test('one context preserves project diagnostics for every scene', () {
    final scenes = [
      _scene('valid', 'known'),
      _scene('missing', 'unknown'),
      _scene('outcome', 'known', outcomes: const ['missing']),
    ];
    final project = _project(scenes);
    final context = SceneProjectDiagnosticsContext(project);
    for (final scene in scenes) {
      expect(
        context.diagnose(scene).diagnostics,
        diagnoseSceneAgainstProject(scene, project).diagnostics,
      );
    }
    expect(context.diagnose(scenes.first).hasErrors, isFalse);
    expect(
      context
          .diagnose(scenes[1])
          .byCode(SceneDiagnosticCode.dialogueRefUnknown),
      hasLength(1),
    );
    expect(
      context
          .diagnose(scenes[2])
          .byCode(SceneDiagnosticCode.dialogueExpectedOutcomeUnknown),
      hasLength(1),
    );
  });

  test('unloaded declared maps defer only their map checks', () {
    final scene = _remoteMapScene();
    final project = ProjectManifest(
      name: 'Partial maps',
      tilesets: const [],
      maps: const [
        ProjectMapEntry(
          id: 'remote',
          name: 'Remote',
          relativePath: 'maps/remote.json',
        ),
      ],
      scenes: [scene],
    );
    int count(SceneDiagnosticsReport report, SceneDiagnosticCode code) =>
        report.byCode(code).length;

    final strict = SceneProjectDiagnosticsContext(project).diagnose(scene);
    expect(count(strict, SceneDiagnosticCode.consequenceUnknownNpc), 2);
    expect(count(strict, SceneDiagnosticCode.commandUnknownPlatform), 1);
    expect(count(strict, SceneDiagnosticCode.commandUnknownMap), 1);
    expect(count(strict, SceneDiagnosticCode.commandUnknownNpc), 1);
    expect(count(strict, SceneDiagnosticCode.commandInvalidActorTarget), 1);
    expect(count(strict, SceneDiagnosticCode.consequenceUnknownFact), 1);

    final partial = SceneProjectDiagnosticsContext(
      project,
      unloadedMapIds: {'remote'},
    ).diagnose(scene);
    expect(count(partial, SceneDiagnosticCode.consequenceUnknownNpc), 1);
    expect(count(partial, SceneDiagnosticCode.commandUnknownPlatform), 0);
    expect(count(partial, SceneDiagnosticCode.commandUnknownMap), 0);
    expect(count(partial, SceneDiagnosticCode.commandUnknownNpc), 0);
    expect(count(partial, SceneDiagnosticCode.commandInvalidActorTarget), 0);
    expect(count(partial, SceneDiagnosticCode.consequenceUnknownFact), 1);
    expect(
      partial.diagnostics,
      diagnoseSceneAgainstProject(
        scene,
        project,
        unloadedMapIds: {'remote'},
      ).diagnostics,
    );
  });

  test('contexts are isolated between changed project snapshots', () {
    final scene = _scene('scene', 'known');
    final project = _project([scene]);
    final original = SceneProjectDiagnosticsContext(project);
    final changed = SceneProjectDiagnosticsContext(
      project.copyWith(dialogues: []),
    );
    expect(original.diagnose(scene).hasErrors, isFalse);
    expect(
      changed.diagnose(scene).byCode(SceneDiagnosticCode.dialogueRefUnknown),
      hasLength(1),
    );
    expect(original.diagnose(scene).hasErrors, isFalse);
  });
}

SceneAsset _itemScene() => SceneAsset(
  id: 'item',
  name: 'Item',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'give',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'give',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'last',
        fromNodeId: 'give',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

SceneAsset _remoteMapScene() {
  SceneNode action(String id, SceneActionPayload payload) =>
      SceneNode(id: id, kind: SceneNodeKind.action, payload: payload);
  return SceneAsset(
    id: 'remote_map',
    name: 'Remote map',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        action(
          'presence',
          SceneActionPayload.consequence(
            SceneConsequence.setNpcPresence(
              mapId: 'remote',
              entityId: 'npc',
              present: false,
            ),
          ),
        ),
        action(
          'undeclared_presence',
          SceneActionPayload.consequence(
            SceneConsequence.setNpcPresence(
              mapId: 'undeclared',
              entityId: 'npc',
              present: false,
            ),
          ),
        ),
        action(
          'platform',
          SceneActionPayload.interactive(
            SceneMovePlatformInteractiveCommand(
              mapId: 'remote',
              platformId: 'lift',
              motion: MovingPlatformMotion.forward,
            ),
          ),
        ),
        action(
          'wait',
          SceneActionPayload.interactive(
            SceneWaitForActorRoutesInteractiveCommand(mapId: 'remote'),
          ),
        ),
        action(
          'move_npc',
          SceneActionPayload.interactive(
            SceneMoveNpcInteractiveCommand(
              mapId: 'remote',
              entityId: 'npc',
              warpId: 'door',
            ),
          ),
        ),
        action(
          'route',
          SceneActionPayload.interactive(
            SceneActorRouteInteractiveCommand(
              target: SceneActorTarget.player(mapId: 'remote'),
              steps: [SceneActorRouteStep.wait(durationMs: 100)],
            ),
          ),
        ),
        action(
          'fact',
          SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'missing_fact', value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: const [],
    ),
  );
}

ProjectManifest _project(List<SceneAsset> scenes) => ProjectManifest(
  name: 'Context qualification',
  maps: const [],
  tilesets: const [],
  scenes: scenes,
  dialogues: const [
    ProjectDialogueEntry(
      id: 'known',
      name: 'Known',
      relativePath: 'dialogues/known.yarn',
    ),
  ],
);

SceneAsset _scene(
  String id,
  String dialogue, {
  List<String> outcomes = const [],
}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: dialogue,
          expectedOutcomes: outcomes,
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'last',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
