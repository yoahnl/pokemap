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
