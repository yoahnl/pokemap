import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> warpWire({String? facing, String transition = 'none'}) =>
      {
        'kind': 'warp',
        'destinationMapId': 'centre',
        'warpId': 'arrival',
        if (facing != null) 'arrivalFacing': facing,
        'transition': transition,
      };

  test('warp preserves its arrival direction and transition on round-trip', () {
    for (final facing in EntityFacing.values) {
      final wire = warpWire(facing: facing.name);
      expect(SceneInteractiveCommand.fromJson(wire).toJson(), wire);
    }
  });

  test('warp defaults to the map transition and preserves the direction', () {
    final command = SceneInteractiveCommand.warp(
      destinationMapId: 'centre',
      warpId: 'arrival',
    );
    expect(command.toJson(), warpWire(transition: 'mapDefault'));
  });

  test('warp options participate in command identity', () {
    final commands = {
      SceneInteractiveCommand.fromJson(warpWire()),
      SceneInteractiveCommand.fromJson(warpWire(transition: 'mapDefault')),
      for (final facing in EntityFacing.values)
        SceneInteractiveCommand.fromJson(warpWire(facing: facing.name)),
    };
    expect(commands, hasLength(6));
  });

  test('warp refuses unknown or malformed options', () {
    for (final field in ['arrivalFacing', 'transition']) {
      for (final value in <Object>['invalid', '', 1, true, <String>[]]) {
        expect(
          () => SceneInteractiveCommand.fromJson({...warpWire(), field: value}),
          throwsFormatException,
          reason: '$field=$value',
        );
      }
    }
    expect(
      () =>
          SceneInteractiveCommand.fromJson({...warpWire(), 'transition': null}),
      throwsFormatException,
    );
  });

  test('no-code warp builder retains the typed options', () {
    final payload =
        buildScenePayloadForNarrativeCommand(
              commandId: NarrativeCommandIds.warp,
              parameters: const {
                'destinationMapId': 'centre',
                'warpId': 'arrival',
                'arrivalFacing': 'north',
                'transition': 'none',
              },
            )
            as SceneActionPayload;
    expect(payload.interactiveCommand!.toJson(), warpWire(facing: 'north'));
  });

  test('warp catalog exposes guided optional direction and transition', () {
    final parameters = NarrativeCommandCatalog.canonical()
        .byId(NarrativeCommandIds.warp)!
        .parameters;
    expect(parameters.map((parameter) => parameter.id), [
      'destinationMapId',
      'warpId',
      'arrivalFacing',
      'transition',
      'presentationMode',
      'illustrationElementId',
      'fadeOutMs',
      'transferDelayMs',
      'revealMs',
      'illustrationHoldMs',
      'illustrationFadeMs',
    ]);
    final facing = parameters.singleWhere((p) => p.id == 'arrivalFacing');
    final transition = parameters.singleWhere((p) => p.id == 'transition');
    expect(facing.kind, NarrativeCommandParameterKind.characterDirection);
    expect(facing.required, isFalse);
    expect(transition.kind.name, 'warpTransition');
    expect(transition.required, isFalse);
  });

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

  test(
    'gift item reference is indexed once with its editable command path',
    () {
      final project = ProjectManifest(
        name: 'Gift',
        maps: const [],
        tilesets: const [],
        scenes: [
          SceneAsset(
            id: 'gift',
            name: 'Gift',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'gift',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.giveItem(
                      itemId: 'tm23',
                      quantity: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      final references = buildProjectItemReferenceIndex(
        project: project,
      ).referencesFor('tm23');
      expect(references, hasLength(1));
      expect(references.single.kind, ProjectItemReferenceKind.sceneGive);
      expect(
        references.single.editablePath,
        'scenes[gift].graph.nodes[1].payload.interactiveCommand.itemId',
      );
    },
  );
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
