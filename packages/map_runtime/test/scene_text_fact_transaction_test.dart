import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

final class TextFactFixture {
  TextFactFixture({
    bool presets = false,
    bool suffixOverwrite = false,
    bool failAfter = false,
  }) {
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'inputTextToFact',
      'factId': 'rival',
      'prompt': {'localizationKey': 'rival.name', 'fallbackText': 'Son nom ?'},
      'confirmationPrompt': {
        'localizationKey': 'rival.confirm',
        'fallbackText': 'Confirmer {value} ?',
      },
      'constraints': {'minGraphemes': 1, 'maxGraphemes': 7},
      if (presets) ...{
        'presetValues': ['Blue', 'Gary', 'Michael'],
        'customChoiceLabel': 'Custom',
        'presetChoicePrompt': {
          'localizationKey': 'rival.choice',
          'fallbackText': 'Quel nom ?',
        },
      },
    });
    final nodes = [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'before',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFactValue(
            factId: 'rival',
            value: NarrativeValue.string('Before'),
          ),
        ),
      ),
      SceneNode(
        id: 'input',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(command),
      ),
      if (suffixOverwrite)
        SceneNode(
          id: 'after',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFactValue(
              factId: 'rival',
              value: NarrativeValue.string('After'),
            ),
          ),
        ),
      if (failAfter)
        SceneNode(
          id: 'fail',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.wait(durationMs: 0),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ];
    scene = SceneAsset(
      id: 'names',
      name: 'Names',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: nodes,
        edges: [
          for (var i = 0; i < nodes.length - 1; i++)
            SceneEdge(
              id: 'edge$i',
              fromNodeId: nodes[i].id,
              fromPortId: 'completed',
              toNodeId: nodes[i + 1].id,
              kind: SceneEdgeKind.defaultFlow,
            ),
          SceneEdge(
            id: 'cancel',
            fromNodeId: 'input',
            fromPortId: 'cancelled',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );
    project = ProjectManifest(
      name: 'Names',
      maps: [],
      tilesets: [],
      facts: [
        NarrativeFactDefinition(
          id: 'rival',
          label: 'Nom',
          initialValue: NarrativeValue.string('Old'),
        ),
      ],
      scenes: [scene],
    );
    controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => initial,
      commitAndSave: (_) async {
        commits++;
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    );
  }
  final initial = const GameState(saveId: 'text-scene', currentMapId: 'lab');
  late final SceneAsset scene;
  late final ProjectManifest project;
  late final PlayerServiceRuntimeController controller;
  final locks = <bool>[];
  final requests = <SceneInteractionRequest>[];
  int commits = 0;
  Future<SceneInteractionResult> present(
    OpenSceneTextInteractionService request,
  ) async {
    requests.add(request.interaction);
    return controller.openSceneTextInteraction(request: request);
  }

  Future<SceneInteractionResult> answer(
    OpenSceneTextInteractionService request, {
    String text = 'Gold',
    bool confirm = true,
  }) async {
    final future = present(request);
    final snapshot = controller.worldServiceSnapshot!;
    final interaction = request.interaction;
    final result = switch (interaction) {
      SceneTextInteractionRequest() => SceneInteractionResult.textSubmitted(
        requestId: interaction.requestId,
        revision: interaction.revision,
        value: text,
      ),
      SceneConfirmationInteractionRequest() => SceneInteractionResult.confirmed(
        requestId: interaction.requestId,
        revision: interaction.revision,
        value: confirm,
      ),
      _ => throw StateError('Unexpected request'),
    };
    expect(
      (await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: result,
        ),
      )).status,
      RuntimeWorldServiceCommandStatus.accepted,
    );
    return future;
  }

  Future<({bool success, GameState? state})> run({
    bool legacy = false,
    Future<SceneInteractionResult> Function(OpenSceneTextInteractionService)?
    presenter,
  }) async {
    final callbacks = SceneRuntimeHostCallbacks(
      evaluateCondition: (_) async => 'true',
      showDialogue: (_) async => 'completed',
      startBattle: (_) async => 'victory',
      playCinematic: (_) async => 'completed',
      executeInteractiveCommand: (_) async =>
          throw StateError('Failure after confirmed input'),
      presentTextInput: presenter ?? present,
    );
    if (!legacy) {
      final result = await executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'name',
          sceneId: scene.id,
          executionId: 'name-1',
          gameState: initial,
        ),
        project: project,
        mapsById: {},
        currentGameState: () => initial,
        callbacks: callbacks,
      );
      return (
        success: result is NarrativeSceneExecutionCompleted,
        state: result is NarrativeSceneExecutionCompleted
            ? result.updatedGameState
            : null,
      );
    }
    final page = MapEventPage(
      pageNumber: 0,
      sceneTarget: MapEventSceneTarget(sceneId: scene.id),
    );
    final result = await SceneEventRuntimeHook(callbacks: callbacks)
        .runForEventPage(
          project: project,
          map: MapData(
            id: 'lab',
            name: 'Lab',
            size: GridSize(width: 1, height: 1),
            layers: [],
          ),
          event: MapEventDefinition(
            id: 'event',
            pages: [page],
            position: EventPosition(layerId: 'base', x: 0, y: 0),
          ),
          page: page,
          gameState: initial,
          executionId: 'name-1',
        );
    return (success: result.success, state: result.updatedGameState);
  }
}

void main() {
  test(
    'confirmed text survives a real disk save and a fresh repository',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'scene-text-fact-save-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fixture = TextFactFixture();
      addTearDown(fixture.controller.dispose);
      final result = await fixture.run(
        presenter: (request) => fixture.answer(request, text: 'Éli🌟'),
      );
      expect(result.success, isTrue);
      await _TextSaveRepository(directory).save(result.state!);
      final cold = await _TextSaveRepository(directory).load();
      expect(
        cold!.narrativeFactRuntimeState.valueFor('rival'),
        NarrativeValue.string('Éli🌟'),
      );
      expect(cold.scriptVariables.values, isEmpty);
      expect(fixture.commits, 0);
    },
  );
  for (final legacy in [false, true]) {
    test(
      'legacy=$legacy confirmed input follows earlier Fact assignment and survives cold save',
      () async {
        final f = TextFactFixture();
        addTearDown(f.controller.dispose);
        final result = await f.run(
          legacy: legacy,
          presenter: (request) => f.answer(request),
        );
        expect(result.success, isTrue);
        expect(
          result.state!.narrativeFactRuntimeState.valueFor('rival'),
          NarrativeValue.string('Gold'),
        );
        expect(
          (f.requests.first as SceneTextInteractionRequest).initialValue,
          'Before',
        );
        final reloaded = gameStateFromStrictSaveJson(
          strictGameStateSaveJson(result.state!),
        );
        expect(
          reloaded.narrativeFactRuntimeState,
          result.state!.narrativeFactRuntimeState,
        );
        expect(f.initial.narrativeFactRuntimeState.valueFor('rival'), isNull);
        expect(f.initial.scriptVariables.values, isEmpty);
        expect(f.commits, 0);
        expect(f.locks, [true, false, true, false]);
      },
    );
    test(
      'legacy=$legacy later Fact assignment follows input in the same buffer',
      () async {
        final f = TextFactFixture(suffixOverwrite: true);
        addTearDown(f.controller.dispose);
        final result = await f.run(
          legacy: legacy,
          presenter: (request) => f.answer(request),
        );
        expect(result.success, isTrue);
        expect(
          result.state!.narrativeFactRuntimeState.valueFor('rival'),
          NarrativeValue.string('After'),
        );
        expect(f.commits, 0);
      },
    );
    test(
      'legacy=$legacy failed suffix rolls back confirmed text and earlier facts',
      () async {
        final f = TextFactFixture(failAfter: true);
        addTearDown(f.controller.dispose);
        final result = await f.run(
          legacy: legacy,
          presenter: (request) => f.answer(request),
        );
        expect(result.success, isFalse);
        expect(result.state, isNull);
        expect(f.initial.narrativeFactRuntimeState.valuesByFactId, isEmpty);
        expect(f.commits, 0);
      },
    );
  }
}

final class _TextSaveRepository extends FileGameSaveRepository {
  _TextSaveRepository(this.directory);
  final Directory directory;
  @override
  Future<String> getSaveFilePath() async => '${directory.path}/game-save.json';
}
