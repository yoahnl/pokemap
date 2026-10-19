import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SceneAsset whiteOutScene() => SceneAsset(
  id: 'white_out',
  name: 'Défaite scénarisée',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'recovery',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.fromJson({'kind': 'whiteOut'}),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'recovery',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'return',
        fromNodeId: 'recovery',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

void main() {
  test('whiteOut is a strict command with one completion port', () {
    final command = SceneInteractiveCommand.fromJson({'kind': 'whiteOut'});
    expect(command.kind.name, 'whiteOut');
    expect(command.outputPortIds, ['completed']);
    expect(command.toJson(), {'kind': 'whiteOut'});
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    for (final field in ['money', 'healParty', 'mapId', 'defeatRecovery']) {
      expect(
        () =>
            SceneInteractiveCommand.fromJson({'kind': 'whiteOut', field: true}),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('whiteOut builds an autonomous runtime command', () {
    final scene = whiteOutScene();
    final result = buildSceneRuntimePlan(scene);
    expect(result.canBuild, isTrue);
    final intent = result.plan!.nodes
        .singleWhere((node) => node.id == 'recovery')
        .intent;
    expect(intent.kind, SceneRuntimePlanIntentKind.executeInteractiveCommand);
    expect(intent.interactiveCommand!.toJson(), {'kind': 'whiteOut'});
    expect(SceneAsset.fromJson(scene.toJson()).graph.edges, scene.graph.edges);
  });

  test('whiteOut has a guided parameterless catalog builder', () {
    final descriptor = NarrativeCommandCatalog.canonical().commands.singleWhere(
      (command) => command.id == 'whiteOut',
    );
    expect(descriptor.parameters, isEmpty);
    expect(descriptor.isPersistent, isTrue);
    final payload =
        buildScenePayloadForNarrativeCommand(
              commandId: descriptor.id,
              parameters: const {},
            )
            as SceneActionPayload;
    expect(payload.interactiveCommand!.toJson(), {'kind': 'whiteOut'});
    expect(
      () => buildScenePayloadForNarrativeCommand(
        commandId: descriptor.id,
        parameters: const {'money': '0'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  for (final dimension in ProjectDimension.values) {
    test('whiteOut availability is explicit for $dimension', () {
      final report = diagnoseSceneAgainstProject(
        whiteOutScene(),
        ProjectManifest(
          name: 'Recovery',
          maps: const [],
          tilesets: const [],
          settings: ProjectSettings(dimension: dimension),
        ),
      );
      expect(
        report.diagnostics.any(
          (diagnostic) =>
              diagnostic.code ==
              SceneDiagnosticCode.commandUnsupportedDimension,
        ),
        dimension != ProjectDimension.twoD,
      );
    });
  }
}
