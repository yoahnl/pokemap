import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('item gift declares separate received and bagFull routes', () {
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'giveItem',
      'itemId': 'tm23',
      'quantity': 1,
    });
    expect(command.outputPortIds, ['received', 'bagFull']);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(
      () => SceneInteractiveCommand.fromJson({
        'kind': 'giveItem',
        'itemId': 'tm23',
        'quantity': 0,
      }),
      throwsArgumentError,
    );
  });

  test('no-code gift command builds the canonical retryable payload', () {
    final payload =
        buildScenePayloadForNarrativeCommand(
              commandId: 'giveItemGift',
              parameters: {'itemId': 'tm23', 'quantity': '1'},
            )
            as SceneActionPayload;
    expect(payload.interactiveCommand!.kind.name, 'giveItem');
    expect(payload.interactiveCommand!.outputPortIds, ['received', 'bagFull']);
    expect(
      diagnoseInteractiveCommand(
        command: payload.interactiveCommand!,
        project: const ProjectManifest(name: 'Gift', maps: [], tilesets: []),
      ),
      isEmpty,
    );
  });

  test('gift item reference is indexed once with its editable command path', () {
    final project = ProjectManifest(name: 'Gift', maps: const [], tilesets: const [], scenes: [
      SceneAsset(id: 'gift', name: 'Gift', graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'gift', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1))),
      ])),
    ]);
    final references = buildProjectItemReferenceIndex(project: project).referencesFor('tm23');
    expect(references, hasLength(1));
    expect(references.single.kind, ProjectItemReferenceKind.sceneGive);
    expect(references.single.editablePath, 'scenes[gift].graph.nodes[1].payload.interactiveCommand.itemId');
  });
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

  test('rail journey command round-trips its canonical begin wire', () {
    final json = <String, dynamic>{
      'kind': 'railJourney',
      'commandId': 'board-t1',
      'journeyId': 'T1',
      'operation': 'begin',
      'direction': 'outbound',
      'doorSide': 'west',
    };

    final command = SceneInteractiveCommand.fromJson(json);

    expect(command.toJson(), json);
    expect(command.outputPortIds, const ['completed', 'blocked']);
  });

  test('rail journey command round-trips advance and acknowledge wires', () {
    final jsons = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'railJourney',
        'commandId': 'arrive-t1',
        'journeyId': 'T1',
        'operation': 'advance',
        'advanceEvent': 'destinationDoorUsed',
        'doorSide': 'east',
      },
      <String, dynamic>{
        'kind': 'railJourney',
        'commandId': 'ack-t1',
        'journeyId': 'T1',
        'operation': 'acknowledge',
      },
    ];

    for (final json in jsons) {
      expect(SceneInteractiveCommand.fromJson(json).toJson(), json);
    }
  });

  test('rail journey command rejects incoherent operation fields', () {
    SceneInteractiveCommand decode(Map<String, dynamic> fields) =>
        SceneInteractiveCommand.fromJson(<String, dynamic>{
          'kind': 'railJourney',
          'commandId': 'command-t1',
          'journeyId': 'T1',
          ...fields,
        });

    expect(
      () => decode(<String, dynamic>{'operation': 'begin', 'doorSide': 'west'}),
      throwsArgumentError,
    );
    expect(
      () => decode(<String, dynamic>{
        'operation': 'begin',
        'direction': 'outbound',
      }),
      throwsArgumentError,
    );
    expect(
      () => decode(<String, dynamic>{
        'operation': 'advance',
        'advanceEvent': 'doorsClosed',
        'doorSide': 'west',
      }),
      throwsArgumentError,
    );
    expect(
      () => decode(<String, dynamic>{
        'operation': 'advance',
        'advanceEvent': 'destinationDoorUsed',
      }),
      throwsArgumentError,
    );
    expect(
      () => decode(<String, dynamic>{
        'operation': 'acknowledge',
        'direction': 'return',
      }),
      throwsArgumentError,
    );
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
        (payload) => (payload as SceneActionPayload).interactiveCommand,
      ),
    );
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
    final diagnostics = diagnoseScene(roundTrip);
    expect(
      diagnostics.hasErrors,
      isFalse,
      reason: diagnostics.diagnostics
          .map((diagnostic) => '${diagnostic.code.name}: ${diagnostic.message}')
          .join('\n'),
    );
    expect(
      diagnostics.byCode(SceneDiagnosticCode.actionPayloadLegacyUnsupported),
      isEmpty,
    );
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
      SceneEdge(
        id: 'shop-cancelled',
        fromNodeId: 'shop',
        fromPortId: 'cancelled',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

extension<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}
