import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('interactive commands round-trip with explicit output ports', () {
    final commands = <SceneInteractiveCommand>[
      SceneInteractiveCommand.warp(
        destinationMapId: 'map.port',
        warpId: 'warp.arrival',
      ),
      SceneInteractiveCommand.openShop(shopId: 'shop.port'),
      SceneInteractiveCommand.openHeal(requiresConfirmation: false),
      SceneInteractiveCommand.openPc(storageId: 'pc.main'),
    ];

    for (final command in commands) {
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      expect(command.outputPortIds, contains('completed'));
    }
  });

  test('Scene action owns exactly one canonical typed backend', () {
    final command = SceneInteractiveCommand.openShop(shopId: 'shop.port');
    final payload = SceneActionPayload.interactive(command);

    expect(payload.interactiveCommand, command);
    expect(payload.consequence, isNull);
    expect(
      () => SceneActionPayload(
        consequence: SceneConsequence.giveMoney(amount: 200),
        interactiveCommand: command,
      ),
      throwsArgumentError,
    );
  });

  test('Scene JSON and runtime plan preserve interactive command wire', () {
    final scene = _interactiveScene();
    final roundTrip = SceneAsset.fromJson(scene.toJson());
    final action = roundTrip.graph.nodes[1].payload as SceneActionPayload;

    expect(
        action.interactiveCommand,
        scene.graph.nodes[1].payload.let(
            (payload) => (payload as SceneActionPayload).interactiveCommand));
    final plan = buildSceneRuntimePlan(roundTrip);
    expect(plan.canBuild, isTrue);
    expect(
      plan.plan!.nodes[1].intent.kind,
      SceneRuntimePlanIntentKind.executeInteractiveCommand,
    );
    expect(plan.plan!.nodes[1].intent.declaredOutputPortIds, [
      'completed',
      'cancelled',
    ]);
  });
}

SceneAsset _interactiveScene() => SceneAsset(
      id: 'scene.shop',
      name: 'Boutique',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'shop',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openShop(shopId: 'shop.port'),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start-shop',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'shop',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'shop-end',
            fromNodeId: 'shop',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

extension<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}
