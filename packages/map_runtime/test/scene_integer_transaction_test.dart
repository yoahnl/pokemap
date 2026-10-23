import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  for (final legacy in [false, true]) {
    test('${legacy ? 'legacy' : 'event V2'} projects typed calculations, numeric input and payment in order', () async {
      const initial = GameState(saveId: 'numbers', trainerProfile: TrainerProfile(name: 'Player', money: 50));
      final nodes = [
        SceneActionPayload.consequence(SceneConsequence.setFactValue(factId: 'n', value: NarrativeValue.integer(7))),
        SceneActionPayload.consequence(SceneConsequence.calculateIntegerFacts(factIds: ['n'], operation: SceneIntegerOperation.add,
          operand: SceneIntegerOperand.integerFact('n'), minimum: 0, maximum: 999)),
        SceneActionPayload.interactive(SceneInteractiveCommand.inputIntegerToFact(factId: 'n',
          prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 3, minimum: 0, maximum: 999)),
        SceneActionPayload.interactive(SceneInteractiveCommand.tryPayMoney(amount: SceneIntegerOperand.integerFact('n'))),
      ];
      final result = await _run(legacy: legacy, initial: initial, read: () => initial, actions: nodes,
        present: (request) async {
          final input = request.interaction as SceneIntegerInteractionRequest;
          expect(input.initialValue, 14);
          return SceneIntegerSubmittedInteractionResult(requestId: input.requestId, revision: input.revision, value: 23);
        });
      expect(result.success, isTrue);
      expect(result.state!.trainerProfile.money, 27);
      expect(result.state!.narrativeFactRuntimeState.valueFor('n'), NarrativeValue.integer(23));
      expect(initial.trainerProfile.money, 50);
    });
    test('${legacy ? 'legacy' : 'event V2'} rejects changed read-only condition dependencies before completion', () async {
      const initial = GameState(saveId: 'numbers');
      var current = initial;
      final result = await _run(legacy: legacy, initial: initial, read: () => current,
        condition: SceneConditionSource.integerComparison(left: SceneIntegerOperand.integerFact('n'),
          comparison: NarrativeFactOperator.equals, right: SceneIntegerOperand.literal(4)),
        actions: [SceneActionPayload.interactive(SceneInteractiveCommand.wait(durationMs: 1))],
        executeInteractive: (_) async {
          current = initial.copyWith(narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {'n': NarrativeValue.integer(5)}));
          return 'completed';
        }, present: (_) async => throw StateError('No modal expected'));
      expect(result.success, isFalse);
      expect(result.state, isNull);
      expect(current.narrativeFactRuntimeState.valueFor('n'), NarrativeValue.integer(5));
    });
    for (final source in SceneIntegerGameRead.values) {
      test('${legacy ? 'legacy' : 'event V2'} rejects changed ${source.name} read dependency', () async {
        const initial = GameState(saveId: 'numbers', trainerProfile: TrainerProfile(name: 'Player', money: 50),
          party: PlayerParty(members: [PlayerPokemon(speciesId: 'bird', natureId: 'hardy', abilityId: 'keen-eye')]),
          bag: Bag(entries: [BagEntry(itemId: 'supply', quantity: 2)]));
        var current = initial;
        final operand = SceneIntegerOperand.gameRead(source, itemId: source == SceneIntegerGameRead.itemCount ? 'supply' : null);
        final result = await _run(legacy: legacy, initial: initial, read: () => current, actions: [
          SceneActionPayload.consequence(SceneConsequence.calculateIntegerFacts(factIds: ['n'], operation: SceneIntegerOperation.assign,
            operand: operand, minimum: 0, maximum: 999)),
          SceneActionPayload.interactive(SceneInteractiveCommand.inputIntegerToFact(factId: 'n',
            prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 3, minimum: 0, maximum: 999)),
        ], present: (request) async {
          current = switch (source) {
            SceneIntegerGameRead.money => initial.copyWith(trainerProfile: initial.trainerProfile.copyWith(money: 49)),
            SceneIntegerGameRead.partyCount => initial.copyWith(party: const PlayerParty()),
            SceneIntegerGameRead.itemCount => initial.copyWith(bag: const Bag(entries: [BagEntry(itemId: 'supply', quantity: 1)])),
          };
          return SceneIntegerSubmittedInteractionResult(requestId: request.interaction.requestId, revision: request.interaction.revision, value: 3);
        });
        expect(result.success, isFalse);
        expect(result.state, isNull);
        expect(initial.narrativeFactRuntimeState.valuesByFactId, isEmpty);
      });
    }
    test('${legacy ? 'legacy' : 'event V2'} preserves unrelated bag and party changes during money-only input', () async {
      const initial = GameState(saveId: 'numbers', trainerProfile: TrainerProfile(name: 'Player', money: 50));
      var current = initial;
      final result = await _run(legacy: legacy, initial: initial, read: () => current, actions: [
        SceneActionPayload.consequence(SceneConsequence.calculateIntegerFacts(factIds: ['n'], operation: SceneIntegerOperation.assign,
          operand: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money), minimum: 0, maximum: 999)),
        SceneActionPayload.interactive(SceneInteractiveCommand.inputIntegerToFact(factId: 'n',
          prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 3, minimum: 0, maximum: 999)),
      ], present: (request) async {
        current = initial.copyWith(bag: const Bag(entries: [BagEntry(itemId: 'unrelated', quantity: 3)]),
          party: const PlayerParty(members: [PlayerPokemon(speciesId: 'bird', natureId: 'hardy', abilityId: 'keen-eye')]));
        return SceneIntegerSubmittedInteractionResult(requestId: request.interaction.requestId, revision: request.interaction.revision, value: 3);
      });
      expect(result.success, isTrue);
      expect(result.state!.party, current.party);
      expect(result.state!.bag, current.bag);
      expect(result.state!.narrativeFactRuntimeState.valueFor('n'), NarrativeValue.integer(3));
    });
    test('${legacy ? 'legacy' : 'event V2'} disposal cancels the transaction without committing a random draw', () async {
      const initial = GameState(saveId: 'numbers');
      final result = await _run(legacy: legacy, initial: initial, read: () => initial, actions: [
        SceneActionPayload.consequence(SceneConsequence.calculateIntegerFacts(factIds: ['n'], operation: SceneIntegerOperation.assign,
          operand: SceneIntegerOperand.random(minimum: 1, maximum: 4), minimum: 0, maximum: 999)),
        SceneActionPayload.interactive(SceneInteractiveCommand.inputIntegerToFact(factId: 'n',
          prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 3, minimum: 0, maximum: 999,
          cancellationPolicy: SceneIntegerCancellationPolicy.restoreInitialAndComplete)),
      ], present: (request) async => SceneInteractionResult.cancelled(requestId: request.interaction.requestId,
        revision: request.interaction.revision, reason: SceneInteractionCancellationReason.disposed));
      expect(result.success, isFalse);
      expect(result.state, isNull);
      expect(initial.sceneRandomState, const SceneRandomState.unseeded());
    });
    test('${legacy ? 'legacy' : 'event V2'} rejects stale dependencies and rolls back random state on later failure', () async {
      const initial = GameState(saveId: 'numbers');
      var current = initial;
      final result = await _run(legacy: legacy, initial: initial, read: () => current, actions: [
        SceneActionPayload.consequence(SceneConsequence.calculateIntegerFacts(factIds: ['n'], operation: SceneIntegerOperation.assign,
          operand: SceneIntegerOperand.random(minimum: 1, maximum: 4), minimum: 0, maximum: 999)),
        SceneActionPayload.interactive(SceneInteractiveCommand.inputIntegerToFact(factId: 'n',
          prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 3, minimum: 0, maximum: 999)),
      ], present: (request) async {
        current = initial.copyWith(narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {'n': NarrativeValue.integer(100)}));
        return SceneIntegerSubmittedInteractionResult(requestId: request.interaction.requestId, revision: request.interaction.revision, value: 3);
      });
      expect(result.success, isFalse);
      expect(result.state, isNull);
      expect(initial.sceneRandomState, const SceneRandomState.unseeded());
      expect(current.sceneRandomState, initial.sceneRandomState);
    });
  }
}

Future<({bool success, GameState? state})> _run({required bool legacy, required GameState initial,
  required GameState Function() read, required List<SceneActionPayload> actions,
  required Future<SceneInteractionResult> Function(OpenSceneTextInteractionService) present,
  SceneConditionSource? condition, Future<String> Function(SceneRuntimePlanIntent)? executeInteractive}) async {
  final scene = SceneAsset(id: 'numbers', name: 'Numbers', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (condition != null) SceneNode(id: 'condition', kind: SceneNodeKind.condition, payload: SceneConditionPayload(conditionSource: condition)),
    for (final (index, payload) in actions.indexed) SceneNode(id: 'a$index', kind: SceneNodeKind.action, payload: payload),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ], edges: [
    SceneEdge(id: 'enter', fromNodeId: 'start', fromPortId: 'completed', toNodeId: condition == null ? 'a0' : 'condition', kind: SceneEdgeKind.defaultFlow),
    if (condition != null) ...[
      SceneEdge(id: 'condition-true', fromNodeId: 'condition', fromPortId: 'true', toNodeId: 'a0', kind: SceneEdgeKind.conditionTrue),
      SceneEdge(id: 'condition-false', fromNodeId: 'condition', fromPortId: 'false', toNodeId: 'end', kind: SceneEdgeKind.conditionFalse),
    ],
    for (final (index, payload) in actions.indexed)
      for (final port in payload.interactiveCommand?.outputPortIds ?? ['completed'])
        SceneEdge(id: 'edge$index:$port', fromNodeId: 'a$index', fromPortId: port,
          toNodeId: port == 'completed' && index < actions.length - 1 ? 'a${index + 1}' : 'end', kind: SceneEdgeKind.actionCompleted),
  ]));
  final project = ProjectManifest(name: 'Numbers', maps: [], tilesets: [], scenes: [scene], facts: [
    NarrativeFactDefinition(id: 'n', label: 'Number', initialValue: NarrativeValue.integer(4)),
  ]);
  final callbacks = SceneRuntimeHostCallbacks(evaluateCondition: (_) async => 'false', showDialogue: (_) async => 'completed',
    startBattle: (_) async => 'victory', playCinematic: (_) async => 'completed', presentTextInput: present, executeInteractiveCommand: executeInteractive);
  if (!legacy) {
    final result = await executeNarrativeEventScene(request: NarrativeSceneExecutionRequest(eventId: 'number', sceneId: scene.id,
      executionId: 'number-1', gameState: initial), project: project, mapsById: {}, currentGameState: read, callbacks: callbacks);
    return (success: result is NarrativeSceneExecutionCompleted, state: result is NarrativeSceneExecutionCompleted ? result.updatedGameState : null);
  }
  final page = MapEventPage(pageNumber: 0, sceneTarget: MapEventSceneTarget(sceneId: scene.id));
  final result = await SceneEventRuntimeHook(callbacks: callbacks).runForEventPage(project: project,
    map: MapData(id: 'lab', name: 'Lab', size: GridSize(width: 1, height: 1), layers: []),
    event: MapEventDefinition(id: 'number', pages: [page], position: EventPosition(layerId: 'base', x: 0, y: 0)),
    page: page, gameState: initial, currentGameState: read, executionId: 'number-1');
  return (success: result.success, state: result.updatedGameState);
}
